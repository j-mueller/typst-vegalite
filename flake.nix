{
  description = "Build and test nulite, the Typst Vega-Lite package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ctxjs-src = {
      url = "github:lublak/typst-ctxjs-package/v0.5.0";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ctxjs-src,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          ctxjs = import ./nix/ctxjs-module-bytecode-builder.nix {
            inherit pkgs;
            src = ctxjs-src;
          };
          javascript = import ./nix/javascript.nix { inherit pkgs; };
          nulite = import ./nix/package.nix { inherit pkgs ctxjs javascript; };
        in
        {
          inherit ctxjs javascript nulite;
          default = nulite;
          typst-minimum = import ./nix/typst-minimum.nix { inherit pkgs; };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          packages = self.packages.${system};
          integration =
            typst:
            pkgs.runCommand "nulite-test-typst-${typst.version}"
              {
                nativeBuildInputs = [
                  pkgs.python3
                  typst
                ];
              }
              ''
                python ${./test/integration.py} \
                  --package ${packages.nulite} \
                  --ctxjs ${pkgs.typstPackages.ctxjs_0_5_0.src} \
                  --examples ${./typst-package/examples} \
                  --spec ${./js/test/bar.json} \
                  --golden ${./js/test/bar.svg}
                touch "$out"
              '';
        in
        {
          javascript = packages.javascript;
          typst-latest = integration pkgs.typst;
          typst-minimum = integration packages.typst-minimum;
          shell =
            pkgs.runCommand "nulite-shell-check"
              {
                nativeBuildInputs = [
                  pkgs.shellcheck
                  pkgs.shfmt
                ];
              }
              ''
                shellcheck --enable=all --severity=style ${./build.sh}
                shfmt -i 4 -bn -ci -d ${./build.sh}
                touch "$out"
              '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "typst-vegalite";
            packages = [
              self.packages.${system}.ctxjs
              pkgs.typst
              pkgs.nodejs_24
            ];
          };
        }
      );
    };
}
