# typst-vegalite

Run Vega-Lite in Typst. The package is published as [nulite](https://typst.app/universe/package/nulite/).
See [typst-package/README.md](typst-package/README.md) for the rendering API.

## Build and test

Run `./build.sh` with Nix installed. It runs the checks and builds the complete
package into `result/`, including freshly compiled bytecode, examples, and
dependency license notices. The examples support the README on Typst Universe;
`typst.toml` excludes them from the downloadable package.
No generated bundle or bytecode is required in the checkout.
The package version remains 0.1.1 until release preparation.

To run the stages separately:

```sh
nix flake check --print-build-logs
nix build .#nulite
```

Checks build the JavaScript bundle, run its SVG regression tests, and test the
assembled package against Typst 0.13.0 and 0.15.1. The integration tests use the
published ctxjs 0.5.0 runtime in an isolated package directory, with no network
access during the Nix build. They cover repeated and distinct charts, sizing,
zoom, unbounded layout, and invalid inputs. CI runs on x86_64 and aarch64 Linux
and audits the npm lockfile.

## Development

`nix develop` provides Typst 0.15.1, Node.js 24, and the ctxjs 0.5.0 bytecode
compiler. Typst, Node.js, and the Rust toolchain come from the NixOS cache; the
custom bytecode compiler builds locally. No project binary cache is required.
Darwin is not supported by this flake.

For JavaScript changes, run inside the shell:

```sh
cd js
npm ci --ignore-scripts
npm run build
npm test
npm audit --package-lock-only
```

The SVG fixture in `js/test/bar.svg` is a regression baseline. Review chart
changes before replacing it. The integration tests compare the WASM output with
this same fixture.

When changing dependencies, update `js/package-lock.json` and the corresponding
`npmDepsHash` in `nix/javascript.nix`. When updating ctxjs, update its flake input
and `nix/typst-ctxjs-cargo.lock` together with the Typst import and test runtime.
The rquickjs crates must match the engine in the published WASM runtime; do not
blindly update their patch versions. The minimum Typst binary is pinned by hash
in `nix/typst-minimum.nix` and must match the package's `compiler` field.

The packaged build and SVG testing approach draws on
[ConnorBaker's PR #2](https://github.com/j-mueller/typst-vegalite/pull/2).
