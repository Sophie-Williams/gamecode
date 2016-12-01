use strict;
use warnings;
#use diagnostics;
use 5.20.1;
use Math::Trig;

no warnings "experimental::smartmatch";
select(STDOUT); $| = 1; # DO NOT REMOVE


# Game Specific Global Variables
my $tokens;
my %checkpoints;
my $tick = 0;

# Push Checkpoints into Hash
chomp(my $laps = <STDIN>);
chomp(my $checkpoint_count = <STDIN>);
for my $i (0..$checkpoint_count-1) {
    chomp($tokens=<STDIN>);
    my ($checkpoint_x, $checkpoint_y) = split(/ /,$tokens);
    $checkpoints{"$i"}{x} = $checkpoint_x;
    $checkpoints{"$i"}{y} = $checkpoint_y;
}

# Racer 1 Global Variables
my $racer_1_pos_x;
my $racer_1_pos_y;
my $racer_1_speed_vx;
my $racer_1_speed_vy;
my $racer_1_speed;
my $racer_1_angle;
my $racer_1_next_check_point_id;
my $racer_1_nextnext_check_point_id;
my $racer_1_next_check_point_x;
my $racer_1_next_check_point_y;
my $racer_1_nextnext_check_point_x;
my $racer_1_nextnext_check_point_y;
my $racer_1_thrust;
my $racer_1_distance2cp;
my $racer_1_realangle;
my $racer_1_direction;
my $racer_1_hasboosted = "false";
my $racer_1_lap = 1;
my $racer_1_nextlap = 0;
my $racer_1_pointsreached = 0;
my $racer_1_currentcp;
my $racer_1_nextposition_x;
my $racer_1_nextposition_y;
my $racer_1_currentcp_x;
my $racer_1_currentcp_y;
my $racer_1_wpcontact = "false";
my $racer_1_collision_1 = "false";
my $racer_1_collision_2 = "false";

# Racer 2 Global Variables
my $racer_2_pos_x;
my $racer_2_pos_y;
my $racer_2_speed_vx;
my $racer_2_speed_vy;
my $racer_2_speed;
my $racer_2_angle;
my $racer_2_next_check_point_id;
my $racer_2_nextnext_check_point_id;
my $racer_2_next_check_point_x;
my $racer_2_next_check_point_y;
my $racer_2_nextnext_check_point_x;
my $racer_2_nextnext_check_point_y;
my $racer_2_thrust;
my $racer_2_thrust2enemy;
my $racer_2_distance2cp;
my $racer_2_realangle;
my $racer_2_direction;
my $racer_2_hasboosted = "false";
my $distance2opponent;
my $distance2opponent2;
my $opponent_pos_x;
my $opponent_pos_y;
my $racer_2_lap = 1;
my $racer_2_nextlap = 0;
my $racer_2_pointsreached = 0;
my $racer_2_currentcp;
my $racer_2_nextposition_x;
my $racer_2_nextposition_y;
my $distance2opponentpos;
my $racer_2_direction2wp;
my $opponent_wppos_x;
my $opponent_wppos_y;
my $racer_2_currentcp_x;
my $racer_2_currentcp_y;
my $racer_2_wpcontact = "false";
my $racer_2_collision_1 = "false";
my $racer_2_collision_2 = "false";

# opponent 1 Global Variables
my $opponent_1_pos_x;
my $opponent_1_pos_y;
my $opponent_1_speed_vx;
my $opponent_1_speed_vy;
my $opponent_1_speed;
my $opponent_1_angle;
my $opponent_1_next_check_point_id;
my $opponent_1_nextnext_check_point_id;
my $opponent_1_next_check_point_x;
my $opponent_1_next_check_point_y;
my $opponent_1_nextnext_check_point_x;
my $opponent_1_nextnext_check_point_y;
my $opponent_1_thrust;
my $opponent_1_distance2cp;
my $opponent_1_realangle;
my $opponent_1_direction;
my $opponent_1_hasboosted = "false";
my $opponent_1_lap = 1;
my $opponent_1_nextlap = 0;
my $opponent_1_pointsreached = 0;
my $opponent_1_oldcp;
my $opponent_1_nextposition_x;
my $opponent_1_nextposition_y;
my $opponent_1_nextnextposition_x;
my $opponent_1_nextnextposition_y;

# opponent 2 Global Variables
my $opponent_2_pos_x;
my $opponent_2_pos_y;
my $opponent_2_speed_vx;
my $opponent_2_speed_vy;
my $opponent_2_speed;
my $opponent_2_angle;
my $opponent_2_next_check_point_id;
my $opponent_2_nextnext_check_point_id;
my $opponent_2_next_check_point_x;
my $opponent_2_next_check_point_y;
my $opponent_2_nextnext_check_point_x;
my $opponent_2_nextnext_check_point_y;
my $opponent_2_thrust;
my $opponent_2_distance2cp;
my $opponent_2_realangle;
my $opponent_2_direction;
my $opponent_2_hasboosted = "false";
my $opponent_2_lap = 1;
my $opponent_2_nextlap = 0;
my $opponent_2_pointsreached = 0;
my $opponent_2_oldcp;
my $opponent_2_nextposition_x;
my $opponent_2_nextposition_y;
my $opponent_2_nextnextposition_x;
my $opponent_2_nextnextposition_y;

# Get the next Checkpoint Coordinates
sub getcheckpointcoordinates {
    my $checkpointid = shift;
    my $param = shift;
    if ($param eq 'x') {
        return $checkpoints{$checkpointid}{x};
    } elsif ($param eq 'y') {
        return $checkpoints{$checkpointid}{y};
    }
}

# Get Distance from two points
sub getdistance {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    my $distance = (((($x1 - $x2) * ($x1 - $x2))) + ((($y1 - $y2) * ($y1 - $y2))));
    $distance = sqrt($distance);
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

sub diffangle {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    my $angle = shift;
    my $a = &getangle($x1,$y1,$x2,$y2);
    my $right = $angle <= $a ? $a - $angle : 360.0 - $angle + $a;
    my $left = $angle >= $a ? $angle - $a : $angle + 360.0 - $a;
    if ($right < $left) {
        return $right;
    } else {
        return -$left;
    }
}

sub getoldthrust_racer_1 {
    my $thrust;
	if (($racer_1_direction > 90) or ($racer_1_direction < -90 )) {	# Over 90°
		$thrust = 15;
	} elsif ((($racer_1_direction > 45) or ($racer_1_direction < -45 )) and (($racer_1_direction < 90) or ($racer_1_direction > -90 ))) {	# Over 45°
		$thrust = 40;
	} elsif ((($racer_1_direction > 18) or ($racer_1_direction < -18 )) and (($racer_1_direction < 45) or ($racer_1_direction > -45 ))) {	# Over 18°
		$thrust = 70;
	} else {
        if (($racer_1_hasboosted eq "false") and ($racer_1_distance2cp > 4000)) {
            $thrust = "BOOST";
            $racer_1_hasboosted = "true";
        } else {
            $thrust = 100;
        }
	}
    return $thrust;
}

sub getthrust_racer_1 {
    my $thrust;
	if (($racer_1_direction > 120) or ($racer_1_direction < -120 )) {	# Over 120°
		if ($racer_1_distance2cp < 800) {
			$thrust = 30;
		} else {
			$thrust = 0;
		}
	} elsif ((($racer_1_direction > 110) or ($racer_1_direction < -110 )) and (($racer_1_direction < 130) or ($racer_1_direction > -130 ))) {	# Over 110°
		$thrust = 0;
	} elsif ((($racer_1_direction > 90) or ($racer_1_direction < -90 )) and (($racer_1_direction < 110) or ($racer_1_direction > -110 ))) {	# Over 90°
		$thrust = 25;
	} elsif ((($racer_1_direction > 70) or ($racer_1_direction < -70 )) and (($racer_1_direction < 90) or ($racer_1_direction > -90 ))) {	# Over 70°
		$thrust = 30;
	} elsif ((($racer_1_direction > 50) or ($racer_1_direction < -50 )) and (($racer_1_direction < 70) or ($racer_1_direction > -70 ))) {	# Over 50°
		$thrust = 40;
	} elsif ((($racer_1_direction > 40) or ($racer_1_direction < -40 )) and (($racer_1_direction < 50) or ($racer_1_direction > -50 ))) {	# Over 40°
		$thrust = 50;
	} elsif ((($racer_1_direction > 30) or ($racer_1_direction < -30 )) and (($racer_1_direction < 40) or ($racer_1_direction > -40 ))) {	# Over 30°
		$thrust = 70;
	} elsif ((($racer_1_direction > 20) or ($racer_1_direction < -20 )) and (($racer_1_direction < 30) or ($racer_1_direction > -30 ))) {	# Over 20°
		$thrust = 90;
	} elsif ((($racer_1_direction > 10) or ($racer_1_direction < -10 )) and (($racer_1_direction < 20) or ($racer_1_direction > -20 ))) {	# Over 10°
		$thrust = 100;
	} elsif ((($racer_1_direction > 0) or ($racer_1_direction < -0 )) and (($racer_1_direction < 10) or ($racer_1_direction > -10 ))) {	# Over 0°
        if (($racer_1_hasboosted eq "false") and ($tick > 25) and ($racer_1_distance2cp > 3000)) {
            $thrust = "BOOST";
            $racer_1_hasboosted = "true";
        } else {
            $thrust = 100;
        }
	} else {
		$thrust = 100;
	}
    return $thrust;
}

sub getthrust_racer_2 {
    my $thrust;
	if (($racer_2_direction > 120) or ($racer_2_direction < -120 )) {	# Over 120°
		if ($racer_2_distance2cp < 800) {
			$thrust = 30;
		} else {
			$thrust = 10;
		}
	} elsif ((($racer_2_direction > 110) or ($racer_2_direction < -110 )) and (($racer_2_direction < 130) or ($racer_2_direction > -130 ))) {	# Over 110°
		$thrust = 10;
	} elsif ((($racer_2_direction > 90) or ($racer_2_direction < -90 )) and (($racer_2_direction < 110) or ($racer_2_direction > -110 ))) {	# Over 90°
		$thrust = 10;
	} elsif ((($racer_2_direction > 70) or ($racer_2_direction < -70 )) and (($racer_2_direction < 90) or ($racer_2_direction > -90 ))) {	# Over 70°
		$thrust = 10;
	} elsif ((($racer_2_direction > 50) or ($racer_2_direction < -50 )) and (($racer_2_direction < 70) or ($racer_2_direction > -70 ))) {	# Over 50°
		$thrust = 10;
	} elsif ((($racer_2_direction > 40) or ($racer_2_direction < -40 )) and (($racer_2_direction < 50) or ($racer_2_direction > -50 ))) {	# Over 40°
		$thrust = 50;
	} elsif ((($racer_2_direction > 30) or ($racer_2_direction < -30 )) and (($racer_2_direction < 40) or ($racer_2_direction > -40 ))) {	# Over 30°
		$thrust = 70;
	} elsif ((($racer_2_direction > 20) or ($racer_2_direction < -20 )) and (($racer_2_direction < 30) or ($racer_2_direction > -30 ))) {	# Over 20°
		$thrust = 90;
	} elsif ((($racer_2_direction > 10) or ($racer_2_direction < -10 )) and (($racer_2_direction < 20) or ($racer_2_direction > -20 ))) {	# Over 10°
		$thrust = 100;
	} elsif ((($racer_2_direction > 0) or ($racer_2_direction < -0 )) and (($racer_2_direction < 10) or ($racer_2_direction > -10 ))) {	# Over 0°
        if (($racer_2_hasboosted eq "false") and ($racer_2_distance2cp > 4000)) {
            $thrust = "BOOST";
            $racer_2_hasboosted = "true";
        } else {
            $thrust = 100;
        }
	} else {
		$thrust = 100;
	}
    return $thrust;
}

sub getthrust_hunter {
	my $param = shift;
	if (!$param) {
	    my $thrust;
		if (($racer_2_direction2wp > 90) or ($racer_2_direction2wp < -90 )) {	# Over 90°
			$thrust = 5;
		} elsif ((($racer_2_direction2wp > 45) or ($racer_2_direction2wp < -45 )) and (($racer_2_direction2wp < 90) or ($racer_2_direction2wp > -90 ))) {	# Over 45°
			$thrust = 50;
		} elsif ((($racer_2_direction2wp > 18) or ($racer_2_direction2wp < -18 )) and (($racer_2_direction2wp < 45) or ($racer_2_direction2wp > -45 ))) {	# Over 18°
			if (($distance2opponentpos < 2500) and ($distance2opponent > 2500)) {
				$thrust = 30
			} else {
				$thrust = 75;
			}
		} else {
			if (($distance2opponentpos < 2500) and ($distance2opponent > 2500)) {
				$thrust = 50
			} else {
				$thrust = 100;
			}
		}
	    return $thrust;
	} elsif ($param eq "enemy") {
	    my $thrust;
		if (($racer_2_direction > 90) or ($racer_2_direction < -90 )) {	# Over 90°
			$thrust = 5;
		} elsif ((($racer_2_direction > 45) or ($racer_2_direction < -45 )) and (($racer_2_direction < 90) or ($racer_2_direction > -90 ))) {	# Over 45°
			$thrust = 30;
		} elsif ((($racer_2_direction > 18) or ($racer_2_direction < -18 )) and (($racer_2_direction < 45) or ($racer_2_direction > -45 ))) {	# Over 18°
			$thrust = 75;
		} else {
	        if (($racer_2_hasboosted eq "false") and ($distance2opponent < 1500) and ($tick > 25)) {
	            $thrust = "BOOST";
	            $racer_2_hasboosted = "true";
	        } else {
	            $thrust = 100;
	        }
		}
	    return $thrust;
	}
}

sub getfirst {
	if ($opponent_1_pointsreached < $opponent_2_pointsreached) {
		return 2;
	} elsif ($opponent_2_pointsreached < $opponent_1_pointsreached) {
		return 1;
	} else {
		if ($opponent_1_lap < $opponent_2_lap) {
			return 2;
		} elsif ($opponent_2_lap < $opponent_1_lap) {
			return 1;
		} else {
			if ($opponent_1_distance2cp < $opponent_2_distance2cp) {
				return 1;
			} else {
				return 2;
			}
		return 1;
		}
	}
}

sub getspeed {
	my $speed_vx = shift;
	my $speed_vy = shift;
	my $speed;
	
	if ($speed_vx + $speed_vy == 0) {
		$speed = 0;
	} else {
		$speed = sqrt(($speed_vx*$speed_vx) + ($speed_vy*$speed_vy));
	}
	return $speed;
}

sub iscp {
	my $x = shift;
	my $y = shift;
	my $cpx = shift;
	my $cpy = shift;
	my $cpxlow = int($cpx - 900);
	my $cpxhigh = int($cpx + 900);
	my $cpylow = int($cpy - 900);
	my $cpyhigh = int($cpy + 900);
	if (($x ~~ [$cpxlow .. $cpxhigh]) and ($y ~~ [$cpylow .. $cpyhigh])) {
		return "true";
	} else {
		return "false";
	}
}

sub collision {
	my $x = shift;
	my $y = shift;
	my $cpx = shift;
	my $cpy = shift;
	my $cpxlow = int($cpx - 900);
	my $cpxhigh = int($cpx + 900);
	my $cpylow = int($cpy - 900);
	my $cpyhigh = int($cpy + 900);
	if (($x ~~ [$cpxlow .. $cpxhigh]) and ($y ~~ [$cpylow .. $cpyhigh])) {
		return "true";
	} else {
		return "false";
	}
}

sub predictposition {
    my $x = shift;
    my $y = shift;
	my $vx = shift;
	my $vy = shift;
	my $newx = ($x + $vx) * 0.85;
	my $newy = ($y + $vy) * 0.85;
	$newx = int($newx);
	$newy = int($newy);
	return ($newx,$newy);
}

# game loop
while (1) {
    for my $i (0..1) {

		# Racer 1
        if ($i == 0) {
        	$tick++;
            chomp($tokens=<STDIN>);
            my ($x, $y, $vx, $vy, $angle, $next_check_point_id) = split(/ /,$tokens);
            $racer_1_pos_x = $x;
            $racer_1_pos_y = $y;
            $racer_1_speed_vx = $vx;
            $racer_1_speed_vy = $vy;
            $racer_1_speed = &getspeed($racer_1_speed_vx,$racer_1_speed_vy);
            $racer_1_angle = $angle;
            $racer_1_next_check_point_id = $next_check_point_id;
            $racer_1_next_check_point_x = &getcheckpointcoordinates($racer_1_next_check_point_id,'x');
            $racer_1_next_check_point_y = &getcheckpointcoordinates($racer_1_next_check_point_id,'y');
            if ($racer_1_next_check_point_id == $checkpoint_count -1) {
                $racer_1_nextnext_check_point_id = 0;
            } else {
                $racer_1_nextnext_check_point_id = ($racer_1_next_check_point_id + 1);
            }
            $racer_1_nextnext_check_point_x = &getcheckpointcoordinates($racer_1_nextnext_check_point_id,'x');
            $racer_1_nextnext_check_point_y = &getcheckpointcoordinates($racer_1_nextnext_check_point_id,'y');
            $racer_1_realangle = &getangle($racer_1_pos_x,$racer_1_pos_y,$racer_1_next_check_point_x,$racer_1_next_check_point_y);
            $racer_1_direction = int(&diffangle($racer_1_pos_x,$racer_1_pos_y,$racer_1_next_check_point_x,$racer_1_next_check_point_y,$racer_1_angle));
            $racer_1_distance2cp = &getdistance($racer_1_pos_x,$racer_1_pos_y,$racer_1_next_check_point_x,$racer_1_next_check_point_y);

            ($racer_1_nextposition_x,$racer_1_nextposition_y) = &predictposition($racer_1_pos_x,$racer_1_pos_y,$racer_1_speed_vx,$racer_1_speed_vy);
            
            
			if (!$racer_1_currentcp) {
				$racer_1_currentcp = $racer_1_next_check_point_id;
				$racer_1_currentcp_x = &getcheckpointcoordinates($racer_1_next_check_point_id,'x');
				$racer_1_currentcp_y = &getcheckpointcoordinates($racer_1_next_check_point_id,'y');
		   	} elsif ($racer_1_next_check_point_id == $racer_1_currentcp) {
				$racer_1_currentcp_x = &getcheckpointcoordinates($racer_1_next_check_point_id,'x');
				$racer_1_currentcp_y = &getcheckpointcoordinates($racer_1_next_check_point_id,'y');
			} else {
				$racer_1_pointsreached++;
			}
			$racer_1_currentcp = $racer_1_next_check_point_id;
	            
			if (($racer_1_next_check_point_id == ($checkpoint_count -1)) and ($racer_1_lap == 1)) {
				$racer_1_nextlap = 2;
			} elsif (($racer_1_next_check_point_id == ($checkpoint_count -1)) and ($racer_1_lap == 2)) {
				$racer_1_nextlap = 3;
			} elsif (($racer_1_next_check_point_id == ($checkpoint_count -1)) and ($racer_1_lap == 3)) {
				$racer_1_nextlap = 3;
			}
			
			if (($racer_1_nextlap == 2) and ($racer_1_next_check_point_id == 1)) {
				$racer_1_lap = 2;
			} elsif (($racer_1_nextlap == 3) and ($racer_1_next_check_point_id == 1)) {
				$racer_1_lap = 3;
			}
        }

		# Racer 2
        if ($i == 1) {
            chomp($tokens=<STDIN>);
            my ($x, $y, $vx, $vy, $angle, $next_check_point_id) = split(/ /,$tokens);
            $racer_2_pos_x = $x;
            $racer_2_pos_y = $y;
            $racer_2_speed_vx = $vx;
            $racer_2_speed_vy = $vy;
            $racer_2_speed = &getspeed($racer_2_speed_vx,$racer_2_speed_vy);
            $racer_2_angle = $angle;
            $racer_2_next_check_point_id = $next_check_point_id;
            $racer_2_next_check_point_x = &getcheckpointcoordinates($racer_2_next_check_point_id,'x');
            $racer_2_next_check_point_y = &getcheckpointcoordinates($racer_2_next_check_point_id,'y');
            if ($racer_2_next_check_point_id == $checkpoint_count -1) {
                $racer_2_nextnext_check_point_id = 0;
            } else {
                $racer_2_nextnext_check_point_id = ($racer_2_next_check_point_id + 1);
            }
            $racer_2_nextnext_check_point_x = &getcheckpointcoordinates($racer_2_nextnext_check_point_id,'x');
            $racer_2_nextnext_check_point_y = &getcheckpointcoordinates($racer_2_nextnext_check_point_id,'y');
            $racer_2_realangle = &getangle($racer_2_pos_x,$racer_2_pos_y,$racer_2_next_check_point_x,$racer_2_next_check_point_y);
            $racer_2_direction = int(&diffangle($racer_2_pos_x,$racer_2_pos_y,$racer_2_next_check_point_x,$racer_2_next_check_point_y,$racer_2_angle));
            $racer_2_distance2cp = &getdistance($racer_2_pos_x,$racer_2_pos_y,$racer_2_next_check_point_x,$racer_2_next_check_point_y);
            
            ($racer_2_nextposition_x,$racer_2_nextposition_y) = &predictposition($racer_2_pos_x,$racer_2_pos_y,$racer_2_speed_vx,$racer_2_speed_vy);
            
			if (!$racer_2_currentcp) {
				$racer_2_currentcp = $racer_2_next_check_point_id;
		   	} elsif ($racer_2_next_check_point_id eq $racer_2_currentcp) {
			} else {
				$racer_2_pointsreached++;
			}
			$racer_2_currentcp = $racer_2_next_check_point_id;

            
			if (($racer_2_next_check_point_id == ($checkpoint_count -1)) and ($racer_2_lap == 1)) {
				$racer_2_nextlap = 2;
			} elsif (($racer_2_next_check_point_id == ($checkpoint_count -1)) and ($racer_2_lap == 2)) {
				$racer_2_nextlap = 3;
			} elsif (($racer_2_next_check_point_id == ($checkpoint_count -1)) and ($racer_2_lap == 3)) {
				$racer_2_nextlap = 3;
			}
			
			if (($racer_2_nextlap == 2) and ($racer_2_next_check_point_id == 1)) {
				$racer_2_lap = 2;
			} elsif (($racer_2_nextlap == 3) and ($racer_2_next_check_point_id == 1)) {
				$racer_2_lap = 3;
			}
        }
    }

    for my $i (0..1) {
 
		# opponent 1
        if ($i == 0) {
            chomp($tokens=<STDIN>);
            my ($x_2, $y_2, $vx_2, $vy_2, $angle_2, $next_check_point_id_2) = split(/ /,$tokens);
            $opponent_1_pos_x = $x_2;
            $opponent_1_pos_y = $y_2;
            $opponent_1_speed_vx = $vx_2;
            $opponent_1_speed_vy = $vy_2;
            $opponent_1_speed = &getspeed($opponent_1_speed_vx,$opponent_1_speed_vy);
            $opponent_1_angle = $angle_2;
            $opponent_1_next_check_point_id = $next_check_point_id_2;
            $opponent_1_next_check_point_x = &getcheckpointcoordinates($opponent_1_next_check_point_id,'x');
            $opponent_1_next_check_point_y = &getcheckpointcoordinates($opponent_1_next_check_point_id,'y');
            if ($opponent_1_next_check_point_id == $checkpoint_count -1) {
                $opponent_1_nextnext_check_point_id = 0;
            } else {
                $opponent_1_nextnext_check_point_id = ($opponent_1_next_check_point_id + 1);
            }
            $opponent_1_nextnext_check_point_x = &getcheckpointcoordinates($opponent_1_nextnext_check_point_id,'x');
            $opponent_1_nextnext_check_point_y = &getcheckpointcoordinates($opponent_1_nextnext_check_point_id,'y');
            $opponent_1_realangle = &getangle($opponent_1_pos_x,$opponent_1_pos_y,$opponent_1_next_check_point_x,$opponent_1_next_check_point_y);
            $opponent_1_direction = int(&diffangle($opponent_1_pos_x,$opponent_1_pos_y,$opponent_1_next_check_point_x,$opponent_1_next_check_point_y,$opponent_1_angle));
            $opponent_1_distance2cp = &getdistance($opponent_1_pos_x,$opponent_1_pos_y,$opponent_1_next_check_point_x,$opponent_1_next_check_point_y);
            
            ($opponent_1_nextposition_x,$opponent_1_nextposition_y) = &predictposition($opponent_1_pos_x,$opponent_1_pos_y,$opponent_1_speed_vx,$opponent_1_speed_vy);
            ($opponent_1_nextnextposition_x,$opponent_1_nextnextposition_y) = &predictposition($opponent_1_nextposition_x,$opponent_1_nextposition_y,$opponent_1_speed_vx,$opponent_1_speed_vy);
            
			if (!$opponent_1_oldcp) {
				$opponent_1_oldcp = $opponent_1_next_check_point_id;
		   	} elsif ($opponent_1_next_check_point_id eq $opponent_1_oldcp) {
			} else {
				$opponent_1_pointsreached++;
			}
			$opponent_1_oldcp = $opponent_1_next_check_point_id;

            
			if (($opponent_1_next_check_point_id == ($checkpoint_count -1)) and ($opponent_1_lap == 1)) {
				$opponent_1_nextlap = 2;
			} elsif (($opponent_1_next_check_point_id == ($checkpoint_count -1)) and ($opponent_1_lap == 2)) {
				$opponent_1_nextlap = 3;
			} elsif (($opponent_1_next_check_point_id == ($checkpoint_count -1)) and ($opponent_1_lap == 3)) {
				$opponent_1_nextlap = 3;
			}
			
			if (($opponent_1_nextlap == 2) and ($opponent_1_next_check_point_id == 1)) {
				$opponent_1_lap = 2;
			} elsif (($opponent_1_nextlap == 3) and ($opponent_1_next_check_point_id == 1)) {
				$opponent_1_lap = 3;
			}
        }

		# opponent 2
        if ($i == 1) {
            chomp($tokens=<STDIN>);
            my ($x_2, $y_2, $vx_2, $vy_2, $angle_2, $next_check_point_id_2) = split(/ /,$tokens);
            $opponent_2_pos_x = $x_2;
            $opponent_2_pos_y = $y_2;
            $opponent_2_speed_vx = $vx_2;
            $opponent_2_speed_vy = $vy_2;
            $opponent_2_speed = &getspeed($opponent_2_speed_vx,$opponent_2_speed_vy);
            $opponent_2_angle = $angle_2;
            $opponent_2_next_check_point_id = $next_check_point_id_2;
            $opponent_2_next_check_point_x = &getcheckpointcoordinates($opponent_2_next_check_point_id,'x');
            $opponent_2_next_check_point_y = &getcheckpointcoordinates($opponent_2_next_check_point_id,'y');
            if ($opponent_2_next_check_point_id == $checkpoint_count -1) {
                $opponent_2_nextnext_check_point_id = 0;
            } else {
                $opponent_2_nextnext_check_point_id = ($opponent_2_next_check_point_id + 1);
            }
            $opponent_2_nextnext_check_point_x = &getcheckpointcoordinates($opponent_2_nextnext_check_point_id,'x');
            $opponent_2_nextnext_check_point_y = &getcheckpointcoordinates($opponent_2_nextnext_check_point_id,'y');
            $opponent_2_realangle = &getangle($opponent_2_pos_x,$opponent_2_pos_y,$opponent_2_next_check_point_x,$opponent_2_next_check_point_y);
            $opponent_2_direction = int(&diffangle($opponent_2_pos_x,$opponent_2_pos_y,$opponent_2_next_check_point_x,$opponent_2_next_check_point_y,$opponent_2_angle));
            $opponent_2_distance2cp = &getdistance($opponent_2_pos_x,$opponent_2_pos_y,$opponent_2_next_check_point_x,$opponent_2_next_check_point_y);
            
            ($opponent_2_nextposition_x,$opponent_2_nextposition_y) = &predictposition($opponent_2_pos_x,$opponent_2_pos_y,$opponent_2_speed_vx,$opponent_2_speed_vy);
            ($opponent_2_nextnextposition_x,$opponent_2_nextnextposition_y) = &predictposition($opponent_2_nextposition_x,$opponent_2_nextposition_y,$opponent_2_speed_vx,$opponent_2_speed_vy);
            
			if (!$opponent_2_oldcp) {
				$opponent_2_oldcp = $opponent_2_next_check_point_id;
		   	} elsif ($opponent_2_next_check_point_id eq $opponent_2_oldcp) {
			} else {
				$opponent_2_pointsreached++;
			}
			$opponent_2_oldcp = $opponent_2_next_check_point_id;
            
			if (($opponent_2_next_check_point_id == ($checkpoint_count -1)) and ($opponent_2_lap == 1)) {
				$opponent_2_nextlap = 2;
			} elsif (($opponent_2_next_check_point_id == ($checkpoint_count -1)) and ($opponent_2_lap == 2)) {
				$opponent_2_nextlap = 3;
			} elsif (($opponent_2_next_check_point_id == ($checkpoint_count -1)) and ($opponent_2_lap == 3)) {
				$opponent_2_nextlap = 3;
			}
			
			if (($opponent_2_nextlap == 2) and ($opponent_2_next_check_point_id == 1)) {
				$opponent_2_lap = 2;
			} elsif (($opponent_2_nextlap == 3) and ($opponent_2_next_check_point_id == 1)) {
				$opponent_2_lap = 3;
			}
        }
    }

################################################################################################################################################################################## 
# Racer 1
	my $racer_1_wpcontact = &iscp($racer_1_pos_x,$racer_1_pos_y,$racer_1_next_check_point_x,$racer_1_next_check_point_y);
	my $racer_1_predictcp = &iscp($racer_1_nextposition_x,$racer_1_nextposition_y,$racer_1_nextnext_check_point_x,$racer_1_nextnext_check_point_y);
	
#	my $racer_1_collision_1 = &collision($racer_1_pos_x,$racer_1_pos_y,$opponent_1_pos_x,$opponent_1_pos_y);
#	my $racer_1_collision_2 = &collision($racer_1_pos_x,$racer_1_pos_y,$opponent_2_pos_x,$opponent_2_pos_y);
	
    $racer_1_thrust = &getthrust_racer_1();
	if (($racer_1_predictcp eq "true") and ($racer_1_distance2cp < 2500)) {
		$racer_1_thrust = 30;
	    print "$racer_1_next_check_point_x $racer_1_next_check_point_y $racer_1_thrust\n";
	} elsif (($racer_1_predictcp eq "true") or ($racer_1_wpcontact eq "true")) {
	    $racer_1_thrust = 50;
	    print "$racer_1_nextnext_check_point_x $racer_1_nextnext_check_point_y $racer_1_thrust\n";
	} else {
    	print "$racer_1_next_check_point_x $racer_1_next_check_point_y $racer_1_thrust\n";
    }

################################################################################################################################################################################## 
# Racer 2
#	my $racer_2_wpcontact = &iscp($racer_2_pos_x,$racer_2_pos_y,$racer_2_next_check_point_x,$racer_2_next_check_point_y);
#	my $racer_2_predictcp = &iscp($racer_2_nextposition_x,$racer_2_nextposition_y,$racer_2_nextnext_check_point_x,$racer_2_nextnext_check_point_y);
	
#	my $racer_2_collision_2 = &collision($racer_2_pos_x,$racer_2_pos_y,$opponent_2_pos_x,$opponent_2_pos_y);
#	my $racer_2_collision_2 = &collision($racer_2_pos_x,$racer_2_pos_y,$opponent_2_pos_x,$opponent_2_pos_y);
	
#    $racer_2_thrust = &getthrust_racer_2();
#	if (($racer_2_predictcp eq "true") and ($racer_2_distance2cp < 2000)) {
#		$racer_2_thrust = 50;
#	    print "$racer_2_next_check_point_x $racer_2_next_check_point_y $racer_2_thrust\n";
#	} elsif (($racer_2_predictcp eq "true") or ($racer_2_wpcontact eq "true")) {
#	    $racer_2_thrust = 50;
#	    print "$racer_2_nextnext_check_point_x $racer_2_nextnext_check_point_y $racer_2_thrust\n";
#	} else {
#   	print "$racer_2_next_check_point_x $racer_2_next_check_point_y $racer_2_thrust\n";
#   }

################################################################################################################################################################################## 
# Hunter
	my $racer_2_collision_1 = &collision($racer_2_pos_x,$racer_2_pos_y,$opponent_1_nextposition_x,$opponent_1_nextposition_y);
	my $racer_2_collision_2 = &collision($racer_2_pos_x,$racer_2_pos_y,$opponent_2_nextposition_x,$opponent_2_nextposition_y);
	my $opponent_collision;

	if (&getfirst() == 1) {
		$racer_2_direction = int(&diffangle($racer_2_pos_x,$racer_2_pos_y,$opponent_1_pos_x,$opponent_1_pos_y,$racer_2_angle));
		$opponent_pos_x = $opponent_1_pos_x;
		$opponent_pos_y = $opponent_1_pos_y;
		$opponent_wppos_x = $opponent_1_nextnextposition_x;
		$opponent_wppos_y = $opponent_1_nextnextposition_y;
		$distance2opponentpos = &getdistance($racer_2_pos_x,$racer_2_pos_y,$opponent_1_nextnextposition_x,$opponent_1_nextnextposition_y);
		$distance2opponent = &getdistance($racer_2_pos_x,$racer_2_pos_y,$opponent_1_pos_x,$opponent_1_pos_y);
		$distance2opponent2 = &getdistance($racer_2_pos_x,$racer_2_pos_y,$opponent_2_pos_x,$opponent_2_pos_y);
		$racer_2_direction2wp = int(&diffangle($racer_2_pos_x,$racer_2_pos_y,$opponent_1_nextnextposition_x,$opponent_1_nextnextposition_y,$racer_2_angle));
		$opponent_collision = $racer_2_collision_1;
	} elsif (&getfirst() == 2) {
		$racer_2_direction = int(&diffangle($racer_2_pos_x,$racer_2_pos_y,$opponent_2_pos_x,$opponent_2_pos_y,$racer_2_angle));
		$opponent_pos_x = $opponent_2_pos_x;
		$opponent_pos_y = $opponent_2_pos_y;
		$opponent_wppos_x = $opponent_2_nextnextposition_x;
		$opponent_wppos_y = $opponent_2_nextnextposition_y;
		$distance2opponentpos = &getdistance($racer_2_pos_x,$racer_2_pos_y,$opponent_2_nextnextposition_x,$opponent_2_nextnextposition_y);
		$distance2opponent = &getdistance($racer_2_pos_x,$racer_2_pos_y,$opponent_2_pos_x,$opponent_2_pos_y);
		$distance2opponent2 = &getdistance($racer_2_pos_x,$racer_2_pos_y,$opponent_1_pos_x,$opponent_1_pos_y);
		$racer_2_direction2wp = int(&diffangle($racer_2_pos_x,$racer_2_pos_y,$opponent_2_nextnextposition_x,$opponent_2_nextnextposition_y,$racer_2_angle));
		$opponent_collision = $racer_1_collision_2;
	}

    $racer_2_thrust2enemy = &getthrust_racer_2("enemy");
    $racer_2_thrust = &getthrust_racer_2();
	if (($distance2opponentpos > 2000) and ($distance2opponent > 2500)){
	    print "$opponent_wppos_x $opponent_wppos_y $racer_2_thrust\n";
	} elsif (($opponent_collision eq "true") and (($racer_2_speed > $opponent_1_speed) or ($racer_2_speed > $opponent_2_speed))) { # SHIELD
	    print "$opponent_pos_x $opponent_pos_y SHIELD\n";
	} elsif (($distance2opponent < 1100) and (($racer_2_direction < 30) or ($racer_2_direction > -30)) and ($racer_2_speed > 150)) {
	    print "$opponent_pos_x $opponent_pos_y SHIELD\n";
	} elsif (($distance2opponent < 3000) and (($racer_2_direction < 45) or ($racer_2_direction > -45))) {
	    print "$opponent_pos_x $opponent_pos_y $racer_2_thrust2enemy\n";
	} else {
    	print "$opponent_wppos_x $opponent_wppos_y $racer_2_thrust\n";
    }

################################################################################################################################################################################## 
# Debug
#    print STDERR "Racer: - Lap: $racer_1_lap Points Reached: $racer_1_pointsreached\n";
#    print STDERR "Speed: $racer_1_speed Speed x: $racer_1_speed_vx | Speed y: $racer_1_speed_vy CheckpointID: $racer_1_next_check_point_id Next CheckpointID: $racer_1_nextnext_check_point_id\n";
#    print STDERR "Angle: " . int(&getangle($racer_1_pos_x,$racer_1_pos_y,$racer_1_next_check_point_x,$racer_1_next_check_point_y)) . " Diff: " . int(&diffangle($racer_1_pos_x,$racer_1_pos_y,$racer_1_next_check_point_x,$racer_1_next_check_point_y,$racer_1_angle)) . "\n";
#	print STDERR "\n";
#    print STDERR "Hunter: - Victim: " . &getfirst() . "\n";
#    print STDERR "Distance: $distance2opponent Speed: $racer_2_speed Speed x: $racer_2_speed_vx | Speed y: $racer_2_speed_vy CheckpointID: $racer_2_next_check_point_id Next CheckpointID: $racer_2_nextnext_check_point_id\n";
#    print STDERR "Angle: " . int(&getangle($racer_2_pos_x,$racer_2_pos_y,$racer_2_next_check_point_x,$racer_2_next_check_point_y)) . " Diff: " . int(&diffangle($racer_2_pos_x,$racer_2_pos_y,$racer_2_next_check_point_x,$racer_2_next_check_point_y,$racer_2_angle)) . "\n";
#	print STDERR "\n";
#    print STDERR "Opponent 1: - Lap: $opponent_1_lap Points Reached: $opponent_1_pointsreached\n";
#    print STDERR "Speed: $opponent_1_speed Speed x: $opponent_1_speed_vx | Speed y: $opponent_1_speed_vy CheckpointID: $opponent_1_next_check_point_id Next CheckpointID: $opponent_1_nextnext_check_point_id\n";
#    print STDERR "Angle: " . int(&getangle($opponent_1_pos_x,$opponent_1_pos_y,$opponent_1_next_check_point_x,$opponent_1_next_check_point_y)) . " Diff: " . int(&diffangle($opponent_1_pos_x,$opponent_1_pos_y,$opponent_1_next_check_point_x,$opponent_1_next_check_point_y,$opponent_1_angle)) . "\n";
#	print STDERR "\n";
#    print STDERR "Opponent 2: - Lap: $opponent_2_lap Points Reached: $opponent_2_pointsreached\n";
#    print STDERR "Speed: $opponent_2_speed Speed x: $opponent_2_speed_vx | Speed y: $opponent_2_speed_vy CheckpointID: $opponent_2_next_check_point_id Next CheckpointID: $opponent_2_nextnext_check_point_id\n";
#    print STDERR "Angle: " . int(&getangle($opponent_2_pos_x,$opponent_2_pos_y,$opponent_2_next_check_point_x,$opponent_2_next_check_point_y)) . " Diff: " . int(&diffangle($opponent_2_pos_x,$opponent_2_pos_y,$opponent_2_next_check_point_x,$opponent_2_next_check_point_y,$opponent_2_angle)) . "\n";
#	print STDERR "\n";
#	print STDERR "Collision1: $racer_2_collision_1\n";
#	print STDERR "Collision2: $racer_2_collision_2\n";
}
