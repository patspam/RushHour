use strict;
use warnings;

use RushHour;

my $pieces = {
    'yellow truck' => {
        position    => '0,0',
        orientation => 'v',
        type        => 'truck',
    },
    'blue truck' => {
        position    => '0,3',
        orientation => 'h',
        type        => 'truck',
    },
    'purple truck' => {
        position    => '5,1',
        orientation => 'v',
        type        => 'truck',
    },
    
    'light green car' => {
        position    => '1,0',
        orientation => 'h',
        type        => 'car',
    },
    'blue car' => {
        position    => '1,1',
        orientation => 'v',
        type        => 'car',
    },
    'pink car' => {
        position    => '2,1',
        orientation => 'v',
        type        => 'car',
    },
    'red car' => {
        position    => '3,2',
        orientation => 'h',
        type        => 'car',
    },
    'orange car' => {
        position    => '4,0',
        orientation => 'v',
        type        => 'car',
    },
    'brown car' => {
        position    => '5,0',
        orientation => 'h',
        type        => 'car',
    },
    'dark green car' => {
        position    => '2,4',
        orientation => 'v',
        type        => 'car',
    },
    'purple car' => {
        position    => '3,3',
        orientation => 'v',
        type        => 'car',
    },
    'grey car' => {
        position    => '4,4',
        orientation => 'h',
        type        => 'car',
    },
    'yellow car' => {
        position    => '3,5',
        orientation => 'h',
        type        => 'car',
    },
    
};

my $rh = RushHour->new(6,6,$pieces);
$rh->{debug} = 0;
$rh->solve;