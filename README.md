# simple_speech

Speech-to-text library for Eiffel, wrapping [whisper.cpp](https://github.com/ggml-org/whisper.cpp).

## Features

- **Local/Offline** - No cloud API needed, runs entirely on your machine
- **99+ Languages** - Supports all languages from OpenAI Whisper
- **Timestamps** - Word and segment-level timing
- **Translation** - Translate to English from any language
- **Export Formats** - VTT, SRT, JSON, TXT
- **Loose Coupling** - SPEECH_ENGINE abstraction allows swapping backends

## Status

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 0 | Foundation Setup | ✅ Complete |
| Phase 1 | Core Transcription | ✅ Complete |
| Phase 2 | Export Formats | ✅ Complete |
| Phase 3 | Video Pipeline | ⏳ Pending |
| Phase 4 | AI Enhancement | ⏳ Pending |
| Phase 5 | Batch Processing | ⏳ Pending |
| Phase 6 | Real-Time Streaming | ⏳ Pending |

## Quick Start

```eiffel
-- Transcribe audio file
create speech.make ("models/ggml-base.en.bin")
segments := speech.transcribe_file ("audio.wav")
across segments as seg loop
    print (seg.start_time_formatted + " " + seg.text + "%N")
end

-- Export to subtitles
create exporter.make (segments)
exporter.export_vtt ("captions.vtt")
        .export_srt ("captions.srt")
        .export_json ("captions.json")
```

## Requirements

- EiffelStudio 25.02+
- whisper.lib (build from whisper.cpp v1.8.2)
- Model file (see Models section)

## Models

| Model | Size | Speed | Use Case |
|-------|------|-------|----------|
| ggml-base.en.bin | 142 MB | Fast | English only |
| ggml-base.bin | 142 MB | Fast | 99+ languages |
| ggml-tiny.en.bin | 39 MB | Fastest | Quick tests |
| ggml-small.en.bin | 466 MB | Medium | Higher accuracy |

Download from [HuggingFace](https://huggingface.co/ggerganov/whisper.cpp).

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

## Test Coverage

- 14 unit tests (segments, speech, export)
- 9 sample tests (various audio types)
- Tested with: mono/stereo, 8kHz-48kHz, noisy audio, 4 languages

## License

MIT License - See LICENSE file

## Credits

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) by Georgi Gerganov
- [OpenAI Whisper](https://github.com/openai/whisper)
- Test audio from [Blender Foundation](https://www.blender.org/about/projects/), [LibriVox](https://librivox.org/)
