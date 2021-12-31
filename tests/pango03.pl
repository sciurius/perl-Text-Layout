#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Pango;
use Cairo;
require "./pango00.pl";	   # subs

# Create document and graphics environment.
my $surface = Cairo::PdfSurface->create( 'pango03.pdf', 595, 842 ); # A4
my $cr = Cairo::Context->create($surface);
my $layout = Pango::Cairo::create_layout($cr);

# Scale from Cairo (PDF) units to Pango.
my $PANGO_SCALE = Pango->scale;

# Select a font.
my $font = Pango::FontDescription->from_string('Amiri 45');
$layout->set_font_description($font);

# Start...
my $x = 0;
my $y = 842-600;

# Left align text.
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_alignment("left");

# Typeset in three parts. Note that parts 1 and 3 will be ltr,
# and part 2 will be rtl.
# Note, however, that this currently relies on the native
# harfbuzz library to correctly determine ('guess') the
# characteristics of the text.

$layout->set_markup("abc");
$x += showlayout( $cr, $layout, $x, $y );

$layout->set_markup( q{برنامج أهلا بالعالم} );
# Arabic is RTL, restrict to actual width to prevent unwanted alignment.
$layout->set_width( ($layout->get_size)[0] );
$x += showlayout( $cr, $layout, $x, $y );

$layout->set_markup("xyz");
$dx = ($layout->get_size)[0];
$layout->set_width($dx);
showlayout( $cr, $layout, $x, $y );

# Typeset as one string, using <span>.
$x = 0;
$y += 100;
$font = Pango::FontDescription->from_string("Sans 45");
$layout->set_font_description($font);
$layout->set_width( 595 * $PANGO_SCALE );
$layout->set_markup( "abc".
		     "<span font='Amiri'>".q{برنامج أهلا بالعالم}."</span>".
		     "def" );
showlayout( $cr, $layout, $x, $y );

# Ship out.
$cr->show_page;
