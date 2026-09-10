{ pkgs, src }:
pkgs.rustPlatform.buildRustPackage {
  pname = "ctxjs";
  version = "0.5.0";
  inherit src;

  postPatch = ''
    cp ${./typst-ctxjs-cargo.lock} Cargo.lock
  '';

  cargoLock = {
    lockFile = ./typst-ctxjs-cargo.lock;
    outputHashes = {
      "minicbor-2.2.2" = "sha256-XO99sE/+kjfwtBPYsBeOuVRNKhYNhKZGE9ToDLO51KA=";
      "wasm-minimal-protocol-0.2.1" = "sha256-B/nol76ODuqpCx3fCb4RntLVSTDEp+K3Ae0QdLLWCcI=";
    };
  };

  # QuickJS bytecode must match the engine in the published ctxjs WASM plugin.
  cargoBuildFlags = [
    "--bin"
    "ctxjs_module_bytecode_builder"
  ];
  doCheck = false;
  meta.mainProgram = "ctxjs_module_bytecode_builder";
}
