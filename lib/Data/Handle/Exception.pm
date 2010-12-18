use strict;
use warnings;

package Data::Handle::Exception;

# ABSTRACT: Super-light Weight Dependency Free Exception base.

=head1 SYNOPSIS

    use Data::Handle::Exception;
    Data::Handle::Exception->generate_exception(
        'Foo::Bar' => 'A Bar error occurred :('
    )->throw();

=cut

=head1 DESCRIPTION

L<Data::Handle>'s primary goal is to be somewhat "Infrastructural" in design, much like L<Package::Stash> is, being very low-level, and doing one thing, and doing it well, solving an issue with Perl's native implementation.

The idea is for more complex things to use this, instead of this using more complex things.

As such, a dependency on something like Moose would be overkill, possibly even detrimental to encouraging the use of this module.

So we've scrimped and gone really cheap ( for now at least ) in a few places to skip adding downstream dependencies, so this module is a really really nasty but reasonably straight forward exception class.

The actual Exception classes don't actually exist, they're automatically vivified when they're needed.
And we have some really nasty stack-trace collection support.

=cut

use overload '""' => sub {
  my $self = shift;
  return $self->{message} . "\n\n" . ( join qq{\n}, @{ $self->{stack} } ) . "\n\n";
};

=method new

    my @stack;
    my $i = Data::Handle::Exception->new(  $messageString, \@stack );

=cut

sub new {
  my ( $class, $message, $stack ) = @_;
  my $self = {};
  $self->{message} = $message;
  $self->{stack}   = $stack;
  bless $self, $class;
  return $self;
}

=method throw

    Data::Handle::Exception->new(  $messageString, \@stack )->throw();

=cut

sub throw {
  my $self = shift;
  require Carp;
  Carp::confess($self);
}

my $dynaexceptions = { 'Data::Handle::Exception' => 1 };

sub _gen {
  my ( $self, $fullclass, $parent ) = @_;
  ## no critic ( RequireInterpolationOfMetachars )
  my $code = sprintf q{package %s; our @ISA=("%s"); 1;}, $fullclass, $parent;

  ## no critic ( ProhibitStringyEval RequireCarping ProhibitPunctuationVars )
  eval $code or throw(qq{ Exception generating exception :[ $@ });
  $dynaexceptions->{$fullclass} = 1;
  return 1;
}

=method generate_exception

    my $i = Data::Handle::Exception->generate_exception(
        'Foo::Bar' => 'SomeMessage'
    );

    # $i isa Data::Handle::Exception::Foo::Bar
    # Data::Handle::Exception::Foo::Bar isa
    #    Data::Handle::Exception::Foo
    #
    # Data::Handle::Exception::Foo isa
    #   Data::Handle::Exception
    #
    # $i has a message and a stack-trace
    #

    $i->throw():


=cut

sub generate_exception {
  my ( $self, $class, $message ) = @_;

  my $fullclass   = "Data::Handle::Exception::$class";
  my $parentclass = $fullclass;
  $parentclass =~ s{
     ::[^:]+$
   }{}x;

  if ( !exists $dynaexceptions->{$parentclass} ) {
    $self->generate_exception( $parentclass, q{} );
  }
  if ( !exists $dynaexceptions->{$fullclass} ) {
    $self->_gen( $fullclass, $parentclass );
  }
  my @stack;
  my $i = 0;
  while ( my @line = caller $i ) {
    ## no critic ( ProhibitMagicNumbers )
    push @stack, sprintf q{%s:%s  %s: %s}, $line[1], $line[2], $line[0], $line[3];
    $i++;
  }
  return $fullclass->new( $message, \@stack );
}

1;

