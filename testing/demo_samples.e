note
	description: "Demo: Test various audio sample types"
	author: "Larry Rix"

class
	DEMO_SAMPLES

create
	make

feature {NONE} -- Initialization

	make
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_len: INTEGER
		do
			print ("=== Simple Speech Sample Testing ===%N%N")
			passed := 0
			failed := 0
			
			-- Test 1: Mono 16kHz
			print ("1. Mono 16kHz (30s clip)...%N")
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/mono/sintel_clip_30s.wav")
				report_result ("Mono 16kHz", segments.count)
				speech.dispose
			else
				report_failure ("Mono 16kHz", "Model failed to load")
			end
			
			-- Test 2: Different sample rate
			print ("%N2. Different sample rates...%N")
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/mono/sintel_mono_8k.wav")
				report_result ("8kHz sample rate", segments.count)
				speech.dispose
			end
			
			-- Test 3: Noisy audio
			print ("%N3. Noisy audio...%N")
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/noisy/sintel_clip_noisy_light.wav")
				report_result ("Light noise", segments.count)
				
				segments := speech.transcribe_file ("testing/samples/noisy/sintel_clip_noisy_heavy.wav")
				report_result ("Heavy noise", segments.count)
				speech.dispose
			end
			
			-- Test 4: LibriSpeech
			print ("%N4. LibriSpeech samples...%N")
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/librispeech/librispeech_sample1.wav")
				report_result ("LibriSpeech sample", segments.count)
				if segments.count > 0 then
					l_len := segments[1].text.count.min (80)
					print ("   Text: " + segments[1].text.to_string_8.substring (1, l_len) + "...%N")
				end
				speech.dispose
			end
			
			-- Test 5: Blender movies
			print ("%N5. Blender Open Movies...%N")
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/mono/elephants_clip_30s.wav")
				report_result ("Elephants Dream", segments.count)
				
				segments := speech.transcribe_file ("testing/samples/mono/tears_clip_30s.wav")
				report_result ("Tears of Steel", segments.count)
				speech.dispose
			end
			
			-- Test 6: Multilingual (requires multilingual model)
			print ("%N6. Multilingual tests...%N")
			create speech.make ("models/ggml-base.bin")
			if speech.is_valid then
				-- Chinese
				speech.set_language ("zh")
				segments := speech.transcribe_file ("testing/samples/multilingual/chinese_shuidiaogetou.wav")
				report_result ("Chinese (short poem)", segments.count)
				if segments.count > 0 then
					l_len := segments[1].text.count.min (60)
					print ("   Text: " + segments[1].text.to_string_8.substring (1, l_len) + "%N")
				end
				
				-- Spanish
				speech.set_language ("es")
				segments := speech.transcribe_file ("testing/samples/multilingual/spanish_elbuenhombre.wav")
				report_result ("Spanish", segments.count)
				if segments.count > 0 then
					l_len := segments[1].text.count.min (60)
					print ("   Text: " + segments[1].text.to_string_8.substring (1, l_len) + "...%N")
				end
				
				speech.dispose
			else
				report_failure ("Multilingual", "Multilingual model not available")
			end
			
			-- Summary
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed = 0 then
				print ("ALL SAMPLE TESTS PASSED%N")
			else
				print ("SOME TESTS FAILED%N")
			end
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER
	
	report_result (a_name: STRING; a_count: INTEGER)
		do
			if a_count > 0 then
				print ("   PASS: " + a_name + " (" + a_count.out + " segments)%N")
				passed := passed + 1
			else
				print ("   FAIL: " + a_name + " (no segments)%N")
				failed := failed + 1
			end
		end
	
	report_failure (a_name: STRING; a_reason: STRING)
		do
			print ("   FAIL: " + a_name + " - " + a_reason + "%N")
			failed := failed + 1
		end

end
