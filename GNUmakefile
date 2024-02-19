#! /bin/make -f

PKGBASE := $(notdir $(basename $(shell pwd)))
PKGNAME := $(subst -,::,${PKGBASE})
PKGFILE := $(subst -,/,${PKGBASE})

################ Pass-through ################

.PHONY : all
all :	Makefile cleanup
	mv Makefile.old Makefile
	$(MAKE) -f Makefile all

.PHONY : test
test : Makefile
	$(MAKE) -f Makefile test

.PHONY : clean
clean : cleanup
	rm -f *~

.PHONY : cleanup
cleanup : Makefile
	$(MAKE) -f Makefile clean

.PHONY : dist
dist : Makefile
	$(MAKE) -f Makefile dist

.PHONY : install
install : Makefile
	$(MAKE) -f Makefile install

Makefile : Makefile.PL lib/${PKGFILE}/Version.pm
	perl Makefile.PL

################ Extensions ################

REL  := 0.022
DATE := $(shell date +%F)
TMP  := tmp

release : reltest _copy _fix_pl _fix_Makefile _fix_Changes _build _upd_ver

reltest :
	test "${REL}" != "0.022" 

# Make a temp copy of the distribution files.
_copy :
	rm -fr ${TMP}; mkdir ${TMP}
	rsync --files-from=MANIFEST --delete --archive ./ ${TMP}/
	cp -p lib/${PKGFILE}/Version.pm ${TMP}/lib/${PKGFILE}/

# Remove 'use Version' and insert a fixed version in pl and pm files.
_fix_pl :
	perl -ni \
		-e 's/use ${PKGNAME}::Version.*?;//;' \
		-e 's/our \$$VERSION =.*/our \$$VERSION = "${REL}";/;' \
		-e 'print;' \
		`find ${TMP} -name '*.p[lm]' -print`

# Insert fixed version in the Makefile.PL.
_fix_Makefile :
	perl -ni \
		-e 's/my \$$version =.*/my \$$version = "${REL}";/;' \
		-e 'print;' ${TMP}/Makefile.PL

# Update version and insert release date in Changes.
_fix_Changes :
	perl -ni \
		-e 's/^[._0-9]+\s*$$/${REL}\t${DATE}\n/;' \
		-e 'print;' ${TMP}/Changes

# Build the release kit.
_build :
	( cd ${TMP}; \
	  perl Makefile.PL; \
	  make all test dist; )

# Update the version file.
_upd_ver :
	cp ${TMP}/lib/${PKGFILE}/Version.pm lib/${PKGFILE}/Version.pm 
	perl -pe '$$. == 2 && print "\n0.000\n"' ${TMP}/Changes > ./Changes
