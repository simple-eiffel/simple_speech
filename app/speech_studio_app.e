note
	description: "Speech Studio - GUI frontend for simple_speech transcription"
	author: "Larry Rix"
	date: "2025-12-29"
	design: "[
		simple_gui (since 2026-11-09; it was simple_vision): native controls on each
		platform - GTK 4 on Linux, AppKit on macOS, simple_widgets on Windows.

		SCOOP: the window runs on the GUI processor and never waits on a job.
		SPEECH_STUDIO_RELAY, on its own processor, owns the transcriber and hands progress,
		segments, chapters and the outcome back through the GUI's mailbox plus a GUI_WAKE
		(simple_gui's rule: workers never call into the GUI).

		Cancel: simple_speech's transcriber only notices a cancel between the phases of a
		job, and a cancel request would wait behind the running job. So Cancel returns the
		window to ready at once and the job's results are dropped when it ends; Transcribe
		comes back when it has.
	]"

class
	SPEECH_STUDIO_APP

inherit
	SPEECH_STUDIO_TAGS

create
	make, make_studio

feature {NONE} -- Initialization

	make
			-- Build Speech Studio and run it.
		do
			make_studio
			window.show
			app.run
		end

	make_studio
			-- Build Speech Studio without running it (checks drive it with GUI_TEST_DRIVER).
		do
			create app.make ("Speech Studio", "org.simple-eiffel.speech-studio")
			create transcribed_segments.make (0)
			create transcribed_chapters.make (0)
			create current_file.make_empty
			create current_file_name.make_empty
			create window.make ("Speech Studio", 1200, 800)
			create btn_open.make ("Open File")
			create btn_transcribe.make ("Transcribe")
			create btn_cancel.make ("Cancel")
			create btn_export_vtt.make ("Export VTT")
			create btn_export_srt.make ("Export SRT")
			create btn_export_json.make ("Export JSON")
			create lbl_file_name.make ("No file loaded")
			create lbl_file_info.make ("")
			create lbl_status.make ("Open a file to begin transcription")
			create progress.make
			create chapter_list.make
			create segment_list.make
			create status_bar.make
			create relay.make (app.mailbox)
			lay_out
			app.message_actions.extend (agent on_message)
		end

	lay_out
			-- Toolbar, file and chapters on the left, progress and transcript on the right,
			-- a status bar below.
		local
			l_toolbar: GUI_TOOLBAR
			l_split: GUI_SPLITTER
			l_left, l_right: GUI_STACK
			l_file_heading, l_chapters_heading, l_transcript_heading: GUI_LABEL
		do
			create l_toolbar.make
			l_toolbar.extend (btn_open)
			l_toolbar.extend (btn_transcribe)
			l_toolbar.extend (btn_cancel)
			l_toolbar.add_separator
			l_toolbar.extend (btn_export_vtt)
			l_toolbar.extend (btn_export_srt)
			l_toolbar.extend (btn_export_json)
			btn_open.click_actions.extend (agent on_open_file)
			btn_transcribe.click_actions.extend (agent on_transcribe)
			btn_cancel.click_actions.extend (agent on_cancel)
			btn_export_vtt.click_actions.extend (agent on_export_vtt)
			btn_export_srt.click_actions.extend (agent on_export_srt)
			btn_export_json.click_actions.extend (agent on_export_json)
			window.set_toolbar (l_toolbar)

			create l_file_heading.make ("File")
			create l_chapters_heading.make ("Chapters")
			create l_left.make_vertical
			l_left.set_spacing (6)
			l_left.extend (l_file_heading)
			l_left.extend (lbl_file_name)
			l_left.extend (lbl_file_info)
			l_left.extend (l_chapters_heading)
			l_left.extend_stretching (chapter_list)
			chapter_list.set_accessible_label ("Chapters")

			create l_transcript_heading.make ("Transcript")
			create l_right.make_vertical
			l_right.set_spacing (6)
			l_right.extend (lbl_status)
			l_right.extend (progress)
			l_right.extend (l_transcript_heading)
			l_right.extend_stretching (segment_list)
			progress.set_accessible_label ("Progress")
			segment_list.set_accessible_label ("Transcript")

			create l_split.make_horizontal
			l_split.set_first (l_left)
			l_split.set_second (l_right)
			l_split.set_position (300)
			window.set_content (l_split)

			status_bar.set_text ("Ready")
			window.set_status_bar (status_bar)
			show_buttons
		end

feature -- Access

	app: GUI_APPLICATION

	window: GUI_WINDOW

	relay: separate SPEECH_STUDIO_RELAY
			-- Runs transcription jobs on its own processor.

	transcribed_segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Segments from the last transcription.

	transcribed_chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			-- Chapters from the last transcription.

	current_file: STRING_32
			-- The loaded file's path, or empty.

	current_file_name: STRING_32
			-- Its last part.

	is_running: BOOLEAN
			-- Is a job running on the relay (cancelled or not)?

	cancel_requested: BOOLEAN
			-- Did the user cancel the running job?

feature -- Controls

	btn_open, btn_transcribe, btn_cancel, btn_export_vtt, btn_export_srt, btn_export_json: GUI_BUTTON

	lbl_file_name, lbl_file_info, lbl_status: GUI_LABEL

	progress: GUI_PROGRESS_BAR

	chapter_list, segment_list: GUI_LIST

	status_bar: GUI_STATUS_BAR

feature -- Event handlers

	on_open_file
		do
			if attached app.dialogs.open_file ("Open audio or video",
					{ARRAY [READABLE_STRING_GENERAL]} <<"mp3", "wav", "mp4", "mkv", "avi", "mov", "ogg", "flac", "m4a">>) as al_path
			then
				load_file (al_path)
			end
		end

	load_file (a_path: PATH)
			-- Load a media file for transcription.
		local
			l_file: RAW_FILE
		do
			current_file := a_path.name
			if attached a_path.entry as al_entry then
				current_file_name := al_entry.name
			else
				current_file_name := current_file.twin
			end
			lbl_file_name.set_text (current_file_name)
			create l_file.make_with_path (a_path)
			if l_file.exists then
				lbl_file_info.set_text ("Size: " + format_size (l_file.count))
			else
				lbl_file_info.set_text ("File not found")
			end
			if not is_running then
				lbl_status.set_text ({STRING_32} "Ready to transcribe: " + current_file_name)
			end
			status_bar.set_text (current_file)
			show_buttons
		end

	on_transcribe
			-- Start a job on the relay; the window goes on at once.
		do
			if not is_running and not current_file.is_empty then
				is_running := True
				cancel_requested := False
				transcribed_segments.wipe_out
				transcribed_chapters.wipe_out
				segment_list.wipe_out
				chapter_list.wipe_out
				lbl_status.set_text ("Starting transcription...")
				progress.set_value (0)
				start_job (relay, current_file)
				show_buttons
			end
		end

	on_cancel
			-- Drop the running job's results; the window is ready again at once.
		do
			if is_running then
				cancel_requested := True
				progress.set_value (0)
				lbl_status.set_text ("Cancelled. The current step finishes in the background.")
				show_buttons
			end
		end

	on_message (a_tag: INTEGER; a_payload: STRING_32)
			-- A message from the relay.
		do
			if cancel_requested then
				if a_tag = Tag_done or a_tag = Tag_error or a_tag = Tag_cancelled then
					is_running := False
					cancel_requested := False
					transcribed_segments.wipe_out
					transcribed_chapters.wipe_out
					lbl_status.set_text ({STRING_32} "Cancelled. Ready to transcribe: " + current_file_name)
					show_buttons
				end
			else
				inspect a_tag
				when Tag_progress then
					progress.set_value (field (a_payload, 1).to_integer.max (0).min (100))
					lbl_status.set_text (rest (a_payload, 1))
				when Tag_segment then
					transcribed_segments.extend (create {SPEECH_SEGMENT}.make (rest (a_payload, 2),
						field (a_payload, 1).to_double, field (a_payload, 2).to_double))
				when Tag_chapter then
					transcribed_chapters.extend (create {SPEECH_CHAPTER}.make_with_title (
						field (a_payload, 1).to_double, field (a_payload, 2).to_double, rest (a_payload, 2)))
				when Tag_done then
					is_running := False
					update_lists
					progress.set_value (100)
					lbl_status.set_text ("Completed: " + transcribed_segments.count.out + " segments, " + transcribed_chapters.count.out + " chapters")
					show_buttons
				when Tag_error then
					is_running := False
					lbl_status.set_text ({STRING_32} "Error: " + a_payload)
					show_buttons
				when Tag_cancelled then
					is_running := False
					progress.set_value (0)
					lbl_status.set_text ({STRING_32} "Cancelled. Ready to transcribe: " + current_file_name)
					show_buttons
				else
				end
			end
		end

feature -- Export handlers

	on_export_vtt
		local
			l_exporter: VTT_EXPORTER
		do
			if attached save_path ("Export WebVTT", "vtt") as al_path then
				create l_exporter.make
				l_exporter.set_segments (transcribed_segments)
				report_export (l_exporter.export_to_file (al_path), al_path)
			end
		end

	on_export_srt
		local
			l_exporter: SRT_EXPORTER
		do
			if attached save_path ("Export SubRip", "srt") as al_path then
				create l_exporter.make
				l_exporter.set_segments (transcribed_segments)
				report_export (l_exporter.export_to_file (al_path), al_path)
			end
		end

	on_export_json
		local
			l_exporter: JSON_EXPORTER
		do
			if attached save_path ("Export JSON", "json") as al_path then
				create l_exporter.make
				l_exporter.set_segments (transcribed_segments)
				report_export (l_exporter.export_to_file (al_path), al_path)
			end
		end

feature {NONE} -- Implementation

	start_job (a_relay: separate SPEECH_STUDIO_RELAY; a_path: STRING_32)
			-- Give the relay the file, then start it. `start' takes nothing from this
			-- processor's region, so this call does not wait for the job.
		do
			a_relay.set_file (a_path)
			a_relay.start
		end

	show_buttons
			-- Enable what makes sense now.
		do
			set_enabled (btn_transcribe, not is_running and not current_file.is_empty)
			set_enabled (btn_cancel, is_running and not cancel_requested)
			set_enabled (btn_export_vtt, not is_running and not transcribed_segments.is_empty)
			set_enabled (btn_export_srt, not is_running and not transcribed_segments.is_empty)
			set_enabled (btn_export_json, not is_running and not transcribed_segments.is_empty)
		end

	set_enabled (a_button: GUI_BUTTON; a_on: BOOLEAN)
		do
			if a_on then
				a_button.enable
			else
				a_button.disable
			end
		end

	update_lists
		local
			l_line: STRING_32
		do
			segment_list.wipe_out
			across transcribed_segments as ic loop
				create l_line.make_from_string_general (format_timestamp (ic.start_time))
				l_line.append ({STRING_32} " - ")
				l_line.append (ic.text)
				segment_list.extend (l_line)
			end
			chapter_list.wipe_out
			across transcribed_chapters as ic loop
				create l_line.make_from_string_general (format_timestamp (ic.start_time))
				l_line.append ({STRING_32} " - ")
				l_line.append (ic.title)
				chapter_list.extend (l_line)
			end
		end

	save_path (a_title: STRING; a_extension: STRING): detachable STRING_32
			-- A path the user chose, ending in `a_extension'.
		local
			l_suffix: STRING_32
		do
			if attached app.dialogs.save_file (a_title, {ARRAY [READABLE_STRING_GENERAL]} <<a_extension>>) as al_path then
				Result := al_path.name.twin
				create l_suffix.make_from_string_general ("." + a_extension)
				if not Result.as_lower.ends_with (l_suffix) then
					Result.append (l_suffix)
				end
			end
		end

	report_export (a_ok: BOOLEAN; a_path: STRING_32)
		do
			if a_ok then
				app.dialogs.inform ("Speech Studio", {STRING_32} "Exported to " + a_path)
			else
				app.dialogs.inform ("Speech Studio", {STRING_32} "Export failed: " + a_path)
			end
		end

	field (a_payload: STRING_32; n: INTEGER): STRING_32
			-- Field `n' (1-based) of a tab-separated payload.
		require
			positive: n >= 1
		local
			l_fields: LIST [STRING_32]
		do
			l_fields := a_payload.split ('%T')
			if n <= l_fields.count then
				Result := l_fields.i_th (n)
			else
				create Result.make_empty
			end
		end

	rest (a_payload: STRING_32; n: INTEGER): STRING_32
			-- Everything after the first `n' tabs (the last field may hold tabs).
		local
			i, l_tabs: INTEGER
		do
			from
				i := 1
			until
				i > a_payload.count or l_tabs = n
			loop
				if a_payload.item (i) = '%T' then
					l_tabs := l_tabs + 1
				end
				i := i + 1
			end
			if l_tabs = n then
				Result := a_payload.substring (i, a_payload.count)
			else
				create Result.make_empty
			end
		end

	format_size (a_bytes: INTEGER): STRING
			-- File size for display.
		do
			if a_bytes >= 1048576 then
				Result := (a_bytes // 1048576).out + " MB"
			elseif a_bytes >= 1024 then
				Result := (a_bytes // 1024).out + " KB"
			else
				Result := a_bytes.out + " bytes"
			end
		end

	format_timestamp (a_seconds: REAL_64): STRING
			-- Seconds as M:SS.
		local
			l_mins, l_secs: INTEGER
		do
			l_mins := (a_seconds / 60.0).truncated_to_integer
			l_secs := (a_seconds - (l_mins * 60)).truncated_to_integer
			if l_secs < 10 then
				Result := l_mins.out + ":0" + l_secs.out
			else
				Result := l_mins.out + ":" + l_secs.out
			end
		end

end
