{
  flake.modules.homeManager.gui =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.unzip
        pkgs.imagemagick # must be built with jp2/raw support
        pkgs.libraw # for ARW (Sony RAW)
        pkgs.openjpeg # for JP2
        pkgs.mediainfo
      ];

      programs.yazi = {
        enable = true;
        shellWrapperName = "y";

        plugins = {
          inherit (pkgs.yaziPlugins)
            chmod
            clipboard
            git
            mediainfo
            mount
            smart-enter
            ;
        };

        settings = {
          plugin = {
            prepend_preloaders = [
              # Replace magick, image, video with mediainfo
              {
                mime = "{audio,video,image}/*";
                run = "mediainfo";
              }
              {
                mime = "application/subrip";
                run = "mediainfo";
              }

              # Adobe Photoshop is image/adobe.photoshop, already handled above
              # Adobe Illustrator
              {
                mime = "application/postscript";
                run = "mediainfo";
              }
              {
                mime = "application/illustrator";
                run = "mediainfo";
              }
              {
                mime = "application/dvb.ait";
                run = "mediainfo";
              }
              {
                mime = "application/vnd.adobe.illustrator";
                run = "mediainfo";
              }
              {
                mime = "image/x-eps";
                run = "mediainfo";
              }
              {
                mime = "application/eps";
                run = "mediainfo";
              }

              # Sometimes AI file is recognized as "application/pdf". Lmao.
              # In this case use file extension instead:
              {
                url = "*.{ai,eps,ait}";
                run = "mediainfo";
              }
            ];

            prepend_previewers = [
              # Replace magick, image, video with mediainfo
              {
                mime = "{audio,video,image}/*";
                run = "mediainfo";
              }
              {
                mime = "application/subrip";
                run = "mediainfo";
              }

              # Adobe Photoshop is image/adobe.photoshop, already handled above
              # Adobe Illustrator
              {
                mime = "application/postscript";
                run = "mediainfo";
              }
              {
                mime = "application/illustrator";
                run = "mediainfo";
              }
              {
                mime = "application/dvb.ait";
                run = "mediainfo";
              }
              {
                mime = "application/vnd.adobe.illustrator";
                run = "mediainfo";
              }
              {
                mime = "image/x-eps";
                run = "mediainfo";
              }
              {
                mime = "application/eps";
                run = "mediainfo";
              }

              # Sometimes AI file is recognized as "application/pdf". Lmao.
              # In this case use file extension instead:
              {
                url = "*.{ai,eps,ait}";
                run = "mediainfo";
              }
            ];
          };

          tasks = {
            image_alloc = 1073741824; # 1024MB
          };
        };

        keymap = {
          mgr.prepend_keymap = [
            {
              on = "l";
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            }
            {
              on = "<Enter>";
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            }
            {
              on = "m";
              run = "plugin mount";
              desc = "Open mount manager";
            }
            {
              on = [
                "c"
                "m"
              ];
              run = "plugin chmod";
              desc = "Chmod on selected files";
            }
          ];
        };
      };
    };
}
