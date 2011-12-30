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

use Cwd;
use File::Basename;
$main::we_are_here = File::Basename::dirname(Cwd::abs_path($0));
require("$main::we_are_here/paula.pm");

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
    $wesnoth_path = '/usr/share/wesnoth';
}

push @main::wesnoth_paths, join('/', $wesnoth_path, 'images');
push @main::wesnoth_paths, join('/', $wesnoth_path, 'data', 'core', 'images');
my $tc_file = join('/', $wesnoth_path, 'data', 'core', 'team-colors.cfg');

package Phat_Agnus::color;
use POSIX qw(floor);
sub new_from_str
{
    my ($cstr) = @_;
    my $color = {};

    $cstr =~ m/([0-9A-F][0-9A-F])([0-9A-F][0-9A-F])([0-9A-F][0-9A-F])/;
    
    @{$color}{('red', 'green', 'blue')} = map { hex($_) } ($1, $2, $3);

    $color->{'cstr'} = $cstr;

    return bless $color, __PACKAGE__;
}

sub new_from_rgb
{
    my ($r, $g, $b) = @_;
    my $color = {};

    @{$color}{('red', 'green', 'blue')} = map { int($_ + 0.5) } ($r, $g, $b);

    $color->{'cstr'} = sprintf('%02X%02X%02X', @{$color}{('red', 'green', 'blue')});

    return bless $color, __PACKAGE__;
}

sub new_from_rgb_norm
{
    my ($r, $g, $b) = @_;
 
    return new_from_rgb(map { $_ * 255 } ($r, $g, $b));
}

sub get_avg
{
    my ($this) = @_;

    return floor(($this->{'red'} + $this->{'green'} + $this->{'blue'}) / 3);
}

package Phat_Agnus::color_range;
sub new
{
    my ($mid, $max, $min, $rep) = @_;
    my $color_range = {};

    $color_range->{'mid'} = Phat_Agnus::color::new_from_str($mid);
    $color_range->{'max'} = Phat_Agnus::color::new_from_str($max);
    $color_range->{'min'} = Phat_Agnus::color::new_from_str($min);
    $color_range->{'rep'} = Phat_Agnus::color::new_from_str($rep);
    
    return bless $color_range, __PACKAGE__;
}

package Phat_Agnus::color_palette;
sub new
{
    my (@colors) = @_;
    my $color_palette = [];

    for $c (@colors) {
	push @$color_palette, Phat_Agnus::color::new_from_str($c);
    }

    return bless $color_palette, __PACKAGE__;
}

package main;

%tag_table = (NOP => \&do_nothing,
	      TC => \&do_teamcolor,
	      RC => \&do_recolor,
	      PAL => \&do_palette_switch,
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
Paula::init_lexer();
parse_tc_cfg($tc_file);
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

    print STDERR "ERROR: image $img couldn't be found directly nor in @main::wesnoth_paths\n";

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

sub recolor_range
{
    my ($tgt_range, $src_palette) = @_;
    my ($c, $old_avg, $ref_avg, $new_r, $new_g, $new_b, %recolor_palette);
    %recolor_palette = ();
    $ref_avg = $src_palette->[0]->get_avg();

    for $c (@$src_palette) {
	$old_avg = $c->get_avg();
	if (($ref_avg > 0) && ($old_avg <= $ref_avg)) {
	    $old_rat = $old_avg / $ref_avg;
	    $new_r = ($old_rat * $tgt_range->{'mid'}->{'red'}   + (1 - $old_rat) * $tgt_range->{'min'}->{'red'});
	    $new_g = ($old_rat * $tgt_range->{'mid'}->{'green'} + (1 - $old_rat) * $tgt_range->{'min'}->{'green'});
	    $new_b = ($old_rat * $tgt_range->{'mid'}->{'blue'}  + (1 - $old_rat) * $tgt_range->{'min'}->{'blue'});
	} elsif ($ref_avg < 255) {
	    $old_rat = (255 - $old_avg) / (255 - $ref_avg);
	    $new_r = ($old_rat * $tgt_range->{'mid'}->{'red'}   + (1 - $old_rat) * $tgt_range->{'max'}->{'red'});
	    $new_g = ($old_rat * $tgt_range->{'mid'}->{'green'} + (1 - $old_rat) * $tgt_range->{'max'}->{'green'});
	    $new_b = ($old_rat * $tgt_range->{'mid'}->{'blue'}  + (1 - $old_rat) * $tgt_range->{'max'}->{'blue'});
	} else {
	    die "something went wrong with the color ranges";
	}

	$new_r = 255 if ($new_r > 255);
	$new_g = 255 if ($new_g > 255);
	$new_b = 255 if ($new_b > 255);

	$recolor_palette{$c->{'cstr'}} = Phat_Agnus::color::new_from_rgb($new_r, $new_g, $new_b);
    }

    return \%recolor_palette;
}

sub vodo_recolor
{
    my ($mapping) = @_;
    my ($r, $g, $b, $a);
    my ($iw, $ih);
    my ($w, $h) = $main::image_stack[0]->Get('columns', 'rows');

    my @pixels = $main::image_stack[0]->GetPixels(width => $w, height => $h, map => 'RGBA', normalize => 'true');

    for ($iw = 0; $iw < $w; ++$iw) {
	for ($ih = 0; $ih < $h; ++$ih) {
	    my $idx = ($iw * 4) + ($ih * $w * 4); # * 4 => RGBA
	    $a = $pixels[$idx+3];
	    next if (!$a);
	    $r = $pixels[$idx+0];
	    $g = $pixels[$idx+1];
	    $b = $pixels[$idx+2];
	    $cstr = Phat_Agnus::color::new_from_rgb_norm($r, $g, $b)->{'cstr'};
	    if (defined $mapping->{$cstr}) {
		@new_colors = map { $_ / 255 } (@{$mapping->{$cstr}}{('red', 'green', 'blue')});
		$main::image_stack[0]->SetPixel(geometry => sprintf('0x0+%d+%d', $iw, $ih), color => [@new_colors, $a]);
	    }
	}
    }
}

sub do_teamcolor
{
    my ($tn, $src_palette) = @_;

    $src_palette = $main::color_palettes->{$src_palette};
    my $tgt_range = $main::color_ranges->{$tn};

    my $mapping = recolor_range($tgt_range, $src_palette);

    vodo_recolor($mapping);
}

sub do_recolor
{
    my ($mapstr) = @_;

    my ($src_palette, $tgt_range) = split('>', $mapstr);
    
    $src_palette = $main::color_palettes->{$src_palette};
    $tgt_range   = $main::color_ranges->{$tgt_range};

    my $mapping = recolor_range($tgt_range, $src_palette);

    vodo_recolor($mapping);
}

sub do_palette_switch
{
    my ($mapstr) = @_;
    my $mapping = {};
    my ($src_palette, $tgt_palette) = split('>', $mapstr);

    $src_palette = $main::color_palettes->{$src_palette};
    $tgt_palette = $main::color_palettes->{$tgt_palette};

    @{$mapping}{map { $_->{'cstr'} } @$src_palette} = @$tgt_palette;

    vodo_recolor($mapping);
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
    my ($iw, $ih);
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

sub parse_ipf
{
    my ($ipf) = @_;  

    Paula::parse_wml($ipf, ('start' => 'ipf'));
}

sub parse_tc_cfg
{
    my ($tc_file) = @_;
    my ($crn, @range, @palette);

    open($wml, "<$tc_file");
    my $tc_cfg = Paula::parse_wml($wml, ('start' => 'wml'));
    close($wml);

    # extract color ranges, and remap rgb string to array
    for $crn (@{$tc_cfg->{'_children'}->{'[color_range]'}}) {
	$crn = $crn->{_wml};
	@range = split('\s*,\s*', $crn->{'rgb'});
	$main::color_ranges->{$crn->{'id'}} = Phat_Agnus::color_range::new(@range);
    }

    # extract color palettes, remap color strings to array
    my $color_palettes = $tc_cfg->{'_children'}->{'[color_palette]'}->[0]->{_wml};
    for $cpk (keys(%$color_palettes)) {
	@palette = split('\s*,\s*', $color_palettes->{$cpk});
	$main::color_palettes->{$cpk} =  Phat_Agnus::color_palette::new(@palette);
    }
}
