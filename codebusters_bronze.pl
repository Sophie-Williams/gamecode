use strict;
use warnings;
#use diagnostics;
use 5.20.1;
use Data::Dumper;
no if ($] >= 5.018), 'warnings' => 'experimental';
#use List::Util qw {min};
use List::Util qw(first max maxstr min minstr reduce shuffle sum);

#############################################################################################
# Defines
select(STDOUT); $| = 1; # DO NOT REMOVE
my $tokens;
chomp(my $busters_per_player = <STDIN>);
chomp(my $ghost_count = <STDIN>);
chomp(my $my_team_id = <STDIN>);
my %entity;
my $tick = 0;
my ($mybase_x,$mybase_y,$enemybase_x,$enemybase_y,$myteam,$enemyteam);

if ($my_team_id == 0) {
	$myteam = "team0";
	$enemyteam = "team1";
} else {
	$myteam = "team1";
	$enemyteam = "team0";
}

if ($myteam eq "team0") {
	$mybase_x = 0;
	$mybase_y = 0;
	$enemybase_x = 16000;
	$enemybase_y = 9000;
} elsif ($myteam eq "team1") {
	$mybase_x = 16000;
	$mybase_y = 9000;
	$enemybase_x = 0;
	$enemybase_y = 0;
}

#############################################################################################
# Todo:
# - Warte-Bot, der die gegner abzieht
# - Shared ghost-db wieder einbauen. anhand anzahl der buster begrenzen
# - besserer roam-mode. (ggfs per zurück gelegter strecke?)
# - Hüter-Bot, der die geister richtung base treibt
# - Stun-Timer so anpassen das falls man gerade busted, wartet bis der geist ca 10% hp hat. (gegner blocken)
# - nicht mehr als 2 pro geist los schicken
# - geist mit wenigster hp zuerst angreifen

#############################################################################################
# getdistance function - Returns distance between 2 points
sub getdistance {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    my $distance = (((($x1 - $x2) * ($x1 - $x2))) + ((($y1 - $y2) * ($y1 - $y2))));
    $distance = sqrt($distance);
    return int($distance);
}

#############################################################################################
# sweep function - moves a buster from left to right and crosses map on every border
sub sweep {
    chomp(my $busterid = shift);
    my $x = shift;
    my $y = shift;
    my $param = shift;
    my $nextpos_x;
    my $nextpos_y;

    if (($param eq "up") and (!$entity{$myteam}{$busterid}{side})) {
        $nextpos_y = 2000;
    } elsif (($param eq "down") and (!$entity{$myteam}{$busterid}{side})) {
        $nextpos_y = 7000;
    } elsif ($entity{$myteam}{$busterid}{side}) {
        $nextpos_y = $entity{$myteam}{$busterid}{side};
    } elsif ($param eq "middle") {
        $nextpos_y = 4500;
    }

    if (($my_team_id == 0) and (!$entity{$myteam}{$busterid}{direction})) {
        $entity{$myteam}{$busterid}{direction} = "right";
    } elsif (($my_team_id == 1) and (!$entity{$myteam}{$busterid}{direction})) {
        $entity{$myteam}{$busterid}{direction} = "left";
    }
    

    if ($entity{$myteam}{$busterid}{direction} eq 'left') {
        if ($x < 250) {
            $entity{$myteam}{$busterid}{direction} = "right";
            if (($param eq "up") or ($param eq "down")) {
                $entity{$myteam}{$busterid}{side} = &swapsides($param);
            }
            $nextpos_x = ($x + 1500);
        } else {
            $nextpos_x = ($x - 1500);
        }
    } elsif ($entity{$myteam}{$busterid}{direction} eq 'right') {
        if ($x > 15750) {
            $entity{$myteam}{$busterid}{direction} = "left";
            if (($param eq "up") or ($param eq "down")) {
                $entity{$myteam}{$busterid}{side} = &swapsides($param);
            }
            $nextpos_x = ($x - 1500);
        } else {
            $nextpos_x = ($x + 1500);
        }
    }

    return($nextpos_x,$nextpos_y);
}

#############################################################################################
# swapsides function - needed for the sweep function
sub swapsides {
    my $y = shift;
    if ($y eq "up") {
        return 7000
    } elsif ($y eq "down") {
        return 2000
    }
}

#############################################################################################
# roam function - returns a random point thats 1500 away 
sub roam {
    my $x = shift;
    my $y = shift;
    while (1) {
        my $rand_x = int(rand(16000));
        my $rand_y = int(rand(9000));
        my $distance2random = &getdistance($x,$y,$rand_x,$rand_y);
        if ($distance2random > 1500) {
            return($rand_x,$rand_y);
        }
    }
}

#############################################################################################
# trapcheck function - returns back2base/release depending on range to base
sub trapcheck {
    my $busterid = shift;
    if ($entity{$myteam}{$busterid}{state}) {
        if ($entity{$myteam}{$busterid}{state} == 1) {
            my $ghost_id = $entity{$myteam}{$busterid}{value};
            if ($entity{$myteam}{$busterid}{distance2mybase} > 1600) {
                $entity{'ghost'}{$ghost_id}{trapped} = "true";
                delete $entity{'ghost'}{$ghost_id};
                return "back2base";
            } else {
                delete $entity{'ghost'}{$ghost_id};
                return "release";
            }
        }
    }
}



sub ghostcheck {
    my $busterid = shift;
    if ($entity{'ghost'}) {
        foreach my $ghost_id (sort keys %{ $entity{'ghost'} }) {
            $entity{'ghost'}{$ghost_id}{stamina} = $entity{'ghost'}{$ghost_id}{state};
            $entity{'ghost'}{$ghost_id}{trappedby} = $entity{'ghost'}{$ghost_id}{value};

            $entity{$myteam}{$busterid}{ghost}{$ghost_id}{distance} = &getdistance($entity{$myteam}{$busterid}{x},$entity{$myteam}{$busterid}{y},$entity{'ghost'}{$ghost_id}{x},$entity{'ghost'}{$ghost_id}{y});
            my $distance2ghost = &getdistance($entity{$myteam}{$busterid}{x},$entity{$myteam}{$busterid}{y},$entity{'ghost'}{$ghost_id}{x},$entity{'ghost'}{$ghost_id}{y});
            
            if ($entity{$myteam}{$busterid}{ghost}{$ghost_id}{distance}) {
                my $ghosts = $entity{$myteam}{$busterid}{ghost};
	            my $nearest = min map { $ghosts->{$_}{distance} } keys %$ghosts;
#                my $nearest = min $entity{$myteam}{$busterid}{ghost}{$ghost_id}{distance};
                
                if ($distance2ghost == $nearest) {
                    if (($entity{'ghost'}{$ghost_id}{trappedby} > 1) and ($entity{$myteam}{$busterid}{state} != 3)) {

                    } elsif (($entity{'ghost'}{$ghost_id}{trapped} eq "false") and (($entity{$myteam}{$busterid}{state} == 0) or ($entity{$myteam}{$busterid}{state} == 3))) {
                        $entity{$myteam}{$busterid}{ghost}{$ghost_id}{id} = $ghost_id;
                        $entity{$myteam}{$busterid}{ghost}{$ghost_id}{x} = $entity{'ghost'}{$ghost_id}{x};
                        $entity{$myteam}{$busterid}{ghost}{$ghost_id}{y} = $entity{'ghost'}{$ghost_id}{y};
                        return("true",$entity{$myteam}{$busterid}{ghost}{$ghost_id}{id},$entity{'ghost'}{$ghost_id}{x},$entity{'ghost'}{$ghost_id}{y},$distance2ghost);
                    }
                }
            }
        }
    }
}

#############################################################################################
# ghostistrapped function - defines $entity{'ghost'}{$ghost_id}{trapped}
# if ghost is currently trapped by a buster
sub ghostistrapped {
    if ($entity{'ghost'}) {
        foreach my $ghost_id (sort keys %{ $entity{'ghost'} }) {
            if (!$entity{'ghost'}{$ghost_id}{trapped}) {
                $entity{'ghost'}{$ghost_id}{trapped} = "false";
            } elsif (($entity{'ghost'}{$ghost_id}{state}) and (($entity{'ghost'}{$ghost_id}{state} == 0) or ($entity{'ghost'}{$ghost_id}{state} < 0))) {
                $entity{'ghost'}{$ghost_id}{trapped} = "true";
            }
        }	
    }
	
    if ($entity{$myteam}) {
        foreach my $buster_id (sort keys %{ $entity{$myteam} }) {            
            if ($entity{$myteam}{$buster_id}{state} == 1) {
                my $ghost_id = $entity{$myteam}{$buster_id}{value};
                $entity{'ghost'}{$ghost_id}{trapped} = "true";
            }
        }
    }
    if ($entity{$enemyteam}) {
        foreach my $enemy_id (sort keys %{ $entity{$enemyteam} }) {
            if ($entity{$enemyteam}{$enemy_id}{state} == 1) {
                my $ghost_id = $entity{$enemyteam}{$enemy_id}{value};
                $entity{'ghost'}{$ghost_id}{trapped} = "true";
            }
        }
    }
}

sub cleanhash {
    if ($entity{'ghost'}) {
        foreach my $ghost_id (sort keys %{ $entity{'ghost'} }) {
            if ((!$entity{'ghost'}{$ghost_id}) or (!$entity{'ghost'}{$ghost_id}{x}) and (!$entity{'ghost'}{$ghost_id}{y})) {
                delete $entity{'ghost'}{$ghost_id};
#                $entity{'ghost'}{$ghost_id}{trapped} = "false";
            } elsif (($entity{'ghost'}{$ghost_id}{state}) and ($entity{'ghost'}{$ghost_id}{state} > 15)) {
                print STDERR "Ghost - ID:" . $entity{'ghost'}{$ghost_id}{id} . " - " . $entity{'ghost'}{$ghost_id}{state} . "HP\n";
                print STDERR "Trapped:" . $entity{'ghost'}{$ghost_id}{trapped} . "\n";
                $entity{'ghost'}{$ghost_id}{trapped} = "false";
            } elsif ($entity{'ghost'}{$ghost_id}{trapped} eq "true") {
                delete $entity{'ghost'}{$ghost_id};
            }
        }
    }

    if ($entity{$enemyteam}) {
        foreach my $enemy_id (sort keys %{ $entity{$enemyteam} }) {
            if ((!$entity{$enemyteam}{$enemy_id}{x}) and (!$entity{$enemyteam}{$enemy_id}{y})) {
                delete $entity{$enemyteam}{$enemy_id};
            }
        }
    }
}



sub stuncheck {
    my $busterid = shift;
    if ($entity{$enemyteam}) {        
        foreach my $enemyid (sort keys %{ $entity{$enemyteam} }) {
            my $distance2enemy = &getdistance($entity{$myteam}{$busterid}{x},$entity{$myteam}{$busterid}{y},$entity{$enemyteam}{$enemyid}{x},$entity{$enemyteam}{$enemyid}{y});
            if ($distance2enemy < 1760) {
                if ((!$entity{$myteam}{$busterid}{elapsedtick}) or ($tick > $entity{$myteam}{$busterid}{elapsedtick})) {
                    if ($entity{$enemyteam}{$enemyid}{state} != 2) {
    	                return($enemyid,"stun");
                    }
                }
            }# elsif ((($entity{$enemyteam}{$enemyid}{state} == 1) and ($distance2enemy < 3000)) and ((!$entity{$myteam}{$busterid}{elapsedtick}) or ($tick > $entity{$myteam}{$busterid}{elapsedtick}))) {
             #   print "MOVE " . $entity{$enemyteam}{$enemyid}{x} . " " . $entity{$enemyteam}{$enemyid}{y} . "\n";
        #    
        #    }
        }
    }
}

sub action {
    my $busterid = shift;
    my $action = shift;
    my $actionparam = shift;
    my $trapcheck = &trapcheck($busterid);
    my ($ghostcheck,$ghost_id,$ghost_x,$ghost_y,$distance2ghost) = &ghostcheck($busterid);
    my ($enemy_id,$enemy_action) = &stuncheck($busterid);

    if (($enemy_id) and ($enemy_action eq "stun")) {
        $entity{$myteam}{$busterid}{stuntime} = $tick;
        $entity{$myteam}{$busterid}{elapsedtick} = ($tick + 20);
        print "STUN $enemy_id\n";
        
    } elsif ($trapcheck) {
        if ($trapcheck eq 'release') {
            print "RELEASE\n";
        } else {
            print "MOVE $mybase_x $mybase_y\n";
        }    
        
    } elsif ($ghostcheck) {
    
        if (($distance2ghost > 900) and ($distance2ghost < 1760)) {
            print "BUST  $ghost_id\n";
            $entity{$myteam}{$busterid}{ghost}{$ghost_id}{busting} = "true";
        } elsif ($distance2ghost < 900) {
            print "MOVE " . ($entity{$myteam}{$busterid}{ghost}{$ghost_id}{x} + 1500) . " " . ($entity{$myteam}{$busterid}{ghost}{$ghost_id}{y} - 1500) . "\n";
        } else {
            print "MOVE " . $entity{$myteam}{$busterid}{ghost}{$ghost_id}{x} . " " . $entity{$myteam}{$busterid}{ghost}{$ghost_id}{y} . "\n";
        }
        
    } else {
        &search($busterid,$action,$actionparam);
    }
}

sub search {
    my $busterid = shift;
    my $action = shift;
    my $actionparam = shift;
    if ($action eq "roam") {
        my ($roam_x,$roam_y) = &roam($entity{$myteam}{$busterid}{x},$entity{$myteam}{$busterid}{y});
        print "MOVE $roam_x $roam_y\n";            
    } elsif ($action eq "sweep") {
        my ($sweep_x,$sweep_y) = &sweep($busterid,$entity{$myteam}{$busterid}{x},$entity{$myteam}{$busterid}{y},$actionparam);
        print "MOVE $sweep_x $sweep_y\n";
    }
}

while (1) {
    $tick++;
    chomp(my $entities = <STDIN>);
    for my $i (0..$entities-1) {
        chomp($tokens=<STDIN>);
        my ($entity_id, $x, $y, $entity_type, $state, $value) = split(/ /,$tokens);
        my $type;
        
        if ($entity_type == 0) {
            $type = "team0";
        }
        if ($entity_type == 1) {
            $type = "team1";
        }
        if ($entity_type == -1) {
            $type = "ghost";            
        }
        
        $entity{$type}{$entity_id}{x} = $x;
        $entity{$type}{$entity_id}{y} = $y;
        $entity{$type}{$entity_id}{state} = $state;
        $entity{$type}{$entity_id}{value} = $value;
        $entity{$type}{$entity_id}{id} = $entity_id;
        $entity{$type}{$entity_id}{type} = $entity_type;
        $entity{$type}{$entity_id}{distance2mybase} = &getdistance($entity{$type}{$entity_id}{x},$entity{$type}{$entity_id}{y},$mybase_x,$mybase_y);
        $entity{$type}{$entity_id}{distance2enemybase} = &getdistance($entity{$type}{$entity_id}{x},$entity{$type}{$entity_id}{y},$enemybase_x,$enemybase_y);
    }

	&ghostistrapped();
	&cleanhash();
    


	my $internalid;
	foreach my $busterid (sort keys %{ $entity{$myteam} }) {
	    &cleanhash();
		$internalid++;
		$entity{$myteam}{$busterid}{internalid} = $internalid;

        if ($busters_per_player == 2) {
    		if ($internalid == 1) {
    			&action($busterid,"sweep","up");
    		} elsif ($internalid == 2) {
    			&action($busterid,"sweep","down");
    		}
        } elsif ($busters_per_player == 3) {
    		if ($internalid == 1) {
    			&action($busterid,"sweep","up");
    		} elsif ($internalid == 2) {
    			&action($busterid,"sweep","down");
    		} elsif ($internalid == 3) {
    			&action($busterid,"sweep","middle");
    		}
        } elsif ($busters_per_player == 4) {
    		if ($internalid == 1) {
    			&action($busterid,"sweep","up");
    		} elsif ($internalid == 2) {
    			&action($busterid,"sweep","down");
    		} elsif ($internalid == 3) {
    			&action($busterid,"sweep","middle");
    		} elsif ($internalid == 4) {
    			&action($busterid,"sweep","middle");
    		}
        } elsif ($busters_per_player == 5) {
    		if ($internalid == 1) {
    			&action($busterid,"sweep","up");
    		} elsif ($internalid == 2) {
    			&action($busterid,"sweep","down");
    		} elsif ($internalid == 3) {
    			&action($busterid,"sweep","middle");
    		} elsif ($internalid == 4) {
    			&action($busterid,"roam");
    		} elsif ($internalid == 5) {
    			&action($busterid,"roam");
    		}
        } else {
			&action($busterid,"roam");
        }
    }
    
    my $realtick = ($tick / $busters_per_player);
    if ($realtick % 100) {
        delete $entity{'ghost'};
    }
    
    #&cleanhash();
    print STDERR Dumper(\%entity);
}