#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Pango;
use Cairo;

# Create document and graphics environment.
my $surface = Cairo::PdfSurface->create( 'pango02.pdf', 595, 842 ); # A4
my $cr = Cairo::Context->create($surface);
my $layout = Pango::Cairo::create_layout($cr);

# Scale from Cairo (PDF) units to Pango.
my $PANGO_SCALE = Pango->scale;

# Scale from Cairo (PDF) font size to Pango.
my $PANGO_FONT_SCALE = 0.75 * $PANGO_SCALE;

# Font sizes used, scaled.
my $realfontsize = 60;
my $fontsize = $realfontsize * $PANGO_FONT_SCALE;
my $tinysize = 20 * $PANGO_FONT_SCALE;

sub main {

    # Select a font.
    my $font = Pango::FontDescription->from_string('freeserif 12');
    $font->set_size($fontsize);
    $layout->set_font_description($font);

    # Start...
    my $x = 0;
    my $y = 842-500;		# Cairo goes down

    # Text to render.
    $layout->set_markup( q{ Áhe <i><span foreground="red">quick</span> <span size="15360"><b>brown</b></span></i> fox } );

    # Left align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("left");

    # Render it.
    showlayout( $x, $y );

    $y += 100;

    # Right align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("right");

    # Render it.
    showlayout( $x, $y );

    $y += 100;

    $font = Pango::FontDescription->from_string('Lohit Devanagari 45');
    $layout->set_font_description($font);
    $layout->set_width( 595 * $PANGO_SCALE );
    # Nepali is LTR.
    $layout->set_alignment("left");

    # This text consists of 6 characters but will render 4 glyphs.
    my $phrase =
      "\N{DEVANAGARI LETTER TA}".
      "\N{DEVANAGARI LETTER MA}".
      "\N{DEVANAGARI VOWEL SIGN AA}".
      "\N{DEVANAGARI LETTER NGA}".
      "\N{DEVANAGARI SIGN VIRAMA}".
      "\N{DEVANAGARI LETTER GA}".
      qq{ <span font="sans 20"> this should look like THIS</span>};
    $layout->set_markup($phrase);
    showlayout( $x, $y );

}

################ Subroutines ################


sub showlayout {
    my ( $x, $y ) = @_;
    $cr->move_to( $x, $y );
    $cr->set_source_rgba( 0, 0, 0, 1 );
    Pango::Cairo::show_layout($cr, $layout);
    showbb( $layout, $x, $y, "magenta" );
}

# Shows the bounding box of the last piece of text that was rendered.
sub showbb {
    my ( $self, $x, $y ) = @_;

    # Show origin.
    _showloc( $x, $y );

    # Bounding box, top-left coordinates.
    my %e = %{($self->get_pixel_extents)[0]};
    printf( "EX1: %.2f %.2f %.2f %.2f\n", @e{qw( x y width height )} );
    %e = %{$self->get_pixel_extents};
    printf( "EX0: %.2f %.2f %.2f %.2f\n", @e{qw( x y width height )} );

    # NOTE: Some fonts include natural spacing in the bounding box.
    # NOTE: Some fonts exclude accents on capitals from the bounding box.

    # Show baseline.
    $cr->save;
    $cr->set_source_rgb(1,0,1);
    $cr->set_line_width( 0.25 );
    $cr->translate( $x, $y );

    _line( $e{x}, $self->get_baseline/$PANGO_SCALE, $e{width}, 0 );

    # Show BBox.
    $cr->rectangle( $e{x}, $e{y}, $e{width}, $e{height} );;
    $cr->stroke;
    %e = %{($self->get_pixel_extents)[0]};
    $cr->set_source_rgb(0,1,1);
    $cr->rectangle( $e{x}, $e{y}, $e{width}, $e{height} );;
    $cr->stroke;
    $cr->restore;

}

sub _showloc {
    my ( $x, $y, $d ) = @_;
    $x ||= 0; $y ||= 0; $d ||= 50;
    $cr->save;
    $cr->set_source_rgb(0,0,1);
    _line( $x-$d, $y, 2*$d, 0 );
    _line( $x, $y-$d, 0, 2*$d );
    $cr->restore;
}

sub _line {
    my ( $x, $y, $w, $h, $lw ) = @_;
    $lw ||= 0.5;
    $y = $y;
    $cr->save;
    $cr->move_to( $x, $y );
    $cr->rel_line_to( $w, $h );
    $cr->set_line_width($lw);
    $cr->stroke;
    $cr->restore;
}

################ Main entry point ################

# Run...
main();
