EDITOR=emacs

PRJ_FILES=Makefile README phat_agnus.pl paula.pm wml.yp
GRAMMAR_FILES=wml_grammar.pm
GIT_FILES=$(PRJ_FILES) $(GRAMMAR_FILES) COPYING.txt

.PHONY: edit gitadd gitcommit gitpush

all: $(GRAMMAR_FILES)

%.pm: %.yp
	yapp -m $(^:.pm=) -o $@ $^

wml_grammar.pm: wml.yp
	yapp -v -s -m wml_grammar -o wml_grammar.pm $^

edit: $(PRJ_FILES)
	$(EDITOR) $^

dist:
	mkdir -p Phat-Agnus
	cp $(GIT_FILES) Phat-Agnus/
	tar -v -c -j -f Phat-Agnus.tar.bz2 Phat-Agnus/

gitadd: $(GIT_FILES)
	git add $^

gitcommit: gitadd
	git commit

gitpush: gitcommit
	git push -u origin master
