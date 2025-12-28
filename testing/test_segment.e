note
	description: "Tests for SPEECH_SEGMENT class"
	author: "Larry Rix"

class
	TEST_SEGMENT

create
	default_create

feature -- Tests

	test_make
			-- Test basic creation.
		local
			seg: SPEECH_SEGMENT
		do
			create seg.make ("Hello world", 1.5, 3.0)
			check text_correct: seg.text.same_string ("Hello world") end
			check start_correct: seg.start_time = 1.5 end
			check end_correct: seg.end_time = 3.0 end
			check no_confidence: not seg.has_confidence end
		end

	test_make_with_confidence
			-- Test creation with confidence.
		local
			seg: SPEECH_SEGMENT
		do
			create seg.make_with_confidence ("Test", 0.0, 1.0, {REAL_32} 0.95)
			check has_conf: seg.has_confidence end
			check conf_value: (seg.confidence - {REAL_32} 0.95).abs < {REAL_32} 0.001 end
		end

	test_duration
			-- Test duration calculation.
		local
			seg: SPEECH_SEGMENT
		do
			create seg.make ("Test", 10.0, 15.5)
			check duration_correct: (seg.duration - 5.5).abs < 0.001 end
		end

	test_time_formatting
			-- Test time formatting.
		local
			seg: SPEECH_SEGMENT
		do
			create seg.make ("Test", 3661.5, 3665.0)
			check start_fmt: seg.start_time_formatted.same_string ("01:01:01.500") end
		end

end
