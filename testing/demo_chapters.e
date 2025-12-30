note
	description: "Demo: Chapter detection and export"
	author: "Larry Rix"

class
	DEMO_CHAPTERS

create
	make

feature {NONE} -- Initialization

	make
		local
			pipeline: SPEECH_PIPELINE
			detector: SPEECH_TRANSITION_DETECTOR
			segments: ARRAYED_LIST [SPEECH_SEGMENT]
			chapters: ARRAYED_LIST [SPEECH_CHAPTER]
			result_obj: SPEECH_CHAPTERED_RESULT
			monitor: SPEECH_MEMORY_MONITOR
		do
			print ("=== Simple Speech Chapter Detection Demo ===%N%N")
			
			-- Check memory
			print ("1. Checking system memory...%N")
			create monitor.make
			print ("   " + monitor.memory_status_string + "%N%N")
			
			-- Create pipeline
			print ("2. Loading whisper model...%N")
			create pipeline.make ("models/ggml-base.en.bin")
			
			if not pipeline.is_ready then
				print ("ERROR: Pipeline not ready. Check FFmpeg and model.%N")
			else
				print ("   Pipeline ready.%N%N")
				
				-- Process video
				print ("3. Transcribing video...%N")
				segments := pipeline.process_video ("testing/samples/blender_movies/sintel.mp4")
				
				if pipeline.has_error then
					if attached pipeline.last_error as err then
						print ("ERROR: " + err + "%N")
					else
						print ("ERROR: Unknown error%N")
					end
				else
					print ("   Found " + segments.count.out + " segments.%N%N")
					
					-- Detect chapters
					print ("4. Detecting chapter transitions...%N")
					create detector.make
					detector.set_sensitivity (detector.Sensitivity_medium)
					detector.set_min_chapter_duration (60.0)
					
					chapters := detector.detect_transitions (segments)
					print ("   Found " + chapters.count.out + " chapters.%N%N")
					
					-- Show chapters
					print ("5. Detected chapters:%N")
					across chapters as ch loop
						print ("   [" + ch.formatted_start + " - " + ch.formatted_end + "] ")
						print (ch.title.to_string_8)
						print (" (" + ch.transition_type + ", confidence: ")
						print ((ch.confidence * 100).truncated_to_integer.out + "%%)")
						print ("%N")
					end
					print ("%N")
					
					-- Export
					print ("6. Exporting chapters...%N")
					create result_obj.make (segments, chapters)
					
					if result_obj.export_chapters_json ("testing/output/chapters/sintel_chapters.json") then
						print ("   Exported: sintel_chapters.json%N")
					end
					
					if result_obj.export_chapters_vtt ("testing/output/chapters/sintel_chapters.vtt") then
						print ("   Exported: sintel_chapters.vtt%N")
					end
					
					if result_obj.export_full_vtt ("testing/output/chapters/sintel_full.vtt") then
						print ("   Exported: sintel_full.vtt (with chapter markers)%N")
					end
				end
			end
			
			print ("%N=== Demo Complete ===%N")
		end

end
