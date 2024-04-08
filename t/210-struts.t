#! perl

use strict;
use warnings;
use utf8;
use Test::More;
if ( eval { require PDF::API2 } ) {
    plan tests => 1;
}
else {
    plan skip_all => "PDF::API2 not installed";
}

use Text::Layout::Testing;

-d "t" && chdir("t");

# Create PDF document, with a page and text content.
my $pdf = PDF::API2->new;

my $text = "<strut label='start' width=10/>The quick brown fox<strut label='end'/>";

my $fc = Text::Layout::FontConfig->new( corefonts => 1 );

my $layout = Text::Layout->new($pdf);
$layout->set_font_description
  ( Text::Layout::FontConfig->from_string( "Times-Roman 20" ) );

$layout->set_markup($text);
my @s = $layout->get_struts;

my $exp = [ { _x     => 0,
	      width  => 10,
	      desc   => undef,
	      asc    => undef,
	      label  => 'start' },
	    { _x     =>  178.3,
	      desc   => undef,
	      asc    => undef,
	      width  => 0,
	      label  => 'end' } ];

is_deeply( \@s, $exp, "struts" );
