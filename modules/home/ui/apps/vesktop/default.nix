{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ui.apps.vesktop;
in {
  options.ui.apps.vesktop = {enable = mkEnableOption "vesktop";};

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.vesktop
    ];

    xdg.configFile = {
      "vesktop/themes/Catppuccin.theme.css".source = ./theme.css;

      "vesktop/settings.json".text = builtins.toJSON {
        discordBranch = "stable";
        firstLaunch = false;
        arRPC = "on";
        splashColor = "rgb(219, 222, 225)";
        splashBackground = "rgb(49, 51, 56)";
        minimizeToTray = false;
      };

      "vesktop/settings/settings.json".text = builtins.toJSON {
        notifyAboutUpdates = false;
        autoUpdate = false;
        autoUpdateNotification = false;
        useQuickCss = true;
        themeLinks = [];
        enabledThemes = ["Catppuccin.theme.css"];
        enableReactDevtools = true;
        frameless = false;
        transparent = true;
        winCtrlQ = false;
        macosTranslucency = false;
        disableMinSize = false;
        winNativeTitleBar = false;

        plugins = {
          BadgeAPI.enabled = true;
          ChatInputButtonAPI.enabled = false;
          CommandsAPI.enabled = true;
          ContextMenuAPI.enabled = true;
          MemberListDecoratorsAPI.enabled = false;
          MessageAccessoriesAPI.enabled = false;
          MessageDecorationsAPI.enabled = false;
          MessageEventsAPI.enabled = false;
          MessagePopoverAPI.enabled = false;
          NoticesAPI.enabled = true;
          ServerListAPI.enabled = false;
          NoTrack.enabled = true;
          Settings.enabled = true;
          SupportHelper.enabled = true;
        };

        notifications = {
          timeout = 5000;
          position = "bottom-right";
          useNative = "not-focused";
          logLimit = 50;
        };
        cloud = {
          authenticated = false;
          url = "https://api.vencord.dev/";
          settingsSync = false;
          settingsSyncVersion = 1682768329526;
        };
      };
    };
  };
}
