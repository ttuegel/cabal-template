{ default ? import ./default.nix {}
, checkMaterialization ? false
}:

let
  inherit (default) project;
  inherit (project) shellFor;

  sources = import ./nix/sources.nix;

  inherit (pkgs) cabal-install ghcid stack;

  inherit (default) compiler-nix-name index-state pkgs;

  hls-project = import sources."nix-haskell-hls" {
    ghcVersion = compiler-nix-name;
  };
  inherit (hls-project) hls-renamed;

  fourmolu = import ./nix/fourmolu.nix { inherit default checkMaterialization; };

in

shellFor {
  buildInputs =
    [
      hls-renamed
      ghcid fourmolu
      cabal-install stack
    ];
  passthru.rematerialize = pkgs.writeScript "rematerialize-shell.sh" ''
    #!/bin/sh
    ${fourmolu.passthru.updateMaterialized}
  '';
}
