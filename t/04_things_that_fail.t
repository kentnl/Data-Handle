use strict;
use warnings;

use Test::More 0.96;

use Test::Fatal;
use Data::Handle;

use lib 't/lib';
use Data;

my ( $handle, $e );

isnt(
  $e = exception {
    Data::Handle->_get_data_symbol('Data_That_Isn\'t_there');
  },
  undef,
  '_get_data_symbol Fails if DATA is not there'
);

my $needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::Internal::BadGet', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::Internal',         'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception',                   'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->_get_start_offset('Data_That_Really_Isn\'t_there');
  },
  undef,
  '_get_start_offset Fails if DATA is not there.'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::Internal::BadGet', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::Internal', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->_is_valid_data_tell('Data_That_Really_Isn\'t_there_at_all');
  },
  undef,
  '_is_valid_data_tell Fails if DATA is not there.'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::Internal::BadGet', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::Internal', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_readline( 1, 2, 3 );
  },
  undef,
  '_readline Fails with params'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid::Params', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_read(1);
  },
  undef,
  '_read Fails with < 2 params'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid::Params', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_read( 1, 2, 3, 4 );
  },
  undef,
  '_read Fails with > 3 params'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid::Params', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_getc(1);
  },
  undef,
  '_getc Fails with params'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid::Params', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_seek(1);
  },
  undef,
  '_seek Fails with params !=2'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid::Params', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_seek(1,4);
  },
  undef,
  '_seek Fails with whences not 0-2'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid::Whence', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_tell(1);
  },
  undef,
  '_tell Fails with params'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid::Params', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_eof(5);
  },
  undef,
  '_eof Fails with params other than (1)'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid::Params', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

isnt(
  $e = exception {
    Data::Handle->new('Data')->_binmode();
  },
  undef,
  '_binmode Fails.'
);

$needdiag = 0;
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::NotImplemented', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
$needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
diag($e) if $needdiag;

for my $meth (qw( _open _close _printf _print _write )) {
  isnt(
    $e = exception {
      my $instance = Data::Handle->new('Data');
      my $method   = $instance->can($meth);
      $method->($instance);
    },
    undef,
    $meth . ' Fails'
  );

  $needdiag = 0;
  $needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API::Invalid', 'Expected Exception Type' );
  $needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception::API', 'Expected Exception Type' );
  $needdiag = 1 unless isa_ok( $e, 'Data::Handle::Exception', 'Expected Exception Type' );
  diag($e) if $needdiag;
}

done_testing;
