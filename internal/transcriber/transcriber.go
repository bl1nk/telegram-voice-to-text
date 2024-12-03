package transcriber

import (
	"context"
	"io"
	"os"

	"github.com/openai/openai-go"
)

type Transcriber struct {
	client *openai.Client
}

func New() *Transcriber {
	client := openai.NewClient()
	return &Transcriber{
		client: client,
	}
}

func (t *Transcriber) Transcribe(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	transcription, err := t.client.Audio.Transcriptions.New(context.Background(), openai.AudioTranscriptionNewParams{
		Model: openai.F(openai.AudioModelWhisper1),
		File:  openai.F[io.Reader](file),
	})
	if err != nil {
		return "", err
	}

	return transcription.Text, nil
}
