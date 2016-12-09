package XAS::Service::Resource::Rexec::Root;

use strict;
use warnings;

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
        text => 'Remote Execution'
    }];

}

sub get_links {
    my $self = shift;

    return {
        self => {
            title => 'Root',
            href  => '/',
        },
        children => [{
            title => 'Remote Execution',
            href  => '/rexec',
        }],
    };

}

sub get_response {
    my $self = shift;

    return {
        '_links'     => $self->get_links(),
        'navigation' => $self->get_navigation()
    };

}

1;

__END__

=head1 NAME

XAS::Service::Resource::Rexec::Root - Perl extension for the XAS environment

=head1 SYNOPSIS

 my $builder = Plack::Builder->new();

 $builder->mount('/' => Service::Machine->new(
     resource => 'XAS::Service::Resource::Rexec::Root',
     resource_args => [
         alias           => 'root',
         template        => $template,
         json            => $json,
         app_name        => $name,
         app_description => $description
     ] )->to_app
 );

=head1 DESCRIPTION

This module inherits from L<XAS::Service::Resource|XAS::Service::Resource>. It
provides a link to "/" and the services it provides.

=head1 METHODS - Web::Machine

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
