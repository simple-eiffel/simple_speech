note
	description: "Test runner for simple_speech_gpu (needs the CUDA DLLs; see the ECF note)."
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
		local
			t: TEST_GPU_SPEECH
		do
			create t
			say ("simple_speech_gpu tests%N")
			run_test (agent t.test_decode_a_window_on_the_gpu, "decode_a_window_on_the_gpu")
			run_test (agent t.test_no_context_is_stable, "no_context_is_stable")
			run_test (agent t.test_already_read_prompt_is_harmless, "already_read_prompt_is_harmless")
			run_test (agent t.test_vad_hears_speech_and_silence, "vad_hears_speech_and_silence")
			run_test (agent t.test_vad_streaming_cost, "vad_streaming_cost")
			say ("%NResults: " + passed.out + " passed, " + failed.out + " failed%N")
		end

feature {NONE} -- Implementation

	passed, failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				say ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			say ("  FAIL: " + a_name + failure_detail + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

	failure_detail: STRING
		local
			l_utf: UTF_CONVERTER
		do
			create Result.make_empty
			if attached (create {EXCEPTION_MANAGER_FACTORY}).exception_manager.last_exception as al_e then
				Result.append (" [" + al_e.generator)
				if attached al_e.description as al_d then
					Result.append (": " + l_utf.string_32_to_utf_8_string_8 (al_d))
				end
				Result.append ("]")
			end
		end

	say (a_text: STRING)
		do
			io.put_string (a_text)
			io.output.flush
		end

end
