# Before `make install' is performed this script should be
#runnable with `make test'. After `make install' it should work as
#`perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 11 };
use Text::Align::WagnerFischer 'distance';
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
warn "Testing Text::Align::WagnerFischer\n";
warn "testing distance drop-in\n";

ok(distance([0,1,2],'foo', 'food'), 1,
   '[0m,1id,2s], foo => food');

ok(distance([0, 1, 2], 'feed', 'food'), 4,
   '[0m,1id,2s], feed => food');

ok(distance([0, 1, 1.9], 'foo', 'food'), 1,
   '[0m,1id,1.9s], foo => food');
ok(distance([0, 1, 1.9], 'feed', 'food'), 3.8,
   '[0m,1id,1.9s], feed => food');
ok(distance([0, 1, 1.9], 'foo', 'bob'), 3.8,
   '[0m,1id,1.9s], foo => bob');
ok(distance([0, 1, 1.9], 'booze', 'boolean'), 3.9,
   '[0m,1id,1.9s], booze => boolean');

ok(distance([0,1,1], 'mccartney', 'mcarthur'), 4,
   '[0m,1id,1s], mccartney => mcarthur');

warn "testing as_strings interface\n";

my $al =
  Text::Align::WagnerFischer->new(weights => [0,1,1],
				  left => 'mccartney',
				  right => 'mcarthur'
				  );
ok(join("\n", $al->as_strings()), scalar $al->as_strings());

ok(scalar $al->as_strings, "mccartney\nm-carthur");
ok(scalar $al->as_strings(join => ' '),
'm c c a r t n e y
m - c a r t h u r');
