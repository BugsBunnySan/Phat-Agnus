#!/usr/bin/perl -w

use Image::Magick;
use Data::Dumper;
use Parse::Lex;

use Cwd;
use File::Basename;
$we_are_here = File::Basename::dirname(Cwd::abs_path($0));
require("$we_are_here/ipf_grammar.pm");

@main::image_stack = ();
@main::arg_stack = ();
$main::stack_level = 0;

my $wesnoth_path = $ENV{"WESNOTH_PATH"};
my ($ipf, $out_image) = @ARGV;

my $tc_file = join('/', $wesnoth_path, 'data', 'core', 'team-colors.cfg');

%tag_table = (TC => \&do_nothing,
	      RC => \&do_nothing,
	      PAL => \&do_nothing,
	      L => \&do_nothing,
	      O => \&do_nothing,
	      LIGHTEN => \&do_nothing,
	      DARKEN => \&do_nothing,
	      BG  => \&do_nothing,
	      GS => \&do_grayscale,
	      CS => \&do_color_shift,
	      R => \&do_r_shift,
	      G => \&do_g_shift,
	      B => \&do_b_shift,
	      BL => \&do_blur,
	      FL => \&do_flip,
	      CROP => \&do_crop,
	      SCALE => \&do_scale,
	      BLIT => \&do_blit,
	      MASK => \&do_mask,
	      NOP => \&do_nothing,
    );

parse_tc_cfg($tc_file);

parse_ipf($ipf);

print "@main::image_stack\n";

$main::image_stack[0]->Write(filename => "$out_image");

sub read_image
{
    my ($img) = @_;

    my $i = Image::Magick->new();
    $i->Read($img);
    unshift @main::image_stack, $i;
}

sub do_nothing
{
    return;
}

sub do_color_shift
{
    my ($r, $g, $b) = @_;
    $r = 0 if (!defined $r);
    $g = 0 if (!defined $g);
    $b = 0 if (!defined $b);

    $r /= 255.0; $g /= 255.0; $b /= 255.0;

    my $matrix = [ 1,  0,  0,  0,  0, $r,
		   0,  1,  0,  0,  0, $g,
		   0,  0,  1,  0,  0, $b,
		   0,  0,  0,  1,  0,  0,
                   0,  0,  0,  0,  1,  0,
                   0,  0,  0,  0,  0,  1,
	];

    $main::image_stack[0]->ColorMatrix(matrix => $matrix);

}

sub do_r_shift
{
    my ($r) = @_;

    do_color_shift($r, 0, 0);
}

sub do_g_shift
{
    my ($g) = @_;

    do_color_shift(0, $g, 0);
}

sub do_b_shift
{
    my ($b) = @_;

    do_color_shift(0, 0, $b);
}

sub do_grayscale
{
    $main::image_stack[0]->Quantize(colorspace => 'gray');
}

sub do_blur
{
    my ($radius) = @_;
    my ($w, $h) = $main::image_stack[0]->Get('columns', 'rows');

    # this looks not at all like the wesnoth blur, the amount is about the same, but they use a weird blur function
    $main::image_stack[0]->Blur(geometry => sprintf('%dx%d', $w, $h), channel => 'all', radius => $radius);
}

sub do_flip
{
    my ($dir) = @_;

    if ($dir =~ m/.*horiz.*/) {
	$main::error = $main::image_stack[0]->Flop();
    } else {
	$main::error = $main::image_stack[0]->Flip();
    }    
}

sub do_crop
{
    my ($x, $y, $w, $h) = @_;

    $main::image_stack[0]->Crop(geometry => sprintf('%dx%d+%d+%d', $x, $y, $w, $h));
}

sub do_scale
{
    my ($w, $h) = @_;

    $main::image_stack[0]->Scale(width=>$w, height=>$h);
}

sub do_blit
{
    my ($x, $y) = @_;

    $main::image_stack[1]->Composite(image=>$main::image_stack[0], 
				     geometry=>sprintf('0x0+%d+%d', $x, $y), compose => 'Over');

    shift @main::image_stack;
}

sub do_mask
{
    my ($x, $y) = @_;
    $x = 0 if (!defined $x);
    $y = 0 if (!defined $y);

    $main::image_stack[1]->Composite(image=>$main::image_stack[0], 
				     geometry=>sprintf('0x0+%d+%d', $x, $y), compose => 'CopyOpacity', mask => $main::image_stack[1]);

    shift @main::image_stack;
}

sub do_empty_tag
{
    my ($tag) = @_;
    my (@args) = ();


    if ($tag eq 'FL') {
	@args = ("horizontal");
    }
    
    print "\t$stack_level call $tag(@args)\n";
    print "\t[@image_stack]\n";

    $tag_table{$tag}->(@args);
    
    $arg_stack[$stack_level] = []; --$stack_level;

    print "$main::error\n" if $main::error;

}

sub do_tag 
{
    my ($tag, $args) = @_;

    my @args = split('\s*,\s*', $args);

    print "\t$stack_level call $tag(@args)\n";
    print "\t[@image_stack]\n";

    $tag_table{$tag}->(@args);

    $arg_stack[$stack_level] = []; --$stack_level;

    print "$main::error\n" if $main::error;
}

sub push_arg
{
    my ($arg) = @_;

    push @{$arg_stack[$stack_level]}, $arg;
}

sub get_args
{
    return join(',', reverse(@{$arg_stack[$stack_level]}));
}

sub ipf_lexor
{
    my ($token) = $lexer->next;
    if ($lexer->eoi) {
	return ('', undef);
    } else {
	print $token->name .' '. $token->text ."\n";
	return ($token->name, $token->text);
    }
}

sub ipf_error
{
    print STDERR "Error parsing line $.\n";
}

sub parse_ipf
{
    my ($ipf) = @_;

    
    
    my @token = (
	'ipf:FILENAME', '[^\~\(\)\s,]+' , sub { $lexer->start('pf'); $_[1] },
	'pf:FUNCCALL', '~', sub {$_[1] },
	'pf:FUNCTION_IPF', 'BLIT|MASK', sub {$lexer->start('ipf'); $_[1] },
	'pf:FUNCTION', 'TC|RC|PAL|FL|GS|CROP|CS|R|G|B[^LG]|L[^I]|SCALE|O|BL|LIGHTEN|DARKEN|BG|NOP', sub { $_[1] },
	'ipf:OPENCIPF', '\\(', sub { ++$stack_level; $arglist[$stack_level] = []; $_[1] },
	'pf:OPENC', '\\(', sub { ++$stack_level; $arglist[$stack_level] = []; $_[1] },
	'pf:COMMA', '\s*,\s*', sub { $_[1] },
	'pf:CLOSEC', '\\)', sub { $_[1] },
	'pf:ARG', '[^)\s,]+', sub { $_[1] },
	'ERROR', '.*', sub { die "no idea what $_[1] means\n" }
	);

    Parse::Lex->exclusive('pf', 'ipf');
    $lexer = Parse::Lex->new(@token);
    
    $lexer->from($ipf);
    $lexer->start('ipf');
    
    $parser = new ipf_grammar();
    $parser->YYParse(yylex => \&ipf_lexor, yyerror => \&ipf_error);
}

sub parse_tc_cfg
{
    my ($file) = @_;

    $parsed = {};

    open(TC_CFG, "<$file") or return $parsed;
    while ($line = <TC_CFG>) {
	chomp($line);
	$line =~ s/#.+$//; # ignore comments
	$line =~ s/^\s*|\s*$//; # strip whitespace
	next if ($line =~ m/^\s*$/); # ignore empty lines
	if ($line =~ s/(\[\w+\])\s*//) {
	    $tag = {_ => $1};
	    push @state, $tag;
	} elsif ($line =~ s/(\[\/\w+\])\s*//) {
	    $parsed->{$tag->{_}}->{$tag->{id}} = pop @state;
	} elsif ($line =~ s/(\w+)\s*=\s*_?\s*(\S+)$//) {
	    $tag->{$1} = $2;
	} else {
	    next;
	}
    }
    close(TC_CFG);

    #print Dumper($parsed);
    return $parsed;
}

