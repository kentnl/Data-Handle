use strict;
use warnings;

package Data::Handle;

# ABSTRACT: A Very simple interface to the __DATA__  file handle.

use Package::Stash;

=head1 SYNOPSIS

    package Foo;

    sub bar {
        for ( 1 .. 10 ){
            my $handle = Data::Handle->new(__PACKAGE__);
            while(defined( my $_ = $handle->getline() ){
                print $_;
            }
        }
    }

    __DATA__
    Foo

=cut

=head1 DESCRIPTION

This Package serves as a very I<very> simple interface to a packages __DATA__ section.

Its primary purposes is to make successive accesses viable without needing to scan the file manually for the __DATA__ marker.

It does this mostly by recording the current position of the file handle on the first call to C<< ->new >>, and then re-using that position on every successive C<< ->new >> call,
which eliminates a bit of the logic for you.

=cut

=head1 WARNING

At present, this module does you no favours if something else earlier has moved the file handle position past
the __DATA__ section, or rewound it to the start of the file. This is an understood caveat, but nothing else
seems to have a good way around this either.

Hopefully, if other people B<*do*> decide to go moving your file pointer, they'll use this module to do it so
you your code doesn't break.

Also, unfortunately, due to the way this works, if 2 people both call get_fh on the same package in
co-operative code things might be a bit weird, but this is pretty inescapable if you're working with the
file handle interface anyway, and its going to be by default a pretty evil thing to do.
=cut

my %datastash;

sub new {
  my ( $class, $targetpackage ) = @_;
  if ( !$class->_has_data_symbol($targetpackage) ) {
    die $class->_e( "NoSymbol", "$targetpackage has no DATA symbol" );
  }
  if ( !$class->_is_valid_data_tell($targetpackage) ) {
    die $class->_e( "BadFilePos",
          "$targetpackage has a DATA symbol, but the filepointer"
        . " is well beyond the __DATA__ section.\n"
        . " We can't work out safely where it is.\n"
        . $class->_stringify_metadata($targetpackage)
        . "\n" );
  }
  my $self = {};
  $self->{start_offset}   = $class->_get_start_offset($targetpackage);
  $self->{targetpackage}  = $targetpackage;
  $self->{current_offset} = $class->_get_start_offset($targetpackage);
  $self->{filehandle}     = $class->_get_data_symbol($targetpackage);
  bless $self, $class;
  return $self;
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
    die $self->_e( 'Internal::BadGet', '_get_data_symbol was called when there is no data_symbol to get' );
  }
  return Package::Stash->new($package)->get_package_symbol('DATA');
}

sub _get_start_offset {
  my ( $self, $package ) = @_;
  if ( exists $datastash{$package}->{offset} ) {
    return $datastash{$package}->{offset};
  }
  if ( !$self->_has_data_symbol($package) ) {
    die $self->_e( 'Internal::BadGet', '_get_start_offset was called when there is no data_symbol to get' );
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
    die $self->_e( 'Internal::BadGet', '_is_valid_data_tell was called when there is no data_symbol to get' );
  }

  my $fh     = $self->_get_data_symbol($package);
  my $offset = $self->_get_start_offset($package);

  # The offset to the start of __DATA__ is 9 bytes because it includes the
  # trailing \n
  #
  seek $fh, $offset - 9, 0;
  read $fh, my $buffer, 9;
  seek $fh, $offset, 0;

  $datastash{$package}->{previous_bytes} = $buffer;

  if ( $buffer eq qq{__DATA_\n} ) {
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
    push @lines, "Offset : " . $datastash{$package}->{offset};
    push @lines, "Prelude : '" . $datastash{$package}->{previous_bytes} . "'";
    push @lines, "Valid: " . $datastash{$package}->{valid};
    return join "\n", @lines;
  }
}

# SUPER ULTRA LIGHT EXCEPTIONS.
#
{

  package Data::Handle::Exception;

  use overload '""' => sub {
    my $self = shift;
    return $self->{message} . "\n\n" . ( join qq{\n}, @{ $self->{stack} } ) . "\n\n";
  };

  sub new {
    my ( $class, $message, $stack ) = @_;
    my $self = {};
    $self->{message} = $message;
    $self->{stack}   = $stack;
    bless $self, $class;
    return $self;
  }

  1;

}
{
  my $dynaexceptions = { 'Data::Handle::Exception' => 1 };

  sub _gen {
    my ( $self, $fullclass, $parent ) = @_;
    my $code = sprintf q{package %s; our @ISA=("%s"); 1;}, $fullclass, $parent;

    eval $code or die qq{ Exception generating exception :[ $@ };
    $dynaexceptions->{$fullclass} = 1;
  }


  sub _e {
    my ( $self, $class, $message ) = @_;

    my $fullclass   = "Data::Handle::Exception::$class";
    my $parentclass = $fullclass;
    $parentclass =~ s/::[^:]+$//;

    if ( !exists $dynaexceptions->{$parentclass} ) {
      $self->_e( $parentclass, '' );
    }
    if ( !exists $dynaexceptions->{$fullclass} ) {
      $self->_gen( $fullclass, $parentclass );
    }
    my @stack;
    my $i = 0;
    while ( my @line = caller($i) ) {
      push @stack, sprintf( "%s:%s  %s: %s", $line[1], $line[2], $line[0], $line[3] );
      $i++;
    }
    return $fullclass->new( $message, \@stack );
  }

}
1;

