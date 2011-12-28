EDITOR=emacs

PRJ_FILES=Makefile ipf.yp phat_agnus.pl paula.pm wml.yp
GIT_FILES=$(PRJ_FILES) ipf_grammar.pm wml_grammar.pm

.PHONY: edit gitadd gitcommit gitpush

%.pm: %.yp
	yapp -m $(^:.pm=) -o $@ $^

ipf_grammar.pm: ipf.yp
	yapp -m ipf_grammar -o ipf_grammar.pm $^
wml_grammar.pm: wml.yp
	yapp -m wml_grammar -o wml_grammar.pm $^

edit: $(PRJ_FILES)
	$(EDITOR) $^

gitadd: $(GIT_FILES)
	git add $^

gitcommit: gitadd
	git commit

gitpush: gitcommit
	git push -u origin master
