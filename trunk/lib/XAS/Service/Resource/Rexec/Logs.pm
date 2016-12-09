package XAS::Service::Resource::Rexec::Logs;

use strict;
use warnings;

use POE;
use DateTime;
use XAS::Utils 'trim';
use XAS::Rexec::Common;
use parent 'XAS::Service::Resource';
use Web::Machine::Util qw( bind_path );

XAS::Rexec::Common->mixin(__PACKAGE__); # load the mixins

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# -------------------------------------------------------------------------

sub malformed_request {
    my $self = shift;

    my $stat   = 0;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug("$alias: malformed_request");

    if (my $id = bind_path('/:id', $path)) {

        if ($method eq 'GET') {

            $stat = $self->check_id($id);

        }

    }

    return $stat;

}

sub resource_exists {
    my $self = shift;

    my $stat   = 0;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug("$alias: resource_exists");

    if ($method eq 'GET') {

        $stat = 1;

        if (my $id = bind_path('/:id', $path)) {

            my $log = $self->build_log($id);

            $stat = $log->exists;

        }

    }

    return $stat;

}

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
        parent => {
            title => 'Remote Execution',
            href  => '/rexec',
        },
        self => {
            title => 'Logs',
            href  => '/rexec/logs',
        },
    };

}

sub get_response {
    my $self = shift;

    my $id;
    my $log;
    my $data;
    my $alias  = $self->alias;
    my $method = $self->request->method;
    my $path   = $self->request->path_info;

    $self->log->debug("$alias: get_response");

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    if ($id = bind_path('/:id', $path)) {

        my $rec = $self->get_log($id);

        $data->{'_embedded'}->{'log'} = $rec;

    } else {

        my $logs = $self->log_files();

        foreach my $log (@$logs) {

            my $info = $self->build_link($log);

            push(@{$data->{'_embedded'}->{'logs'}}, $info);

        }

    }

    return $data;

}

sub build_link {
    my $self = shift;
    my $log = shift;

    my $data;
    my @stat = $log->stat;
    my $name = $log->basename;
    my $path = "/rexec/logs/$name";
    my $dt   = DateTime->from_epoch(epoch => $stat[9], time_zone => 'local');

    $data->{'_links'}->{'self'} = {
        href  => "/rexec/logs/$name",
        title => $name
    };

    $data->{'jobid'} = $name;
    $data->{'size'}  = $stat[7];
    $data->{'mtime'} = sprintf('%s %s', $dt->ymd('-'), $dt->hms);

    return $data;

}

sub get_log {
    my $self = shift;
    my $id   = shift;

    my $data;
    my $log = $self->build_log($id);

    $data->{'jobid'} = $id;
    $data->{'_links'}->{'self'} = {
        href  => "/rexec/logs/$id",
        title => $id
    };

    if (my $fh = $log->open('<')) {

        while (my $line = $fh->getline) {

            $line = trim($line);
            push(@{$data->{'lines'}}, $line);

        }

        $fh->close;

    } else {

        push(@{$data->{'lines'}}, 'no content available');

    }

    return $data;

}

1;

__END__

=head1 NAME

XAS::Service::Resource::Rexec::Logs - Perl extension for the XAS environment

=head1 SYNOPSIS

    my $builder = Plack::Builder->new();

    $builder->mount('/rexec/logs' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Rexec::Logs',
        resource_args => [
            alias           => 'logs',
            json            => $json,
            template        => $template,
            schema          => $schema,
            app_name        => $name,
            controler       -> $controller,
            app_description => $description
        ] )->to_app
    );

=head1 DESCRIPTION

This module inherits from L<XAS::Service::Resource|XAS::Service::Resource>. It
provides a link to "/rexec/logs" and the services it provides.

Logs are associated with jobs. Not all jobs will create a log. Logs are
deleted when jobs are deleted.

=head1 METHODS - Web::Machine

Web::Machine provides callbacks for processing the request. These have been
overridden.

=head2 allowed_methods

This returns the allowed methods for the handler. The defaults are
OPTIONS GET HEAD.

=head2 malformed_request

This method checks the request url for proper format.

=head2 resource_exists

This method checks to see if the job exists within the database.

=head1 METHODS - Ours

These methods are used to make writting services easier.

=head2 build_link

This method creates the data structure for a log. This will later be translated
into html or json.

=head1 SEE ALSO

=over 4

=item L<XAS::Service::Resource|XAS::Service::Resource>

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
