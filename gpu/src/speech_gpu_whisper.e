note
	description: "[
		Whisper on the GPU (CUDA build of whisper.cpp 1.8.2) for live, sliding-window
		recognition: one resident model, decode a few seconds of 16 kHz mono audio,
		get the words with their times. Decoding always sets no_context (overlapping
		windows must not inherit each other's text), and the prompt must hold only
		text ALREADY spoken - upcoming text makes whisper hallucinate (both found by
		the 2026-10-05 spike). Loading takes seconds; decode once to warm the GPU
		kernels before timing matters.

		`decode' blocks (seconds at worst): call it from a SCOOP worker processor,
		never from the GUI. The external is marked blocking so other processors
		keep running.
	]"
	author: "Larry Rix"

class
	SPEECH_GPU_WHISPER

create
	make

feature {NONE} -- Initialization

	make (a_model_path: READABLE_STRING_GENERAL; a_use_gpu: BOOLEAN)
			-- Load the ggml model at `a_model_path', on the GPU when `a_use_gpu'.
		require
			path_present: not a_model_path.is_empty
		local
			l_path: C_STRING
		do
			create last_words.make (0)
			create last_text.make_empty
			create last_error.make_empty
			thread_count := 4
			uses_gpu := a_use_gpu
			create l_path.make (utf_8 (a_model_path))
			context := c_load (l_path.item, a_use_gpu.to_integer)
			if context = default_pointer then
				last_error := {STRING_32} "could not load the model: " + a_model_path.to_string_32
			end
		ensure
			loaded_or_error: is_loaded xor not last_error.is_empty
			gpu_recorded: uses_gpu = a_use_gpu
		end

feature -- Access

	last_words: ARRAYED_LIST [SPEECH_TIMED_WORD]
			-- Words of the last `decode', in order.

	last_text: STRING_32
			-- Those words joined by single spaces.

	last_decode_ms: REAL_64
			-- Wall time of the last `decode'.

	last_error: STRING_32
			-- Why loading or the last `decode' failed (empty when it did not).

	thread_count: INTEGER
			-- CPU threads whisper may use alongside the GPU.

	uses_gpu: BOOLEAN

feature -- Status

	is_loaded: BOOLEAN
			-- Is a model resident?
		do
			Result := context /= default_pointer
		end

feature -- Commands

	decode (a_samples: SPECIAL [REAL_32]; a_count: INTEGER; a_prompt: READABLE_STRING_GENERAL)
			-- Recognize the first `a_count' samples of `a_samples' (16 kHz mono), biased by
			-- `a_prompt' (text already spoken; may be empty).
		require
			loaded: is_loaded
			count_valid: a_count > 0 and a_count <= a_samples.count
		local
			l_buffer: MANAGED_POINTER
			l_prompt: C_STRING
			i, l_rc: INTEGER
			l_start: REAL_64
		do
			create l_buffer.make (a_count * 4)
			from i := 0 until i >= a_count loop
				l_buffer.put_real_32 (a_samples [i], i * 4)
				i := i + 1
			end
			create l_prompt.make (utf_8 (a_prompt))
			l_start := now_ms
			l_rc := c_decode (context, l_buffer.item, a_count, l_prompt.item, thread_count)
			last_decode_ms := now_ms - l_start
			if l_rc = 0 then
				last_error := {STRING_32} ""
				collect_words (a_count / 16_000)
			else
				last_error := {STRING_32} "decode failed (" + l_rc.out + ")"
				create last_words.make (0)
				create last_text.make_empty
			end
		ensure
			ordered: across last_words as ic all ic.t0 >= 0 and ic.t1 >= ic.t0 end
			inside_the_audio: across last_words as ic all ic.t1 <= a_count / 16_000 end
			timed: last_decode_ms >= 0
		end

	set_thread_count (a_count: INTEGER)
		require
			sane: a_count >= 1 and a_count <= 64
		do
			thread_count := a_count
		ensure
			set: thread_count = a_count
		end

	close
			-- Free the model (GPU memory included).
		do
			if is_loaded then
				c_free (context)
				context := default_pointer
			end
		ensure
			closed: not is_loaded
		end

feature {NONE} -- Words

	collect_words (a_limit: REAL_64)
			-- Rebuild words from tokens: a token starting with a space starts a word. Bytes are
			-- gathered first and decoded per word, since a token may split a UTF-8 character.
			-- Times are clamped to `a_limit' seconds: whisper pads every window to 30 s and now
			-- and then stamps the last word past the audio it was given.
		local
			l_seg, l_tok, l_segments, l_tokens, l_n, i: INTEGER
			l_buffer: MANAGED_POINTER
			l_piece, l_word: STRING_8
			l_t0, l_t1, l_p: REAL_64
		do
			create last_words.make (16)
			create last_text.make_empty
			create l_word.make_empty
			create l_buffer.make (512)
			l_segments := c_n_segments (context)
			from l_seg := 0 until l_seg >= l_segments loop
				l_tokens := c_n_tokens (context, l_seg)
				from l_tok := 0 until l_tok >= l_tokens loop
					if c_is_special (context, l_seg, l_tok) = 0 then
						l_n := c_token_text (context, l_seg, l_tok, l_buffer.item, 512)
						create l_piece.make (l_n)
						from i := 0 until i >= l_n loop
							l_piece.append_character (l_buffer.read_character (i))
							i := i + 1
						end
						if not l_piece.is_empty and then l_piece [1] = ' ' and then not l_word.is_empty then
							flush_word (l_word, l_t0, l_t1, l_p)
							l_word.wipe_out
						end
						if l_word.is_empty then
							l_t0 := c_token_t0 (context, l_seg, l_tok).max (0.0).min (a_limit)
							l_p := c_token_p (context, l_seg, l_tok)
						else
							l_p := l_p.min (c_token_p (context, l_seg, l_tok))
						end
						l_word.append (l_piece)
						l_t1 := c_token_t1 (context, l_seg, l_tok).min (a_limit)
					end
					l_tok := l_tok + 1
				end
				l_seg := l_seg + 1
			end
			if not l_word.is_empty then
				flush_word (l_word, l_t0, l_t1, l_p)
			end
		end

	flush_word (a_bytes: STRING_8; a_t0, a_t1, a_p: REAL_64)
			-- Add the word whose UTF-8 bytes are `a_bytes'.
		local
			l_text: STRING_32
		do
			l_text := (create {UTF_CONVERTER}).utf_8_string_8_to_string_32 (a_bytes)
			l_text.left_adjust
			l_text.right_adjust
			if not l_text.is_empty then
				last_words.extend (create {SPEECH_TIMED_WORD}.make (l_text, a_t0, a_t1.max (a_t0), a_p.max (0.0).min (1.0)))
				if not last_text.is_empty then
					last_text.append_character (' ')
				end
				last_text.append (l_text)
			end
		end

feature {NONE} -- Implementation

	context: POINTER
			-- The native whisper context.

	utf_8 (a_text: READABLE_STRING_GENERAL): STRING_8
		do
			Result := (create {UTF_CONVERTER}).string_32_to_utf_8_string_8 (a_text.to_string_32)
		end

	now_ms: REAL_64
		external "C inline use <windows.h>"
		alias "LARGE_INTEGER f, c; QueryPerformanceFrequency (&f); QueryPerformanceCounter (&c); return (EIF_REAL_64) c.QuadPart * 1000.0 / (EIF_REAL_64) f.QuadPart;"
		end

feature {NONE} -- Externals

	c_load (a_path: POINTER; a_gpu: INTEGER): POINTER
		external "C blocking inline use %"speech_gpu.h%""
		alias "return speech_gpu_whisper_load((const char*)$a_path, $a_gpu);"
		end

	c_free (a_ctx: POINTER)
		external "C inline use %"speech_gpu.h%""
		alias "speech_gpu_whisper_free($a_ctx);"
		end

	c_decode (a_ctx, a_samples: POINTER; a_count: INTEGER; a_prompt: POINTER; a_threads: INTEGER): INTEGER
		external "C blocking inline use %"speech_gpu.h%""
		alias "return speech_gpu_whisper_decode($a_ctx, (const float*)$a_samples, $a_count, (const char*)$a_prompt, $a_threads);"
		end

	c_n_segments (a_ctx: POINTER): INTEGER
		external "C inline use %"speech_gpu.h%""
		alias "return speech_gpu_n_segments($a_ctx);"
		end

	c_n_tokens (a_ctx: POINTER; a_seg: INTEGER): INTEGER
		external "C inline use %"speech_gpu.h%""
		alias "return speech_gpu_n_tokens($a_ctx, $a_seg);"
		end

	c_is_special (a_ctx: POINTER; a_seg, a_tok: INTEGER): INTEGER
		external "C inline use %"speech_gpu.h%""
		alias "return speech_gpu_token_is_special($a_ctx, $a_seg, $a_tok);"
		end

	c_token_text (a_ctx: POINTER; a_seg, a_tok: INTEGER; a_out: POINTER; a_cap: INTEGER): INTEGER
		external "C inline use %"speech_gpu.h%""
		alias "return speech_gpu_token_text($a_ctx, $a_seg, $a_tok, (char*)$a_out, $a_cap);"
		end

	c_token_t0 (a_ctx: POINTER; a_seg, a_tok: INTEGER): REAL_64
		external "C inline use %"speech_gpu.h%""
		alias "return speech_gpu_token_t0($a_ctx, $a_seg, $a_tok);"
		end

	c_token_t1 (a_ctx: POINTER; a_seg, a_tok: INTEGER): REAL_64
		external "C inline use %"speech_gpu.h%""
		alias "return speech_gpu_token_t1($a_ctx, $a_seg, $a_tok);"
		end

	c_token_p (a_ctx: POINTER; a_seg, a_tok: INTEGER): REAL_64
		external "C inline use %"speech_gpu.h%""
		alias "return speech_gpu_token_p($a_ctx, $a_seg, $a_tok);"
		end

invariant
	threads_sane: thread_count >= 1

end
