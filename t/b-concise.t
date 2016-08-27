use strict;
use warnings;
use Test::More;
use Ref::Util 'is_arrayref';
use B::Concise qw<compile walk_output>;

plan skip_all => 'nothing to do when no custom ops'
    if !Ref::Util::_using_custom_ops();

plan tests => 2;

sub func { is_arrayref([]) }

my $walker = compile('-exec', 'func', \&func);
walk_output(\ my $buf);
eval { $walker->() };
my $exn = $@;

ok(!$exn, 'deparsing ops succeeded');
like($buf, qr/\b is_arrayref \b/x, 'deparsing found the custom op');
