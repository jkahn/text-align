package Text::Align::Phone;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';
use base 'Lingua::FeatureMatrix::Eme';
our @Features;
BEGIN {
    @Features =
      (
       qw{ vow cons voice },
       qw{ long front back high low round },
       qw{ glottal velar palatal alveolar dental interdental labial },
       qw{ stop fricative liquid nasal }
      );
} # end BEGIN
use Class::MethodMaker get_set => [ @Features ];
sub getFeatureNames { return @Features };


1;
__END__

=head1 NAME

Text::Align::Phone - Object class representing a single phone and its features.

=head1 SYNOPSIS

  use Text::Align::Phone;
  blah blah blah

=head1 DESCRIPTION

A subclass of C<Lingua::FeatureMatrix::Eme>. To be used with
C<Lingua::FeatureMatrix>. Designed for use in phonetic alignments;
basically covers major phonetics.

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Text::Align::Phone

=back

=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<Text::Align>.

L<Text::Align::Covington>.

L<Lingua::FeatureMatrix>.

=cut
