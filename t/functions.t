use strict;
use warnings;
use Test::More tests => 72;

BEGIN {
    use_ok('Ref::Util');

    Ref::Util->import(qw<
        is_ref
        is_scalarref
        is_arrayref
        is_hashref
        is_coderef
        is_regexpref
        is_globref
        is_formatref
        is_ioref
        is_refref
        is_plain_ref
        is_plain_scalarref
        is_plain_arrayref
        is_plain_hashref
        is_plain_coderef
        is_plain_globref
        is_plain_formatref
        is_plain_refref
    >);
}

my $blessed_glob = do {
    no warnings 'once';
    bless \*FOO;
};

ok( is_ref(\1), 'is_ref (scalarref)' );
ok( is_ref([]), 'is_ref (arrayref)' );
ok( is_ref({}), 'is_ref (hashref)' );
ok( is_ref(sub {1}), 'is_ref (coderef)' );
ok( is_ref(qr//), 'is_ref (regexpref)' );
ok( is_ref(\*STDIN), 'is_ref (globref)' );
ok( is_ref(*STDOUT{'IO'}), 'is_ref (ioref)' );
ok( is_ref(\\1), 'is_ref (refref)' );

ok( is_plain_ref(\1), 'is_plain_ref (scalarref)' );
ok( is_plain_ref([]), 'is_plain_ref (arrayref)' );
ok( is_plain_ref({}), 'is_plain_ref (hashref)' );
ok( is_plain_ref(sub {1}), 'is_plain_ref (coderef)' );
ok( is_plain_ref(\*STDIN), 'is_plain_ref (globref)' );
ok( is_plain_ref(\\1), 'is_plain_ref (refref)' );

ok( !is_plain_ref(do { bless \(my $x = 1) }), '!is_plain_ref (blessed scalarref)' );
ok( !is_plain_ref(bless []), '!is_plain_ref (blessed arrayref)' );
ok( !is_plain_ref(bless {}), '!is_plain_ref (blessed hashref)' );
ok( !is_plain_ref(bless sub {1}), '!is_plain_ref (blessed coderef)' );
ok( !is_plain_ref(bless \*FOO), '!is_plain_ref (blessed globref)' );
ok( !is_plain_ref(do { bless \\(my $x = 1) }), '!is_plain_ref (blessed refref)' );

ok( is_scalarref(\1), 'is_scalarref' );
ok( is_arrayref([]), 'is_arrayref' );
ok( is_hashref({}), 'is_hashref' );
ok( is_coderef(sub {1}), 'is_coderef' );
ok( is_regexpref(qr//), 'is_regexpref' );
ok( is_globref($blessed_glob), 'is_globref' );

ok( is_regexpref(bless qr/^/, 'Foo'), 'is_regexpref on blessed' );
ok( is_regexpref(bless qr/^/, 'Foo'), 'is_regexpref (randomly blessed)' );

ok( is_plain_scalarref(\1), 'is_plain_scalarref' );
ok( is_plain_arrayref([]), 'is_plain_arrayref' );
ok( is_plain_hashref({}), 'is_plain_hashref' );
ok( is_plain_coderef(sub {1}), 'is_plain_coderef' );
ok( is_plain_globref(\*STDIN), 'is_plain_globref' );

ok( !is_plain_scalarref(do { bless \(my $x = 1) }), 'is_plain_scalarref (blessed)' );
ok( !is_plain_arrayref(bless []), 'is_plain_arrayref (blessed)' );
ok( !is_plain_hashref(bless {}), 'is_plain_hashref (blessed)' );
ok( !is_plain_coderef(bless sub {1}), 'is_plain_coderef (blessed)' );
ok( !is_plain_globref($blessed_glob), 'is_plain_globref (blessed)' );

ok( !is_scalarref(\\1), '!is_scalarref (refref)' );
ok( !is_arrayref(\\1),  '!is_arrayref (refref)' );
ok( !is_hashref(\\1),   '!is_hashref (refref)' );
ok( !is_coderef(\\1),   '!is_coderef (refref)' );
ok( !is_regexpref(\\1), '!is_regexpref (refref)' );
ok( !is_globref(\\1),   '!is_globref (refref)' );
ok( !is_ioref(\\1),     '!is_ioref (refref)' );

ok( !is_plain_scalarref(\\1), '!is_plain_scalarref (refref)' );
ok( !is_plain_arrayref(\\1),  '!is_plain_arrayref (refref)' );
ok( !is_plain_hashref(\\1),   '!is_plain_hashref (refref)' );
ok( !is_plain_coderef(\\1),   '!is_plain_coderef (refref)' );
ok( !is_plain_globref(\\1),   '!is_plain_globref (refref)' );

SKIP: {
    skip 'format references do not exist before Perl 5.8.0', 10
        if !$^V || $^V lt v5.8.0;
    format STDOUT =
.
    my $ref = *main::STDOUT{'FORMAT'};
    ok( is_formatref($ref), 'is_formatref' );
    ok( is_ref($ref), 'is_ref (formatref)' );
    ok( is_plain_ref($ref), 'is_plain_ref (formatref)' );
    ok( is_plain_formatref($ref), 'is_plain_formatref' );
    ok( !is_formatref(\\1),  '!is_formatref (refref)' );
    ok( !is_plain_formatref(\\1), '!is_plain_formatref (refref)' );

    my $blessed = bless $ref, 'Surprise';
    ok( is_formatref($blessed), 'is_formatref (blessed)' );
    ok( is_ref($blessed), 'is_ref (blessed formatref)' );
    ok( !is_plain_ref($blessed), '!is_plain_ref (blessed formatref)' );
    ok( !is_plain_formatref($blessed), '!is_plain_formatref (blessed format)' );
}

ok( is_ioref(*STDOUT{'IO'}), 'is_ioref' );
ok( is_refref(\\1), 'is_refref' );
ok( is_plain_refref(\\1), 'is_plain_refref' );

ok( !is_scalarref(\*STDIN), "!is_scalarref (glob)" );
ok( !is_plain_scalarref(\*STDIN), "!is_plain_scalarref (glob)" );
ok( !is_scalarref($blessed_glob), "!is_scalarref (blessed glob)" );
ok( !is_plain_scalarref($blessed_glob), "!is_plain_scalarref (blessed glob)" );

ok( !is_scalarref(qr/./), "!is_scalarref (regexp)" );
ok( !is_plain_scalarref(qr/./), "!is_plain_scalarref (regexp)" );
ok( !is_scalarref(bless qr/./, 'Foo'), "!is_scalarref (randomly-blessed regexp" );
ok( !is_plain_scalarref(bless qr/./, 'Foo'),
    "!is_plain_scalarref (randomly-blessed regexp" );
