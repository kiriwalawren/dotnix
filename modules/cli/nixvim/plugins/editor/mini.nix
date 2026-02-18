{
  flake.modules.nixvim.base.plugins = {
    web-devicons.enable = true;

    mini = {
      enable = true;

      modules = {
        comment = { };
      };
    };
  };
}
