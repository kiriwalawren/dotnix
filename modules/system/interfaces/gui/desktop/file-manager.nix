{
  flake.modules.homeManager.gui = { pkgs, ... }: {
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
        plugin =
          let
            mediainfoRules = [
              # Replace magick, image, video with mediainfo.
              # Also covers Adobe Photoshop (image/adobe.photoshop) and image/x-eps
              {
                mime = "{audio,video,image}/*";
                run = "mediainfo";
              }
              # Subtitles, plus Adobe Illustrator / EPS variants
              {
                mime = "application/{subrip,postscript,illustrator,dvb.ait,vnd.adobe.illustrator,eps}";
                run = "mediainfo";
              }
              # Sometimes AI file is recognized as "application/pdf". Lmao.
              # In this case use file extension instead:
              {
                url = "*.{ai,eps,ait}";
                run = "mediainfo";
              }
            ];
          in
          {
            # Yazi caps preloaders at 16 *including* its 8 built-in ones, so keep these rules merged.
            prepend_preloaders = mediainfoRules;
            prepend_previewers = mediainfoRules;
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
