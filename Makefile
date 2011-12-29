EDITOR=emacs

PRJ_FILES=Makefile ipf.yp phat_agnus.pl paula.pm wml.yp
GRAMMAR_FILES=ipf_grammar.pm wml_grammar.pm
GIT_FILES=$(PRJ_FILES) $(GRAMMAR_FILES)

.PHONY: edit gitadd gitcommit gitpush

all: $(GRAMMAR_FILES)

%.pm: %.yp
	yapp -m $(^:.pm=) -o $@ $^

wml_grammar.pm: wml.yp
	yapp -v -s -m wml_grammar -o wml_grammar.pm $^

edit: $(PRJ_FILES)
	$(EDITOR) $^

gitadd: $(GIT_FILES)
	git add $^

gitcommit: gitadd
	git commit

gitpush: gitcommit
	git push -u origin master
