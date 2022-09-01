#! perl

use strict;
use warnings;
use utf8;

package Text::Layout::PDFAPI2;

use parent 'Text::Layout';
use Carp;
use List::Util qw(max);

my $hb;
my $fc;

#### API
sub new {
    my ( $pkg, @data ) = @_;
    unless ( @data == 1 && ref($data[0]) =~ /^PDF::(API2|Builder)\b/ ) {
	croak("Usage: Text::Layout::PDFAPI2->new(\$pdf)");
    }
    my $self = $pkg->SUPER::new;
    $self->{_context} = $data[0];
    if ( !$fc || $fc->{__PDF__} ne $data[0] ) {
	# Init cache.
	$fc = { __PDF__ => $data[0] };
	Text::Layout::FontConfig->reset;
    }
    $self;
}

# Creates a (singleton) HarfBuzz::Shaper object.
sub _hb_init {
    return $hb if defined $hb;
    $hb = 0;
    eval {
	require HarfBuzz::Shaper;
	$hb = HarfBuzz::Shaper->new;
    };
    return $hb;
}

# Verify if a font needs shaping, and we can do that.
sub _hb_font_check {
    my ( $f ) = @_;
    return $f->{_hb_checked} if defined $f->{_hb_checked};

    if ( $f->get_shaping ) {
	my $fn = $f->to_string;
	if ( $f->{font}->can("fontfilename") ) {
	    if ( _hb_init() ) {
		# warn("Font $fn will use shaping.\n");
		return $f->{_hb_checked} = 1;
	    }
	    carp("Font $fn: Requires shaping but HarfBuzz cannot be loaded.");
	}
	else {
	    carp("Font $fn: Shaping not supported");
	}
    }
    else {
	# warn("Font ", $f->to_string, " does not need shaping.\n");
    }
    return $f->{_hb_checked} = 0;
}

#### API
sub render {
    my ( $self, $x, $y, $text, $fp ) = @_;

    $self->{_lastx} = $x;
    $self->{_lasty} = $y;

    my @bb = $self->get_pixel_bbox;
    my $bl = $bb[0];
    my $align = $self->{_alignment} // 0;
    if ( $self->{_width} ) {
	my $w = $bb[3];
	if ( $w < $self->{_width} ) {
	    if ( $align eq "right" ) {
		$x += $self->{_width} - $w;
	    }
	    elsif ( $align eq "center" ) {
		$x += ( $self->{_width} - $w ) / 2;
	    }
	    else {
		$x += $bb[1];
	    }
	}
    }
    my $upem = 1000;

    foreach my $fragment ( @{ $self->{_content} } ) {
	next unless length($fragment->{text});
	my $x0 = $x;
	my $y0 = $y;
	my $f = $fragment->{font};
	my $font = $f->get_font($self);
	unless ( $font ) {
	    carp("Can't happen?");
	    $f = $self->{_currentfont};
	    $font = $f->getfont($self);
	}
	$text->strokecolor( $fragment->{color} );
	$text->fillcolor( $fragment->{color} );
	$text->font( $font, $fragment->{size} || $self->{_currentsize} );

	if ( _hb_font_check($f) ) {
	    $hb->set_font( $font->fontfilename );
	    $hb->set_size( $fragment->{size} || $self->{_currentsize} );
	    $hb->set_text( $fragment->{text} );
	    $hb->set_direction( $f->{direction} ) if $f->{direction};
	    $hb->set_language( $f->{language} ) if $f->{language};
	    my $info = $hb->shaper($fp);
	    my $y = $y - $fragment->{base} - $bl;
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $w = 0;
	    $w += $_->{ax} for @$info;

	    if ( $fragment->{bgcolor} ) {
		my $y = $y0;
		my $h = -$sz*($font->ascender-$font->descender)/$upem;
		my $x = $x0;
		$text->add(PDF::API2::Content::_save());

		$text->add($text->_fillcolor($fragment->{bgcolor}));
		$text->add($text->_strokecolor($fragment->{bgcolor}));
		$text->add(PDF::API2::Content::_linewidth(2));
		$text->add(PDF::API2::Content::_move($x, $y));
		$text->add(PDF::API2::Content::_line($x+$w, $y));
		$text->add(PDF::API2::Content::_line($x+$w, $y+$h));
		$text->add(PDF::API2::Content::_line($x, $y+$h));
		$text->add('h'); # close
		$text->add('B'); # fillstroke
		$text->add(PDF::API2::Content::_restore());
	    }

	    foreach my $g ( @$info ) {
		$text->translate( $x + $g->{dx}, $y - $g->{dy} );
		$text->glyph_by_CId( $g->{g} );
		$x += $g->{ax};
		$y += $g->{ay};
	    }
	}
	else {
	    printf("%.2f %.2f %.2f \"%s\" %s\n",
		   $x, $y-$fragment->{base}-$bl,
		   $font->width($fragment->{text}) * ($fragment->{size} || $self->{_currentsize}),
		   $fragment->{text},
		   join(" ", $fragment->{font}->{family},
			$fragment->{font}->{style},
			$fragment->{font}->{weight},
			$fragment->{size} || $self->{_currentsize},
			$fragment->{color},
			$fragment->{underline}||'""', $fragment->{underline_color}||'""',
			$fragment->{strikethrough}||'""', $fragment->{strikethrough_color}||'""',
		       ),
		  ) if 0;
	    my $t = $fragment->{text};
	    if ( $t ne "" ) {

		# See ChordPro issue 240.
		if ( $font->issymbol && $font->is_standard ) {
		    # This enables byte access to these symbol fonts.
		    utf8::downgrade( $t, 1 );
		}

		my $y = $y-$fragment->{base}-$bl;
		my $sz = $fragment->{size} || $self->{_currentsize};
		my $w = $font->width($t) * $sz;

		if ( $fragment->{bgcolor} ) {
		    my $y = $y0;
		    my $h = -$sz*($font->ascender-$font->descender)/$upem;
		    my $x = $x0;
		    $text->add(PDF::API2::Content::_save());

		    $text->add($text->_fillcolor($fragment->{bgcolor}));
		    $text->add($text->_strokecolor($fragment->{bgcolor}));
		    $text->add(PDF::API2::Content::_linewidth(2));
		    $text->add(PDF::API2::Content::_move($x, $y));
		    $text->add(PDF::API2::Content::_line($x+$w, $y));
		    $text->add(PDF::API2::Content::_line($x+$w, $y+$h));
		    $text->add(PDF::API2::Content::_line($x, $y+$h));
		    $text->add('h'); # close
		    $text->add('B'); # fillstroke
		    $text->add(PDF::API2::Content::_restore());
		}

		$text->translate( $x, $y );
		$text->text($t);
		$x += $w;
	    }
	}

	next unless $x > $x0;

	my $dw = 1000;
	my $xh = $font->xheight;

	my @strikes;
	if ( $fragment->{underline} && $fragment->{underline} ne 'none' ) {
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $d = -( $f->{underline_position}
		       || $font->underlineposition ) * $sz/$dw;
	    my $h = ( $f->{underline_thickness}
		      || $font->underlinethickness ) * $sz/$dw;
	    my $col = $fragment->{underline_color} // $fragment->{color};
	    if ( $fragment->{underline} eq 'double' ) {
		push( @strikes, [ $d-0.125*$h, $h * 0.75, $col ],
		                [ $d+1.125*$h, $h * 0.75, $col ] );
	    }
	    else {
		push( @strikes, [ $d+$h/2, $h, $col ] );
	    }
	}

	if ( $fragment->{strikethrough} ) {
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $d = -( $f->{strikeline_position}
		       ? $f->{strikeline_position}
		       : 0.6*$xh ) * $sz/$dw;
	    my $h = ( $f->{strikeline_thickness}
		      || $f->{underline_thickness}
		      || $font->underlinethickness ) * $sz/$dw;
	    my $col = $fragment->{strikethrough_color} // $fragment->{color};
	    push( @strikes, [ $d+$h/2, $h, $col ] );
	}

	if ( $fragment->{overline} && $fragment->{overline} ne 'none' ) {
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $h = ( $f->{overline_thickness}
		      || $f->{underline_thickness}
		      || $font->underlinethickness ) * $sz/$dw;
	    my $d = -( $f->{overline_position}
		       ? $f->{overline_position} * $sz/$dw
		       : $xh*$sz/$dw + 2*$h );
	    my $col = $fragment->{overline_color} // $fragment->{color};
	    if ( $fragment->{overline} eq 'double' ) {
		push( @strikes, [ $d-0.125*$h, $h * 0.75, $col ],
		                [ $d+1.125*$h, $h * 0.75, $col ] );
	    }
	    else {
		push( @strikes, [ $d+$h/2, $h, $col ] );
	    }
	}
	for ( @strikes ) {

	    # Mostly copied from PDF::API2::Content::_text_underline.
	    $text->add_post(PDF::API2::Content::_save());

	    $text->add_post($text->_strokecolor($_->[2]));
	    $text->add_post(PDF::API2::Content::_linewidth($_->[1]));
	    $text->add_post(PDF::API2::Content::_move($x0, $y0-$fragment->{base}-$bl-$_->[0]));
	    $text->add_post(PDF::API2::Content::_line($x, $y0-$fragment->{base}-$bl-$_->[0]));
	    $text->add_post(PDF::API2::Content::_stroke());
	    $text->add_post(PDF::API2::Content::_restore());
	}

	if ( $fragment->{href} ) {
	    my $sz = $fragment->{size} || $self->{_currentsize};
	    my $ann = $text->{' apipage'}->annotation;
	    $ann->url( $fragment->{href},
		     #  -border => [ 0, 0, 1 ],
		       -rect => [ $x0, $y0, #-$fragment->{base}-$bl,
		     		  $x, $y0 - $sz ]
		     );
	}
    }
}

#### API
sub bbox {
    my ( $self, $all ) = @_;

    my ( $bl, $x, $y, $w, $h ) = (0) x 4;
    my ( $d, $a ) = (0) x 2;
    my ( $xMin, $xMax, $yMin, $yMax );
    my $dir;

    foreach ( @{ $self->{_content} } ) {
	my $f = $_->{font};
	my $font = $f->get_font($self);
	unless ( $font ) {
	    carp("Can't happen?");
	    $f = $self->{_currentfont};
	    $font = $f->getfont($self);
	}
	my $upem = 1000;	# as delivered by PDF::API2
	my $size = $_->{size};
	my $base = $_->{base};
	my $mydir = $f->{direction} || 'ltr';

	# Width and inkbox, if requested.
	if ( _hb_font_check( $f ) ) {
	    $hb->set_font( $font->fontfilename );
	    $hb->set_size($size);
	    $hb->set_language( $f->{language} ) if $f->{language};
	    $hb->set_direction( $f->{direction} ) if $f->{direction};
	    $hb->set_text( $_->{text} );
	    my $info = $hb->shaper;
	    $mydir = $hb->get_direction;
	    # warn("mydir $mydir\n");

	    if ( $all ) {
		my $ext = $hb->get_extents;
		foreach my $g ( @$info ) {
		    my $e = shift(@$ext);
		    printf STDERR ( "G  %3d  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f\n",
				    $g->{g}, $g->{ax},
				    @$e{ qw( x_bearing y_bearing width height ) } ) if 0;
		    # It is easier to work with the baseline oriented box.
		    $e->{xMin} = $e->{x_bearing};
		    $e->{yMin} = $e->{y_bearing} + $e->{height} - $base;
		    $e->{xMax} = $e->{x_bearing} + $e->{width};
		    $e->{yMax} = $e->{y_bearing} - $base;

		    $xMin //= $w + $e->{xMin} if $e->{width};
		    $yMin = $e->{yMin}
		      if !defined($yMin) || $e->{yMin} < $yMin;
		    $yMax = $e->{yMax}
		      if !defined($yMax) || $e->{yMax} > $yMax;
		    $xMax = $w + $e->{xMax};
		    $w += $g->{ax};
		}
	    }
	    else {
		foreach my $g ( @$info ) {
		    $w += $g->{ax};
		}
	    }
	}
	elsif ( $all && $font->can("extents") ) {
	    my $e = $font->extents( $_->{text}, $size );
	    printf STDERR ("(%.2f,%.2f)(%.2f,%.2f) -> ",
			   $xMin//0, $yMin//0, $xMax//0, $yMax//0 ) if $all && 0;
	    $xMax = $w + $e->{xMax} if $all;
	    $w += $e->{wx};
#	    warn("W \"", $_->{text}, "\" $w, ", $e->{width}, "\n");
	    if ( $all ) {
		$_ -= $base for $e->{yMin}, $e->{yMax};
		# Baseline oriented box.
		$xMin //= $e->{xMin};
		$yMin = $e->{yMin}
		  if !defined($yMin) || $e->{yMin} < $yMin;
		$yMax = $e->{yMax}
		  if !defined($yMax) || $e->{yMax} > $yMax;
		printf STDERR ("(%.2f,%.2f)(%.2f,%.2f)\n",
			       $xMin//0, $yMin//0, $xMax//0, $yMax//0 ) if 0;
	    }
	}
	else {
	    $w += $font->width( $_->{text} ) * $size;
	}

	# We have width. Now the rest of the layoutbox.
	my ( $d0, $a0 );
	if ( !$f->get_interline ) {
	    # Use descender/ascender.
	    # Quite accurate, although there are some fonts that do
	    # not include accents on capitals in the ascender.
	    $d0 = $font->descender * $size / $upem - $base;
	    $a0 = $font->ascender * $size / $upem - $base;
	}
	else {
	    # Use bounding box.
	    # Some (modern) fonts include spacing in the bb.
	    my @bb = map { $_ * $size / $upem } $font->fontbbox;
	    $d0 = $bb[1] - $base;
	    $a0 = $bb[3] - $base;
	}
	# Keep track of biggest decender/ascender.
	$d = $d0 if $d0 < $d;
	$a = $a0 if $a0 > $a;

	# Direction.
	$dir //= $mydir;
	$dir = 0 unless $dir eq $mydir; # mix
    }
    $bl = $a;
    $h = $a - $d;

    my $align = $self->{_alignment};
    # warn("ALIGN: ", $align//"<unset>","\n");
    if ( $self->{_width} && $dir && $w < $self->{_width} ) {
	if ( $dir eq 'rtl' && (!$align || $align eq "left") ) {
	    $align = "right";
	    # warn("ALIGN: set to $align\n");
	}
    }
    if ( $self->{_width} && $align && $w < $self->{_width} ) {
	# warn("ALIGNING...\n");
	if ( $align eq "right" ) {
	    # warn("ALIGNING: to $align\n");
	    $x += my $d = $self->{_width} - $w;
	    $xMin += $d if defined $xMin;
	    $xMax += $d if defined $xMax;
	}
	elsif ( $align eq "center" ) {
	    # warn("ALIGNING: to $align\n");
	    $x += my $d = ( $self->{_width} - $w ) / 2;
	    $xMin += $d if defined $xMin;
	    $xMax += $d if defined $xMax;
	}
    }

    [ $bl, $x, $y-$h, $w, $h,
      defined $xMin ? ( $xMin, $yMin-$bl, $xMax-$xMin, $yMax-$yMin ) : ()];
}

#### API
sub load_font {
    my ( $self, $font, $fd ) = @_;

    if ( $fc->{$font} ) {
	# warn("Loaded font $font (cached)\n");
	return $fc->{$font};
    }
    my $ff;
    if ( $font =~ /\.[ot]tf$/ ) {
	eval {
	    $ff = $self->{_context}->ttfont( $font,
					     -dokern => 1,
					     $fd->{nosubset}
					     ? ( -nosubset => 1 )
					     : (),
					   );
	};
    }
    else {
	eval {
	    $ff = $self->{_context}->corefont( $font, -dokern => 1 );
	};
    }

    croak( "Cannot load font: ", $font, "\n", $@ ) unless $ff;
    # warn("Loaded font: $font\n");
    $self->{font} = $ff;
    $fc->{$font} = $ff;
    return $ff;
}

sub xheight {
    $_[0]->data->{xheight};
}

################ Extensions to PDF::API2 ################

sub PDF::API2::Content::glyph_by_CId {
    my ( $self, $cid ) = @_;
    $self->add( sprintf("<%04x> Tj", $cid ) );
    $self->{' font'}->fontfile->subsetByCId($cid);
}

# HarfBuzz requires a TT/OT font. Define the fontfilename method only
# for classes that HarfBuzz can deal with.
sub PDF::API2::Resource::CIDFont::TrueType::fontfilename {
    my ( $self ) = @_;
    $self->fontfile->{' font'}->{' fname'};
}

# Add extents calculation for CIDfonts.
# Note: Origin is x=0 at the baseline.
sub PDF::API2::Resource::CIDFont::extents {
    my ( $self, $text, $size ) = @_;
    $size //= 1;
    my $e = $self->extents_cid( $self->cidsByStr($text), $size );
    return $e;
}

sub PDF::API2::Resource::CIDFont::extents_cid {
    my ( $self, $text, $size ) = @_;
    my $width = 0;
    my ( $xMin, $xMax, $yMin, $yMax, $bl );

    my $upem = $self->data->{upem};
    my $glyphs = $self->fontobj->{loca}->read->{glyphs};
    $bl = $self->ascender;
    my $lastglyph = 0;
    my $lastwidth;

    # Fun ahead! Widths are in 1000 and xMin and such in upem.
    # Scale to 1000ths.
    my $scale = 1000 / $upem;

    foreach my $n (unpack('n*', $text)) {
        $width += $lastwidth = $self->wxByCId($n);
        if ($self->{'-dokern'} and $self->haveKernPairs()) {
            if ($self->kernPairCid($lastglyph, $n)) {
                $width -= $self->kernPairCid($lastglyph, $n);
            }
        }
        $lastglyph = $n;
	my $ex = $glyphs->[$n];
	unless ( defined $ex && %$ex ) {
	    warn("Missing glyph: $n\n");
	    next;
	}
	$ex->read;

	my $e;
	# Copy while scaling.
	$e->{$_} = $ex->{$_} * $scale for qw( xMin yMin xMax yMax );

	printf STDERR ( "G  %3d  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f\n",
			$n, $lastwidth,
			@$e{ qw( xMin yMin xMax yMax ) } ) if 0;

	$xMin //= ($width - $lastwidth) + $e->{xMin};
	$yMin = $e->{yMin} if !defined($yMin) || $e->{yMin} < $yMin;
	$yMax = $e->{yMax} if !defined($yMax) || $e->{yMax} > $yMax;
	$xMax = ($width - $lastwidth) + $e->{xMax};
    }

    if ( defined $lastwidth ) {
#	$xMax += ($width - $lastwidth);
    }
    else {
	$xMin = $yMin = $xMax = $yMax = 0;
	$width = $self->missingwidth;
    }
    $_ = ($_//0)*$size/1000 for $xMin, $xMax, $yMin, $yMax, $bl;
    $_ = ($_//0)*$size/1000 for $width;

    return { x	     => $xMin,
	     y	     => $yMin,
	     width   => $xMax - $xMin,
	     height  => $yMax - $yMin,
	     # These are for convenience
	     xMin    => $xMin,
	     yMin    => $yMin,
	     xMax    => $xMax,
	     yMax    => $yMax,
	     wx	     => $width,
	     bl      => $bl,
	   };
}

################ Extensions to PDF::Builder ################

sub PDF::Builder::Content::glyph_by_CId {
    my ( $self, $cid ) = @_;
    $self->add( sprintf("<%04x> Tj", $cid ) );
    $self->{' font'}->fontfile->subsetByCId($cid);
}

# HarfBuzz requires a TT/OT font. Define the fontfilename method only
# for classes that HarfBuzz can deal with.
sub PDF::Builder::Resource::CIDFont::TrueType::fontfilename {
    my ( $self ) = @_;
    $self->fontfile->{' font'}->{' fname'};
}

################ For debugging/convenience ################

# Shows the bounding box of the last piece of text that was rendered.
sub showbb {
    my ( $self, $gfx, $x, $y, $col ) = @_;
    $x //= $self->{_lastx};
    $y //= $self->{_lasty};
    $col ||= "magenta";

    my ( $ink, $bb ) = $self->get_pixel_extents;
    my $bl = $bb->{bl};
    # Bounding box, top-left coordinates.
    printf( "Ink:    %6.2f %6.2f %6.2f %6.2f\n",
	    @$ink{qw( x y width height )} );
    printf( "Layout: %6.2f %6.2f %6.2f %6.2f  BL %.2f\n",
	    @$bb{qw( x y width height )}, $bl );

    # NOTE: Some fonts include natural spacing in the bounding box.
    # NOTE: Some fonts exclude accents on capitals from the bounding box.

    $gfx->save;
    $gfx->translate( $x, $y );

    # Show origin.
    _showloc($gfx);

    # Show baseline.
    _line( $gfx, $bb->{x}, -$bl, $bb->{width}, 0, $col );
    $gfx->restore;

    # Show layout box.
    $gfx->save;
    $gfx->linewidth( 0.25 );
    $gfx->strokecolor($col);
    $gfx->translate( $x, $y );
    for my $e ( $bb ) {
	$gfx->rect( @$e{ qw( x y width height ) } );
	$gfx->stroke;
    }
    $gfx->restore;

    # Show ink box.
    $gfx->save;
    $gfx->linewidth( 0.25 );
    $gfx->strokecolor("cyan");
    $gfx->translate( $x, $y );
    for my $e ( $ink ) {
	$gfx->rect( @$e{ qw( x y width height ) } );
	$gfx->stroke;
    }
    $gfx->restore;
}

sub _showloc {
    my ( $gfx, $x, $y, $d, $col ) = @_;
    $x ||= 0; $y ||= 0; $d ||= 50; $col ||= "blue";

    _line( $gfx, $x-$d, $y, 2*$d, 0, $col );
    _line( $gfx, $x, $y-$d, 0, 2*$d, $col );
}

sub _line {
    my ( $gfx, $x, $y, $w, $h, $col, $lw ) = @_;
    $col ||= "black";
    $lw ||= 0.5;

    $gfx->save;
    $gfx->move( $x, $y );
    $gfx->line( $x+$w, $y+$h );
    $gfx->linewidth($lw);
    $gfx->strokecolor($col);
    $gfx->stroke;
    $gfx->restore;
}

1;
