package Text::Align::WagnerFischer;
use 5.006;
use strict;
use warnings;
##################################################################
our @ISA;
our @EXPORT_OK = ( qw( distance ) );
our @EXPORT = qw();
our $VERSION = '0.02';
##################################################################
require Exporter;
use base 'Text::Align';
push @ISA, qw(Exporter);
use Carp;
##################################################################
use constant MATCH => 0;
use constant INDEL => 1;
use constant SUBSTITUTION => 2;
##################################################################
my %weights; # inside-out hash -- maps ids to weights
##################################################################
sub init {
    my ($self, %args) = @_;
    my $weightref = $args{weights};
    if (not defined $weightref or not UNIVERSAL::isa($weightref, 'ARRAY')) {
	croak __PACKAGE__ ,
	  " requires a weights argument of a weightref\n";
    }
    elsif (@{$weightref} != 3) {
	croak __PACKAGE__ . " weighting arrayref not 3 elements long!\n";
    }

    my ($match, $indel, $substitute) = @{$weightref};
    my $id = $self->id();
    $weights{$id}[MATCH] = $match;
    $weights{$id}[INDEL] = $indel;
    $weights{$id}[SUBSTITUTION] = $substitute;
}
##################################################################
sub weighter {
    my ($self, $left, $right, $actionref) = @_;
    my $id = $self->id();
    if (not defined $left or not defined $right) {
	return $weights{$id}[INDEL];
    }
    elsif ($left eq $right) {
	return $weights{$id}[MATCH];
    }
    else {
	return $weights{$id}[SUBSTITUTION];
    }
}
##################################################################
sub distance {
    my $weightref = shift;
    if (not UNIVERSAL::isa($weightref, 'ARRAY')) {
	# put it back
	unshift @_, $weightref;

	# use levenshtein weights if not provided
	$weightref = [0,1,1]; # levenshtein case
    }

    return __PACKAGE__->costs({weights => $weightref}, @_);
}
##################################################################
1;
__END__

=head1 NAME

Text::Align::WagnerFischer - Subclass of Text::Align that performs
Wagner-Fischer alignments.

=head1 SYNOPSIS

  use Text::Align::WagnerFischer;

  my $alignment =
    Text::Align::WagnerFischer->new( left => 'foo',
                                     right => 'four',
                                     weights => [0,1,1]
                                    );
  print scalar $alignment->as_strings(), "\n";

  use Text::Align::WagnerFischer 'distance';
  # drop in replacement for:
  # use Text::WagnerFischer 'distance';
  # exx. below come from there

  print distance("foo","four");# prints "2"

  print distance([0,1,2],"foo","four");# prints "3"

  my @words=("four","foo","bar");

  my @distances=distance("foo",@words); 
  print "@distances"; # prints "2 0 3"

  @distances=distance([0,2,1],"foo",@words); 
  print "@distances"; # prints "3 0 3"


=head1 DESCRIPTION

This module implements the Wagner-Fischer dynamic programming technique,
used here to calculate the edit distance of two strings.

This module fulfils the contract required by C<Text::Align>, and so
C<Text::WagnerFischer> objects have all the methods available for any
C<Text::Align> object. See L<Text::Align>.

In the Wagner-Fischer technique, the weight of two strings is
calculated by a simple cost function, for each of three cases:

=over

=item matches

=item insertions or deletions (indels)

=item substitutions

=back

These costs are given trough an array reference as first argument of
the C<distance> subroutine: C<[m,i,s]>, if you're using the drop-in
replacement for the C<Text::WagnerFischer> module. In this case, if
the costs are not given, a default array cost is used: C<[0,1,1]> (the
case of the Levenshtein edit distance).

If you're using the more powerful object-oriented
C<Text::Align::WagnerFischer> object directly, then you should pass
this listreference (the three-element weighting function) as a named
parameter (using the C<weights> key) to C<new> when creating a new
alignment.

=head2 EXPORT

None by default.  C<distance> below is available if requested.

=over

=item distance

Emulates the C<distance> function from C<Text::WagnerFischer> (see
L<Text::Align::background/Related Perl modules> for a comparison).

=back


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Text::Align::WagnerFischer

=item 0.02

revised to use array internally, and to use private hash of weights
(so that base class infrastructure doesn't influence anything here).

See "inside-out objects" at
L<http://www.perlmonks.org/index.pl?node_id=189791> for more on this strategy.

=back

=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<Text::WagnerFischer>, which it replaces, and which is an inspiration

L<Text::Align>, from which it is derived, and which abstracts out much
of Levenshtein's dynamic programming algorithm -- the core of this
module.

=cut
