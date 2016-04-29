package Ref::Util;

use strict;
use warnings;
use XSLoader;

use Exporter 5.57 'import';

our $VERSION     = '0.010';
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

XSLoader::load('Ref::Util', $VERSION);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Ref::Util - Utility functions for checking references

=head1 VERSION

0.010

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

    XS:      Ran 27 iterations (6 outliers).
    XS:      Rounded run time per iteration: 3.0093e-01 +/- 4.4e-04 (0.1%)

    reftype: Ran 25 iterations (5 outliers).
    reftype: Rounded run time per iteration: 9.173e-01 +/- 1.2e-03 (0.1%)

    PP:      Ran 26 iterations (6 outliers).
    PP:      Rounded run time per iteration: 6.1437e-01 +/- 3.4e-04 (0.1%)

=item * No comparison against a string constant

When you call C<ref>, you stringify the reference and then compare it
to some string constant (like C<ARRAY> or C<HASH>). Not just awkward,
it's brittle since you can mispell the string.

If you use L<Scalar::Util>'s C<reftype>, you still compare it as a
string:

    if ( reftype($foo) eq 'ARRAY' ) { ... }

=item * Supports blessed variables

B<Note:> In future versions, the idea is to make the default functions
use the B<plain> variation, which means explicitly non-blessed references.
If you want to explicitly check for B<blessed> references, you should use
the C<is_blessed_*> functions. There will be an C<is_any_*> variation
which will act like the current main functions - not caring whether it's
blessed or not.

When calling C<ref>, you receive either the reference type (B<SCALAR>,
B<ARRAY>, B<HASH>, etc.) or the package it's blessed into.

When calling C<is_arrayref> (et. al.), you check the variable flags,
so even if it's blessed, you know what type of variable is blessed.

    my $foo = bless {}, 'PKG';
    ref($foo) eq 'HASH'; # fails

    use Ref::Util 'is_hashref';
    my $foo = bless {}, 'PKG';
    is_hashref($foo); # works

On the other hand, in some situations it might be better to specifically
exclude blessed references. The rationale for that might be that merely
because some object happens to be implemented using a hash doesn't mean it's
necessarily correct to treat it as a hash. For these situations, you can use
C<is_plain_hashref> and friends, which have the same performance benefits as
C<is_hashref>.

There is also a family of functions with names like C<is_blessed_hashref>;
these return true for blessed object instances that are implemented using
the relevant underlying type.

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

Overloading is I<cool, but terribly horrible>. 'Nuff said.

=item * Readonly, tied variables, and magic

Tied variables (used in L<Readonly>, for example) are not supported,
as they are not references, but regular variables with added magic.

Consider the following:

    use Data::Printer;
    use Readonly;
    Readonly::Scalar my $rh2 => { a => { b => 2 } };
    p $rh2->{a};

    # result:
    # "HASH(0x187dcc8)"

This should print a hashref structure with key B<b> and value B<2>,
but it doesn't. It prints a string. It should have retrieved the
values but caused stringification instead.

The problem here is that C<< $rh2->{a} >> is not a hashref, but a
C<PVLV> with magic, so C<is_hashref> will correctly not detect it.

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
version you have. For perls that supports Custom OPs, we actually add
an OP (which is faster), and for perls that do not, we include
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

=head2 is_ref($ref)

Check for a reference to anything.

    is_ref([]);

=head2 is_scalarref($ref)

Check for a scalar reference.

    is_scalarref(\"hello");
    is_scalarref(\30);
    is_scalarref(\$value);

Note that, even though a reference is itself a type of scalar value, a
reference to another reference is not treated as a scalar reference:

    !is_scalarref(\\1);

The rationale for this is two-fold. First, callers that want to decide how
to handle inputs based on their reference type will usually want to treat a
ref-ref and a scalar-ref differently. Secondly, this more closely matches
the behavior of the C<ref> builtin and of L<Scalar::Util/reftype>, which
report a ref-ref as C<REF> rather than C<SCALAR>.

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

This function is not available in Perl 5.6 and will trigger a
C<croak()>.

=head2 is_ioref($ref)

Check for an IO reference.

    is_ioref( *STDOUT{IO} );

=head2 is_refref($ref)

Check for a reference to a reference.

    is_refref( \[] ); # reference to array reference

=head2 is_plain_scalarref($ref)

Check for an unblessed scalar reference.

    is_plain_scalarref(\"hello");
    is_plain_scalarref(\30);
    is_plain_scalarref(\$value);

=head2 is_plain_ref($ref)

Check for an unblessed reference to anything.

    is_plain_ref([]);

=head2 is_plain_arrayref($ref)

Check for an unblessed array reference.

    is_plain_arrayref([]);

=head2 is_plain_hashref($ref)

Check for an unblessed hash reference.

    is_plain_hashref({});

=head2 is_plain_coderef($ref)

Check for an unblessed code reference.

    is_plain_coderef( sub {} );

=head2 is_plain_globref($ref)

Check for an unblessed glob reference.

    is_plain_globref( \*STDIN );

=head2 is_plain_formatref($ref)

Check for an unblessed format reference.

    # set up format in STDOUT
    format STDOUT =
    .

    # now we can test it
    is_plain_formatref(bless *main::STDOUT{'FORMAT'} );

=head2 is_plain_refref($ref)

Check for an unblessed reference to a reference.

    is_plain_refref( \[] ); # reference to array reference

=head2 is_blessed_scalarref($ref)

Check for a blessed scalar reference.

    is_blessed_scalarref(bless \$value);

=head2 is_blessed_ref($ref)

Check for a blessed reference to anything.

    is_blessed_ref(bless [], $class);

=head2 is_blessed_arrayref($ref)

Check for a blessed array reference.

    is_blessed_arrayref(bless [], $class);

=head2 is_blessed_hashref($ref)

Check for a blessed hash reference.

    is_blessed_hashref(bless {}, $class);

=head2 is_blessed_coderef($ref)

Check for a blessed code reference.

    is_blessed_coderef( bless sub {}, $class );

=head2 is_blessed_globref($ref)

Check for a blessed glob reference.

    is_blessed_globref( bless \*STDIN, $class );

=head2 is_blessed_formatref($ref)

Check for a blessed format reference.

    # set up format for FH
    format FH =
    .

    # now we can test it
    is_blessed_formatref(bless *FH{'FORMAT'}, $class );

=head2 is_blessed_refref($ref)

Check for a blessed reference to a reference.

    is_blessed_refref( bless \[], $class ); # reference to array reference

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

=item * Aaron Crane

=back
