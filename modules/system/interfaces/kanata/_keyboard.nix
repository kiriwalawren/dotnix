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

  # Real Programmers Dvorak (ThePrimeagen's take on Programmer Dvorak),
  # mirrors https://github.com/thePrimeagen/keyboards/blob/master/ubuntu/real-prog-dvorak
  rows = [
    [
      (key "grv" [ "`" "~" ] "(fork S-4 grv (lsft rsft))" [
        "$"
        "~"
      ])
      (key "1" [ "1" "!" ] "(t! dvp S-eql 1)" [
        "+"
        "1"
      ])
      (key "2" [ "2" "@" ] "(t! dvp lbrc 2)" [
        "["
        "2"
      ])
      (key "3" [ "3" "#" ] "(t! dvp S-lbrc 3)" [
        "{"
        "3"
      ])
      (key "4" [ "4" "$" ] "(t! dvp S-9 4)" [
        "("
        "4"
      ])
      (key "5" [ "5" "%" ] "(t! dvp S-7 5)" [
        "&"
        "5"
      ])
      (key "6" [ "6" "^" ] "(t! dvp eql 6)" [
        "="
        "6"
      ])
      (key "7" [ "7" "&" ] "(t! dvp S-0 7)" [
        ")"
        "7"
      ])
      (key "8" [ "8" "*" ] "(t! dvp S-rbrc 8)" [
        "}"
        "8"
      ])
      (key "9" [ "9" "(" ] "(t! dvp rbrc 9)" [
        "]"
        "9"
      ])
      (key "0" [ "0" ")" ] "(t! dvp S-8 0)" [
        "*"
        "0"
      ])
      (key "min" [ "-" "_" ] "(fork S-1 5 (lsft rsft))" [
        "!"
        "%"
      ])
      (key "eql" [ "=" "+" ] "(t! dvp S-bksl grv)" [
        "|"
        "`"
      ])
    ]
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
      (key "lbrc" [ "[" "{" ] "/" [
        "/"
        "?"
      ])
      (key "rbrc" [ "]" "}" ] "(fork S-2 6 (lsft rsft))" [
        "@"
        "^"
      ])
      (key "bksl" [ "\\" "|" ] "(fork bksl 3 (lsft rsft))" [
        "\\"
        "#"
      ])
    ]
    [
      (letterKey "a" "a")
      (layerKey "s" "o" "symbols")
      (letterKey "d" "e")
      (letterKey "f" "u")
      (letterKey "g" "i")
      (letterKey "h" "d")
      (letterKey "j" "h")
      (letterKey "k" "t")
      (layerKey "l" "n" "symbols")
      (key "scln" [ ";" ":" ] "s" (letter "s"))
      (key "apos" [ "'" "\"" ] "min" [
        "-"
        "_"
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
  };
}
