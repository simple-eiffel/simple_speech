@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1
cd /d D:\prod\simple_speech\Clib
cl /c /MT /O2 /DNDEBUG ^
    /I"D:\prod\simple_speech\Clib" ^
    whisper_wrapper.c ^
    /Fo"whisper_wrapper.obj"
if %ERRORLEVEL% EQU 0 (
    lib /OUT:whisper_wrapper.lib whisper_wrapper.obj
    echo SUCCESS: Created whisper_wrapper.lib
) else (
    echo FAILED: Compilation error
)
