note
	description: "Tests for simple_speech library"
	author: "Larry Rix"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test: SPEECH_SEGMENT

	test_segment_creation
		local
			seg: SPEECH_SEGMENT
		do
			create seg.make ("Hello world", 0.0, 5.0)
			assert_true ("segment created", seg /= Void)
			assert_strings_equal ("text", "Hello world", seg.text)
		end

	test_segment_timing
		local
			seg: SPEECH_SEGMENT
		do
			create seg.make ("Test", 1.5, 3.5)
			assert_reals_equal ("start", 1.5, seg.start_time, 0.001)
			assert_reals_equal ("end", 3.5, seg.end_time, 0.001)
			assert_reals_equal ("duration", 2.0, seg.duration, 0.001)
		end

	test_segment_confidence
		local
			seg: SPEECH_SEGMENT
		do
			create seg.make_with_confidence ("Test", 0.0, 1.0, 0.95)
			assert_reals_equal ("confidence", 0.95, seg.confidence, 0.001)
		end

feature -- Test: SPEECH_CHAPTER

	test_chapter_creation
		local
			ch: SPEECH_CHAPTER
		do
			create ch.make_with_title (0.0, 60.0, "Introduction")
			assert_true ("chapter created", ch /= Void)
			assert_strings_equal ("title", "Introduction", ch.title)
		end

	test_chapter_timing
		local
			ch: SPEECH_CHAPTER
		do
			create ch.make_with_title (10.0, 120.0, "Chapter 1")
			assert_reals_equal ("start", 10.0, ch.start_time, 0.001)
			assert_reals_equal ("end", 120.0, ch.end_time, 0.001)
			assert_reals_equal ("duration", 110.0, ch.duration, 0.001)
		end

feature -- Test: Export Formats

	test_vtt_exporter
		local
			exporter: VTT_EXPORTER
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_output: STRING
		do
			create exporter.make
			create segments.make (2)
			segments.extend (create {SPEECH_SEGMENT}.make ("First", 0.0, 2.0))
			segments.extend (create {SPEECH_SEGMENT}.make ("Second", 2.0, 4.0))
			l_output := exporter.from_segments (segments).to_string
			assert_string_contains ("header", l_output, "WEBVTT")
			assert_string_contains ("first cue", l_output, "First")
			assert_string_contains ("second cue", l_output, "Second")
		end

	test_srt_exporter
		local
			exporter: SRT_EXPORTER
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_output: STRING
		do
			create exporter.make
			create segments.make (1)
			segments.extend (create {SPEECH_SEGMENT}.make ("Test", 0.0, 1.0))
			l_output := exporter.from_segments (segments).to_string
			assert_string_contains ("cue number", l_output, "1")
			assert_string_contains ("text", l_output, "Test")
		end

	test_json_exporter
		local
			exporter: JSON_EXPORTER
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_output: STRING
		do
			create exporter.make
			create segments.make (1)
			segments.extend (create {SPEECH_SEGMENT}.make ("JSON test", 1.5, 3.0))
			l_output := exporter.from_segments (segments).to_string
			assert_string_contains ("json array", l_output, "[")
			assert_string_contains ("text field", l_output, "JSON test")
		end

feature -- Test: Transition Detector

	test_detector_creation
		local
			detector: SPEECH_TRANSITION_DETECTOR
		do
			create detector.make
			assert_true ("detector created", detector /= Void)
		end

	test_detector_sensitivity
		local
			detector: SPEECH_TRANSITION_DETECTOR
		do
			create detector.make
			detector.set_sensitivity (2)
			assert_reals_equal ("sensitivity", 2, detector.sensitivity, 0.001)
		end

	test_detector_min_duration
		local
			detector: SPEECH_TRANSITION_DETECTOR
		do
			create detector.make
			detector.set_min_chapter_duration (60.0)
			assert_reals_equal ("min duration", 60.0, detector.min_chapter_duration, 0.001)
		end

feature -- Test: SPEECH_QUICK Facade

	test_quick_creation
		local
			quick: SPEECH_QUICK
		do
			create quick.make_with_model ("models/ggml-base.en.bin")
			assert_true ("quick created", quick /= Void)
		end

	test_quick_status
		local
			quick: SPEECH_QUICK
		do
			create quick.make_with_model ("models/ggml-base.en.bin")
			assert_false ("no segments initially", quick.has_segments)
			assert_false ("no chapters initially", quick.has_chapters)
			assert_integers_equal ("zero segments", 0, quick.segment_count)
			assert_integers_equal ("zero chapters", 0, quick.chapter_count)
		end

feature -- Test: Memory Monitor

	test_memory_monitor
		local
			monitor: SPEECH_MEMORY_MONITOR
		do
			create monitor.make
			assert_true ("monitor created", monitor /= Void)
			assert_true ("has memory info", monitor.get_available_memory_mb > 0)
		end

end