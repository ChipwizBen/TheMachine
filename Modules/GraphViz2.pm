package GraphViz2;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Capture::Tiny 'capture';

use Data::Section::Simple 'get_data_section';

use File::Basename;	# For fileparse().
use File::Temp;		# For newdir().
use File::Which;	# For which().

use Moo;

use IPC::Run3; # For run3().

use Set::Array;

use Try::Tiny;

use Types::Standard qw/Any HashRef Int Str/;

has command =>
(
	default  => sub{return Set::Array -> new},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has dot_input =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has dot_output =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has edge =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has edge_hash =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has global =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has graph =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has im_meta =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has logger =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has node =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has node_hash =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has scope =>
(
	default  => sub{return Set::Array -> new},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has subgraph =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has verbose =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has valid_attributes =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

our $VERSION = '2.46';

# -----------------------------------------------

sub BUILD
{
	my($self)    = @_;
	my($globals) = $self -> global;
	my($dot)     = which('dot');
	#my($dot) = '/usr/bin/dot';
	my($global)  =
	{
		directed		=> $$globals{directed}			? 'digraph'				: 'graph',
		driver			=> $$globals{driver}			? $$globals{driver}		: $dot,
		format			=> $$globals{format}			? $$globals{format}		: 'svg',
		im_format		=> $$globals{im_format}			? $$globals{im_format}	: 'cmapx',
		label			=> $$globals{directed}			? '->'					: '--',
		name			=> defined($$globals{name})		? $$globals{name}		: 'Perl',
		record_shape	=> ($$globals{record_shape} && $$globals{record_shape} =~ /^(M?record)$/) ? $1 : 'Mrecord',
		strict			=> defined($$globals{strict})	? $$globals{strict}		:  0,
		subgraph		=> $$globals{subgraph}			? $$globals{subgraph}	: {},
		timeout			=> defined($$globals{timeout})	? $$globals{timeout}	: 10,
	};
	my($im_metas)	= $self -> im_meta;
	my($im_meta)	=
	{
		URL => $$im_metas{URL} ? $$im_metas{URL} : '',
	};

	$self -> global($global);
	$self -> im_meta($im_meta);
	$self -> load_valid_attributes;
	$self -> validate_params('global',		%{$self -> global});
	$self -> validate_params('graph',		%{$self -> graph});
	$self -> validate_params('im_meta',		%{$self -> im_meta});
	$self -> validate_params('node',		%{$self -> node});
	$self -> validate_params('edge',		%{$self -> edge});
	$self -> validate_params('subgraph',	%{$self -> subgraph});
	$self -> scope -> push
		({
			edge     => $self -> edge,
			graph    => $self -> graph,
			node     => $self -> node,
			subgraph => $self -> subgraph,
		 });

	my(%global)		= %{$self -> global};
	my(%im_meta)	= %{$self -> im_meta};

	$self -> log(debug => "Default global:  $_ => $global{$_}")	for sort keys %global;
	$self -> log(debug => "Default im_meta: $_ => $im_meta{$_}")	for grep{$im_meta{$_} } sort keys %im_meta;

	my($command) = (${$self -> global}{strict} ? 'strict ' : '')
		. (${$self -> global}{directed} . ' ')
		. ${$self -> global}{name}
		. "\n{\n";

	for my $key (grep{$im_meta{$_} } sort keys %im_meta)
	{
		$command .= qq|$key = "$im_meta{$key}"; \n|;
	}

	$self -> command -> push($command);

	$self -> default_graph;
	$self -> default_node;
	$self -> default_edge;

} # End of BUILD.

# -----------------------------------------------

sub add_edge
{
	my($self, %arg) = @_;
	my($from)   = delete $arg{from};
	$from       = defined($from) ? $from : '';
	my($to)     = delete $arg{to};
	$to         = defined($to) ? $to : '';
	my($label)  = defined($arg{label}) ? $arg{label} : '';
	$label      =~ s/^\s+(<)/$1/;
	$label      =~ s/(>)\s+$/$1/;
	$label      =~ s/^(<)\n/$1/;
	$label      =~ s/\n(>)$/$1/;
	$arg{label} = $label if (defined $arg{label});

	$self -> validate_params('edge', %arg);

	# If either 'from' or 'to' is unknown, add a new node.

	my($new)  = 0;
	my($node) = $self -> node_hash;

	my(@node);

	for my $name ($from, $to)
	{
		# Remove :port:compass, if any, from name.
		# But beware Perl-style node names like 'A::Class'.

		my(@field) = split(/(:(?!:))/, $name);
		$field[0]  = $name if ($#field < 0);

		# Restore Perl module names:
		# o A: & B to A::B.
		# o A: & B: & C to A::B::C.

		while ($field[0] =~ /:$/)
		{
			splice(@field, 0, 3, "$field[0]:$field[2]");
		}

		# Restore:
		# o : & port to :port.
		# o : & port & : & compass to :port:compass.

		splice(@field, 1, $#field, join('', @field[1 .. $#field]) ) if ($#field > 0);

		# This line is mandatory - It overwrites $from and $to for use after the loop.

		$name     = $field[0];
		$field[1] = '' if ($#field == 0);

		push @node, [$name, $field[1] ];

		if (! defined $$node{$name})
		{
			$new = 1;

			$self -> add_node(name => $name);
		}
	}

	# Add these nodes to the hashref of all nodes, if necessary.

	$self -> node_hash($node) if ($new);

	# Add this edge to the hashref of all edges.

	my($edge)          = $self -> edge_hash;
	$$edge{$from}      = {} if (! $$edge{$from});
	$$edge{$from}{$to} = [] if (! $$edge{$from}{$to});

	push @{$$edge{$from}{$to} },
	{
		attributes => {%arg},
		from_port  => $node[0][1],
		to_port    => $node[1][1],
	};

	$self -> edge_hash($edge);

	# Add this edge to the DOT output string.

	my($dot) = $self -> stringify_attributes(qq|"$from"$node[0][1] ${$self -> global}{label} "$to"$node[1][1]|, {%arg});

	$self -> command -> push($dot);
	$self -> log(debug => "Added edge: $dot");

	return $self;

} # End of add_edge.

# -----------------------------------------------

sub add_node
{
	my($self, %arg) = @_;
	my($name) = delete $arg{name};
	$name     = defined($name) ? $name : '';

	$self -> validate_params('node', %arg);

	my($node)                 = $self -> node_hash;
	$$node{$name}             = {} if (! $$node{$name});
	$$node{$name}{attributes} = {} if (! $$node{$name}{attributes});
	$$node{$name}{attributes} = {%{$$node{$name}{attributes} }, %arg};
	%arg                      = %{$$node{$name}{attributes} };
	my($label)                = defined($arg{label}) ? $arg{label} : '';
	$label                    =~ s/^\s+(<)/$1/;
	$label                    =~ s/(>)\s+$/$1/;
	$label                    =~ s/^(<)\n/$1/;
	$label                    =~ s/\n(>)$/$1/;
	$arg{label}               = $label if (defined $arg{label});

	# Handle ports.

	if (ref $label eq 'ARRAY')
	{
		my($port_count) = 0;

		my(@label);
		my($port);
		my($text);

		for my $index (0 .. scalar @$label - 1)
		{
			if (ref $$label[$index] eq 'HASH')
			{
				$port = $$label[$index]{port} || 0;
				$text = $$label[$index]{text} || '';
			}
			else
			{
				$port_count++;

				$port = "<port$port_count>";
				$text = $$label[$index];
			}

			$text = $self -> escape_some_chars($text);

			if (ref $$label[$index] eq 'HASH')
			{
				push @label, $port ? "$port $text" : $text;
			}
			else
			{
				push @label, "$port $text";
			}
		}

		$arg{label} = join('|', @label);
		my(%global) = %{$self -> global};
		$arg{shape} = $arg{shape} || $global{record_shape};
	}
	elsif ($arg{shape} && ( ($arg{shape} =~ /M?record/) || ( ($arg{shape} =~ /(?:none|plaintext)/) && ($label =~ /^</) ) ) )
	{
		# Do not escape anything.
	}
	elsif ($label)
	{
		$arg{label} = $self -> escape_some_chars($arg{label});
	}

	$$node{$name}{attributes} = {%arg};
	my($dot)                  = $self -> stringify_attributes(qq|"$name"|, {%arg});

	$self -> command -> push($dot);
	$self -> node_hash($node);
	$self -> log(debug => "Added node: $dot");

	return $self;

} # End of add_node.

# -----------------------------------------------

sub default_edge
{
	my($self, %arg) = @_;

	$self -> validate_params('edge', %arg);

	my($scope)    = $self -> scope -> last;
	$$scope{edge} = {%{$$scope{edge} }, %arg};
	my($tos)      = $self -> scope -> length - 1;

	$self -> command -> push($self -> stringify_attributes('edge', $$scope{edge}) );
	$self -> scope -> fill($scope, $tos, 1);
	$self -> log(debug => 'Default edge: ' . join(', ', map{"$_ => $$scope{edge}{$_}"} sort keys %{$$scope{edge} }) );

	return $self;

} # End of default_edge.

# -----------------------------------------------

sub default_graph
{
	my($self, %arg) = @_;

	$self -> validate_params('graph', %arg);

	my($scope)     = $self -> scope -> last;
	$$scope{graph} = {%{$$scope{graph} }, %arg};
	my($tos)       = $self -> scope -> length - 1;

	$self -> command -> push($self -> stringify_attributes('graph', $$scope{graph}) );
	$self -> scope -> fill($scope, $tos, 1);
	$self -> log(debug => 'Default graph: ' . join(', ', map{"$_ => $$scope{graph}{$_}"} sort keys %{$$scope{graph} }) );

	return $self;

} # End of default_graph.

# -----------------------------------------------

sub default_node
{
	my($self, %arg) = @_;

	$self -> validate_params('node', %arg);

	my($scope)    = $self -> scope -> last;
	$$scope{node} = {%{$$scope{node} }, %arg};
	my($tos)      = $self -> scope -> length - 1;

	$self -> command -> push($self -> stringify_attributes('node', $$scope{node}) );
	$self -> scope -> fill($scope, $tos, 1);
	$self -> log(debug => 'Default node: ' . join(', ', map{"$_ => $$scope{node}{$_}"} sort keys %{$$scope{node} }) );

	return $self;

} # End of default_node.

# -----------------------------------------------

sub default_subgraph
{
	my($self, %arg) = @_;

	$self -> validate_params('subgraph', %arg);

	my($scope)        = $self -> scope -> last;
	$$scope{subgraph} = {%{$$scope{subgraph} }, %arg};
	my($tos)          = $self -> scope -> length - 1;

	$self -> command -> push($self -> stringify_attributes('subgraph', $$scope{subgraph}) );
	$self -> scope -> fill($scope, $tos, 1);
	$self -> log(debug => 'Default subgraph: ' . join(', ', map{"$_ => $$scope{subgraph}{$_}"} sort keys %{$$scope{subgraph} }) );

	return $self;

} # End of default_subgraph.

# -----------------------------------------------

sub dependency
{
	my($self, %arg) = @_;
	my($data) = delete $arg{data} || die 'Error: No dependency data provided';
	my(@item) = sort{$a -> id cmp $b -> id} $data -> source -> items;

	for my $item (@item)
	{
		$self -> add_node(name => $item -> id);
	}

	for my $from (@item)
	{
		for my $to ($from -> depends)
		{
			$self -> add_edge(from => $from -> id, to => $to);
		}
	}

	return $self;

} # End of dependency.

# -----------------------------------------------

sub escape_some_chars
{
	my($self, $s) = @_;
	my(@s)        = split(//, $s);
	my($label)    = '';

	for my $i (0 .. $#s)
	{
		if ( ($s[$i] eq '[') || ($s[$i] eq ']') )
		{
			# Escape if not escaped.

			if ( ($i == 0) || ( ($i > 0) && ($s[$i - 1] ne '\\') ) )
			{
				$label .= '\\';
			}
		}
		elsif ($s[$i] eq '"')
		{
			if (substr($s, 0, 1) ne '<')
			{
				# It's not a HTML label. Escape if not escaped.

				if ( ($i == 0) || ( ($i > 0) && ($s[$i - 1] ne '\\') ) )
				{
					$label .= '\\';
				}
			}
		}

		$label .= $s[$i];
	}

	return $label;

} # End of escape_some_chars.

# -----------------------------------------------

sub load_valid_attributes
{
	my($self) = @_;

	# Phase 1: Get attributes from __DATA__ section.

	my($data) = get_data_section;

	my(%data);

	for my $key (sort keys %$data)
	{
		$data{$key} = [grep{! /^$/ && ! /^(?:\s*)#/} split(/\n/, $$data{$key})];
	}

	# Phase 2: Reorder them so the major key is the context and the minor key is the attribute.
	# I.e. $attribute{global}{directed} => 1 means directed is valid in a global context.

	my(%attribute);

	for my $context (grep{! /common_attribute/} keys %$data)
	{
		for my $a (@{$data{$context} })
		{
			$attribute{$context}{$a} = 1;
		}
	}

	# Common attributes are a special case, since one attribute can be valid is several contexts...
	# Format: attribute_name => context_1, context_2.

	my($attribute);
	my($context, @context);

	for my $a (@{$data{common_attribute} })
	{
		($attribute, $context) = split(/\s*=>\s*/, $a);
		@context               = split(/\s*,\s*/, $context);

		for my $c (@context)
		{
			$attribute{$c}             = {} if (! $attribute{$c});
			$attribute{$c}{$attribute} = 1;
		}
	}

	# Since V 2.24, output formats are no longer read from the __DATA__ section.
	# Rather, they are extracted from the stderr output of 'dot -T?'.

	my($stdout, $stderr)			= capture{system 'dot', '-T?'};
	my(@field)						= split(/one of:\s+/, $stderr);
	$attribute{output_format}{$_}	= 1 for split(/\s+/, $field[1]);

	$self -> valid_attributes(\%attribute);

	return $self;

} # End of load_valid_attributes.

# -----------------------------------------------

sub log
{
	my($self, $level, $message) = @_;
	$level   ||= 'debug';
	$message ||= '';

	if ($level eq 'error')
	{
		die $message;
	}

	if ($self -> logger)
	{
		$self -> logger -> $level($message);
	}
	elsif ($self -> verbose)
	{
		print "$level: $message\n";
	}

	return $self;

} # End of log.

# -----------------------------------------------

sub pop_subgraph
{
	my($self) = @_;

	$self -> command -> push("}\n");
	$self -> scope -> pop;

	return $self;

}	# End of pop_subgraph.

# -----------------------------------------------

sub push_subgraph
{
	my($self, %arg) = @_;
	my($name) = delete $arg{name};
	$name     = defined($name) && length($name) ? qq|"$name"| : '';

	$self -> validate_params('graph',    %{$arg{graph} });
	$self -> validate_params('node',     %{$arg{node} });
	$self -> validate_params('edge',     %{$arg{edge} });
	$self -> validate_params('subgraph', %{$arg{subgraph} });

	# Child inherits parent attributes.

	my($scope)        = $self -> scope -> last;
	$$scope{edge}     = {%{$$scope{edge} },     %{$arg{edge} } };
	$$scope{graph}    = {%{$$scope{graph} },    %{$arg{graph} } };
	$$scope{node}     = {%{$$scope{node} },     %{$arg{node} } };
	$$scope{subgraph} = {%{$$scope{subgraph} }, %{$arg{subgraph} } };

	$self -> scope -> push($scope);
	$self -> command -> push(qq|\nsubgraph $name\n{\n|);
	$self -> default_graph;
	$self -> default_node;
	$self -> default_edge;
	$self -> default_subgraph;

	return $self;

}	# End of push_subgraph.

# -----------------------------------------------

sub report_valid_attributes
{
	my($self)       = @_;
	my($attributes) = $self -> valid_attributes;

	$self -> log(info => 'Global attributes:');

	for my $a (sort keys %{$$attributes{global} })
	{
		$self -> log(info => $a);
	}

	$self -> log;
	$self -> log(info => 'Graph attributes:');

	for my $a (sort keys %{$$attributes{graph} })
	{
		$self -> log(info => $a);
	}

	$self -> log;
	$self -> log(info => 'Cluster attributes:');

	for my $n (sort keys %{$$attributes{cluster} })
	{
		$self -> log(info => $n);
	}

	$self -> log;
	$self -> log(info => 'Subgraph attributes:');

	for my $n (sort keys %{$$attributes{subgraph} })
	{
		$self -> log(info => $n);
	}

	$self -> log;
	$self -> log(info => 'Node attributes:');

	for my $n (sort keys %{$$attributes{node} })
	{
		$self -> log(info => $n);
	}

	$self -> log;
	$self -> log(info => 'Arrow modifiers:');

	for my $a (sort keys %{$$attributes{arrow_modifier} })
	{
		$self -> log(info => $a);
	}

	$self -> log;
	$self -> log(info => 'Arrow attributes:');

	for my $a (sort keys %{$$attributes{arrow} })
	{
		$self -> log(info => $a);
	}

	$self -> log;
	$self -> log(info => 'Edge attributes:');

	for my $a (sort keys %{$$attributes{edge} })
	{
		$self -> log(info => $a);
	}

	$self -> log;
	$self -> log(info => 'Output formats:');

	for my $a (sort keys %{$$attributes{output_format} })
	{
		$self -> log(info => $a);
	}

	$self -> log(info => 'Output formats for the form png:gd etc are also supported');
	$self -> log;

} # End of report_valid_attributes.

# -----------------------------------------------

sub run
{
	my($self, %arg)		= @_;
	my($driver)			= delete $arg{driver}			|| ${$self -> global}{driver};
	my($format)			= delete $arg{format}			|| ${$self -> global}{format};
	my($im_format)		= delete $arg{im_format}		|| ${$self -> global}{im_format};
	my($timeout)		= delete $arg{timeout}			|| ${$self -> global}{timeout};
	my($output_file)	= delete $arg{output_file}		|| '';
	my($im_output_file)	= delete $arg{im_output_file}	|| '';
	my($prefix)			= $format;
	$prefix				=~ s/:.+$//; # In case of 'png:gd', etc.
	%arg				= ($prefix => 1);

	$self -> validate_params('output_format', %arg);

	my($prefix_1)	= $im_format;
	$prefix_1		=~ s/:.+$//; # In case of 'png:gd', etc.
	%arg			= ($prefix_1 => 1);

	$self -> validate_params('output_format', %arg);
	$self -> dot_input(join('', @{$self -> command -> print}) . "}\n");
	$self -> log(debug => $self -> dot_input);

	# Warning: Do not use $im_format in this 'if', because it has a default value.

	if ($im_output_file)
	{
		return $self -> run_map($driver, $output_file, $format, $timeout, $im_output_file, $im_format);
	}
	else
	{
		return $self -> run_mapless($driver, $output_file, $format, $timeout);
	}

} # End of run.

# -----------------------------------------------

sub run_map
{
	my($self, $driver, $output_file, $format, $timeout, $im_output_file, $im_format) = @_;

	$self -> log(debug => "Driver: $driver. Output file: $output_file. Format: $format. IM output file: $im_output_file. IM format: $im_format. Timeout: $timeout second(s)");
	$self -> log;

	my($result);

	try
	{
		# The EXLOCK option is for BSD-based systems.

		my($temp_dir)	= File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
		my($temp_file)	= File::Spec -> catfile($temp_dir, 'temp.gv');

		open(my $fh, '> :raw', $temp_file) || die "Can't open(> $temp_file): $!";
		print $fh $self -> dot_input;
		close $fh;

		my(@args) = ("-T$im_format", "-o$im_output_file", "-T$format", "-o$output_file", $temp_file);

		system($driver, @args);
	}
	catch
	{
		$result = $_;
	};

	die $result if ($result);

	return $self;

} # End of run_map.

# -----------------------------------------------

sub run_mapless
{
	my($self, $driver, $output_file, $format, $timeout) = @_;

	$self -> log(debug => "Driver: $driver. Output file: $output_file. Format: $format. Timeout: $timeout second(s)");
	$self -> log;

	my($result);

	try
	{
		my($stdout, $stderr);

		# Usage of utf8 here relies on ISO-8859-1 matching Unicode for low chars.
		# It saves me the effort of determining if the input contains Unicode.


		run3
			[$driver, "-T$format"],
			\$self -> dot_input,
			\$stdout,
			\$stderr,
			{
				binmode_stdin  => ':utf8',
				binmode_stdout => ':raw',
				binmode_stderr => ':raw',
			};

		die $stderr if ($stderr);

		$self -> dot_output($stdout);

		if ($output_file)
		{
			open(my $fh, '> :raw', $output_file) || die "Can't open(> $output_file): $!";
			print $fh $stdout;
			close $fh;

			$self -> log(debug => "Wrote $output_file. Size: " . length($stdout) . ' bytes');
		}
	}
	catch
	{
		$result = $_;
	};

	die $result if ($result);

	return $self;

} # End of run_mapless.

# -----------------------------------------------

sub stringify_attributes
{
	my($self, $context, $option) = @_;
	my($dot) = '';

	# Add double-quotes around anything (e.g. labels) which does not look like HTML.

	for my $key (sort keys %$option)
	{
		$$option{$key} = '' if (! defined $$option{$key});
		$$option{$key} =~ s/^\s+(<)/$1/;
		$$option{$key} =~ s/(>)\s+$/$1/;
		$dot           .= ($$option{$key} =~ /^<.+>$/s) ? qq|$key=$$option{$key} | : qq|$key="$$option{$key}" |;
	}

	if ($context eq 'subgraph')
	{
		$dot .= "\n";
	}
	elsif ($dot)
	{
		$dot = "$context [ $dot]\n";
	}
	else
	{
		$dot = $context =~ /^(?:edge|graph|node)/ ? '' : "$context\n";
	}

	return $dot;

} # End of stringify_attributes.

# -----------------------------------------------

sub validate_params
{
	my($self, $context, %attributes) = @_;
	my(%attr) = %{$self -> valid_attributes};

	for my $a (sort keys %attributes)
	{
		next if ($attr{$context}{$a} || ( ($context eq 'subgraph') && $attr{cluster}{$a}) );

		$self -> log(error => "Error: '$a' is not a valid attribute in the '$context' context");
	}

	return $self;

} # End of validate_params.

# -----------------------------------------------

1;

=pod

=head1 NAME

GraphViz2 - A wrapper for AT&T's Graphviz

=head1 Synopsis

=head2 Sample output

Unpack the distro and copy html/*.html and html/*.svg to your web server's doc root directory.

Then, point your browser at 127.0.0.1/index.html.

Or, hit L<the demo page|http://savage.net.au/Perl-modules/html/graphviz2/index.html>.

=head2 Perl code

=head3 Typical Usage

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::Spec;

	use GraphViz2;

	use Log::Handler;

	# ---------------

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
		 graph  => {label => 'Adult', rankdir => 'TB'},
		 logger => $logger,
		 node   => {shape => 'oval'},
		);

	$graph -> add_node(name => 'Carnegie', shape => 'circle');
	$graph -> add_node(name => 'Murrumbeena', shape => 'box', color => 'green');
	$graph -> add_node(name => 'Oakleigh',    color => 'blue');

	$graph -> add_edge(from => 'Murrumbeena', to    => 'Carnegie', arrowsize => 2);
	$graph -> add_edge(from => 'Murrumbeena', to    => 'Oakleigh', color => 'brown');

	$graph -> push_subgraph
	(
	 name  => 'cluster_1',
	 graph => {label => 'Child'},
	 node  => {color => 'magenta', shape => 'diamond'},
	);

	$graph -> add_node(name => 'Chadstone', shape => 'hexagon');
	$graph -> add_node(name => 'Waverley', color => 'orange');

	$graph -> add_edge(from => 'Chadstone', to => 'Waverley');

	$graph -> pop_subgraph;

	$graph -> default_node(color => 'cyan');

	$graph -> add_node(name => 'Malvern');
	$graph -> add_node(name => 'Prahran', shape => 'trapezium');

	$graph -> add_edge(from => 'Malvern', to => 'Prahran');
	$graph -> add_edge(from => 'Malvern', to => 'Murrumbeena');

	my($format)      = shift || 'svg';
	my($output_file) = shift || File::Spec -> catfile('html', "sub.graph.$format");

	$graph -> run(format => $format, output_file => $output_file);

This program ships as scripts/sub.graph.pl. See L</Scripts Shipped with this Module>.

=head3 Image Maps Usage

As of V 2.43, C<GraphViz2> supports image maps, both client and server side.

See L</Image Maps> below.

=head1 Description

=head2 Overview

This module provides a Perl interface to the amazing L<Graphviz|http://www.graphviz.org/>, an open source graph visualization tool from AT&T.

It is called GraphViz2 so that pre-existing code using (the Perl module) GraphViz continues to work.

To avoid confusion, when I use L<GraphViz2> (note the capital V), I'm referring to this Perl module, and
when I use L<Graphviz|http://www.graphviz.org/> (lower-case v) I'm referring to the underlying tool (which is in fact a set of programs).

Version 1.00 of L<GraphViz2> is a complete re-write, by Ron Savage, of GraphViz V 2, which was written by Leon Brocard. The point of the re-write
is to provide access to all the latest options available to users of L<Graphviz|http://www.graphviz.org/>.

GraphViz2 V 1 is not backwards compatible with GraphViz V 2, despite the considerable similarity. It was not possible to maintain compatibility
while extending support to all the latest features of L<Graphviz|http://www.graphviz.org/>.

To ensure L<GraphViz2> is a light-weight module, L<Moo> has been used to provide getters and setters,
rather than L<Moose>.

As of V 2.43, C<GraphViz2> supports image maps, both client and server side.

See L</Image Maps> below.

=head2 What is a Graph?

An undirected graph is a collection of nodes optionally linked together with edges.

A directed graph is the same, except that the edges have a direction, normally indicated by an arrow head.

A quick inspection of L<Graphviz|http://www.graphviz.org/>'s L<gallery|http://www.graphviz.org/Gallery.php> will show better than words
just how good L<Graphviz|http://www.graphviz.org/> is, and will reinforce the point that humans are very visual creatures.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Of course you need to install AT&T's Graphviz before using this module.
See L<http://www.graphviz.org/Download.php>.

You are strongly advised to download the stable version of Graphviz, because the
development snapshots (click on 'Source code'), are sometimes non-functional.

Install L<GraphViz2> as you would for any C<Perl> module:

Run:

	cpanm GraphViz2

	Note: cpanm ships in App::cpanminus. See also App::perlbrew.

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

C<new()> is called as C<< my($obj) = GraphViz2 -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2>.

Key-value pairs accepted in the parameter list:

=over 4

=item o edge => $hashref

The I<edge> key points to a hashref which is used to set default attributes for edges.

Hence, allowable keys and values within that hashref are anything supported by L<Graphviz|http://www.graphviz.org/>.

The default is {}.

This key is optional.

=item o global => $hashref

The I<global> key points to a hashref which is used to set attributes for the output stream.

Valid keys within this hashref are:

=over 4

=item o directed => $Boolean

This option affects the content of the output stream.

directed => 1 outputs 'digraph name {...}', while directed => 0 outputs 'graph name {...}'.

At the Perl level, directed graphs have edges with arrow heads, such as '->', while undirected graphs have
unadorned edges, such as '--'.

The default is 0.

This key is optional.

=item o driver => $program_name

This option specifies which external program to run to process the output stream.

The default is to use L<File::Which>'s which() method to find the 'dot' program.

This key is optional.

=item o format => $string

This option specifies what type of output file to create.

The default is 'svg'.

Output formats of the form 'png:gd' etc are also supported, but only the component before
the first ':' is validated by L<GraphViz2>.

This key is optional.

=item o label => $string

This option specifies what an edge looks like: '->' for directed graphs and '--' for undirected graphs.

You wouldn't normally need to use this option.

The default is '->' if directed is 1, and '--' if directed is 0.

This key is optional.

=item o name => $string

This option affects the content of the output stream.

name => 'G666' outputs 'digraph G666 {...}'.

The default is 'Perl' :-).

This key is optional.

=item o record_shape => /^(?:M?record)$/

This option affects the shape of records. The value must be 'Mrecord' or 'record'.

Mrecords have nice, rounded corners, whereas plain old records have square corners.

The default is 'Mrecord'.

See L<Record shapes|http://www.graphviz.org/content/node-shapes#record> for details.

=item o strict => $Boolean

This option affects the content of the output stream.

strict => 1 outputs 'strict digraph name {...}', while strict => 0 outputs 'digraph name {...}'.

The default is 0.

This key is optional.

=item o subgraph => $hashref

The I<subgraph> key points to a hashref which is used to set attributes for all subgraphs, unless overridden
for specific subgraphs in a call of the form push_subgraph(subgraph => {$attribute => $string}).

Valid keys within this hashref are:

=over 4

=item o rank => $string

This option affects the content of all subgraphs, unless overridden later.

A typical usage would be new(subgraph => {rank => 'same'}) so that all nodes mentioned within each subgraph
are constrained to be horizontally aligned.

See scripts/rank.sub.graph.[12].pl for sample code.

Possible values for $string are: max, min, same, sink and source.

See the L<Graphviz 'rank' docs|http://www.graphviz.org/content/attrs#drank> for details.

=back

The default is {}.

This key is optional.

=item o timeout => $integer

This option specifies how long to wait for the external program before exiting with an error.

The default is 10 (seconds).

This key is optional.

=back

This key (global) is optional.

=item o graph => $hashref

The I<graph> key points to a hashref which is used to set default attributes for graphs.

Hence, allowable keys and values within that hashref are anything supported by L<Graphviz|http://www.graphviz.org/>.

The default is {}.

This key is optional.

=item o logger => $logger_object

Provides a logger object so $logger_object -> $level($message) can be called at certain times.

See "Why such a different approach to logging?" in the </FAQ> for details.

Retrieve and update the value with the logger() method.

The default is ''.

See also the verbose option, which can interact with the logger option.

This key is optional.

=item o node => $hashref

The I<node> key points to a hashref which is used to set default attributes for nodes.

Hence, allowable keys and values within that hashref are anything supported by L<Graphviz|http://www.graphviz.org/>.

The default is {}.

This key is optional.

=item o verbose => $Boolean

Provides a way to control the amount of output when a logger is not specified.

Setting verbose to 0 means print nothing.

Setting verbose to 1 means print the log level and the message to STDOUT, when a logger is not specified.

Retrieve and update the value with the verbose() method.

The default is 0.

See also the logger option, which can interact with the verbose option.

This key is optional.

=back

=head2 Validating Parameters

The secondary keys (under the primary keys 'edge|graph|node') are checked against lists of valid attributes (stored at the end of this
module, after the __DATA__ token, and made available using L<Data::Section::Simple>).

This mechanism has the effect of hard-coding L<Graphviz|http://www.graphviz.org/> options in the source code of L<GraphViz2>.

Nevertheless, the implementation of these lists is handled differently from the way it was done in V 2.

V 2 ships with a set of scripts, scripts/extract.*.pl, which retrieve pages from the
L<Graphviz|http://www.graphviz.org/> web site and extract the current lists of valid attributes.

These are then copied manually into the source code of L<GraphViz2>, meaning any time those lists change on the
L<Graphviz|http://www.graphviz.org/> web site, it's a trivial matter to update the lists stored within this module.

See L<GraphViz2/Scripts Shipped with this Module>.

=head1 Attribute Scope

=head2 Graph Scope

The graphical elements graph, node and edge, have attributes. Attributes can be set when calling new().

Within new(), the defaults are graph => {}, node => {}, and edge => {}.

You override these with code such as new(edge => {color => 'red'}).

These attributes are pushed onto a scope stack during new()'s processing of its parameters, and they apply thereafter until changed.
They are the 'current' attributes. They live at scope level 0 (zero).

You change the 'current' attributes by calling any of the methods default_edge(%hash), default_graph(%hash) and default_node(%hash).

See scripts/trivial.pl (L<GraphViz2/Scripts Shipped with this Module>) for an example.

=head2 Subgraph Scope

When you wish to create a subgraph, you call push_subgraph(%hash). The word push emphasises that you are moving into a new scope,
and that the default attributes for the new scope are pushed onto the scope stack.

This module, as with L<Graphviz|http://www.graphviz.org/>, defaults to using inheritance of attributes.

That means the parent's 'current' attributes are combined with the parameters to push_subgraph(%hash) to generate a new set of 'current'
attributes for each of the graphical elements, graph, node and edge.

After a single call to push_subgraph(%hash), these 'current' attributes will live a level 1 in the scope stack.

See scripts/sub.graph.pl (L<GraphViz2/Scripts Shipped with this Module>) for an example.

Another call to push_subgraph(%hash), I<without> an intervening call to pop_subgraph(), will repeat the process, leaving you with
a set of attributes at level 2 in the scope stack.

Both L<GraphViz2> and L<Graphviz|http://www.graphviz.org/> handle this situation properly.

See scripts/sub.sub.graph.pl (L<GraphViz2/Scripts Shipped with this Module>) for an example.

At the moment, due to design defects (IMHO) in the underlying L<Graphviz|http://www.graphviz.org/> logic, there are some tiny problems with this:

=over 4

=item o A global frame

I can't see how to make the graph as a whole (at level 0 in the scope stack) have a frame.

=item o Frame color

When you specify graph => {color => 'red'} at the parent level, the subgraph has a red frame.

I think a subgraph should control its own frame.

=item o Parent and child frames

When you specify graph => {color => 'red'} at the subgraph level, both that subgraph and it children have red frames.

This contradicts what happens at the global level, in that specifying color there does not given the whole graph a frame.

=item o Frame visibility

A subgraph whose name starts with 'cluster' is currently forced to have a frame, unless you rig it by specifying a
color the same as the background.

For sample code, see scripts/sub.graph.frames.pl.

=back

Also, check L<the pencolor docs|http://www.graphviz.org/content/attrs#dpencolor> for how the color of the frame is
chosen by cascading thru a set of options.

I've posted an email to the L<Graphviz|http://www.graphviz.org/> mailing list suggesting a new option, framecolor, so deal with
this issue, including a special color of 'invisible'.

=head1 Image Maps

As of V 2.43, C<GraphViz2> supports image maps, both client and server side.

=head2 The Default URL

See the L<Graphviz docs for 'cmapx'|http://www.graphviz.org/doc/info/output.html#d:cmapx>.

Their sample code has a dot file - x.gv - containing this line:

	URL="http://www.research.att.com/base.html";

The way you set such a url in C<GraphViz2> is via a new parameter to C<new()>. This parameter is called C<im_meta>
and it takes a hashref as a value. Currently the only key used within that hashref is the case-sensitive C<URL>.

Thus you must do this to set a URL:

	my($graph) = GraphViz2 -> new
	             (
	                ...
	                im_meta =>
	                {
	                    URL => 'http://savage.net.au/maps/demo.3.1.html', # Note: URL must be in caps.
	                },
	             );

See maps/demo.3.pl and maps/demo.4.pl for sample code.

=head2 Typical Code

Normally you would call C<run()> as:

	$graph -> run
	(
	    format      => $format,
	    output_file => $output_file
	);

That line was copied from scripts/cluster.pl.

To trigger image map processing, you must include 2 new parameters:

	$graph -> run
	(
	    format         => $format,
	    output_file    => $output_file,
	    im_format      => $im_format,
	    im_output_file => $im_output_file
	);

That line was copied from maps/demo.3.pl, and there is an identical line in maps/demo.4.pl.

=head2 The New Parameters to run()

=over 4

=item o im_format => $str

Expected values: 'imap' (server-side) and 'cmapx' (client-side).

Default value: 'cmapx'.

=item o im_output_file => $file_name

The name of the output map file.

Default: ''.

=back

=head2 Sample Code

Various demos are shipped in the new maps/ directory:

Each demo, when FTPed to your web server displays some text with an image in the middle. In each case
you can click on the upper oval to jump to one page, or click on the lower oval to jump to a different
page, or click anywhere else in the image to jump to a third page.

=over 4

=item o demo.1.*

This set demonstrates a server-side image map but does not use C<GraphViz2>.

You have to run demo.1.sh which generates demo.1.map, and then you FTP the whole dir maps/ to your web server.

URL: your.domain.name/maps/demo.1.html.

=item o demo.2.*

This set demonstrates a client-side image map but does not use C<GraphViz2>.

You have to run demo.2.sh which generates demo.2.map, and then you manually copy demo.2.map into demo.2.html,
replacing any version of the map already present. After that you FTP the whole dir maps/ to your web server.

URL: your.domain.name/maps/demo.2.html.

=item o demo.3.*

This set demonstrates a server-side image map using C<GraphViz2> via demo.3.pl.

Note line 54 of demo.3.pl which sets the default C<im_format> to 'imap'.

URL: your.domain.name/maps/demo.3.html.

=item o demo.4.*

This set demonstrates a client-side image map using C<GraphViz2> via demo.4.pl.

As with demo.2.* there is some manually editing to be done.

Note line 54 of demo.4.pl which sets the default C<im_format> to 'cmapx'. This is the only important
difference between this demo and the previous one.

There are other minor differences, in that one uses 'svg' and the other 'png'. And of course the urls
of the web pages embedded in the code and in those web pages differs, just to demonstate that the maps
do indeed lead to different pages.

URL: your.domain.name/maps/demo.4.html.

=back

=head1 Methods

=head2 add_edge(from => $from_node_name, to => $to_node_name, [label => $label, %hash])

Adds an edge to the graph.

Returns $self to allow method chaining.

Here, [] indicate optional parameters.

Add a edge from 1 node to another.

$from_node_name and $to_node_name default to ''.

If either of these node names is unknown, add_node(name => $node_name) is called automatically. The lack of
attributes in this call means such nodes are created with the default set of attributes, and that may not
be what you want. To avoid this, you have to call add_node(...) yourself, with the appropriate attributes,
before calling add_edge(...).

%hash is any edge attributes accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the edge parameters in the calls to default_edge(%hash), new(edge => {}) and push_subgraph(edge => {}).

=head2 add_node(name => $node_name, [%hash])

Adds a node to the graph.

Returns $self to allow method chaining.

If you want to embed newlines or double-quotes in node names or labels, see scripts/quote.pl in L<GraphViz2/Scripts Shipped with this Module>.

If you want anonymous nodes, see scripts/anonymous.pl in L<GraphViz2/Scripts Shipped with this Module>.

Here, [] indicates an optional parameter.

%hash is any node attributes accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the node parameters in the calls to default_node(%hash), new(node => {}) and push_subgraph(node => {}).

The attribute name 'label' may point to a string or an arrayref.

=head3 If it is a string...

The string is the label.

The string may contain ports and orientation markers ({}).

=head3 If it is an arrayref of strings...

=over 4

=item o The node is forced to be a record

The actual shape, 'record' or 'Mrecord', is set globally, with:

	my($graph) = GraphViz2 -> new
	(
		global => {record_shape => 'record'}, # Override default 'Mrecord'.
		...
	);

Or set locally with:

	$graph -> add_node(name => 'Three', label => ['Good', 'Bad'], shape => 'record');

=item o Each element in the array defines a field in the record

These fields are combined into a single node

=item o Each element is treated as a label

=item o Each label is given a port name (1 .. N) of the form "port<$port_count>"

=item o Judicious use of '{' and '}' in the label can make this record appear horizontally or vertically, and even nested

=back

=head3 If it is an arrayref of hashrefs...

=over 4

=item o The node is forced to be a record

The actual shape, 'record' or 'Mrecord', can be set globally or locally, as explained just above.

=item o Each element in the array defines a field in the record

=item o Each element is treated as a hashref with keys 'text' and 'port'

The 'port' key is optional.

=item o The value of the 'text' key is the label

=item o The value of the 'port' key is the port

The format is "<$port_name>".

=item o Judicious use of '{' and '}' in the label can make this record appear horizontally or vertically, and even nested

=back

See scripts/html.labels.*.pl and scripts/record.*.pl for sample code.

See also the FAQ topic L</How labels interact with ports>.

For more details on this complex topic, see L<Records|http://www.graphviz.org/content/node-shapes#record> and L<Ports|http://www.graphviz.org/content/attrs#kportPos>.

=head2 default_edge(%hash)

Sets defaults attributes for edges added subsequently.

Returns $self to allow method chaining.

%hash is any edge attributes accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the edge parameters in the calls to new(edge => {}) and push_subgraph(edge => {}).

=head2 default_graph(%hash)

Sets defaults attributes for the graph.

Returns $self to allow method chaining.

%hash is any graph attributes accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the graph parameter in the calls to new(graph => {}) and push_subgraph(graph => {}).

=head2 default_node(%hash)

Sets defaults attributes for nodes added subsequently.

Returns $self to allow method chaining.

%hash is any node attributes accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the node parameters in the calls to new(node => {}) and push_subgraph(node => {}).

=head2 default_subgraph(%hash)

Sets defaults attributes for clusters and subgraphs.

Returns $self to allow method chaining.

%hash is any cluster or subgraph attribute accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the subgraph parameter in the calls to new(subgraph => {}) and push_subgraph(subgraph => {}).

=head2 dot_input()

Returns the output stream, formatted nicely, which was passed to the external program (e.g. dot).

You I<must> call run() before calling dot_input(), since it is only during the call to run() that the output stream is
stored in the buffer controlled by dot_input().

=head2 dot_output()

Returns the output from calling the external program (e.g. dot).

You I<must> call run() before calling dot_output(), since it is only during the call to run() that the output of the
external program is stored in the buffer controlled by dot_output().

This output is available even if run() does not write the output to a file.

=head2 edge_hash()

Returns, at the end of the run, a hashref keyed by node name, specifically the node at the arrowI<tail> end of
the hash, i.e. where the edge starts from.

Use this to get a list of all nodes and the edges which leave those nodes, the corresponding destination
nodes, and the attributes of each edge.

	my($node_hash) = $graph -> node_hash;
	my($edge_hash) = $graph -> edge_hash;

	for my $from (sort keys %$node_hash)
	{
		my($attr) = $$node_hash{$from}{attributes};
		my($s)    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

		print "Node: $from\n";
		print "\tAttributes: $s\n";

		for my $to (sort keys %{$$edge_hash{$from} })
		{
			for my $edge (@{$$edge_hash{$from}{$to} })
			{
				$attr = $$edge{attributes};
				$s    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

				print "\tEdge: $from$$edge{from_port} -> $to$$edge{to_port}\n";
				print "\t\tAttributes: $s\n";
			}
		}
	}

If the caller adds the same edge two (or more) times, the attributes from each call are
I<not> coalesced (unlike L</node_hash()>), but rather the attributes from each call are stored separately
in an arrayref.

A bit more formally then, $$edge_hash{$from_node}{$to_node} is an arrayref where each element describes
one edge, and which defaults to:

	{
		attributes => {},
		from_port  => $from_port,
		to_port    => $to_port,
	}

If I<from_port> is not provided by the caller, it defaults to '' (the empty string). If it is provided,
it contains a leading ':'. Likewise for I<to_port>.

See scripts/report.nodes.and.edges.pl (a version of scripts/html.labels.1.pl) for a complete example.

=head2 escape_some_chars($s)

Escapes various chars in various circumstances, because some chars are treated specially by Graphviz.

See the L</FAQ> for a discussion of this tricky topic.

=head2 load_valid_attributes()

Load various sets of valid attributes from within the source code of this module, using L<Data::Section::Simple>.

Returns $self to allow method chaining.

These attributes are used to validate attributes in many situations.

You wouldn't normally need to use this method.

=head2 log([$level, $message])

Logs the message at the given log level.

Returns $self to allow method chaining.

Here, [] indicate optional parameters.

$level defaults to 'debug', and $message defaults to ''.

If called with $level eq 'error', it dies with $message.

=head2 logger($logger_object])

Gets or sets the log object.

Here, [] indicates an optional parameter.

=head2 node_hash()

Returns, at the end of the run, a hashref keyed by node name. Use this to get a list of all nodes
and their attributes.

	my($node_hash) = $graph -> node_hash;

	for my $name (sort keys %$node_hash)
	{
		my($attr) = $$node_hash{$name}{attributes};
		my($s)    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

		print "Node: $name\n";
		print "\tAttributes: $s\n";
	}

If the caller adds the same node two (or more) times, the attributes from each call are
I<coalesced> (unlike L</edge_hash()>), meaning all attributes from all calls are combined under the
I<attributes> sub-key.

A bit more formally then, $$node_hash{$node_name} is a hashref where each element describes one node, and
which defaults to:

	{
		attributes => {},
	}

See scripts/report.nodes.and.edges.pl (a version of scripts/html.labels.1.pl) for a complete example,
including usage of the corresponding L</edge_hash()> method.

=head2 pop_subgraph()

Pop off and discard the top element of the scope stack.

Returns $self to allow method chaining.

=head2 push_subgraph([name => $name, edge => {...}, graph => {...}, node => {...}, subgraph => {...}])

Sets up a new subgraph environment.

Returns $self to allow method chaining.

Here, [] indicate optional parameters.

name => $name is the name to assign to the subgraph. Name defaults to ''.

So, without $name, 'subgraph {' is written to the output stream.

With $name, 'subgraph "$name" {' is written to the output stream.

Note that subgraph names beginning with 'cluster' L<are special to Graphviz|http://www.graphviz.org/content/attrs#dclusterrank>.

See scripts/rank.sub.graph.[1234].pl for the effect of various values for $name.

edge => {...} is any edge attributes accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the edge parameters in the calls to default_edge(%hash), new(edge => {}) and push_subgraph(edge => {}).

graph => {...} is any graph attributes accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the graph parameters in the calls to default_graph(%hash), new(graph => {}) and push_subgraph(graph => {}).

node => {...} is any node attributes accepted as L<Graphviz attributes|http://www.graphviz.org/content/attrs>. These are validated in exactly
the same way as the node parameters in the calls to default_node(%hash), new(node => {}) and push_subgraph(node => {}).

subgraph => {..} is for setting attributes applicable to clusters and subgraphs.

Currently the only subgraph attribute is C<rank>, but clusters have many attributes available.

See the second column of the L<Graphviz attribute docs|http://www.graphviz.org/content/attrs> for details.

A typical usage would be push_subgraph(subgraph => {rank => 'same'}) so that all nodes mentioned within the subgraph
are constrained to be horizontally aligned.

See scripts/rank.sub.graph.[12].pl and scripts/sub.graph.frames.pl for sample code.

=head2 report_valid_attributes()

Prints all attributes known to this module.

Returns nothing.

You wouldn't normally need to use this method.

See scripts/report.valid.attributes.pl. See L<GraphViz2/Scripts Shipped with this Module>.

=head2 run([driver => $exe, format => $string, timeout => $integer, output_file => $output_file])

Runs the given program to process the output stream.

Returns $self to allow method chaining.

Here, [] indicate optional parameters.

$driver is the name of the external program to run.

It defaults to the value supplied in the call to new(global => {driver => '...'}), which in turn defaults
to L<File::Which>'s which('dot') return value.

$format is the type of output file to write.

It defaults to the value supplied in the call to new(global => {format => '...'}), which in turn defaults
to 'svg'.

$timeout is the time in seconds to wait while the external program runs, before dieing with an error.

It defaults to the value supplied in the call to new(global => {timeout => '...'}), which in turn defaults
to 10.

$output_file is the name of the file into which the output from the external program is written.

There is no default value for $output_file. If a value is not supplied for $output_file, the only way
to recover the output of the external program is to call dot_output().

This method performs a series of tasks:

=over 4

=item o Formats the output stream

=item o Stores the formatted output in a buffer controlled by the dot_input() method

=item o Output the output stream to a file

=item o Run the chosen external program on that file

=item o Capture STDOUT and STDERR from that program

=item o Die if STDERR contains anything

=item o Copies STDOUT to the buffer controlled by the dot_output() method

=item o Write the captured contents of STDOUT to $output_file, if $output_file has a value

=back

=head2 stringify_attributes($context, $option)

Returns a string suitable to writing to the output stream.

$context is one of 'edge', 'graph', 'node', or a special string. See the code for details.

You wouldn't normally need to use this method.

=head2 validate_params($context, %attributes)

Validate the given attributes within the given context.

Also, if $context is 'subgraph', attributes are allowed to be in the 'cluster' context.

Returns $self to allow method chaining.

$context is one of 'edge', 'global', 'graph', 'node' or 'output_format'.

You wouldn't normally need to use this method.

=head2 verbose([$integer])

Gets or sets the verbosity level, for when a logging object is not used.

Here, [] indicates an optional parameter.

=head1 FAQ

=head2 Which version of Graphviz do you use?

GraphViz2 targets V 2.34.0 of L<Graphviz|http://www.graphviz.org/>.

This affects the list of available attributes per graph item (node, edge, cluster, etc) available.

See the second column of the L<Graphviz attribute docs|http://www.graphviz.org/content/attrs> for details.

See the next item for a discussion of the list of output formats.

=head2 Where does the list of valid output formats come from?

Up to V 2.23, it came from downloading and parsing http://www.graphviz.org/content/output-formats. This was done
by scripts/extract.output.formats.pl.

Starting with V 2.24 it comes from parsing the output of 'dot -T?'. The problems avoided, and advantages, of this are:

=over 4

=item o I might forget to run the script after Graphviz is updated

=item o The on-line docs might be out-of-date

=item o dot output includes the formats supported by locally-installed plugins

=back

=head2 Why do I get error messages like the following?

	Error: <stdin>:1: syntax error near line 1
	context: digraph >>>  Graph <<<  {

Graphviz reserves some words as keywords, meaning they can't be used as an ID, e.g. for the name of the graph.
So, don't do this:

	strict graph graph{...}
	strict graph Graph{...}
	strict graph strict{...}
	etc...

Likewise for non-strict graphs, and digraphs. You can however add double-quotes around such reserved words:

	strict graph "graph"{...}

Even better, use a more meaningful name for your graph...

The keywords are: node, edge, graph, digraph, subgraph and strict. Compass points are not keywords.

See L<keywords|http://www.graphviz.org/content/dot-language> in the discussion of the syntax of DOT
for details.

=head2 How do I include utf8 characters in labels?

Since V 2.00, L<GraphViz2> incorporates a sample which produce graphs such as L<this|http://savage.net.au/Perl-modules/html/graphviz2/utf8.1.svg>.

scripts/utf8.1.pl contains 'use utf8;' because of the utf8 characters embedded in the source code. You will need to do this.

=head2 Why did you remove 'use utf8' from this file (in V 2.26)?

Because it is global, i.e. it applies to all code in your program, not just within this module.
Some modules you are using may not expect that. If you need it, just use it in your *.pl script.

=head2 Why do I get 'Wide character in print...' when outputting to PNG but not SVG?

As of V 2.02, you should not get this from GraphViz2. So, I suggest you study your own code very, very carefully :-(.

Examine the output from scripts/utf8.2.pl, i.e. html/utf8.2.svg and you'll see it's correct. Then run:

	perl scripts/utf8.2.pl png

and examine html/utf8.2.png and you'll see it matches html/utf8.2.svg in showing 5 deltas. So, I I<think> it's all working.

=head2 How do I print output files?

Under Unix, output as PDF, and then try: lp -o fitplot html/parse.stt.pdf (or whatever).

=head2 Can I include spaces and newlines in HTML labels?

Yes. The code removes leading and trailing whitespace on HTML labels before calling 'dot'.

Also, the code, and 'dot', both accept newlines embedded within such labels.

Together, these allow HTML labels to be formatted nicely in the calling code.

See <the Graphviz docs|http://www.graphviz.org/content/node-shapes#record> for their discussion on whitespace.

=head2 I'm having trouble with special characters in node names and labels

L<GraphViz2> escapes these 2 characters in those contexts: [].

Escaping the 2 chars [] started with V 2.10. Previously, all of []{} were escaped, but {} are used in records
to control the orientation of fields, so they should not have been escaped in the first place.
See scripts/record.1.pl.

Double-quotes are escaped when the label is I<not> an HTML label. See scripts/html.labels.*.pl for sample code.

It would be nice to also escape | and <, but these characters are used in specifying fields and ports in records.

See the next couple of points for details.

=head2 A warning about L<Graphviz|http://www.graphviz.org/> and ports

Ports are what L<Graphviz|http://www.graphviz.org/> calls those places on the outline of a node where edges
leave and terminate.

The L<Graphviz|http://www.graphviz.org/> syntax for ports is a bit unusual:

=over 4

=item o This works: "node_name":port5

=item o This doesn't: "node_name:port5"

=back

Let me repeat - that is Graphviz syntax, not GraphViz2 syntax. In Perl, you must do this:

	$graph -> add_edge(from => 'struct1:f1', to => 'struct2:f0', color => 'blue');

You don't have to quote all node names in L<Graphviz|http://www.graphviz.org/>, but some, such as digits, must be quoted, so I've decided to quote them all.

=head2 How labels interact with ports

You can specify labels with ports in these ways:

=over 4

=item o As a string

From scripts/record.1.pl:

	$graph -> add_node(name => 'struct3', label => "hello\nworld |{ b |{c|<here> d|e}| f}| g | h");

Here, the string contains a port (<here>), field markers (|), and orientation markers ({}).

Clearly, you must specify the field separator character '|' explicitly. In the next 2 cases, it is implicit.

Then you use $graph -> add_edge(...) to refer to those ports, if desired. Again, from scripts/record.1.pl:

$graph -> add_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

The same label is specified in the next case.

=item o As an arrayref of hashrefs

From scripts/record.2.pl:

	$graph -> add_node(name => 'struct3', label =>
	[
		{
			text => "hello\nworld",
		},
		{
			text => '{b',
		},
		{
			text => '{c',
		},
		{
			port => '<here>',
			text => 'd',
		},
		{
			text => 'e}',
		},
		{
			text => 'f}',
		},
		{
			text => 'g',
		},
		{
			text => 'h',
		},
	]);

Each hashref is a field, and hence you do not specify the field separator character '|'.

Then you use $graph -> add_edge(...) to refer to those ports, if desired. Again, from scripts/record.2.pl:

$graph -> add_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

The same label is specified in the previous case.

=item o As an arrayref of strings

From scripts/html.labels.1.pl:

	$graph -> add_node(name => 'Oakleigh', shape => 'record', color => 'blue',
		label => ['West Oakleigh', 'East Oakleigh']);

Here, again, you do not specify the field separator character '|'.

What happens is that each string is taken to be the label of a field, and each field is given
an auto-generated port name of the form "<port$n>", where $n starts from 1.

Here's how you refer to those ports, again from scripts/html.labels.1.pl:

	$graph -> add_edge(from => 'Murrumbeena', to => 'Oakleigh:port2',
		color => 'green', label => '<Drive<br/>Run<br/>Sprint>');

=back

See also the docs for the C<< add_node(name => $node_name, [%hash]) >> method.

=head2 How do I specify attributes for clusters?

Just use subgraph => {...}, because the code (as of V 2.22) accepts attributes belonging to either clusters or subgraphs.

An example attribute is C<pencolor>, which is used for clusters but not for subgraphs:

	$graph -> push_subgraph
	(
		graph    => {label => 'Child the Second'},
		name     => 'cluster Second subgraph',
		node     => {color => 'magenta', shape => 'diamond'},
		subgraph => {pencolor => 'white'}, # White hides the cluster's frame.
	);

See scripts/sub.graph.frames.pl.

=head2 Why does L<GraphViz> plot top-to-bottom but L<GraphViz2::Parse::ISA> plot bottom-to-top?

Because the latter knows the data is a class structure. The former makes no assumptions about the nature of the data.

=head2 What happened to GraphViz::No?

The default_node(%hash) method in L<GraphViz2> allows you to make nodes vanish.

Try: $graph -> default_node(label => '', height => 0, width => 0, style => 'invis');

Because that line is so simple, I feel it's unnecessary to make a subclass of GraphViz2.

=head2 What happened to GraphViz::Regex?

See L<GraphViz2::Parse::Regexp>.

=head2 What happened to GraphViz::Small?

The default_node(%hash) method in L<GraphViz2> allows you to make nodes which are small.

Try: $graph -> default_node(label => '', height => 0.2, width => 0.2, style => 'filled');

Because that line is so simple, I feel it's unnecessary to make a subclass of GraphViz2.

=head2 What happened to GraphViz::XML?

Use L<GraphViz2::Parse::XML> instead, which uses the pure-Perl XML::Tiny.

Alternately, see L<GraphViz2/Scripts Shipped with this Module> for how to use L<XML::Bare>, L<GraphViz2>
and L<GraphViz2::Data::Grapher> instead.

See L</scripts/parse.xml.pp.pl> or L</scripts/parse.xml.bare.pl> below.

=head2 GraphViz returned a node name from add_node() when given an anonymous node. What does GraphViz2 do?

You can give the node a name, and an empty string for a label, to suppress plotting the name.

See L</scripts/anonymous.pl> for demo code.

If there is some specific requirement which this does not cater for, let me know and I can change the code.

=head2 How do I use image maps?

See L</Image Maps> above.

=head2 I'm trying to use image maps but the non-image map code runs instead!

The default value of C<im_output_file> is '', so if you do not set it to anything, the new image maps code
is ignored.

=head2 Why such a different approach to logging?

As you can see from scripts/*.pl, I always use L<Log::Handler>.

By default (i.e. without a logger object), L<GraphViz2> prints warning and debug messages to STDOUT,
and dies upon errors.

However, by supplying a log object, you can capture these events.

Not only that, you can change the behaviour of your log object at any time, by calling
L</logger($logger_object)>.

=head2 A Note about XML Containers

The 2 demo programs L</scripts/parse.html.pl> and L</scripts/parse.xml.bare.pl>, which both use L<XML::Bare>, assume your XML has a single
parent container for all other containers. The programs use this container to provide a name for the root node of the graph.

=head2 Why did you choose L<Moo> over L<Moose>?

L<Moo> is light-weight.

=head1 Scripts Shipped with this Module

See L<the demo page|http://savage.net.au/Perl-modules/html/graphviz2/index.html>, which displays the output
of each program listed below.

=head2 scripts/anonymous.pl

Demonstrates empty strings for node names and labels.

Outputs to ./html/anonymous.svg by default.

=head2 scripts/cluster.pl

Demonstrates building a cluster as a subgraph.

Outputs to ./html/cluster.svg by default.

See also scripts/macro.*.pl below.

=head2 copy.config.pl

End users have no need to run this script.

=head2 scripts/dbi.schema.pl

If the environment vaiables DBI_DSN, DBI_USER and DBI_PASS are set (the latter 2 are optional [e.g. for SQLite]),
then this demonstrates building a graph from a database schema.

Also, for Postgres, you can set $ENV{DBI_SCHEMA} to a comma-separated list of schemas, e.g. when processing the
MusicBrainz database. See scripts/dbi.schema.pl.

For details, see L<http://blogs.perl.org/users/ron_savage/2013/03/graphviz2-and-the-dread-musicbrainz-db.html>.

Outputs to ./html/dbi.schema.svg by default.

=head2 scripts/dependency.pl

Demonstrates graphing an L<Algorithm::Dependency> source.

Outputs to ./html/dependency.svg by default.

The default for L<GraphViz2> is to plot from the top to the bottom. This is the opposite of L<GraphViz2::Parse::ISA>.

See also parse.isa.pl below.

=head2 scripts/extract.arrow.shapes.pl

Downloads the arrow shapes from L<Graphviz's Arrow Shapes|http://www.graphviz.org/content/arrow-shapes> and outputs them to ./data/arrow.shapes.html.
Then it extracts the reserved words into ./data/arrow.shapes.dat.

=head2 scripts/extract.attributes.pl

Downloads the attributes from L<Graphviz's Attributes|http://www.graphviz.org/content/attrs> and outputs them to ./data/attributes.html.
Then it extracts the reserved words into ./data/attributes.dat.

=head2 scripts/extract.node.shapes.pl

Downloads the node shapes from L<Graphviz's Node Shapes|http://www.graphviz.org/content/node-shapes> and outputs them to ./data/node.shapes.html.
Then it extracts the reserved words into ./data/node.shapes.dat.

=head2 scripts/extract.output.formats.pl

Downloads the output formats from L<Graphviz's Output Formats|http://www.graphviz.org/content/output-formats> and outputs them to ./data/output.formats.html.
Then it extracts the reserved words into ./data/output.formats.dat.

=head2 find.config.pl

End users have no need to run this script.

=head2 scripts/generate.demo.pl

Run by scripts/generate.svg.sh. See next point.

=head2 scripts/generate.png.sh

See scripts/generate.svg.sh for details.

Outputs to /tmp by default.

This script is generated by generate.sh.pl.

=head2 generate.sh.pl

Generates scripts/generate.png.sh and scripts/generate.svg.sh.

=head2 scripts/generate.svg.sh

A bash script to run all the scripts and generate the *.svg and *.log files, in ./html.

You can them copy html/*.html and html/*.svg to your web server's doc root, for viewing.

Outputs to /tmp by default.

This script is generated by generate.sh.pl.

=head2 scripts/Heawood.pl

Demonstrates the transitive 6-net, also known as Heawood's graph.

Outputs to ./html/Heawood.svg by default.

This program was reverse-engineered from graphs/undirected/Heawood.gv in the distro for L<Graphviz|http://www.graphviz.org/> V 2.26.3.

=head2 scripts/html.labels.1.pl

Demonstrates a HTML label without a table.

Also demonstrates an arrayref of strings as a label.

See also scripts/record.*.pl for other label techniques.

Outputs to ./html/html.labels.1.svg by default.

=head2 scripts/html.labels.2.pl

Demonstrates a HTML label with a table.

Outputs to ./html/html.labels.2.svg by default.

=head2 scripts/macro.1.pl

Demonstrates non-cluster subgraphs via a macro.

Outputs to ./html/macro.1.svg by default.

=head2 scripts/macro.2.pl

Demonstrates linked non-cluster subgraphs via a macro.

Outputs to ./html/macro.2.svg by default.

=head2 scripts/macro.3.pl

Demonstrates cluster subgraphs via a macro.

Outputs to ./html/macro.3.svg by default.

=head2 scripts/macro.4.pl

Demonstrates linked cluster subgraphs via a macro.

Outputs to ./html/macro.4.svg by default.

=head2 scripts/macro.5.pl

Demonstrates compound cluster subgraphs via a macro.

Outputs to ./html/macro.5.svg by default.

=head2 scripts/parse.data.pl

Demonstrates graphing a Perl data structure.

Outputs to ./html/parse.data.svg by default.

=head2 scripts/parse.html.pl

Demonstrates using L<XML::Bare> to parse HTML.

Inputs from ./t/sample.html, and outputs to ./html/parse.html.svg by default.

=head2 scripts/parse.isa.pl

Demonstrates combining 2 Perl class hierarchies on the same graph.

Outputs to ./html/parse.isa.svg by default.

The default for L<GraphViz2::Parse::ISA> is to plot from the bottom to the top (Grandchild to Parent).
This is the opposite of L<GraphViz2>.

See also dependency.pl, above.

=head2 scripts/parse.recdescent.pl

Demonstrates graphing a L<Parse::RecDescent>-style grammar.

Inputs from t/sample.recdescent.1.dat and outputs to ./html/parse.recdescent.svg by default.

The input grammar was extracted from t/basics.t in L<Parse::RecDescent> V 1.965001.

You can patch the *.pl to read from t/sample.recdescent.2.dat, which was copied from L<a V 2 bug report|https://rt.cpan.org/Ticket/Display.html?id=36057>.

=head2 scripts/parse.regexp.pl

Demonstrates graphing a Perl regular expression.

Outputs to ./html/parse.regexp.svg by default.

=head2 scripts/parse.stt.pl

Demonstrates graphing a L<Set::FA::Element>-style state transition table.

Inputs from t/sample.stt.1.dat and outputs to ./html/parse.stt.svg by default.

The input grammar was extracted from L<Set::FA::Element>.

You can patch the scripts/parse.stt.pl to read from t/sample.stt.2.dat instead of t/sample.stt.1.dat.
t/sample.stt.2.dat was extracted from a obsolete version of L<Graph::Easy::Marpa>, i.e. V 1.*. The Marpa-based
parts of the latter module were completely rewritten for V 2.*.

=head2 scripts/parse.yacc.pl

Demonstrates graphing a L<byacc|http://invisible-island.net/byacc/byacc.html>-style grammar.

Inputs from t/calc3.output, and outputs to ./html/parse.yacc.svg by default.

The input was copied from test/calc3.y in byacc V 20101229 and process as below.

Note: The version downloadable via HTTP is 20101127.

I installed byacc like this:

	sudo apt-get byacc

Now get a sample file to work with:

	cd ~/Downloads
	curl ftp://invisible-island.net/byacc/byacc.tar.gz > byacc.tar.gz
	tar xvzf byacc.tar.gz
	cd ~/perl.modules/GraphViz2
	cp ~/Downloads/byacc-20101229/test/calc3.y t
	byacc -v t/calc3.y
	mv y.output t/calc3.output
	diff ~/Downloads/byacc-20101229/test/calc3.output t/calc3.output
	rm y.tab.c

It's the file calc3.output which ships in the t/ directory.

=head2 scripts/parse.yapp.pl

Demonstrates graphing a L<Parse::Yapp>-style grammar.

Inputs from t/calc.output, and outputs to ./html/parse.yapp.svg by default.

The input was copied from t/calc.t in L<Parse::Yapp>'s and processed as below.

I installed L<Parse::Yapp> (and yapp) like this:

	cpanm Parse::Yapp

Now get a sample file to work with:

	cd ~/perl.modules/GraphViz2
	cp ~/.cpanm/latest-build/Parse-Yapp-1.05/t/calc.t t/calc.input

Edit t/calc.input to delete the code, leaving the grammar after the __DATA__token.

	yapp -v t/calc.input > t/calc.output
	rm t/calc.pm

It's the file calc.output which ships in the t/ directory.

=head2 scripts/parse.xml.bare.pl

Demonstrates using L<XML::Bare> to parse XML.

Inputs from ./t/sample.xml, and outputs to ./html/parse.xml.bare.svg by default.

=head2 scripts/parse.xml.pp.pl

Demonstrates using L<XML::Tiny> to parse XML.

Inputs from ./t/sample.xml, and outputs to ./html/parse.xml.pp.svg by default.

=head2 scripts/quote.pl

Demonstrates embedded newlines and double-quotes in node names and labels.

It also demonstrates that the justification escapes, \l and \r, work too, sometimes.

Outputs to ./html/quote.svg by default.

Tests which run dot directly show this is a bug in L<Graphviz|http://www.graphviz.org/> itself.

For example, in this graph, it looks like \r only works after \l (node d), but not always (nodes b, c).

Call this x.gv:

	digraph G {
		rankdir=LR;
		node [shape=oval];
		a [ label ="a: Far, far, Left\rRight"];
		b [ label ="\lb: Far, far, Left\rRight"];
		c [ label ="XXX\lc: Far, far, Left\rRight"];
		d [ label ="d: Far, far, Left\lRight\rRight"];
	}

and use the command:

	dot -Tsvg x.gv > x.svg

See L<the Graphviz docs|http://www.graphviz.org/content/attrs#kescString> for escString, where they write 'l to mean \l, for some reason.

=head2 scripts/rank.sub.graph.1.pl

Demonstrates a very neat way of controlling the I<rank> attribute of nodes within subgraphs.

Outputs to ./html/rank.sub.graph.1.svg by default.

=head2 scripts/rank.sub.graph.2.pl

Demonstrates a long-winded way of controlling the I<rank> attribute of nodes within subgraphs.

Outputs to ./html/rank.sub.graph.2.svg by default.

=head2 scripts/rank.sub.graph.3.pl

Demonstrates the effect of the name of a subgraph, when that name does not start with 'cluster'.

Outputs to ./html/rank.sub.graph.3.svg by default.

=head2 scripts/record.1.pl

Demonstrates a string as a label, containing both ports and orientation markers ({}).

Outputs to ./html/record.1.svg by default.

See also scripts/html.labels.2.pl and scripts/record.*.pl for other label techniques.

=head2 scripts/record.2.pl

Demonstrates an arrayref of hashrefs as a label, containing both ports and orientation markers ({}).

Outputs to ./html/record.2.svg by default.

See also scripts/html.labels.1.pl the other type of HTML labels.

=head2 scripts/record.3.pl

Demonstrates a string as a label, containing ports and deeply nested orientation markers ({}).

Outputs to ./html/record.3.svg by default.

See also scripts/html.labels.*.pl and scripts/record.*.pl for other label techniques.

=head2 scripts/record.4.pl

Demonstrates setting node shapes by default and explicitly.

Outputs to ./html/record.4.svg by default.

=head2 scripts/rank.sub.graph.4.pl

Demonstrates the effect of the name of a subgraph, when that name starts with 'cluster'.

Outputs to ./html/rank.sub.graph.4.svg by default.

=head2 scripts/report.nodes.and.edges.pl

Demonstates how to access the data returned by L</edge_hash()> and L</node_hash()>.

Prints node and edge attributes.

Outputs to STDOUT.

=head2 scripts/report.valid.attributes.pl

Prints all current L<Graphviz|http://www.graphviz.org/> attributes, along with a few global ones I've invented for the purpose of writing this module.

Outputs to STDOUT.

=head2 scripts/sqlite.foreign.keys.pl

Demonstrates how to find foreign key info by calling SQLite's pragma foreign_key_list.

Outputs to STDOUT.

=head2 scripts/sub.graph.frames.pl

Demonstrates clusters with and without frames.

Outputs to ./html/sub.graph.frames.svg by default.

=head2 scripts/sub.graph.pl

Demonstrates a graph combined with a subgraph.

Outputs to ./html/sub.graph.svg by default.

=head2 scripts/sub.sub.graph.pl

Demonstrates a graph combined with a subgraph combined with a subsubgraph.

Outputs to ./html/sub.sub.graph.svg by default.

=head2 scripts/trivial.pl

Demonstrates a trivial 3-node graph, with colors, just to get you started.

Outputs to ./html/trivial.svg by default.

=head2 scripts/utf8.1.pl

Demonstrates using utf8 characters in labels.

Outputs to ./html/utf8.1.svg by default.

=head2 scripts/utf8.2.pl

Demonstrates using utf8 characters in labels.

Outputs to ./html/utf8.2.svg by default.

=head1 TODO

=over 4

=item o Does GraphViz2 need to emulate the sort option in GraphViz?

That depends on what that option really does.

=item o Handle edges such as 1 -> 2 -> {A B}, as seen in L<Graphviz|http://www.graphviz.org/>'s graphs/directed/switch.gv

But how?

=item o Validate parameters more carefully, e.g. to reject non-hashref arguments where appropriate

Some method parameter lists take keys whose value must be a hashref.

=back

=head1 A Extremely Short List of Other Graphing Software

L<Axis Maps|http://www.axismaps.com/>.

L<Polygon Map Generation|http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/>.
Read more on that L<here|http://blogs.perl.org/users/max_maischein/2011/06/display-your-data---randompoissondisc.html>.

L<Voronoi Applications|http://www.voronoi.com/wiki/index.php?title=Voronoi_Applications>.

=head1 Thanks

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Repository

L<https://github.com/ronsavage/GraphViz2.git>

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

__DATA__
@@ arrow_modifier
l
o
r

@@ arrow
box
crow
curve
diamond
dot
inv
none
normal
tee
vee

@@ common_attribute
Damping => graph
K => graph, cluster
URL => edge, node, graph, cluster
area => node, cluster
arrowhead => edge
arrowsize => edge
arrowtail => edge
bb => graph
bgcolor => graph, cluster
center => graph
charset => graph
clusterrank => graph
color => edge, node, cluster
colorscheme => edge, node, cluster, graph
comment => edge, node, graph
compound => graph
concentrate => graph
constraint => edge
decorate => edge
defaultdist => graph
dim => graph
dimen => graph
dir => edge
diredgeconstraints => graph
distortion => node
dpi => graph
edgeURL => edge
edgehref => edge
edgetarget => edge
edgetooltip => edge
epsilon => graph
esep => graph
fillcolor => node, edge, cluster
fixedsize => node
fontcolor => edge, node, graph, cluster
fontname => edge, node, graph, cluster
fontnames => graph
fontpath => graph
fontsize => edge, node, graph, cluster
forcelabels => graph
gradientangle => node, cluster, graph
group => node
headURL => edge
head_lp => edge
headclip => edge
headhref => edge
headlabel => edge
headport => edge
headtarget => edge
headtooltip => edge
height => node
href => graph, cluster, node, edge
id => graph, cluster, node, edge
image => node
imagepath => graph
imagescale => node
inputscale => graph
label => edge, node, graph, cluster
labelURL => edge
label_scheme => graph
labelangle => edge
labeldistance => edge
labelfloat => edge
labelfontcolor => edge
labelfontname => edge
labelfontsize => edge
labelhref => edge
labeljust => graph, cluster
labelloc => node, graph, cluster
labeltarget => edge
labeltooltip => edge
landscape => graph
layer => edge, node, cluster
layerlistsep => graph
layers => graph
layerselect => graph
layersep => graph
layout => graph
len => edge
levels => graph
levelsgap => graph
lhead => edge
lheight => graph, cluster
lp => edge, graph, cluster
ltail => edge
lwidth => graph, cluster
margin => node, cluster, graph
maxiter => graph
mclimit => graph
mindist => graph
minlen => edge
mode => graph
model => graph
mosek => graph
nodesep => graph
nojustify => graph, cluster, node, edge
normalize => graph
nslimit => graph
ordering => graph, node
orientation => node
orientation => graph
outputorder => graph
overlap => graph
overlap_scaling => graph
overlap_shrink => graph
pack => graph
packmode => graph
pad => graph
page => graph
pagedir => graph
pencolor => cluster
penwidth => cluster, node, edge
peripheries => node, cluster
pin => node
pos => edge, node
quadtree => graph
quantum => graph
rank => subgraph
rankdir => graph
ranksep => graph
ratio => graph
rects => node
regular => node
remincross => graph
repulsiveforce => graph
resolution => graph
root => graph, node
rotate => graph
rotation => graph
samehead => edge
sametail => edge
samplepoints => node
scale => graph
searchsize => graph
sep => graph
shape => node
shapefile => node
showboxes => edge, node, graph
sides => node
size => graph
skew => node
smoothing => graph
sortv => graph, cluster, node
splines => graph
start => graph
style => edge, node, cluster, graph
stylesheet => graph
tailURL => edge
tail_lp => edge
tailclip => edge
tailhref => edge
taillabel => edge
tailport => edge
tailtarget => edge
tailtooltip => edge
target => edge, node, graph, cluster
tooltip => node, edge, cluster
truecolor => graph
vertices => node
viewport => graph
voro_margin => graph
weight => edge
width => node
xdotversion => graph
xlabel => edge, node
xlp => node, edge
z => node

@@ global
directed
driver
format
im_format
label
name
record_shape
strict
subgraph
timeout

@@ im_meta
URL

@@ node
Mcircle
Mdiamond
Msquare
assembly
box
box3d
cds
circle
component
diamond
doublecircle
doubleoctagon
egg
ellipse
fivepoverhang
folder
hexagon
house
insulator
invhouse
invtrapezium
invtriangle
larrow
lpromoter
none
note
noverhang
octagon
oval
parallelogram
pentagon
plaintext
point
polygon
primersite
promoter
proteasesite
proteinstab
rarrow
rect
rectangle
restrictionsite
ribosite
rnastab
rpromoter
septagon
signature
square
star
tab
terminator
threepoverhang
trapezium
triangle
tripleoctagon
underline
utr
