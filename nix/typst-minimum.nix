{ pkgs }:
let
  hashes = {
    x86_64-linux = "sha256-zRFI2mHWhE5iwzD8YiLpiEgKyv4zt22uyOtdIhJY/rY=";
    aarch64-linux = "sha256-Ghs4Qe4dhNEwxP1Y8ayKI6zw1r8RFhxSRvAWYizwRuY=";
  };
  arch = pkgs.stdenv.hostPlatform.parsed.cpu.name;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "typst-minimum";
  version = "0.13.0";
  src = pkgs.fetchurl {
    url = "https://github.com/typst/typst/releases/download/v0.13.0/typst-${arch}-unknown-linux-musl.tar.xz";
    hash = hashes.${pkgs.stdenv.hostPlatform.system};
  };
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 typst "$out/bin/typst"
    runHook postInstall
  '';
  meta.mainProgram = "typst";
}
