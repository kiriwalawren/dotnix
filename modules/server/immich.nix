{
  flake.modules.nixos.homelab =
    { config, ... }:
    {
      sops.secrets."immich/oidc-client-secret" = {
        owner = config.services.immich.user;
        inherit (config.services.immich) group;
      };

      systemd.tmpfiles.settings."10-immich".${config.services.immich.mediaLocation}.d = {
        mode = "755";
        inherit (config.services.immich) user group;
      };

      services.immich = {
        enable = true;
        host = "127.0.0.1";
        mediaLocation = "/data/photos";
        database = {
          enable = true;
          createDB = true;
        };
        redis.enable = true;

        settings = {
          backup = {
            database = {
              cronExpression = "0 02 * * *";
              enabled = true;
              keepLastAmount = 14;
            };
          };

          ffmpeg = {
            accel = "disabled";
            accelDecode = false;
            acceptedAudioCodecs = [
              "aac"
              "mp3"
              "opus"
            ];
            acceptedContainers = [
              "mov"
              "ogg"
              "webm"
            ];
            acceptedVideoCodecs = [ "h264" ];
            bframes = -1;
            cqMode = "auto";
            crf = 23;
            gopSize = 0;
            maxBitrate = "0";
            preferredHwDevice = "auto";
            preset = "ultrafast";
            refs = 0;
            targetAudioCodec = "aac";
            targetResolution = "720";
            targetVideoCodec = "h264";
            temporalAQ = false;
            threads = 0;
            tonemap = "hable";
            transcode = "required";
            twoPass = false;
          };

          image = {
            colorspace = "p3";
            extractEmbedded = false;
            fullsize = {
              enabled = false;
              format = "jpeg";
              quality = 80;
            };
            preview = {
              format = "jpeg";
              quality = 80;
              size = 1440;
            };
            thumbnail = {
              format = "webp";
              quality = 80;
              size = 250;
            };
          };

          job = {
            backgroundTask = {
              concurrency = 5;
            };
            faceDetection = {
              concurrency = 2;
            };
            library = {
              concurrency = 5;
            };
            metadataExtraction = {
              concurrency = 5;
            };
            migration = {
              concurrency = 5;
            };
            notifications = {
              concurrency = 5;
            };
            ocr = {
              concurrency = 1;
            };
            search = {
              concurrency = 5;
            };
            sidecar = {
              concurrency = 5;
            };
            smartSearch = {
              concurrency = 2;
            };
            thumbnailGeneration = {
              concurrency = 3;
            };
            videoConversion = {
              concurrency = 1;
            };
          };

          library = {
            scan = {
              cronExpression = "0 0 * * *";
              enabled = true;
            };
            watch = {
              enabled = false;
            };
          };

          logging = {
            enabled = true;
            level = "log";
          };

          machineLearning = {
            availabilityChecks = {
              enabled = true;
              interval = 30000;
              timeout = 2000;
            };
            clip = {
              enabled = true;
              modelName = "ViT-B-32__openai";
            };
            duplicateDetection = {
              enabled = true;
              maxDistance = 0.01;
            };
            enabled = true;
            facialRecognition = {
              enabled = true;
              maxDistance = 0.5;
              minFaces = 3;
              minScore = 0.7;
              modelName = "buffalo_l";
            };
            ocr = {
              enabled = true;
              maxResolution = 736;
              minDetectionScore = 0.5;
              minRecognitionScore = 0.8;
              modelName = "PP-OCRv5_mobile";
            };
            urls = [ "http://immich-machine-learning:3003" ];
          };

          map = {
            darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
            enabled = true;
            lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
          };

          metadata = {
            faces = {
              import = false;
            };
          };

          newVersionCheck = {
            enabled = true;
          };

          nightlyTasks = {
            clusterNewFaces = true;
            databaseCleanup = true;
            generateMemories = true;
            missingThumbnails = true;
            startTime = "00:00";
            syncQuotaUsage = true;
          };

          notifications = {
            smtp = {
              enabled = false;
              from = "";
              replyTo = "";
              transport = {
                host = "";
                ignoreCert = false;
                password = "";
                port = 587;
                secure = false;
                username = "";
              };
            };
          };

          oauth = {
            enabled = true;
            autoLaunch = true;
            autoRegister = true;
            buttonText = "Login with OAuth";
            clientId = "8294b517-8463-4955-b973-0f9727e8a3d6";
            clientSecret._secret = config.sops.secrets."immich/oidc-client-secret".path;
            defaultStorageQuota = null;
            issuerUrl = "https://auth.walawren.com";
            mobileOverrideEnabled = false;
            mobileRedirectUri = "";
            profileSigningAlgorithm = "none";
            roleClaim = "immich_role";
            scope = "openid email profile";
            signingAlgorithm = "RS256";
            storageLabelClaim = "preferred_username";
            storageQuotaClaim = "immich_quota";
            timeout = 30000;
            tokenEndpointAuthMethod = "client_secret_post";
          };

          passwordLogin = {
            enabled = true;
          };

          reverseGeocoding = {
            enabled = true;
          };

          server = {
            externalDomain = "http://photos.homelab";
            loginPageMessage = "";
            publicUsers = true;
          };

          storageTemplate = {
            enabled = false;
            hashVerificationEnabled = true;
            template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
          };

          templates = {
            email = {
              albumInviteTemplate = "";
              albumUpdateTemplate = "";
              welcomeTemplate = "";
            };
          };

          theme = {
            customCss = "";
          };

          trash = {
            days = 30;
            enabled = true;
          };

          user = {
            deleteDelay = 7;
          };
        };
      };

      services.nginx.virtualHosts."photos.${config.system.ddns.domain}" = {
        forceSSL = true;
        useACMEHost = config.system.ddns.domain;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString config.services.immich.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            # allow large file uploads
            client_max_body_size 50000M;

            # disable buffering uploads to prevent OOM on reverse proxy server and make uploads twice as fast (no pause)
            proxy_request_buffering off;

            # increase body buffer to avoid limiting upload speed
            client_body_buffer_size 1024k;

            proxy_redirect off;

            # set timeout
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout       600s;
          '';
        };
      };
    };
}
