package XAS::Apps::Rexec::Service;

our $VERSION = '0.01';

use Template;
use JSON::XS;
use Web::Machine;
use Plack::Builder;
use Authen::Simple;
use Plack::App::File;
use Plack::App::URLMap;
use XAS::Model::Schema;
use Authen::Simple::PAM;
use XAS::Service::Server;
use XAS::Rexec::Controller;
use XAS::Service::Resource::Rexec::Root;
use XAS::Service::Resource::Rexec::Main;
use XAS::Service::Resource::Rexec::Jobs;
use XAS::Service::Resource::Rexec::Logs;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App::Service',
  mixin      => 'XAS::Lib::Mixins::Configs',
  filesystem => 'File Dir',
  accessors  => 'cfg',
  vars => {
    SERVICE_NAME         => 'XAS_Rexecd',
    SERVICE_DISPLAY_NAME => 'XAS Remote Execution',
    SERVICE_DESCRIPTION  => 'This process allows for the remote execution of commands'
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub build_app {
    my $self   = shift;
    my $schema = shift;

    # define base, name and description

    my $path = $self->env->lib . '/web/';
    my $root = $self->cfg->val('app', 'root', $path);
    my $base = $self->cfg->val('app', 'base', '/home/kevin/dev/XAS-Rexec/trunk/web/');
    my $name = $self->cfg->val('app', 'name', 'WEB Services');
    my $description = $self->cfg->val('app', 'description', 'Test api using RESTFUL HAL-JSON');

    my @paths = [
        Dir($base, 'root/rexec/')->path,
        Dir($root, 'root/')->path,
    ];
    
    # Template config

    my $config = {
        INCLUDE_PATH => \@paths,   # or list ref
        INTERPOLATE  => 1,         # expand "$var" in plain text
    };

    # create various objects

    my $template = Template->new($config);
    my $json     = JSON::XS->new->utf8();
    my $authen   = Authen::Simple->new(
        Authen::Simple::PAM->new(
            service => 'login'
        )
    );

    # allow variables with preceeding _

    $Template::Stash::PRIVATE = undef;

    # handlers, using URLMap for routing

    my $builder = Plack::Builder->new();
    my $urlmap  = Plack::App::URLMap->new();

    $urlmap->mount('/' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Rexec::Root',
        resource_args => [
            alias           => 'root',
            template        => $template,
            json            => $json,
            app_name        => $name,
            app_description => $description,
            authenticator   => $authen,
        ] )->to_app
    );

    $urlmap->mount('/rexec' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Rexec::Main',
        resource_args => [
            alias           => 'rexec',
            template        => $template,
            json            => $json,
            app_name        => $name,
            app_description => $description,
            authenticator   => $authen,
        ] )->to_app
    );

    $urlmap->mount('/rexec/jobs' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Rexec::Jobs',
        resource_args => [
            alias           => 'jobs',
            controller      => 'controller',
            template        => $template,
            json            => $json,
            schema          => $schema,
            app_name        => $name,
            app_description => $description,
            authenticator   => $authen,
        ] )->to_app
    );

    $urlmap->mount('/rexec/logs' => Web::Machine->new(
        resource => 'XAS::Service::Resource::Rexec::Logs',
        resource_args => [
            alias           => 'logs',
            template        => $template,
            json            => $json,
            app_name        => $name,
            app_description => $description,
            authenticator   => $authen,
        ] )->to_app
    );

    # static files

    $urlmap->mount('/js' => Plack::App::File->new(
            root => Dir($root, '/root/js')->path 
        )->to_app
    );

    $urlmap->mount('/css' => Plack::App::File->new(
            root => Dir($root, '/root/css')->path 
        )->to_app
    );

    $urlmap->mount('/yaml' => Plack::App::File->new(
            root => Dir($root, '/root/yaml/yaml')->path
        )->to_app
    );

    return $builder->to_app($urlmap->to_app);

}

sub setup {
    my $self = shift;

    my $database = $self->cfg->val('database', 'name', 'rexecd');
    my $schema = XAS::Model::Schema->opendb($database);

    my $controller = XAS::Rexec::Controller->new(
        -alias    => 'controller',
        -schema   => $schema,
        -service  => $self->service,
        -tasks    => $self->cfg->val('system', 'tasks', 1),
    );

    my $interface = XAS::Service::Server->new(
        -alias   => 'interface',
        -port    => $self->cfg->val('system', 'port', 9507),
        -address => $self->cfg->val('system', 'address', 'localhost'),
        -app     => $self->build_app($schema),
    );

    $self->service->register('controller,interface');

}

sub main {
    my $self = shift;

    $self->log->info_msg('startup');

    $self->setup();
    $self->service->run();

    $self->log->info_msg('shutdown');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->load_config();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Apps::Rexec::Service - This module provides a micro service for remote job execution

=head1 SYNOPSIS

 use XAS::Apps::Rexec::Service;

 my $app = XAS::Apps::Rexec::Service->new();

 exit $app->run();

=head1 DESCRIPTION

This module module provides a micro service for remote job execution. It
exposes a REST api that allow a remote process to run a command on the local
system. All state for the command is stored in a local database. This may
be queried by the api.

=head1 CONFIGURATION

The configuration file follows the familiar Windows .ini format. It contains
followign stanzas.

 [system]
 port = 9507
 address = 127.0.0.1

This stanza defines the network interface. By default the process listens on
port 9507 on the 127.0.0.1 network.

 [database]
 name = rexecd

This stanza defines what database to use for state information. This
database must be defined in etc/database.ini.

 [app]
 base = /var/lib/wpm/web
 name = My Great service
 description = This is a really great service

This stanza defines where the root directory for html assets are stored and
the name and description of the micro service.

=head1 EXAMPLE

 [system]
 port = 9507
 address = 127.0.0.1

 [database]
 name = rexecd

 [app]
 base = /var/lib/wpm/web
 name = Rexecd Micro Service
 description = a micro service for remote job execution

=head1 SEE ALSO

=over 4

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
