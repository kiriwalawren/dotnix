{
  flake.modules.nixvim.base.plugins = {
    conform-nvim.settings = {
      formatters.yamlfmt = {
        prepend_args = [
          "-formatter"
          "retain_line_breaks=true"
        ];
      };

      formatters_by_ft.yaml = [ "yamlfmt" ];
    };
  };
}
