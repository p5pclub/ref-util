use strict;
use warnings;
use Test::More;

BEGIN {
    # this is actually enabled, but if merged into t/ it should be disabled
    plan skip_all => 'Rewrite tests is disabled by default' unless 1;
    plan tests => 2 + 7;

    use_ok('Ref::Util::Rewriter');
}

can_ok( Ref::Util::Rewriter::, qw<rewrite rewrite_string rewrite_file> );

my @tests = (
    q{ref $foo eq 'ARRAY';}        => q{is_arrayref($foo);},
    q{ref($foo) eq 'ARRAY';}       => q{is_arrayref($foo);},
    q{ref  ($foo) eq 'ARRAY';}     => q{is_arrayref($foo);},
    q{ref($foo) or}                => q{is_ref($foo) or},
    q!if (ref($foo) eq 'ARRAY') {! => q!if (is_arrayref($foo)) {!,
    q{ref($foo) eq 'ARRAY' or}     => q{is_arrayref($foo) or},
    qq{ref(\$foo) # comment\nor}   => q{is_ref($foo) or # comment},
);

while ( my ( $input, $output ) = splice @tests, 0, 2 ) {
    my $test_name = $input;
    is(
        Ref::Util::Rewriter::rewrite_string($input),
        $output,
        $test_name,
    );
}
