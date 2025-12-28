note
	description: "Demo: Video to captions pipeline"
	author: "Larry Rix"

class
	DEMO_PIPELINE

create
	make

feature {NONE} -- Initialization

	make
		local
			pipeline: SPEECH_PIPELINE
			l_segs: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			print ("=== Simple Speech Video Pipeline Demo ===%N%N")

			create pipeline.make ("models/ggml-base.en.bin")

			if not pipeline.is_ready then
				print ("ERROR: FFmpeg not available in PATH%N")
			else
				print ("FFmpeg available. Processing video...%N%N")

				-- Process Sintel video and export to all formats
				print ("Processing: testing/samples/blender_movies/sintel.mp4%N")
				l_segs := pipeline.process_video ("testing/samples/blender_movies/sintel.mp4")

				if pipeline.has_error and then attached pipeline.last_error as err then
					print ("ERROR: " + err.to_string_8 + "%N")
				else
					print ("Transcription complete: " + pipeline.segments.count.out + " segments%N%N")

					-- Export to all formats
					print ("Exporting to captions...%N")
					if pipeline.export_all ("testing/output/sintel") then
						print ("  Created: sintel.vtt%N")
						print ("  Created: sintel.srt%N")
						print ("  Created: sintel.json%N")
						print ("  Created: sintel.txt%N")
					else
						print ("Export failed!%N")
					end

					-- Show sample of transcription
					print ("%N=== Transcription Sample ===%N")
					show_sample (pipeline)

					-- Show video info
					if attached pipeline.video_info as vi then
						print ("%N=== Video Info ===%N")
						print ("Duration: " + vi.duration.out + " seconds%N")
						print ("Has audio: " + vi.has_audio.out + "%N")
						print ("Has video: " + vi.has_video.out + "%N")
					end
				end

				print ("%N=== Demo Complete ===%N")
			end
		end

	show_sample (a_pipeline: SPEECH_PIPELINE)
			-- Show first 5 segments.
		local
			i, n: INTEGER
		do
			n := a_pipeline.segments.count.min (5)
			from i := 1 until i > n loop
				print (format_time (a_pipeline.segments[i].start_time) + " - " +
				       format_time (a_pipeline.segments[i].end_time) + ": ")
				print (a_pipeline.segments[i].text.to_string_8 + "%N")
				i := i + 1
			end
			if a_pipeline.segments.count > 5 then
				print ("... (" + (a_pipeline.segments.count - 5).out + " more segments)%N")
			end
		end

	format_time (a_seconds: REAL_64): STRING_8
			-- Format seconds as MM:SS.
		local
			m, s: INTEGER
		do
			m := (a_seconds / 60).truncated_to_integer
			s := (a_seconds - m * 60).truncated_to_integer
			create Result.make (6)
			if m < 10 then Result.append ("0") end
			Result.append_integer (m)
			Result.append (":")
			if s < 10 then Result.append ("0") end
			Result.append_integer (s)
		end

end
