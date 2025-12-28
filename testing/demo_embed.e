note
	description: "Demo: Embed captions and chapters into video"
	author: "Larry Rix"

class
	DEMO_EMBED

create
	make

feature {NONE} -- Initialization

	make
		local
			pipeline: SPEECH_PIPELINE
			detector: SPEECH_TRANSITION_DETECTOR
			embedder: SPEECH_VIDEO_EMBEDDER
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			l_dummy: SPEECH_TRANSITION_DETECTOR
			l_input, l_output: STRING_8
			l_ffmpeg: FFMPEG_CLI
		do
			print ("=== Simple Speech Embedding Demo ===%N%N")
			print ("This demo transcribes a video, detects chapters,%N")
			print ("and embeds both captions and chapters into a new video file.%N%N")
			
			l_input := "testing/samples/blender_movies/sintel.mp4"
			l_output := "testing/output/embed/sintel_embedded.mp4"
			
			-- Create pipeline
			print ("1. Loading whisper model...%N")
			create pipeline.make ("models/ggml-base.en.bin")
			
			if not pipeline.is_ready then
				print ("ERROR: Pipeline not ready.%N")
			else
				print ("   Pipeline ready.%N%N")
				
				-- Transcribe
				print ("2. Transcribing video...%N")
				segments := pipeline.process_video (l_input)
				
				if pipeline.has_error then
					if attached pipeline.last_error as err then
						print ("ERROR: " + err + "%N")
					end
				else
					print ("   Found " + segments.count.out + " segments.%N%N")
					
					-- Detect chapters
					print ("3. Detecting chapters...%N")
					create detector.make
					l_dummy := detector.set_min_chapter_duration (60.0)
					chapters := detector.detect_transitions (segments)
					print ("   Found " + chapters.count.out + " chapters.%N%N")
					
					-- Check FFmpeg
					print ("4. Checking FFmpeg...%N")
					create l_ffmpeg.make
					if l_ffmpeg.is_available then
						print ("   FFmpeg available.%N%N")
						
						-- Create embedder
						print ("5. Embedding captions + chapters...%N")
						create embedder.make (l_ffmpeg)
						
						if embedder.embed_all (l_input, segments, chapters, l_output) then
							print ("   SUCCESS!%N")
							print ("   Output: " + l_output + "%N%N")
							print ("   The output video now contains:%N")
							print ("   - Embedded soft subtitles (toggleable)%N")
							print ("   - Chapter markers (navigable in VLC, YouTube, etc.)%N")
						else
							print ("   FAILED: ")
							if attached embedder.last_error as err then
								print (err.to_string_8 + "%N")
							else
								print ("Unknown error%N")
							end
						end
					else
						print ("   FFmpeg not available.%N")
					end
				end
			end
			
			print ("%N=== Demo Complete ===%N")
		end

end
