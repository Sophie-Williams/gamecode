use strict;
use warnings;
#use diagnostics;
use 5.20.1;
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;
no if ($] >= 5.018), 'warnings' => 'experimental';
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use Math::Trig;
no warnings "experimental::smartmatch";

#############################################################################################
# Defines
select(STDOUT); $| = 1; # DO NOT REMOVE
my $tokens;
chomp(my $my_team_id = <STDIN>);
my %entity;
my %manastorage;
my $round = 0;
my ($mybase_x,$mybase_y,$enemybase_x,$enemybase_y,$OPPONENT_WIZARDteam,$enemy_side,$keeperposition_x,$keeperposition_y,$side_safe);

if ($my_team_id == 1) {
	$mybase_x = 16000;
	$mybase_y = 3750;
	$enemybase_x = 0;
	$enemybase_y = 3750;
	$enemy_side = "left";
	$keeperposition_x = 14500;
} elsif ($my_team_id == 0) {
	$mybase_x = 0;
	$mybase_y = 3750;
	$enemybase_x = 16000;
	$enemybase_y = 3750;
	$enemy_side = "right";
	$keeperposition_x = 1000;
}

sub getdistance {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    my $distance = (((($x1 - $x2) * ($x1 - $x2))) + ((($y1 - $y2) * ($y1 - $y2))));
    $distance = sqrt($distance);
    
    if (int($distance) == 0) { $distance = 1 }
    return int($distance);
}

sub getangle {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    my $distance = &getdistance($x1,$y1,$x2,$y2);
    my $dx = ($x2 - $x1) / $distance;
    my $dy = ($y2 - $y1) / $distance;
    my $a = acos($dx) * 180.0 / pi;
    if ($dy < 0) {
        $a = 360.0 - $a;
    }
    return $a;
}

sub angle_diff {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    my $angle = shift;
    if (($x1) and ($x2)) {
	    my $a = &getangle($x1,$y1,$x2,$y2);
	    my $right = $angle <= $a ? $a - $angle : 360.0 - $angle + $a;
	    my $left = $angle >= $a ? $angle - $a : $angle + 360.0 - $a;
	    $right = $right;
	    $left = $left;
	    if ($right < $left) {
	        return $right;
	    } else {
	        return -$left;
	    }
	} else {
		return(90);
	}
}

sub snafflecheck {
    my $wizard_id = shift;
    my $wizard_x = shift;
    my $wizard_y = shift;
    if ($entity{'SNAFFLE'}) {
        foreach my $snaffle_id (sort keys %{ $entity{'SNAFFLE'} }) {
            my $distance2SNAFFLE = &getdistance($wizard_x,$wizard_y,$entity{'SNAFFLE'}{$snaffle_id}{x},$entity{'SNAFFLE'}{$snaffle_id}{y});
            my $snaffles = $entity{'WIZARD'}{$wizard_id}{SNAFFLE};
            my $nearest = min map { $snaffles->{$_}{distance} } keys %$snaffles;
            
            if ($distance2SNAFFLE) {
                if ($distance2SNAFFLE == $nearest) {
                    $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{target} = "true";
                    $entity{'SNAFFLE'}{$snaffle_id}{tracked} = "true";
                    return("true",$entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{id},$entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x},$entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y},$distance2SNAFFLE);
                }
            }
        }
    }
}

sub handle_snaffle {
    my $wizard_id = shift;
    if ($entity{'WIZARD'}{$wizard_id}{state} == 1) {
        return "true";
    }
}

sub opponent_wizard_check {
    my $wizard_id = shift;
    my $wizard_x = shift;
    my $wizard_y = shift;
    if ($entity{'OPPONENT_WIZARD'}) {
        foreach my $opponent_wizard_id (sort keys %{ $entity{'OPPONENT_WIZARD'} }) {
            my $distance2OPPONENT_WIZARD = &getdistance($wizard_x,$wizard_y,$entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{x},$entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{y});
            my $OPPONENT_WIZARDs = $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD};
            my $nearest = min map { $OPPONENT_WIZARDs->{$_}{distance} } keys %$OPPONENT_WIZARDs;
            
            if ($distance2OPPONENT_WIZARD < 5000) {
                if ($distance2OPPONENT_WIZARD == $nearest) {
                    $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{target} = "true";
                    $entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{tracked} = "true";
                    return("true",$entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{id},$entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{y},$distance2OPPONENT_WIZARD);
                }
            }
        }
    }
}

sub bludgercheck {
    my $wizard_id = shift;
    my $wizard_x = shift;
    my $wizard_y = shift;
    if ($entity{'BLUDGER'}) {
        foreach my $bludger_id (sort keys %{ $entity{'BLUDGER'} }) {
            my $distance2BLUDGER = &getdistance($wizard_x,$wizard_y,$entity{'BLUDGER'}{$bludger_id}{x},$entity{'BLUDGER'}{$bludger_id}{y});
            my $BLUDGERs = $entity{'WIZARD'}{$wizard_id}{BLUDGER};
            my $nearest = min map { $BLUDGERs->{$_}{distance} } keys %$BLUDGERs;
            
            if ($distance2BLUDGER < 1000) {
                if ($distance2BLUDGER == $nearest) {
                    $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{target} = "true";
                    $entity{'BLUDGER'}{$bludger_id}{tracked} = "true";
                    return("true",$entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{id},$entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{x},$entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{y},$distance2BLUDGER);
                }
            }
        }
    }
}

sub keeperposition {
    my $wizard_id = shift;
    my $upper_y = 1900;
    my $lower_y = 5600;
    #$entity{'WIZARD'}{$wizard_id}{y};
    return("$keeperposition_x $mybase_y");
}

sub shot_position {
	my $wizard_id = shift;
	my $shot_y;
	my $x = $entity{'WIZARD'}{$wizard_id}{x};
	my $y = $entity{'WIZARD'}{$wizard_id}{y};
	my $distance2goal = $entity{'WIZARD'}{$wizard_id}{distance_enemybase};
	my $random = rand(1000);	
	
	if (($y < 3750) and ($distance2goal > 3000)) {
		$shot_y = ($enemybase_y - 1000);
	} elsif (($y > 3750) and ($distance2goal > 3000)) {
		$shot_y = ($enemybase_y + 1000);
	} elsif ($y == 0) {
		$shot_y = ($enemybase_y + $random);
	} else {
		$shot_y = $enemybase_y;
	}
	
	return "$enemybase_x $shot_y";
}

sub action {
    my $wizard_id = shift;
    my $action = shift;
    my $wizard_partner;

    if ($wizard_id == 0) {
        $wizard_partner = 1;
    } elsif ($wizard_id == 1) {
		$wizard_partner = 0
	} elsif ($wizard_id == 2) {
		$wizard_partner = 3
	} elsif ($wizard_id == 3) {
		$wizard_partner = 2
	}
	
    my $snafflecount = keys $entity{'SNAFFLE'};
    if ($snafflecount > 2) {
        $action = "catcher";
    }

    if ($action eq "catcher") {
        my ($snafflecheck,$snaffle_id,$snaffle_x,$snaffle_y,$distance2SNAFFLE) = &snafflecheck($wizard_id,$entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y});
        my ($opponent_wizard_check,$opponent_wizard_id,$OPPONENT_WIZARD_x,$OPPONENT_WIZARD_y,$distance2OPPONENT_WIZARD) = &opponent_wizard_check($wizard_id,$entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y});
        my ($bludgercheck,$bludger_id,$BLUDGER_x,$BLUDGER_y,$distance2BLUDGER) = &bludgercheck($wizard_id,$entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y});
        my $handle_snaffle = &handle_snaffle($wizard_id);
        my $cast_accio = &cast($wizard_id,"ACCIO",$snaffle_id);
        my $cast_flipendo = &cast($wizard_id,"FLIPENDO",$snaffle_id);
        my $cast_petrificus = &cast($wizard_id,"PETRIFICUS",$snaffle_id);
        my $cast_obliviate = &cast($wizard_id,"OBLIVIATE",$snaffle_id);
        my $shot_position = &shot_position($wizard_id);
        if (($handle_snaffle) and ($handle_snaffle eq 'true')) {
            print "THROW $shot_position 500\n";
        } elsif (($opponent_wizard_check) and ($cast_petrificus eq "true") and ($distance2OPPONENT_WIZARD < 2000) and ($manastorage{$wizard_id}{mana} > 30)) {
        	$manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 10);
        	print "PETRIFICUS $opponent_wizard_id\n";
    	} elsif (($bludgercheck) and ($cast_obliviate eq "true") and ($distance2BLUDGER < 2000) and ($manastorage{$wizard_id}{mana} > 50)) {
        	$manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 5);
        	print "OBLIVIATE $bludger_id\n";
    	} elsif ($snafflecheck) {
            print STDERR "Angle2Snaffle: " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{angle_WIZARD} . "\n";
            print STDERR "Diff Angle2Snaffle: " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{angle_WIZARD_diff} . "\n";
			my $snaffeldistancefromgoal = $entity{'SNAFFLE'}{$snaffle_id}{distance_enemybase};
			my $snaffeldistancefrommygoal = $entity{'SNAFFLE'}{$snaffle_id}{distance_mybase};
        	
            if (($cast_accio eq "true") and ($distance2SNAFFLE > 2000)) {
                if (($enemy_side eq "right") and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} < $entity{'WIZARD'}{$wizard_id}{x})) {
                    $manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 20);
                    print "ACCIO $snaffle_id\n";
                } elsif (($enemy_side eq "left") and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} > $entity{'WIZARD'}{$wizard_id}{x})) {
                    $manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 20);
                    print "ACCIO $snaffle_id\n";
                } else {
                    print "MOVE " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} . " " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y} . " 150\n";
                }
            } elsif (($cast_flipendo eq "true") and ($distance2SNAFFLE < 4000) and (($entity{'WIZARD'}{$wizard_id}{angle_enemybase_diff} < 15) or ($entity{'WIZARD'}{$wizard_id}{angle_enemybase_diff} > -15))) {
                if (($enemy_side eq "right") and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} > $entity{'WIZARD'}{$wizard_id}{x})) {
                    $manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 20);
                    print "FLIPENDO $snaffle_id\n";
                } elsif (($enemy_side eq "left") and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} < $entity{'WIZARD'}{$wizard_id}{x})) {
                    $manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 20);
                    print "FLIPENDO $snaffle_id\n";
                } else {
                    print "MOVE " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} . " " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y} . " 150\n";
                }
            } else {
            	print "MOVE " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} . " " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y} . " 150\n";
            }
        } else {
            print "MOVE " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} . " " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y} . " 150\n";
        }
    
    } elsif ($action eq "keeper") {
        my ($snafflecheck,$snaffle_id,$snaffle_x,$snaffle_y,$distance2SNAFFLE) = &snafflecheck($wizard_id,$entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y});
        my ($opponent_wizard_check,$opponent_wizard_id,$OPPONENT_WIZARD_x,$OPPONENT_WIZARD_y,$distance2OPPONENT_WIZARD) = &opponent_wizard_check($wizard_id,$entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y});
		my ($bludgercheck,$bludger_id,$BLUDGER_x,$BLUDGER_y,$distance2BLUDGER) = &bludgercheck($wizard_id,$entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y});
		
        my $handle_snaffle = &handle_snaffle($wizard_id);
        my $cast_accio = &cast($wizard_id,"ACCIO",$snaffle_id);
        my $cast_flipendo = &cast($wizard_id,"FLIPENDO",$snaffle_id);
        my $cast_petrificus = &cast($wizard_id,"PETRIFICUS",$snaffle_id);
        my $cast_obliviate = &cast($wizard_id,"OBLIVIATE",$snaffle_id);
        my $shot_position = &shot_position($wizard_id);
        if (($handle_snaffle) and ($handle_snaffle eq 'true')) {
            my $partner_x = $entity{'WIZARD'}{$wizard_partner}{x};
            my $partner_y = $entity{'WIZARD'}{$wizard_partner}{y};
            my $partner_distance = &getdistance($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$entity{'WIZARD'}{$wizard_partner}{x},$entity{'WIZARD'}{$wizard_partner}{y});        	
			if (($enemy_side eq "right") and ($partner_x > $entity{'WIZARD'}{$wizard_id}{x}) and ($partner_distance > 2000)) {
				print "THROW $partner_x $partner_y 500\n";
			} elsif (($enemy_side eq "left") and ($partner_x < $entity{'WIZARD'}{$wizard_id}{x}) and ($partner_distance > 2000)) {
				print "THROW $partner_x $partner_y 500\n";
			} else {
				print "THROW $shot_position 500\n";
			}
        } elsif (($opponent_wizard_check) and ($cast_petrificus eq "true") and ($distance2OPPONENT_WIZARD < 2000) and ($manastorage{$wizard_id}{mana} > 30)) {
        	$manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 10);
        	print "PETRIFICUS $opponent_wizard_id\n";
    	} elsif (($bludgercheck) and ($cast_obliviate eq "true") and ($distance2BLUDGER < 2000) and ($manastorage{$wizard_id}{mana} > 25)) {
        	$manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 5);
        	print "OBLIVIATE $bludger_id\n";
    	} elsif ($snafflecheck) {    	    
			my $snaffeldistancefromgoal = $entity{'SNAFFLE'}{$snaffle_id}{distance_enemybase};
			my $snaffeldistancefrommygoal = $entity{'SNAFFLE'}{$snaffle_id}{distance_mybase};
            if ($cast_accio eq "true") { # PULL
                if (($enemy_side eq "right") and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} < $entity{'WIZARD'}{$wizard_id}{x})) {
                    $manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 20);
                    print "ACCIO $snaffle_id\n";
                } elsif (($enemy_side eq "left") and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} > $entity{'WIZARD'}{$wizard_id}{x})) {
                    $manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 20);
                    print "ACCIO $snaffle_id\n";
                } else {
                    print "MOVE " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} . " " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y} . " 150\n";
                }
            } elsif (($cast_flipendo eq "true") and ($distance2SNAFFLE < 3500)) { # PUSH
                if (($enemy_side eq "right") and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} > $entity{'WIZARD'}{$wizard_id}{x})) {
                    $manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 20);
                    print "FLIPENDO $snaffle_id\n";
                } elsif (($enemy_side eq "left") and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} < $entity{'WIZARD'}{$wizard_id}{x})) {
                    $manastorage{$wizard_id}{mana} = ($manastorage{$wizard_id}{mana} - 20);
                    print "FLIPENDO $snaffle_id\n";
                } else {
                    print "MOVE " . &keeperposition($wizard_id) . " 150\n";
                }
                
            } elsif (($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{vx} == 0) and ($entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{vy} == 0) and ($entity{'WIZARD'}{$wizard_id}{distance_mybase} < 3000) and ($distance2SNAFFLE < 3000)) {
            	print "MOVE " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} . " " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y} . " 150\n";
            } elsif (($entity{'WIZARD'}{$wizard_id}{distance_mybase} < 3000) and ($distance2SNAFFLE < 3000)) {
            	print "MOVE " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} . " " . $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y} . " 150\n";
            } elsif (($distance2OPPONENT_WIZARD) and ($distance2OPPONENT_WIZARD < 8000) and ($entity{'WIZARD'}{$wizard_id}{distance_mybase} < 2500)) {
                print "MOVE " . $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{x} . " " . $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{y} . " 150\n";
            } else {
                print "MOVE " . &keeperposition($wizard_id) . " 150\n";
            }
        } else {
            print "MOVE " . &keeperposition($wizard_id) . " 150\n";
        }

    }
}

sub cast {
    my $wizard_id = shift;
    my $spell = shift;
    my $cost;
    my $duration;

    my $mana = $manastorage{$wizard_id}{mana};
    
    if ($spell eq "OBLIVIATE") {
        $cost = 5;
        $duration = 3;
    } elsif ($spell eq "PETRIFICUS") {
        $cost = 10;
        $duration = 1;
    } elsif ($spell eq "ACCIO") {
        $cost = 20;
        $duration = 6;
    } elsif ($spell eq "FLIPENDO") {
        $cost = 20;
        $duration = 3;
    }

    if ($mana > $cost) {
        if (!$manastorage{$wizard_id}{$spell}{start}) {
            $manastorage{$wizard_id}{$spell}{start} = 0;
        }
        
        my $durationend = ($manastorage{$wizard_id}{$spell}{start} + $duration);
        if ($round > $durationend) {
            $manastorage{$wizard_id}{$spell}{start} = $round;
            return("true");
        }
    } else {
        return("false");
    }
}

# game loop
while (1) {
    $round++;
    chomp(my $entities = <STDIN>);
    for my $i (0..$entities-1) {
        chomp($tokens=<STDIN>);
        my ($entity_id, $entity_type, $x, $y, $vx, $vy, $state) = split(/ /,$tokens);
        my $type;
  

        $entity{$entity_type}{$entity_id}{x} = $x;
        $entity{$entity_type}{$entity_id}{y} = $y;
        $entity{$entity_type}{$entity_id}{vx} = $vx;
        $entity{$entity_type}{$entity_id}{vy} = $vy;
        $entity{$entity_type}{$entity_id}{state} = $state;
        $entity{$entity_type}{$entity_id}{id} = $entity_id;
        $entity{$entity_type}{$entity_id}{type} = $entity_type;
        $entity{$entity_type}{$entity_id}{distance_mybase} = &getdistance($entity{$entity_type}{$entity_id}{x},$entity{$entity_type}{$entity_id}{y},$mybase_x,$mybase_y);
        $entity{$entity_type}{$entity_id}{distance_enemybase} = &getdistance($entity{$entity_type}{$entity_id}{x},$entity{$entity_type}{$entity_id}{y},$enemybase_x,$enemybase_y);
    }

	foreach my $wizard_id (sort keys %{ $entity{'WIZARD'} }) {
        $manastorage{$wizard_id}{mana}++;
        if ($manastorage{$wizard_id}{mana} > 100) {
            $manastorage{$wizard_id}{mana} = 100;
        }

        $entity{'WIZARD'}{$wizard_id}{angle_mybase} = &getangle($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$mybase_x,$mybase_y);
        $entity{'WIZARD'}{$wizard_id}{angle_enemybase} = &getangle($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$enemybase_x,$enemybase_y);
		$entity{'WIZARD'}{$wizard_id}{angle_mybase_diff} = int(&angle_diff($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$mybase_x,$mybase_y,$entity{'WIZARD'}{$wizard_id}{angle_mybase}));
		$entity{'WIZARD'}{$wizard_id}{angle_enemybase_diff} = int(&angle_diff($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$enemybase_x,$enemybase_y,$entity{'WIZARD'}{$wizard_id}{angle_enemybase}));

        foreach my $snaffle_id (sort keys %{ $entity{'SNAFFLE'} }) {
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{id} = $snaffle_id;
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x} = $entity{'SNAFFLE'}{$snaffle_id}{x};
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y} = $entity{'SNAFFLE'}{$snaffle_id}{y};
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{vx} = $entity{'SNAFFLE'}{$snaffle_id}{vx};
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{vy} = $entity{'SNAFFLE'}{$snaffle_id}{vy};
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{angle_WIZARD} = &getangle($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{x},$entity{'SNAFFLE'}{$snaffle_id}{x},$entity{'SNAFFLE'}{$snaffle_id}{y});
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{angle_mybase} = &getangle($entity{'SNAFFLE'}{$snaffle_id}{x},$entity{'SNAFFLE'}{$snaffle_id}{y},$mybase_x,$mybase_y);
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{angle_enemybase} = &getangle($entity{'SNAFFLE'}{$snaffle_id}{x},$entity{'SNAFFLE'}{$snaffle_id}{y},$enemybase_x,$enemybase_y);
			$entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{angle_WIZARD_diff} = int(&angle_diff($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{x},$entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{y},$entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{angle_WIZARD}));
            $entity{'WIZARD'}{$wizard_id}{SNAFFLE}{$snaffle_id}{distance} = &getdistance($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$entity{'SNAFFLE'}{$snaffle_id}{x},$entity{'SNAFFLE'}{$snaffle_id}{y});
            if (!$entity{'SNAFFLE'}{$snaffle_id}{tracked}) {
                $entity{'SNAFFLE'}{$snaffle_id}{tracked} = "false";
            }
        }

        foreach my $opponent_wizard_id (sort keys %{ $entity{'OPPONENT_WIZARD'} }) {
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{id} = $opponent_wizard_id;
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{x} = $entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{x};
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{y} = $entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{y};
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{vx} = $entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{vx};
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{vy} = $entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{vy};
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{angle_WIZARD} = &getangle($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{x},$entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{x},$entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{y});
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{angle_mybase} = &getangle($entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{x},$entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{y},$mybase_x,$mybase_y);
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{angle_enemybase} = &getangle($entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{x},$entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{y},$enemybase_x,$enemybase_y);
			$entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{angle_WIZARD_diff} = int(&angle_diff($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{y},$entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{angle_WIZARD}));
            $entity{'WIZARD'}{$wizard_id}{OPPONENT_WIZARD}{$opponent_wizard_id}{distance} = &getdistance($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{x},$entity{'OPPONENT_WIZARD'}{$opponent_wizard_id}{y});
        }

        foreach my $bludger_id (sort keys %{ $entity{'BLUDGER'} }) {
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{id} = $bludger_id;
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{x} = $entity{'BLUDGER'}{$bludger_id}{x};
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{y} = $entity{'BLUDGER'}{$bludger_id}{y};
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{vx} = $entity{'BLUDGER'}{$bludger_id}{vx};
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{vy} = $entity{'BLUDGER'}{$bludger_id}{vy};
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{angle_WIZARD} = &getangle($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{x},$entity{'BLUDGER'}{$bludger_id}{x},$entity{'BLUDGER'}{$bludger_id}{y});
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{angle_mybase} = &getangle($entity{'BLUDGER'}{$bludger_id}{x},$entity{'BLUDGER'}{$bludger_id}{y},$mybase_x,$mybase_y);
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{angle_enemybase} = &getangle($entity{'BLUDGER'}{$bludger_id}{x},$entity{'BLUDGER'}{$bludger_id}{y},$enemybase_x,$enemybase_y);
			$entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{angle_WIZARD_diff} = int(&angle_diff($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{x},$entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{y},$entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{angle_WIZARD}));
            $entity{'WIZARD'}{$wizard_id}{BLUDGER}{$bludger_id}{distance} = &getdistance($entity{'WIZARD'}{$wizard_id}{x},$entity{'WIZARD'}{$wizard_id}{y},$entity{'BLUDGER'}{$bludger_id}{x},$entity{'BLUDGER'}{$bludger_id}{y});
        }
	
        if (($wizard_id == 0) or ($wizard_id == 2)) {
	        print STDERR "Angle2EnemyBase: " . $entity{'WIZARD'}{$wizard_id}{angle_enemybase} . "\n";
            print STDERR "Diff Angle2EnemyBase: " . $entity{'WIZARD'}{$wizard_id}{angle_enemybase_diff} . "\n";
			&action($wizard_id,"catcher");
		} elsif (($wizard_id == 1) or ($wizard_id == 3)) {
			&action($wizard_id,"catcher");
			#&action($wizard_id,"keeper");
		}
    }

    #print STDERR Dumper(\$entity{'WIZARD'}{0});
    undef %entity;
}
