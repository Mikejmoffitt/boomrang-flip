AS=asl
P2BIN=p2bin
SRC=patch.s
BSPLIT=bsplit
MAME=mame

ASFLAGS=

.PHONY: clean

all: clean prg.bin

prg.o:
	$(AS) $(SRC) $(ASFLAGS) -o prg.o

prg.bin: prg.o
	$(P2BIN) $< $@ -r \$$-0x10000

boomrang: prg.bin
	split prg.bin -b 16384
	$(BSPLIT) n xaa bp13.9k
	$(BSPLIT) n xab bp14.11k

test: boomrang
	$(MAME) -debug boomrang -r 480x512

clean:
	@-rm -f prg.bin
	@-rm -f prg.o
