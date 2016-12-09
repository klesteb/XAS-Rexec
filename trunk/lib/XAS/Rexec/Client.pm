package XAS::Rexec::Client;

our $VERSION = '0.01';

use JSON;
use Badger::URL;
use HTTP::Request;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Curl::HTTP',
  utils     => ':validation dotid trim',
  accessors => 'json',
  mutators  => 'status',
  constants => 'ARRAYREF HASHREF',
  vars => {
    PARAMS => {
      -url => { optional => 1, default => 'http://localhost:9507/' },
    },
    JOBS => '/rexec/jobs',
    LOGS => '/rexec/logs',
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub job {
    my $self = shift;
    my ($jobid) = validate_params(\@_, [
      { regexp => qr/\d+\.\w+/ },
    ]);

    my $data;
    my $request;
    my $response;
    my $path = sprintf('%s/%s', $self->class->var('JOBS'), $jobid);

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'job'};

}

sub log {
    my $self = shift;
    my ($job) = validate_params(\@_, [
      { type => HASHREF },
    ]);

    my $data;
    my $request;
    my $response;
    my $path = $job->{'_links'}->{'log'}->{'href'};

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'log'};

}

sub jobs {
    my $self  = shift;
    my $p = validate_params(\@_, {
      -sort   => { optional => 1, type => ARRAYREF, default => undef },
      -group  => { optional => 1, type => ARRAYREF, default => undef },
      -filter => { optional => 1, type => ARRAYREF, default => undef },
      -start => {
          optional => 1,
          regexp   => qr/\d+/,
          depends  => [ '-limit' ],
          default  => undef
      },
      -limit => {
          optional => 1,
          regexp   => qr/\d+/,
          depends  => [ '-start' ],
          default  => undef
      },
    });

    my $data;
    my $request;
    my $response;
    my $path = $self->class->var('JOBS');

    $path    = $self->_build_get($path, $p);
    $request = HTTP::Request->new(GET => $path);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'jobs'};

}

sub logs {
    my $self  = shift;
    my $p = validate_params(\@_, {
      -sort   => { optional => 1, type => ARRAYREF, default => undef },
      -group  => { optional => 1, type => ARRAYREF, default => undef },
      -filter => { optional => 1, type => ARRAYREF, default => undef },
      -start => {
          optional => 1,
          regexp   => qr/\d+/,
          depends  => [ '-limit' ],
          default  => undef
      },
      -limit => {
          optional => 1,
          regexp   => qr/\d+/,
          depends  => [ '-start' ],
          default  => undef
      },
    });

    my $data;
    my $request;
    my $path = $self->class->var('LOGS');

    $path    = $self->_build_get($path, $p);
    $request = HTTP::Request->new(GET => $path);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'logs'};

}

sub submit {
    my $self = shift;
    my $p = validate_params(\@_, {
        -username    => 1,
        -command     => 1,
        -directory   => { optional => 1, default => '/' },
        -priority    => { optional => 1, regexp => qr/\d+/, default => '0' },
        -umask       => { optional => 1, regexp => qr/\d+/, default => '0022' },
        -user        => { optional => 1, regext => qr/\w+/, default => 'xas' },
        -group       => { optional => 1, regexp => qr/\w+/, default => 'xas' },
        -environment => { optional => 1, regexp => qr/\w+=\w+;;/, default => undef },
    });

    $p->{'-action'} = 'post';

    my $data;
    my $params;
    my $request;
    my $path = $self->class->var('JOBS');

    $self->url->path($path);

    $params  = $self->_build_post($p);
    $request = HTTP::Request->new(POST => $self->url->text);

    $request->content($params);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'job'};

}

sub start {
    my $self = shift;
    my ($job) = validate_params(\@_, [
      { type => HASHREF },
    ]);

    my $p->{'-action'} = 'start';

    my $data;
    my $params;
    my $request;
    my $path = $job->{'_links'}->{'start'}->{'href'};

    $self->url->path($path);

    $params  = $self->_build_post($p);
    $request = HTTP::Request->new(POST => $self->url->text);

    $request->content($params);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'job'};

}

sub stop {
    my $self = shift;
    my ($job) = validate_params(\@_, [
      { type => HASHREF },
    ]);

    my $p->{'-action'} = 'stop';

    my $data;
    my $params;
    my $request;
    my $path = $job->{'_links'}->{'stop'}->{'href'};

    $self->url->path($path);

    $params  = $self->_build_post($p);
    $request = HTTP::Request->new(POST => $self->url->text);

    $request->content($params);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'job'};

}

sub pause {
    my $self = shift;
    my ($job) = validate_params(\@_, [
      { type => HASHREF },
    ]);

    my $p->{'-action'} = 'pause';

    my $data;
    my $params;
    my $request;
    my $path = $job->{'_links'}->{'pause'}->{'href'};

    $self->url->path($path);

    $params  = $self->_build_post($p);
    $request = HTTP::Request->new(POST => $self->url->text);

    $request->content($params);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'job'};

}

sub resume {
    my $self = shift;
    my ($job) = validate_params(\@_, [
      { type => HASHREF },
    ]);

    my $p->{'-action'} = 'resume';

    my $data;
    my $params;
    my $request;
    my $path = $job->{'_links'}->{'resume'}->{'href'};

    $self->url->path($path);

    $params  = $self->_build_post($p);
    $request = HTTP::Request->new(POST => $self->url->text);

    $request->content($params);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'job'};

}

sub kill {
    my $self = shift;
    my ($job) = validate_params(\@_, [
      { type => HASHREF },
    ]);

    my $p->{'-action'} = 'kill';

    my $data;
    my $params;
    my $request;
    my $path = $job->{'_links'}->{'kill'}->{'href'};

    $self->url->path($path);

    $params  = $self->_build_post($p);
    $request = HTTP::Request->new(POST => $self->url->text);

    $request->content($params);

    $data = $self->_make_call($request);

    return $data->{'_embedded'}->{'job'};

}

sub delete {
    my $self = shift;
    my ($job) = validate_params(\@_, [
      { type => HASHREF },
    ]);

    my $data;
    my $request;
    my $response;
    my $path = $job->{'_links'}->{'delete'}->{'href'};

    $self->url->path($path);

    $request = HTTP::Request->new(DELETE => $self->url->text);

    $request->header('Accept' => [ 'application/hal+json' ]);

    $response = $self->request($request);

    $self->status($response->code);

    unless ($response->is_success) {

        $data = $self->json->decode($response->content);
        $self->_error_msg($data);

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'url'}  = Badger::URL->new($self->url);
    $self->{'json'} = JSON->new->utf8();

    return $self;

}

sub _build_get {
    my $self = shift;
    my $path = shift;
    my $p    = shift;

    my @params;
    my $count = 0;

    my $sort   = $p->{'-sort'};
    my $group  = $p->{'-group'};
    my $filter = $p->{'-filter'};
    my $start  = $p->{'-start'};
    my $limit  = $p->{'-limit'};

    # internal routines

    my $fix_field = sub {
        my $array = shift;

        my @new;

        foreach my $item (@$array) {

            if ($item->{'field'} eq 'jobid') {

                $item->{'field'} = 'id';

                if (defined($item->{'value'})) {

                    ($item->{'value'}) = $item->{'value'} =~ m/(\d+)\.\w+/;

                }

            }

            push(@new, $item);

        }

        return \@new;

    };

    # main routine

    if (defined($start) && defined($limit)) {

        $params[$count] = sprintf('start=%s&limit=%s', $start, $limit);
        $count += 1;

    }

    if (defined($sort)) {

        my $new = $fix_field->($sort);

        $params[$count] = sprintf('sort=%s', $self->json->encode($new));
        $count += 1;

    }

    if (defined($group)) {

        my $new = $fix_field->($group);

        $params[$count] = sprintf('group=%s', $self->json->encode($new));
        $count += 1;

    }

    if (defined($filter)) {

        my $new = $fix_field->($filter);

        $params[$count] = sprintf('filter=%s', $self->json->encode($new));
        $count += 1;

    }

    if (scalar(@params) > 0) {

        $path .= sprintf('/_search?%s', join('&', @params));

    }

    $self->url->path($path);

    return $self->url->text;

}

sub _build_post {
    my $self = shift;
    my $p    = shift;

    my $params;

    $params->{'action'} = $p->{'-action'};

    if ($params->{'action'} eq 'post' ) {

        $params->{'username'}    = $p->{'-username'};
        $params->{'command'}     = $p->{'-command'};
        $params->{'directory'}   = $p->{'-directory'};
        $params->{'priority'}    = $p->{'-priority'};
        $params->{'umask'}       = $p->{'-umask'};
        $params->{'user'}        = $p->{'-user'};
        $params->{'group'}       = $p->{'-group'};
        $params->{'environment'} = $p->{'-environment'};

    }

    return $self->json->encode($params);

}

sub _make_call {
    my $self = shift;
    my $request = shift;

    my $data;
    my $response;

    $request->header('Accept' => [ 'application/hal+json' ]);
    $request->header('Content-Type' => 'application/vnd.xas.rexec+json;version=1.0');

    $response = $self->request($request);

    $self->status($response->code);

    if ($response->is_success) {

        $data = $self->json->decode($response->content);

    } else {

        $data = $self->json->decode($response->content);
        $self->_error_msg($data);

    }

    return $data;

}

sub _error_msg {
    my $self  = shift;
    my $error = shift;

    my $errors = $error->{'_embedded'}->{'errors'}->[0];
    my @parts  = split('::', (caller(1))[3]);
    my $caller = lc($parts[-1]);

    $self->throw_msg(
        sprintf('%s.%s.server.%s', dotid($self->class), $caller, $errors->{'status'}),
        'server_error',
        $errors->{'title'},
        $errors->{'status'},
        $errors->{'detail'},
        $errors->{'code'},
    );

}

1;

__END__

=head1 NAME

XAS::Rexec::Client - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Rexec::Client;

 my $client = XAS::Rexec::Client->new(
     -username => 'kevin',
     -password => 'secret',
     -url      => 'http://bob:9100/'
 );

 my $result = $client->submit(
     -username => 'kevin',
     -command  => 'test.sh'
 );

 if ($result->{'status'} eq 'Q') {

     $client->start($result);

 }

 do {

     $result = $self->job($result->{'jobid'});

     printf("%s has a status of %s\n", $result->{'jobid'}, $result->{'status'});
     sleep 1;

 } while ($result->{'status'} ne 'C');

=head1 DESCRIPTION

This module provides a programmable interface to the xas-rexecd service. This
allows a program to submit and control jobs within the xas-rexecd service. It
also allows a program to retrieve information about current and past jobs.

=head1 METHODS

=head2 job($jobid)

This method will retrieve a job record. This record will have the following
format:

 $job = {
     '_links' => {
         'self' => {
             'href'  => '/rexec/job/<jobid>,
             'title' => 'View',
          },
      },
      jobid           => <jobid>,
      status          => 'C',
      queued_time     => 'YYYY-MM-DD HH:MM:SS',
      start_time      => 'YYYY-MM-DD HH:MM:SS'
      completion_time => 'YYYY-MM-DD HH:MM:SS',
      exit_code       => '0',
      username        => 'kevin',
      command         => 'sleep 60',
      priority        => '0',
      umask           => '0022',
      xgroup          => 'xas',
      user            => 'xas',
      directory       => '/',
      environment     => 'XAS_REXEC=1;;',
 };

Where the '_links' section may have additional fields depending on the status
of the job. Those fields may be one of the following:

 log    - title 'Log',    and href is the url to retrieve the log from
 start  - title 'Start'   and href is the url to request a start action
 stop   - title 'Stop'    and href is the url to request a stop action
 pause  - title 'Pause',  and href is the url to request a pause action
 resume - title 'Resume', and href is the url to request a resume action
 kill   - title 'Kill'    and href is the url to request a kill action
 delete - title 'Delete'  and href is the url to perform a delete action

The status field may contain one of the following:

 A - job was aborted
 C - job has completed
 P - job has been paused
 Q - job has been queued
 R - job is running
 U - job is in an unknown state

=over 4

=item B<$jobid>

The job id to use when retrieving the record.

=back

=head2 jobs(...)

This method will return an array of jobs. Each memeber of te array will have
the format of the above job record. By default it will return all jobs stored
on the xas-rexecd service. This behavior can be modified with selection
criteria.

=over 4

=item B<-start>

Defines the start of the rows within the xas-rexecd database.

=item B<-limit>

The number of records to return.

=item B<-sort>

Defines how to sort the results. It should be the following data structure:

  $sort = [{
      field     => 'username',
      direction => 'ASC',
  }];

Where 'field' is a field in the database, and 'direction' needs to be either
'ASC' or 'DESC'. More then one "sort" can be defined.

=item B<-group>

Defines how to group the results. It should be the following data structure:

  $group = [{
      field     => 'username',
      direction => 'ASC',
  }];

Where 'field' is a field in the database, and 'direction' needs to be either
'ASC' or 'DESC'. More then one "group" can be defined.

=item B<-filter>

Defines how to filter the results. It should be the following data structure:

 $filter = [{
     field => 'username',
     type  => 'string',
     value => 'kevin'
 }];

Which will return all jobs for username 'kevin'. There is an optional
'comparison' field that allows you to better filter the results. The
'type' field can be one of the following:

 string  - the 'value' field should be a string
 number  - the 'value' field should be a number
 list    - the 'value' field will be a list of values
 boolean - the 'value' field will be either 0 or 1
 date    - the 'value; field should be a date

So the following data structure will retrieve all jobs that belong to 'kevin'
and 'debbie'.

 $filter = [{
     field => 'username',
     type  => 'list',
     value => ['kevin', 'debbie']
 }];

The optional "comparison" parameter can have the following values:

 lt - less then the value
 le - less then or equal to the value
 gt - greater then the value
 ge - greater then or equal to the value
 lk - like the value
 be - between two values
 eq - equal to the value

The "comparision" parameter is only meaningful with the "string", "number" and
"date" types. So to further filter our jobs, we could use this data
structure:

 $filter = [{
     field => 'username',
     type  => 'list',
     value => ['kevin', 'debbie']
 },{
     field => 'completion_time',
     type  => 'date',
     value => ['2016-07-29', '2016-07-31'],
     comparision => 'be',
 }];

Which would return all jobs by either 'kevin' or 'debbie' with a
completion_time between '2016-07-29' and '2016-07-31'.

=back

=head2 log($job)

This method will retrieve the log for a job. The log record will have the
following format:

 $log = {
     '_links' => {
         self => {
             href  => '/rexec/logs/<jobid>
             title => <jobid>
         },
     },
     jobid => <jobid>
     lines => [
         'line one',
         'line two',
     ]
 };

=over 4

=item B<$job>

The job record to use when retrieving the log.

=back

=head2 logs(...)

This method will return an array of log files. By default it will
return all logs stored by the xas-rexecd service. This behavior can be
modified with selection criteria. Each log record will have this format:

 $log = {
     '_links' => {
         self => {
             href  => '/rexec/logs/<jobid>
             title => <jobid>
         },
     },
     jobid => <jobid>
     size  => '1000',
     mtime => 'YYYY-MM-DD HH:MM:SS'
 };

The selection criteria is the same as used by jobs().

=head2 submit(...)

This method will submit a job to the xas-rexecd service for processing. Once
the job has been submited it will return a job record. It takes the following
paramters:

=over 4

=item B<-username>

This is a mandatory parameter. It is the username of who is submitting the job.

=item B<-command>

This is a manadatory parameter. It is the command to run.

=item B<-directory>

The optional directory to start the job in, defaults to '/'.

=item B<-environment>

Optional environment variables to provide to the job. There is no default,
but the variable "XAS_REXECD" will always be defined.

=item B<-priority>

The optional priority to run the job under, defaults to 0. This has no
meaning on Windows.

=item B<-umask>

The optional process protection mask to use for the job, defaults to '0022'.
This has no meaning on Windows.

=item B<-user>

The optional user to run the job under, defaults to 'xas'. This user must
exist on the system that the xas-rexecd service is running on. This has
no meaning on Windows.

=item B<-group>

The optional group to run the job under, defaults to 'xas'. This group must
exist on the system that the xas-rexecd service is running on. This has
no meaning on Windows.

=back

=head2 start($job)

This method will start a job.

=over 4

=item B<$job>

The job that a start action will be requested for.

=back

=head2 stop($job)

This method will start a job.

=over 4

=item B<$job>

The job that a stop action will be requested for.

=back

=head2 pause($job)

This method will start a job.

=over 4

=item B<$job>

The job that a pause action will be requested for.

=back

=head2 resume($job)

This method will start a job.

=over 4

=item B<$job>

The job that a resume action will be requested for.

=back

=head2 kill($job)

This method will start a job.

=over 4

=item B<$job>

The job that a kill action will be requested for.

=back

=head2 delete($job)

This method will delete a job record from the database.

=over 4

=item B<$job>

The job that a delete action will be requested.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Rexec|XAS::Rexec>

=item L<XAS::Service::Search|XAS::Service::Search>

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
