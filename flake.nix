{
  description = "A simple Go package";

  inputs.nixpkgs.url = "nixpkgs/nixos-24.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
    version = builtins.substring 0 8 lastModifiedDate;
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    devShells = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
      in {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            gotools
            go-tools
            gofumpt
          ];
        };
      }
    );

    packages = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
      in {
        telegram-voice-to-text = pkgs.buildGoModule {
          pname = "telegram-voice-to-text";
          inherit version;
          src = ./.;

          vendorHash = "sha256-iTUoag4ePnNXMaLXKeWyD3jroXwLvzUAxBvzLL3rNcE=";
        };
      }
    );

    defaultPackage = forAllSystems (system: self.packages.${system}.telegram-voice-to-text);

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.telegram-voice-to-text}/bin/telegram-voice-to-text";
      };
    });

    formatter = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.writeShellApplication {
          name = "format-all";
          runtimeInputs = with pkgs; [
            alejandra

            go
            gofumpt
          ];
          text = ''
            find . -name "*.nix" -exec alejandra -q {} +
            find . -name "*.go" -exec gofumpt -w {} +
          '';
        }
    );
  };
}
