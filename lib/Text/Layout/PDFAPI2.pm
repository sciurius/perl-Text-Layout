#! perl

use strict;
use warnings;
use utf8;

package Text::Layout::PDFAPI2;

use Carp;

sub init {
    my ( $pkg, @args ) = @_;
    $args[0];
}

sub render {
    my ( $ctx, $x, $y, $text ) = @_;

    my @bb = $ctx->get_pixel_bbox;
    my $bl = $bb[3];
    if ( $ctx->{_width} && $ctx->{_alignment} ) {
	my $w = $bb[2] - $bb[0];
	if ( $w < $ctx->{_width} ) {
	    if ( $ctx->{_alignment} eq "right" ) {
		$x += $ctx->{_width} - $w;
	    }
	    elsif ( $ctx->{_alignment} eq "center" ) {
		$x += ( $ctx->{_width} - $w ) / 2;
	    }
	}
    }

    $text->save;
    foreach my $fragment ( @{ $ctx->{_content} } ) {
	next unless length($fragment->{text});
	my $f = $fragment->{font}->get_font($ctx) || $ctx->{_currentfont}->{font};
	$text->font( $f, $fragment->{size} || $ctx->{_currentsize} );
	$text->strokecolor( $fragment->{color} );
	$text->fillcolor( $fragment->{color} );

	printf("%.2f %.2f \"%s\" %s\n",
	       $x, $y-$fragment->{base}-$bl,
	       $fragment->{text},
	       join(" ", $fragment->{font}->{family},
		    $fragment->{font}->{style},
		    $fragment->{font}->{weight},
		    $fragment->{size} || $ctx->{_currentsize},
		    $fragment->{color},
		   ),
	       ) if 0;
	$text->translate( $x, $y-$fragment->{base}-$bl );
	$text->text( $fragment->{text} );
	$x += $f->width( $fragment->{text} ) * $fragment->{size};
    }
    $text->restore;
}

sub bbox {
    my ( $ctx ) = @_;
    my ( $x, $w, $d, $a ) = (0) x 4;
    foreach ( @{ $ctx->{_content} } ) {
	my $font = $_->{font}->get_font($ctx);
	my $upem = 1000;	# as delivered by PDF::API2
	my $size = $_->{size};
	my $base = $_->{base};
	$w += $font->width( $_->{text} ) * $size;
	my ( $d0, $a0 );
	if ( 1 ) {
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
	$d = $d0 if $d0 < $d;
	$a = $a0 if $a0 > $a;
    }

    if ( $ctx->{_width} && $ctx->{_alignment} && $w < $ctx->{_width} ) {
	if ( $ctx->{_alignment} eq "right" ) {
	    $x += $ctx->{_width} - $w;
	}
	elsif ( $ctx->{_alignment} eq "center" ) {
	    $x += ( $ctx->{_width} - $w ) / 2;
	}
    }

    [ $x, $d, $x+$w, $a ];
}

sub load_font {
    my ( $self, $ctx, $font ) = @_;
    my $ff;
    if ( $font =~ /\.[ot]tf$/ ) {
	eval {
	    $ff = $ctx->{_context}->ttfont( $font, -dokern => 1 );
	};
    }
    else {
	eval {
	    $ff = $ctx->{_context}->corefont( $font, -dokern => 1 );
	};
    }

    croak( "Cannot load font: ", $font, "\n", $@ ) unless $ff;
    # warn("Loaded font: $description->{load}\n");
    $self->{font} = $ff;
    $self->{cache}->{font} = $ff;
    return $ff;
}

1;
