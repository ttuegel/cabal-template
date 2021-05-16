{ profiling ? false
, release ? false
, threaded ? !profiling
, checkMaterialization ? false

# Override `src` when this project is imported as a Git submodule:
#
# > ttuegel.cleanGitSubtree {
# >   name = "kore";
# >   src = ./parent/repo;
# >   subDir = "path/to/submodule";
# > };
#
# Use `cleanGitSubtree` whenever possible to preserve the same source code
# layout as the kframework/kore repository (to enable cache re-use).
#
, src ? null
, compiler-nix-name ? "ghc8104"
, index-state ? "2021-05-10T00:00:00Z"
}:

let
  sources = import ./nix/sources.nix;
  haskell-nix = import sources."haskell.nix" {};
  inherit (haskell-nix) pkgs;
  ttuegel = import sources."ttuegel" { inherit pkgs; };
  inherit (pkgs) lib;
in

let
  project = pkgs.haskell-nix.cabalProject {
    inherit compiler-nix-name index-state;
    src = ttuegel.cleanSourceWith {
      name = "cabal-template";
      src = ttuegel.orElse src (ttuegel.cleanGitSubtree { src = ./.; });
      ignore = [
        "/nix/"
        "*.nix"
      ];
    };
    inherit checkMaterialization;
    materialized = ./nix/cabal-template.nix.d;
    modules = [
      {
        # package *
        enableLibraryProfiling = true;
        profilingDetail = "none";
        # package cabal-template
        packages.cabal-template = {
          flags = {
            inherit release threaded;
          };
          enableLibraryProfiling = profiling;
          enableExecutableProfiling = profiling;
          profilingDetail = "toplevel-functions";
        };
      }
    ];
  };

  shell = import ./shell.nix { inherit default checkMaterialization; };

  rematerialize = pkgs.writeScript "rematerialize.sh" ''
    #!/bin/sh
    ${project.plan-nix.passthru.updateMaterialized}
  '';

  default =
    {
      inherit compiler-nix-name index-state;
      inherit pkgs project rematerialize;
    };

in default
