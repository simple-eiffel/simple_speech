note
	description: "[
		TEST_DIARIZATION - Tests for SHERPA_DIARIZATION speaker diarization.

		Tests:
		- Model path validation
		- Audio file handling (WAV and video)
		- DBC contract verification
	]"
	author: "Larry Rix"
	date: "$Date$"

class
	TEST_DIARIZATION

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		do
			print ("=== SHERPA_DIARIZATION Tests ===%N%N")

			test_model_path_validation
			test_file_extension_helper
			test_temp_directory
			test_initialization
			test_diarize_wav
			test_diarize_media_video

			print ("%N=== All Tests Complete ===%N")
		end

feature -- Tests

	test_model_path_validation
			-- Test that invalid model paths are caught.
		local
			l_diar: SHERPA_DIARIZATION
		do
			print ("Test: Model path validation%N")

			-- Try with non-existent paths
			create l_diar.make ("nonexistent_seg.onnx", "nonexistent_emb.onnx")

			if l_diar.is_initialized then
				print ("  FAIL: Should not initialize with missing models%N")
			else
				print ("  PASS: Correctly rejected missing models%N")
				if l_diar.has_error then
					print ("  Error message: " + l_diar.last_error.to_string_8 + "%N")
				end
			end
		end

	test_file_extension_helper
			-- Test the file_extension helper function.
		local
			l_diar: SHERPA_DIARIZATION
			l_ext: STRING_32
		do
			print ("%NTest: file_extension helper%N")

			create l_diar.make ("dummy", "dummy")  -- Will fail but we can test helper

			l_ext := l_diar.file_extension ("test.wav")
			if l_ext.is_equal ("wav") then
				print ("  PASS: wav extension detected%N")
			else
				print ("  FAIL: expected 'wav', got '" + l_ext.to_string_8 + "'%N")
			end

			l_ext := l_diar.file_extension ("video.MP4")
			if l_ext.as_lower.is_equal ("mp4") then
				print ("  PASS: MP4 extension detected%N")
			else
				print ("  FAIL: expected 'mp4', got '" + l_ext.to_string_8 + "'%N")
			end

			l_ext := l_diar.file_extension ("no_extension")
			if l_ext.is_empty then
				print ("  PASS: Empty extension for no-extension file%N")
			else
				print ("  FAIL: expected empty, got '" + l_ext.to_string_8 + "'%N")
			end
		end

	test_temp_directory
			-- Test temp_directory returns valid path.
		local
			l_diar: SHERPA_DIARIZATION
			l_temp: STRING_32
		do
			print ("%NTest: temp_directory%N")

			create l_diar.make ("dummy", "dummy")
			l_temp := l_diar.temp_directory

			if not l_temp.is_empty then
				print ("  PASS: temp_directory = " + l_temp.to_string_8 + "%N")
			else
				print ("  FAIL: temp_directory is empty%N")
			end
		end

	test_initialization
			-- Test initialization with real models if available.
		local
			l_diar: SHERPA_DIARIZATION
			l_seg_model, l_emb_model: STRING_32
		do
			print ("%NTest: Initialization with real models%N")

			l_seg_model := models_directory + "\sherpa-onnx-pyannote-segmentation-3-0\model.onnx"
			l_emb_model := models_directory + "\3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx"

			create l_diar.make (l_seg_model, l_emb_model)

			if l_diar.is_initialized then
				print ("  PASS: Initialized with real models%N")
				print ("  Sample rate: " + l_diar.expected_sample_rate.out + " Hz%N")
				l_diar.dispose
			else
				print ("  SKIP: Models not available at " + models_directory.to_string_8 + "%N")
				if l_diar.has_error then
					print ("  Reason: " + l_diar.last_error.to_string_8 + "%N")
				end
			end
		end

	test_diarize_wav
			-- Test diarization of WAV file.
		local
			l_diar: SHERPA_DIARIZATION
			l_seg_model, l_emb_model: STRING_32
			l_test_wav: STRING_32
			l_segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_file: RAW_FILE
		do
			print ("%NTest: Diarize WAV file%N")

			l_seg_model := models_directory + "\sherpa-onnx-pyannote-segmentation-3-0\model.onnx"
			l_emb_model := models_directory + "\3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx"
			l_test_wav := test_samples_directory + "\test_audio.wav"

			create l_file.make_with_name (l_test_wav)
			if not l_file.exists then
				print ("  SKIP: Test WAV not found at " + l_test_wav.to_string_8 + "%N")
			else
				create l_diar.make (l_seg_model, l_emb_model)
				if not l_diar.is_initialized then
					print ("  SKIP: Could not initialize diarization%N")
				else
					l_segments := l_diar.diarize (l_test_wav)

					if l_diar.has_error then
						print ("  FAIL: " + l_diar.last_error.to_string_8 + "%N")
					else
						print ("  PASS: Found " + l_segments.count.out + " speaker segments%N")
						-- Show first few segments
						across l_segments as seg loop
							if @seg.cursor_index <= 3 then
								if attached seg.speaker_label as lbl then
									print ("    [" + lbl.to_string_8 + "] " +
									       seg.start_time.out + "s - " + seg.end_time.out + "s%N")
								else
									print ("    [unknown] " +
									       seg.start_time.out + "s - " + seg.end_time.out + "s%N")
								end
							end
						end
					end
					l_diar.dispose
				end
			end
		end

	test_diarize_media_video
			-- Test diarization of video file (requires ffmpeg extraction).
		local
			l_diar: SHERPA_DIARIZATION
			l_seg_model, l_emb_model: STRING_32
			l_test_video: STRING_32
			l_segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_file: RAW_FILE
		do
			print ("%NTest: Diarize video file (MP4)%N")

			l_seg_model := models_directory + "\sherpa-onnx-pyannote-segmentation-3-0\model.onnx"
			l_emb_model := models_directory + "\3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx"
			l_test_video := test_samples_directory + "\test_video.mp4"

			create l_file.make_with_name (l_test_video)
			if not l_file.exists then
				-- No external fallback - tests must use local samples only
				print ("  SKIP: Test video not found at " + l_test_video.to_string_8 + "%N")
				print ("        Place test_video.mp4 in testing/samples/ directory%N")
			else
				create l_diar.make (l_seg_model, l_emb_model)
				if not l_diar.is_initialized then
					print ("  SKIP: Could not initialize diarization%N")
				else
					print ("  Processing: " + l_test_video.to_string_8 + "%N")
					l_segments := l_diar.diarize_media (l_test_video)

					if l_diar.has_error then
						print ("  FAIL: " + l_diar.last_error.to_string_8 + "%N")
					else
						print ("  PASS: Found " + l_segments.count.out + " speaker segments%N")
						-- Show first few segments
						across l_segments as seg loop
							if @seg.cursor_index <= 5 then
								if attached seg.speaker_label as lbl then
									print ("    [" + lbl.to_string_8 + "] " +
									       seg.start_time.out + "s - " + seg.end_time.out + "s%N")
								else
									print ("    [unknown] " +
									       seg.start_time.out + "s - " + seg.end_time.out + "s%N")
								end
							end
						end
					end
					l_diar.dispose
				end
			end
		end

feature {NONE} -- Helpers

	models_directory: STRING_32
			-- VoxCraft models directory.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.item ("PROGRAMDATA") as pd then
				Result := pd.to_string_32 + "\VoxCraft\models"
			else
				Result := "C:\ProgramData\VoxCraft\models"
			end
		end

	test_samples_directory: STRING_32
			-- Test samples directory.
		do
			Result := "D:\prod\simple_speech\testing\samples"
		end

end
