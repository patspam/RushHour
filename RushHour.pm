package RushHour;

use strict;
use warnings;
use Clone qw(clone);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

sub new {
    my $class = shift;
    my ($board_x, $board_y, $initial_state) = @_;
    
    my $self = {
        debug => 0,
        board_x => $board_x,
        board_y => $board_y,
        seen => {},
        initial_state => $initial_state,
    };
    bless $self, $class;
}

sub say {
    my $self = shift;
    local $\ = "\n";
    print @_;
}

sub debug {
    my $self = shift;
    my $msg = shift;
    print "DEBUG: $msg\n" if $self->{debug};
}

sub solve {
    my $self = shift;
    
    $self->debug("Attempting to solve..");
    my $initial_state = $self->{initial_state};
#    $self->debug("Starting with initial state: " . Dumper($initial_state));

    my @states = ( $initial_state );
    $self->mark_as_seen($initial_state);
    
    while (my $state = pop @states) {
        push @states, $self->get_new_states($state);
    }
    
    if (!$self->{solution}) {
        $self->say("No solution found -- examined " . (keys %{$self->{seen}}) . " states");
        exit;
    }
    
    $self->say("Smallest solution has length: $self->{solution_length}");
    $self->say(join "\n", @{$self->{solution}});
}

sub new_state {
    my $self = shift;
    my ($old_state, $piece, $position) = @_;
    
    if (defined $self->{solution_length} && $old_state->{count} >= $self->{solution_length} - 1) {
        $self->debug("Skipping new state $piece $position, a smaller solution exists");
        return;
    }
    
    my ( $x, $y ) = split /,/, $position;
    if ($x < 0 || $x >= $self->{board_x}) {
        $self->debug("Out of bounds: $x, skipping");
        return;
    }
    
    if ($y < 0 || $y >= $self->{board_y}) {
        $self->debug("Out of bounds: $y, skipping");
        return;
    }
    
    my $matrix = $self->get_matrix($old_state);
    if (my $hit = $matrix->{ $position } ) {
        if ($hit ne $piece) {
            $self->debug("Illegal move $position, skipping");
            return;
        }
    }
    
    my $new_state = clone $old_state;
    delete $new_state->{matrix};
    delete $new_state->{ss};
    delete $new_state->{previous};
    delete $new_state->{count};
    delete $new_state->{move};
    
    $new_state->{$piece}{position} = $position;
    
    my $move = "$piece from $old_state->{$piece}{position} to $position";
    $new_state->{count} = $old_state->{count} + 1;
    $new_state->{previous} = [@{$old_state->{previous} || []}, $move];
    
    if ($self->seen($new_state)) {
        $self->debug("Skipping, already seen $position");
        return;
    }
    
    $self->debug("Adding new move: $move");
    
    $self->mark_as_seen($new_state);
    
    # Check for winning state
    if (my $position = $new_state->{'red car'}{position}) {
        my $matrix = $self->get_matrix($new_state);
        my ( $x, $y ) = split /,/, $position;
        my $clear_path = 1;
        for my $new_x ($x + 1 .. $self->{board_x} - 1) {
            if (my $hit = $matrix->{ "$new_x,$y" } ) {
                if ($hit ne 'red car') {
                    $clear_path = 0;
                    last;
                }
            }
        }
        if ($clear_path) {
            $self->debug("Solution found");
            $self->say("Found solution of length: $new_state->{count}");
            if (!$self->{solution_length} || $new_state->{count} < $self->{solution_length}) {
                $self->{solution_length} = $new_state->{count};
                $self->{solution} = [ @{$new_state->{previous}}, 'red car outta there!' ];
                $self->debug("Set solution_length to $new_state->{count}");
            }
            return; # prune this branch
        }
    }

    return $new_state;
}

sub seen {
    my $self = shift;
    my $state = shift;
    
    my $ss = $self->get_state_string($state);
    
    if (defined (my $count = $self->{seen}{$ss})) {
        if ($state->{count} >= $count) {
            $self->debug("Already seen $ss (count=$count), and this solution does not have a lower count ($state->{count}) so skipping");
            return 1;
        } else {
            $self->debug("Already seen $ss (count=$count), but this solution has a lower count ($state->{count}) so re-examining");
            
            # Re-compute ss..
            delete $state->{ss};
            $self->mark_as_seen($state);
            
            return;
        }
    } else {
        return;
    }
}

sub mark_as_seen {
    my $self = shift;
    my $state = shift;
    my $ss = $self->get_state_string($state);
    $self->debug("Marking as seen: $ss ($state->{count})");
    $self->{seen}{$ss} = $state->{count};
}

sub clear_seen {
    my $self = shift;
    $self->{seen} = {};
}

sub get_state_string {
    my $self = shift;
    my $state = shift;    
    
    if ($state->{ss}) {
        return $state->{ss};
    }
    
    my @positions = map { $_ . "_" . $state->{$_}{position} } 
                    grep { $_ ne 'matrix' && $_ ne 'ss' && $_ ne 'previous' && $_ ne 'count' && $_ ne 'move' } keys %$state;
#    while ( my ( $piece, $spec ) = each(%$state) ) {
#        next if $piece eq 'matrix' || $piece eq 'ss' || $piece eq 'previous'  || $piece eq 'count' || $piece eq 'move' ;
#        push @positions, $piece . "_" . $spec->{position};
#    }
    $state->{count} ||= 0;
    my $ss = join ' ', sort @positions;
    $state->{ss} = $ss;
    return $ss;
}

sub get_new_states {
    my $self = shift;
    my $state = shift;
    my $matrix = $self->get_matrix($state);
    
    if (defined $self->{solution_length} && $state->{count} >= $self->{solution_length} - 1) {
        $self->debug("Skipping get_new_states, a smaller solution exists");
        return;
    }
    
    my $ss = $self->get_state_string($state);
    
#    $self->debug("Getting new states for: $ss");
    
    my @new_states;
    my $xxx = clone $state;
    while ( my ( $piece, $spec ) = each(%$xxx) ) {
        next if $piece eq 'matrix' || $piece eq 'ss' || $piece eq 'previous' || $piece eq 'count'  || $piece eq 'move';
        
#        $self->debug("Examining $piece");
        
        my ( $position, $orientation, $type ) = @{$spec}{ 'position', 'orientation', 'type' };
        my ( $x, $y ) = split /,/, $position;
        my ( $new_x, $new_y ) = ($x, $y);
        
        my $length = $type eq 'car' ? 2 : 3;
        
        if ( $orientation eq 'h' ) {
            PIECE:
            for my $new_x ($x + 1 .. $self->{board_x} - $length) {
                my $new_position = "$new_x,$y";
                for my $delta ( 0 .. $length - 1) {
                    if (my $hit = $matrix->{ ( $new_x + $delta ) . "," . $y }) {
                        last PIECE if $hit ne $piece;
                    }
                }
                push @new_states, $self->new_state($state, $piece, $new_position);
            }
            for my $new_x (reverse(0 .. $x - 1)) {
                my $new_position = "$new_x,$y";
                if (my $hit = $matrix->{ $new_position }) {
                    last if $hit ne $piece;
                }
                push @new_states, $self->new_state($state, $piece, $new_position);
            }
        }
        elsif ($orientation eq 'v') {
            PIECE:
            for my $new_y ($y + 1 .. $self->{board_y} - $length) {
                my $new_position = "$x,$new_y";
                for my $delta ( 0 .. $length - 1) {
                    if (my $hit = $matrix->{ $x . "," . ( $new_y + $delta ) }) {
                        last PIECE if $hit ne $piece;
                    }
                }
                push @new_states, $self->new_state($state, $piece, $new_position);
            }
            for my $new_y (reverse(0 .. $y - 1)) {
                my $new_position = "$x,$new_y";
                if (my $hit = $matrix->{ $new_position }) {
                    last if $hit ne $piece;
                }
                push @new_states, $self->new_state($state, $piece, $new_position);
            }
        }
        else {
            die "Bad config";
        }
    }
    $self->debug("Adding " . @new_states . " new states");
    return @new_states;
}

sub get_matrix {
    my $self = shift;
    my $state = shift;
    
    if ($state->{matrix}) {
        return $state->{matrix};
    }
    my $matrix;
    while ( my ( $piece, $spec ) = each(%$state) ) {
        next if $piece eq 'matrix' || $piece eq 'ss' || $piece eq 'previous' || $piece eq 'count'  || $piece eq 'move';
        my ( $position, $orientation, $type ) = @{$spec}{ 'position', 'orientation', 'type' };
        my ( $x, $y ) = split /,/, $position;
        $matrix->{$position} = $piece;

        if ( $type eq 'car' && $orientation eq 'h' ) {
            $matrix->{ ++$x . "," . $y } = $piece;
        }
        elsif ( $type eq 'car' && $orientation eq 'v' ) {
            $matrix->{ $x . "," . ++$y } = $piece;
        }
        elsif ( $type eq 'truck' && $orientation eq 'h' ) {
            $matrix->{ ++$x . "," . $y } = $piece;
            $matrix->{ ++$x . "," . $y } = $piece;
        }
        elsif ( $type eq 'truck' && $orientation eq 'v' ) {
            $matrix->{ $x . "," . ++$y } = $piece;
            $matrix->{ $x . "," . ++$y } = $piece;
        }
        else {
            die "Bad config";
        }
    }
    $state->{matrix} = $matrix;
    return $matrix;
}

1;