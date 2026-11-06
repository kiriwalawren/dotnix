# Single source of truth for the kanata layouts. Used to generate both the
# kanata config (./default.nix) and the Noctalia layout overlay
# (modules/gui/desktop/keyboard-overlay.nix).
_:
let
  # A physical key. `qwerty`/`dvorak` are `[ base shifted ]` labels for the
  # overlay; `action` is the kanata action for the dvorak layer (null = the
  # key passes through unchanged).
  key = src: qwerty: action: dvorak: {
    inherit
      src
      qwerty
      action
      dvorak
      ;
  };

  # Letters: the shifted label is omitted (it's just the uppercase letter)
  letter = l: [
    l
    ""
  ];

  # A qwerty letter key that types another letter in dvorak
  letterKey = src: target: key src (letter src) target (letter target);

  # A key that does nothing in dvorak (`XX` is kanata's no-op), from
  # `[ src qwertyBase qwertyShifted ]`
  blank =
    k:
    key (builtins.elemAt k 0) [ (builtins.elemAt k 1) (builtins.elemAt k 2) ] "XX" [
      ""
      ""
    ];

  # A dvorak letter that also activates a held layer. Tapping types the letter;
  # the layer activates when a key on the other hand (see `defhands` in
  # ./default.nix) is pressed AND released while this one is held, or once it
  # has been held for 200ms. Same-hand keys resolve as a tap. The `-release`
  # variant keeps fast rolls like "on"/"no" (both layer keys, opposite hands)
  # typing letters instead of symbols.
  layerKey =
    src: target: layer:
    key src (letter src)
      "(tap-hold-opposite-hand-release 200 ${target} (layer-while-held ${layer}) (timeout hold))"
      (letter target);

  # A key in a held layer: the kanata action (US keysyms, which is what the OS
  # layout is) and the overlay label
  sym = action: label: { inherit action label; };

  # A keypad key (labelled "kp" in the overlay). Keypad `.` needs Num Lock on,
  # otherwise xkb's keypad map sends KP_Delete; niri turns it on (./default.nix).
  kp = action: label: {
    inherit action label;
    sub = "kp";
  };
in
{
  # TCP port kanata listens on (localhost only, enforced by the nixpkgs module's sandbox)
  port = 6666;

  # Order matters: kanata always starts in the first layer defined in its
  # config (it does not remember the last layer), and `cycle-layout` cycles
  # through them in this order.
  layers = [
    "dvorak"
    "qwerty"
  ];

  # Dvorak on a 3x5 grid per hand: only the index fingers leave their home
  # column. Keys outside the grid (number row, outer pinky column) do nothing;
  # symbols live on the `symbols` hold layer instead. Letter and punctuation
  # placement follows Programmer Dvorak.
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
      (key "q" (letter "q") "scln" [
        ";"
        ":"
      ])
      (key "w" (letter "w") "comm" [
        ","
        "<"
      ])
      (key "e" (letter "e") "." [
        "."
        ">"
      ])
      (letterKey "r" "p")
      (letterKey "t" "y")
      (letterKey "y" "f")
      (letterKey "u" "g")
      (letterKey "i" "c")
      (letterKey "o" "r")
      (letterKey "p" "l")
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
      (letterKey "f" "u")
      (letterKey "g" "i")
      (letterKey "h" "d")
      (letterKey "j" "h")
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
      (key "." [ "." ">" ] "v" (letter "v"))
      (key "/" [ "/" "?" ] "z" (letter "z"))
    ]
  ];

  # Layers that are only active while a key is held. They sit on top of the
  # base layer (dvorak/qwerty): keys not listed here fall through to it.
  # Keyed by the physical (qwerty) key name used in `rows`.
  holdLayers = {
    # Held with dvorak O or N (physical S/L). Home row is the resting position:
    #   $ ~ * =     _ - / ?
    #   { } ( )     [ ] + !
    #   % @ | &     ` # \ ^
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

    # Held with dvorak E or T (physical D/K). F6 is the left index home key,
    # 4 the right index home key:
    #   F10 F11 F12                    kp*
    #   F7  F8  F9      kp.  7  8  9  kp+
    #   F4  F5  F6      kp=  4  5  6  kp-
    #   F1  F2  F3        0  1  2  3  kp/
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
      p = kp "kp+" "+";

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
      "/" = kp "kp/" "/";
    };
  };
}
