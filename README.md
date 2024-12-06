# Telegram Voice to Text Bot

A Telegram bot that converts voice messages to text using OpenAI's Whisper model using the audio API.

Voice messages can be sent to the bot directly to be transcribed or forwarded from other chats.

## Configuration

Set the following environment variables:

- `TELEGRAM_BOT_TOKEN`: Your Telegram bot token.
- `OPENAI_API_KEY`: Your OpenAI API key.
- `ALLOWED_USERS`: Comma-separated list of Telegram user IDs.
   The Bot logs messages it receives from users.
   The user ID is included in the log message.

## Development

- `nix develop` enters a development shell with all dependencies.
- `nix fmt` formats the nix and go code.
- `nix build` builds the project.
- `nix run` runs the project.
