{ config }:
with builtins;
let
  radius = "${toString config.theme.radius}px";
in
with config.catppuccin.colors;
''
  * {
    border: none;
    font-family: "${config.theme.font}";
    font-size: ${toString config.theme.fontSizeSmall}px;
    margin: 0px;
    padding: 0px;
  }

  #window {
    background-color: transparent;
    box-shadow: none;
  }

  window#waybar {
    background-color: transparent;
    border-radius: 0px;
  }

  window * {
    background-color: transparent;
    border-radius: 0px;
  }

  #clock,
  #cpu,
  #memory,
  #disk,
  #network,
  #battery,
  #pulseaudio,
  #window,
  #tray,
  #bluetooth,
  #power-profiles-daemon {
    border-radius: ${radius};
    background: #${base};
    color: #${primaryAccent};
    margin-left: 2px;
    margin-right: 2px;
    margin: 0px 2px;
    padding: 0px 15px;
    transition: all 0.3s ease;
    font-weight: bold;
  }

  #clock {
    color: #${tertiaryAccent};
  }

  #cpu {
    color: #${secondaryAccent};
  }

  #memory {
    color: #${yellow};
  }

  #pulseaudio {
    color: #${rosewater};
  }

  #network {
    color: #${lavender};
  }

  #battery {
    color: #${green};
    margin-right: 10px;
  }

  #battery.warning {
    color: #${yellow};
  }

  #battery.critical:not(.charging) {
    color: #${red};
  }

  #bluetooth {
    color: #${sky};
  }

  #power-profiles-daemon {
    color: #${peach};
  }

  #workspaces button label {
    color: #${secondaryAccent};
  }

  #workspaces button.active label {
    color: #${base};
    font-weight: bolder;
  }

  #workspaces button:hover {
    box-shadow: #${secondaryAccent} 0 0 0 1.5px;
    background-color: #${base};
    min-width: 35px;
  }

  #workspaces {
    background-color: transparent;
    border-radius: ${radius};
  }

  #workspaces button {
    background-color: #${base};
    border-radius: ${radius};
    margin-left: 10px;
    padding: 0px 10px;

    transition: all 0.3s ease;
  }

  #workspaces button.active {
    min-width: 35px;
    box-shadow: rgba(0, 0, 0, 0.288) 1px 1px 2px 2px;
    background-color: #${primaryAccent};
    background-size: 400% 400%;
    transition: all 0.3s ease-in-out;
    background-size: 300% 300%;
  }

  .modules-left,
  .modules-center,
  .modules-right {
    background-color: transparent;
    padding: 1px 0px;
    margin-top: 3px;
  }
''
