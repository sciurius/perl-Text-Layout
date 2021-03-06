#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib "../CPAN";
use PDF::API2;

use lib "../lib";
use Text::Layout;
use Text::Layout::FontConfig;

# Create document and graphics environment.
my $pdf = PDF::API2->new();
$pdf->mediabox( 595, 842 );	# A4

# Set up page and get the text context.
my $page = $pdf->page;
my $text = $page->text;

# Create a layout instance.
my $layout = Text::Layout->new($pdf);

my $PANGO_SCALE;

sub main {
    # Select a font.
    my $font = Text::Layout::FontConfig->from_string("Serif 60");
    $layout->set_font_description($font);

    # Start...
    my $x = 0;
    my $y = 500;

    # Text to render.
    $layout->set_markup( q{Áhe <i><span foreground="red">quick</span> <span size="20"><b>brown</b></span></i> fox} );

    # Left align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("left");

    # Render it.
    showlayout( $x, $y );

    $y -= 100;

    # Right align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("right");

    # Render it.
    showlayout( $x, $y );

    $y -= 100;

    $text->font( $font->{font}, 60);
    $text->translate( $x, $y-50 );
    $text->text(q{Áhe quick brown fox});

    $y -= 100;

    # Text to render.
#    $layout->set_markup( q{Áhe quick brown fox} );

    # Right align text.
    $layout->set_width( 595 * $PANGO_SCALE );
    $layout->set_alignment("center");

    # Render it.
    showlayout( $x, $y );

    # Ship out.
    $pdf->saveas("pdfapi1.pdf");
}

################ Subroutines ################

my $gfx;

sub showlayout {
    my ( $x, $y ) = @_;
    $layout->show( $x, $y, $text);
    $gfx //= $page->gfx;
    $layout->showbb($gfx);
}

sub setup_fonts {
    # Register all corefonts. Useful for fallback.
    # Not required, skip if you have your own fonts.
    my $fd = Text::Layout::FontConfig->new;
    # $fd->register_corefonts;

    # Add font dir and register fonts.
    $fd->add_fontdirs( $ENV{HOME}."/.fonts", "/usr/share/fonts/" );
    $fd->register_font( "ITCGaramond-Light.ttf",       "Garamond"               );
    $fd->register_font( "ITCGaramond-Bold.ttf",        "Garamond", "Bold"       );
    $fd->register_font( "ITCGaramond-LightItalic.ttf", "Garamond", "Italic"     );
    $fd->register_font( "ITCGaramond-BoldItalic.ttf",  "Garamond", "BoldItalic" );

    # Make Serif alias for Garamond.
    $fd->register_aliases( "Garamond", "Serif" );

    # Add a Sans family.
    $fd->register_font( "DejaVuSans.ttf",             "Sans"               );
    $fd->register_font( "DejaVuSans-Bold.ttf",        "Sans", "Bold"       );
    $fd->register_font( "DejaVuSans-Oblique.ttf",     "Sans", "Italic"     );
    $fd->register_font( "DejaVuSans-BoldOblique.ttf", "Sans", "BoldItalic" );
}

################ Main entry point ################

# Setup the fonts.
setup_fonts();

if ( 1 ) {
    # For compliancy, use Pango units;
    $layout->set_pango_scale;
    $PANGO_SCALE = 1000;
}
else {
    $PANGO_SCALE = 1;
}

main();
