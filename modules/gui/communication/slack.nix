{
  nixpkgs.config.allowUnfreePackages = [ "slack" ];

  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        slack
        wf-recorder
      ];
    };
}
