{
  description = "Josh's flake setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, hyprland, ... }@inputs: 
    let
      system = "x86_64-linux";     
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
     nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs pkgs;
          };  
          modules = [
            ./hosts/nixos.nix
          ];
       };    

       homeConfigurations."josh" = home-manager.lib.homeManagerConfiguration {
           inherit pkgs;
           extraSpecialArgs = { 
             inherit inputs;
           };
           modules = [
             ./home/josh.nix      
          ];
        };
      };
}
