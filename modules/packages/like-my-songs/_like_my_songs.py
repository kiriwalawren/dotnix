#!/usr/bin/env python3
"""
Bulk-favorite (star) your Spotify Liked Songs in Navidrome.

Workflow:
  1. Export your Spotify Liked Songs to CSV using Exportify:
     https://exportify.net  (click "Liked Songs" -> Export)
  2. Run this script pointing at that CSV and your Navidrome server.

It matches each Spotify track (by title + artist) against your Navidrome
library using the Subsonic search3 endpoint, and stars (favorites) the
best match it finds. Anything it can't confidently match is logged to
a report file so you can handle it manually instead of risking a wrong star.

Usage:
    python _like_my_songs.py \
        --server https://your-navidrome-url \
        --user your_username \
        --password your_password \
        [--csv "./_liked-songs.csv.csv"] \
        [--dry-run] [--threshold 0.82] [--workers 12]

Notes:
  - "--dry-run" shows what WOULD be starred without actually starring anything.
    Strongly recommended for your first run.
  - "--workers" controls how many searches/stars run concurrently (default 8).
    Higher = faster, but can hammer your server. Lower it if you see errors.
  - Requires: pip install requests --break-system-packages
"""

import argparse
import csv
import difflib
import hashlib
import os
import random
import string
import sys
import threading
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

print_lock = threading.Lock()

SUBSONIC_API_VERSION = "1.16.1"
CLIENT_NAME = "favorite-spotify-liked-script"


def make_auth_params(username: str, password: str) -> dict:
    """Subsonic token auth: token = md5(password + salt)."""
    salt = "".join(random.choices(string.ascii_letters + string.digits, k=12))
    token = hashlib.md5((password + salt).encode("utf-8")).hexdigest()
    return {
        "u": username,
        "t": token,
        "s": salt,
        "v": SUBSONIC_API_VERSION,
        "c": CLIENT_NAME,
        "f": "xml",
    }


def normalize(text: str) -> str:
    return "".join(ch.lower() for ch in text if ch.isalnum() or ch.isspace()).strip()


def similarity(a: str, b: str) -> float:
    return difflib.SequenceMatcher(None, normalize(a), normalize(b)).ratio()


def search_song(server: str, auth_params: dict, title: str, artist: str, timeout=15):
    """Query Subsonic search3 for a title, return list of (song_id, title, artist, album)."""
    params = dict(auth_params)
    params["query"] = title
    params["songCount"] = 20
    params["albumCount"] = 0
    params["artistCount"] = 0

    resp = requests.get(f"{server}/rest/search3", params=params, timeout=timeout)
    resp.raise_for_status()
    root = ET.fromstring(resp.text)

    ns = {"s": "http://subsonic.org/restapi"}
    songs = []
    search_result = root.find("s:searchResult3", ns)
    if search_result is None:
        return songs

    for song in search_result.findall("s:song", ns):
        songs.append(
            {
                "id": song.get("id"),
                "title": song.get("title", ""),
                "artist": song.get("artist", ""),
                "album": song.get("album", ""),
            }
        )
    return songs


def star_song(server: str, auth_params: dict, song_id: str, timeout=15):
    params = dict(auth_params)
    params["id"] = song_id
    resp = requests.get(f"{server}/rest/star", params=params, timeout=timeout)
    resp.raise_for_status()
    root = ET.fromstring(resp.text)
    return root.get("status") == "ok"


def read_spotify_csv(path: str):
    """Read an Exportify CSV. Handles common column name variants."""
    tracks = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        fieldnames = [fn.strip() for fn in (reader.fieldnames or [])]

        title_col = next(
            (c for c in fieldnames if c.lower() in ("track name", "name", "title")),
            None,
        )
        artist_col = next(
            (
                c
                for c in fieldnames
                if c.lower() in ("artist name(s)", "artist name", "artist", "artists")
            ),
            None,
        )
        album_col = next(
            (c for c in fieldnames if c.lower() in ("album name", "album")),
            None,
        )

        if not title_col or not artist_col:
            print(
                f"ERROR: Could not find title/artist columns in CSV headers: {fieldnames}",
                file=sys.stderr,
            )
            sys.exit(1)

        for row in reader:
            title = (row.get(title_col) or "").strip()
            artist_field = (row.get(artist_col) or "").strip()
            # Exportify often joins multiple artists with a comma; take the first
            artist = artist_field.split(",")[0].strip()
            album = (row.get(album_col) or "").strip() if album_col else ""
            if title and artist:
                tracks.append({"title": title, "artist": artist, "album": album})
    return tracks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--server",
        required=True,
        help="Navidrome base URL, e.g. https://music.example.com",
    )
    parser.add_argument("--user", required=True, help="Navidrome username")
    parser.add_argument("--password", required=True, help="Navidrome password")
    parser.add_argument(
        "--csv",
        default=os.environ.get(
            "LIKE_MY_SONGS_CSV", os.path.join(os.getcwd(), "_liked-songs.csv")
        ),
        help="Path to Exportify CSV export (defaults to the bundled copy when packaged via Nix)",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=0.82,
        help="Minimum combined title+artist similarity (0-1) to accept a match. Default 0.82",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Don't actually star anything, just report what would happen",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=12,
        help="Number of concurrent requests for searching/starring. Default 8.",
    )
    args = parser.parse_args()

    server = args.server.rstrip("/")
    tracks = read_spotify_csv(args.csv)
    total = len(tracks)
    print(f"Loaded {total} liked tracks from CSV. Using {args.workers} workers.\n")

    def search_one(index, track):
        """Runs in a worker thread. Each thread gets its own auth params
        (fresh salt/token) since Subsonic auth is stateless per-request."""
        title, artist, album = track["title"], track["artist"], track.get("album", "")
        try:
            auth_params = make_auth_params(args.user, args.password)
            results = search_song(server, auth_params, title, artist)
        except requests.RequestException as e:
            return index, title, artist, album, None, None, f"server error: {e}"

        if not results:
            return index, title, artist, album, None, None, "no results"

        best, best_score = None, 0.0
        for song in results:
            if album:
                # Title + artist + album, weighted so title/artist still dominate
                score = (
                    0.5 * similarity(song["title"], title)
                    + 0.3 * similarity(song["artist"], artist)
                    + 0.2 * similarity(song.get("album", ""), album)
                )
            else:
                # No album info from Spotify export, fall back to title+artist only
                score = 0.6 * similarity(song["title"], title) + 0.4 * similarity(
                    song["artist"], artist
                )
            if score > best_score:
                best, best_score = song, score

        return index, title, artist, album, best, best_score, None

    matched, unmatched, low_confidence = [], [], []
    completed = 0

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = [
            executor.submit(search_one, i, track) for i, track in enumerate(tracks, 1)
        ]
        for future in as_completed(futures):
            index, title, artist, album, best, best_score, error = future.result()
            completed += 1

            with print_lock:
                prefix = f"[{completed}/{total}]"
                if error:
                    print(f"{prefix} {artist} - {title} -> {error}")
                    unmatched.append((title, artist, error))
                elif best_score >= args.threshold:
                    print(
                        f"{prefix} {artist} - {title} -> MATCH ({best_score:.2f}): "
                        f"{best['artist']} - {best['title']} [{best.get('album', '')}]"
                    )
                    matched.append((title, artist, best))
                else:
                    print(
                        f"{prefix} {artist} - {title} -> low confidence "
                        f"({best_score:.2f}): {best['artist']} - {best['title']} "
                        f"[{best.get('album', '')}]"
                    )
                    low_confidence.append((title, artist, best, best_score))

    print(f"\n{'='*60}")
    print(f"Confident matches: {len(matched)}")
    print(f"Low-confidence (skipped): {len(low_confidence)}")
    print(f"No results (skipped): {len(unmatched)}")
    print(f"{'='*60}\n")

    if args.dry_run:
        print("DRY RUN - nothing was starred. Re-run without --dry-run to apply.\n")
    else:
        starred, failed = 0, 0
        star_lock = threading.Lock()

        def star_one(item):
            title, artist, song = item
            try:
                auth_params = make_auth_params(args.user, args.password)
                ok = star_song(server, auth_params, song["id"])
                return title, artist, ok, None
            except requests.RequestException as e:
                return title, artist, False, str(e)

        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            futures = [executor.submit(star_one, item) for item in matched]
            for future in as_completed(futures):
                title, artist, ok, error = future.result()
                with star_lock:
                    if ok:
                        starred += 1
                    else:
                        failed += 1
                        print(
                            f"  Failed to star: {artist} - {title}"
                            + (f" ({error})" if error else "")
                        )

        print(f"\nStarred {starred} songs. Failed: {failed}.\n")

    # Write a report of anything skipped so you can handle manually
    report_path = "unmatched_report.csv"
    with open(report_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "spotify_title",
                "spotify_artist",
                "reason",
                "best_guess_title",
                "best_guess_artist",
                "score",
            ]
        )
        for title, artist, reason in unmatched:
            writer.writerow([title, artist, reason, "", "", ""])
        for title, artist, best, score in low_confidence:
            writer.writerow(
                [
                    title,
                    artist,
                    "low_confidence",
                    best["title"],
                    best["artist"],
                    f"{score:.2f}",
                ]
            )

    print(f"Report of skipped/unmatched tracks written to: {report_path}")


if __name__ == "__main__":
    main()
