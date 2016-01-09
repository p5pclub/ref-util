use strict;
use warnings;
use Test::More;

BEGIN {
    # 5.8.0+ gets 1 extra test for FORMAT reference
    # (see comment below)
    plan tests => 17 +
        ( ( $^V && $^V ge v5.8.0 ) ? 2 : 0 );

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
ok( is_globref(\*STDIN), 'is_globref' );

if ( $^V && $^V ge v5.8.0 ) {
format STDOUT =
.
    ok( is_formatref(*main::STDOUT{'FORMAT'}), 'is_formatref' );
    ok( is_ref(*main::STDOUT{'FORMAT'}), 'is_ref (formatref)' );
}

ok( is_ioref(*STDOUT{'IO'}), 'is_ioref' );
ok( is_refref(\\1), 'is_refref' );
