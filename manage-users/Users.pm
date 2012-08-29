#!/usr/bin/env perl

package Users;

use strict;
use warnings;

sub parse_file {
    my $file = shift;
    my $vals = shift;
    local *IN;

    open(IN, "<$file");

    while (<IN>) {
        chomp;

#        print "$_\n";

        my ($a, $b) = split(/:/, $_, 2);

#        print "inserting: $a: $b into hash\n";

        $$vals{$a} = $b;
    }

    close(IN);

}

sub new {
    my $class = shift;
    my $self = {
        _file => shift,
        _values => {},
    };

    parse_file($self->{_file}, $self->{_values});

    bless $self, $class;
    return $self;
}

1;
