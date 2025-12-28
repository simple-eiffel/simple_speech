note
	description: "[
		SPEECH_ENGINE - Deferred contract for speech-to-text engines.
		
		This abstraction layer allows swapping implementations:
		- WHISPER_ENGINE: whisper.cpp (default)
		- Future: VOSK_ENGINE, cloud APIs, etc.
		
		When whisper.cpp API changes, only the concrete engine changes.
		The facade (SIMPLE_SPEECH) remains stable.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SPEECH_ENGINE

feature -- Status

	is_ready: BOOLEAN
			-- Is the engine initialized and ready to transcribe?
		deferred
		end

	is_model_loaded: BOOLEAN
			-- Is a model currently loaded?
		deferred
		end

	last_error: detachable STRING_32
			-- Last error message, if any.
		deferred
		end

	model_path: detachable STRING_32
			-- Path to currently loaded model.
		deferred
		end

feature -- Configuration

	set_language (a_language: READABLE_STRING_GENERAL)
			-- Set source language (e.g., "en", "es", "auto").
		require
			language_not_empty: not a_language.is_empty
		deferred
		end

	set_threads (a_count: INTEGER)
			-- Set number of CPU threads for inference.
		require
			positive: a_count > 0
		deferred
		end

	set_translate (a_translate: BOOLEAN)
			-- Enable/disable translation to English.
		deferred
		end

feature -- Operations

	load_model (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Load model from file. Returns True on success.
		require
			path_not_empty: not a_path.is_empty
		deferred
		ensure
			loaded_implies_ready: Result implies is_model_loaded
		end

	transcribe (a_samples: ARRAY [REAL_32]; a_sample_rate: INTEGER): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcribe PCM audio samples.
		require
			ready: is_ready
			samples_not_empty: not a_samples.is_empty
			valid_sample_rate: a_sample_rate > 0
		deferred
		ensure
			result_exists: Result /= Void
		end

	dispose
			-- Release all resources.
		deferred
		end

end
