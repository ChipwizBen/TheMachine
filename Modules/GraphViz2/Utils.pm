package GraphViz2::Utils;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Config;

use Date::Simple;

use File::Spec;
use File::Slurp; # For read_file().

use GraphViz2::Config;
use GraphViz2::Filer;

use HTML::Entities::Interpolate;

use Moo;

use Text::Xslate 'mark_raw';

has config =>
(
	default  => sub{return GraphViz2::Config -> new -> config},
	is       => 'rw',
#	isa      => 'HashRef',
	required => 0,
);

our $VERSION = '2.46';

# ------------------------------------------------

sub generate_demo_environment
{
	my($self) = @_;

	my(@environment);

	# mark_raw() is needed because of the HTML tag <a>.

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => 'Debian V 6'},
	{left => 'Perl',   right => $Config{version} };

	return \@environment;

} # End of generate_demo_environment.

# -----------------------------------------------

sub generate_demo_index
{
	my($self)          = @_;
	my($html_dir_name) = 'html';
	my(%script_file)   = GraphViz2::Filer -> new -> get_scripts;

	my($html_name);
	my(@line);
	my($note);

	for my $key (sort keys %script_file)
	{
		@line      = read_file($script_file{$key}, {binmode => ':utf8'});
		$note      = $line[3];
		$note      =~ s/Annotation: //;
		$html_name = "$html_dir_name/$key.svg";

		$script_file{$key} =
		{
			image_name  => -e $html_name ? $html_name : '',
			note        => $note,
			script_name => $script_file{$key},
		};
	}

	my(@key)       = sort keys %script_file;
	my($config)    = $self -> config;
	my($templater) = Text::Xslate -> new
	(
		input_layer => '',
		path        => $$config{template_path},
	);
	my($count) = 0;
	my($index) = $templater -> render
	(
	'graphviz2.index.tx',
	{
		default_css     => "$$config{css_url}/default.css",
		data =>
			[
			map
			{
				{
					count       => ++$count,
					image       => "./$_.svg",
					image_name  => $script_file{$_}{image_name},
					note        => $script_file{$_}{note},
					script_name => $script_file{$_}{script_name},
				};
			} @key
			],
		environment     => $self -> generate_demo_environment,
		fancy_table_css => "$$config{css_url}/fancy.table.css",
		version         => $VERSION,
	}
	);
	my($file_name) = File::Spec -> catfile($html_dir_name, 'index.html');

	open(my $fh, '>', $file_name);
	print $fh $index;
	close $fh;

	print "Wrote $file_name\n";

	# Return 0 for success and 1 for failure.

	return 0;

} # End of generate_demo_index.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Utils> - Some utils to generate the demo page

=head1 Synopsis

See L<GraphViz2/Synopsis>.

See scripts/generate.index.pl.

Note: scripts/generate.index.pl outputs to a directory called 'html' in the 'current' directory.

See: L<http://savage.net.au/Perl-modules/html/graph.easy.marpa/index.html>.

=head1 Description

Some utils to simplify generation of the demo page.

It is not expected that end-users would ever need to use this module.

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

C<new()> is called as C<< my($obj) = GraphViz2::Utils -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Utils>.

Key-value pairs accepted in the parameter list:

=over 4

=item o (none)

=back

=head1 Methods

=head2 generate_demo_environment()

Returns a hashref of OS, etc, values.

Keys are C<left> and C<right>, to suit C<htdocs/assets/templates/graph/easy/marpa/fancy.table.tx>.

C<*.tx> files are used by L<Text::Xslate>.

Called by L</generate_demo_index()>.

=head2 generate_demo_index()

Calls L<GraphViz2::Filer/get_files($dir_name, $type)> and L</generate_demo_environment()>.

Writes C<html/index.html>.

See scripts/generate.index.pl.

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
