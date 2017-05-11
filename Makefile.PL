use strict;
use warnings;

use lib 'inc';
use ExtUtils::MakeMaker::Dist::Zilla::Develop;

WriteMakefile(
    NAME => 'Ref::Util',
    VERSION_FROM => 'lib/Ref/Util.pm',
    INSTALLMAN1DIR => 'none',
    INSTALLMAN3DIR => 'none',
    NORECURS => 1,
);

use Devel::PPPort;
Devel::PPPort::WriteFile();
