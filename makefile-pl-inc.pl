if (!want_pp() && can_xs()) {
    test_requires('Ref::Util::XS');
    runtime_requires('Ref::Util::XS');
}

if (eval { require Ref::Util } && Ref::Util->VERSION < 0.114) {
  package MY;
  no warnings 'once';

  *install = sub {
    my $self = shift;
    return '
pure_site_install ::
        $(NOECHO) $(RM_F) ' . $self->quote_literal(
      $self->catfile('$(DESTINSTALLSITEARCH)', 'Ref', 'Util.pm')
    ) . "\n" . $self->SUPER::install;
  };
}
