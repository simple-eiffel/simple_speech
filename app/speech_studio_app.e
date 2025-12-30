note
	description: "Speech Studio - GUI frontend for simple_speech transcription"
	author: "Larry Rix"
	date: "2025-12-29"
	design: "[
		Uses simple_vision for UI, SCOOP for async transcription.

		SCOOP Architecture:
		- UI runs in main processor (responsive)
		- Transcription runs in separate processor (non-blocking)
		- Progress callbacks update UI via SCOOP message passing
	]"

class
	SPEECH_STUDIO_APP

inherit
	SV_APPLICATION
		redefine
			make
		end

	SPEECH_PROGRESS_HANDLER
		undefine
			default_create, copy
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Create and launch Speech Studio.
		do
			Precursor
			create sv.make
			sv.set_dark_mode (False)
			create transcriber.make
			create transcribed_segments.make (0)
			create transcribed_chapters.make (0)
			create_state_machine
			create_main_window
			if attached main_window as al_window then
				al_window.show_now
			end
			launch
		end

feature -- Access

	sv: SV_QUICK
			-- Widget factory.

	transcriber: separate SPEECH_ASYNC_TRANSCRIBER
			-- Async transcription processor (SCOOP separate).

	transcribed_segments: ARRAYED_LIST [SPEECH_SEGMENT]
			-- Segments from last transcription.

	transcribed_chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			-- Chapters from last transcription.

	state: detachable SV_STATE_MACHINE
			-- UI state machine.

	current_file: detachable STRING
			-- Currently loaded file path.

	current_file_name: detachable STRING
			-- Just the filename portion.

feature -- UI Components

	lbl_file_name: detachable SV_TEXT
	lbl_file_info: detachable SV_TEXT
	lbl_status: detachable SV_TEXT
	progress: detachable SV_PROGRESS_BAR
	segment_list: detachable SV_LIST
	chapter_list: detachable SV_LIST
	btn_transcribe: detachable SV_TOOLBAR_BUTTON
	btn_cancel: detachable SV_TOOLBAR_BUTTON
	btn_export_vtt: detachable SV_TOOLBAR_BUTTON
	btn_export_srt: detachable SV_TOOLBAR_BUTTON
	btn_export_json: detachable SV_TOOLBAR_BUTTON

feature {NONE} -- State Machine

	create_state_machine
			-- Create the main state machine.
		local
			l_machine: SV_STATE_MACHINE
		do
			l_machine := sv.state_machine ("main")

			-- States
			l_machine.state ("idle").described_as ("No file loaded").do_nothing
			l_machine.state ("file_loaded").described_as ("File ready").do_nothing
			l_machine.state ("transcribing").described_as ("Transcription in progress").do_nothing
			l_machine.state ("completed").described_as ("Transcript ready").do_nothing
			l_machine.state ("error").described_as ("Error occurred").do_nothing

			-- Transitions
			l_machine.on ("file_opened").from_state ("idle").to ("file_loaded").apply.do_nothing
			l_machine.on ("file_opened").from_state ("file_loaded").to ("file_loaded").apply.do_nothing
			l_machine.on ("file_opened").from_state ("completed").to ("file_loaded").apply.do_nothing
			l_machine.on ("file_opened").from_state ("error").to ("file_loaded").apply.do_nothing

			l_machine.on ("transcribe").from_state ("file_loaded").to ("transcribing").apply.do_nothing
			l_machine.on ("transcribe").from_state ("completed").to ("transcribing").apply.do_nothing

			l_machine.on ("done").from_state ("transcribing").to ("completed").apply.do_nothing
			l_machine.on ("failed").from_state ("transcribing").to ("error").apply.do_nothing
			l_machine.on ("cancelled").from_state ("transcribing").to ("file_loaded").apply.do_nothing

			l_machine.on ("dismiss").from_state ("error").to ("idle").apply.do_nothing

			l_machine.set_initial ("idle")
			l_machine.start
			state := l_machine
		end

feature {NONE} -- Window Construction

	create_main_window
			-- Build the main application window.
		local
			l_window: SV_WINDOW
			l_toolbar: SV_TOOLBAR
			l_main_split: SV_SPLITTER
			l_left_panel, l_center_panel: SV_COLUMN
			l_file_info_card, l_chapters_card, l_transcript_card: SV_CARD
			l_status_bar: SV_STATUSBAR
			l_list: SV_LIST
		do
			-- Create main window
			l_window := sv.window ("Speech Studio").size (1200, 800)

			-- Toolbar
			l_toolbar := create_toolbar

			-- Left panel: file info + chapters
			create lbl_file_name.make_with_text ("No file loaded")
			create lbl_file_info.make_with_text ("")

			l_file_info_card := sv.card_titled ("File Info")
			if attached lbl_file_name as al_file_name and attached lbl_file_info as al_file_info then
				l_file_info_card := l_file_info_card.content (
					sv.column_of (<<al_file_name, al_file_info>>).padding (10).spacing (5)
				)
			end

			l_list := sv.list
			chapter_list := l_list
			l_chapters_card := sv.card_titled ("Chapters").content (l_list)

			l_left_panel := sv.column_of (<<
				l_file_info_card,
				l_chapters_card
			>>).padding (10).spacing (10)

			-- Center panel: status + progress + segment list
			progress := sv.progress_bar.set_minimum_height (30).no_expand
			l_list := sv.list
			segment_list := l_list
			l_transcript_card := sv.card_titled ("Transcript").content (l_list)

			create lbl_status.make_with_text ("Open a file to begin transcription")

			if attached progress as al_progress and attached lbl_status as al_status then
				l_center_panel := sv.column_of (<<
					al_status,
					al_progress,
					l_transcript_card
				>>).padding (10).spacing (10)
			else
				l_center_panel := sv.column_of (<<l_transcript_card>>).padding (10)
			end

			-- Main split
			l_main_split := sv.horizontal_splitter
			l_main_split := l_main_split.first (l_left_panel.set_minimum_width (280))
			l_main_split := l_main_split.second (l_center_panel)

			-- Status bar
			l_status_bar := sv.statusbar_with ("Ready").no_expand

			-- Assemble window
			l_window := l_window.content (sv.column_of (<<l_toolbar, l_main_split, l_status_bar>>))

			add_window (l_window)
		end

	create_toolbar: SV_TOOLBAR
			-- Create the main toolbar.
		local
			l_toolbar: SV_TOOLBAR
			l_button: SV_TOOLBAR_BUTTON
		do
			l_toolbar := sv.toolbar

			-- Open File button
			l_button := sv.toolbar_button ("Open File")
			l_button.on_click (agent on_open_file)
			l_toolbar.add_button (l_button)

			-- Transcribe button (initially disabled)
			l_button := sv.toolbar_button ("Transcribe")
			l_button.on_click (agent on_transcribe)
			l_button.disable
			btn_transcribe := l_button
			l_toolbar.add_button (l_button)

			-- Cancel button (initially disabled)
			l_button := sv.toolbar_button ("Cancel")
			l_button.on_click (agent on_cancel)
			l_button.disable
			btn_cancel := l_button
			l_toolbar.add_button (l_button)

			-- Separator
			l_toolbar.separator

			-- Export buttons (initially disabled)
			l_button := sv.toolbar_button ("Export VTT")
			l_button.on_click (agent on_export_vtt)
			l_button.disable
			btn_export_vtt := l_button
			l_toolbar.add_button (l_button)

			l_button := sv.toolbar_button ("Export SRT")
			l_button.on_click (agent on_export_srt)
			l_button.disable
			btn_export_srt := l_button
			l_toolbar.add_button (l_button)

			l_button := sv.toolbar_button ("Export JSON")
			l_button.on_click (agent on_export_json)
			l_button.disable
			btn_export_json := l_button
			l_toolbar.add_button (l_button)

			Result := l_toolbar
		end

feature -- Event Handlers

	on_open_file
			-- Handle Open File button click.
		local
			l_dialog: SV_FILE_DIALOG
			l_path: STRING_32
		do
			l_dialog := sv.open_file_dialog
			l_dialog := l_dialog.filter ("Audio/Video", "*.mp3;*.wav;*.mp4;*.mkv;*.avi;*.mov;*.ogg;*.flac;*.m4a")
			if attached main_window as al_main_window then
				l_dialog.show (al_main_window)
				l_path := l_dialog.file_name
				if not l_path.is_empty then
					load_file (l_path.to_string_8)
				end
			end
		end

	load_file (a_path: STRING)
			-- Load a media file for transcription.
		local
			l_file: RAW_FILE
		do
			current_file := a_path
			current_file_name := extract_filename (a_path)

			if attached lbl_file_name as al_file_name and attached current_file_name as al_current_file_name then
				al_file_name.set_text (al_current_file_name).do_nothing
			end
			if attached lbl_file_info as al_file_info then
				create l_file.make_with_name (a_path)
				if l_file.exists then
					al_file_info.set_text ("Size: " + format_size (l_file.count)).do_nothing
				else
					al_file_info.set_text ("File not found").do_nothing
				end
			end
			if attached lbl_status as al_status and attached current_file_name as al_current_file_name then
				al_status.set_text ("Ready to transcribe: " + al_current_file_name).do_nothing
			end

			-- Enable transcribe button
			if attached btn_transcribe as al_btn_transcribe then
				al_btn_transcribe.enable
			end

			-- Trigger state transition
			if attached state as al_state then
				al_state.trigger ("file_opened").do_nothing
			end
		end

	on_transcribe
			-- Handle Transcribe button click - starts async transcription.
		do
			if attached current_file as al_current_file then
				-- Update UI
				if attached lbl_status as al_status then
					al_status.set_text ("Starting transcription...").do_nothing
				end
				if attached progress as al_progress then
					al_progress.set_value (0)
				end

				-- Toggle buttons
				if attached btn_transcribe as al_btn then
					al_btn.disable
				end
				if attached btn_cancel as al_btn then
					al_btn.enable
				end

				-- Disable export buttons during transcription
				if attached btn_export_vtt as al_btn then al_btn.disable end
				if attached btn_export_srt as al_btn then al_btn.disable end
				if attached btn_export_json as al_btn then al_btn.disable end

				-- State transition
				if attached state as al_state then
					al_state.trigger ("transcribe").do_nothing
				end

				-- Start async transcription (non-blocking!)
				start_async_transcription (transcriber, al_current_file, Current)
			end
		end

	on_cancel
			-- Handle Cancel button click.
		do
			cancel_transcription (transcriber)
			if attached lbl_status as al_status then
				al_status.set_text ("Cancelling...").do_nothing
			end
		end

feature -- SPEECH_PROGRESS_HANDLER Implementation

	on_progress (a_percent: INTEGER; a_phase: separate READABLE_STRING_GENERAL)
			-- Called when transcription progress updates.
			-- SCOOP ensures this runs on the UI processor.
		do
			if attached lbl_status as al_status then
				al_status.set_text (import_string (a_phase)).do_nothing
			end
			if attached progress as al_progress then
				al_progress.set_value (a_percent)
			end
          -- Force immediate repaint
          ev_application.process_graphical_events
		end

	on_transcription_complete (a_segments: separate ARRAYED_LIST [SPEECH_SEGMENT]; a_chapters: separate ARRAYED_LIST [SPEECH_CHAPTER])
			-- Called when transcription successfully completes.
		do
			-- Store results locally (copy from separate to local)
			transcribed_segments.wipe_out
			copy_segments (a_segments)
			transcribed_chapters.wipe_out
			copy_chapters (a_chapters)

			-- Update UI
			update_segment_list
			update_chapter_list

			if attached lbl_status as al_status then
				al_status.set_text ("Completed: " + transcribed_segments.count.out + " segments, " + transcribed_chapters.count.out + " chapters").do_nothing
			end
			if attached progress as al_progress then
				al_progress.set_value (100)
			end

			-- Enable export buttons
			if attached btn_export_vtt as al_btn then al_btn.enable end
			if attached btn_export_srt as al_btn then al_btn.enable end
			if attached btn_export_json as al_btn then al_btn.enable end

			-- Toggle buttons back
			if attached btn_transcribe as al_btn then
				al_btn.enable
			end
			if attached btn_cancel as al_btn then
				al_btn.disable
			end

			-- State transition
			if attached state as al_state then
				al_state.trigger ("done").do_nothing
			end
		end

	on_transcription_error (a_message: separate READABLE_STRING_GENERAL)
			-- Called when transcription fails.
		do
			if attached lbl_status as al_status then
				al_status.set_text ("Error: " + import_string (a_message)).do_nothing
			end

			-- Toggle buttons back
			if attached btn_transcribe as al_btn then
				al_btn.enable
			end
			if attached btn_cancel as al_btn then
				al_btn.disable
			end

			-- State transition
			if attached state as al_state then
				al_state.trigger ("failed").do_nothing
			end
		end

	on_transcription_cancelled
			-- Called when transcription is cancelled.
		do
			if attached lbl_status as al_status and attached current_file_name as al_file_name then
				al_status.set_text ("Cancelled. Ready to transcribe: " + al_file_name).do_nothing
			end
			if attached progress as al_progress then
				al_progress.set_value (0)
			end

			-- Toggle buttons back
			if attached btn_transcribe as al_btn then
				al_btn.enable
			end
			if attached btn_cancel as al_btn then
				al_btn.disable
			end

			-- State transition
			if attached state as al_state then
				al_state.trigger ("cancelled").do_nothing
			end
		end

feature {NONE} -- SCOOP Helpers

	start_async_transcription (a_transcriber: separate SPEECH_ASYNC_TRANSCRIBER; a_file: STRING; a_handler: separate SPEECH_PROGRESS_HANDLER)
			-- Start transcription on separate processor (SCOOP pattern).
		do
			a_transcriber.transcribe_async (a_file, a_handler)
		end

	cancel_transcription (a_transcriber: separate SPEECH_ASYNC_TRANSCRIBER)
			-- Request cancellation on separate processor.
		do
			a_transcriber.cancel
		end

feature {NONE} -- SCOOP Data Import

	import_string (a_separate: separate READABLE_STRING_GENERAL): STRING
			-- Import string from separate object (char-by-char copy for SCOOP).
		local
			i: INTEGER
		do
			create Result.make (a_separate.count)
			from i := 1 until i > a_separate.count loop
				Result.extend (a_separate.item (i).to_character_8)
				i := i + 1
			end
		end

	copy_segments (a_segments: separate ARRAYED_LIST [SPEECH_SEGMENT])
			-- Copy segments from separate list to local storage.
		local
			i: INTEGER
			l_seg: separate SPEECH_SEGMENT
		do
			from i := 1 until i > a_segments.count loop
				l_seg := a_segments.i_th (i)
				transcribed_segments.extend (import_segment (l_seg))
				i := i + 1
			end
		end

	copy_chapters (a_chapters: separate ARRAYED_LIST [SPEECH_CHAPTER])
			-- Copy chapters from separate list to local storage.
		local
			i: INTEGER
			l_ch: separate SPEECH_CHAPTER
		do
			from i := 1 until i > a_chapters.count loop
				l_ch := a_chapters.i_th (i)
				transcribed_chapters.extend (import_chapter (l_ch))
				i := i + 1
			end
		end

	import_segment (a_seg: separate SPEECH_SEGMENT): SPEECH_SEGMENT
			-- Create local copy of separate segment.
		do
			create Result.make (import_string (a_seg.text), a_seg.start_time, a_seg.end_time)
		end

	import_chapter (a_ch: separate SPEECH_CHAPTER): SPEECH_CHAPTER
			-- Create local copy of separate chapter.
		do
			create Result.make_with_title (a_ch.start_time, a_ch.end_time, import_string (a_ch.title))
		end

feature {NONE} -- UI Updates

	update_segment_list
			-- Populate segment list with transcribed text.
		do
			if attached segment_list as al_segment_list then
				al_segment_list.clear
				across transcribed_segments as seg loop
					al_segment_list.add_item (format_timestamp (seg.start_time) + " - " + seg.text)
				end
			end
		end

	update_chapter_list
			-- Populate chapter list.
		do
			if attached chapter_list as al_chapter_list then
				al_chapter_list.clear
				across transcribed_chapters as ch loop
					al_chapter_list.add_item (format_timestamp (ch.start_time) + " - " + ch.title)
				end
			end
		end

feature -- Export Handlers

	on_export_vtt
			-- Export to VTT format.
		local
			l_dialog: SV_FILE_DIALOG
			l_path: STRING_32
			l_exporter: VTT_EXPORTER
		do
			l_dialog := sv.save_file_dialog
			l_dialog := l_dialog.filter ("WebVTT", "*.vtt")
			l_dialog := l_dialog.default_name (safe_filename + ".vtt")
			if attached main_window as al_main_window then
				l_dialog.show (al_main_window)
				l_path := l_dialog.file_name
				if not l_path.is_empty then
					create l_exporter.make
					l_exporter.set_segments (transcribed_segments)
					if l_exporter.export_to_file (l_path.to_string_8) then
						show_info ("Exported to " + l_path.to_string_8)
					else
						show_info ("Export failed")
					end
				end
			end
		end

	on_export_srt
			-- Export to SRT format.
		local
			l_dialog: SV_FILE_DIALOG
			l_path: STRING_32
			l_exporter: SRT_EXPORTER
		do
			l_dialog := sv.save_file_dialog
			l_dialog := l_dialog.filter ("SubRip", "*.srt")
			l_dialog := l_dialog.default_name (safe_filename + ".srt")
			if attached main_window as al_main_window then
				l_dialog.show (al_main_window)
				l_path := l_dialog.file_name
				if not l_path.is_empty then
					create l_exporter.make
					l_exporter.set_segments (transcribed_segments)
					if l_exporter.export_to_file (l_path.to_string_8) then
						show_info ("Exported to " + l_path.to_string_8)
					else
						show_info ("Export failed")
					end
				end
			end
		end

	on_export_json
			-- Export to JSON format.
		local
			l_dialog: SV_FILE_DIALOG
			l_path: STRING_32
			l_exporter: JSON_EXPORTER
		do
			l_dialog := sv.save_file_dialog
			l_dialog := l_dialog.filter ("JSON", "*.json")
			l_dialog := l_dialog.default_name (safe_filename + ".json")
			if attached main_window as al_main_window then
				l_dialog.show (al_main_window)
				l_path := l_dialog.file_name
				if not l_path.is_empty then
					create l_exporter.make
					l_exporter.set_segments (transcribed_segments)
					if l_exporter.export_to_file (l_path.to_string_8) then
						show_info ("Exported to " + l_path.to_string_8)
					else
						show_info ("Export failed")
					end
				end
			end
		end

feature {NONE} -- Utilities

	extract_filename (a_path: STRING): STRING
			-- Extract just the filename from a path.
		local
			l_index: INTEGER
		do
			l_index := a_path.last_index_of ('\', a_path.count)
			if l_index = 0 then
				l_index := a_path.last_index_of ('/', a_path.count)
			end
			if l_index > 0 and l_index < a_path.count then
				Result := a_path.substring (l_index + 1, a_path.count)
			else
				Result := a_path
			end
		end

	format_size (a_bytes: INTEGER): STRING
			-- Format file size for display.
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
			-- Format seconds as MM:SS.
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

	safe_filename: STRING
			-- Get safe filename for export (without extension).
		local
			l_name: STRING
			l_dot: INTEGER
		do
			if attached current_file_name as al_current_file_name then
				l_name := al_current_file_name.twin
				l_dot := l_name.last_index_of ('.', l_name.count)
				if l_dot > 1 then
					Result := l_name.substring (1, l_dot - 1)
				else
					Result := l_name
				end
			else
				Result := "transcript"
			end
		end

	show_info (a_message: STRING)
			-- Show information message.
		local
			l_message_box: SV_MESSAGE_BOX
		do
			l_message_box := sv.info_box (a_message)
			if attached main_window as al_main_window then
				l_message_box.show (al_main_window)
			end
		end

end
