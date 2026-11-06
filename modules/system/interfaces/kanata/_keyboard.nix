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
      (letterKey "s" "o")
      (letterKey "d" "e")
      (letterKey "f" "u")
      (letterKey "g" "i")
      (letterKey "h" "d")
      (letterKey "j" "h")
      (letterKey "k" "t")
      (letterKey "l" "n")
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
}
