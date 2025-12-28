note
	description: "[
		WHISPER_ENGINE - Speech-to-text engine using whisper.cpp.
		
		This class isolates all whisper.cpp API coupling.
		When whisper.cpp updates its API, only this file changes.
		
		Based on whisper.cpp v1.8.2 API.
		
		Uses a C wrapper (whisper_wrapper.c) to avoid struct-by-value
		complexity and Eiffel macro conflicts.
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
			language := "en"
			thread_count := 4
			translate_to_english := False
		ensure
			not_ready: not is_ready
		end

feature -- Status

	is_ready: BOOLEAN
			-- Is the engine initialized and ready?
		do
			Result := ctx /= default_pointer
		end

	is_model_loaded: BOOLEAN
			-- Is a model loaded?
		do
			Result := ctx /= default_pointer
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
			l_path: C_STRING
		do
			create l_path.make (a_path.to_string_8)
			ctx := c_whisper_wrapper_init (l_path.item)
			if ctx /= default_pointer then
				create model_path.make_from_string_general (a_path)
				Result := True
			else
				last_error := {STRING_32} "Failed to load model: " + a_path.to_string_32
			end
		end

	transcribe (a_samples: ARRAY [REAL_32]; a_sample_rate: INTEGER): ARRAYED_LIST [SPEECH_SEGMENT]
			-- Transcribe audio samples.
		local
			l_special: SPECIAL [REAL_32]
			l_lang: C_STRING
			l_result: INTEGER
			i, n: INTEGER
			l_text_ptr: POINTER
			l_text: STRING_8
			l_t0, l_t1: INTEGER_64
			l_start, l_end: REAL_64
			l_segment: SPEECH_SEGMENT
			l_translate: INTEGER
		do
			create Result.make (10)
			
			if ctx /= default_pointer and then a_samples.count > 0 then
				-- Get native array pointer
				l_special := a_samples.to_special
				
				-- Set language
				create l_lang.make (language)
				
				-- Translate flag
				if translate_to_english then
					l_translate := 1
				else
					l_translate := 0
				end
				
				-- Run whisper transcription
				l_result := c_whisper_wrapper_transcribe (ctx, l_special.base_address, a_samples.count, thread_count, l_lang.item, l_translate)
				
				if l_result = 0 then
					-- Get segments
					n := c_whisper_wrapper_n_segments (ctx)
					from i := 0 until i >= n loop
						-- Get segment text
						l_text_ptr := c_whisper_wrapper_segment_text (ctx, i)
						if l_text_ptr /= default_pointer then
							create l_text.make_from_c (l_text_ptr)
							if not l_text.is_empty then
								-- Get timestamps (in centiseconds, convert to seconds)
								l_t0 := c_whisper_wrapper_segment_t0 (ctx, i)
								l_t1 := c_whisper_wrapper_segment_t1 (ctx, i)
								l_start := l_t0 / 100.0
								l_end := l_t1 / 100.0
								
								create l_segment.make (l_text, l_start, l_end)
								Result.extend (l_segment)
							end
						end
						i := i + 1
					end
				else
					last_error := {STRING_32} "Transcription failed with code: " + l_result.out
				end
			end
		end

	dispose
			-- Release whisper context.
		do
			if ctx /= default_pointer then
				c_whisper_wrapper_free (ctx)
				ctx := default_pointer
			end
			model_path := Void
		end

feature {NONE} -- Implementation

	ctx: POINTER
			-- Opaque whisper_context pointer.

feature {NONE} -- C Externals (whisper_wrapper.c)

	c_whisper_wrapper_init (a_path: POINTER): POINTER
			-- Initialize whisper context from model file.
		external
			"C (const char*): void* | %"whisper_wrapper.h%""
		alias
			"whisper_wrapper_init"
		end

	c_whisper_wrapper_transcribe (a_ctx, a_samples: POINTER; a_n_samples, a_n_threads: INTEGER; a_language: POINTER; a_translate: INTEGER): INTEGER
			-- Run full transcription pipeline.
		external
			"C (void*, const float*, int, int, const char*, int): int | %"whisper_wrapper.h%""
		alias
			"whisper_wrapper_transcribe"
		end

	c_whisper_wrapper_n_segments (a_ctx: POINTER): INTEGER
			-- Number of segments in transcription result.
		external
			"C (void*): int | %"whisper_wrapper.h%""
		alias
			"whisper_wrapper_n_segments"
		end

	c_whisper_wrapper_segment_text (a_ctx: POINTER; a_index: INTEGER): POINTER
			-- Get text of segment at index.
		external
			"C (void*, int): const char* | %"whisper_wrapper.h%""
		alias
			"whisper_wrapper_segment_text"
		end

	c_whisper_wrapper_segment_t0 (a_ctx: POINTER; a_index: INTEGER): INTEGER_64
			-- Get start timestamp (centiseconds) of segment at index.
		external
			"C (void*, int): int64_t | %"whisper_wrapper.h%""
		alias
			"whisper_wrapper_segment_t0"
		end

	c_whisper_wrapper_segment_t1 (a_ctx: POINTER; a_index: INTEGER): INTEGER_64
			-- Get end timestamp (centiseconds) of segment at index.
		external
			"C (void*, int): int64_t | %"whisper_wrapper.h%""
		alias
			"whisper_wrapper_segment_t1"
		end

	c_whisper_wrapper_free (a_ctx: POINTER)
			-- Free whisper context.
		external
			"C (void*) | %"whisper_wrapper.h%""
		alias
			"whisper_wrapper_free"
		end

invariant
	valid_threads: thread_count > 0
	language_set: language /= Void

end
