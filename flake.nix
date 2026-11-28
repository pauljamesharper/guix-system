{
  description = "NixOS for gUn and alteredcarbon: the dotfiles' Debian desktop (mango + mangobutter)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # partitions, LUKS and btrfs from modules/nixos/disko.nix (no UUIDs)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # the Flatpak apps, declared (modules/nixos/flatpak.nix)
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # mangobutter's wallpaper palette and image viewer, from their own flakes
    butterpal = {
      url = "git+https://justaguy.dev/drew/butterpal?ref=refs/tags/v0.3.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    butterview = {
      url = "git+https://justaguy.dev/drew/butterview?ref=refs/tags/v0.4.9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # one configuration per directory in hosts/, named as the hostname
      # (so a plain `nixos-rebuild switch` finds it)
      hosts = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts));

      mkHost =
        name:
        lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${name}
            ./modules/nixos
            { networking.hostName = name; }
          ];
        };
    in
    {
      nixosConfigurations = lib.genAttrs hosts mkHost;

      packages.${system} = import ./pkgs { inherit pkgs; };

      formatter.${system} = pkgs.nixfmt;
    };
}
