# Kanata layouts; source for the kanata config and the Noctalia keymap overlay.
_:
let
  # A physical key: overlay labels `[ base shifted hold? ]` per layout, plus its dvorak action.
  key = src: qwerty: action: dvorak: {
    inherit
      src
      qwerty
      action
      dvorak
      ;
  };

  # Letter label (no shifted label)
  letter = l: [
    l
    ""
  ];

  # A qwerty letter key that types another letter in dvorak
  letterKey = src: target: key src (letter src) target (letter target);

  # A key that does nothing in dvorak, from `[ src qwertyBase qwertyShifted ]`
  blank =
    k:
    key (builtins.elemAt k 0) [ (builtins.elemAt k 1) (builtins.elemAt k 2) ] "XX" [
      ""
      ""
    ];

  # Hold on an other-hand press+release or after 200ms; always a tap mid-word (prior-idle 150)
  holdAction =
    tap: hold:
    "(tap-hold-opposite-hand-release 200 ${tap} ${hold} (require-prior-idle 150) (timeout hold))";
  # A dvorak tap-hold key; `holdLabel` is shown under it in the overlay
  holdKey =
    hold: holdLabel: src: qwerty: tap: dvorak:
    key src qwerty (holdAction tap hold) (dvorak ++ [ holdLabel ]);

  # Also give a key a modifier hold in qwerty (tap types the key itself)
  qwertyHold =
    hold: k:
    k
    // {
      qwertyAction = holdAction k.src hold;
      qwerty = k.qwerty ++ [ modLabels.${hold} ];
    };

  # Tap then re-hold within 200ms to hold (repeat) the tap key instead
  repeatOnRetap =
    k:
    k
    // {
      action =
        builtins.replaceStrings [ "(timeout hold))" ] [ "(timeout hold) (tap-repress-timeout 200))" ]
          k.action;
    };

  # Overlay labels for hold actions
  layerLabels = {
    symbols = "sym";
    numpad = "num";
    shortcuts = "shrt";
  };
  modLabels = {
    lctl = "ctl";
    rctl = "ctl";
    lalt = "alt";
    ralt = "alt";
    lmet = "sup";
    rmet = "sup";
    "$meh" = "meh";
    "$hyper" = "hyp";
  };

  # A dvorak letter that activates a held layer
  layerKey =
    src: target: layer:
    holdKey "(layer-while-held ${layer})" layerLabels.${layer} src (letter src) target (letter target);

  # A dvorak key that holds modifiers (`$meh`/`$hyper` are defvars)
  modTap = hold: holdKey hold modLabels.${hold};

  # A dvorak letter that holds modifiers
  modKey =
    src: target: hold:
    modTap hold src (letter src) target (letter target);

  # A held-layer key: kanata action (US keysyms) and overlay label
  sym = action: label: { inherit action label; };

  # A keypad key, labelled "kp" (keypad `.` needs Num Lock, which niri turns on)
  kp = action: label: {
    inherit action label;
    sub = "kp";
  };

  # A held-layer key with a small secondary label (e.g. the chord)
  labelled = action: label: sub: { inherit action label sub; };
in
{
  # Empty layers held with `$hyper`/`$meh` so the overlay can show their niri binds (by prefix)
  modLayers = {
    hyper = "Mod+Ctrl+Alt+Shift";
    meh = "Ctrl+Alt+Shift";
  };

  # kanata's TCP port (localhost only)
  port = 6666;

  # Kanata boots into the first; `cycle-layout` cycles in this order
  layers = [
    "dvorak"
    "qwerty"
  ];

  # Programmer Dvorak on a 3x5 grid per hand; keys outside it do nothing in dvorak
  rows = [
    (map blank [
      [
        "grv"
        "`"
        "~"
      ]
      [
        "1"
        "1"
        "!"
      ]
      [
        "2"
        "2"
        "@"
      ]
      [
        "3"
        "3"
        "#"
      ]
      [
        "4"
        "4"
        "$"
      ]
      [
        "5"
        "5"
        "%"
      ]
      [
        "6"
        "6"
        "^"
      ]
      [
        "7"
        "7"
        "&"
      ]
      [
        "8"
        "8"
        "*"
      ]
      [
        "9"
        "9"
        "("
      ]
      [
        "0"
        "0"
        ")"
      ]
      [
        "min"
        "-"
        "_"
      ]
      [
        "eql"
        "="
        "+"
      ]
    ])
    [
      (qwertyHold "$meh" (
        modTap "$meh" "q" (letter "q") "scln" [
          ";"
          ":"
        ]
      ))
      (modTap "lctl" "w" (letter "w") "comm" [
        ","
        "<"
      ])
      (modTap "lalt" "e" (letter "e") "." [
        "."
        ">"
      ])
      (modKey "r" "p" "lmet")
      (letterKey "t" "y")
      (letterKey "y" "f")
      (modKey "u" "g" "rmet")
      (modKey "i" "c" "ralt")
      (modKey "o" "r" "rctl")
      (qwertyHold "$meh" (modKey "p" "l" "$meh"))
      (blank [
        "lbrc"
        "["
        "{"
      ])
      (blank [
        "rbrc"
        "]"
        "}"
      ])
      (blank [
        "bksl"
        "\\"
        "|"
      ])
    ]
    [
      (letterKey "a" "a")
      (layerKey "s" "o" "symbols")
      (layerKey "d" "e" "numpad")
      (repeatOnRetap (layerKey "f" "u" "shortcuts"))
      (letterKey "g" "i")
      (letterKey "h" "d")
      (layerKey "j" "h" "shortcuts")
      (layerKey "k" "t" "numpad")
      (layerKey "l" "n" "symbols")
      (key "scln" [ ";" ":" ] "s" (letter "s"))
      (blank [
        "apos"
        "'"
        "\""
      ])
    ]
    [
      (key "z" (letter "z") "apos" [
        "'"
        "\""
      ])
      (letterKey "x" "q")
      (letterKey "c" "j")
      (letterKey "v" "k")
      (letterKey "b" "x")
      (letterKey "n" "b")
      (letterKey "m" "m")
      (key "comm" [ "," "<" ] "w" (letter "w"))
      (modTap "$meh" "." [ "." ">" ] "v" (letter "v"))
      (key "/" [ "/" "?" ] "z" (letter "z"))
    ]
  ];

  # Keys outside the grid, in every base layer, with no hand (so they never trigger other holds).
  # Space: hyper on any press+release while held, or after 200ms.
  extraKeys =
    let
      spaceLabel = [
        "Space"
        ""
        modLabels."$hyper"
      ];
    in
    [ (key "spc" spaceLabel "(tap-hold-release 200 200 spc $hyper)" spaceLabel) ];

  # Layers active while a key is held, keyed by physical key; unlisted keys fall through
  holdLayers = {
    # Held with dvorak O or N
    symbols = {
      q = sym "S-4" "$";
      w = sym "S-grv" "~";
      e = sym "S-8" "*";
      r = sym "eql" "=";
      u = sym "S-min" "_";
      i = sym "min" "-";
      o = sym "/" "/";
      p = sym "S-/" "?";

      a = sym "S-lbrc" "{";
      s = sym "S-rbrc" "}";
      d = sym "S-9" "(";
      f = sym "S-0" ")";
      j = sym "lbrc" "[";
      k = sym "rbrc" "]";
      l = sym "S-eql" "+";
      scln = sym "S-1" "!";

      z = sym "S-5" "%";
      x = sym "S-2" "@";
      c = sym "S-bksl" "|";
      v = sym "S-7" "&";
      m = sym "grv" "`";
      comm = sym "S-3" "#";
      "." = sym "bksl" "\\";
      "/" = sym "S-6" "^";
    };

    # Held with dvorak E or T
    numpad = {
      "2" = sym "f10" "F10";
      "3" = sym "f11" "F11";
      "4" = sym "f12" "F12";
      "0" = kp "kp*" "*";

      w = sym "f7" "F7";
      e = sym "f8" "F8";
      r = sym "f9" "F9";
      y = kp "kp." ".";
      u = sym "7" "7";
      i = sym "8" "8";
      o = sym "9" "9";
      p = kp "kp/" "/";

      s = sym "f4" "F4";
      d = sym "f5" "F5";
      f = sym "f6" "F6";
      # `kp=` is kanata's name for Clear; keypad equals is `NumpadEqual`
      h = kp "NumpadEqual" "=";
      j = sym "4" "4";
      k = sym "5" "5";
      l = sym "6" "6";
      scln = kp "kp-" "-";

      x = sym "f1" "F1";
      c = sym "f2" "F2";
      v = sym "f3" "F3";
      n = sym "0" "0";
      m = sym "1" "1";
      comm = sym "2" "2";
      "." = sym "3" "3";
      "/" = kp "kp+" "+";

      spc = kp "kp0" "0";
    };

    # Held with dvorak U or H; media keys are handled by the niri XF86* binds
    shortcuts = {
      q = sym "esc" "Esc";
      w = labelled "C-S-tab" "Tab" "C-S";
      e = labelled "C-tab" "Tab" "C";
      y = sym "volu" "Vol+";
      i = sym "up" "↑";
      p = sym "bspc" "Bksp";

      a = labelled "C-x" "Cut" "C-x";
      s = labelled "C-c" "Cpy" "C-c";
      d = labelled "C-v" "Pst" "C-v";
      f = sym "brdn" "Br-";
      g = sym "brup" "Br+";
      h = sym "vold" "Vol-";
      j = sym "lft" "←";
      k = sym "down" "↓";
      l = sym "rght" "→";
      scln = sym "ret" "Ent";

      n = sym "mute" "Mute";
      m = sym "prev" "Prev";
      comm = sym "pp" "Play";
      "." = sym "next" "Next";
    };
  };
}
