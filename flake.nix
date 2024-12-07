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
        default = pkgs.buildGoModule {
          inherit version;
          pname = "bot";
          src = ./.;
          subPackages = ["cmd/bot"];
          vendorHash = "sha256-X0i7x9mb4hW+QoXjV3NTiYqzVSuqWZt1jkYXdsU0OtE=";
        };
      }
    );
    defaultPackage = forAllSystems (system: self.packages.${system}.default);

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/bot";
      };
    });

    nixosModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.services.telegram-voice-to-text = {
        enable = lib.mkEnableOption "Telegram Voice to Text Bot";
        environmentFile = lib.mkOption {
          default = null;
          description = "Path to the environment file";
          type = with lib.types; nullOr path;
        };
      };
      config = lib.mkIf config.services.telegram-voice-to-text.enable {
        systemd.services.telegram-voice-to-text = {
          description = "Telegram Voice to Text Bot";
          wantedBy = ["multi-user.target"];
          after = ["network.target"];
          serviceConfig = {
            Type = "simple";
            DynamicUser = true;
            ExecStart = "${self.packages.${pkgs.system}.default}/bin/bot";
            Restart = "always";
            EnvironmentFile = config.services.telegram-voice-to-text.environmentFile;
          };
        };
      };
    };

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
