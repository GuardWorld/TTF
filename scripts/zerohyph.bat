@rem = ('--*-Perl-*--
@echo off
if not exist %0 goto n1
perl %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:n1
if not exist %0.bat goto n2
perl %0.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:n2
perl -S %0.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ') if 0;
require 'getopts.pl';
use TTF::Font;

Getopts('u:');

unless (defined $ARGV[1])
{
    die <<'EOT';
    ZEROHYPH [-u unicode] infile outfile
Converts the hyphen glyph (or whichever Unicode valued glyph) to a zero width
space.

Handles the following tables: hmtx, loca, glyf, hdmx, LTSH, kern (MS
compatability only).

    -u unicode      unicode value in hex [002D]
EOT
}

$opt_u = "2D" unless defined $opt_u;
$opt_u = hex($opt_u);

my ($hyphnum);          # local scope for anonymous subs

$f = TTF::Font->open($ARGV[0]);
$hyphnum = $f->{'cmap'}->read->ms_lookup($opt_u);
$f->{'hmtx'}->read->{'advance'}[$hyphnum] = 0;
$f->{'hmtx'}{'lsb'}[$hyphnum] = 0;
$f->{'loca'}->read->{'glyphs'}[$hyphnum] = "";
$f->{'hdmx'}->read->tables_do(sub { $_[0][$hyphnum] = 0; }) if defined $f->{'hdmx'};
$f->{'LTSH'}->read->{'glyphs'}[$hyphnum] = 1 if defined $f->{'LTSH'};

# deal with MS kerning only.
if (defined $f->{'kern'} && $f->{'kern'}->read->{'tables'}[0]{'type'} == 0)
{
    delete $f->{'kern'}{'tables'}[0]{'kerns'}{$hyphnum};
    while (($l, $r) = each(%{$f->{'kern'}{'tables'}[0]}))
    {  delete $r->{$g} if defined $r->{$g}; }
}

$f->out($ARGV[1]);

__END__
:endofperl
