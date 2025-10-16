{
  lib,
  config,
  pkgs,
  theme,
  ...
}:
with lib; let
  cfg = config.ui.nixos.impala-launcher;

  impalaLauncher = pkgs.writeShellScriptBin "impala-launcher" ''
    # Clear screen and show help
    clear

    # Catppuccin Mocha color codes (converted to ANSI escape codes)
    TEAL='\033[38;2;148;226;213m'      # ${theme.colors.teal}
    MAUVE='\033[38;2;203;166;247m'     # ${theme.colors.mauve}
    LAVENDER='\033[38;2;180;190;254m'  # ${theme.colors.lavender}
    BLUE='\033[38;2;137;180;250m'      # ${theme.colors.blue}
    TEXT='\033[38;2;205;214;244m'      # ${theme.colors.text}
    SUBTEXT='\033[38;2;166;173;200m'   # ${theme.colors.subtext0}
    NC='\033[0m' # No Color

    # Get terminal dimensions
    TERM_HEIGHT=$(${pkgs.ncurses}/bin/tput lines)
    TERM_WIDTH=$(${pkgs.ncurses}/bin/tput cols)

    # Box dimensions (26 lines for box + 2 lines spacing + 1 prompt)
    BOX_HEIGHT=28
    BOX_WIDTH=62

    # Calculate starting position to center the box
    START_ROW=$(( (TERM_HEIGHT - BOX_HEIGHT) / 2 ))
    START_COL=$(( (TERM_WIDTH - BOX_WIDTH) / 2 ))

    # Ensure we don't go negative
    [ $START_ROW -lt 0 ] && START_ROW=0
    [ $START_COL -lt 0 ] && START_COL=0

    # Function to move cursor and print
    print_at() {
      local row=$1
      local col=$2
      shift 2
      ${pkgs.ncurses}/bin/tput cup $row $col
      echo -e "$@"
    }

    # Clear screen and hide cursor
    clear
    ${pkgs.ncurses}/bin/tput civis

    # Print centered box
    print_at $((START_ROW + 0)) $START_COL "''${LAVENDER}╔════════════════════════════════════════════════════════════╗''${NC}"
    print_at $((START_ROW + 1)) $START_COL "''${LAVENDER}║''${NC}              ''${TEAL}Impala WiFi Manager''${NC} - Keyboard Shortcuts      ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 2)) $START_COL "''${LAVENDER}╠════════════════════════════════════════════════════════════╣''${NC}"
    print_at $((START_ROW + 3)) $START_COL "''${LAVENDER}║''${NC} ''${MAUVE}Navigation:''${NC}                                                ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 4)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}Tab / Shift+Tab''${NC}    Switch between sections               ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 5)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}j / Down''${NC}           Scroll down                           ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 6)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}k / Up''${NC}             Scroll up                             ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 7)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}?''${NC}                  Show help                             ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 8)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}Esc''${NC}                Dismiss pop-ups                       ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 9)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}q / Ctrl+C''${NC}         Quit                                  ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 10)) $START_COL "''${LAVENDER}║''${NC}                                                            ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 11)) $START_COL "''${LAVENDER}║''${NC} ''${MAUVE}Device & Adapter:''${NC}                                          ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 12)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}Ctrl+R''${NC}             Switch adapter mode (Station/AP)      ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 13)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}i''${NC}                  Show device information               ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 14)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}o''${NC}                  Toggle device power                   ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 15)) $START_COL "''${LAVENDER}║''${NC}                                                            ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 16)) $START_COL "''${LAVENDER}║''${NC} ''${BLUE}Station Mode:''${NC}                                              ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 17)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}s''${NC}                  Start scanning                        ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 18)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}Space''${NC}              Connect/Disconnect network            ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 19)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}a''${NC}                  Toggle auto-connect                   ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 20)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}d''${NC}                  Remove from known networks            ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 21)) $START_COL "''${LAVENDER}║''${NC}                                                            ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 22)) $START_COL "''${LAVENDER}║''${NC} ''${BLUE}Access Point Mode:''${NC}                                         ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 23)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}n''${NC}                  Start new access point                ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 24)) $START_COL "''${LAVENDER}║''${NC}   ''${SUBTEXT}x''${NC}                  Stop running access point             ''${LAVENDER}║''${NC}"
    print_at $((START_ROW + 25)) $START_COL "''${LAVENDER}╚════════════════════════════════════════════════════════════╝''${NC}"
    print_at $((START_ROW + 27)) $START_COL "''${TEAL}Press any key to launch Impala...''${NC}"

    # Wait for key press and restore cursor
    read -n 1 -s
    ${pkgs.ncurses}/bin/tput cnorm

    # Launch impala
    exec ${pkgs.impala}/bin/impala
  '';
in {
  options.ui.nixos.impala-launcher = {
    enable = mkEnableOption "impala-launcher";
  };

  config = mkIf cfg.enable {
    home.packages = [impalaLauncher];

    # Waybar integration - override the network on-click
    programs.waybar.settings.mainBar.network.on-click = "pkill impala || ${pkgs.kitty}/bin/kitty --class=impala impala-launcher";
  };
}
