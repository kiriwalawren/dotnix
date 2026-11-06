# A toggleable, click-through overlay showing the active kanata layout,
# implemented as a Nix-built Noctalia plugin (a `[[layer]]` surface).
{ lib, self, ... }:
let
  keyboard = import ../../system/interfaces/kanata/_keyboard.nix { inherit lib; };

  pluginId = "dotnix/keymap";
in
{
  flake.wrappers.noctalia =
    { pkgs, ... }:
    let
      # Follows kanata: it sends the current layer as a `LayerChange` on
      # connect, then broadcasts every layer change. Reconnects if kanata restarts.
      layerStream = "while :; do ${pkgs.socat}/bin/socat -u TCP:127.0.0.1:${toString keyboard.port} STDOUT; sleep 2; done";

      generated = {
        order = keyboard.layers;
        stream = layerStream;
        labels = lib.genAttrs keyboard.layers (layer: map (map (k: k.${layer})) keyboard.rows);
      };

      manifest = ''
        id          = "${pluginId}"
        name        = "Keymap"
        version     = "1.0.0"
        plugin_api  = 43
        author      = "dotnix"
        description = "Toggleable overlay of the active kanata layout."

        [[service]]
        id    = "service"
        entry = "service.luau"

        [[layer]]
        id            = "overlay"
        entry         = "overlay.luau"
        layer         = "overlay"
        anchors       = ["bottom"]
        margins       = { bottom = 48 }
        keyboard      = "none"
        click_through = true
        output        = "focused"
      '';

      service = ''
        --!nonstrict
        local generated = require("./generated.luau")
        local visible = false

        noctalia.runStream(generated.stream, function(line)
          local msg = noctalia.json.decode(line)
          if msg and msg.LayerChange then
            noctalia.state.set("layer", msg.LayerChange.new)
          end
        end)

        function onIpc(event, payload)
          if event == "toggle" then
            visible = not visible
          elseif event == "show" then
            visible = true
          elseif event == "hide" then
            visible = false
          else
            return
          end

          if visible then
            noctalia.layer.show("overlay")
          else
            noctalia.layer.hide("overlay")
          end
        end
      '';

      overlay = ''
        --!nonstrict
        local generated = require("./generated.luau")

        local KEY = 40
        local GAP = 4
        -- Row stagger, roughly matching a physical keyboard
        local OFFSETS = { 0, 22, 33, 55 }

        local function keycap(label)
          return ui.column({
            width = KEY,
            height = KEY,
            radius = 6,
            fill = "surface_container_high/0.85",
            align = "center",
            justify = "center",
            gap = 0,
          }, {
            ui.label({ text = label[2], fontSize = 10, color = "on_surface/0.6" }),
            ui.label({ text = label[1], fontSize = 15, fontWeight = "bold", color = "on_surface" }),
          })
        end

        local function render(name)
          if generated.labels[name] == nil then
            name = generated.order[1]
          end

          local children = {
            ui.label({ text = name, fontSize = 12, fontWeight = "bold", color = "primary" }),
          }

          for i, row in ipairs(generated.labels[name]) do
            local keys = { ui.box({ width = OFFSETS[i], height = KEY }) }
            for _, label in ipairs(row) do
              table.insert(keys, keycap(label))
            end
            table.insert(children, ui.row({ gap = GAP }, keys))
          end

          layer.render(ui.column({ gap = GAP, padding = 12, radius = 14, fill = "surface/0.6" }, children))
        end

        render(noctalia.state.get("layer"))
        noctalia.state.watch("layer", render)
      '';

      plugin = pkgs.runCommand "noctalia-plugin-keymap" { } ''
        dir=$out/keymap
        mkdir -p $dir
        cp ${pkgs.writeText "plugin.toml" manifest} $dir/plugin.toml
        cp ${pkgs.writeText "service.luau" service} $dir/service.luau
        cp ${pkgs.writeText "overlay.luau" overlay} $dir/overlay.luau
        cp ${pkgs.writeText "generated.luau" "return ${lib.generators.toLua { } generated}\n"} $dir/generated.luau
      '';
    in
    {
      settings.plugins = {
        enabled = [ pluginId ];
        source = [
          {
            name = "dotnix";
            kind = "path";
            location = "${plugin}";
            enabled = true;
          }
        ];
      };
    };

  flake.wrappers.niri = { pkgs, ... }: {
    settings.binds."Mod+O".spawn = [
      (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia)
      "msg"
      "plugin"
      "${pluginId}:service"
      "all"
      "toggle"
    ];
  };
}
