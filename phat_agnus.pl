#!/usr/bin/perl -w

# Phat Agnus
# Wesnoth ImagePathFunction WML aproximaplementation
# Named in honor of a chip that blited more awesomeness onto the screen than any other chip ever
#
# Copyright (c) 2011 Sebastian Haas
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY.

# See the COPYING file for more details.

use Image::Magick;
use Data::Dumper;
use Parse::Lex;

use Cwd;
use File::Basename;
$main::we_are_here = File::Basename::dirname(Cwd::abs_path($0));
require("$main::we_are_here/ipf_grammar.pm");
#require("$main::we_are_here/paula.pm");

# new images in nested ipf are stacked here (and removed from the argument list)
@main::image_stack = ();
# stack function call args in arrays per nesting level and function call
@main::arg_stack = ();
$main::stack_level = 0;

my $wesnoth_path;
@main::wesnoth_paths = ();

if (defined $ENV{"WESNOTH_PATH"}) {
    $wesnoth_path = $ENV{"WESNOTH_PATH"};
} else {
    $wesnoth_path = '/usr/local/share/wesnoth';
}

push @main::wesnoth_paths, join('/', $wesnoth_path, 'images');
push @main::wesnoth_paths, join('/', $wesnoth_path, 'data', 'core', 'images');
my $tc_file = join('/', $wesnoth_path, 'data', 'core', 'team-colors.cfg');
#parse_tc_cfg($tc_file);

%tag_table = (TC => \&to_do_nothing,
	      PAL => \&to_do_nothing,
	      NOP => \&do_nothing,
	      RC => \&do_recolor,
	      CS => \&do_color_shift,
	      R => \&do_r_shift,
	      G => \&do_g_shift,
	      B => \&do_b_shift,
	      GS => \&do_grayscale,
	      L => \&do_lightmap,
	      O => \&do_opacity,
	      BL => \&do_blur,
	      FL => \&do_flipflop,
	      CROP => \&do_crop,
	      SCALE => \&do_scale,
	      BLIT => \&do_blit,
	      LIGHTEN => \&do_lighten,
	      DARKEN => \&do_darken,
	      MASK => \&do_mask,
	      BG  => \&do_background,
    );

my ($ipf, $out_image) = @ARGV;

parse_ipf($ipf);

print "@main::image_stack\n";

# just png, or just the png extension defaults to 24bit png, i.e. just rgb, which fills the alpha with 1
$main::image_stack[0]->Write(filename => "png32:$out_image");

# searches the binary_paths for the img
# returns first one found
sub find_img
{
    my ($img) = @_;

    for $p (@main::wesnoth_paths) {
	$test_img = join('/', $p, $img);
	return $test_img if (-f $test_img);
    }

    return undef;
}

sub read_image
{
    my ($uimg) = @_;

    if (! -f $uimg) {
	$img = find_img($uimg);
    } else {
	$img = $uimg;
    }

    my $i = Image::Magick->new();
    $main::error = $i->Read($img);
    unshift @main::image_stack, $i;

    warn $main::error if $main::error;

    print "\t[@image_stack]\n";
}

sub to_do_nothing
{
    print "\t<<not implemented yet>>\n";

    return;
}

sub do_nothing
{
    return;
}

sub do_recolor
{
    my ($mapstr) = @_;

    my ($map_src, $map_tgt) = split('>', $mapstr);

    #my $mapping = mk_color_range($map_src, $map_tgt);

    
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

    $main::error = $main::image_stack[0]->ColorMatrix(matrix => $matrix);
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
    $main::error = $main::image_stack[0]->Quantize(colorspace => 'gray');
}

sub do_lightmap
{
    my ($r, $g, $b, $a);
    my ($w, $h) = $main::image_stack[1]->Get('columns', 'rows');

    $main::image_stack[0]->Scale(width => $w, height => $h);

    my @lightmap_pixels = $main::image_stack[0]->GetPixels(width => $w, height => $h, map => 'RGBA', normalize => 'true');
    my @image_pixels    = $main::image_stack[1]->GetPixels(width => $w, height => $h, map => 'RGBA', normalize => 'true');

    for ($iw = 0; $iw < $w; ++$iw) {
	for ($ih = 0; $ih < $h; ++$ih) {
	    my $idx = ($iw * 4) + ($ih * $w * 4); # * 4 => RGBA
	    # "The formula is (x-128)*2, which means that 0 gives -256, 128 gives 0 and 255 gives 254 (wesnoth wiki)"
	    $r = $image_pixels[$idx+0] + ($lightmap_pixels[$idx+0] - 0.50196) * 2;
	    $g = $image_pixels[$idx+1] + ($lightmap_pixels[$idx+1] - 0.50196) * 2;
	    $b = $image_pixels[$idx+2] + ($lightmap_pixels[$idx+2] - 0.50196) * 2;
	    $a = $image_pixels[$idx+3];
	    $r = $r > 1 ? 1 : $r < 0 ? 0 : $r;
	    $g = $g > 1 ? 1 : $g < 0 ? 0 : $g;
	    $b = $b > 1 ? 1 : $b < 0 ? 0 : $b;
	    $main::image_stack[1]->SetPixel(geometry => sprintf('0x0+%d+%d', $iw, $ih), color => [$r, $g, $b, $a]);
	}
    }
    
    shift @main::image_stack;
}

sub do_opacity
{
    my ($o) = @_;

    if ($o =~ m/(\d+)%/) {
	$o /= 100.0;
    }

    my $matrix = [ 1,  0,  0,  0,  0,  0,
		   0,  1,  0,  0,  0,  0,
		   0,  0,  1,  0,  0,  0,
		   0,  0,  0, $o,  0,  0,
                   0,  0,  0,  0,  1,  0,
                   0,  0,  0,  0,  0,  0,
	];

    $main::error = $main::image_stack[0]->ColorMatrix(matrix => $matrix);
}

sub do_blur
{
    my ($radius) = @_;
    my ($w, $h) = $main::image_stack[0]->Get('columns', 'rows');

    # this looks almost, but not quite, entirely unlike the wesnoth blur, the amount is about the same...
    $main::error = $main::image_stack[0]->Blur(geometry => sprintf('%dx%d', $w, $h), channel => 'all', radius => $radius);
}

sub do_flipflop
{
    my ($dir) = @_;

    if ((!defined $dir) || ($dir =~ m/.*horiz.*/)) {
	$main::error = $main::image_stack[0]->Flop();
    } else {
	$main::error = $main::image_stack[0]->Flip();
    }    
}

sub do_crop
{
    my ($x, $y, $w, $h) = @_;

    $main::error = $main::image_stack[0]->Crop(geometry => sprintf('%dx%d+%d+%d', $w, $h, $x, $y));
}

sub do_scale
{
    my ($w, $h) = @_;

    $main::error = $main::image_stack[0]->Scale(width => $w, height => $h);
}

sub do_blit
{
    my ($x, $y) = @_;

    $main::error = $main::image_stack[1]->Composite(image => $main::image_stack[0], 
				     geometry => sprintf('0x0+%d+%d', $x, $y), compose => 'Over');    
    
    shift @main::image_stack;
}

sub do_lighten
{
    read_image("misc/tod-bright.png");

    do_blit(0, 0);
}

sub do_darken
{
    read_image("misc/tod-dark.png");

    do_blit(0, 0);
}

sub do_mask
{
    my ($x, $y) = @_;
    $x = 0 if (!defined $x);
    $y = 0 if (!defined $y);

    $main::error = $main::image_stack[1]->Composite(image => $main::image_stack[0], 
						    geometry => sprintf('0x0+%d+%d', $x, $y), compose => 'CopyOpacity', mask => $main::image_stack[1]);

    shift @main::image_stack;
}

sub do_background
{
    my ($r, $g, $b) = @_;
    my ($w, $h) = $main::image_stack[0]->Get('columns', 'rows');

    my $bg_img = Image::Magick->new();
    $bg_img->Set(size => sprintf('%dx%d', $w, $h));
    $bg_img->ReadImage(sprintf('canvas:rgb(%d, %d, %d)', $r, $g, $b));

    $main::error = $bg_img->Composite(image => $main::image_stack[0], 
				      geometry => '0x0+0+0', compose => 'Over');

    $main::image_stack[0] = $bg_img;    
}

sub do_tag 
{
    my ($tag, $args) = @_;
    my @args = (); 
    @args = split('\s*,\s*', $args) if $args;

    print "\t$stack_level call $tag(@args)\n";
    print "\t[@image_stack]\n";

    $tag_table{$tag}->(@args);

    $arg_stack[$stack_level] = []; --$stack_level;

    warn $main::error if $main::error;
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

sub parse_lexer
{
    my $lexer = $_[0]->YYLexer();

    my ($token) = $lexer->next;
    if ($lexer->eoi) {
	return ('', undef);
    } else {
	print $token->name .' '. $token->text ."\n";
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

sub parse_ipf
{
    my ($ipf) = @_;  
    my $lexer = $_[0]->YYLexer();

    my @token = (
	'ipf:FILENAME_IPF', '[^\~\(\)\s,]+' , sub { $lexer->start('pf'); $_[1] },
	'i:FILENAME_I', '[^\~\(\)\s,]+' , sub { $lexer->start('pf'); $_[1] },
	'pf:FUNCCALL', '~', sub {$_[1] },
	'pf:FUNCTION_IPF', 'BLIT|MASK', sub {$lexer->start('ipf'); $_[1] },
	'pf:FUNCTION', 'TC|RC|PAL|FL|GS|CROP|CS|R|G|B[^LG]|SCALE|O|BL|LIGHTEN|DARKEN|BG|NOP', sub { $_[1] },
	'pf:FUNCTION_I', 'L', sub {$lexer->start('i'); $_[1] },
	'ipf:OPENC_IPF', '\\(', sub { ++$stack_level; $arglist[$stack_level] = []; $_[1] },
	'i:OPENC_I', '\\(', sub { ++$stack_level; $arglist[$stack_level] = []; $_[1] },
	'pf:OPENC', '\\(', sub { ++$stack_level; $arglist[$stack_level] = []; $_[1] },
	'pf:COMMA', '\s*,\s*', sub { $_[1] },
	'pf:CLOSEC', '\\)', sub { $_[1] },
	'pf:ARG', '[^)\s,]+', sub { $_[1] },
	'ERROR', '.*', sub { die "no idea what $_[1] means\n" }
	);

    Parse::Lex->exclusive('pf', 'ipf', 'i');
    $lexer = Parse::Lex->new(@token);
    
    $lexer->from($ipf);
    $lexer->start('ipf');
    
    $parser = new ipf_grammar();
    $parser->YYParse(yylex => \&parse_lexer, yyerror => \&parse_error);
}
