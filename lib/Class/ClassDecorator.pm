package Class::ClassDecorator;

use strict;

use vars qw($VERSION);

$VERSION = 0.01;

use NEXT;

# Given a set of classes like Foo::Base, Foo::Bar, and Foo::Baz, we
# end up with a hierarchy like this:
#
#              Foo::Baz  Foo::Bar  Foo::Base
#                  \         |         /
#                   \        |         /
#        MadeBy::Class::ClassDecorator::Class000000000
#
# As long as all the top classes (excluding Foo::Base) use NEXT::
# instead of SUPER::, it works.
#

my %Cache;
sub decorate
{
    unless ( @_ > 1 )
    {
        require Carp;
        Carp::croak( "Cannot call hierarchy function with only a single class name.\n" );
    }

    # class names should never have spaces in them
    my $key = join ' ', @_;

    return $Cache{$key} if $Cache{$key};

    my $name = _make_name();

    {
        no strict 'refs';
        @{"$name\::ISA"} = ( reverse @_ );
    }

    return $Cache{$key} = $name;
}

my $Base = 'MadeBy::Class::ClassDecorator::Class';
my $Num = 0;

sub _make_name { sprintf( '%s%09d', $Base, $Num++ ) }


1;

__END__


=head1 NAME

Class::ClassDecorator - Dynamically decorate classes instead of objects using NEXT

=head1 SYNOPSIS

  use Class::ClassDecorator;

  my $class = Class::ClassDecorator::decorate( 'Foo::Base' => 'Foo::Bar' => 'Foo::Baz' );

  my $object = $class->new;

  # may be implemented in any of the three classes specified.
  $object->foo();

=head1 DESCRIPTION

This module provides some syntactic sugar for dynamically constructing
a unique subclass which exists solely to represent a set of
decorations to a base class.

This is useful when you have a base module and you want to add
different behaviors (decorations) to it at a class level, as opposed
to decorating a single object.

So for example, given a base class of C<Foo>, and possible decorating
classes C<Foo::WithCache>, C<Foo::Persistent>, and C<Foo::Oversize>,
we could construct new classes that used any possible combination of
the decorating classes.

With regular inheritance, we'd have to create many classes like
C<Foo::PersisentWithCache> and C<Foo::OversizePersistent> and so on.
Plus we'd still need to use C<NEXT> from within the decorating classes
or risk breaking another decorating classes behavior, because it
expects to override certain methods.

With C<NEXT>, we can easily implement our desired behavior by creating
a single subclass that inherits from all of the decorating classes
C<and> the base class.

So to implement a C<Foo> subclass that incorporate persistence and
caching, we could create a hierarchy like:

  Foo::Persistent    Foo::WithCache    Foo
       \                 |              /
        \                |             /
         our subclass here

This module automates the create of that subclass.


=head1 USAGE

Simply call the C<decorate()> function with a list of classes,
starting with the base class you want to decorate, followed by each
decorator.  The function returns a string containing the new class
name.

The created classes are cached, so multiple calls with the same
arguments always return the same subclass name.

The order of the arguments is significant.  Methods are searched for
in last to first order, so that the base class is called last.  With
our "persistent caching Foo" example from the
L<DESCRIPTION|DESCRIPTION>, we can pretend that we have created a
hierarchy like this:

      Foo
       |
     Foo::WithCache
       |
     Foo::Persistent
       |
     our subclass here

=head1 DECORATING CLASS COOPERATION

Decorating classes B<must> always use C<NEXT::> to call methods for
classes "above" them in the (fictional) hierarchy, rather than
C<SUPER::>.

Decorating classes B<must not> actually inherit from the base class.
They are, of course, free to inherit from other classes if they wish,
but the author should take care in their use of C<NEXT::> versus
C<SUPER::> here.

=head1 SUPPORT

Nag the author via email at autarch@urth.org.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

Thanks to Ken Fox for suggesting this implementation.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
