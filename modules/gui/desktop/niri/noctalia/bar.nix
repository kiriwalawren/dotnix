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
              labelMode = "none";
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
              iconColor = "error";
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
    };
}
