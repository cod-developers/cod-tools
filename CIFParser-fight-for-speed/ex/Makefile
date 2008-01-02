# $Id$

VERSION=0.6

all: CalcParser.pm GenParser.pm

CalcParser.pm: calc.y
	pbyacc -P CalcParser calc.y

GenParser.pm: gen.y
	pbyacc -P GenParser gen.y

clean:
	-rm -f CalcParser.pm GenParser.pm

patch:
	cd ..; \
	diff -C 2 perl-byacc1.8.2.orig perl-byacc1.8.2 > patch; \
	mv patch perl5-byacc-patches

dist:
	cd ..; \
	mv perl5-byacc-patches perl5-byacc-patches-$(VERSION); \
	tar cvf perl5-byacc-patches-$(VERSION).tar \
	  `find perl5-byacc-patches-$(VERSION) -type f | grep -v CVS`; \
	gzip perl5-byacc-patches-$(VERSION).tar; \
	mv perl5-byacc-patches-$(VERSION) perl5-byacc-patches; \
	mv perl5-byacc-patches-$(VERSION).tar.gz perl5-byacc-patches
