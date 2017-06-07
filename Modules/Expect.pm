# -*-cperl-*-
# This module is copyrighted as per the usual perl legalese:
# Copyright (c) 1997 Austin Schutz.
# expect() interface & functionality enhancements (c) 1999 Roland Giersig.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# Don't blame/flame me if you bust your stuff.
# Austin Schutz <ASchutz@users.sourceforge.net>
#
# This module now is maintained by
# Dave Jacoby <jacoby@cpan.org>
#

use 5.006;

package Expect;
use strict;
use warnings;

use IO::Pty 1.11; # We need make_slave_controlling_terminal()
use IO::Tty;

use POSIX qw(:sys_wait_h :unistd_h); # For WNOHANG and isatty
use Fcntl qw(:DEFAULT);              # For checking file handle settings.
use Carp qw(cluck croak carp confess);
use IO::Handle ();
use Exporter   qw(import);
use Errno;

# This is necessary to make routines within Expect work.

@Expect::ISA    = qw(IO::Pty);
@Expect::EXPORT = qw(expect exp_continue exp_continue_timeout);

BEGIN {
	$Expect::VERSION = '1.35';

	# These are defaults which may be changed per object, or set as
	# the user wishes.
	# This will be unset, since the default behavior differs between
	# spawned processes and initialized filehandles.
	#  $Expect::Log_Stdout = 1;
	$Expect::Log_Group          = 1;
	$Expect::Debug              = 0;
	$Expect::Exp_Max_Accum      = 0; # unlimited
	$Expect::Exp_Internal       = 0;
	$Expect::IgnoreEintr        = 0;
	$Expect::Manual_Stty        = 0;
	$Expect::Multiline_Matching = 1;
	$Expect::Do_Soft_Close      = 0;
	@Expect::Before_List        = ();
	@Expect::After_List         = ();
	%Expect::Spawned_PIDs       = ();
}

sub version {
	my ($version) = @_;

	warn "Version $version is later than $Expect::VERSION. It may not be supported"
		if ( defined($version) && ( $version > $Expect::VERSION ) );

	die "Versions before 1.03 are not supported in this release"
		if ( ( defined($version) ) && ( $version < 1.03 ) );
	return $Expect::VERSION;
}

sub new {
	my ($class, @args) = @_;

	$class = ref($class) if ref($class); # so we can be called as $exp->new()

	# Create the pty which we will use to pass process info.
	my ($self) = IO::Pty->new;
	die "$class: Could not assign a pty" unless $self;
	bless $self => $class;
	$self->autoflush(1);

	# This is defined here since the default is different for
	# initialized handles as opposed to spawned processes.
	${*$self}{exp_Log_Stdout} = 1;
	$self->_init_vars();

	if (@args) {

		# we got add'l parms, so pass them to spawn
		return $self->spawn(@args);
	}
	return $self;
}

sub spawn {
	my ($class, @cmd) = @_;
	# spawn is passed command line args.

	my $self;

	if ( ref($class) ) {
		$self = $class;
	} else {
		$self = $class->new();
	}

	croak "Cannot reuse an object with an already spawned command"
		if exists ${*$self}{"exp_Command"};
	${*$self}{"exp_Command"} = \@cmd;

	# set up pipe to detect childs exec error
	pipe( FROM_CHILD,  TO_PARENT ) or die "Cannot open pipe: $!";
	pipe( FROM_PARENT, TO_CHILD )  or die "Cannot open pipe: $!";
	TO_PARENT->autoflush(1);
	TO_CHILD->autoflush(1);
	eval { fcntl( TO_PARENT, Fcntl::F_SETFD, Fcntl::FD_CLOEXEC ); };

	my $pid = fork;

	unless ( defined($pid) ) {
		warn "Cannot fork: $!" if $^W;
		return;
	}

	if ($pid) {

		# parent
		my $errno;
		${*$self}{exp_Pid} = $pid;
		close TO_PARENT;
		close FROM_PARENT;
		$self->close_slave();
		$self->set_raw() if $self->raw_pty and isatty($self);
		close TO_CHILD; # so child gets EOF and can go ahead

		# now wait for child exec (eof due to close-on-exit) or exec error
		my $errstatus = sysread( FROM_CHILD, $errno, 256 );
		die "Cannot sync with child: $!" if not defined $errstatus;
		close FROM_CHILD;
		if ($errstatus) {
			$! = $errno + 0;
			warn "Cannot exec(@cmd): $!\n" if $^W;
			return;
		}
	} else {

		# child
		close FROM_CHILD;
		close TO_CHILD;

		$self->make_slave_controlling_terminal();
		my $slv = $self->slave()
			or die "Cannot get slave: $!";

		$slv->set_raw() if $self->raw_pty;
		close($self);

		# wait for parent before we detach
		my $buffer;
		my $errstatus = sysread( FROM_PARENT, $buffer, 256 );
		die "Cannot sync with parent: $!" if not defined $errstatus;
		close FROM_PARENT;

		close(STDIN);
		open( STDIN, "<&" . $slv->fileno() )
			or die "Couldn't reopen STDIN for reading, $!\n";
		close(STDOUT);
		open( STDOUT, ">&" . $slv->fileno() )
			or die "Couldn't reopen STDOUT for writing, $!\n";
		close(STDERR);
		open( STDERR, ">&" . $slv->fileno() )
			or die "Couldn't reopen STDERR for writing, $!\n";

		{ exec(@cmd) };
		print TO_PARENT $! + 0;
		die "Cannot exec(@cmd): $!\n";
	}

	# This is sort of for code compatibility, and to make debugging a little
	# easier. By code compatibility I mean that previously the process's
	# handle was referenced by $process{Pty_Handle} instead of just $process.
	# This is almost like 'naming' the handle to the process.
	# I think this also reflects Tcl Expect-like behavior.
	${*$self}{exp_Pty_Handle} = "spawn id(" . $self->fileno() . ")";
	if ( ( ${*$self}{"exp_Debug"} ) or ( ${*$self}{"exp_Exp_Internal"} ) ) {
		cluck(
			"Spawned '@cmd'\r\n",
			"\t${*$self}{exp_Pty_Handle}\r\n",
			"\tPid: ${*$self}{exp_Pid}\r\n",
			"\tTty: " . $self->SUPER::ttyname() . "\r\n",
		);
	}
	$Expect::Spawned_PIDs{ ${*$self}{exp_Pid} } = undef;
	return $self;
}

sub exp_init {
	my ($class, $self) = @_;

	# take a filehandle, for use later with expect() or interconnect() .
	# All the functions are written for reading from a tty, so if the naming
	# scheme looks odd, that's why.
	bless $self, $class;
	croak "exp_init not passed a file object, stopped"
		unless defined( $self->fileno() );
	$self->autoflush(1);

	# Define standard variables.. debug states, etc.
	$self->_init_vars();

	# Turn of logging. By default we don't want crap from a file to get spewed
	# on screen as we read it.
	${*$self}{exp_Log_Stdout} = 0;
	${*$self}{exp_Pty_Handle} = "handle id(" . $self->fileno() . ")";
	${*$self}{exp_Pty_Handle} = "STDIN" if $self->fileno() == fileno(STDIN);
	print STDERR "Initialized ${*$self}{exp_Pty_Handle}.'\r\n"
		if ${*$self}{"exp_Debug"};
	return $self;
}

# make an alias
*init = \&exp_init;

######################################################################
# We're happy OOP people. No direct access to stuff.
# For standard read-writeable parameters, we define some autoload magic...
my %Writeable_Vars = (
	debug                        => 'exp_Debug',
	exp_internal                 => 'exp_Exp_Internal',
	do_soft_close                => 'exp_Do_Soft_Close',
	max_accum                    => 'exp_Max_Accum',
	match_max                    => 'exp_Max_Accum',
	notransfer                   => 'exp_NoTransfer',
	log_stdout                   => 'exp_Log_Stdout',
	log_user                     => 'exp_Log_Stdout',
	log_group                    => 'exp_Log_Group',
	manual_stty                  => 'exp_Manual_Stty',
	restart_timeout_upon_receive => 'exp_Continue',
	raw_pty                      => 'exp_Raw_Pty',
);
my %Readable_Vars = (
	pid              => 'exp_Pid',
	exp_pid          => 'exp_Pid',
	exp_match_number => 'exp_Match_Number',
	match_number     => 'exp_Match_Number',
	exp_error        => 'exp_Error',
	error            => 'exp_Error',
	exp_command      => 'exp_Command',
	command          => 'exp_Command',
	exp_match        => 'exp_Match',
	match            => 'exp_Match',
	exp_matchlist    => 'exp_Matchlist',
	matchlist        => 'exp_Matchlist',
	exp_before       => 'exp_Before',
	before           => 'exp_Before',
	exp_after        => 'exp_After',
	after            => 'exp_After',
	exp_exitstatus   => 'exp_Exit',
	exitstatus       => 'exp_Exit',
	exp_pty_handle   => 'exp_Pty_Handle',
	pty_handle       => 'exp_Pty_Handle',
	exp_logfile      => 'exp_Log_File',
	logfile          => 'exp_Log_File',
	%Writeable_Vars,
);

sub AUTOLOAD {
	my ($self, @args) = @_;

	my $type = ref($self)
		or croak "$self is not an object";

	use vars qw($AUTOLOAD);
	my $name = $AUTOLOAD;
	$name =~ s/.*:://; # strip fully-qualified portion

	unless ( exists $Readable_Vars{$name} ) {
		croak "ERROR: cannot find method `$name' in class $type";
	}
	my $varname = $Readable_Vars{$name};
	my $tmp;
	$tmp = ${*$self}{$varname} if exists ${*$self}{$varname};

	if (@args) {
		if ( exists $Writeable_Vars{$name} ) {
			my $ref = ref($tmp);
			if ( $ref eq 'ARRAY' ) {
				${*$self}{$varname} = [@args];
			} elsif ( $ref eq 'HASH' ) {
				${*$self}{$varname} = {@args};
			} else {
				${*$self}{$varname} = shift @args;
			}
		} else {
			carp "Trying to set read-only variable `$name'"
				if $^W;
		}
	}

	my $ref = ref($tmp);
	return ( wantarray ? @{$tmp} : $tmp ) if ( $ref eq 'ARRAY' );
	return ( wantarray ? %{$tmp} : $tmp ) if ( $ref eq 'HASH' );
	return $tmp;
}

######################################################################

sub set_seq {
	my ( $self, $escape_sequence, $function, $params, @args ) = @_;

	# Set an escape sequence/function combo for a read handle for interconnect.
	# Ex: $read_handle->set_seq('',\&function,\@parameters);
	${ ${*$self}{exp_Function} }{$escape_sequence} = $function;
	if ( ( !defined($function) ) || ( $function eq 'undef' ) ) {
		${ ${*$self}{exp_Function} }{$escape_sequence} = \&_undef;
	}
	${ ${*$self}{exp_Parameters} }{$escape_sequence} = $params;

	# This'll be a joy to execute. :)
	if ( ${*$self}{"exp_Debug"} ) {
		print STDERR "Escape seq. '" . $escape_sequence;
		print STDERR "' function for ${*$self}{exp_Pty_Handle} set to '";
		print STDERR ${ ${*$self}{exp_Function} }{$escape_sequence};
		print STDERR "(" . join( ',', @args ) . ")'\r\n";
	}
}

sub set_group {
	my ($self, @args) = @_;

	# Make sure we can read from the read handle
	if ( !defined( $args[0] ) ) {
		if ( defined( ${*$self}{exp_Listen_Group} ) ) {
			return @{ ${*$self}{exp_Listen_Group} };
		} else {

			# Refrain from referencing an undef
			return;
		}
	}
	@{ ${*$self}{exp_Listen_Group} } = ();
	if ( $self->_get_mode() !~ 'r' ) {
		warn(
			"Attempting to set a handle group on ${*$self}{exp_Pty_Handle}, ",
			"a non-readable handle!\r\n"
		);
	}
	while ( my $write_handle = shift @args ) {
		if ( $write_handle->_get_mode() !~ 'w' ) {
			warn(
				"Attempting to set a non-writeable listen handle ",
				"${*$write_handle}{exp_Pty_handle} for ",
				"${*$self}{exp_Pty_Handle}!\r\n"
			);
		}
		push( @{ ${*$self}{exp_Listen_Group} }, $write_handle );
	}
}

sub log_file {
	my ($self, $file, $mode)  = @_;
	$mode ||= "a";

	return ( ${*$self}{exp_Log_File} )
		if @_ < 2; # we got no param, return filehandle
	# $e->log_file(undef) is an acceptable call hence we need to check the number of parameters here

	if ( ${*$self}{exp_Log_File} and ref( ${*$self}{exp_Log_File} ) ne 'CODE' ) {
		close( ${*$self}{exp_Log_File} );
	}
	${*$self}{exp_Log_File} = undef;
	return if ( not $file );
	my $fh = $file;
	if ( not ref($file) ) {

		# it's a filename
		$fh = IO::File->new( $file, $mode )
			or croak "Cannot open logfile $file: $!";
	}
	if ( ref($file) ne 'CODE' ) {
		croak "Given logfile doesn't have a 'print' method"
			if not $fh->can("print");
		$fh->autoflush(1); # so logfile is up to date
	}

	${*$self}{exp_Log_File} = $fh;

	return $fh;
}

# I'm going to leave this here in case I might need to change something.
# Previously this was calling `stty`, in a most bastardized manner.
sub exp_stty {
	my ($self) = shift;
	my ($mode) = "@_";

	return unless defined $mode;
	if ( not defined $INC{"IO/Stty.pm"} ) {
		carp "IO::Stty not installed, cannot change mode";
		return;
	}

	if ( ${*$self}{"exp_Debug"} ) {
		print STDERR "Setting ${*$self}{exp_Pty_Handle} to tty mode '$mode'\r\n";
	}
	unless ( POSIX::isatty($self) ) {
		if ( ${*$self}{"exp_Debug"} or $^W ) {
			warn "${*$self}{exp_Pty_Handle} is not a tty. Not changing mode";
		}
		return ''; # No undef to avoid warnings elsewhere.
	}
	IO::Stty::stty( $self, split( /\s/, $mode ) );
}

*stty = \&exp_stty;

# If we want to clear the buffer. Otherwise Accum will grow during send_slow
# etc. and contain the remainder after matches.
sub clear_accum {
	my ($self) = @_;
	return $self->set_accum('');
}

sub set_accum {
	my ($self, $accum) = @_;

	my $old_accum = ${*$self}{exp_Accum};
	${*$self}{exp_Accum} = $accum;

	# return the contents of the accumulator.
	return $old_accum;
}
sub get_accum {
	my ($self) = @_;
	return ${*$self}{exp_Accum};
}

######################################################################
# define constants for pattern subs
sub exp_continue         {"exp_continue"}
sub exp_continue_timeout {"exp_continue_timeout"}

######################################################################
# Expect on multiple objects at once.
#
# Call as Expect::expect($timeout, -i => \@exp_list, @patternlist,
#                       -i => $exp, @pattern_list, ...);
# or $exp->expect($timeout, @patternlist, -i => \@exp_list, @patternlist,
#                 -i => $exp, @pattern_list, ...);
#
# Patterns are arrays that consist of
#   [ $pattern_type, $pattern, $sub, @subparms ]
#
#   Optional $pattern_type is '-re' (RegExp, default) or '-ex' (exact);
#
#   $sub is optional CODE ref, which is called as &{$sub}($exp, @subparms)
#     if pattern matched; may return exp_continue or exp_continue_timeout.
#
# Old-style syntax (pure pattern strings with optional type)  also supported.
#

sub expect {
	my $self;

	print STDERR ("expect(@_) called...\n") if $Expect::Debug;
	if ( defined( $_[0] ) ) {
		if ( ref( $_[0] ) and $_[0]->isa('Expect') ) {
			$self = shift;
		} elsif ( $_[0] eq 'Expect' ) {
			shift; # or as Expect->expect
		}
	}
	croak "expect(): not enough arguments, should be expect(timeout, [patterns...])"
		if @_ < 1;
	my $timeout      = shift;
	my $timeout_hook = undef;

	my @object_list;
	my %patterns;

	my @pattern_list;
	my @timeout_list;
	my $curr_list;

	if ($self) {
		$curr_list = [$self];
	} else {

		# called directly, so first parameter must be '-i' to establish
		# object list.
		$curr_list = [];
		croak
			"expect(): ERROR: if called directly (not as \$obj->expect(...), but as Expect::expect(...), first parameter MUST be '-i' to set an object (list) for the patterns to work on."
			if ( $_[0] ne '-i' );
	}

	# Let's make a list of patterns wanting to be evaled as regexps.
	my $parm;
	my $parm_nr = 1;
	while ( defined( $parm = shift ) ) {
		print STDERR ("expect(): handling param '$parm'...\n")
			if $Expect::Debug;
		if ( ref($parm) ) {
			if ( ref($parm) eq 'ARRAY' ) {
				my $err = _add_patterns_to_list(
					\@pattern_list, \@timeout_list,
					$parm_nr,       $parm
				);
				carp(
					"expect(): Warning: multiple `timeout' patterns (",
					scalar(@timeout_list), ").\r\n"
				) if @timeout_list > 1;
				$timeout_hook = $timeout_list[-1] if $timeout_list[-1];
				croak $err if $err;
				$parm_nr++;
			} else {
				croak("expect(): Unknown pattern ref $parm");
			}
		} else {

			# not a ref, is an option or raw pattern
			if ( substr( $parm, 0, 1 ) eq '-' ) {

				# it's an option
				print STDERR ("expect(): handling option '$parm'...\n")
					if $Expect::Debug;
				if ( $parm eq '-i' ) {

					# first add collected patterns to object list
					if ( scalar(@$curr_list) ) {
						push @object_list, $curr_list
							if not exists $patterns{"$curr_list"};
						push @{ $patterns{"$curr_list"} }, @pattern_list;
						@pattern_list = ();
					}

					# now put parm(s) into current object list
					if ( ref( $_[0] ) eq 'ARRAY' ) {
						$curr_list = shift;
					} else {
						$curr_list = [shift];
					}
				} elsif ( $parm eq '-re'
					or $parm eq '-ex' )
				{
					if ( ref( $_[1] ) eq 'CODE' ) {
						push @pattern_list, [ $parm_nr, $parm, shift, shift ];
					} else {
						push @pattern_list, [ $parm_nr, $parm, shift, undef ];
					}
					$parm_nr++;
				} else {
					croak("Unknown option $parm");
				}
			} else {

				# a plain pattern, check if it is followed by a CODE ref
				if ( ref( $_[0] ) eq 'CODE' ) {
					if ( $parm eq 'timeout' ) {
						push @timeout_list, shift;
						carp(
							"expect(): Warning: multiple `timeout' patterns (",
							scalar(@timeout_list),
							").\r\n"
						) if @timeout_list > 1;
						$timeout_hook = $timeout_list[-1] if $timeout_list[-1];
					} elsif ( $parm eq 'eof' ) {
						push @pattern_list, [ $parm_nr, "-$parm", undef, shift ];
					} else {
						push @pattern_list, [ $parm_nr, '-ex', $parm, shift ];
					}
				} else {
					print STDERR ("expect(): exact match '$parm'...\n")
						if $Expect::Debug;
					push @pattern_list, [ $parm_nr, '-ex', $parm, undef ];
				}
				$parm_nr++;
			}
		}
	}

	# add rest of collected patterns to object list
	carp "expect(): Empty object list" unless $curr_list;
	push @object_list, $curr_list if not exists $patterns{"$curr_list"};
	push @{ $patterns{"$curr_list"} }, @pattern_list;

	my $debug    = $self ? ${*$self}{exp_Debug}        : $Expect::Debug;
	my $internal = $self ? ${*$self}{exp_Exp_Internal} : $Expect::Exp_Internal;

	# now start matching...

	if (@Expect::Before_List) {
		print STDERR ("Starting BEFORE pattern matching...\r\n")
			if ( $debug or $internal );
		_multi_expect( 0, undef, @Expect::Before_List );
	}

	cluck("Starting EXPECT pattern matching...\r\n")
		if ( $debug or $internal );
	my @ret;
	@ret = _multi_expect(
		$timeout, $timeout_hook,
		map { [ $_, @{ $patterns{"$_"} } ] } @object_list
	);

	if (@Expect::After_List) {
		print STDERR ("Starting AFTER pattern matching...\r\n")
			if ( $debug or $internal );
		_multi_expect( 0, undef, @Expect::After_List );
	}

	return wantarray ? @ret : $ret[0];
}

######################################################################
# the real workhorse
#
sub _multi_expect {
	my ($timeout, $timeout_hook, @params) = @_;

	if ($timeout_hook) {
		croak "Unknown timeout_hook type $timeout_hook"
			unless ( ref($timeout_hook) eq 'CODE'
			or ref($timeout_hook) eq 'ARRAY' );
	}

	foreach my $pat (@params) {
		my @patterns = @{$pat}[ 1 .. $#{$pat} ];
		foreach my $exp ( @{ $pat->[0] } ) {
			${*$exp}{exp_New_Data} = 1; # first round we always try to match
			if ( exists ${*$exp}{"exp_Max_Accum"}
				and ${*$exp}{"exp_Max_Accum"} )
			{
				${*$exp}{exp_Accum} = $exp->_trim_length(
					${*$exp}{exp_Accum},
					${*$exp}{exp_Max_Accum}
				);
			}
			print STDERR (
				"${*$exp}{exp_Pty_Handle}: beginning expect.\r\n",
				"\tTimeout: ",
				( defined($timeout) ? $timeout : "unlimited" ),
				" seconds.\r\n",
				"\tCurrent time: " . localtime() . "\r\n",
			) if $Expect::Debug;

			# What are we expecting? What do you expect? :-)
			if ( ${*$exp}{exp_Exp_Internal} ) {
				print STDERR "${*$exp}{exp_Pty_Handle}: list of patterns:\r\n";
				foreach my $pattern (@patterns) {
					print STDERR (
						'  ',
						defined( $pattern->[0] )
						? '#' . $pattern->[0] . ': '
						: '',
						$pattern->[1],
						" `",
						_make_readable( $pattern->[2] ),
						"'\r\n"
					);
				}
				print STDERR "\r\n";
			}
		}
	}

	my $successful_pattern;
	my $exp_matched;
	my $err;
	my $before;
	my $after;
	my $match;
	my @matchlist;

	# Set the last loop time to now for time comparisons at end of loop.
	my $start_loop_time = time();
	my $exp_cont        = 1;

	READLOOP:
	while ($exp_cont) {
		$exp_cont = 1;
		$err      = "";
		my $rmask     = '';
		my $time_left = undef;
		if ( defined $timeout ) {
			$time_left = $timeout - ( time() - $start_loop_time );
			$time_left = 0 if $time_left < 0;
		}

		$exp_matched = undef;

		# Test for a match first so we can test the current Accum w/out
		# worrying about an EOF.

		foreach my $pat (@params) {
			my @patterns = @{$pat}[ 1 .. $#{$pat} ];
			foreach my $exp ( @{ $pat->[0] } ) {

				# build mask for select in next section...
				my $fn = $exp->fileno();
				vec( $rmask, $fn, 1 ) = 1 if defined $fn;

				next unless ${*$exp}{exp_New_Data};

				# clear error status
				${*$exp}{exp_Error} = undef;
				${*$exp}{exp_After}        = undef;
				${*$exp}{exp_Match_Number} = undef;
				${*$exp}{exp_Match}        = undef;

				# This could be huge. We should attempt to do something
				# about this.  Because the output is used for debugging
				# I'm of the opinion that showing smaller amounts if the
				# total is huge should be ok.
				# Thus the 'trim_length'
				print STDERR (
					"\r\n${*$exp}{exp_Pty_Handle}: Does `",
					$exp->_trim_length( _make_readable( ${*$exp}{exp_Accum} ) ),
					"'\r\nmatch:\r\n"
				) if ${*$exp}{exp_Exp_Internal};

				# we don't keep the parameter number anymore
				# (clashes with before & after), instead the parameter number is
				# stored inside the pattern; we keep the pattern ref
				# and look up the number later.
				foreach my $pattern (@patterns) {
					print STDERR (
						"  pattern",
						defined( $pattern->[0] ) ? ' #' . $pattern->[0] : '',
						": ",
						$pattern->[1],
						" `",
						_make_readable( $pattern->[2] ),
						"'? "
					) if ( ${*$exp}{exp_Exp_Internal} );

					# Matching exactly
					if ( $pattern->[1] eq '-ex' ) {
						my $match_index =
							index( ${*$exp}{exp_Accum}, $pattern->[2] );

						# We matched if $match_index > -1
						if ( $match_index > -1 ) {
							$before =
								substr( ${*$exp}{exp_Accum}, 0, $match_index );
							$match = substr(
								${*$exp}{exp_Accum},
								$match_index, length( $pattern->[2] )
							);
							$after = substr(
								${*$exp}{exp_Accum},
								$match_index + length( $pattern->[2] )
							);
							${*$exp}{exp_Before}       = $before;
							${*$exp}{exp_Match}        = $match;
							${*$exp}{exp_After}        = $after;
							${*$exp}{exp_Match_Number} = $pattern->[0];
							$exp_matched = $exp;
						}
					} elsif ( $pattern->[1] eq '-re' ) {

						if ($Expect::Multiline_Matching) {
							@matchlist =
								( ${*$exp}{exp_Accum}  =~ m/($pattern->[2])/m);
						} else {
							@matchlist =
								( ${*$exp}{exp_Accum} =~ m/($pattern->[2])/);
						}
						if (@matchlist) {

							# Matching regexp
							$match  = shift @matchlist;
							my $start = index ${*$exp}{exp_Accum}, $match;
							die 'The match could not be found' if $start == -1;
							$before = substr ${*$exp}{exp_Accum}, 0, $start;
							$after = substr ${*$exp}{exp_Accum}, $start + length($match);

							${*$exp}{exp_Before} = $before;
							${*$exp}{exp_Match}  = $match;
							${*$exp}{exp_After}  = $after;
							#pop @matchlist; # remove kludged empty bracket from end
							@{ ${*$exp}{exp_Matchlist} } = @matchlist;
							${*$exp}{exp_Match_Number} = $pattern->[0];
							$exp_matched = $exp;
						}
					} else {

						# 'timeout' or 'eof'
					}

					if ($exp_matched) {
						${*$exp}{exp_Accum} = $after
							unless ${*$exp}{exp_NoTransfer};
						print STDERR "YES!!\r\n"
							if ${*$exp}{exp_Exp_Internal};
						print STDERR (
							"    Before match string: `",
							$exp->_trim_length( _make_readable( ($before) ) ),
							"'\r\n",
							"    Match string: `",
							_make_readable($match),
							"'\r\n",
							"    After match string: `",
							$exp->_trim_length( _make_readable( ($after) ) ),
							"'\r\n",
							"    Matchlist: (",
							join(
								",  ",
								map { "`" . $exp->_trim_length( _make_readable( ($_) ) ) . "'" } @matchlist,
							),
							")\r\n",
						) if ( ${*$exp}{exp_Exp_Internal} );

						# call hook function if defined
						if ( $pattern->[3] ) {
							print STDERR (
								"Calling hook $pattern->[3]...\r\n",
								)
								if ( ${*$exp}{exp_Exp_Internal}
								or $Expect::Debug );
							if ( $#{$pattern} > 3 ) {

								# call with parameters if given
								$exp_cont = &{ $pattern->[3] }( $exp, @{$pattern}[ 4 .. $#{$pattern} ] );
							} else {
								$exp_cont = &{ $pattern->[3] }($exp);
							}
						}
						if ( $exp_cont and $exp_cont eq exp_continue ) {
							print STDERR ("Continuing expect, restarting timeout...\r\n")
								if ( ${*$exp}{exp_Exp_Internal}
								or $Expect::Debug );
							$start_loop_time = time(); # restart timeout count
							next READLOOP;
						} elsif ( $exp_cont
							and $exp_cont eq exp_continue_timeout )
						{
							print STDERR ("Continuing expect...\r\n")
								if ( ${*$exp}{exp_Exp_Internal}
								or $Expect::Debug );
							next READLOOP;
						}
						last READLOOP;
					}
					print STDERR "No.\r\n" if ${*$exp}{exp_Exp_Internal};
				}
				print STDERR "\r\n" if ${*$exp}{exp_Exp_Internal};

				# don't have to match again until we get new data
				${*$exp}{exp_New_Data} = 0;
			}
		} # End of matching section

		# No match, let's see what is pending on the filehandles...
		print STDERR (
			"Waiting for new data (",
			defined($time_left) ? $time_left : 'unlimited',
			" seconds)...\r\n",
		) if ( $Expect::Exp_Internal or $Expect::Debug );
		my $nfound;
		SELECT: {
			$nfound = select( $rmask, undef, undef, $time_left );
			if ( $nfound < 0 ) {
				if ( $!{EINTR} and $Expect::IgnoreEintr ) {
					print STDERR ("ignoring EINTR, restarting select()...\r\n")
						if ( $Expect::Exp_Internal or $Expect::Debug );
					next SELECT;
				}
				print STDERR ("select() returned error code '$!'\r\n")
					if ( $Expect::Exp_Internal or $Expect::Debug );

				# returned error
				$err = "4:$!";
				last READLOOP;
			}
		}

		# go until we don't find something (== timeout).
		if ( $nfound == 0 ) {

			# No pattern, no EOF. Did we time out?
			$err = "1:TIMEOUT";
			foreach my $pat (@params) {
				foreach my $exp ( @{ $pat->[0] } ) {
					$before = ${*$exp}{exp_Before} = ${*$exp}{exp_Accum};
					next if not defined $exp->fileno(); # skip already closed
					${*$exp}{exp_Error} = $err unless ${*$exp}{exp_Error};
				}
			}
			print STDERR ("TIMEOUT\r\n")
				if ( $Expect::Debug or $Expect::Exp_Internal );
			if ($timeout_hook) {
				my $ret;
				print STDERR ("Calling timeout function $timeout_hook...\r\n")
					if ( $Expect::Debug or $Expect::Exp_Internal );
				if ( ref($timeout_hook) eq 'CODE' ) {
					$ret = &{$timeout_hook}( $params[0]->[0] );
				} else {
					if ( $#{$timeout_hook} > 3 ) {
						$ret = &{ $timeout_hook->[3] }(
							$params[0]->[0],
							@{$timeout_hook}[ 4 .. $#{$timeout_hook} ]
						);
					} else {
						$ret = &{ $timeout_hook->[3] }( $params[0]->[0] );
					}
				}
				if ( $ret and $ret eq exp_continue ) {
					$start_loop_time = time(); # restart timeout count
					next READLOOP;
				}
			}
			last READLOOP;
		}

		my @bits = split( //, unpack( 'b*', $rmask ) );
		foreach my $pat (@params) {
			foreach my $exp ( @{ $pat->[0] } ) {
				next if not defined $exp->fileno(); # skip already closed
				if ( $bits[ $exp->fileno() ] ) {
					print STDERR ("${*$exp}{exp_Pty_Handle}: new data.\r\n")
						if $Expect::Debug;

					# read in what we found.
					my $buffer;
					my $nread = sysread( $exp, $buffer, 2048 );

					# Make errors (nread undef) show up as EOF.
					$nread = 0 unless defined($nread);

					if ( $nread == 0 ) {
						print STDERR ("${*$exp}{exp_Pty_Handle}: EOF\r\n")
							if ($Expect::Debug);
						$before = ${*$exp}{exp_Before} = $exp->clear_accum();
						$err = "2:EOF";
						${*$exp}{exp_Error}   = $err;
						${*$exp}{exp_Has_EOF} = 1;
						$exp_cont = undef;
						foreach my $eof_pat ( grep { $_->[1] eq '-eof' } @{$pat}[ 1 .. $#{$pat} ] ) {
							my $ret;
							print STDERR ( "Calling EOF hook $eof_pat->[3]...\r\n", )
								if ($Expect::Debug);
							if ( $#{$eof_pat} > 3 ) {

								# call with parameters if given
								$ret = &{ $eof_pat->[3] }( $exp, @{$eof_pat}[ 4 .. $#{$eof_pat} ] );
							} else {
								$ret = &{ $eof_pat->[3] }($exp);
							}
							if ($ret
								and (  $ret eq exp_continue
									or $ret eq exp_continue_timeout )
								)
							{
								$exp_cont = $ret;
							}
						}

						# is it dead?
						if ( defined( ${*$exp}{exp_Pid} ) ) {
							my $ret =
								waitpid( ${*$exp}{exp_Pid}, POSIX::WNOHANG );
							if ( $ret == ${*$exp}{exp_Pid} ) {
								printf STDERR (
									"%s: exit(0x%02X)\r\n",
									${*$exp}{exp_Pty_Handle}, $?
								) if ($Expect::Debug);
								$err = "3:Child PID ${*$exp}{exp_Pid} exited with status $?";
								${*$exp}{exp_Error} = $err;
								${*$exp}{exp_Exit}  = $?;
								delete $Expect::Spawned_PIDs{ ${*$exp}{exp_Pid} };
								${*$exp}{exp_Pid} = undef;
							}
						}
						print STDERR ("${*$exp}{exp_Pty_Handle}: closing...\r\n")
							if ($Expect::Debug);
						$exp->hard_close();
						next;
					}
					print STDERR ("${*$exp}{exp_Pty_Handle}: read $nread byte(s).\r\n")
						if ($Expect::Debug);

					# ugly hack for broken solaris ttys that spew <blank><backspace>
					# into our pretty output
					$buffer =~ s/ \cH//g if not ${*$exp}{exp_Raw_Pty};

					# Append it to the accumulator.
					${*$exp}{exp_Accum} .= $buffer;
					if ( exists ${*$exp}{exp_Max_Accum}
						and ${*$exp}{exp_Max_Accum} )
					{
						${*$exp}{exp_Accum} = $exp->_trim_length(
							${*$exp}{exp_Accum},
							${*$exp}{exp_Max_Accum}
						);
					}
					${*$exp}{exp_New_Data} = 1; # next round we try to match again

					$exp_cont = exp_continue
						if ( exists ${*$exp}{exp_Continue}
						and ${*$exp}{exp_Continue} );

					# Now propagate what we have read to other listeners...
					$exp->_print_handles($buffer);

					# End handle reading section.
				}
			}
		} # end read loop
		$start_loop_time = time() # restart timeout count
			if ( $exp_cont and $exp_cont eq exp_continue );
	}

	# End READLOOP

	# Post loop. Do we have anything?
	# Tell us status
	if ( $Expect::Debug or $Expect::Exp_Internal ) {
		if ($exp_matched) {
			print STDERR (
				"Returning from expect ",
				${*$exp_matched}{exp_Error} ? 'un' : '',
				"successfully.",
				${*$exp_matched}{exp_Error}
				? "\r\n  Error: ${*$exp_matched}{exp_Error}."
				: '',
				"\r\n"
			);
		} else {
			print STDERR ("Returning from expect with TIMEOUT or EOF\r\n");
		}
		if ( $Expect::Debug and $exp_matched ) {
			print STDERR "  ${*$exp_matched}{exp_Pty_Handle}: accumulator: `";
			if ( ${*$exp_matched}{exp_Error} ) {
				print STDERR (
					$exp_matched->_trim_length( _make_readable( ${*$exp_matched}{exp_Before} ) ),
					"'\r\n"
				);
			} else {
				print STDERR (
					$exp_matched->_trim_length( _make_readable( ${*$exp_matched}{exp_Accum} ) ),
					"'\r\n"
				);
			}
		}
	}

	if ($exp_matched) {
		return wantarray
			? (
			${*$exp_matched}{exp_Match_Number}, ${*$exp_matched}{exp_Error},
			${*$exp_matched}{exp_Match},        ${*$exp_matched}{exp_Before},
			${*$exp_matched}{exp_After},        $exp_matched,
			)
			: ${*$exp_matched}{exp_Match_Number};
	}

	return wantarray ? ( undef, $err, undef, $before, undef, undef ) : undef;
}

# Patterns are arrays that consist of
# [ $pattern_type, $pattern, $sub, @subparms ]
# optional $pattern_type is '-re' (RegExp, default) or '-ex' (exact);
# $sub is optional CODE ref, which is called as &{$sub}($exp, @subparms)
#   if pattern matched;
# the $parm_nr gets unshifted onto the array for reporting purposes.

sub _add_patterns_to_list {
	my ($listref, $timeoutlistref,$store_parm_nr, @params) = @_;

	# $timeoutlistref gets timeout patterns
	my $parm_nr        = $store_parm_nr || 1;
	foreach my $parm (@params) {
		if ( not ref($parm) eq 'ARRAY' ) {
			return "Parameter #$parm_nr is not an ARRAY ref.";
		}
		$parm = [@$parm];                    # make copy
		if ( $parm->[0] =~ m/\A-/ ) {

			# it's an option
			if (    $parm->[0] ne '-re'
				and $parm->[0] ne '-ex' )
			{
				return "Unknown option $parm->[0] in pattern #$parm_nr";
			}
		} else {
			if ( $parm->[0] eq 'timeout' ) {
				if ( defined $timeoutlistref ) {
					splice @$parm, 0, 1, ( "-$parm->[0]", undef );
					unshift @$parm, $store_parm_nr ? $parm_nr : undef;
					push @$timeoutlistref, $parm;
				}
				next;
			} elsif ( $parm->[0] eq 'eof' ) {
				splice @$parm, 0, 1, ( "-$parm->[0]", undef );
			} else {
				unshift @$parm, '-re'; # defaults to RegExp
			}
		}
		if ( @$parm > 2 ) {
			if ( ref( $parm->[2] ) ne 'CODE' ) {
				croak(
					"Pattern #$parm_nr doesn't have a CODE reference",
					"after the pattern."
				);
			}
		} else {
			push @$parm, undef;        # make sure we have three elements
		}

		unshift @$parm, $store_parm_nr ? $parm_nr : undef;
		push @$listref, $parm;
		$parm_nr++;
	}

	return;
}

######################################################################
# $process->interact([$in_handle],[$escape sequence])
# If you don't specify in_handle STDIN  will be used.
sub interact {
	my ($self, $infile, $escape_sequence) = @_;

	my $outfile;
	my @old_group = $self->set_group();

	# If the handle is STDIN we'll
	# $infile->fileno == 0 should be stdin.. follow stdin rules.
	no strict 'subs'; # Allow bare word 'STDIN'
	unless ( defined($infile) ) {
		# We need a handle object Associated with STDIN.
		$infile = IO::File->new;
		$infile->IO::File::fdopen( STDIN, 'r' );
		$outfile = IO::File->new;
		$outfile->IO::File::fdopen( STDOUT, 'w' );
	} elsif ( fileno($infile) == fileno(STDIN) ) {

		# With STDIN we want output to go to stdout.
		$outfile = IO::File->new;
		$outfile->IO::File::fdopen( STDOUT, 'w' );
	} else {
		undef($outfile);
	}

	# Here we assure ourselves we have an Expect object.
	my $in_object = Expect->exp_init($infile);
	if ( defined($outfile) ) {

		# as above.. we want output to go to stdout if we're given stdin.
		my $out_object = Expect->exp_init($outfile);
		$out_object->manual_stty(1);
		$self->set_group($out_object);
	} else {
		$self->set_group($in_object);
	}
	$in_object->set_group($self);
	$in_object->set_seq( $escape_sequence, undef ) if defined($escape_sequence);

	# interconnect normally sets stty -echo raw. Interact really sort
	# of implies we don't do that by default. If anyone wanted to they could
	# set it before calling interact, of use interconnect directly.
	my $old_manual_stty_val = $self->manual_stty();
	$self->manual_stty(1);

	# I think this is right. Don't send stuff from in_obj to stdout by default.
	# in theory whatever 'self' is should echo what's going on.
	my $old_log_stdout_val = $self->log_stdout();
	$self->log_stdout(0);
	$in_object->log_stdout(0);

	# Allow for the setting of an optional EOF escape function.
	#  $in_object->set_seq('EOF',undef);
	#  $self->set_seq('EOF',undef);
	Expect::interconnect( $self, $in_object );
	$self->log_stdout($old_log_stdout_val);
	$self->set_group(@old_group);

	# If old_group was undef, make sure that occurs. This is a slight hack since
	# it modifies the value directly.
	# Normally an undef passed to set_group will return the current groups.
	# It is possible that it may be of worth to make it possible to undef
	# The current group without doing this.
	unless (@old_group) {
		@{ ${*$self}{exp_Listen_Group} } = ();
	}
	$self->manual_stty($old_manual_stty_val);

	return;
}

sub interconnect {
	my (@handles) = @_;

	#  my ($handle)=(shift); call as Expect::interconnect($spawn1,$spawn2,...)
	my ( $nread );
	my ( $rout, $emask, $eout );
	my ( $escape_character_buffer );
	my ( $read_mask, $temp_mask ) = ( '', '' );

	# Get read/write handles
	foreach my $handle (@handles) {
		$temp_mask = '';
		vec( $temp_mask, $handle->fileno(), 1 ) = 1;

		# Under Linux w/ 5.001 the next line comes up w/ 'Uninit var.'.
		# It appears to be impossible to make the warning go away.
		# doing something like $temp_mask='' unless defined ($temp_mask)
		# has no effect whatsoever. This may be a bug in 5.001.
		$read_mask = $read_mask | $temp_mask;
	}
	if ($Expect::Debug) {
		print STDERR "Read handles:\r\n";
		foreach my $handle (@handles) {
			print STDERR "\tRead handle: ";
			print STDERR "'${*$handle}{exp_Pty_Handle}'\r\n";
			print STDERR "\t\tListen Handles:";
			foreach my $write_handle ( @{ ${*$handle}{exp_Listen_Group} } ) {
				print STDERR " '${*$write_handle}{exp_Pty_Handle}'";
			}
			print STDERR ".\r\n";
		}
	}

	#  I think if we don't set raw/-echo here we may have trouble. We don't
	# want a bunch of echoing crap making all the handles jabber at each other.
	foreach my $handle (@handles) {
		unless ( ${*$handle}{"exp_Manual_Stty"} ) {

			# This is probably O/S specific.
			${*$handle}{exp_Stored_Stty} = $handle->exp_stty('-g');
			print STDERR "Setting tty for ${*$handle}{exp_Pty_Handle} to 'raw -echo'.\r\n"
				if ${*$handle}{"exp_Debug"};
			$handle->exp_stty("raw -echo");
		}
		foreach my $write_handle ( @{ ${*$handle}{exp_Listen_Group} } ) {
			unless ( ${*$write_handle}{"exp_Manual_Stty"} ) {
				${*$write_handle}{exp_Stored_Stty} =
					$write_handle->exp_stty('-g');
				print STDERR "Setting ${*$write_handle}{exp_Pty_Handle} to 'raw -echo'.\r\n"
					if ${*$handle}{"exp_Debug"};
				$write_handle->exp_stty("raw -echo");
			}
		}
	}

	print STDERR "Attempting interconnection\r\n" if $Expect::Debug;

	# Wait until the process dies or we get EOF
	# In the case of !${*$handle}{exp_Pid} it means
	# the handle was exp_inited instead of spawned.
	CONNECT_LOOP:

	# Go until we have a reason to stop
	while (1) {

		# test each handle to see if it's still alive.
		foreach my $read_handle (@handles) {
			waitpid( ${*$read_handle}{exp_Pid}, WNOHANG )
				if ( exists( ${*$read_handle}{exp_Pid} )
				and ${*$read_handle}{exp_Pid} );
			if (    exists( ${*$read_handle}{exp_Pid} )
				and ( ${*$read_handle}{exp_Pid} )
				and ( !kill( 0, ${*$read_handle}{exp_Pid} ) ) )
			{
				print STDERR
					"Got EOF (${*$read_handle}{exp_Pty_Handle} died) reading ${*$read_handle}{exp_Pty_Handle}\r\n"
					if ${*$read_handle}{"exp_Debug"};
				last CONNECT_LOOP
					unless defined( ${ ${*$read_handle}{exp_Function} }{"EOF"} );
				last CONNECT_LOOP
					unless &{ ${ ${*$read_handle}{exp_Function} }{"EOF"} }
					( @{ ${ ${*$read_handle}{exp_Parameters} }{"EOF"} } );
			}
		}

		# Every second? No, go until we get something from someone.
		my $nfound = select( $rout = $read_mask, undef, $eout = $emask, undef );

		# Is there anything to share?  May be -1 if interrupted by a signal...
		next CONNECT_LOOP if not defined $nfound or $nfound < 1;

		# Which handles have stuff?
		my @bits = split( //, unpack( 'b*', $rout ) );
		$eout = 0 unless defined($eout);
		my @ebits = split( //, unpack( 'b*', $eout ) );

		#    print "Ebits: $eout\r\n";
		foreach my $read_handle (@handles) {
			if ( $bits[ $read_handle->fileno() ] ) {
				$nread = sysread(
					$read_handle, ${*$read_handle}{exp_Pty_Buffer},
					1024
				);

				# Appease perl -w
				$nread = 0 unless defined($nread);
				print STDERR "interconnect: read $nread byte(s) from ${*$read_handle}{exp_Pty_Handle}.\r\n"
					if ${*$read_handle}{"exp_Debug"} > 1;

				# Test for escape seq. before printing.
				# Appease perl -w
				$escape_character_buffer = ''
					unless defined($escape_character_buffer);
				$escape_character_buffer .= ${*$read_handle}{exp_Pty_Buffer};
				foreach my $escape_sequence ( keys( %{ ${*$read_handle}{exp_Function} } ) ) {
					print STDERR "Tested escape sequence $escape_sequence from ${*$read_handle}{exp_Pty_Handle}"
						if ${*$read_handle}{"exp_Debug"} > 1;

					# Make sure it doesn't grow out of bounds.
					$escape_character_buffer = $read_handle->_trim_length(
						$escape_character_buffer,
						${*$read_handle}{"exp_Max_Accum"}
					) if ( ${*$read_handle}{"exp_Max_Accum"} );
					if ( $escape_character_buffer =~ /($escape_sequence)/ ) {
						my $match = $1;
						if ( ${*$read_handle}{"exp_Debug"} ) {
							print STDERR
								"\r\ninterconnect got escape sequence from ${*$read_handle}{exp_Pty_Handle}.\r\n";

							# I'm going to make the esc. seq. pretty because it will
							# probably contain unprintable characters.
							print STDERR "\tEscape Sequence: '"
								. _trim_length(
								undef,
								_make_readable($escape_sequence)
								) . "'\r\n";
							print STDERR "\tMatched by string: '" . _trim_length( undef, _make_readable($match) ) . "'\r\n";
						}

						# Print out stuff before the escape.
						# Keep in mind that the sequence may have been split up
						# over several reads.
						# Let's get rid of it from this read. If part of it was
						# in the last read there's not a lot we can do about it now.
						if ( ${*$read_handle}{exp_Pty_Buffer} =~ /([\w\W]*)($escape_sequence)/ ) {
							$read_handle->_print_handles($1);
						} else {
							$read_handle->_print_handles( ${*$read_handle}{exp_Pty_Buffer} );
						}

						# Clear the buffer so no more matches can be made and it will
						# only be printed one time.
						${*$read_handle}{exp_Pty_Buffer} = '';
						$escape_character_buffer = '';

						# Do the function here. Must return non-zero to continue.
						# More cool syntax. Maybe I should turn these in to objects.
						last CONNECT_LOOP
							unless &{ ${ ${*$read_handle}{exp_Function} }{$escape_sequence} }
							( @{ ${ ${*$read_handle}{exp_Parameters} }{$escape_sequence} } );
					}
				}
				$nread = 0 unless defined($nread); # Appease perl -w?
				waitpid( ${*$read_handle}{exp_Pid}, WNOHANG )
					if ( defined( ${*$read_handle}{exp_Pid} )
					&& ${*$read_handle}{exp_Pid} );
				if ( $nread == 0 ) {
					print STDERR "Got EOF reading ${*$read_handle}{exp_Pty_Handle}\r\n"
						if ${*$read_handle}{"exp_Debug"};
					last CONNECT_LOOP
						unless defined( ${ ${*$read_handle}{exp_Function} }{"EOF"} );
					last CONNECT_LOOP
						unless &{ ${ ${*$read_handle}{exp_Function} }{"EOF"} }
						( @{ ${ ${*$read_handle}{exp_Parameters} }{"EOF"} } );
				}
				last CONNECT_LOOP if ( $nread < 0 ); # This would be an error
				$read_handle->_print_handles( ${*$read_handle}{exp_Pty_Buffer} );
			}

			# I'm removing this because I haven't determined what causes exceptions
			# consistently.
			if (0) #$ebits[$read_handle->fileno()])
			{
				print STDERR "Got Exception reading ${*$read_handle}{exp_Pty_Handle}\r\n"
					if ${*$read_handle}{"exp_Debug"};
				last CONNECT_LOOP
					unless defined( ${ ${*$read_handle}{exp_Function} }{"EOF"} );
				last CONNECT_LOOP
					unless &{ ${ ${*$read_handle}{exp_Function} }{"EOF"} }
					( @{ ${ ${*$read_handle}{exp_Parameters} }{"EOF"} } );
			}
		}
	}
	foreach my $handle (@handles) {
		unless ( ${*$handle}{"exp_Manual_Stty"} ) {
			$handle->exp_stty( ${*$handle}{exp_Stored_Stty} );
		}
		foreach my $write_handle ( @{ ${*$handle}{exp_Listen_Group} } ) {
			unless ( ${*$write_handle}{"exp_Manual_Stty"} ) {
				$write_handle->exp_stty( ${*$write_handle}{exp_Stored_Stty} );
			}
		}
	}

	return;
}

# user can decide if log output gets also sent to logfile
sub print_log_file {
	my ($self, @params) = @_;

	if ( ${*$self}{exp_Log_File} ) {
		if ( ref( ${*$self}{exp_Log_File} ) eq 'CODE' ) {
			${*$self}{exp_Log_File}->(@params);
		} else {
			${*$self}{exp_Log_File}->print(@params);
		}
	}

	return;
}

# we provide our own print so we can debug what gets sent to the
# processes...
sub print {
	my ( $self, @args ) = @_;

	return if not defined $self->fileno(); # skip if closed
	if ( ${*$self}{exp_Exp_Internal} ) {
		my $args = _make_readable( join( '', @args ) );
		cluck "Sending '$args' to ${*$self}{exp_Pty_Handle}\r\n";
	}
	foreach my $arg (@args) {
		while ( length($arg) > 80 ) {
			$self->SUPER::print( substr( $arg, 0, 80 ) );
			$arg = substr( $arg, 80 );
		}
		$self->SUPER::print($arg);
	}

	return;
}

# make an alias for Tcl/Expect users for a DWIM experience...
*send = \&print;

# This is an Expect standard. It's nice for talking to modems and the like
# where from time to time they get unhappy if you send items too quickly.
sub send_slow {
	my ($self, $sleep_time, @chunks) = @_;

	return if not defined $self->fileno(); # skip if closed

	# Flushing makes it so each character can be seen separately.
	my $chunk;
	while ( $chunk = shift @chunks ) {
		my @linechars = split( '', $chunk );
		foreach my $char (@linechars) {

			# How slow?
			select( undef, undef, undef, $sleep_time );

			print $self $char;
			print STDERR "Printed character \'" . _make_readable($char) . "\' to ${*$self}{exp_Pty_Handle}.\r\n"
				if ${*$self}{"exp_Debug"} > 1;

			# I think I can get away with this if I save it in accum
			if ( ${*$self}{"exp_Log_Stdout"} || ${*$self}{exp_Log_Group} ) {
				my $rmask = "";
				vec( $rmask, $self->fileno(), 1 ) = 1;

				# .01 sec granularity should work. If we miss something it will
				# probably get flushed later, maybe in an expect call.
				while ( select( $rmask, undef, undef, .01 ) ) {
					my $ret = sysread( $self, ${*$self}{exp_Pty_Buffer}, 1024 );
					last if not defined $ret or $ret == 0;

					# Is this necessary to keep? Probably.. #
					# if you need to expect it later.
					${*$self}{exp_Accum} .= ${*$self}{exp_Pty_Buffer};
					${*$self}{exp_Accum} = $self->_trim_length(
						${*$self}{exp_Accum},
						${*$self}{"exp_Max_Accum"}
					) if ( ${*$self}{"exp_Max_Accum"} );
					$self->_print_handles( ${*$self}{exp_Pty_Buffer} );
					print STDERR "Received \'"
						. $self->_trim_length( _make_readable($char) )
						. "\' from ${*$self}{exp_Pty_Handle}\r\n"
						if ${*$self}{"exp_Debug"} > 1;
				}
			}
		}
	}

	return;
}

sub test_handles {
	my ($timeout, @handle_list)  = @_;

	# This should be called by Expect::test_handles($timeout,@objects);
	my ( $allmask, $rout );
	foreach my $handle (@handle_list) {
		my $rmask = '';
		vec( $rmask, $handle->fileno(), 1 ) = 1;
		$allmask = '' unless defined($allmask);
		$allmask = $allmask | $rmask;
	}
	my $nfound = select( $rout = $allmask, undef, undef, $timeout );
	return () unless $nfound;

	# Which handles have stuff?
	my @bits = split( //, unpack( 'b*', $rout ) );

	my $handle_num  = 0;
	my @return_list = ();
	foreach my $handle (@handle_list) {

		# I go to great lengths to get perl -w to shut the hell up.
		if ( defined( $bits[ $handle->fileno() ] )
			and ( $bits[ $handle->fileno() ] ) )
		{
			push( @return_list, $handle_num );
		}
	} continue {
		$handle_num++;
	}

	return @return_list;
}

# Be nice close. This should emulate what an interactive shell does after a
# command finishes... sort of. We're not as patient as a shell.
sub soft_close {
	my ($self) = @_;

	my ( $nfound, $nread, $rmask, $end_time, $temp_buffer );

	# Give it 15 seconds to cough up an eof.
	cluck "Closing ${*$self}{exp_Pty_Handle}.\r\n" if ${*$self}{exp_Debug};
	return -1 if not defined $self->fileno(); # skip if handle already closed
	unless ( exists ${*$self}{exp_Has_EOF} and ${*$self}{exp_Has_EOF} ) {
		$end_time = time() + 15;
		while ( $end_time > time() ) {
			my $select_time = $end_time - time();

			# Sanity check.
			$select_time = 0 if $select_time < 0;
			$rmask = '';
			vec( $rmask, $self->fileno(), 1 ) = 1;
			($nfound) = select( $rmask, undef, undef, $select_time );
			last unless ( defined($nfound) && $nfound );
			$nread = sysread( $self, $temp_buffer, 8096 );

			# 0 = EOF.
			unless ( defined($nread) && $nread ) {
				print STDERR "Got EOF from ${*$self}{exp_Pty_Handle}.\r\n"
					if ${*$self}{exp_Debug};
				last;
			}
			$self->_print_handles($temp_buffer);
		}
		if ( ( $end_time <= time() ) && ${*$self}{exp_Debug} ) {
			print STDERR "Timed out waiting for an EOF from ${*$self}{exp_Pty_Handle}.\r\n";
		}
	}
	my $close_status = $self->close();
	if ( $close_status && ${*$self}{exp_Debug} ) {
		print STDERR "${*$self}{exp_Pty_Handle} closed.\r\n";
	}

	# quit now if it isn't a process.
	return $close_status unless defined( ${*$self}{exp_Pid} );

	# Now give it 15 seconds to die.
	$end_time = time() + 15;
	while ( $end_time > time() ) {
		my $returned_pid = waitpid( ${*$self}{exp_Pid}, &WNOHANG );

		# Stop here if the process dies.
		if ( defined($returned_pid) && $returned_pid ) {
			delete $Expect::Spawned_PIDs{$returned_pid};
			if ( ${*$self}{exp_Debug} ) {
				printf STDERR (
					"Pid %d of %s exited, Status: 0x%02X\r\n",
					${*$self}{exp_Pid},
					${*$self}{exp_Pty_Handle}, $?
				);
			}
			${*$self}{exp_Pid}  = undef;
			${*$self}{exp_Exit} = $?;
			return ${*$self}{exp_Exit};
		}
		sleep 1; # Keep loop nice.
	}

	# Send it a term if it isn't dead.
	if ( ${*$self}{exp_Debug} ) {
		print STDERR "${*$self}{exp_Pty_Handle} not exiting, sending TERM.\r\n";
	}
	kill TERM => ${*$self}{exp_Pid};

	# Now to be anal retentive.. wait 15 more seconds for it to die.
	$end_time = time() + 15;
	while ( $end_time > time() ) {
		my $returned_pid = waitpid( ${*$self}{exp_Pid}, &WNOHANG );
		if ( defined($returned_pid) && $returned_pid ) {
			delete $Expect::Spawned_PIDs{$returned_pid};
			if ( ${*$self}{exp_Debug} ) {
				printf STDERR (
					"Pid %d of %s terminated, Status: 0x%02X\r\n",
					${*$self}{exp_Pid},
					${*$self}{exp_Pty_Handle}, $?
				);
			}
			${*$self}{exp_Pid}  = undef;
			${*$self}{exp_Exit} = $?;
			return $?;
		}
		sleep 1;
	}

	# Since this is a 'soft' close, sending it a -9 would be inappropriate.
	return;
}

# 'Make it go away' close.
sub hard_close {
	my ($self) = @_;

	cluck "Closing ${*$self}{exp_Pty_Handle}.\r\n" if ${*$self}{exp_Debug};

	# Don't wait for an EOF.
	my $close_status = $self->close();
	if ( $close_status && ${*$self}{exp_Debug} ) {
		print STDERR "${*$self}{exp_Pty_Handle} closed.\r\n";
	}

	# Return now if handle.
	return $close_status unless defined( ${*$self}{exp_Pid} );

	# Now give it 5 seconds to die. Less patience here if it won't die.
	my $end_time = time() + 5;
	while ( $end_time > time() ) {
		my $returned_pid = waitpid( ${*$self}{exp_Pid}, &WNOHANG );

		# Stop here if the process dies.
		if ( defined($returned_pid) && $returned_pid ) {
			delete $Expect::Spawned_PIDs{$returned_pid};
			if ( ${*$self}{exp_Debug} ) {
				printf STDERR (
					"Pid %d of %s terminated, Status: 0x%02X\r\n",
					${*$self}{exp_Pid},
					${*$self}{exp_Pty_Handle}, $?
				);
			}
			${*$self}{exp_Pid}  = undef;
			${*$self}{exp_Exit} = $?;
			return ${*$self}{exp_Exit};
		}
		sleep 1; # Keep loop nice.
	}

	# Send it a term if it isn't dead.
	if ( ${*$self}{exp_Debug} ) {
		print STDERR "${*$self}{exp_Pty_Handle} not exiting, sending TERM.\r\n";
	}
	kill TERM => ${*$self}{exp_Pid};

	# wait 15 more seconds for it to die.
	$end_time = time() + 15;
	while ( $end_time > time() ) {
		my $returned_pid = waitpid( ${*$self}{exp_Pid}, &WNOHANG );
		if ( defined($returned_pid) && $returned_pid ) {
			delete $Expect::Spawned_PIDs{$returned_pid};
			if ( ${*$self}{exp_Debug} ) {
				printf STDERR (
					"Pid %d of %s terminated, Status: 0x%02X\r\n",
					${*$self}{exp_Pid},
					${*$self}{exp_Pty_Handle}, $?
				);
			}
			${*$self}{exp_Pid}  = undef;
			${*$self}{exp_Exit} = $?;
			return ${*$self}{exp_Exit};
		}
		sleep 1;
	}
	kill KILL => ${*$self}{exp_Pid};

	# wait 5 more seconds for it to die.
	$end_time = time() + 5;
	while ( $end_time > time() ) {
		my $returned_pid = waitpid( ${*$self}{exp_Pid}, &WNOHANG );
		if ( defined($returned_pid) && $returned_pid ) {
			delete $Expect::Spawned_PIDs{$returned_pid};
			if ( ${*$self}{exp_Debug} ) {
				printf STDERR (
					"Pid %d of %s killed, Status: 0x%02X\r\n",
					${*$self}{exp_Pid},
					${*$self}{exp_Pty_Handle}, $?
				);
			}
			${*$self}{exp_Pid}  = undef;
			${*$self}{exp_Exit} = $?;
			return ${*$self}{exp_Exit};
		}
		sleep 1;
	}
	warn "Pid ${*$self}{exp_Pid} of ${*$self}{exp_Pty_Handle} is HUNG.\r\n";
	${*$self}{exp_Pid} = undef;

	return;
}

# These should not be called externally.

sub _init_vars {
	my ($self) = @_;

	# for every spawned process or filehandle.
	${*$self}{exp_Log_Stdout} = $Expect::Log_Stdout
		if defined($Expect::Log_Stdout);
	${*$self}{exp_Log_Group}     = $Expect::Log_Group;
	${*$self}{exp_Debug}         = $Expect::Debug;
	${*$self}{exp_Exp_Internal}  = $Expect::Exp_Internal;
	${*$self}{exp_Manual_Stty}   = $Expect::Manual_Stty;
	${*$self}{exp_Stored_Stty}   = 'sane';
	${*$self}{exp_Do_Soft_Close} = $Expect::Do_Soft_Close;

	# sysread doesn't like my or local vars.
	${*$self}{exp_Pty_Buffer} = '';

	# Initialize accumulator.
	${*$self}{exp_Max_Accum}  = $Expect::Exp_Max_Accum;
	${*$self}{exp_Accum}      = '';
	${*$self}{exp_NoTransfer} = 0;

	# create empty expect_before & after lists
	${*$self}{exp_expect_before_list} = [];
	${*$self}{exp_expect_after_list}  = [];

	return;
}

sub _make_readable {
	my ($s) = @_;

	$s = '' if not defined($s);
	study $s;          # Speed things up?
	$s =~ s/\\/\\\\/g; # So we can tell easily(?) what is a backslash
	$s =~ s/\n/\\n/g;
	$s =~ s/\r/\\r/g;
	$s =~ s/\t/\\t/g;
	$s =~ s/\'/\\\'/g; # So we can tell whassa quote and whassa notta quote.
	$s =~ s/\"/\\\"/g;

	# Formfeed (does anyone use formfeed?)
	$s =~ s/\f/\\f/g;
	$s =~ s/\010/\\b/g;

	# escape control chars high/low, but allow ISO 8859-1 chars
	$s =~ s/([\000-\037\177-\237\377])/sprintf("\\%03lo",ord($1))/ge;

	return $s;
}

sub _trim_length {
	my ($self, $string, $length) = @_;

	# This is sort of a reverse truncation function
	# Mostly so we don't have to see the full output when we're using
	# Also used if Max_Accum gets set to limit the size of the accumulator
	# for matching functions.
	# exp_internal

	croak('No string passed') if not defined $string;

	# If we're not passed a length (_trim_length is being used for debugging
	# purposes) AND debug >= 3, don't trim.
	return ($string)
		if (defined($self)
		and ${*$self}{"exp_Debug"} >= 3
		and ( !( defined($length) ) ) );
	my $indicate_truncation = ($length ? '' : '...');
	$length ||= 1021;
	return $string if $length >= length $string;

	# We wouldn't want the accumulator to begin with '...' if max_accum is passed
	# This is because this funct. gets called internally w/ max_accum
	# and is also used to print information back to the user.
	return $indicate_truncation . substr( $string, ( length($string) - $length ), $length );
}

sub _print_handles {
	my ($self, $print_this) = @_;

	# Given crap from 'self' and the handles self wants to print to, print to
	# them. these are indicated by the handle's 'group'
	if ( ${*$self}{exp_Log_Group} ) {
		foreach my $handle ( @{ ${*$self}{exp_Listen_Group} } ) {
			$print_this = '' unless defined($print_this);

			# Appease perl -w
			print STDERR "Printed '"
				. $self->_trim_length( _make_readable($print_this) )
				. "' to ${*$handle}{exp_Pty_Handle} from ${*$self}{exp_Pty_Handle}.\r\n"
				if ( ${*$handle}{"exp_Debug"} > 1 );
			print $handle $print_this;
		}
	}

	# If ${*$self}{exp_Pty_Handle} is STDIN this would make it echo.
	print STDOUT $print_this
		if ${*$self}{"exp_Log_Stdout"};
	$self->print_log_file($print_this);
	$| = 1; # This should not be necessary but autoflush() doesn't always work.

	return;
}

sub _get_mode {
	my ($handle)      = @_;

	my ($fcntl_flags) = '';

	# What mode are we opening with? use fcntl to find out.
	$fcntl_flags = fcntl( \*{$handle}, Fcntl::F_GETFL, $fcntl_flags );
	die "fcntl returned undef during exp_init of $handle, $!\r\n"
		unless defined($fcntl_flags);
	if ( $fcntl_flags | (Fcntl::O_RDWR) ) {
		return 'rw';
	} elsif ( $fcntl_flags | (Fcntl::O_WRONLY) ) {
		return 'w';
	} else {

		# Under Solaris (among others?) O_RDONLY is implemented as 0. so |O_RDONLY would fail.
		return 'r';
	}
}

sub _undef {
	return undef;

	# Seems a little retarded but &CORE::undef fails in interconnect.
	# This is used for the default escape sequence function.
	# w/out the leading & it won't compile.
}

# clean up child processes
sub DESTROY {
	my ($self) = @_;

	my $status = $?;   # save this as it gets mangled by the terminating spawned children
	if ( ${*$self}{exp_Do_Soft_Close} ) {
		$self->soft_close();
	}
	$self->hard_close();
	$? = $status;      # restore it. otherwise deleting an Expect object may mangle $?, which is unintuitive

	return;
}

1;
__END__

=head1 NAME

Expect - automate interactions with command line programs that expose a text terminal interface.

=head1 SYNOPSIS

  use Expect;

  # create an Expect object by spawning another process
  my $exp = Expect->spawn($command, @params)
    or die "Cannot spawn $command: $!\n";

  # or by using an already opened filehandle (e.g. from Net::Telnet)
  my $exp = Expect->exp_init(\*FILEHANDLE);

  # if you prefer the OO mindset:
  my $exp = Expect->new;
  $exp->raw_pty(1);
  $exp->spawn($command, @parameters)
    or die "Cannot spawn $command: $!\n";

  # send some string there:
  $exp->send("string\n");

  # or, for the filehandle mindset:
  print $exp "string\n";

  # then do some pattern matching with either the simple interface
  $patidx = $exp->expect($timeout, @match_patterns);

  # or multi-match on several spawned commands with callbacks,
  # just like the Tcl version
  $exp->expect($timeout,
             [ qr/regex1/ => sub { my $exp = shift;
                       $exp->send("response\n");
                       exp_continue; } ],
             [ "regexp2" , \&callback, @cbparms ],
            );

  # if no longer needed, do a soft_close to nicely shut down the command
  $exp->soft_close();

  # or be less patient with
  $exp->hard_close();

Expect.pm is built to either spawn a process or take an existing filehandle
and interact with it such that normally interactive tasks can be done
without operator assistance. This concept makes more sense if you are
already familiar with the versatile Tcl version of Expect.
The public functions that make up Expect.pm are:

  Expect->new()
  Expect::interconnect(@objects_to_be_read_from)
  Expect::test_handles($timeout, @objects_to_test)
  Expect::version($version_requested | undef);
  $object->spawn(@command)
  $object->clear_accum()
  $object->set_accum($value)
  $object->debug($debug_level)
  $object->exp_internal(0 | 1)
  $object->notransfer(0 | 1)
  $object->raw_pty(0 | 1)
  $object->stty(@stty_modes) # See the IO::Stty docs
  $object->slave()
  $object->before();
  $object->match();
  $object->after();
  $object->matchlist();
  $object->match_number();
  $object->error();
  $object->command();
  $object->exitstatus();
  $object->pty_handle();
  $object->do_soft_close();
  $object->restart_timeout_upon_receive(0 | 1);
  $object->interact($other_object, $escape_sequence)
  $object->log_group(0 | 1 | undef)
  $object->log_user(0 | 1 | undef)
  $object->log_file("filename" | $filehandle | \&coderef | undef)
  $object->manual_stty(0 | 1 | undef)
  $object->match_max($max_buffersize or undef)
  $object->pid();
  $object->send_slow($delay, @strings_to_send)
  $object->set_group(@listen_group_objects | undef)
  $object->set_seq($sequence,\&function,\@parameters);

There are several configurable package variables that affect the behavior of Expect. They are:

  $Expect::Debug;
  $Expect::Exp_Internal;
  $Expect::IgnoreEintr;
  $Expect::Log_Group;
  $Expect::Log_Stdout;
  $Expect::Manual_Stty;
  $Expect::Multiline_Matching;
  $Expect::Do_Soft_Close;

=head1 DESCRIPTION

See an explanation of L<What is Expect|http://code-maven.com/expect>

The Expect module is a successor of Comm.pl and a descendent of Chat.pl. It
more closely resembles the Tcl Expect language than its predecessors. It
does not contain any of the networking code found in Comm.pl. I suspect this
would be obsolete anyway given the advent of IO::Socket and external tools
such as netcat.

Expect.pm is an attempt to have more of a switch() & case feeling to make
decision processing more fluid.  Three separate types of debugging have
been implemented to make code production easier.

It is possible to interconnect multiple file handles (and processes) much
like Tcl's Expect. An attempt was made to enable all the features of Tcl's
Expect without forcing Tcl on the victim programmer :-) .

Please, before you consider using Expect, read the FAQs about
L</"I want to automate password entry for su/ssh/scp/rsh/..."> and
L</"I want to use Expect to automate [anything with a buzzword]...">


=head1 USAGE

=over 4

=item new

Creates a new Expect object, i.e. a pty.  You can change parameters on
it before actually spawning a command.  This is important if you want
to modify the terminal settings for the slave.  See slave() below.
The object returned is actually a reblessed IO::Pty filehandle, so see
there for additional methods.


=item Expect->exp_init(\*FILEHANDLE) I<or>

=item Expect->init(\*FILEHANDLE)

Initializes $new_handle_object for use with other Expect functions. It must
be passed a B<_reference_> to FILEHANDLE if you want it to work properly.
IO::File objects are preferable. Returns a reference to the newly created
object.

You can use only real filehandles, certain tied filehandles
(e.g. Net::SSH2) that lack a fileno() will not work. Net::Telnet
objects can be used but have been reported to work only for certain
hosts. YMMV.


=item Expect->spawn($command, @parameters) I<or>

=item $object->spawn($command, @parameters) I<or>

=item Expect->new($command, @parameters)

Forks and execs $command. Returns an Expect object upon success or
C<undef> if the fork was unsuccessful or the command could not be
found.  spawn() passes its parameters unchanged to Perls exec(), so
look there for detailed semantics.

Note that if spawn cannot exec() the given command, the Expect object
is still valid and the next expect() will see "Cannot exec", so you
can use that for error handling.

Also note that you cannot reuse an object with an already spawned
command, even if that command has exited.  Sorry, but you have to
allocate a new object...


=item $object->debug(0 | 1 | 2 | 3 | undef)

Sets debug level for $object. 1 refers to general debugging
information, 2 refers to verbose debugging and 0 refers to no
debugging. If you call debug() with no parameters it will return the
current debugging level.  When the object is created the debugging
level will match that $Expect::Debug, normally 0.

The '3' setting is new with 1.05, and adds the additional
functionality of having the _full_ accumulated buffer printed every
time data is read from an Expect object. This was implemented by
request. I recommend against using this unless you think you need it
as it can create quite a quantity of output under some circumstances..


=item $object->exp_internal(1 | 0)

Sets/unsets 'exp_internal' debugging. This is similar in nature to its Tcl
counterpart. It is extremely valuable when debugging expect() sequences.
When the object is created the exp_internal setting will match the value of
$Expect::Exp_Internal, normally 0. Returns the current setting if called
without parameters. It is highly recommended that you make use of the
debugging features lest you have angry code.


=item $object->raw_pty(1 | 0)

Set pty to raw mode before spawning.  This disables echoing, CR->LF
translation and an ugly hack for broken Solaris TTYs (which send
<space><backspace> to slow things down) and thus gives a more
pipe-like behaviour (which is important if you want to transfer binary
content).  Note that this must be set I<before> spawning the program.


=item $object->stty(qw(mode1 mode2...))

Sets the tty mode for $object's associated terminal to the given
modes.  Note that on many systems the master side of the pty is not a
tty, so you have to modify the slave pty instead, see next item.  This
needs IO::Stty installed, which is no longer required.


=item $object->slave()

Returns a filehandle to the slave part of the pty.  Very useful in modifying
the terminal settings:

  $object->slave->stty(qw(raw -echo));

Typical values are 'sane', 'raw', and 'raw -echo'.  Note that I
recommend setting the terminal to 'raw' or 'raw -echo', as this avoids
a lot of hassle and gives pipe-like (i.e. transparent) behaviour
(without the buffering issue).


=item $object->print(@strings) I<or>

=item $object->send(@strings)

Sends the given strings to the spawned command.  Note that the strings
are not logged in the logfile (see print_log_file) but will probably
be echoed back by the pty, depending on pty settings (default is echo)
and thus end up there anyway.  This must also be taken into account
when expect()ing for an answer: the next string will be the command
just sent.  I suggest setting the pty to raw, which disables echo and
makes the pty transparently act like a bidirectional pipe.


=item $object->expect($timeout, @match_patterns)

=over 4

=item Simple interface

Given $timeout in seconds Expect will wait for $object's handle to produce
one of the match_patterns, which are matched exactly by default. If you
want a regexp match, prefix the pattern with '-re'.

  $object->expect(15, 'match me exactly','-re','match\s+me\s+exactly');

Due to o/s limitations $timeout should be a round number. If $timeout
is 0 Expect will check one time to see if $object's handle contains
any of the match_patterns. If $timeout is undef Expect
will wait forever for a pattern to match.

If called in a scalar context, expect() will return the position of
the matched pattern within @matched_patterns, or undef if no pattern was
matched. This is a position starting from 1, so if you want to know
which of an array of @matched_patterns matched you should subtract one
from the return value.

If called in an array context expect() will return
($matched_pattern_position, $error, $successfully_matching_string,
$before_match, and $after_match).

C<$matched_pattern_position> will contain the value that would have been
returned if expect() had been called in a scalar context.

C<$error> is
the error that occurred that caused expect() to return. $error will
contain a number followed by a string equivalent expressing the nature
of the error. Possible values are undef, indicating no error,
'1:TIMEOUT' indicating that $timeout seconds had elapsed without a
match, '2:EOF' indicating an eof was read from $object, '3: spawn
id($fileno) died' indicating that the process exited before matching
and '4:$!' indicating whatever error was set in $ERRNO during the last
read on $object's handle or during select(). All handles indicated by
set_group plus STDOUT will have all data to come out of $object
printed to them during expect() if log_group and log_stdout are set.

C<$successfully_matching_string>
C<$before_match>
C<$after_match>

Changed from older versions is the regular expression handling. By
default now all strings passed to expect() are treated as literals. To
match a regular expression pass '-re' as a parameter in front of the
pattern you want to match as a regexp.

This change makes it possible to match literals and regular expressions
in the same expect() call.

Also new is multiline matching. ^ will now match the beginning of
lines. Unfortunately, because perl doesn't use $/ in determining where
lines break using $ to find the end of a line frequently doesn't work. This
is because your terminal is returning "\r\n" at the end of every line. One
way to check for a pattern at the end of a line would be to use \r?$ instead
of $.

Example: Spawning telnet to a host, you might look for the escape
character.  telnet would return to you "\r\nEscape character is
'^]'.\r\n". To find this you might use $match='^Escape char.*\.\r?$';

  $telnet->expect(10,'-re',$match);

=item New more Tcl/Expect-like interface

  expect($timeout,
       '-i', [ $obj1, $obj2, ... ],
             [ $re_pattern, sub { ...; exp_continue; }, @subparms, ],
             [ 'eof', sub { ... } ],
             [ 'timeout', sub { ... }, \$subparm1 ],
       '-i', [ $objn, ...],
       '-ex', $exact_pattern, sub { ... },
              $exact_pattern, sub { ...; exp_continue_timeout; },
       '-re', $re_pattern, sub { ... },
       '-i', \@object_list, @pattern_list,
       ...);


It's now possible to expect on more than one connection at a time by
specifying 'C<-i>' and a single Expect object or a ref to an array
containing Expect objects, e.g.

 expect($timeout,
        '-i', $exp1, @patterns_1,
        '-i', [ $exp2, $exp3 ], @patterns_2_3,
       )

Furthermore, patterns can now be specified as array refs containing
[$regexp, sub { ...}, @optional_subprams] . When the pattern matches,
the subroutine is called with parameters ($matched_expect_obj,
@optional_subparms). The subroutine can return the symbol
`exp_continue' to continue the expect matching with timeout starting
anew or return the symbol `exp_continue_timeout' for continuing expect
without resetting the timeout count.

 $exp->expect($timeout,
              [ qr/username: /i, sub { my $self = shift;
                                       $self->send("$username\n");
                                       exp_continue; }],
              [ qr/password: /i, sub { my $self = shift;
                                       $self->send("$password\n");
                                       exp_continue; }],
             $shell_prompt);


`expect' is now exported by default.

=back

=item $object->exp_before() I<or>

=item $object->before()

before() returns the 'before' part of the last expect() call. If the last
expect() call didn't match anything, exp_before() will return the entire
output of the object accumulated before the expect() call finished.

Note that this is something different than Tcl Expects before()!!


=item $object->exp_after() I<or>

=item $object->after()

returns the 'after' part of the last expect() call. If the last
expect() call didn't match anything, exp_after() will return undef().


=item $object->exp_match() I<or>

=item $object->match()

returns the string matched by the last expect() call, undef if
no string was matched.


=item $object->exp_match_number() I<or>

=item $object->match_number()

exp_match_number() returns the number of the pattern matched by the last
expect() call. Keep in mind that the first pattern in a list of patterns is 1,
not 0. Returns undef if no pattern was matched.


=item $object->exp_matchlist() I<or>

=item $object->matchlist()

exp_matchlist() returns a list of matched substrings from the brackets
() inside the regexp that last matched. ($object->matchlist)[0]
thus corresponds to $1, ($object->matchlist)[1] to $2, etc.


=item $object->exp_error() I<or>

=item $object->error()

exp_error() returns the error generated by the last expect() call if
no pattern was matched. It is typically useful to examine the value returned by
before() to find out what the output of the object was in determining
why it didn't match any of the patterns.


=item $object->clear_accum()

Clear the contents of the accumulator for $object. This gets rid of
any residual contents of a handle after expect() or send_slow() such
that the next expect() call will only see new data from $object. The
contents of the accumulator are returned.


=item $object->set_accum($value)

Sets the content of the accumulator for $object to $value. The
previous content of the accumulator is returned.


=item $object->exp_command() I<or>

=item $object->command()

exp_command() returns the string that was used to spawn the command. Helpful
for debugging and for reused patternmatch subroutines.


=item $object->exp_exitstatus() I<or>

=item $object->exitstatus()

Returns the exit status of $object (if it already exited).


=item $object->exp_pty_handle() I<or>

=item $object->pty_handle()

Returns a string representation of the attached pty, for example:
`spawn id(5)' (pty has fileno 5), `handle id(7)' (pty was initialized
from fileno 7) or `STDIN'. Useful for debugging.


=item $object->restart_timeout_upon_receive(0 | 1)

If this is set to 1, the expect timeout is retriggered whenever something
is received from the spawned command.  This allows to perform some
aliveness testing and still expect for patterns.

    $exp->restart_timeout_upon_receive(1);
    $exp->expect($timeout,
                 [ timeout => \&report_timeout ],
                 [ qr/pattern/ => \&handle_pattern],
                );

Now the timeout isn't triggered if the command produces any kind of output,
i.e. is still alive, but you can act upon patterns in the output.


=item $object->notransfer(1 | 0)

Do not truncate the content of the accumulator after a match.
Normally, the accumulator is set to the remains that come after the
matched string.  Note that this setting is per object and not per
pattern, so if you want to have normal acting patterns that truncate
the accumulator, you have to add a

    $exp->set_accum($exp->after);

to their callback, e.g.

    $exp->notransfer(1);
    $exp->expect($timeout,
                 # accumulator not truncated, pattern1 will match again
                 [ "pattern1" => sub { my $self = shift;
                                       ...
                                     } ],
                 # accumulator truncated, pattern2 will not match again
                 [ "pattern2" => sub { my $self = shift;
                                       ...
                                       $self->set_accum($self->after());
                                     } ],
                );

This is only a temporary fix until I can rewrite the pattern matching
part so it can take that additional -notransfer argument.


=item Expect::interconnect(@objects);

Read from @objects and print to their @listen_groups until an escape sequence
is matched from one of @objects and the associated function returns 0 or undef.
The special escape sequence 'EOF' is matched when an object's handle returns
an end of file. Note that it is not necessary to include objects that only
accept data in @objects since the escape sequence is _read_ from an object.
Further note that the listen_group for a write-only object is always empty.
Why would you want to have objects listening to STDOUT (for example)?
By default every member of @objects _as well as every member of its listen
group_ will be set to 'raw -echo' for the duration of interconnection.
Setting $object->manual_stty() will stop this behavior per object.
The original tty settings will be restored as interconnect exits.

For a generic way to interconnect processes, take a look at L<IPC::Run>.


=item Expect::test_handles(@objects)

Given a set of objects determines which objects' handles have data ready
to be read. B<Returns an array> who's members are positions in @objects that
have ready handles. Returns undef if there are no such handles ready.


=item Expect::version($version_requested or undef);

Returns current version of Expect. As of .99 earlier versions are not
supported. Too many things were changed to make versioning possible.


=item $object->interact( C<\*FILEHANDLE, $escape_sequence>)

interact() is essentially a macro for calling interconnect() for
connecting 2 processes together. \*FILEHANDLE defaults to \*STDIN and
$escape_sequence defaults to undef. Interaction ceases when $escape_sequence
is read from B<FILEHANDLE>, not $object. $object's listen group will
consist solely of \*FILEHANDLE for the duration of the interaction.
\*FILEHANDLE will not be echoed on STDOUT.


=item $object->log_group(0 | 1 | undef)

Set/unset logging of $object to its 'listen group'. If set all objects
in the listen group will have output from $object printed to them during
$object->expect(), $object->send_slow(), and C<Expect::interconnect($object
, ...)>. Default value is on. During creation of $object the setting will
match the value of $Expect::Log_Group, normally 1.


=item $object->log_user(0 | 1 | undef) I<or>

=item $object->log_stdout(0 | 1 | undef)

Set/unset logging of object's handle to STDOUT. This corresponds to Tcl's
log_user variable. Returns current setting if called without parameters.
Default setting is off for initialized handles.  When a process object is
created (not a filehandle initialized with exp_init) the log_stdout setting
will match the value of $Expect::Log_Stdout variable, normally 1.
If/when you initialize STDIN it is usually associated with a tty which
will by default echo to STDOUT anyway, so be careful or you will have
multiple echoes.


=item $object->log_file("filename" | $filehandle | \&coderef | undef)

Log session to a file.  All characters send to or received from the
spawned process are written to the file.  Normally appends to the
logfile, but you can pass an additional mode of "w" to truncate the
file upon open():

  $object->log_file("filename", "w");

Returns the logfilehandle.

If called with an undef value, stops logging and closes logfile:

  $object->log_file(undef);

If called without argument, returns the logfilehandle:

  $fh = $object->log_file();

Can be set to a code ref, which will be called instead of printing
to the logfile:

  $object->log_file(\&myloggerfunc);


=item $object->print_log_file(@strings)

Prints to logfile (if opened) or calls the logfile hook function.
This allows the user to add arbitrary text to the logfile.  Note that
this could also be done as $object->log_file->print() but would only
work for log files, not code hooks.


=item $object->set_seq($sequence, \&function, \@function_parameters)

During Expect->interconnect() if $sequence is read from $object &function
will be executed with parameters @function_parameters. It is B<_highly
recommended_> that the escape sequence be a single character since the
likelihood is great that the sequence will be broken into to separate reads
from the $object's handle, making it impossible to strip $sequence from
getting printed to $object's listen group. \&function should be something
like 'main::control_w_function' and @function_parameters should be an
array defined by the caller, passed by reference to set_seq().
Your function should return a non-zero value if execution of interconnect()
is to resume after the function returns, zero or undefined if interconnect()
should return after your function returns.
The special sequence 'EOF' matches the end of file being reached by $object.
See interconnect() for details.


=item $object->set_group(@listener_objects)

@listener_objects is the list of objects that should have their handles
printed to by $object when Expect::interconnect, $object->expect() or
$object->send_slow() are called. Calling w/out parameters will return
the current list of the listener objects.


=item $object->manual_stty(0 | 1 | undef)

Sets/unsets whether or not Expect should make reasonable guesses as to
when and how to set tty parameters for $object. Will match
$Expect::Manual_Stty value (normally 0) when $object is created. If called
without parameters manual_stty() will return the current manual_stty setting.


=item $object->match_max($maximum_buffer_length | undef) I<or>

=item $object->max_accum($maximum_buffer_length | undef)

Set the maximum accumulator size for object. This is useful if you think
that the accumulator will grow out of hand during expect() calls. Since
the buffer will be matched by every match_pattern it may get slow if the
buffer gets too large. Returns current value if called without parameters.
Not defined by default.


=item $object->notransfer(0 | 1)

If set, matched strings will not be deleted from the accumulator.
Returns current value if called without parameters.  False by default.


=item $object->exp_pid() I<or>

=item $object->pid()

Return pid of $object, if one exists. Initialized filehandles will not have
pids (of course).


=item $object->send_slow($delay, @strings);

print each character from each string of @strings one at a time with $delay
seconds before each character. This is handy for devices such as modems
that can be annoying if you send them data too fast. After each character
$object will be checked to determine whether or not it has any new data ready
and if so update the accumulator for future expect() calls and print the
output to STDOUT and @listen_group if log_stdout and log_group are
appropriately set.

=back

=head2 Configurable Package Variables:

=over 4

=item $Expect::Debug

Defaults to 0. Newly created objects have a $object->debug() value
of $Expect::Debug. See $object->debug();

=item $Expect::Do_Soft_Close

Defaults to 0. When destroying objects, soft_close may take up to half
a minute to shut everything down.  From now on, only hard_close will
be called, which is less polite but still gives the process a chance
to terminate properly.  Set this to '1' for old behaviour.

=item $Expect::Exp_Internal

Defaults to 0. Newly created objects have a $object->exp_internal()
value of $Expect::Exp_Internal. See $object->exp_internal().

=item $Expect::IgnoreEintr

Defaults to 0. If set to 1, when waiting for new data, Expect will
ignore EINTR errors and restart the select() call instead.

=item $Expect::Log_Group

Defaults to 1. Newly created objects have a $object->log_group()
value of $Expect::Log_Group. See $object->log_group().

=item $Expect::Log_Stdout

Defaults to 1 for spawned commands, 0 for file handles
attached with exp_init(). Newly created objects have a
$object->log_stdout() value of $Expect::Log_Stdout. See
$object->log_stdout().

=item $Expect::Manual_Stty

Defaults to 0. Newly created objects have a $object->manual_stty()
value of $Expect::Manual_Stty. See $object->manual_stty().

=item $Expect::Multiline_Matching

Defaults to 1. Affects whether or not expect() uses the /m flag for
doing regular expression matching. If set to 1 /m is used.

This makes a difference when you are trying to match ^ and $. If
you have this on you can match lines in the middle of a page of output
using ^ and $ instead of it matching the beginning and end of the entire
expression. I think this is handy.

The $Expect::Multiline_Matching turns on and off Expect's multi-line
matching mode. But this only has an effect if you pass in a string, and
then use '-re' mode. If you pass in a regular expression value (via
qr//), then the qr//'s own flags are preserved irrespective of what it
gets interpolated into. There was a bug in Perl 5.8.x where interpolating
a regex without /m into a match with /m would incorrectly apply the /m
to the inner regex too, but this was fixed in Perl 5.10. The correct
behavior, as seen in Perl 5.10, is that if you pass in a regex (via
qr//), then $Expect::Multiline_Matching has no effect. 
So if you pass in a regex, then you must use the qr's flags
to control whether it is multiline (which by default it is not, opposite
of the default behavior of Expect).

=back

=head1 CONTRIBUTIONS

Lee Eakin <leakin@japh.itg.ti.com> has ported the kibitz script
from Tcl/Expect to Perl/Expect.

Jeff Carr <jcarr@linuxmachines.com> provided a simple example of how
handle terminal window resize events (transmitted via the WINCH
signal) in a ssh session.

You can find both scripts in the examples/ subdir.  Thanks to both!

Historical notes:

There are still a few lines of code dating back to the inspirational
Comm.pl and Chat.pl modules without which this would not have been possible.
Kudos to Eric Arnold <Eric.Arnold@Sun.com> and Randal 'Nuke your NT box with
one line of perl code' Schwartz<merlyn@stonehenge.com> for making these
available to the perl public.

As of .98 I think all the old code is toast. No way could this have been done
without it though. Special thanks to Graham Barr for helping make sense of
the IO::Handle stuff as well as providing the highly recommended IO::Tty
module.


=head1 REFERENCES

Mark Rogaski <rogaski@att.com> wrote:

"I figured that you'd like to know that Expect.pm has been very
useful to AT&T Labs over the past couple of years (since I first talked to
Austin about design decisions). We use Expect.pm for managing
the switches in our network via the telnet interface, and such automation
has significantly increased our reliability. So, you can honestly say that
one of the largest digital networks in existence (AT&T Frame Relay) uses
Expect.pm quite extensively."


=head1 FAQ - Frequently Asked Questions

This is a growing collection of things that might help.
Please send you questions that are not answered here to
RGiersig@cpan.org


=head2 What systems does Expect run on?

Expect itself doesn't have real system dependencies, but the underlying
IO::Tty needs pseudoterminals. IO::Stty uses POSIX.pm and Fcntl.pm.

I have used it on Solaris, Linux and AIX, others report *BSD and OSF
as working.  Generally, any modern POSIX Unix should do, but there
are exceptions to every rule.  Feedback is appreciated.

See L<IO::Tty> for a list of verified systems.


=head2 Can I use this module with ActivePerl on Windows?

Up to now, the answer was 'No', but this has changed.

You still cannot use ActivePerl, but if you use the Cygwin environment
(http://sources.redhat.com), which brings its own perl, and have
the latest IO::Tty (v0.05 or later) installed, it should work (feedback
appreciated).


=head2 The examples in the tutorial don't work!

The tutorial is hopelessly out of date and needs a serious overhaul.
I apologize for this, I have concentrated my efforts mainly on the
functionality.  Volunteers welcomed.


=head2 How can I find out what Expect is doing?

If you set

  $Expect::Exp_Internal = 1;

Expect will tell you very verbosely what it is receiving and sending,
what matching it is trying and what it found.  You can do this on a
per-command base with

  $exp->exp_internal(1);

You can also set

  $Expect::Debug = 1;  # or 2, 3 for more verbose output

or

  $exp->debug(1);

which gives you even more output.


=head2 I am seeing the output of the command I spawned.  Can I turn that off?

Yes, just set

  $Expect::Log_Stdout = 0;

to globally disable it or

   $exp->log_stdout(0);

for just that command.  'log_user' is provided as an alias so
Tcl/Expect user get a DWIM experience... :-)


=head2 No, I mean that when I send some text to the spawned process, it gets echoed back and I have to deal with it in the next expect.

This is caused by the pty, which has probably 'echo' enabled.  A
solution would be to set the pty to raw mode, which in general is
cleaner for communication between two programs (no more unexpected
character translations).  Unfortunately this would break a lot of old
code that sends "\r" to the program instead of "\n" (translating this
is also handled by the pty), so I won't add this to Expect just like that.
But feel free to experiment with C<$exp-E<gt>raw_pty(1)>.


=head2 How do I send control characters to a process?

A: You can send any characters to a process with the print command. To
represent a control character in Perl, use \c followed by the letter. For
example, control-G can be represented with "\cG" . Note that this will not
work if you single-quote your string. So, to send control-C to a process in
$exp, do:

  print $exp "\cC";

Or, if you prefer:

  $exp->send("\cC");

The ability to include control characters in a string like this is provided
by Perl, not by Expect.pm . Trying to learn Expect.pm without a thorough
grounding in Perl can be very daunting. We suggest you look into some of
the excellent Perl learning material, such as the books _Programming Perl_
and _Learning Perl_ by O'Reilly, as well as the extensive online Perl
documentation available through the perldoc command.


=head2 My script fails from time to time without any obvious reason.  It seems that I am sometimes loosing output from the spawned program.

You could be exiting too fast without giving the spawned program
enough time to finish.  Try adding $exp->soft_close() to terminate the
program gracefully or do an expect() for 'eof'.

Alternatively, try adding a 'sleep 1' after you spawn() the program.
It could be that pty creation on your system is just slow (but this is
rather improbable if you are using the latest IO-Tty).


=head2 I want to automate password entry for su/ssh/scp/rsh/...

You shouldn't use Expect for this.  Putting passwords, especially
root passwords, into scripts in clear text can mean severe security
problems.  I strongly recommend using other means.  For 'su', consider
switching to 'sudo', which gives you root access on a per-command and
per-user basis without the need to enter passwords.  'ssh'/'scp' can be
set up with RSA authentication without passwords.  'rsh' can use
the .rhost mechanism, but I'd strongly suggest to switch to 'ssh'; to
mention 'rsh' and 'security' in the same sentence makes an oxymoron.

It will work for 'telnet', though, and there are valid uses for it,
but you still might want to consider using 'ssh', as keeping cleartext
passwords around is very insecure.


=head2 I want to use Expect to automate [anything with a buzzword]...

Are you sure there is no other, easier way?  As a rule of thumb,
Expect is useful for automating things that expect to talk to a human,
where no formal standard applies.  For other tasks that do follow a
well-defined protocol, there are often better-suited modules that
already can handle those protocols.  Don't try to do HTTP requests by
spawning telnet to port 80, use LWP instead.  To automate FTP, take a
look at L<Net::FTP> or C<ncftp> (http://www.ncftp.org).  You don't use
a screwdriver to hammer in your nails either, or do you?


=head2 Is it possible to use threads with Expect?

Basically yes, with one restriction: you must spawn() your programs in
the main thread and then pass the Expect objects to the handling
threads. The reason is that spawn() uses fork(), and L<perlthrtut>:

  "Thinking of mixing fork() and threads?  Please lie down and wait until the feeling passes."


=head2 I want to log the whole session to a file.

Use

  $exp->log_file("filename");

or

  $exp->log_file($filehandle);

or even

  $exp->log_file(\&log_procedure);

for maximum flexibility.

Note that the logfile is appended to by default, but you can
specify an optional mode "w" to truncate the logfile:

  $exp->log_file("filename", "w");

To stop logging, just call it with a false argument:

  $exp->log_file(undef);


=head2 How can I turn off multi-line matching for my regexps?

To globally unset multi-line matching for all regexps:

  $Expect::Multiline_Matching = 0;

You can do that on a per-regexp basis by stating C<(?-m)> inside the regexp
(you need perl5.00503 or later for that).


=head2 How can I expect on multiple spawned commands?

You can use the B<-i> parameter to specify a single object or a list
of Expect objects.  All following patterns will be evaluated against
that list.

You can specify B<-i> multiple times to create groups of objects
and patterns to match against within the same expect statement.

This works just like in Tcl/Expect.

See the source example below.


=head2 I seem to have problems with ptys!

Well, pty handling is really a black magic, as it is extremely system
dependent.  I have extensively revised IO-Tty, so these problems
should be gone.

If your system is listed in the "verified" list of IO::Tty, you
probably have some non-standard setup, e.g. you compiled your
Linux-kernel yourself and disabled ptys.  Please ask your friendly
sysadmin for help.

If your system is not listed, unpack the latest version of IO::Tty,
do a 'perl Makefile.PL; make; make test; uname C<-a>' and send me the
results and I'll see what I can deduce from that.


=head2 I just want to read the output of a process without expect()ing anything. How can I do this?

[ Are you sure you need Expect for this?  How about qx() or open("prog|")? ]

By using expect without any patterns to match.

  $process->expect(undef); # Forever until EOF
  $process->expect($timeout); # For a few seconds
  $process->expect(0); # Is there anything ready on the handle now?


=head2 Ok, so now how do I get what was read on the handle?

  $read = $process->before();


=head2  Where's IO::Pty?

Find it on CPAN as IO-Tty, which provides both.


=head2 How come when I automate the passwd program to change passwords for me passwd dies before changing the password sometimes/every time?

What's happening is you are closing the handle before passwd exits.
When you close the handle to a process, it is sent a signal (SIGPIPE?)
telling it that STDOUT has gone away. The default behavior for
processes is to die in this circumstance. Two ways you can make this
not happen are:

  $process->soft_close();

This will wait 15 seconds for a process to come up with an EOF by
itself before killing it.

  $process->expect(undef);

This will wait forever for the process to match an empty set of
patterns. It will return when the process hits an EOF.

As a rule, you should always expect() the result of your transaction
before you continue with processing.


=head2 How come when I try to make a logfile with log_file() or set_group() it doesn't print anything after the last time I run expect()?

Output is only printed to the logfile/group when Expect reads from the
process, during expect(), send_slow() and interconnect().
One way you can force this is to make use of

  $process->expect(undef);

and

  $process->expect(0);

which will make expect() run with an empty pattern set forever or just
for an instant to capture the output of $process. The output is
available in the accumulator, so you can grab it using
$process->before().


=head2 I seem to have problems with terminal settings, double echoing, etc.

Tty settings are a major pain to keep track of. If you find unexpected
behavior such as double-echoing or a frozen session, doublecheck the
documentation for default settings. When in doubt, handle them
yourself using $exp->stty() and manual_stty() functions.  As of .98
you shouldn't have to worry about stty settings getting fouled unless
you use interconnect or intentionally change them (like doing -echo to
get a password).

If you foul up your terminal's tty settings, kill any hung processes
and enter 'stty sane' at a shell prompt. This should make your
terminal manageable again.

Note that IO::Tty returns ptys with your systems default setting
regarding echoing, CRLF translation etc. and Expect does not change
them.  I have considered setting the ptys to 'raw' without any
translation whatsoever, but this would break a lot of existing things,
as '\r' translation would not work anymore.  On the other hand, a raw
pty works much like a pipe and is more WYGIWYE (what you get is what
you expect), so I suggest you set it to 'raw' by yourself:

  $exp = Expect->new;
  $exp->raw_pty(1);
  $exp->spawn(...);

To disable echo:

  $exp->slave->stty(qw(-echo));


=head2 I'm spawning a telnet/ssh session and then let the user interact with it.  But screen-oriented applications on the other side don't work properly.

You have to set the terminal screen size for that.  Luckily, IO::Pty
already has a method for that, so modify your code to look like this:

  my $exp = Expect->new;
  $exp->slave->clone_winsize_from(\*STDIN);
  $exp->spawn("telnet somehost);

Also, some applications need the TERM shell variable set so they know
how to move the cursor across the screen.  When logging in, the remote
shell sends a query (Ctrl-Z I think) and expects the terminal to
answer with a string, e.g. 'xterm'.  If you really want to go that way
(be aware, madness lies at its end), you can handle that and send back
the value in $ENV{TERM}.  This is only a hand-waving explanation,
please figure out the details by yourself.


=head2 I set the terminal size as explained above, but if I resize the window, the application does not notice this.

You have to catch the signal WINCH ("window size changed"), change the
terminal size and propagate the signal to the spawned application:

  my $exp = Expect->new;
  $exp->slave->clone_winsize_from(\*STDIN);
  $exp->spawn("ssh somehost);
  $SIG{WINCH} = \&winch;

  sub winch {
    $exp->slave->clone_winsize_from(\*STDIN);
    kill WINCH => $exp->pid if $exp->pid;
    $SIG{WINCH} = \&winch;
  }

  $exp->interact();

There is an example file ssh.pl in the examples/ subdir that shows how
this works with ssh. Please note that I do strongly object against
using Expect to automate ssh login, as there are better way to do that
(see L<ssh-keygen>).

=head2 I noticed that the test uses a string that resembles, but not exactly matches, a well-known sentence that contains every character.  What does that mean?

That means you are anal-retentive. :-)  [Gotcha there!]


=head2 I get a "Could not assign a pty" error when running as a non-root user on an IRIX box?

The OS may not be configured to grant additional pty's (pseudo terminals)
to non-root users.  /usr/sbin/mkpts should be 4755, not 700 for this
to work.  I don't know about security implications if you do this.


=head2 How come I don't notice when the spawned process closes its stdin/out/err??

You are probably on one of the systems where the master doesn't get an
EOF when the slave closes stdin/out/err.

One possible solution is when you spawn a process, follow it with a
unique string that would indicate the process is finished.

  $process = Expect->spawn('telnet somehost; echo ____END____');

And then $process->expect($timeout,'____END____','other','patterns');


=head1 Source Examples


=head2 How to automate login

  my $telnet = Net::Telnet->new("remotehost") # see Net::Telnet
    or die "Cannot telnet to remotehost: $!\n";;
  my $exp = Expect->exp_init($telnet);

  # deprecated use of spawned telnet command
  # my $exp = Expect->spawn("telnet localhost")
  #   or die "Cannot spawn telnet: $!\n";;

  my $spawn_ok;
  $exp->expect($timeout,
           [
        qr'login: $',
        sub {
                  $spawn_ok = 1;
          my $fh = shift;
          $fh->send("$username\n");
                  exp_continue;
        }
           ],
           [
        'Password: $',
        sub {
          my $fh = shift;
          print $fh "$password\n";
                  exp_continue;
        }
           ],
           [
        eof =>
        sub {
                  if ($spawn_ok) {
            die "ERROR: premature EOF in login.\n";
                  } else {
            die "ERROR: could not spawn telnet.\n";
                  }
        }
           ],
           [
        timeout =>
        sub {
          die "No login.\n";
        }
           ],
           '-re', qr'[#>:] $', #' wait for shell prompt, then exit expect
          );


=head2 How to expect on multiple spawned commands

  foreach my $cmd (@list_of_commands) {
    push @commands, Expect->spawn($cmd);
  }

  expect($timeout,
     '-i', \@commands,
     [
      qr"pattern",        # find this pattern in output of all commands
      sub {
        my $obj = shift;    # object that matched
        print $obj "something\n";
        exp_continue;    # we don't want to terminate the expect call
      }
     ],
     '-i', $some_other_command,
     [
      "some other pattern",
      sub {
        my ($obj, $parmref) = @_;
        # ...

        # now we exit the expect command
      },
      \$parm
     ],
    );


=head2 How to propagate terminal sizes

  my $exp = Expect->new;
  $exp->slave->clone_winsize_from(\*STDIN);
  $exp->spawn("ssh somehost);
  $SIG{WINCH} = \&winch;

  sub winch {
    $exp->slave->clone_winsize_from(\*STDIN);
    kill WINCH => $exp->pid if $exp->pid;
    $SIG{WINCH} = \&winch;
  }

  $exp->interact();

=head1 HOMEPAGE

L<http://sourceforge.net/projects/expectperl/> though the source code is now in GitHub: L<https://github.com/jacoby/expect.pm>


=head1 MAILING LISTS

There are two mailing lists available, expectperl-announce and
expectperl-discuss, at

  http://lists.sourceforge.net/lists/listinfo/expectperl-announce

and

  http://lists.sourceforge.net/lists/listinfo/expectperl-discuss


=head1 BUG TRACKING

You can use the CPAN Request Tracker http://rt.cpan.org/ and submit
new bugs under

  http://rt.cpan.org/Ticket/Create.html?Queue=Expect


=head1 AUTHORS

(c) 1997 Austin Schutz E<lt>F<ASchutz@users.sourceforge.net>E<gt> (retired)

expect() interface & functionality enhancements (c) 1999-2006 Roland Giersig.

This module is now maintained by Dave Jacoby E<lt>F<jacoby@cpan.org>E<gt>

=head1 LICENSE

This module can be used under the same terms as Perl.


=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.

In other words: Use at your own risk.  Provided as is.  Your mileage
may vary.  Read the source, Luke!

And finally, just to be sure:

Any Use of This Product, in Any Manner Whatsoever, Will Increase the
Amount of Disorder in the Universe. Although No Liability Is Implied
Herein, the Consumer Is Warned That This Process Will Ultimately Lead
to the Heat Death of the Universe.

=cut
