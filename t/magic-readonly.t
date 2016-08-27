use strict;
use warnings;
use Test::More 'tests' => 3;
use Ref::Util qw<is_hashref is_plain_hashref is_blessed_hashref>;
use Readonly;

Readonly::Scalar my $rh2 => { a => { b => 2 } };

ok( is_hashref($rh2), 'Readonly objects work!' );
ok( is_plain_hashref($rh2), 'They are not plain!' );
ok( !is_blessed_hashref($rh2), 'They are blessed!' );
