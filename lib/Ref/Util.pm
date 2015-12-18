package Ref::Util;

use strict;
use warnings;
use XSLoader;

use Exporter 5.57 'import';

our $VERSION     = '0.003';
our %EXPORT_TAGS = ( 'all' => [qw<
    is_scalarref is_arrayref is_hashref is_coderef is_regexpref
    is_globref is_formatref is_ioref is_refref
>] );
our @EXPORT      = ();
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

XSLoader::load('Ref::Util', $VERSION);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Ref::Util - Utility functions for checking references

=head1 VERSION

0.003

=head1 DESCRIPTION

Ref::Util introduces several functions to help identify references in a
faster and B<smarter> way. In short:

    ref $foo eq 'ARRAY'

    # is now:

    is_arrayref($foo)

The difference:

=over 4

=item * Fast

The benchmark:

    my $bench = Dumbbench->new(
        target_rel_precision => 0.005,
        initial_runs         => 20,
    );

    my $ref = [];
    $bench->add_instances(
        Dumbbench::Instance::PerlSub->new(
            name => 'XS',
            code => sub { Ref::Util::is_arrayref($ref) for(1..1e7) },
        ),

        Dumbbench::Instance::PerlSub->new(
            name => 'reftype',
            code => sub { reftype($ref) eq 'ARRAY' for(1..1e7) },
        ),

        Dumbbench::Instance::PerlSub->new(
            name => 'PP',
            code => sub { ref($ref) eq 'ARRAY' for(1..1e7) },
        ),
    );

The results:

    XS: Ran 27 iterations (7 outliers).
    XS: Rounded run time per iteration: 2.9665e-01 +/- 1.2e-04 (0.0%)
    reftype: Ran 26 iterations (6 outliers).
    reftype: Rounded run time per iteration: 9.1131e-01 +/- 7.2e-04 (0.1%)
    PP: Ran 29 iterations (9 outliers).
    PP: Rounded run time per iteration: 6.0823e-01 +/- 4.4e-04 (0.1%)

=item * No comparison against a string constant

When you call C<ref>, you stringify the reference and then compare it
to some string constant (like C<ARRAY> or C<HASH>). Not just awkward,
it's brittle since you can mispell the string.

If you use L<Scalar::Util>'s C<reftype>, you still compare it as a
string:

    if ( reftype($foo) eq 'ARRAY' ) { ... }

=item * Supports blessed variables

When calling C<ref>, you receive either the reference type (B<SCALAR>,
B<ARRAY>, B<HASH>, etc.) or the package it's blessed into.

When calling C<is_arrayref> (et. al.), you check the variable flags,
so even if it's blessed, you know what type of variable is blessed.

    my $foo = bless {}, 'PKG';
    ref($foo) eq 'HASH'; # fails

    use Ref::Util 'is_hashref';
    my $foo = bless {}, 'PKG';
    is_hashref($foo); # works

=item * Ignores overloading

These functions ignore overloaded operators and simply check the
variable type. Overloading will likely not ever be supported, since I
deem it problematic and confusing.

Overloading makes your variables opaque containers and hides away
B<what> they are and instead require you to figure out B<how> to use
them. This leads to code that has to test different abilities (in
C<eval>, so it doesn't crash) and to interfaces that get around what
a person thought you would do with a variable. Ugh. Double Ugh.
For this reason they are not supported.

This is also not duck-typing, as at least one person suggested. Duck
typing provides a method that *works* and has different
implementations. The difference is that here we have different methods
(stringification, array dereferencing, hash dereferencing, callbacks,
greater-than comparsion, etc.) which have to be tested each
individually. This is the B<opposite> of duck-typing. Also, in
duck-typing you can introspect to know what is available, and
overloading does not lend to that.

Overloading is cool, but terribly horrible. 'Nuff said.

=item * Possibly susceptible to change

On a new enough Perl (2010+), it will use the op code implementation
(see below), which, in case the op tree changes, it will have to be
updated. That's not likely to happen but if any such changes arise,
the code will be updated to fix it.

=item * Ignores subtle types:

The following types, provided by L<Scalar::Util>'s C<reftype>, are
not supported:

=over 4

=item * C<VSTRING>

This is a C<PVMG> ("normal" variable) with a flag set for VSTRINGs.
Since this is not a reference, it is not supported.

=item * C<LVALUE>

A variable that delegates to another scalar. Since this is not a
reference, it is not supported.

=item * C<INVLIST>

I couldn't find documentation for this type.

=back

Support might be added, if a good reason arises.

=back

Additionally, two implementations are available, depending on the perl
version you have. For perl that supports Custom OPs, we actually add
an OP code (which is faster), and for perls that do not, we include
an implementation that just calls an XS function - which is still
faster than the Pure-Perl equivalent.

We might also introduce a Pure-Perl version of everything, allowing
to install this module where a compiler is not available, making the
XS parts optional.

=head1 EXPORT

Nothing is exported by default. You can ask for specific subroutines
(described below) or ask for all subroutines at once:

    use Ref::Util qw<is_scalarref is_arrayref is_hashref ...>;

    # or

    use Ref::Util ':all';

=head1 SUBROUTINES

=head2 is_scalarref($ref)

Check for a scalar reference.

    is_scalarref(\"hello");
    is_scalarref(\30);
    is_scalarref(\$value);

=head2 is_arrayref($ref)

Check for an array reference.

    is_arrayref([]);

=head2 is_hashref($ref)

Check for a hash reference.

    is_hashref({});

=head2 is_coderef($ref)

Check for a code reference.

    is_coderef( sub {} );

=head2 is_regexpref($ref)

Check for a regular expression (regex, regexp) reference.

    is_regexpref( qr// );

=head2 is_globref($ref)

Check for a glob reference.

    is_globref( \*STDIN );

=head2 is_formatref($ref)

Check for a format reference.

    # set up format in STDOUT
    format STDOUT =
    .

    # now we can test it
    is_formatref( *main::STDOUT{'FORMAT'} );

=head2 is_ioref($ref)

Check for an IO reference.

    is_ioref( *STDOUT{IO} );

=head2 is_refref($ref)

Check for a reference to a reference.

    is_refref( \[] ); # reference to array reference

=head1 SEE ALSO

=over 4

=item * L<Params::Classify>

=item * L<Scalar::Util>

=back

=head1 THANKS

The following people have been invaluable in their feedback and support.

=over 4

=item * Yves Orton

=item * Steffen Müller

=item * Jarkko Hietaniemi

=item * Mattia Barbon

=back

=head1 AUTHORS

=over 4

=item * Vikentiy Fesunov

=item * Sawyer X

=item * Gonzalo Diethelm

=item * p5pclub

=back
