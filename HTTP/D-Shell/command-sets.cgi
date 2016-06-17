#!/usr/bin/perl

use strict;
use HTML::Table;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Name = System_Name();
my $Header = Header();
my $Footer = Footer();
my $DB_Management = DB_Management();
my $DB_DShell = DB_DShell();
my $DB_IP_Allocation = DB_IP_Allocation();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Command = $CGI->param("Add_Command");
	my $Command_Add_Final = $CGI->param("Command_Add_Final");
	my $Command_Name_Add = $CGI->param("Command_Name_Add");
	my $Command_Add = $CGI->param("Command_Add");
		$Command_Add =~ s/<MagicTagNewLine>/\n/g;
		$Command_Add =~ s/<MagicTagComment>/#/g;
		$Command_Add =~ s/<MagicTagPlus>/\+/g;
	my $Command_Description_Add = $CGI->param("Description_Add");
	my $Command_Owner_Add = $CGI->param("Owner_Add");
	my $Add_Command_Dependency_Temp_New = $CGI->param("Add_Command_Dependency_Temp_New");
	my $Add_Command_Dependency_Temp_Existing = $CGI->param("Add_Command_Dependency_Temp_Existing");
	my $Delete_Command_Add_Dependency_Entry_ID = $CGI->param("Delete_Command_Add_Dependency_Entry_ID");

my $Edit_Command = $CGI->param("Edit_Command");
	my $Command_Edit_Final = $CGI->param("Command_Edit_Final");
	my $Command_Name_Edit = $CGI->param("Command_Name_Edit");
	my $Command_Edit = $CGI->param("Command_Edit");
		$Command_Edit =~ s/<MagicTagNewLine>/\n/g;
		$Command_Edit =~ s/<MagicTagComment>/#/g;
		$Command_Edit =~ s/<MagicTagPlus>/\+/g;
	my $Command_Description_Edit = $CGI->param("Description_Edit");
	my $Command_Owner_Edit = $CGI->param("Owner_Edit");
	my $Edit_Command_Dependency_Temp_New = $CGI->param("Edit_Command_Dependency_Temp_New");
	my $Edit_Command_Dependency_Temp_Existing = $CGI->param("Edit_Command_Dependency_Temp_Existing");
	my $Delete_Command_Edit_Dependency_Entry_ID = $CGI->param("Delete_Command_Edit_Dependency_Entry_ID");
	my $Edit_Command_Revision = $CGI->param("Edit_Command_Revision");

my $Delete_Command = $CGI->param("Delete_Command");
my $Delete_Command_Confirm = $CGI->param("Delete_Command_Confirm");
my $Command_Delete = $CGI->param("Command_Delete");

my $Revision_History = $CGI->param("Revision_History");
	my $Master_Revision = $CGI->param("Master_Revision");
	my $Diff = $CGI->param("Diff");
	my $Diff_Previous = $CGI->param("Diff_Previous");

my $Run_Command = $CGI->param("Run_Command");
	my $Add_Host_Group_Temp_New = $CGI->param("Add_Host_Group_Temp_New");
	my $Add_Host_Group_Temp_Existing = $CGI->param("Add_Host_Group_Temp_Existing");
	my $Add_Host_Temp_New = $CGI->param("Add_Host_Temp_New");
	my $Add_Host_Temp_Existing = $CGI->param("Add_Host_Temp_Existing");
	my $Delete_Host_Run_Entry_ID = $CGI->param("Delete_Host_Run_Entry_ID");
	my $Run_Toggle_Add = $CGI->param("Run_Toggle_Add");
	my $User_Name_Add = $CGI->param("User_Name_Add");
	my $Password_Add = $CGI->param("Password_Add");
	my $On_Failure_Add = $CGI->param("On_Failure_Add");
	my $SSH_Key = $CGI->param("SSH_Key");
	my $Key_Lock_Phrase = $CGI->param("Key_Lock_Phrase");
	my $Key_Passphrase = $CGI->param("Key_Passphrase");

my $Run_Command_Final = $CGI->param("Run_Command_Final");


my $User_Name = $Session->param("User_Name");
my $User_ID = $Session->param("User_ID");
my $User_DShell_Admin = $Session->param("User_DShell_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");
my $ID_Filter = $CGI->param("ID_Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Add_Command && !$Command_Add_Final) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_command;
	}
}
elsif ($Add_Command && $Command_Add_Final) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		my $Command_ID = &add_command;
		my $Message_Green="$Command_Name_Add added successfully as ID $Command_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Command && !$Command_Edit_Final) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_command;
	}
}
elsif ($Edit_Command && $Command_Edit_Final) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		&edit_command;
		my $Message_Green="$Command_Name_Edit edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
}
elsif ($Revision_History) {
		require $Header;
		&html_output;
		require $Footer;
		&html_revision_history;
}
elsif ($Diff && $Diff_Previous) {
		require $Header;
		&html_output;
		require $Footer;
		&html_diff_revision;
}
elsif ($Delete_Command) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_command;
	}
}
elsif ($Delete_Command_Confirm) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		&delete_command;
		my $Message_Green="$Command_Delete deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
}
elsif ($Run_Command && !$Run_Command_Final) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_run_command;
	}
}
elsif ($Run_Command && $Run_Command_Final && $Add_Host_Temp_Existing) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		&run_command;
		my $Message_Green = '<a href="/D-Shell/jobs.cgi">Job(s) submitted - click here to view the status.</a>';
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_command {

if ($Add_Command_Dependency_Temp_New) {
	if ($Add_Command_Dependency_Temp_Existing !~ m/^$Add_Command_Dependency_Temp_New,/g &&
	$Add_Command_Dependency_Temp_Existing !~ m/,$Add_Command_Dependency_Temp_New$/g &&
	$Add_Command_Dependency_Temp_Existing !~ m/,$Add_Command_Dependency_Temp_New,/g) {
		$Add_Command_Dependency_Temp_Existing = $Add_Command_Dependency_Temp_Existing . $Add_Command_Dependency_Temp_New . ",";
	}
}

if ($Delete_Command_Add_Dependency_Entry_ID) {$Add_Command_Dependency_Temp_Existing =~ s/$Delete_Command_Add_Dependency_Entry_ID//;}
$Add_Command_Dependency_Temp_Existing =~ s/,,/,/g;

my $Command_Set_Dependencies;
my @Command_Set_Dependencies = split(',', $Add_Command_Dependency_Temp_Existing);

foreach my $Command_Set_Dependency (@Command_Set_Dependencies) {

	my $Command_Set_Query = $DB_DShell->prepare("SELECT `name`, `revision`
		FROM `command_sets`
		WHERE `id` = ? ");
	$Command_Set_Query->execute($Command_Set_Dependency);
		
	while ( my ($Command_Set_Name, $Command_Set_Revision) = $Command_Set_Query->fetchrow_array() ) {
		my $Command_Set_Name_Character_Limited = substr( $Command_Set_Name, 0, 60 );
			if ($Command_Set_Name_Character_Limited ne $Command_Set_Name) {
				$Command_Set_Name_Character_Limited = $Command_Set_Name_Character_Limited . '...';
			}
			my $Command_Add_Delete_Dependency_Link = $Command_Add;
			$Command_Add_Delete_Dependency_Link =~ s/\n/<MagicTagNewLine>/g;
			$Command_Add_Delete_Dependency_Link =~ s/#/<MagicTagComment>/g;
			$Command_Add_Delete_Dependency_Link =~ s/\+/<MagicTagPlus>/g;
			$Command_Set_Dependencies = $Command_Set_Dependencies . "<tr><td align='left' style='color: #00FF00; padding-right: 15px;'>$Command_Set_Name_Character_Limited [Rev. $Command_Set_Revision]"
				. " <a href='/D-Shell/command-sets.cgi?
				Add_Command=1&
				Command_Name_Add=$Command_Name_Add&
				Owner_Add=$Command_Owner_Add&
				Command_Add=$Command_Add_Delete_Dependency_Link&
				Description_Add=$Command_Description_Add&
				Add_Command_Dependency_Temp_Existing=$Add_Command_Dependency_Temp_Existing&
				Delete_Command_Add_Dependency_Entry_ID=$Command_Set_Dependency&
				Add_Command=1
				' class='tooltip' text=\"Remove $Command_Set_Name from list\"><span style='color: #FFC600'>[Remove]</span></a>"
				. "</td></tr>";
	}
}

print <<ENDHTML;

<div id="full-width-popup-box">
<a href="/D-Shell/command-sets.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Command Set</h3>

<form action='/D-Shell/command-sets.cgi' name='Add_Command' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Name:</td>
		<td colspan="2"><input type='text' name='Command_Name_Add' value='$Command_Name_Add' style="width:100%" maxlength='128' placeholder="Update Command" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Used By:</td>
		<td style="text-align: left;">
			<select name='Owner_Add' style="width: 200px">
				<option value='0' selected>Everybody</option>
				<option value='$User_ID' selected>Only Me</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Command(s):</td>
		<td colspan="2"><textarea name="Command_Add" style="width: 800px; height: 150px" placeholder="Command Set" required="">$Command_Add</textarea></td>
	</tr>
	<tr>
		<td style="text-align: right;">Description:</td>
		<td colspan="2"><input type='text' name='Description_Add' value='$Command_Description_Add' style="width:100%" maxlength='1024' placeholder="This command set does bla bla."></td>
	<tr>
	<tr>
		<td style="text-align: right;">Dependencies:</td>
		<td style="text-align: left;">
			<select name='Add_Command_Dependency_Temp_New' onchange='this.form.submit()' style="width: 400px">
ENDHTML

	print "<option value='' selected>--Select a Command Set Dependency--</option>";

	my $Select_Command_Sets = $DB_DShell->prepare("SELECT `id`, `name`, `revision`
		FROM `command_sets`
		ORDER BY `name`"
	);

	$Select_Command_Sets->execute();


	while ( my ($Command_Set_ID, $Command_Set_Name, $Command_Set_Revision) = $Select_Command_Sets->fetchrow_array() )
	{

		my $Command_Set_Character_Limited = substr( $Command_Set_Name, 0, 60 );
			if ($Command_Set_Character_Limited ne $Command_Set_Name) {
				$Command_Set_Character_Limited = $Command_Set_Character_Limited . '...';
			}
		print "<option value='$Command_Set_ID'>$Command_Set_Character_Limited [Rev. $Command_Set_Revision]</option>";

	}
print <<ENDHTML;
			</select>
		</td>
	</tr>

</table>

<hr width="50%">

ENDHTML

if ($Command_Set_Dependencies) {
print <<ENDHTML;
			<table align = "center">
				<tr>
					<td style="padding-right: 15px">Command Set Dependencies</td>
				</tr>
				$Command_Set_Dependencies
			</table>
ENDHTML
}
else {
	print "<span style='text-align: left; color: #FFC600;'>No Command Set Dependencies</span>";
}

print <<ENDHTML;

<hr width="50%">

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<span style='color: #00FF00;'>You can give the job processor special instructions by using these tags (note the * before each):</span>
	<li><span style='color: #FC64FF;'>*VSNAPSHOT</span> - Creates/removes a VMWare snapshot for the host. Options are:</li>
		<ul style="list-style-type:circle">
			<li><span style='color: #FC64FF;'>*VSNAPSHOT COUNT</span> Counts the VMWare snapshots of the host..</li>
			<li><span style='color: #FC64FF;'>*VSNAPSHOT TAKE</span> Takes a VMWare snapshot of the host.</li>
			<li><span style='color: #FC64FF;'>*VSNAPSHOT REMOVE</span> Removes VMWare snapshots taken by $System_Name.</li>
			<li><span style='color: #FC64FF;'>*VSNAPSHOT REMOVEALL</span> Removes all VMWare snapshots for the host.</li>
		</ul>
	<li><span style='color: #FC64FF;'>*PAUSE</span> <span style='color: #00FF00;'>xx</span> - Pauses for xx seconds before processing the next command 
		(e.g. '*PAUSE 60' to pause processing for 60 seconds). Useful for waiting for machines to reboot.</li>
	<li><span style='color: #FC64FF;'>*WAITFOR</span> <span style='color: #00FF00;'>xx</span> - Waits for xx to appear on the console before processing the next 
		command. Useful for changing passwords, scripting the answers to interactive questions, sudo elevation, etc. 
		Accepts regular expressions. The default wait time is 120 seconds; after than the system assumes that something has 
		gone wrong - you can customise the wait time by appending a duration to the tag (see example below).</li>
		<ul style="list-style-type:circle">
			<li><span style='color: #FC64FF;'>*WAITFOR</span> <span style='color: #00FF00;'>password:</span> (waits for a password prompt)</li>
			<li><span style='color: #FC64FF;'>*WAITFOR</span> <span style='color: #00FF00;'>Is this ok?</span> (waits for the 'Is this ok?' prompt like the one seen in yum)</li>
			<li><span style='color: #FC64FF;'>*WAITFOR300</span> <span style='color: #00FF00;'>Is this ok?</span> (waits up to 300 seconds (5 minutes) for the 
				'Is this ok?' prompt in yum. You can set 300 to be any second value - e.g. 3600 would be 1 hour.)</li>
		</ul>
	<li><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>xx</span> - Sends characters to the console (e.g. '*SEND y' to send the letter y 
		to the console). Best used with WAITFOR, it's useful for answering the prompts that WAITFOR is looking for. <b>You should 
		also use SEND to submit the command <i>before</i> you want to use WAITFOR immediately after it. Not doing so will make the processor wait for the prompt and then wait for your 
		WAITFOR (this is unlikely to be what you intended).</b> You should use SEND for any command that you believe might need interaction, as well as for any answer (see the working example below).</li>
		<ul style="list-style-type:circle">
			<li><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>yum update</span> (sends the yum update command, then monitor the output 
				instead of monitoring the process)</li>
			<li><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>d</span> (sends the letter d to just download the packages instead of installing them)</li>
			<ul style="list-style-type:square">
				<li>Working example of yum update:
				<li style='list-style-type:none;'><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>yum update</span></li>
				<li style='list-style-type:none;'><span style='color: #FC64FF;'>*WAITFOR60</span> <span style='color: #00FF00;'>Is this ok?</span></li>
				<li style='list-style-type:none;'><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>y</span></li>
		</ul>
</ul>

<input type='hidden' name='Add_Command' value='1'>
<input type='hidden' name='Add_Command_Dependency_Temp_Existing' value='$Add_Command_Dependency_Temp_Existing'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='Command_Add_Final' value='Add Command Set'></div>

</form>

ENDHTML

} #sub html_add_command

sub add_command {

	my $Command_Insert = $DB_DShell->prepare("INSERT INTO `command_sets` (
		`name`,
		`command`,
		`description`,
		`owner_id`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?, ?
	)");

	$Command_Insert->execute($Command_Name_Add, $Command_Add, $Command_Description_Add, $Command_Owner_Add, $User_Name);

	my $Command_Insert_ID = $DB_DShell->{mysql_insertid};

	# Audit Log (Command Set)
	my $DB_Management = DB_Management();
	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");
	
	$Audit_Log_Submission->execute("D-Shell", "Add", "$User_Name added $Command_Name_Add. The system assigned it Command ID $Command_Insert_ID.", $User_Name);
	# / Audit Log (Command Set)

	### Dependencies
	$Add_Command_Dependency_Temp_Existing =~ s/^,//;
	$Add_Command_Dependency_Temp_Existing =~ s/,$//;
	my @Dependencies = split(',', $Add_Command_Dependency_Temp_Existing);

	foreach my $Dependency (@Dependencies) {

		my $Dependency_Insert = $DB_DShell->prepare("INSERT INTO `command_set_dependency` (
			`id`,
			`command_set_id`,
			`dependent_command_set_id`,
			`order`
		)
		VALUES (
			NULL,
			?,
			?,
			?
		)");
		
		$Dependency_Insert->execute($Command_Insert_ID, $Dependency, '0');

		# Audit Log (Dependency)
		my $Select_Command_Set = $DB_DShell->prepare("SELECT `name` FROM `command_sets` WHERE `id` = ?");
		$Select_Command_Set->execute($Dependency);
		while ( (my $Name) = $Select_Command_Set->fetchrow_array() )
		{
			my $DB_Management = DB_Management();
			my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
				`category`,
				`method`,
				`action`,
				`username`
			)
			VALUES (
				?,
				?,
				?,
				?
			)");
			$Audit_Log_Submission->execute("D-Shell", "Add", "$User_Name added Command Set $Name [ID $Dependency] as a dependency of $Command_Name_Add [Command Set ID $Command_Insert_ID]", $User_Name);
		}
		# / Audit Log
	}
	### / Dependencies

	return($Command_Insert_ID);

} # sub add_command

sub html_edit_command {

	## Existing Command Set Details

	my $Select_Command_Sets = $DB_DShell->prepare("SELECT `name`, `command`, `description`, `owner_id`, `revision`
		FROM `command_sets`
		WHERE `id` = ?"
	);

	$Select_Command_Sets->execute($Edit_Command);

	my $Command_Revision_Edit;
	while ( my @Select_Command_Sets = $Select_Command_Sets->fetchrow_array() ) {
		if (!$Command_Name_Edit) {$Command_Name_Edit = $Select_Command_Sets[0]}
		if (!$Command_Edit) {$Command_Edit = $Select_Command_Sets[1]}
		if (!$Command_Description_Edit) {$Command_Description_Edit = $Select_Command_Sets[2]}
		if (!$Command_Owner_Edit) {$Command_Owner_Edit = $Select_Command_Sets[3]}
		$Command_Revision_Edit = $Select_Command_Sets[4];
	}

	## / Existing Command Set Details

	## Existing Command Set Dependencies

	my $Select_Command_Set_Dependencies = $DB_DShell->prepare("SELECT `dependent_command_set_id`
		FROM `command_set_dependency`
		WHERE `command_set_id` = ?"
	);

	$Select_Command_Set_Dependencies->execute($Edit_Command);

	my $Discovered_Existing_Dependencies;
	while ( my $Command_Set_Dependencies = $Select_Command_Set_Dependencies->fetchrow_array() ) {
		$Discovered_Existing_Dependencies = $Discovered_Existing_Dependencies . $Command_Set_Dependencies . ',';
	}

	if (!$Edit_Command_Dependency_Temp_Existing) {
		$Edit_Command_Dependency_Temp_Existing = $Discovered_Existing_Dependencies;
	}

	## / Existing Command Set Dependencies

if ($Edit_Command_Dependency_Temp_New) {
	if ($Edit_Command_Dependency_Temp_Existing !~ m/^$Edit_Command_Dependency_Temp_New,/g &&
	$Edit_Command_Dependency_Temp_Existing !~ m/,$Edit_Command_Dependency_Temp_New$/g &&
	$Edit_Command_Dependency_Temp_Existing !~ m/,$Edit_Command_Dependency_Temp_New,/g) {
		$Edit_Command_Dependency_Temp_Existing = $Edit_Command_Dependency_Temp_Existing . $Edit_Command_Dependency_Temp_New . ",";
	}
}

if ($Delete_Command_Edit_Dependency_Entry_ID) {$Edit_Command_Dependency_Temp_Existing =~ s/$Delete_Command_Edit_Dependency_Entry_ID//;}
$Edit_Command_Dependency_Temp_Existing =~ s/,,/,/g;

$Edit_Command_Dependency_Temp_Existing =~ s/^,//;

my $Command_Set_Dependencies;
my @Command_Set_Dependencies = split(',', $Edit_Command_Dependency_Temp_Existing);

foreach my $Command_Set_Dependency (@Command_Set_Dependencies) {

	my $Command_Set_Query = $DB_DShell->prepare("SELECT `name`, `revision`
		FROM `command_sets`
		WHERE `id` = ? ");
	$Command_Set_Query->execute($Command_Set_Dependency);

	while ( my ($Command_Set_Name, $Command_Set_Revision) = $Command_Set_Query->fetchrow_array() ) {
		my $Command_Set_Name_Character_Limited = substr( $Command_Set_Name, 0, 60 );
			if ($Command_Set_Name_Character_Limited ne $Command_Set_Name) {
				$Command_Set_Name_Character_Limited = $Command_Set_Name_Character_Limited . '...';
			}
			my $Command_Edit_Delete_Dependency_Link = $Command_Edit;
			$Command_Edit_Delete_Dependency_Link =~ s/\n/<MagicTagNewLine>/g;
			$Command_Edit_Delete_Dependency_Link =~ s/#/<MagicTagComment>/g;
			$Command_Edit_Delete_Dependency_Link =~ s/\+/<MagicTagPlus>/g;
			$Command_Set_Dependencies = $Command_Set_Dependencies . "<tr><td align='left' style='color: #00FF00; padding-right: 15px;'>$Command_Set_Name_Character_Limited [Rev. $Command_Set_Revision]"
				. " <a href='/D-Shell/command-sets.cgi?
				Edit_Command=$Edit_Command&
				Command_Name_Edit=$Command_Name_Edit&
				Owner_Edit=$Command_Owner_Edit&
				Command_Edit=$Command_Edit_Delete_Dependency_Link&
				Description_Edit=$Command_Description_Edit&
				Edit_Command_Dependency_Temp_Existing=$Edit_Command_Dependency_Temp_Existing&
				Delete_Command_Edit_Dependency_Entry_ID=$Command_Set_Dependency&
				Edit_Command=1
				' class='tooltip' text=\"Remove $Command_Set_Name from list\"><span style='color: #FFC600'>[Remove]</span></a>"
				. "</td></tr>";
	}
}

my $Command_Revision_Edit_Plus_One = $Command_Revision_Edit + 1;

print <<ENDHTML;

<div id="full-width-popup-box">
<a href="/D-Shell/command-sets.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Command Set ID $Edit_Command</h3>

<table align = "center">
	<tr>
		<td style="text-align: right;">Current revision:</td>
		<td style='color: #00FF00;'>$Command_Revision_Edit</td>
	</tr>
	<tr>
		<td style="text-align: right;">Next revision:</td>
		<td style='color: #00FF00;'>$Command_Revision_Edit_Plus_One</td>
	</tr>
</table>

<br />

<form action='/D-Shell/command-sets.cgi' name='Edit_Command' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Name:</td>
		<td colspan="2"><input type='text' name='Command_Name_Edit' value='$Command_Name_Edit' style="width:100%" maxlength='128' placeholder="Update Command" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Used By:</td>
		<td style="text-align: left;">
			<select name='Owner_Edit' style="width: 200px">
				<option value='0' selected>Everybody</option>
				<option value='$User_ID' selected>Only Me</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Command(s):</td>
		<td colspan="2"><textarea name="Command_Edit" style="width: 800px; height: 150px" placeholder="Command Set" required="">$Command_Edit</textarea></td>
	</tr>
	<tr>
		<td style="text-align: right;">Description:</td>
		<td colspan="2"><input type='text' name='Description_Edit' value='$Command_Description_Edit' style="width:100%" maxlength='1024' placeholder="This command set does bla bla."></td>
	<tr>
	<tr>
		<td style="text-align: right;">Dependencies:</td>
		<td style="text-align: left;">
			<select name='Edit_Command_Dependency_Temp_New' onchange='this.form.submit()' style="width: 400px">
ENDHTML

	print "<option value='' selected>--Select a Command Set Dependency--</option>";

	my $Select_Dependency_Command_Sets = $DB_DShell->prepare("SELECT `id`, `name`, `revision`
		FROM `command_sets`
		ORDER BY `name`"
	);

	$Select_Dependency_Command_Sets->execute();


	while ( my ($Command_Set_ID, $Command_Set_Name, $Command_Set_Revision) = $Select_Dependency_Command_Sets->fetchrow_array() )
	{
		if ($Command_Set_ID != $Edit_Command) { 
			my $Command_Set_Character_Limited = substr( $Command_Set_Name, 0, 60 );
				if ($Command_Set_Character_Limited ne $Command_Set_Name) {
					$Command_Set_Character_Limited = $Command_Set_Character_Limited . '...';
				}
			print "<option value='$Command_Set_ID'>$Command_Set_Character_Limited [Rev. $Command_Set_Revision]</option>";
		}
	}
print <<ENDHTML;
			</select>
		</td>
	</tr>

</table>

<hr width="50%">

ENDHTML

if ($Command_Set_Dependencies) {
print <<ENDHTML;
			<table align = "center">
				<tr>
					<td style="padding-right: 15px">Command Set Dependencies</td>
				</tr>
				$Command_Set_Dependencies
			</table>
ENDHTML
}
else {
	print "<span style='text-align: left; color: #FFC600;'>No Command Set Dependencies</span>";
}

print <<ENDHTML;

<hr width="50%">

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<span style='color: #00FF00;'>You can give the job processor special instructions by using these tags (note the * before each):</span>
	<li><span style='color: #FC64FF;'>*VSNAPSHOT</span> - Creates/removes a VMWare snapshot for the host. Options are:</li>
		<ul style="list-style-type:circle">
			<li><span style='color: #FC64FF;'>*VSNAPSHOT COUNT</span> Counts the VMWare snapshots of the host..</li>
			<li><span style='color: #FC64FF;'>*VSNAPSHOT TAKE</span> Takes a VMWare snapshot of the host.</li>
			<li><span style='color: #FC64FF;'>*VSNAPSHOT REMOVE</span> Removes VMWare snapshots taken by $System_Name.</li>
			<li><span style='color: #FC64FF;'>*VSNAPSHOT REMOVEALL</span> Removes all VMWare snapshots for the host.</li>
		</ul>
	<li><span style='color: #FC64FF;'>*PAUSE</span> <span style='color: #00FF00;'>xx</span> - Pauses for xx seconds before processing the next command 
		(e.g. '*PAUSE 60' to pause processing for 60 seconds). Useful for waiting for machines to reboot.</li>
	<li><span style='color: #FC64FF;'>*WAITFOR</span> <span style='color: #00FF00;'>xx</span> - Waits for xx to appear on the console before processing the next 
		command. Useful for changing passwords, scripting the answers to interactive questions, sudo elevation, etc. 
		Accepts regular expressions. The default wait time is 120 seconds; after than the system assumes that something has 
		gone wrong - you can customise the wait time by appending a duration to the tag (see example below).</li>
		<ul style="list-style-type:circle">
			<li><span style='color: #FC64FF;'>*WAITFOR</span> <span style='color: #00FF00;'>password:</span> (waits for a password prompt)</li>
			<li><span style='color: #FC64FF;'>*WAITFOR</span> <span style='color: #00FF00;'>Is this ok?</span> (waits for the 'Is this ok?' prompt like the one seen in yum)</li>
			<li><span style='color: #FC64FF;'>*WAITFOR300</span> <span style='color: #00FF00;'>Is this ok?</span> (waits up to 300 seconds (5 minutes) for the 
				'Is this ok?' prompt in yum. You can set 300 to be any second value - e.g. 3600 would be 1 hour.)</li>
		</ul>
	<li><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>xx</span> - Sends characters to the console (e.g. '*SEND y' to send the letter y 
		to the console). Best used with WAITFOR, it's useful for answering the prompts that WAITFOR is looking for. <b>You should 
		also use SEND to submit the command <i>before</i> you want to use WAITFOR immediately after it. Not doing so will make the processor wait for the prompt and then wait for your 
		WAITFOR (this is unlikely to be what you intended).</b> You should use SEND for any command that you believe might need interaction, as well as for any answer (see the working example below).</li>
		<ul style="list-style-type:circle">
			<li><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>yum update</span> (sends the yum update command, then monitor the output 
				instead of monitoring the process)</li>
			<li><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>d</span> (sends the letter d to just download the packages instead of installing them)</li>
			<ul style="list-style-type:square">
				<li>Working example of yum update:
				<li style='list-style-type:none;'><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>yum update</span></li>
				<li style='list-style-type:none;'><span style='color: #FC64FF;'>*WAITFOR60</span> <span style='color: #00FF00;'>Is this ok?</span></li>
				<li style='list-style-type:none;'><span style='color: #FC64FF;'>*SEND</span> <span style='color: #00FF00;'>y</span></li>
		</ul>
</ul>

<input type='hidden' name='Edit_Command' value='$Edit_Command'>
<input type='hidden' name='Edit_Command_Revision' value='$Command_Revision_Edit_Plus_One'>
<input type='hidden' name='Edit_Command_Dependency_Temp_Existing' value='$Edit_Command_Dependency_Temp_Existing'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='Command_Edit_Final' value='Edit Command Set'></div>

</form>

ENDHTML

} # sub html_edit_command

sub edit_command {

	my $Update_Command = $DB_DShell->prepare("INSERT INTO `command_sets` (
		`name`,
		`command`,
		`description`,
		`owner_id`,
		`revision`,
		`revision_parent`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?, ?, ?, ?
	)");

	$Update_Command->execute($Command_Name_Edit, $Command_Edit, $Command_Description_Edit, $Command_Owner_Edit, $Edit_Command_Revision, $Edit_Command, $User_Name);
	my $Command_Insert_ID = $DB_DShell->{mysql_insertid};

	# Audit Log (Command Set)
	my $DB_Management = DB_Management();
	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");

	$Audit_Log_Submission->execute("D-Shell", "Modify", "$User_Name created a new revision (Rev. $Edit_Command_Revision) for $Command_Name_Edit (Command Set ID $Edit_Command, now ID $Command_Insert_ID). It is now recorded as $Command_Edit.", $User_Name);
	# / Audit Log (Command Set)

	### Dependencies
	$Edit_Command_Dependency_Temp_Existing =~ s/^,//;
	$Edit_Command_Dependency_Temp_Existing =~ s/,$//;
	my @Dependencies = split(',', $Edit_Command_Dependency_Temp_Existing);


	my $Clear_Old_Dependency_Links = $DB_DShell->prepare("DELETE from `command_set_dependency`
		WHERE `command_set_id` = ?");
	
	$Clear_Old_Dependency_Links->execute($Command_Insert_ID);

	foreach my $Dependency (@Dependencies) {

		my $Dependency_Insert = $DB_DShell->prepare("INSERT INTO `command_set_dependency` (
			`id`,
			`command_set_id`,
			`dependent_command_set_id`,
			`order`
		)
		VALUES (
			NULL,
			?,
			?,
			?
		)");
		
		$Dependency_Insert->execute($Command_Insert_ID, $Dependency, '0');

		# Audit Log (Dependency)
		my $Select_Command_Set = $DB_DShell->prepare("SELECT `name` FROM `command_sets` WHERE `id` = ?");
		$Select_Command_Set->execute($Dependency);
		while ( (my $Name) = $Select_Command_Set->fetchrow_array() )
		{
			my $DB_Management = DB_Management();
			my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
				`category`,
				`method`,
				`action`,
				`username`
			)
			VALUES (
				?,
				?,
				?,
				?
			)");
			$Audit_Log_Submission->execute("D-Shell", "Modify", "$User_Name modified $Command_Name_Edit [Command Set ID $Command_Insert_ID] to have the dependency $Name [Command Set ID $Dependency].", $User_Name);
		}
		# / Audit Log
	}
	### / Dependencies

} # sub edit_command

sub html_delete_command {

	my $Select_Command = $DB_DShell->prepare("SELECT `name`, `revision`
	FROM `command_sets`
	WHERE `id` = ?");

	$Select_Command->execute($Delete_Command);
	
	while ( my ($Command_Name, $Command_Revision) = $Select_Command->fetchrow_array() )
	{


print <<ENDHTML;
<div id="small-popup-box">
<a href="/D-Shell/command-sets.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Command Set</h3>

<form action='/D-Shell/command-sets.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this command set?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Command Set:</td>
		<td style="text-align: left; color: #00FF00;">$Command_Name [Rev. $Command_Revision]</td>
	</tr>
</table>

<input type='hidden' name='Delete_Command_Confirm' value='$Delete_Command'>
<input type='hidden' name='Command_Delete' value='$Command_Name [Rev. $Command_Revision]'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Command Set'></div>

</form>

ENDHTML

	}
} # sub html_delete_command

sub delete_command {

	# Dependency check
	my $Dependency_Check = $DB_DShell->prepare("SELECT `command_set_id`
		FROM `command_set_dependency`
		WHERE `dependent_command_set_id` = ?"
	);
	$Dependency_Check->execute($Delete_Command_Confirm);
	my $Rows = $Dependency_Check->rows();
	
	if ($Rows > 0) {
		my $Dependencies;
		while (my $Dependency = $Dependency_Check->fetchrow_array() )
		{
			my $Dependency_Discovery = $DB_DShell->prepare("SELECT `name`, `revision`
				FROM `command_sets`
				WHERE `id` = ?"
			);
			$Dependency_Discovery->execute($Dependency);
			while (my ($Dependency_Name, $Dependency_Revision) = $Dependency_Discovery->fetchrow_array() )
			{
				$Dependencies = $Dependencies . "$Dependency_Name [Rev. $Dependency_Revision], ";
			}
		}
		$Dependencies =~ s/,\s$//;
		
		my $Message_Red="Cannot delete Command Set ID $Delete_Command_Confirm as the following are dependent on it: $Dependencies.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);

	}

	# Audit Log
	my $Select_Commands = $DB_DShell->prepare("SELECT `name`, `revision`
		FROM `command_sets`
		WHERE `id` = ?");

	$Select_Commands->execute($Delete_Command_Confirm);

	while ( my ( $Command_Name, $Command_Revision ) = $Select_Commands->fetchrow_array() )
	{

		my $DB_Management = DB_Management();
		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");

		$Audit_Log_Submission->execute("D-Shell", "Delete", "$User_Name deleted Command Set $Command_Name [Rev. $Command_Revision], Command Set ID $Delete_Command_Confirm.", $User_Name);

	}
	# / Audit Log

	my $Delete_Command = $DB_DShell->prepare("DELETE from `command_sets`
		WHERE `id` = ?");
	
	$Delete_Command->execute($Delete_Command_Confirm);

	my $Delete_Dependency_Links = $DB_DShell->prepare("DELETE from `command_set_dependency`
		WHERE `command_set_id` = ?");
	
	$Delete_Dependency_Links->execute($Delete_Command_Confirm);

} # sub delete_command

sub html_run_command {

	my $Select_Command = $DB_DShell->prepare("SELECT `name`
		FROM `command_sets`
		WHERE `id` LIKE ?"
	);

	$Select_Command->execute($Run_Command);

	my $Command_Name;
	while ( my @Select_Command = $Select_Command->fetchrow_array() ) {
		$Command_Name = $Select_Command[0];
	}

### Temp Selection Filters
	# *_Temp_Existing are existing temporary allocations from the last refresh. This is basically a list of 'new' elements that have not yet been committed to the database.
	# *_Temp_Existing_New are new temporary allocations from the last refresh. These are added to the *_Temp_Existing variable below to form a single list for each element.
	# The list is a comma separated array, which is parsed when adding to the database.

if ($Add_Host_Temp_New) {
	if ($Add_Host_Temp_Existing !~ m/^$Add_Host_Temp_New,/g && $Add_Host_Temp_Existing !~ m/,$Add_Host_Temp_New$/g && $Add_Host_Temp_Existing !~ m/,$Add_Host_Temp_New,/g) {
		$Add_Host_Temp_Existing = $Add_Host_Temp_Existing . $Add_Host_Temp_New . ",";
	}
	if ($Add_Host_Temp_New eq 'ALL') {$Add_Host_Temp_Existing = 'ALL'}
}

if ($Delete_Host_Run_Entry_ID) {$Add_Host_Temp_Existing =~ s/$Delete_Host_Run_Entry_ID//;}
$Add_Host_Temp_Existing =~ s/,,/,/g;

#Hosts

my $Hosts;
my @Hosts = split(',', $Add_Host_Temp_Existing);

if ($Add_Host_Temp_Existing eq 'ALL') {
	$Hosts = "<tr><td align='left' style='color: #00FF00; padding-right: 15px;'>ALL (Special)</td><td align='left' style='color: #00FF00'>ALL (Special)</td></tr>";
}
else {
	foreach my $Host (@Hosts) {
	
		my $Host_Query = $DB_IP_Allocation->prepare("SELECT `hostname`
			FROM `hosts`
			WHERE `id` = ? ");
		$Host_Query->execute($Host);
			
		while ( my $Host_Name = $Host_Query->fetchrow_array() ) {
			my $Host_Name_Character_Limited = substr( $Host_Name, 0, 40 );
				if ($Host_Name_Character_Limited ne $Host_Name) {
					$Host_Name_Character_Limited = $Host_Name_Character_Limited . '...';
				}
				$Hosts = $Hosts . "<tr><td align='left' style='color: #00FF00; padding-right: 15px;'>$Host_Name_Character_Limited"
					. " <a href='/D-Shell/command-sets.cgi?Delete_Host_Run_Entry_ID=$Host&Add_Host_Temp_Existing=$Add_Host_Temp_Existing&Run_Command=$Run_Command' class='tooltip' text=\"Remove $Host_Name from list\"><span style='color: #FFC600'>[Remove]</span></a>"
					. "</td></tr>";
		}
	}
}

my $Run_Now_Checked;
my $Run_Now_Disabled;
my $On_Failure_Continue;
my $On_Failure_Kill;
if ($Run_Toggle_Add eq 'on') {
	$Run_Now_Checked = 'checked';
	$Run_Now_Disabled = '';
}
else {
	$Run_Now_Checked = '';
	$Run_Now_Disabled = 'disabled';
}
if ($On_Failure_Add) {
	$On_Failure_Kill = 'checked';
}
else {
	$On_Failure_Continue = 'checked';
}

print <<ENDHTML;

<div id="wide-popup-box">
<a href="/D-Shell/command-sets.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Queue Command Set <span style='color: #00FF00;'>$Command_Name</span></h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Run_Job_Toggle() {
	if(document.Run_Command.Run_Toggle_Add.checked)
	{
		document.Run_Command.User_Name_Add.disabled=false;
		document.Run_Command.Password_Add.disabled=false;
		document.Run_Command.User_Name_Add.value="$User_Name_Add";
		document.Run_Command.Password_Add.value="$Password_Add";
		document.Run_Command.Run_Command_Final.value="Run Job";
	}
	else
	{
		document.Run_Command.User_Name_Add.disabled=true;
		document.Run_Command.Password_Add.disabled=true;
		document.Run_Command.User_Name_Add.value="$User_Name_Add";
		document.Run_Command.Password_Add.value="$Password_Add";
		document.Run_Command.Run_Command_Final.value="Queue Job";
	}
}
//-->
</SCRIPT>

<form action='/D-Shell/command-sets.cgi' name='Run_Command' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Add Host:</td>
		<td></td>
		<td colspan="3" style="text-align: left;">
			<select name='Add_Host_Temp_New' onchange='this.form.submit()' style="width: 300px">
ENDHTML

### Hosts
				my $Host_List_Query = $DB_IP_Allocation->prepare("SELECT `id`, `hostname`
				FROM `hosts`
				ORDER BY `hostname` ASC");
				$Host_List_Query->execute( );

				print "<option value='' selected>--Select a Host--</option>";

				while ( (my $ID, my $Host_Name) = my @Host_List_Query = $Host_List_Query->fetchrow_array() )
				{
					my $Host_Name_Character_Limited = substr( $Host_Name, 0, 40 );
						if ($Host_Name_Character_Limited ne $Host_Name) {
							$Host_Name_Character_Limited = $Host_Name_Character_Limited . '...';
						}
					print "<option value='$ID'>$Host_Name_Character_Limited</option>";
				}

print <<ENDHTML;
			</select>
		</td>
	</tr>
</table>
ENDHTML

if ($Hosts) {
print <<ENDHTML;
			<table align = "center">
				<tr>
					<td style="padding-right: 15px">Host Name</td>
				</tr>
				$Hosts
			</table>
ENDHTML
}
else {
	print "<span style='text-align: left; color: #FFC600;'>No hosts yet selected</span>";
}

print <<ENDHTML;

<br /><br />

<table align="center">
	<tr>
		<td style="text-align: right;">On command failure:</td>
		<td style="text-align: right;"><input type="radio" name="On_Failure_Add" value="0" $On_Failure_Continue></td>
		<td style="text-align: left; color: #00FF00;">Continue Job</td>
		<td style="text-align: right;"><input type="radio" name="On_Failure_Add" value="1" $On_Failure_Kill></td>
		<td style="text-align: left; color: #FFC600;">Kill Job</td>
	</tr>
</table>

<hr width="50%">

<table align="center">
	<tr>
		<td style="text-align: right;">Run Job Now?:</td>
		<td colspan='4' align='left'><input type="checkbox" onclick="Run_Job_Toggle()" name="Run_Toggle_Add" $Run_Now_Checked></td>
	</tr>
	<tr>
		<td style="text-align: right;">SSH Username:</td>
		<td colspan='4'><input type="text" name="User_Name_Add" value="$User_Name_Add" placeholder="SSH Username" style="width:100%" $Run_Now_Disabled></td>
	</tr>
	<tr>
		<td style="text-align: right;">SSH Password:</td>
		<td colspan='4'><input type="password" name="Password_Add" value="$Password_Add" placeholder="SSH Password" style="width:100%" $Run_Now_Disabled></td>
	</tr>
	<tr>
		<td colspan='5'>-- or --</td>
	</tr>
	<tr>
		<td style="text-align: right;">Key:</td>
		<td colspan="3" style="text-align: left;">
			<select name='SSH_Key' style="width: 300px">
ENDHTML

### Keys
				my $Key_List_Query = $DB_Management->prepare("SELECT `id`, `key_name`, `key_username`, `key_passphrase`
				FROM `auth`
				ORDER BY `key_name` ASC");
				$Key_List_Query->execute( );

				print "<option value='' selected>--Select a Key--</option>";

				while ( my ($ID, $Key_Name, $Key_User, $Key_Passphrase) = my @Key_List_Query = $Key_List_Query->fetchrow_array() )
				{
					my $Key_Name_Character_Limited = substr( $Key_Name, 0, 40 );
						if ($Key_Name_Character_Limited ne $Key_Name) {
							$Key_Name_Character_Limited = $Key_Name_Character_Limited . '...';
						}
					print "<option value='$ID'>$Key_Name_Character_Limited [$Key_User]</option>";
				}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Key Lock Phrase:</td>
		<td colspan='4'><input type="password" name="Key_Lock_Phrase" placeholder="DB Lock Phrase" style="width:100%"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Key Passphrase:</td>
		<td colspan='4'><input type="password" name="Key_Passphrase" placeholder="Key Passphrase" style="width:100%"></td>
	</tr>
</table>

<hr width="50%">

<div style="text-align: center"><input type=submit name='Run_Command_Final' value='Queue Job'></div>

<input type='hidden' name='Run_Command' value='$Run_Command'>
<input type='hidden' name='Add_Host_Temp_Existing' value='$Add_Host_Temp_Existing'>

<br />

</form>


ENDHTML
	
} # sub html_run_command

sub run_command {

	$Add_Host_Temp_Existing =~ s/^,//;
	$Add_Host_Temp_Existing =~ s/,$//;

	# Audit Log
	my $DB_Management = DB_Management();
	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");
	
	$Audit_Log_Submission->execute("D-Shell", "Queue", "$User_Name queued a job.", $User_Name);
	# / Audit Log

	my $Push_User_Name = $User_Name;
		$Push_User_Name =~ s/\s/MagicTagSpace/g;
	if ($Run_Toggle_Add) {
		if ($Password_Add) {
			my $Password = enc($Password_Add);
			system("./job-receiver.pl -c $Run_Command -H $Add_Host_Temp_Existing -u $User_Name_Add -P $Password -f $On_Failure_Add -X ${Push_User_Name}");			
		}
		elsif ($SSH_Key) {
			$Key_Lock_Phrase =~ s/\s//g;
			my $Lock = enc($Key_Lock_Phrase);
			if ($Key_Passphrase) {
				my $Passphrase = enc($Key_Passphrase);
				system("./job-receiver.pl -c $Run_Command -H $Add_Host_Temp_Existing -k $SSH_Key -L $Lock -K $Passphrase -f $On_Failure_Add -X ${Push_User_Name}");
			}
			else {
				system("./job-receiver.pl -c $Run_Command -H $Add_Host_Temp_Existing -k $SSH_Key -L $Lock -f $On_Failure_Add -X ${Push_User_Name}");
			}

		}


	}
	else {
		system("./job-receiver.pl -c $Run_Command -H $Add_Host_Temp_Existing -f $On_Failure_Add -X ${Push_User_Name}");
	}

}

sub html_diff_revision {

	use Text::Diff;

	my $Select_First_Diff = $DB_DShell->prepare("SELECT `name`, `command`
		FROM `command_sets`
		WHERE `id` = ?"
	);

	$Select_First_Diff->execute($Diff_Previous);

	my $Diff_One_Name;
	my $Diff_One_Command;
	while ( my @Diff_One = $Select_First_Diff->fetchrow_array() ) {
			$Diff_One_Name = $Diff_One[0];
			$Diff_One_Command = $Diff_One[1];
	}

	my $Select_Second_Diff = $DB_DShell->prepare("SELECT `name`, `command`
		FROM `command_sets`
		WHERE `id` = ?"
	);

	$Select_Second_Diff->execute($Diff);

	my $Diff_Two_Name;
	my $Diff_Two_Command;
	while ( my @Diff_Two = $Select_Second_Diff->fetchrow_array() ) {
			$Diff_Two_Name = $Diff_Two[0];
			$Diff_Two_Command = $Diff_Two[1];
	}
 
	my $Diff_Compare = diff \$Diff_One_Command, \$Diff_Two_Command, { STYLE => 'Text::Diff::HTML' };
	$Diff_Compare =~ s/\r/<br \/>/g;

print <<ENDHTML;

<style>
	.file span { display: block; }
	.file .fileheader, .file .hunkheader {color: #FFFFFF; }
	.file .hunk .ctx { background: #0000FF;}
	.file .hunk ins { background: #007200; text-decoration: none; display: block; }
	.file .hunk del { background: #FF0000; text-decoration: none; display: block; }
</style>

<div id="full-width-popup-box">
<a href="/D-Shell/command-sets.cgi?Revision_History=$Master_Revision">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Diff of Command Set ID <span style='color: #00FF00;'>$Diff</span> and <span style='color: #00FF00;'>$Diff_Previous</span></h3>

<table align='center'>
	<tr>
		<td>$Diff_One_Name (ID $Diff)</td>
		<td>$Diff_Two_Name (ID $Diff_Previous)</td>
	</tr>
	<tr>
		<td colspan='2'>$Diff_Compare</td>
		
	</tr>
</table>




<br />

ENDHTML


} # sub html_diff_revision

sub html_revision_history {

	my $Table = new HTML::Table(
		-cols=>8,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'95%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow( "ID", "Command Set Name", "Commands", "Description", "Owner", 
		"Last Modified", "Modified By", "Diff with Previous" );
	$Table->setRowClass (1, 'tbrow1');

	my $Revision = $Revision_History;
	while ($Revision ne 'Last') {
		my $Select_Command = $DB_DShell->prepare("SELECT `name`, `command`, `description`, `owner_id`, `revision`, `revision_parent`, `last_modified`, `modified_by`
			FROM `command_sets`
			WHERE `id` LIKE ?"
		);
	
		$Select_Command->execute($Revision);
	
		while ( my @Revision = $Select_Command->fetchrow_array() ) {
			my $Command_Name = $Revision[0];
			my $Command_Set = $Revision[1];
				$Command_Set =~ s/</&lt;/g;
				$Command_Set =~ s/>/&gt;/g;
				$Command_Set =~ s/  /&nbsp;&nbsp;/g;
				$Command_Set =~ s/\r/<br \/>/g;
				$Command_Set =~ s/(#{1,}[\s\w'"`,.!\?\/\\\-|]*)(.*)/<span style='color: #FFC600;'>$1<\/span>$2/g;
				$Command_Set =~ s/(\*[A-Z0-9]*)(\s*.*)/<span style='color: #FC64FF;'>$1<\/span>$2/g;
			my $Command_Description = $Revision[2];
			my $Command_Owner_ID = $Revision[3];
			my $Command_Revision = $Revision[4];
				my $Command_Revision_Previous = $Command_Revision - 1;
			my $Command_Parent = $Revision[5];
			my $Last_Modified = $Revision[6];
			my $Modified_By = $Revision[7];

			## Discover owner
	
			my $Command_Owner;
			if ($Command_Owner_ID == 0) {
				$Command_Owner = 'System';
			}
			else {
				my $Discover_Owner = $DB_Management->prepare("SELECT `username`
					FROM `credentials`
					WHERE `id` = ?"
				);
				$Discover_Owner->execute($Command_Owner_ID);
				$Command_Owner = $Discover_Owner->fetchrow_array();
			}
	
			## / Discover owner

			my $Diff;
			if ($Command_Parent) {
				$Diff = "<a href='/D-Shell/command-sets.cgi?Master_Revision=$Revision_History&Diff=$Revision&Diff_Previous=$Command_Parent'><img src=\"/resources/imgs/diff.png\" alt=\"Diff Rev. $Command_Revision and Rev. $Command_Revision_Previous\" ></a>";
			}
			else {
				$Diff = 'N/A';
			}

			$Table->addRow($Revision, "$Command_Name [Rev. $Command_Revision]", $Command_Set, $Command_Description, $Command_Owner, 
			$Last_Modified, $Modified_By, 
			$Diff);
	
			if ($Command_Parent) {
				$Revision = $Command_Parent;
			}
			else {
				$Revision = 'Last';
			}

		}
	}

	$Table->setColAlign(2, 'left');
	$Table->setColAlign(3, 'left');
	$Table->setColAlign(4, 'left');
	$Table->setCellAlign(1, 2, 'center');
	$Table->setCellAlign(1, 3, 'center');
	$Table->setCellAlign(1, 4, 'center');

print <<ENDHTML;

<div id="full-width-popup-box">
<a href="/D-Shell/command-sets.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Revision history for Command Set ID <span style='color: #00FF00;'>$Revision_History</span></h3>

$Table
<br />

ENDHTML


} # sub html_revision_history

sub html_output {

	my $Table = new HTML::Table(
		-cols=>12,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Command_Count = $DB_DShell->prepare("SELECT `id` FROM `command_sets`");
		$Select_Command_Count->execute( );
		my $Total_Rows = $Select_Command_Count->rows();


	my $Select_Command_Sets;
	if ($ID_Filter) {
		$Select_Command_Sets = $DB_DShell->prepare("SELECT `id`, `name`, `command`, `description`, `owner_id`, `revision`, `revision_parent`, `last_modified`, `modified_by`
			FROM `command_sets`
			WHERE `id` = ?"
		);
		$Select_Command_Sets->execute($ID_Filter);
	}
	else {
		$Select_Command_Sets = $DB_DShell->prepare("SELECT `id`, `name`, `command`, `description`, `owner_id`, `revision`, `revision_parent`, `last_modified`, `modified_by`
			FROM `command_sets`
			WHERE `id` = ?
			OR `name` LIKE ?
			OR `command` LIKE ?
			OR `revision` LIKE ?
			OR `description` LIKE ?
			ORDER BY `name` ASC
			LIMIT 0 , $Rows_Returned"
		);
		$Select_Command_Sets->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%");
	}

	$Table->addRow( "ID", "Command Set Name", "Commands", "Description", "Dependencies", "Owner", 
		"Last Modified", "Modified By", "Revision History", "Queue Job", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Rows;
	COMMAND_SET: while ( my @Select_Command_Sets = $Select_Command_Sets->fetchrow_array() )
	{
		$Rows++;
		my $DBID = $Select_Command_Sets[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command_Name = $Select_Command_Sets[1];
			$Command_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command = $Select_Command_Sets[2];
			$Command =~ s/</&lt;/g;
			$Command =~ s/>/&gt;/g;
			$Command =~ s/  /&nbsp;&nbsp;/g;
			$Command =~ s/\r/<br \/>/g;
			$Command =~ s/(#{1,}[\s\w'"`,.!\?\/\\\-|]*)(.*)/<span style='color: #FFC600;'>$1<\/span>$2/g;
			$Command =~ s/(\*[A-Z0-9]*)(\s*.*)/<span style='color: #FC64FF;'>$1<\/span>$2/g;
			$Command =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
			
			my $Line_Count = $Command =~ tr/\n//;
				$Line_Count++;
		my $Command_Description = $Select_Command_Sets[3];
			$Command_Description =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command_Owner_ID = $Select_Command_Sets[4];
		my $Command_Revision = $Select_Command_Sets[5];
			$Command_Revision =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command_Revision_Parent = $Select_Command_Sets[6];
		my $Last_Modified = $Select_Command_Sets[7];
		my $Modified_By = $Select_Command_Sets[8];

		## Latest revision filter
		if (!$ID_Filter) {
			my $Select_Child = $DB_DShell->prepare("SELECT `id` FROM `command_sets` WHERE `revision_parent` = ?");
			$Select_Child->execute($DBID);
			my $Children = $Select_Child->rows();
			if ($Children > 0) {
				$Rows--;
				next COMMAND_SET;
			}	
		}

		## Gather dependency data
		my $Command_Set_Dependencies;
		my $Select_Command_Set_Dependencies = $DB_DShell->prepare("SELECT `dependent_command_set_id`
			FROM `command_set_dependency`
			WHERE `command_set_id` = ?
			ORDER BY `order` ASC"
		);
		$Select_Command_Set_Dependencies->execute($DBID_Clean);
	
		while ( my @Dependencies = $Select_Command_Set_Dependencies->fetchrow_array() )
		{
			my $Dependent_Command_Set_ID = $Dependencies[0];

			my $Select_Dependency_Name = $DB_DShell->prepare("SELECT `name`, `description`, `revision`
				FROM `command_sets`
				WHERE `id` = ?"
			);
			$Select_Dependency_Name->execute($Dependent_Command_Set_ID);
			my ($Dependency_Name, $Dependency_Description, $Dependency_Revision) = $Select_Dependency_Name->fetchrow_array();

			$Dependency_Description =~ s/(.{40}[^\s]*)\s+/$1\n/g; # Takes the first 40 chars, then breaks at next linespace

			$Command_Set_Dependencies = $Command_Set_Dependencies . 
			"<a href='/D-Shell/command-sets.cgi?ID_Filter=$Dependent_Command_Set_ID' class='tooltip' 
			text=\"$Dependency_Description\"><span style='color: #FF8A00;'>$Dependency_Name</span> <span style='color: #00FF00;'>[Rev. $Dependency_Revision]</span></a><br/>";
		}
		## / Gather dependency data

		## Discover owner

		my $Command_Owner;
		if ($Command_Owner_ID == 0) {
			$Command_Owner = 'System';
		}
		else {
			my $Discover_Owner = $DB_Management->prepare("SELECT `username`
				FROM `credentials`
				WHERE `id` = ?"
			);
			$Discover_Owner->execute($Command_Owner_ID);
			$Command_Owner = $Discover_Owner->fetchrow_array();
		}

		## / Discover owner

		if (!$Command_Set_Dependencies) {
			$Command_Set_Dependencies = 'None';
		}
		$Table->addRow(
			$DBID,
			"<span style='font-size: 15px; color: #FF8A00;'>" . $Command_Name . "</span><br /> <span style='color: #00FF00;'>Revision " . $Command_Revision . "</span>",
			"<details>
				<summary>#This command set has $Line_Count lines. Expand to view.</summary>
				<p>$Command</p>
			</details>",
			$Command_Description,
			$Command_Set_Dependencies,
			$Command_Owner,
			$Last_Modified,
			$Modified_By,
			"<a href='/D-Shell/command-sets.cgi?Revision_History=$DBID_Clean'><img src=\"/resources/imgs/history.png\" alt=\"Revision History for Command ID $DBID_Clean\" ></a>",
			"<a href='/D-Shell/command-sets.cgi?Run_Command=$DBID_Clean'><img src=\"/resources/imgs/forward.png\" alt=\"Run Command ID $DBID_Clean\" ></a>",
			"<a href='/D-Shell/command-sets.cgi?Edit_Command=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Command ID $DBID_Clean\" ></a>",
			"<a href='/D-Shell/command-sets.cgi?Delete_Command=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Command ID $DBID_Clean\" ></a>"
		);

	}

	$Table->setColWidth(1, '1px');
	$Table->setColStyle (3, 'max-width: 500px; word-wrap: break-word;');
	$Table->setColStyle (4, 'max-width: 500px;');
	$Table->setColWidth(6, '110px');
	$Table->setColWidth(7, '110px');
	$Table->setColWidth(8, '110px');
	$Table->setColWidth(9, '40px');
	$Table->setColWidth(10, '40px');
	$Table->setColWidth(11, '40px');
	$Table->setColWidth(12, '40px');

	$Table->setColAlign(1, 'center');
	$Table->setColAlign(2, 'center');
	for (5..12) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/D-Shell/command-sets.cgi' method='post' >
				<tr>
					<td style="text-align: right;">Returned Rows:</td>
					<td style="text-align: right;">
						<select name='Rows_Returned' onchange='this.form.submit()' style="width: 150px">
ENDHTML

if ($Rows_Returned == 100) {print "<option value=100 selected>100</option>";} else {print "<option value=100>100</option>";}
if ($Rows_Returned == 250) {print "<option value=250 selected>250</option>";} else {print "<option value=250>250</option>";}
if ($Rows_Returned == 500) {print "<option value=500 selected>500</option>";} else {print "<option value=500>500</option>";}
if ($Rows_Returned == 1000) {print "<option value=1000 selected>1000</option>";} else {print "<option value=1000>1000</option>";}
if ($Rows_Returned == 2500) {print "<option value=2500 selected>2500</option>";} else {print "<option value=2500>2500</option>";}
if ($Rows_Returned == 5000) {print "<option value=5000 selected>5000</option>";} else {print "<option value=5000>5000</option>";}
if ($Rows_Returned == 18446744073709551615) {print "<option value=18446744073709551615 selected>All</option>";} else {print "<option value=18446744073709551615>All</option>";}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">
						Filter:
					</td>
					<td style="text-align: right;">
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Commands" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/D-Shell/command-sets.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Command Set</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Command' value='Add Command Set'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/D-Shell/command-sets.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Command Set</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Command' value='Edit Command Set'></td>
					<td align="center">
						<select name='Edit_Command' style="width: 150px">
ENDHTML

						my $Command_List_Query = $DB_DShell->prepare("SELECT `id`, `name`
						FROM `command_sets`
						ORDER BY `name` ASC");
						$Command_List_Query->execute( );
						
						while ( my ($ID, $Command) = my @Command_List_Query = $Command_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Command</option>";
						}

print <<ENDHTML;
						</select>
					</td>
				</tr>
			</table>
			</form>
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Command Sets | Commands Sets Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output