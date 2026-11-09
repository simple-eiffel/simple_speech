note
	description: "[
		Drives Speech Studio as a user would: opens the sample recording, clicks
		Transcribe, keeps the window turning while the relay works, and checks that
		segments came back through the mailbox. Also checks Cancel. Run it from
		simple_speech's folder (the model path is relative: models/ggml-base.en.bin).
	]"

class
	SPEECH_STUDIO_CHECK

create
	make

feature {NONE} -- Initialization

	make
		local
			l_studio: SPEECH_STUDIO_APP
			l_driver: GUI_TEST_DRIVER
			l_turns, l_progress_seen: INTEGER
		do
			create l_studio.make_studio
			create l_driver
			l_studio.window.show
			l_driver.pump_until_idle (300)
			l_studio.load_file (create {PATH}.make_from_string ("testing/samples/test_audio.wav"))
			check_that ("transcribe enabled after loading", l_studio.btn_transcribe.is_enabled)
			check_that ("exports disabled before a transcript", not l_studio.btn_export_vtt.is_enabled)

				-- A whole job, through the window
			l_driver.perform_click (l_studio.btn_transcribe)
			check_that ("running, and the window came straight back", l_studio.is_running)
			check_that ("cancel enabled while running", l_studio.btn_cancel.is_enabled)
			from
			until
				not l_studio.is_running or l_turns > 3000
			loop
				l_studio.app.process_events (100)
				if l_studio.progress.value > 0 and l_studio.progress.value < 100 then
					l_progress_seen := l_progress_seen + 1
				end
				l_turns := l_turns + 1
			end
			print ("  job took about " + (l_turns // 10).out + " s of window turns%N")
			print ("  status: " + l_studio.lbl_status.text.to_string_8 + "%N")
			check_that ("the job ended", not l_studio.is_running)
			check_that ("progress reached the window while it ran", l_progress_seen > 0)
			check_that ("segments came back", l_studio.transcribed_segments.count > 0)
			check_that ("the transcript list shows them", l_studio.segment_list.count = l_studio.transcribed_segments.count)
			check_that ("progress at 100", l_studio.progress.value = 100)
			check_that ("exports enabled", l_studio.btn_export_vtt.is_enabled)
			if l_studio.segment_list.count > 0 then
				print ("  first line: " + l_studio.segment_list.i_th (1).to_string_8 + "%N")
			end
			check_that ("picture", l_driver.snapshot (l_studio.window, create {PATH}.make_from_string ("speech_studio.png")))

				-- Cancel: the window is ready at once; the job's results are dropped
			l_driver.perform_click (l_studio.btn_transcribe)
			l_studio.app.process_events (100)
			l_driver.perform_click (l_studio.btn_cancel)
			check_that ("cancel disables itself", not l_studio.btn_cancel.is_enabled)
			l_turns := 0
			from
			until
				not l_studio.is_running or l_turns > 3000
			loop
				l_studio.app.process_events (100)
				l_turns := l_turns + 1
			end
			check_that ("cancelled job dropped", l_studio.transcribed_segments.is_empty)
			check_that ("transcribe back", l_studio.btn_transcribe.is_enabled)
			print ("  after cancel: " + l_studio.lbl_status.text.to_string_8 + "%N")

			l_studio.window.close
			print ("=== Results: " + passed.out + " passed, " + failed.out + " failed ===%N")
		end

feature {NONE} -- Implementation

	passed, failed: INTEGER

	check_that (a_name: STRING; a_ok: BOOLEAN)
		do
			if a_ok then
				passed := passed + 1
				print ("  PASS: " + a_name + "%N")
			else
				failed := failed + 1
				print ("  FAIL: " + a_name + "%N")
			end
		end

end
