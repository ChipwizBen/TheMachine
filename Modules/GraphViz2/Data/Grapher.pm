package GraphViz2::Data::Grapher;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use GraphViz2;

use HTML::Entities::Interpolate;

use Moo;

use Scalar::Util qw(blessed reftype);

use Tree::DAG_Node;

has current =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'Str',
	required => 0,
);

has graph =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'GraphViz2',
	required => 0,
);

has logger =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'Log::Handler',
	required => 0,
);

has tree =>
(
	default  => sub{return Tree::DAG_Node -> new},
	is       => 'rw',
	#isa     => 'Tree::DAG_Node',
	required => 0,
);

our $VERSION = '2.46';

# -----------------------------------------------
# This is a function.

sub address
{
	my($address) = @_;
	$address =~ tr/[:.]/_/;

	return $address;

} # End of address;

# -----------------------------------------------

sub add_record
{
	my($self, $seen, $parent, @node) = @_;
	my(@label) = ();
	my($name)  = address($parent -> address) . '_kids';
	my($port)  = 0;

	for my $node (@node)
	{
		$port++;

		$$seen{$node -> address} = 1;

		$node -> attributes({record => "$name:port$port"});

		# Comment out HTML labels since I can't get them to work.
		# It seems only a shape of plaintext works with HTML.

#		push @label, qq|<td border="0" port="port$port">| . $Entitize{$node -> name} . '</td>';
		push @label, "<port$port> " . $node -> name;
	}

#	my($label) = '<<table border="0"><tr>' . join('', @label) . '</tr></table>>';
	my($label) = join('|', @label);

	if ( ($#node == 0) && ($node[0] -> name =~ /^(?:\&CODE|\$REF)/) )
	{
		$node[0] -> attributes({record => $node[0] -> name});
	}
	else
	{
		my(%global) = %{$self -> graph -> global};
		my($shape)  = $global{record_shape};

		$self -> graph -> add_node(color => 'grey', fontcolor => 'blue', name => $name, label => $label, shape => $shape);
	}

	return $self;

} # End of add_record;

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
			logger => $self -> logger,
			node   => {color => 'blue', shape => 'oval'},
		)
	);

	# Make the root the 'current' node.
	# get_reftype() will use current().

	$self -> current($self -> tree);

} # End of BUILD.

# -----------------------------------------------

sub build_graph
{
	my($self, $seen, $node) = @_;

	my(@child)  = $node -> daughters;
	my($mother) = $node -> mother;

	if (@child)
	{
		# Add a 'record' type node for all children,
		# except if the only child is a code ref or a ref,
		# which we add below to make them stand out.

		$self -> add_record($seen, $node, @child);

		# Add an edge from the parent to the middle of the child list.

		my($child) = $child[int($#child / 2)];
		$child     = $child[0] if ( ($#child == 0) && ($child[0] -> name =~ /^(?:\&CODE|\$REF)/) );
		my($from)  = ${$node -> attributes}{record};
		my($to)    = ${$child -> attributes}{record};

		if ( ($#child == 0) && ($child[0] -> name =~ /^(?:\&CODE|\$REF)/) )
		{
			$self -> graph -> add_node(color => 'grey', fontcolor => 'red', name => $child[0] -> name, shape => 'oval');
		}

		$self -> graph -> add_edge(from => $from, to => $to);

		# Recurse to handle the grandkids.

		$self -> build_graph($seen, $_) for @child;
	}
	elsif (! $$seen{$node -> address})
	{
		$$seen{$node -> address} = 1;

		$self -> graph -> add_node(name => address($node -> address), label => $node -> name, shape => 'circle');
		$self -> graph -> add_edge(from => ${$mother -> attributes}{record}, to => address($node -> address) );
	}

	return $self;

} # End of build_graph.

# -----------------------------------------------

sub build_tree
{
	my($self, $name, $item) = @_;

	my($current);
	my($daughter);

	my($ref) = reftype $item;

	if (defined $ref)
	{
		my($blessed) = blessed $item;

		if ($blessed)
		{
			$daughter = Tree::DAG_Node -> new;

			$daughter -> name($blessed);
			$self -> current -> add_daughter($daughter);
			$self -> current -> name($blessed);
		}
		elsif ($ref =~ /^ARRAY/)
		{
			$self -> current -> name('@$' . $name);

			for my $key (@$item)
			{
				$current  = $self -> current;
				$daughter = Tree::DAG_Node -> new;

				$self -> current -> add_daughter($daughter);
				$self -> current($daughter);
				$self -> build_tree($item, $key);
				$self -> current($current);
			}
		}
		elsif ($ref =~ /^CODE/)
		{
			$daughter = Tree::DAG_Node -> new;

			$daughter -> name('&' . $item);
			$self -> current -> add_daughter($daughter);
			$self -> current -> name('$' . $name);
		}
		elsif ($ref =~ /^HASH/)
		{
			$self -> current -> name('%$' . $name);

			for my $key (sort keys %$item)
			{
				$current  = $self -> current;
				$daughter = Tree::DAG_Node -> new;

				$self -> current -> add_daughter($daughter);
				$self -> current($daughter);
				$self -> build_tree($key, $key);

				$daughter = Tree::DAG_Node -> new;

				$self -> current -> add_daughter($daughter);
				$self -> current($daughter);
				$self -> build_tree($key, $$item{$key});
				$self -> current($current);
			}
		}
		elsif ($ref =~ /^SCALAR/)
		{
			$self -> current -> name("\$ $item - Not used");
		}
		elsif ($ref)
		{
			$self -> current -> name("Object: $name");

			$current  = $self -> current;
			$daughter = Tree::DAG_Node -> new;

			$self -> current -> add_daughter($daughter);
			$self -> current($daughter);
			$self -> build_tree($item, $$item);
			$self -> current($current);
		}
		else
		{
			$self -> current -> name("$item - Not used");
		}
	}
	else
	{
		$self -> current -> name($item);
	}

	return $self;

} # End of build_tree.

# -----------------------------------------------

sub create
{
	my($self, %arg) = @_;
	my(%form) =
		(
		 '@' =>
		 {
			 color => 'brown',
			 shape => 'house',
		 },
		 '%' =>
		 {
			 color => 'blue',
			 shape => 'doubleoctagon',
		 },
		 '$' =>
		 {
			 color => 'black',
			 shape => 'box',
		 },
		 '&' =>
		 {
			 color => 'green',
			 shape => 'ellipse',
		 },
		);

	$self -> build_tree($arg{name} => $arg{thing});
	$self -> tree -> attributes({record => address($self -> tree -> address)});
	$self -> graph -> add_node(color => 'green', name => address($self -> tree -> address), label => $self -> tree -> name, shape => 'doubleoctagon');
	$self -> build_graph({$self -> tree -> address => 1}, $self -> tree);

	return $self;

}	# End of create.

# -----------------------------------------------

sub DESTROY
{
	my($self) = @_;

	$self -> tree -> delete_tree;

} # End of DESTROY.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Data::Grapher> - Visualize a data structure as a graph

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::Spec;

	use GraphViz2;
	use GraphViz2::Data::Grapher;

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

	my($sub) = sub{};
	my($s)   =
	{
		A =>
		{
			a =>
			{
			},
			bbbbbb => $sub,
			c123   => $sub,
			d      => \$sub,
		},
		C =>
		{
			b =>
			{
				a =>
				{
					a =>
					{
					},
					b => sub{},
					c => 42,
				},
			},
		},
		els => [qw(element_1 element_2 element_3)],
	};

	my($graph) = GraphViz2 -> new
		(
		 edge   => {color => 'grey'},
		 global => {directed => 1},
		 graph  => {rankdir => 'TB'},
		 logger => $logger,
		 node   => {color => 'blue', shape => 'oval'},
		);

	my($g)           = GraphViz2::Data::Grapher -> new(graph => $graph, logger => $logger);
	my($format)      = shift || 'svg';
	my($output_file) = shift || File::Spec -> catfile('html', "parse.data.$format");

	$g -> create(name => 's', thing => $s);
	$graph -> run(format => $format, output_file => $output_file);

	# If you did not provide a GraphViz2 object, do this
	# to get access to the auto-created GraphViz2 object.

	#$g -> create(name => 's', thing => $s);
	#$g -> graph -> run(format => $format, output_file => $output_file);

	# Or even

	#$g -> create(name => 's', thing => $s)
	#-> graph
	#-> run(format => $format, output_file => $output_file);

See scripts/parse.data.pl (L<GraphViz2/Scripts Shipped with this Module>).

=head1 Description

Takes a Perl data structure and recursively converts it into L<Tree::DAG_Node> object, and then graphs it.

You can write the result in any format supported by L<Graphviz|http://www.graphviz.org/>.

Here is the list of L<output formats|http://www.graphviz.org/content/output-formats>.

Within the graph:

=over 4

=item o Array names are preceeded by '@'

=item o Code references are preceeded by '&'

=item o Hash names are preceeded by '%'

=item o Scalar names are preceeded by '$'

=back

Hence, a hash ref will look like '%$h'.

Further, objects of different type have different shapes.

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

C<new()> is called as C<< my($obj) = GraphViz2::Data::Grapher -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Data::Grapher>.

Key-value pairs accepted in the parameter list:

=over 4

=item o graph => $graphviz_object

This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
except for the graph label of course.

This key is optional.

=item o logger => $logger_object

Provides a logger object so $logger_object -> $level($message) can be called at certain times.

Retrieve and update the value with the logger() method.

The default is ''.

At the moment, the logger object is not used. This feature is mainly used for testing.

=back

=head1 Methods

=head2 create(name => $name, thing => $thing)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to new().

Returns $self to allow method chaining.

$name is the string which will be placed in the root node of the tree.

If $s = {...}, say, use 's', not '$s', because '%$' will be prefixed automatically to the name,
because $s is a hashref.

$thing is the data stucture to graph.

=head2 graph()

Returns the graph object, either the one supplied to new() or the one created during the call to new().

=head2 tree()

Returns the tree object (of type L<Tree::DAG_Node>) built before it is traversed to generate the nodes and edges.

Traversal does change the attributes of nodes, by storing {record => $string} there, so that
edges can be plotted from a parent to its daughters.

Warning: As the L<GraphViz2::Data::Grapher> object exits its scope, $self -> tree -> delete_tree is called.

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
