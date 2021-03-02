package Mojo::Promise::Merge;

# ABSTRACT: merge JSON from multiple responses

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(merge);

use Hash::Merge;
use JSON::Path;

sub merge {
    my $cb;

    if (ref $_[-1] eq 'CODE') {
	$cb = pop;
    } elsif (ref $_[-1] eq 'SCALAR') {
	my $query = ${pop()};
	my $jpath = JSON::Path->new($query);

	if ($query =~ /\[\*\]/) {
	    $cb = sub { [ $jpath->values(shift()->res->json) ] };
	} else {
	    $cb = sub { $jpath->value(shift()->res->json) };
	}
    } else {
	$cb = sub { return shift()->res->json }
    }
    my @r = map { $cb->($_) } map { $_->[0] } @_;
    my $b = {};
    for (@r) { $b = Hash::Merge::merge($b, $_) }
    return $b;
};

1;
