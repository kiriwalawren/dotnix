{
  runCommand,
  alejandra,
  nodePackages,
  shfmt,
  ...
}:
runCommand "check-format" {nativeBuildInputs = [alejandra nodePackages.prettier shfmt];} ''
  alejandra --check ${./..}
  prettier --check -u ${./..} --ignore-path ${./../.prettierignore} ${./../.gitignore} --ignore-path "**/*.sh"
  shfmt -d -i 2 -ci ${./..}
  touch $out
''
