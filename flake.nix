{
  description = "NixOS flake configuration for host nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Clavis shell 依赖的外部 QML 模块（Material 3 shapes，androidx shape 的 Qt 移植）
    # 上游：https://github.com/soramanew/m3shapes
    m3shapes = {
      url = "github:soramanew/m3shapes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # 上游 Clavis shell 的打包（源码 vendored 在 assets/quickshell/clavis）
    packages.x86_64-linux.clavis-shell =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/clavis-shell.nix { };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        inputs.home-manager.nixosModules.home-manager
      ];
    };
  };
}
