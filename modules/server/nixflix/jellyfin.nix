{
  flake.modules.nixos.homelab =
    { config, inputs, ... }:
    let
      inherit (inputs.nixflix.lib.jellyfinPlugins) fromRepo;
    in
    {
      sops.secrets."jellyfin/kiri_password" = { };
      sops.secrets."jellyfin/api_key" = { };
      sops.secrets."jellyfin/oidc-client-id" = { };
      sops.secrets."jellyfin/oidc-client-secret" = { };
      sops.secrets."opensubtitles-com/api-key" = { };
      sops.secrets."opensubtitles-com/password" = { };

      system.backup.paths = [ config.nixflix.jellyfin.dataDir ];

      nixflix.jellyfin = {
        enable = true;
        apiKey._secret = config.sops.secrets."jellyfin/api_key".path;
        subdomain = "watch";
        network.enableRemoteAccess = true;
        branding = {
          loginDisclaimer = ''
            <form action="https://watch.walawren.com/sso/OID/start/PocketID">
              <button class="raised block emby-button button-submit">
                Sign in with PocketID
              </button>
            </form>
          '';

          customCss = ''
            @import url("https://theme-park.dev/css/base/jellyfin/${config.nixflix.theme.name}.css");

            a.raised.emby-button {
              padding: 0.9em 1em;
              color: inherit !important;
            }

            .disclaimerContainer {
              display: block;
            }
          '';
        };

        users = {
          admin = {
            mutable = false;
            policy.isAdministrator = true;
            password = {
              _secret = config.sops.secrets."jellyfin/kiri_password".path;
            };
          };
        };

        libraries =
          let
            subtitleSettings = {
              subtitleDownloadLanguages = [
                "eng"
                "spa"
              ];
              requirePerfectSubtitleMatch = true;
            };
          in
          {
            Shows = subtitleSettings;
            Anime = subtitleSettings;
            Movies = subtitleSettings;
          };

        system.pluginRepositories = {
          "Intro Skipper" = {
            url = "https://raw.githubusercontent.com/intro-skipper/manifest/d56c137ae182c04a894dd700c25b04c8d2eba855/10.11/manifest.json";
            hash = "sha256-ENwn7Ei3WU2REcxnFNwzF6NGFUcnH2kJ4E5TKbpcDII=";
          };
          "Jellyfin SSO" = {
            url = "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/4ee785577e77b703f206c7a33f4123986d90f2c2/manifest.json";
            hash = "sha256-KeMfhBGoeeC3dW329sr1K0dnUaM35rYdAhr2y/o3vp4=";
          };
        };

        plugins = {
          subbuzz = {
            enable = true;

            config = {
              OpenSubApiKey._secret = config.sops.secrets."opensubtitles-com/api-key".path;
              OpenSubUserName = "kiriwalawren.com";
              OpenSubPassword._secret = config.sops.secrets."opensubtitles-com/password".path;
              EnableOpenSubtitles = true;
              EnableYifySubtitles = true;

              Cache.SubLifeInMinutes = "Always";
            };
          };

          "Subtitle Extract" = {
            enable = true;

            config.ExtractionDuringLibraryScan = true;
          };

          "Intro Skipper" = {
            package = fromRepo {
              version = "1.10.11.17";
              hash = "sha256-cfEnLqKeEGpQSth3NPjDnxCkgv2pePfgCXfVIOrYSiQ=";
            };
            config = {
              ExcludeSeries = "";
              AutoDetectIntros = true;
              AnalyzeSeasonZero = false;
              PreferChromaprint = false;
              CacheFingerprints = true;
              UseAlternativeBlackFrameAnalyzer = false;
              UpdateMediaSegments = true;
              RebuildMediaSegments = true;
              ScanIntroduction = true;
              ScanCredits = true;
              ScanRecap = true;
              ScanPreview = true;
              ScanCommercial = false;
              AnalysisPercent = "25";
              AnalysisLengthLimit = "10";
              FullLengthChapters = false;
              SkipFirstEpisode = false;
              SkipFirstEpisodeAnime = false;
              MinimumIntroDuration = "15";
              MaximumIntroDuration = "120";
              MinimumCreditsDuration = "15";
              MaximumCreditsDuration = "450";
              MaximumMovieCreditsDuration = "900";
              MinimumRecapDuration = "15";
              MaximumRecapDuration = "120";
              MinimumPreviewDuration = "15";
              MaximumPreviewDuration = "120";
              MinimumCommercialDuration = "15";
              MaximumCommercialDuration = "120";
              BlackFrameMinimumPercentage = "85";
              BlackFrameThreshold = "28";
              UseChapterMarkersBlackFrame = true;
              AdjustIntroBasedOnChapters = true;
              AdjustIntroBasedOnSilence = true;
              SnapToKeyframe = true;
              EndSnapThreshold = "2";
              AdjustWindowInward = "5";
              AdjustWindowOutward = "2";
              ChapterAnalyzerIntroductionPattern = "(^|\\s)(Intro|Introduction|OP|Opening)(?!\\sEnd)(\\s|$)";
              ChapterAnalyzerEndCreditsPattern = "(^|\\s)(Credits?|ED|Ending|Outro)(?!\\sEnd)(\\s|$)";
              ChapterAnalyzerPreviewPattern = "(^|\\s)(Preview|PV|Sneak\\s?Peek|Coming\\s?(Up|Soon)|Next\\s+(time|on|episode)|Extra|Teaser|Trailer)(?!\\sEnd)(\\s|:|$)";
              ChapterAnalyzerRecapPattern = "(^|\\s)(Re?cap|Sum{1,2}ary|Prev(ious(ly)?)?|(Last|Earlier)(\\s\\w+)?|Catch[ -]up)(?!\\sEnd)(\\s|:|$)";
              ChapterAnalyzerCommercialPattern = "(^|\\s)(Ad(vert(isement)?)?|Commercial)(?!\\sEnd)(\\s|$)";
              IntroEndOffset = "0";
              IntroStartOffset = "0";
              MaximumFingerprintPointDifferences = 6;
              MaximumTimeSkip = 3.5;
              InvertedIndexShift = 2;
              SilenceDetectionMaximumNoise = "-50";
              SilenceDetectionMinimumDuration = "0.33";
              MaxParallelism = "2";
              ProcessThreads = "0";
              ProcessPriority = "BelowNormal";
              UseFileTransformationPlugin = false;
              SkipbuttonHideDelay = "8";
              EnableMainMenu = true;
              FileTransformationPluginEnabled = false;
            };
          };

          "SSO Authentication" = {
            apiName = "SSO-Auth";
            package = fromRepo {
              version = "4.0.0.4";
              hash = "sha256-MJTyE6CeVLk7mlugauJ/F6bpi1kYwNtzNmQeH3+CFeQ=";
            };
            config = {
              SamlConfigs = { };
              OidConfigs = {
                PocketID = {
                  OidProviderName = "PocketID";
                  OidEndpoint = "https://auth.walawren.com";
                  OidClientId._secret = config.sops.secrets."jellyfin/oidc-client-id".path;
                  OidSecret._secret = config.sops.secrets."jellyfin/oidc-client-secret".path;
                  RoleClaim = "groups";
                  DefaultProvider = "Jellyfin.Server.Implementations.Users.DefaultAuthenticationProvider";
                  DefaultUsernameClaim = "preferred_username";
                  AvatarUrlFormat = "@{picture}";
                  SchemeOverride = "https";
                  PortOverride = null;
                  Enabled = true;
                  EnableAuthorization = true;
                  EnableAllFolders = true;
                  EnableFolderRoles = false;
                  EnableLiveTvRoles = false;
                  EnableLiveTv = false;
                  EnableLiveTvManagement = false;
                  DisableHttps = false;
                  DisablePushedAuthorization = false;
                  DoNotValidateEndpoints = false;
                  DoNotValidateIssuerName = false;
                  DoNotLoadProfile = false;
                  Roles = [
                    "watchers"
                    "admins"
                  ];
                  AdminRoles = [ "admins" ];
                  LiveTvRoles = [ ];
                  LiveTvManagementRoles = [ ];
                  OidScopes = [ "groups" ];
                  EnabledFolders = [ ];
                  FolderRoleMapping = [ ];
                };
              };
            };
          };
        };
      };
    };
}
