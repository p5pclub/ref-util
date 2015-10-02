use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Ref::Util',
    VERSION_FROM   => 'lib/Ref/Util.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57' },
    ABSTRACT_FROM  => 'lib/Ref/Util.pm',
    AUTHOR         => 'Sawyer X <xsawyerx@cpan.org>',
    LIBS           => [''],
    DEFINE         => '',
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
);

