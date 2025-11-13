# Makefile for dynamic library interface to GNU multiprecision package GMP

# The runtime system must be compiled with support for dynamic libraries.
# The GNU GMP multiprecision package must be installed.

# Where to find GMP header file and compiled library
# Uses pkg-config if available, otherwise falls back to common default locations.
# Can be overridden: make GMPINCDIR=/path/to/gmp/include GMPLIBDIR=/path/to/gmp/lib

GMPINCDIR ?= $(shell pkg-config --cflags-only-I gmp 2>/dev/null | sed 's/-I//' | xargs)
GMPLIBDIR ?= $(shell pkg-config --libs-only-L gmp 2>/dev/null | sed 's/-L//' | xargs)

# Fallback to common locations if pkg-config fails
ifeq ($(GMPINCDIR),)
  GMPINCDIR ?= $(shell \
    for dir in /opt/homebrew/opt/gmp/include /opt/homebrew/include /usr/local/include /usr/include /usr/include/x86_64-linux-gnu; do \
      [ -f $$dir/gmp.h ] && echo $$dir && break; \
    done)
endif
ifeq ($(GMPLIBDIR),)
  GMPLIBDIR ?= $(shell \
    for dir in /opt/homebrew/opt/gmp/lib /opt/homebrew/lib /usr/local/lib /usr/lib /usr/lib/x86_64-linux-gnu; do \
      ls "$$dir"/libgmp* > /dev/null 2>&1 && echo "$$dir" && break; \
    done)
endif

include ../../Makefile.inc

#OPTS=-fno-defer-pop
ROOTDIR:=../..
CFLAGS=-Dunix -O3 $(OPTS) $(ADDDYNLIBCFLAGS) -I$(CAMLRT) $(if $(GMPINCDIR),-I${GMPINCDIR},)
#CFLAGS=-Dunix -O2 $(OPTS) $(ADDDYNLIBCFLAGS) -I$(INCDIR) -I ${GMPDIR}

MOSMLTOOLS=camlrunm $(TOOLDIR)

all: libmgmp.so IntInf.uo

install:
	$(INSTALL_DATA) libmgmp.so $(DESTDIR)$(LIBDIR)
	$(INSTALL_DATA) IntInf.sig $(DESTDIR)$(LIBDIR)
	$(INSTALL_DATA) IntInf.ui $(DESTDIR)$(LIBDIR)
	$(INSTALL_DATA) IntInf.uo $(DESTDIR)$(LIBDIR)

uninstall:
	cd $(DESTDIR)$(LIBDIR) && ${UNINSTALL_DATA} libmgmp.so IntInf.sig IntInf.ui IntInf.uo

intinf.o: intinf.c
	$(CC) $(CFLAGS) -c -o intinf.o intinf.c

libmgmp.so: intinf.o
	$(DYNLD) -o libmgmp.so intinf.o $(if $(GMPLIBDIR),-L$(GMPLIBDIR),) -lgmp -lc

test:
	echo $(CURDIR)
	mosml testintinf.sml

clean:
	rm -f *.o
	rm -f *.so
	rm -f *.ui
	rm -f *.uo
	rm -f Makefile.bak

depend: 
	rm -f Makefile.bak
	mv Makefile Makefile.bak
	$(MOSMLTOOLS)/cutdeps < Makefile.bak > Makefile
	$(MOSMLTOOLS)/mosmldep >> Makefile

### DO NOT DELETE THIS LINE
IntInf.uo: IntInf.ui 
