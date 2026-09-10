{ pkgs }:
pkgs.buildNpmPackage {
  pname = "nulite-js";
  version = "1.0.0";
  src = pkgs.lib.sourceByRegex ../js [
    "^src(/.*)?$"
    "^test(/.*)?$"
    "^build.mjs$"
    "^package(-lock)?.json$"
  ];
  nodejs = pkgs.nodejs_24;
  npmDepsHash = "sha256-fZi1H/E7fAT/zaDjR5y1WEfYFMqnUvbUyueWwQlNfGw=";
  npmFlags = [ "--ignore-scripts" ];
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    npm test
    runHook postCheck
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp dist/* "$out/"
    runHook postInstall
  '';
}
