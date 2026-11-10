# Noctalia plugin: click-through overlay of the active kanata layout, and a
# which-key legend of niri binds while hyper/meh is held.
{
  config,
  lib,
  self,
  ...
}:
let
  keyboard = import ../../../system/interfaces/kanata/_keyboard.nix { inherit lib; };

  pluginId = "dotnix/keymap";
in
{
  flake.wrappers.noctalia =
    { pkgs, ... }:
    let
      # Follows kanata's layer changes; stops when Noctalia ($PPID) exits, since an
      # orphaned loop's reconnects leak fds in kanata until it crashes
      layerStream = "while kill -0 $PPID 2>/dev/null; do ${pkgs.socat}/bin/socat -u TCP:127.0.0.1:${toString keyboard.port} STDOUT; sleep 2; done";

      # niri bind titles by combo; read from the wrapper module (the niri package
      # depends on this one), and only `props` to avoid a cycle
      bindTitles = lib.filterAttrs (_: title: title != null) (
        lib.mapAttrs (
          _: v: if builtins.isFunction v then (v null).props.hotkey-overlay-title or null else null
        ) config.flake.wrappers.niri.settings.binds
      );

      # Display names for xkb key names
      keyNames = {
        Equal = "=";
        Minus = "-";
        Comma = ",";
        Period = ".";
        Slash = "/";
        Return = "⏎";
        Space = "Spc";
      };

      # Binds whose modifiers are exactly `prefix` (case-insensitive), sorted by title
      legend =
        prefix:
        let
          p = lib.toLower prefix + "+";
        in
        lib.sort (a: b: a.title < b.title) (
          lib.concatLists (
            lib.mapAttrsToList (
              combo: title:
              let
                rest = lib.substring (lib.stringLength p) (-1) combo;
              in
              lib.optional (lib.hasPrefix p (lib.toLower combo) && !lib.hasInfix "+" rest) {
                key = keyNames.${rest} or rest;
                inherit title;
              }
            ) bindTitles
          )
        );

      generated = {
        order = keyboard.layers;
        stream = layerStream;
        # Per layout: rows of `{ base, shifted, hold? }` labels
        labels = lib.genAttrs keyboard.layers (layer: map (map (k: k.${layer})) keyboard.rows);
        # Per layout: the space-bar row
        extra = lib.genAttrs keyboard.layers (layer: map (k: k.${layer}) keyboard.extraKeys);
        # Held layers laid out like `labels` plus the space-bar row; `false` = show the base key
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
          )) (keyboard.rows ++ [ keyboard.extraKeys ])
        ) keyboard.holdLayers;
        # Modifier layers: lists of `{ key, title }` niri binds
        legends = lib.mapAttrs (_: legend) keyboard.modLayers;
      };

      manifest = ''
        id          = "${pluginId}"
        name        = "Keymap"
        version     = "1.0.0"
        plugin_api  = 43
        author      = "dotnix"
        description = "Toggleable overlay of the active kanata layout, and a legend of niri binds while a modifier chord is held."

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

        # Own surface: sharing `overlay`'s reused nodes squashed it to keycap sizes
        [[layer]]
        id            = "legend"
        entry         = "legend.luau"
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
        -- Keymap shows while pinned (Hyper+O) or a hold layer is held; the legend
        -- replaces it while hyper/meh is held
        local pinned = false
        local holding = false
        local layer = nil

        -- Holds must last this long before popping up (no flashes on rolls); hiding is immediate
        local SHOW_DELAY_MS = 200
        local holdSince = nil -- nowMs() when the current hold started
        local shown = { overlay = false, legend = false }

        local function setShown(id, want)
          if want ~= shown[id] then
            shown[id] = want
            if want then
              noctalia.layer.show(id)
            else
              noctalia.layer.hide(id)
            end
          end
        end

        local function apply()
          local held = holding and holdSince ~= nil and noctalia.nowMs() - holdSince >= SHOW_DELAY_MS
          local legend = held and generated.legends[layer] ~= nil
          local keymap = not legend and (pinned or (held and generated.holds[layer] ~= nil))
          -- Hide first so the two never show at once
          if legend then
            setShown("overlay", false)
            setShown("legend", true)
          else
            setShown("legend", false)
            setShown("overlay", keymap)
          end
        end

        -- Polls a pending hold until its delay passes
        noctalia.setUpdateInterval(25)
        function update()
          if holding then
            apply()
          end
        end

        noctalia.runStream(generated.stream, function(line)
          local msg = noctalia.json.decode(line)
          if msg and msg.LayerChange then
            local name = msg.LayerChange.new
            -- kanata reports only the top layer, so remember the base one
            if generated.labels[name] ~= nil then
              noctalia.state.set("base", name)
            end
            noctalia.state.set("layer", name)
            layer = name

            -- A hold layer or modifier chord is active
            local nowHolding = generated.holds[name] ~= nil or generated.legends[name] ~= nil
            if nowHolding ~= holding then
              holding = nowHolding
              holdSince = nowHolding and noctalia.nowMs() or nil
            end
            apply()
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

        -- label = { base, shifted, hold? }: shifted, base, then hold in secondary
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
              -- Shrink longer labels to fit
              fontSize = (utf8.len(label[1]) or 0) > 2 and 11 or 15,
              fontWeight = "bold",
              color = held and "on_primary_container" or "on_surface",
            }),
            -- Always present so keys line up
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

          -- Space bar; its held labels follow the grid rows in `hold`
          local spaceRow = { ui.box({ width = SPACE_OFFSET, height = KEY }) }
          local spaceHold = hold ~= nil and hold[#generated.labels[base] + 1] or nil
          for j, label in ipairs(generated.extra[base]) do
            local held = spaceHold ~= nil and spaceHold[j] or false
            table.insert(spaceRow, keycap(held or label, held ~= false, SPACE_WIDTH))
          end
          table.insert(children, ui.row({ gap = GAP }, spaceRow))

          layer.render(ui.column({ gap = GAP, padding = 12, radius = 14, fill = "surface/0.6" }, children))
        end

        render()
        noctalia.state.watch("layer", render)
        noctalia.state.watch("base", render)
      '';

      # Which-key legend: columns of `[key] title`, ROWS per column
      legendScript = ''
        --!nonstrict
        local generated = require("./generated.luau")

        local ROWS = 8
        local KEY = 40
        local GAP = 4

        local function entryRow(entry)
          return ui.row({ gap = 8, align = "center" }, {
            ui.column({
              width = KEY,
              height = 24,
              radius = 6,
              fill = "surface_container_high/0.85",
              align = "center",
              justify = "center",
            }, {
              ui.label({ text = entry.key, fontSize = 12, fontWeight = "bold", color = "primary" }),
            }),
            ui.label({ text = entry.title, fontSize = 12, color = "on_surface" }),
          })
        end

        local function render()
          local name = noctalia.state.get("layer")
          local entries = generated.legends[name]
          -- Empty until the service hides it after the chord ends
          if entries == nil then
            layer.render(ui.column({}, {}))
            return
          end

          local columns = {}
          for i, entry in ipairs(entries) do
            local c = math.floor((i - 1) / ROWS) + 1
            columns[c] = columns[c] or {}
            table.insert(columns[c], entryRow(entry))
          end
          local row = {}
          for _, column in ipairs(columns) do
            table.insert(row, ui.column({ gap = GAP }, column))
          end

          layer.render(ui.column({ gap = 8, padding = 12, radius = 14, fill = "surface/0.6" }, {
            ui.label({
              text = name:sub(1, 1):upper() .. name:sub(2),
              fontSize = 12,
              fontWeight = "bold",
              color = "primary",
            }),
            ui.row({ gap = 24, align = "start" }, row),
          }))
        end

        render()
        noctalia.state.watch("layer", render)
      '';

      plugin = pkgs.runCommand "noctalia-plugin-keymap" { } ''
        dir=$out/keymap
        mkdir -p $dir
        cp ${pkgs.writeText "plugin.toml" manifest} $dir/plugin.toml
        cp ${pkgs.writeText "service.luau" service} $dir/service.luau
        cp ${pkgs.writeText "overlay.luau" overlay} $dir/overlay.luau
        cp ${pkgs.writeText "legend.luau" legendScript} $dir/legend.luau
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
    settings.binds."Mod+Ctrl+Alt+Shift+O" = import ../niri/_bind.nix "Keymap overlay" {
      spawn = [
        (lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia)
        "msg"
        "plugin"
        "${pluginId}:service"
        "all"
        "toggle"
      ];
    };
  };
}
