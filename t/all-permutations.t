use strict;
use warnings;
use Test::More 'tests' => 3;
use Ref::Util ':all';

use DDP; use Data::Dumper;

my $plain_formatref = do {
    format FH1 =
.
    *FH1{'FORMAT'};
};

my $blessed_formatref = bless do {
    format FH2 =
.
    *FH2{'FORMAT'};
}, 'FormatRef';

my ( $var_for_globref, $var_for_blessed_globref );
my $plain_scalar = 'string';
my $var_for_scalarref = 'stringy';
my $blessed_scalarref = bless \$var_for_scalarref, 'ScalarRef';

my %all;
{;
    # globref causes this warning
    no warnings qw<once>;

    %all = (
        'plain_scalarref' => \$plain_scalar,
        'plain_arrayref'  => [],
        'plain_hashref'   => +{},
        'plain_coderef'   => sub {'plain_code'},
        'plain_globref'   => \*::var_for_globref,
        'plain_formatref' => $plain_formatref,
        'plain_refref'    => \\$plain_scalar,

        'blessed_scalarref' => $blessed_scalarref,
        'blessed_arrayref'  => bless( [], 'ArrayRef' ),
        'blessed_hashref'   => bless( +{}, 'HashRef' ),
        'blessed_coderef'   => bless( sub {'blessed_code'}, 'CodeRef' ),
        'blessed_globref'   => bless( \*::var_for_blessed_globref, 'GlobRef' ),
        'blessed_formatref' => $blessed_formatref,
        'blessed_refref'    => bless( \\$blessed_scalarref, 'RefRef' ),
    );
}

my ( %plain, %blessed );
foreach my $key ( keys %all ) {
    $key =~ /^plain_/   and $plain{$key}   = $all{$key};
    $key =~ /^blessed_/ and $blessed{$key} = $all{$key};
}

my @all_keys     = sort keys %all;
my @plain_keys   = sort keys %plain;
my @blessed_keys = sort keys %blessed;

# FIXME: is_any_ref should added here
subtest 'is_ref' => sub {
    # FIXME: is_any_ref() does * 2 on next two lines
    plan 'tests' => scalar(@all_keys)
                    + 7;

    foreach my $key (@all_keys) {
        ok( is_ref( $all{$key} ), "is_ref($key) is true" );

        # FIXME: is_any_ref
        #ok( is_any_ref( $all{$key} ), "is_any_ref($key) is true" );
    }

    foreach my $value ( 0, 1, 'string', '', undef, '0', '0e0' ) {
        # better string representation for test output
        my $rep = defined $value ? $value eq '' ? q{''} : $value : '(undef)';

        ok( !is_ref($value), "is_ref($rep) is false" );

        # FIXME: is_any_ref
        #ok( !is_any_ref($value), "is_any_ref($rep) is false" );
    }
};

subtest 'plain references' => sub {
    # I don't have the energy to figure this count
    #plan 'tests' => scalar(@plain_keys) * scalar(@blessed_keys)
    #                  # is_blessed_ref() is not in the %blessed hash
    #                + 1 * scalar(@plain_keys);

    plan 'tests' => 119;

    # each %plain should fail each test of the %blessed
    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        ok(
            !is_blessed_ref($value),
            "is_blessed_ref($plain_type) is false",
        );

        ok(
            !is_blessed_scalarref($value),
            "is_blessed_scalarref($plain_type) is false",
        );

        ok(
            !is_blessed_arrayref($value),
            "is_blessed_arrayref($plain_type) is false",
        );

        ok(
            !is_blessed_hashref($value),
            "is_blessed_hashref($plain_type) is false",
        );

        ok(
            !is_blessed_coderef($value),
            "is_blessed_coderef($plain_type) is false",
        );

        ok(
            !is_blessed_globref($value),
            "is_blessed_coderef($plain_type) is false",
        );

        ok(
            !is_blessed_formatref($value),
            "is_blessed_formatref($plain_type) is false",
        );

        ok(
            !is_blessed_refref($value),
            "is_blessed_refref($plain_type) is false",
        );
    }

    # each should fail everything except their own
    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        ok(
            is_plain_ref($value),
            "is_plain_ref($plain_type) is true",
        );
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        $plain_type eq 'plain_scalarref'
            ? ok(
                is_plain_scalarref($value),
                "is_plain_scalarref($plain_type) is true",
            )
            : ok(
                !is_plain_scalarref($value),
                "is_plain_scalarref($plain_type) is false",
            );
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        $plain_type eq 'plain_scalarref'
            ? ok(
                is_plain_scalarref($value),
                "is_plain_scalarref($plain_type) is true",
            )
            : ok(
                !is_plain_scalarref($value),
                "is_plain_scalarref($plain_type) is false",
            );
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        $plain_type eq 'plain_arrayref'
            ? ok(
                is_plain_arrayref($value),
                "is_plain_arrayref($plain_type) is true",
            )
            : ok(
                !is_plain_arrayref($value),
                "is_plain_arrayref($plain_type) is false",
            );
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        $plain_type eq 'plain_hashref'
            ? ok(
                is_plain_hashref($value),
                "is_plain_hashref($plain_type) is true",
            )
            : ok(
                !is_plain_hashref($value),
                "is_plain_hashref($plain_type) is false",
            );
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        $plain_type eq 'plain_coderef'
            ? ok(
                is_plain_coderef($value),
                "is_plain_coderef($plain_type) is true",
            )
            : ok(
                !is_plain_coderef($value),
                "is_plain_coderef($plain_type) is false",
            );
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        $plain_type eq 'plain_globref'
            ? ok(
                is_plain_globref($value),
                "is_plain_globref($plain_type) is true",
            )
            : ok(
                !is_plain_globref($value),
                "is_plain_globref($plain_type) is false",
            );
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        $plain_type eq 'plain_formatref'
            ? ok(
                is_plain_formatref($value),
                "is_plain_formatref($plain_type) is true",
            )
            : ok(
                !is_plain_formatref($value),
                "is_plain_formatref($plain_type) is false",
            );
    }

    foreach my $plain_type (@plain_keys) {
        my $value = $plain{$plain_type};

        $plain_type eq 'plain_globref'
            ? ok(
                is_plain_globref($value),
                "is_plain_globref($plain_type) is true",
            )
            : ok(
                !is_plain_globref($value),
                "is_plain_globref($plain_type) is false",
            );
    }
};

subtest 'blessed references' => sub {
    plan 'tests' => 119;

    # each %blessed should fail each test of the %plain
    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        ok(
            !is_plain_ref($value),
            "is_plain_ref($blessed_type) is false",
        );

        ok(
            !is_plain_scalarref($value),
            "is_plain_scalarref($blessed_type) is false",
        );

        ok(
            !is_plain_arrayref($value),
            "is_plain_arrayref($blessed_type) is false",
        );

        ok(
            !is_plain_hashref($value),
            "is_plain_hashref($blessed_type) is false",
        );

        ok(
            !is_plain_coderef($value),
            "is_plain_coderef($blessed_type) is false",
        );

        ok(
            !is_plain_globref($value),
            "is_plain_coderef($blessed_type) is false",
        );

        ok(
            !is_plain_formatref($value),
            "is_plain_formatref($blessed_type) is false",
        );

        ok(
            !is_plain_refref($value),
            "is_plain_refref($blessed_type) is false",
        );
    }

    # each should fail everything except their own
    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        ok(
            is_blessed_ref($value),
            "is_blessed_ref($blessed_type) is true",
        );
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        $blessed_type eq 'blessed_scalarref'
            ? ok(
                is_blessed_scalarref($value),
                "is_blessed_scalarref($blessed_type) is true",
            )
            : ok(
                !is_blessed_scalarref($value),
                "is_blessed_scalarref($blessed_type) is false",
            );
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        $blessed_type eq 'blessed_scalarref'
            ? ok(
                is_blessed_scalarref($value),
                "is_blessed_scalarref($blessed_type) is true",
            )
            : ok(
                !is_blessed_scalarref($value),
                "is_blessed_scalarref($blessed_type) is false",
            );
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        $blessed_type eq 'blessed_arrayref'
            ? ok(
                is_blessed_arrayref($value),
                "is_blessed_arrayref($blessed_type) is true",
            )
            : ok(
                !is_blessed_arrayref($value),
                "is_blessed_arrayref($blessed_type) is false",
            );
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        $blessed_type eq 'blessed_hashref'
            ? ok(
                is_blessed_hashref($value),
                "is_blessed_hashref($blessed_type) is true",
            )
            : ok(
                !is_blessed_hashref($value),
                "is_blessed_hashref($blessed_type) is false",
            );
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        $blessed_type eq 'blessed_coderef'
            ? ok(
                is_blessed_coderef($value),
                "is_blessed_coderef($blessed_type) is true",
            )
            : ok(
                !is_blessed_coderef($value),
                "is_blessed_coderef($blessed_type) is false",
            );
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        $blessed_type eq 'blessed_globref'
            ? ok(
                is_blessed_globref($value),
                "is_blessed_globref($blessed_type) is true",
            )
            : ok(
                !is_blessed_globref($value),
                "is_blessed_globref($blessed_type) is false",
            );
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        $blessed_type eq 'blessed_formatref'
            ? ok(
                is_blessed_formatref($value),
                "is_blessed_formatref($blessed_type) is true",
            )
            : ok(
                !is_blessed_formatref($value),
                "is_blessed_formatref($blessed_type) is false",
            );
    }

    foreach my $blessed_type (@blessed_keys) {
        my $value = $blessed{$blessed_type};

        $blessed_type eq 'blessed_globref'
            ? ok(
                is_blessed_globref($value),
                "is_blessed_globref($blessed_type) is true",
            )
            : ok(
                !is_blessed_globref($value),
                "is_blessed_globref($blessed_type) is false",
            );
    }
};
