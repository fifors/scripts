#!/usr/bin/perl

use lib "../manage-users";
use warnings;
use strict;
use WWW::Mechanize;
use HTML::TableExtract;
use Users;

my $pass = "pass-fit.txt";
my $users = new Users($pass);
my %info = %{ $users->{_values} };
my $login = $info{'user'};
my $password = $info{'pass'};

my $fitlinxx = "https://www.fitlinxx.com/workout/default.asp";
my $visits = "https://www.fitlinxx.com/workout/visits/visitsummary.asp";
my $full_stats = "https://www.fitlinxx.com/workout/FullStats.asp";
my $weights = "";
my $cardio = "";
my $fitpoints = "";
my $start = "10%2F1%2F2011";
my $end = "10%2F30%2F2011";
my $ytd_visits = "https://www.fitlinxx.com/workout/visits/visitsummary.asp?when=ytd&start_date=$start&display_start_date=$start&end_date=$end&display_end_date=$end";

sub get_table {
	my $index = shift;
	my @tables = @_;
	my $ret = "";

	my $count = 0;
	foreach my $ts (@tables) {
		next if ($count != -1 && $count++ < $index);

		$ret .= "<table>\n";
		foreach my $row ($ts->rows) {
			$ret .= "<tr><td>". join('</td><td>', @$row). "</td></tr>\n";
		}

		$ret .= "</table>\n";

		last if ($count != -1);
	}

	$ret .= "<p>Last Updated: " . `date` . "\n<br>";
	return $ret;
}

my %table_list = ('visits', 8, 'stats', 9);

my $m = WWW::Mechanize->new();
my $te = HTML::TableExtract->new();

$m->get($fitlinxx);

$m->submit_form(
	form_name 	=> 'loginForm',
	fields		=> { username => $login, password => $password, targetURL => "" },
);

die "stuff broke\n" unless ($m->success);

$m->get($full_stats);
my $p = $m->content;

#print "stats: \n\n $p\n";

$te->parse($p);

my $out = get_table($table_list{'stats'}, $te->tables);

print $out;

