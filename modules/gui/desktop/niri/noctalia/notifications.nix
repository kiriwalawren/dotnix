{
  flake.modules.homeManager.niri = {
    programs.noctalia-shell.settings.notifications = {
      enabled = true;
      enableMarkdown = true;
      density = "default";
      monitors = [ ];
      location = "bottom_right";
      overlayLayer = true;
      backgroundOpacity = .85;
      respectExpireTimeout = true;
      lowUrgencyDuration = 3;
      normalUrgencyDuration = 8;
      criticalUrgencyDuration = 15;
      clearDismissed = true;
      saveToHistory = {
        low = true;
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
  };
}
