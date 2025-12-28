note
	description: "Tests for SIMPLE_SPEECH facade"
	author: "Larry Rix"

class
	TEST_SPEECH

create
	default_create

feature -- Tests

	test_creation_stub
			-- Test creation (stub mode).
		local
			speech: SIMPLE_SPEECH
		do
			create speech.make ("models/ggml-base.en.bin")
			-- In stub mode, facade is created but may not be "valid"
			-- This is OK - real tests come in Phase 1 with actual model
			check created: speech /= Void end
			check has_engine: speech.is_model_loaded end  -- stub says True
		end

	test_fluent_config
			-- Test fluent configuration.
		local
			speech: SIMPLE_SPEECH
			result_speech: SIMPLE_SPEECH
		do
			create speech.make ("models/test.bin")
			result_speech := speech.set_language ("en")
			                       .set_threads (4)
			                       .set_translate (True)
			check fluent_self: result_speech = speech end
		end

end
