package Net::SSH::Expect;
use 5.008000;
use warnings;
use strict;
use fields qw(
	host user password port no_terminal escape_char ssh_option
	raw_pty exp_internal exp_debug log_file log_stdout restart_timeout_upon_receive
	timeout terminator expect debug next_line before match after binary
);
use Expect;
use Carp;
use POSIX qw(:signal_h WNOHANG);

our $VERSION = '1.09';

# error contants
use constant ILLEGAL_STATE => "IllegalState";
use constant ILLEGAL_STATE_NO_SSH_CONNECTION => "IllegalState: you don't have a valid SSH connection to the server";
use constant ILLEGAL_ARGUMENT => "IllegalArgument";
use constant SSH_AUTHENTICATION_ERROR => "SSHAuthenticationError";
use constant SSH_PROCESS_ERROR => "SSHProcessError";
use constant SSH_CONNECTION_ERROR => "SSHConnectionError";
use constant SSH_CONNECTION_ABORTED => "SSHConnectionAborted";

sub new {
    my $type = shift;
	my %args = @_;
    my Net::SSH::Expect $self = fields::new(ref $type || $type);
	
	# Options used to configure the SSH command
    $self->{host} 			= $args{host}|| undef; 
    $self->{user}  			= $args{user} || $ENV{'USER'}; 
    $self->{password} 		= $args{password} || undef;
	$self->{port}			= $args{port} || undef;			# ssh -p
	$self->{no_terminal}	= $args{no_terminal} || 0; 		# ssh -T
	$self->{escape_char}	= $args{escape_char} || undef; 	# ssh -e
	$self->{ssh_option}		= $args{ssh_option} || undef;	# arbitrary ssh options
	$self->{binary}			= $args{binary} || "ssh"; 		# path to SSH binary.
	
	# Options used to configure the Expect object
	$self->{raw_pty}		= $args{raw_pty} || 0;
	$self->{exp_internal}	= $args{exp_internal} || 0;
	$self->{exp_debug}		= $args{exp_debug} || 0;
	$self->{log_file} 		= $args{log_file} || undef;
	$self->{log_stdout}		= $args{log_stdout} || 0;
	$self->{restart_timeout_upon_receive} = $args{restart_timeout_upon_receive} || 0;

	# Attributes for this module 
	$self->timeout(defined $args{timeout} ? $args{timeout} : 1);
	$self->{terminator} 	= $args{terminator} || "\n";
	$self->{next_line}		= "";
	$self->{expect}			= undef;	# this will hold the Expect instance
	$self->{debug}			= $args{debug} || 0;
	$self->{before}			= "";
	$self->{match}			= "";
	$self->{after}			= "";

	# validating the user input
	foreach my $key (keys %args) {
		if (! exists $self->{$key} ) {
			croak ILLEGAL_ARGUMENT . " attribute '$key' is not a valid constructor argument.";
		}
	}

	return $self;
}

# boolean run_ssh() - forks the ssh client process opening an ssh connection to the SSH server.
#
#	This method has three roles:
#	1) 	Instantiate a new Expect object configuring it with all the defaults and user-defined
#		settings.
#	2)	Define the ssh command line using the defaults and user-defined settings
#	3)	Fork the ssh process using the spawn() method of the Expect instance we created. 
#		The SSH connection is established on this step using the user account set in the 'user'
#		constructor attribute. No password is sent here, that happens only in the login() method.
#
#	This method is run internally by the login() method so you don't need to run it yourself
#	in most of the cases. You'll run this method alone if you had set up public-key authentication 
#	between the ssh client and the ssh server. In this case you only need to call this method
#	to have an authenticated ssh connection, you won't call login(). Note that when you 
#	use public-key authentication you won't need to set the 'password' constructor attribute
#	but you still need to define the 'user' attribute.
#	If you don't know how to setup public-key authentication there's a good guide at
#	http://sial.org/howto/openssh/publickey-auth/
#		
# returns:
#	boolean: 1 if the ssh ran OK or 0 otherwise. In case of failures, use $! to do get info.
sub run_ssh {
	my Net::SSH::Expect $self = shift;

	my $user = $self->{user};
	my $host = $self->{host};

	croak(ILLEGAL_STATE . " field 'host' is not set.") unless $host;
	croak(ILLEGAL_STATE . " field 'user' is not set.") unless $user;

	my $log_file = $self->{log_file};
	my $log_stdout = $self->{log_stdout};
	my $exp_internal = $self->{exp_internal};
	my $exp_debug = $self->{exp_debug};
	my $no_terminal = $self->{no_terminal};
	my $raw_pty = $self->{raw_pty};
		my $escape_char = $self->{escape_char};
	my $ssh_option = $self->{ssh_option};
	my $port = $self->{port};
	my $rtup = $self->{restart_timeout_upon_receive};

	# Gather flags.
	my $flags = "";
	$flags .= $escape_char ? "-e '$escape_char' " : "-e none ";
	$flags .= "-p $port " if $port;
	$flags .= "-T " if $no_terminal;
	$flags .= $ssh_option if $ssh_option;
	
	# this sets the ssh command line
	my $ssh_string = $self->{binary} . " $flags $user\@$host";
	
	# creating the Expect object
	my $exp = new Expect();
	
	# saving this instance
	$self->{expect} = $exp; 
	
	# configuring the expect object
	$exp->log_stdout($log_stdout);
	$exp->log_file($log_file, "w") if $log_file;
	$exp->exp_internal($exp_internal);
	$exp->debug($exp_debug);
	$exp->raw_pty($raw_pty);	
	$exp->restart_timeout_upon_receive($rtup);
	my $success = $exp->spawn($ssh_string); 
	
	return (defined $success);
}

# string login ([$login_prompt, $password_prompt] [,$test_success]) - authenticates on the ssh server. 
#	This method responds to the authentication prompt sent by the SSH server. 
#	You can customize the "Login:" and "Password:" prompts that must be expected by passing their
#	patterns as arguments to this method, although this method has default values that work to most
#	SSH servers out there.
#	It runs the run_ssh() method only if it wasn't run before(), but it'll die
#	if run_ssh() returns false.
#
# param:
#	$login_prompt: A pattern string used to match the "Login:" prompt. The default 
#		pattern is qr/ogin:\s*$/
#
#	$password_prompt: A pattern string used to match the "Password:" prompt. The default
#		pattern is qr/[Pp]assword.*?:|[Pp]assphrase.*?:/
#
#	$test_success: 0 | 1. if 1, login will do an extra-test to verify if the password
# 		entered was accepted. The test consists in verifying if, after sending the password,
#		the "Password" prompt shows up again what would indicate that the password was rejected.
#		This test is disabled by default.
#
#	OBS: the number of paramaters passed to this method will tell it what parameters are being passed:
#	0 parameters: login() : All the default values will be used.
#	1 parameter:  login(1) : The $test_success parameter is set.
#	2 parameters: login("Login:", "Password:") : the $login_prompt and $password_prompt parameters are set.
#	3 parameters: login("Login:", "Password;", 1) : the three parameters received values in this order.
#
# returns:
#	string: whatever the SSH server wrote in my input stream after loging in. This usually is some
#		welcome message and/or the remote prompt. You could use this string to do your verification
#		that the login was successful. The content returned is removed from the input stream.
# dies:
#	IllegalState: if any of 'host' or 'user' or 'password' fields are unset.
#	SSHProccessError: if run_ssh() failed to spawn the ssh process
# 	SSHConnectionError: if the connection failed for some reason, like invalid 'host' address or network problems.
sub login {
    my Net::SSH::Expect $self = shift;

	# setting the default values for the parameters
	my ($login_prompt, $password_prompt, $test_success) = ( qr/ogin:\s*$/, qr/[Pp]assword.*?:|[Pp]assphrase.*?:/, 0);
	
	# attributing the user defined values
	if (@_ == 2 || @_ == 3) {
		$login_prompt = shift;
		$password_prompt = shift;
	}
	if (@_ == 1) {
		$test_success = shift;
	}

	my $user = $self->{user};
	my $password = $self->{password};
	my $timeout = $self->{timeout};
	my $t = $self->{terminator};

	croak(ILLEGAL_STATE . " field 'user' is not set.") unless $user;
	croak(ILLEGAL_STATE . " field 'password' is not set.") unless $password;

	# spawns the ssh process if this wasn't done yet
	if (! defined($self->{expect})) {
		$self->run_ssh() or croak SSH_PROCESS_ERROR . " Couldn't start ssh: $!\n";
	}

	my $exp = $self->get_expect();

	# loggin in
	$self->_sec_expect($timeout,
		[ qr/\(yes\/no\)\?\s*$/ => sub { $exp->send("yes$t"); exp_continue; } ],
		[ $password_prompt		=> sub { $exp->send("$password$t"); } ],
		[ $login_prompt         => sub { $exp->send("$user$t"); exp_continue; } ],
		[ qr/REMOTE HOST IDEN/  => sub { print "FIX: .ssh/known_hosts\n"; exp_continue; } ],
		[ timeout				=> sub 
			{ 
				croak SSH_AUTHENTICATION_ERROR . " Login timed out. " .
				"The input stream currently has the contents bellow: " .
				$self->peek();
			} 
		]
	);
	
	# verifying if we failed to logon
	if ($test_success) {
		$self->_sec_expect($timeout, 
			[ $password_prompt  => 			
				sub { 
					my $error = $self->peek();
					croak(SSH_AUTHENTICATION_ERROR . " Error: Bad password [$error]");
				}
			]
		);
	}

   	# swallows any output the server wrote to my input stream after loging in	
	return $self->read_all();
}



# boolean waitfor ($string [, $timeout, $match_type])
# This method reads until a pattern or string is found in the input stream.
# All the characters before and including the match are removed from the input stream.
# 
# After waitfor returns, use the methods before(), match() and after() to get the data
# 'before the match', 'what matched', and 'after the match' respectively.
#
# If waitfor returns false, whatever content is on input stream can be accessed with 
# before(). In this case before() will return the same content as peek(). 
#
# params:
#	$string: a string to be matched. It can be a regular expression or a literal string
#			 anb its interpretation as one or other depends on $match_type. Default is
#			 're', what treats $string as a regular expression.
#
#	$timeout: the timeout in seconds while waiting for $string
#
#	$match_type: match_type affects how $string will be matched:
#		'-re': means $string is a regular expression.
#		'-ex': means $string is an "exact match", i.e., will be matched literally.
#
# returns: 
#	boolean: 1 is returned if string was found, 0 otherwise. When the match fails
#			 waitfor() will only return after waiting $timeout seconds.
#
# dies:
#	SSH_CONNECTION_ABORTED if EOF is found (error type 2)
#	SSH_PROCESS_ERROR if the ssh process has died (error type 3)
#	SSH_CONNECTION_ERROR if unknown error (type 4) is found
sub waitfor {
	my Net::SSH::Expect $self = shift;
	my $pattern = shift;
	my $timeout = @_ ? shift : $self->{timeout};
	my $match_type = @_ ? shift : '-re';
	croak ( ILLEGAL_ARGUMENT . "match_type '$match_type' is invalid." )
		unless ($match_type eq '-re' || $match_type eq '-ex');

	my ($pos, $error);
	($pos, $error, $self->{match}, $self->{before}, $self->{after}) 
		= $self->_sec_expect($timeout, $match_type, $pattern);

	my $debug = $self->{debug};

	# sanity verification
	# Enforcing that match before and after have correct values
	if (! defined $pos) { # if the pattern failed to match
		# match should be undef
		if (defined $self->{match}) {
			if ($debug) {
				carp ("The last expect() didn't match but \$exp->match() returned content '". $self->{match} ."'." .
						" We'll set \$self->{match} to undef explicitly;");
			}
			$self->{match} = undef;
		}
		# after should be undef
		if (defined $self->{after}) {
			if ($debug) {
				carp ("The last expect() didn't match but \$exp->after() returned content '". $self->{after} ."'." .
						" We'll set \$self->{after} to undef explicitly;");
			}
			$self->{after} = undef;
		}
	} 
	
	return (defined $pos);
}

# string before() - returns the "before match" data of the last waitfor() call, or empty string.
# if the last waitfor() didn't match, before() will return all the current content on the input
# stream, just as if you had called peek() with the same timeout.
sub before {
	my Net::SSH::Expect $self = shift;
	return $self->{before};
}

# string match() - returns the "match" data of the last waitfor() call, or undef if didn't match.
sub match {
	my Net::SSH::Expect $self = shift;
	return $self->{match};
}

# string after() - returns the "after match" data of the last waitfor() call, or undef if didn't match.
sub after {
	my Net::SSH::Expect $self = shift;
	return $self->{after};
}


# send ("string") - breaks on through to the other side.
sub send {
	my Net::SSH::Expect $self = shift;
	my $send = shift;
	croak (ILLEGAL_ARGUMENT . " missing argument 'string'.") unless ($send);
	my $exp = $self->get_expect();
	my $t = $self->{terminator};
	$exp->send($send . $t);
}

# peek([$timeout]) - returns what is in the input stream without removing anything
#	params:
#		$timeout: how many seconds peek() will wait for input
# dies:
#	SSH_CONNECTION_ABORTED if EOF is found (error type 2)
#	SSH_PROCESS_ERROR if the ssh process has died (error type 3)
#	SSH_CONNECTION_ERROR if unknown error (type 4) is found
sub peek {
	my Net::SSH::Expect $self = shift;
	my $timeout = @_ ? shift : $self->{timeout};
	my $exp = $self->get_expect();
	$self->_sec_expect($timeout);
	return $exp->before();
}

# string eat($string)- removes all the head of the input stream until $string inclusive.
#	eat() will only be able	to remove the $string if it's currently present on the 
#	input stream because eat() will wait 0 seconds before removing it.
#
#	Use it associated with peek to eat everything that appears on the input stream:
#
#	while ($chunk = $exp->eat($exp->peak())) {
#		print $chunk;
#	}
#	
#	Or use the read_all() method that does the above loop for you returning the accumulated
#	result.
#
# param:
#	string: a string currently available on the input stream. 
#		If $string doesn't start in the head, all the content before $string will also
#		be removed. 
#
#		If $string is undef or empty string it will be returned immediately as it.
#	
# returns:
#	string: the removed content or empty string if there is nothing in the input stream.
# 
# dies:
#	SSH_CONNECTION_ABORTED if EOF is found (error type 2)
#	SSH_PROCESS_ERROR if the ssh process has died (error type 3)
#	SSH_CONNECTION_ERROR if unknown error (type 4) is found
#
# debbuging features:
#	The following warnings are printed to STDERR if $exp->debug() == 1:
#		eat() prints a warning is $string wasn't found in the head of the input stream.
#		eat() prints a warning is $string was empty or undefined.
#
sub eat {
	my Net::SSH::Expect $self = shift;
	my $string = shift;
	unless (defined $string && $string ne "") {
		if ($self->{debug}) {
			carp ("eat(): param \$string is undef or empty string\n");
		}
		return $string;
	}

	my $exp = $self->get_expect();

	# the top of the input stream that will be removed from there and
	# returned to the user
	my $top;

	# eat $string from (hopefully) the head of the input stream
	$self->_sec_expect(0, '-ex', $string);
	$top .= $exp->match();

	# if before() returns any content, the $string passed is not in the beginning of the 
	# input stream.
	if (defined $exp->before() && !($exp->before() eq "") ) {
		if ($self->{debug}) {
			carp ("eat(): param \$string '$string' was found on the input stream ".
				"after '". $exp->before() . "'.");
		}
		$top = $exp->before() . $top; 
	}
	return $top;
}

# string read_all([$timeout]) - reads and remove all the output from the input stream.
# The reading/removing process will be interrupted after $timeout seconds of inactivity
# on the input stream.
sub read_all {
	my Net::SSH::Expect $self = shift;
	my $timeout = @_ ? shift : $self->{timeout};
	my $out;
	while ($self->_sec_expect($timeout, '-re', qr/[\s\S]+/)) {
		$out .= $self->get_expect()->match();
	}
	return $out;
}


# boolean has_line([$timeout]) - tells if there is one more line on the input stream
sub has_line {
	my Net::SSH::Expect $self = shift;
	my $timeout = @_ ? shift : $self->{timeout};
	$self->{next_line} = $self->read_line($timeout);
	return (defined $self->{next_line});
}

# string read_line([$timeout]) - reads the next line from the input stream
# Read a line of text. A line is considered to be terminated by the 'teminator'
# character. Default is "\n". Lines can also be ended with "\r" or "\r\n".
# Remember to adequate this for your system with the terminator() method. 
# When there are no more lines available, read_line() returns undef. Note that this doen't mean
# there is no data left on input stream since there can be a string not terminated with the 
# 'terminator' character, notably the remote prompt could be left there when read_line() returns
# undef.
#
# params:
#	$timeout: the timeout waiting for a line. Defaults to timeout().
#
# returns:
#	string: a line on the input stream, without the trailing 'terminator' character.
#			An empty string indicates that the line read only contained the 'terminator'
#			character (an empty line)
#	undef: when there are no more lines on the input stream.
#
sub read_line {
	my Net::SSH::Expect $self = shift;
	my $timeout = @_ ? shift : $self->{timeout};
	my $t = $self->{terminator};
	my $line = undef;
	if ( $self->waitfor($t, $timeout) ) {
		$line = $self->before();
	}
	return $line;
}

# string exec($cmd [,$timeout]) - executes a command, returns the complete output
sub exec {
	my Net::SSH::Expect $self = shift;
	my $cmd = shift;
	my $timeout = @_ ? shift : $self->{timeout};
	$self->send($cmd);
	return $self->read_all($timeout);
}

sub close {
	my Net::SSH::Expect $self = shift;
	my $exp = $self->get_expect();
	$exp->hard_close();
	return 1;
}


# returns 
#	reference: the internal Expect object used to manage the ssh connection.
sub get_expect {
	my Net::SSH::Expect $self = shift;
	my $exp = defined ($self->{expect}) ? $self->{expect} : 
		croak (ILLEGAL_STATE_NO_SSH_CONNECTION);
	return $exp;
}

# void restart_timeout_upon_receive( 0 | 1 ) - changes the timeout counter behaviour
# params:
#	boolean: if true, sets the timeout to "inactivity timeout", if false
#			sets it to "absolute timeout".
# dies:
#	IllegalParamenter if argument is not given.
sub restart_timeout_upon_receive {
	my Net::SSH::Expect $self = shift;
	my $value = @_ ? shift : croak (ILLEGAL_ARGUMENT . " missing argument.");
	$self->get_expect()->restart_timeout_upon_receive($value);
}

#
# Setter methods
#

sub host {
	my Net::SSH::Expect $self = shift;
	croak(ILLEGAL_ARGUMENT . " No host supplied to 'host()' method") unless @_;
	$self->{host} = shift;
}

sub user {
	my Net::SSH::Expect $self = shift;
	croak(ILLEGAL_ARGUMENT . " No user supplied to 'user()' method") unless @_;
	$self->{user} =shift;
} 

sub password{
	my Net::SSH::Expect $self = shift;
	croak(ILLEGAL_ARGUMENT . " No password supplied to 'password()' method") unless @_;
	$self->{password} = shift;
}

sub port {
	my Net::SSH::Expect $self = shift;
	croak(ILLEGAL_ARGUMENT . " No value passed to 'port()' method") unless @_;
	my $port = shift;
	croak (ILLEGAL_ARGUMENT . " Passed number '$port' is not a valid port number") 
		if ($port !~ /\A\d+\z/ || $port < 1 || $port > 65535);
	$self->{port} = $port;
}

sub terminator {
	my Net::SSH::Expect $self = shift;
	$self->{terminator} = shift if (@_);
	return $self->{terminator};
}

# boolean debug([0|1]) - gets/sets the $exp->{debug} attribute.
sub debug {
	my Net::SSH::Expect $self = shift;
	if (@_) {
		$self->{debug} = shift;
	}
	return $self->{debug};
}

# number timeout([$number]) - get/set the default timeout used for every method 
# that reads data from the input stream. 
# The only exception is eat() that has its timeout defined as 0.
sub timeout {
	my Net::SSH::Expect $self = shift;
	if (! @_ ) {
		return $self->{timeout};
	}
	my $timeout = shift;
	if ( $timeout !~ /\A\d+\z/ || $timeout < 0) {
		croak (ILLEGAL_ARGUMENT . " timeout '$timeout' is not a positive number.");
	}
	$self->{timeout} = $timeout;
}

#
# Private Methods 
#

# _sec_expect(@params) - secure expect. runs expect with @params and croaks if problems happen
# Note: timeout is not considered a problem.
# params:
#	the same parameters as expect() accepts.
# returns:
# 	the same as expect() returns
# dies:
#	SSH_CONNECTION_ABORTED if EOF is found (error type 2)
#	SSH_PROCESS_ERROR if the ssh process has died (error type 3)
#	SSH_CONNECTION_ERROR if unknown error is found (error type 4)
sub _sec_expect {
	my Net::SSH::Expect $self = shift;
	my @params = @_ ? @_ : die ("\@params cannot be undefined.");
	my $exp = $self->get_expect();
	my ($pos, $error, $match, $before, $after) = $exp->expect(@params);
	if (defined $error) {
		my $error_first_digit = substr($error, 0, 1);
		if ($error_first_digit eq '2') {	
			# found eof
			croak (SSH_CONNECTION_ABORTED);
		} elsif ($error_first_digit eq '3') {  
			# ssh process died
			croak (SSH_PROCESS_ERROR . " The ssh process was terminated.");
		} elsif ($error_first_digit eq '4') {   
			# unknown reading error
			croak (SSH_CONNECTION_ERROR . " Reading error type 4 found: $error");
		}
	}
	if (wantarray()) {
		return ($pos, $error, $match, $before, $after);
	} else {
		return $pos;
	}
}

1;



