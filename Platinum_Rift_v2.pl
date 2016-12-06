use strict;
use warnings;
#use diagnostics;
use 5.20.1;

select(STDOUT); $| = 1; # DO NOT REMOVE

# Auto-generated code below aims at helping you parse
# the standard input according to the problem statement.

my $tokens;

# player_count: the amount of players (always 2)
# my_id: my player ID (0 or 1)
# zone_count: the amount of zones on the map
# link_count: the amount of links between all zones
chomp($tokens=<STDIN>);
my ($player_count, $my_id, $zone_count, $link_count) = split(/ /,$tokens);
for my $i (0..$zone_count-1) {
    # zone_id: this zone's ID (between 0 and zoneCount-1)
    # platinum_source: Because of the fog, will always be 0
    chomp($tokens=<STDIN>);
    my ($zone_id, $platinum_source) = split(/ /,$tokens);
}
for my $i (0..$link_count-1) {
    chomp($tokens=<STDIN>);
    my ($zone_1, $zone_2) = split(/ /,$tokens);
}

# game loop
while (1) {
    chomp(my $my_platinum = <STDIN>); # your available Platinum
    for my $i (0..$zone_count-1) {
        # z_id: this zone's ID
        # owner_id: the player who owns this zone (-1 otherwise)
        # pods_p0: player 0's PODs on this zone
        # pods_p1: player 1's PODs on this zone
        # visible: 1 if one of your units can see this tile, else 0
        # platinum: the amount of Platinum this zone can provide (0 if hidden by fog)
        chomp($tokens=<STDIN>);
        my ($z_id, $owner_id, $pods_p0, $pods_p1, $visible, $platinum) = split(/ /,$tokens);
    }
    
    # Write an action using print
    # To debug: print STDERR "Debug messages...\n";

    # first line for movement commands, second line no longer used (see the protocol in the statement for details)

    print "WAIT\n";
    print "WAIT\n";
}