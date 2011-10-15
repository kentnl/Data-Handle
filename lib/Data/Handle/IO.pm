
use strict;
use warnings;

package Data::Handle::IO;
BEGIN {
  $Data::Handle::IO::AUTHORITY = 'cpan:KENTNL';
}
{
  $Data::Handle::IO::VERSION = '0.01011704';
}

# ABSTRACT: A Tie Package so Data::Handle can look and feel like a normal handle.
#


sub TIEHANDLE {
  my $self   = shift;
  my $object = shift;
  return bless $object, $self;
}

sub _object {
  my $self = shift;
  return $self->{self};
}

## no critic (ProtectPrivateSubs)

sub READLINE { return shift->_object->_readline(@_) }
sub READ     { return shift->_object->_read(@_) }
sub GETC     { return shift->_object->_getc(@_) }
sub WRITE    { return shift->_object->_write(@_) }
sub PRINT    { return shift->_object->_print(@_) }
sub PRINTF   { return shift->_object->_printf(@_) }
sub EOF      { return shift->_object->_eof(@_) }
sub CLOSE    { return shift->_object->_close(@_) }
sub BINMODE  { return shift->_object->_binmode(@_) }
sub OPEN     { return shift->_object->_open(@_) }
sub FILENO   { return shift->_object->_fileno(@_) }
sub SEEK     { return shift->_object->_seek(@_) }
sub TELL     { return shift->_object->_tell(@_) }

1;

__END__
=pod

=head1 NAME

Data::Handle::IO - A Tie Package so Data::Handle can look and feel like a normal handle.

=head1 VERSION

version 0.01011704

=head1 DESCRIPTION

This is an internal component used by L<Data::Handle> used as a C<tie>
target to provide accessibility to the Perl Core functions, in order to
truly emulate a file-handle.

All the methods on this tie are essentially proxy methods that feed back to
L<Data::Handle> methods, so that all internal calls and all method calls can be coded the same way.

For instance: C<getc($fh)> maps to being the same as if you'd done C< $fh->_getc() >

You're not really supposed to use this package Directly though.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

