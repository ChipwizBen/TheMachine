package Net::SFTP::Foreign::Common;

our $VERSION = '1.76_02';

use strict;
use warnings;
use Carp;

BEGIN {
    # Some versions of Scalar::Util are crippled
    require Scalar::Util;
    eval { Scalar::Util->import(qw(dualvar tainted)); 1 }
        or do {
            *tainted = sub { croak "The version of Scalar::Util installed on your system "
                                 . "does not provide 'tainted'" };
            *dualvar = sub { $_[0] };
        };
}

use Net::SFTP::Foreign::Helpers qw(_gen_wanted _ensure_list _debug _glob_to_regex _is_lnk _is_dir $debug);
use Net::SFTP::Foreign::Constants qw(:status);

my %status_str = ( SSH2_FX_OK, "OK",
		   SSH2_FX_EOF, "End of file",
		   SSH2_FX_NO_SUCH_FILE, "No such file or directory",
		   SSH2_FX_PERMISSION_DENIED, "Permission denied",
		   SSH2_FX_FAILURE, "Failure",
		   SSH2_FX_BAD_MESSAGE, "Bad message",
		   SSH2_FX_NO_CONNECTION, "No connection",
		   SSH2_FX_CONNECTION_LOST, "Connection lost",
		   SSH2_FX_OP_UNSUPPORTED, "Operation unsupported" );

our $debug;

sub _set_status {
    my $sftp = shift;
    my $code = shift;
    if ($code) {
        my $str;
        if (@_) {
            $str = join ': ', @_;
            ($str) = $str =~ /(.*)/
                if (${^TAINT} && tainted $str);
        }
        unless (defined $str and length $str) {
            $str = $status_str{$code} || "Unknown status ($code)";
        }
        $debug and $debug & 64 and _debug("_set_status code: $code, str: $str");
	return $sftp->{_status} = dualvar($code, $str);
    }
    else {
	return $sftp->{_status} = 0;
    }
}

sub status { shift->{_status} }

sub _set_error {
    my $sftp = shift;
    my $code = shift;
    if ($code) {
        my $str;
        if (@_) {
            $str = join ': ', @_;
            ($str) = $str =~ /(.*)/
                if (${^TAINT} && tainted $str);
        }
        else {
	    $str = $code ? "Unknown error $code" : "OK";
	}
        $debug and $debug & 64 and _debug("_set_err code: $code, str: $str");
	my $error = $sftp->{_error} = dualvar $code, $str;

        # FIXME: use a better approach to determine when some error is fatal
        croak $error if $sftp->{_autodie};
    }
    elsif ($sftp->{_error}) {
        # FIXME: use a better approach to determine when some error is fatal
        if ($sftp->{_error} != Net::SFTP::Foreign::Constants::SFTP_ERR_CONNECTION_BROKEN()) {
            $sftp->{_error} = 0;
        }
    }
    return $sftp->{_error}
}

sub _clear_error_and_status {
    my $sftp = shift;
    $sftp->_set_error;
    $sftp->_set_status;
}

sub _copy_error {
    my ($sftp, $other) = @_;
    unless ($sftp->{_error} and
            $sftp->{_error} == Net::SFTP::Foreign::Constants::SFTP_ERR_CONNECTION_BROKEN()) {
        $sftp->{_error} = $other->{_error};
    }
}

sub error { shift->{_error} }

sub die_on_error {
    my $sftp = shift;
    $sftp->{_error} and croak(@_ ? "@_: $sftp->{_error}" : $sftp->{_error});
}

sub _ok_or_autodie {
    my $sftp = shift;
    return 1 unless $sftp->{_error};
    $sftp->{_autodie} and croak $sftp->{_error};
    undef;
}

sub _set_errno {
    my $sftp = shift;
    if ($sftp->{_error}) {
	my $status = $sftp->{_status} + 0;
	my $error = $sftp->{_error} + 0;
	if ($status == SSH2_FX_EOF) {
	    return;
	}
        elsif ($status == SSH2_FX_NO_SUCH_FILE) {
	    $! = Errno::ENOENT();
	}
	elsif ($status == SSH2_FX_PERMISSION_DENIED) {
	    $! = Errno::EACCES();
	}
	elsif ($status == SSH2_FX_BAD_MESSAGE) {
	    $! = Errno::EBADMSG();
	}
	elsif ($status == SSH2_FX_OP_UNSUPPORTED) {
	    $! = Errno::ENOTSUP()
	}
	elsif ($status) {
	    $! = Errno::EIO()
	}
    }
}

sub _best_effort {
    my $sftp = shift;
    my $best_effort = shift;
    my $method = shift;
    local ($sftp->{_error}, $sftp->{_autodie}) if $best_effort;
    $sftp->$method(@_);
    return (($best_effort or not $sftp->{_error}) ? 1 : undef);
}

sub _call_on_error {
    my ($sftp, $on_error, $entry) = @_;
    $on_error and $sftp->error
	and $on_error->($sftp, $entry);
    $sftp->_clear_error_and_status;
}

# this method code is a little convoluted because we are trying to
# keep in memory as few entries as possible!!!
sub find {
    @_ >= 1 or croak 'Usage: $sftp->find($remote_dirs, %opts)';

    my $self = shift;
    my %opts = @_ & 1 ? ('dirs', @_) : @_;

    $self->_clear_error_and_status;

    my $dirs = delete $opts{dirs};
    my $follow_links = delete $opts{follow_links};
    my $on_error = delete $opts{on_error};
    local $self->{_autodie} if $on_error;
    my $realpath = delete $opts{realpath};
    my $ordered = delete $opts{ordered};
    my $names_only = delete $opts{names_only};
    my $atomic_readdir = delete $opts{atomic_readdir};
    my $wanted = _gen_wanted( delete $opts{wanted},
			      delete $opts{no_wanted} );
    my $descend = _gen_wanted( delete $opts{descend},
			       delete $opts{no_descend} );

    %opts and croak "invalid option(s) '".CORE::join("', '", keys %opts)."'";

    $dirs = '.' unless defined $dirs;

    my $wantarray = wantarray;
    my (@res, $res);
    my %done;
    my %rpdone; # used to detect cycles

    my @dirs = _ensure_list $dirs;
    my @queue = map { { filename => $_ } } ($ordered ? sort @dirs : @dirs);

    # we use a clousure instead of an auxiliary method to have access
    # to the state:

    my $task = sub {
	my $entry = shift;
	my $fn = $entry->{filename};
	for (1) {
	    my $follow = ($follow_links and _is_lnk($entry->{a}->perm));

	    if ($follow or $realpath) {
		unless (defined $entry->{realpath}) {
                    my $rp = $entry->{realpath} = $self->realpath($fn);
                    next unless (defined $rp and not $rpdone{$rp}++);
		}
	    }

	    if ($follow) {
                my $a = $self->stat($fn);
                if (defined $a) {
                    $entry->{a} = $a;
                    # we queue it for reprocessing as it could be a directory
                    unshift @queue, $entry;
                }
		next;
	    }

	    if (!$wanted or $wanted->($self, $entry)) {
		if ($wantarray) {
                    push @res, ( $names_only
                                 ? ( exists $entry->{realpath}
                                     ? $entry->{realpath}
                                     : $entry->{filename} )
                                 : $entry )
		}
		else {
		    $res++;
		}
	    }
	}
	continue {
	    $self->_call_on_error($on_error, $entry)
	}
    };

    my $try;
    while (@queue) {
	no warnings 'uninitialized';
	$try = shift @queue;
	my $fn = $try->{filename};

	my $a = $try->{a} ||= $self->lstat($fn)
	    or next;

	next if (_is_dir($a->perm) and $done{$fn}++);

	$task->($try);

	if (_is_dir($a->perm)) {
	    if (!$descend or $descend->($self, $try)) {
		if ($ordered or $atomic_readdir) {
		    my $ls = $self->ls( $fn,
					ordered => $ordered,
					_wanted => sub {
					    my $child = $_[1]->{filename};
					    if ($child !~ /^\.\.?$/) {
						$_[1]->{filename} = $self->join($fn, $child);
						return 1;
					    }
					    undef;
					})
			or next;
		    unshift @queue, @$ls;
		}
		else {
		    $self->ls( $fn,
			       _wanted => sub {
				   my $entry = $_[1];
				   my $child = $entry->{filename};
				   if ($child !~ /^\.\.?$/) {
				       $entry->{filename} = $self->join($fn, $child);

				       if (_is_dir($entry->{a}->perm)) {
					   push @queue, $entry;
				       }
				       else {
					   $task->($entry);
				       }
				   }
				   undef } )
			or next;
		}
	    }
	}
    }
    continue {
	$self->_call_on_error($on_error, $try)
    }

    return wantarray ? @res : $res;
}


sub glob {
    @_ >= 2 or croak 'Usage: $sftp->glob($pattern, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $glob, %opts) = @_;
    return () if $glob eq '';

    my $on_error = delete $opts{on_error};
    local $sftp->{_autodie} if $on_error;
    my $follow_links = delete $opts{follow_links};
    my $ignore_case = delete $opts{ignore_case};
    my $names_only = delete $opts{names_only};
    my $realpath = delete $opts{realpath};
    my $ordered = delete $opts{ordered};
    my $wanted = _gen_wanted( delete $opts{wanted},
			      delete $opts{no_wanted});
    my $strict_leading_dot = delete $opts{strict_leading_dot};
    $strict_leading_dot = 1 unless defined $strict_leading_dot;

    %opts and _croak_bad_options(keys %opts);

    my $wantarray = wantarray;

    my (@parts, $top);
    if (ref $glob eq 'Regexp') {
        @parts = ($glob);
        $top = '.';
    }
    else {
        @parts = ($glob =~ m{\G/*([^/]+)}g);
        push @parts, '.' unless @parts;
        $top = ( $glob =~ m|^/|  ? '/' : '.');
    }
    my @res = ( {filename => $top} );
    my $res = 0;

    while (@parts and @res) {
	my @parents = @res;
	@res = ();
	my $part = shift @parts;
        my ($re, $has_wildcards);
        if (ref $part eq 'Regexp') {
            $re = $part;
            $has_wildcards = 1;
        }
	else {
            ($re, $has_wildcards) = _glob_to_regex($part, $strict_leading_dot, $ignore_case);
        }

	for my $parent (@parents) {
	    my $pfn = $parent->{filename};
            if ($has_wildcards) {
                $sftp->ls( $pfn,
                           ordered => $ordered,
                           _wanted => sub {
                               my $e = $_[1];
                               if ($e->{filename} =~ $re) {
                                   my $fn = $e->{filename} = $sftp->join($pfn, $e->{filename});
                                   if ( (@parts or $follow_links)
                                        and _is_lnk($e->{a}->perm) ) {
                                       if (my $a = $sftp->stat($fn)) {
                                           $e->{a} = $a;
                                       }
                                       else {
                                           $on_error and $sftp->_call_on_error($on_error, $e);
                                           return undef;
                                       }
                                   }
                                   if (@parts) {
                                       push @res, $e if _is_dir($e->{a}->perm)
                                   }
                                   elsif (!$wanted or $wanted->($sftp, $e)) {
                                       if ($wantarray) {
                                           if ($realpath) {
                                               my $rp = $e->{realpath} = $sftp->realpath($e->{filename});
                                               unless (defined $rp) {
                                                   $on_error and $sftp->_call_on_error($on_error, $e);
                                                   return undef;
                                               }
                                           }
                                           push @res, ($names_only
                                                       ? ($realpath ? $e->{realpath} : $e->{filename} )
                                                       : $e);
                                       }
                                       $res++;
                                   }
                               }
                               return undef
                           } )
                    or ($on_error and $sftp->_call_on_error($on_error, $parent));
            }
            else {
                my $fn = $sftp->join($pfn, $part);
                my $method = ((@parts or $follow_links) ? 'stat' : 'lstat');
                if (my $a = $sftp->$method($fn)) {
                    my $e = { filename => $fn, a => $a };
                    if (@parts) {
                        push @res, $e if _is_dir($a->{perm})
                    }
                    elsif (!$wanted or $wanted->($sftp, $e)) {
                        if ($wantarray) {
                            if ($realpath) {
                                my $rp = $fn = $e->{realpath} = $sftp->realpath($fn);
                                unless (defined $rp) {
                                    $on_error and $sftp->_call_on_error($on_error, $e);
                                    next;
                                }
                            }
                            push @res, ($names_only ? $fn : $e)
                        }
                        $res++;
                    }
                }
            }
        }
    }
    return wantarray ? @res : $res;
}

sub test_d {
    my ($sftp, $name) = @_;
    {
        local $sftp->{_autodie};
        my $a = $sftp->stat($name);
        return _is_dir($a->perm) if $a;
    }
    if ($sftp->{_status} == SSH2_FX_NO_SUCH_FILE) {
        $sftp->_clear_error_and_status;
        return undef;
    }
    $sftp->_ok_or_autodie;
}

sub test_e {
    my ($sftp, $name) = @_;
    {
        local $sftp->{_autodie};
        $sftp->stat($name) and return 1;
    }
    if ($sftp->{_status} == SSH2_FX_NO_SUCH_FILE) {
        $sftp->_clear_error_and_status;
        return undef;
    }
    $sftp->_ok_or_autodie;
}

1;

