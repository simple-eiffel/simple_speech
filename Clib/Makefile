# POSIX build of the whisper wrapper object simple_speech.ecf expects on macOS and Linux.
# Usage: make -C Clib
# It compiles against the installed whisper.cpp headers (Homebrew on macOS, the
# system or /usr/local on Linux), never the Windows copies kept in this folder,
# because whisper_full_params is passed by value and must match the library.
CC ?= cc
WHISPER_PREFIX ?= $(shell [ -f /opt/homebrew/include/whisper.h ] && echo /opt/homebrew || echo /usr/local)
CFLAGS ?= -O2 -fPIC -I$(WHISPER_PREFIX)/include

whisper_wrapper.o: whisper_wrapper.c whisper_wrapper.h
	$(CC) $(CFLAGS) -c whisper_wrapper.c -o whisper_wrapper.o

clean:
	rm -f whisper_wrapper.o

.PHONY: clean
