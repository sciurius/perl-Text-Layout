#!/usr/bin/perl

# This is an example of using Text::Layout to create the same document
# as native Pango.
#
# This example uses Text::Layout in comfort mode. The relevant parts
# of this program differ slightly from its Pango counterpart but are
# much easier to program and maintain.

use strict;
use warnings;
use utf8;

use lib "../lib";
use PDF::API2;
use Text::Layout;

# Create document and graphics environment.
my $pdf = PDF::API2->new( file => 'pdfapi1c.pdf' );
$pdf->mediabox( 595, 842 );	# A4

# Set up page and get the text context.
my $page = $pdf->page;
my $text = $page->text;

# Create a layout instance.
my $layout = Text::Layout->new($pdf);

# Font sizes used.
my $fontsize = 60;
my $tinysize = 20;

sub main {
    # Select a font.
    my $font = Text::Layout::FontConfig->from_string("freeserif 12");
    $font->set_size($fontsize);
    $layout->set_font_description($font);

    # Start...
    my $x = 0;
    my $y = 500;		# PDF goes up

    # Text to render.
    $layout->set_markup( qq{Áhe <i><span foreground="red">quick</span> <span size="$tinysize"><b>brown</b></span></i> fox} );

    # Left align text.
    $layout->set_width(595);
    $layout->set_alignment("left");

    # Render it.
    showlayout( $x, $y );

    $y -= 100;

    # Right align text.
    $layout->set_width(595);
    $layout->set_alignment("right");

    # Render it.
    showlayout( $x, $y );

    $y -= 100;

    # Plain PDF::API2, no Text::Layout.
    $text->font( $font->{font}, $fontsize );
    $text->translate( $x, $y-50 );
    $text->text(q{Áhe quick brown fox});

    $y -= 100;

    # Right align text.
    $layout->set_width(595);
    $layout->set_alignment("center");

    # Render it.
    showlayout( $x, $y );

    # Ship out.
    $pdf->save;
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
    my $fd = Text::Layout::FontConfig->new;

    # Add font dir and register fonts.
    $fd->add_fontdirs( $ENV{HOME}."/.fonts", "/usr/share/fonts/" );
    for ( "", qw( Bold Italic BoldItalic ) ) {
	$fd->register_font( "FreeSerif$_.ttf", "freeserif", $_ );
    }
}

################ Main entry point ################

# Setup the fonts.
setup_fonts();

# Run...
main();
