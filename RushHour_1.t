use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use Clone qw(clone);
use Readonly;
$Data::Dumper::Sortkeys = 1;

plan tests => 1;

use_ok('RushHour');

my $state = {
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
        goal        => 1,
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

my $rh = RushHour->new(6,6,$state);
$rh->{debug} = 0;
#$rh->test;
$rh->solve;