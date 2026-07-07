{
  description = "BoscoDomingo dotfiles — Home Manager + flakes (proposal skeleton)";

  # Inputs are hash-locked in flake.lock once you run `nix flake update`.
  # That lock file is the reproducibility guarantee: identical versions on
  # every machine until you deliberately update it.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system defaults (Dock, keyboard, casks). Only used by the mac host.
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nix-darwin, ... }:
    let
      # TODO: set these to your real values.
      username = "bosco";
      homeDir = system:
        if nixpkgs.lib.hasSuffix "darwin" system
        then "/Users/${username}"
        else "/home/${username}";

      # Helper: build a Home Manager configuration for one host.
      mkHome = { system, hostModule }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          modules = [
            hostModule
            {
              home.username = username;
              home.homeDirectory = homeDir system;
              home.stateVersion = "24.11"; # do not bump casually
              programs.home-manager.enable = true;
            }
          ];
        };
    in
    {
      # One entry per machine. Invoke with:
      #   home-manager switch --flake .#arch-wsl
      homeConfigurations = {
        "arch-wsl" = mkHome {
          system = "x86_64-linux";
          hostModule = ./hosts/arch-wsl.nix;
        };
        "ubuntu" = mkHome {
          system = "x86_64-linux";
          hostModule = ./hosts/ubuntu.nix;
        };
        "macbook" = mkHome {
          system = "aarch64-darwin";
          hostModule = ./hosts/macbook.nix;
        };
      };

      # Optional: full macOS system management via nix-darwin.
      # Invoke with: darwin-rebuild switch --flake .#macbook-system
      # darwinConfigurations."macbook-system" = nix-darwin.lib.darwinSystem {
      #   system = "aarch64-darwin";
      #   modules = [ ./hosts/darwin-system.nix ];
      # };
    };
}
