use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use Clone qw(clone);
use Readonly;
$Data::Dumper::Sortkeys = 1;

plan tests => 10;

use_ok('RushHour');

my $debug = 0;

my $pieces = {
    'light green car' => {
        position    => '0,0',
        orientation => 'h',
        type        => 'car',
    },
    'purple truck' => {
        position    => '0,1',
        orientation => 'v',
        type        => 'truck',
    },
    'yellow car' => {
        position    => '0,4',
        orientation => 'v',
        type        => 'car',
    },
    'red car' => {
        position    => '1,2',
        orientation => 'h',
        type        => 'car',
    },
    'blue truck' => {
        position    => '3,1',
        orientation => 'v',
        type        => 'truck',
    },
    'green truck' => {
        position    => '2,5',
        orientation => 'h',
        type        => 'truck',
    },
    'yellow truck' => {
        position    => '5,0',
        orientation => 'v',
        type        => 'truck',
    },
    'blue car' => {
        position    => '4,4',
        orientation => 'h',
        type        => 'car',
    },
};

my $rh = RushHour->new( 6, 6, $pieces );
$rh->{debug} = $debug;
isa_ok( $rh, 'RushHour' );

my $state = { pieces => $pieces };
is( $rh->get_state_string($state),
    'blue car_4,4 blue truck_3,1 green truck_2,5 light green car_0,0 purple truck_0,1 red car_1,2 yellow car_0,4 yellow truck_5,0',
    'get_state_string'
);
ok( !$rh->seen($state), 'Not seen yet' );
$rh->mark_as_seen($state);
ok( $rh->seen($state), 'And now seen' );
$rh->clear_seen;
ok( !$rh->seen($state), 'And now not seen again' );

cmp_deeply(
    $rh->get_matrix($state),
    {   '0,0' => 'light green car',
        '0,1' => 'purple truck',
        '0,2' => 'purple truck',
        '0,3' => 'purple truck',
        '0,4' => 'yellow car',
        '0,5' => 'yellow car',
        '1,0' => 'light green car',
        '1,2' => 'red car',
        '2,2' => 'red car',
        '2,5' => 'green truck',
        '3,1' => 'blue truck',
        '3,2' => 'blue truck',
        '3,3' => 'blue truck',
        '3,5' => 'green truck',
        '4,4' => 'blue car',
        '4,5' => 'green truck',
        '5,0' => 'yellow truck',
        '5,1' => 'yellow truck',
        '5,2' => 'yellow truck',
        '5,4' => 'blue car'
    },
    'get_matrix'
);

delete $state->{matrix};
delete $state->{ss};
delete $state->{count};
delete $state->{previous};

my $new_state = clone $state;
$new_state->{pieces}{'green truck'}{position} = "1,5";

$rh = RushHour->new( 6, 6, $state );
cmp_deeply( $rh->new_state( $state, 'green truck', "1,5" ), superhashof($new_state), 'new_state' );
cmp_deeply(
    $rh->get_matrix($new_state),
    {   '0,0' => 'light green car',
        '0,1' => 'purple truck',
        '0,2' => 'purple truck',
        '0,3' => 'purple truck',
        '0,4' => 'yellow car',
        '0,5' => 'yellow car',
        '1,0' => 'light green car',
        '1,2' => 'red car',
        '2,2' => 'red car',
        '1,5' => 'green truck',       # moved
        '3,1' => 'blue truck',
        '3,2' => 'blue truck',
        '3,3' => 'blue truck',
        '2,5' => 'green truck',       # moved
        '4,4' => 'blue car',
        '3,5' => 'green truck',       # moved
        '5,0' => 'yellow truck',
        '5,1' => 'yellow truck',
        '5,2' => 'yellow truck',
        '5,4' => 'blue car'
    },
    'get_matrix'
);

my @states = $rh->get_new_states($state);
is( scalar @states, 10, '10 new states' );

{
    my $r = RushHour->new(
        6, 6,
        {   'light green car' => {
                position    => '0,0',
                orientation => 'h',
                type        => 'car',
            },
            'red car' => {
                position    => '0,2',
                orientation => 'h',
                type        => 'car',
            },
        }
    );
    $r->{debug} = $debug;
    $r->solve;
}

{
    my $r = RushHour->new(
        6, 6,
        {   'light green car' => {
                position    => '5,2',
                orientation => 'v',
                type        => 'car',
            },
            'red car' => {
                position    => '0,2',
                orientation => 'h',
                type        => 'car',
            },
        }
    );
    $r->{debug} = $debug;
    $r->solve;
}

{
    my $r = RushHour->new(
        6, 6,
        {   'brown car' => {
                position    => '0,5',
                orientation => 'h',
                type        => 'car',
            },
            'yellow truck' => {
                position    => '0,0',
                orientation => 'v',
                type        => 'truck',
            },
        }
    );
    $r->{debug} = 1;
    $r->solve;
}
