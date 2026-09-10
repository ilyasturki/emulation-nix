{
  description = "Emulators missing from nixpkgs, and newer builds of the ones that lag behind";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # No `follows`: the cache only holds builds against eden-nix's own pin, and
    # their CI is what validates the recipe. Rebuilding Eden against a different
    # nixpkgs throws both away.
    eden-nix.url = "github:Daaboulex/eden-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      eden-nix,
    }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # nx-optimizer ships under CC-BY-NC, which nixpkgs treats as unfree.
      # Consumers of `overlays.default` need `allowUnfree` for that one attribute.
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      overlays.default = final: _prev: {
        atmosphere = final.callPackage ./pkgs/atmosphere/package.nix { };
        citron-neo = final.callPackage ./pkgs/citron-neo/package.nix { };
        hekate = final.callPackage ./pkgs/hekate/package.nix { };
        nx-optimizer = final.callPackage ./pkgs/nx-optimizer/package.nix { };
        panda3ds = final.callPackage ./pkgs/panda3ds/package.nix { };
        pcsx2 = final.callPackage ./pkgs/pcsx2/package.nix { };
        ryujinx-canary = final.callPackage ./pkgs/ryujinx-canary/package.nix { };
        eden = eden-nix.packages.${final.stdenv.hostPlatform.system}.eden;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          inherit (pkgs.extend self.overlays.default)
            atmosphere
            citron-neo
            hekate
            nx-optimizer
            panda3ds
            pcsx2
            ryujinx-canary
            ;
          eden = eden-nix.packages.${system}.eden;
        }
      );

      nixosModules.default = {
        imports = [
          eden-nix.nixosModules.default
          ./modules/default.nix
        ];
        nixpkgs.overlays = [ self.overlays.default ];
      };

      checks = forAllSystems (system: self.packages.${system});

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              curl
              git
              jq
              nix-prefetch-git
              perl
            ];
          };
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
