#!/bin/env perl

use warnings;
use strict;
use Text::CSV;
use Data::Dumper;

my $sysstat_directory 	= "/var/log/sa/";
my $hostname		= `hostname -s`;
my $cell_zero		= '# hostname';

# Chomp [remove trailing record separator {\n}] $hostname for later use.

chomp($hostname);

opendir(my $directory_handle, $sysstat_directory) || die "Can't locate ".$sysstat_directory."\n";

my @file_list 		= grep { /^sa[0-9]./ } readdir($directory_handle);

#print <<EOF;
#============================================== Variables ===================================================
#Sysstat Directory....	$sysstat_directory\n 
#Cell Zero............   $cell_zero\n
#Hostname.............	$hostname\n
#EOF
foreach my $filename (sort {$a cmp $b} @file_list)
{
#	printf "Filepath.......	".$sysstat_directory.$filename."\n";
	my $shell_call 	= "sadf -dht ".$sysstat_directory.$filename." -- -S -u -r -p -q -n DEV";

	open(my $file_handle, "$shell_call 2>&1 |") || die "Failed to parse output of [".$shell_call."].\n";

	my @csv_handle	= <$file_handle>;
	close $file_handle;

	sysstat_csv_to_hash_of_hashes(@csv_handle);
}
# Array of filesystems found on the system

##
# ===========================================================================================================
#  Functions
# ===========================================================================================================


## Should I be creating a function that does the following? :
##	used on only the first CSV to determine the position of IFACE column headers, store
##	the information in an array for use to parse all CSVs
## OR
## Should I detect column headers for each CSV, perhaps using a separate function,
## perhaps not? 
## 
sub sysstat_csv_to_hash_of_hashes
{

	my @csv_lines	   = @_;
	my @csv_keys	   = split(/;/,$csv_lines[0]);
	my $csv_keys_count = scalar (@csv_keys);
	my @memory_keys	   = ("kbavail", "kbmemused", "kbbuffers", "kbcached");

	#print join(" ", @csv_keys);
	chomp(@csv_keys);

	shift(@csv_lines);
	chomp(@csv_lines);

	if ($csv_keys_count < split(/;/, $csv_lines[1]))
	{
		# Some columns are missing keys
		# This can be due to the output format of sysstat, where redundant sequences of csv
		# column names are printed for data sets like  network interfaces.
		#
		# Loop through csv keys until we find the first IFACE column
		# Find the first ocurance of 'IFACE'

		my $counter	= 1;
		foreach my $csv_column (@csv_keys)
		{
			if (grep(/^IFACE/i, $csv_column))
			{
				print "\n\nFound iFACE in column ".$counter."!\n";
			} else {
				(++$counter);
			}
		}
	}

#	foreach my $line_of_stats (@csv_lines)
#	{
#		my @array_of_stats	= split /;/, $line_of_stats;
#
#			print $csv_keys[32].": ...\n";
#			print $array_of_stats[32].": ...\n";
#			print $csv_keys[33].": ...\n";
#			print $csv_keys[34].": ...\n";
#			print $csv_keys[35].": ...\n";
#			print $csv_keys[36].": ...\n";
#			print $csv_keys[37].": ...\n";
#			print $csv_keys[38].": ...\n";
#			print $csv_keys[39].": ...\n";
#			print $csv_keys[40].": ...\n======================================================\n";
		#print "Stats Count : ...".@array_of_stats.".\n";
		#print "Key Count : ...".@csv_keys.".\n";
		#if (defined $csv_keys[32])
		#{
		#	print $csv_keys[32].": ...\n";
		#	print "........".$array_of_stats[32]."\n";
		#}
#	shift(@csv_lines);
#	print join(" ",@csv_keys);
#
#	foreach my $line (@csv_lines)
#	{
#		print join("\n",@$line);
#	}
}
