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
my ($mypods,$enemypods,$enemy_id,$tick);

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
    $zone{path}{$zone_1}{$zone_2} = $zone_2;
    $zone{path}{$zone_2}{$zone_1} = $zone_1;
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
    
    print STDERR "$zone{$destination}\n";
    
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

sub randompath {
    my $zone_id = shift;
    my @zone_keys    = keys $zone{path}{$zone_id};
    my $random_zone_id   = $zone_keys[rand @zone_keys];
    my $random_zone = $zone{path}{$zone_id}{$random_zone_id};
    return $random_zone;
}

# game loop
while (1) {
    $tick++;
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
    
    #&podlocation();

    my (@cmds,@cmds2);
    foreach my $zone_id (sort keys $zone{zone}) {
        &podlocation();
        if ($zone{zone}{$zone_id}{$mypods}{pods}) {
            my $half = int($pods{$mypods}{zone}{$zone_id}{count} / 2);
            if ($tick < 30) { $half = 1; } elsif (($pods{$mypods}{zone}{$zone_id}{count} > 1) and ($pods{$mypods}{zone}{$zone_id}{count} < 6)) { $half = $pods{$mypods}{zone}{$zone_id}{count}; } elsif ($pods{$mypods}{zone}{$zone_id}{count} == 1) { $half = 1; }

            foreach my $path_zone_id (sort keys $zone{path}{$zone_id}) {
                if ($zone{zone}{$path_zone_id}{owner} == $my_id) {
                    my $randomzone = &randompath($zone_id);
                    my $cmd = ($half . " " . $zone_id . " " . $randomzone . " ");
                    push(@cmds,$cmd) unless ((grep{$_ eq $cmd} @cmds) or (grep{$_ eq $cmd} @cmds2));
                    next;
                } elsif ($zone{zone}{$path_zone_id}{owner} != $my_id) {
                    if (($zone{path}{$zone_id}{$path_zone_id}) or ($zone{path}{$path_zone_id}{$zone_id})) {
                        my $cmd = ($half . " " . $zone_id . " " . $path_zone_id);
                        push(@cmds2,$cmd) unless ((grep{$_ eq $cmd} @cmds2) or (grep{$_ eq $cmd} @cmds));
                        next;
                    }
                    next;
                }
            }
        }
    }


if ($cmds2[0]) {
    print join(" ",@cmds2," ",@cmds) . "\n";
    print "WAIT\n";
} else {
    print join(" ",@cmds) . "\n";
    print "WAIT\n";
}


    #print STDERR Dumper(\%zone{path});
}