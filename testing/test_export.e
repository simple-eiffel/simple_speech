note
	description: "Tests for speech export functionality"
	author: "Larry Rix"

class
	TEST_EXPORT

create
	default_create

feature -- Tests

	test_vtt_export
			-- Test VTT export format.
		local
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			exporter: VTT_EXPORTER
			vtt: STRING_8
		do
			segments := make_test_segments
			create exporter.make
			vtt := exporter.from_segments (segments).to_string
			
			check has_header: vtt.has_substring ("WEBVTT") end
			check has_timestamp: vtt.has_substring ("00:00:00.000 --> 00:00:01.500") end
			check has_text: vtt.has_substring ("Hello world") end
		end

	test_srt_export
			-- Test SRT export format.
		local
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			exporter: SRT_EXPORTER
			srt: STRING_8
		do
			segments := make_test_segments
			create exporter.make
			srt := exporter.from_segments (segments).to_string
			
			check has_number: srt.has_substring ("1%N") end
			check has_comma_timestamp: srt.has_substring ("00:00:00,000 --> 00:00:01,500") end
			check has_text: srt.has_substring ("Hello world") end
		end

	test_json_export
			-- Test JSON export format.
		local
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			exporter: JSON_EXPORTER
			json: STRING_8
		do
			segments := make_test_segments
			create exporter.make
			json := exporter.from_segments (segments).to_string
			
			check has_segments_array: json.has_substring ("%"segments%":") end
			check has_start: json.has_substring ("%"start%":") end
			check has_end: json.has_substring ("%"end%":") end
			check has_text: json.has_substring ("%"text%":") end
			check has_count: json.has_substring ("%"segment_count%": 2") end
		end

	test_txt_export
			-- Test plain text export.
		local
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			exporter: TXT_EXPORTER
			txt: STRING_8
		do
			segments := make_test_segments
			create exporter.make
			txt := exporter.from_segments (segments).to_string
			
			check has_text: txt.has_substring ("Hello world") end
			check has_second: txt.has_substring ("Testing speech") end
			
			-- With timestamps
			create exporter.make
			exporter.from_segments (segments)
				exporter.set_timestamps (True)
			txt := exporter.to_string
			check has_timestamp: txt.has_substring ("[00:00:00]") end
		end

	test_unified_exporter
			-- Test unified SPEECH_EXPORTER facade.
		local
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			exporter: SPEECH_EXPORTER
		do
			segments := make_test_segments
			create exporter.make (segments)
			
			check vtt_works: exporter.to_vtt.has_substring ("WEBVTT") end
			check srt_works: exporter.to_srt.has_substring ("-->") end
			check json_works: exporter.to_json.has_substring ("%"segments%":") end
			check txt_works: exporter.to_text.has_substring ("Hello") end
		end

	test_file_export
			-- Test exporting to actual files.
		local
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			exporter: SPEECH_EXPORTER
			l_file: PLAIN_TEXT_FILE
		do
			segments := make_test_segments
			create exporter.make (segments)
			
			-- Export all formats
			exporter.then_export_vtt ("testing/output/test.vtt")
			                   .then_export_srt ("testing/output/test.srt")
			                   .then_export_json ("testing/output/test.json")
			                   .then_export_text ("testing/output/test.txt").do_nothing
			
			check exports_ok: exporter.is_ok end
			
			-- Verify files exist
			create l_file.make_with_name ("testing/output/test.vtt")
			check vtt_exists: l_file.exists end
			
			create l_file.make_with_name ("testing/output/test.srt")
			check srt_exists: l_file.exists end
		end

feature {NONE} -- Test Data

	make_test_segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Create test segments.
		local
			seg1, seg2: SPEECH_SEGMENT
		do
			create Result.make (2)
			create seg1.make ("Hello world", 0.0, 1.5)
			create seg2.make ("Testing speech", 1.5, 3.0)
			Result.extend (seg1)
			Result.extend (seg2)
		end

end
