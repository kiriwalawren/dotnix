# A toggleable, click-through overlay showing the active kanata layout,
# implemented as a Nix-built Noctalia plugin (a `[[layer]]` surface).
{ lib, self, ... }:
let
  keyboard = import ../../../system/interfaces/kanata/_keyboard.nix { inherit lib; };

  pluginId = "dotnix/keymap";
in
{
  flake.wrappers.noctalia =
    { pkgs, ... }:
    let
      # Follows kanata: it sends the current layer as a `LayerChange` on
      # connect, then broadcasts every layer change. Reconnects if kanata restarts.
      # Loops only while Noctalia ($PPID) is alive: Noctalia kills the stream
      # when it stops it, but not when Noctalia itself exits, and an orphaned
      # loop reconnects every 2s forever. kanata leaks an fd per closed client,
      # so that eventually crashed it with "Too many open files".
      layerStream = "while kill -0 $PPID 2>/dev/null; do ${pkgs.socat}/bin/socat -u TCP:127.0.0.1:${toString keyboard.port} STDOUT; sleep 2; done";

      generated = {
        order = keyboard.layers;
        stream = layerStream;
        # Per layer: rows of `{ base, shifted, hold? }` labels
        labels = lib.genAttrs keyboard.layers (layer: map (map (k: k.${layer})) keyboard.rows);
        # Per layer: the space-bar row (keys outside the letter grid)
        extra = lib.genAttrs keyboard.layers (layer: map (k: k.${layer}) keyboard.extraKeys);
        # Held layers, laid out like `labels`; `false` = transparent (show the base layer's key)
        holds = lib.mapAttrs (
          _: mappings:
          map (map (
            k:
            if mappings ? ${k.src} then
              [
                mappings.${k.src}.label
                (mappings.${k.src}.sub or "")
              ]
            else
              false
          )) keyboard.rows
        ) keyboard.holdLayers;
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
        -- `pinned`: toggled on with Hyper+O (Mod+Ctrl+Alt+Shift+O). `holding`: a hold layer is active.
        -- The overlay shows while either is true.
        local pinned = false
        local holding = false

        -- Debounce the automatic pop-up: a hold layer must stay active this
        -- long before the overlay shows, so a hold that flickers on and off
        -- during a fast roll never flashes it. Hiding is immediate.
        local SHOW_DELAY_MS = 200
        local holdSince = nil -- nowMs() when the current hold started
        local shown = false

        local function apply()
          local want = pinned
            or (holding and holdSince ~= nil and noctalia.nowMs() - holdSince >= SHOW_DELAY_MS)
          if want ~= shown then
            shown = want
            if want then
              noctalia.layer.show("overlay")
            else
              noctalia.layer.hide("overlay")
            end
          end
        end

        -- Polls a pending hold; does nothing otherwise
        noctalia.setUpdateInterval(25)
        function update()
          if holding and not shown then
            apply()
          end
        end

        noctalia.runStream(generated.stream, function(line)
          local msg = noctalia.json.decode(line)
          if msg and msg.LayerChange then
            local name = msg.LayerChange.new
            -- kanata only reports the top layer; remember the base layer
            -- underneath so held layers can be drawn on top of it
            if generated.labels[name] ~= nil then
              noctalia.state.set("base", name)
            end
            noctalia.state.set("layer", name)

            -- Pop up while a hold layer (symbols, numpad, ...) is active
            local nowHolding = generated.holds[name] ~= nil
            if nowHolding ~= holding then
              holding = nowHolding
              holdSince = nowHolding and noctalia.nowMs() or nil
              apply()
            end
          end
        end)

        function onIpc(event, payload)
          if event == "toggle" then
            pinned = not pinned
          elseif event == "show" then
            pinned = true
          elseif event == "hide" then
            pinned = false
          else
            return
          end
          apply()
        end
      '';

      overlay = ''
        --!nonstrict
        local generated = require("./generated.luau")

        local KEY = 46
        local GAP = 4
        local PITCH = KEY + GAP
        -- Row stagger in key widths, roughly matching a physical keyboard
        local OFFSETS = { 0, PITCH * 0.5, PITCH * 0.75, PITCH * 1.25 }
        -- Space bar: starts under the bottom row's third key, five keys wide
        local SPACE_OFFSET = OFFSETS[4] + PITCH * 2
        local SPACE_WIDTH = PITCH * 5 - GAP

        -- label = { base, shifted, hold? }: shifted on top, base in the middle,
        -- the hold action (if any) underneath in the theme's secondary color
        local function keycap(label, held, width)
          return ui.column({
            width = width or KEY,
            height = KEY,
            radius = 6,
            fill = held and "primary_container/0.9" or "surface_container_high/0.85",
            align = "center",
            justify = "center",
            gap = 0,
          }, {
            ui.label({ text = label[2], fontSize = 9, color = "on_surface/0.6" }),
            ui.label({
              text = label[1],
              -- Shrink longer labels (F10, Vol+, Bksp, ...) to fit the keycap
              fontSize = (utf8.len(label[1]) or 0) > 2 and 11 or 15,
              fontWeight = "bold",
              color = held and "on_primary_container" or "on_surface",
            }),
            -- Always present (blank when there's no hold) so every key lines up
            ui.label({ text = label[3] or " ", fontSize = 9, fontWeight = "bold", color = "secondary" }),
          })
        end

        local function render()
          local name = noctalia.state.get("layer")
          local base = noctalia.state.get("base")
          if generated.labels[base] == nil then
            base = generated.order[1]
          end
          local hold = generated.holds[name]

          local title = base
          if hold ~= nil then
            title = name .. " (on " .. base .. ")"
          end

          local children = {
            ui.label({ text = title, fontSize = 12, fontWeight = "bold", color = "primary" }),
          }

          for i, row in ipairs(generated.labels[base]) do
            local keys = { ui.box({ width = OFFSETS[i], height = KEY }) }
            for j, label in ipairs(row) do
              local held = hold ~= nil and hold[i][j] or false
              table.insert(keys, keycap(held or label, held ~= false))
            end
            table.insert(children, ui.row({ gap = GAP }, keys))
          end

          -- Space bar row (held layers don't remap it, so always the base layer's)
          local spaceRow = { ui.box({ width = SPACE_OFFSET, height = KEY }) }
          for _, label in ipairs(generated.extra[base]) do
            table.insert(spaceRow, keycap(label, false, SPACE_WIDTH))
          end
          table.insert(children, ui.row({ gap = GAP }, spaceRow))

          layer.render(ui.column({ gap = GAP, padding = 12, radius = 14, fill = "surface/0.6" }, children))
        end

        render()
        noctalia.state.watch("layer", render)
        noctalia.state.watch("base", render)
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
    settings.binds."Mod+Ctrl+Alt+Shift+O".spawn = [
      (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia)
      "msg"
      "plugin"
      "${pluginId}:service"
      "all"
      "toggle"
    ];
  };
}
