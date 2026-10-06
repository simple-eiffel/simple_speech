note
	description: "[
		Live GPU speech on a real recording (simple_prompter's larry_read_01.wav: Larry
		reading a test script, 16 kHz mono). Needs the CUDA build's DLLs beside the test
		exe and the CUDA runtime on PATH.
	]"
	author: "Larry Rix"

class
	TEST_GPU_SPEECH

inherit
	TEST_SET_BASE

feature -- Whisper

	test_decode_a_window_on_the_gpu
			-- 3.2-6.2 s: "This is a test of Simple Prompter, a ..." (words.tsv).
		local
			w: SPEECH_GPU_WHISPER
		do
			w := whisper
			assert_true ({STRING_32} "model on the GPU: " + w.last_error, w.is_loaded and w.uses_gpu)
			w.decode (recording, Rate * 3, "")
				-- warm the kernels, then decode the window that matters
			w.decode (window (3.2, 3.0), Rate * 3, "")
			print ("    [gpu] " + w.last_decode_ms.out + " ms: " + w.last_text.to_string_8 + "%N")
			assert_true ({STRING_32} "heard the test sentence: " + w.last_text, w.last_text.as_lower.has_substring ("test of"))
			assert_true ("several words", w.last_words.count >= 4)
			assert_true ("times inside the window", across w.last_words as ic all ic.t1 <= 3.2 end)
			assert_true ("warm decode under 250 ms: " + w.last_decode_ms.out, w.last_decode_ms < 250.0)
		end

	test_no_context_is_stable
			-- The same window twice gives the same words (spike gotcha 1: no carry-over).
		local
			w: SPEECH_GPU_WHISPER
			l_first: STRING_32
		do
			w := whisper
			w.decode (window (3.2, 3.0), Rate * 3, "")
			l_first := w.last_text.twin
			w.decode (window (3.2, 3.0), Rate * 3, "")
			assert_true ({STRING_32} "same text twice: [" + l_first + "] [" + w.last_text + "]", w.last_text.same_string (l_first))
		end

	test_already_read_prompt_is_harmless
			-- Biasing with the text before the window keeps the words (spike gotcha 2).
		local
			w: SPEECH_GPU_WHISPER
		do
			w := whisper
			w.decode (window (3.2, 3.0), Rate * 3, "Simple Prompter Read Test One.")
			assert_true ({STRING_32} "still heard: " + w.last_text, w.last_text.as_lower.has_substring ("test of"))
		end

feature -- Voice activity

	test_vad_hears_speech_and_silence
			-- 4.5-5.0 s is speech; 20.0-20.5 s is inside the instructed pause (19.17-22.85).
		local
			v: SPEECH_SILERO_VAD
		do
			create v.make (Vad_model)
			assert_true ({STRING_32} "voice model: " + v.last_error, v.is_loaded)
			v.score (recording, (4.5 * Rate).truncated_to_integer, Rate // 2)
			assert_true ("speech: " + v.last_probability.out, v.last_probability > 0.5)
			v.score (recording, (20.0 * Rate).truncated_to_integer, Rate // 2)
			assert_true ("silence: " + v.last_probability.out, v.last_probability < 0.2)
			v.close
		end

	test_vad_streaming_cost
			-- A half-second trailing window every 32 ms frame over 10 s costs a few ms per call.
		local
			v: SPEECH_SILERO_VAD
			l_start, l_ms: REAL_64
			l_end, l_calls: INTEGER
		do
			create v.make (Vad_model)
			l_start := now_ms
			from l_end := Rate // 2 until l_end > 10 * Rate loop
				v.score (recording, l_end - Rate // 2, Rate // 2)
				l_calls := l_calls + 1
				l_end := l_end + 512
			end
			l_ms := (now_ms - l_start) / l_calls
			print ("    [vad] " + l_calls.out + " calls, " + l_ms.out + " ms each%N")
			assert_true ("under 5 ms per frame: " + l_ms.out, l_ms < 5.0)
			v.close
		end

feature {NONE} -- Fixtures

	Rate: INTEGER = 16_000

	Model: STRING = "D:\prod\simple_speech\models\ggml-large-v3-turbo-q5_0.bin"
	Vad_model: STRING = "D:\prod\simple_speech\models\ggml-silero-v6.2.0.bin"
	Recording_path: STRING = "D:\prod\simple_prompter\testing\fixtures\larry_read_01.wav"

	whisper: SPEECH_GPU_WHISPER
			-- One resident model for the whole run.
		once
			create Result.make (Model, True)
		end

	recording: SPECIAL [REAL_32]
			-- The whole recording as floats (16-bit PCM WAV, "data" chunk).
		local
			l_file: RAW_FILE
			l_bytes: MANAGED_POINTER
			l_pos, l_data, l_size, i, l_n: INTEGER
		once
			create l_file.make_open_read (Recording_path)
			create l_bytes.make (l_file.count)
			l_file.read_to_managed_pointer (l_bytes, 0, l_file.count)
			l_file.close
			from l_pos := 12 until l_data > 0 or l_pos + 8 > l_bytes.count loop
				l_size := l_bytes.read_integer_32_le (l_pos + 4)
				if l_bytes.read_natural_8 (l_pos) = ('d').code.to_natural_8 and l_bytes.read_natural_8 (l_pos + 1) = ('a').code.to_natural_8
					and l_bytes.read_natural_8 (l_pos + 2) = ('t').code.to_natural_8 and l_bytes.read_natural_8 (l_pos + 3) = ('a').code.to_natural_8 then
					l_data := l_pos + 8
				else
					l_pos := l_pos + 8 + l_size
				end
			end
			l_n := ((l_bytes.count - l_data) // 2).max (0)
			create Result.make_filled (0, l_n)
			from i := 0 until i >= l_n loop
				Result [i] := (l_bytes.read_integer_16_le (l_data + 2 * i) / 32768.0).truncated_to_real
				i := i + 1
			end
		end

	window (a_start_s, a_length_s: REAL_64): SPECIAL [REAL_32]
			-- `a_length_s' seconds of the recording from `a_start_s'.
		local
			l_from, l_n, i: INTEGER
		do
			l_from := (a_start_s * Rate).truncated_to_integer
			l_n := (a_length_s * Rate).truncated_to_integer
			create Result.make_filled (0, l_n)
			from i := 0 until i >= l_n loop
				Result [i] := recording [l_from + i]
				i := i + 1
			end
		end

	now_ms: REAL_64
		external "C inline use <windows.h>"
		alias "LARGE_INTEGER f, c; QueryPerformanceFrequency (&f); QueryPerformanceCounter (&c); return (EIF_REAL_64) c.QuadPart * 1000.0 / (EIF_REAL_64) f.QuadPart;"
		end

end
