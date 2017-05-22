package Net::SFTP::Foreign::Constants;

our $VERSION = '1.63_05';

use strict;
use warnings;

use Carp;

require Exporter;
our @ISA = qw(Exporter);
our (@EXPORT_OK, %EXPORT_TAGS);

BEGIN {
    my %constants = ( SSH2_FXP_INIT => 1,
		      SSH2_FXP_VERSION => 2,
		      SSH2_FXP_OPEN => 3,
		      SSH2_FXP_CLOSE => 4,
		      SSH2_FXP_READ => 5,
		      SSH2_FXP_WRITE => 6,
		      SSH2_FXP_LSTAT => 7,
		      SSH2_FXP_FSTAT => 8,
		      SSH2_FXP_SETSTAT => 9,
		      SSH2_FXP_FSETSTAT => 10,
		      SSH2_FXP_OPENDIR => 11,
		      SSH2_FXP_READDIR => 12,
		      SSH2_FXP_REMOVE => 13,
		      SSH2_FXP_MKDIR => 14,
		      SSH2_FXP_RMDIR => 15,
		      SSH2_FXP_REALPATH => 16,
		      SSH2_FXP_STAT => 17,
		      SSH2_FXP_RENAME => 18,
		      SSH2_FXP_READLINK => 19,
		      SSH2_FXP_SYMLINK => 20,
		      SSH2_FXP_STATUS => 101,
		      SSH2_FXP_HANDLE => 102,
		      SSH2_FXP_DATA => 103,
		      SSH2_FXP_NAME => 104,
		      SSH2_FXP_ATTRS => 105,
                      SSH2_FXP_EXTENDED => 200,
                      SSH2_FXP_EXTENDED_REPLY => 201,

		      SSH2_FXF_READ => 0x01,
		      SSH2_FXF_WRITE => 0x02,
		      SSH2_FXF_APPEND => 0x04,
		      SSH2_FXF_CREAT => 0x08,
		      SSH2_FXF_TRUNC => 0x10,
		      SSH2_FXF_EXCL => 0x20,

		      SSH2_FX_OK => 0,
		      SSH2_FX_EOF => 1,
		      SSH2_FX_NO_SUCH_FILE => 2,
		      SSH2_FX_PERMISSION_DENIED => 3,
		      SSH2_FX_FAILURE => 4,
		      SSH2_FX_BAD_MESSAGE => 5,
		      SSH2_FX_NO_CONNECTION => 6,
		      SSH2_FX_CONNECTION_LOST => 7,
		      SSH2_FX_OP_UNSUPPORTED => 8,

		      SSH2_FILEXFER_ATTR_SIZE => 0x01,
		      SSH2_FILEXFER_ATTR_UIDGID => 0x02,
		      SSH2_FILEXFER_ATTR_PERMISSIONS => 0x04,
		      SSH2_FILEXFER_ATTR_ACMODTIME => 0x08,
		      SSH2_FILEXFER_ATTR_EXTENDED => 0x80000000,

		      SSH2_FILEXFER_VERSION => 3,

                      SSH2_FXE_STATVFS_ST_READONLY => 0x1,
                      SSH2_FXE_STATVFS_ST_NOSUID => 0x2,

		      SFTP_ERR_REMOTE_STAT_FAILED => 1,
		      SFTP_ERR_REMOTE_OPEN_FAILED => 2,
		      SFTP_ERR_LOCAL_ALREADY_EXISTS => 3,
		      # SFTP_ERR_LOCAL_OPEN_FAILED => 4,
		      SFTP_ERR_LOCAL_OPEN_FAILED => 26,
		      SFTP_ERR_REMOTE_READ_FAILED => 5,
		      SFTP_ERR_REMOTE_BLOCK_TOO_SMALL => 6,
		      SFTP_ERR_LOCAL_WRITE_FAILED => 7,
		      SFTP_ERR_REMOTE_BAD_PERMISSIONS => 8,
		      SFTP_ERR_LOCAL_CHMOD_FAILED => 9,
		      SFTP_ERR_REMOTE_BAD_TIME => 10,
		      SFTP_ERR_LOCAL_UTIME_FAILED => 11,
		      SFTP_ERR_REMOTE_BAD_MESSAGE => 13,
		      SFTP_ERR_REMOTE_REALPATH_FAILED => 14,
		      SFTP_ERR_REMOTE_OPENDIR_FAILED => 15,
		      SFTP_ERR_REMOTE_WRITE_FAILED => 16,
		      SFTP_ERR_REMOTE_RENAME_FAILED => 17,
		      SFTP_ERR_REMOTE_LSTAT_FAILED => 18,
		      SFTP_ERR_REMOTE_FSTAT_FAILED => 19,
		      SFTP_ERR_REMOTE_CLOSE_FAILED => 20,
		      SFTP_ERR_REMOTE_REMOVE_FAILED => 21,
		      SFTP_ERR_REMOTE_MKDIR_FAILED => 22,
		      SFTP_ERR_REMOTE_RMDIR_FAILED => 23,
		      SFTP_ERR_REMOTE_SETSTAT_FAILED => 24,
		      SFTP_ERR_REMOTE_FSETSTAT_FAILED => 25,
		      SFTP_ERR_LOCAL_STAT_FAILED => 27,
		      SFTP_ERR_LOCAL_READ_ERROR => 28,
		      SFTP_ERR_REMOTE_READDIR_FAILED => 29,
		      SFTP_ERR_REMOTE_READLINK_FAILED => 30,
		      SFTP_ERR_REMOTE_SYMLINK_FAILED => 31,
		      SFTP_ERR_REMOTE_BAD_PATH => 32,
		      SFTP_ERR_LOCAL_MKDIR_FAILED => 33,
		      SFTP_ERR_LOCAL_SYMLINK_FAILED => 34,
		      SFTP_ERR_REMOTE_BAD_OBJECT => 35,
		      SFTP_ERR_REMOTE_ACCESING_CLOSED_FILE => 36,
		      SFTP_ERR_CONNECTION_BROKEN => 37,
		      SFTP_ERR_LOCAL_GENERIC_ERROR => 38,
		      SFTP_ERR_LOCAL_READLINK_FAILED => 39,
		      SFTP_ERR_LOCAL_BAD_PATH => 40,
		      SFTP_ERR_LOCAL_BAD_OBJECT => 41,
		      SFTP_ERR_REMOTE_ALREADY_EXISTS => 42,
                      # SFTP_ERR_BAD_SSH_BINARY => 43,
                      SFTP_ERR_ABORTED => 44,
                      SFTP_ERR_REMOTE_BIGGER_THAN_LOCAL => 45,
                      SFTP_ERR_LOCAL_BIGGER_THAN_REMOTE => 46,
                      SFTP_ERR_LOCAL_SEEK_FAILED => 47,
                      SFTP_ERR_REMOTE_STATVFS_FAILED => 48,
                      SFTP_ERR_REMOTE_FSTATVFS_FAILED => 49,
		      SFTP_ERR_PASSWORD_AUTHENTICATION_FAILED => 50,
                      SFTP_ERR_REMOTE_HARDLINK_FAILED => 51,
		      SFTP_ERR_LOCAL_RENAME_FAILED => 52,
                      SFTP_ERR_REMOTE_FSYNC_FAILED => 53,
                    );

    for my $key (keys %constants) {
	no strict 'refs';
	my $value = $constants{$key};
        *{$key} = sub () { $value }
    }

    @EXPORT_OK = keys %constants;

    my %etagre = qw( fxp SSH2_FXP_
		     flags SSH2_FXF_
		     att SSH2_FILEXFER_ATTR
		     status SSH2_FX_
		     error SFTP_ERR_
                     ext SSH2_FXE_);

    for my $key (keys %etagre) {
	my $re = qr/^$etagre{$key}/;
	$EXPORT_TAGS{$key} = [grep $_=~$re, @EXPORT_OK];
    }
}

1;
__END__

=head1 NAME

Net::SFTP::Foreign::Constants - Constant definitions for
Net::SFTP::Foreign

=head1 SYNOPSIS

    use Net::SFTP::Foreign::Constants qw(:tag SSH2_FILEXFER_VERSION);
    print "Protocol version is ", SSH2_FILEXFER_VERSION;

=head1 DESCRIPTION

Net::SFTP::Foreign::Constants provides a list of exportable SFTP
constants: for SFTP messages and commands, for file-open flags,
for status messages, etc. Constants can be exported individually,
or in sets identified by tag names.

Net::SFTP::Foreign::Constants provides values for all of the constants
listed in the SFTP protocol version 3 draft; the only thing to note is
that the constants are listed with the prefix C<SSH2_> instead of
C<SSH_>. So, for example, to import the constant for the file-open
command, you would write:

    use Net::SFTP::Foreign::Constants qw( SSH2_FXP_OPEN );

=head1 TAGS

As mentioned above, constants can either be imported individually
or in sets grouped by tag names. The tag names are:

=over 4

=item :fxp

Imports all of the C<SSH2_FXP_*> constants: these are the
constants used in the messaging protocol.

=item :flags

Imports all of the C<SSH2_FXF_*> constants: these are constants
used as flags sent to the server when opening files.

=item :att

Imports all of the C<SSH2_FILEXFER_ATTR_*> constants: these are
the constants used to construct the flag in the serialized
attributes. The flag describes what types of file attributes
are listed in the buffer.

=item :status

Imports all of the C<SSH2_FX_*> constants: these are constants
returned from a server C<SSH2_FXP_STATUS> message and indicate
the status of a particular operation.

=item :error

Imports all the C<SFTP_ERR_*> constants used to represent high level
errors: C<SFTP_ERR_LOCAL_ALREADY_EXISTS>,
C<SFTP_ERR_LOCAL_CHMOD_FAILED>, C<SFTP_ERR_LOCAL_OPEN_FAILED>,
C<SFTP_ERR_LOCAL_READ_ERROR>, C<SFTP_ERR_LOCAL_STAT_FAILED>,
C<SFTP_ERR_LOCAL_UTIME_FAILED>, C<SFTP_ERR_LOCAL_WRITE_FAILED>,
C<SFTP_ERR_REMOTE_BAD_PACKET_SEQUENCE>,
C<SFTP_ERR_REMOTE_BAD_PERMISSIONS>, C<SFTP_ERR_REMOTE_BAD_TIME>,
C<SFTP_ERR_REMOTE_BLOCK_TOO_SMALL>, C<SFTP_ERR_REMOTE_CLOSE_FAILED>,
C<SFTP_ERR_REMOTE_FSETSTAT_FAILED>, C<SFTP_ERR_REMOTE_FSTAT_FAILED>,
C<SFTP_ERR_REMOTE_LSTAT_FAILED>, C<SFTP_ERR_REMOTE_MKDIR_FAILED>,
C<SFTP_ERR_REMOTE_OPENDIR_FAILED>, C<SFTP_ERR_REMOTE_OPEN_FAILED>,
C<SFTP_ERR_REMOTE_READDIR_FAILED>, C<SFTP_ERR_REMOTE_READ_FAILED>,
C<SFTP_ERR_REMOTE_REALPATH_FAILED>, C<SFTP_ERR_REMOTE_REMOVE_FAILED>,
C<SFTP_ERR_REMOTE_RENAME_FAILED>, C<SFTP_ERR_REMOTE_RMDIR_FAILED>,
C<SFTP_ERR_REMOTE_READLINK_FAILED>, C<SFTP_ERR_REMOTE_SYMLINK_FAILED>,
C<SFTP_ERR_REMOTE_SETSTAT_FAILED>, C<SFTP_ERR_REMOTE_STAT_FAILED>,
C<SFTP_ERR_REMOTE_WRITE_FAILED> and
C<SFTP_ERR_REMOTE_HARDLINK_FAILED>.

Note: these constants are not defined on the SFTP draft.

=item :ext

Import all the C<SSH2_FXE_*> constants: there are the constants
defined for usage with SFTP extensions.

Currently, these are supported: C<SSH2_FXE_STATVFS_ST_RDONLY>,
C<SSH_FXE_STATVFS_ST_NOSUID>.

=back

There is one constant that does not fit into any of the
tag sets: C<SSH2_FILEXFER_VERSION>, which holds the value
of the SFTP protocol implemented by L<Net::SFTP::Foreign>.

=head1 AUTHOR & COPYRIGHTS

Please see the L<Net::SFTP::Foreign> manpage for author, copyright,
and license information.

=cut
