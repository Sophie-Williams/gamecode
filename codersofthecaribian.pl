use strict;
use warnings;
#use diagnostics;
use 5.20.1;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
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
my $shipcount;

sub oddr2cube {
    my $col = shift;
    my $row = shift;
    my $x = $col - ($row - ($row & 1)) / 2;
    my $z = $row;
    my $y = (-$x - $z);
    return($x,$y,$z);
}

sub cube2oddr {
    my $x = shift;
    my $y = shift;
    my $z = shift;
    my $col = $x + ($z - ($z & 1)) / 2;
    my $row = $z;
    return($col,$row);
}

sub cornermove {
    my $ship_id = shift;
    my $x = $ship{$ship_id}{x};
    my $y = $ship{$ship_id}{y};
    # PORT = left
    # STARBOARD = right

    if (($x == 0) and ($y == 0)){ # Top Left
        if (($ship{$ship_id}{orientation} == 1) or ($ship{$ship_id}{orientation} == 2) or ($ship{$ship_id}{orientation} == 3) or ($ship{$ship_id}{orientation} == 4)) {
            return("PORT");
        }
    } elsif (($x == 0) and ($y == 20)){ # Bottom Left
        if (($ship{$ship_id}{orientation} == 2) or ($ship{$ship_id}{orientation} == 3) or ($ship{$ship_id}{orientation} == 4) or ($ship{$ship_id}{orientation} == 5)) {
            return("PORT");
        }
    } elsif (($x == 22) and ($y == 0)){ # Top Right
        if (($ship{$ship_id}{orientation} == 0) or ($ship{$ship_id}{orientation} == 1) or ($ship{$ship_id}{orientation} == 2) or ($ship{$ship_id}{orientation} == 5)) {
            return("PORT");
        }
    } elsif (($x == 22) and ($y == 20)){ # Bottom Right
        if (($ship{$ship_id}{orientation} == 0) or ($ship{$ship_id}{orientation} == 1) or ($ship{$ship_id}{orientation} == 4) or ($ship{$ship_id}{orientation} == 5)) {
            return("PORT");
        }
    } elsif ($x == 0) { # Left
        if ($ship{$ship_id}{orientation} == 2) {
            return("STARBOARD");
        } elsif (($ship{$ship_id}{orientation} == 3) or ($ship{$ship_id}{orientation} == 4)) {
        	return("PORT");
        }
    } elsif ($x == 22) { # Right
        if ($ship{$ship_id}{orientation} == 1) {
            return("PORT");
        } elsif (($ship{$ship_id}{orientation} == 0) or ($ship{$ship_id}{orientation} == 5)) {
        	return("STARBOARD");
        }
    } elsif ($y == 0) { # Top
        if ($ship{$ship_id}{orientation} == 2) {
            return("PORT");
        } elsif ($ship{$ship_id}{orientation} == 1) {
        	return("STARBOARD");
        }
    } elsif ($y == 20) { # Bottom
        if ($ship{$ship_id}{orientation} == 4) {
            return("STARBOARD");
        } elsif ($ship{$ship_id}{orientation} == 5) {
        	return("PORT");
        }
    }
}    

sub cornerslide {
    my $ship_id = shift;
    my $x = $ship{$ship_id}{x};
    my $y = $ship{$ship_id}{y};
    # PORT = left
    # STARBOARD = right

	if ($ship{$ship_id}{speed} > 1) {
	    if (($x < 1) or ($y < 1)) {
	        if (($ship{$ship_id}{orientation} == 1) or ($ship{$ship_id}{orientation} == 2) or ($ship{$ship_id}{orientation} == 3) or ($ship{$ship_id}{orientation} == 4)) {
	            return("PORT");
	        }
	    } elsif (($x > 19) or ($y > 21)) {
	        if (($ship{$ship_id}{orientation} == 2) or ($ship{$ship_id}{orientation} == 3) or ($ship{$ship_id}{orientation} == 4) or ($ship{$ship_id}{orientation} == 5)) {
	            return("STARBOARD");
	        }
	    }
	}    
}

sub predictnext {
    my $ship_id = shift;
    my $speed = $ship{$ship_id}{speed};
    my $orientation = $ship{$ship_id}{orientation};
    my $target_col;
    my $target_row;
    my $line;
    if ($ship{$ship_id}{x} % 2 == 0) { $line = "even"; }
    if ($ship{$ship_id}{x} % 2 == 1) { $line = "odd"; }

    if ($orientation == 0) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = $ship{$ship_id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = $ship{$ship_id}{y};
        }
    } elsif ($orientation == 1) {
        if ($line eq 'even') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = ($ship{$ship_id}{y} - $speed);
        }
    } elsif ($orientation == 2) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = ($ship{$ship_id}{y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} - $speed);
        }
    } elsif ($orientation == 3) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = $ship{$ship_id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = $ship{$ship_id}{y};
        }
    } elsif ($orientation == 4) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = ($ship{$ship_id}{y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} + $speed);
        }
    } elsif ($orientation == 5) {
        if ($line eq 'even') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = ($ship{$ship_id}{y} + $speed);
        }
    }
    
    if ($target_col < 0) { $target_col = 0; }
    if ($target_col > 22) { $target_col = 22; }
    if ($target_row < 0) { $target_row = 0; }
    if ($target_row > 20) { $target_row = 20; }
    
    return($target_col,$target_row);
}

sub aim {
    my $ship_id = shift;
    my $enemy_id = shift;
    my $speed = $enemy{$enemy_id}{speed};
    my $orientation = $enemy{$enemy_id}{orientation};
    my $distance = $ship{$ship_id}{enemies}{$enemy_id};
    my $target_col;
    my $target_row;
    my $line;
    if ($enemy{$enemy_id}{x} % 2 == 0) { $line = "even"; }
    if ($enemy{$enemy_id}{x} % 2 == 1) { $line = "odd"; }
    
    my $reachtime = (2 + $distance) / 3;
    my $speeddiff = ($speed + $reachtime);
    $speeddiff = int($speeddiff);
    if ($speed == 0) { $speeddiff = 0; }

    if ($orientation == 0) {
        if ($line eq 'even') {
            $target_col = ($enemy{$enemy_id}{x} + $speeddiff);
            $target_row = $enemy{$enemy_id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($enemy{$enemy_id}{x} + $speeddiff);
            $target_row = $enemy{$enemy_id}{y};
        }
    } elsif ($orientation == 1) {
        if ($line eq 'even') {
            $target_col = $enemy{$enemy_id}{x};
            $target_row = ($enemy{$enemy_id}{y} - $speeddiff);
        } elsif ($line eq 'odd') {
            $target_col = ($enemy{$enemy_id}{x} + $speeddiff);
            $target_row = ($enemy{$enemy_id}{y} - $speeddiff);
        }
    } elsif ($orientation == 2) {
        if ($line eq 'even') {
            $target_col = ($enemy{$enemy_id}{x} - $speeddiff);
            $target_row = ($enemy{$enemy_id}{y} - $speeddiff);
        } elsif ($line eq 'odd') {
            $target_col = $enemy{$enemy_id}{x};
            $target_row = ($enemy{$enemy_id}{y} - $speeddiff);
        }
    } elsif ($orientation == 3) {
        if ($line eq 'even') {
            $target_col = ($enemy{$enemy_id}{x} - $speeddiff);
            $target_row = $enemy{$enemy_id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($enemy{$enemy_id}{x} - $speeddiff);
            $target_row = $enemy{$enemy_id}{y};
        }
    } elsif ($orientation == 4) {
        if ($line eq 'even') {
            $target_col = ($enemy{$enemy_id}{x} - $speeddiff);
            $target_row = ($enemy{$enemy_id}{y} + $speeddiff);
        } elsif ($line eq 'odd') {
            $target_col = $enemy{$enemy_id}{x};
            $target_row = ($enemy{$enemy_id}{y} + $speeddiff);
        }
    } elsif ($orientation == 5) {
        if ($line eq 'even') {
            $target_col = $enemy{$enemy_id}{x};
            $target_row = ($enemy{$enemy_id}{y} + $speeddiff);
        } elsif ($line eq 'odd') {
            $target_col = ($enemy{$enemy_id}{x} + $speeddiff);
            $target_row = ($enemy{$enemy_id}{y} + $speeddiff);
        }
    }
    
    if ($target_col < 0) { $target_col = 0; }
    if ($target_col > 22) { $target_col = 22; }
    if ($target_row < 0) { $target_row = 0; }
    if ($target_row > 20) { $target_row = 20; }
    
    my $ship_front_x = $ship{$ship_id}{hull_front_x};
    my $ship_front_y = $ship{$ship_id}{hull_front_y};
    my $ship_mid_x = $ship{$ship_id}{hull_mid_x};
    my $ship_mid_y = $ship{$ship_id}{hull_mid_y};
    my $ship_back_x = $ship{$ship_id}{hull_back_x};
    my $ship_back_y = $ship{$ship_id}{hull_back_y};
    
    if (($ship{$ship_id}{speed} == 0) or ($ship{$ship_id}{stuck} eq 'true')) {
    	$ship{$ship_id}{suicide} = 'false';
    	return($target_col,$target_row);    	
    } elsif ((($target_col != $ship_front_x) and ($target_row != $ship_front_y)) and (($target_col != $ship_mid_x) and ($target_row != $ship_mid_y)) and (($target_col != $ship_back_x) and ($target_row != $ship_back_y))) {
    	$ship{$ship_id}{suicide} = 'false';
        return($target_col,$target_row);
    } else {
    	$ship{$ship_id}{suicide} = 'true';
    	return($target_col,$target_row);
    }
}

sub avoidhit {
	my $ship_id = shift;
    my $ship_front_x = $ship{$ship_id}{hull_front_x};
    my $ship_front_y = $ship{$ship_id}{hull_front_y};
    my $ship_mid_x = $ship{$ship_id}{hull_mid_x};
    my $ship_mid_y = $ship{$ship_id}{hull_mid_y};
    my $ship_back_x = $ship{$ship_id}{hull_back_x};
    my $ship_back_y = $ship{$ship_id}{hull_back_y};
    my $ship_next_x = $ship{$ship_id}{next_x};
    my $ship_next_y = $ship{$ship_id}{next_y};
    
    foreach my $cannonball_id (sort keys %cannonball) {
	    my $target_x = $cannonball{$cannonball_id}{target_x};
	    my $target_y = $cannonball{$cannonball_id}{target_y};

		if ($ship{$ship_id}{stuck} eq 'true') {
			
		} elsif ((($cannonball{$cannonball_id}{countdown} == 1) or ($cannonball{$cannonball_id}{countdown} == 2)) and (($target_x == $ship_front_x) and ($target_y == $ship_front_y))) {
            if ($ship{$ship_id}{speed} > 1) {
				return("true","SLOWER");
            } else {
                return("true","FASTER");
            }
	    } elsif ((($cannonball{$cannonball_id}{countdown} == 1) or ($cannonball{$cannonball_id}{countdown} == 2)) and (($target_x == $ship_mid_x) and ($target_y == $ship_mid_y))) {
            if ($ship{$ship_id}{speed} > 1) {
    	    	if (int(rand(2)) == 0) {
    	    		return("true","PORT");
    	    	} else {
    	    		return("true","STARBOARD");
    	    	}
            } else {
                return("true","FASTER");
            }
	    } elsif ((($cannonball{$cannonball_id}{countdown} == 1) and ($ship{$ship_id}{speed} > 0)) and (($target_x == $ship_next_x) and ($target_y == $ship_next_y))) {
            if ($ship{$ship_id}{speed} > 1) {
    	    	if (int(rand(2)) == 0) {
    	    		return("true","PORT");
    	    	} else {
    	    		return("true","STARBOARD");
    	    	}
            } else {
                return("true","SLOWER");
            }
	    } elsif ((($cannonball{$cannonball_id}{countdown} == 1) and ($ship{$ship_id}{speed} == 0)) and (($target_x == $ship_back_x) and ($target_y == $ship_back_y))) {
	        return("true","FASTER");
	    }
    }
}

sub getshipfront {
    my $ship_id = shift;
    my $speed = $ship{$ship_id}{speed};
    my $orientation = $ship{$ship_id}{orientation};
    my $target_col;
    my $target_row;
    my $line;
    if ($ship{$ship_id}{x} % 2 == 0) { $line = "even"; }
    if ($ship{$ship_id}{x} % 2 == 1) { $line = "odd"; }
    if ($speed == 0) { $speed = 1; }

    if ($orientation == 0) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = $ship{$ship_id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = $ship{$ship_id}{y};
        }
    } elsif ($orientation == 1) {
        if ($line eq 'even') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = ($ship{$ship_id}{y} - $speed);
        }
    } elsif ($orientation == 2) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = ($ship{$ship_id}{y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} - $speed);
        }
    } elsif ($orientation == 3) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = $ship{$ship_id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = $ship{$ship_id}{y};
        }
    } elsif ($orientation == 4) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = ($ship{$ship_id}{y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} + $speed);
        }
    } elsif ($orientation == 5) {
        if ($line eq 'even') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = ($ship{$ship_id}{y} + $speed);
        }
    }
    
    if ($target_col < 0) { $target_col = 0; }
    if ($target_col > 22) { $target_col = 22; }
    if ($target_row < 0) { $target_row = 0; }
    if ($target_row > 20) { $target_row = 20; }

	return($target_col,$target_row);    
}

sub getshipback {
    my $ship_id = shift;
    my $speed = $ship{$ship_id}{speed};
    my $orientation = $ship{$ship_id}{orientation};
    my $target_col;
    my $target_row;
    my $line;
    if ($ship{$ship_id}{x} % 2 == 0) { $line = "even"; }
    if ($ship{$ship_id}{x} % 2 == 1) { $line = "odd"; }
    if ($speed == 0) { $speed = 1; }

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

    if ($orientation == 0) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = $ship{$ship_id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = $ship{$ship_id}{y};
        }
    } elsif ($orientation == 1) {
        if ($line eq 'even') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = ($ship{$ship_id}{y} - $speed);
        }
    } elsif ($orientation == 2) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = ($ship{$ship_id}{y} - $speed);
        } elsif ($line eq 'odd') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} - $speed);
        }
    } elsif ($orientation == 3) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = $ship{$ship_id}{y};
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = $ship{$ship_id}{y};
        }
    } elsif ($orientation == 4) {
        if ($line eq 'even') {
            $target_col = ($ship{$ship_id}{x} - $speed);
            $target_row = ($ship{$ship_id}{y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} + $speed);
        }
    } elsif ($orientation == 5) {
        if ($line eq 'even') {
            $target_col = $ship{$ship_id}{x};
            $target_row = ($ship{$ship_id}{y} + $speed);
        } elsif ($line eq 'odd') {
            $target_col = ($ship{$ship_id}{x} + $speed);
            $target_row = ($ship{$ship_id}{y} + $speed);
        }
    }
    
    if ($target_col < 0) { $target_col = 0; }
    if ($target_col > 22) { $target_col = 22; }
    if ($target_row < 0) { $target_row = 0; }
    if ($target_row > 20) { $target_row = 20; }

	return($target_col,$target_row);    
}


sub findtarget {
    my $ship_id = shift;
    my $enemies = $ship{$ship_id}{enemies};
    foreach my $enemy_id (sort {%$enemies{$a} <=> %$enemies{$b}} keys %$enemies) {
        if (($ship{$ship_id}{enemies}{$enemy_id} < 4) and (($persistent{ships}{$ship_id}{shot} + $persistent{ships}{$ship_id}{shottime}) < $tick)) {
        	$persistent{ships}{$ship_id}{shottime} = 1;
            $ship{$ship_id}{enemy} = "$enemy_id";
            last;
        } elsif (($ship{$ship_id}{enemies}{$enemy_id} < 11) and (($persistent{ships}{$ship_id}{shot} + $persistent{ships}{$ship_id}{shottime}) < $tick)) {
        	$persistent{ships}{$ship_id}{shottime} = 2;
            $ship{$ship_id}{enemy} = "$enemy_id";
            last;
        } elsif (!$ship{$ship_id}{nextrum}) {
            $ship{$ship_id}{enemy} = "$enemy_id";
            last;
        }
    }
}

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

sub findmine {
    my $ship_id = shift;
    my $mines = $ship{$ship_id}{mines};
    foreach my $mine_id (sort {%$mines{$a} <=> %$mines{$b}} keys %$mines) {
        if (!$persistent{mines}{$mine_id}{trackedby}) {
            if ((($ship{$ship_id}{mines}{$mine_id} > 3) or ($ship{$ship_id}{mines}{$mine_id} < 6)) and (($persistent{ships}{$ship_id}{shot} + 1) < $tick) and (!$ship{$ship_id}{enemy})) {
            	$persistent{mines}{$mine_id}{trackedby} = $ship_id;
                $ship{$ship_id}{mine} = "$mine_id";
                last;
            }
        }
    }
}

sub getcubedistance {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    my $distance = (((($x1 - $x2) * ($x1 - $x2))) + ((($y1 - $y2) * ($y1 - $y2))));
    $distance = sqrt($distance);
    return int($distance);
}

sub getcubedistance {
    my $cube_x1 = shift;
    my $cube_y1 = shift;
    my $cube_z1 = shift;
    my $cube_x2 = shift;
    my $cube_y2 = shift;
    my $cube_z2 = shift;
    my $cubedistance = (abs($cube_x1 - $cube_x2) + abs($cube_y1 - $cube_y2) + abs($cube_z1 - $cube_z2)) / 2;
}

sub attackmode {
    my $ship_id = shift;
    my $target_id = $ship{$ship_id}{enemy};
    my $target_x = $enemy{$target_id}{x};
    my $target_y = $enemy{$target_id}{y};
    my ($predict_x,$predict_y) = &aim($ship_id,$target_id);
    my $enemydistance = $ship{$ship_id}{enemies}{$target_id};
    if ($ship{$ship_id}{speed} > 1) {
    	if (int(rand(2)) == 0) {
    		print "PORT\n";
    	} else {
    		print"STARBOARD\n";
    	}
    } elsif ($enemydistance < 10) { #and ($ship{$ship_id}{suicide} ne 'false')) {
       	$persistent{ships}{$ship_id}{shot} = $tick;
       	print "FIRE $predict_x $predict_y EAT THIS\n";
    } else {
        print "MOVE $target_x $target_y\n";
    }
}


sub shipaction {
    my $ship_id = shift;
	my $cornercheck = &cornermove($ship_id);
	my $cornerslide = &cornerslide($ship_id);
	my ($shiphit,$shiphit_cmd) = &avoidhit($ship_id);
    &findnextrum($ship_id);
    &findtarget($ship_id);
    &findmine($ship_id);
    
    
    if ($cornerslide) {
        print "$cornercheck\n";
    } elsif ($cornercheck) {
        print "$cornercheck\n";
    } elsif ($shiphit eq 'true') {
    	print "$shiphit_cmd INCOMING\n";
    } elsif ($ship{$ship_id}{mine}) {
        my $target_id = $ship{$ship_id}{mine};
        my $target_x = $mine{$target_id}{x};
        my $target_y = $mine{$target_id}{y};
        $persistent{ships}{$ship_id}{shot} = $tick;
        print "FIRE $target_x $target_y\n";
    } elsif (!$ship{$ship_id}{nextrum}) {
        &attackmode($ship_id);
    } elsif (($ship{$ship_id}{enemy}) and ($ship{$ship_id}{suicide} eq 'false')) {
        my $target_id = $ship{$ship_id}{enemy};
        my ($predict_x,$predict_y) = &aim($ship_id,$target_id);
        $persistent{ships}{$ship_id}{shot} = $tick;
        print "FIRE $predict_x $predict_y EAT THIS\n";
    } elsif ($ship{$ship_id}{nextrum}) {
        my $rum_id = $ship{$ship_id}{nextrum};
        my $rum_x = $rum{$rum_id}{x};
        my $rum_y = $rum{$rum_id}{y};
        
        my $distance = $ship{$ship_id}{kegs}{$rum_id};
        if ($distance == 0) {
        	print "FASTER GO GO GO\n";
        } else {
        	print "MOVE $rum_x $rum_y\n";
        }
    } else {
        print "WAIT\n";  
    }
}

# game loop
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
                if ($entity_id == 0) { $entity_id = "100"; }
                $ship{$entity_id}{x} = $x;
                $ship{$entity_id}{y} = $y;
                ($ship{$entity_id}{cube_x},$ship{$entity_id}{cube_y},$ship{$entity_id}{cube_z}) = oddr2cube($x,$y);
                $ship{$entity_id}{orientation} = $arg_1;
                $ship{$entity_id}{speed} = $arg_2;
                $ship{$entity_id}{rum} = $arg_3;
                ($ship{$entity_id}{next_x},$ship{$entity_id}{next_y}) = predictnext($entity_id);
                ($ship{$entity_id}{hull_front_x},$ship{$entity_id}{hull_front_y}) = &getshipfront($entity_id);
                ($ship{$entity_id}{hull_back_x},$ship{$entity_id}{hull_back_y}) = &getshipback($entity_id);
                $ship{$entity_id}{hull_mid_x} = $x;
                $ship{$entity_id}{hull_mid_y} = $y;
                if (!$persistent{ships}{$entity_id}{shot}) { $persistent{ships}{$entity_id}{shot} = "0"; }
                if (!$persistent{ships}{$entity_id}{shottime}) { $persistent{ships}{$entity_id}{shottime} = 2; }
                if (!$persistent{ships}{$entity_id}{speed}) { $persistent{ships}{$entity_id}{speed} = 0; }
                if ($tick & 2) {
                	$persistent{ships}{$entity_id}{speed} = $ship{$entity_id}{speed};
                }
                if (($persistent{ships}{$entity_id}{speed} == $ship{$entity_id}{speed}) and ($ship{$entity_id}{speed} == 0)) {
                	$ship{$entity_id}{stuck} = 'true';
                } else {
                	$ship{$entity_id}{stuck} = 'false';
                }
                
                if (!$ship{$entity_id}{hasmines}) { $ship{$entity_id}{hasmines} = 5; }
                if (!$ship{$entity_id}{suicide}) { $ship{$entity_id}{suicide} = 'false'; }
            } else {
                if ($entity_id == 0) { $entity_id = "200"; }
                $enemy{$entity_id}{x} = $x;
                $enemy{$entity_id}{y} = $y;
                ($enemy{$entity_id}{cube_x},$enemy{$entity_id}{cube_y},$enemy{$entity_id}{cube_z}) = oddr2cube($x,$y);
                $enemy{$entity_id}{orientation} = $arg_1;
                $enemy{$entity_id}{speed} = $arg_2;
                $enemy{$entity_id}{rum} = $arg_3;            
            }
            
        } elsif ($entity_type eq 'BARREL') {
            if ($entity_id == 0) { $entity_id = "300"; }
            $rum{$entity_id}{x} = $x;
            $rum{$entity_id}{y} = $y;
            ($rum{$entity_id}{cube_x},$rum{$entity_id}{cube_y},$rum{$entity_id}{cube_z}) = oddr2cube($x,$y);
            $rum{$entity_id}{amount} = $arg_1;
            if (!$persistent{rum}{$entity_id}{trackedby}) { $persistent{rum}{$entity_id}{trackedby} = 1337; }
            
            
        } elsif ($entity_type eq 'MINE') {
            if ($entity_id == 0) { $entity_id = "400"; }
            $mine{$entity_id}{x} = $x;
            $mine{$entity_id}{y} = $y;
            if (!$persistent{mines}{$entity_id}{shot}) { $persistent{mines}{$entity_id}{shot} = 'false'; }
            ($mine{$entity_id}{cube_x},$mine{$entity_id}{cube_y},$mine{$entity_id}{cube_z}) = oddr2cube($x,$y);
            
        } elsif ($entity_type eq 'CANNONBALL') {
            if ($entity_id == 0) { $entity_id = "500"; }
            $cannonball{$entity_id}{target_x} = $x;
            $cannonball{$entity_id}{target_y} = $y;
            ($cannonball{$entity_id}{cube_target_x},$cannonball{$entity_id}{cube_target_y},$cannonball{$entity_id}{cube_target_z}) = oddr2cube($x,$y);
            $cannonball{$entity_id}{shooter} = $arg_1;
            $cannonball{$entity_id}{countdown} = $arg_2;
        }
    }
    
    foreach my $ship_id (sort keys %ship) {
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

        foreach my $rum_id (sort keys %rum) {
            my $ship_x = $ship{$ship_id}{x};
            my $ship_y = $ship{$ship_id}{y};
            my $rum_x = $rum{$rum_id}{x};
            my $rum_y = $rum{$rum_id}{y};
            $ship{$ship_id}{kegs}{$rum_id}{id} = $rum_id;
            $ship{$ship_id}{kegs}{$rum_id}{x} = $rum{$rum_id}{x};
            $ship{$ship_id}{kegs}{$rum_id}{y} = $rum{$rum_id}{y};
            $ship{$ship_id}{kegs}{$rum_id} = &getcubedistance($ship_x,$ship_y,$rum_x,$rum_y);
        }

        foreach my $mine_id (sort keys %mine) {
            my $ship_x = $ship{$ship_id}{x};
            my $ship_y = $ship{$ship_id}{y};
            my $mine_x = $mine{$mine_id}{x};
            my $mine_y = $mine{$mine_id}{y};
            $ship{$ship_id}{mines}{$mine_id}{id} = $mine_id;
            $ship{$ship_id}{mines}{$mine_id}{x} = $mine{$mine_id}{x};
            $ship{$ship_id}{mines}{$mine_id}{y} = $mine{$mine_id}{y};
            $ship{$ship_id}{mines}{$mine_id} = &getcubedistance($ship_x,$ship_y,$mine_x,$mine_y);
        }
        
        foreach my $ship_id (sort keys %ship) { $shipcount++; }
        

        &shipaction($ship_id);
    }
    
    #print STDERR Dumper(%ship);
    #print STDERR Dumper(%mine);
    #print STDERR Dumper(%cannonball);
    #print STDERR Dumper(%enemy);
    #print STDERR Dumper(%persistent);
    
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

    my $duration = time - $start;
    print STDERR "Loop: $tick - Global Runtime: $duration seconds.\n";
}