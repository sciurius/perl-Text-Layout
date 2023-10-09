#! perl

use v5.26;
use Object::Pad;
use utf8;
use Carp;

role Text::Layout::ElementRole;

# Implementors of this role must provide the following methods:

method parse( $el, $atts );
#
# $el :  the elemant name, e.g. "img"
# $atts: anything that follows the tag, presumably atributes
#
# If the element is "<foo blar blech/>" then $el = "foo"
# and $atts = "bar blech".
#
# Should return a hash reference with whatever is useful.

method render( $hash, $gfx, $x, $y );
#
# $hash: the hash as delivered by the parser
# $gfx : PDF graphics context
# $x   : $x origin
# $y   : $y origin
#
# Should return the advance width.

method bbox( $hash );
#
# $hash: the hash as delivered by the parser
#
# Should return an array reference with the augmented bounding box.
# Elements 0 .. 3 contain the bounding box,
# Element 4 contains the horizontal advance and element 5 the vertical advance.

1;
