{
  flake.modules.nixvim.base =
    { pkgs, ... }:
    {
      extraPlugins = with pkgs.vimPlugins; [
        catppuccin-nvim
        nord-nvim
        gruvbox-nvim
        dracula-nvim
        tokyonight-nvim
        kanagawa-nvim
        rose-pine
        ayu-vim
        eldritch-nvim
        base16-nvim
      ];

      extraConfigLua = ''
        local noctalia_theme_state = vim.fn.expand("~/.config/nvim/current-scheme.json")
        local noctalia_theme_applied = nil

        local function noctalia_apply_theme()
          local ok, lines = pcall(vim.fn.readfile, noctalia_theme_state)
          if not ok or #lines == 0 then
            return
          end

          local raw = table.concat(lines, "\n")
          if raw == noctalia_theme_applied then
            return
          end

          local decode_ok, data = pcall(vim.json.decode, raw)
          if not decode_ok or type(data) ~= "table" then
            return
          end

          if data.mode == "curated" and data.name then
            pcall(vim.cmd.colorscheme, data.name)
          elseif data.mode == "generic" and data.colors then
            local base16_ok, base16 = pcall(require, "base16-colorscheme")
            if base16_ok then
              pcall(base16.setup, data.colors)
            end
          end

          noctalia_theme_applied = raw
        end

        noctalia_apply_theme()

        local noctalia_theme_timer = vim.uv.new_timer()
        noctalia_theme_timer:start(
          1500,
          1500,
          vim.schedule_wrap(noctalia_apply_theme)
        )
      '';
    };
}
