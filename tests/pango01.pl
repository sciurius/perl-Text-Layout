#!/usr/bin/perl

# This example created a PDF document using pure Pango. This is
# intended to be a reference for the documents created by the
# tl_p_01.pl test programs.

use strict;
use warnings;
use utf8;

use Pango;
use Cairo;

# Create document and graphics environment.
my $surface = Cairo::PdfSurface->create( 'pango01.pdf', 595, 842 ); # A4
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
    my $txt = qq{ Áhe <i><span foreground="red">quick</span> }.
      # $tinysize = 15360 for a 20pt font.
      qq{<span size="$tinysize"><b>brown</b></span></i> }.
      # rise is in 1/1024 units.
      qq{<span rise="10240">fox</span>}.
      # 10240/1024 units = 10pt.
      qq{<span rise="10pt" }.
      # size=46080 (45*1024) for a 60pt font.
      qq{size="46080">x</span>}.
      # size=45pt for a 60pt font.
      qq{<span rise="10pt" size="45pt">x</span> };
    my $txt_nomarkup = "Áhe quick brown fox ";

    $layout->set_markup($txt);

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

    # Plain Cairo, no Pango.
    $cr->select_font_face( "freeserif", "normal", "normal" );
    $cr->set_font_size($realfontsize);
    $cr->move_to( $x, $y+50 );
    $cr->show_text($txt_nomarkup);

    $y += 100;

    # Right align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("center");

    # Render it.
    showlayout( $x, $y );

    # Ship out.
    $cr->show_page;

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
