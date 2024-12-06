{
  description = "Telegram Voice to Text Bot";

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
        bot = pkgs.buildGoModule {
          inherit version;
          pname = "bot";
          src = ./.;
          subPackages = ["cmd/bot"];
          vendorHash = "sha256-X0i7x9mb4hW+QoXjV3NTiYqzVSuqWZt1jkYXdsU0OtE=";
        };
      }
    );

    defaultPackage = forAllSystems (system: self.packages.${system}.bot);

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.bot}/bin/bot";
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
