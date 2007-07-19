
COD_DIR  = ./inputs/cod
DICT_DIR = ${HOME}/down/CIF-dictionaries

LISTS = \
tags.lst \
tags-counted.lst \
tags-sorted.lst \
tags-not-in-dictionaries.lst \
tags-indict-counted.lst \
tags-indict-sorted.lst \
tags-indict-canonical.lst \
looped-blocks.lst \
looped-tags.lst \
##

all: ${LISTS}

tags.lst:
	find ${COD_DIR}/cif/ -name '*.[Cc][Ii][Ff]' \
	| xargs perl -ne \
	'print lc($$2), "\n" if /(^|\s)(_[^\s]+)(\s|$$)/' \
	> $@

tags-sorted.lst: tags.lst
	sort $< | uniq > $@

tags-counted.lst: tags.lst
	sort $< | uniq -c | sort -nr -k1 > $@

tags-not-in-dictionaries.lst: tags-sorted.lst
	for i in `cat $<`; do \
		if perl -ne "exit 1 if m:'\Q$$i\E':i" ${DICT_DIR}/*.dic; \
		then \
			echo $$i; \
		fi; \
	done \
	> $@

tags-indict-sorted.lst: tags-sorted.lst tags-not-in-dictionaries.lst
	cp -av $< $@
	for i in `cat ${word 2,$^}`; do \
		mv $@ tmp-$$$$; \
		perl -ne "print unless m:(^|\\s)\\Q$$i\\E(\\s|$$):" \
			tmp-$$$$ > $@; \
	done; \
	rm -v tmp-$$$$

tags-indict-counted.lst: tags-counted.lst tags-not-in-dictionaries.lst
	cp -av $< $@
	for i in `cat ${word 2,$^}`; do \
		mv $@ tmp-$$$$; \
		perl -ne "print unless m:\\s\\Q$$i\\E(\\s|$$):" \
			tmp-$$$$ > $@; \
	done; \
	rm -v tmp-$$$$

tags-indict-canonical.lst: tags-indict-sorted.lst
	for i in `cat $<`; do \
		perl -ne "print \$$1, \"\\n\" and exit if m:'($$i)':i" \
			${DICT_DIR}/*.dic; \
	done \
	> $@

looped-blocks.lst:
	perl -00 -ne 'print if /^\s+_list\s+yes/m' ${DICT_DIR}/*.dic \
	> $@

looped-tags.lst: looped-blocks.lst
	perl -ne "print \$$1, \"\n\" if m:\\s_name\\s+'(_[^\\s]+)':" $< \
	| sort | uniq \
	> $@

clean cleanAll distclean:
	rm -f ${LISTS}
