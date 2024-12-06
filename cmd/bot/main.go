package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/bl1nk/telegram-voice-to-text/internal/bot"
	"github.com/bl1nk/telegram-voice-to-text/internal/transcriber"
	"github.com/sethvargo/go-envconfig"
)

type config struct {
	TelegramBotToken string  `env:"TELEGRAM_BOT_TOKEN"`
	OpenAIAPIKey     string  `env:"OPENAI_API_KEY"`
	AllowedUserIDs   []int64 `env:"ALLOWED_USER_IDS"`
}

func main() {
	ctx := context.Background()
	logger := slog.New(slog.NewTextHandler(os.Stderr, nil))

	var c config
	if err := envconfig.Process(ctx, &c); err != nil {
		logger.Error("process config", "error", err)
		os.Exit(1)
	}

	t := transcriber.New()

	b, err := bot.New(logger, c.TelegramBotToken, c.AllowedUserIDs, t)
	if err != nil {
		logger.Error("new bot", "error", err)
		os.Exit(1)
	}

	logger.Info("starting bot")

	b.Start(ctx)
}
