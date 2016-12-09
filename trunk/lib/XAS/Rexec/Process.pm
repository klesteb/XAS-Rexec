package XAS::Rexec::Process;

our $VERSION = '0.01';

use POE;
use XAS::Lib::POE::PubSub;
use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Process',
  accessors => 'events',
  constants => ':process',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('start_process',  $self, '_start_process');
    $poe_kernel->state('stop_process',   $self, '_stop_process');
    $poe_kernel->state('pause_process',  $self, '_pause_process');
    $poe_kernel->state('resume_process', $self, '_resume_process');
    $poe_kernel->state('kill_process',   $self, '_kill_process');
    $poe_kernel->state('check_status',   $self, '_check_status');

    # walk the chain

    $self->SUPER::session_initialize();

    $poe_kernel->post($alias, 'session_startup');

    $self->log->debug("$alias: leaving session_initialize()");

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _start_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    if ($self->status == PROC_STOPPED) {

        $self->start_process();
        $poe_kernel->post($alias, 'check_status', $count);

    }

}

sub _resume_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    $self->resume_process();
    $poe_kernel->post($alias, 'check_status', $count);

}

sub _pause_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    $self->pause_process();
    $poe_kernel->post($alias, 'check_status', $count);

}

sub _stop_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    $self->stop_process();
    $poe_kernel->post($alias, 'check_status', $count);

}

sub _kill_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    $self->kill_process();
    $poe_kernel->post($alias, 'check_status', $count);

}

sub _check_status {
    my ($self, $count) = @_[OBJECT, ARG0];

    my $alias = $self->alias;
    my $stat  = $self->stat_process();

    $count++;

    $self->log->debug(sprintf('%s: check_status -  code: %s, count: %s', $alias, $stat, $count));

    if ($self->status == PROC_STARTED) {

        if (($stat == 3) || ($stat == 2)) {

            $self->status(PROC_RUNNING);

            $self->events->publish(
                -event   => 'job_started',
                -channel => 'rexec',
                -args => {
                    jobid => $alias,
                }
            );

        }

    } elsif ($self->status == PROC_RUNNING) {

        if (($stat != 3) || ($stat != 2)) {

            $self->resume_process();
            $poe_kernel->delay('check_status', 5, $count);

        } else {

            $self->events->publish(
                -event   => 'job_resumed',
                -channel => 'rexec',
                -args => {
                    jobid => $alias,
                }
            );

        }

    } elsif ($self->status == PROC_PAUSED) {

        if ($stat != 6) {

            $self->pause_process();
            $poe_kernel->delay('check_status', 5, $count);

        } else {

            $self->events->publish(
                -event   => 'job_paused',
                -channel => 'rexec',
                -args => {
                    jobid => $alias,
                }
            );

        }

    } elsif ($self->status == PROC_STOPPED) {

        if ($stat != 0) {

            $self->stop_process();
            $poe_kernel->delay('check_status', 5, $count);

        } else {

            $self->events->publish(
                -event   => 'job_aborted',
                -channel => 'rexec',
                -args => {
                    jobid => $alias,
                }
            );

        }

    } elsif ($self->status == PROC_KILLED) {

        if ($stat != 0) {

            $self->kill_process();
            $poe_kernel->delay('check_status', 5, $count);

        } else {

            $self->events->publish(
                -event   => 'job_aborted',
                -channel => 'rexec',
                -args => {
                    jobid => $alias,
                }
            );

        }

    }

}

sub _child_exit {
    my ($self, $signal, $pid, $exitcode) = @_[OBJECT,ARG0,ARG1,ARG2];

    my $count   = 0;
    my $alias   = $self->alias;
    my $status  = $self->status;
    my $retries = $self->retries;

    $self->{'pid'}         = undef;
    $self->{'exit_code'}   = $exitcode >> 8;
    $self->{'exit_signal'} = $exitcode & 127;

    $self->log->warn_msg('process_exited', $alias, $pid, $self->exit_code);

    if ($status == PROC_STOPPED) {

        $self->events->publish(
            -event   => 'job_completed',
            -channel => 'rexec',
            -args => {
                jobid     => $alias,
                exit_code => $self->exit_code
            }
        );

    }

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'events'} = XAS::Lib::POE::PubSub->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Rexec::Process - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Rexec::Process;

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

=head1 DESCRIPTION

This module inherits from L<XAS::Lib::Process|XAS::Lib::Process> and adds
some events to allow another POE session to control this process. It also
connects to the PubSub bus (L<XAS::Lib::POE::PubSub|XAS::Lib::POE::PubSub>)
to allow status messages to be broadcast.

=head1 PUBLIC EVENTS

The following public events have been added.

=head2 start_process

Allows another session to start a process.

=head2 stop_process

Allows another session to stop a process.

=head2 pause_process

Allows another session to pause a process.

=head2 resume_process

Allows another session to resume a process.

=head2 kill_process

Allows another session to kill a process.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Process|XAS::Lib::Process>

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
