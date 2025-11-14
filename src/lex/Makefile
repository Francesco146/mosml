# Unix Makefile for the Moscow ML lexer generator

INCLUDES=-I ../compiler
COMPFLAGS=$(INCLUDES)
LINKFLAGS=$(INCLUDES)

include ../Makefile.inc

LIBOBJS= \
    List.uo Vector.uo Array.uo Strbase.uo Char.uo String.uo StringCvt.uo \
    Word.uo Word8.uo Word8Vector.uo Word8Array.uo CharVector.uo CharArray.uo \
    Obj.uo BasicIO.uo Nonstdio.uo Lexing.uo Parsing.uo

EXTOBJS= \
    Miscsys.uo Printexc.uo Filename.uo Fnlib.uo Sort.uo \
    Arg.uo Hasht.uo

OBJS= \
    Syntax.uo Scan_aux.uo Gram_aux.uo Grammar.uo Scanner.uo \
    Lexgen.uo Output.uo Mainlex.uo

all: mosmllex

mosmllex: $(OBJS)
	$(MOSMLL) $(LINKFLAGS) -noheader -o mosmllex Mainlex.uo

clean:
	rm -f *.ui
	rm -f *.uo
	rm -f mosmllex
	rm -f mosmllex.bin
	rm -f Grammar.sml
	rm -f Grammar.sig
	rm -f Grammar.output
	rm -f Scanner.sml
	rm -f Makefile.bak
	cd test; make clean

install:
	${INSTALL_DATA} mosmllex $(DESTDIR)$(LIBDIR)

install_w32:
	@set -e; \
	# Verify inputs exist
	if [ ! -f ../launch.w32/header.exe ]; then \
		echo "Error: ../launch.w32/header.exe not found; run 'make install' from top-level or ensure launch.w32 is built." >&2; \
		exit 1; \
	fi; \
	if [ ! -f mosmllex ]; then \
		echo "Error: mosmllex not found; build the mosmllex target first (make)." >&2; \
		exit 1; \
	fi; \
	# Ensure destination directory exists
	mkdir -p "$(DESTDIR)$(BINDIR)"; \
	# Concatenate header and binary into the destination exe
	cat ../launch.w32/header.exe mosmllex > "$(DESTDIR)$(BINDIR)/mosmllex.exe"; \
	# Try to set executable bit when supported; ignore failure on filesystems that don't support it
	if command -v chmod >/dev/null 2>&1; then \
		chmod a+x "$(DESTDIR)$(BINDIR)/mosmllex.exe" || true; \
	fi

uninstall:
	${UNINSTALL_DATA} $(DESTDIR)$(LIBDIR)/mosmllex

Grammar.sml Grammar.sig: Grammar.grm
	$(MOSMLYACC) Grammar.grm

depend: Scanner.sml Grammar.sml Grammar.sig
	rm -f Makefile.bak
	mv Makefile Makefile.bak
	$(MOSMLCUT) < Makefile.bak > Makefile
	$(MOSMLDEP) >> Makefile

### DO NOT DELETE THIS LINE
Grammar.ui: Syntax.uo 
Grammar.uo: Grammar.ui Syntax.uo Gram_aux.uo 
Scanner.uo: Scanner.ui Syntax.uo Scan_aux.uo Grammar.ui 
Gram_aux.uo: Syntax.uo 
Output.uo: Syntax.uo 
Mainlex.uo: Lexgen.uo Syntax.uo Scan_aux.uo Scanner.ui Grammar.ui Output.uo 
Scanner.ui: Grammar.ui 
Lexgen.uo: Syntax.uo 
