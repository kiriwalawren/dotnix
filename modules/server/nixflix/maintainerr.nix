{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      system.backup.paths = [ config.nixflix.maintainerr.dataDir ];

      nixflix.maintainerr = {
        enable = true;
        subdomain = "cleanup";

        overlays = {
          settings.enabled = true;
        };

        rules = [
          {
            name = "Movies To Delete";
            description = "Deletes movies that have been watched or have been around for too long.";
            library = "Movies";
            dataType = "movie";
            radarrServerName = "Radarr";
            collection = {
              deleteAfterDays = 14;
              overlayEnabled = true;
            };
            rules = [
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "1";
                };
                firstVal = [
                  6
                  42
                ];
                action = 2;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "23328000";
                };
                operator = "1";
                firstVal = [
                  6
                  0
                ];
                action = 5;
                section = 0;
              }
              {
                operator = "0";
                firstVal = [
                  6
                  39
                ];
                action = 19;
                section = 1;
              }
            ];
          }
          {
            name = "Show Seasons To Delete";
            description = "Deletes entire seasons that have been around for too long.";
            library = "Shows";
            dataType = "season";
            sonarrServerName = "Sonarr";
            collection = {
              deleteAfterDays = 14;
              overlayEnabled = true;
            };
            rules = [
              {
                firstVal = [
                  6
                  7
                ];
                action = 19;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "7776000";
                };
                operator = "0";
                firstVal = [
                  6
                  0
                ];
                action = 5;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "7776000";
                };
                operator = "1";
                firstVal = [
                  6
                  7
                ];
                action = 5;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "0";
                };
                operator = "1";
                firstVal = [
                  2
                  1
                ];
                action = 2;
                section = 1;
              }
              {
                lastVal = [
                  6
                  15
                ];
                operator = "1";
                firstVal = [
                  6
                  14
                ];
                action = 2;
                section = 1;
              }
              {
                operator = "0";
                firstVal = [
                  6
                  41
                ];
                action = 19;
                section = 2;
              }
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "1";
                };
                operator = "0";
                firstVal = [
                  2
                  16
                ];
                action = 2;
                section = 3;
              }
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "1";
                };
                operator = "1";
                firstVal = [
                  2
                  17
                ];
                action = 2;
                section = 3;
              }
            ];
          }
          {
            name = "Anime Seasons To Delete";
            description = "Deletes entire seasons that have been around for too long.";
            library = "Anime";
            dataType = "season";
            sonarrServerName = "Sonarr Anime";
            collection = {
              deleteAfterDays = 14;
              overlayEnabled = true;
            };
            rules = [
              {
                firstVal = [
                  6
                  7
                ];
                action = 19;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "7776000";
                };
                operator = "0";
                firstVal = [
                  6
                  0
                ];
                action = 5;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "7776000";
                };
                operator = "1";
                firstVal = [
                  6
                  7
                ];
                action = 5;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "0.0";
                };
                operator = "1";
                firstVal = [
                  2
                  1
                ];
                action = 2;
                section = 1;
              }
              {
                lastVal = [
                  6
                  15
                ];
                operator = "1";
                firstVal = [
                  6
                  14
                ];
                action = 2;
                section = 1;
              }
              {
                operator = "0";
                firstVal = [
                  6
                  41
                ];
                action = 19;
                section = 2;
              }
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "1";
                };
                operator = "0";
                firstVal = [
                  2
                  16
                ];
                action = 2;
                section = 3;
              }
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "1";
                };
                operator = "1";
                firstVal = [
                  2
                  17
                ];
                action = 2;
                section = 3;
              }
            ];
          }
          {
            name = "Shows To Delete";
            description = "Deletes shows that have had all episodes removed by other rules and are ended.";
            library = "Shows";
            dataType = "show";
            sonarrServerName = "Sonarr";
            collection = {
              deleteAfterDays = 14;
              overlayEnabled = true;
            };
            rules = [
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "0";
                };
                firstVal = [
                  2
                  1
                ];
                action = 2;
                section = 0;
              }
              {
                lastVal = [
                  6
                  15
                ];
                operator = "1";
                firstVal = [
                  6
                  14
                ];
                action = 2;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "1";
                };
                operator = "0";
                firstVal = [
                  2
                  7
                ];
                action = 2;
                section = 0;
              }
              {
                operator = "0";
                firstVal = [
                  6
                  40
                ];
                action = 19;
                section = 1;
              }
            ];
          }
          {
            name = "Anime To Delete";
            description = "Deletes anime that have had all episodes removed by other rules and are ended.";
            library = "Anime";
            dataType = "show";
            sonarrServerName = "Sonarr Anime";
            collection = {
              deleteAfterDays = 14;
              overlayEnabled = true;
            };
            rules = [
              {
                firstVal = [
                  2
                  1
                ];
                action = 19;
                section = 0;
              }
              {
                lastVal = [
                  6
                  15
                ];
                operator = "1";
                firstVal = [
                  6
                  14
                ];
                action = 2;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "1";
                };
                operator = "0";
                firstVal = [
                  2
                  7
                ];
                action = 2;
                section = 0;
              }
              {
                operator = "0";
                firstVal = [
                  6
                  40
                ];
                action = 19;
                section = 1;
              }
            ];
          }
          {
            name = "Shows To Ignore";
            description = "Creates list of shows that should be ignore because their folders are empty, but they are not ended.";
            library = "Shows";
            dataType = "show";
            arrAction = 4;
            sonarrServerName = "Sonarr";
            rules = [
              {
                customVal = {
                  ruleTypeId = 0;
                  value = "0";
                };
                firstVal = [
                  2
                  1
                ];
                action = 2;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "0";
                };
                operator = "0";
                firstVal = [
                  2
                  7
                ];
                action = 2;
                section = 0;
              }
              {
                operator = "0";
                firstVal = [
                  6
                  40
                ];
                action = 19;
                section = 1;
              }
            ];
          }
          {
            name = "Anime To Ignore";
            description = "Creates list of shows that should be ignore because their folders are empty, but they are not ended.";
            library = "Anime";
            dataType = "show";
            arrAction = 4;
            sonarrServerName = "Sonarr Anime";
            rules = [
              {
                firstVal = [
                  2
                  1
                ];
                action = 19;
                section = 0;
              }
              {
                customVal = {
                  ruleTypeId = 3;
                  value = "0";
                };
                operator = "0";
                firstVal = [
                  2
                  7
                ];
                action = 2;
                section = 0;
              }
              {
                operator = "0";
                firstVal = [
                  6
                  40
                ];
                action = 19;
                section = 1;
              }
            ];
          }
          {
            name = "Show Episodes To Delete";
            library = "Shows";
            dataType = "episode";
            arrAction = 3;
            sonarrServerName = "Sonarr";
            collection = {
              deleteAfterDays = 14;
              overlayEnabled = true;
            };
            rules = [
              {
                customVal = {
                  ruleTypeId = 2;
                  value = ''["Show Seasons to Delete"]'';
                };
                firstVal = [
                  6
                  26
                ];
                action = 10;
                section = 0;
              }
            ];
          }
          {
            name = "Anime Episodes To Delete";
            library = "Anime";
            dataType = "episode";
            arrAction = 3;
            sonarrServerName = "Sonarr Anime";
            collection = {
              deleteAfterDays = 14;
              overlayEnabled = true;
            };
            rules = [
              {
                customVal = {
                  ruleTypeId = 2;
                  value = ''["Anime Seasons to Delete"]'';
                };
                firstVal = [
                  6
                  26
                ];
                action = 10;
                section = 0;
              }
            ];
          }
        ];
      };
    };
}
