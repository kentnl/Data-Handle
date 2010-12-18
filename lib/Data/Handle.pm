use strict;
use warnings;

package Data::Handle;

# ABSTRACT: A Very simple interface to the __DATA__  file handle.

use Package::Stash;
require Carp;

=head1 SYNOPSIS

    package Foo;

    sub bar {
        my $handle = Data::Handle->new( __PACKAGE__ );
        while (<$handle>) {
            print $_;
        }
    }

    __DATA__
    Foo

=cut

=head1 DESCRIPTION

This Package serves as a very I<very> simple interface to a packages __DATA__ section.

Its primary purposes is to make successive accesses viable without needing to
scan the file manually for the __DATA__ marker.

It does this mostly by recording the current position of the file handle on
the first call to C<< ->new >>, and then re-using that position on every successive C<< ->new >> call,
which eliminates a bit of the logic for you.

At present, it only does a simple heuristic ( backtracking ) to verify the current position is B<immediately>
at the start of a __DATA__ section, but we may improve on this one day.

=cut

=head1 WARNING

At present, this module does you no favours if something else earlier has moved the file handle position past
the __DATA__ section, or rewound it to the start of the file. This is an understood caveat, but nothing else
seems to have a good way around this either. ( You can always rewind to the start of the file and use heuristics, but that is rather pesky ).

Hopefully, if other people B<do> decide to go moving your file pointer, they'll use this module to do it so
you your code doesn't break.

=cut

=head1 USAGE

C<Data::Handle->new()> returns a tied file-handle, and for all intents and purposes, it should
behave as if somebody had copied __DATA__ to its own file, and then done C<< open $fh, '<' , $file >>
on it, for every instance of the Data::Handle.

It also inherits from L<IO::File>, so all the methods it has that make sense to use should probably work
on this too,  i.e.:

    my $handle = Data::Handle->new( __PACKAGE__ );
    my @lines = $handle->getlines();


Also, all offsets are proxied in transit, so you can treat the file-handle as if byte 0 is the first byte of the data section.

    my $handle = Data::Handle->new( __PACKAGE__ );
    my @lines = $handle->getlines();
    seek $handle, 0, 0;
    local $/ = undef;
    my $line = scalar <$handle>; # SLURPED!

Also, the current position of each handle instance is internally tracked, so you can have as many
objects pointing to the same __DATA__ section but have their read mechanism uninterrupted by any others.

    my $handlea  = Data::Handle->new( __PACKAGE__ );
    my $handleb  = Data::Handle->new( __PACKAGE__ );

    seek $handlea, 10, 0;
    seek $handleb, 15, 0;

    read $handlea, my $buf, 5;

    read $handleb, my $bufa, 1;
    read $handleb, my $bufb, 1;

     $bufa eq $bufb;

Don't be fooled, it does this under the covers by a lot of C<seek>/C<tell> magic, but they shouldn't be a problem unless you are truly anal over speed.

=cut

my %datastash;
use Symbol qw( gensym );
use Scalar::Util qw( weaken );
use parent qw( IO::File );

=method new

    my $fh = Data::Handle->new( $targetpackage )

Where C<$targetpackage> is the package you want the __DATA__ section from.

=cut


sub new {
  my ( $class, $targetpackage ) = @_;
  if ( !$class->_has_data_symbol($targetpackage) ) {
    $class->_e( NoSymbol =>, "$targetpackage has no DATA symbol" )->throw();
  }
  if ( !$class->_is_valid_data_tell($targetpackage) ) {
    $class->_e( BadFilePos => "$targetpackage has a DATA symbol, but the filepointer"
        . " is well beyond the __DATA__ section.\n"
        . " We can't work out safely where it is.\n"
        . $class->_stringify_metadata($targetpackage)
        . "\n" )->throw();
  }

  my $sym  = gensym();
  my $xsym = $sym;
  weaken($xsym);
  require Data::Handle::IO;

  ## no critic( ProhibitTies )
  tie *{$sym}, 'Data::Handle::IO', { self => $xsym };
  ${ *{$sym} }{stash} = {};
  bless $sym, $class;
  $sym->_stash->{start_offset}   = $class->_get_start_offset($targetpackage);
  $sym->_stash->{targetpackage}  = $targetpackage;
  $sym->_stash->{current_offset} = $class->_get_start_offset($targetpackage);
  $sym->_stash->{filehandle}     = $class->_get_data_symbol($targetpackage);
  return $sym;

}

sub _stash {
  my $self = shift;
  return ${ *{$self} }{stash};
}

sub _has_data_symbol {
  my ( $self, $package ) = @_;
  my $object = Package::Stash->new($package);
  return unless $object->has_package_symbol('DATA');
  my $fh = $object->get_package_symbol('DATA');
  return defined fileno *{$fh};
}

sub _get_data_symbol {
  my ( $self, $package ) = @_;
  if ( !$self->_has_data_symbol($package) ) {
    $self->_e( 'Internal::BadGet', '_get_data_symbol was called when there is no data_symbol to get' )->throw();
  }
  return Package::Stash->new($package)->get_package_symbol('DATA');
}

sub _get_start_offset {
  my ( $self, $package ) = @_;
  if ( exists $datastash{$package}->{offset} ) {
    return $datastash{$package}->{offset};
  }
  if ( !$self->_has_data_symbol($package) ) {
    $self->_e( 'Internal::BadGet', '_get_start_offset was called when there is no data_symbol to get' )->throw();
  }
  my $fd       = $self->_get_data_symbol($package);
  my $position = tell $fd;

  $datastash{$package}->{offset} = $position;

  return $position;
}

sub _is_valid_data_tell {
  my ( $self, $package ) = @_;
  if ( exists $datastash{$package} && $datastash{$package}->{valid} == 1 ) {
    return 1;
  }
  if ( !$self->_has_data_symbol($package) ) {
    $self->_e( 'Internal::BadGet', '_is_valid_data_tell was called when there is no data_symbol to get' )->throw();
  }

  my $fh     = $self->_get_data_symbol($package);
  my $offset = $self->_get_start_offset($package);

  # The offset to the start of __DATA__ is 9 bytes because it includes the
  # trailing \n
  #
  my $checkfor = qq{__DATA__\n};
  seek $fh, ( $offset - length $checkfor ), 0;
  read $fh, my $buffer, length $checkfor;
  seek $fh, $offset, 0;

  $datastash{$package}->{previous_bytes} = $buffer;

  if ( $buffer eq $checkfor ) {
    $datastash{$package}->{valid} = 1;
    return 1;
  }
  else {
    $datastash{$package}->{valid} = 0;
    return;
  }
}

sub _stringify_metadata {
  my ( $self, $package ) = @_;
  my @lines = ();
  if ( not exists $datastash{$package} ) {
    push @lines, "Nothing known about $package\n";
    return join "\n", @lines;
  }
  else {
    push @lines, q{Offset : } . $datastash{$package}->{offset};
    push @lines, q{Prelude : '} . $datastash{$package}->{previous_bytes} . q{'};
    push @lines, q{Valid: } . $datastash{$package}->{valid};
    return join "\n", @lines;
  }
}

sub _e {
  require Data::Handle::Exception;
  $_[0] = 'Data::Handle::Exception';
  goto \&Data::Handle::Exception::generate_exception;    # stack duck
}

sub _readline {
  my ( $self, @args ) = @_;
  if (@args) {
    $self->_e( 'Data::Handle::API::Invalid::Params' => '_readline() takes no parameters' )->throw();
  }
  my $start = $self->_stash->{current_offset};
  my $fh    = $self->_stash->{filehandle};
  seek $fh, $self->_stash->{current_offset}, 0;
  if (wantarray) {
    my @result = <$fh>;
    $self->_stash->{current_offset} = tell $fh;
    return @result;
  }
  my $result = <$fh>;
  $self->_stash->{current_offset} = tell $fh;

  #print "red: $start -> " . $self->_stash->{current_offset};
  return $result;
}

sub _read {
  my ( $self, undef, $len, $offset ) = @_;

  ## no critic ( ProhibitMagicNumbers )
  if ( scalar @_ < 3 or scalar @_ > 4 ) {
    $self->_e( 'Data::Handle::API::Invalid::Params' => '_read() takes 2 or 3 parameters.' )->throw();
  }

  my $fh = $self->_stash->{filehandle};
  seek $fh, $self->_stash->{current_offset}, 0;
  my $return;
  if ( defined $offset ) {
    $return = read $fh, $_[1], $len, $offset;
  }
  else {
    $return = read $fh, $_[1], $len;
  }
  $self->_stash->{current_offset} = tell $fh;
  return $return;
}

sub _getc {
  my ($self) = @_;
  if ( scalar @_ > 1 ) {
    $self->_e( 'Data::Handle::API::Invalid::Params' => '_get() takes 0 parameters.' )->throw();
  }

  my $fh = $self->_stash->{filehandle};
  seek $fh, $self->_stash->{current_offset}, 0;
  my $return = getc $fh;
  $self->_stash->{current_offset} = tell $fh;
  return $return;
}

sub _seek {
  my ( $self, $position, $whence ) = @_;

  ## no critic ( ProhibitMagicNumbers )

  if ( scalar @_ != 3 ) {
    $self->_e( 'Data::Handle::API::Invalid::Params' => '_seek() takes 2 params.' )->throw();
  }

  my $fh = $self->_stash->{filehandle};

  if ( $whence == 0 ) {
    $position = $self->_stash->{start_offset} + $position;
  }
  elsif ( $whence == 1 ) {
    $whence   = 0;
    $position = $self->_stash->{current_offset} + $position;
  }
  elsif ( $whence == 2 ) {
  }
  else {
    $self->_e( 'Data::Handle::API::Invalid::Whence' => 'Expected whence values are 0,1,2' )->throw();
  }
  my $return = seek $fh, $position, $whence;
  $self->_stash->{current_offset} = tell $fh;
  return $return;
}

sub _tell {
  my ($self) = shift;
  if (@_) {
    $self->_e( 'Data::Handle::API::Invalid::Params' => '_tell() takes no params.' )->throw();
  }
  return $self->_stash->{current_offset} - $self->_stash->{start_offset};
}

sub _fileno {
  return;
}

sub _open {
  return shift->_e( 'Data::Handle::API::Invalid' => '_open() is invalid on Data::Handle.' )->throw();
}

sub _binmode {
  return
    shift->_e( 'Data::Handle::API::NotImplemented' => '_binmode() is difficult on Data::Handle and not implemented yet.' )
    ->throw();
}

sub _close {
  return shift->_e( 'Data::Handle::API::Invalid' => '_close() is invalid on Data::Handle' )->throw();
}

sub _eof {
  my $self = shift;
  seek $self->_stash->{filehandle}, $self->_stash->{current_offset}, 0;
  return eof $self->_stash->{filehandle};
}

sub _printf {
  return shift->_e( 'Data::Handle::API::Invalid' => '_printf() is invalid on Data::Handle.' )->throw();

}

sub _print {
  return shift->_e( 'Data::Handle::API::Invalid' => '_print() is invalid on Data::Handle.' )->throw();

}

sub _write {
  return shift->_e( 'Data::Handle::API::Invalid' => '_write() is invalid on Data::Handle.' )->throw();

}

=head1 CREDITS

Thanks to LeoNerd and anno, from #perl on irc.freenode.org,
they were most helpful in helping me grok the magic of C<tie> that
makes the simplicity of the interface possible.

=cut
1;

