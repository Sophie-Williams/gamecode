use strict;
use warnings;
#use diagnostics;
use 5.20.1;
use Data::Dumper;
no if ($] >= 5.018), 'warnings' => 'experimental';
select(STDOUT); $| = 1; # DO NOT REMOVE

# Auto-generated code below aims at helping you parse
# the standard input according to the problem statement.

my $tokens;
my %zone;
my %pods;
my ($mypods,$enemypods,$enemy_id);

# player_count: the amount of players (always 2)
# my_id: my player ID (0 or 1)
# zone_count: the amount of zones on the map
# link_count: the amount of links between all zones
# POD costs 20 Platinum
chomp($tokens=<STDIN>);
my ($player_count, $my_id, $zone_count, $link_count) = split(/ /,$tokens);
for my $i (0..$zone_count-1) {
    chomp($tokens=<STDIN>);
    my ($zone_id, $platinum_source) = split(/ /,$tokens);
}

# Set Path for each Zone
for my $i (0..$link_count-1) {
    chomp($tokens=<STDIN>);
    my ($zone_1, $zone_2) = split(/ /,$tokens);
    $zone{path}{$zone_1}{$zone_2} = "true";
    $zone{path}{$zone_2}{$zone_1} = "true";
}

if ($my_id == 0) {
    $enemy_id = 1;
	$mypods = "player0";
	$enemypods = "player1";
} elsif ($my_id == 1) {
    $enemy_id = 0;
	$mypods = "player1";
	$enemypods = "player0";
}

$pods{$mypods}{podcount} = 10;
sub podcount {
    my $platinum = shift;
    print STDERR "New PODs: " . ($platinum % 20) . "\n";
    if ($platinum % 20) {
        $pods{$mypods}{podcount} = ($pods{$mypods}{podcount} + ($platinum % 20));
    }
    return $pods{$mypods}{podcount};
}
    

sub getpath {
    chomp(my $zone_id = shift);
    chomp(my $destination = shift);
    foreach my $zone (sort keys $zone{path}{$zone_id}) {
            
       if (($zone{$destination}) and ($zone{$destination} eq "true")) {
            print STDERR "HIT\n";
            return("true",$zone{$destination});
       } else {
            return("false");
       }
    }
}

sub podlocation {
    foreach my $zone_id (sort keys $zone{zone}) {
        if ($zone{zone}{$zone_id}{$mypods}{pods}) {
               $pods{$mypods}{zone}{$zone_id}{count} = $zone{zone}{$zone_id}{$mypods}{pods};
        }
    }
}

sub move {
    my $podzones = $pods{$mypods}{zone};
    foreach my $zone_id (sort keys $podzones) {
        my $podcount = $pods{$mypods}{zone}{$zone_id}{count};
    } 
}

# game loop
while (1) {
    chomp(my $my_platinum = <STDIN>); # your available Platinum
    $pods{$mypods}{$my_platinum} = $my_platinum;
    &podcount($my_platinum);
    
    for my $i (0..$zone_count-1) {
        # z_id: this zone's ID
        # owner_id: the player who owns this zone (-1 otherwise)
        # pods_p0: player 0's PODs on this zone
        # pods_p1: player 1's PODs on this zone
        # visible: 1 if one of your units can see this tile, else 0
        # platinum: the amount of Platinum this zone can provide (0 if hidden by fog)
        chomp($tokens=<STDIN>);
        my ($z_id, $owner_id, $pods_p0, $pods_p1, $visible, $platinum) = split(/ /,$tokens);
        $zone{zone}{$z_id}{owner} = $owner_id;
        $zone{zone}{$z_id}{visible} = $visible;
        $zone{zone}{$z_id}{platinum} = $platinum;
        $zone{zone}{$z_id}{player0}{pods} = $pods_p0;
        $zone{zone}{$z_id}{player1}{pods} = $pods_p1;
    }
    
    &podlocation();

    my @cmds;
    foreach my $zone_id (sort keys $zone{zone}) {
        if ($zone{zone}{$zone_id}{$mypods}{pods}) {
               
            foreach my $path_zone_id (sort keys $zone{zone}) {
                if (($zone{zone}{$path_zone_id}{owner} != $my_id) and ($zone{zone}{$path_zone_id}{visible} == 1)) {
                    
                    my $path = &getpath($zone_id,$path_zone_id);
                    #if ($path eq "true") {
                        #print $zone{zone}{$zone_id}{$mypods}{pods} . " " . $zone_id . " " . $path_zone_id . "\n";
                        my $cmd = (1 . " " . $zone_id . " " . $path_zone_id . " ");
                        push(@cmds,$cmd);
                    #}
                    
                }
            }
        }
    }

    my $command;
    foreach(@cmds) {
        $command = $command .= $_;
    }
    undef @cmds;
    
    if ($command) {
        print $command . "\n";
        print "WAIT\n";
    } else {
        print "WAIT\n";
        print "WAIT\n";
    }
    
    #print STDERR Dumper(\%zone{path});
}