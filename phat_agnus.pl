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
$we_are_here = File::Basename::dirname(Cwd::abs_path($0));
require("$we_are_here/ipf_grammar.pm");

# new images in nested ipf are stacked here (and removed from the argument list)
@main::image_stack = ();
# stack function call args in arrays per nesting level and function call
@main::arg_stack = ();
$main::stack_level = 0;

my ($ipf, $out_image) = @ARGV;

#my $wesnoth_path = $ENV{"WESNOTH_PATH"};
#my $tc_file = join('/', $wesnoth_path, 'data', 'core', 'team-colors.cfg');

%tag_table = (TC => \&to_do_nothing,
	      RC => \&to_do_nothing,
	      PAL => \&to_do_nothing,
	      LIGHTEN => \&to_do_nothing,
	      DARKEN => \&to_do_nothing,
	      NOP => \&do_nothing,
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
	      MASK => \&do_mask,
	      BG  => \&do_background,
    );

#parse_tc_cfg($tc_file);

parse_ipf($ipf);

print "@main::image_stack\n";

# just png, or just the png extension defaults to 24bit png, i.e. just rgb, which fills the alpha with 1
$main::image_stack[0]->Write(filename => "png32:$out_image");

sub read_image
{
    my ($img) = @_;

    my $i = Image::Magick->new();
    $main::error = $i->Read($img);
    unshift @main::image_stack, $i;

    warn $main::error if $main::error;

    print "\t[@image_stack]\n";
}

sub to_do_nothing
{
    print "not implemented yet\n";

    return;
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
	'ipf:FILENAME_IPF', '[^\~\(\)\s,]+' , sub { $lexer->start('pf'); $_[1] },
	'i:FILENAME_I', '[^\~\(\)\s,]+' , sub { $lexer->start('pf'); $_[1] },
	'pf:FUNCCALL', '~', sub {$_[1] },
	'pf:FUNCTION_IPF', 'BLIT|MASK', sub {$lexer->start('ipf'); $_[1] },
	'pf:FUNCTION_I', 'L', sub {$lexer->start('i'); $_[1] },
	'pf:FUNCTION', 'TC|RC|PAL|FL|GS|CROP|CS|R|G|B[^LG]|SCALE|O|BL|LIGHTEN|DARKEN|BG|NOP', sub { $_[1] },
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

