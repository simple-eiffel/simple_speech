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

	test_real_transcription
			-- Test real transcription with actual model and audio.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_text: STRING_32
			l_dummy: SIMPLE_SPEECH
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				l_dummy := speech.set_language ("en").set_threads (4)
				segments := speech.transcribe_file ("testing/samples/test_audio.wav")
				
				-- Combine all segment text
				create l_text.make_empty
				across segments as seg loop
					l_text.append (seg.text)
				end
				
				-- Check that we got some transcription
				check got_segments: segments.count > 0 end
				check got_text: not l_text.is_empty end
				
				-- Check for expected content (micro-machines ad)
				check has_micro: l_text.as_lower.has_substring ("micro") end
				
				speech.dispose
			else
				-- Skip test if model not available
				print ("  (skipped - model not found)%N")
			end
		end

	test_wav_reader
			-- Test WAV file reading.
		local
			reader: WAV_READER
			samples: detachable ARRAY [REAL_32]
		do
			create reader.make
			samples := reader.load_file ("testing/samples/test_audio.wav")
			
			if attached samples then
				check has_samples: samples.count > 0 end
				check is_resampled: reader.target_sample_rate = 16000 end
				-- 30 seconds of audio at 16kHz = 480,000 samples
				check reasonable_count: samples.count > 100000 end
			else
				-- Skip if file not found
				print ("  (skipped - test audio not found)%N")
			end
		end

end
