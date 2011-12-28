################
package Paula; #
################

# Wesnoth WML parser
# 

use Parse::Lex;
require("$main::we_are_here/wml_grammar.pm");

$Paula::pp_defs = {};
@Paula::tag_stack = ();
@Paula::tag_mode = undef;

$Paula::parsed_wml = {};

sub finalize_tag
{
    
}

sub parse_wml
{
    my ($wml) = @_;
    my $lexer = $_[0]->YYLexer();

    my @token = {
	'wml:PP_IFDEF', '^#ifdef', sub { $lexer->start('pp_ifdef'); $_[1] },
	'wml:PP_ENDIF_WML', '^#endif', sub { $_[1] }, 
	'wml:HASH', '#', sub { $lexer->start('wml_skip'); $_[1] }, 
	'wml_skip:WML_SKIP', '.+', sub { $_[1] },
	'wml_skip:NEWLINE', '\n|\r\n|\n\r|\r', sub { $lexer->start('wml'), $_[1] },
	'wml:VAR', '\w+', sub { $_[1] },
	'wml:EQUALS', '=', sub { $_[1] },
	'wml:VAREQUALS', 
	'pp_ifdef:PP_DEF', '\w+', sub { if (!defined $main::pp_defs->{$_[1]}) { $lexer->start('pp_skip'); $_[1]; } else { $lexer->start('wml'); $_[1]; } },
	'pp_skip:PP_ENDIF_SKIP', '^#endif', sub { $lexer->start('wml'); $_[1] }, 
	'pp_skip:PP_SKIP', '.+', sub { $_[1] },

    };

    #Parse::Lex->exclusive();
    $lexer = Parse::Lex->new(@token);
    
    $lexer->from($wml);
    $lexer->start();
    
    $parser = new wml_grammar();
    $parser->YYParse(yylex => \&parse_lexer, yyerror => \&parse_error);
}
