note
	description: "Test application for simple_speech library"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running simple_speech tests...%N%N")
			passed := 0
			failed := 0

			run_segment_tests
			run_speech_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_segment_tests
			-- Run SPEECH_SEGMENT tests.
		local
			tests: TEST_SEGMENT
		do
			print ("--- SPEECH_SEGMENT Tests ---%N")
			create tests
			run_test (agent tests.test_make, "test_make")
			run_test (agent tests.test_make_with_confidence, "test_make_with_confidence")
			run_test (agent tests.test_duration, "test_duration")
			run_test (agent tests.test_time_formatting, "test_time_formatting")
		end

	run_speech_tests
			-- Run SIMPLE_SPEECH tests.
		local
			tests: TEST_SPEECH
		do
			print ("%N--- SIMPLE_SPEECH Tests ---%N")
			create tests
			run_test (agent tests.test_creation_stub, "test_creation_stub")
			run_test (agent tests.test_fluent_config, "test_fluent_config")
		end

feature {NONE} -- Test Infrastructure

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test with error handling.
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_failed := True
			retry
		end

	passed: INTEGER
			-- Number of passed tests.

	failed: INTEGER
			-- Number of failed tests.

end
