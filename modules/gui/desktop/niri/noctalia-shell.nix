{ inputs, ... }:
{
  flake.modules.nixos.niri = {
    services.upower.enable = true;
  };

  flake.modules.homeManager.gui = {
    imports = [ inputs.noctalia.homeModules.default ];
  };

  flake.modules.homeManager.niri =
    { pkgs, ... }:
    let
      noctalia =
        cmd:
        [
          "noctalia-shell"
          "ipc"
          "call"
        ]
        ++ (pkgs.lib.splitString " " cmd);
    in
    {
      programs.niri.settings = {
        debug.honor-xdg-activation-with-invalid-serial = [ ];
        spawn-at-startup = [
          {
            command = [ "noctalia-shell" ];
          }
          {
            command = noctalia "volume muteInput";
          }
        ];

        binds =
          let
            noctalia =
              cmd:
              [
                "noctalia-shell"
                "ipc"
                "call"
              ]
              ++ (pkgs.lib.splitString " " cmd);
          in
          {
            # Core Noctalia Bindings
            "Mod+Space".action.spawn = noctalia "launcher toggle";
            "Mod+S".action.spawn = noctalia "controlCenter toggle";
            "Mod+Comma".action.spawn = noctalia "settings toggle";
            "Mod+N".action.spawn = noctalia "lockScreen lock";
            "Mod+Shift+N".action.spawn = noctalia "sessionMenu lockAndSuspend";

            # Audio
            "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
            "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
            "XF86AudioMute".action.spawn = noctalia "volume muteOutput";
            "CTRL+Space".action.spawn = noctalia "volume muteInput";

            # Media
            "XF86AudioPlay".action.spawn = noctalia "media playPause";
            "XF86AudioPrev".action.spawn = noctalia "media previous";
            "XF86AudioNext".action.spawn = noctalia "media next";

            # Brightness
            "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
            "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
          };
      };

      programs.noctalia-shell = {
        enable = true;
        settings = {
          settingsVersion = 53;
          bar = {
            barType = "floating";
            position = "top";
            monitors = [ ];
            density = "default";
            showOutline = false;
            showCapsule = true;
            capsuleOpacity = 1;
            capsuleColorKey = "none";
            widgetSpacing = 6;
            contentPadding = 2;
            fontScale = 1;
            backgroundOpacity = 0.93;
            useSeparateOpacity = false;
            floating = true;
            marginVertical = 4;
            marginHorizontal = 4;
            frameThickness = 8;
            frameRadius = 12;
            outerCorners = true;
            hideOnOverview = false;
            displayMode = "always_visible";
            autoHideDelay = 500;
            autoShowDelay = 150;
            showOnWorkspaceSwitch = true;
            widgets = {
              left = [
                {
                  colorizeSystemIcon = "tertiary";
                  customIconPath = "";
                  enableColorization = true;
                  icon = "rocket";
                  iconColor = "none";
                  id = "Launcher";
                  useDistroLogo = true;
                }
                {
                  clockColor = "secondary";
                  customFont = "";
                  formatHorizontal = "HH:mm ddd, MMM dd";
                  formatVertical = "HH mm - dd MM";
                  id = "Clock";
                  tooltipFormat = "HH:mm ddd, MMM dd";
                  useCustomFont = false;
                }
                {
                  compactMode = false;
                  diskPath = "/";
                  iconColor = "tertiary";
                  id = "SystemMonitor";
                  showCpuFreq = false;
                  showCpuTemp = true;
                  showCpuUsage = true;
                  showDiskAvailable = false;
                  showDiskUsage = false;
                  showDiskUsageAsPercent = false;
                  showGpuTemp = false;
                  showLoadAverage = false;
                  showMemoryAsPercent = true;
                  showMemoryUsage = true;
                  showNetworkStats = false;
                  showSwapUsage = false;
                  textColor = "tertiary";
                  useMonospaceFont = true;
                  usePadding = false;
                }
                {
                  compactMode = true;
                  compactShowAlbumArt = true;
                  compactShowVisualizer = false;
                  hideMode = "hidden";
                  hideWhenIdle = false;
                  id = "MediaMini";
                  maxWidth = 145;
                  panelShowAlbumArt = true;
                  panelShowVisualizer = true;
                  scrollingMode = "hover";
                  showAlbumArt = true;
                  showArtistFirst = true;
                  showProgressRing = true;
                  showVisualizer = false;
                  textColor = "error";
                  useFixedWidth = false;
                  visualizerType = "linear";
                }
              ];
              center = [
                {
                  characterCount = 2;
                  colorizeIcons = false;
                  emptyColor = "secondary";
                  enableScrollWheel = true;
                  focusedColor = "primary";
                  followFocusedScreen = false;
                  groupedBorderOpacity = 1;
                  hideUnoccupied = false;
                  iconScale = 0.8;
                  id = "Workspace";
                  labelMode = "index";
                  occupiedColor = "secondary";
                  pillSize = 0.6;
                  showApplications = false;
                  showBadge = true;
                  showLabelsOnlyWhenOccupied = true;
                  unfocusedIconsOpacity = 1;
                }
              ];
              right = [
                {
                  blacklist = [ ];
                  chevronColor = "none";
                  colorizeIcons = false;
                  drawerEnabled = true;
                  hidePassive = false;
                  id = "Tray";
                  pinned = [
                    "Microsoft Teams"
                    "You have 1 notification"
                  ];
                }
                {
                  hideWhenZero = false;
                  hideWhenZeroUnread = false;
                  iconColor = "none";
                  id = "NotificationHistory";
                  showUnreadBadge = false;
                  unreadBadgeColor = "primary";
                }
                {
                  id = "plugin:tailscale";
                }
                {
                  id = "plugin:timer";
                }
                {
                  deviceNativePath = "__default__";
                  displayMode = "graphic";
                  hideIfIdle = false;
                  hideIfNotDetected = true;
                  id = "Battery";
                  showNoctaliaPerformance = true;
                  showPowerProfiles = true;
                }
                {
                  displayMode = "alwaysShow";
                  iconColor = "secondary";
                  id = "Volume";
                  middleClickCommand = "pwvucontrol || pavucontrol";
                  textColor = "secondary";
                }
                {
                  displayMode = "alwaysHide";
                  iconColor = "none";
                  id = "Microphone";
                  middleClickCommand = "pwvucontrol || pavucontrol";
                  textColor = "none";
                }
                {
                  applyToAllMonitors = false;
                  displayMode = "alwaysShow";
                  iconColor = "primary";
                  id = "Brightness";
                  textColor = "primary";
                }
                {
                  colorizeDistroLogo = false;
                  colorizeSystemIcon = "none";
                  customIconPath = "";
                  enableColorization = false;
                  icon = "noctalia";
                  id = "ControlCenter";
                  useDistroLogo = false;
                }
              ];
            };
            screenOverrides = [ ];
          };
          general = {
            avatarImage = "/home/walawren/.face";
            dimmerOpacity = 0.2;
            showScreenCorners = false;
            forceBlackScreenCorners = false;
            scaleRatio = 1;
            radiusRatio = 1;
            iRadiusRatio = 1;
            boxRadiusRatio = 1;
            screenRadiusRatio = 1;
            animationSpeed = 1;
            animationDisabled = false;
            compactLockScreen = false;
            lockScreenAnimations = true;
            lockOnSuspend = true;
            showSessionButtonsOnLockScreen = true;
            showHibernateOnLockScreen = false;
            enableShadows = true;
            shadowDirection = "bottom_right";
            shadowOffsetX = 2;
            shadowOffsetY = 3;
            language = "";
            allowPanelsOnScreenWithoutBar = true;
            showChangelogOnStartup = true;
            telemetryEnabled = false;
            enableLockScreenCountdown = true;
            lockScreenCountdownDuration = 10000;
            autoStartAuth = true;
            allowPasswordWithFprintd = true;
            clockStyle = "custom";
            clockFormat = "hh\\nmm";
            passwordChars = false;
            lockScreenMonitors = [ ];
            lockScreenBlur = 0;
            lockScreenTint = 0.2;
            keybinds = {
              keyUp = [ "Up" ];
              keyDown = [ "Down" ];
              keyLeft = [ "Left" ];
              keyRight = [ "Right" ];
              keyEnter = [ "Return" ];
              keyEscape = [ "Esc" ];
              keyRemove = [ "Del" ];
            };
            reverseScroll = false;
          };
          ui = {
            fontDefault = "Sans Serif";
            fontFixed = "monospace";
            fontDefaultScale = 1;
            fontFixedScale = 1;
            tooltipsEnabled = true;
            boxBorderEnabled = false;
            panelBackgroundOpacity = 0.93;
            panelsAttachedToBar = true;
            settingsPanelMode = "attached";
            settingsPanelSideBarCardStyle = false;
          };
          location = {
            name = "Tokyo";
            weatherEnabled = false;
            weatherShowEffects = true;
            useFahrenheit = false;
            use12hourFormat = false;
            showWeekNumberInCalendar = false;
            showCalendarEvents = true;
            showCalendarWeather = true;
            analogClockInCalendar = false;
            firstDayOfWeek = -1;
            hideWeatherTimezone = false;
            hideWeatherCityName = false;
          };
          calendar = {
            cards = [
              {
                enabled = true;
                id = "calendar-header-card";
              }
              {
                enabled = true;
                id = "calendar-month-card";
              }
              {
                enabled = false;
                id = "weather-card";
              }
            ];
          };
          wallpaper = {
            enabled = true;
            overviewEnabled = false;
            directory = "/home/walawren/Pictures/Wallpapers";
            monitorDirectories = [ ];
            enableMultiMonitorDirectories = false;
            showHiddenFiles = false;
            viewMode = "single";
            setWallpaperOnAllMonitors = true;
            fillMode = "crop";
            fillColor = "#000000";
            useSolidColor = false;
            solidColor = "#1a1a2e";
            automationEnabled = false;
            wallpaperChangeMode = "random";
            randomIntervalSec = 300;
            transitionDuration = 1500;
            transitionType = "random";
            skipStartupTransition = false;
            transitionEdgeSmoothness = 0.05;
            panelPosition = "follow_bar";
            hideWallpaperFilenames = false;
            overviewBlur = 0.4;
            overviewTint = 0.6;
            useWallhaven = false;
            wallhavenQuery = "";
            wallhavenSorting = "relevance";
            wallhavenOrder = "desc";
            wallhavenCategories = "111";
            wallhavenPurity = "100";
            wallhavenRatios = "";
            wallhavenApiKey = "";
            wallhavenResolutionMode = "atleast";
            wallhavenResolutionWidth = "";
            wallhavenResolutionHeight = "";
            sortOrder = "name";
            favorites = [ ];
          };
          appLauncher = {
            enableClipboardHistory = true;
            autoPasteClipboard = false;
            enableClipPreview = true;
            clipboardWrapText = true;
            clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
            clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
            position = "center";
            pinnedApps = [ ];
            useApp2Unit = false;
            sortByMostUsed = true;
            terminalCommand = "kitty -e";
            customLaunchPrefixEnabled = false;
            customLaunchPrefix = "";
            viewMode = "list";
            showCategories = true;
            iconMode = "tabler";
            showIconBackground = false;
            enableSettingsSearch = true;
            enableWindowsSearch = true;
            enableSessionSearch = true;
            ignoreMouseInput = false;
            screenshotAnnotationTool = "satty -f -";
            overviewLayer = true;
            density = "default";
          };
          controlCenter = {
            position = "close_to_bar_button";
            diskPath = "/";
            shortcuts = {
              left = [
                { id = "Network"; }
                { id = "Bluetooth"; }
                { id = "WallpaperSelector"; }
                { id = "NoctaliaPerformance"; }
              ];
              right = [
                { id = "Notifications"; }
                { id = "PowerProfile"; }
                { id = "KeepAwake"; }
                { id = "NightLight"; }
              ];
            };
            cards = [
              {
                enabled = true;
                id = "profile-card";
              }
              {
                enabled = true;
                id = "shortcuts-card";
              }
              {
                enabled = true;
                id = "audio-card";
              }
              {
                enabled = false;
                id = "brightness-card";
              }
              {
                enabled = true;
                id = "weather-card";
              }
              {
                enabled = true;
                id = "media-sysmon-card";
              }
            ];
          };
          systemMonitor = {
            cpuWarningThreshold = 80;
            cpuCriticalThreshold = 90;
            tempWarningThreshold = 80;
            tempCriticalThreshold = 90;
            gpuWarningThreshold = 80;
            gpuCriticalThreshold = 90;
            memWarningThreshold = 80;
            memCriticalThreshold = 90;
            swapWarningThreshold = 80;
            swapCriticalThreshold = 90;
            diskWarningThreshold = 80;
            diskCriticalThreshold = 90;
            diskAvailWarningThreshold = 20;
            diskAvailCriticalThreshold = 10;
            batteryWarningThreshold = 20;
            batteryCriticalThreshold = 5;
            enableDgpuMonitoring = false;
            useCustomColors = false;
            warningColor = "#94e2d5";
            criticalColor = "#f38ba8";
            externalMonitor = "btop";
          };
          dock = {
            enabled = true;
            position = "bottom";
            displayMode = "auto_hide";
            dockType = "floating";
            backgroundOpacity = 0.75;
            floatingRatio = 1;
            size = 1;
            onlySameOutput = true;
            monitors = [ ];
            pinnedApps = [ ];
            colorizeIcons = false;
            showLauncherIcon = false;
            launcherPosition = "end";
            launcherIconColor = "none";
            pinnedStatic = false;
            inactiveIndicators = false;
            groupApps = false;
            groupContextMenuMode = "extended";
            groupClickAction = "cycle";
            groupIndicatorStyle = "dots";
            deadOpacity = 0.6;
            animationSpeed = 2;
            sitOnFrame = false;
            showFrameIndicator = true;
          };
          network = {
            wifiEnabled = true;
            airplaneModeEnabled = false;
            bluetoothRssiPollingEnabled = false;
            bluetoothRssiPollIntervalMs = 60000;
            networkPanelView = "wifi";
            wifiDetailsViewMode = "grid";
            bluetoothDetailsViewMode = "grid";
            bluetoothHideUnnamedDevices = false;
            disableDiscoverability = false;
          };
          sessionMenu = {
            enableCountdown = false;
            countdownDuration = 5000;
            position = "center";
            showHeader = true;
            showKeybinds = true;
            largeButtonsStyle = false;
            largeButtonsLayout = "grid";
            powerOptions = [
              {
                action = "lock";
                command = "";
                countdownEnabled = true;
                enabled = false;
                keybind = "1";
              }
              {
                action = "suspend";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "2";
              }
              {
                action = "hibernate";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "3";
              }
              {
                action = "reboot";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "4";
              }
              {
                action = "logout";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "5";
              }
              {
                action = "shutdown";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "6";
              }
              {
                action = "rebootToUefi";
                command = "";
                countdownEnabled = true;
                enabled = true;
                keybind = "7";
              }
            ];
          };
          notifications = {
            enabled = true;
            enableMarkdown = true;
            density = "default";
            monitors = [ ];
            location = "bottom_right";
            overlayLayer = true;
            backgroundOpacity = 1;
            respectExpireTimeout = true;
            lowUrgencyDuration = 3;
            normalUrgencyDuration = 8;
            criticalUrgencyDuration = 15;
            clearDismissed = true;
            saveToHistory = {
              low = false;
              normal = true;
              critical = true;
            };
            sounds = {
              enabled = false;
              volume = 0.5;
              separateSounds = false;
              criticalSoundFile = "";
              normalSoundFile = "";
              lowSoundFile = "";
              excludedApps = "discord,firefox,chrome,chromium,edge,slack,teams";
            };
            enableMediaToast = false;
            enableKeyboardLayoutToast = true;
            enableBatteryToast = true;
          };
          osd = {
            enabled = true;
            location = "top_right";
            autoHideMs = 2000;
            overlayLayer = true;
            backgroundOpacity = 1;
            enabledTypes = [
              0
              1
              2
            ];
            monitors = [ ];
          };
          audio = {
            volumeStep = 5;
            volumeOverdrive = false;
            cavaFrameRate = 30;
            visualizerType = "linear";
            mprisBlacklist = [ ];
            preferredPlayer = "";
            volumeFeedback = false;
            volumeFeedbackSoundFile = "";
          };
          brightness = {
            brightnessStep = 5;
            enforceMinimum = true;
            enableDdcSupport = false;
            backlightDeviceMappings = [ ];
          };
          colorSchemes = {
            useWallpaperColors = false;
            predefinedScheme = "Catppuccin";
            darkMode = true;
            schedulingMode = "off";
            manualSunrise = "06:30";
            manualSunset = "18:30";
            generationMethod = "tonal-spot";
            monitorForColors = "";
          };
          templates = {
            activeTemplates = [ ];
            enableUserTheming = false;
          };
          nightLight = {
            enabled = false;
            forced = false;
            autoSchedule = true;
            nightTemp = "4000";
            dayTemp = "6500";
            manualSunrise = "06:30";
            manualSunset = "18:30";
          };
          hooks = {
            enabled = false;
            wallpaperChange = "";
            darkModeChange = "";
            screenLock = "";
            screenUnlock = "";
            performanceModeEnabled = "";
            performanceModeDisabled = "";
            startup = "";
            session = "";
          };
          plugins = {
            autoUpdate = true;
          };
          idle = {
            enabled = true;
            screenOffTimeout = 300;
            lockTimeout = 330;
            suspendTimeout = 1800;
            fadeDuration = 5;
            customCommands = "[]";
          };
          desktopWidgets = {
            enabled = true;
            overviewEnabled = true;
            gridSnap = false;
            monitorWidgets = [
              {
                name = "eDP-1";
                widgets = [
                  {
                    hideMode = "idle";
                    id = "MediaPlayer";
                    roundedCorners = true;
                    showAlbumArt = true;
                    showBackground = true;
                    showButtons = true;
                    showVisualizer = true;
                    visualizerType = "wave";
                    x = 20;
                    y = 860;
                  }
                  {
                    diskPath = "/";
                    id = "SystemStat";
                    layout = "bottom";
                    roundedCorners = true;
                    scale = 1;
                    showBackground = true;
                    statType = "CPU";
                    x = 20;
                    y = 60;
                  }
                ];
              }
            ];
          };
        };
      };
    };
}
