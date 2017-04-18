use strict;
use warnings;
no warnings "experimental";
#use diagnostics;
use 5.20.1;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
select(STDOUT); $| = 1;

my $tokens;
my %factory;
my %troop;
my %enemy;
chomp(my $factory_count = <STDIN>);
chomp(my $link_count = <STDIN>);

for my $i (0..$link_count-1) {
    chomp($tokens=<STDIN>);
    my ($factory_1, $factory_2, $distance) = split(/ /,$tokens);
    $factory{$factory_1}{factories}{$factory_2} = $distance;
    $factory{$factory_2}{factories}{$factory_1} = $distance;
}

sub findnextfactory {
    my $factory_id = shift;
    my $otherfactories = $factory{$factory_id}{factories};
    foreach my $location (sort {%$otherfactories{$a} <=> %$otherfactories{$b}} keys %$otherfactories) {
        if ((!$location) or ($location == 0)) { $location = "0"; }
        $factory{$factory_id}{nextone} = "$location";
        last;
    }
}

while (1) {
    chomp(my $entity_count = <STDIN>);
    for my $i (0..$entity_count-1) {
        chomp($tokens=<STDIN>);
        my ($entity_id, $entity_type, $arg_1, $arg_2, $arg_3, $arg_4, $arg_5) = split(/ /,$tokens);

        if ($entity_type eq 'FACTORY') {
            &findnextfactory($entity_id);
            if ($arg_1 == 1) {
                $factory{$entity_id}{owner} = 'me';
            } elsif ($arg_1 == -1) {
                $factory{$entity_id}{owner} = 'enemy';
            } elsif ($arg_1 == 0) {
                $factory{$entity_id}{owner} = 'nobody';
            }
            $factory{$entity_id}{cyborgcount} = $arg_2;
            $factory{$entity_id}{production} = $arg_3;
        } elsif (($entity_type eq 'TROOP') and ($arg_1 == 1)) {
            $troop{$entity_id}{factoryleave} = $arg_2;
            $troop{$entity_id}{factorytarget} = $arg_3;
            $troop{$entity_id}{troopcount} = $arg_4;
            $troop{$entity_id}{turnsb4arrival} = $arg_5;
        } elsif (($entity_type eq 'TROOP') and ($arg_1 == -1)) {
            $enemy{$entity_id}{factoryleave} = $arg_2;
            $enemy{$entity_id}{factorytarget} = $arg_3;
            $enemy{$entity_id}{troopcount} = $arg_4;
            $enemy{$entity_id}{turnsb4arrival} = $arg_5;
        }
    }

    print STDERR Dumper(%factory);
    print "WAIT\n";
}