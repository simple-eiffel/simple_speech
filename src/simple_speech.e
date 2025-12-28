note
	description: "[
		SIMPLE_SPEECH - Main facade for speech-to-text operations.
		
		Swiss Army knife speech-to-text library with:
		- File transcription (WAV)
		- PCM sample transcription
		- Multi-language support (99+ via whisper)
		- Configurable threading
		- Optional translation to English
		
		Example:
			speech: SIMPLE_SPEECH
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("audio.wav")
				across segments as seg loop
					print (seg.text + "%N")
				end
			end
		
		Architecture:
		- Uses SPEECH_ENGINE abstraction for loose coupling
		- Default engine: WHISPER_ENGINE (whisper.cpp)
		- Engine can be injected for testing or alternative backends
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SPEECH

create
	make,
	make_with_engine

feature {NONE} -- Initialization

	make (a_model_path: READABLE_STRING_GENERAL)
			-- Create with default WHISPER_ENGINE.
		require
			path_not_empty: not a_model_path.is_empty
		local
			l_engine: WHISPER_ENGINE
		do
			create l_engine.make
			engine := l_engine
			create wav_reader.make
			if not engine.load_model (a_model_path) then
				last_error := engine.last_error
			end
		ensure
			engine_set: engine /= Void
		end

	make_with_engine (an_engine: SPEECH_ENGINE)
			-- Create with custom engine (for testing or alternative backends).
		require
			engine_not_void: an_engine /= Void
		do
			engine := an_engine
			create wav_reader.make
		ensure
			engine_set: engine = an_engine
		end

feature -- Status

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

	last_error: detachable STRING_32
			-- Last error message.

feature -- Configuration (Fluent)

	set_language (a_language: READABLE_STRING_GENERAL): like Current
			-- Set source language (e.g., "en", "es", "auto").
		require
			language_not_empty: not a_language.is_empty
		do
			engine.set_language (a_language)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_threads (a_count: INTEGER): like Current
			-- Set number of CPU threads.
		require
			positive: a_count > 0
		do
			engine.set_threads (a_count)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_translate (a_translate: BOOLEAN): like Current
			-- Enable/disable translation to English.
		do
			engine.set_translate (a_translate)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Operations

	transcribe_file (a_wav_path: READABLE_STRING_GENERAL): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcribe WAV file to segments.
		require
			valid: is_valid
			path_not_empty: not a_wav_path.is_empty
		local
			l_samples: detachable ARRAY [REAL_32]
		do
			l_samples := wav_reader.load_file (a_wav_path)
			if attached l_samples as samples then
				Result := engine.transcribe (samples, wav_reader.target_sample_rate)
			else
				last_error := wav_reader.last_error
				create Result.make (0)
			end
		ensure
			result_exists: Result /= Void
		end

	transcribe_pcm (a_samples: ARRAY [REAL_32]; a_sample_rate: INTEGER): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcribe raw PCM samples.
		require
			valid: is_valid
			samples_not_empty: not a_samples.is_empty
			valid_rate: a_sample_rate > 0
		do
			Result := engine.transcribe (a_samples, a_sample_rate)
		ensure
			result_exists: Result /= Void
		end

feature -- Cleanup

	dispose
			-- Release all resources.
		do
			engine.dispose
		end

feature {NONE} -- Implementation

	engine: SPEECH_ENGINE
			-- The underlying speech engine.

	wav_reader: WAV_READER
			-- WAV file reader.

invariant
	engine_exists: engine /= Void

end
