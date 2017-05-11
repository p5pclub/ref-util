package Ref::Util::PP;

# ABSTRACT: pure-Perl version of Ref::Util

use strict;
use warnings;
use Carp         ();
use Scalar::Util ();
use Exporter 5.57 'import';

our %EXPORT_TAGS = ( 'all' => [qw<
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

    is_blessed_ref
    is_blessed_scalarref
    is_blessed_arrayref
    is_blessed_hashref
    is_blessed_coderef
    is_blessed_globref
    is_blessed_formatref
    is_blessed_refref
>] );
our @EXPORT      = ();
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

# ----
# -- is_*
# ----

sub is_ref($) { ref $_[0] }

sub is_scalarref($) {
    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'SCALAR';
}

sub is_arrayref($) {
    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'ARRAY';
}

sub is_hashref($) {
    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'HASH';
}

sub is_coderef($) {
    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'CODE';
}

sub is_regexpref($) {
    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'REGEXP';
}

sub is_globref($) {
    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'GLOB';
}

sub is_formatref($) {
    "$]" < 5.007
        and
        Carp::croak("is_formatref() isn't available on Perl 5.6.x and under");

    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'FORMAT';
}

sub is_ioref($) {
    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'IO';
}

sub is_refref($) {
    no warnings 'uninitialized';
    Scalar::Util::reftype( $_[0] ) eq 'REF';
}

# ----
# -- is_plain_*
# ----

sub is_plain_ref($) { ref $_[0] && !Scalar::Util::blessed( $_[0] ) }

sub is_plain_scalarref($) {
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'SCALAR';
}

sub is_plain_arrayref($) {
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'ARRAY';
}

sub is_plain_hashref($) {
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'HASH';
}

sub is_plain_coderef($) {
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'CODE';
}

sub is_plain_globref($) {
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'GLOB';
}

sub is_plain_formatref($) {
    "$]" < 5.007
        and
        Carp::croak("is_formatref() isn't available on Perl 5.6.x and under");

    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'FORMAT';
}

sub is_plain_refref($) {
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'REF';
}

# ----
# -- is_blessed_*
# ----

sub is_blessed_ref($) { defined Scalar::Util::blessed( $_[0] ) }

sub is_blessed_scalarref($) {
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'SCALAR';
}

sub is_blessed_arrayref($) {
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'ARRAY';
}

sub is_blessed_hashref($) {
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'HASH';
}

sub is_blessed_coderef($) {
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'CODE';
}

sub is_blessed_globref($) {
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'GLOB';
}

sub is_blessed_formatref($) {
    "$]" < 5.007
        and
        Carp::croak("is_formatref() isn't available on Perl 5.6.x and under");

    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'FORMAT';
}

sub is_blessed_refref($) {
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'REF';
}

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION
