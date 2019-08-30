#! perl

use strict;
use warnings;
use utf8;

package Text::Layout::FontConfig;

use Carp;

use Text::Layout::Version;

our $VERSION = $Text::Layout::VERSION;

=head1 NAME

Text::Layout::FontConfig - Pango style font description for Text::Layout

=head1 SYNOPSIS

Font descriptors are strings that identify the characteristics of the
desired font. For example, C<Sans Italic 20>.

The PDF context deals with fysical fonts, e.g. built-in fonts like
C<Times-Bold> and fonts loaded from font files like
C</usr/share/fonts/dejavu/DejaVuSans.ttf>.

To map font descriptions to fysical fonts, these fonts must be
registered. This defines a font family, style, and weight for the
font.

Note that Text::Layout::FontConfig is a singleton. Creating objects
with new() will always return the same object.

=cut

my %fonts;
my @dirs;

=head2 METHODS

=over

=item new

For convenience only. Text::Layout::FontConfig is a singleton.
Creating objects with new() will always return the same object.

=back

=cut

sub new {
    my ( $pkg ) = @_;
    return bless \my $i => $pkg;
}

=over

=item register_fonts( $font, $family, $style, $weight )

Registers a font fmaily, style and weight for the given font.

$font can be the name of a built-in font, or the name of a TrueType or
OpenType font file.

$family is a font family name such as C<normal>, C<sans>, C<serif>, or
C<monospace>. It is possible to specify multiple family names, e.g.,
C<times, serif>.

$style is the slant style, one of C<normal>, C<oblique>, or C<italic>.

$weight is the font weight, like C<normal>, or C<bold>.

For convenience, style combinations like "bolditalic" are allowed.

=back

=cut

sub register_font {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $font, $family, $style, $weight ) = @_;

    if ( $style && !$weight && $style =~ s/^bold//i ) {
	$weight = "bold";
    }
    $style  = _norm_style( $style   // "normal" );
    $weight = _norm_weight( $weight // "normal" );

    my $ff;
    if ( $font =~ /\.[ot]tf$/ ) {
	if ( $font =~ m;^/; ) {
	    $ff = $font if -r -s $font;
	}
	else {
	    foreach ( @dirs ) {
		next unless -r -s "$_/$font";
		$ff = "$_/$font";
		last;
	    }
	}
    }
    else {
	# Assume corefont.
	$ff = $font
    }

    croak("Cannot find font: ", $font, "\n") unless $ff;
 
    $fonts{lc $_}->{$style}->{$weight}->{load} = $ff
      foreach split(/\s*,\s*/, $family);

}

=over

=item add_fontdirs( @dirs )

Adds one or more file paths to be searched for font files.

=back

=cut

sub add_fontdirs {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( @d ) = @_;

    foreach ( @d ) {
	unless ( -d -r -x ) {
	    carp("Skipped font dir: $_ [$!]");
	    next;
	}
	#	$pdf->addFontDirs($_);
	push( @dirs, $_ );
    }
}

=over

=item register_aliases( $family, $aliases, ... )

Adds aliases for existing font families.

Multiple aliases can be specified, e.g.

    $layout->register_aliases( "times", "serif, default" );

or

    $layout->register_aliases( "times", "serif", "default" );

=back

=cut

sub register_aliases {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $family, @aliases ) = @_;
    carp("Unknown font family: $family")
      unless exists $fonts{lc $family};
    foreach ( @aliases ) {
	foreach ( split( /\s*,\s*/, $_ ) ) {
	    $fonts{lc $_} = $fonts{lc $family};
	}
    }
}

=over

=item register_corefonts

This is a convenience method that registers all built-in corefonts.

Aliases for families C<serif>, C<sans>, and C<monospace> are added.

You do not need to call this method if you provide your own font
registrations.

=back

=cut

sub register_corefonts {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );

    register_font( "Times-Roman",           "Times"                );
    register_font( "Times-Bold",            "Times", "Bold"        );
    register_font( "Times-Italic",          "Times", "Italic"      );
    register_font( "Times-BoldItalic",      "Times", "BoldItalic"  );
    register_aliases( "Times", "Serif" );

    register_font( "Helvetica",             "Helvetica"                 );
    register_font( "Helvetica-Bold",        "Helvetica",  "Bold"        );
    register_font( "Helvetica-Oblique",     "Helvetica",  "Oblique"     );
    register_font( "Helvetica-BoldOblique", "Helvetica",  "BoldOblique" );
    register_aliases( "Helvetica", "Sans", "Arial" );

    register_font( "Courier",               "Courier"                 );
    register_font( "Courier-Bold",          "Courier",  "Bold"        );
    register_font( "Courier-Oblique",       "Courier",  "Italic"      );
    register_font( "Courier-BoldOblique",   "Courier",  "BoldItalic"  );
    register_aliases( "Courier", "Mono", "Monospace", "fixed" );
    register_aliases( "Courier", "Mono", "Monospace", "fixed" );

    register_font( "ZapfDingbats",          "Dingbats"                );

    register_font( "Georgia",               "Georgia"                );
    register_font( "Georgia,Bold",          "Georgia",  "Bold"        );
    register_font( "Georgia,Italic",        "Georgia",  "Italic"      );
    register_font( "Georgia,BoldItalic",    "Georgia",  "BoldItalic"  );

    register_font( "Verdana",               "Verdana"                );
    register_font( "Verdana,Bold",          "Verdana",  "Bold"        );
    register_font( "Verdana,Italic",        "Verdana",  "Italic"      );
    register_font( "Verdana,BoldItalic",    "Verdana",  "BoldItalic"  );

    register_font( "WebDings",              "WebDings"                );
    register_font( "WingDings",             "WingDings"               );
}

# Find a font based on family, style and weight.

sub find_font {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $family, $style, $weight, $atts ) = @_;

    $style  = _norm_style( $style   // "normal" );
    $weight = _norm_weight( $weight // "normal" );

    if ( $fonts{$family}
	 && $fonts{$family}->{$style}
	 && $fonts{$family}->{$style}->{$weight} ) {
	my $ff;
	if ( $ff = $fonts{$family}->{$style}->{$weight}->{font} ) {
	    return
	      bless { font   => $ff,
		      family => $family,
		      style  => $style,
		      weight => $weight } => __PACKAGE__;
	}
	elsif ( $ff = $fonts{$family}->{$style}->{$weight}->{load} ) {
	    return
	      bless { load   => $ff,
		      cache  => $fonts{$family}->{$style}->{$weight},
		      family => $family,
		      style  => $style,
		      weight => $weight } => __PACKAGE__;
	}
    }

    # TODO: Some form of font fallback.

    croak("Cannot find font: $family $style\n");
}

=over

=item from_string( $description )

Returns a font object using a Pango-style font description, e.g.
C<Sans Italic 14>.

=back

=cut

my $stylep  = qr/^(bi|bo|boldoblique|bolditalic|i|o|oblique|italic)$/;
my $weightp = qr/^(b|bi|bo|bold|boldoblique|bolditalic)$/;

sub from_string {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ( $description ) = @_;

    my $family = "";
    my $style = "";
    my $weight = "";
    my $size;

    my @p = split( ' ', $description );
    $size = pop(@p) if $p[-1] =~ /^\d+(?:\.\d+)?$/;

    for ( @p ) {
	my $t = lc;
	if ( exists($fonts{$t}) ) {
	    $family = $t;
	}
	elsif ( $t =~ $stylep ) {
	    $style = "italic";
	}
	elsif ( $t =~ $weightp ) {
	    $weight = "bold";
	}
	elsif ( $t eq "normal" ) {
	    $style = $weight = "";
	}
	else {
	    carp("Unknown font property: $t");
	}
    }

    my $res = find_font( $family, $style, $weight );
    $res->{size} = $size if $res && $size;
    $res;
}

=over

=item to_string

Returns a Pango-style font string, C<Sans Italic 14>.

=back

=cut

sub to_string {
    my ( $self ) = @_;
    my $desc = ucfirst( $self->{family} );
    $desc .= ucfirst( $self->{style} ) if $self->{style} ne "normal";
    $desc .= " " . ucfirst( $self->{weight} ) if $self->{weight} ne "normal";
    $desc .= " " . $self->{size} if $self->{size};
    return $desc;
}

use overload '""' => \&to_string;

################ Helper Routines ################

# Normalize (and check) a style specification.

sub _norm_style {
    my ( $style ) = @_;
    $style = lc $style;
    return "italic" if $style =~ $stylep;

    carp("Unhandled font style: $style\n")
      unless $style =~ /^(regular|normal)?$/;

    return "normal";
}

# Normalize (and check) a weight specification.

sub _norm_weight {
    my ( $weight ) = @_;
    $weight = lc $weight;
    return "bold" if $weight =~ $weightp;

    carp("Unhandled font weight: $weight\n")
      unless $weight =~ /^(regular|normal)?$/;

    return "normal";
}

=head1 SEE ALSO

L<PDF::API2::Layout::Simple>, L<PDF::API2>, L<PDF::Builder>, L<Font::TTF>.

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 SUPPORT

Development of this module takes place on GitHub:
L<https://github.com/sciurius/xxx>.

You can find documentation for this module with the perldoc command.

  perldoc PDF::API2::Layout::Simple

Please report any bugs or feature requests using the issue tracker on
GitHub.

=back

=head1 LICENSE

Copyright (C) 2019, Johan Vromans

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
