package GraphViz2::Parse::STT;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use GraphViz2;

use Moo;

has graph =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'GraphViz2',
	required => 0,
);

our $VERSION = '2.46';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> graph
	(
		$self -> graph ||
		GraphViz2 -> new
		(
			edge   => {color => 'grey'},
			global => {directed => 1},
			graph  => {rankdir => 'TB'},
			logger => '',
			node   => {color => 'blue', shape => 'oval'},
		)
	);

} # End of BUILD.

# -----------------------------------------------

sub create
{
	my($self, %arg) = @_;
	my($stt) = $arg{stt};

	my(%edge);
	my(@field);
	my($i);
	my(%seen);

	for my $line (split(/\n/, $stt) )
	{
		$line  =~ s/^\s+//;
		$line  =~ s/\s+$//;
		$line  =~ s/^\[//;
		$line  =~ s/],?$//;
		@field = split(/\s*,\s*/, $line);

		# The first 2 '\'s are just to fix the syntax highlighting in UltraEdit.

		@field = map{s/^([\"\'])(.+)\1/$2/; $_} @field;

		for $i (0, 2)
		{
			if (! $seen{$field[$i]})
			{
				$seen{$field[$i]} = 1;

				$self -> graph -> add_node(name => $field[$i]);
			}
		}

		$edge{$field[0]}            = {} if (! $edge{$field[0]});
		$edge{$field[0]}{$field[2]} = [] if (! $edge{$field[0]}{$field[2]});

		push @{$edge{$field[0]}{$field[2]} }, $field[1];
	}

	for my $from (keys %edge)
	{
		for my $to (keys %{$edge{$from} })
		{
			for my $edge (@{$edge{$from}{$to} })
			{
				$self -> graph -> add_edge(from => $from, to => $to, label => "/$edge/");
			}
		}
	}

	return $self;

}	# End of create.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Parse::STT> - Visualize a Set::FA::Element state transition table as a graph

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::Spec;

	use GraphViz2;
	use GraphViz2::Parse::STT;

	use Log::Handler;

	use File::Slurp; # For read_file().

	# ------------------------------------------------

	my($logger) = Log::Handler -> new;

	$logger -> add
		(
		 screen =>
		 {
			 maxlevel       => 'debug',
			 message_layout => '%m',
			 minlevel       => 'error',
		 }
		);

	my($graph)  = GraphViz2 -> new
		(
		 edge   => {color => 'grey'},
		 global => {directed => 1},
		 graph  => {rankdir => 'TB'},
		 logger => $logger,
		 node   => {color => 'green', shape => 'oval'},
		);
	my($g)  = GraphViz2::Parse::STT -> new(graph => $graph);
	my $stt = read_file(File::Spec -> catfile('t', 'sample.stt.1.dat') );

	$g -> create(stt => $stt);

	my($format)      = shift || 'svg';
	my($output_file) = shift || File::Spec -> catfile('html', "parse.stt.$format");

	$graph -> run(format => $format, output_file => $output_file);

See scripts/parse.stt.pl (L<GraphViz2/Scripts Shipped with this Module>).

Note: t/sample.stt.2.dat is output from L<Graph::Easy::Marpa::DFA> V 0.70, and can be used
instead of t/sample.stt.1.dat in the above code.

=head1 Description

Takes a L<Set::FA::Element>-style state transition table and converts it into a graph.

You can write the result in any format supported by L<Graphviz|http://www.graphviz.org/>.

Here is the list of L<output formats|http://www.graphviz.org/content/output-formats>.

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

C<new()> is called as C<< my($obj) = GraphViz2::Parse::STT -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Parse::STT>.

Key-value pairs accepted in the parameter list:

=over 4

=item o graph => $graphviz_object

This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
except for the logger of course, which defaults to ''.

This key is optional.

=back

=head1 Methods

=head2 create(stt => $state_transition_table)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to new().

Returns $self for method chaining.

$state_transition_table is a list of arrayrefs, each with 3 elements.

That is, it is the I<contents> of the arrayref 'transitions', which is one of the keys in the parameter list
to L<Set::FA::Element>'s new().

A quick summary of each element of this list, where each element is an arrayref with 3 elements:

=over 4

=item o [0] A state name

=item o [1] A regexp

=item o [2] Another state name (which may be the same as the first)

=back

The DFA in L<Set::FA::Element> tests the 'current' state against the state name ([0]), and for each state name
which matches, tests the regexp ([1]) against the next character in the input stream. The first regexp to match
causes the DFA to transition to the state named in the 3rd element of the arrayref ([2]).

See t/sample.stt.1.dat for an example.

=head2 graph()

Returns the graph object, either the one supplied to new() or the one created during the call to new().

=head1 FAQ

See L<GraphViz2/FAQ> and L<GraphViz2/Scripts Shipped with this Module>.

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
