package Text::Align::Levenshtein;

use 5.006;
use strict;
use warnings;

# our @ISA = qw(Exporter);
our (@ISA);
use base ('Text::Align::WagnerFischer');
push @ISA, 'Exporter';
# export nothing by default
our @EXPORT_OK = qw( distance );
our @EXPORT = qw();
our $VERSION = '0.01';

##################################################################
sub init {
    my $self = shift;
    $self->SUPER::init(@_, weights => [0,1,1]);
}
##################################################################
sub distance {
    return __PACKAGE__->costs({}, @_);
}
##################################################################
1;
__END__

=head1 NAME

Text::Align::Levenshtein - Performs Levenshtein alignments (and
distance computations)

=head1 SYNOPSIS

  use Text::Align::Levenshtein;

  my $alignment =
     Text::Align::Levenshtein->new(left  => 'foo',
                                   right => [ 'f', 'ü' ],
                                   );
  print $alignment->cost(); # 3, for this example

  my @pairwise = $alignment->pairwise();

  print scalar $alignment->as_strings();


Also, it can export a C<distance()> function that emulates one from
C<Text::Levenshtein>.

  use Text::Align::Levenshtein 'distance';
  # replaces:
  # use Text::Levenshtein 'distance';
  distance ( 'foo', 'food' ); # yields '1'
  distance ( 'feed', 'food' ); # yields '4'

  print distance("foo","four");
  # prints "2"

  my @words=("four","foo","bar");
  my @distances=distance("foo",@words);

  print "@distances";
  # prints "2 0 3"


=head1 DESCRIPTION

An alignment scheme derived from C<Text::Align>.

The alignment scheme is the minimum edit distance between two strings,
where edit distance is the number of deletions, insertions, or
substitutions needed to transform one string into the other. When the
distance between two strings is 0, they're equivalent.

This module fulfils the contract required by C<Text::Align>, and so
C<Text::Levenshtein> objects have all the methods available for any
C<Text::Align> object. See L<Text::Align>.

=head2 EXPORT

None by default.  C<distance> below is available if requested.

=over

=item distance

Emulates the C<distance> function from C<Text::Levenshtein>. See
L<Text::Align::background/Related Perl modules> for a comparison.

=back

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Text::Align::Levenshtein

=back


=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<Text::Align>.

L<Text::Levenshtein> (which it replaces).

=cut
