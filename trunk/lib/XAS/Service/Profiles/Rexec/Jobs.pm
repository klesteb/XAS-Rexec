package XAS::Service::Profiles::Rexec::Jobs;

our $VERSION = '0.01';

use XAS::Utils ':validation';
use Data::FormValidator::Constraints::MethodsFactory ':set';

#use Data::Dumper;

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------

sub new {
    my $class = shift;

    my $jobs = {
        filters  => ['trim'],
        required => ['action'],
        optional => ['environment', 'cancel'],
        field_filters => {
            action => ['lc']
        },
        defaults => {
            priority => '0',
        },
        dependencies => {
            action => {
                post => ['username', 'command', 'umask', 'group', 'user', 'priority', 'directory'],
            }
        },
        constraint_methods => {
            username    => qr/^\w+$/,
            command     => qr/.*/,
            umask       => qr/^\d+/,
            group       => qr/^\w+/,
            user        => qr/^\w+/,
            directory   => qr/.*/,
            environment => qr/^\w+=\w+;;/,
            cancel      => qr/cancel/,
            action      => FV_set(1, qw( post start resume pause stop kill )),
        },
        msgs => {
            format => '%s',
            constraints => {
                username    => 'should be alphanumeric characters',
                command     => 'should be a valid command',
                umask       => 'should numeric characters',
                group       => 'should be numeric characters',
                user        => 'should be alphanumeric characters',
                directory   => 'should be a valid directory path',
                environment => 'must be: name=value;;',
                action      => 'must be one of these: post start resume pause stop kill',
                cancel      => 'should be "cancel"',
            }
        }
    };

    my $profiles = {
        jobs => $jobs,
    };

    return $profiles;

}

1;

=head1 NAME

XAS::Service::Profiles::Jobs - A class for creating standard validation profiles.

=head1 SYNOPSIS

 my $jobs     = XAS::Service::Profiles::Rexec::Jobs->new();
 my $validate = XAS::Service::Profiles->new($jobs);

=head1 DESCRIPTION

This module creates a standardized
L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator> validation
profile for searches.

=head1 METHODS

=head2 new($fields)

Initializes the vaildation profile.

=over 4

=item B<$field>

An array ref of field names that may appear in search requests.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Service|XAS::Service>

=item L<XAS::Rexec|XAS::Rexec>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
