use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Ref::Util') }

my %tests = (
    is_scalarref => \1,
    is_arrayref  => [],
    is_hashref   => {},
    is_coderef   => sub {1},
    is_regexpref => qr//,
    is_globref   => *STDIN,
    # formatref is unique
    is_ioref     => *STDOUT{IO},
);

# functions available
can_ok( Ref::Util::, keys %tests );
ok( ! main->can($_), "No $_ available yet" ) for keys %tests;

# importing
Ref::Util->import( keys %tests );
can_ok( main::, keys %tests );

foreach my $func ( keys %tests ) {
    my $cb  = Ref::Util->can($func);
    my $arg = $tests{$func};
    $cb->( [] );
    is( $cb->($arg), 1, "$func($arg)" );

    eval { $cb->(); 1; } 
    or do { like( $@ || 'Zombie error', qr/$func\(ref\)/, "$func()" ); };
    
    eval { $cb->(undef); 1; } 
    or do {
        like( $@ || 'Zombie error', qr/$func\(ref\)/, "$func(undef)" );
    };
}

# add test for FORMAT

done_testing;
