note
	description: "[
		SPEECH_BATCH_PROCESSOR - Memory-conscious batch video processing.
		
		Processes multiple video/audio files with transcription and export,
		designed for memory-constrained systems.
	]"
	author: "Larry Rix"

class
	SPEECH_BATCH_PROCESSOR

create
	make

feature {NONE} -- Initialization

	make (a_pipeline: SPEECH_PIPELINE)
			-- Create batch processor with existing pipeline.
		require
			pipeline_attached: a_pipeline /= Void
			pipeline_valid: a_pipeline.is_ready
		do
			pipeline := a_pipeline
			create files.make (50)
			create languages.make (5)
			output_folder := "./"
			format := "vtt"
			create progress.make
			create memory_monitor.make
			create errors.make (10)
		ensure
			pipeline_set: pipeline = a_pipeline
		end

feature -- Access

	pipeline: SPEECH_PIPELINE

	files: ARRAYED_LIST [STRING_32]

	output_folder: STRING_32

	format: STRING_8

	languages: ARRAYED_LIST [STRING_32]

	progress: SPEECH_PROGRESS_INFO

	memory_monitor: SPEECH_MEMORY_MONITOR

	errors: ARRAYED_LIST [STRING_32]

	progress_callback: detachable PROCEDURE [SPEECH_PROGRESS_INFO]

feature -- Status

	has_files: BOOLEAN
		do
			Result := files.count > 0
		end

	has_errors: BOOLEAN
		do
			Result := errors.count > 0
		end

	is_running: BOOLEAN

feature -- Configuration Commands

	add_file (a_path: READABLE_STRING_GENERAL)
			-- Add file to processing list.
		require
			path_not_empty: not a_path.is_empty
		do
			files.extend (a_path.to_string_32)
		end

	set_output_folder (a_folder: READABLE_STRING_GENERAL)
			-- Set output folder.
		require
			folder_not_empty: not a_folder.is_empty
		do
			output_folder := a_folder.to_string_32
		end

	set_format (a_format: READABLE_STRING_GENERAL)
			-- Set output format.
		do
			format := a_format.to_string_8
		end

	set_languages (a_languages: ARRAY [READABLE_STRING_GENERAL])
			-- Set languages.
		do
			languages.wipe_out
			across a_languages as lang loop
				languages.extend (lang.to_string_32)
			end
		end

	set_progress_callback (a_callback: PROCEDURE [SPEECH_PROGRESS_INFO])
			-- Set progress callback.
		do
			progress_callback := a_callback
		end

feature -- Configuration Fluent

	with_file (a_path: READABLE_STRING_GENERAL): like Current
			-- Fluent: add file and return Current.
		require
			path_not_empty: not a_path.is_empty
		do
			add_file (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	with_output_folder (a_folder: READABLE_STRING_GENERAL): like Current
			-- Fluent: set output folder and return Current.
		require
			folder_not_empty: not a_folder.is_empty
		do
			set_output_folder (a_folder)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	with_format (a_format: READABLE_STRING_GENERAL): like Current
			-- Fluent: set format and return Current.
		do
			set_format (a_format)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	with_languages (a_languages: ARRAY [READABLE_STRING_GENERAL]): like Current
			-- Fluent: set languages and return Current.
		do
			set_languages (a_languages)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	with_progress_callback (a_callback: PROCEDURE [SPEECH_PROGRESS_INFO]): like Current
			-- Fluent: set progress callback and return Current.
		do
			set_progress_callback (a_callback)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Execution

	run: BOOLEAN
		local
			l_file: STRING_32
			l_segments: ARRAYED_LIST [SPEECH_SEGMENT]
			l_exporter: SPEECH_EXPORTER
			l_output_path: STRING_32
			l_index: INTEGER
		do
			is_running := True
			errors.wipe_out
			progress.reset
			progress.set_total_files (files.count)
			
			Result := True
			l_index := 0
			
			across files as file_cursor loop
				l_index := l_index + 1
				l_file := file_cursor
				progress.set_current_file (l_file, l_index)
				progress.set_memory_usage (memory_monitor.get_process_memory_mb)
				
				progress.set_phase ("transcribing")
				report_progress
				
				l_segments := pipeline.process_video (l_file)
				
				if pipeline.has_error then
					if attached pipeline.last_error as e then
						errors.extend (l_file + ": " + e)
					else
						errors.extend (l_file + ": Unknown error")
					end
					progress.increment_failed
					Result := False
				else
					progress.set_phase ("exporting")
					report_progress
					
					create l_exporter.make (l_segments)
					l_output_path := build_output_path (l_file)
					do_export (l_exporter, l_output_path)
					
					if l_exporter.is_ok then
						progress.increment_succeeded
					else
						errors.extend (l_file + ": Export failed")
						progress.increment_failed
						Result := False
					end
				end
				
				report_progress
			end
			
			progress.set_phase ("idle")
			is_running := False
		ensure
			not_running: not is_running
		end

	clear
		do
			files.wipe_out
			errors.wipe_out
			progress.reset
		end

feature {NONE} -- Implementation

	report_progress
		do
			if attached progress_callback as cb then
				cb.call ([progress])
			end
		end

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

	build_output_path (a_input: STRING_32): STRING_32
		local
			l_name: STRING_32
			l_dot, l_sep: INTEGER
		do
			l_sep := a_input.last_index_of ('/', a_input.count)
			if l_sep > 0 then
				l_name := a_input.substring (l_sep + 1, a_input.count)
			else
				l_name := a_input.twin
			end
			
			l_dot := l_name.last_index_of ('.', l_name.count)
			if l_dot > 1 then
				l_name := l_name.substring (1, l_dot - 1)
			end
			
			create Result.make (100)
			Result.append (output_folder)
			Result.append (l_name)
			Result.append_character ('.')
			Result.append (format)
		end

invariant
	pipeline_attached: pipeline /= Void
	files_attached: files /= Void
	languages_attached: languages /= Void
	output_folder_attached: output_folder /= Void
	format_attached: format /= Void
	progress_attached: progress /= Void
	memory_monitor_attached: memory_monitor /= Void
	errors_attached: errors /= Void

end
