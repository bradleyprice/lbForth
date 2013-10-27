CC = gcc
M32 = -m32
CFLAGS = $(M32) -O2 -fomit-frame-pointer -fno-unit-at-a-time
CPPFLAGS = -I$(TARGET)
LDFLAGS = $(M32)

GREP = grep -a
ERROR_PATTERNS = -e 'INCORRECT RESULT' -e 'WRONG NUMBER'

TARGET = targets/c
meta = $(TARGET)/meta.fth
nucleus = $(TARGET)/nucleus.fth

%.c: %.fth
	echo 'include $(meta)  bye' | ./forth | tail -n+3 > $@

all: .bootstrap forth

.bootstrap: lisp/meta.lisp
	$(MAKE) -f$(TARGET)/bootstrap.mk CC="$(CC)" CFLAGS="$(CFLAGS)" \
	CPPFLAGS="$(CPPFLAGS)" LDFLAGS="$(LDFLAGS)"

lisp/meta.lisp:
	git submodule update --init

forth: kernel.o
	$(CC) $(LDFLAGS) $^ -o $@

kernel.o: kernel.c $(TARGET)/forth.h

kernel.c: kernel.fth dictionary.fth params.fth $(nucleus) $(meta)

params.fth: params
	./$< -forth > $@

params: $(TARGET)/params.c $(TARGET)/forth.h Makefile
	$(CC) $(CFLAGS) $(CPPFLAGS) $< -o $@

check: test-errors
	test `cat $<` -le 81

test-errors: test-output
	$(GREP) $(ERROR_PATTERNS) $< | wc -l > $@

test-output: test-input all
	./forth < $< > $@
	$(GREP) Test-OK $@

clean:
	rm -f forth .bootstrap *.o kernel.c params* test-output test-errors
