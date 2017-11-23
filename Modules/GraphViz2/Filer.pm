package GraphViz2::Filer;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use File::Basename; # For basename().
use File::Slurp;    # For read_file().

use Moo;

our $VERSION = '2.46';

# ------------------------------------------------

sub get_annotations
{
	my($self)     = @_;
	my($dir_name) = 'scripts';

	$|=1;

	opendir(my $fh, $dir_name);
	my(@file_name) = sort grep{! -d $_} readdir $fh;
	closedir $fh;

	my(%annotation);
	my(@line);
	my($s);

	for my $file_name (@file_name)
	{
		@line = read_file(File::Spec -> catfile($dir_name, $file_name), {chomp => 1});

		if ( ($#line >= 3) && ($line[3] =~ /^# Annotation: (.+)$/) )
		{
			# Preserve $1 in case basename changes it.

			$s                                       = $1;
			$annotation{basename($file_name, '.pl')} = $s;
		}
	}

	return %annotation;

} # End of get_annotations.

# ------------------------------------------------

sub get_files
{
	my($self, $dir_name, $type) = @_;

	opendir(my $fh, $dir_name);
	my(@file) = sort grep{/$type$/} readdir $fh;
	closedir $fh;

	my(%file);

	for my $file_name (@file)
	{
		$file{basename($file_name, ".$type")} = $file_name;
	}

	return %file;

} # End of get_files.

# ------------------------------------------------

sub get_scripts
{
	my($self)     = @_;
	my($dir_name) = 'scripts';

	opendir(my $fh, $dir_name);
	my(@file_name) = sort grep{! -d $_ && /\.pl$/} readdir $fh;
	closedir $fh;

	my(@line);
	my(%script);

	for my $file_name (map{File::Spec -> catfile($dir_name, $_)} @file_name)
	{
		@line = read_file($file_name, {chomp => 1});

		if ( ($#line >= 3) && ($line[3] =~ /^# Annotation: (?:.+)$/) )
		{
			$script{basename($file_name, '.pl')} = $file_name;
		}
	}

	return %script;

} # End of get_scripts.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Filer> - Some utils to simplify testing and generating the demo page

=head1 Synopsis

See L<GraphViz2/Synopsis>.

See t/tokens.t.

=head1 Description

Some utils to simplify testing.

End-users do not need to call the methods in this module.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<GraphViz2> as you would for any C<Perl> module:

Run:

	cpanm GraphViz2

or run:

	sudo cpan GraphViz2

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = GraphViz2::Filer -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Filer>.

=head1 Methods

=head1 get_annotations()

Returns a hash (sic) keyed by *.pl name, with the values being the text off line 3 of each script.

This text is used to annotate html/index.html, the output of scripts/generate.demo.pl.


=head2 get_files($dir_name, $type)

Returns a list of files from the given $dir_name, whose type (extension) matches $type.

See t/tokens.t.

=head2 get_scripts()

Returns a hash (sic) keyed by *.pl name, with the values being the full path to the script.

=head1 Thanks

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2>.

=head1 Author

L<GraphViz2> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
