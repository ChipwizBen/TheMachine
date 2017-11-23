package GraphViz2::Parse::Regexp;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Capture::Tiny 'capture';

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
	my($self, %arg)      = @_;
	my($regexp)          = $arg{regexp};
	my($stdout, $stderr) = capture{system $^X, '-e', qq|use re 'debug'; qr/$regexp/;|};

    my(%following);
    my($last_id);
    my(%states);

    for my $line ( split /\n/, $stderr ) {
        next unless my ( $id, $state ) = $line =~ /(\d+):\s+(.+)$/;
        $states{$id}         = $state;
        $following{$last_id} = $id if $last_id;
        $last_id             = $id;
    }

    my %done;
    my @todo = (1);

    if ( not defined $last_id ) {
        $self -> graph ->add_node(name => 'Error compiling regexp');
        return $self;
    }

    while (@todo) {
        my $id = pop @todo;
        next unless $id;
        next if $done{$id}++;
        my $state     = $states{$id};
        my $following = $following{$id};
        my ($next) = $state =~ /\((\d+)\)$/;

        push @todo, $following;
        push @todo, $next if $next;

        my $match;

        if ( ($match) = $state =~ /^EXACTF?L? <(.+)>/ ) {
            $self -> graph ->add_node( name => $id, label => $match, shape => 'box' );
            $self -> graph ->add_edge( from => $id, to => $next ) if $next != 0;
            $done{$following}++ unless $next;
        } elsif ( ($match) = $state =~ /^ANYOF\[(.+)\]/ ) {
            $self -> graph ->add_node( name => $id, label => '[' . $match . ']', shape => 'box' );
            $self -> graph ->add_edge( from => $id, to => $next ) if $next != 0;
            $done{$following}++ unless $next;
        } elsif ( ($match) = $state =~ /^OPEN(\d+)/ ) {
            $self -> graph ->add_node( name => $id, label => 'START \$' . $match );
            $self -> graph ->add_edge( from => $id, to => $following );
        } elsif ( ($match) = $state =~ /^CLOSE(\d+)/ ) {
            $self -> graph ->add_node( name => $id, label => 'END \$' . $match );
            $self -> graph ->add_edge( from => $id, to => $next );
        } elsif ( $state =~ /^END/ ) {
            $self -> graph ->add_node( name => $id, label => 'END' );
        } elsif ( $state =~ /^BRANCH/ ) {
            my $branch = $next;
            my @children;
            push @children, $following;
            while ($branch && $states{$branch} =~ /^BRANCH|TAIL/ ) {
                $done{$branch}++;
                push @children, $following{$branch};
                ($branch) = $states{$branch} =~ /(\d+)/;
            }
            $self -> graph ->add_node( name => $id, label => '', shape => 'diamond' );
            foreach my $child (@children) {
                push @todo, $child;
                $self -> graph ->add_edge( from => $id, to => $child );
            }
        } elsif ( my ($repetition) = $state =~ /^(PLUS|STAR)/ ) {
            my $label = '?';
            if ( $repetition eq 'PLUS' ) {
                $label = '+';
            } elsif ( $repetition eq 'STAR' ) {
                $label = '*';
            }
            $self -> graph ->add_node( name => $id, label => 'REPEAT' );
            $self -> graph ->add_edge( from => $id, to => $id,   label => $label );
            $self -> graph ->add_edge( from => $id, to => $following );
            $self -> graph ->add_edge( from => $id, to => $next, style => 'dashed' );
        } elsif ( my ( $type, $min, $max )
            = $state =~ /^CURLY([NMX]?)\[?\d*\]? \{(\d+),(\d+)\}/ )
        {
            $self -> graph ->add_node( name => $id, label => 'REPEAT' );
            $self -> graph ->add_edge(
                from => $id, to   => $id,
                label => '{' . $min . ", " . $max . '}'
            );
            $self -> graph ->add_edge( from => $id, to => $following );
            $self -> graph ->add_edge( from => $id, to => $next, style => 'dashed' );
        } elsif ( $state =~ /^BOL/ ) {
            $self -> graph ->add_node( name => $id, label => '^' );
            $self -> graph ->add_edge( from => $id, to => $next );
        } elsif ( $state =~ /^EOL/ ) {
            $self -> graph ->add_node( name => $id, label => "\$" );
            $self -> graph ->add_edge( from => $id, to => $next );
        } elsif ( $state =~ /^NOTHING/ ) {
            $self -> graph ->add_node( name => $id, label => 'Match empty string' );
            $self -> graph ->add_edge( from => $id, to => $next );
        } elsif ( $state =~ /^MINMOD/ ) {
            $self -> graph ->add_node( name => $id, label => 'Next operator\nnon-greedy' );
            $self -> graph ->add_edge( from => $id, to => $next );
        } elsif ( $state =~ /^SUCCEED/ ) {
            $self -> graph ->add_node( name => $id, label => 'SUCCEED' );
            $done{$following}++;
        } elsif ( $state =~ /^UNLESSM/ ) {
            $self -> graph ->add_node( name => $id, label => 'UNLESS' );
            $self -> graph ->add_edge( from => $id, to => $following );
            $self -> graph ->add_edge( from => $id, to => $next, style => 'dashed' );
        } elsif ( $state =~ /^IFMATCH/ ) {
            $self -> graph ->add_node( name => $id, label => 'IFMATCH' );
            $self -> graph ->add_edge( from => $id, to => $following );
            $self -> graph ->add_edge( from => $id, to => $next, style => 'dashed' );
        } elsif ( $state =~ /^IFTHEN/ ) {
            $self -> graph ->add_node( name => $id, label => 'IFTHEN' );
            $self -> graph ->add_edge( from => $id, to => $following );
            $self -> graph ->add_edge( from => $id, to => $next, style => 'dashed' );
        } elsif ( $state =~ /^([A-Z_0-9]+)/ ) {
            my ($state) = ( $1, $2 );
            $self -> graph ->add_node( name => $id, label => $state );
            $self -> graph ->add_edge( from => $id, to => $next ) if $next != 0;
        } else {
            $self -> graph ->add_node( name => $id, label => $state );
        }
    }

	return $self;

}	# End of create.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Parse::Regexp> - Visualize a Perl regular expression as a graph

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::Spec;

	use GraphViz2;
	use GraphViz2::Parse::Regexp;

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
		 graph  => {rankdir => 'TB'},
		 logger => $logger,
		 node   => {color => 'blue', shape => 'oval'},
		);
	my($g) = GraphViz2::Parse::Regexp -> new(graph => $graph);

	$g -> create(regexp => '(([abcd0-9])|(foo))');

	my($format)      = shift || 'svg';
	my($output_file) = shift || File::Spec -> catfile('html', "parse.regexp.$format");

	$graph -> run(format => $format, output_file => $output_file);

See scripts/parse.regexp.pl (L<GraphViz2/Scripts Shipped with this Module>).

=head1 Description

Takes a Perl regular expression and converts it into a graph.

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

C<new()> is called as C<< my($obj) = GraphViz2::Parse::Regexp -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Parse::Regexp>.

Key-value pairs accepted in the parameter list:

=over 4

=item o graph => $graphviz_object

This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
except for the logger of course, which defaults to ''.

This key is optional.

=back

=head1 Methods

=head2 create(regexp => $regexp)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to new().

Returns $self for method chaining.

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
