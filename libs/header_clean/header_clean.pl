#!/usr/bin/perl

use strict;
use warnings;

my $remove_file_add_header    = 1;
my $remove_file_delete_header = 1;
my $clean_permission_changes  = 1;

#################################################################################

my $ansi_sequence_regex = qr/(\e\[([0-9]{1,3}(;[0-9]{1,3}){0,3})[mK])?/;

my ($file_1,$file_2,$last_file_seen);
my @input = <>;
strip_empty_first_line(\@input);

for (my $i = 0; $i <= $#input; $i++) {
	my $line = $input[$i];

	#print "RAW: $line";

	#########################
	# Look for the filename #
	#########################
	if ($line =~ /^${ansi_sequence_regex}diff --git (.+?) /) {
		$last_file_seen = $4;
		$last_file_seen =~ s|a/||; # Remove a/
	########################################
	# Find the first file: --- a/README.md #
	########################################
	} elsif ($line =~ /^$ansi_sequence_regex--- (a\/)?(.+?)(\e|$)/) {
		$file_1 = $5;

		# Find the second file on the next line: +++ b/README.md
		my $next = $input[++$i];
		$next    =~ /^$ansi_sequence_regex\+\+\+ (b\/)?(.+?)(\e|$)/;
		if ($1) {
			print $1; # Print out whatever color we're using
		}
		$file_2 = $5;

		# If they're the same it's a modify
		if ($file_1 eq $file_2) {
			print "modified: $file_1\n";
		# If the first is /dev/null it's a new file
		} elsif ($file_1 eq "/dev/null") {
			print "added: $file_2\n";
		# If the second is /dev/null it's a deletion
		} elsif ($file_2 eq "/dev/null") {
			print "deleted: $file_1\n";
		# If the files aren't the same it's a rename
		} elsif ($file_1 ne $file_2) {
			print "renamed: $file_1 to $file_2\n";
		# Something we haven't thought of yet
		} else {
			print "$file_1 -> $file_2\n";
		}
	###################################
	# Remove any new file permissions #
	###################################
	} elsif ($remove_file_add_header && $line =~ /^${ansi_sequence_regex}new file mode/) {
		# Don't print the line (i.e. remove it from the output);
	######################################
	# Remove any delete file permissions #
	######################################
	} elsif ($remove_file_delete_header && $line =~ /^${ansi_sequence_regex}deleted file mode/) {
		# Don't print the line (i.e. remove it from the output);
	#####################################################
	# Check if we're changing the permissions of a file #
	#####################################################
	} elsif ($clean_permission_changes && $line =~ /^${ansi_sequence_regex}old mode (\d+)/) {
		my $next = $input[++$i];

		if ($1) {
			print $1; # Print out whatever color we're using
		}

		my ($new_mode) = $next =~ m/new mode (\d+)/;
		print "$last_file_seen changed file mode to $new_mode\n";
	#####################################
	# Just a regular line, print it out #
	#####################################
	} else {
		print $line;
	}
}

sub strip_empty_first_line {
	my $foo = shift(); # Array passed in by reference

	# If the first line is just whitespace remove it
	if ($foo->[0] =~ /^\s*$/) {
		shift($foo);
	}
}