# The Machine #

## What is The Machine? ##
The Machine is an automation tool designed for system administrators that need to make their difficult or onerous tasks simple. The Machine is designed to do, among other things:

* IPv4 and IPv6 allocation, assignment and management including floating addresses
* Detailed remote sudo management on a large scale
* Apache Reverse Proxy and Redirect configuration
* DNS Domains and Zone Records (BIND)
* Bulk remote execution and reboot control of systems via SSH (D-Shell)
* VMWare snapshot integration (via API)
* Service dependency management and automatic dependency visualisation
* Full auditability of actions
* Icinaga 2 configuration (beta)

## D-Shell? What is that? ##
It's the uninspiring name given to the remote execution component of The Machine which allows you to control other systems via SSH either individually or in bulk. It's short for Distributed Shell. You provide a shell script (with optional 'tags' to do special things) and it executes the script line by line, flagging or halting on any errors - you decide which. It has a few clever tricks like being able to specify dependencies on other scripts (dependencies execute first), being able to make API calls to VMWare to make snapshots of VMs during script execution, handle reboots mid-execution (any host type) and is able to drive interactive prompts that even regular shell scripts can't manage (through optional 'tags'). It does a few other things but I won't list them all here; there's documentation for that. But most of all, it's really easy to use and very powerful.
]
## What about the other remote management tools, how does this compare? ##
**D-Shell does not require a remote agent in order to function.** It uses SSH and is limited to the rights of the user running the script - which is how it should be. That means that you don't have to deal with several sets of conflicting permissions on the host and the tool like with other management systems, nor do you need to have a 'super mega ultra god mode' account that's shared between all staff (either directly or a via single root level tool like Ansible) - shared accounts are dangerous and we don't like them. Also, unlike other remote management or configuration management systems, D-Shell isn't limited to systems with a specific set of software (like agents, Python, SNMP, etc). If you can SSH to something, The Machine can drive it with D-Shell.

## So it's like PSSH/DSH? ##
Not quite. It is similar in that it can run sets of commands in parallel across several systems, but with The Machine you can run whole scripts with just a click instead of several different commands. It also means that, because it's a single script that's executing, you can use everything that's available to you in a normal shell script such as variables, cases, loops etc. D-Shell has a few more smarts such as reboot control, execution status checking, key or password auth, etc. PSSH/DSH are handy tools for quick one line SSH tasks over many hosts, but D-Shell does that and a lot more and it's trivilally easy to use.

## What's this 'reboot control' stuff? ##
With The Machine, you can reboot a host mid-way through a script's execution and continue processing the script when the host returns. It's very useful when running updates (such as kernel updates) to be able to reboot and then resume processing later on, such as for checking that services came up correctly after the update. It might also be useful as part of a host's baseline test to reboot as a clean starting point before performing other checks. Like the rest of The Machine, reboot control is simple to use - it's a simple tag in your executing script (*REBOOT).

## Tags? ##
Tags are a special marker that tells D-Shell to do a specific thing at a specific point in a script. Reboot control is one, but there are many others such as telling D-Shell to wait for a certain length of time before performing the next action, wait for a specific string to appear on the command line before continuing, take or delete a snapshot, send a runtime variable, etc. They're easy to use - you just put them inline in the shell script and The Machine interprets them. There are some examples in the documentation to get you going.

## Runtime variables? ##
That's another tag. If you have a runtime variable tag in a script The Machine will prompt you for the value of that variable before it executes. The variable could be anything - a command, a string like a password, or even another tag.

## So what else does it do? ##
The Machine can manage sudo on remote systems, so you have fine-grained control options about what people can and can't execute on hosts. It can manage IP allocation and tracking for you letting you know how full your blocks are getting - it supports CIDR notated addresses, allocating blocks or IPs from other blocks, overlap checking, IPv4 and IPv6 addresses, host and IP network bulk discovery, floating addresses and pairing IPs with hosts. You can also track services visually allowing you to see how your company's services depend on each other - The Machine creates a visualisation for you. The Machine can also create Apache config, DNS config and Icinga 2 config for you through the GUI. No editing manifests, playbooks, SLS files or any of the other confusing names given to config files. It's designed to be easy and secure.

## Authenticaion? ##
The Machine supports local (internal) authentication, LDAP authentication or Active Directory (AD) authentication.

## Installation ##


### RHEL / CentOS ###

The Machine has RPM packages available for CentOS 7 and Red Hat Enterprise Linux (RHEL) 7. To install on one of these, run the following:

`# yum repo setup
cat << EOF > /etc/yum.repos.d/TheMachine.repo
[TheMachine]
name=The Machine
baseurl=https://rpm.nwk1.com/RHEL/
enabled=1
gpgcheck=1
gpgkey=https://rpm.nwk1.com/RPM-GPG-KEY-The-Machine
EOF

# Installation
yum -y install themachine

# Initial database setup (only required on first installation)
/opt/TheMachine/Configs/Populate_DB.sh`


The Machine also runs well on Debian varients including Ubuntu and other Linux varients but there has so far not been enough demand on these distributions to justify building and testing packages for them. If you would like packages for a specfic distribution and are willing to assist with testing, please get in touch.

## Who's using The Machine? ##
As it's an open source project with code freely available to download, it's hard to tell exacty who's using it as we don't collect stats. But from what we do know, The Machine is used from small companies managing tens of servers to large companies and government departments managing thousands of hosts and services. Parts of The Machine are even used in military environments - we know because we helped set it up.

## What about my privacy and company data? ##
We do NOT collect any data or stats and we have no plans to. The data you put into The Machine stays in The Machine and on any hosts that you explicitly push config data or commands to. There are no caveats or special exceptions, it's your data, not ours.

## Can I see some screenshots? ##
Right this way! Some of these screenshots are from test systems and some are from live systems - some data have been redacted and some things haven't been included.

![picture alt](https://nwk1.com/TheMachine/AuditLog.png "Audit Log")
![picture alt](https://nwk1.com/TheMachine/CommandSetQueue.png "Command Set Queue")
![picture alt](https://nwk1.com/TheMachine/CommandSets.png "Command Sets")
![picture alt](https://nwk1.com/TheMachine/Hosts.png "Hosts")
![picture alt](https://nwk1.com/TheMachine/IPv4Assignment.png "IPv4 Assignment")
![picture alt](https://nwk1.com/TheMachine/IPv4Assignments.png "IPv4 Assignments")
![picture alt](https://nwk1.com/TheMachine/IPv4Blocks.png "IPv4 Blocks")
![picture alt](https://nwk1.com/TheMachine/Jobs.png "Jobs")
![picture alt](https://nwk1.com/TheMachine/Management.png "Management")
![picture alt](https://nwk1.com/TheMachine/MyAccount.png "My Account")
![picture alt](https://nwk1.com/TheMachine/ReverseProxy.png "Reverse Proxy")
![picture alt](https://nwk1.com/TheMachine/Rules.png "Sudo Rules")
![picture alt](https://nwk1.com/TheMachine/SingleService.png "Single Service")
![picture alt](https://nwk1.com/TheMachine/Services.png "Services")





