# important directories
prefix=/usr/local
datadir=$(prefix)/share
localedir=$(datadir)/locale

# compiler
CXX=c++

# compiler and linker flags
DEFINES=-D_ENABLE_NLS -DLOCALEDIR=\"$(localedir)\"
CXXFLAGS=-ggdb -I./include -I./stfl -I. -I/usr/local/include -I/sw/include -Wall -pedantic $(DEFINES)
LDFLAGS=-L/usr/local/lib -L/sw/lib

# libraries to link with
LIBS=-lstfl -lmrss -lnxml -lncurses -lsqlite3 -lidn -lpthread

OUTPUT=newsbeuter

SRC=$(wildcard *.cpp) $(wildcard src/*.cpp)
OBJS=$(patsubst %.cpp,%.o,$(SRC))

# additional commands
MKDIR=mkdir -p
INSTALL=install
A2X=a2x
MSGFMT=msgfmt

STFLHDRS=$(patsubst %.stfl,%.h,$(wildcard stfl/*.stfl))
POFILES=$(wildcard po/*.po)
MOFILES=$(patsubst %.po,%.mo,$(POFILES))
POTFILE=po/$(OUTPUT).pot

STFLCONV=./stfl2h.pl
RM=rm -f

all: $(OUTPUT)

$(OUTPUT): $(MOFILES) $(STFLHDRS) $(OBJS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) -o $(OUTPUT) $(OBJS) $(LIBS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ -c $<

%.h: %.stfl
	$(STFLCONV) $< > $@

testpp: src/xmlpullparser.cpp testpp.cpp
	$(CXX) -I./include -pg -g -D_TESTPP src/xmlpullparser.cpp testpp.cpp -o testpp

clean:
	$(RM) $(OUTPUT) $(OBJS) $(STFLHDRS) core *.core core.*
	$(RM) -rf doc/xhtml doc/*.xml

distclean: clean clean-mo
	$(RM) Makefile.deps

doc:
	$(MKDIR) doc/xhtml
	$(A2X) -f xhtml -d doc/xhtml doc/newsbeuter.txt

install: install-mo
	$(MKDIR) $(prefix)/bin
	$(INSTALL) $(OUTPUT) $(prefix)/bin
	$(MKDIR) $(prefix)/share/man/man1
	$(INSTALL) doc/$(OUTPUT).1 $(prefix)/share/man/man1

uninstall:
	$(RM) $(prefix)/bin/$(OUTPUT)
	$(RM) $(prefix)/share/man/man1/$(OUTPUT).1

Makefile.deps: $(SRC)
	$(CXX) $(CXXFLAGS) -MM -MG $(SRC) > Makefile.deps

.PHONY: doc clean all

# the following targets are i18n/l10n-related:

extract:
	$(RM) $(POTFILE)
	xgettext -k_ -o $(POTFILE) $(SRC)

msgmerge:
	for f in $(POFILES) ; do msgmerge -U $$f $(POTFILE) ; done

%.mo: %.po
	$(MSGFMT) --statistics -o $@ $<

clean-mo:
	$(RM) $(MOFILES) po/*~

install-mo:
	$(MKDIR) $(datadir)
	@for mof in $(MOFILES) ; do \
		mofile=`basename $$mof` ; \
		lang=`echo $$mofile | sed 's/\.mo$$//'`; \
		dir=$(localedir)/$$lang/LC_MESSAGES; \
		$(MKDIR) $$dir ; \
		$(INSTALL) -m 644 $$mof $$dir/$(OUTPUT).mo ; \
		echo "Installing $$mofile as $$dir/$(OUTPUT).mo" ; \
	done

include Makefile.deps
