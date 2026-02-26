{
  description = "PFW M26 EXPLORER ROV";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
  };

  outputs =
    { nixpkgs, nix-ros-overlay, ... }:
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
          pkgsBase = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          pkgsRos = import nix-ros-overlay.inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              nix-ros-overlay.overlays.default

              (final: prev: {
                python3Packages = prev.python3Packages.overrideScope (
                  pyFinal: pyPrev: {
                    colcon-ros = pyPrev.colcon-ros.overridePythonAttrs (old: {
                      dontUsePythonCatchConflicts = true;
                    });
                  }
                );
              })
            ];
          };
        in
        {
          default = pkgsBase.callPackage ./nix/shell-base.nix { };

          fw = pkgsBase.callPackage ./nix/shell-fw.nix { };

          ros = pkgsRos.callPackage ./nix/shell-ros.nix { };
        }
      );
    };

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    ];
  };
}
