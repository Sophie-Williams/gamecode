use strict;
use warnings;
#use diagnostics;
use 5.20.1;
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;
use Time::HiRes qw( time );
select(STDOUT); $| = 1;

my $tokens;
my %ship;
my %persistent;
my %rum;
my %enemy;
my %mine;
my %cannonball;
my $tick;

# Convert odd-r hex to cube coordinates
sub oddr2cube {
    my $col = shift;
    my $row = shift;
    my $x = $col - ($row - ($row & 1)) / 2;
    my $z = $row;
    my $y = (-$x-$z);
    return($x,$y,$z);
}

# Convert cube to odd-r hex coordinates
sub cube2oddr {
    my $x = shift;
    my $y = shift;
    my $z = shift;
    my $col = $x + ($z - ($z & 1)) / 2;
    my $row = $z;
    return($col,$row);
}

# Get distance from two cube positions
sub getcubedistance {
    my $cube_x1 = shift;
    my $cube_y1 = shift;
    my $cube_z1 = shift;
    my $cube_x2 = shift;
    my $cube_y2 = shift;
    my $cube_z2 = shift;
    my $cubedistance = (abs($cube_x1 - $cube_x2) + abs($cube_y1 - $cube_y2) + abs($cube_z1 - $cube_z2)) / 2;
}

# Move away from the edges
sub cornerslide {
    my $ship_id = shift;
    my $x = $ship{$ship_id}{hull_front_x};
    my $y = $ship{$ship_id}{hull_front_y};
    if (($x < 2) or ($y < 2)) {
        if (($ship{$ship_id}{orientation} == 1) or ($ship{$ship_id}{orientation} == 2) or ($ship{$ship_id}{orientation} == 3) or ($ship{$ship_id}{orientation} == 4)) {
            if ($ship{$ship_id}{speed} > 0) {
            	return("MOVE 12 10");
            }
        }
    } elsif (($x > 18) or ($y > 20)) {
        if (($ship{$ship_id}{orientation} == 2) or ($ship{$ship_id}{orientation} == 3) or ($ship{$ship_id}{orientation} == 4) or ($ship{$ship_id}{orientation} == 5)) {
            if ($ship{$ship_id}{speed} > 0) {
            	return("MOVE 12 10");
            }
        }
    }
}

# Avoid cannonballs
sub avoidhit {
	my $ship_id = shift;
    my $ship_next_x = $ship{$ship_id}{next_x};
    my $ship_next_y = $ship{$ship_id}{next_y};
    my $ship_front_x = $ship{$ship_id}{hull_front_x};
    my $ship_front_y = $ship{$ship_id}{hull_front_y};
    my $ship_mid_x = $ship{$ship_id}{hull_mid_x};
    my $ship_mid_y = $ship{$ship_id}{hull_mid_y};
    my $ship_back_x = $ship{$ship_id}{hull_back_x};
    my $ship_back_y = $ship{$ship_id}{hull_back_y};
    
    foreach my $cannonball_id (sort keys %cannonball) {
	    my $target_x = $cannonball{$cannonball_id}{target_x};
	    my $target_y = $cannonball{$cannonball_id}{target_y};

	    if ((($cannonball{$cannonball_id}{countdown} == 2) and ($ship{$ship_id}{speed} > 0)) and (($target_x == $ship_next_x) and ($target_y == $ship_next_y))) {
            if ($ship{$ship_id}{speed} > 1) {
    	    	if (int(rand(2)) == 0) {
    	    		return("true","PORT");
    	    	} else {
    	    		return("true","STARBOARD");
    	    	}
            } else {
                return("true","FASTER");
            }
	    } elsif ((($cannonball{$cannonball_id}{countdown} == 2) and ($ship{$ship_id}{speed} == 0)) and (($target_x == $ship_next_x) and ($target_y == $ship_next_y))) {
            return("true","FASTER");
	    } elsif ((($cannonball{$cannonball_id}{countdown} == 0) or ($cannonball{$cannonball_id}{countdown} == 1)) and (($target_x == $ship_front_x) and ($target_y == $ship_front_y))) {
            if ($ship{$ship_id}{speed} > 1) {
    	    	if (int(rand(2)) == 0) {
    	    		return("true","PORT");
    	    	} else {
    	    		return("true","STARBOARD");
    	    	}
            } else {
                return("true","FASTER");
            }
	    } elsif (($cannonball{$cannonball_id}{countdown} == 1) and (($target_x == $ship_mid_x) and ($target_y == $ship_mid_y))) {
            if ($ship{$ship_id}{speed} > 1) {
    	    	if (int(rand(2)) == 0) {
    	    		return("true","PORT");
    	    	} else {
    	    		return("true","STARBOARD");
    	    	}
            } else {
                return("true","FASTER");
            }
	    } elsif (($cannonball{$cannonball_id}{countdown} == 1) and (($target_x == $ship_back_x) and ($target_y == $ship_back_y))) {
            if ($ship{$ship_id}{speed} > 1) {
    	    	if (int(rand(2)) == 0) {
    	    		return("true","PORT");
    	    	} else {
    	    		return("true","STARBOARD");
    	    	}
            } else {
                return("true","FASTER");
            }
	    }
    }
}

# Predict next move based on current position/orientation/speed
sub predict {
	my $item = shift;
    my $id = shift;
    my $speed = $item->{$id}{speed};
    my $orientation = $item->{$id}{orientation};
    my $target_col;
    my $target_row;
    my $line;
    if ($item->{$id}{x} % 2 == 0) { $line = "even"; }
    if ($item->{$id}{x} % 2 == 1) { $line = "odd"; }
    
    if ($orientation == 0) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{x} + $speed);
            $target_row = $item->{$id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{x} + $speed);
            $target_row = $item->{$id}{y};
        }
    } elsif ($orientation == 1) {
        if ($line eq 'even') {
            $target_col = $item->{$id}{x};
            $target_row = ($item->{$id}{y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{x} + $speed);
            $target_row = ($item->{$id}{y} - $speed);
        }
    } elsif ($orientation == 2) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{x} - $speed);
            $target_row = ($item->{$id}{y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = $item->{$id}{x};
            $target_row = ($item->{$id}{y} - $speed);
        }
    } elsif ($orientation == 3) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{x} - $speed);
            $target_row = $item->{$id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{x} - $speed);
            $target_row = $item->{$id}{y};
        }
    } elsif ($orientation == 4) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{x} - $speed);
            $target_row = ($item->{$id}{y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = $item->{$id}{x};
            $target_row = ($item->{$id}{y} + $speed);
        }
    } elsif ($orientation == 5) {
        if ($line eq 'even') {
            $target_col = $item->{$id}{x};
            $target_row = ($item->{$id}{y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{x} + $speed);
            $target_row = ($item->{$id}{y} + $speed);
        }
    }
    
    if ($target_col < 0) { $target_col = 0; }
    if ($target_col > 22) { $target_col = 22; }
    if ($target_row < 0) { $target_row = 0; }
    if ($target_row > 20) { $target_row = 20; }

   	return($target_col,$target_row);
}

# Predict move based on next position/orientation/speed
sub predict2 {
	my $item = shift;
    my $id = shift;
    my $speed = $item->{$id}{speed};
    my $orientation = $item->{$id}{orientation};
    my $target_col;
    my $target_row;
    my $line;
    if ($item->{$id}{next_x} % 2 == 0) { $line = "even"; }
    if ($item->{$id}{next_x} % 2 == 1) { $line = "odd"; }
    
    if ($orientation == 0) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{next_x} + $speed);
            $target_row = $item->{$id}{next_y};
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{next_x} + $speed);
            $target_row = $item->{$id}{next_y};
        }
    } elsif ($orientation == 1) {
        if ($line eq 'even') {
            $target_col = $item->{$id}{next_x};
            $target_row = ($item->{$id}{next_y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{next_x} + $speed);
            $target_row = ($item->{$id}{next_y} - $speed);
        }
    } elsif ($orientation == 2) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{next_x} - $speed);
            $target_row = ($item->{$id}{next_y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = $item->{$id}{next_x};
            $target_row = ($item->{$id}{next_y} - $speed);
        }
    } elsif ($orientation == 3) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{next_x} - $speed);
            $target_row = $item->{$id}{next_y};
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{next_x} - $speed);
            $target_row = $item->{$id}{next_y};
        }
    } elsif ($orientation == 4) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{next_x} - $speed);
            $target_row = ($item->{$id}{next_y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = $item->{$id}{next_x};
            $target_row = ($item->{$id}{next_y} + $speed);
        }
    } elsif ($orientation == 5) {
        if ($line eq 'even') {
            $target_col = $item->{$id}{next_x};
            $target_row = ($item->{$id}{next_y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{next_x} + $speed);
            $target_row = ($item->{$id}{next_y} + $speed);
        }
    }
    
    if ($target_col < 0) { $target_col = 0; }
    if ($target_col > 22) { $target_col = 22; }
    if ($target_row < 0) { $target_row = 0; }
    if ($target_row > 20) { $target_row = 20; }

   	return($target_col,$target_row);
}

# Predict move based on following round position/orientation/speed
sub predict3 {
	my $item = shift;
    my $id = shift;
    my $speed = $item->{$id}{speed};
    my $orientation = $item->{$id}{orientation};
    my $target_col;
    my $target_row;
    my $line;
    if ($item->{$id}{nextnext_x} % 2 == 0) { $line = "even"; }
    if ($item->{$id}{nextnext_x} % 2 == 1) { $line = "odd"; }
    
    if ($orientation == 0) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{nextnext_x} + $speed);
            $target_row = $item->{$id}{nextnext_y};
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{nextnext_x} + $speed);
            $target_row = $item->{$id}{nextnext_y};
        }
    } elsif ($orientation == 1) {
        if ($line eq 'even') {
            $target_col = $item->{$id}{nextnext_x};
            $target_row = ($item->{$id}{nextnext_y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{nextnext_x} + $speed);
            $target_row = ($item->{$id}{nextnext_y} - $speed);
        }
    } elsif ($orientation == 2) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{nextnext_x} - $speed);
            $target_row = ($item->{$id}{nextnext_y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = $item->{$id}{nextnext_x};
            $target_row = ($item->{$id}{nextnext_y} - $speed);
        }
    } elsif ($orientation == 3) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{nextnext_x} - $speed);
            $target_row = $item->{$id}{nextnext_y};
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{nextnext_x} - $speed);
            $target_row = $item->{$id}{nextnext_y};
        }
    } elsif ($orientation == 4) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{nextnext_x} - $speed);
            $target_row = ($item->{$id}{nextnext_y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = $item->{$id}{nextnext_x};
            $target_row = ($item->{$id}{nextnext_y} + $speed);
        }
    } elsif ($orientation == 5) {
        if ($line eq 'even') {
            $target_col = $item->{$id}{nextnext_x};
            $target_row = ($item->{$id}{nextnext_y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{nextnext_x} + $speed);
            $target_row = ($item->{$id}{nextnext_y} + $speed);
        }
    }
    
    if ($target_col < 0) { $target_col = 0; }
    if ($target_col > 22) { $target_col = 22; }
    if ($target_row < 0) { $target_row = 0; }
    if ($target_row > 20) { $target_row = 20; }

   	return($target_col,$target_row);
}

# Save the ship-coordinates
sub shipcoordinates {
	my $item = shift;
    my $id = shift;
    my $orientation = $item->{$id}{orientation};
    my $target_col;
    my $target_row;
    my $line;
    my $distance = 1;
  	my $location = 'front';
    
    if ($item->{$id}{x} % 2 == 0) { $line = "even"; }
    if ($item->{$id}{x} % 2 == 1) { $line = "odd"; }

	START:

	# Just turn around the orientation to get back coords
	if ($location eq 'back') {
		$distance = -2;
		if ($orientation == 0) {
			$orientation = 3;
		} elsif ($orientation == 1) {
			$orientation = 4;
		} elsif ($orientation == 2) {
			$orientation = 5;
		} elsif ($orientation == 3) {
			$orientation = 0;
		} elsif ($orientation == 4) {
			$orientation = 1;
		} elsif ($orientation == 5) {
			$orientation = 2;
		}
	}

    if ($orientation == 0) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{x} + $distance);
            $target_row = $item->{$id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{x} + $distance);
            $target_row = $item->{$id}{y};
        }
    } elsif ($orientation == 1) {
        if ($line eq 'even') {
            $target_col = $item->{$id}{x};
            $target_row = ($item->{$id}{y} - $distance);
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{x} + $distance);
            $target_row = ($item->{$id}{y} - $distance);
        }
    } elsif ($orientation == 2) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{x} - $distance);
            $target_row = ($item->{$id}{y} - $distance);
        } elsif ($line eq 'odd') {
            $target_col = $item->{$id}{x};
            $target_row = ($item->{$id}{y} - $distance);
        }
    } elsif ($orientation == 3) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{x} - $distance);
            $target_row = $item->{$id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{x} - $distance);
            $target_row = $item->{$id}{y};
        }
    } elsif ($orientation == 4) {
        if ($line eq 'even') {
            $target_col = ($item->{$id}{x} - $distance);
            $target_row = ($item->{$id}{y} + $distance);
        } elsif ($line eq 'odd') {
            $target_col = $item->{$id}{x};
            $target_row = ($item->{$id}{y} + $distance);
        }
    } elsif ($orientation == 5) {
        if ($line eq 'even') {
            $target_col = $item->{$id}{x};
            $target_row = ($item->{$id}{y} + $distance);
        } elsif ($line eq 'odd') {
            $target_col = ($item->{$id}{x} + $distance);
            $target_row = ($item->{$id}{y} + $distance);
        }
    }

    if ($target_col < 0) { $target_col = 0; }
    if ($target_col > 22) { $target_col = 22; }
    if ($target_row < 0) { $target_row = 0; }
    if ($target_row > 20) { $target_row = 20; }

	if ($location eq 'front') {
    	$item->{$id}{hull_front_x} = $target_col;
    	$item->{$id}{hull_front_y} = $target_row;
    	$location = 'mid';
    	goto START;
	} elsif ($location eq 'mid') {
    	$item->{$id}{hull_mid_x} = $item->{$id}{x};
    	$item->{$id}{hull_mid_y} = $item->{$id}{y};
    	$location = 'back';
    	goto START;
    } elsif ($location eq 'back') {
    	$item->{$id}{hull_back_x} = $target_col;
    	$item->{$id}{hull_back_y} = $target_row;
    }
}

# Find the next enemy ship
sub findtarget {
    my $ship_id = shift;
    my $enemies = $ship{$ship_id}{enemies};
    foreach my $enemy_id (sort {%$enemies{$a} <=> %$enemies{$b}} keys %$enemies) {
        if (($ship{$ship_id}{enemies}{$enemy_id} < 11) and (($persistent{ships}{$ship_id}{shot} + 1) < $tick)) {
            $ship{$ship_id}{enemy} = "$enemy_id";
            last;
        } elsif (!$ship{$ship_id}{nextrum}) {
            $ship{$ship_id}{enemy} = "$enemy_id";
            last;
        }
    }
}

# Find the next rum keg
sub findnextrum {
    my $ship_id = shift;
    my $rumkegs = $ship{$ship_id}{kegs};
    foreach my $rum_id (sort {%$rumkegs{$a} <=> %$rumkegs{$b}} keys %$rumkegs) {
        if ($persistent{rum}{$rum_id}{trackedby} == $ship_id) {
            $ship{$ship_id}{nextrum} = "$rum_id";
            last;
        } else {
            next;
        }
    }

    foreach my $rum_id (sort {%$rumkegs{$a} <=> %$rumkegs{$b}} keys %$rumkegs) {
        if ((!$ship{$ship_id}{nextrum}) and ($persistent{rum}{$rum_id}{trackedby} == 1337)) {
       		$persistent{rum}{$rum_id}{trackedby} = $ship_id;
           	$ship{$ship_id}{nextrum} = "$rum_id";
           	last;
	    } else {
            next;
        }
    }
}

# Avoid mines
sub avoidmine {
    my $ship_id = shift;
    my $mines = $ship{$ship_id}{mines};
    foreach my $mine_id (sort {%$mines{$a} <=> %$mines{$b}} keys %$mines) {
        if (($ship{$ship_id}{nextnextnext_x} == $mine{$mine_id}{x}) and ($ship{$ship_id}{nextnextnext_y} == $mine{$mine_id}{y})) {
        	return "true";            
        }
    }
}

# Find the next mine
sub findmine {
    my $ship_id = shift;
    my $mines = $ship{$ship_id}{mines};
    foreach my $mine_id (sort {%$mines{$a} <=> %$mines{$b}} keys %$mines) {
        if ($persistent{mines}{$mine_id}{shot} eq 'false') {
            if ((($ship{$ship_id}{mines}{$mine_id} > 2) or ($ship{$ship_id}{mines}{$mine_id} < 6)) and (($persistent{ships}{$ship_id}{shot} + 1) < $tick) and (!$ship{$ship_id}{enemy})) {
            	$persistent{mines}{$mine_id}{shot} = 'true';
                $ship{$ship_id}{mine} = "$mine_id";
                last;
            }
        }
    }
}

# Shot function
sub shoot {
	my $ship_id = shift;
	my $shot;
	my $hit_x;
	my $hit_y;
    my $enemy_id = $ship{$ship_id}{enemy};
    my $distance = $ship{$ship_id}{enemies}{$enemy_id};
    if ($distance < 6) {
	    $hit_x = $enemy{$enemy_id}{nextnext_x};
	    $hit_y = $enemy{$enemy_id}{nextnext_y};
    } else {
	    $hit_x = $enemy{$enemy_id}{nextnext_x};
	    $hit_y = $enemy{$enemy_id}{nextnext_y};
    }
        
	$persistent{ships}{$ship_id}{shot} = $tick;
    print "FIRE $hit_x $hit_y\n";
}

# Game loop
while (1) {
    my $start = time;
    $tick++;
    chomp(my $my_ship_count = <STDIN>);
    chomp(my $entity_count = <STDIN>);
    for my $i (0..$entity_count-1) {
        chomp($tokens=<STDIN>);
        my ($entity_id, $entity_type, $x, $y, $arg_1, $arg_2, $arg_3, $arg_4) = split(/ /,$tokens);

        if ($entity_type eq 'SHIP') {
            if ($arg_4 == 1) {
            	
            	# Define our Ships
                if ($entity_id == 0) { $entity_id = "100"; }
                $ship{$entity_id}{x} = $x;
                $ship{$entity_id}{y} = $y;
                $ship{$entity_id}{orientation} = $arg_1;
                $ship{$entity_id}{speed} = $arg_2;
                $ship{$entity_id}{rum} = $arg_3;

                if (!$persistent{ships}{$entity_id}{shot}) {
                	$persistent{ships}{$entity_id}{shot} = "0";
                }
                
                if (!$ship{$entity_id}{hasmines}) {
                	$ship{$entity_id}{hasmines} = 5;
                }
                
                if (!$persistent{ships}{$entity_id}{speed}) {
                	$persistent{ships}{$entity_id}{speed} = 0;
                }
                
                if ($tick & 2) {
                	$persistent{ships}{$entity_id}{speed} = $ship{$entity_id}{speed};
                }

                if (!$ship{$entity_id}{stuck}) {
                	$ship{$entity_id}{stuck} = 'false';
                }
                
                if (($persistent{ships}{$entity_id}{speed} == $ship{$entity_id}{speed}) and ($ship{$entity_id}{speed} == 0)) {
                	$ship{$entity_id}{stuck} = 'true';
                } else {
                	$ship{$entity_id}{stuck} = 'false';
                }

				($ship{$entity_id}{cube_x},$ship{$entity_id}{cube_y},$ship{$entity_id}{cube_z}) = oddr2cube($x,$y);
                &shipcoordinates(\%ship,$entity_id);
                ($ship{$entity_id}{next_x},$ship{$entity_id}{next_y}) = &predict(\%ship,$entity_id);
                ($ship{$entity_id}{nextnext_x},$ship{$entity_id}{nextnext_y}) = &predict2(\%ship,$entity_id);
                ($ship{$entity_id}{nextnextnext_x},$ship{$entity_id}{nextnextnext_y}) = &predict3(\%ship,$entity_id);
                
			# Define enemy Ships
            } else {
                if ($entity_id == 0) { $entity_id = "200"; }
                $enemy{$entity_id}{x} = $x;
                $enemy{$entity_id}{y} = $y;
                ($enemy{$entity_id}{cube_x},$enemy{$entity_id}{cube_y},$enemy{$entity_id}{cube_z}) = oddr2cube($x,$y);
                $enemy{$entity_id}{orientation} = $arg_1;
                $enemy{$entity_id}{speed} = $arg_2;
                $enemy{$entity_id}{rum} = $arg_3;          
                &shipcoordinates(\%enemy,$entity_id);
                ($enemy{$entity_id}{next_x},$enemy{$entity_id}{next_y}) = &predict(\%enemy,$entity_id);
                ($enemy{$entity_id}{nextnext_x},$enemy{$entity_id}{nextnext_y}) = &predict2(\%enemy,$entity_id);
                ($enemy{$entity_id}{nextnextnext_x},$enemy{$entity_id}{nextnextnext_y}) = &predict3(\%enemy,$entity_id);
            }
            
		# Define Rum Kegs
        } elsif ($entity_type eq 'BARREL') {
            if ($entity_id == 0) { $entity_id = "300"; }
            $rum{$entity_id}{x} = $x;
            $rum{$entity_id}{y} = $y;
            ($rum{$entity_id}{cube_x},$rum{$entity_id}{cube_y},$rum{$entity_id}{cube_z}) = oddr2cube($x,$y);
            $rum{$entity_id}{amount} = $arg_1;
            if (!$persistent{rum}{$entity_id}{trackedby}) { $persistent{rum}{$entity_id}{trackedby} = 1337; }
            
		# Define Mines
        } elsif ($entity_type eq 'MINE') {
            if ($entity_id == 0) { $entity_id = "400"; }
            $mine{$entity_id}{x} = $x;
            $mine{$entity_id}{y} = $y;
            if (!$persistent{mines}{$entity_id}{shot}) { $persistent{mines}{$entity_id}{shot} = 'false'; }
            ($mine{$entity_id}{cube_x},$mine{$entity_id}{cube_y},$mine{$entity_id}{cube_z}) = oddr2cube($x,$y);
            
		# Define Cannonballs
        } elsif ($entity_type eq 'CANNONBALL') {
            if ($entity_id == 0) { $entity_id = "500"; }
            $cannonball{$entity_id}{target_x} = $x;
            $cannonball{$entity_id}{target_y} = $y;
            ($cannonball{$entity_id}{cube_target_x},$cannonball{$entity_id}{cube_target_y},$cannonball{$entity_id}{cube_target_z}) = oddr2cube($x,$y);
            $cannonball{$entity_id}{shooter} = $arg_1;
            $cannonball{$entity_id}{countdown} = $arg_2;
        }
    }
    
    # Save all items into each ships own hash
    foreach my $ship_id (sort keys %ship) {
    	# Enemies
        foreach my $enemy_id (sort keys %enemy) {
            my $ship_x = $ship{$ship_id}{x};
            my $ship_y = $ship{$ship_id}{y};
            my $ship_cube_x = $ship{$ship_id}{cube_x};
            my $ship_cube_y = $ship{$ship_id}{cube_y};
            my $ship_cube_z = $ship{$ship_id}{cube_z};
            my $enemy_x = $enemy{$enemy_id}{x};
            my $enemy_y = $enemy{$enemy_id}{y};
            my $enemy_cube_x = $enemy{$enemy_id}{cube_x};
            my $enemy_cube_y = $enemy{$enemy_id}{cube_y};
            my $enemy_cube_z = $enemy{$enemy_id}{cube_z};
            $ship{$ship_id}{enemies}{$enemy_id}{id} = $enemy_id;
            $ship{$ship_id}{enemies}{$enemy_id}{x} = $enemy{$enemy_id}{x};
            $ship{$ship_id}{enemies}{$enemy_id}{y} = $enemy{$enemy_id}{y};
            $ship{$ship_id}{enemies}{$enemy_id} = &getcubedistance($ship_cube_x,$ship_cube_y,$ship_cube_z,$enemy_cube_x,$enemy_cube_y,$enemy_cube_z);
        }

    	# Rum
        foreach my $rum_id (sort keys %rum) {
            my $ship_x = $ship{$ship_id}{x};
            my $ship_y = $ship{$ship_id}{y};
            my $rum_x = $rum{$rum_id}{x};
            my $rum_y = $rum{$rum_id}{y};
            my $ship_cube_x = $ship{$ship_id}{cube_x};
            my $ship_cube_y = $ship{$ship_id}{cube_y};
            my $ship_cube_z = $ship{$ship_id}{cube_z};
            my $rum_cube_x = $rum{$rum_id}{cube_x};
            my $rum_cube_y = $rum{$rum_id}{cube_y};
            my $rum_cube_z = $rum{$rum_id}{cube_z};
            $ship{$ship_id}{kegs}{$rum_id}{id} = $rum_id;
            $ship{$ship_id}{kegs}{$rum_id}{x} = $rum{$rum_id}{x};
            $ship{$ship_id}{kegs}{$rum_id}{y} = $rum{$rum_id}{y};
            $ship{$ship_id}{kegs}{$rum_id} = &getcubedistance($ship_cube_x,$ship_cube_y,$ship_cube_z,$rum_cube_x,$rum_cube_y,$rum_cube_z);
        }

    	# Mines
        foreach my $mine_id (sort keys %mine) {
            my $ship_x = $ship{$ship_id}{x};
            my $ship_y = $ship{$ship_id}{y};
            my $mine_x = $mine{$mine_id}{x};
            my $mine_y = $mine{$mine_id}{y};
            my $ship_cube_x = $ship{$ship_id}{cube_x};
            my $ship_cube_y = $ship{$ship_id}{cube_y};
            my $ship_cube_z = $ship{$ship_id}{cube_z};
            my $mine_cube_x = $mine{$mine_id}{cube_x};
            my $mine_cube_y = $mine{$mine_id}{cube_y};
            my $mine_cube_z = $mine{$mine_id}{cube_z};
            $ship{$ship_id}{mines}{$mine_id}{id} = $mine_id;
            $ship{$ship_id}{mines}{$mine_id}{x} = $mine{$mine_id}{x};
            $ship{$ship_id}{mines}{$mine_id}{y} = $mine{$mine_id}{y};
            $ship{$ship_id}{mines}{$mine_id} = &getcubedistance($ship_cube_x,$ship_cube_y,$ship_cube_z,$mine_cube_x,$mine_cube_y,$mine_cube_z);
        }

		# Run functions
		my $cornerslide = &cornerslide($ship_id);
		my ($shiphit,$shiphit_cmd) = &avoidhit($ship_id);
		my $minehit = &avoidmine($ship_id);
        &findnextrum($ship_id);
        &findtarget($ship_id);
        &findmine($ship_id);

		# Run actions
        if ($minehit) {
        	print "MOVE 10 12 ARGH\n";

        } elsif ($cornerslide) {
        	print "$cornerslide\n";

    	} elsif ($shiphit eq 'true') {
        	print "$shiphit_cmd\n";

        } elsif ($ship{$ship_id}{mine}) {
            my $target_id = $ship{$ship_id}{mine};
            my $target_x = $mine{$target_id}{x};
            my $target_y = $mine{$target_id}{y};
            $persistent{ships}{$ship_id}{shot} = $tick;
            print "FIRE $target_x $target_y\n";

        } elsif (!$ship{$ship_id}{nextrum}) {
            my $target_id = $ship{$ship_id}{enemy};
            my $target_x = $enemy{$target_id}{x};
            my $target_y = $enemy{$target_id}{y};
            my $predict_x = $enemy{$target_id}{next_x};
            my $predict_y = $enemy{$target_id}{next_y};
            my $enemydistance = $ship{$ship_id}{enemies}{$target_id};
            if ($enemydistance < 6) {
                $persistent{ships}{$ship_id}{shot} = $tick;
                print "FIRE $predict_x $predict_y\n";
            } else {
                print "MOVE $target_x $target_y\n";
            }

        } elsif ($ship{$ship_id}{enemy}) {
            &shoot($ship_id);
        } elsif ($ship{$ship_id}{nextrum}) {
            my $rum_id = $ship{$ship_id}{nextrum};
            my $rum_x = $rum{$rum_id}{x};
            my $rum_y = $rum{$rum_id}{y};
           	print "MOVE $rum_x $rum_y\n";

        } else {
                print "WAIT\n";  
        }
    }
    
    
    # Debug #
    #print STDERR Dumper(%ship);
    #print STDERR Dumper(%persistent);
    #print STDERR Dumper(%mine);
    #print STDERR Dumper(%cannonball);
    #print STDERR Dumper(%enemy);
    
    # Undef hashes before next round starts
    undef %rum;
    %rum = ();
    undef %ship;
    %ship = ();
    undef %enemy;
    %enemy = ();
    undef %mine;
    %mine = ();
    undef %cannonball;
    %cannonball = ();

	# Print duration per round
    my $duration = time - $start;
    print STDERR "Tick: $tick - Runtime: $duration\n";
}