#!/usr/bin/perl -w

# =head1 NAME

# perm_block.pl - permenantly block unwanted IPs

# =head1 SYNOPSIS

# Use:

    # perl perm_block.pl [--help] [--man] [--nocolor] 
                       # [--logfile path] [--attempts number]

# Examples:

    # perl perm_block.pl --help

    # perl perm_block.pl --man

    # # Block all failed attempts greater than 2:

    # perl perm_block.pl --attempts 3

# =head1 DESCRIPTION

# This script is part of the genome annotation pipeline. The script scans
# the GenBank-format RefSeq genomes from NCBI and inserts the data into the
# MySQL database; optionally, the script creates a Fasta-format output file
# containing the protein sequences.

# =head1 ARGUMENTS

# perm_block.pl takes the following arguments:

# =over 4

# =item help

  # --help

# (Optional.) Displays the usage message.

# =item man

  # --man

# (Optional.) Displays all documentation.

# =item path

  # --path name

# (Required.) Sets the path to the directory in which the division is found.

# =item division

  # --division name

# (Required.) Sets the name of the GenBank division, a subdirectory of the path
# containing one or more GenBank flat files.

# =over 8

# =item bct

# The RefSeq microbial genomes from NCBI.

# =back

# =item writeToDb

  # --writeToDb

# (Optional.) Include this argument if you want to write data to the database.

# =item clearDb

  # --clearDb

# (Optional.) Include this argument if you want to delete all data from all
# database tables before parsing and inserting begins.

# =item outFileName

  # --outFileName name

# (Optional.) The name of the fasta-format output file containing the protein
# sequences extracted from the CDS features of each accession. If not specified,
# no fasta data will be created.

# =back

# =head1 AUTHOR

# Naidu, BTR<lt>me@btrnaidu.com<gt>.

# =head1 COPYRIGHT

# This program is distributed under the GNU License.

# =head1 DATE

# 20-Aug-2012

# =cut



package main;
use strict;
use Getopt::Long ();
use Pod::Usage ();
use Term::ANSIColor;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

MAIN:	{
	#>>>>>>>>>> MAIN STARTS

	my $BAN_THRESHOLD_LIMIT = defined $ARGV[0] ? $ARGV[0] : 4;
	my %banlist;

	# Extract all the lines containing banned from /var/log/fail2ban.log
	# store in an array
	open FAIL2BAN, "/var/log/fail2ban.log" or die $!;
	my @lines = <FAIL2BAN>;
	close FAIL2BAN;

	foreach ( @lines )
	{
		if( /Ban ((\d{1,3}\.){3}\d{1,3})/ )	{
		my $found = 0;

		# Search through all the IPs in the %banlist
		my $ip;
		foreach $ip ( keys %banlist )  {
			if( $1 eq $ip )  {
			$banlist{$ip} = $banlist{$ip} + 1;
			$found = 1;
			last;
			}
		}
		if( ! $found ) {
			$banlist{$1} = 1;
		}
		}
	}

	# print the ban IPs
	my $ip;
	foreach $ip ( keys %banlist )  {
		if( $banlist{$ip} >= $BAN_THRESHOLD_LIMIT )	{
		#print "$ip : $banlist{$ip} \n";
		checkIfAlreadyDenyed( $ip ) ? 
			print colored( sprintf("%s", "$ip : $banlist{$ip}" ), 'green'), "\n" : 
			print colored( sprintf("%s", "$ip : $banlist{$ip}" ), 'red'), "\n" ; 
			#print BLINK BOLD RED ON_WHITE "$ip : $banlist{$ip}\n";
		}
	}

	print "\n";
	print colored('BLOCKED', 'green'), ' ';
	print colored('OPEN', 'red'), "\n";

	my $run_time = time - $^T;
	print "\n**** finished in ($run_time)s ****\n\n";

	exit( 0 );
	#<<<<<<<<<< MAIN ENDS

	sub checkIfAlreadyDenyed    {
		my $ip = shift @_;
		
		# Check for the ip in /etc/hosts.deny file
		# return 0 (not found) / 1 (found)
		# foreach ( `cat /etc/hosts.deny` )    {
		# return 1 if /$ip/;
		# }
		return 0;
	}

}