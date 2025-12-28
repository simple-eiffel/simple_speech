note
	description: "Demo: Batch processing with memory-conscious design"
	author: "Larry Rix"

class
	DEMO_BATCH

create
	make

feature {NONE} -- Initialization

	make
		local
			pipeline: SPEECH_PIPELINE
			batch: SPEECH_BATCH_PROCESSOR
			monitor: SPEECH_MEMORY_MONITOR
			l_dummy: SPEECH_BATCH_PROCESSOR
		do
			print ("=== Simple Speech Batch Processing Demo ===%N%N")
			
			-- Check memory first
			print ("1. Checking system memory...%N")
			create monitor.make
			print ("   " + monitor.memory_status_string + "%N")
			print ("   " + monitor.recommended_settings_string + "%N%N")
			
			-- Create pipeline (loads model once)
			print ("2. Loading whisper model (one-time cost)...%N")
			create pipeline.make ("models/ggml-base.en.bin")
			
			if not pipeline.is_ready then
				print ("ERROR: FFmpeg not available. Cannot process videos.%N")
			else
				print ("   Pipeline ready. Memory now: " + monitor.get_process_memory_mb.out + " MB%N%N")
				
				-- Create batch processor with the pipeline
				print ("3. Creating batch processor...%N")
				create batch.make (pipeline)
				
				-- Add actual video files
				l_dummy := batch.add_file ("testing/samples/blender_movies/sintel.mp4")
				l_dummy := batch.add_file ("testing/samples/blender_movies/elephants_dream.mp4")
				l_dummy := batch.add_file ("testing/samples/blender_movies/tears_of_steel.mp4")
				l_dummy := batch.set_output_folder ("testing/output/batch/")
				l_dummy := batch.set_format ("vtt")
				l_dummy := batch.set_progress_callback (agent on_progress)
				
				print ("   Files to process: " + batch.files.count.out + "%N")
				print ("   Output folder: " + batch.output_folder + "%N")
				print ("   Format: " + batch.format + "%N%N")
				
				-- Run batch
				print ("4. Running batch processing...%N")
				if batch.run then
					print ("%N   All files processed successfully!%N")
				else
					print ("%N   Some files failed:%N")
					across batch.errors as err loop
						print ("   - " + err.to_string_8 + "%N")
					end
				end
				
				-- Final stats
				print ("%N5. Final statistics:%N")
				print ("   Succeeded: " + batch.progress.files_succeeded.out + "%N")
				print ("   Failed: " + batch.progress.files_failed.out + "%N")
				print ("   Total time: " + batch.progress.formatted_elapsed + "%N")
				print ("   Final memory: " + monitor.get_process_memory_mb.out + " MB%N")
			end
			
			print ("%N=== Demo Complete ===%N")
		end

	on_progress (info: SPEECH_PROGRESS_INFO)
			-- Progress callback.
		do
			print ("   [" + info.current_phase + "] ")
			print ("File " + info.current_file_index.out + "/" + info.total_files.out)
			print (" - " + info.current_file.to_string_8)
			if info.current_file_index > 0 then
				print (" (ETA: " + info.formatted_eta + ")")
			end
			print (" [" + info.memory_usage_mb.out + " MB]%N")
		end

end
