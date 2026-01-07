{
  description = "Conor's dotfile flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    tap-brew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      perSystem =
        {
          system,
          pkgs,
          lib,
          ...
        }:
        let
          inherit (pkgs.stdenv) hostPlatform;
          # TODO: Neovim configuration for flake dev
          commonDevPackages = with pkgs; [
            statix
            deadnix

            nixfmt
            alejandra

            nil
            nixd

            nodejs_25
          ];
          darwinDevPackages = with pkgs; lib.optionals hostPlatform.isDarwin [ tart ];
          linuxDevPackages = with pkgs; lib.optionals hostPlatform.isLinux [ ];
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };

          devShells.default = pkgs.mkShellNoCC {
            packages = commonDevPackages ++ darwinDevPackages ++ linuxDevPackages;
          };

        };

      flake = {
        darwinConfigurations.macbook = inputs.nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/macbook
          ];
        };
        # NOTE: should we use nixos-unstable nixpkgs?
        nixosConfigurations.vps = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/vps
          ];
        };
      };
    };
}
