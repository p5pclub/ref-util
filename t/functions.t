use strict;
use warnings;
use Test::More tests => 31;

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
        is_plain_scalarref
        is_plain_arrayref
        is_plain_hashref
        is_plain_coderef
        is_plain_globref
    >);
}

ok( is_ref(\1), 'is_ref (scalarref)' );
ok( is_ref([]), 'is_ref (arrayref)' );
ok( is_ref({}), 'is_ref (hashref)' );
ok( is_ref(sub {1}), 'is_ref (coderef)' );
ok( is_ref(qr//), 'is_ref (regexpref)' );
ok( is_ref(\*STDIN), 'is_ref (globref)' );
ok( is_ref(*STDOUT{'IO'}), 'is_ref (ioref)' );
ok( is_ref(\\1), 'is_ref (refref)' );

ok( is_scalarref(\1), 'is_scalarref' );
ok( is_arrayref([]), 'is_arrayref' );
ok( is_hashref({}), 'is_hashref' );
ok( is_coderef(sub {1}), 'is_coderef' );
ok( is_regexpref(qr//), 'is_regexpref' );
ok( is_regexpref(bless qr//, 'Foo'), 'is_regexpref on blessed' );
ok( is_globref(\*STDIN), 'is_globref' );

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
ok( !is_plain_globref(bless \*STDIN), 'is_plain_globref (blessed)' );

SKIP: {
    skip 'format references do not exist before Perl 5.8.0', 2
        if !$^V || $^V lt v5.8.0;
    format STDOUT =
.
    ok( is_formatref(*main::STDOUT{'FORMAT'}), 'is_formatref' );
    ok( is_ref(*main::STDOUT{'FORMAT'}), 'is_ref (formatref)' );
}

ok( is_ioref(*STDOUT{'IO'}), 'is_ioref' );
ok( is_refref(\\1), 'is_refref' );
