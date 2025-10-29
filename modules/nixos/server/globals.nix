{lib, ...}:
with lib; {
  options.server.globals = mkOption {
    type = types.attrs;
    description = "Global values to be used by the server";
    default = {};
  };

  config.server.globals = {
    libraryOwner.user = "root";
    libraryOwner.group = "media";

    uids = {
      jellyfin = 146;
      autobrr = 188;
      bazarr = 232;
      lidarr = 306;
      prowlarr = 293;
      jellyseerr = 262;
      sonarr = 274;
      radarr = 275;
      recyclarr = 269;
      sabnzbd = 38;
      transmission = 70;
      cross-seed = 183;
    };
    gids = {
      autobrr = 188;
      cross-seed = 183;
      jellyseerr = 250;
      media = 169;
      prowlarr = 287;
      recyclarr = 269;
    };

    # TODO: Remove these when you have added each specific service
    # autobrr = {
    #   user = "autobrr";
    #   group = "autobrr";
    # };
    # bazarr = {
    #   inherit (globals.libraryOwner) group;
    #   user = "bazarr";
    # };
    # jellyfin = {
    #   inherit (globals.libraryOwner) group;
    #   user = "jellyfin";
    # };
    # jellyseerr = {
    #   user = "jellyseerr";
    #   group = "jellyseerr";
    # };
    # recyclarr = {
    #   user = "recyclarr";
    #   group = "recyclarr";
    # };
    # sabnzbd = {
    #   inherit (globals.libraryOwner) group;
    #   user = "sabnzbd";
    # };
    # transmission = {
    #   inherit (globals.libraryOwner) group;
    #   user = "transmission";
    # };
    # cross-seed = {
    #   user = "cross-seed";
    #   group = "cross-seed";
    # };
  };
}
