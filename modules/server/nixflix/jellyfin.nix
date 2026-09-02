{
  flake.modules.nixos.homelab =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (inputs.nixflix.lib.jellyfinPlugins) fromRepo;
    in
    {
      sops.secrets."jellyfin/kiri-password" = { };
      sops.secrets."jellyfin/guest-password" = { };
      sops.secrets."jellyfin/api-key" = { };
      sops.secrets."opensubtitles-com/api-key" = { };
      sops.secrets."opensubtitles-com/password" = { };

      system.backup.paths = [ config.nixflix.jellyfin.dataDir ];

      nixflix.jellyfin = {
        enable = true;
        apiKey._secret = config.sops.secrets."jellyfin/api-key".path;
        subdomain = "watch";
        network.enableRemoteAccess = true;
        branding = {
          customCss = ''
            @import url("https://theme-park.dev/css/base/jellyfin/${config.nixflix.theme.name}.css");
          '';
        };

        users = {
          admin = {
            mutable = false;
            policy.isAdministrator = true;
            password = {
              _secret = config.sops.secrets."jellyfin/kiri-password".path;
            };
          };
          guest = {
            mutable = false;
            policy.isAdministrator = lib.mkForce false;
            password = {
              _secret = config.sops.secrets."jellyfin/guest-password".path;
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
            Music = lib.mkForce null;
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
        };
      };
    };
}
