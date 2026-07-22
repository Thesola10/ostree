{ description = "Cross-compilation platform for OSTree development";

  inputs."nixpkgs".url = github:NixOS/nixpkgs;

  outputs = { self, nixpkgs, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem
    (system:
    let pkgs = import nixpkgs {
      inherit system;
      config.allowUnsupportedSystem = true;
      overlays = [
        (self: super: {
          ostree1 = self.callPackage ./default.nix {};
        })
      ];
    };
    in
    { legacyPackages = pkgs;
      packages.default = pkgs.callPackage ./default.nix {};
      packages.defaultWin32 = pkgs.pkgsCross.mingwW64.callPackage ./default.nix {};
    });
}
