#!/usr/bin/perl

use lib "../manage-users";
use Email::MIME;
use Email::Send;
use Users;

my $pass = "godaddy.txt";
my $users = new Users($pass);

my %info = %{ $users->{_values} };

my $email = Email::MIME->create(
    attributes => {
        content_type => 'multipart/alternative',
    },
    header_str => [
        From    => 'peter@ragnarak.com',
        To      => 'peter_buckingham@dell.com',
        Subject => 'Here\'s a multipart email..',
    ],
    parts => [
        Email::MIME->create(
            attributes  => { content_type => 'text/plain'},
            body        => 'Howdie',
        ),
        Email::MIME->create(
            attributes  => { content_type => 'text/html' },
            body        => '<b>Howdie</b>',
        )
    ],
);

#printf "email: %s\n", $email->as_string;

my $send = Email::Send->new(
                {  mailer => 'SMTP',
                   mailer_args => [
                       Host => 'smtpout.secureserver.net:465',
                       ssl => 1,
                       username => $info{'user'},
                       password => $info{'pass'},
                   ]
                }
            );

eval { $send->send($email) };
            die "Error sending email: $@" if $@;
