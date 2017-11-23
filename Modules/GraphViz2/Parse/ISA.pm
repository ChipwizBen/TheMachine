package GraphViz2::Parse::ISA;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Algorithm::Dependency;
use Algorithm::Dependency::Source::HoA;

use Class::ISA;
use Class::Load 'try_load_class';

use GraphViz2;

use Moo;

use Tree::DAG_Node;

has graph =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'GraphViz2',
	required => 0,
);

has is_a =>
(
	default  => sub{return {} },
	is       => 'rw',
	#isa     => 'HashRef',
	required => 0,
);

our $VERSION = '2.46';

# -----------------------------------------------

sub add
{
	my($self, %arg) = @_;
	my($class)  = delete $arg{class}  || die 'Error. No class name specified';
	my($ignore) = delete $arg{ignore} || [];

	die "Error. The class parameter must not be a ref\n"            if (ref $class);
	die "Error. The ignore parameter's value must be an arrayref\n" if ($ignore && (ref $ignore ne 'ARRAY') );
	die "Error: Unable to load class '$class'\n"                    if (try_load_class($class) == 0);

	my(%ignore);

	@ignore{@$ignore} = (1) x @$ignore;
	my($tree)         = Tree::DAG_Node -> new;

	$self -> _process_is_a($tree, $class, \%ignore);
	$self -> _simplify($tree);

	my($is_a) = $self -> is_a;

	$self -> _build_dependency($tree, $is_a);
	$self -> is_a($is_a);

	return $self;

} # End of add.

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
			graph  => {rankdir => 'BT'},
			logger => '',
			node   => {color => 'blue', shape => 'Mrecord'},
		)
	);

} # End of BUILD.

# -----------------------------------------------

sub _build_dependency
{
	my($self, $tree, $is_a) = @_;
	my($name)     = $tree -> name;
	$$is_a{$name} = [];

	for my $node ($tree -> daughters)
	{
		push @{$$is_a{$name} }, $node -> name;

		$self -> _build_dependency($node, $is_a);
	}

} # End of _build_dependency.

# -----------------------------------------------

sub generate_graph
{
	my($self) = @_;

	return $self -> graph -> dependency(data => Algorithm::Dependency -> new(source => Algorithm::Dependency::Source::HoA -> new($self -> is_a) ) );

} # End of generate_graph.

# -----------------------------------------------

sub _process_is_a
{
	my($self, $tree, $class, $ignore) = @_;

	$tree -> name($class);

	for my $klass (Class::ISA::super_path($class) )
	{
		$self -> _process_is_a($tree -> new_daughter, $klass, $ignore) if (! $$ignore{$klass});
	}

} # End of _process_is_a.

# -----------------------------------------------

sub _simplify
{
	my($self, $tree) = @_;

	my(@node);

	for my $node ($tree -> daughters)
	{
		for my $sister ($node -> sisters)
		{
			for my $daughter ($sister -> daughters)
			{
				push @node, $node if ($node -> name eq $daughter -> name);
			}
		}
	}

	$tree -> remove_daughters(@node);

	for my $node ($tree -> daughters)
	{
		$self -> _simplify($node);
	}

} # End of _simplify.

# ------------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Parse::ISA> - Visualize N Perl class hierarchies as a graph

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::Spec;

	use GraphViz2;
	use GraphViz2::Parse::ISA;

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

	my($graph) = GraphViz2 -> new
		(
		 edge   => {color => 'grey'},
		 global => {directed => 1},
		 graph  => {rankdir => 'BT'},
		 logger => $logger,
		 node   => {color => 'blue', shape => 'Mrecord'},
		);
	my($parser) = GraphViz2::Parse::ISA -> new(graph => $graph);

	unshift @INC, 't/lib';

	$parser -> add(class => 'Adult::Child::Grandchild', ignore => []);
	$parser -> add(class => 'Hybrid', ignore => []);
	$parser -> generate_graph;

	my($format)      = shift || 'svg';
	my($output_file) = shift || File::Spec -> catfile('html', "parse.code.$format");

	$graph -> run(format => $format, output_file => $output_file);

See scripts/parse.isa.pl (L<GraphViz2/Scripts Shipped with this Module>).

=head1 Description

Takes a class name and converts its class hierarchy into a graph. This can be done for N different classes before the graph is generated.

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

C<new()> is called as C<< my($obj) = GraphViz2::Parse::ISA -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Parse::ISA>.

Key-value pairs accepted in the parameter list:

=over 4

=item o graph => $graphviz_object

This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
except for the logger of course, which defaults to ''.

This key is optional.

=back

=head1 Methods

=head2 add(class => $class[, ignore => $ignore])

Adds the class hierarchy of $class to an internal structure.

$class is the name of the class whose parents are to be found.

$ignore is an optional arrayref of class names to ignore. The value of $ignore is I<not> preserved between calls to add().

After all desired calls to add(), you I<must> call L</generate_graph()> to actually trigger the call to the L<GraphViz2> methods add_node() and add_edge().

Returns $self for method chaining.

See scripts/parse.isa.pl.

=head2 generate_graph()

Processes the internal structure mentioned under add() to add all the nodes and edges to the graph.

After that you call L<GraphViz2>'s run() method on the graph object. See L</graph()>.

Returns $self for method chaining.

See scripts/parse.isa.pl.

=head2 graph()

Returns the graph object, either the one supplied to new() or the one created during the call to new().

=head1 FAQ

See L<GraphViz2/FAQ> and L<GraphViz2/Scripts Shipped with this Module>.

=head1 Thanks

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

The code in add() was adapted from L<GraphViz::ISA::Multi> by Marcus Thiesen, but that code gobbled up package declarations
in comments and POD, so I used L<Pod::Simple> to give me just the source code.

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
