package XAS::Rexec::Controller;

our $VERSION = '0.01';

use POE;
use DateTime;
use XAS::Rexec::Process;
use POE::Component::Cron;
use XAS::Lib::POE::PubSub;

use XAS::Model::Database
  schema => 'XAS::Model::Database::Rexec',
  tables => ':all'
;

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Lib::POE::Service',
  mixin      => 'XAS::Lib::Mixins::Handlers XAS::Rexec::Common',
  utils      => 'dt2db :env',
  accessors  => 'cron events schema',
  constants  => 'HASHREF :process',
  filesystem => 'Dir File',
  vars => {
    PARAMS => {
      -service  => 1,
      -schema   => 1,
      -retires  => { optional => 1, default => 5 },
      -tasks    => { optional => 1, default => 1 },
      -schedule => { optional => 1, default => '*/1 * * * *' },
    }
  }
;

#use Data::Dumper;

# note to self - job status
#
# U - unknown
# Q - queued
# R - running
# C - completed
# P - paused
# A - aborted - stop/kill
#

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    # private events

    $poe_kernel->state('scheduler', $self, '_scheduler');

    # broadcast events - channel 'rexec'

    $poe_kernel->state('job_paused',    $self);
    $poe_kernel->state('job_aborted',   $self);
    $poe_kernel->state('job_resumed',   $self);
    $poe_kernel->state('job_started',   $self);
    $poe_kernel->state('job_completed', $self);

    # service events - from micro service frontend

    $poe_kernel->state('kill_job',   $self);
    $poe_kernel->state('stop_job',   $self);
    $poe_kernel->state('start_job',  $self);
    $poe_kernel->state('resume_job', $self);
    $poe_kernel->state('pause_job',  $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;
    my $schema = $self->schema;
    my $schedule = $self->schedule;

    my $criteria = {
        status => [
            [ '=', 'R' ],
            [ '=', 'P' ],
        ]
    };

    $self->log->debug("$alias: entering session_startup()");

    $self->{'cron'} = POE::Component::Cron->from_cron(
        $schedule, $alias, 'scheduler'
    );

    # clear jobs with indeterminate states

    if (my $jobs = Jobs->search($schema, $criteria)) {

        while (my $job = $jobs->next) {

            my $jobid = $self->build_id($job->id);

            unless ($poe_kernel->alias_resolve($jobid)) {

                $schema->txn_do(sub {

                    $job->status('A');
                    $job->update;

                });

            }

        }

    }

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause()");

    $poe_kernel->alarm_remove_all();

    if (my $cron = $self->cron) {

        $cron->delete();

    }

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: entering session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;
    my $schedule = $self->schedule;

    $self->log->debug("$alias: entering session_resume()");

    $self->{'cron'} = POE::Component::Cron->from_cron(
        $schedule, $alias, 'scheduler'
    );

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: entering session_resume()");

}

sub session_stop {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_stop()");

    $poe_kernel->alarm_remove_all();

    if (my $cron = $self->cron) {

        $cron->delete();

    }

    # walk the chain

    $self->SUPER::session_stop();

    $self->log->debug("$alias: leaving session_stop()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_shutdown()");

    $poe_kernel->alarm_remove_all();

    if (my $cron = $self->cron) {

        $cron->delete();

    }

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown()");

}

# ---------------------------------------------------------------------
# Channel Events
# ---------------------------------------------------------------------

sub job_completed {
    my ($self, $args) = @_[OBJECT,ARG0];

    my $jobid     = $args->{'jobid'};
    my $exit_code = $args->{'exit_code'};

    my $alias  = $self->alias;
    my $schema = $self->schema;
    my $now    = DateTime->now(time_zone => 'UTC');
    my $dt     = dt2db($now);

    $self->log->debug("$alias: entering job_completed");

    my $key = {
        id => $self->get_id($jobid)
    };

    if (my $job = Jobs->find($schema, $key)) {

        $schema->txn_do(sub {

            $job->status('C');
            $job->completion_time($dt);
            $job->exit_code($exit_code);

            $job->update;

        });

    }

    $self->service->unregister($jobid);
    $poe_kernel->call($jobid, 'session_shutdown');

    $self->{'running'} -= 1;
    $self->{'running'} = 0 if ($self->{'running'} < 0);

    $self->log->debug("$alias: leaving job_completed");

}

sub job_started {
    my ($self, $args) = @_[OBJECT,ARG0];

    my $jobid  = $args->{'jobid'};
    my $alias  = $self->alias;
    my $schema = $self->schema;
    my $now    = DateTime->now(time_zone => 'UTC');
    my $wanted = dt2db($now);

    my $key = {
        id => $self->get_id($jobid)
    };

    $self->log->debug("$alias: entering job_started");

    if (my $job = Jobs->find($schema, $key)) {

        $schema->txn_do(sub {

            $job->start_time($wanted);
            $job->status('R');
            $job->update;

        });

    }

    $self->log->debug("$alias: leaving job_started");

}

sub job_aborted {
    my ($self, $args) = @_[OBJECT,ARG0];

    my $jobid  = $args->{'jobid'};
    my $alias  = $self->alias;
    my $schema = $self->schema;
    my $now    = DateTime->now(time_zone => 'UTC');
    my $wanted = dt2db($now);

    my $key = {
        id => $self->get_id($jobid)
    };

    $self->log->debug("$alias: entering job_aborted");

    if (my $job = Jobs->find($schema, $key)) {

        $schema->txn_do(sub {

            $job->completion_time($wanted);
            $job->status('A');
            $job->update;

        });

    }

    $self->log->debug("$alias: leaving job_aborted");

}

sub job_paused {
    my ($self, $args) = @_[OBJECT,ARG0];

    my $jobid  = $args->{'jobid'};
    my $alias  = $self->alias;
    my $schema = $self->schema;

    my $key = {
        id => $self->get_id($jobid)
    };

    $self->log->debug("$alias: entering job_paused");

    if (my $job = Jobs->find($schema, $key)) {

        $schema->txn_do(sub {

            $job->status('P');
            $job->update;

        });

    }

    $self->log->debug("$alias: leaving job_paused");

}

sub job_resumed {
    my ($self, $args) = @_[OBJECT,ARG0];

    my $jobid  = $args->{'jobid'};
    my $alias  = $self->alias;
    my $schema = $self->schema;

    my $key = {
        id => $self->get_id($jobid)
    };

    $self->log->debug("$alias: entering job_resumed");

    if (my $job = Jobs->find($schema, $key)) {

        $schema->txn_do(sub {

            $job->status('R');
            $job->update;

        });

    }

    $self->log->debug("$alias: leaving job_resumed");

}

# ---------------------------------------------------------------------
# Service Events
# ---------------------------------------------------------------------

sub start_job {
    my ($self, $jobid) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->info_msg('rexec_action', $alias, 'start', $jobid);

    if ($poe_kernel->alias_resolve($jobid)) {

        $poe_kernel->post($jobid, 'start_process');

    } else {

        if (my $job = $self->find_job($jobid)) {

            $self->_create_job($job);

        }

    }

}

sub stop_job {
    my ($self, $jobid) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->info_msg('rexec_action', $alias, 'stop', $jobid);

    if ($poe_kernel->alias_resolve($jobid)) {

        $poe_kernel->post($jobid, 'stop_process');

    }

}

sub kill_job {
    my ($self, $jobid) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->info_msg('rexec_action', $alias, 'kill', $jobid);

    if ($poe_kernel->alias_resolve($jobid)) {

        $poe_kernel->post($jobid, 'kill_process');

    }

}

sub pause_job {
    my ($self, $jobid) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->info_msg('rexec_action', $alias, 'pause', $jobid);

    if ($poe_kernel->alias_resolve($jobid)) {

        $poe_kernel->post($jobid, 'pause_process');

    }

}

sub resume_job {
    my ($self, $jobid) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->info_msg('rexec_action', $alias, 'resume', $jobid);

    if ($poe_kernel->alias_resolve($jobid)) {

        $poe_kernel->post($jobid, 'resume_process');

    }

}

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

sub _scheduler {
    my $self = $_[OBJECT];

    my $alias  = $self->alias;
    my $schema = $self->schema;
    my $now    = DateTime->now(time_zone => 'UTC');

    my $criteria = {
        status => { '=', 'Q' },
    };

    $self->log->debug("$alias: entering scheduler");

    if (my $jobs = Jobs->search($schema, $criteria)) {

        while (my $job = $jobs->next) {

            if ($job->start_time <= $now) {

                $self->_create_job($job);

            }

        }

    }

    $self->log->debug("$alias: leaving scheduler");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'running'} = 0;
    $self->{'events'}  = XAS::Lib::POE::PubSub->new();

    $self->events->subscribe($self->alias, 'rexec');

    return $self;

}

sub _create_job {
    my $self = shift;
    my $job  = shift;

    my $args;
    my $alias = $self->alias;
    my $jobid = $self->build_id($job->id);
    my $log   = $self->build_log($jobid);
    my $env   = env_parse($job->environment);

    $self->log->info_msg('rexec_starting', $alias, $jobid);

    if ($self->{'running'} <= $self->tasks) {

        my $process = XAS::Rexec::Process->new(
            -alias        => $jobid,
            -auto_start   => 1,
            -auto_restart => 0,
            -pty          => 1,
            -command      => $job->command,
            -environment  => $env,
            -umask        => $job->umask,
            -group        => $job->xgroup,
            -user         => $job->user,
            -directory    => Dir($job->directory),
            -redirect     => 1,
            -output_handler => sub {
                my $line = shift;
                $line = sprintf("%s\n", $line);
                $log->append($line);
            }
        );

        $args = {
            jobid => $jobid,
        };

        $self->service->register($jobid);
        $poe_kernel->call($alias, 'job_started', $args);

        $self->{'running'} += 1;

    } else {

        $self->log->warn_msg('rexec_toomany', $alias, $jobid);

    }

}

1;

__END__

=head1 NAME

XAS::Rexec::Controller - Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Rexec::Controler;

 my $controller = XAS::Rexec::Controller->new(
     -alias    => 'controller',
     -schema   => $schema,
     -service  => $self->service,
     -tasks    => $self->cfg->val('system', 'tasks', 1),
 );

 $self->service->register('controller');

=head1 DESCRIPTION

This module is the inter process controller between the micro service front end
and the background jobs that are currently processing. It also maintains the
database that records all of the job processing.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service> and
takes these additional parameters:

=over 4

=item B<-service>

The handle to the service. This allows the background jobs to interact with
the service controller.

=item B<-schema>

The handle to the database schema.

=item B<-tasks>

The number of concurrent tasks that can be running. Defaults to 1.

=item B<-schedule>

The schedule for the internal scheduler. Defaults to  '*/1 * * * *'.

=back

=head2 session_initialize

This method defines all the events that will be used.

=head2 session_startup

This method clears any jobs that may in an indeterminate state when the module
starts up. It also starts the internal scheduler.

=head2 session_pause

This method stops the internal scheduler.

=head2 session_resume

This method starts the internal scheduler.

=head2 session_stop

This method stops the internal scheduler.

=head2 session_shutdown

This method stops the internal scheduler.

=head2

=head1 CHANNEL EVENTS

These events are generated by the process controller. They are issued when
the status of a job has changed. They are broadcast over the rexec channel.
Each of the events is passed a hash structure. This will have a 'jobid' field
used to hold the job id of processing job. When a job finishes,
this structure will have an 'exit_code' field, that holds the exit code from
the completed job. Please see L<XAS::Lib::POE::PubSub|XAS::Lib::POE::PubSub> for the
details on argument passing.

=head2 job_started

This event is issued when a job has started. It changes the jobs
status to 'R' in the database.

=head2 job_completed

This event is issued when a job has completed. It changes the jobs
status to 'C' and updates the exit code of the job in the database.

=head2 job_aborted

This event is issued when a job was aborted. It changes the jobs
status to 'A' in the database.

=head2 job_paused

This event is issued when a job was paused. It changes the jobs
status to 'P' in the database.

=head2 job_resumed

This event is issued when a job was resumed. It changes the jobs
status to 'R' in the database.

=head1 SERVICE EVENTS

These events are generated by the micro service front end. They are used to
control running jobs. Each of these events are also passed the job id. This
is used to control individual jogs.

=head2 start_job($jobid)

This event will start the indicated job.

=head2 stop_job($jobid)

This event will stop the indicated job.

=head2 pause_job($jobid)

This event will pause the indicated job.

=head2 resume_job($jobid)

This event will resume the indicated job.

=head2 kill_job($jobid)

This event will kill the indicated job.

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
