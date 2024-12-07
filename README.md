# Telegram Voice to Text Bot

A Telegram bot that converts voice messages to text using OpenAI's Whisper model using the audio API.

Voice messages can be sent to the bot directly to be transcribed or forwarded from other chats.

## Configuration

Set the following environment variables:

- `TELEGRAM_BOT_TOKEN`: Your Telegram bot token.
- `OPENAI_API_KEY`: Your OpenAI API key.
- `ALLOWED_USER_IDS`: Comma-separated list of Telegram user IDs.
  Messages sent to the bot are logged and include the user ID.

## Deployment

The `flake.nix` exposes a NixOS module that can be imported for easy deployment.

Assuming the necessary environment variables have been configured and placed in
`/etc/telegram-voice-to-text.env` on the host:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    telegram-voice-to-text.url = "github:bl1nk/telegram-voice-to-text";  # 1
  };

  outputs = {
    self,
    nixpkgs,
    telegram-voice-to-text,
    ...
  }: {
    nixosConfigurations.target = nixpkgs.lib.nixosSystem {
      modules = [
        telegram-voice-to-text.nixosModules.default                      # 2
        {
          services.telegram-voice-to-text = {                            # 3
            enable = true;
            environmentFile = "/etc/telegram-voice-to-text.env";
          };
        }
      ];
    };
  };
}
```

1. Import the repository.
2. Import the module.
3. Configure the module.

## Development

- `nix develop` enters a development shell with all dependencies.
- `nix fmt` formats the nix and go code.
- `nix build` builds the project.
- `nix run` runs the project.
