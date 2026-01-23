# Test Samples

Place test audio/video files here for diarization tests:

- `test_audio.wav` - WAV file for basic diarization test
- `test_video.mp4` - Video file for media diarization test

These files are NOT included in the repository due to size.
For CI/CD, either:
1. Use Git LFS to store them
2. Download from a known URL during test setup
3. Skip tests that require large media files

The tests will SKIP gracefully if samples are not present.
