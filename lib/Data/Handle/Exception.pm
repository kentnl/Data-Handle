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

The actual Exception classes don't actually have their own sources, they're automatically generated when L<Data::Handle::Exception> is loaded.
And we have some really nice backtraces stolen from Carp's code.

If you have a coloured terminal, then L<Term::ANSIColor> is used to highlight lines based on how likely they are to be relevant to diagnosis.

=over 4

=item Green - From Data::Handle and is likely to be "safe", its where the error is being reported from, so its useful informationally, but the problem is probably elsewhere.

=item Yellow - Sources we're confident its unlikely to be a source of problems, currently

=over 4

=item Try::Tiny

=item Test::Fatal

=back

=item White - Everything Else, the place the problem is most likely to be.

=back

=cut

use overload '""' => \&stringify;
use Scalar::Util qw( blessed );
use Carp ();
use Term::ANSIColor qw( :constants );

=method new

    my @stack;
    my $i = Data::Handle::Exception->new(  $messageString, \@stack );

=cut

sub new {
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
  return $self;
}

=method throw

    Data::Handle::Exception->new(  $messageString, \@stack )->throw();

=cut

sub throw {
  my $self = shift;
  if ( not blessed $self ) {
    $self = $self->new();
  }
  my $message = shift;

  my @stack      = ();
  my @stacklines = ();

  {    # stolen parts  from Carp::ret_backtrace
    my ( $i, @error ) = ( -1, $message );
    my $mess;
    my $err = join '', @error;
    $i++;

    my $tid_msg = '';
    if ( defined &threads::tid ) {
      my $tid = threads->tid;
      $tid_msg = " thread $tid" if $tid;
    }

    my %i = Carp::caller_info($i);

    push @stack,      \%i;
    push @stacklines, "Exception '" . blessed($self) . "' Thrown at $i{file} line $i{line}$tid_msg";

    while ( my %i = Carp::caller_info( ++$i ) ) {
      push @stack,      \%i;
      push @stacklines, "$i{sub_name} called at $i{file} line $i{line}$tid_msg";
    }
  }
  $self->{message}    = $message;
  $self->{stacklines} = \@stacklines;
  $self->{stack}      = \@stack;

  Carp::confess($self);
}

sub _color_for_line {
  my $line = shift;
  return YELLOW if ( $line =~ qr{[/\\]Try[/\\]Tiny\.pm} );
  return YELLOW if ( $line =~ qr{[/\\]Test[/\\]Fatal\.pm} );
  return GREEN  if ( $line =~ qr{[/\\]Data[/\\]Handle(\.pm|[/\\])} );
  return '';
}

sub stringify {
  my $self       = shift;
  my $message    = $self->{message};
  my @stacklines = @{ $self->{stacklines} };

  my $out       = $message . "\n\n";
  my $throwline = shift @stacklines;
  $out .= _color_for_line($throwline) . $throwline . RESET;
  my $i = 2;
  for (@stacklines) {
    $out .= "\n " . _color_for_line($_) . "$i.  " . $_ . RESET;
    $i++;
  }
  return $out . "\n\n";
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

sub _gen_tree {
  my ( $self, $class ) = @_;
  my $parent = $class;
  require Carp;

  #    Carp::carp("Generating $class.");
  $parent =~ s{
     ::[^:]+$
    }{}x;
  if ( !exists $dynaexceptions->{$parent} ) {
    $self->_gen_tree($parent);
  }
  if ( !exists $dynaexceptions->{$class} ) {
    $self->_gen( $class, $parent );
  }
  return $class;
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

  # $class =~ s/^(Data::Handle::Exception::|)//x;  # remove prefix if already there.
  my $fullclass = $self->_gen_tree("Data::Handle::Exception::$class");

  if ($message) {
    return $fullclass->new()->throw($message);
  }
  else {
    return $fullclass->new();
  }

}

for (qw( API::Invalid API::Invalid::Params API::NotImplemented Internal::BadGet NoSymbol BadFilePos )) {
  __PACKAGE__->_gen_tree("Data::Handle::Exception::$_");
}

1;

