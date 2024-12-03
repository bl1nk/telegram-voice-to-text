package bot

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"slices"

	"github.com/bl1nk/telegram-voice-to-text/internal/transcriber"
	"github.com/go-telegram/bot"
	"github.com/go-telegram/bot/models"
)

type Bot struct {
	log          *slog.Logger
	client       *bot.Bot
	transcriber  *transcriber.Transcriber
	allowedUsers []int64
}

func New(log *slog.Logger, token string, allowedUsers []int64, transcriber *transcriber.Transcriber) (*Bot, error) {
	client, err := bot.New(token, bot.WithDefaultHandler(defaultHandler(log)))
	if err != nil {
		return nil, err
	}

	b := &Bot{
		log:          log,
		client:       client,
		allowedUsers: allowedUsers,
		transcriber:  transcriber,
	}

	b.client.RegisterHandler(bot.HandlerTypeMessageText, "/start", bot.MatchTypeExact, b.startHandler)
	b.client.RegisterHandlerMatchFunc(b.shouldHandleVoiceMessage, b.voiceHandler)

	return b, nil
}

func defaultHandler(log *slog.Logger) func(ctx context.Context, t *bot.Bot, update *models.Update) {
	return func(ctx context.Context, t *bot.Bot, update *models.Update) {
		log.Info("message received", "userID", update.Message.From.ID, "username", update.Message.From.Username, "text", update.Message.Text)
	}
}

func (b *Bot) startHandler(ctx context.Context, t *bot.Bot, update *models.Update) {
	if _, err := t.SendMessage(ctx, &bot.SendMessageParams{
		Text:   "Send or forward me a voice message and I will transcribe it for you.",
		ChatID: update.Message.Chat.ID,
	}); err != nil {
		b.log.Error("send message", "error", err)
	}
}

func (b *Bot) shouldHandleVoiceMessage(update *models.Update) bool {
	isAllowedUser := slices.Contains(b.allowedUsers, update.Message.From.ID)
	hasVoice := update.Message.Voice != nil
	return isAllowedUser && hasVoice
}

func (b *Bot) voiceHandler(ctx context.Context, t *bot.Bot, update *models.Update) {
	chatID := update.Message.Chat.ID

	// Get voice file info
	fileInfo, err := t.GetFile(ctx, &bot.GetFileParams{FileID: update.Message.Voice.FileID})
	if err != nil {
		b.sendError(ctx, chatID, fmt.Errorf("get file: %w", err))
		return
	}

	// Create temporary file
	tempFile, err := os.CreateTemp("", "voice-file-*.oga")
	if err != nil {
		b.sendError(ctx, chatID, fmt.Errorf("create temp file: %w", err))
		return
	}
	defer os.Remove(tempFile.Name())

	// Download the file
	resp, err := http.Get(t.FileDownloadLink(fileInfo))
	if err != nil {
		b.sendError(ctx, chatID, fmt.Errorf("download file: %w", err))
		return
	}
	defer resp.Body.Close()

	// Save to temp file
	_, err = io.Copy(tempFile, resp.Body)
	if err != nil {
		b.sendError(ctx, chatID, fmt.Errorf("copy file: %w", err))
		return
	}

	// Transcribe
	transcript, err := b.transcriber.Transcribe(tempFile.Name())
	if err != nil {
		b.sendError(ctx, chatID, fmt.Errorf("transcribe: %w", err))
		return
	}

	// Send transcription back to user
	if _, err := t.SendMessage(ctx, &bot.SendMessageParams{
		Text:   transcript,
		ChatID: update.Message.Chat.ID,
	}); err != nil {
		b.sendError(ctx, chatID, fmt.Errorf("send message: %w", err))
		return
	}
}

func (b *Bot) sendError(ctx context.Context, chatID int64, err error) {
	text := fmt.Sprintf("```\nError: %v\n```", err)
	if _, sendErr := b.client.SendMessage(ctx, &bot.SendMessageParams{
		ChatID: chatID,
		Text:   text,
	}); sendErr != nil {
		b.log.Error("send error", "error", sendErr, "original_error", err)
	}
}

func (b *Bot) Start(ctx context.Context) {
	b.client.Start(ctx)
}
