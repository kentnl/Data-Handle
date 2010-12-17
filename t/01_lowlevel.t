
use strict;
use warnings;
use Test::More;

use Data::Handle;

use lib 't/lib';
use Data;

my $handle = Data::Handle->new('Data');

#isnt( $handle, undef, 'Data:: has a DATA symbol' );

diag( Data::Handle->_is_valid_data_tell('Data'));
#my $fh = Data::Handle->_get_data_symbol('Data');
#my $offset = Data::Handle->_get_start_offset('Data');
#
#diag( $offset );
#binmode( $fh, ':raw' );
#seek $fh, $offset - 9, 0;
#diag( <$fh> );
#seek $fh, $offset, 0 ;
#diag( <$fh> );

done_testing;
