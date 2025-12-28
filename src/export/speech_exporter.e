note
	description: "[
		SPEECH_EXPORTER - Unified facade for exporting transcription results.
		
		Provides a single interface to export to multiple formats:
		- VTT (WebVTT) for web video captions
		- SRT (SubRip) for broad compatibility
		- JSON for structured data
		- TXT for plain text transcripts
		
		Example:
			create exporter.make (segments)
			exporter.export_vtt ("output.vtt")
			exporter.export_srt ("output.srt")
			exporter.export_json ("output.json")
			exporter.export_text ("output.txt")
			
		Fluent API:
			create exporter.make (segments)
			if exporter.export_vtt ("output.vtt")
			        .export_srt ("output.srt")
			        .is_ok then
			    print ("Export complete!")
			end
	]"
	author: "Larry Rix"

class
	SPEECH_EXPORTER

create
	make,
	make_empty

feature {NONE} -- Initialization

	make (a_segments: ARRAYED_LIST [SPEECH_SEGMENT])
			-- Create exporter with segments.
		do
			segments := a_segments
			create errors.make (0)
		ensure
			segments_set: segments = a_segments
		end

	make_empty
			-- Create empty exporter.
		do
			create segments.make (0)
			create errors.make (0)
		end

feature -- Access

	segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Segments to export.

	errors: ARRAYED_LIST [STRING_32]
			-- Accumulated errors from export operations.

	is_ok: BOOLEAN
			-- Did all exports succeed?
		do
			Result := errors.is_empty
		end

	last_error: detachable STRING_32
			-- Most recent error, if any.
		do
			if not errors.is_empty then
				Result := errors.last
			end
		end

feature -- Configuration

	from_segments (a_segments: like segments): like Current
			-- Set segments to export.
		do
			segments := a_segments
			Result := Current
		ensure
			segments_set: segments = a_segments
			result_is_current: Result = Current
		end

feature -- Export Operations

	export_vtt (a_path: READABLE_STRING_GENERAL): like Current
			-- Export to WebVTT format.
		local
			exporter: VTT_EXPORTER
		do
			create exporter.make
			if not exporter.from_segments (segments).export_to_file (a_path) then
				add_error ("VTT export failed: " + a_path.to_string_32)
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	export_srt (a_path: READABLE_STRING_GENERAL): like Current
			-- Export to SubRip (SRT) format.
		local
			exporter: SRT_EXPORTER
		do
			create exporter.make
			if not exporter.from_segments (segments).export_to_file (a_path) then
				add_error ("SRT export failed: " + a_path.to_string_32)
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	export_json (a_path: READABLE_STRING_GENERAL): like Current
			-- Export to JSON format.
		local
			exporter: JSON_EXPORTER
		do
			create exporter.make
			if not exporter.from_segments (segments).export_to_file (a_path) then
				add_error ("JSON export failed: " + a_path.to_string_32)
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	export_text (a_path: READABLE_STRING_GENERAL): like Current
			-- Export to plain text format.
		local
			exporter: TXT_EXPORTER
		do
			create exporter.make
			if not exporter.from_segments (segments).export_to_file (a_path) then
				add_error ("TXT export failed: " + a_path.to_string_32)
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	export_text_with_timestamps (a_path: READABLE_STRING_GENERAL): like Current
			-- Export to plain text format with timestamps.
		local
			exporter: TXT_EXPORTER
			l_dummy: TXT_EXPORTER
		do
			create exporter.make
			l_dummy := exporter.from_segments (segments).set_timestamps (True)
			if not exporter.export_to_file (a_path) then
				add_error ("TXT export failed: " + a_path.to_string_32)
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- String Generation

	to_vtt: STRING_8
			-- Generate VTT content as string.
		local
			exporter: VTT_EXPORTER
		do
			create exporter.make
			Result := exporter.from_segments (segments).to_string
		end

	to_srt: STRING_8
			-- Generate SRT content as string.
		local
			exporter: SRT_EXPORTER
		do
			create exporter.make
			Result := exporter.from_segments (segments).to_string
		end

	to_json: STRING_8
			-- Generate JSON content as string.
		local
			exporter: JSON_EXPORTER
		do
			create exporter.make
			Result := exporter.from_segments (segments).to_string
		end

	to_text: STRING_8
			-- Generate plain text content as string.
		local
			exporter: TXT_EXPORTER
		do
			create exporter.make
			Result := exporter.from_segments (segments).to_string
		end

feature {NONE} -- Implementation

	add_error (a_message: STRING_32)
			-- Add error message to list.
		do
			errors.extend (a_message)
		end

invariant
	segments_exists: segments /= Void
	errors_exists: errors /= Void

end
