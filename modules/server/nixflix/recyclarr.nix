{ inputs, ... }:
let
  # Recyclarr `qualities` entries, highest priority first; setting `qualities` replaces the guide
  # profile's list, while its cutoff (1080p for all three) and custom format scores still apply
  on = name: { inherit name; };
  off = name: {
    inherit name;
    enabled = false;
  };
  group = name: qualities: { inherit name qualities; };
  offGroup = name: qualities: (group name qualities) // { enabled = false; };
in
{
  flake.modules.nixos.homelab = { config, ... }: {
    nixflix.recyclarr = {
      enable = true;
      cleanupUnmanagedProfiles.enable = true;

      # These override nixflix's mkDefault lists. Each mirrors its TRaSH guide profile's
      # qualities, but also allows everything down to 480p (incl. DVD and SDTV)
      config.radarr.radarr.quality_profiles = [
        {
          trash_id = "0896c29d74de619df168d23b98104b22"; # [SQP] SQP-1 (1080p)
          reset_unmatched_scores.enabled = true;
          min_format_score = 100;
          qualities = [
            (group "Bluray|WEB-1080p" [
              "Bluray-1080p"
              "WEBRip-1080p"
              "WEBDL-1080p"
              "WEBRip-720p"
              "WEBDL-720p"
            ])
            (on "Bluray-720p")
            (on "Bluray-576p")
            (on "Bluray-480p")
            (group "WEB 480p" [
              "WEBRip-480p"
              "WEBDL-480p"
            ])
            (on "DVD")
            (on "SDTV")
            (off "Raw-HD")
            (off "BR-DISK")
            (off "Remux-2160p")
            (off "Bluray-2160p")
            (offGroup "WEB 2160p" [
              "WEBRip-2160p"
              "WEBDL-2160p"
            ])
            (off "HDTV-2160p")
            (off "Remux-1080p")
            (off "HDTV-1080p")
            (off "HDTV-720p")
            (off "DVD-R")
            (off "DVDSCR")
            (off "REGIONAL")
            (off "TELECINE")
            (off "TELESYNC")
            (off "CAM")
            (off "WORKPRINT")
            (off "Unknown")
          ];
        }
      ];

      config.sonarr.sonarr.quality_profiles = [
        {
          trash_id = "9d142234e45d6143785ac55f5a9e8dc9"; # WEB-1080p (Alternative)
          reset_unmatched_scores.enabled = true;
          qualities = [
            (group "WEB 1080p" [
              "WEBRip-1080p"
              "WEBDL-1080p"
            ])
            (on "Bluray-1080p")
            (on "HDTV-1080p")
            (group "WEB 720p" [
              "WEBRip-720p"
              "WEBDL-720p"
            ])
            (on "Bluray-720p")
            (on "HDTV-720p")
            (on "Bluray-576p")
            (group "WEB 480p" [
              "WEBRip-480p"
              "WEBDL-480p"
            ])
            (on "Bluray-480p")
            (on "DVD")
            (on "SDTV")
            (off "Bluray-2160p Remux")
            (off "Bluray-2160p")
            (offGroup "WEB 2160p" [
              "WEBRip-2160p"
              "WEBDL-2160p"
            ])
            (off "HDTV-2160p")
            (off "Bluray-1080p Remux")
            (off "Raw-HD")
            (off "Unknown")
          ];
        }
      ];

      # The guide profile already allows 480p, DVD and SDTV; this also allows Bluray-576p
      config.sonarr.sonarr_anime.quality_profiles = [
        {
          trash_id = "20e0fc959f1f1704bed501f23bdae76f"; # [Anime] Remux-1080p
          reset_unmatched_scores.enabled = true;
          qualities = [
            (group "Bluray 1080p" [
              "Bluray-1080p Remux"
              "Bluray-1080p"
            ])
            (group "WEB 1080p" [
              "HDTV-1080p"
              "WEBRip-1080p"
              "WEBDL-1080p"
            ])
            (on "Bluray-720p")
            (group "WEB 720p" [
              "HDTV-720p"
              "WEBRip-720p"
              "WEBDL-720p"
            ])
            (on "Bluray-576p")
            (on "Bluray-480p")
            (group "WEB 480p" [
              "WEBRip-480p"
              "WEBDL-480p"
            ])
            (on "DVD")
            (on "SDTV")
            (off "Bluray-2160p Remux")
            (off "Bluray-2160p")
            (offGroup "WEB 2160p" [
              "WEBRip-2160p"
              "WEBDL-2160p"
            ])
            (off "HDTV-2160p")
            (off "Raw-HD")
            (off "Unknown")
          ];
        }
      ];
    };
  };
}
