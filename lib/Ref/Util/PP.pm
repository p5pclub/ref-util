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

sub _using_custom_ops () { 0 }

# ----
# -- is_*
# ----

sub is_ref($) { length ref $_[0] }

sub is_scalarref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_scalarref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'SCALAR';
}

sub is_arrayref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_arrayref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'ARRAY';
}

sub is_hashref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_hashref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'HASH';
}

sub is_coderef($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_coderef") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'CODE';
}

sub is_regexpref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_regexpref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'REGEXP';
}

sub is_globref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_globref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'GLOB';
}

sub is_formatref($) {
    "$]" < 5.007
        and
        Carp::croak("is_formatref() isn't available on Perl 5.6.x and under");

    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_formatref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'FORMAT';
}

sub is_ioref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_ioref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'IO';
}

sub is_refref($) {
    no warnings 'uninitialized';
    Carp::croak("Too many arguments for is_refref") if @_ > 1;
    Scalar::Util::reftype( $_[0] ) eq 'REF';
}

# ----
# -- is_plain_*
# ----

sub is_plain_ref($) {
    Carp::croak("Too many arguments for is_plain_ref") if @_ > 1;
    ref $_[0] && !Scalar::Util::blessed( $_[0] );
}

sub is_plain_scalarref($) {
    Carp::croak("Too many arguments for is_plain_scalarref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'SCALAR';
}

sub is_plain_arrayref($) {
    Carp::croak("Too many arguments for is_plain_arrayref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'ARRAY';
}

sub is_plain_hashref($) {
    Carp::croak("Too many arguments for is_plain_hashref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'HASH';
}

sub is_plain_coderef($) {
    Carp::croak("Too many arguments for is_plain_coderef") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'CODE';
}

sub is_plain_globref($) {
    Carp::croak("Too many arguments for is_plain_globref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'GLOB';
}

sub is_plain_formatref($) {
    "$]" < 5.007
        and
        Carp::croak("is_formatref() isn't available on Perl 5.6.x and under");

    Carp::croak("Too many arguments for is_formatref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'FORMAT';
}

sub is_plain_refref($) {
    Carp::croak("Too many arguments for is_plain_refref") if @_ > 1;
    !defined Scalar::Util::blessed( $_[0] )
        && ref( $_[0] ) eq 'REF';
}

# ----
# -- is_blessed_*
# ----

sub is_blessed_ref($) {
    Carp::croak("Too many arguments for is_blessed_ref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] );
}

sub is_blessed_scalarref($) {
    Carp::croak("Too many arguments for is_blessed_scalarref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'SCALAR';
}

sub is_blessed_arrayref($) {
    Carp::croak("Too many arguments for is_blessed_arrayref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'ARRAY';
}

sub is_blessed_hashref($) {
    Carp::croak("Too many arguments for is_blessed_hashref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'HASH';
}

sub is_blessed_coderef($) {
    Carp::croak("Too many arguments for is_blessed_coderef") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'CODE';
}

sub is_blessed_globref($) {
    Carp::croak("Too many arguments for is_blessed_globref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'GLOB';
}

sub is_blessed_formatref($) {
    "$]" < 5.007
        and
        Carp::croak("is_formatref() isn't available on Perl 5.6.x and under");

    Carp::croak("Too many arguments for is_formatref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'FORMAT';
}

sub is_blessed_refref($) {
    Carp::croak("Too many arguments for is_blessed_refref") if @_ > 1;
    defined Scalar::Util::blessed( $_[0] )
        && Scalar::Util::reftype( $_[0] ) eq 'REF';
}

1;

__END__

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION
