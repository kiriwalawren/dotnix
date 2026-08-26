{
  nixpkgs.overlays = [
    (final: _prev: {
      catppuccin-userstyles = final.callPackage (
        {
          stdenvNoCC,
          fetchFromGitHub,
          lessc,
          jq,
          python3,
          rev ? "04413649d48c355ab716fd53c0d77d5cd432bb0a",
          hash ? "sha256-xA19P9CuNkPVqDSt8DXksmRYIbxRhTxx8CINJjyzEvA=",
          lightFlavor ? "latte",
          darkFlavor ? "mocha",
          accentColor ? "teal",
        }:
        stdenvNoCC.mkDerivation {
          pname = "catppuccin-userstyles";
          version = "unstable-${builtins.substring 0 8 rev}";

          src = fetchFromGitHub {
            owner = "catppuccin";
            repo = "userstyles";
            inherit rev hash;
          };

          nativeBuildInputs = [
            lessc
            jq
            python3
          ];

          dontConfigure = true;

          buildPhase = ''
            runHook preBuild

            # Compiled output lives in its own directory, separate from the fetched
            # source tree (which has its own unrelated *.json files, e.g. deno.json,
            # that must not leak into the jq glob in installPhase).
            mkdir -p compiled

            for lessFile in styles/*/catppuccin.user.less; do
              site=$(basename "$(dirname "$lessFile")")
              sed 's#https://userstyles\.catppuccin\.com/##' "$lessFile" > "$site.patched.less"

              # Most sites only use the three standard vars below, but some declare
              # extra vars (checkboxes, ranges, extra color pickers). Pass each of
              # those through too, using its own declared default, so lessc doesn't
              # fail on an undefined variable. (`text`/`color`-default vars are rare
              # enough in this corpus to skip; those sites fail loudly below instead.)
              extraModifyVars=()
              while IFS= read -r varLine; do
                type=$(sed -E 's/^@var ([a-z]+) .*/\1/' <<<"$varLine")
                name=$(sed -E 's/^@var [a-z]+ ([A-Za-z0-9_-]+).*/\1/' <<<"$varLine")
                case "$name" in
                  lightFlavor | darkFlavor | accentColor | "") continue ;;
                esac
                case "$type" in
                  select)
                    opts=$(sed -E 's/^@var select [A-Za-z0-9_-]+ "[^"]*" \[(.*)\]$/\1/' <<<"$varLine")
                    default=$(tr ',' '\n' <<<"$opts" | grep '\*' | head -1 | sed -E 's/^[[:space:]]*"?([A-Za-z0-9_-]+):.*/\1/')
                    ;;
                  checkbox | number)
                    default=$(sed -E 's/^@var [a-z]+ [A-Za-z0-9_-]+ "[^"]*" ([0-9.]+).*/\1/' <<<"$varLine")
                    ;;
                  range)
                    bracket=$(sed -E 's/^@var range [A-Za-z0-9_-]+ "[^"]*" \[(.*)\]$/\1/' <<<"$varLine")
                    default=$(cut -d',' -f1 <<<"$bracket" | tr -d '[:space:]')
                    ;;
                  *)
                    default=""
                    ;;
                esac
                if [ -n "$default" ]; then
                  extraModifyVars+=("--modify-var=$name=$default")
                fi
              done < <(grep -E '^@var (select|checkbox|number|range)' "$lessFile")

              if lessc --include-path="$PWD" \
                --modify-var="lightFlavor=${lightFlavor}" \
                --modify-var="darkFlavor=${darkFlavor}" \
                --modify-var="accentColor=${accentColor}" \
                "''${extraModifyVars[@]}" \
                "$site.patched.less" "$site.raw.css"; then
                # `@-moz-document` only takes effect in privileged sheets, not the
                # plain <style> a content script injects into a page (Firefox
                # bug 1035091), so Stylus needs the real domain/url-prefix/regexp
                # targets in its own sections[].domains/urlPrefixes/regexps
                # fields - not left embedded in the code, where Gecko silently
                # ignores them. Split the wrapper into matcher pairs (on
                # stderr) and the bare inner rules (on stdout).
                python3 ${./_catppuccin-userstyles-split.py} "$site.raw.css" \
                  > "compiled/$site.css" 2> "compiled/$site.matchers.txt"
              else
                echo "Warning: failed to compile $site, skipping" >&2
              fi
              rm -f "$site.raw.css"
            done

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p "$out" jsonstaging
            id=0
            for css in compiled/*.css; do
              site=$(basename "$css" .css)
              id=$((id + 1))
              matchersFile="compiled/$site.matchers.txt"
              domainsJson=$(awk -F'\t' '$1=="domain"{print $2}' "$matchersFile" | jq -R -s -c 'split("\n")[:-1]')
              urlPrefixesJson=$(awk -F'\t' '$1=="url-prefix"{print $2}' "$matchersFile" | jq -R -s -c 'split("\n")[:-1]')
              regexpsJson=$(awk -F'\t' '$1=="regexp"{print $2}' "$matchersFile" | jq -R -s -c 'split("\n")[:-1]')
              urlsJson=$(awk -F'\t' '$1=="url"{print $2}' "$matchersFile" | jq -R -s -c 'split("\n")[:-1]')
              # Stylus keys its in-memory style map by the numeric `id` field
              # inside each style object, not by the storage key name below it
              # (style-N) - every style needs a distinct id or Stylus's Map
              # collapses them all into one entry on load.
              jq -n --argjson id "$id" --arg name "$site" --rawfile code "$css" \
                --argjson domains "$domainsJson" --argjson urlPrefixes "$urlPrefixesJson" \
                --argjson regexps "$regexpsJson" --argjson urls "$urlsJson" \
                '{id: $id, name: $name, enabled: true, sections: [
                    ({code: $code}
                     + (if ($domains | length) > 0 then {domains: $domains} else {} end)
                     + (if ($urlPrefixes | length) > 0 then {urlPrefixes: $urlPrefixes} else {} end)
                     + (if ($regexps | length) > 0 then {regexps: $regexps} else {} end)
                     + (if ($urls | length) > 0 then {urls: $urls} else {} end))
                  ]}' > "jsonstaging/$site.json"
            done
            jq -s '.' jsonstaging/*.json > "$out/styles.json"

            runHook postInstall
          '';
        }
      ) { };
    })
  ];

  perSystem =
    { pkgs, ... }:
    {
      packages.catppuccin-userstyles = pkgs.catppuccin-userstyles;
    };
}
