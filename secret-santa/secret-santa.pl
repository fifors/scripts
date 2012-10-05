#!/bin/perl

use lib "../manage-users";
use warnings;
use strict;
use Getopt::Std;
use Email::Send;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use Email::Simple::Creator;
use Users;

sub usage {

    print "Usage for secret-santa.pl\n";
    print "perl secret-santa.pl [-m] [-M] [-a] [-f file] [-n names] [-s ?]";
    print " [-A audit] [-h]\n\n";

    print "-m\t\tPrint email messages\n";
    print "-M\t\tSend email messages\n";
    print "-a\t\tShow all the details\n";
    print "-f file\tFile with list of names, eg peter,\tpeter\@asdf.com\n";
    print "-n names\tList of names to use\n";
    print "-s Santa\tEmail address to use for the Secret Santa\n";
    print "-A auditor\tAuditor's email";
    print "-h\t\tPrints this help message\n"
}

my %options;
my @names;
my @partners;
my %contacts;
my $file = "names";
my $ssanta = "ssanta\@ragnarak.com";
my $auditor;
local *INPUT;
my %ss;
my $pers = 0;
my $index;
my $el;
my $showall = 0;

%options = ();

getopts("mMaf:n:F:e:s:A:h", \%options);

if (defined($options{"h"})) {
    usage();
    exit 0;
}

if (defined($options{"f"})) {
	print "Using \"$options{'f'}\" as the source of names\n";
	$file = $options{"f"};
}

if (defined($options{"s"})) {
	print "Using $ssanta as the email of the Secret Santa\n";
	$ssanta = $options{"s"};
}

if (defined($options{"A"})) {
	print "Using \"$options{'A'}\" as the email of the auditor\n";
	$auditor = $options{"A"};
}
if (defined($options{"a"})) {
	print "WARNING: showing all details\n";
	$showall = 1;
}

if (-f $file) {
    open(INPUT, $file);
    while (<INPUT>) {
	chomp;
	if (! -z $_) {
	    my ($n, $nn, $e, $a) = split(/,/);
            $e =~ s/\s+//g;
            $a =~ s/(\b)  (\b)/$1\n$2/g;
            $a =~ s/\s+\b//;
            $nn =~ s/\s+//g;
	    $contacts{$n} = [$e, $a, $nn];
	    push(@names, $n);
	    push(@partners, $n);
	}
    }
    close(INPUT);
} else {
    print "There are no names\n";
    exit 1;
}

my $pass = "kk-gmail.txt";
my $users = new Users($pass);
my %info = %{ $users->{_values} };

while ($#partners >= 0) {
    $index = int(rand($#partners));

    for (my $i = 0; ($partners[$index] eq $names[$pers]); $i++) {
	if ($i == 5) {
	    $pers--;
	    push(@partners, $ss{$names[$pers]});
	    next;
	}
	$index = int(rand($#partners));
    }

    $el = splice(@partners, $index, 1);
    $ss{$names[$pers]} = $el;
    $pers++;
}

if ($showall) {
    foreach  (sort (keys (%ss))) {
        print "$_: $ss{$_}\n";
    }
    print "\n\n";
}

my $printMail = $options{"m"};
my $sendMail;

if (defined($options{"M"})) {
    print "Are you sure you want to send the mail? [y|n] ";
    my $ans = <STDIN>;
    chomp($ans);

    if ($ans eq 'y') {
	$sendMail = $options{"M"};
    } else {
	print "Not sending the mail, printing it out instead\n";
	$printMail = "y";
    }
}

if ($printMail || $sendMail) {
    foreach  (sort (keys (%contacts))) {
	my $from = "Secret Santa <$ssanta>";
	my $to = "$_ <$contacts{$_}[0]>";
	my $subject = "Your Kris Kindle is....";
	my $msg = "\n$contacts{$ss{$_}}[2]\n\nDo _not_ reveal under pain of death!\n\nThe mailing address for $ss{$_} is:\n\n$contacts{$ss{$_}}[1]\n\nSecret Santa\n";
	my $email = Email::Simple->create(
	    header => [
		From    => $from,
		To      => $to,
		Subject => $subject,
	    ],
	    body => $msg,
	    );

	if ($printMail) {
            print "To: $to\n";
            print "From: $from\n";
            print "Subject: $subject\n";
            print "Msg: $msg\n";
        }

        if ($sendMail) {
	    my $transport = Email::Sender::Transport::SMTP::TLS->new(
		host => 'smtp.gmail.com',
		port => 587,
		username => $info{'user'},
		password => $info{'pass'},
		helo => 'ragnarak.com',
		);

	    sendmail($email, {transport => $transport});
	    die "Error sending email: $@" if $@;
        }
    }
}

if (defined($auditor)) {
	my $from = "Secret Santa <$ssanta>";
	my $to = "$auditor";
	my $subject = "Kris Kindle List";
	my $msg;

	$msg = "Kris Kindles\nSecret Santa:\tfor:\n";
	$msg = $msg . "--------------------\n";
	foreach  (sort (keys (%ss))) {
	    $msg = $msg . "$_\t\t$ss{$_}\n";
	}
	$msg = $msg . "\nThanks!\n\nSecret Santa\n";

	my $email = Email::Simple->create(
	    header => [
		From    => $from,
		To      => $to,
		Subject => $subject,
	    ],
	    body => $msg,
	    );

	if ($printMail) {
            print "To: $to\n";
            print "From: $from\n";
            print "Subject: $subject\n";
            print "Msg: $msg\n";
        }

        if ($sendMail) {
            my $send = Email::Send->new(
		{  mailer => 'Gmail',
		   mailer_args => [
		        username => $info{'user'},
		        password => $info{'pass'},
		   ]
		}
	    );
	    eval { $send->send($email) };
	    die "Error sending email: $@" if $@;
        }
}
