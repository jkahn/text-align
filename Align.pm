﻿package Text::Align;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.06';
##################################################################
use Carp;
use utf8; # character semantics, please
##################################################################
# CONSTANTS
##################################################################
# define shorthands for private hashkeys -- nobody else can stomp on
# 'em (by accident) if we give nice complex names like this

# dynamic -- used during alignment
use constant _ACTIONS => __PACKAGE__ . "::actions";
# the current cell being evaluated
use constant _POSX => __PACKAGE__ . "::posx";
use constant _POSY => __PACKAGE__ . "::posy";
# the current position of the backtrace
use constant _CURRTRACE => __PACKAGE__ . '::currtrace';
use constant _BTX => __PACKAGE__ . "::btx";
use constant _BTY => __PACKAGE__ . "::bty";

# the results
use constant _PATH => __PACKAGE__ . "::path"; # key for arrayref
use constant _COST => __PACKAGE__ . "::cost"; # key for scalar value
# keys for the items compared themselves
use constant _LEFT => __PACKAGE__ . "::left";
use constant _RIGHT => __PACKAGE__ . "::right";

use constant TRACE_WEIGHTS => 0;
##################################################################
# CLASS METHODS
##################################################################
sub costs {
    my $class = shift;
    my ($args) = shift;
    my $left = shift;

    my @distances;
    foreach my $right (@_) {
	my $alignment =
	  $class->new(%{$args}, left => $left, right => $right);
	push @distances, $alignment->cost();
    }
    if (wantarray) {
	return @distances;
    }
    else {
	return $distances[0];
    }
}
##################################################################
# CONSTRUCTOR
##################################################################
sub new {
    my $class = shift;
    my (%args) = @_;
    my ($self) = {};
    bless $self, $class;

    # check for user mistakes -- forgot to include a param?
    if ( not defined $args{left} ) {
	croak "no left key provided to new()";
    }
    elsif ( not defined $args{right} ) {
	croak "no right key provided to new()";
    }

    $self->init(%args);
    $self->align($args{left}, $args{right});

    return $self;
}
##################################################################
# accessor methods - primitives
##################################################################
sub pairwise {
    my $self = shift;
    return @{$self->{_PATH()}};
}
##################################################################
sub cost {
    my $self = shift;
    return $self->{_COST()};
}
##################################################################
sub as_lists {
    # returns two parallel arrays
    my $self = shift;

    my $class = ref($self);
    carp "as_lists not called in list context" if not wantarray;

    return $class->_as_lists($self->pairwise());
}
##################################################################
sub _as_lists {
    # class method, returns trace as parallel lists
    my $class = shift;
    my (@left, @right);
    foreach (@_) {
	push @left, $_->[0];
	push @right, $_->[1];
    }
    return [@left], [@right];
}
##################################################################
# instance method -- returns trace as strings
sub as_strings {
    my $self = shift;
    my $class = ref($self);
    my (%args) = @_;
    my ($left, $right) = $self->as_lists();
    return $class->_as_strings(%args, left => $left, right => $right);
}
##################################################################
# class method; doesn't need self. can be used for tracing
sub _as_strings {
    my $class = shift;
    my (%args) = @_;
    # set default characters
    if (not defined wantarray) {
	carp "as_strings called in void context";
    }
    my ($join, $pad, $separator, $deleted) = ('', ' ', "\n", '-');
    if (defined $args{join}) {
	$join = $args{join};
	delete $args{join};
    }
    if (defined $args{pad}) {
	$pad = $args{pad};
	delete $args{pad};
	if (not length $pad) {
	    croak "pad character '$pad' provided has zero length!\n";
	}
    }
    if (defined $args{separator}) {
	$separator = $args{separator};
	delete $args{separator};
	if (wantarray) {
	    carp "separator key defined, but as_strings called ",
	      "in scalar or void context!";
	}
    }
    if (defined $args{deleted}) {
	$deleted = $args{deleted};
	delete $args{deleted};
    }

    my (@left) =
      map { defined $_ ? $_ : $deleted } @{$args{left}};
    delete $args{left};

    my (@right) =
      map { defined $_ ? $_ : $deleted } @{$args{right}};
    delete $args{right};

    if (%args) {
	carp "argument key(s) {", join (', ', keys %args ),
	  "} unrecognized!";
    }

    for (0 .. $#left) {
	if (length $left[$_] < length $right[$_]) {
	    $left[$_] = _pad($left[$_], length($right[$_]), $pad);
	}
	elsif (length $right[$_] < length $left[$_]) {
	    $right[$_] = _pad($right[$_], length($left[$_]), $pad);
	}
    }

    my ($leftstring)  = join($join, @left);
    my ($rightstring) = join ($join, @right);

    if (wantarray) {
	return ($leftstring, $rightstring);
    }
    else {
	return join ($separator, $leftstring, $rightstring);
    }
}
##################################################################
sub _pad {
    my ($string, $length, $pad) = @_;
    while (length($string) < $length) {
	$string .= $pad;
    }
    while (length($string) > $length) {
	chop $string;
    }
    return $string;
}
##################################################################
# constructor helper functions
##################################################################
sub init {
    # stub placeholder; do nothing
    # subclasses may override (but need not).
}
##################################################################
# abstract, contract method -- subclasses must implement an override
# to avoid hitting this 'croak'.
sub weighter {
    my $self = shift;
    my $class = ref ($self);
    croak "couldn't find weighter in $class or its ancestors!\n";
}
##################################################################
# wrapper around workhorse. this wrapper does the mapping to arrays,
# typechecking.
sub align {
    my $self = shift;
    my ($left, $right) = @_;

    # if user provided a string as left or right component to align,
    # split that string into an array. If they provided an arrayref,
    # we'll leave it alone.
    if ( not ref $left ) {
	# user gave a string; split it!
	$self->{_LEFT()} = [ split (//, $left) ];
    }
    elsif ( not UNIVERSAL::isa($left, 'ARRAY') ) {
	require Carp;
	croak "left value provided was a reference, but not an arrayref!";
    }
    else {
	$self->{_LEFT()} = $left;
    }
    # same again for right side.
    if ( not ref $right ) {
	# user gave a string; split it!
	$self->{_RIGHT()} = [ split (//, $right) ];
    }
    elsif ( not UNIVERSAL::isa($right, 'ARRAY') ) {
	require Carp;
	croak "right value provided was a reference, but not an arrayref!";
    }
    else {
	$self->{_RIGHT()} = $right;
    }

    # actually do the alignment!
    $self->_align();
}
##################################################################
# workhorse does actual alignment. expects $left and $right to be
# arrayrefs, $weight to be coderef. DOES NOT CHECK THIS ASSUMPTION. IT
# IS A PRIVATE FUNCTION TO THIS MODULE. call 'align' instead, or one
# of the even higher-level methods like 'traverse' or a weighting
# function.

# this function may need adjustment if local or semiglobal alignments
# (allowing mismatches at beginning or end at low cost)
sub _align {
    my $self = shift;
    my $class = ref($self);

#     # get a reference to the weighter once so we don't do method
#     # lookup on every single cell.
#     my $weighter = $self->can('weighter');

    my (@left)   = @{$self->{_LEFT()}};
    my (@right)  = @{$self->{_RIGHT()}};

    # put the anchoring boundary pseudo-tokens in as the first
    # item. They are both undef, since there is absolutely no
    # possibility of that being confused with an actual value, yet we
    # need to have a point of agreement -- that the left anchor
    # pseudo-token on one side is aligned with the anchor pseudo-token
    # on the other side.
    unshift @left,  undef;
    unshift @right, undef;

    my (@costs); # two-dimensional array, lengths @left by @right
    my (@actions); # also 2-d, @left by @right, records which action
                   # got us here. Only populated if $tracing

    $costs[0][0] = 0; # these are the mock-match pseudo-anchors, and
                      # since $weighter->(undef, undef) is undefined,
                      # set this now.
    $self->{_ACTIONS()}[0][0] =
      [undef,undef];

    # initialize edge cells
    $self->{_POSY()} = 0;
    for my $x (1 .. $#left) {
	# all deletions up to $x
	$self->{_POSX()} = $x;
	my $cost = $self->_getWeight($left[$x], undef) + $costs[$x-1][0];
	my $action = [ $left[$x], undef ];

	$costs[$x][0] = $cost;
	$self->{_ACTIONS()}[$x][0] = $action;

	if (TRACE_WEIGHTS) {
	    $self->dump_trace($x, 0, \@left, \@right, $action, $cost);
	}
    }
    $self->{_POSX()} = 0;
    for my $y (1 .. $#right) {
	# all insertions up to $y
	$self->{_POSY()} = $y;
	my $cost = $self->_getWeight(undef, $right[$y]) + $costs[0][$y-1];
	  my $action = [ undef, $right[$y] ];

	$costs[0][$y] = $cost;
	$self->{_ACTIONS()}[0][$y] = $action;

	if (TRACE_WEIGHTS) {
	    $self->dump_trace(0, $y, \@left, \@right, $action, $cost);
	}
    }

    # set inside cells based on their neighbors, who are now
    # guaranteed to exist
    for my $x (1 .. $#left) {
	$self->{_POSX()} = $x;
	for my $y (1 .. $#right) {
	    # work the dp algorithm for each interior cell
	    $self->{_POSY()} = $y;

	    # (1) compare three costs to reach the current cell:
	    my ($paircost) = # match or substitution
	      $self->_getWeight($left[$x], $right[$y])
		+ $costs[$x-1][$y-1];

	    my ($deletecost) = # consume a left-side token
	      $self->_getWeight($left[$x], undef)
		+ $costs[$x-1][$y];

	    my ($insertcost) = # consume a right-side token
	      $self->_getWeight(undef, $right[$y])
		+ $costs[$x][$y-1];

	    # (2) select the minimum cost to reach the current cell
	    my ($cost) = _min($paircost, $deletecost, $insertcost);
	    $costs[$x][$y] = $cost;

	    # (3) if we're looking for an alignment (and not just a
	    # cost), then

	    # (3a) store a backpointer to the cell from which this
	    # local-best solution is derived. (here, it's stored as a
	    # 2-element array -- if one of the elements is undefined,
	    # then it's a deletion or insertion, else it's a match or
	    # substitution.)
	    my $action;
	    if ($cost == $paircost) {
		$action = [ $left[$x], $right[$y] ];
	    }
	    elsif ($cost == $deletecost) {
		$action = [ $left[$x], undef ];
	    }
	    else {
		$action = [ undef, $right[$y] ];
	    }
	    $self->{_ACTIONS()}[$x][$y] = $action;

	    # (3b) repeat this operation on each cell in the table


	    if (TRACE_WEIGHTS) {
		$self->dump_trace($x, $y, \@left, \@right, $action, $cost);
	    }

	} # for $y
    } # for $x

    # (4) the best alignment cost is that in the cell farthest from (0,0).
    $self->{_COST()} = $costs[$#left][$#right];

    # (5) walk back along the best alignment.
    @{$self->{_PATH()}} =
      $self->_backtrace($self->{_POSX()}, $self->{_POSY()});

    # discard dynamic actions record
    delete $self->{_LEFT()};
    delete $self->{_RIGHT()};

    delete $self->{_ACTIONS()};
    delete $self->{_POSX()};
    delete $self->{_POSY()};
    delete $self->{_BTX()};
    delete $self->{_BTY()};
}
##################################################################
sub dump_trace {
    # used for debugging...
    my ($self, $x, $y, $left, $right, $action, $cost) = @_;
    my $class = ref $self;

    print "considering ($x, $y)\n";
    if (not defined $action->[0]) {
	print "chose skip {NULL,$right->[$y]}: total $cost\n";
    }
    elsif (not defined $action->[1]) {
	print "chose skip {$left->[$x],NULL}: total $cost\n";
    }
    else {
	print "chose match {$left->[$x],$right->[$y]}: total $cost\n";
    }

    my ($leftstring, $rightstring) =
      $class->_as_lists($self->_backtrace($x,$y));
    print scalar $class->_as_strings(left => $leftstring,
				     right => $rightstring), "\n";

}
##################################################################
sub _backtrace {
    my ($self, $x, $y) = @_;
    croak if (not defined $x or not defined $y);
    # save state:
    my $oldx = $self->{_BTX()};
    my $oldy = $self->{_BTY()};
    # move to state set by argument
    $self->{_BTX()} = $x;
    $self->{_BTY()} = $y;

    my (@path);
    while (my $step = $self->backstep()) {
	unshift @path, $step;
    }

    # reset state
    $self->{_BTX()} = $oldx;
    $self->{_BTY()} = $oldy;
    return @path;
}
##################################################################
sub _getWeight {
    my ($self, $left, $right) = @_;
    # reset the backtrace pointers to the current position, so the
    # weighting routine always begins its trace from the current
    # position

    # setup
    $self->{_CURRTRACE()} = [ $left, $right ];

    $self->reset_backtrace();

    # call subclass weighter function
    my $result = $self->weighter($left, $right);

    # discard setup
    delete $self->{_CURRTRACE()};

    if (TRACE_WEIGHTS) {
	if (not defined $left) {
	    print "skip {NULL,$right}: $result\n";
	}
	elsif (not defined $right) {
	    print "skip {$left,NULL}: $result\n";
	}
	else {
	    print "match {$left,$right}: $result\n";
	}
    }
    return $result;
}
#################################################################
sub reset_backtrace {
    my $self = shift;

    $self->{_BTX()} = $self->{_POSX()};
    $self->{_BTY()} = $self->{_POSY()};

    croak "can't call reset_backtrace except from within ",
      "weighter() method implementation" if not defined $self->{_CURRTRACE()};

    # adjust current 
    if (not defined $self->{_CURRTRACE()}[0]) {
	$self->{_BTY()}--;
    }
    if (not defined $self->{_CURRTRACE()}[1]) {
	$self->{_BTX()}--;
    }
}
##################################################################
sub backstep {
    my $self = shift;
    my $x = $self->{_BTX()};
    my $y = $self->{_BTY()};

    croak "how did btx get to be less than 0?" if $x < 0;
    croak "how did bty get to be less than 0?" if $y < 0;

    croak "can't call backstep() except from weighting function"
      if (not defined $x or not defined $y);

    my $action = $self->{_ACTIONS()}[$x][$y];

    # regardless of which step it was
    if (defined $action->[0] and defined $action->[1]) {
	# a match/substitution
	$self->{_BTX()}--;
	$self->{_BTY()}--;
    }
    elsif (defined $action->[0]) {
	# a deletion
	$self->{_BTX()}--;
    }
    elsif (defined $action->[1]) {
	# an insertion
	$self->{_BTY()}--;
    }
    else {
	return (); # we must be at the anchor pseudo-match
    }
    return $action;
}
##################################################################
# selects the minimum of (usually) three. Probably could be more
# useful, but also a private function. No need.
sub _min {
    carp "not 3 args passed to _min!" if ( @_ != 3 );
    my ($answer) = shift;
    while (my $next = shift @_) {
	if ($next < $answer) {
	    $answer = $next;
	}
    }
    return $answer;
}
##################################################################
# intended to be a replacement for Algorithm::Diff. given two
# arrayrefs, a hash of callbacks, and a key-generator, constructs a
# simple weighter that generates keys for each item and compares them.
# Does NOT provide a mechanism for weights other than {0,1}.
# interesting to see if this is similar to the LCS algorithm...
sub traverse {
    my ($left, $right, $callbacks, $keygen) = @_;
    my $weight;
    if (not UNIVERSAL::isa($left, 'ARRAY') ) {
	require Carp;
	croak "first argument to traverse not an arrayref!";
    }
    if (not UNIVERSAL::isa($right, 'ARRAY') ) {
	require Carp;
	croak "second argument to traverse not an arrayref!";
    }
    if (not UNIVERSAL::isa($callbacks, 'HASH') ) {
	require Carp;
	croak "third argument to traverse not a hashref!";
    }
    if (defined $keygen) {
	if (not UNIVERSAL::isa($weight, 'CODE')) {
	    require Carp;
	    croak "fourth (optional) argument to traverse found, ",
	      "but not coderef!";
	}
	$weight =
	  sub {
	      return 1 if ( not defined $_[0] or not defined $_[1] );
	      return ($keygen->($_[0]) eq $keygen->($_[1]) ? 0 : 2);
	  }
    }
    else {
	# default weighting -- optimized to remove a sub call to $keygen
	$weight =
	  sub {
	      return 1 if ( not defined $_[0] or not defined $_[1] );
	      return ($_[0] eq $_[1] ? 0 : 2);
	  };
    }

    my @callbackKeys = qw( MATCH DISCARD_A DISCARD_B );
    if ( not grep { defined $callbacks->{$_} } @callbackKeys ) {
	require Carp;
	croak "none of the callback keys {",
	  join (',', @callbackKeys),
	    "} are defined in the third argument hashref to traverse()!";
    }
    foreach my $key ( @callbackKeys ) {
	if (defined $callbacks->{$key}
	    and not UNIVERSAL::isa($callbacks->{$key}, 'CODE') ) {
	    require Carp;
	    croak "value associated with $key not a coderef!";
	}
    }

    # generate the actual path of the system
    my ($cost, @path) = align(left => $left, right => $right,
			      weight => $weight, keeptrace => 0);

    # traverse() from Algorithm::Diff calls the callbacks back with
    # indices, so we must keep track of those indices.
    my ($x, $y) = (0, 0);
    while ($x < @{$left} or $y < @{$right}) {
	my $pair = shift @path;

	if (defined $pair->[0] and defined $pair->[1]) {
	    if ($weight->($pair->[0], $pair->[1])) {
		# a substitution, not a match
		if (defined $callbacks->{CHANGE}) {
		    $callbacks->{CHANGE}->($x, $y);
		}
		else {
		    # no change function; emulate by calling discard_a
		    # and discard_b instead
		    if (defined $callbacks->{DISCARD_A}) {
			$callbacks->{DISCARD_A}->($x);
		    }
		    if (defined $callbacks->{DISCARD_B}) {
			$callbacks->{DISCARD_B}->($y);
		    }
		}
	    }
	    else {
		# a match
		if (defined $callbacks->{MATCH}) {
		    $callbacks->{MATCH}->($x, $y);
		}
	    }
	    $x++;
	    $y++;
	}
	elsif (defined $pair->[0]) {
	    if (defined $callbacks->{DISCARD_A}) {
		$callbacks->{DISCARD_A}->($x);
	    }
	    $x++;
	}
	elsif (defined $pair->[1]) {
	    if (defined $callbacks->{DISCARD_B}) {
		$callbacks->{DISCARD_B}->($y);
	    }
	    $x++;
	}
    }
}
##################################################################
1;
__END__

=head1 NAME

Text::Align - base class for aligning two strings or two arrays,
according to derived class matching functions.

=head1 SYNOPSIS

  # in some other class
  package MyDerivedAlignmentClass;
  use base 'Text::Align';
  # derived from this core class.

  # define the contract methods (weighter, init)
  sub weighter {
    # my clever weighting technique
  }
  sub init {
    my $self = shift;
    # whatever you need to initialize this clever weighting technique

  }
  1;

  __END__

  =head1 NAME

  MyDerivedAlignmentClass -- a weighting scheme.

  =head1 DESCRIPTION

  This is why C<MyDerivedAlignmentClass is so neat...

  =head1 Required params to C<new()>

  In addition to the usual C<left> and C<right> parameters, please
  also pass the following parameters...

  =cut

Somewhere, not far away...

  use MyDerivedAlignmentClass;

  # establish parameters as needed; include:
  $params{left} = 'foo';      # could use array reference here instead
  $params{right} = 'foobar';

  my $alignment = MyDerivedAlignmentClass->new(%params);

  my (@lines) = $alignment->as_strings();
  print join ("\n", @lines), "\n";

  # use the string 'SKIP' instead of a '-' to represent a skipped token

  print scalar $alignment->as_strings(deleted => 'SKIP'), "\n";

  print $alignment->cost(), "\n";
  # prints the minimum cost as determined by the algorithm.

  my (@pairs) = $alignment->pairwise();
  # @pairs now has a list of 2-element listrefs that represent the
  # lowest-cost alignment

  my ($left, $right) = $alignment->as_lists();
  # $left now has a list of the sections of the left side of the
  # alignment. Note that undef elements represent skips.
  # similarly for $right.


=head1 DESCRIPTION

This module is intended to be a base class for modules that intend to
experiment with the dynamic-programming algorithm for sequence
alignment.

Derived classes shipped with this component include
C<Text::Align::Levenshtein> (see L<Text::Align::Levenshtein>) and
C<Text::Align::WagnerFischer> (see L<Text::Align::WagnerFischer>), which
are intended as more configurable replacements for C<Text::Levenshtein>
and C<Text::WagnerFischer>. (see L<Text::Align::background/Related Perl
modules> for a comparison among these).

Subclasses of this module can also use alternate weightings (rather
than the "exact equality" metric used by Levenshtein and
Wagner-Fischer), based on the specific characters (or elements) being
substituted, deleted or inserted.  See L<Text::Align::Covington> for
one of these.

It also can apply to calculate alignments between arrays, if array
references are provided.

A more detailed discussion of the background for this module is
available (see L<Text::Align::background>).

=head1 This is a contract class

This class is a contract class.  This means that:

=over

=item (1)

Clients of this class take the form of subclasses (descendants) of
this class. To fulfill the contract, they must provide implementations
of certain methods.

=item (2)

C<Text::Align> will not function if used directly:

  use Text::Align;
  # the next line will croak
  my $alignment = Text::Align->new(left => 'foo', right => 'bar');

since subclasses provide key pieces of the functionality. (A
contract's no good with only one signer.)

=item (3)

Subclasses fulfilling the contract will also receive the benefits of
the contract -- they will be granted the inherited methods from this
contract class (C<pairwise()>, C<cost()>, C<as_strings()>,
C<as_lists()>).

=back

=head2 Contract methods

The following methods must be provided to this module by any subclass
in order to fulfill the contract. If these methods do not exist, then
this module will not behave correctly - and will complain and probably
C<croak> at runtime.

=over

=item weighter()

This function is the core of any subclass of this one. The
C<weighter()> method will be called when comparing two elements, or
when considering skipping one. It will be called with two arguments,
representing the left and right elements to be compared.

The actual calls to the C<weighter()> will happen after the call to
C<init()> but before returning from C<new()>.

The C<weighter()> method will be called whenever the system is
considering a pair of tokens to align together (matches or
substitutions) or when one of the tokens should be skipped (insertion
or deletion). In the skip cases, one of the two arguments (the one on
the side being skipped) will be C<undef>.

To examine the context of the match, the C<weighter> method may invoke
any of the methods listed under L</Weighting utility methods>,
e.g. using C<backstep()> (possibly more than once) to examine the
context of the tokens being compared.

=item init()

Upon calling C<new()>, and before the actual alignment gets underway,
this class will call the C<init> method on itself (as an instance)
with all the hash arguments passed to C<new()>.

This provides an opportunity for the subclass to set any internal
configuration variables or do any other prep-work before the
polynomially-bound dynamic-programming algorithm gets underway.

If the subclass does not provide an implementation of C<init()>, a
null-operation implementation will be provided by (this) the base
class.

=back

=head2 Weighting utility methods

These methods are provided as hooks so that subclasses can cleanly
fulfil their end of the contract.  They are interfaces so that the
weighter can look back into the context of the alignment thus far.

They will probably I<not> behave correctly if invoked anywhere except
from within the C<weighter()> routine.

=over

=item backstep()

Retrieves, for the current weighting being considered, the previous
pairwise alignment (a match, substitution, insertion or deletion, as
returned from the C<pairwise()> method).

This method should only be invoked from within the C<weighter()>
function.  If it is called a second time, returns "the one before
that", etc.  Call the C<reset_backtrace()> method to begin again from
the token under consideration.

=item reset_backtrace()

Resets the state of the backtracing to the "pristine" state -- as it
was set when entering the C<weighter()> routine.

This method should only be invoked within the C<weighter()>
implementation.

=back

=head1 Methods provided

=head2 Class methods

The following methods may be called as class methods; e.g., in the
syntax:

  CLASSNAME->methodname();
  # assumes CLASSNAME is a descendant of Text::Align

These class methods are available to any subclass that fulfills the
contract.

=over

=item costs()

Arguments are:

  init-hash-ref, $left, @right

Calculates a series of distances (from C<$left> to each element in
C<@right>), using C<init-hash-ref> as the parameters with which to
initialize the C<Text::Alignment> object.

Arguments are defined as follows:

=over

=item init-hash-ref

Any arguments to be passed to the C<new()> method.  Each subclass may
require different initialization parameters; any additional parameters
required for initialization may be passed here.

=item $left

a scalar value or a reference to a list.  Will be passed as the
C<left> token to each of the C<Text::Alignment> objects constructed.

=item @right

a list of scalars or listrefs. Each of these will be compared to
C<$left>, and the resulting distance will be added to the list of
C<distances> to return.

=back

=item new()

constructs a new object of the subclass. Actually performs the
alignment and returns an object; instance methods on that object
access the results of the completed alignment.

Arguments are a set of key/value pairs including at least the
following:

=over

=item left  => (string or listref)

=item right => (string or listref)

The C<left> and C<right> keys are required. In each case, if the value
provided is a reference to a list, then that list is considered to be
"pre-split" and the elements provided will be used as the units.  If a
(non-reference) scalar is provided, it will be C<split> into separate
characters.

The two arguments (C<left> and C<right>) need not be the same datatype
-- one may be a listref, and the other a string, and all is well: the
string will be C<split>.

=back

See L</Instance methods> below for methods available from the object
returned from C<new()>.

=back

=head2 Instance methods

The following methods may be called on any instance of a
C<Text::Align> object, that is, the reference returned by calling
C<new()>.  Essentially, these methods make up the functionality
guaranteed to the subclass by the contract.

=over

=item pairwise()

Returns the alignment as a list of 2-element list references. Each
item in the list consists of a single pairwise alignment -- either an
insertion or a deletion in the alignment (in which case one element
will be C<undef>) or a match or substitution (both elements will be
present).

Takes no arguments.

=item cost()

Returns the total minimum cost of this alignment, as calculated during
the alignment step (which happened upon creation of the object).

Takes no arguments.

=item as_strings()

Returns the alignment as two strings of the same length, with C<pad>
characters (usually whitespace) and C<deleted> characters (usually
C<->) inserted where necessary so that aligned units share left edges.

If called in scalar context, will join the two strings with the
C<separator> character (usually C<\n>, see below). Optional arguments
include the following:

=over

=item join => JOINSTRING

The string that should separate tokens on output. Defaults to the
empty string (C<''>) if not provided.

=item pad => PADSTRING

The string with which to pad any segments of different
lengths. Default is a single (0x20) space (C< >) if not provided. Note
that any string you provide here must have a non-zero length (... of
course).

If the string you provide has a length larger than 1, then you run the
risk of it being ruthlessly C<chop>-ed

=item separator => SEPSTRING

The character with which to join the two strings when returning them
as a single text blob (scalar context). Defaults to a newline (C<\n>)
if not provided. Meaningless in list context.

=item deleted => DELSTRING

The character to use to represent a deleted (or inserted) character,
on the missing side. Note that the empty string (C<''>) is legal here,
which will most likely have the effect of using the C<pad> character
instead.  Defaults to a dash (C<->) if not provided.

=back

=item as_lists()

Returns 2 values representing the C<left> and C<right> lists of
alignments, with C<undef> values inserted opposite any skipped
tokens. Matching or substituted elements will be listed unchanged.

=back

=head2 EXPORT

None. This is an object-oriented module. Use OO syntax to access its
methods.

=head1 Installation

=over

=item *

Install the prerequisites (see L</Prerequisites>).

=item *

C<gunzip> and un-C<tar> the distribution into a working directory. On
Unix, this looks like:

  tar zxvf Text-Align-NNN.tar.gz # NNN corresponds to the version
                                 # number

On Windows, you may have to use Cygwin tools
(L<http://www.redhat.com>) or Winzip, using "Extract with
directory-names".

=item *

Change the working directory into the newborn untarballed directory.

  cd Text-Align-NNN

=item *

Execute the C<Makefile.PL> code.

  perl Makefile.PL

=item *

Build and test the module.

On Windows (ActiveState Perl distribution):

  nmake
  nmake test

You may have to add C<nmake.exe> to your path. It is available from
the web.  (TO DO: give a working link).

On Unix I<et al.>:

  make
  make test

=item *

Install the module:

Windows

  nmake install

Unix etc (you may have to be C<root>):

  make install

=back

=head2 Prerequisites

The core module C<Text::Align> depends on no Perl modules (other than
a standard distribution of Perl 5.6 or greater).

However, several of the subclasses distributed with it require
additional modules from CPAN:

=over

=item Text::Align::Covington

Requires C<Lingua::FeatureMatrix> and C<Class::MethodMaker>.

=item Text::Align::Phone

Requires C<Class::MethodMaker>.

=back

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Text::Align

=item 0.02

Redesigned to use OO paradigm.

=item 0.03

Now ships with C<Text::Align::Covington>.

=item 0.04

Extended and improved documentation

=item 0.05

Greatly expanded documentation. Now has L<Text::Align::future> and
L<Text::Align::background>.

=item 0.06

Expanded documentation (L<Text::Align::analysis>), established grouped
C<scripts> directory for analysis.

=back

=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

=over

=item L<Text::Levenshtein>

=item L<Text::WagnerFischer>

=item L<Algorithm::Diff>

Modules whose functionality is replicated by C<Text::Align> or its
derived classes.  See L<Text::Align::background/Related Perl modules>
for a more detailed discussion of their relationship with each other
and this module.

=item L<Text::Align::Levenshtein>

A descendant of C<Text::Align>, emulating C<Text::Levenshtein>, but
providing the full suite of C<Text::Align> methods.

=item L<Text::Align::WagnerFischer>

A descendant of C<Text::Align>, emulating C<Text::WagnerFischer>, but
providing the full suite of C<Text::Align> methods.

=item L<Text::Align::Covington>

A descendant of C<Text::Align> that uses a weighting scheme based on a
paper by Michael Covington (University of Georgia).

=item L<Text::Align::background>

=item L<Text::Align::analysis>

=item L<Text::Align::future>

Further discussion of this module.

=back

=cut
