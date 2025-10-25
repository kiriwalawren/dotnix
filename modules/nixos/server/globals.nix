{
  config,
  lib,
  ...
}:
with lib; let
  globals = config.server.globals;
in {
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

    autobrr = {
      user = "autobrr";
      group = "autobrr";
    };
    bazarr = {
      user = "bazarr";
      group = globals.libraryOwner.group;
    };
    jellyfin = {
      user = "jellyfin";
      group = globals.libraryOwner.group;
    };
    jellyseerr = {
      user = "jellyseerr";
      group = "jellyseerr";
    };
    lidarr = {
      user = "lidarr";
      group = globals.libraryOwner.group;
    };
    prowlarr = {
      user = "prowlarr";
      group = "prowlarr";
    };
    radarr = {
      user = "radarr";
      group = globals.libraryOwner.group;
    };
    recyclarr = {
      user = "recyclarr";
      group = "recyclarr";
    };
    sabnzbd = {
      user = "sabnzbd";
      group = globals.libraryOwner.group;
    };
    sonarr = {
      user = "sonarr";
      group = globals.libraryOwner.group;
    };
    transmission = {
      user = "transmission";
      group = globals.libraryOwner.group;
    };
    cross-seed = {
      user = "cross-seed";
      group = "cross-seed";
    };
  };
}
