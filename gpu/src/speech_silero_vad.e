note
	description: "[
		Silero voice activity through whisper.cpp's ggml port (ggml-silero-*.bin), on the
		CPU. whisper_vad_detect_speech clears the model's recurrent state on every call,
		so a streaming caller scores a short TRAILING window (about half a second ending at
		the newest frame) and reads the probability of its last 32 ms chunk.
	]"
	author: "Larry Rix"

class
	SPEECH_SILERO_VAD

create
	make

feature {NONE} -- Initialization

	make (a_model_path: READABLE_STRING_GENERAL)
			-- Load the Silero model at `a_model_path'.
		require
			path_present: not a_model_path.is_empty
		local
			l_path: C_STRING
		do
			create last_error.make_empty
			create l_path.make ((create {UTF_CONVERTER}).string_32_to_utf_8_string_8 (a_model_path.to_string_32))
			context := c_load (l_path.item, 1)
			if context = default_pointer then
				last_error := {STRING_32} "could not load the voice model: " + a_model_path.to_string_32
			end
		ensure
			loaded_or_error: is_loaded xor not last_error.is_empty
		end

feature -- Constants

	Chunk_samples: INTEGER = 512
			-- The model's chunk: 32 ms at 16 kHz.

feature -- Access

	last_probability: REAL_64
			-- Speech probability of the last chunk scored by `score' (0 before any).

	last_error: STRING_32

feature -- Status

	is_loaded: BOOLEAN
		do
			Result := context /= default_pointer
		end

feature -- Commands

	score (a_samples: SPECIAL [REAL_32]; a_offset, a_count: INTEGER)
			-- Score samples `a_offset' .. `a_offset' + `a_count' - 1 (16 kHz mono); the
			-- probability of their last chunk becomes `last_probability'.
		require
			loaded: is_loaded
			window_inside: a_offset >= 0 and a_count >= Chunk_samples and a_offset + a_count <= a_samples.count
		local
			l_buffer: MANAGED_POINTER
			i: INTEGER
			l_p: REAL_64
		do
			create l_buffer.make (a_count * 4)
			from i := 0 until i >= a_count loop
				l_buffer.put_real_32 (a_samples [a_offset + i], i * 4)
				i := i + 1
			end
			l_p := c_last_probability (context, l_buffer.item, a_count)
			if l_p >= 0 then
				last_probability := l_p.min (1.0)
				last_error := {STRING_32} ""
			else
				last_probability := 0
				last_error := {STRING_32} "voice detection failed"
			end
		ensure
			probability_range: last_probability >= 0 and last_probability <= 1
		end

	close
		do
			if is_loaded then
				c_free (context)
				context := default_pointer
			end
		ensure
			closed: not is_loaded
		end

feature {NONE} -- Implementation

	context: POINTER

feature {NONE} -- Externals

	c_load (a_path: POINTER; a_threads: INTEGER): POINTER
		external "C blocking inline use %"speech_gpu.h%""
		alias "return speech_gpu_vad_load((const char*)$a_path, $a_threads);"
		end

	c_free (a_ctx: POINTER)
		external "C inline use %"speech_gpu.h%""
		alias "speech_gpu_vad_free($a_ctx);"
		end

	c_last_probability (a_ctx, a_samples: POINTER; a_count: INTEGER): REAL_64
		external "C inline use %"speech_gpu.h%""
		alias "return speech_gpu_vad_last_probability($a_ctx, (const float*)$a_samples, $a_count);"
		end

invariant
	probability_range: last_probability >= 0 and last_probability <= 1

end
