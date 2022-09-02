requires 'perl', '5.008008';
requires 'strict';
requires 'warnings';

requires 'Sentinel';
requires 'NEXT';

on test => sub {
	requires 'Carp';
	requires 'Test::Lives';
	requires 'Test::More';
	requires 'lib';
};

# vim: ft=perl
