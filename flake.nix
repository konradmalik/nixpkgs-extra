{
  description = "nixpkgs-extra km";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  nixConfig = {
    extra-substituters = [ "https://cerebre.cachix.org" ];
    extra-trusted-public-keys = [ "cerebre.cachix.org-1:BaUHZ8t0vpa0AXTStUWbaGHBv92Phc2lBC3CJlC5erM=" ];
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
          (
            system:
            function (
              import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              }
            )
          );
    in
    {
      overlays.default = final: prev: {
        extra = self.packages.${prev.system};
      };
      packages = forAllSystems (
        pkgs:
        let
          azurite = pkgs.callPackages ./pkgs/node-packages { };
          dotnet-sdk_8 = pkgs.callPackages ./pkgs/dotnet { };

          getLatest =
            attr:
            let
              # attr names sorts in ASC
              lastAlphKey = pkgs.lib.last (builtins.attrNames attr);
            in
            attr.${lastAlphKey};
        in
        dotnet-sdk_8
        // azurite
        // {
          azurite = getLatest azurite;
          dotnet-sdk_8 = getLatest dotnet-sdk_8;
        }
      );
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          name = "pkgs-extra";

          packages = [ pkgs.node2nix ];
        };
      });
      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
