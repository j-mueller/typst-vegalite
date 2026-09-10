{
  pkgs,
  ctxjs,
  javascript,
}:
let
  manifest = (builtins.fromTOML (builtins.readFile ../typst-package/typst.toml)).package;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = manifest.name;
  inherit (manifest) version;
  src = pkgs.lib.sourceByRegex ../typst-package [
    "^lib.typ$"
    "^typst.toml$"
    "^README.md$"
    "^LICENSE$"
  ];
  nativeBuildInputs = [ ctxjs ];
  buildPhase = ''
    runHook preBuild
    ctxjs_module_bytecode_builder vegalite ${javascript}/index.js vegalite.kbc1
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp lib.typ typst.toml README.md LICENSE vegalite.kbc1 "$out/"
    cp ${javascript}/THIRD-PARTY-NOTICES.txt "$out/"
    runHook postInstall
  '';
}
