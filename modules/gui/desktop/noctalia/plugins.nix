{
  flake.wrappers.noctalia.settings = {
    plugins = {
      enabled = [
        "davemhammer/tailscale"
        "noctalia/timer"
        "noctalia/translator"
      ];
      auto_update = "all";

      # Declaring any source replaces Noctalia's built-in defaults, so they are
      # listed explicitly here (other modules append their own sources).
      source = [
        {
          name = "official";
          kind = "git";
          location = "https://github.com/noctalia-dev/official-plugins";
          enabled = true;
        }
        {
          name = "community";
          kind = "git";
          location = "https://github.com/noctalia-dev/community-plugins";
          enabled = true;
        }
      ];
    };

    plugin_settings = {
      "davemhammer/tailscale" = {
        refresh_interval = 5; # seconds
        ssh_user = "";
        admin_url = "https://headscale.walawren.com";
      };
    };
  };
}
