# S03 - Contracts: simple_speech

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_speech
**Date:** 2026-01-23

## SIMPLE_SPEECH Contracts

### Initialization

```eiffel
make (a_model_path: READABLE_STRING_GENERAL)
    require
        path_not_empty: not a_model_path.is_empty
    ensure
        engine_set: engine /= Void

make_with_engine (an_engine: SPEECH_ENGINE)
    require
        engine_not_void: an_engine /= Void
    ensure
        engine_set: engine = an_engine
```

### Status Queries

```eiffel
is_valid: BOOLEAN
    -- Is the speech engine ready to transcribe?
    do
        Result := engine.is_ready
    end

is_model_loaded: BOOLEAN
    -- Is a model loaded?
    do
        Result := engine.is_model_loaded
    end
```

### Configuration Commands

```eiffel
set_language (a_language: READABLE_STRING_GENERAL)
    require
        language_not_empty: not a_language.is_empty

set_threads (a_count: INTEGER)
    require
        positive: a_count > 0

set_translate (a_translate: BOOLEAN)
    -- No precondition
```

### Fluent Configuration

```eiffel
with_language (a_language: READABLE_STRING_GENERAL): like Current
    require
        language_not_empty: not a_language.is_empty
    ensure
        result_is_current: Result = Current

with_threads (a_count: INTEGER): like Current
    require
        positive: a_count > 0
    ensure
        result_is_current: Result = Current

with_translate (a_translate: BOOLEAN): like Current
    ensure
        result_is_current: Result = Current
```

### Transcription Operations

```eiffel
transcribe_file (a_wav_path: READABLE_STRING_GENERAL): ARRAYED_LIST [SPEECH_SEGMENT]
    require
        valid: is_valid
        path_not_empty: not a_wav_path.is_empty
    ensure
        result_exists: Result /= Void

transcribe_pcm (a_samples: ARRAY [REAL_32]; a_sample_rate: INTEGER): ARRAYED_LIST [SPEECH_SEGMENT]
    require
        valid: is_valid
        samples_not_empty: not a_samples.is_empty
        valid_rate: a_sample_rate > 0
    ensure
        result_exists: Result /= Void
```

## SPEECH_SEGMENT Contracts

```eiffel
text: STRING_32
    -- Transcribed text content

start_ms: INTEGER_64
    -- Start time in milliseconds
    ensure
        non_negative: Result >= 0

end_ms: INTEGER_64
    -- End time in milliseconds
    ensure
        after_start: Result >= start_ms

duration_ms: INTEGER_64
    -- Duration in milliseconds
    ensure
        definition: Result = end_ms - start_ms
```

## Invariants

```eiffel
class SIMPLE_SPEECH
invariant
    engine_exists: engine /= Void
end

class SPEECH_SEGMENT
invariant
    valid_timing: end_ms >= start_ms
    text_exists: text /= Void
end
```
