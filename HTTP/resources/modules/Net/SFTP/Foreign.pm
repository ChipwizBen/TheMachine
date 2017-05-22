package Net::SFTP::Foreign;

our $VERSION = '1.87';

use strict;
use warnings;
use warnings::register;

use Carp qw(carp croak);

use Symbol ();
use Errno ();
use Fcntl;
use File::Spec ();
use Time::HiRes ();
use POSIX ();

BEGIN {
    if ($] >= 5.008) {
        require Encode;
    }
    else {
        # Work around for incomplete Unicode handling in perl 5.6.x
        require bytes;
        bytes->import();
        *Encode::encode = sub { $_[1] };
        *Encode::decode = sub { $_[1] };
        *utf8::downgrade = sub { 1 };
    }
}

# we make $Net::SFTP::Foreign::Helpers::debug an alias for
# $Net::SFTP::Foreign::debug so that the user can set it without
# knowing anything about the Helpers package!
our $debug;
BEGIN { *Net::SFTP::Foreign::Helpers::debug = \$debug };
use Net::SFTP::Foreign::Helpers qw(_is_reg _is_lnk _is_dir _debug
                                   _sort_entries _gen_wanted
                                   _gen_converter _hexdump
                                   _ensure_list _catch_tainted_args
                                   _file_part _umask_save_and_set
                                   _untaint);
use Net::SFTP::Foreign::Constants qw( :fxp :flags :att
				      :status :error
				      SSH2_FILEXFER_VERSION );
use Net::SFTP::Foreign::Attributes;
use Net::SFTP::Foreign::Buffer;
require Net::SFTP::Foreign::Common;
our @ISA = qw(Net::SFTP::Foreign::Common);

our $dirty_cleanup;
my $windows;

BEGIN {
    $windows = $^O =~ /Win(?:32|64)/;

    if ($^O =~ /solaris/i) {
	$dirty_cleanup = 1 unless defined $dirty_cleanup;
    }
}

my $thread_generation = 1;
sub CLONE { $thread_generation++ }

sub _deprecated {
    if (warnings::enabled('deprecated') and warnings::enabled(__PACKAGE__)) {
        Carp::carp(join('', @_));
    }
}

sub _next_msg_id { shift->{_msg_id}++ }

use constant _empty_attributes => Net::SFTP::Foreign::Attributes->new;

sub _queue_new_msg {
    my $sftp = shift;
    my $code = shift;
    my $id = $sftp->_next_msg_id;
    my $msg = Net::SFTP::Foreign::Buffer->new(int8 => $code, int32 => $id, @_);
    $sftp->_queue_msg($msg);
    return $id;
}

sub _queue_msg {
    my ($sftp, $buf) = @_;

    my $bytes = $buf->bytes;
    my $len = length $bytes;

    if ($debug and $debug & 1) {
	$sftp->{_queued}++;
	_debug(sprintf("queueing msg len: %i, code:%i, id:%i ... [$sftp->{_queued}]",
		       $len, unpack(CN => $bytes)));

        $debug & 16 and _hexdump(pack('N', length($bytes)) . $bytes);
    }

    $sftp->{_bout} .= pack('N', length($bytes));
    $sftp->{_bout} .= $bytes;
}


sub _do_io { $_[0]->{_backend}->_do_io(@_) }

sub _conn_lost {
    my ($sftp, $status, $err, @str) = @_;

    $debug and $debug & 32 and _debug("_conn_lost");

    $sftp->{_status} or
	$sftp->_set_status(defined $status ? $status : SSH2_FX_CONNECTION_LOST);

    $sftp->{_error} or
	$sftp->_set_error((defined $err ? $err : SFTP_ERR_CONNECTION_BROKEN),
			  (@str ? @str : "Connection to remote server is broken"));

    undef $sftp->{_connected};
}

sub _conn_failed {
    my $sftp = shift;
    $sftp->_conn_lost(SSH2_FX_NO_CONNECTION,
                      SFTP_ERR_CONNECTION_BROKEN,
                      @_)
	unless $sftp->{_error};
}

sub _get_msg {
    my $sftp = shift;

    $debug and $debug & 1 and _debug("waiting for message... [$sftp->{_queued}]");

    unless ($sftp->_do_io($sftp->{_timeout})) {
	$sftp->_conn_lost(undef, undef, "Connection to remote server stalled");
	return undef;
    }

    my $bin = \$sftp->{_bin};
    my $len = unpack N => substr($$bin, 0, 4, '');
    my $msg = Net::SFTP::Foreign::Buffer->make(substr($$bin, 0, $len, ''));

    if ($debug and $debug & 1) {
	$sftp->{_queued}--;
        my ($code, $id, $status) = unpack( CNN => $$msg);
	$id = '-' if $code == SSH2_FXP_VERSION;
        $status = '-' unless $code == SSH2_FXP_STATUS;
	_debug(sprintf("got it!, len:%i, code:%i, id:%s, status: %s",
                       $len, $code, $id, $status));
        $debug & 8 and _hexdump($$msg);
    }

    return $msg;
}

sub _croak_bad_options {
    if (@_) {
        my $s = (@_ > 1 ? 's' : '');
        croak "Invalid option$s '" . CORE::join("', '", @_) . "' or bad combination of options";
    }
}

sub _fs_encode {
    my ($sftp, $path) = @_;
    Encode::encode($sftp->{_fs_encoding}, $path);
}

sub _fs_decode {
    my ($sftp, $path) = @_;
    Encode::decode($sftp->{_fs_encoding}, $path);
}

sub new {
    ${^TAINT} and &_catch_tainted_args;

    my $class = shift;
    unshift @_, 'host' if @_ & 1;
    my %opts = @_;

    my $sftp = { _msg_id    => 0,
		 _bout      => '',
		 _bin       => '',
		 _connected => 1,
		 _queued    => 0,
                 _error     => 0,
                 _status    => 0 };

    bless $sftp, $class;

    if ($debug) {
        _debug "This is Net::SFTP::Foreign $Net::SFTP::Foreign::VERSION";
        _debug "Loaded from $INC{'Net/SFTP/Foreign.pm'}";
        _debug "Running on Perl $^V for $^O";
        _debug "debug set to $debug";
        _debug "~0 is " . ~0;
    }

    $sftp->_clear_error_and_status;

    my $backend = delete $opts{backend};
    unless (ref $backend) {
	$backend = ($windows ? 'Windows' : 'Unix')
	    unless (defined $backend);
	$backend =~ /^\w+$/
	    or croak "Bad backend name $backend";
	my $backend_class = "Net::SFTP::Foreign::Backend::$backend";
	eval "require $backend_class; 1"
	    or croak "Unable to load backend $backend: $@";
	$backend = $backend_class->_new($sftp, \%opts);
    }
    $sftp->{_backend} = $backend;

    if ($debug) {
        my $class = ref($backend) || $backend;
        no strict 'refs';
        my $version = ${$class .'::VERSION'} || 0;
        _debug "Using backend $class $version";
    }

    my %defs = $backend->_defaults;

    $sftp->{_autodie} = delete $opts{autodie};
    $sftp->{_block_size} = delete $opts{block_size} || $defs{block_size} || 32*1024;
    $sftp->{_min_block_size} = delete $opts{min_block_size} || $defs{min_block_size} || 512;
    $sftp->{_queue_size} = delete $opts{queue_size} || $defs{queue_size} || 32;
    $sftp->{_read_ahead} = $defs{read_ahead} || $sftp->{_block_size} * 4;
    $sftp->{_write_delay} = $defs{write_delay} || $sftp->{_block_size} * 8;
    $sftp->{_autoflush} = delete $opts{autoflush};
    $sftp->{_late_set_perm} = delete $opts{late_set_perm};
    $sftp->{_dirty_cleanup} = delete $opts{dirty_cleanup};
    $sftp->{_remote_has_volumes} = delete $opts{remote_has_volumes};

    $sftp->{_timeout} = delete $opts{timeout};
    defined $sftp->{_timeout} and $sftp->{_timeout} <= 0 and croak "invalid timeout";

    $sftp->{_fs_encoding} = delete $opts{fs_encoding};
    if (defined $sftp->{_fs_encoding}) {
        $] < 5.008
            and carp "fs_encoding feature is not supported in this perl version $]";
    }
    else {
        $sftp->{_fs_encoding} = 'utf8';
    }

    $sftp->autodisconnect(delete $opts{autodisconnect});

    $backend->_init_transport($sftp, \%opts);
    %opts and _croak_bad_options(keys %opts);

    $sftp->_init unless $sftp->{_error};
    $backend->_after_init($sftp);
    $sftp
}

sub autodisconnect {
    my ($sftp, $ad) = @_;
    if (not defined $ad or $ad == 2) {
        $debug and $debug & 4 and _debug "setting disconnecting pid to $$ and thread to $thread_generation";
        $sftp->{_disconnect_by_pid} = $$;
        $sftp->{_disconnect_by_thread} = $thread_generation;
    }
    else {
        delete $sftp->{_disconnect_by_thread};
        if ($ad == 0) {
            $sftp->{_disconnect_by_pid} = -1;
        }
        elsif ($ad == 1) {
            delete $sftp->{_disconnect_by_pid};
        }
        else {
            croak "bad value '$ad' for autodisconnect";
        }
    }
    1;
}

sub disconnect {
    my $sftp = shift;
    my $pid = delete $sftp->{pid};

    $debug and $debug & 4 and _debug("$sftp->disconnect called (ssh pid: ".($pid||'').")");

    local $sftp->{_autodie};
    $sftp->_conn_lost;

    if (defined $pid) {
        close $sftp->{ssh_out} if (defined $sftp->{ssh_out} and not $sftp->{_ssh_out_is_not_dupped});
        close $sftp->{ssh_in} if defined $sftp->{ssh_in};
        if ($windows) {
	    kill KILL => $pid
                and waitpid($pid, 0);
            $debug and $debug & 4 and _debug "process $pid reaped";
        }
        else {
	    my $dirty = ( defined $sftp->{_dirty_cleanup}
                          ? $sftp->{_dirty_cleanup}
                          : $dirty_cleanup );

	    if ($dirty or not defined $dirty) {
                $debug and $debug & 4 and _debug("starting dirty cleanup of process $pid");
            OUT: for my $sig (($dirty ? () : 0), qw(TERM TERM KILL KILL)) {
                    $debug and $debug & 4 and _debug("killing process $pid with signal $sig");
		    $sig and kill $sig, $pid;

                    local ($@, $SIG{__DIE__}, $SIG{__WARN__});
                    my $deadline = Time::HiRes::time + 8;
                    my $dt = 0.01;
                    while (Time::HiRes::time < $deadline) {
                        my $wpr = waitpid($pid, POSIX::WNOHANG());
                        $debug and $debug & 4 and _debug("waitpid returned ", $wpr);
                        last OUT if $wpr or $! == Errno::ECHILD();
                        Time::HiRes::sleep($dt);
                        $dt *= 1.2;
                    }
		}
	    }
	    else {
		while (1) {
		    last if waitpid($pid, 0) > 0;
		    if ($! != Errno::EINTR()) {
			warn "internal error: unexpected error in waitpid($pid): $!"
			    if $! != Errno::ECHILD();
			last;
		    }
		}
	    }
            $debug and $debug & 4 and _debug "process $pid reaped";
        }
    }
    close $sftp->{_pty} if defined $sftp->{_pty};
    1
}

sub DESTROY {
    local ($?, $!, $@);

    my $sftp = shift;
    my $dbpid = $sftp->{_disconnect_by_pid};
    my $dbthread = $sftp->{_disconnect_by_thread};

    $debug and $debug & 4 and _debug("$sftp->DESTROY called (current pid: $$, disconnect_by_pid: " .
                                     ($dbpid || '') .
                                     "), current thread generation: $thread_generation, disconnect_by_thread: " .
                                     ($dbthread || '') . ")");

    if (!defined $dbpid or ($dbpid == $$ and $dbthread == $thread_generation)) {
        $sftp->disconnect
    }
    else {
        $debug and $debug & 4 and _debug "skipping disconnection because pid and/or thread generation don't match";
    }
}

sub _init {
    my $sftp = shift;
    $sftp->_queue_msg( Net::SFTP::Foreign::Buffer->new(int8 => SSH2_FXP_INIT,
						       int32 => SSH2_FILEXFER_VERSION));

    if (my $msg = $sftp->_get_msg) {
	my $type = $msg->get_int8;
	if ($type == SSH2_FXP_VERSION) {
	    my $version = $msg->get_int32;

	    $sftp->{server_version} = $version;
            $sftp->{server_extensions} = {};
            while (length $$msg) {
                my $key = $msg->get_str;
                my $value = $msg->get_str;
                $sftp->{server_extensions}{$key} = $value;

                if ($key eq 'vendor-id') {
                    my $vid = Net::SFTP::Foreign::Buffer->make("$value");
                    $sftp->{_ext__vendor_id} = [ Encode::decode(utf8 => $vid->get_str),
                                                 Encode::decode(utf8 => $vid->get_str),
                                                 Encode::decode(utf8 => $vid->get_str),
                                                 $vid->get_int64 ];
                }
                elsif ($key eq 'supported2') {
                    my $s2 = Net::SFTP::Foreign::Buffer->make("$value");
                    $sftp->{_ext__supported2} = [ $s2->get_int32,
                                                  $s2->get_int32,
                                                  $s2->get_int32,
                                                  $s2->get_int32,
                                                  $s2->get_int32,
                                                  $s2->get_int16,
                                                  $s2->get_int16,
                                                  [map Encode::decode(utf8 => $_), $s2->get_str_list],
                                                  [map Encode::decode(utf8 => $_), $s2->get_str_list] ];
                }
            }

	    return $version;
	}

	$sftp->_conn_lost(SSH2_FX_BAD_MESSAGE,
			  SFTP_ERR_REMOTE_BAD_MESSAGE,
			  "bad packet type, expecting SSH2_FXP_VERSION, got $type");
    }
    elsif ($sftp->{_status} == SSH2_FX_CONNECTION_LOST
	   and $sftp->{_password_authentication}
	   and $sftp->{_password_sent}) {
	$sftp->_set_error(SFTP_ERR_PASSWORD_AUTHENTICATION_FAILED,
			  "Password authentication failed or connection lost");
    }
    return undef;
}

sub server_extensions { %{shift->{server_extensions}} }

sub _check_extension {
    my ($sftp, $name, $version, $error, $errstr) = @_;
    my $ext = $sftp->{server_extensions}{$name};
    return 1 if (defined $ext and $ext == $version);

    $sftp->_set_status(SSH2_FX_OP_UNSUPPORTED);
    $sftp->_set_error($error, "$errstr: extended operation not supported by server");
    return undef;
}

# helper methods:
sub _get_msg_and_check {
    my ($sftp, $etype, $eid, $err, $errstr) = @_;
    my $msg = $sftp->_get_msg;
    if ($msg) {
	my $type = $msg->get_int8;
	my $id = $msg->get_int32;

	$sftp->_clear_error_and_status;

	if ($id != $eid) {
	    $sftp->_conn_lost(SSH2_FX_BAD_MESSAGE,
			      SFTP_ERR_REMOTE_BAD_MESSAGE,
			      $errstr, "bad packet sequence, expected $eid, got $id");
	    return undef;
	}

	if ($type != $etype) {
	    if ($type == SSH2_FXP_STATUS) {
                my $code = $msg->get_int32;
                my $str = Encode::decode(utf8 => $msg->get_str);
		my $status = $sftp->_set_status($code, (defined $str ? $str : ()));
		$sftp->_set_error($err, $errstr, $status);
	    }
	    else {
		$sftp->_conn_lost(SSH2_FX_BAD_MESSAGE,
				  SFTP_ERR_REMOTE_BAD_MESSAGE,
				  $errstr, "bad packet type, expected $etype packet, got $type");
	    }
	    return undef;
	}
    }
    $msg;
}

# reads SSH2_FXP_HANDLE packet and returns handle, or undef on failure
sub _get_handle {
    my ($sftp, $eid, $error, $errstr) = @_;
    if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_HANDLE, $eid,
					    $error, $errstr)) {
	return $msg->get_str;
    }
    return undef;
}

sub _rid {
    my ($sftp, $rfh) = @_;
    my $rid = $rfh->_rid;
    unless (defined $rid) {
	$sftp->_set_error(SFTP_ERR_REMOTE_ACCESING_CLOSED_FILE,
			  "Couldn't access a file that has been previosly closed");
    }
    $rid
}

sub _rfid {
    $_[1]->_check_is_file;
    &_rid;
}

sub _rdid {
    $_[1]->_check_is_dir;
    &_rid;
}

sub _queue_rid_request {
    my ($sftp, $code, $fh, $attrs) = @_;
    my $rid = $sftp->_rid($fh);
    return undef unless defined $rid;

    $sftp->_queue_new_msg($code, str => $rid,
			 (defined $attrs ? (attr => $attrs) : ()));
}

sub _queue_rfid_request {
    $_[2]->_check_is_file;
    &_queue_rid_request;
}

sub _queue_rdid_request {
    $_[2]->_check_is_dir;
    &_queue_rid_request;
}

sub _queue_str_request {
    my($sftp, $code, $str, $attrs) = @_;
    $sftp->_queue_new_msg($code, str => $str,
			 (defined $attrs ? (attr => $attrs) : ()));
}

sub _check_status_ok {
    my ($sftp, $eid, $error, $errstr) = @_;
    if (defined $eid) {
        if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_STATUS, $eid,
                                                $error, $errstr)) {
            my $status = $sftp->_set_status($msg->get_int32, $msg->get_str);
            return 1 if $status == SSH2_FX_OK;

            $sftp->_set_error($error, $errstr, $status);
        }
    }
    return undef;
}

sub setcwd {
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $cwd, %opts) = @_;
    $sftp->_clear_error_and_status;

    my $check = delete $opts{check};
    $check = 1 unless defined $check;

    %opts and _croak_bad_options(keys %opts);

    if (defined $cwd) {
        if ($check) {
            $cwd = $sftp->realpath($cwd);
            return undef unless defined $cwd;
            _untaint($cwd);
            my $a = $sftp->stat($cwd)
                or return undef;
            unless (_is_dir($a->perm)) {
                $sftp->_set_error(SFTP_ERR_REMOTE_BAD_OBJECT,
                                  "Remote object '$cwd' is not a directory");
                return undef;
            }
        }
        else {
            $cwd = $sftp->_rel2abs($cwd);
        }
        return $sftp->{cwd} = $cwd;
    }
    else {
        delete $sftp->{cwd};
        return $sftp->cwd if defined wantarray;
    }
}

sub cwd {
    @_ == 1 or croak 'Usage: $sftp->cwd()';

    my $sftp = shift;
    return defined $sftp->{cwd} ? $sftp->{cwd} : $sftp->realpath('');
}

## SSH2_FXP_OPEN (3)
# returns handle on success, undef on failure
sub open {
    (@_ >= 2 and @_ <= 4)
	or croak 'Usage: $sftp->open($path [, $flags [, $attrs]])';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $path, $flags, $a) = @_;
    $path = $sftp->_rel2abs($path);
    defined $flags or $flags = SSH2_FXF_READ;
    defined $a or $a = Net::SFTP::Foreign::Attributes->new;
    my $id = $sftp->_queue_new_msg(SSH2_FXP_OPEN,
                                   str => $sftp->_fs_encode($path),
                                   int32 => $flags, attr => $a);

    my $rid = $sftp->_get_handle($id,
				SFTP_ERR_REMOTE_OPEN_FAILED,
				"Couldn't open remote file '$path'");

    if ($debug and $debug & 2) {
        if (defined $rid) {
            _debug("new remote file '$path' open, rid:");
            _hexdump($rid);
        }
        else {
            _debug("open failed: $sftp->{_status}");
        }
    }

    defined $rid or return undef;

    my $fh = Net::SFTP::Foreign::FileHandle->_new_from_rid($sftp, $rid);
    $fh->_flag(append => 1) if ($flags & SSH2_FXF_APPEND);

    $fh;
}

sub _open_mkpath {
    my ($sftp, $filename, $mkpath, $flags, $attrs) = @_;
    $flags = ($flags || 0) | SSH2_FXF_WRITE|SSH2_FXF_CREAT;
    my $fh = do {
        local $sftp->{_autodie};
        $sftp->open($filename, $flags, $attrs);
    };
    unless ($fh) {
        if ($mkpath and $sftp->status == SSH2_FX_NO_SUCH_FILE) {
            my $da = $attrs->clone;
            $da->set_perm(($da->perm || 0) | 0700);
            $sftp->mkpath($filename, $da, 1) or return;
            $fh = $sftp->open($filename, $flags, $attrs);
        }
        else {
            $sftp->_ok_or_autodie;
        }
    }
    $fh;
}

## SSH2_FXP_OPENDIR (11)
sub opendir {
    @_ <= 2 or croak 'Usage: $sftp->opendir($path)';
    ${^TAINT} and &_catch_tainted_args;

    my $sftp = shift;
    my $path = shift;
    $path = '.' unless defined $path;
    $path = $sftp->_rel2abs($path);
    my $id = $sftp->_queue_str_request(SSH2_FXP_OPENDIR, $sftp->_fs_encode($path), @_);
    my $rid = $sftp->_get_handle($id, SFTP_ERR_REMOTE_OPENDIR_FAILED,
				 "Couldn't open remote dir '$path'");

    if ($debug and $debug & 2) {
        _debug("new remote dir '$path' open, rid:");
        _hexdump($rid);
    }

    defined $rid
	or return undef;

    Net::SFTP::Foreign::DirHandle->_new_from_rid($sftp, $rid, 0)
}

## SSH2_FXP_READ (4)
# returns data on success undef on failure
sub sftpread {
    (@_ >= 3 and @_ <= 4)
	or croak 'Usage: $sftp->sftpread($fh, $offset [, $size])';

    my ($sftp, $rfh, $offset, $size) = @_;

    unless ($size) {
	return '' if defined $size;
	$size = $sftp->{_block_size};
    }

    my $rfid = $sftp->_rfid($rfh);
    defined $rfid or return undef;

    my $id = $sftp->_queue_new_msg(SSH2_FXP_READ, str=> $rfid,
				  int64 => $offset, int32 => $size);

    if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_DATA, $id,
					    SFTP_ERR_REMOTE_READ_FAILED,
					    "Couldn't read from remote file")) {
	return $msg->get_str;
    }
    return undef;
}

## SSH2_FXP_WRITE (6)
# returns true on success, undef on failure
sub sftpwrite {
    @_ == 4 or croak 'Usage: $sftp->sftpwrite($fh, $offset, $data)';

    my ($sftp, $rfh, $offset) = @_;
    my $rfid = $sftp->_rfid($rfh);
    defined $rfid or return undef;
    utf8::downgrade($_[3], 1) or croak "wide characters found in data";

    my $id = $sftp->_queue_new_msg(SSH2_FXP_WRITE, str => $rfid,
				  int64 => $offset, str => $_[3]);

    if ($sftp->_check_status_ok($id,
				SFTP_ERR_REMOTE_WRITE_FAILED,
				"Couldn't write to remote file")) {
	return 1;
    }
    return undef;
}

sub seek {
    (@_ >= 3 and @_ <= 4)
	or croak 'Usage: $sftp->seek($fh, $pos [, $whence])';

    my ($sftp, $rfh, $pos, $whence) = @_;
    $sftp->flush($rfh) or return undef;

    if (!$whence) {
        $rfh->_pos($pos)
    }
    elsif ($whence == 1) {
        $rfh->_inc_pos($pos)
    }
    elsif ($whence == 2) {
	my $a = $sftp->stat($rfh) or return undef;
        $rfh->_pos($pos + $a->size);
    }
    else {
	croak "invalid value for whence argument ('$whence')";
    }
    1;
}

sub tell {
    @_ == 2 or croak 'Usage: $sftp->tell($fh)';

    my ($sftp, $rfh) = @_;
    return $rfh->_pos + length ${$rfh->_bout};
}

sub eof {
    @_ == 2 or croak 'Usage: $sftp->eof($fh)';

    my ($sftp, $rfh) = @_;
    $sftp->_fill_read_cache($rfh, 1);
    return length(${$rfh->_bin}) == 0
}

sub _write {
    my ($sftp, $rfh, $off, $cb) = @_;

    $sftp->_clear_error_and_status;

    my $rfid = $sftp->_rfid($rfh);
    defined $rfid or return undef;

    my $qsize = $sftp->{_queue_size};

    my @msgid;
    my @written;
    my $written = 0;
    my $end;

    while (!$end or @msgid) {
	while (!$end and @msgid < $qsize) {
	    my $data = $cb->();
	    if (defined $data and length $data) {
		my $id = $sftp->_queue_new_msg(SSH2_FXP_WRITE, str => $rfid,
					      int64 => $off + $written, str => $data);
		push @written, $written;
		$written += length $data;
		push @msgid, $id;
	    }
	    else {
		$end = 1;
	    }
	}

	my $eid = shift @msgid;
	my $last = shift @written;
	unless ($sftp->_check_status_ok($eid,
					SFTP_ERR_REMOTE_WRITE_FAILED,
					"Couldn't write to remote file")) {

	    # discard responses to queued requests:
	    $sftp->_get_msg for @msgid;
	    return $last;
	}
    }

    return $written;
}

sub write {
    @_ == 3 or croak 'Usage: $sftp->write($fh, $data)';

    my ($sftp, $rfh) = @_;
    $sftp->flush($rfh, 'in') or return undef;
    utf8::downgrade($_[2], 1) or croak "wide characters found in data";
    my $datalen = length $_[2];
    my $bout = $rfh->_bout;
    $$bout .= $_[2];
    my $len = length $$bout;

    $sftp->flush($rfh, 'out')
	if ($len >= $sftp->{_write_delay} or ($len and $sftp->{_autoflush} ));

    return $datalen;
}

sub flush {
    (@_ >= 2 and @_ <= 3)
	or croak 'Usage: $sftp->flush($fh [, $direction])';

    my ($sftp, $rfh, $dir) = @_;
    $dir ||= '';

    defined $sftp->_rfid($rfh) or return;

    if ($dir ne 'out') { # flush in!
	${$rfh->_bin} = '';
    }

    if ($dir ne 'in') { # flush out!
	my $bout = $rfh->_bout;
	my $len = length $$bout;
	if ($len) {
	    my $start;
	    my $append = $rfh->_flag('append');
	    if ($append) {
		my $attr = $sftp->stat($rfh)
		    or return undef;
		$start = $attr->size;
	    }
	    else {
		$start = $rfh->_pos;
		${$rfh->_bin} = '';
	    }
	    my $off = 0;
	    my $written = $sftp->_write($rfh, $start,
					sub {
					    my $data = substr($$bout, $off, $sftp->{_block_size});
					    $off += length $data;
					    $data;
					} );
	    $rfh->_inc_pos($written)
		unless $append;

	    substr($$bout, 0, $written, '');
	    $written == $len or return undef;
	}
    }
    1;
}

sub _fill_read_cache {
    my ($sftp, $rfh, $len) = @_;

    $sftp->_clear_error_and_status;

    $sftp->flush($rfh, 'out')
	or return undef;

    my $rfid = $sftp->_rfid($rfh);
    defined $rfid or return undef;

    my $bin = $rfh->_bin;

    if (defined $len) {
	return 1 if ($len < length $$bin);

	my $read_ahead = $sftp->{_read_ahead};
	$len = length($$bin) + $read_ahead
	    if $len - length($$bin) < $read_ahead;
    }

    my $pos = $rfh->_pos;

    my $qsize = $sftp->{_queue_size};
    my $bsize = $sftp->{_block_size};

    my @msgid;
    my $askoff = length $$bin;
    my $eof;

    while (!defined $len or length $$bin < $len) {
	while ((!defined $len or $askoff < $len) and @msgid < $qsize) {
	    my $id = $sftp->_queue_new_msg(SSH2_FXP_READ, str=> $rfid,
					  int64 => $pos + $askoff, int32 => $bsize);
	    push @msgid, $id;
	    $askoff += $bsize;
	}

	my $eid = shift @msgid;
	my $msg = $sftp->_get_msg_and_check(SSH2_FXP_DATA, $eid,
					    SFTP_ERR_REMOTE_READ_FAILED,
					    "Couldn't read from remote file")
	    or last;

	my $data = $msg->get_str;
	$$bin .= $data;
	if (length $data < $bsize) {
	    unless (defined $len) {
		$eof = $sftp->_queue_new_msg(SSH2_FXP_READ, str=> $rfid,
					     int64 => $pos + length $$bin, int32 => 1);
	    }
	    last;
	}

    }

    $sftp->_get_msg for @msgid;

    if ($eof) {
	$sftp->_get_msg_and_check(SSH2_FXP_DATA, $eof,
				  SFTP_ERR_REMOTE_BLOCK_TOO_SMALL,
				  "received block was too small")
    }

    if ($sftp->{_status} == SSH2_FX_EOF and length $$bin) {
	$sftp->_clear_error_and_status;
    }

    return $sftp->{_error} ? undef : length $$bin;
}

sub read {
    @_ == 3 or croak 'Usage: $sftp->read($fh, $len)';

    my ($sftp, $rfh, $len) = @_;
    if ($sftp->_fill_read_cache($rfh, $len)) {
	my $bin = $rfh->_bin;
	my $data = substr($$bin, 0, $len, '');
	$rfh->_inc_pos(length $data);
	return $data;
    }
    return undef;
}

sub _readline {
    my ($sftp, $rfh, $sep) = @_;

    $sep = "\n" if @_ < 3;

    my $sl = length $sep;

    my $bin = $rfh->_bin;
    my $last = 0;

    while(1) {
	my $ix = index $$bin, $sep, $last + 1 - $sl ;
	if ($ix >= 0) {
	    $ix += $sl;
	    $rfh->_inc_pos($ix);
	    return substr($$bin, 0, $ix, '');
	}

	$last = length $$bin;
	$sftp->_fill_read_cache($rfh, length($$bin) + 1);

	unless (length $$bin > $last) {
	    $sftp->{_error}
		and return undef;

	    my $line = $$bin;
	    $rfh->_inc_pos(length $line);
	    $$bin = '';
	    return $line;
	}
    }
}

sub readline {
    (@_ >= 2 and @_ <= 3)
	or croak 'Usage: $sftp->readline($fh [, $sep])';

    my ($sftp, $rfh, $sep) = @_;
    $sep = "\n" if @_ < 3;
    if (!defined $sep or $sep eq '') {
	$sftp->_fill_read_cache($rfh);
	$sftp->{_error}
	    and return undef;
	my $bin = $rfh->_bin;
	my $line = $$bin;
	$rfh->_inc_pos(length $line);
	$$bin = '';
	return $line;
    }
    if (wantarray) {
	my @lines;
	while (defined (my $line = $sftp->_readline($rfh, $sep))) {
	    push @lines, $line;
	}
	return @lines;
    }
    return $sftp->_readline($rfh, $sep);
}

sub getc {
    @_ == 2 or croak 'Usage: $sftp->getc($fh)';

    my ($sftp, $rfh) = @_;

    $sftp->_fill_read_cache($rfh, 1);
    my $bin = $rfh->_bin;
    if (length $bin) {
	$rfh->_inc_pos(1);
	return substr $$bin, 0, 1, '';
    }
    return undef;
}

## SSH2_FXP_LSTAT (7), SSH2_FXP_FSTAT (8), SSH2_FXP_STAT (17)
# these all return a Net::SFTP::Foreign::Attributes object on success, undef on failure

sub lstat {
    @_ <= 2 or croak 'Usage: $sftp->lstat($path)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $path) = @_;
    $path = '.' unless defined $path;
    $path = $sftp->_rel2abs($path);
    my $id = $sftp->_queue_str_request(SSH2_FXP_LSTAT, $sftp->_fs_encode($path));
    if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_ATTRS, $id,
                                            SFTP_ERR_REMOTE_LSTAT_FAILED, "Couldn't stat remote link")) {
        return $msg->get_attributes;
    }
    return undef;
}

sub stat {
    @_ <= 2 or croak 'Usage: $sftp->stat($path_or_fh)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $pofh) = @_;
    $pofh = '.' unless defined $pofh;
    my $id = $sftp->_queue_new_msg( (ref $pofh and UNIVERSAL::isa($pofh, 'Net::SFTP::Foreign::FileHandle'))
                                    ? ( SSH2_FXP_FSTAT, str => $sftp->_rid($pofh))
                                    : ( SSH2_FXP_STAT,  str => $sftp->_fs_encode($sftp->_rel2abs($pofh))) );
    if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_ATTRS, $id,
                                            SFTP_ERR_REMOTE_STAT_FAILED, "Couldn't stat remote file")) {
        return $msg->get_attributes;
    }
    return undef;
}

sub fstat {
    _deprecated "fstat is deprecated and will be removed on the upcoming 2.xx series, "
        . "stat method accepts now both file handlers and paths";
    goto &stat;
}

## SSH2_FXP_RMDIR (15), SSH2_FXP_REMOVE (13)
# these return true on success, undef on failure

sub _gen_remove_method {
    my($name, $code, $error, $errstr) = @_;
    my $sub = sub {
	@_ == 2 or croak "Usage: \$sftp->$name(\$path)";
        ${^TAINT} and &_catch_tainted_args;

        my ($sftp, $path) = @_;
        $path = $sftp->_rel2abs($path);
        my $id = $sftp->_queue_str_request($code, $sftp->_fs_encode($path));
        $sftp->_check_status_ok($id, $error, $errstr);
    };
    no strict 'refs';
    *$name = $sub;
}

_gen_remove_method(remove => SSH2_FXP_REMOVE,
                   SFTP_ERR_REMOTE_REMOVE_FAILED, "Couldn't delete remote file");
_gen_remove_method(rmdir => SSH2_FXP_RMDIR,
                   SFTP_ERR_REMOTE_RMDIR_FAILED, "Couldn't remove remote directory");

## SSH2_FXP_MKDIR (14), SSH2_FXP_SETSTAT (9)
# these return true on success, undef on failure

sub mkdir {
    (@_ >= 2 and @_ <= 3)
        or croak 'Usage: $sftp->mkdir($path [, $attrs])';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $path, $attrs) = @_;
    $attrs = _empty_attributes unless defined $attrs;
    $path = $sftp->_rel2abs($path);
    my $id = $sftp->_queue_str_request(SSH2_FXP_MKDIR,
                                       $sftp->_fs_encode($path),
                                       $attrs);
    $sftp->_check_status_ok($id,
                            SFTP_ERR_REMOTE_MKDIR_FAILED,
                            "Couldn't create remote directory");
}

sub join {
    my $sftp = shift;
    my $vol = '';
    my $a = '.';
    while (@_) {
	my $b = shift;
	if (defined $b) {
            if (ref $sftp and   # this method can also be used as a static one
                $sftp->{_remote_has_volumes} and $b =~ /^([a-z]\:)(.*)/i) {
                $vol = $1;
                $a = '.';
                $b = $2;
            }
	    $b =~ s|^(?:\./+)+||;
	    if (length $b and $b ne '.') {
		if ($b !~ m|^/| and $a ne '.' ) {
		    $a = ($a =~ m|/$| ? "$a$b" : "$a/$b");
		}
		else {
		    $a = $b
		}
		$a =~ s|(?:/+\.)+/?$|/|;
		$a =~ s|(?<=[^/])/+$||;
		$a = '.' unless length $a;
	    }
	}
    }
    "$vol$a";
}

sub _rel2abs {
    my ($sftp, $path) = @_;
    my $old = $path;
    my $cwd = $sftp->{cwd};
    $path = $sftp->join($sftp->{cwd}, $path);
    $debug and $debug & 4096 and _debug("'$old' --> '$path'");
    return $path
}

sub mkpath {
    (@_ >= 2 and @_ <= 4)
        or croak 'Usage: $sftp->mkpath($path [, $attrs [, $parent]])';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $path, $attrs, $parent) = @_;
    $sftp->_clear_error_and_status;
    my $first = !$parent; # skips file name
    $path =~ s{^(/*)}{};
    my $start = $1;
    $path =~ s{/+$}{};
    my @path;
    while (1) {
        if ($first) {
            $first = 0
        }
        else {
            $path =~ s{/*[^/]*$}{}
        }
	my $p = "$start$path";
	$debug and $debug & 8192 and _debug "checking $p";
	if ($sftp->test_d($p)) {
	    $debug and $debug & 8192 and _debug "$p is a dir";
	    last;
	}
	unless (length $path) {
	    $sftp->_set_error(SFTP_ERR_REMOTE_MKDIR_FAILED,
                              "Unable to make path, bad root");
	    return undef;
	}
	unshift @path, $p;

    }
    for my $p (@path) {
	$debug and $debug & 8192 and _debug "mkdir $p";
	if ($p =~ m{^(?:.*/)?\.{1,2}$} or $p =~ m{/$}) {
	    $debug and $debug & 8192 and _debug "$p is a symbolic dir, skipping";
	    unless ($sftp->test_d($p)) {
		$debug and $debug & 8192 and _debug "symbolic dir $p can not be checked";
		$sftp->{_error} or
		    $sftp->_set_error(SFTP_ERR_REMOTE_MKDIR_FAILED,
				      "Unable to make path, bad name");
		return undef;
	    }
	}
	else {
	    $sftp->mkdir($p, $attrs)
                or return undef;
	}
    }
    1;
}

sub _mkpath_local {
    my ($sftp, $path, $perm, $parent) = @_;
    # When parent is set, the last path part is removed and the parent
    # directory of the path given created.

    my @parts = File::Spec->splitdir($path);
    $debug and $debug & 32768 and _debug "_mkpath_local($path, $perm, ".($parent||0).")";

    if ($parent) {
        pop @parts while @parts and not length $parts[-1];
        unless (@parts) {
            $sftp->_set_error(SFTP_ERR_LOCAL_MKDIR_FAILED,
                              "mkpath failed, top dir reached");
            return;
        }
        pop @parts;
    }

    my @tail;
    while (@parts) {
        my $target = File::Spec->catdir(@parts);
        if (-e $target) {
            unless (-d $target) {
                $sftp->_set_error(SFTP_ERR_LOCAL_BAD_OBJECT,
                                  "Local file '$target' is not a directory");
                return;
            }
            last
        }
        unshift @tail, pop @parts;
    }
    while (@tail) {
        push @parts, shift @tail;
        my $target = File::Spec->catdir(@parts);
        $debug and $debug and 32768 and _debug "creating local directory '$target'";
        unless (CORE::mkdir $target, $perm) {
            unless (do { local $!; -d $target}) {
                $sftp->_set_error(SFTP_ERR_LOCAL_MKDIR_FAILED,
                                  "mkdir '$target' failed", $!);
                return;
            }
        }
    }
    $debug and $debug & 32768 and _debug "_mkpath_local succeeded";
    return 1;
}

sub setstat {
    @_ == 3 or croak 'Usage: $sftp->setstat($path_or_fh, $attrs)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $pofh, $attrs) = @_;
    my $id = $sftp->_queue_new_msg( ( (ref $pofh and UNIVERSAL::isa($pofh, 'Net::SFTP::Foreign::FileHandle') )
                                      ? ( SSH2_FXP_FSETSTAT, str => $sftp->_rid($pofh) )
                                      : ( SSH2_FXP_SETSTAT,  str => $sftp->_fs_encode($sftp->_rel2abs($pofh)) ) ),
                                    attr => $attrs );
    return $sftp->_check_status_ok($id,
                                   SFTP_ERR_REMOTE_SETSTAT_FAILED,
                                   "Couldn't setstat remote file");
}

## SSH2_FXP_CLOSE (4), SSH2_FXP_FSETSTAT (10)
# these return true on success, undef on failure

sub fsetstat {
    _deprecated "fsetstat is deprecated and will be removed on the upcoming 2.xx series, "
        . "setstat method accepts now both file handlers and paths";
    goto &setstat;
}

sub _gen_setstat_shortcut {
    my ($name, $rid_type, $attrs_flag, @arg_types) = @_;
    my $nargs = 2 + @arg_types;
    my $usage = ("\$sftp->$name("
                 . CORE::join(', ', '$path_or_fh', map "arg$_", 1..@arg_types)
                 . ')');
    my $rid_method = ($rid_type eq 'file' ? '_rfid' :
                      $rid_type eq 'dir'  ? '_rdid' :
                      $rid_type eq 'any'  ? '_rid'  :
                      croak "bad rid type $rid_type");
    my $sub = sub {
        @_ == $nargs or croak $usage;
        my $sftp = shift;
        my $pofh = shift;
        my $id = $sftp->_queue_new_msg( ( (ref $pofh and UNIVERSAL::isa($pofh, 'Net::SFTP::Foreign::FileHandle') )
                                          ? ( SSH2_FXP_FSETSTAT, str => $sftp->$rid_method($pofh) )
                                          : ( SSH2_FXP_SETSTAT,  str => $sftp->_fs_encode($sftp->_rel2abs($pofh)) ) ),
                                        int32 => $attrs_flag,
                                        map { $arg_types[$_] => $_[$_] } 0..$#arg_types );
        $sftp->_check_status_ok($id,
                                SFTP_ERR_REMOTE_SETSTAT_FAILED,
                                "Couldn't setstat remote file ($name)");
    };
    no strict 'refs';
    *$name = $sub;
}

_gen_setstat_shortcut(truncate => 'file', SSH2_FILEXFER_ATTR_SIZE,        'int64');
_gen_setstat_shortcut(chown    => 'any' , SSH2_FILEXFER_ATTR_UIDGID,      'int32', 'int32');
_gen_setstat_shortcut(chmod    => 'any' , SSH2_FILEXFER_ATTR_PERMISSIONS, 'int32');
_gen_setstat_shortcut(utime    => 'any' , SSH2_FILEXFER_ATTR_ACMODTIME,   'int32', 'int32');

sub _close {
    @_ == 2 or croak 'Usage: $sftp->close($fh, $attrs)';

    my $sftp = shift;
    my $id = $sftp->_queue_rid_request(SSH2_FXP_CLOSE, @_);
    defined $id or return undef;

    my $ok = $sftp->_check_status_ok($id,
                                     SFTP_ERR_REMOTE_CLOSE_FAILED,
                                     "Couldn't close remote file");

    if ($debug and $debug & 2) {
        _debug sprintf("closing file handle, return: %s, rid:", (defined $ok ? $ok : '-'));
        _hexdump($sftp->_rid($_[0]));
    }

    return $ok;
}

sub close {
    @_ == 2 or croak 'Usage: $sftp->close($fh)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $rfh) = @_;
    # defined $sftp->_rfid($rfh) or return undef;
    # ^--- commented out because flush already checks it is an open file
    $sftp->flush($rfh)
	or return undef;

    if ($sftp->_close($rfh)) {
	$rfh->_close;
	return 1
    }
    undef
}

sub closedir {
    @_ == 2 or croak 'Usage: $sftp->closedir($dh)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $rdh) = @_;
    $rdh->_check_is_dir;

    if ($sftp->_close($rdh)) {
	$rdh->_close;
	return 1;
    }
    undef
}

sub readdir {
    @_ == 2 or croak 'Usage: $sftp->readdir($dh)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $rdh) = @_;

    my $rdid = $sftp->_rdid($rdh);
    defined $rdid or return undef;

    my $cache = $rdh->_cache;

    while (!@$cache or wantarray) {
	my $id = $sftp->_queue_str_request(SSH2_FXP_READDIR, $rdid);
	if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_NAME, $id,
						SFTP_ERR_REMOTE_READDIR_FAILED,
						"Couldn't read remote directory" )) {
	    my $count = $msg->get_int32 or last;

	    for (1..$count) {
		push @$cache, { filename => $sftp->_fs_decode($msg->get_str),
				longname => $sftp->_fs_decode($msg->get_str),
				a => $msg->get_attributes };
	    }
	}
	else {
	    $sftp->_set_error if $sftp->{_status} == SSH2_FX_EOF;
	    last;
	}
    }

    if (wantarray) {
	my $old = $cache;
	$cache = [];
	return @$old;
    }
    shift @$cache;
}

sub _readdir {
    my ($sftp, $rdh);
    if (wantarray) {
	my $line = $sftp->readdir($rdh);
	if (defined $line) {
	    return $line->{filename};
	}
    }
    else {
	return map { $_->{filename} } $sftp->readdir($rdh);
    }
}

sub _gen_getpath_method {
    my ($code, $error, $name) = @_;
    return sub {
	@_ == 2 or croak 'Usage: $sftp->some_method($path)';
        ${^TAINT} and &_catch_tainted_args;

	my ($sftp, $path) = @_;
	$path = $sftp->_rel2abs($path);
	my $id = $sftp->_queue_str_request($code, $sftp->_fs_encode($path));

	if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_NAME, $id,
						$error,
						"Couldn't get $name for remote '$path'")) {
	    $msg->get_int32 > 0
		and return $sftp->_fs_decode($msg->get_str);

	    $sftp->_set_error($error,
			      "Couldn't get $name for remote '$path', no names on reply")
	}
	return undef;
    };
}

## SSH2_FXP_REALPATH (16)
## SSH2_FXP_READLINK (19)
# return path on success, undef on failure
*realpath = _gen_getpath_method(SSH2_FXP_REALPATH,
				SFTP_ERR_REMOTE_REALPATH_FAILED,
				"realpath");
*readlink = _gen_getpath_method(SSH2_FXP_READLINK,
				SFTP_ERR_REMOTE_READLINK_FAILED,
				"link target");

## SSH2_FXP_RENAME (18)
# true on success, undef on failure

sub _rename {
    my ($sftp, $old, $new) = @_;

    $old = $sftp->_rel2abs($old);
    $new = $sftp->_rel2abs($new);

    my $id = $sftp->_queue_new_msg(SSH2_FXP_RENAME,
                                   str => $sftp->_fs_encode($old),
                                   str => $sftp->_fs_encode($new));

    $sftp->_check_status_ok($id, SFTP_ERR_REMOTE_RENAME_FAILED,
                            "Couldn't rename remote file '$old' to '$new'");
}

sub rename {
    (@_ & 1) or croak 'Usage: $sftp->rename($old, $new, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $old, $new, %opts) = @_;

    my $overwrite = delete $opts{overwrite};
    my $numbered = delete $opts{numbered};
    croak "'overwrite' and 'numbered' options can not be used together"
        if ($overwrite and $numbered);
    %opts and _croak_bad_options(keys %opts);

    if ($overwrite) {
        $sftp->atomic_rename($old, $new) and return 1;
        $sftp->{_status} != SSH2_FX_OP_UNSUPPORTED and return undef;
    }

    for (1) {
        local $sftp->{_autodie};
        # we are optimistic here and try to rename it without testing
        # if a file of the same name already exists first
        if (!$sftp->_rename($old, $new) and
            $sftp->{_status} == SSH2_FX_FAILURE) {
            if ($numbered and $sftp->test_e($new)) {
                _inc_numbered($new);
                redo;
            }
            elsif ($overwrite) {
                my $rp_old = $sftp->realpath($old);
                my $rp_new = $sftp->realpath($new);
                if (defined $rp_old and defined $rp_new and $rp_old eq $rp_new) {
                    $sftp->_clear_error_and_status;
                }
                elsif ($sftp->remove($new)) {
                    $overwrite = 0;
                    redo;
                }
            }
        }
    }
    $sftp->_ok_or_autodie;
}

sub atomic_rename {
    @_ == 3 or croak 'Usage: $sftp->atomic_rename($old, $new)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $old, $new) = @_;

    $sftp->_check_extension('posix-rename@openssh.com' => 1,
                             SFTP_ERR_REMOTE_RENAME_FAILED,
                            "atomic rename failed")
        or return undef;

    $old = $sftp->_rel2abs($old);
    $new = $sftp->_rel2abs($new);

    my $id = $sftp->_queue_new_msg(SSH2_FXP_EXTENDED,
                                   str => 'posix-rename@openssh.com',
                                   str => $sftp->_fs_encode($old),
                                   str => $sftp->_fs_encode($new));

    $sftp->_check_status_ok($id, SFTP_ERR_REMOTE_RENAME_FAILED,
                            "Couldn't rename remote file '$old' to '$new'");
}

## SSH2_FXP_SYMLINK (20)
# true on success, undef on failure
sub symlink {
    @_ == 3 or croak 'Usage: $sftp->symlink($sl, $target)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $sl, $target) = @_;
    $sl = $sftp->_rel2abs($sl);
    my $id = $sftp->_queue_new_msg(SSH2_FXP_SYMLINK,
                                   str => $sftp->_fs_encode($target),
                                   str => $sftp->_fs_encode($sl));

    $sftp->_check_status_ok($id, SFTP_ERR_REMOTE_SYMLINK_FAILED,
                            "Couldn't create symlink '$sl' pointing to '$target'");
}

sub hardlink {
    @_ == 3 or croak 'Usage: $sftp->hardlink($hl, $target)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $hl, $target) = @_;

    $sftp->_check_extension('hardlink@openssh.com' => 1,
                            SFTP_ERR_REMOTE_HARDLINK_FAILED,
                            "hardlink failed")
        or return undef;
    $hl = $sftp->_rel2abs($hl);
    $target = $sftp->_rel2abs($target);

    my $id = $sftp->_queue_new_msg(SSH2_FXP_EXTENDED,
                                   str => 'hardlink@openssh.com',
                                   str => $sftp->_fs_encode($target),
                                   str => $sftp->_fs_encode($hl));
    $sftp->_check_status_ok($id, SFTP_ERR_REMOTE_HARDLINK_FAILED,
                            "Couldn't create hardlink '$hl' pointing to '$target'");
}

sub _gen_save_status_method {
    my $method = shift;
    sub {
	my $sftp = shift;
        local ($sftp->{_error}, $sftp->{_status}) if $sftp->{_error};
	$sftp->$method(@_);
    }
}


*_close_save_status = _gen_save_status_method('close');
*_closedir_save_status = _gen_save_status_method('closedir');
*_remove_save_status = _gen_save_status_method('remove');

sub _inc_numbered {
    $_[0] =~ s{^(.*)\((\d+)\)((?:\.[^\.]*)?)$}{"$1(" . ($2+1) . ")$3"}e or
    $_[0] =~ s{((?:\.[^\.]*)?)$}{(1)$1};
    $debug and $debug & 128 and _debug("numbering to: $_[0]");
}

## High-level client -> server methods.

sub abort {
    my $sftp = shift;
    $sftp->_set_error(SFTP_ERR_ABORTED, ($@ ? $_[0] : "Aborted"));
}

# returns true on success, undef on failure
sub get {
    @_ >= 2 or croak 'Usage: $sftp->get($remote, $local, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $remote, $local, %opts) = @_;
    defined $remote or croak "remote file path is undefined";

    $sftp->_clear_error_and_status;

    $remote = $sftp->_rel2abs($remote);
    $local = _file_part($remote) unless defined $local;
    my $local_is_fh = (ref $local and $local->isa('GLOB'));

    my $cb = delete $opts{callback};
    my $umask = delete $opts{umask};
    my $perm = delete $opts{perm};
    my $copy_perm = delete $opts{exists $opts{copy_perm} ? 'copy_perm' : 'copy_perms'};
    my $copy_time = delete $opts{copy_time};
    my $overwrite = delete $opts{overwrite};
    my $resume = delete $opts{resume};
    my $append = delete $opts{append};
    my $block_size = delete $opts{block_size} || $sftp->{_block_size};
    my $queue_size = delete $opts{queue_size} || $sftp->{_queue_size};
    my $dont_save = delete $opts{dont_save};
    my $conversion = delete $opts{conversion};
    my $numbered = delete $opts{numbered};
    my $cleanup = delete $opts{cleanup};
    my $atomic = delete $opts{atomic};
    my $best_effort = delete $opts{best_effort};
    my $mkpath = delete $opts{mkpath};

    croak "'perm' and 'copy_perm' options can not be used simultaneously"
	if (defined $perm and defined $copy_perm);
    croak "'numbered' can not be used with 'overwrite', 'resume' or 'append'"
	if ($numbered and ($overwrite or $resume or $append));
    if ($resume or $append) {
        $resume and $append and croak "'resume' and 'append' options can not be used simultaneously";
        $atomic and croak "'atomic' can not be used with 'resume' or 'append'";
        $overwrite and croak "'overwrite' can not be used with 'resume' or 'append'";
    }

    if ($local_is_fh) {
	my $tail = 'option can not be used when target is a file handle';
	$resume and croak "'resume' $tail";
	$overwrite and croak "'overwrite' $tail";
	$numbered and croak "'numbered' $tail";
	$dont_save and croak "'dont_save' $tail";
        $atomic and croak "'croak' $tail";
    }
    %opts and _croak_bad_options(keys %opts);

    if ($resume and $conversion) {
        carp "resume option is useless when data conversion has also been requested";
        undef $resume;
    }

    $overwrite = 1 unless (defined $overwrite or $local_is_fh or $numbered or $append);
    $copy_perm = 1 unless (defined $perm or defined $copy_perm or $local_is_fh);
    $copy_time = 1 unless (defined $copy_time or $local_is_fh);
    $mkpath    = 1 unless defined $mkpath;
    $cleanup = ($atomic || $numbered) unless defined $cleanup;

    my $a = do {
        local $sftp->{_autodie};
        $sftp->stat($remote);
    };
    my ($rperm, $size, $atime, $mtime) = ($a ? ($a->perm, $a->size, $a->atime, $a->mtime) : ());
    $size = -1 unless defined $size;

    if ($copy_time and not defined $atime) {
        if ($best_effort) {
            undef $copy_time;
        }
        else {
            $sftp->_ok_or_autodie and $sftp->_set_error(SFTP_ERR_REMOTE_STAT_FAILED,
                                                        "Not enough information on stat, amtime not included");
            return undef;
        }
    }

    $umask = (defined $perm ? 0 : umask) unless defined $umask;
    if ($copy_perm) {
        if (defined $rperm) {
            $perm = $rperm;
        }
        elsif ($best_effort) {
            undef $copy_perm
        }
        else {
            $sftp->_ok_or_autodie and $sftp->_set_error(SFTP_ERR_REMOTE_STAT_FAILED,
                                                        "Not enough information on stat, mode not included");
            return undef
        }
    }
    $perm &= ~$umask if defined $perm;

    $sftp->_clear_error_and_status;

    if ($resume and $resume eq 'auto') {
        undef $resume;
        if (defined $mtime) {
            if (my @lstat = CORE::stat $local) {
                $resume = ($mtime <= $lstat[9]);
            }
        }
    }

    my ($atomic_numbered, $atomic_local, $atomic_cleanup);

    my ($rfh, $fh);
    my $askoff = 0;
    my $lstart = 0;

    if ($dont_save) {
        $rfh = $sftp->open($remote, SSH2_FXF_READ);
        defined $rfh or return undef;
    }
    else {
        unless ($local_is_fh or $overwrite or $append or $resume or $numbered) {
	    if (-e $local) {
                $sftp->_set_error(SFTP_ERR_LOCAL_ALREADY_EXISTS,
                                  "local file $local already exists");
                return undef
	    }
        }

        if ($atomic) {
            $atomic_local = $local;
            $local .= sprintf("(%d).tmp", rand(10000));
            $atomic_numbered = $numbered;
            $numbered = 1;
            $debug and $debug & 128 and _debug("temporal local file name: $local");
        }

        if ($resume) {
            if (CORE::open $fh, '+<', $local) {
                binmode $fh;
		CORE::seek($fh, 0, 2);
                $askoff = CORE::tell $fh;
                if ($askoff < 0) {
                    # something is going really wrong here, fall
                    # back to non-resuming mode...
                    $askoff = 0;
                    undef $fh;
                }
                else {
                    if ($size >=0 and $askoff > $size) {
                        $sftp->_set_error(SFTP_ERR_LOCAL_BIGGER_THAN_REMOTE,
                                          "Couldn't resume transfer, local file is bigger than remote");
                        return undef;
                    }
                    $size == $askoff and return 1;
                }
            }
        }

        # we open the remote file so late in order to skip it when
        # resuming an already completed transfer:
        $rfh = $sftp->open($remote, SSH2_FXF_READ);
        defined $rfh or return undef;

	unless (defined $fh) {
	    if ($local_is_fh) {
		$fh = $local;
		local ($@, $SIG{__DIE__}, $SIG{__WARN__});
		eval { $lstart = CORE::tell($fh) };
		$lstart = 0 unless ($lstart and $lstart > 0);
	    }
	    else {
                my $flags = Fcntl::O_CREAT|Fcntl::O_WRONLY;
                $flags |= Fcntl::O_APPEND if $append;
                $flags |= Fcntl::O_EXCL if ($numbered or (!$overwrite and !$append));
                unlink $local if $overwrite;
                my $open_perm = (defined $perm ? $perm : 0666);
                my $save = _umask_save_and_set($umask);
                $sftp->_mkpath_local($local, $open_perm|0700, 1) if $mkpath;
                while (1) {
                    sysopen ($fh, $local, $flags, $open_perm) and last;
                    unless ($numbered and -e $local) {
                        $sftp->_set_error(SFTP_ERR_LOCAL_OPEN_FAILED,
                                          "Can't open $local", $!);
                        return undef;
                    }
                    _inc_numbered($local);
                }
                $$numbered = $local if ref $numbered;
		binmode $fh;
		$lstart = sysseek($fh, 0, 2) if $append;
	    }
	}

	if (defined $perm) {
            my $error;
	    do {
                local ($@, $SIG{__DIE__}, $SIG{__WARN__});
                unless (eval { CORE::chmod($perm, $local) > 0 }) {
                    $error = ($@ ? $@ : $!);
                }
            };
	    if ($error and !$best_effort) {
                unlink $local unless $resume or $append;
		$sftp->_set_error(SFTP_ERR_LOCAL_CHMOD_FAILED,
				  "Can't chmod $local", $error);
		return undef
	    }
	}
    }

    my $converter = _gen_converter $conversion;

    my $rfid = $sftp->_rfid($rfh);
    defined $rfid or die "internal error: rfid not defined";

    my @msgid;
    my @askoff;
    my $loff = $askoff;
    my $adjustment = 0;
    local $\;

    my $slow_start = ($size == -1 ? $queue_size - 1 : 0);

    my $safe_block_size = $sftp->{_min_block_size} >= $block_size;

    do {
        # Disable autodie here in order to do not leave unhandled
        # responses queued on the connection in case of failure.
        local $sftp->{_autodie};

        # Again, once this point is reached, all code paths should end
        # through the CLEANUP block.

        while (1) {
            # request a new block if queue is not full
            while (!@msgid or ( ($size == -1 or $size + $block_size > $askoff)   and
                                @msgid < $queue_size - $slow_start and
                                $safe_block_size ) ) {
                my $id = $sftp->_queue_new_msg(SSH2_FXP_READ, str=> $rfid,
                                               int64 => $askoff, int32 => $block_size);
                push @msgid, $id;
                push @askoff, $askoff;
                $askoff += $block_size;
            }

            $slow_start-- if $slow_start;

            my $eid = shift @msgid;
            my $roff = shift @askoff;

            my $msg = $sftp->_get_msg_and_check(SSH2_FXP_DATA, $eid,
                                                SFTP_ERR_REMOTE_READ_FAILED,
                                                "Couldn't read from remote file");

            unless ($msg) {
                $sftp->_set_error if $sftp->{_status} == SSH2_FX_EOF;
                last;
            }

            my $data = $msg->get_str;
            my $len = length $data;

            if ($roff != $loff or !$len) {
                $sftp->_set_error(SFTP_ERR_REMOTE_BLOCK_TOO_SMALL,
                                  "remote packet received is too small" );
                last;
            }

            $loff += $len;
            unless ($safe_block_size) {
                if ($len > $sftp->{_min_block_size}) {
                    $sftp->{min_block_size} = $len;
                    if ($len < $block_size) {
                        # auto-adjust block size
                        $block_size = $len;
                        $askoff = $loff;
                    }
                }
                $safe_block_size = 1;
            }

            my $adjustment_before = $adjustment;
            $adjustment += $converter->($data) if $converter;

            if (length($data) and defined $cb) {
                # $size = $loff if ($loff > $size and $size != -1);
                local $\;
                $cb->($sftp, $data,
                      $lstart + $roff + $adjustment_before,
                      $lstart + $size + $adjustment);

                last if $sftp->{_error};
            }

            if (length($data) and !$dont_save) {
                unless (print $fh $data) {
                    $sftp->_set_error(SFTP_ERR_LOCAL_WRITE_FAILED,
                                      "unable to write data to local file $local", $!);
                    last;
                }
            }
        }

        $sftp->_get_msg for (@msgid);

        goto CLEANUP if $sftp->{_error};

        # if a converter is in place, and aditional call has to be
        # performed in order to flush any pending buffered data
        if ($converter) {
            my $data = '';
            my $adjustment_before = $adjustment;
            $adjustment += $converter->($data);

            if (length($data) and defined $cb) {
                # $size = $loff if ($loff > $size and $size != -1);
                local $\;
                $cb->($sftp, $data, $askoff + $adjustment_before, $size + $adjustment);
                goto CLEANUP if $sftp->{_error};
            }

            if (length($data) and !$dont_save) {
                unless (print $fh $data) {
                    $sftp->_set_error(SFTP_ERR_LOCAL_WRITE_FAILED,
                                      "unable to write data to local file $local", $!);
                    goto CLEANUP;
                }
            }
        }

        # we call the callback one last time with an empty string;
        if (defined $cb) {
            my $data = '';
            do {
                local $\;
                $cb->($sftp, $data, $askoff + $adjustment, $size + $adjustment);
            };
            return undef if $sftp->{_error};
            if (length($data) and !$dont_save) {
                unless (print $fh $data) {
                    $sftp->_set_error(SFTP_ERR_LOCAL_WRITE_FAILED,
                                      "unable to write data to local file $local", $!);
                    goto CLEANUP;
                }
            }
        }

        unless ($dont_save) {
            unless ($local_is_fh or CORE::close $fh) {
                $sftp->_set_error(SFTP_ERR_LOCAL_WRITE_FAILED,
                                  "unable to write data to local file $local", $!);
                goto CLEANUP;
            }

            # we can be running on taint mode, so some checks are
            # performed to untaint data from the remote side.

            if ($copy_time) {
                unless (utime($atime, $mtime, $local) or $best_effort) {
                    $sftp->_set_error(SFTP_ERR_LOCAL_UTIME_FAILED,
                                      "Can't utime $local", $!);
                    goto CLEANUP;
                }
            }

            if ($atomic) {
                if (!$overwrite) {
                    while (1) {
                        # performing a non-overwriting atomic rename is
                        # quite burdensome: first, link is tried, if that
                        # fails, non-overwriting is favoured over
                        # atomicity and an empty file is used to lock the
                        # path before atempting an overwriting rename.
                        if (link $local, $atomic_local) {
                            unlink $local;
                            last;
                        }
                        my $err = $!;
                        unless (-e $atomic_local) {
                            if (sysopen my $lock, $atomic_local,
                                Fcntl::O_CREAT|Fcntl::O_EXCL|Fcntl::O_WRONLY,
                                0600) {
                                $atomic_cleanup = 1;
                                goto OVERWRITE;
                            }
                            $err = $!;
                            unless (-e $atomic_local) {
                                $sftp->_set_error(SFTP_ERR_LOCAL_OPEN_FAILED,
                                                  "Can't open $local", $err);
                                goto CLEANUP;
                            }
                        }
                        unless ($numbered) {
                            $sftp->_set_error(SFTP_ERR_LOCAL_ALREADY_EXISTS,
                                              "local file $atomic_local already exists");
                            goto CLEANUP;
                        }
                        _inc_numbered($atomic_local);
                    }
                }
                else {
                OVERWRITE:
                    unless (CORE::rename $local, $atomic_local) {
                        $sftp->_set_error(SFTP_ERR_LOCAL_RENAME_FAILED,
                                          "Unable to rename temporal file to its final position '$atomic_local'", $!);
                        goto CLEANUP;
                    }
                }
                $$atomic_numbered = $local if ref $atomic_numbered;
            }
        }
    CLEANUP:
        if ($cleanup and $sftp->{_error}) {
            unlink $local;
            unlink $atomic_local if $atomic_cleanup;
        }
    }; # autodie flag is restored here!

    $sftp->_ok_or_autodie;
}

# return file contents on success, undef on failure
sub get_content {
    @_ == 2 or croak 'Usage: $sftp->get_content($remote)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $name) = @_;
    $name = $sftp->_rel2abs($name);
    my @data;

    my $rfh = $sftp->open($name)
	or return undef;

    scalar $sftp->readline($rfh, undef);
}

sub put {
    @_ >= 2 or croak 'Usage: $sftp->put($local, $remote, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $local, $remote, %opts) = @_;
    defined $local or croak "local file path is undefined";

    $sftp->_clear_error_and_status;

    my $local_is_fh = (ref $local and $local->isa('GLOB'));
    unless (defined $remote) {
        $local_is_fh and croak "unable to infer remote file name when a file handler is passed as local";
        $remote = (File::Spec->splitpath($local))[2];
    }
    $remote = $sftp->_rel2abs($remote);

    my $cb = delete $opts{callback};
    my $umask = delete $opts{umask};
    my $perm = delete $opts{perm};
    my $copy_perm = delete $opts{copy_perm};
    $copy_perm = delete $opts{copy_perms} unless defined $copy_perm;
    my $copy_time = delete $opts{copy_time};
    my $overwrite = delete $opts{overwrite};
    my $resume = delete $opts{resume};
    my $append = delete $opts{append};
    my $block_size = delete $opts{block_size} || $sftp->{_block_size};
    my $queue_size = delete $opts{queue_size} || $sftp->{_queue_size};
    my $conversion = delete $opts{conversion};
    my $late_set_perm = delete $opts{late_set_perm};
    my $numbered = delete $opts{numbered};
    my $atomic = delete $opts{atomic};
    my $cleanup = delete $opts{cleanup};
    my $best_effort = delete $opts{best_effort};
    my $sparse = delete $opts{sparse};
    my $mkpath = delete $opts{mkpath};

    croak "'perm' and 'umask' options can not be used simultaneously"
	if (defined $perm and defined $umask);
    croak "'perm' and 'copy_perm' options can not be used simultaneously"
	if (defined $perm and $copy_perm);
    croak "'resume' and 'append' options can not be used simultaneously"
	if ($resume and $append);
    croak "'resume' and 'overwrite' options can not be used simultaneously"
	if ($resume and $overwrite);
    croak "'numbered' can not be used with 'overwrite', 'resume' or 'append'"
	if ($numbered and ($overwrite or $resume or $append));
    croak "'atomic' can not be used with 'resume' or 'append'"
        if ($atomic and ($resume or $append));

    %opts and _croak_bad_options(keys %opts);

    $overwrite = 1 unless (defined $overwrite or $numbered);
    $copy_perm = 1 unless (defined $perm or defined $copy_perm or $local_is_fh);
    $copy_time = 1 unless (defined $copy_time or $local_is_fh);
    $late_set_perm = $sftp->{_late_set_perm} unless defined $late_set_perm;
    $cleanup = ($atomic || $numbered) unless defined $cleanup;
    $mkpath = 1 unless defined $mkpath;

    my $neg_umask;
    if (defined $perm) {
	$neg_umask = $perm;
    }
    else {
	$umask = umask unless defined $umask;
	$neg_umask = 0777 & ~$umask;
    }

    my ($fh, $lmode, $lsize, $latime, $lmtime);
    if ($local_is_fh) {
	$fh = $local;
	# we don't set binmode for the passed file handle on purpose
    }
    else {
	unless (CORE::open $fh, '<', $local) {
	    $sftp->_set_error(SFTP_ERR_LOCAL_OPEN_FAILED,
			      "Unable to open local file '$local'", $!);
	    return undef;
	}
	binmode $fh;
    }

    {
	# as $fh can come from the outside, it may be a tied object
	# lacking support for some methods, so we call them wrapped
	# inside eval blocks
	local ($@, $SIG{__DIE__}, $SIG{__WARN__});
	if ((undef, undef, $lmode, undef, undef,
	     undef, undef, $lsize, $latime, $lmtime) =
	    eval {
		no warnings; # Calling stat on a tied handler
                             # generates a warning because the op is
                             # not supported by the tie API.
		CORE::stat $fh;
	    }
	   ) {
            $debug and $debug & 16384 and _debug "local file size is " . (defined $lsize ? $lsize : '<undef>');

	    # $fh can point at some place inside the file, not just at the
	    # begining
	    if ($local_is_fh and defined $lsize) {
		my $tell = eval { CORE::tell $fh };
		$lsize -= $tell if $tell and $tell > 0;
	    }
	}
	elsif ($copy_perm or $copy_time) {
	    $sftp->_set_error(SFTP_ERR_LOCAL_STAT_FAILED,
			      "Couldn't stat local file '$local'", $!);
	    return undef;
	}
	elsif ($resume and $resume eq 'auto') {
            $debug and $debug & 16384 and _debug "not resuming because stat'ing the local file failed";
	    undef $resume
	}
    }

    $perm = $lmode & $neg_umask if $copy_perm;
    my $attrs = Net::SFTP::Foreign::Attributes->new;
    $attrs->set_perm($perm) if defined $perm;

    my $rfh;
    my $writeoff = 0;
    my $converter = _gen_converter $conversion;
    my $converted_input = '';
    my $rattrs;

    if ($resume or $append) {
	$rattrs = do {
            local $sftp->{_autodie};
            $sftp->stat($remote);
        };
	if ($rattrs) {
	    if ($resume and $resume eq 'auto' and $rattrs->mtime <= $lmtime) {
                $debug and $debug & 16384 and
                    _debug "not resuming because local file is newer, r: ".$rattrs->mtime." l: $lmtime";
		undef $resume;
	    }
	    else {
		$writeoff = $rattrs->size;
		$debug and $debug & 16384 and _debug "resuming from $writeoff";
	    }
	}
        else {
            if ($append) {
                $sftp->{_status} == SSH2_FX_NO_SUCH_FILE
                    or $sftp->_ok_or_autodie or return undef;
                # no such file, no append
                undef $append;
            }
            $sftp->_clear_error_and_status;
        }
    }

    my ($atomic_numbered, $atomic_remote);
    if ($writeoff) {
        # one of $resume or $append is set
        if ($resume) {
            $debug and $debug & 16384 and _debug "resuming file transfer from $writeoff";
            if ($converter) {
                # as size could change, we have to read and convert
                # data until we reach the given position on the local
                # file:
                my $off = 0;
                my $eof_t;
                while (1) {
                    my $len = length $converted_input;
                    my $delta = $writeoff - $off;
                    if ($delta <= $len) {
                        $debug and $debug & 16384 and _debug "discarding $delta converted bytes";
                        substr $converted_input, 0, $delta, '';
                        last;
                    }
                    else {
                        $off += $len;
                        if ($eof_t) {
                            $sftp->_set_error(SFTP_ERR_REMOTE_BIGGER_THAN_LOCAL,
                                              "Couldn't resume transfer, remote file is bigger than local");
                            return undef;
                        }
                        my $read = CORE::read($fh, $converted_input, $block_size * 4);
                        unless (defined $read) {
                            $sftp->_set_error(SFTP_ERR_LOCAL_READ_ERROR,
                                              "Couldn't read from local file '$local' to the resume point $writeoff", $!);
                            return undef;
                        }
                        $lsize += $converter->($converted_input) if defined $lsize;
                        utf8::downgrade($converted_input, 1)
                                or croak "converter introduced wide characters in data";
                        $read or $eof_t = 1;
                    }
                }
            }
            elsif ($local_is_fh) {
                # as some PerlIO layer could be installed on the $fh,
                # just seeking to the resume position will not be
                # enough. We have to read and discard data until the
                # desired offset is reached
                my $off = $writeoff;
                while ($off) {
                    my $read = CORE::read($fh, my($buf), ($off < 16384 ? $off : 16384));
                    if ($read) {
                        $debug and $debug & 16384 and _debug "discarding $read bytes";
                        $off -= $read;
                    }
                    else {
                        $sftp->_set_error(defined $read
                                          ? ( SFTP_ERR_REMOTE_BIGGER_THAN_LOCAL,
                                              "Couldn't resume transfer, remote file is bigger than local")
                                          : ( SFTP_ERR_LOCAL_READ_ERROR,
                                              "Couldn't read from local file handler '$local' to the resume point $writeoff", $!));
                    }
                }
            }
            else {
                if (defined $lsize and $writeoff > $lsize) {
                    $sftp->_set_error(SFTP_ERR_REMOTE_BIGGER_THAN_LOCAL,
                                      "Couldn't resume transfer, remote file is bigger than local");
                    return undef;
                }
                unless (CORE::seek($fh, $writeoff, 0)) {
                    $sftp->_set_error(SFTP_ERR_LOCAL_SEEK_FAILED,
                                      "seek operation on local file failed: $!");
                    return undef;
                }
            }
            if (defined $lsize and $writeoff == $lsize) {
                if (defined $perm and $rattrs->perm != $perm) {
                    # FIXME: do copy_time here if required
                    return $sftp->_best_effort($best_effort, setstat => $remote, $attrs);
                }
                return 1;
            }
        }
        $rfh = $sftp->open($remote, SSH2_FXF_WRITE)
            or return undef;
    }
    else {
        if ($atomic) {
            # check that does not exist a file of the same name that
            # would block the rename operation at the end
            if (!($numbered or $overwrite) and
                $sftp->test_e($remote)) {
                $sftp->_set_status(SSH2_FX_FAILURE);
                $sftp->_set_error(SFTP_ERR_REMOTE_ALREADY_EXISTS,
                                  "Remote file '$remote' already exists");
                return undef;
            }
            $atomic_remote = $remote;
            $remote .= sprintf("(%d).tmp", rand(10000));
            $atomic_numbered = $numbered;
            $numbered = 1;
            $debug and $debug & 128 and _debug("temporal remote file name: $remote");
        }
        local $sftp->{_autodie};
	if ($numbered) {
            while (1) {
                $rfh = $sftp->_open_mkpath($remote,
                                          $mkpath,
                                          SSH2_FXF_WRITE | SSH2_FXF_CREAT | SSH2_FXF_EXCL,
                                          $attrs);
                last if ($rfh or
                         $sftp->{_status} != SSH2_FX_FAILURE or
                         !$sftp->test_e($remote));
                _inc_numbered($remote);
	    }
            $$numbered = $remote if $rfh and ref $numbered;
	}
        else {
            # open can fail due to a remote file with the wrong
            # permissions being already there. We are optimistic here,
            # first we try to open the remote file and if it fails due
            # to a permissions error then we remove it and try again.
            for my $rep (0, 1) {
                $rfh = $sftp->_open_mkpath($remote,
                                           $mkpath,
                                           SSH2_FXF_WRITE | SSH2_FXF_CREAT |
                                           ($overwrite ? SSH2_FXF_TRUNC : SSH2_FXF_EXCL),
                                           $attrs);

                last if $rfh or $rep or !$overwrite or $sftp->{_status} != SSH2_FX_PERMISSION_DENIED;

                $debug and $debug & 2 and _debug("retrying open after removing remote file");
                local ($sftp->{_status}, $sftp->{_error});
                $sftp->remove($remote);
            }
        }
    }

    $sftp->_ok_or_autodie or return undef;
    # Once this point is reached and for the remaining of the sub,
    # code should never return but jump into the CLEANUP block.

    my $last_block_was_zeros;

    do {
        local $sftp->{autodie};

        # In some SFTP server implementations, open does not set the
        # attributes for existent files so we do it again. The
        # $late_set_perm work around is for some servers that do not
        # support changing the permissions of open files
        if (defined $perm and !$late_set_perm) {
            $sftp->_best_effort($best_effort, setstat => $rfh, $attrs) or goto CLEANUP;
        }

        my $rfid = $sftp->_rfid($rfh);
        defined $rfid or die "internal error: rfid is undef";

        # In append mode we add the size of the remote file in
        # writeoff, if lsize is undef, we initialize it to $writeoff:
        $lsize += $writeoff if ($append or not defined $lsize);

        # when a converter is used, the EOF can become delayed by the
        # buffering introduced, we use $eof_t to account for that.
        my ($eof, $eof_t);
        my @msgid;
    OK: while (1) {
            if (!$eof and @msgid < $queue_size) {
                my ($data, $len);
                if ($converter) {
                    while (!$eof_t and length $converted_input < $block_size) {
                        my $read = CORE::read($fh, my $input, $block_size * 4);
                        unless ($read) {
                            unless (defined $read) {
                                $sftp->_set_error(SFTP_ERR_LOCAL_READ_ERROR,
                                                  "Couldn't read from local file '$local'", $!);
                                last OK;
                            }
                            $eof_t = 1;
                        }

                        # note that the $converter is called a last time
                        # with an empty string
                        $lsize += $converter->($input);
                        utf8::downgrade($input, 1)
                                or croak "converter introduced wide characters in data";
                        $converted_input .= $input;
                    }
                    $data = substr($converted_input, 0, $block_size, '');
                    $len = length $data;
                    $eof = 1 if ($eof_t and !$len);
                }
                else {
                    $debug and $debug & 16384 and
                        _debug "reading block at offset ".CORE::tell($fh)." block_size: $block_size";

                    $len = CORE::read($fh, $data, $block_size);

                    if ($len) {
                        $debug and $debug & 16384 and _debug "block read, size: $len";

                        utf8::downgrade($data, 1)
                                or croak "wide characters unexpectedly read from file";

                        $debug and $debug & 16384 and length $data != $len and
                            _debug "read data changed size on downgrade to " . length($data);
                    }
                    else {
                        unless (defined $len) {
                            $sftp->_set_error(SFTP_ERR_LOCAL_READ_ERROR,
                                              "Couldn't read from local file '$local'", $!);
                            last OK;
                        }
                        $eof = 1;
                    }
                }

                my $nextoff = $writeoff + $len;

                if (defined $cb) {
                    $lsize = $nextoff if $nextoff > $lsize;
                    $cb->($sftp, $data, $writeoff, $lsize);

                    last OK if $sftp->{_error};

                    utf8::downgrade($data, 1) or croak "callback introduced wide characters in data";

                    $len = length $data;
                    $nextoff = $writeoff + $len;
                }

                if ($len) {
                    if ($sparse and $data =~ /^\x{00}*$/s) {
                        $last_block_was_zeros = 1;
                        $debug and $debug & 16384 and _debug "skipping zeros block at offset $writeoff, length $len";
                    }
                    else {
                        $debug and $debug & 16384 and _debug "writing block at offset $writeoff, length $len";

                        my $id = $sftp->_queue_new_msg(SSH2_FXP_WRITE, str => $rfid,
                                                       int64 => $writeoff, str => $data);
                        push @msgid, $id;
                        $last_block_was_zeros = 0;
                    }
                    $writeoff = $nextoff;
                }
            }

            last if ($eof and !@msgid);

            next unless  ($eof
                          or @msgid >= $queue_size
                          or $sftp->_do_io(0));

            my $id = shift @msgid;
            unless ($sftp->_check_status_ok($id,
                                            SFTP_ERR_REMOTE_WRITE_FAILED,
                                            "Couldn't write to remote file")) {
                last OK;
            }
        }

        CORE::close $fh unless $local_is_fh;

        $sftp->_get_msg for (@msgid);

        $sftp->truncate($rfh, $writeoff)
            if $last_block_was_zeros and not $sftp->{_error};

        $sftp->_close_save_status($rfh);

        goto CLEANUP if $sftp->{_error};

        # set perm for servers that does not support setting
        # permissions on open files and also atime and mtime:
        if ($copy_time or ($late_set_perm and defined $perm)) {
            $attrs->set_perm unless $late_set_perm and defined $perm;
            $attrs->set_amtime($latime, $lmtime) if $copy_time;
            $sftp->_best_effort($best_effort, setstat => $remote, $attrs) or goto CLEANUP
        }

        if ($atomic) {
            $sftp->rename($remote, $atomic_remote,
                          overwrite => $overwrite,
                          numbered => $atomic_numbered) or goto CLEANUP;
        }

    CLEANUP:
        if ($cleanup and $sftp->{_error}) {
            warn "cleanup $remote";
            $sftp->_remove_save_status($remote);
        }
    };
    $sftp->_ok_or_autodie;
}

sub put_content {
    @_ >= 3 or croak 'Usage: $sftp->put_content($content, $remote, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, undef, $remote, %opts) = @_;
    my %put_opts = ( map { $_ => delete $opts{$_} }
                     qw(perm umask block_size queue_size overwrite conversion resume
                        numbered late_set_perm atomic best_effort mkpath));
    %opts and _croak_bad_options(keys %opts);

    my $fh;
    unless (CORE::open $fh, '<', \$_[1]) {
        $sftp->_set_error(SFTP_ERR_LOCAL_OPEN_FAILED, "Can't open scalar as file handle", $!);
        return undef;
    }
    $sftp->put($fh, $remote, %opts);
}

sub ls {
    @_ >= 1 or croak 'Usage: $sftp->ls($remote_dir, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my $sftp = shift;
    my %opts = @_ & 1 ? (dir => @_) : @_;

    my $dir = delete $opts{dir};
    my $ordered = delete $opts{ordered};
    my $follow_links = delete $opts{follow_links};
    my $atomic_readdir = delete $opts{atomic_readdir};
    my $names_only = delete $opts{names_only};
    my $realpath = delete $opts{realpath};
    my $queue_size = delete $opts{queue_size};
    my $cheap = ($names_only and !$realpath); 
    my ($cheap_wanted, $wanted);
    if ($cheap and
	ref $opts{wanted} eq 'RegExp' and 
	not defined $opts{no_wanted}) {
	$cheap_wanted = delete $opts{wanted}
    }
    else {
	$wanted = (delete $opts{_wanted} ||
		   _gen_wanted(delete $opts{wanted},
			       delete $opts{no_wanted}));
	undef $cheap if defined $wanted;
    }

    %opts and _croak_bad_options(keys %opts);

    my $delayed_wanted = ($atomic_readdir and $wanted);
    $queue_size = 1 if ($follow_links or $realpath or
			($wanted and not $delayed_wanted));
    my $max_queue_size = $queue_size || $sftp->{_queue_size};
    $queue_size ||= 2;

    $dir = '.' unless defined $dir;
    $dir = $sftp->_rel2abs($dir);

    my $rdh = $sftp->opendir($dir);
    return unless defined $rdh;

    my $rdid = $sftp->_rdid($rdh);
    defined $rdid or return undef;

    my @dir;
    my @msgid;

    do {
        local $sftp->{_autodie};
    OK: while (1) {
            push @msgid, $sftp->_queue_str_request(SSH2_FXP_READDIR, $rdid)
                while (@msgid < $queue_size);

            my $id = shift @msgid;
            if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_NAME, $id,
                                                    SFTP_ERR_REMOTE_READDIR_FAILED,
                                                    "Couldn't read directory '$dir'" )) {
                my $count = $msg->get_int32 or last;

                if ($cheap) {
                    for (1..$count) {
                        my $fn = $sftp->_fs_decode($msg->get_str);
                        push @dir, $fn if (!defined $cheap_wanted or $fn =~ $cheap_wanted);
                        $msg->skip_str;
                        Net::SFTP::Foreign::Attributes->skip_from_buffer($msg);
                    }
                }
                else {
                    for (1..$count) {
                        my $fn = $sftp->_fs_decode($msg->get_str);
                        my $ln = $sftp->_fs_decode($msg->get_str);
                        # my $a = $msg->get_attributes;
                        my $a = Net::SFTP::Foreign::Attributes->new_from_buffer($msg);

                        my $entry =  { filename => $fn,
                                       longname => $ln,
                                       a => $a };

                        if ($follow_links and _is_lnk($a->perm)) {

                            if ($a = $sftp->stat($sftp->join($dir, $fn))) {
                                $entry->{a} = $a;
                            }
                            else {
                                $sftp->_clear_error_and_status;
                            }
                        }

                        if ($realpath) {
                            my $rp = $sftp->realpath($sftp->join($dir, $fn));
                            if (defined $rp) {
                                $fn = $entry->{realpath} = $rp;
                            }
                            else {
                                $sftp->_clear_error_and_status;
                            }
                        }

                        if (!$wanted or $delayed_wanted or $wanted->($sftp, $entry)) {
                            push @dir, (($names_only and !$delayed_wanted) ? $fn : $entry);
                        }
                    }
                }

                $queue_size ++ if $queue_size < $max_queue_size;
            }
            else {
                $sftp->_set_error if $sftp->{_status} == SSH2_FX_EOF;
                $sftp->_get_msg for @msgid;
                last;
            }
        }
        $sftp->_closedir_save_status($rdh) if $rdh;
    };
    unless ($sftp->{_error}) {
	if ($delayed_wanted) {
	    @dir = grep { $wanted->($sftp, $_) } @dir;
	    @dir = map { defined $_->{realpath}
			 ? $_->{realpath}
			 : $_->{filename} } @dir
		if $names_only;
	}
        if ($ordered) {
            if ($names_only) {
                @dir = sort @dir;
            }
            else {
                _sort_entries \@dir;
            }
        }
	return \@dir;
    }
    croak $sftp->{_error} if $sftp->{_autodie};
    return undef;
}

sub rremove {
    @_ >= 2 or croak 'Usage: $sftp->rremove($dirs, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $dirs, %opts) = @_;

    my $on_error = delete $opts{on_error};
    local $sftp->{_autodie} if $on_error;
    my $wanted = _gen_wanted( delete $opts{wanted},
			      delete $opts{no_wanted});

    %opts and _croak_bad_options(keys %opts);

    my $count = 0;

    my @dirs;
    $sftp->find( $dirs,
		 on_error => $on_error,
		 atomic_readdir => 1,
		 wanted => sub {
		     my $e = $_[1];
		     my $fn = $e->{filename};
		     if (_is_dir($e->{a}->perm)) {
			 push @dirs, $e;
		     }
		     else {
			 if (!$wanted or $wanted->($sftp, $e)) {
			     if ($sftp->remove($fn)) {
				 $count++;
			     }
			     else {
				 $sftp->_call_on_error($on_error, $e);
			     }
			 }
		     }
		 } );

    _sort_entries(\@dirs);

    while (@dirs) {
	my $e = pop @dirs;
	if (!$wanted or $wanted->($sftp, $e)) {
	    if ($sftp->rmdir($e->{filename})) {
		$count++;
	    }
	    else {
		$sftp->_call_on_error($on_error, $e);
	    }
	}
    }

    return $count;
}

sub get_symlink {
    @_ >= 3 or croak 'Usage: $sftp->get_symlink($remote, $local, %opts)';
    my ($sftp, $remote, $local, %opts) = @_;
    my $overwrite = delete $opts{overwrite};
    my $numbered = delete $opts{numbered};

    croak "'overwrite' and 'numbered' can not be used together"
	if ($overwrite and $numbered);
   %opts and _croak_bad_options(keys %opts);

    $overwrite = 1 unless (defined $overwrite or $numbered);

    my $a = $sftp->lstat($remote) or return undef;
    unless (_is_lnk($a->perm)) {
	$sftp->_set_error(SFTP_ERR_REMOTE_BAD_OBJECT,
			  "Remote object '$remote' is not a symlink");
	return undef;
    }

    my $link = $sftp->readlink($remote) or return undef;

    # TODO: this is too weak, may contain race conditions.
    if ($numbered) {
        _inc_numbered($local) while -e $local;
    }
    elsif (-e $local) {
	if ($overwrite) {
	    unlink $local;
	}
	else {
	    $sftp->_set_error(SFTP_ERR_LOCAL_ALREADY_EXISTS,
			      "local file $local already exists");
	    return undef
	}
    }

    unless (eval { CORE::symlink $link, $local }) {
	$sftp->_set_error(SFTP_ERR_LOCAL_SYMLINK_FAILED,
			  "creation of symlink '$local' failed", $!);
	return undef;
    }
    $$numbered = $local if ref $numbered;

    1;
}

sub put_symlink {
    @_ >= 3 or croak 'Usage: $sftp->put_symlink($local, $remote, %opts)';
    my ($sftp, $local, $remote, %opts) = @_;
    my $overwrite = delete $opts{overwrite};
    my $numbered = delete $opts{numbered};

    croak "'overwrite' and 'numbered' can not be used together"
	if ($overwrite and $numbered);
    %opts and _croak_bad_options(keys %opts);

    $overwrite = 1 unless (defined $overwrite or $numbered);
    my $perm = (CORE::lstat $local)[2];
    unless (defined $perm) {
	$sftp->_set_error(SFTP_ERR_LOCAL_STAT_FAILED,
			  "Couldn't stat local file '$local'", $!);
	return undef;
    }
    unless (_is_lnk($perm)) {
	$sftp->_set_error(SFTP_ERR_LOCAL_BAD_OBJECT,
			  "Local file $local is not a symlink");
	return undef;
    }
    my $target = readlink $local;
    unless (defined $target) {
	$sftp->_set_error(SFTP_ERR_LOCAL_READLINK_FAILED,
			  "Couldn't read link '$local'", $!);
	return undef;
    }

    while (1) {
        local $sftp->{_autodie};
        $sftp->symlink($remote, $target);
        if ($sftp->{_error} and
            $sftp->{_status} == SSH2_FX_FAILURE) {
            if ($numbered and $sftp->test_e($remote)) {
                _inc_numbered($remote);
                redo;
            }
            elsif ($overwrite and $sftp->_remove_save_status($remote)) {
                $overwrite = 0;
                redo;
            }
        }
        last
    }
    $$numbered = $remote if ref $numbered;
    $sftp->_ok_or_autodie;
}

sub rget {
    @_ >= 2 or croak 'Usage: $sftp->rget($remote, $local, %opts)';
    ${^TAINT} and &_catch_tainted_args;
    my ($sftp, $remote, $local, %opts) = @_;

    defined $remote or croak "remote file path is undefined";
    $local = File::Spec->curdir unless defined $local;

    # my $cb = delete $opts{callback};
    my $umask = delete $opts{umask};
    my $copy_perm = delete $opts{exists $opts{copy_perm} ? 'copy_perm' : 'copy_perms'};
    my $copy_time = delete $opts{copy_time};
    my $newer_only = delete $opts{newer_only};
    my $on_error = delete $opts{on_error};
    local $sftp->{_autodie} if $on_error;
    my $ignore_links = delete $opts{ignore_links};
    my $mkpath = delete $opts{mkpath};

    # my $relative_links = delete $opts{relative_links};

    my $wanted = _gen_wanted( delete $opts{wanted},
			      delete $opts{no_wanted} );

    my %get_opts = (map { $_ => delete $opts{$_} }
                    qw(block_size queue_size overwrite conversion
                       resume numbered atomic best_effort));

    if ($get_opts{resume} and $get_opts{conversion}) {
        carp "resume option is useless when data conversion has also been requested";
        delete $get_opts{resume};
    }

    my %get_symlink_opts = (map { $_ => $get_opts{$_} }
                            qw(overwrite numbered));

    %opts and _croak_bad_options(keys %opts);

    $remote = $sftp->join($remote, './');
    my $qremote = quotemeta $remote;
    my $reremote = qr/^$qremote(.*)$/i;

    my $save = _umask_save_and_set $umask;

    $copy_perm = 1 unless defined $copy_perm;
    $copy_time = 1 unless defined $copy_time;
    $mkpath    = 1 unless defined $mkpath;

    my $count = 0;
    $sftp->find( [$remote],
		 descend => sub {
		     my $e = $_[1];
		     # print "descend: $e->{filename}\n";
		     if (!$wanted or $wanted->($sftp, $e)) {
			 my $fn = $e->{filename};
			 if ($fn =~ $reremote) {
			     my $lpath = File::Spec->catdir($local, $1);
                             ($lpath) = $lpath =~ /(.*)/ if ${^TAINT};
			     if (-d $lpath) {
				 $sftp->_set_error(SFTP_ERR_LOCAL_ALREADY_EXISTS,
						   "directory '$lpath' already exists");
				 $sftp->_call_on_error($on_error, $e);
				 return 1;
			     }
			     else {
                                 my $perm = ($copy_perm ? $e->{a}->perm & 0777 : 0777);
                                 if (CORE::mkdir($lpath, $perm) or
                                     ($mkpath and $sftp->_mkpath_local($lpath, $perm))) {
				     $count++;
				     return 1;
				 }
                                 $sftp->_set_error(SFTP_ERR_LOCAL_MKDIR_FAILED,
                                                   "mkdir '$lpath' failed", $!);
			     }
			 }
			 else {
			     $sftp->_set_error(SFTP_ERR_REMOTE_BAD_PATH,
					       "bad remote path '$fn'");
			 }
			 $sftp->_call_on_error($on_error, $e);
		     }
		     return undef;
		 },
		 wanted => sub {
		     my $e = $_[1];
		     unless (_is_dir($e->{a}->perm)) {
			 if (!$wanted or $wanted->($sftp, $e)) {
			     my $fn = $e->{filename};
			     if ($fn =~ $reremote) {
				 my $lpath = ((length $1) ? File::Spec->catfile($local, $1) : $local);
                                 # print "file fn:$e->{filename}, lpath:$lpath, re:$reremote\n";
                                 ($lpath) = $lpath =~ /(.*)/ if ${^TAINT};
				 if (_is_lnk($e->{a}->perm) and !$ignore_links) {
				     if ($sftp->get_symlink($fn, $lpath,
							    # copy_time => $copy_time,
                                                            %get_symlink_opts)) {
					 $count++;
					 return undef;
				     }
				 }
				 elsif (_is_reg($e->{a}->perm)) {
				     if ($newer_only and -e $lpath
					 and (CORE::stat _)[9] >= $e->{a}->mtime) {
					 $sftp->_set_error(SFTP_ERR_LOCAL_ALREADY_EXISTS,
							   "newer local file '$lpath' already exists");
				     }
				     else {
					 if ($sftp->get($fn, $lpath,
							copy_perm => $copy_perm,
							copy_time => $copy_time,
                                                        %get_opts)) {
					     $count++;
					     return undef;
					 }
				     }
				 }
				 else {
				     $sftp->_set_error(SFTP_ERR_REMOTE_BAD_OBJECT,
						       ( $ignore_links
							 ? "remote file '$fn' is not regular file or directory"
							 : "remote file '$fn' is not regular file, directory or link"));
				 }
			     }
			     else {
				 $sftp->_set_error(SFTP_ERR_REMOTE_BAD_PATH,
						   "bad remote path '$fn'");
			     }
			     $sftp->_call_on_error($on_error, $e);
			 }
		     }
		     return undef;
		 } );

    return $count;
}

sub rput {
    @_ >= 2 or croak 'Usage: $sftp->rput($local, $remote, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $local, $remote, %opts) = @_;

    defined $local or croak "local path is undefined";
    $remote = '.' unless defined $remote;

    # my $cb = delete $opts{callback};
    my $umask = delete $opts{umask};
    my $perm = delete $opts{perm};
    my $copy_perm = delete $opts{exists $opts{copy_perm} ? 'copy_perm' : 'copy_perms'};
    my $copy_time = delete $opts{copy_time};

    my $newer_only = delete $opts{newer_only};
    my $on_error = delete $opts{on_error};
    local $sftp->{_autodie} if $on_error;
    my $ignore_links = delete $opts{ignore_links};
    my $mkpath = delete $opts{mkpath};

    my $wanted = _gen_wanted( delete $opts{wanted},
			      delete $opts{no_wanted} );

    my %put_opts = (map { $_ => delete $opts{$_} }
		    qw(block_size queue_size overwrite
                       conversion resume numbered
                       late_set_perm atomic best_effort
                       sparse));

    my %put_symlink_opts = (map { $_ => $put_opts{$_} }
                            qw(overwrite numbered));

    croak "'perm' and 'umask' options can not be used simultaneously"
        if (defined $perm and defined $umask);
    croak "'perm' and 'copy_perm' options can not be used simultaneously"
        if (defined $perm and $copy_perm);

    %opts and _croak_bad_options(keys %opts);

    require Net::SFTP::Foreign::Local;
    my $lfs = Net::SFTP::Foreign::Local->new;

    $local = $lfs->join($local, './');
    my $relocal;
    if ($local =~ m|^\./?$|) {
	$relocal = qr/^(.*)$/;
    }
    else {
	my $qlocal = quotemeta $local;
	$relocal = qr/^$qlocal(.*)$/i;
    }

    $copy_perm = 1 unless defined $copy_perm;
    $copy_time = 1 unless defined $copy_time;
    $mkpath = 1 unless defined $mkpath;

    my $mask;
    if (defined $perm) {
        $mask = $perm & 0777;
    }
    else {
        $umask = umask unless defined $umask;
        $mask = 0777 & ~$umask;
    }

    if ($on_error) {
	my $on_error1 = $on_error;
	$on_error = sub {
	    my $lfs = shift;
	    $sftp->_copy_error($lfs);
	    $sftp->_call_on_error($on_error1, @_);
	}
    }

    my $count = 0;
    $lfs->find( [$local],
		descend => sub {
		    my $e = $_[1];
		    # print "descend: $e->{filename}\n";
		    if (!$wanted or $wanted->($lfs, $e)) {
			my $fn = $e->{filename};
			$debug and $debug & 32768 and _debug "rput handling $fn";
			if ($fn =~ $relocal) {
			    my $rpath = $sftp->join($remote, File::Spec->splitdir($1));
			    $debug and $debug & 32768 and _debug "rpath: $rpath";
                            my $a = Net::SFTP::Foreign::Attributes->new;
                            if (defined $perm) {
                                $a->set_perm($mask | 0300);
                            }
                            elsif ($copy_perm) {
                                $a->set_perm($e->{a}->perm & $mask);
                            }
                            if ($sftp->mkdir($rpath, $a)) {
                                $count++;
                                return 1;
                            }
                            if ($mkpath and
                                $sftp->status == SSH2_FX_NO_SUCH_FILE) {
                                $sftp->_clear_error_and_status;
                                if ($sftp->mkpath($rpath, $a)) {
                                    $count++;
                                    return 1;
                                }
                            }
                            $lfs->_copy_error($sftp);
                            if ($sftp->test_d($rpath)) {
				$lfs->_set_error(SFTP_ERR_REMOTE_ALREADY_EXISTS,
						 "Remote directory '$rpath' already exists");
				$lfs->_call_on_error($on_error, $e);
				return 1;
			    }
			}
			else {
			    $lfs->_set_error(SFTP_ERR_LOCAL_BAD_PATH,
					      "Bad local path '$fn'");
			}
			$lfs->_call_on_error($on_error, $e);
		    }
		    return undef;
		},
		wanted => sub {
		    my $e = $_[1];
		    # print "file fn:$e->{filename}, a:$e->{a}\n";
		    unless (_is_dir($e->{a}->perm)) {
			if (!$wanted or $wanted->($lfs, $e)) {
			    my $fn = $e->{filename};
			    $debug and $debug & 32768 and _debug "rput handling $fn";
			    if ($fn =~ $relocal) {
				my (undef, $d, $f) = File::Spec->splitpath($1);
				my $rpath = $sftp->join($remote, File::Spec->splitdir($d), $f);
				if (_is_lnk($e->{a}->perm) and !$ignore_links) {
				    if ($sftp->put_symlink($fn, $rpath,
                                                           %put_symlink_opts)) {
					$count++;
					return undef;
				    }
				    $lfs->_copy_error($sftp);
				}
				elsif (_is_reg($e->{a}->perm)) {
				    my $ra;
				    if ( $newer_only and
					 $ra = $sftp->stat($rpath) and
					 $ra->mtime >= $e->{a}->mtime) {
					$lfs->_set_error(SFTP_ERR_REMOTE_ALREADY_EXISTS,
							 "Newer remote file '$rpath' already exists");
				    }
				    else {
					if ($sftp->put($fn, $rpath,
                                                       ( defined($perm) ? (perm => $perm)
                                                         : $copy_perm   ? (perm => $e->{a}->perm & $mask)
                                                         : (copy_perm => 0, umask => $umask) ),
						       copy_time => $copy_time,
                                                       %put_opts)) {
					    $count++;
					    return undef;
					}
					$lfs->_copy_error($sftp);
				    }
				}
				else {
				    $lfs->_set_error(SFTP_ERR_LOCAL_BAD_OBJECT,
						      ( $ignore_links
							? "Local file '$fn' is not regular file or directory"
							: "Local file '$fn' is not regular file, directory or link"));
				}
			    }
			    else {
				$lfs->_set_error(SFTP_ERR_LOCAL_BAD_PATH,
						  "Bad local path '$fn'");
			    }
			    $lfs->_call_on_error($on_error, $e);
			}
		    }
		    return undef;
		} );

    return $count;
}

sub mget {
    @_ >= 2 or croak 'Usage: $sftp->mget($remote, $localdir, %opts)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $remote, $localdir, %opts) = @_;

    defined $remote or croak "remote pattern is undefined";

    my $on_error = $opts{on_error};
    local $sftp->{_autodie} if $on_error;
    my $ignore_links = delete $opts{ignore_links};

    my %glob_opts = (map { $_ => delete $opts{$_} }
		     qw(on_error follow_links ignore_case
                        wanted no_wanted strict_leading_dot));

    my %get_symlink_opts = (map { $_ => $opts{$_} }
			    qw(overwrite numbered));

    my %get_opts = (map { $_ => delete $opts{$_} }
		    qw(umask perm copy_perm copy_time block_size queue_size
                       overwrite conversion resume numbered atomic best_effort mkpath));

    %opts and _croak_bad_options(keys %opts);

    my @remote = map $sftp->glob($_, %glob_opts), _ensure_list $remote;

    my $count = 0;

    require File::Spec;
    for my $e (@remote) {
	my $perm = $e->{a}->perm;
	if (_is_dir($perm)) {
	    $sftp->_set_error(SFTP_ERR_REMOTE_BAD_OBJECT,
			      "Remote object '$e->{filename}' is a directory");
	}
	else {
	    my $fn = $e->{filename};
	    my ($local) = $fn =~ m{([^\\/]*)$};

	    $local = File::Spec->catfile($localdir, $local)
		if defined $localdir;

	    if (_is_lnk($perm)) {
		next if $ignore_links;
		$sftp->get_symlink($fn, $local, %get_symlink_opts);
	    }
	    else {
		$sftp->get($fn, $local, %get_opts);
	    }
	}
	$count++ unless $sftp->{_error};
	$sftp->_call_on_error($on_error, $e);
    }
    $count;
}

sub mput {
    @_ >= 2 or croak 'Usage: $sftp->mput($local, $remotedir, %opts)';

    my ($sftp, $local, $remotedir, %opts) = @_;

    defined $local or die "local pattern is undefined";

    my $on_error = $opts{on_error};
    local $sftp->{_autodie} if $on_error;
    my $ignore_links = delete $opts{ignore_links};

    my %glob_opts = (map { $_ => delete $opts{$_} }
		     qw(on_error follow_links ignore_case
                        wanted no_wanted strict_leading_dot));
    my %put_symlink_opts = (map { $_ => $opts{$_} }
			    qw(overwrite numbered));

    my %put_opts = (map { $_ => delete $opts{$_} }
		    qw(umask perm copy_perm copy_time block_size queue_size
                       overwrite conversion resume numbered late_set_perm
                       atomic best_effort sparse mkpath));

    %opts and _croak_bad_options(keys %opts);

    require Net::SFTP::Foreign::Local;
    my $lfs = Net::SFTP::Foreign::Local->new;
    my @local = map $lfs->glob($_, %glob_opts), _ensure_list $local;

    my $count = 0;
    require File::Spec;
    for my $e (@local) {
	my $perm = $e->{a}->perm;
	if (_is_dir($perm)) {
	    $sftp->_set_error(SFTP_ERR_REMOTE_BAD_OBJECT,
			      "Remote object '$e->{filename}' is a directory");
	}
	else {
	    my $fn = $e->{filename};
	    my $remote = (File::Spec->splitpath($fn))[2];
	    $remote = $sftp->join($remotedir, $remote)
		if defined $remotedir;

	    if (_is_lnk($perm)) {
		next if $ignore_links;
		$sftp->put_symlink($fn, $remote, %put_symlink_opts);
	    }
	    else {
		$sftp->put($fn, $remote, %put_opts);
	    }
	}
	$count++ unless $sftp->{_error};
	$sftp->_call_on_error($on_error, $e);
    }
    $count;
}

sub fsync {
    @_ == 2 or croak 'Usage: $sftp->fsync($fh)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $fh) = @_;

    $sftp->flush($fh, "out");
    $sftp->_check_extension('fsync@openssh.com' => 1,
                            SFTP_ERR_REMOTE_FSYNC_FAILED,
                            "fsync failed, not implemented")
        or return undef;

    my $id = $sftp->_queue_new_msg(SSH2_FXP_EXTENDED,
                                   str => 'fsync@openssh.com',
                                   str => $sftp->_rid($fh));
    if ($sftp->_check_status_ok($id,
                                SFTP_ERR_REMOTE_FSYNC_FAILED,
                                "Couldn't fsync remote file")) {
        return 1;
    }
    return undef;
}

sub statvfs {
    @_ == 2 or croak 'Usage: $sftp->statvfs($path_or_fh)';
    ${^TAINT} and &_catch_tainted_args;

    my ($sftp, $pofh) = @_;
    my ($extension, $arg) = ( (ref $pofh and UNIVERSAL::isa($pofh, 'Net::SFTP::Foreign::FileHandle'))
                              ? ('fstatvfs@openssh.com', $sftp->_rid($pofh) )
                              : ('statvfs@openssh.com' , $sftp->_fs_encode($sftp->_rel2abs($pofh)) ) );

    $sftp->_check_extension($extension => 2,
                            SFTP_ERR_REMOTE_STATVFS_FAILED,
                            "statvfs failed, not implemented")
        or return undef;

    my $id = $sftp->_queue_new_msg(SSH2_FXP_EXTENDED,
                                   str => $extension,
                                   str => $arg);

    if (my $msg = $sftp->_get_msg_and_check(SSH2_FXP_EXTENDED_REPLY, $id,
                                            SFTP_ERR_REMOTE_STATVFS_FAILED,
                                            "Couldn't stat remote file system")) {
        my %statvfs = map { $_ => $msg->get_int64 } qw(bsize frsize blocks
                                                       bfree bavail files ffree
                                                       favail fsid flag namemax);
        return \%statvfs;
    }
    return undef;
}

sub fstatvfs {
    _deprecated "fstatvfs is deprecated and will be removed on the upcoming 2.xx series, "
        . "statvfs method accepts now both file handlers and paths";
    goto &statvfs;
}

package Net::SFTP::Foreign::Handle;

use Tie::Handle;
our @ISA = qw(Tie::Handle);
our @CARP_NOT = qw(Net::SFTP::Foreign Tie::Handle);

my $gen_accessor = sub {
    my $ix = shift;
    sub {
	my $st = *{shift()}{ARRAY};
	if (@_) {
	    $st->[$ix] = shift;
	}
	else {
	    $st->[$ix]
	}
    }
};

my $gen_proxy_method = sub {
    my $method = shift;
    sub {
	my $self = $_[0];
	$self->_check
	    or return undef;

	my $sftp = $self->_sftp;
	if (wantarray) {
	    my @ret = $sftp->$method(@_);
	    $sftp->_set_errno unless @ret;
	    return @ret;
	}
	else {
	    my $ret = $sftp->$method(@_);
	    $sftp->_set_errno unless defined $ret;
	    return $ret;
	}
    }
};

my $gen_not_supported = sub {
    sub {
	$! = Errno::ENOTSUP();
	undef
    }
};

sub TIEHANDLE { return shift }

# sub UNTIE {}

sub _new_from_rid {
    my $class = shift;
    my $sftp = shift;
    my $rid = shift;
    my $flags = shift || 0;

    my $self = Symbol::gensym;
    bless $self, $class;
    *$self = [ $sftp, $rid, 0, $flags, @_];
    tie *$self, $self;

    $self;
}

sub _close {
    my $self = shift;
    @{*{$self}{ARRAY}} = ();
}

sub _check {
    return 1 if defined(*{shift()}{ARRAY}[0]);
    $! = Errno::EBADF();
    undef;
}

sub FILENO {
    my $self = shift;
    $self->_check
	or return undef;

    my $hrid = unpack 'H*' => $self->_rid;
    "-1:sftp(0x$hrid)"
}

sub _sftp { *{shift()}{ARRAY}[0] }
sub _rid { *{shift()}{ARRAY}[1] }

* _pos = $gen_accessor->(2);

sub _inc_pos {
    my ($self, $inc) = @_;
    *{shift()}{ARRAY}[2] += $inc;
}


my %flag_bit = (append => 0x1);

sub _flag {
    my $st = *{shift()}{ARRAY};
    my $fn = shift;
    my $flag = $flag_bit{$fn};
    Carp::croak("unknown flag $fn") unless defined $flag;
    if (@_) {
	if (shift) {
	    $st->[3] |= $flag;
	}
	else {
	    $st->[3] &= ~$flag;
	}
    }
    $st->[3] & $flag ? 1 : 0
}

sub _check_is_file {
    Carp::croak("expecting remote file handler, got directory handler");
}
sub _check_is_dir {
    Carp::croak("expecting remote directory handler, got file handler");
}

my $autoloaded;
sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    if ($autoloaded) {
	my $class = ref $self || $self;
	Carp::croak qq|Can't locate object method "$AUTOLOAD" via package "$class|;
    }
    else {
	$autoloaded = 1;
	require IO::File;
	require IO::Dir;
	my ($method) = $AUTOLOAD =~ /^.*::(.*)$/;
	$self->$method(@_);
    }
}

package Net::SFTP::Foreign::FileHandle;
our @ISA = qw(Net::SFTP::Foreign::Handle IO::File);

sub _new_from_rid {
    my $class = shift;
    my $sftp = shift;
    my $rid = shift;
    my $flags = shift;

    my $self = $class->SUPER::_new_from_rid($sftp, $rid, $flags, '', '');
}

sub _check_is_file {}

sub _bin { \(*{shift()}{ARRAY}[4]) }
sub _bout { \(*{shift()}{ARRAY}[5]) }

sub WRITE {
    my ($self, undef, $length, $offset) = @_;
    $self->_check
	or return undef;

    $offset = 0 unless defined $offset;
    $offset = length $_[1] + $offset if $offset < 0;
    $length = length $_[1] unless defined $length;

    my $sftp = $self->_sftp;

    my $ret = $sftp->write($self, substr($_[1], $offset, $length));
    $sftp->_set_errno unless defined $ret;
    $ret;
}

sub READ {
    my ($self, undef, $len, $offset) = @_;
    $self->_check
	or return undef;

    $_[1] = '' unless defined $_[1];
    $offset ||= 0;
    if ($offset > length $_[1]) {
	$_[1] .= "\0" x ($offset - length $_[1])
    }

    if ($len == 0) {
	substr($_[1], $offset) = '';
	return 0;
    }

    my $sftp = $self->_sftp;
    $sftp->_fill_read_cache($self, $len);

    my $bin = $self->_bin;
    if (length $$bin) {
	my $data = substr($$bin, 0, $len, '');
	$self->_inc_pos($len);
	substr($_[1], $offset) = $data;
	return length $data;
    }
    return 0 if $sftp->{_status} == $sftp->SSH2_FX_EOF;
    $sftp->_set_errno;
    undef;
}

sub EOF {
    my $self = $_[0];
    $self->_check or return undef;
    my $sftp = $self->_sftp;
    my $ret = $sftp->eof($self);
    $sftp->_set_errno unless defined $ret;
    $ret;
}

*GETC = $gen_proxy_method->('getc');
*TELL = $gen_proxy_method->('tell');
*SEEK = $gen_proxy_method->('seek');
*CLOSE = $gen_proxy_method->('close');

my $readline = $gen_proxy_method->('readline');
sub READLINE { $readline->($_[0], $/) }

sub OPEN {
    shift->CLOSE;
    undef;
}

sub DESTROY {
    local ($@, $!, $?);
    my $self = shift;
    my $sftp = $self->_sftp;
    $debug and $debug & 4 and Net::SFTP::Foreign::_debug("$self->DESTROY called (sftp: ".($sftp||'<undef>').")");
    if ($self->_check and $sftp) {
        local $sftp->{_autodie};
	$sftp->_close_save_status($self)
    }
}

package Net::SFTP::Foreign::DirHandle;
our @ISA = qw(Net::SFTP::Foreign::Handle IO::Dir);

sub _new_from_rid {
    my $class = shift;
    my $sftp = shift;
    my $rid = shift;
    my $flags = shift;

    my $self = $class->SUPER::_new_from_rid($sftp, $rid, $flags, []);
}


sub _check_is_dir {}

sub _cache { *{shift()}{ARRAY}[4] }

*CLOSEDIR = $gen_proxy_method->('closedir');
*READDIR = $gen_proxy_method->('_readdir');

sub OPENDIR {
    shift->CLOSEDIR;
    undef;
}

*REWINDDIR = $gen_not_supported->();
*TELLDIR = $gen_not_supported->();
*SEEKDIR = $gen_not_supported->();

sub DESTROY {
    local ($@, $!, $?);
    my $self = shift;
    my $sftp = $self->_sftp;

    $debug and $debug & 4 and Net::SFTP::Foreign::_debug("$self->DESTROY called (sftp: ".($sftp||'').")");

    if ($self->_check and $sftp) {
        local $sftp->{_autodie};
	$sftp->_closedir_save_status($self)
    }
}

1;
__END__

=head1 NAME

Net::SFTP::Foreign - SSH File Transfer Protocol client

=head1 SYNOPSIS

    use Net::SFTP::Foreign;
    my $sftp = Net::SFTP::Foreign->new($host);
    $sftp->die_on_error("Unable to establish SFTP connection");

    $sftp->setcwd($path) or die "unable to change cwd: " . $sftp->error;

    $sftp->get("foo", "bar") or die "get failed: " . $sftp->error;

    $sftp->put("bar", "baz") or die "put failed: " . $sftp->error;

=head1 DESCRIPTION

SFTP stands for SSH File Transfer Protocol and is a method of
transferring files between machines over a secure, encrypted
connection (as opposed to regular FTP, which functions over an
insecure connection). The security in SFTP comes through its
integration with SSH, which provides an encrypted transport layer over
which the SFTP commands are executed.

Net::SFTP::Foreign is a Perl client for the SFTP version 3 as defined
in the SSH File Transfer Protocol IETF draft, which can be found at
L<http://www.openssh.org/txt/draft-ietf-secsh-filexfer-02.txt> (also
included on this package distribution, on the C<rfc> directory).

Net::SFTP::Foreign uses any compatible C<ssh> command installed on
the system (for instance, OpenSSH C<ssh>) to establish the secure
connection to the remote server.

A wrapper module L<Net::SFTP::Foreign::Compat> is also provided for
compatibility with L<Net::SFTP>.


=head2 Net::SFTP::Foreign Vs. Net::SFTP Vs. Net::SSH2::SFTP

Why should I prefer Net::SFTP::Foreign over L<Net::SFTP>?

Well, both modules have their pros and cons:

Net::SFTP::Foreign does not require a bunch of additional modules and
external libraries to work, just the OpenBSD SSH client (or any other
client compatible enough).

I trust OpenSSH SSH client more than L<Net::SSH::Perl>, there are lots
of paranoid people ensuring that OpenSSH doesn't have security
holes!!!

If you have an SSH infrastructure already deployed, by using the same
binary SSH client, Net::SFTP::Foreign ensures a seamless integration
within your environment (configuration files, keys, etc.).

Net::SFTP::Foreign is much faster transferring files, specially over
networks with high (relative) latency.

Net::SFTP::Foreign provides several high level methods not available
from Net::SFTP as for instance C<find>, C<glob>, C<rget>, C<rput>,
C<rremove>, C<mget>, C<mput>.

On the other hand, using the external command means an additional
process being launched and running, depending on your OS this could
eat more resources than the in process pure perl implementation
provided by L<Net::SSH::Perl>.

L<Net::SSH2> is a module wrapping libssh2, an SSH version 2 client
library written in C. It is a very active project that aims to replace
L<Net::SSH::Perl>. Unfortunately, libssh2 SFTP functionality
(available in Perl via L<Net::SSH2::SFTP>) is rather limited and its
performance very poor.

Later versions of Net::SFTP::Foreign can use L<Net::SSH2> as the
transport layer via the backend module
L<Net::SFTP::Foreign::Backend::Net_SSH2>.

=head2 Error handling

The method C<$sftp-E<gt>error> can be used to check for errors
after every method call. For instance:

  $sftp = Net::SFTP::Foreign->new($host);
  $sftp->error and die "unable to connect to remote host: " . $sftp->error;

Also, the L</die_on_error> method provides a handy shortcut for the last line:

  $sftp = Net::SFTP::Foreign->new($host);
  $sftp->die_on_error("unable to connect to remote host");

The C<status> method can also be used to get the value for the last
SFTP status response, but that is only useful when calling low level
methods mapping to single SFTP primitives. In any case, it should be
considered an implementation detail of the module usable only for
troubleshooting and error reporting.

=head2 autodie mode

When the C<autodie> mode is set at construction time, non-recoverable
errors are automatically promoted to exceptions. For instance:

  $sftp = Net::SFTP::Foreign->new($host, autodie => 1);
  my $ls = $sftp->ls("/bar");
  # dies as: "Couldn't open remote dir '/bar': No such file"

=head3 Error handling in non-recursive methods

Most of the non-recursive methods available from this package return
undef on failure and a true value or the requested data on success.

For instance:

  $sftp->get($from, $to) or die "get failed!";

=head3 Error handling in recursive methods

Recursive methods (i.e. C<find>, C<rget>, C<rput>, C<rremove>) do not
stop on errors but just skip the affected files and directories and
keep going.

After a call to a recursive method, the error indicator is only set
when an unrecoverable error is found (i.e. a connection lost). For
instance, this code doesn't work as expected:

  $sftp->rremove($dir);
  $sftp->error and die "rremove failed"; # this is wrong!!!

This does:

  my $errors;
  $sftp->rremove($dir, on_error => sub { $errors++});
  $errors and die "rremove failed";

The C<autodie> mode is disabled when an C<on_error> handler is passed
to methods accepting it:

  my $sftp = Net::SFTP::Foreign->new($host, autodie => 1);
  # prints "foo!" and does not die:
  $sftp->find("/sdfjkalshfl", # nonexistent directory
              on_error => sub { print "foo!\n" });
  # dies:
  $sftp->find("/sdfjkalshfl");

=head2 API

The methods available from this module are described below.

Don't forget to read also the FAQ and BUGS sections at the end of this
document!

=over 4

=item Net::SFTP::Foreign->new($host, %args)

=item Net::SFTP::Foreign->new(%args)

Opens a new SFTP connection with a remote host C<$host>, and returns a
Net::SFTP::Foreign object representing that open connection.

An explicit check for errors should be included always after the
constructor call:

  my $sftp = Net::SFTP::Foreign->new(...);
  $sftp->die_on_error("SSH connection failed");

The optional arguments accepted are as follows:

=over 4

=item host =E<gt> $hostname

remote host name

=item user =E<gt> $username

username to log in to the remote server. This should be your SSH
login, and can be empty, in which case the username is drawn from the
user executing the process.

=item port =E<gt> $portnumber

port number where the remote SSH server is listening

=item ssh1 =E<gt> 1

use old SSH1 approach for starting the remote SFTP server.

=item more =E<gt> [@more_ssh_args]

additional args passed to C<ssh> command.

For debugging purposes you can run C<ssh> in verbose mode passing it
the C<-v> option:

  my $sftp = Net::SFTP::Foreign->new($host, more => '-v');

Note that this option expects a single command argument or a reference
to an array of arguments. For instance:

  more => '-v'         # right
  more => ['-v']       # right
  more => "-c $cipher"    # wrong!!!
  more => [-c => $cipher] # right

=item timeout =E<gt> $seconds

when this parameter is set, the connection is dropped if no data
arrives on the SSH socket for the given time while waiting for some
command to complete.

When the timeout expires, the current method is aborted and
the SFTP connection becomes invalid.

Note that the given value is used internally to time out low level
operations. The high level operations available through the API may
take longer to expire (sometimes up to 4 times longer).

The C<Windows> backend used by default when the operating system is MS
Windows (though, not under Cygwin perl), does not support timeouts. To
overcome this limitation you can switch to the C<Net_SSH2> backend or
use L<Net::SSH::Any> that provides its own backend supporting
timeouts.

=item fs_encoding =E<gt> $encoding

Version 3 of the SFTP protocol (the one supported by this module)
knows nothing about the character encoding used on the remote
filesystem to represent file and directory names.

This option allows one to select the encoding used in the remote
machine. The default value is C<utf8>.

For instance:

  $sftp = Net::SFTP::Foreign->new('user@host', fs_encoding => 'latin1');

will convert any path name passed to any method in this package to its
C<latin1> representation before sending it to the remote side.

Note that this option will not affect file contents in any way.

This feature is not supported in perl 5.6 due to incomplete Unicode
support in the interpreter.

=item key_path =E<gt> $filename

=item key_path =E<gt> \@filenames

asks C<ssh> to use the key(s) in the given file(s) for authentication.

=item password =E<gt> $password

Logs into the remote host using password authentication with the given
password.

Password authentication is only available if the module L<IO::Pty> is
installed. Note also, that on Windows this module is only available
when running the Cygwin port of Perl.

=item asks_for_username_at_login =E<gt> 0|'auto'|1

During the interactive authentication dialog, most SSH servers only
ask for the user password as the login name is passed inside the SSH
protocol. But under some uncommon servers or configurations it is
possible that a username is also requested.

When this flag is set to C<1>, the username will be send
unconditionally at the first remote prompt and then the password at
the second.

When it is set to C<auto> the module will use some heuristics in order
to determine if it is being asked for an username.

When set to C<0>, the username will never be sent during the
authentication dialog. This is the default.

=item password_prompt => $regex_or_str

The module expects the password prompt from the remote server to end
in a colon or a question mark. This seems to cover correctly 99% of
real life cases.

Otherwise this option can be used to handle the exceptional cases. For
instance:

  $sftp = Net::SFTP::Foreign->new($host, password => $password,
                                  password_prompt => qr/\bpassword>\s*$/);

Note that your script will hang at the login phase if the wrong prompt
is used.

=item passphrase =E<gt> $passphrase

Logs into the remote server using a passphrase protected private key.

Requires also the module L<IO::Pty>.

=item expect_log_user =E<gt> $bool

This feature is obsolete as Expect is not used anymore to handle
password authentication.

=item ssh_cmd =E<gt> $sshcmd

=item ssh_cmd =E<gt> \@sshcmd

name of the external SSH client. By default C<ssh> is used.

For instance:

  $sftp = Net::SFTP::Foreign->new($host, ssh_cmd => 'plink');

When an array reference is used, its elements are inserted at the
beginning of the system call. That allows one, for instance, to
connect to the target host through some SSH proxy:

  $sftp = Net::SFTP::Foreign->new($host,
              ssh_cmd => qw(ssh -l user proxy.server ssh));

But note that the module will not handle password authentication for
those proxies.

=item ssh_cmd_interface =E<gt> 'plink' or 'ssh' or 'tectia'

declares the command line interface that the SSH client used to
connect to the remote host understands. Currently C<plink>, C<ssh> and
C<tectia> are supported.

This option would be rarely required as the module infers the
interface from the SSH command name.

=item transport =E<gt> $fh

=item transport =E<gt> [$in_fh, $out_fh]

=item transport =E<gt> [$in_fh, $out_fh, $pid]

allows one to use an already open pipe or socket as the transport for
the SFTP protocol.

It can be (ab)used to make this module work with password
authentication or with keys requiring a passphrase.

C<in_fh> is the file handler used to read data from the remote server,
C<out_fh> is the file handler used to write data.

On some systems, when using a pipe as the transport, closing it, does
not cause the process at the other side to exit. The additional
C<$pid> argument can be used to instruct this module to kill that
process if it doesn't exit by itself.

=item open2_cmd =E<gt> [@cmd]

=item open2_cmd =E<gt> $cmd;

allows one to completely redefine how C<ssh> is called. Its arguments
are passed to L<IPC::Open2::open2> to open a pipe to the remote
server.

=item stderr_fh =E<gt> $fh

redirects the output sent to stderr by the SSH subprocess to the given
file handle.

It can be used to suppress banners:

  open my $ssherr, '>', '/dev/null' or die "unable to open /dev/null";
  my $sftp = Net::SFTP::Foreign->new($host,
                                     stderr_fh => $ssherr);

Or to send SSH stderr to a file in order to capture errors for later
analysis:

  my $ssherr = File::Temp->new or die "File::Temp->new failed";
  my $sftp = Net::SFTP::Foreign->new($hostname, more => ['-v'],
                                     stderr_fh => $ssherr);
  if ($sftp->error) {
    print "sftp error: ".$sftp->error."\n";
    seek($ssherr, 0, 0);
    while (<$ssherr>) {
      print "captured stderr: $_";
    }
  }

=item stderr_discard =E<gt> 1

redirects stderr to /dev/null

=item block_size =E<gt> $default_block_size

=item queue_size =E<gt> $default_queue_size

default C<block_size> and C<queue_size> used for read and write
operations (see the C<put> or C<get> documentation).

=item autoflush =E<gt> $bool

by default, and for performance reasons, write operations are cached,
and only when the write buffer becomes big enough is the data written to
the remote file. Setting this flag makes the write operations immediate.

=item write_delay =E<gt> $bytes

This option determines how many bytes are buffered before the real
SFTP write operation is performed.

=item read_ahead =E<gt> $bytes

On read operations this option determines how many bytes to read in
advance so that later read operations can be fulfilled from the
buffer.

Using a high value will increase the performance of the module for a
sequential reads access pattern but degrade it for a short random
reads access pattern. It can also cause synchronization problems if
the file is concurrently modified by other parties (L</flush> can be
used to discard all the data inside the read buffer on demand).

The default value is set dynamically considering some runtime
parameters and given options, though it tends to favor the sequential
read access pattern.

=item autodisconnect =E<gt> $ad

by default, the SSH connection is closed from the DESTROY method when
the object goes out of scope on the process and thread where it was
created. This option allows one to customize this behaviour.

The acceptable values for C<$ad> are:

=over 4

=item '0'

Never try to disconnect this object when exiting from any process.

On most operating systems, the SSH process will exit when the last
process connected to it ends, but this is not guaranteed.

You can always call the C<disconnect> method explicitly to end the
connection at the right time from the right place.

=item '1'

Disconnect on exit from any thread or process.

=item '2'

Disconnect on exit from the current process/thread only. This is the
default.

=back

See also the C<disconnect> and C<autodisconnect> methods.

=item late_set_perm =E<gt> $bool

See the FAQ below.

=item dirty_cleanup =E<gt> $bool

Sets the C<dirty_cleanup> flag in a per object basis (see the BUGS
section).

=item backend => $backend

From version 1.57 Net::SFTP::Foreign supports plugable backends in
order to allow other ways to communicate with the remote server in
addition to the default I<pipe-to-ssh-process>.

Custom backends may change the set of options supported by the C<new>
method.

=item autodie => $bool

Enables the autodie mode that will cause the module to die when any
error is found (a la L<autodie>).

=back

=item $sftp-E<gt>error

Returns the error code from the last executed command. The value
returned is similar to C<$!>, when used as a string it yields the
corresponding error string.

See L<Net::SFTP::Foreign::Constants> for a list of possible error
codes and how to import them on your scripts.

=item $sftp-E<gt>die_on_error($msg)

Convenience method:

  $sftp->die_on_error("Something bad happened");
  # is a shortcut for...
  $sftp->error and die "Something bad happened: " . $sftp->error;

=item $sftp-E<gt>status

Returns the code from the last SSH2_FXP_STATUS response. It is also a
dualvar that yields the status string when used as a string.

Usually C<$sftp-E<gt>error> should be checked first to see if there was
any error and then C<$sftp-E<gt>status> to find out its low level cause.

=item $sftp-E<gt>cwd

Returns the remote current working directory.

When a relative remote path is passed to any of the methods on this
package, this directory is used to compose the absolute path.

=item $sftp-E<gt>setcwd($dir, %opts)

Changes the remote current working directory. The remote directory
should exist, otherwise the call fails.

Returns the new remote current working directory or undef on failure.

Passing C<undef> as the C<$dir> argument resets the cwd to the server
default which is usually the user home but not always.

The method accepts the following options:

=over 4

=item check => 0

By default the given target directory is checked against the remote
server to ensure that it actually exists and that it is a
directory. Some servers may fail to honor those requests even for
valid directories (i.e. when the directory has the hidden flag set).

This option allows one to disable those checks and just sets the cwd
to the given value blindly.

=back

=item $sftp-E<gt>get($remote, $local, %options)

X<get>Copies remote file C<$remote> to local $local. By default file
attributes are also copied (permissions, atime and mtime). For
instance:

  $sftp->get('/var/log/messages', '/tmp/messages')
    or die "file transfer failed: " . $sftp->error;

A file handle can also be used as the local target. In that case, the
remote file contents are retrieved and written to the given file
handle. Note also that the handle is not closed when the transmission
finish.

  open F, '| gzip -c > /tmp/foo' or die ...;
  $sftp->get("/etc/passwd", \*F)
    or die "get failed: " . $sftp->error;
  close F or die ...;

Accepted options (not all combinations are possible):

=over 4

=item copy_time =E<gt> $bool

determines if access and modification time attributes have to be
copied from remote file. Default is to copy them.

=item copy_perm =E<gt> $bool

determines if permission attributes have to be copied from remote
file. Default is to copy them after applying the local process umask.

=item umask =E<gt> $umask

allows one to select the umask to apply when setting the permissions
of the copied file. Default is to use the umask for the current
process or C<0> if the C<perm> option is also used.

=item perm =E<gt> $perm

sets the permission mask of the file to be $perm, remote
permissions are ignored.

=item resume =E<gt> 1 | 'auto'

resumes an interrupted transfer.

If the C<auto> value is given, the transfer will be resumed only when
the local file is newer than the remote one.

C<get> transfers can not be resumed when a data conversion is in
place.

=item append =E<gt> 1

appends the contents of the remote file at the end of the local one
instead of overwriting it. If the local file does not exist a new one
is created.

=item overwrite =E<gt> 0

setting this option to zero cancels the transfer when a local file of
the same name already exists.

=item numbered =E<gt> 1

modifies the local file name inserting a sequence number when required
in order to avoid overwriting local files.

For instance:

  for (1..2) {
    $sftp->get("data.txt", "data.txt", numbered => 1);
  }

will copy the remote file as C<data.txt> the first time and as
C<data(1).txt> the second one.

If a scalar reference is passed as the numbered value, the final
target will be stored in the value pointed by the reference. For
instance:

  my $target;
  $sftp->get("data.txt", "data.txt", numbered => \$target);
  say "file was saved as $target" unless $sftp->error

=item atomic =E<gt> 1

The remote file contents are transferred into a temporal file that
once the copy completes is renamed to the target destination.

If not-overwrite of remote files is also requested, an empty file may
appear at the target destination before the rename operation is
performed. This is due to limitations of some operating/file systems.

=item mkpath =E<gt> 0

By default the method creates any non-existent parent directory for
the given target path. That feature can be disabled setting this flag
to 0.

=item cleanup =E<gt> 1

If the transfer fails, remove the incomplete file.

This option is set to by default when there is not possible to resume
the transfer afterwards (i.e., when using `atomic` or `numbered`
options).

=item best_effort =E<gt> 1

Ignore minor errors as setting time or permissions.

=item conversion =E<gt> $conversion

on the fly data conversion of the file contents can be performed with
this option. See L</On the fly data conversion> below.

=item callback =E<gt> $callback

C<$callback> is a reference to a subroutine that will be called after
every iteration of the download process.

The callback function will receive as arguments: the current
Net::SFTP::Foreign object; the data read from the remote file; the
offset from the beginning of the file in bytes; and the total size of
the file in bytes.

This mechanism can be used to provide status messages, download
progress meters, etc.:

    sub callback {
        my($sftp, $data, $offset, $size) = @_;
        print "Read $offset / $size bytes\r";
    }

The C<abort> method can be called from inside the callback to abort
the transfer:

    sub callback {
        my($sftp, $data, $offset, $size) = @_;
        if (want_to_abort_transfer()) {
            $sftp->abort("You wanted to abort the transfer");
        }
    }

The callback will be called one last time with an empty data argument
to indicate the end of the file transfer.

The size argument can change between different calls as data is
transferred (for instance, when on-the-fly data conversion is being
performed or when the size of the file can not be retrieved with the
C<stat> SFTP command before the data transfer starts).

=item block_size =E<gt> $bytes

size of the blocks the file is being split on for transfer.
Incrementing this value can improve performance but most servers limit
the maximum size.

=item queue_size =E<gt> $size

read and write requests are pipelined in order to maximize transfer
throughput. This option allows one to set the maximum number of
requests that can be concurrently waiting for a server response.

=back

=item $sftp-E<gt>get_content($remote)

Returns the content of the remote file.

=item $sftp-E<gt>get_symlink($remote, $local, %opts)

copies a symlink from the remote server to the local file system

The accepted options are C<overwrite> and C<numbered>. They have the
same effect as for the C<get> method.

=item $sftp-E<gt>put($local, $remote, %opts)

Uploads a file C<$local> from the local host to the remote host saving
it as C<$remote>. By default file attributes are also copied. For
instance:

  $sftp->put("test.txt", "test.txt")
    or die "put failed: " . $sftp->error;

A file handle can also be passed in the C<$local> argument. In that
case, data is read from there and stored in the remote file. UTF8 data
is not supported unless a custom converter callback is used to
transform it to bytes. The method will croak if it encounters any data
in perl internal UTF8 format. Note also that the handle is not closed
when the transmission finish.

Example:

  binmode STDIN;
  $sftp->put(\*STDIN, "stdin.dat") or die "put failed";
  close STDIN;

This method accepts several options:

=over 4

=item copy_time =E<gt> $bool

determines if access and modification time attributes have to be
copied from remote file. Default is to copy them.

=item copy_perm =E<gt> $bool

determines if permission attributes have to be copied from remote
file. Default is to copy them after applying the local process umask.

=item umask =E<gt> $umask

allows one to select the umask to apply when setting the permissions
of the copied file. Default is to use the umask for the current
process.

=item perm =E<gt> $perm

sets the permission mask of the file to be $perm, umask and local
permissions are ignored.

=item overwrite =E<gt> 0

by default C<put> will overwrite any pre-existent file with the same
name at the remote side. Setting this flag to zero will make the
method fail in that case.

=item numbered =E<gt> 1

when set, a sequence number is added to the remote file name in order
to avoid overwriting pre-existent files. Off by default.

=item append =E<gt> 1

appends the local file at the end of the remote file instead of
overwriting it. If the remote file does not exist a new one is
created. Off by default.

=item resume =E<gt> 1 | 'auto'

resumes an interrupted transfer.

If the C<auto> value is given, the transfer will be resumed only when
the remote file is newer than the local one.

=item sparse =E<gt> 1

Blocks that are all zeros are skipped possibly creating an sparse file
on the remote host.

=item mkpath =E<gt> 0

By default the method creates any non-existent parent directory for
the given target path. That feature can be disabled setting this flag
to 0.

=item atomic =E<gt> 1

The local file contents are transferred into a temporal file that
once the copy completes is renamed to the target destination.

This operation relies on the SSH server to perform an
overwriting/non-overwriting atomic rename operation free of race
conditions.

OpenSSH server does it correctly on top of Linux/UNIX native file
systems (i.e. ext[234]>, ffs or zfs) but has problems on file systems
not supporting hard links (i.e. FAT) or on operating systems with
broken POSIX semantics as Windows.

=item cleanup =E<gt> 1

If the transfer fails, attempts to remove the incomplete file. Cleanup
may fail (for example, if the SSH connection gets broken).

This option is set by default when the transfer is not resumable
(i.e., when using `atomic` or `numbered` options).

=item best_effort =E<gt> 1

Ignore minor errors, as setting time and permissions on the remote
file.

=item conversion =E<gt> $conversion

on the fly data conversion of the file contents can be performed with
this option. See L</On the fly data conversion> below.

=item callback =E<gt> $callback

C<$callback> is a reference to a subroutine that will be called after
every iteration of the upload process.

The callback function will receive as arguments: the current
Net::SFTP::Foreign object; the data that is going to be written to the
remote file; the offset from the beginning of the file in bytes; and
the total size of the file in bytes.

The callback will be called one last time with an empty data argument
to indicate the end of the file transfer.

The size argument can change between calls as data is transferred (for
instance, when on the fly data conversion is being performed).

This mechanism can be used to provide status messages, download
progress meters, etc.

The C<abort> method can be called from inside the callback to abort
the transfer.

=item block_size =E<gt> $bytes

size of the blocks the file is being split on for transfer.
Incrementing this value can improve performance but some servers limit
its size and if this limit is overpassed the command will fail.

=item queue_size =E<gt> $size

read and write requests are pipelined in order to maximize transfer
throughput. This option allows one to set the maximum number of
requests that can be concurrently waiting for a server response.

=item late_set_perm =E<gt> $bool

See the FAQ below.

=back

=item $sftp-E<gt>put_content($bytes, $remote, %opts)

Creates (or overwrites) a remote file whose content is the passed
data.

=item $sftp-E<gt>put_symlink($local, $remote, %opts)

Copies a local symlink to the remote host.

The accepted options are C<overwrite> and C<numbered>.

=item $sftp-E<gt>abort()

=item $sftp-E<gt>abort($msg)

This method, when called from inside a callback sub, causes the
current transfer to be aborted

The error state is set to SFTP_ERR_ABORTED and the optional $msg
argument is used as its textual value.

=item $sftp-E<gt>ls($remote, %opts)

Fetches a listing of the remote directory C<$remote>. If C<$remote> is
not given, the current remote working directory is listed.

Returns a reference to a list of entries. Every entry is a reference
to a hash with three keys: C<filename>, the name of the entry;
C<longname>, an entry in a "long" listing like C<ls -l>; and C<a>, a
L<Net::SFTP::Foreign::Attributes> object containing file atime, mtime,
permissions and size.

    my $ls = $sftp->ls('/home/foo')
        or die "unable to retrieve directory: ".$sftp->error;

    print "$_->{filename}\n" for (@$ls);



The options accepted by this method are as follows (note that usage of
some of them can degrade the method performance when reading large
directories):

=over 4

=item wanted =E<gt> qr/.../

Only elements whose name matches the given regular expression are
included on the listing.

=item wanted =E<gt> sub {...}

Only elements for which the callback returns a true value are included
on the listing. The callback is called with two arguments: the
C<$sftp> object and the current entry (a hash reference as described
before). For instance:

  use Fcntl ':mode';

  my $files = $sftp->ls ( '/home/hommer',
			  wanted => sub {
			      my $entry = $_[1];
			      S_ISREG($entry->{a}->perm)
			  } )
	or die "ls failed: ".$sftp->error;


=item no_wanted =E<gt> qr/.../

=item no_wanted =E<gt> sub {...}

those options have the opposite result to their C<wanted> counterparts:

  my $no_hidden = $sftp->ls( '/home/homer',
			     no_wanted => qr/^\./ )
	or die "ls failed";


When both C<no_wanted> and C<wanted> rules are used, the C<no_wanted>
rule is applied first and then the C<wanted> one (order is important
if the callbacks have side effects, experiment!).

=item ordered =E<gt> 1

the list of entries is ordered by filename.

=item follow_links =E<gt> 1

by default, the attributes on the listing correspond to a C<lstat>
operation, setting this option causes the method to perform C<stat>
requests instead. C<lstat> attributes will still appear for links
pointing to non existent places.

=item atomic_readdir =E<gt> 1

reading a directory is not an atomic SFTP operation and the protocol
draft does not define what happens if C<readdir> requests and write
operations (for instance C<remove> or C<open>) affecting the same
directory are intermixed.

This flag ensures that no callback call (C<wanted>, C<no_wanted>) is
performed in the middle of reading a directory and has to be set if
any of the callbacks can modify the file system.

=item realpath =E<gt> 1

for every file object, performs a realpath operation and populates the
C<realpath> entry.

=item names_only =E<gt> 1

makes the method return a simple array containing the file names from
the remote directory only. For instance, these two sentences are
equivalent:

  my @ls1 = @{ $sftp->ls('.', names_only => 1) };

  my @ls2 = map { $_->{filename} } @{$sftp->ls('.')};

=back

=item $sftp-E<gt>find($path, %opts)

=item $sftp-E<gt>find(\@paths, %opts)

X<find>Does a recursive search over the given directory C<$path> (or
directories C<@path>) and returns a list of the entries found or the
total number of them on scalar context.

Every entry is a reference to a hash with two keys: C<filename>, the
full path of the entry; and C<a>, a L<Net::SFTP::Foreign::Attributes>
object containing file atime, mtime, permissions and size.

This method tries to recover and continue under error conditions.

The options accepted:

=over 4

=item on_error =E<gt> sub { ... }

the callback is called when some error is detected, two arguments are
passed: the C<$sftp> object and the entry that was being processed
when the error happened. For instance:

  my @find = $sftp->find( '/',
			  on_error => sub {
			      my ($sftp, $e) = @_;
		 	      print STDERR "error processing $e->{filename}: "
				   . $sftp->error;
			  } );

=item realpath =E<gt> 1

calls method C<realpath> for every entry, the result is stored under
the key C<realpath>. This option slows down the process as a new
remote query is performed for every entry, specially on networks with
high latency.

=item follow_links =E<gt> 1

By default symbolic links are not resolved and appear as that on the
final listing. This option causes then to be resolved and substituted
by the target file system object. Dangling links are ignored, though
they generate a call to the C<on_error> callback when stat fails on
them.

Following symbolic links can introduce loops on the search. Infinite
loops are detected and broken but files can still appear repeated on
the final listing under different names unless the option C<realpath>
is also active.

=item ordered =E<gt> 1

By default, the file system is searched in an implementation dependent
order (actually optimized for low memory consumption). If this option
is included, the file system is searched in a deep-first, sorted by
filename fashion.

=item wanted =E<gt> qr/.../

=item wanted =E<gt> sub { ... }

=item no_wanted =E<gt> qr/.../

=item no_wanted =E<gt> sub { ... }

These options have the same effect as on the C<ls> method, allowing to
filter out unwanted entries (note that filename keys contain B<full
paths> here).

The callbacks can also be used to perform some action instead of
creating the full listing of entries in memory (that could use huge
amounts of RAM for big file trees):

  $sftp->find($src_dir,
	      wanted => sub {
		  my $fn = $_[1]->{filename}
		  print "$fn\n" if $fn =~ /\.p[ml]$/;
		  return undef # so it is discarded
	      });

=item descend =E<gt> qr/.../

=item descend =E<gt> sub { ... }

=item no_descend =E<gt> qr/.../

=item no_descend =E<gt> sub { ... }

These options, similar to the C<wanted> ones, allow one to prune the
search, discarding full subdirectories. For instance:

    use Fcntl ':mode';
    my @files = $sftp->find( '.',
			     no_descend => qr/\.svn$/,
			     wanted => sub {
				 S_ISREG($_[1]->{a}->perm)
			     } );


C<descend> and C<wanted> rules are unrelated. A directory discarded by
a C<wanted> rule will still be recursively searched unless it is also
discarded on a C<descend> rule and vice versa.

=item atomic_readdir =E<gt> 1

see C<ls> method documentation.

=item names_only =E<gt> 1

makes the method return a list with the names of the files only (see C<ls>
method documentation).

equivalent:

  my $ls1 = $sftp->ls('.', names_only => 1);

=back

=item $sftp-E<gt>glob($pattern, %opts)

X<glob>performs a remote glob and returns the list of matching entries
in the same format as the L</find> method.

This method tries to recover and continue under error conditions.

The given pattern can be a UNIX style pattern (see L<glob(7)>) or a
Regexp object (i.e C<qr/foo/>). In the later case, only files on the
current working directory will be matched against the Regexp.

Accepted options:

=over 4

=item ignore_case =E<gt> 1

by default the matching over the file system is carried out in a case
sensitive fashion, this flag changes it to be case insensitive.

This flag is ignored when a Regexp object is used as the pattern.

=item strict_leading_dot =E<gt> 0

by default, a dot character at the beginning of a file or directory
name is not matched by wildcards (C<*> or C<?>). Setting this flags to
a false value changes this behaviour.

This flag is ignored when a Regexp object is used as the pattern.

=item follow_links =E<gt> 1

=item ordered =E<gt> 1

=item names_only =E<gt> 1

=item realpath =E<gt> 1

=item on_error =E<gt> sub { ... }

=item wanted =E<gt> ...

=item no_wanted =E<gt> ...

these options perform as on the C<ls> method.

=back

Some usage samples:

  my $files = $sftp->glob("*/lib");

  my $files = $sftp->glob("/var/log/dmesg.*.gz");

  $sftp->set_cwd("/var/log");
  my $files = $sftp->glob(qr/^dmesg\.[\d+]\.gz$/);

  my $files = $sftp->glob("*/*.pdf", strict_leading_dot => 0);

=item $sftp-E<gt>rget($remote, $local, %opts)

Recursively copies the contents of remote directory C<$remote> to
local directory C<$local>. Returns the total number of elements
(files, directories and symbolic links) successfully copied.

This method tries to recover and continue when some error happens.

The options accepted are:

=over 4

=item umask =E<gt> $umask

use umask C<$umask> to set permissions on the files and directories
created.

=item copy_perm =E<gt> $bool;

if set to a true value, file and directory permissions are copied to
the remote server (after applying the umask). On by default.

=item copy_time =E<gt> $bool;

if set to a true value, file atime and mtime are copied from the
remote server. By default it is on.

=item overwrite =E<gt> $bool

if set to a true value, when a local file with the same name
already exists it is overwritten. On by default.

=item numbered =E<gt> $bool

when required, adds a sequence number to local file names in order to
avoid overwriting pre-existent remote files. Off by default.

=item newer_only =E<gt> $bool

if set to a true value, when a local file with the same name
already exists it is overwritten only if the remote file is newer.

=item ignore_links =E<gt> $bool

if set to a true value, symbolic links are not copied.

=item on_error =E<gt> sub { ... }

the passed sub is called when some error happens. It is called with two
arguments, the C<$sftp> object and the entry causing the error.

=item wanted =E<gt> ...

=item no_wanted =E<gt> ...

This option allows one to select which files and directories have to
be copied. See also C<ls> method docs.

If a directory is discarded all of its contents are also discarded (as
it is not possible to copy child files without creating the directory
first!).

=item atomic =E<gt> 1

=item block_size =E<gt> $block_size

=item queue_size =E<gt> $queue_size

=item conversion =E<gt> $conversion

=item resume =E<gt> $resume

=item best_effort =E<gt> $best_effort

See C<get> method docs.

=back

=item $sftp-E<gt>rput($local, $remote, %opts)

Recursively copies the contents of local directory C<$local> to
remote directory C<$remote>.

This method tries to recover and continue when some error happens.

Accepted options are:

=over 4

=item umask =E<gt> $umask

use umask C<$umask> to set permissions on the files and directories
created.

=item copy_perm =E<gt> $bool;

if set to a true value, file and directory permissions are copied
to the remote server (after applying the umask). On by default.

=item copy_time =E<gt> $bool;

if set to a true value, file atime and mtime are copied to the
remote server. On by default.

=item perm =E<gt> $perm

Sets the permission of the copied files to $perm. For directories the
value C<$perm|0300> is used.

Note that when this option is used, umask and local permissions are
ignored.

=item overwrite =E<gt> $bool

if set to a true value, when a remote file with the same name already
exists it is overwritten. On by default.

=item newer_only =E<gt> $bool

if set to a true value, when a remote file with the same name already
exists it is overwritten only if the local file is newer.

=item ignore_links =E<gt> $bool

if set to a true value, symbolic links are not copied

=item on_error =E<gt> sub { ... }

the passed sub is called when some error happens. It is called with two
arguments, the C<$sftp> object and the entry causing the error.

=item wanted =E<gt> ...

=item no_wanted =E<gt> ...

This option allows one to select which files and directories have to
be copied. See also C<ls> method docs.

If a directory is discarded all of its contents are also discarded (as
it is not possible to copy child files without creating the directory
first!).

=item atomic =E<gt> 1

=item block_size =E<gt> $block_size

=item queue_size =E<gt> $queue_size

=item conversion =E<gt> $conversion

=item resume =E<gt> $resume

=item best_effort =E<gt> $best_effort

=item late_set_perm =E<gt> $bool

see C<put> method docs.

=back

=item $sftp-E<gt>rremove($dir, %opts)

=item $sftp-E<gt>rremove(\@dirs, %opts)

recursively remove directory $dir (or directories @dirs) and its
contents. Returns the number of elements successfully removed.

This method tries to recover and continue when some error happens.

The options accepted are:

=over 4

=item on_error =E<gt> sub { ... }

This callback is called when some error is occurs. The arguments
passed are the C<$sftp> object and the current entry (a hash
containing the file object details, see C<ls> docs for more
information).

=item wanted =E<gt> ...

=item no_wanted =E<gt> ...

Allows one to select which file system objects have to be deleted.

=back

=item $sftp-E<gt>mget($remote, $localdir, %opts)

=item $sftp-E<gt>mget(\@remote, $localdir, %opts)

X<mget>expands the wildcards on C<$remote> or C<@remote> and retrieves
all the matching files.

For instance:

  $sftp->mget(['/etc/hostname.*', '/etc/init.d/*'], '/tmp');

The method accepts all the options valid for L</glob> and for L</get>
(except those that do not make sense :-)

C<$localdir> is optional and defaults to the process current working
directory (C<cwd>).

Files are saved with the same name they have in the remote server
excluding the directory parts.

Note that name collisions are not detected. For instance:

 $sftp->mget(["foo/file.txt", "bar/file.txt"], "/tmp")

will transfer the first file to "/tmp/file.txt" and later overwrite it
with the second one. The C<numbered> option can be used to avoid this
issue.

=item $sftp-E<gt>mput($local, $remotedir, %opts)

=item $sftp-E<gt>mput(\@local, $remotedir, %opts)

similar to L</mget> but works in the opposite direction transferring
files from the local side to the remote one.

=item $sftp-E<gt>join(@paths)

returns the given path fragments joined in one path (currently the
remote file system is expected to be UNIX like).

=item $sftp-E<gt>open($path, $flags [, $attrs ])

Sends the C<SSH_FXP_OPEN> command to open a remote file C<$path>,
and returns an open handle on success. On failure returns
C<undef>.

The returned value is a tied handle (see L<Tie::Handle>) that can be
used to access the remote file both with the methods available from
this module and with perl built-ins. For instance:

  # reading from the remote file
  my $fh1 = $sftp->open("/etc/passwd")
    or die $sftp->error;
  while (<$fh1>) { ... }

  # writing to the remote file
  use Net::SFTP::Foreign::Constants qw(:flags);
  my $fh2 = $sftp->open("/foo/bar", SSH2_FXF_WRITE|SSH2_FXF_CREAT)
    or die $sftp->error;
  print $fh2 "printing on the remote file\n";
  $sftp->write($fh2, "writing more");

The C<$flags> bitmap determines how to open the remote file as defined
in the SFTP protocol draft (the following constants can be imported
from L<Net::SFTP::Foreign::Constants>):

=over 4

=item SSH2_FXF_READ

Open the file for reading. It is the default mode.

=item SSH2_FXF_WRITE

Open the file for writing.  If both this and C<SSH2_FXF_READ> are
specified, the file is opened for both reading and writing.

=item SSH2_FXF_APPEND

Force all writes to append data at the end of the file.

As OpenSSH SFTP server implementation ignores this flag, the module
emulates it (I will appreciate receiving feedback about the
inter-operation of this module with other server implementations when
this flag is used).

=item SSH2_FXF_CREAT

If this flag is specified, then a new file will be created if one does
not already exist.

=item SSH2_FXF_TRUNC

Forces an existing file with the same name to be truncated to zero
length when creating a file. C<SSH2_FXF_CREAT> must also be specified
if this flag is used.

=item SSH2_FXF_EXCL

Causes the request to fail if the named file already exists.
C<SSH2_FXF_CREAT> must also be specified if this flag is used.

=back

When creating a new remote file, C<$attrs> allows one to set its
initial attributes. C<$attrs> has to be an object of class
L<Net::SFTP::Foreign::Attributes>.

=item $sftp-E<gt>close($handle)

Closes the remote file handle C<$handle>.

Files are automatically closed on the handle C<DESTROY> method when
not done explicitly.

Returns true on success and undef on failure.

=item $sftp-E<gt>read($handle, $length)

reads C<$length> bytes from an open file handle C<$handle>. On success
returns the data read from the remote file and undef on failure
(including EOF).

=item $sftp-E<gt>write($handle, $data)

writes C<$data> to the remote file C<$handle>. Returns the number of
bytes written or undef on failure.

=item $sftp-E<gt>readline($handle)

=item $sftp-E<gt>readline($handle, $sep)

in scalar context reads and returns the next line from the remote
file. In list context, it returns all the lines from the current
position to the end of the file.

By default "\n" is used as the separator between lines, but a
different one can be used passing it as the second method argument. If
the empty string is used, it returns all the data from the current
position to the end of the file as one line.

=item $sftp-E<gt>getc($handle)

returns the next character from the file.

=item $sftp-E<gt>seek($handle, $pos, $whence)

sets the current position for the remote file handle C<$handle>. If
C<$whence> is 0, the position is set relative to the beginning of the
file; if C<$whence> is 1, position is relative to current position and
if $<$whence> is 2, position is relative to the end of the file.

returns a trues value on success, undef on failure.

=item $sftp-E<gt>tell($fh)

returns the current position for the remote file handle C<$handle>.

=item $sftp-E<gt>eof($fh)

reports whether the remote file handler points at the end of the file.

=item $sftp-E<gt>flush($fh)

X<flush>writes to the remote file any pending data and discards the
read cache.

Note that this operation just sends data cached locally to the remote
server. You may like to call C<fsync> (when supported) afterwards to
ensure that data is actually flushed to disc.

=item $sftp-E<gt>fsync($fh)

On servers supporting the C<fsync@openssh.com> extension, this method
calls L<fysnc(2)> on the remote side, which usually flushes buffered
changes to disk.

=item $sftp-E<gt>sftpread($handle, $offset, $length)

low level method that sends a SSH2_FXP_READ request to read from an
open file handle C<$handle>, C<$length> bytes starting at C<$offset>.

Returns the data read on success and undef on failure.

Some servers (for instance OpenSSH SFTP server) limit the size of the
read requests and so the length of data returned can be smaller than
requested.

=item $sftp-E<gt>sftpwrite($handle, $offset, $data)

low level method that sends a C<SSH_FXP_WRITE> request to write to an
open file handle C<$handle>, starting at C<$offset>, and where the
data to be written is in C<$data>.

Returns true on success and undef on failure.

=item $sftp-E<gt>opendir($path)

Sends a C<SSH_FXP_OPENDIR> command to open the remote directory
C<$path>, and returns an open handle on success (unfortunately,
current versions of perl does not support directory operations via
tied handles, so it is not possible to use the returned handle as a
native one).

On failure returns C<undef>.

=item $sftp-E<gt>closedir($handle)

closes the remote directory handle C<$handle>.

Directory handles are closed from their C<DESTROY> method when not
done explicitly.

Return true on success, undef on failure.

=item $sftp-E<gt>readdir($handle)

returns the next entry from the remote directory C<$handle> (or all
the remaining entries when called in list context).

The return values are a hash with three keys: C<filename>, C<longname> and
C<a>. The C<a> value contains a L<Net::SFTP::Foreign::Attributes>
object describing the entry.

Returns undef on error or when no more entries exist on the directory.

=item $sftp-E<gt>stat($path_or_fh)

performs a C<stat> on the remote file and returns a
L<Net::SFTP::Foreign::Attributes> object with the result values. Both
paths and open remote file handles can be passed to this method.

Returns undef on failure.

=item $sftp-E<gt>fstat($handle)

this method is deprecated.

=item $sftp-E<gt>lstat($path)

this method is similar to C<stat> method but stats a symbolic link
instead of the file the symbolic links points to.

=item $sftp-E<gt>setstat($path_or_fh, $attrs)

sets file attributes on the remote file. Accepts both paths and open
remote file handles.

Returns true on success and undef on failure.

=item $sftp-E<gt>fsetstat($handle, $attrs)

this method is deprecated.

=item $sftp-E<gt>truncate($path_or_fh, $size)

=item $sftp-E<gt>chown($path_or_fh, $uid, $gid)

=item $sftp-E<gt>chmod($path_or_fh, $perm)

=item $sftp-E<gt>utime($path_or_fh, $atime, $mtime)

Shortcuts around C<setstat> method.

=item $sftp-E<gt>remove($path)

Sends a C<SSH_FXP_REMOVE> command to remove the remote file
C<$path>. Returns a true value on success and undef on failure.

=item $sftp-E<gt>mkdir($path, $attrs)

Sends a C<SSH_FXP_MKDIR> command to create a remote directory C<$path>
whose attributes are initialized to C<$attrs> (a
L<Net::SFTP::Foreign::Attributes> object).

Returns a true value on success and undef on failure.

The C<$attrs> argument is optional.

=item $sftp-E<gt>mkpath($path, $attrs, $parent)

This method is similar to C<mkdir> but also creates any non-existent
parent directories recursively.

When the optional argument C<$parent> has a true value, just the
parent directory of the given path (and its ancestors as required) is
created.

For instance:

  $sftp->mkpath("/tmp/work", undef, 1);
  my $fh = $sftp->open("/tmp/work/data.txt",
                       SSH2_FXF_WRITE|SSH2_FXF_CREAT);

=item $sftp-E<gt>rmdir($path)

Sends a C<SSH_FXP_RMDIR> command to remove a remote directory
C<$path>. Returns a true value on success and undef on failure.

=item $sftp-E<gt>realpath($path)

Sends a C<SSH_FXP_REALPATH> command to canonicalise C<$path>
to an absolute path. This can be useful for turning paths
containing C<'..'> into absolute paths.

Returns the absolute path on success, C<undef> on failure.

When the given path points to an nonexistent location, what one
gets back is server dependent. Some servers return a failure message
and others a canonical version of the path.

=item $sftp-E<gt>rename($old, $new, %opts)

Sends a C<SSH_FXP_RENAME> command to rename C<$old> to C<$new>.
Returns a true value on success and undef on failure.

Accepted options are:

=over 4

=item overwrite => $bool

By default, the rename operation fails when a file C<$new> already
exists. When this options is set, any previous existent file is
deleted first (the C<atomic_rename> operation will be used if
available).

Note than under some conditions the target file could be deleted and
afterwards the rename operation fail.

=back

=item $sftp-E<gt>atomic_rename($old, $new)

Renames a file using the C<posix-rename@openssh.com> extension when
available.

Unlike the C<rename> method, it overwrites any previous C<$new> file.

=item $sftp-E<gt>readlink($path)

Sends a C<SSH_FXP_READLINK> command to read the path where the
symbolic link is pointing.

Returns the target path on success and undef on failure.

=item $sftp-E<gt>symlink($sl, $target)

Sends a C<SSH_FXP_SYMLINK> command to create a new symbolic link
C<$sl> pointing to C<$target>.

C<$target> is stored as-is, without any path expansion taken place on
it. Use C<realpath> to normalize it:

  $sftp->symlink("foo.lnk" => $sftp->realpath("../bar"))

=item $sftp-E<gt>hardlink($hl, $target)

Creates a hardlink on the server.

This command requires support for the 'hardlink@openssh.com' extension
on the server (available in OpenSSH from version 5.7).

=item $sftp-E<gt>statvfs($path)

=item $sftp-E<gt>fstatvfs($fh)

On servers supporting C<statvfs@openssh.com> and
C<fstatvfs@openssh.com> extensions respectively, these methods return
a hash reference with information about the file system where the file
named C<$path> or the open file C<$fh> resides.

The hash entries are:

  bsize   => file system block size
  frsize  => fundamental fs block size
  blocks  => number of blocks (unit f_frsize)
  bfree   => free blocks in file system
  bavail  => free blocks for non-root
  files   => total file inodes
  ffree   => free file inodes
  favail  => free file inodes for to non-root
  fsid    => file system id
  flag    => bit mask of f_flag values
  namemax => maximum filename length

The values of the f_flag bit mask are as follows:

  SSH2_FXE_STATVFS_ST_RDONLY => read-only
  SSH2_FXE_STATVFS_ST_NOSUID => no setuid

=item $sftp->test_d($path)

Checks whether the given path corresponds to a directory.

=item $sftp->test_e($path)

Checks whether a file system object (file, directory, etc.) exists at
the given path.

=item $sftp-E<gt>disconnect

Closes the SSH connection to the remote host. From this point the
object becomes mostly useless.

Usually, this method should not be called explicitly, but implicitly
from the DESTROY method when the object goes out of scope.

See also the documentation for the C<autodiscconnect> constructor
argument.

=item $sftp-E<gt>autodisconnect($ad)

Sets the C<autodisconnect> behaviour.

See also the documentation for the C<autodiscconnect> constructor
argument. The values accepted here are the same as there.

=back


=head2 On the fly data conversion

Some of the methods on this module allow one to perform on the fly
data conversion via the C<conversion> option that accepts the
following values:

=over 4

=item conversion =E<gt> 'dos2unix'

Converts CR+LF line endings (as commonly used under MS-DOS) to LF
(UNIX).

=item conversion =E<gt> 'unix2dos'

Converts LF line endings (UNIX) to CR+LF (DOS).

=item conversion =E<gt> sub { CONVERT $_[0] }

When a callback is given, it is invoked repeatedly as chunks of data
become available. It has to change C<$_[0]> in place in order to
perform the conversion.

Also, the subroutine is called one last time with and empty data
string to indicate that the transfer has finished, so that
intermediate buffers can be flushed.

Note that when writing conversion subroutines, special care has to be
taken to handle sequences crossing chunk borders.

=back

The data conversion is always performed before any other callback
subroutine is called.

See the Wikipedia entry on line endings
L<http://en.wikipedia.org/wiki/Newline> or the article Understanding
Newlines by Xavier Noria
(L<http://www.onlamp.com/pub/a/onlamp/2006/08/17/understanding-newlines.html>)
for details about the different conventions.

=head1 FAQ

=over 4

=item Closing the connection:

B<Q>: How do I close the connection to the remote server?

B<A>: let the C<$sftp> object go out of scope or just undefine it:

  undef $sftp;

=item Using Net::SFTP::Foreign from a cron script:

B<Q>: I wrote a script for performing sftp file transfers that works
beautifully from the command line. However when I try to run the same
script from cron it fails with a broken pipe error:

  open2: exec of ssh -l user some.location.com -s sftp
    failed at Net/SFTP/Foreign.pm line 67

B<A>: C<ssh> is not on your cron PATH.

The remedy is either to add the location of the C<ssh> application to
your cron PATH or to use the C<ssh_cmd> option of the C<new> method to
hardcode the location of C<ssh> inside your script, for instance:

  my $ssh = Net::SFTP::Foreign->new($host,
                                    ssh_cmd => '/usr/local/ssh/bin/ssh');

=item C<more> constructor option expects an array reference:

B<Q>: I'm trying to pass in the private key file using the -i option,
but it keep saying it couldn't find the key. What I'm doing wrong?

B<A>: The C<more> argument on the constructor expects a single option
or a reference to an array of options. It will not split an string
containing several options.

Arguments to SSH options have to be also passed as different entries
on the array:

  my $sftp = Net::SFTP::Foreign->new($host,
                                      more => [qw(-i /home/foo/.ssh/id_dsa)]);

Note also that latest versions of Net::SFTP::Foreign support the
C<key_path> argument:

  my $sftp = Net::SFTP::Foreign->new($host,
                                      key_path => '/home/foo/.ssh/id_dsa');

=item Plink and password authentication

B<Q>: Why password authentication is not supported for the plink SSH
client?

B<A>: A bug in plink breaks it.

Newer versions of Net::SFTP::Foreign pass the password to C<plink>
using its C<-pw> option. As this feature is not completely secure a
warning is generated.

It can be silenced (though, don't do it without understanding why it
is there, please!) as follows:

  no warnings 'Net::SFTP::Foreign';
  my $sftp = Net::SFTP::Foreign->new('foo@bar',
                                     ssh_cmd => 'plink',
                                     password => $password);
  $sftp->die_on_error;

=item Plink

B<Q>: What is C<plink>?

B<A>: Plink is a command line tool distributed with the
L<PuTTY|http://the.earth.li/~sgtatham/putty/> SSH client. Very popular
between MS Windows users, it is also available for Linux and other
UNIX now.

=item Put method fails

B<Q>: put fails with the following error:

  Couldn't setstat remote file: The requested operation cannot be
  performed because there is a file transfer in progress.

B<A>: Try passing the C<late_set_perm> option to the put method:

  $sftp->put($local, $remote, late_set_perm => 1)
     or die "unable to transfer file: " . $sftp->error;

Some servers do not support the C<fsetstat> operation on open file
handles. Setting this flag allows one to delay that operation until
the file has been completely transferred and the remote file handle
closed.

Also, send me a bug report containing a dump of your $sftp object so I
can add code for your particular server software to activate the
work-around automatically.

=item Put method fails even with late_set_perm set

B<Q>: I added C<late_set_perm =E<gt> 1> to the put call, but we are still
receiving the error C<Couldn't setstat remote file (setstat)>.

B<A>: Some servers forbid the SFTP C<setstat> operation used by the
C<put> method for replicating the file permissions and time-stamps on
the remote side.

As a work around you can just disable the feature:

  $sftp->put($local_file, $remote_file,
             copy_perm => 0, copy_time => 0);

=item Disable password authentication completely

B<Q>: When we try to open a session and the key either doesn't exist
or is invalid, the child SSH hangs waiting for a password to be
entered.  Is there a way to make this fail back to the Perl program to
be handled?

B<A>: Disable anything but public key SSH authentication calling the
new method as follows:

  $sftp = Net::SFTP::Foreign->new($host,
                more => [qw(-o PreferredAuthentications=publickey)])

See L<ssh_config(5)> for the details.

=item Understanding C<$attr-E<gt>perm> bits

B<Q>: How can I know if a directory entry is a (directory|link|file|...)?

B<A>: Use the C<S_IS*> functions from L<Fcntl>. For instance:

  use Fcntl qw(S_ISDIR);
  my $ls = $sftp->ls or die $sftp->error;
  for my $entry (@$ls) {
    if (S_ISDIR($entry->{a}->perm)) {
      print "$entry->{filename} is a directory\n";
    }
  }

=item Host key checking

B<Q>: Connecting to a remote server with password authentication fails
with the following error:

  The authenticity of the target host can not be established,
  connect from the command line first

B<A>: That probably means that the public key from the remote server
is not stored in the C<~/.ssh/known_hosts> file. Run an SSH Connection
from the command line as the same user as the script and answer C<yes>
when asked to confirm the key supplied.

Example:

  $ ssh pluto /bin/true
  The authenticity of host 'pluto (172.25.1.4)' can't be established.
  RSA key fingerprint is 41:b1:a7:86:d2:a9:7b:b0:7f:a1:00:b7:26:51:76:52.
  Are you sure you want to continue connecting (yes/no)? yes

Your SSH client may also support some flag to disable this check, but
doing it can ruin the security of the SSH protocol so I advise against
its usage.

Example:

  # Warning: don't do that unless you fully understand
  # its security implications!!!
  $sftp = Net::SFTP::Foreign->new($host,
                                  more => [-o => 'StrictHostKeyChecking no'],
                                  ...);

=back

=head1 BUGS

These are the currently known bugs:

=over 4

=item - Doesn't work on VMS:

The problem is related to L<IPC::Open3> not working on VMS. Patches
are welcome!

=item - Dirty cleanup:

On some operating systems, closing the pipes used to communicate with
the slave SSH process does not terminate it and a work around has to
be applied. If you find that your scripts hung when the $sftp object
gets out of scope, try setting C<$Net::SFTP::Foreign::dirty_cleanup>
to a true value and also send me a report including the value of
C<$^O> on your machine and the OpenSSH version.

From version 0.90_18 upwards, a dirty cleanup is performed anyway when
the SSH process does not terminate by itself in 8 seconds or less.

=item - Reversed symlink arguments:

This package uses the non-conforming OpenSSH argument order for the
SSH_FXP_SYMLINK command that seems to be the de facto standard. When
interacting with SFTP servers that follow the SFTP specification, the
C<symlink> method will interpret its arguments in reverse order.

=item - IPC::Open3 bugs on Windows

On Windows the IPC::Open3 module is used to spawn the slave SSH
process. That module has several nasty bugs (related to STDIN, STDOUT
and STDERR being closed or not being assigned to file descriptors 0, 1
and 2 respectively) that will cause the connection to fail.

Specifically this is known to happen under mod_perl/mod_perl2.

=item - Password authentication on HP-UX

For some unknown reason, it seems that when using the module on HP-UX,
number signs (C<#>) in password need to be escaped (C<\#>). For
instance:

  my $password = "foo#2014";
  $password =~ s/#/\\#/g if $running_in_hp_ux;
  my $ssh = Net::OpenSSH->new($host, user => $user,
                              password => $password);

I don't have access to an HP-UX machine, and so far nobody using it
has been able to explain this behaviour. Patches welcome!

=item - Taint mode and data coming through SFTP

When the module finds it is being used from a script started in taint
mode, on every method call it checks all the arguments passed and dies
if any of them is tainted. Also, any data coming through the SFTP
connection is marked as tainted.

That generates an internal conflict for those methods that under the
hood query the remote server multiple times, using data from responses
to previous queries (tainted) to build new ones (die!).

I don't think a generic solution could be applied to this issue while
honoring the taint-mode spirit (and erring on the safe side), so my
plan is to fix that in a case by case manner.

So, please report any issue you find with taint mode!

=back

Also, the following features should be considered experimental:

- support for Tectia server

- numbered feature

- autodie mode

- best_effort feature

=head1 SUPPORT

To report bugs, send me and email or use the CPAN bug tracking system
at L<http://rt.cpan.org>.

=head2 Commercial support

Commercial support, professional services and custom software
development around this module are available through my current
company. Drop me an email with a rough description of your
requirements and we will get back to you ASAP.

=head2 My wishlist

If you like this module and you're feeling generous, take a look at my
Amazon Wish List: L<http://amzn.com/w/1WU1P6IR5QZ42>

Also consider contributing to the OpenSSH project this module builds
upon: L<http://www.openssh.org/donations.html>.

=head1 SEE ALSO

Information about the constants used on this module is available from
L<Net::SFTP::Foreign::Constants>. Information about attribute objects
is available from L<Net::SFTP::Foreign::Attributes>.

General information about SSH and the OpenSSH implementation is
available from the OpenSSH web site at L<http://www.openssh.org/> and
from the L<sftp(1)> and L<sftp-server(8)> manual pages.

Net::SFTP::Foreign integrates nicely with my other module
L<Net::OpenSSH>.

L<Net::SFTP::Foreign::Backend::Net_SSH2> allows one to run
Net::SFTP::Foreign on top of L<Net::SSH2> (nowadays, this combination
is probably the best option under Windows).

Modules offering similar functionality available from CPAN are
L<Net::SFTP> and L<Net::SSH2>.

L<Test::SFTP> allows one to run tests against a remote SFTP server.

L<autodie>.

=head1 COPYRIGHT

Copyright (c) 2005-2017 Salvador FandiE<ntilde>o (sfandino@yahoo.com).

Copyright (c) 2001 Benjamin Trott, Copyright (c) 2003 David Rolsky.

_glob_to_regex method based on code (c) 2002 Richard Clamp.

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
