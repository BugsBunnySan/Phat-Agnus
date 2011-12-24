
ipf_grammar.pm: ipf.yp
	yapp -m ipf_grammar -o ipf_grammar.pm $^

gitadd: ipf_grammar.pm Makefile ipf.yp phat_agnus.pl
	git add $^
