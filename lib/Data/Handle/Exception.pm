use strict;
use warnings;

package Data::Handle::Exception;
BEGIN {
  $Data::Handle::Exception::VERSION = '0.01011617';
}

# ABSTRACT: Super-light Weight Dependency Free Exception base.



use overload '""' => \&stringify;
use Scalar::Util qw( blessed );
use Carp ();
use Term::ANSIColor qw( :constants );


sub new {
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
  return $self;
}


sub throw {
  my $self = shift;
  if ( not blessed $self ) {
    $self = $self->new();
  }
  my $message = shift;

  my @stack      = ();
  my @stacklines = ();

  my $callerinfo;

  if ( not defined &Carp::caller_info ) {
      ## no critic (RequireBarewordIncludes, ProhibitPunctuationVars )
    require 'Carp/Heavy.pm' unless $^O eq 'MSWin32';
    require 'Carp\Heavy.pm' if $^O eq 'MSWin32';
  }
  $callerinfo = \&Carp::caller_info;
  {    # stolen parts  from Carp::ret_backtrace
    my ($i) = 0;

    my $tid_msg = q{};
    if ( defined &threads::tid ) {
      my $tid = threads->tid;
      $tid_msg = " thread $tid" if $tid;
    }

    my %i = $callerinfo->($i);

    push @stack, \%i;
    push @stacklines, sprintf q{Exception '%s' thrown at %s line %s%s}, blessed($self), $i{file}, $i{line}, $tid_msg;

    while ( my %j = $callerinfo->( ++$i ) ) {
      push @stack, \%j;
      push @stacklines, sprintf q{%s called at %s line %s%s}, $j{sub_name}, $j{file}, $j{line}, $tid_msg;
    }
  }
  $self->{message}    = $message;
  $self->{stacklines} = \@stacklines;
  $self->{stack}      = \@stack;

  Carp::confess($self);
}

{
  ## no critic ( RequireInterpolationOfMetachars )
  my $s = q{(\x2F|\x5c)};
  my $d = q{\x2E};
  ## use critic
  my $yellow = qr{
      ${s}Try${s}Tiny${d}pm
      |
      ${s}Test${s}Fatal${d}pm
  }x;
  my $green = qr{
    ${s}Data${s}Handle${d}pm
    |
    ${s}Data${s}Handle${s}
  }x;

  sub _color_for_line {
    my $line = shift;
    return YELLOW if ( $line =~ $yellow );
    return GREEN  if ( $line =~ $green );
    return q{};
  }
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

for (qw( API::Invalid API::Invalid::Whence API::Invalid::Params API::NotImplemented Internal::BadGet NoSymbol BadFilePos )) {
  __PACKAGE__->_gen_tree("Data::Handle::Exception::$_");
}

1;


__END__
=pod

=head1 NAME

Data::Handle::Exception - Super-light Weight Dependency Free Exception base.

=head1 VERSION

version 0.01011617

=head1 SYNOPSIS

    use Data::Handle::Exception;
    Data::Handle::Exception->generate_exception(
        'Foo::Bar' => 'A Bar error occurred :('
    )->throw();

=head1 DESCRIPTION

L<Data::Handle>'s primary goal is to be somewhat "Infrastructural" in design, much like L<Package::Stash> is, being very low-level, and doing one thing, and doing it well, solving an issue with Perl's native implementation.

The idea is for more complex things to use this, instead of this using more complex things.

As such, a dependency on something like Moose would be overkill, possibly even detrimental to encouraging the use of this module.

So we've scrimped and gone really cheap ( for now at least ) in a few places to skip adding downstream dependencies, so this module is a slightly nasty but reasonably straight forward exception class.

The actual Exception classes don't actually have their own sources, they're automatically generated when L<Data::Handle::Exception> is loaded.
And we have some really nice backtraces stolen from Carp's code, with some sexy coloured formatting. See L/stringify> for details.

=head1 METHODS

=head2 new

    my @stack;
    my $i = Data::Handle::Exception->new(  $messageString, \@stack );

=head2 throw

    Data::Handle::Exception->new(  $messageString, \@stack )->throw();

=head2 stringify

Turns this stacktrace into a string.

    $exception->stringify();

    my $str = "hello " . $exception . " world";

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

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

