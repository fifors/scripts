#!/usr/bin/perl

use warnings;
use strict;
use WWW::Mechanize;
use Storable;

my $url = 'http://www.census.gov/population/www/documentation/twps0027.html';
my $m = WWW::Mechanize->new()

$m->get($url);

my $c = $m->content;

$c =~ m{<A NAME=.tabA.>(.*?)</TABLE>}s or
	die "Can't find the population table\n";

my $t = $1;
my @outer = $t =~ m{<TR.*?>(.*?)</TR>}gs;
shift @outer;
my %data;

foreach my $r (@outer) {
	my @bits = $r =~ m{<TD.*?>(.*?)</TD>}gs;
	for (my $x = 0; $x < $#bits; $x++) {
		my $b = $bits[$x];
		my @v = split /\s*<BR>\s*/, $b;

		foreach (@v) { s/^\s+//; s/\s+$//;}
		push @{$data[$x]}, @v;
	}
}

for (my $y = 0; $y < @{$data[0]}; $y++) {
	$data{$data[1][$y]} = {
		NAME	=> $data[1][$y],
		RANK	=> $data[0][$y],
		POP	=> comma_free($data[2][$y]),
		AREA	=> comma_free($data[3][$y]),
		DENS	=> comma_free($data[4][$y]),
	};
}

store(\%data, "cities.dat");

sub comma_free {
	my $n = shift;
	$n =~ s/,//;

	return $n;
}
