{
  config,
  inputs,
  lib,
  ...
}:
with lib; let
  cfg = config.ui.apps.vesktop;

  inherit (inputs) catppuccin-discord;
  themeFileNames = builtins.attrNames (builtins.readDir "${catppuccin-discord}/themes");
  themeFileConfigs = builtins.listToAttrs (map (fileName: {
      name = ".config/vesktop/themes/${fileName}";
      value = {source = "${catppuccin-discord}/themes/${fileName}";};
    })
    themeFileNames);
in {
  options.ui.apps.vesktop = {enable = mkEnableOption "vesktop";};

  config = mkIf cfg.enable {
    home.file = themeFileConfigs;

    programs.vesktop = {
      enable = true;

      settings = {
        discordBranch = "stable";
        firstLaunch = false;
        arRPC = true;
        splashBackground = "#181825";
        splashColor = "#cdd6f4";
        minimizeToTray = false;
      };

      vencord.settings = {
        enabledThemes = ["mocha.theme.css"];
        notifyAboutUpdates = false;
        autoUpdate = false;
        autoUpdateNotification = false;
        useQuickCss = true;
        themeLinks = [];
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
