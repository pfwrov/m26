{
  description = "PFW M26 EXPLORER ROV";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.callPackage ./nix/shell-base.nix { };
          ros = pkgs.callPackage ./nix/shell-ros.nix { };

          # NOTE: optional for now. Need all the fw stuff base first so we dont switch all the time
          fw = pkgs.callPackage ./nix/shell-fw.nix { };
        }
      );
    };
}
