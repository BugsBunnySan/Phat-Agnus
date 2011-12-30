package Paula::tag_node;

sub new
{
    my ($name, $parent) = @_;

    return bless {_name     => $name,
		  _parent   => $parent,
		  _children => {},
		  _wml      => {}
    }, __PACKAGE__;
}

################
package Paula; #
################

# Wesnoth WML parser
# 

use Parse::Lex;
use Data::Dumper;
require("$main::we_are_here/wml_grammar.pm");

$Paula::pp_defs = {};
$Paula::tag_tree = {'WML' => Paula::tag_node::new('WML', undef)};
$Paula::current_tag = $Paula::tag_tree->{'WML'};
$Paula::tag_mode = undef;

sub init_wml
{
    $Paula::pp_defs = {};
    $Paula::tag_tree = {'WML' => Paula::tag_node::new('WML', undef)};
    $Paula::current_tag = $Paula::tag_tree->{'WML'};
    $Paula::tag_mode = undef;
}



sub init_lexer
{
    my @token = (
	# wml
	'wml:PP_IFDEF', '^#ifdef', sub { $lexer->start('pp_ifdef'); $_[1] },
	'wml:PP_ENDIF_WML', '^#endif', sub { $_[1] }, 
	'wml:HASH', '#', sub { $lexer->start('wml_skip'); $_[1] }, 
	'wml_skip:WML_SKIP', '.+', sub { $_[1] },
	'wml_skip:NEWLINE_SKIP', '\n|\r\n|\n\r|\r', sub { $lexer->start('wml'); '' },
	'wml:VAREQUALSTEXT', '\w+=.+', sub { $_[1] },
	'wml:VAREQUALS', '\w+=', sub { $_[1] },
	'wml:VAR', '\w+', sub { $_[1] },
	'wml:EQUALS', '=', sub { $_[1] },
	'wml:NEWLINE', '\n|\r\n|\n\r|\r', sub { $lexer->start('wml'); '' },
	'wml:OPEN_TAG', '\[\w+\]', sub { $_[1] },
	'wml:ADD_TAG', '\[\+\w+\]', sub { $_[1] },
	'wml:CLOSE_TAG', '\[/\w+\]', sub { $_[1] },
	'wml:TEXT', '[^\n|\r\n|\n\r|\r]+', sub { $_[1] },
	'pp_ifdef:PP_DEF', '\w+', sub { if (!defined $main::pp_defs->{$_[1]}) { $lexer->start('pp_skip'); $_[1]; } else { $lexer->start('wml'); $_[1]; } },
	'pp_skip:PP_ENDIF_SKIP', '^#endif', sub { $lexer->start('wml'); $_[1] }, 
	'pp_skip:PP_SKIP', '.+', sub { $_[1] },
	# imagepathfoo
	'ipf:FILENAME_IPF', '[^\~\(\)\s,]+' , sub { $lexer->start('pf'); $_[1] },
	'i:FILENAME_I', '[^\~\(\)\s,]+' , sub { $lexer->start('pf'); $_[1] },
	'pf:FUNCCALL', '~', sub {$_[1] },
	'pf:FUNCTION_IPF', 'BLIT|MASK', sub {$lexer->start('ipf'); $_[1] },
	'pf:FUNCTION', 'TC|RC|PAL|FL|GS|CROP|CS|R|G|B[^LG]|SCALE|O|BL|LIGHTEN|DARKEN|BG|NOP', sub { $_[1] },
	'pf:FUNCTION_I', 'L', sub {$lexer->start('i'); $_[1] },
	'ipf:OPENC_IPF', '\\(', sub { ++$main::stack_level; $main::arg_stack[$main::stack_level] = []; $_[1] },
	'i:OPENC_I', '\\(', sub { ++$main::stack_level; $main::arg_stack[$main::stack_level] = []; $_[1] },
	'pf:OPENC', '\\(', sub { ++$main::stack_level; $main::arg_stack[$main::stack_level] = []; $_[1] },
	'pf:COMMA', '\s*,\s*', sub { $_[1] },
	'pf:CLOSEC', '\\)', sub { $_[1] },
	'pf:ARG', '[^)\s,]+', sub { $_[1] },
	'ERROR', '.*', sub { die "no idea what $_[1] means\n" }

    );

    Parse::Lex->exclusive('wml', 'wml_skip', 'pp_ifdef', 'pp_skip', 'pf', 'ipf', 'i');
    $Paula::lexer = Parse::Lex->new(@token);
}

sub print_tag_tree
{
    print Dumper($Paula::tag_tree);
}

sub set_current_tag
{
    my ($tag, $mode) = @_;

    #print "\tcurrent $Paula::current_tag->{_name}\n";
    my $new_node =  Paula::tag_node::new($tag, $Paula::current_tag);
    if (!defined $Paula::current_tag->{_children}->{$tag}) {
	$Paula::current_tag->{_children}->{$tag} = [];
    }
    push @{$Paula::current_tag->{_children}->{$tag}}, $new_node;
    
    $Paula::current_tag = $new_node;

    #print "\topened $Paula::current_tag->{_name}\n";
}

sub close_current_tag
{
    #print "\tclosing $Paula::current_tag->{_name}\n";
    #print Dumper($Paula::tag_tree);
    $Paula::current_tag = $Paula::current_tag->{_parent};
    #print "\tcurrent $Paula::current_tag->{_name}\n";
}

sub assign
{
    my ($var, $text) = @_;

    $Paula::current_tag->{_wml}->{$var} = $text;
}

sub parse_lexer
{
    my ($token) = $Paula::lexer->next;
    if ($Paula::lexer->eoi) {
	return ('', undef);
    } else {
	#print $token->name .' '. $token->text ."\n";
	return ($token->name, $token->text);
    }
}

sub parse_error
{
    my ($cur_token, $cur_value, @expected);
    $cur_token = $_[0]->YYCurtok();
    $cur_value = $_[0]->YYCurval();
    @expected  = $_[0]->YYExpect;

    $cur_value = '<undef>' if (!defined $cur_value);

    print STDERR "\tError parsing: Expected (@expected); got: $cur_token '$cur_value'\n";
}

sub parse_wml
{
    my ($wml, @inopts) = @_;
    my %opts = (('start' => 'wml'), @inopts);

    $Paula::lexer->from($wml);
    $Paula::lexer->start($opts{'start'});
    
    $parser = new wml_grammar();
    $parser->YYParse(yylex => \&parse_lexer, yyerror => \&parse_error);
    
    if ($opts{'start'} eq 'wml') {
	return $Paula::tag_tree->{'WML'};
    } else {
	return {};
    }
}

return 1;
