#!/usr/bin/perl

use warnings;
use strict;

local *FLIST;
my %files;
my %matches;
my $dir = "/home/fifors/";

open(FLIST, "find $dir -type f |");

while(<FLIST>) {
	chomp;

	if (-f $_) {
		my $md5 = `md5sum "$_" | cut -f 1 -d " "`;

		chomp($md5);

		next if (/^md5sum/);

		$md5 =~ s/\s+//g;

		if (!exists($files{$md5})) {
			#print "adding $_\t$md5\n";
			$files{$md5} = $_;
		} else {
			#print "we have a match for $_ which is: " . $files{$md5}. "\n";
			if (exists($matches{$md5})) {
				push @{ $matches{$md5} }, $_;
			} else {
				push @{ $matches{$md5} }, $files{$md5}, $_;
			}
		}
	}
}

close(FLIST);

foreach my $m (keys %matches) {
	print "Matches with MD5sum: $m\n";
	foreach (@{ $matches{$m} }) {
		print "$_\n";
	}
	print "\n\n";
}
