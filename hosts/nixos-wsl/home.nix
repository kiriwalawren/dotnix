{ config, pkgs, lib, ... }:

{
  imports = [ ../../modules/home ];

  home.username = "nixos";
  home.homeDirectory = "/home/nixos";

  modules.headless.enable = true;
}
