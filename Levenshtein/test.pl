# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 12 };
use Text::Align::Levenshtein 'distance';
ok(1); # If we made it this far, we're ok.

#########################
warn "Testing Text::Align::Levenshtein\n";
warn "testing distance drop-in\n";

ok(distance('foo', 'food'),1, 'foo => food');
ok(distance('food', 'foo'),1, 'food => foo');

ok(distance('fed', 'fad'), 1, 'fed => fad');

ok(distance('fed', 'feed'),1, 'fed => feed');
ok(distance('feed', 'fed'),1, 'feed => fed');

ok(distance('foo', 'bob'), 2, 'foo => bob');
ok(distance('foo', 'bar'), 3, 'foo => bar');

ok(distance('booze', 'food'), 3, 'booze => food');

# Gates & Torvalds are 1 closer than their OSes
ok(distance('Windows', 'Linux'), 5, 'Windows => Linux');
ok(distance('Bill', 'Linus'), 4, 'Bill => Linus');

warn "testing the as_strings method for levenshtein";
my $al =
  Text::Align::Levenshtein->new(left => 'pikachu', right => 'achoo');
ok($al->as_strings(separator => "\t"), "pikach-u\t---achoo");

my $al = Text::Align::Levenshtein->new(left => 'foo',
				       right => 'foe',
				       keepgrid => 1,
				      );
print $al->dump_grid(), "\n";

print "\n\n";
my $al = Text::Align::Levenshtein->new(left => 'foo',
				       right => 'foot',
				       keepgrid => 1,
				      );
print $al->dump_grid(), "\n";
