# S02 - Class Catalog: simple_speech

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_speech
**Date:** 2026-01-23

## Class Hierarchy

```
SIMPLE_SPEECH (facade)
|
+-- SPEECH_ENGINE (deferred)
|   +-- WHISPER_ENGINE
|
+-- SPEECH_SEGMENT
+-- WAV_READER
|
+-- Export
|   +-- SPEECH_EXPORTER
|   +-- VTT_EXPORTER
|   +-- SRT_EXPORTER
|   +-- JSON_EXPORTER
|
+-- Pipeline
|   +-- SPEECH_PIPELINE
|   +-- VIDEO_PIPELINE
|
+-- Async
|   +-- ASYNC_TRANSCRIBER
|
+-- Batch
|   +-- BATCH_PROCESSOR
|
+-- AI
|   +-- AI_ENHANCER
```

## Class Descriptions

### SIMPLE_SPEECH (Facade)
Main entry point providing speech-to-text transcription. Manages engine lifecycle and configuration.

**Creation:**
- `make (a_model_path)` - Create with default Whisper engine
- `make_with_engine (an_engine)` - Create with custom engine

### SPEECH_ENGINE (Deferred)
Abstract interface for speech recognition engines. Defines contract for transcription.

### WHISPER_ENGINE
Whisper.cpp implementation of SPEECH_ENGINE. Wraps native whisper.dll.

### SPEECH_SEGMENT
Represents a transcription segment with:
- Text content
- Start time (milliseconds)
- End time (milliseconds)
- Confidence score
- Language detected

### WAV_READER
Loads WAV audio files and extracts 16-bit PCM samples at 16kHz mono (Whisper requirement).

### Export Classes
- **VTT_EXPORTER** - WebVTT subtitle format
- **SRT_EXPORTER** - SubRip subtitle format
- **JSON_EXPORTER** - JSON with timing metadata

### Pipeline Classes
- **SPEECH_PIPELINE** - General transcription workflow
- **VIDEO_PIPELINE** - Video file to transcript (requires simple_ffmpeg)

### Async Classes
- **ASYNC_TRANSCRIBER** - Non-blocking transcription with callbacks

### Batch Classes
- **BATCH_PROCESSOR** - Process multiple files with progress tracking

### AI Classes
- **AI_ENHANCER** - LLM post-processing for error correction

## Class Count Summary
- Facade: 1
- Engines: 2
- Data: 2
- Export: 4
- Pipeline: 2
- Async: 1
- Batch: 1
- AI: 1
- **Total: ~14+ classes**
