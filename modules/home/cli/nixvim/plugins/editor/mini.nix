{
  programs.nixvim.plugins = {
    web-devicons.enable = true;

    mini = {
      enable = true;

      modules = {
        comment = { };
      };
    };
  };
}
