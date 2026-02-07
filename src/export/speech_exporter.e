note
	description: "[
		SPEECH_EXPORTER - Unified facade for exporting transcription results.

		Provides a single interface to export to multiple formats:
		- VTT (WebVTT) for web video captions
		- SRT (SubRip) for broad compatibility
		- JSON for structured data
		- TXT for plain text transcripts

		Example (commands):
			create exporter.make (segments)
			exporter.export_vtt ("output.vtt")
			exporter.export_srt ("output.srt")

		Example (fluent chain):
			create exporter.make (segments)
			if exporter.then_export_vtt ("output.vtt")
			        .then_export_srt ("output.srt")
			        .is_ok then
			    print ("Export complete!")
			end

		CQS Pattern:
		- Commands: set_segments, export_vtt, export_srt, export_json, export_text
		- Fluent: with_segments, then_export_vtt, then_export_srt, etc.
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

	ai_provider: detachable STRING_8
			-- AI provider used for transcription (e.g., "claude", "ollama", "google").

	ai_model: detachable STRING_8
			-- AI model name (e.g., "claude-sonnet-4-20250514", "llama3.2:latest").

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

feature -- Configuration Commands

	set_segments (a_segments: like segments)
			-- Set segments to export.
		do
			segments := a_segments
		ensure
			segments_set: segments = a_segments
		end

	set_ai_source (a_provider: STRING_8; a_model: STRING_8)
			-- Set AI provider and model used for transcription.
			-- This will be included as metadata in exported files.
		require
			provider_not_empty: not a_provider.is_empty
		do
			ai_provider := a_provider
			ai_model := a_model
		ensure
			provider_set: ai_provider ~ a_provider
			model_set: ai_model ~ a_model
		end

feature -- Configuration Fluent

	with_segments (a_segments: like segments): like Current
			-- Fluent: set segments and return Current.
		do
			set_segments (a_segments)
			Result := Current
		ensure
			segments_set: segments = a_segments
			result_is_current: Result = Current
		end

	from_segments (a_segments: like segments): like Current
			-- Alias for with_segments (legacy compatibility).
		do
			Result := with_segments (a_segments)
		ensure
			segments_set: segments = a_segments
			result_is_current: Result = Current
		end

	with_ai_source (a_provider: STRING_8; a_model: STRING_8): like Current
			-- Fluent: set AI source and return Current.
		require
			provider_not_empty: not a_provider.is_empty
		do
			set_ai_source (a_provider, a_model)
			Result := Current
		ensure
			provider_set: ai_provider ~ a_provider
			result_is_current: Result = Current
		end

feature -- Export Commands

	export_vtt (a_path: READABLE_STRING_GENERAL)
			-- Export to WebVTT format.
		local
			l_exporter: VTT_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			if attached ai_provider as l_provider and then attached ai_model as l_model then
				l_exporter.set_ai_source (l_provider, l_model)
			end
			if not l_exporter.export_to_file (a_path) then
				add_error ({STRING_32} "VTT export failed: " + a_path.to_string_32)
			end
		end

	export_srt (a_path: READABLE_STRING_GENERAL)
			-- Export to SubRip (SRT) format.
		local
			l_exporter: SRT_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			if attached ai_provider as l_provider and then attached ai_model as l_model then
				l_exporter.set_ai_source (l_provider, l_model)
			end
			if not l_exporter.export_to_file (a_path) then
				add_error ({STRING_32} "SRT export failed: " + a_path.to_string_32)
			end
		end

	export_json (a_path: READABLE_STRING_GENERAL)
			-- Export to JSON format.
		local
			l_exporter: JSON_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			if not l_exporter.export_to_file (a_path) then
				add_error ({STRING_32} "JSON export failed: " + a_path.to_string_32)
			end
		end

	export_text (a_path: READABLE_STRING_GENERAL)
			-- Export to plain text format.
		local
			l_exporter: TXT_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			if not l_exporter.export_to_file (a_path) then
				add_error ({STRING_32} "TXT export failed: " + a_path.to_string_32)
			end
		end

	export_text_with_timestamps (a_path: READABLE_STRING_GENERAL)
			-- Export to plain text format with timestamps.
		local
			l_exporter: TXT_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			l_exporter.set_timestamps (True)
			if not l_exporter.export_to_file (a_path) then
				add_error ({STRING_32} "TXT export failed: " + a_path.to_string_32)
			end
		end

feature -- Export Fluent

	then_export_vtt (a_path: READABLE_STRING_GENERAL): like Current
			-- Fluent: export to VTT and return Current.
		do
			export_vtt (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	then_export_srt (a_path: READABLE_STRING_GENERAL): like Current
			-- Fluent: export to SRT and return Current.
		do
			export_srt (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	then_export_json (a_path: READABLE_STRING_GENERAL): like Current
			-- Fluent: export to JSON and return Current.
		do
			export_json (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	then_export_text (a_path: READABLE_STRING_GENERAL): like Current
			-- Fluent: export to text and return Current.
		do
			export_text (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	then_export_text_with_timestamps (a_path: READABLE_STRING_GENERAL): like Current
			-- Fluent: export to text with timestamps and return Current.
		do
			export_text_with_timestamps (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- String Generation

	to_vtt: STRING_8
			-- Generate VTT content as string.
		local
			l_exporter: VTT_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			if attached ai_provider as l_provider and then attached ai_model as l_model then
				l_exporter.set_ai_source (l_provider, l_model)
			end
			Result := l_exporter.to_string
		end

	to_srt: STRING_8
			-- Generate SRT content as string.
		local
			l_exporter: SRT_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			if attached ai_provider as l_provider and then attached ai_model as l_model then
				l_exporter.set_ai_source (l_provider, l_model)
			end
			Result := l_exporter.to_string
		end

	to_json: STRING_8
			-- Generate JSON content as string.
		local
			l_exporter: JSON_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			Result := l_exporter.to_string
		end

	to_text: STRING_8
			-- Generate plain text content as string.
		local
			l_exporter: TXT_EXPORTER
		do
			create l_exporter.make
			l_exporter.set_segments (segments)
			Result := l_exporter.to_string
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
