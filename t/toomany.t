use strict;
use warnings;
use Test::More tests => 4;
use Ref::Util qw<is_arrayref is_hashref>;

my $array_func = \&is_arrayref;
my $hash_func = \&is_hashref;

# We have to use string eval for this, because when the custom op is being
# used, we expect the direct calls to fail at compile time
my @cases = (
    [is_arrayref => 'is_arrayref([], 17)',
     'direct array call with too many arguments'],
    [is_arrayref => '$array_func->([], 17)',
     'array call through coderef with too many arguments'],
    [is_hashref => 'is_hashref([], 17)',
     'direct hash call with too many arguments'],
    [is_hashref => '$hash_func->([], 17)',
     'hash call through coderef with too many arguments'],
);

for my $case (@cases) {
    my ($name, $code, $desc) = @$case;
    scalar eval $code;
    my $exn = $@;
    like($exn, qr/^(?: \QUsage: Ref::Util::$name(ref)\E
                     | \QToo many arguments for Ref::Util::$name\E\b )/x,
         $desc);
}
