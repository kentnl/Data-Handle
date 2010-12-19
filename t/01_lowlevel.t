
use strict;
use warnings;

use Test::More 0.96;

use Test::Fatal;
use Data::Handle;

use lib 't/lib';
use Data;

my $handle;
my $e;

is(
  $e = exception {
    $handle = Data::Handle->new('Data');
  },
  undef,
  "->new on a valid package with an Data works"
);

isnt(
  $e = exception {
    $handle = Data::Handle->new('Data_Not_There');
  },
  undef,
  "->new on a valid package with an Data_Not_There asplodes"
);

isa_ok( $e, 'Data::Handle::Exception' );

$handle = Data::Handle->new('Data');

seek $handle, -9, 0;

my $buffer;

read $handle, $buffer, 8, 0;

is( $buffer, '__DATA__', 'seek and read work properly on new instances' );

is(
  do {
    $handle = Data::Handle->new('Data');
    local $/ = undef;
    scalar <$handle>;
  },
  qq{Hello World.\n\n\nThis is a test file.\n},
  'Slurp contents works'
);

done_testing;
