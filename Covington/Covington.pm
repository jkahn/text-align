##################################################################
package Text::Align::Covington;
use 5.006;
use strict;
use warnings;
##################################################################
our $VERSION = '0.03';
use base 'Text::Align';
use constant _LEFT => 0;
use constant _RIGHT => 1;
##################################################################
use constant _CASE_A => 0;
use constant _CASE_B => 5;
use constant _CASE_C => 10;
use constant _CASE_D => 30;
use constant _CASE_E => 60;
use constant _CASE_F => 100;
use constant _CASE_G => 50;
 # G should be 40, but haven't implemented affine gap cost yet
use constant _CASE_H => 50;
use constant TRACE_CASES => 0;
##################################################################
use Carp;
use constant _PHONESET => __PACKAGE__ . '::phoneset';
##################################################################
use Text::Align::Phone;
my @similarityMetric = grep { $_ ne 'long' } @Text::Align::Phone::Features;
##################################################################
sub init {
    my $self = shift;
    my (%args) = @_;
    if (defined $args{phoneset}) {
	if (not UNIVERSAL::isa($args{phoneset}, 'Lingua::FeatureMatrix')) {
	    croak "phoneset argument to ", __PACKAGE__,
	      " not a Lingua::FeatureMatrix!";
	}
	elsif (not UNIVERSAL::isa($args{phoneset}->_emeType(),
				  'Text::Align::Phone')) {
	    croak "phoneset specified really has to use ",
	      "Text::Align::Phone as its eme object";
	}
	foreach (qw (VOW CONS GLIDE) ) {
	    if (not defined $args{phoneset}->featureClasses($_)) {
		croak "this phoneset doesn't support the $_ class!";
	    }
	}
	# otherwise, it (phew!) passes.

	$self->{_PHONESET()} = $args{phoneset};
    }
    else {
	croak __PACKAGE__, " requires a defined 'phoneset' argument!";
    }
}
##################################################################
sub weighter {
    my $self = shift;
    my ($left, $right) = @_;

    # Covington's weights are described in the POD.
    if (defined $left and not defined $self->{_PHONESET()}->emes($left)) {
	carp "don't recognize phone $left\n";
    }
    if (defined $right and not defined $self->{_PHONESET()}->emes($right)) {
	carp "don't recognize phone $right\n";
    }


    # skips
    if (not defined $left) {
	my $trace = $self->backstep();
	if (not defined $trace) {
	    print "case h\n" if TRACE_CASES;
	    return _CASE_H; # skip not preceded by another skip.
	}
	elsif (not defined $trace->[_LEFT] and defined $trace->[_RIGHT]) {
	    # skip preceded by another skip
	    print "case g\n" if TRACE_CASES;
	    return _CASE_G;
	}
	else {
	    # skip *not* preceded by another skip.
	    print "case_h\n" if TRACE_CASES;
	    return _CASE_H;
	}
    }
    elsif (not defined $right) {
	my $trace = $self->backstep();
	if (not defined $trace) {
	    print "case h\n" if TRACE_CASES;
	    return _CASE_H; #gap skip not preceded by another skip
	}
	elsif (defined $trace->[_LEFT] and not defined $trace->[_RIGHT]) {
	    # skip preceded by another skip
	    print "case g\n" if TRACE_CASES;
	    return _CASE_G;
	}
	else {
	    # "gap" skip
	    return _CASE_H;
	}
    }

    # match -- consonant or vowel
    if ($left eq $right) {
	if ($self->_isConsonant($left)) {
	    # two matching consonants
	    print "case a\n" if TRACE_CASES;
	    return _CASE_A;
	}
	else {
	    # presumably vowel-match
	    print "case b\n" if TRACE_CASES;
	    return _CASE_B;
	}
    }
    # dissimilar substitution. Which dissimilar cases?

    if ($self->_isGlide($left) and $self->_isVowel($right)) {
	if ($left eq 'y' and $right eq 'i'
	    or $left eq 'w' and $right eq 'u') {
	    print "case c\n" if TRACE_CASES;
	    return _CASE_C;
	}
	else {
	    # bad luck, no discernible similarity
	    print "case f\n" if TRACE_CASES;
	    return _CASE_F;
	}
    }
    elsif ($self->_isVowel($left) and $self->_isGlide($right)) {
	if ($left eq 'i' and $right eq 'y'
	    or $left eq 'u' and $right eq 'w') {
	    print "case c\n" if TRACE_CASES;
	    return _CASE_C;
	}
	else {
	    # bad luck, no discernible similarity
	    print "case f\n" if TRACE_CASES;
	    return _CASE_F;
	}
    }
    elsif ($self->_isVowel($left) and $self->_isVowel($right)) {
	if ($self->_matchAllButLength($left, $right)) {
	    print "case c\n" if TRACE_CASES;
	    return _CASE_C;
	}
	else {
	    # two dissimilar vowels
	    print "case d\n" if TRACE_CASES;
	    return _CASE_D;
	}
    }
    elsif ($self->_isConsonant($left) and $self->_isConsonant($right)) {
	print "case e\n" if TRACE_CASES;
	return _CASE_E;
    }
    else {
	# not both vowels, nor both consonants
	print "case f\n" if TRACE_CASES;
	return _CASE_F;
    }
}

##################################################################
sub _isConsonant {
    my ($self, $phone) = @_;
#    print "$phone\n";
    return ($self->{_PHONESET()}->matchesFeatureClass($phone, 'CONS'));
}
##################################################################
sub _isGlide {
    my ($self, $phone) = @_;
    return ($self->{_PHONESET()}->matchesFeatureClass($phone, 'GLIDE'));
}
##################################################################
sub _isVowel {
    my ($self, $phone) = @_;
    return ($self->{_PHONESET()}->matchesFeatureClass($phone, 'VOW'));
}
##################################################################
sub _matchAllButLength {
    my ($self, $left, $right) = @_;
    my $lf =
      $self->{_PHONESET()}->emes($left)
	->dumpFeaturesToText(@similarityMetric);
    my $rf =
      $self->{_PHONESET()}->emes($right)
	->dumpFeaturesToText(@similarityMetric);
    return ($lf eq $rf);
}

##################################################################
# COVINGTON_A
##################################################################
package Text::Align::Covington_a;
our (@ISA);
push @ISA, 'Text::Align::Covington';
use constant MATCH => 0.0;
use constant SAMECLASS => 0.5;
use constant MISMATCH => 1.0;
use constant SKIP => 0.5;
##################################################################
sub weighter {
    my ($self, $left, $right) = @_;

    if (not defined $left or not defined $right) {
	return SKIP;
    }
    # both defined
    elsif ($left eq $right) {
	return MATCH;
    }

    # defined and different
    elsif ($self->_isConsonant($left) and $self->_isConsonant($right)) {
	return SAMECLASS;
    }
    elsif ($self->_isVowel($left) and $self->_isVowel($right)) {
	return SAMECLASS;
    }
    else {
	return MISMATCH;
    }

}
##################################################################
1;

__END__

=head1 NAME

Text::Align::Covington - Weighting scheme for Text::Align following
Covington (1996)

=head1 SYNOPSIS

  # set up the phoneset object
  use Lingua::FeatureMatrix;
  use Text::Align::Phone;
  my $phoneset =
      Lingua::FeatureMatrix->new(eme => 'Text::Align::Phone',
				 file => 'phoneset.dat');

  use Text::Align::Covington;
  my $alignment =
      Text::Align::Covington->new(phoneset => $phoneset,
                                  left => "fubar",
                                  right => "fübər");
  print scalar $alignment->as_strings(), "\n";
  print "distance is ", $alignment->cost();

Alternatively, you can try the less-sophisticated
C<Text::Align::Covington_a> class, which is the first alignment
suggested in the paper (L</Covington (1996)>).

  # $phoneset is same as above
  use Text::Align::Covington;
  my $alignment_a =
      Text::Align::Covington_a->new(phoneset => $phoneset,
                                    left => "fubar",
                                    right => "fübər");

  print scalar $alignment->as_strings(), "\n";
  print "distance is ", $alignment_a->cost();

=head1 DESCRIPTION

This module is based on C<Text::Align>, using a weighting scheme
suggested in Covington (L<1996|Text::Align::background/Citations>).

However, following Kondrak
(L<1999|Text::Align::background/Citations>), this module uses the
dynamic-programming algorithm encapsulated in C<Text::Align> (its base
class) rather than the exhaustive tree-search Covington suggests.

=head1 Configuration

A C<Text::Align::Covington> object requires a
C<Text::Align::Phone>-based C<Lingua::FeatureMatrix> object, in
addition to the methods requested by the C<Text::Align> base class.

The C<Lingua::FeatureMatrix> object should be complete and passed in
as the C<phoneset> value in the named arguments handed to C<new()>.

The C<eme> for the C<phoneset> object currently is restricted to
C<Text::Align::Phone> or subclasses. Furthermore, the data fed to the
constructor for the C<phoneset> object must include the C<class>
definitions for C<VOW>, C<GLIDE>, and C<CONS>.

=head1 Weighting scheme

Here is the weighting scheme, as suggested in Covington's paper,
table 2. This is how Covington would score any potential alignments.

=over

=item (a)

0 -- match identical consonant

=item (b)

5 -- match identical vowel

"Reflecting the fact that the aligner should prefer to match
consonants rather than vowels if it must choose between the two"

=item (c)

10 -- match two vowels differing only in length, or C<i> and C<y>, or C<u> and
C<w>

=item (d)

30 -- match two dissimilar vowels

=item (e)

60 -- match of two dissimilar consonants

=item (f)

100 -- match of two segments with no discernible similarity.

=item (g)

40 -- Skip preceded by another skip in the same word

"Reflecting the fact that affixes tend to be contiguous"

=item (h)

50 -- Skip I<not> preceded by another skip in the same word.

=back

Note that this weighting scheme is the one available from the
C<Text::Align::Covington> package.

However, note that B<case g is not implemented>, since this requires
I<gap costing>. See L<Text::Align::future> for more discussion of
this problem.

=head2 Covington_a

Earlier in Covington (L<1996|Text::Align::background/Citations>) he proposes a dummy weighting
scheme.

=over

=item (a)

0.0 -- for an exact match

=item (b)

0.5 -- for aligning a vowel with a different vowel or a consonant with
a different consonant

=item (c)

1.0 -- for a complete mismatch

=item (d)

0.5 -- for a skip, "so that two alternating skips -- the disallowed
case -- would have the same penalty as the mismatch to which they are
equivalent."

=back

Loading this module (C<Text::Align::Covington>) also makes this
secondary (and simpler) weighting available via the
C<Text::Align::Covington_a> package.

=head1 TO DO

=over

=item *

It would be nice if this module did not have so many restrictions on
the C<Lingua::FeatureMatrix> object, but this would require more
parameter options.

A clever improvement might be to set those options by default, but
allow users to override them if they have knowledge.

=item *

Users should be able to hand in I<only> a phoneset file and have it
construct a C<Lingua::FeatureMatrix> appropriately on its own.

=back

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Text::Align::Covington

=item 0.02

Updated documentation, added C<Text::Align::Covington_a> package.

=item 0.03

Clarified documentation. Moved some of it into C<Text::Align>.

=back

=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<Text::Align>.

L<Text::Align::Levenshtein>. A much simpler weighting scheme.

L<Text::Align::Phone>. The subclass of C<Lingua::FeatureMatrix::Eme>
that provides the necessary features for the Covington weighting
scheme.

See L<Text::Align::background> for discussion of the motivation of
this module.

See L<Text::Align::analysis> for discussion of the effectiveness of
this module.

=cut

