note
	description: "[
		SPEECH_CLI - Unified command-line interface for simple_speech.

		Usage:
			speech_cli <command> [options] <file>

		Commands:
			transcribe  - Transcribe audio/video to text
			export      - Export transcription to VTT/SRT/JSON/TXT
			chapters    - Detect and export chapter markers
			batch       - Process multiple files
			embed       - Embed captions/chapters into video
			info        - Show file information

		Options:
			--help, -h     Show this help
			--model, -m    Path to whisper model (default: models/ggml-base.en.bin)
			--language, -l Source language code (default: en)
			--output, -o   Output file or directory
			--format, -f   Export format: vtt, srt, json, txt (default: vtt)
			--threads, -t  CPU threads to use (default: 4)
			--translate    Translate to English
			--quiet, -q    Suppress progress output
	]"
	author: "Larry Rix"
	date: "2025-12-30"

class
	SPEECH_CLI

create
	make

feature {NONE} -- Initialization

	make
			-- Run CLI with command line arguments.
		local
			args: ARGUMENTS_32
		do

			create args
			create output_lines.make (20)

			model_path := "models/ggml-base.en.bin"
			language := "en"
			output_format := "vtt"
			thread_count := 4


			if args.argument_count = 0 then
				show_help
			else
				parse_arguments (args)
				if not has_error then
					execute_command
				end
			end

			-- Print all output
			across output_lines as line loop
				io.put_string (line.to_string_8)
				io.put_new_line
			end
			io.output.flush
		end

feature -- Status

	has_error: BOOLEAN
			-- Did an error occur?

	error_message: detachable STRING_32
			-- Error description if has_error.

	is_quiet: BOOLEAN
			-- Suppress progress output?

feature {NONE} -- Configuration

	command: detachable STRING_32
			-- Command to execute.

	input_file: detachable STRING_32
			-- Input file path.

	input_files: detachable ARRAYED_LIST [STRING_32]
			-- Multiple input files for batch.

	output_path: detachable STRING_32
			-- Output file or directory.

	model_path: STRING_32
			-- Path to whisper model.

	language: STRING_8
			-- Source language code.

	output_format: STRING_8
			-- Export format.

	thread_count: INTEGER
			-- CPU threads.

	do_translate: BOOLEAN
			-- Translate to English?

	output_lines: ARRAYED_LIST [STRING_32]
			-- Collected output lines.

feature {NONE} -- Argument Parsing

	parse_arguments (args: ARGUMENTS_32)
			-- Parse command line arguments.
		local
			i: INTEGER
			arg: STRING_32
		do
			from i := 1 until i > args.argument_count or has_error loop
				arg := args.argument (i)

				if arg.same_string ("--help") or arg.same_string ("-h") then
					show_help
					has_error := True -- Stop processing

				elseif arg.same_string ("--model") or arg.same_string ("-m") then
					i := i + 1
					if i <= args.argument_count then
						model_path := args.argument (i)
					else
						set_error ("--model requires a path")
					end

				elseif arg.same_string ("--language") or arg.same_string ("-l") then
					i := i + 1
					if i <= args.argument_count then
						language := args.argument (i).to_string_8
					else
						set_error ("--language requires a code")
					end

				elseif arg.same_string ("--output") or arg.same_string ("-o") then
					i := i + 1
					if i <= args.argument_count then
						output_path := args.argument (i)
					else
						set_error ("--output requires a path")
					end

				elseif arg.same_string ("--format") or arg.same_string ("-f") then
					i := i + 1
					if i <= args.argument_count then
						output_format := args.argument (i).to_string_8.as_lower
						if not valid_formats.has (output_format) then
							set_error ("Invalid format. Use: vtt, srt, json, txt")
						end
					else
						set_error ("--format requires a value")
					end

				elseif arg.same_string ("--threads") or arg.same_string ("-t") then
					i := i + 1
					if i <= args.argument_count then
						if args.argument (i).is_integer then
							thread_count := args.argument (i).to_integer
						else
							set_error ("--threads requires a number")
						end
					else
						set_error ("--threads requires a number")
					end

				elseif arg.same_string ("--translate") then
					do_translate := True

				elseif arg.same_string ("--quiet") or arg.same_string ("-q") then
					is_quiet := True

				elseif arg.starts_with ("-") then
					set_error ("Unknown option: " + arg)

				elseif command = Void then
					command := arg.as_lower

				elseif input_file = Void then
					input_file := arg

				else
					-- Additional files for batch
					if attached input_files as files then
						files.extend (arg)
					else
						create input_files.make (10)
						if attached input_files as new_files then
							if attached input_file as f then
								new_files.extend (f)
							end
							new_files.extend (arg)
						end
					end
				end

				i := i + 1
			end
		end

	valid_formats: ARRAYED_LIST [STRING_8]
			-- Valid export formats.
		once
			create Result.make (4)
			Result.extend ("vtt")
			Result.extend ("srt")
			Result.extend ("json")
			Result.extend ("txt")
		end

feature {NONE} -- Command Execution

	execute_command
			-- Execute the parsed command.
		do
			if attached command as cmd then
				if cmd.same_string ("transcribe") then
					do_transcribe
				elseif cmd.same_string ("export") then
					do_export
				elseif cmd.same_string ("chapters") then
					do_chapters
				elseif cmd.same_string ("batch") then
					do_batch
				elseif cmd.same_string ("embed") then
					do_embed
				elseif cmd.same_string ("info") then
					do_info
				elseif cmd.same_string ("help") then
					show_help
				else
					set_error ("Unknown command: " + cmd + ". Use --help for usage.")
				end
			else
				show_help
			end
		end

	do_transcribe
			-- Transcribe audio/video file.
		local
			speech: SPEECH_QUICK
		do
			if not attached input_file as f then
				set_error ("transcribe requires an input file")
			else
				log ("Loading model: " + model_path)
				create speech.make_with_model (model_path.to_string_8)

				if not speech.is_ready then
					set_error ("Failed to load model: " + model_path)
				else
					log ("Transcribing: " + f)
					speech.transcribe (f.to_string_8)

					if speech.has_segments then
						output ("=== Transcription (" + speech.segments.count.out + " segments) ===")
						across speech.segments as seg loop
							output ("[" + seg.start_time_formatted + " --> " + seg.end_time_formatted + "]")
							output (seg.text.to_string_32)
							output ("")
						end

						-- Export if output specified
						if attached output_path as op then
							export_segments (speech.segments, op.to_string_8)
						end
					else
						if attached speech.last_error as err then
							set_error ("Transcription failed: " + err)
						else
							set_error ("Transcription produced no segments")
						end
					end
				end
			end
		end

	do_export
			-- Export transcription to file.
		local
			speech: SPEECH_QUICK
		do
			if not attached input_file as f then
				set_error ("export requires an input file")
			elseif not attached output_path as op then
				set_error ("export requires --output path")
			else
				log ("Loading model: " + model_path)
				create speech.make_with_model (model_path.to_string_8)

				if not speech.is_ready then
					set_error ("Failed to load model")
				else
					log ("Transcribing: " + f)
					speech.transcribe (f.to_string_8)

					if speech.has_segments then
						export_segments (speech.segments, op.to_string_8)
					else
						set_error ("Transcription produced no segments")
					end
				end
			end
		end

	do_chapters
			-- Detect chapters and optionally export.
		local
			speech: SPEECH_QUICK
		do
			if not attached input_file as f then
				set_error ("chapters requires an input file")
			else
				log ("Loading model: " + model_path)
				create speech.make_with_model (model_path.to_string_8)

				if not speech.is_ready then
					set_error ("Failed to load model")
				else
					log ("Transcribing: " + f)
					speech.transcribe (f.to_string_8)

					if speech.has_segments then
						log ("Detecting chapters...")
						speech.detect_chapters

						output ("=== Chapters (" + speech.chapters.count.out + " found) ===")
						across speech.chapters as ch loop
							output ("[" + ch.formatted_start + " - " + ch.formatted_end + "] " + ch.title)
						end

						-- Export if output specified
						if attached output_path as op then
							export_chapters (speech.chapters, op.to_string_8)
						end
					else
						set_error ("Transcription produced no segments")
					end
				end
			end
		end

	do_batch
			-- Process multiple files.
		local
			pipeline: SPEECH_PIPELINE
			batch: SPEECH_BATCH_PROCESSOR
		do
			if not attached input_files as files or else files.is_empty then
				if attached input_file as f then
					create input_files.make (1)
					if attached input_files as fl then
						fl.extend (f)
					end
				else
					set_error ("batch requires input files")
				end
			end

			if not has_error and attached input_files as files then
				log ("Loading model: " + model_path)
				create pipeline.make (model_path)

				if not pipeline.is_ready then
					set_error ("Pipeline not ready. Check FFmpeg and model.")
				else
					create batch.make (pipeline)

					across files as f loop
						batch.add_file (f.to_string_8)
					end

					if attached output_path as op then
						batch.set_output_folder (op.to_string_8)
					end
					batch.set_format (output_format)

					log ("Processing " + files.count.out + " files...")

					if batch.run then
						output ("=== Batch Complete ===")
						output ("Succeeded: " + batch.progress.files_succeeded.out)
						output ("Failed: " + batch.progress.files_failed.out)
						output ("Time: " + batch.progress.formatted_elapsed)
					else
						output ("=== Batch Completed with Errors ===")
						across batch.errors as err loop
							output ("ERROR: " + err)
						end
					end
				end
			end
		end

	do_embed
			-- Embed captions into video.
		local
			speech: SPEECH_QUICK
			embedder: SPEECH_VIDEO_EMBEDDER
			ffmpeg: FFMPEG_CLI
		do
			if not attached input_file as f then
				set_error ("embed requires an input video")
			elseif not attached output_path as op then
				set_error ("embed requires --output path")
			else
				create ffmpeg.make
				if not ffmpeg.is_available then
					set_error ("FFmpeg not available in PATH")
				else
					log ("Loading model: " + model_path)
					create speech.make_with_model (model_path.to_string_8)

					if not speech.is_ready then
						set_error ("Failed to load model")
					else
						log ("Transcribing: " + f)
						speech.transcribe (f.to_string_8)

						if speech.has_segments then
							speech.detect_chapters

							log ("Embedding captions and chapters...")
							create embedder.make (ffmpeg)

							if embedder.embed_all (f.to_string_8, speech.segments, speech.chapters, op.to_string_8) then
								output ("=== Embed Complete ===")
								output ("Output: " + op)
								output ("Segments: " + speech.segments.count.out)
								output ("Chapters: " + speech.chapters.count.out)
							else
								if attached embedder.last_error as err then
									set_error ("Embed failed: " + err)
								else
									set_error ("Embed failed")
								end
							end
						else
							set_error ("Transcription produced no segments")
						end
					end
				end
			end
		end

	do_info
			-- Show file information.
		local
			ffmpeg: FFMPEG_CLI
		do
			if not attached input_file as f then
				set_error ("info requires an input file")
			else
				create ffmpeg.make
				if not ffmpeg.is_available then
					set_error ("FFmpeg not available")
				else
					if attached ffmpeg.probe (f.to_string_8) as info then
						output ("=== File Info ===")
						output ("File: " + f)
						output ("Duration: " + info.duration.out + " seconds")
						output ("Has video: " + info.has_video.out)
						output ("Has audio: " + info.has_audio.out)
						if info.has_video then
							if attached info.video_codec as vc then
								output ("Video codec: " + vc)
							end
							output ("Resolution: " + info.video_width.out + "x" + info.video_height.out)
						end
						if info.has_audio then
							if attached info.audio_codec as ac then
								output ("Audio codec: " + ac)
							end
							output ("Sample rate: " + info.audio_sample_rate.out)
							output ("Channels: " + info.audio_channels.out)
						end
					else
						set_error ("Could not probe file: " + f)
					end
				end
			end
		end

feature {NONE} -- Export Helpers

	export_segments (a_segments: ARRAYED_LIST [SPEECH_SEGMENT]; a_path: STRING_8)
			-- Export segments to file.
		local
			exporter: SPEECH_EXPORTER
		do
			create exporter.make (a_segments)

			if output_format.same_string ("vtt") then
				exporter.export_vtt (a_path)
			elseif output_format.same_string ("srt") then
				exporter.export_srt (a_path)
			elseif output_format.same_string ("json") then
				exporter.export_json (a_path)
			elseif output_format.same_string ("txt") then
				exporter.export_text (a_path)
			end

			if exporter.is_ok then
				output ("Exported: " + a_path + " (" + output_format.as_upper + ")")
			else
				across exporter.errors as err loop
					output ("Export error: " + err)
				end
			end
		end

	export_chapters (a_chapters: ARRAYED_LIST [SPEECH_CHAPTER]; a_path: STRING_8)
			-- Export chapters to file.
		local
			result_obj: SPEECH_CHAPTERED_RESULT
			segs: ARRAYED_LIST [SPEECH_SEGMENT]
		do
			create segs.make (0)
			create result_obj.make (segs, a_chapters)

			if output_format.same_string ("json") then
				if result_obj.export_chapters_json (a_path) then
					output ("Exported: " + a_path + " (JSON)")
				else
					set_error ("Failed to export chapters")
				end
			else
				if result_obj.export_chapters_vtt (a_path) then
					output ("Exported: " + a_path + " (VTT)")
				else
					set_error ("Failed to export chapters")
				end
			end
		end

feature {NONE} -- Output

	log (a_message: READABLE_STRING_GENERAL)
			-- Log progress message (respects quiet mode).
		do
			if not is_quiet then
				output_lines.extend (a_message.to_string_32)
			end
		end

	output (a_message: READABLE_STRING_GENERAL)
			-- Output message (always shown).
		do
			output_lines.extend (a_message.to_string_32)
		end

	set_error (a_message: READABLE_STRING_GENERAL)
			-- Set error state.
		do
			has_error := True
			error_message := a_message.to_string_32
			output_lines.extend ({STRING_32} "ERROR: " + a_message.to_string_32)
		end

	show_help
			-- Display help message.
		do
			output ("simple_speech - Speech-to-text transcription toolkit")
			output ("")
			output ("USAGE:")
			output ("  speech_cli <command> [options] <file(s)>")
			output ("")
			output ("COMMANDS:")
			output ("  transcribe <file>     Transcribe audio/video to text")
			output ("  export <file>         Transcribe and export to file (requires --output)")
			output ("  chapters <file>       Detect chapter markers")
			output ("  batch <files...>      Process multiple files")
			output ("  embed <video>         Embed captions/chapters into video (requires --output)")
			output ("  info <file>           Show media file information")
			output ("  help                  Show this help message")
			output ("")
			output ("OPTIONS:")
			output ("  -h, --help            Show this help")
			output ("  -m, --model <path>    Whisper model path (default: models/ggml-base.en.bin)")
			output ("  -l, --language <code> Source language: en, es, zh, etc. (default: en)")
			output ("  -o, --output <path>   Output file or directory")
			output ("  -f, --format <fmt>    Export format: vtt, srt, json, txt (default: vtt)")
			output ("  -t, --threads <n>     CPU threads (default: 4)")
			output ("  --translate           Translate to English")
			output ("  -q, --quiet           Suppress progress messages")
			output ("")
			output ("EXAMPLES:")
			output ("  # Transcribe and print to console")
			output ("  speech_cli transcribe video.mp4")
			output ("")
			output ("  # Transcribe and export to SRT")
			output ("  speech_cli export video.mp4 --output captions.srt --format srt")
			output ("")
			output ("  # Detect chapters")
			output ("  speech_cli chapters video.mp4 --output chapters.json --format json")
			output ("")
			output ("  # Batch process multiple files")
			output ("  speech_cli batch video1.mp4 video2.mp4 --output ./captions/")
			output ("")
			output ("  # Embed captions into video")
			output ("  speech_cli embed video.mp4 --output video_with_captions.mp4")
			output ("")
			output ("  # Use different model and language")
			output ("  speech_cli transcribe audio.wav --model models/ggml-large.bin --language es")
			output ("")
			output ("SUPPORTED FORMATS:")
			output ("  Input:  .mp4, .mkv, .webm, .avi, .mov, .wav, .mp3, .flac, .ogg")
			output ("  Export: .vtt (WebVTT), .srt (SubRip), .json, .txt")
			output ("")
			output ("MODELS:")
			output ("  Download Whisper models from: https://huggingface.co/ggerganov/whisper.cpp")
			output ("  Recommended: ggml-base.en.bin (English) or ggml-base.bin (multilingual)")
		end

end
