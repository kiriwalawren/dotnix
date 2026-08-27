{
  flake.modules.homeManager.base = {
    programs.btop = {
      enable = true;
      settings.color_theme = "noctalia";
    };
  };
}
