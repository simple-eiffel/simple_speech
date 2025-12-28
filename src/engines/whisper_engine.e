note
	description: "[
		WHISPER_ENGINE - Speech-to-text engine using whisper.cpp.
		
		This class isolates all whisper.cpp API coupling.
		When whisper.cpp updates its API, only this file changes.
		
		Based on whisper.cpp v1.8.2 API.
		
		PHASE 0: Stub implementation (compiles but doesn't transcribe)
		PHASE 1: Real whisper.cpp integration via inline C externals
	]"
	author: "Larry Rix"

class
	WHISPER_ENGINE

inherit
	SPEECH_ENGINE

create
	make

feature {NONE} -- Initialization

	make
			-- Create engine (model not yet loaded).
		do
			language := "auto"
			thread_count := 4
			translate_to_english := False
			model_loaded := False
		ensure
			not_ready: not is_ready
		end

feature -- Status

	is_ready: BOOLEAN
			-- Is the engine initialized and ready?
		do
			Result := model_loaded
		end

	is_model_loaded: BOOLEAN
			-- Is a model loaded?
		do
			Result := model_loaded
		end

	last_error: detachable STRING_32
			-- Last error message.

	model_path: detachable STRING_32
			-- Path to loaded model.

feature -- Configuration

	language: STRING_8
			-- Source language code.

	thread_count: INTEGER
			-- Number of threads for inference.

	translate_to_english: BOOLEAN
			-- Translate output to English?

	set_language (a_language: READABLE_STRING_GENERAL)
			-- Set source language.
		do
			language := a_language.to_string_8
		ensure then
			language_set: language.same_string_general (a_language)
		end

	set_threads (a_count: INTEGER)
			-- Set thread count.
		do
			thread_count := a_count
		ensure then
			threads_set: thread_count = a_count
		end

	set_translate (a_translate: BOOLEAN)
			-- Enable/disable translation.
		do
			translate_to_english := a_translate
		ensure then
			translate_set: translate_to_english = a_translate
		end

feature -- Operations

	load_model (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Load whisper model from file.
		local
			l_path: STRING_8
		do
			l_path := a_path.to_string_8
			
			-- STUB: Simulate success (Phase 1 will use real whisper)
			-- TODO Phase 1: ctx := c_whisper_init_from_file (l_path.to_c)
			
			create model_path.make_from_string_general (a_path)
			model_loaded := True
			Result := True
		end

	transcribe (a_samples: ARRAY [REAL_32]; a_sample_rate: INTEGER): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcribe audio samples.
		do
			create Result.make (10)
			
			-- STUB: Return empty list (Phase 1 will use real whisper)
			-- TODO Phase 1: Implement with inline C
		end

	dispose
			-- Release whisper context.
		do
			if ctx /= default_pointer then
				-- TODO Phase 1: c_whisper_free (ctx)
				ctx := default_pointer
			end
			model_path := Void
			model_loaded := False
		end

feature {NONE} -- Implementation

	ctx: POINTER
			-- Opaque whisper_context pointer.

	model_loaded: BOOLEAN
			-- Stub flag: True when load_model was called.

feature {NONE} -- Inline C Externals (Phase 1)

	-- All whisper.cpp C API calls will go here in Phase 1.
	-- c_whisper_init_from_file (path: POINTER): POINTER
	-- c_whisper_full (ctx: POINTER; ...): INTEGER
	-- c_whisper_n_segments (ctx: POINTER): INTEGER
	-- c_whisper_segment_text (ctx: POINTER; i: INTEGER): POINTER
	-- c_whisper_segment_t0 (ctx: POINTER; i: INTEGER): INTEGER_64
	-- c_whisper_segment_t1 (ctx: POINTER; i: INTEGER): INTEGER_64
	-- c_whisper_free (ctx: POINTER)

invariant
	valid_threads: thread_count > 0
	language_set: language /= Void

end
