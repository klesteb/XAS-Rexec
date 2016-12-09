package XAS::Service::Validate::Rexec::Jobs;

our $VERSION = '0.01';

use XAS::Service::Profiles;
use XAS::Service::Profiles::Rexec::Jobs;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Service::CheckParameters',
  accessors => 'profile',
  utils     => ':validation',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub check {
    my $self = shift;
    my ($multi) = validate_params(\@_, [
        { isa => 'Hash::MultiValue' },
    ]);

    my $params = $multi->as_hashref;

    return $self->check_parameters($params, 'jobs');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $jobs = XAS::Service::Profiles::Rexec::Jobs->new();

    $self->{'profile'} = XAS::Service::Profiles->new($jobs);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Service::Validate::Rexec::Jobs - A class to verify the Jobs profile.

=head1 SYNOPSIS

 use XAS::Service::Validate::Rexec::Jobs;

 my $jobs = XAS::Service::Validate::Rexec::Jobs->new();

 if (my $valids = $jobs->check($params)) {

 }

=head1 DESCRIPTION


=head1 METHODS

=head2 new

This method initializes the module.

=head2 check($params)

This method will verify that the parameters is consitent with the Jobs profile.

=over 4

=item B<$params>

The parameters to verify against the profile.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Service|XAS::Service>

=item L<XAS::Rexec|XAS::Rexec>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
