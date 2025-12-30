note
	description: "[
		SPEECH_MULTI_LANGUAGE_EXPORTER - Export segments to multiple languages.

		Translates and exports transcription segments to multiple target languages
		in one batch operation.

		Example:
			create exporter.make (ai_client, segments)
			exporter.set_output_folder ("captions/")
			       .set_languages (<<"es", "fr", "de", "ja">>)
			       .export_all
			-- Creates: captions/video_es.vtt, captions/video_fr.vtt, etc.
	]"
	author: "Larry Rix"

class
	SPEECH_MULTI_LANGUAGE_EXPORTER

create
	make

feature {NONE} -- Initialization

	make (a_client: AI_CLIENT; a_segments: ARRAYED_LIST [SPEECH_SEGMENT])
			-- Create exporter with AI client and segments.
		require
			client_attached: a_client /= Void
			segments_attached: a_segments /= Void
			has_segments: a_segments.count > 0
		do
			create enhancer.make (a_client)
			segments := a_segments
			create languages.make (5)
			output_folder := "./"
			base_name := "output"
			format := "vtt"
		ensure
			segments_set: segments = a_segments
		end

feature -- Access

	segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Original segments to translate.

	languages: ARRAYED_LIST [STRING_32]
			-- Target languages.

	output_folder: STRING_32
			-- Output folder path.

	base_name: STRING_32
			-- Base filename for outputs.

	format: STRING_8
			-- Export format (vtt, srt, json, txt).

	last_error: detachable STRING_32
			-- Last error message.

	exported_files: detachable ARRAYED_LIST [STRING_32]
			-- List of successfully exported files.

feature -- Status

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		end

feature -- Configuration

	set_output_folder (a_folder: READABLE_STRING_GENERAL): like Current
			-- Set output folder.
		require
			folder_not_empty: not a_folder.is_empty
		do
			output_folder := a_folder.to_string_32
			if not output_folder.is_empty and then
			   output_folder.item (output_folder.count) /= '/' and then
			   output_folder.item (output_folder.count) /= '\' then
				output_folder.append_character ('/')
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_base_name (a_name: READABLE_STRING_GENERAL): like Current
			-- Set base filename (without extension).
		require
			name_not_empty: not a_name.is_empty
		do
			base_name := a_name.to_string_32
			Result := Current
		ensure
			base_name_set: base_name.same_string_general (a_name)
			result_is_current: Result = Current
		end

	set_format (a_format: READABLE_STRING_GENERAL): like Current
			-- Set export format (vtt, srt, json, txt).
		require
			format_valid: a_format.same_string ("vtt") or a_format.same_string ("srt") or
			              a_format.same_string ("json") or a_format.same_string ("txt")
		do
			format := a_format.to_string_8
			Result := Current
		ensure
			format_set: format.same_string_general (a_format)
			result_is_current: Result = Current
		end

	set_languages (a_languages: ARRAY [READABLE_STRING_GENERAL]): like Current
			-- Set target languages.
		require
			languages_attached: a_languages /= Void
			has_languages: a_languages.count > 0
		do
			languages.wipe_out
			across a_languages as lang loop
				languages.extend (lang.to_string_32)
			end
			Result := Current
		ensure
			languages_set: languages.count = a_languages.count
			result_is_current: Result = Current
		end

	add_language (a_language: READABLE_STRING_GENERAL): like Current
			-- Add a target language.
		require
			language_not_empty: not a_language.is_empty
		do
			languages.extend (a_language.to_string_32)
			Result := Current
		ensure
			language_added: languages.has (a_language.to_string_32)
			result_is_current: Result = Current
		end

feature -- Export

	export_all: BOOLEAN
			-- Export segments to all configured languages.
			-- Returns True if all exports succeeded.
		require
			has_languages: languages.count > 0
		local
			l_translated: ARRAYED_LIST [SPEECH_SEGMENT]
			l_path: STRING_32
			l_exporter: SPEECH_EXPORTER
			l_files: ARRAYED_LIST [STRING_32]
		do
			clear_error
			create l_files.make (languages.count)
			exported_files := l_files
			Result := True

			across languages as lang loop
				l_translated := enhancer.translate (segments, lang)

				if enhancer.has_error then
					if attached enhancer.last_error as e then
						set_error ("Translation failed for " + lang + ": " + e)
					else
						set_error ("Translation failed for " + lang)
					end
					Result := False
				else
					l_path := build_output_path (lang)
					create l_exporter.make (l_translated)
					do_export (l_exporter, l_path)

					if l_exporter.is_ok then
						l_files.extend (l_path)
					else
						set_error ("Export failed for " + lang + ": " + l_path)
						Result := False
					end
				end
			end
		end

	export_language (a_language: READABLE_STRING_GENERAL): BOOLEAN
			-- Export segments to single language.
		require
			language_not_empty: not a_language.is_empty
		local
			l_translated: ARRAYED_LIST [SPEECH_SEGMENT]
			l_path: STRING_32
			l_exporter: SPEECH_EXPORTER
		do
			clear_error
			l_translated := enhancer.translate (segments, a_language)

			if enhancer.has_error then
			if attached enhancer.last_error as e then
				set_error ("Translation failed: " + e)
			else
				set_error ("Translation failed")
			end
		else
				l_path := build_output_path (a_language.to_string_32)
				create l_exporter.make (l_translated)
				do_export (l_exporter, l_path)

				Result := l_exporter.is_ok
				if not Result then
					set_error ("Export failed: " + l_path)
				end
			end
		end

feature {NONE} -- Implementation

	enhancer: SPEECH_AI_ENHANCER
			-- AI enhancer for translations.

	do_export (a_exporter: SPEECH_EXPORTER; a_path: STRING_32)
			-- Export using configured format.
		do
			if format.same_string ("vtt") then
				a_exporter.export_vtt (a_path)
			elseif format.same_string ("srt") then
				a_exporter.export_srt (a_path)
			elseif format.same_string ("json") then
				a_exporter.export_json (a_path)
			elseif format.same_string ("txt") then
				a_exporter.export_text (a_path)
			else
				a_exporter.export_vtt (a_path)
			end
		end

	build_output_path (a_language: STRING_32): STRING_32
			-- Build output file path for language.
		do
			create Result.make (100)
			Result.append (output_folder)
			Result.append (base_name)
			Result.append_character ('_')
			Result.append (a_language)
			Result.append_character ('.')
			Result.append (format)
		end

	clear_error
			-- Clear last error.
		do
			last_error := Void
		end

	set_error (a_msg: READABLE_STRING_GENERAL)
			-- Set error message.
		do
			last_error := a_msg.to_string_32
		end

invariant
	segments_attached: segments /= Void
	enhancer_attached: enhancer /= Void
	languages_attached: languages /= Void
	output_folder_attached: output_folder /= Void
	base_name_attached: base_name /= Void
	format_attached: format /= Void

end
