package GraphViz2::Parse::Yapp;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use GraphViz2;

use Moo;

use File::Slurp; # For read_file().

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

	my(%edges);
	my(%is_rule);
	my(%labels);
	my($rule, $rule_label);
	my($text);

	for my $line (read_file($arg{file_name}, {chomp => 1}) )
	{
		if ( ($line !~ /\w/) || ($line !~ /^\d+:\s+/) )
		{
			next;
		}

		$line          =~ s/^\d+:\s+//;
		($rule, $text) = $line =~ /^(.+) -> (.+)$/;

		$is_rule{$rule} = 0 if (! $is_rule{$rule});
		$is_rule{$rule}++;

		$text       = '(empty)' if ($text eq '/* empty */');
		$rule_label = '';

		for my $item (split(' ', $text) )
		{
			$rule_label          .= "$item ";
			$edges{$rule}        = {} if (! $edges{$rule});
			$edges{$rule}{$item} = 0  if (! $edges{$rule}{$item});

			$edges{$rule}{$item}++;
        }

		$rule_label    .= '\n';
		$labels{$rule} .= $rule_label;
	}

	for my $from (keys %edges)
	{
		next if (! $is_rule{$from});

		for my $to (keys %{$edges{$from} })
		{
			next if (! $is_rule{$to});

			$self -> graph -> add_edge(from => $from, to => $to);
		}
	}

	for my $rule (keys %labels)
	{
		$self -> graph -> add_node(name => $rule, label => [$rule, $labels{$rule}]);
	}

	return $self;

}	# End of create.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Parse::Yapp> - Visualize a yapp grammar as a graph

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::Spec;

	use GraphViz2;
	use GraphViz2::Parse::Yapp;

	use Log::Handler;

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
		 graph  => {concentrate => 1, rankdir => 'TB'},
		 logger => $logger,
		 node   => {color => 'blue', shape => 'oval'},
		);
	my($g) = GraphViz2::Parse::Yapp -> new(graph => $graph);

	$g -> create(file_name => File::Spec -> catfile('t', 'calc.output') );

	my($format)      = shift || 'svg';
	my($output_file) = shift || File::Spec -> catfile('html', "parse.yapp.$format");

	$graph -> run(format => $format, output_file => $output_file);

See scripts/parse.yapp.pl (L<GraphViz2/Scripts Shipped with this Module>).

=head1 Description

Takes a yapp grammar and converts it into a graph.

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

C<new()> is called as C<< my($obj) = GraphViz2::Parse::Yapp -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Parse::Yapp>.

Key-value pairs accepted in the parameter list:

=over 4

=item o graph => $graphviz_object

This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
except for the logger of course, which defaults to ''.

This key is optional.

=back

=head1 Methods

=head2 create(file_name => $file_name)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to new().

Returns $self for method chaining.

$file_name is the name of a yapp output file. See t/calc.output.

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
