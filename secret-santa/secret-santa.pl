#!/bin/perl

use lib "../manage-users";
use warnings;
use strict;
use Getopt::Std;
use Email::Send;
use Email::MIME;
use Users;

sub usage {

    print "Usage for secret-santa.pl\n";
    print "perl secret-santa.pl [-m] [-M] [-a] [-f file] [-n names] [-s ?]";
    print " [-A audit] [-h]\n\n";

    print "-m\t\tPrint email messages\n";
    print "-M\t\tSend email messages\n";
    print "-a\t\tShow all the details\n";
    print "-f file\tFile with list of names, eg peter,\tpeter\@asdf.com\n";
    print "-d file\tFile with list of duplicate names\n";
    print "-n names\tList of names to use\n";
    print "-s Santa\tEmail address to use for the Secret Santa\n";
    print "-A auditor\tAuditor's email\n";
    print "-h\t\tPrints this help message\n";
}

my %options;
my @names;
my @partners;
my %contacts;
my $file = "names";
my $dups = "dups";
my %dupl;
my $ssanta = "ssanta\@ragnarak.com";
my $auditor;
local *INPUT;
my %ss;
my $pers = 0;
my $index;
my $el;
my $showall = 0;

%options = ();

getopts("mMaf:n:F:e:s:A:hd:", \%options);

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

if (defined($options{"d"})) {
    print "Using \"$options{'d'}\" as the source of duplicates\n";
    $dups = $options{"d"};
}

if (-f $file) {
    open(INPUT, $file);
    while (<INPUT>) {
        chomp;
        if (!-z $_) {
            my ($n, $nn, $e, $a) = split(/,/);
            $e  =~ s/\s+//g;
            $a  =~ s/(\b)  (\b)/$1<br>\n$2/g;
            $a  =~ s/\s+\b//;
            $nn =~ s/\s+//g;
            $contacts{$n} = [ $e, $a, $nn ];
            push(@names,    $n);
            push(@partners, $n);
        }
    }
    close(INPUT);
} else {
    print "There are no names\n";
    exit 1;
}

if (-f $dups) {
    open(INPUT, $dups);
    while (<INPUT>) {
        chomp;
        if (!-z $_) {
            my ($n, $d) = split(/,/);
            $dupl{$n} = $d;
            $d =~ s/^\s+//;
            $d =~ s/\s+$//;
            #print "name: $n\tdup: $d\n";
        }
    }
    close(INPUT);
} else {
    print "There are no dups\n";
    exit 1;
}
#my $pass  = "kk-gmail.txt";
my $pass  = "godaddy.txt";
#my $pass  = "gmail.txt";
my $users = new Users($pass);
my %info  = %{ $users->{_values} };

while ($#partners >= 0) {
    $index = int(rand($#partners));

    for (my $i = 0 ; (($partners[$index] eq $names[$pers])) ; $i++) {
        if ($i == 5) {
            $pers--;
            push(@partners, $ss{ $names[$pers] });
            next;
        }
        $index = int(rand($#partners));
        my $dup = "none";

        if (defined($dupl{ $names[$pers] })) {
            $dup = $dupl{ $names[$pers] };
        }

        #print "Partner: $partners[$index]\tname: $names[$pers]\tdup: $dup\n";
        if ($dup =~ /$partners[$index]/) {
            print "Fixing duplicate, old index: $index\n";
            $index = int(rand($#partners));
            for (my $i = 0 ; (($partners[$index] eq $dup)) ; $i++) {
                if ($i == 5) {
                    $pers--;
                    push(@partners, $ss{ $names[$pers] });
                    last;
                }
                $index = int(rand($#partners));
            }

            print "new index: $index\n";
        }
    }

    $el = splice(@partners, $index, 1);
    $ss{ $names[$pers] } = $el;
    $pers++;
}

if ($showall) {
    foreach (sort (keys (%ss))) {
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

# Write email list
local *OUT;
my $o = "mail_list.txt";

my $idx = 0;
my %reply;
open(OUT, ">$o");
foreach my $k (sort (keys (%contacts))) {
    print OUT "$contacts{$k}[0],$contacts{$ss{$k}}[0]\n";
    my $m;
    foreach my $j (sort (keys (%ss))) {
        if ($ss{$j} eq $k) {
            $m = $j;
            last;
        }
    }

    print OUT "$contacts{$k}[0],$contacts{$m}[0]\n";

    $reply{ $contacts{$k} } = $idx;

    $idx += 2;
}
close(OUT);

if ($printMail || $sendMail) {
    foreach (sort (keys (%contacts))) {
        my $from    = "Secret Santa <$ssanta>";
        my $to      = "$_ <$contacts{$_}[0]>";
        my $subject = "Your Kris Kindle is....";
        my $msg =
          "$contacts{$ss{$_}}[2]<br><br>Do _not_ reveal under any circumstance!";

        $msg .= "<br><br>The mailing address for $ss{$_} is:<br><br>";
        $msg .= "$contacts{$ss{$_}}[1]<br><br>Secret Santa<br><br>";

        my $ref = $reply{ $contacts{$_} };

        $msg .= "Click <a href=\"http://ragnarak.com/ss.cgi?id=$ref\">here</a>";
        $msg .= " when sending your gift.<br>";

        $ref++;
        $msg .= "Click <a href=\"http://ragnarak.com/ss.cgi?id=$ref\">here</a>";
        $msg .= " when you've recieved your gift.<br>";

        my $email = Email::MIME->create(
	    attributes => {
		content_type => 'multipart/alternative',
	    },
            header_str => [
                From    => $from,
                To      => $to,
                Subject => $subject,
            ],
	    parts => [
		Email::MIME->create(
		    attributes 	=> { content_type => 'text/plain' },
            body => $msg,
		),
		Email::MIME->create(
		    attributes 	=> { content_type => 'text/html' },
		    body	=> $msg,
		)
	    ],
       );

        if ($printMail) {
            print "\nTo: $to\n";
            print "From: $from\n";
            print "Subject: $subject\n";
            print "Msg: $msg\n";
        }

        if ($sendMail) {
            my $send = Email::Send->new(
		{ mailer => 'SMTP',
		  mailer_args => [
                Host     => $info{'host'},
                ssl      => 1,
                username => $info{'user'},
                password => $info{'pass'},
		  ]
		}
            );

	    eval { $send->send($email) };
            die "Error sending email: $@" if $@;
        }
    }
}

if (defined($auditor)) {
    my $from    = "Secret Santa <$ssanta>";
    my $to      = "$auditor";
    my $subject = "Kris Kindle List";
    my $msg;

    $msg = "Kris Kindles\nSecret Santa:\tfor:\n";
    $msg = $msg . "--------------------\n";
    foreach (sort (keys (%ss))) {
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
            {
                mailer      => 'Gmail',
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
