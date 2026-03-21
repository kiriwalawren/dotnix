{
  perSystem =
    { pkgs, ... }:
    let
      jq = "${pkgs.jq}/bin/jq";
      pwDump = "${pkgs.pipewire}/bin/pw-dump";
      wpctl = "${pkgs.wireplumber}/bin/wpctl";
      inputNodeIds = ''${pwDump} | ${jq} -r '.[] | select(.type == "PipeWire:Interface:Node") | select(.info.props["media.class"] // "" | test("^Audio/Source|^Stream/Input/Audio")) | .id' '';
    in
    {
      packages.unmutemic = pkgs.writeShellScriptBin "unmutemic" ''
        ${inputNodeIds} | while read -r id; do
          ${wpctl} set-mute "$id" 0
        done
      '';
      packages.mutemic = pkgs.writeShellScriptBin "mutemic" ''
        ${inputNodeIds} | while read -r id; do
          ${wpctl} set-mute "$id" 1
        done
      '';
      packages.togglemic = pkgs.writeShellScriptBin "togglemic" ''
        ${inputNodeIds} | while read -r id; do
          ${wpctl} set-mute "$id" toggle
        done
      '';
      packages.sync-input-mute = pkgs.writeShellScriptBin "sync-input-mute" ''
        if ${wpctl} get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
          MUTE=1
        else
          MUTE=0
        fi
        ${inputNodeIds} | while read -r id; do
          ${wpctl} set-mute "$id" "$MUTE"
        done
      '';
    };
}
