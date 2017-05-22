package Net::SFTP::Foreign::Helpers;

our $VERSION = '1.74_06';

use strict;
use warnings;
use Carp qw(croak carp);

our @CARP_NOT = qw(Net::SFTP::Foreign);

use Scalar::Util qw(tainted);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( _sort_entries
		  _gen_wanted
		  _ensure_list
                  _catch_tainted_args
                  _debug
                  _gen_converter
		  _hexdump
		  $debug
                );
our @EXPORT_OK = qw( _is_lnk
                     _is_dir
                     _is_reg
                     _do_nothing
		     _glob_to_regex
                     _file_part
                     _umask_save_and_set
                     _tcroak
                     _untaint );

our $debug;

BEGIN {
    eval "use Time::HiRes 'time'"
	if ($debug and $debug & 256)
}

sub _debug {
    local ($\, $!);
    my $caller = '';
    if ( $debug & 8192) {
	$caller = (caller 1)[3];
	$caller =~ s/[\w:]*:://;
	$caller .= ': ';
    }

    my $line = join(' ', map { defined $_ ? $_ : '<undef>' } @_);

    if ($debug & 256) {
	my $ts = sprintf("%010.5f", time);
        print STDERR "#$$ $ts $caller $line\n";
    }
    else {
        print STDERR "# $caller $line\n";
    }
}

sub _hexdump {
    local ($\, $!);
    no warnings qw(uninitialized);
    my $data = shift;
    while ($data =~ /(.{1,32})/smg) {
        my $line=$1;
        my @c= (( map { sprintf "%02x",$_ } unpack('C*', $line)),
                (("  ") x 32))[0..31];
        $line=~s/(.)/ my $c=$1; unpack("c",$c)>=32 ? $c : '.' /egms;
	local $\;
        print STDERR join(" ", @c, '|', $line), "\n";
    }
}

sub _do_nothing {}

{
    my $has_sk;
    sub _has_sk {
	unless (defined $has_sk) {
            local $@;
            local $SIG{__DIE__};
	    eval { require Sort::Key };
	    $has_sk = ($@ eq '');
	}
	return $has_sk;
    }
}

sub _sort_entries {
    my $e = shift;
    if (_has_sk) {
	&Sort::Key::keysort_inplace(sub { $_->{filename} }, $e);
    }
    else {
	@$e = sort { $a->{filename} cmp $b->{filename} } @$e;
    }
}

sub _gen_wanted {
    my ($ow, $onw) = my ($w, $nw) = @_;
    if (ref $w eq 'Regexp') {
	$w = sub { $_[1]->{filename} =~ $ow }
    }

    if (ref $nw eq 'Regexp') {
	$nw = sub { $_[1]->{filename} !~ $onw }
    }
    elsif (defined $nw) {
	$nw = sub { !&$onw };
    }

    if (defined $w and defined $nw) {
	return sub { &$nw and &$w }
    }

    return $w || $nw;
}

sub _ensure_list {
    my $l = shift;
    return () unless defined $l;
    local $@;
    local $SIG{__DIE__};
    local $SIG{__WARN__};
    no warnings;
    (eval { @$l; 1 } ? @$l : $l);
}

sub _glob_to_regex {
    my ($glob, $strict_leading_dot, $ignore_case) = @_;

    my ($regex, $in_curlies, $escaping);
    my $wildcards = 0;

    my $first_byte = 1;
    while ($glob =~ /\G(.)/g) {
	my $char = $1;
	# print "char: $char\n";
	if ($char eq '\\') {
	    $escaping = 1;
	}
	else {
	    if ($first_byte) {
		if ($strict_leading_dot) {
		    $regex .= '(?=[^\.])' unless $char eq '.';
		}
		$first_byte = 0;
	    }
	    if ($char eq '/') {
		$first_byte = 1;
	    }
	    if ($escaping) {
		$regex .= quotemeta $char;
	    }
	    else {
                $wildcards++;
		if ($char eq '*') {
		    $regex .= ".*";
		}
		elsif ($char eq '?') {
		    $regex .= '.'
		}
		elsif ($char eq '{') {
		    $regex .= '(?:(?:';
		    ++$in_curlies;
		}
		elsif ($char eq '}') {
		    $regex .= "))";
		    --$in_curlies;
		    $in_curlies < 0
			and croak "invalid glob pattern";
		}
		elsif ($char eq ',' && $in_curlies) {
		    $regex .= ")|(?:";
		}
		elsif ($char eq '[') {
		    if ($glob =~ /\G((?:\\.|[^\]])+)\]/g) {
			$regex .= "[$1]"
		    }
		    else {
			croak "invalid glob pattern";
		    }
		}
		else {
                    $wildcards--;
		    $regex .= quotemeta $char;
		}
	    }

	    $escaping = 0;
	}
    }

    croak "invalid glob pattern" if $in_curlies;

    my $re = $ignore_case ? qr/^$regex$/i : qr/^$regex$/;
    wantarray ? ($re, ($wildcards > 0 ? 1 : undef)) : $re
}

sub _tcroak {
    if (${^TAINT} > 0) {
	push @_, " while running with -T switch";
        goto &croak;
    }
    if (${^TAINT} < 0) {
	push @_, " while running with -t switch";
        goto &carp;
    }
}

sub _catch_tainted_args {
    my $i;
    for (@_) {
        next unless $i++;
        if (tainted($_)) {
            my (undef, undef, undef, $subn) = caller 1;
            my $msg = ( $subn =~ /::([a-z]\w*)$/
                        ? "Insecure argument '$_' on '$1' method call"
                        : "Insecure argument '$_' on method call" );
            _tcroak($msg);
        }
        elsif (ref($_)) {
            for (grep tainted($_),
		 do { local ($@, $SIG{__DIE__}); eval { values %$_ }}) {
		my (undef, undef, undef, $subn) = caller 1;
		my $msg = ( $subn =~ /::([a-z]\w*)$/
			    ? "Insecure argument on '$1' method call"
			    : "Insecure argument on method call" );
		_tcroak($msg);
            }
        }
    }
}

sub _gen_dos2unix {
    my $unix2dos = shift;
    my $name = ($unix2dos ? 'unix2dos' : 'dos2unix');
    my $previous;
    my $done;
    sub {
        $done and die "Internal error: bad calling sequence for $name transformation";
        my $adjustment = 0;
        for (@_) {
            if ($debug and $debug & 128) {
                _debug ("before $name: previous: $previous, data follows...");
                _hexdump($_);
            }
            if (length) {
                if ($previous) {
                    $adjustment++;
                    $_ = "\x0d$_";
                }
                $adjustment -= $previous = s/\x0d\z//s;
                if ($unix2dos) {
                    $adjustment += s/(?<!\x0d)\x0a/\x0d\x0a/gs;
                }
                else {
                    $adjustment -= s/\x0d\x0a/\x0a/gs;
                }
            }
            elsif ($previous) {
                $previous = 0;
                $done = 1;
                $adjustment++;
                $_ = "\x0d";
            }
            if ($debug and $debug & 128) {
                _debug ("after $name: previous: $previous, adjustment: $adjustment, data follows...");
                _hexdump($_);
            }
            return $adjustment;
        }
    }
}

sub _gen_converter {
    my $conversion = shift;

    return undef unless defined $conversion;

    if (ref $conversion) {
        if (ref $conversion eq 'CODE') {
            return sub {
                my $before = length $_[0];
                $conversion->($_[0]);
                length($_[0]) - $before;
            }
        }
        else {
            croak "unsupported conversion argument"
        }
    }
    elsif ($conversion eq 'dos2unix') {
        return _gen_dos2unix(0);
    }
    elsif ($conversion eq 'unix2dos') {
        return _gen_dos2unix(1);
    }
    else {
        croak "unknown conversion '$conversion'";
    }
}

sub _is_lnk { (0120000 & shift) == 0120000 }
sub _is_dir { (0040000 & shift) == 0040000 }
sub _is_reg { (0100000 & shift) == 0100000 }

sub _file_part {
    my $path = shift;
    $path =~ m{([^/]*)$} or croak "unable to get file part from path '$path'";
    $1;
}

sub _untaint {
    if (${^TAINT}) {
        for (@_) {
            defined or next;
            ($_) = /(.*)/s
        }
    }
}

sub _umask_save_and_set {
    my $umask = shift;
    if (defined $umask) {
        my $old = umask $umask;
        return bless \$old, 'Net::SFTP::Foreign::Helpers::umask_saver';
    }
    ()
}

sub Net::SFTP::Foreign::Helpers::umask_saver::DESTROY { umask ${$_[0]} }

1;

