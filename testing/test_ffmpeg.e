note
    description: "Quick FFmpeg test"
class TEST_FFMPEG
create make
feature {NONE} -- Initialization
    make
        local
            cli: FFMPEG_CLI
            l_file: RAW_FILE
        do
            print ("=== FFmpeg Test ===%N")
            create cli.make
            print ("Initial is_available: " + cli.is_available.out + "%N")
            print ("Initial is_ffprobe_available: " + cli.is_ffprobe_available.out + "%N")
            if attached cli.ffmpeg_path as fp then
                print ("FFmpeg path: " + fp.to_string_8 + "%N")
            else
                print ("FFmpeg path: Void%N")
            end
            if attached cli.ffprobe_path as pp then
                print ("FFprobe path: " + pp.to_string_8 + "%N")
            else
                print ("FFprobe path: Void%N")
            end
            
            -- Try setting paths manually
            print ("%NTrying D:\ffmpeg\bin\...%N")
            create l_file.make_with_name ("D:\ffmpeg\bin\ffmpeg.exe")
            print ("FFmpeg exists: " + l_file.exists.out + "%N")
            create l_file.make_with_name ("D:\ffmpeg\bin\ffprobe.exe")
            print ("FFprobe exists: " + l_file.exists.out + "%N")
            
            if l_file.exists then
                cli.set_ffmpeg_path ("D:\ffmpeg\bin\ffmpeg.exe")
                cli.set_ffprobe_path ("D:\ffmpeg\bin\ffprobe.exe")
                print ("After setting:%N")
                print ("is_available: " + cli.is_available.out + "%N")
                print ("is_ffprobe_available: " + cli.is_ffprobe_available.out + "%N")
                
                -- Try probe
                print ("%NTrying probe...%N")
                if attached cli.probe ("testing/samples/blender_movies/sintel.mp4") as info then
                    print ("Probe succeeded!%N")
                    print ("Duration: " + info.duration.out + "%N")
                    print ("Has audio: " + info.has_audio.out + "%N")
                else
                    print ("Probe returned Void%N")
                    if attached cli.last_error as err then
                        print ("Error: " + err.to_string_8 + "%N")
                    end
                end
            end
        end
end
