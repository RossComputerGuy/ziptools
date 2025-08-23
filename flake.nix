{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay?ref=pull/78/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    systems,
    zig-overlay,
    ...
  }@inputs: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;

    flake.overlays = {
      default = final: prev: {
        ziptools = (final.callPackage ./nix/package.nix {}).overrideAttrs (finalAtrs: prevAttrs: {
          version = "${final.lib.trim (builtins.readFile ./.version)}-git+${self.shortRev or "dirty"}";

          zigBuildFlags = [
            "-Drev=${self.shortRev or "dirty"}"
          ];

          __intentionallyOverridingVersion = true;
        });

        ziptools-nosymlinks = final.ziptools.override {
          installSymlinks = false;
        };
      };

      # Replace zip & unzip with ziptools
      replace-zip-unzip = final: prev: {
        ziptools = prev.ziptools.override {
          zig_0_15 = inputs.zig-overlay.packages.${final.system}."0.15.1";
        };

        zip = final.ziptools;
        unzip = final.ziptools;
      };
    };

    perSystem = { system, lib, pkgs, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.self.overlays.default
        ];
      };

      legacyPackages = pkgs.extend inputs.self.overlays.replace-zip-unzip;

      packages = {
        default = pkgs.ziptools;
        nosymlinks = pkgs.ziptools-nosymlinks;
      };
    };
  };
}
