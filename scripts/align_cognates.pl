#!perl -w
use warnings;
use strict;

#use lib '../Text-Align/blib/lib';
use utf8;

use Text::Align::Levenshtein;
use Text::Align::WagnerFischer;
use Text::Align::Covington;
use constant OUTDIR => 'alignments';

my $SHOW_SCORE = 0;

my $file = shift @ARGV;

while (@ARGV) {
    if ($ARGV[0] eq '--show-score') {
	$SHOW_SCORE = shift @ARGV;
    }
    else {
	die "unrecognized argument $ARGV[0]\n";
    }
}

if (not -f $file) {
    die "can't find cognates $file\n";
}

if (not -d OUTDIR) {
    mkdir OUTDIR or die "couldn't create " . OUTDIR . ": $!\n";
}

my @modes =
  qw ( Levenshtein WagnerFischer1 WagnerFischer2 Covington_a Covington );

# MAIN LOOP
foreach my $mode (@modes) {
    # announce our intent
    warn "$mode alignment\n";

    align( $mode, $file, OUTDIR . '/' . $mode . ".txt" );
}
# END MAIN
##################################################################
sub align {
    # given mode, file full of cognates to align, and an outfile name
    # to write the resulting alignments to, write the alignment file.
    my ($mode, $cognates, $outfile) = @_;
    open (FILE, $cognates) or die "couldn't open $cognates: $!\n";

    my $class = 'Text::Align::' . $mode;

    # based on the mode, set the %options hash for this derived class
    # of Text::Align
    my (%options) = ();
    if ($mode =~ /^WagnerFischer(\d+)$/) {
	if ($1 == 1) {
	    $options{weights} = [0,1,1.99];
	}
	elsif ($1 == 2) {
	    $options{weights} = [0,1,2];
	}
	$class =~ s/\d+$//;
    }
    elsif ($mode eq 'Levenshtein') {
    }
    elsif ($mode eq 'Covington' or $mode eq 'Covington_a') {
	use Lingua::FeatureMatrix;
	use Text::Align::Phone;
	my $phoneset =
	  Lingua::FeatureMatrix->new(eme => 'Text::Align::Phone',
				     file => 'phoneset.dat');
	if (not defined $phoneset) {
	    die "couldn't build lingua-featurematrix for covington\n";
	}
	$options{phoneset} = $phoneset;
    }
    else {
	die "unrecognized mode $mode\n";
    }

    # prepare the files
    open OUT, ">$outfile" or die "can't open $outfile for writing: $!\n";

    # write a byte order mark (this is UTF-8 output so this character
    # should be ignored by most readers).
    print OUT "\x{FEFF}";

    while (<FILE>) {
	# read the line with character semantics, not byte semantics:
	$_ = set_utf($_);

	tr/\x{FEFF}//d; # remove BOM from read lines
	if (/^#/) {
	    print OUT; # print comment lines unchanged
	    next;
	}

	# strip newlines
	chomp;

	# split up line (example below between pipes)
	#| todos  tu	# todos:tous 'all'|
	my ($cognates, $comment) = split(/#/, $_, 2);
	print OUT '#', $comment, "\n";

	$cognates =~ s/\s+$//; # strip trailing
	$cognates =~ s/^\s+//; # and leading spaces
	my ($left, $right) = split(/\t/, $cognates, 2);

	# the real alignment happens inside the call to new().
	my $alignment =
	  $class->new(left => $left,
		      right => $right,
		      %options,
		     );

	# now it's just a matter of printing out the results.
	my ($top, $bottom) = $alignment->as_strings(join => "  ");
	print OUT $top;
	print OUT "\t\t", $alignment->cost() if $SHOW_SCORE;
	print OUT "\n";
	print OUT $bottom, "\n";
	print OUT "\n";
    }
    close FILE or die "couldn't close $cognates: $!\n";
    close OUT or die "Couldn't close $outfile: $!\n";
}
##################################################################
sub set_utf {
    # thanks to perlmonks' grantm
    # (http://www.perlmonks.org/index.pl?node=grantm) for saving me by
    # pointing out this trick for setting UTF-8 character semantics in
    # Perl 5.6
    return pack "U0a*", join '', @_;
}
##################################################################

__END__

=head1 Usage instructions

  perl align_cognates.pl cognates-file.txt
  perl align_cognates.pl cognates-file.txt --show-score

Expects that C<phoneset.dat> is available in the current directory.

Expects C<cognates-file.txt> to be two words, tab-separated. Anything
after a '#' symbol will be ignored. (Hmm... that comment format sounds
familiar...). The file should be in UTF-8 format.

  WORD1   WORD2    # comments following '#' symbol

Generates the following files:

  Levenshtein.txt
  WagnerFischer1.txt
  WagnerFischer2.txt
  Covington.txt
  Covington_a.txt

Each file contains an alignment performed with that weighting
scheme. If the C<--show-score> argument is used, then each alignment
will show a total weight. By default, only the alignments (without the
weight) will be used.

=head1 Data

Note that these data use Covington's symbols (an Americanist notation)
rather than the IPA, which is somewhat more compatible with utf-8
character encoding.

=over

=item Covington1996cognates.txt

=item phoneset.dat

=back


=head1 Results

=cut

