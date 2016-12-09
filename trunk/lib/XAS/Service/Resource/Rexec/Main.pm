package XAS::Service::Resource::Rexec::Main;

use strict;
use warnings;

use Data::Dumper;
use parent 'XAS::Service::Resource';

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# methods
# -------------------------------------------------------------------------

sub get_navigation {
    my $self = shift;

    return [{
        link => '/',
        text => 'Root',
    },{
        link => '/rexec',
        text => 'Remote Execution',
    }];

}

sub get_links {
    my $self = shift;

    return {
        parent => {
            title => 'Root',
            href  => '/',
        },
        self => {
            title => 'Remote Execution',
            href  => '/rexec',
        },
        children => [{
            title => 'Jobs',
            href  => '/rexec/jobs',
        },{
            title => 'Logs',
            href  => '/rexec/logs',
        }]
    };

}

sub get_response {
    my $self = shift;

    return {
        '_links'     => $self->get_links(),
        'navigation' => $self->get_navigation(),
    };

}

1;

__END__

=head1 NAME

XAS::Service::Resource::Rexec - Perl extension for the XAS environment

=head1 SYNOPSIS

 my $builder = Plack::Builder->new();

 $builder->mount('/rexec' => Service::Machine->new(
     resource => 'XAS::Service::Resource::Rexec::Main',
     resource_args => [
         alias           => 'rexec',
         template        => $template,
         json            => $json,
         app_name        => $name,
         app_description => $description
     ] )->to_app
 );

=head1 DESCRIPTION

This module inherits from L<XAS::Service::Resource|XAS::Service::Resource>. It
provides a link to "/rexec" and the services it provides.

=head1 METHODS - Service::Machine

No overrides needed.

=head1 METHODS - Ours

Overrides default methods from L<XAS::Service::Resource|XAS::Service::Resource>.

=head1 SEE ALSO

=over 4

=item L<XAS::Service::Resource|XAS::Service::Resource>

=item L<XAS::Service|XAS::Service>

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
