{
  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.qimgv
      ];
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "image/png" = "qimgv.desktop";
          "image/jpeg" = "qimgv.desktop";
          "image/gif" = "qimgv.desktop";
          "image/webp" = "qimgv.desktop";
          "image/tiff" = "qimgv.desktop";
          "image/bmp" = "qimgv.desktop";
          "image/svg+xml" = "qimgv.desktop";
          "image/x-sony-arw" = "qimgv.desktop";
          "image/x-dcraw" = "qimgv.desktop";
        };
      };
    };
}
