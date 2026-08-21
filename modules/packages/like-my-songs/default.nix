{
  perSystem =
    { pkgs, ... }:
    {
      packages.like-my-songs = pkgs.writers.writePython3Bin "like-my-songs" {
        libraries = [ pkgs.python3Packages.requests ];
        doCheck = false;
        makeWrapperArgs = [
          "--set"
          "LIKE_MY_SONGS_CSV"
          "${./_liked-songs.csv}"
        ];
      } ./_like_my_songs.py;
    };
}
