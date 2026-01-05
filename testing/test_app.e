note
	description: "Test application for simple_speech library"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
		do
			print ("Running simple_speech tests...%N%N")
			passed := 0
			failed := 0
			run_lib_tests
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_lib_tests
		do
			create lib_tests
			
			-- SPEECH_SEGMENT tests
			print ("--- SPEECH_SEGMENT Tests ---%N")
			run_test (agent lib_tests.test_segment_creation, "test_segment_creation")
			run_test (agent lib_tests.test_segment_timing, "test_segment_timing")
			run_test (agent lib_tests.test_segment_confidence, "test_segment_confidence")
			
			-- SPEECH_CHAPTER tests
			print ("%N--- SPEECH_CHAPTER Tests ---%N")
			run_test (agent lib_tests.test_chapter_creation, "test_chapter_creation")
			run_test (agent lib_tests.test_chapter_timing, "test_chapter_timing")
			
			-- Export tests
			print ("%N--- EXPORT Tests ---%N")
			run_test (agent lib_tests.test_vtt_exporter, "test_vtt_exporter")
			run_test (agent lib_tests.test_srt_exporter, "test_srt_exporter")
			run_test (agent lib_tests.test_json_exporter, "test_json_exporter")
			
			-- Detector tests
			print ("%N--- TRANSITION_DETECTOR Tests ---%N")
			run_test (agent lib_tests.test_detector_creation, "test_detector_creation")
			run_test (agent lib_tests.test_detector_sensitivity, "test_detector_sensitivity")
			run_test (agent lib_tests.test_detector_min_duration, "test_detector_min_duration")
			
			-- SPEECH_QUICK tests
			print ("%N--- SPEECH_QUICK Tests ---%N")
			run_test (agent lib_tests.test_quick_creation, "test_quick_creation")
			run_test (agent lib_tests.test_quick_status, "test_quick_status")
			
			-- Memory Monitor tests
			print ("%N--- MEMORY_MONITOR Tests ---%N")
			run_test (agent lib_tests.test_memory_monitor, "test_memory_monitor")

			-- Diarization tests
			print ("%N--- SHERPA_DIARIZATION Tests ---%N")
			run_diarization_tests
		end

	run_diarization_tests
			-- Run SHERPA_DIARIZATION tests.
		local
			l_diar_tests: TEST_DIARIZATION
		do
			create l_diar_tests.make
		end

feature {NONE} -- Test Infrastructure

	run_test (a_test: PROCEDURE; a_name: STRING)
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				a_test.call (Void)
				passed := passed + 1
				print ("[PASS] " + a_name + "%N")
			end
		rescue
			l_failed := True
			failed := failed + 1
			print ("[FAIL] " + a_name + "%N")
			retry
		end

	passed: INTEGER
	failed: INTEGER

feature {NONE} -- Test Objects

	lib_tests: LIB_TESTS

end