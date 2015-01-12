use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Object::Properties ();

use lib 't/lib';

sub dies_like ($$;$) {
	my ( $cb, $rx, $name ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	local $@;
	ref $cb ? eval { $cb->() } : eval $cb;
	like $@, $rx, $name;
}

# Define a class
require_ok 'Foo';

# Create a trivial object
for my $obj ( Foo->new ) {
	isa_ok $obj, 'Foo';
	isa_ok $obj, 'Object::Properties::Base';
	is 0+keys %$obj, 0, 'Empty object is empty';
}

# Create a real object
for my $obj ( Foo->new( foo => 1, bar => 2, baz => 3 ) ) {
	isa_ok $obj, 'Foo';
	isa_ok $obj, 'Object::Properties::Base';
	is scalar( keys %$obj ), 3, 'Object contains expect elements';
	is $obj->foo, 1, '->foo';
	is $obj->bar, 2, '->bar';
	dies_like sub { $obj->baz }, qr/(?)/, '->baz returns an error';
	is $obj->{'baz'}, 3, '->{baz} does contain value';
	$obj->foo = 42;
	is $obj->foo, 42, '->foo = new_value';
}

# Trigger the constructor exception
dies_like 'package Bar; use Object::Properties q"bad thing";',
	qr/Invalid accessor name/, 'Bad accessor names are rejected';

dies_like sub { Foo->new( unwritable => 'hello!' ) }, qr/hello!/, 'Instantiation calls checks';

dies_like sub { Foo->new->unwritable = 'hello!' }, qr/hello!/, 'Writing calls checks';

for my $obj ( Foo->new ) {
	$obj->writable = 42;
	is $obj->writable, 42, '->writable = new_value';
	dies_like sub { $obj->writable = 'XXX' }, qr/bah/, '->writable = bad_value';
}

# Define another class
require_ok 'Bar';

# Create a trivial object
for my $obj ( Bar->new ) {
	isa_ok $obj, 'Bar';
	isa_ok $obj, 'Baz';
	is $obj->isa( 'Object::Properties::Base' ), !1, 'Is not an Object::Properties::Base';
	is scalar( keys %$obj ), 0, 'Empty object is empty';
}

# Create a real object
for my $obj ( Bar->new( foo => 1, bar => 2, baz => 3 ) ) {
	isa_ok $obj, 'Bar';
	isa_ok $obj, 'Baz';
	is scalar( keys %$obj ), 3, 'Object contains expect elements';
	is $obj->foo, 1, '->foo';
	is $obj->bar, 2, '->bar';
	dies_like sub { $obj->baz }, qr/(?)/, '->bar returns an error';
	is $obj->{'baz'}, 3, '->{baz} does contain value';
}

done_testing;
