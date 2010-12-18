
use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use lib "t/lib/";
use Data;

use IO::Handle;



sub getfd  {
    return IO::Handle->new_from_fd("Data::DATA", "r" );
}

my $x  = getfd();
my $y = getfd();

local $/ = undef;

my $x_data = <$x>;
my $y_data = <$y>;

is( $x_data, $y_data, "Values are the same");

