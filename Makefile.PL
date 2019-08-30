use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Layout',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/Text/Layout.pm',
    ABSTRACT_FROM       => 'lib/Text/Layout.pm',
    LICENSE		=> 'perl_5',
    PL_FILES            => {},
    MIN_PERL_VERSION	=> '5.010001',
    PREREQ_PM => {
        'ExtUtils::MakeMaker' => 6.46, # for META_MERGE, LICENSE
        'Test::More' => 0,
    },
    META_MERGE => {
      resources    => {
        repository => {
          type => 'git',
	   web  => 'https://github.com/sciurius/perl-Text-Layout',
	   url  => 'https://github.com/sciurius/perl-Text-Layout.git',
	 },
	 bugtracker => "https://github.com/sciurius/perl-Text-Layout/issues",
	},
	'meta-spec' => {
	  version => '2',
	  url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
	},
    }
);
