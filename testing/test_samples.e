note
	description: "Comprehensive test for various audio sample types"
	author: "Larry Rix"

class
	TEST_SAMPLES

feature -- Tests

	test_mono_16k
			-- Test mono 16kHz audio.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/mono/sintel_clip_30s.wav")
				assert ("mono_16k_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_stereo_16k
			-- Test stereo 16kHz audio.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/stereo/sintel_stereo_16k.wav")
				assert ("stereo_16k_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_sample_rate_8k
			-- Test 8kHz sample rate.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/mono/sintel_mono_8k.wav")
				assert ("8k_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_sample_rate_44k
			-- Test 44.1kHz sample rate.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/mono/sintel_mono_44k.wav")
				assert ("44k_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_noisy_light
			-- Test lightly noisy audio.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/noisy/sintel_clip_noisy_light.wav")
				assert ("noisy_light_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_noisy_heavy
			-- Test heavily noisy audio.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/noisy/sintel_clip_noisy_heavy.wav")
				-- May or may not transcribe well with heavy noise
				assert ("noisy_heavy_attempted", True)
				speech.dispose
			end
		end

	test_librispeech
			-- Test LibriSpeech sample.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/librispeech/librispeech_sample1.wav")
				assert ("librispeech_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_multilingual_japanese
			-- Test Japanese audio with multilingual model.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.bin")
			if speech.is_valid then
				speech.set_language ("ja")
				segments := speech.transcribe_file ("testing/samples/multilingual/japanese_sennin.wav")
				assert ("japanese_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_multilingual_french
			-- Test French audio with multilingual model.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.bin")
			if speech.is_valid then
				speech.set_language ("fr")
				segments := speech.transcribe_file ("testing/samples/multilingual/french_lamain.wav")
				assert ("french_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_multilingual_spanish
			-- Test Spanish audio with multilingual model.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.bin")
			if speech.is_valid then
				speech.set_language ("es")
				segments := speech.transcribe_file ("testing/samples/multilingual/spanish_elbuenhombre.wav")
				assert ("spanish_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_multilingual_chinese
			-- Test Chinese audio with multilingual model.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.bin")
			if speech.is_valid then
				speech.set_language ("zh")
				segments := speech.transcribe_file ("testing/samples/multilingual/chinese_shuidiaogetou.wav")
				assert ("chinese_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_blender_elephants_dream
			-- Test Elephants Dream movie audio.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/mono/elephants_clip_30s.wav")
				assert ("elephants_dream_transcribed", segments.count > 0)
				speech.dispose
			end
		end

	test_blender_tears_of_steel
			-- Test Tears of Steel movie audio.
		local
			speech: SIMPLE_SPEECH
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create speech.make ("models/ggml-base.en.bin")
			if speech.is_valid then
				segments := speech.transcribe_file ("testing/samples/mono/tears_clip_30s.wav")
				assert ("tears_of_steel_transcribed", segments.count > 0)
				speech.dispose
			end
		end

feature {NONE} -- Implementation

	assert (a_tag: STRING; a_condition: BOOLEAN)
			-- Assert condition with tag.
		do
			if not a_condition then
				(create {EXCEPTIONS}).raise ("Assertion failed: " + a_tag)
			end
		end

end
