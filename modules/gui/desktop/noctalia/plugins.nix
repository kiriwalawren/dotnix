{
  flake.wrappers.noctalia.settings = {
    plugins = {
      enabled = [
        "davemhammer/tailscale"
        "noctalia/timer"
        "noctalia/translator"
      ];
      auto_update = "all";
    };

    plugin_settings = {
      "davemhammer/tailscale" = {
        refresh_interval = 5; # seconds
        ssh_user = "";
      };
    };
  };
}
