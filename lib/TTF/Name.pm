package TTF::Name;

=head1 NAME

TTF::Name - String table for a TTF font

=head1 DESCRIPTION

Strings are held by number, platform, encoding and language. Strings are
accessed as:

    $f->{'name'}{'strings'}[$number][$platform_id][$encoding_id]{$language_id}

Notice that the language is held in an associative array due to its sparse
nature on some platforms such as Microsoft ($pid = 3). Notice also that the
array order is different from the stored array order (platform, encoding,
language, number) to allow for easy manipulation of strings by number (which is
what I guess most people will want to do).

Strings are stored according to platform:

=over 4

=item Unicode (platform id = 0)

Currently stored as 16-bit network ordered UCS2. Upon release of Perl 5.005 this
will change to utf8 assuming current UCS2 semantics for all encoding ids.

=item Mac (platform id = 1)

Data is stored as 8-bit binary data, leaving the interpretation to the user
according to encoding id.

=item Windows (platform id = 3)

As per Unicode, the data is currently stored as 16-bit network ordered UCS2. Upon
release of Perl 5.005 this will change to utf8 assuming current UCS2 semantics for
all encoding ids.

=back

=head1 INSTANCE VARIABLES

=over 4

=item strings

An array of arrays, etc.

=back

=head1 METHODS

=cut

use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(TTF::Table);

$VERSION = 1.001;           # MJPH  10-AUG-1998     Put $number first in list

=head2 $t->read

Reads all the names into memory

=cut

sub read
{
    my ($self) = @_;
    my ($fh) = $self->{' INFILE'};
    my ($dat, $num, $stroff, $i, $pid, $eid, $lid, $nid, $len, $off, $here);

    $self->SUPER::read or return $self;
    read($fh, $dat, 6);
    ($num, $stroff) = unpack("x2nn", $dat);
    for ($i = 0; $i < $num; $i++)
    {
        read($fh, $dat, 12);
        ($pid, $eid, $lid, $nid, $len, $off) = unpack("n6", $dat);
        $here = tell($fh);
        seek($fh, $self->{' OFFSET'} + $stroff + $off, 0);
        read($fh, $dat, $len);
# do platform specific munging here to utf8
        $self->{'strings'}[$nid][$pid][$eid]{$lid} = $dat;
        seek($fh, $here, 0);
    }
    $self;
}


=head2 $t->out($fh)

Writes out all the strings

=cut

sub out
{
    my ($self, $fh) = @_;
    my ($pid, $eid, $lid, $nid, $todo, @todo);
    my ($len, $offset, $loc, $stroff, $endloc, $str_trans);

    return $self->SUPER::out($fh) unless $self->{' read'};

    $loc = tell($fh);
    print $fh pack("n3", 0, 0, 0);
    foreach $nid (@{$self->{'strings'}})
    {
        foreach $pid (@{$self->{'strings'}[$nid]})
        {
            foreach $eid (@{$self->{'strings'}[$nid][$pid]})
            {
                foreach $lid (keys %{$self->{'strings'}[$nid][$pid]})
                {
                    $str_trans = $self->{'strings'}[$nid][$pid][$eid]{$lid};
# do platform specific munging here
                    push (@todo, [$pid, $eid, $lid, $nid, $str_trans]);
                }
            }
        }
    }

    $offset = 0;
    @todo = (sort {$a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] || $a->[2] <=> $a->[2]
            || $a->[3] <=> $b->[3]} @todo);
    foreach $todo (@todo)
    {
        $len = length($todo->[4]);
        print $fh pack("n6", $pid, $eid, $lid, $nid, $len, $offset);
        $offset += $len;
    }
    
    $stroff = tell($fh) - $loc;
    foreach $todo (@todo)
    { print $fh $todo->[4]; }

    $endloc = tell($fh);
    seek($fh, $loc, 0);
    print $fh pack("n3", 0, $#todo + 1, $stroff);
    seek($fh, $endloc, 0);
    $self;
}

1;

=head1 BUGS

=item *

Unicode type strings will be stored in utf8 for all known platforms,
once Perl 5.005 has been released.

=head1 AUTHOR

Martin Hosken L<Martin_Hosken@sil.org>. See L<TTF::Font> for copyright and
licensing.

=cut

