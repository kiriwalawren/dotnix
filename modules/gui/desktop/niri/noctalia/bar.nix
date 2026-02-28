{
  flake.modules.homeManager.niri =
    { lib, pkgs, ... }:
    {
      programs.noctalia-shell.settings.bar = {
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
              id = "Workspace";
              characterCount = 2;
              colorizeIcons = false;
              emptyColor = "secondary";
              enableScrollWheel = true;
              focusedColor = "primary";
              followFocusedScreen = false;
              groupedBorderOpacity = 1;
              hideUnoccupied = false;
              iconScale = 0.8;
              labelMode = "none";
              occupiedColor = "secondary";
              pillSize = 0.6;
              showApplications = false;
              showBadge = true;
              showLabelsOnlyWhenOccupied = true;
              unfocusedIconsOpacity = 1;
            }
            {
              id = "plugin:tailscale";
            }
            {
              id = "plugin:timer";
            }
            {
              id = "Clock";
              clockColor = "secondary";
              customFont = "";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              tooltipFormat = "HH:mm ddd, MMM dd";
              useCustomFont = false;
            }
            {
              id = "SystemMonitor";
              compactMode = true;
              diskPath = "/";
              iconColor = "primary";
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
              textColor = "primary";
              useMonospaceFont = true;
              usePadding = false;
            }
          ];
          center = [
            {
              id = "MediaMini";
              compactMode = true;
              compactShowAlbumArt = true;
              compactShowVisualizer = false;
              hideMode = "hidden";
              hideWhenIdle = false;
              maxWidth = 145;
              panelShowAlbumArt = true;
              panelShowVisualizer = true;
              scrollingMode = "hover";
              showAlbumArt = true;
              showArtistFirst = true;
              showProgressRing = true;
              showVisualizer = false;
              textColor = "tertiary";
              useFixedWidth = false;
              visualizerType = "linear";
            }
            {
              id = "AudioVisualizer";
              colorName = "tertiary";
              hideWhenIdle = true;
              width = 150;
            }
          ];
          right = [
            {
              id = "Tray";
              blacklist = [ ];
              chevronColor = "none";
              colorizeIcons = false;
              drawerEnabled = true;
              hidePassive = true;
              pinned = [
                "Microsoft Teams"
                "You have 1 notification"
                "Slack"
              ];
            }
            {
              id = "Network";
              displayMode = "alwaysHide";
              iconColor = "tertiary";
              textColor = "tertiary";
            }
            {
              id = "Bluetooth";
              displayMode = "alwaysHide";
              iconColor = "primary";
              textColor = "primary";
            }
            {
              id = "Volume";
              displayMode = "alwaysShow";
              iconColor = "secondary";
              middleClickCommand = "pkill wiremix || ${lib.getExe pkgs.kitty} --class=wiremix ${lib.getExe pkgs.wiremix}";
              textColor = "secondary";
            }
            {
              displayMode = "alwaysHide";
              iconColor = "tertiary";
              id = "Microphone";
              middleClickCommand = "pkill wiremix || ${lib.getExe pkgs.kitty} --class=wiremix ${lib.getExe pkgs.wiremix}";
              textColor = "none";
            }
            {
              id = "Brightness";
              applyToAllMonitors = false;
              displayMode = "alwaysShow";
              iconColor = "primary";
              textColor = "primary";
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
              id = "NotificationHistory";
              hideWhenZero = false;
              hideWhenZeroUnread = false;
              iconColor = "error";
              showUnreadBadge = false;
              unreadBadgeColor = "primary";
            }
            {
              id = "ControlCenter";
              colorizeDistroLogo = true;
              colorizeSystemIcon = "tertiary";
              customIconPath = "";
              enableColorization = true;
              icon = "noctalia";
              useDistroLogo = true;
            }
          ];
        };
        screenOverrides = [ ];
      };
    };
}
