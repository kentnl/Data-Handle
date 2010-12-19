
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Data::Handle;

use lib 't/lib';
use Data;

my $output = "";

sub _diag {

  # diag(@_);
  $output .= $_ for @_;
}

is(
  exception {

    # Traditional Interface

    my $data = Data::Handle->new('Data');

    while (<$data>) {
      _diag($_);
    }

    seek $data, 0, 0;

    # IO::Handle - getline()

    while ( defined( my $foo = $data->getline() ) ) {
      _diag($foo);
    }

    $data->seek( 0, 0 );

    # IO::Handle - getlines()

    for ( $data->getlines() ) {
      _diag($_);
    }

    $data->seek( 0, 0 );

    # SLURPify

    {
      local $/ = undef;
      _diag( ">>slurp>>" . scalar <$data> . "<<slurp<<" );
    }

  },
  undef,
  'Example runs'
);

# diag( $output );
done_testing();
