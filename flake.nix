{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    systems,
    ...
  }@inputs: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;

    flake.overlays = {
      default = final: prev: {
        ziptools = final.callPackage ./nix/package.nix {};
        ziptools-nosymlinks = final.ziptools.override {
          installSymlinks = false;
        };
      };
    };

    perSystem = { system, lib, pkgs, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.self.overlays.default
        ];
      };

      packages = {
        default = pkgs.ziptools;
        nosymlinks = pkgs.ziptools-nosymlinks;
      };
    };
  };
}
