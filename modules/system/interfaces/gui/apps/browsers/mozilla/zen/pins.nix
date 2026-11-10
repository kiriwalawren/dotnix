{
  # ⚠ close Zen before home-manager switch
  # (activation script needs exclusive access to modify zen-sessions.jsonlz4)
  flake.modules.homeManager.gui.programs.zen-browser.profiles.default = {
    pinsForce = true;
    pinsForceAction = "remove";
    pins = {
      "Proton Email" = {
        id = "4c2d5fe0-0e56-426b-adb6-143e2fa72812";
        url = "https://mail.proton.me";
        position = 101;
        isEssential = true;
      };
      "Proton Calendar" = {
        id = "eec6abd9-c990-4196-a570-c94034fed9ea";
        url = "https://calendar.proton.me";
        position = 102;
        isEssential = true;
      };
      "Outlook Email" = {
        id = "8a00e3af-6992-40ba-9dfc-3bd6ec0ea8f5";
        url = "https://outlook.cloud.microsoft/mail";
        position = 103;
        isEssential = true;
      };
      "Clickup" = {
        id = "49a5bb94-8908-4924-b33f-2947ed59159b";
        url = "https://app.clickup.com/9014274601/v/b/f/90147170756";
        position = 104;
        isEssential = true;
      };
      "WhatsApp" = {
        id = "8104649d-57fe-4b2f-9dab-ab60188dbca1";
        url = "https://web.whatsapp.com";
        position = 105;
        isEssential = true;
      };
      "Google Messages" = {
        id = "43e1b199-15ea-4096-aa48-33b726ddd359";
        url = "https://messages.google.com/web/conversations";
        position = 106;
        isEssential = true;
      };
      "dotnix" = {
        id = "e3887fbb-e1cb-4c9f-b93f-9a873aa31fac";
        url = "https://github.com/kiriwalawren/dotnix";
        position = 200;
      };
      "Nixflix" = {
        id = "585c6dde-90de-4f6d-9283-507a0f2e7444";
        url = "https://github.com/kiriwalawren/nixflix";
        position = 201;
      };
      "Eimer" = {
        id = "44dfd919-935c-4cc4-b549-9ca82a271f83";
        url = "https://github.com/FreeWaveTechnologies/eimer";
        position = 202;
      };
    };
  };
}
