{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    gnome.gnome-calculator
    loupe
  ];
}
