package # hide from PAUSE
	Foo;

use Carp ();
use Object::Properties qw( foo bar ),
	writable   => sub { Carp::croak('bah') if $_[1] eq 'XXX' },
	unwritable => sub { Carp::croak( $_[1] ) };

1;
