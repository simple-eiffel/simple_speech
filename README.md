# simple_speech

Speech-to-text library for Eiffel, wrapping [whisper.cpp](https://github.com/ggml-org/whisper.cpp).

## Features

- **Local/Offline** - No cloud API needed, runs entirely on your machine
- **99+ Languages** - Supports all languages from OpenAI Whisper
- **Timestamps** - Word and segment-level timing
- **Translation** - Translate to English from any language
- **Loose Coupling** - SPEECH_ENGINE abstraction allows swapping backends

## Status

**Phase 0 Complete** - Skeleton compiles, tests pass

- [ ] Phase 1: Core transcription (whisper.cpp integration)
- [ ] Phase 2: Export formats (VTT, SRT, JSON)
- [ ] Phase 3: Video pipeline (simple_ffmpeg integration)
- [ ] Phase 4: AI enhancement (simple_ai_client translation)
- [ ] Phase 5: Batch processing
- [ ] Phase 6: Real-time streaming

## Quick Start

```eiffel
-- Phase 1+ (when whisper.lib integrated)
speech: SIMPLE_SPEECH
create speech.make ("models/ggml-base.en.bin")
segments := speech.transcribe_file ("audio.wav")
across segments as seg loop
    print (seg.start_time_formatted + " " + seg.text + "%N")
end
```

## Requirements

- EiffelStudio 25.02+
- whisper.lib (build from whisper.cpp v1.8.2)
- Model file (download via script)

## Setup

1. Build whisper.lib from whisper.cpp (or use prebuilt)
2. Download a model:
   ```bash
   ./download_models.sh base.en
   ```
3. Compile:
   ```bash
   ec -config simple_speech.ecf -target simple_speech_tests
   ```

## Architecture

```
SIMPLE_SPEECH (facade)
       |
       v
SPEECH_ENGINE* (deferred)
       |
       +-- WHISPER_ENGINE (whisper.cpp)
       +-- [future: VOSK_ENGINE, etc.]
```

All whisper.cpp coupling isolated to `src/engines/whisper_engine.e`.

## Model Sizes

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny.en | 39 MB | Fastest | Good |
| base.en | 142 MB | Fast | Better |
| small.en | 466 MB | Medium | High |
| medium.en | 1.5 GB | Slow | Very High |
| large-v3 | 2.9 GB | Slowest | Best |

## License

MIT License - See LICENSE file

## Credits

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) by Georgi Gerganov
- [OpenAI Whisper](https://github.com/openai/whisper)
