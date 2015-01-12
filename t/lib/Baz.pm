package # hide from PAUSE
	Baz;

sub new { my $class = shift; bless { @_ }, $class }

1;
