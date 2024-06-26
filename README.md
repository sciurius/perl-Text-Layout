# Text::Layout
![Version](https://img.shields.io/github/v/release/sciurius/perl-Text-Layout)
![GitHub issues](https://img.shields.io/github/issues/sciurius/perl-Text-Layout)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![Language Perl](https://img.shields.io/badge/Language-Perl-blue)



**WARNING: Some parts of the API are changing in incompatible ways. If you
(want to) use this module for serious work please contact me.**

Text::Layout provides methods for Pango style text formatting. Where
possible the methods have identical names and (near) identical
behaviour as their Pango counterparts.

Text::Layout uses backend modules to render the marked up text.
Backends are included for:

*  PDF::API2  (functional)
*  PDF::Builder  (functional)
*  Markdown  (minimal functionality)

Note that the Pango and Cairo backends are discontinued.

The package uses Text::Layout::FontConfig (included) to organize fonts
by description.

If module HarfBuzz::Shaper is installed, Text::Layout can use it for
text shaping.

## Example

    # Create a PDF document.
    my $pdf = PDF::API2->new;	# or PDF::Builder->new
    $pdf->default_page_size("a4");

    # Set up page and get the text context.
    my $page = $pdf->page;
    my $ctx  = $page->text;

    # Create a markup instance, passing the PDF context.
    my $layout = Text::Layout->new($pdf);

    # This example uses PDF corefonts only.
    Text::Layout::FontConfig->register_corefonts;

    $layout->set_font_description(Text::Layout::FontConfig->from_string("times 40"));
    $layout->set_markup( q{The <i><span foreground="red">quick</span> <span size="20"><b>brown</b></span></i> fox} );

    # Center text.
    $layout->set_width(595);	# width of A4 page
    $layout->set_alignment("center");

    # Render it, passing the text context.
    $layout->show( $x, $y, $ctx );

# SEE ALSO

Description of the Pango Markup Language:
https://docs.gtk.org/Pango/pango_markup.html#pango-markup.

Documentation of the Pango Layout class:
https://docs.gtk.org/Pango/class.Layout.html.

# FUTURE DIRECTIONS

Text::Layout was originally inspired by the Pango Markup Language 
and provided a Pango compatibility mode.
However, both implementations have significantly diversed.
As a result, the Pango compatibility mode will be removed in some
future version.

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-Text-Layout.

You can find documentation for this module with the perldoc command.

    perldoc Text::Layout

Please report any bugs or feature requests using the issue tracker on
GitHub.

# COPYRIGHT AND LICENCE

Copyright (C) 2019,2024 Johan Vromans

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

