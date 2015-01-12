use 5.006;
use strict;
use warnings;

package Object::Properties;

# ABSTRACT: minimal-ceremony class builder

use Import::Into ();
use Class::XSAccessor constructor => 'NEW';
use Package::Stash::XS ();
use Package::Stash ();
use Sentinel ();

# separate sub to keep the closed-over pad small
sub _make_build {
	my $NEW = \&NEW;
	my @checked = @_;
	return sub {
		my $self = &$NEW;
		my @k = grep { exists $self->{ $_ } } @checked;
		my @v = delete @$self{ @k };
		for my $i ( 0 .. $#k ) { $self->$_ = $v[$i] for $k[$i] }
		return $self;
	};
}

# dito separate sub
sub _make_accessor {
	my ( $prop, $get, $check ) = @_;
	my $set = sub { &$check or $_[0]{ $prop } = $_[1] };
	return sub : lvalue { Sentinel::sentinel get => $get, set => $set, obj => $_[0] };
}

sub import {
	my $class = shift;
	my $pkg = caller;

	my ( @r, %w );
	for ( @_ ) {
		$w{ $r[-1] } = $_, next if 'CODE' eq ref and @r;
		die "Invalid accessor name '$_'" unless /\A[^\W\d]\w*\z/;
		push @r, $_;
	}

	Class::XSAccessor->import::into( $pkg, getters => { map { ($_) x 2 } @r } );

	my $stash = Package::Stash->new( $pkg );

	while ( my ( $prop, $check ) = each %w ) {
		my $sym = '&' . $prop;
		my $getter = $stash->get_symbol( $sym );
		$stash->add_symbol( $sym, _make_accessor $prop, $getter, $check );
	}

	$stash->add_symbol( '&NEW', _make_build keys %w );

	my $ISA = $stash->get_or_add_symbol( '@ISA' );
	@$ISA = __PACKAGE__ . '::Base' unless @$ISA;

	return 1;
}

package Object::Properties::Base;

sub new { shift->NEW( @_ ) }

1;

__END__

=head1 SYNOPSIS

 package Someclass;
 use Object::Properties foo => \&_check_foo, qw( bar baz );
 sub _check_foo {
     croak 'Someclass "foo" property may not be a reference'
         if ref $_[1];
 }

Meanwhile, elsewhere:

 my $obj = Someclass->new( bar => 7 );
 say $obj->bar; # 7
 $obj->foo = 42;
 say $obj->foo; # 42
 $obj->foo = \1; # croaks
 $obj->bar = 42; # dies

=head1 DESCRIPTION

This is a class builder with a very minimal API and support for efficient
validated lvalue accessors.

=head1 INTERFACE

The module's C<import> method accepts a list of field names and sets up an
accessor for each of them in the package it was invoked from:

 use Object::Properties qw( foo bar );

Fields are read-only by default, unless the name of the field is followed by
a reference to a function, in which case it will be a read-write field:

 use Object::Properties page => \&_check_page;

Any write to a read-write field will invoke the function associated with it,
with the the object instance passed to it as its first argument and the new
value for the field as its second argument. The function may do with this value
whatever it wishes to:

 sub _check_page {
     my ( $self, $value ) = @_;
     croak 'Cannot page past the end' if $value > $self->max_page;
 }

The return value of this function is very important: it signals whether the
function has fully handled the value itself. A true value means everything is
done. A false value means that the new field value should be stored. This is so
you can write a simple validator for the value (illustrated above) just as well
as handle the whole assignment yourself:

 sub _munge_hostname {
     my ( $self, $value ) = @_;
     $self->{'hostname'} = lc $value;
     1;
 }

A class method called C<NEW> will be exported into your package. This method
creates a blessed hash from its arguments and invokes the function associated
with each writable field supplied by the caller (in some random order), so that
a new instance will be validated during construction. You will probably want to
call C<NEW> from your constructor:

 sub new { shift->NEW( @_ ) }

But if that is all your constructor would do, you will not need to write it:
C<Object::Properties::Base> contains such a C<new> method and will be added to
your C<@ISA> if that is empty.

=head1 SEE ALSO

The biggest difference between this module and all of its competition is that
it is decidedly B<not> pure-Perl. This is inevitably so due to the desire for
efficient validated lvalue accessors. Might as well go all out and get very
fast read-only accessors too, then.

=over 4

=item * L<Object::Tiny>

=item * L<Object::Tiny::RW>

=item * L<Object::Tiny::Lvalue>

=item * L<Class::Tiny>

=item * L<Moo>

=item * L<MooX::LvalueAttribute>

=back
