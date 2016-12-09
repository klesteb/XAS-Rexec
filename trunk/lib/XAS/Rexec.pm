package XAS::Rexec;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.01';

1;

__END__

=head1 NAME

XAS::Rexec - A set of procedures and modules to provide a micro service

=head1 DESCRIPTION

This package provides a method to run commands on remote systems. This process
is OS neutral and dosen't require SSH or WS-Manage. All communications is done
in clear text and should be ran over an encrypted network. Any connections
made to this service are authenticated. This is done with HTTP's basic 
authentication mechanisim. This will allow the Linux and Windows system to 
submit jobs to each other.

A simple HTML based interface is provided. Most of the usability of this
system will come from the REST interface.

=head1 DATA STRUCTURES

All data structures are formatted JSON strings. This is a portable
data structure. It is language agnostic and network neutral. The following
HTTP header types are used when communicating with the service. These
define what the expected input and output data streams should be.

=head2 Content-Type: application/vnd.xas.rexec+json;version=1.0

This defines what can be posted to the service. A HTTP POST is used to
submit a job, or to manipulate a running job. The basic structure is
as follows:

 {'action':'something'}

Where "something" can be either 'post', 'start', 'stop', 'pause', 'resume'
or 'kill'. When the "something" is 'post', then the structure could look
like this:

 {
     'action':      'post',
     'username':    'jdoe',
     'command':     'ls -la',
     'directory':   '/',
     'priority':    '0',
     'umask':       '0022'
     'user':        'wise',
     'group':       'wise',
     'environment': ''
 }

Where 'username' and 'command' are required fields. The rest are optional and
are filled in with defaults on the service end.

=head2 Accept: application/hal+json

All JSON returned, follows the L<HAL - Hypertext Applicaiton Language|http://stateless.co/hal_specification.html>
format. This is a quasi industry standard and has serveral libraries for
various languages, that can manipulate this structure. The basic format is as
follows:

 {
    "_embedded" : {
    },
    "_links" : {
       "parent" : {
          "href" : "/rexec",
          "title" : "Remote Execution"
       },
       "self" : {
          "href" : "/rexec/jobs",
          "title" : "Jobs"
       },
       "children" : [
          {
             "href" : "/rexec/jobs/_create",
             "title" : "Create"
          }
       ]
    }
 }

Where the "_links" can be used to transverse the service. A "parent" is the
link above, "self" is a link to the current location and "children" are the
links below. The "_embedded" is where we store our data. There are five types
of data. They are "job", "jobs", "log", "logs" and "errors".

The data structure for a "job" response looks like this.

 "job": {
     "jobid" : "40.bob",
     "priority" : "0",
     "status" : "C",
     "start_time" : "2016-07-15 08:15:00",
     "xgroup" : "xas",
     "directory" : "/",
     "username" : "kevin",
     "queued_time" : "2016-07-15 08:14:04",
     "environment" : "XAS_REXECD=1;;",
     "exit_code" : 0,
     "completion_time" : "2016-07-15 08:15:00",
     "user" : "xas",
     "umask" : "0022",
     "command" : "/home/kevin/dev/XAS-Rexec/trunk/sbin/test.sh"
     "_links" : {
         "self" : {
             "href" : "/rexec/jobs/40.bob",
             "title" : "View"
         },
         "delete" : {
             "href" : "/rexec/jobs/40.bob",
             "title" : "Delete"
         },
         "log" : {
             "href" : "/rexec/logs/40.bob",
             "title" : "Log"
         }
     },
 }

The job "_links" may vary depending on the job status.

 'self'   where the 'href' field points to the URL for the job
 'log'    where the 'href' field points to the URL for the log file
 'delete' where the 'href' field points to the URL for a HTTP DELETE
 'start'  where the 'href' field points to the URL for a HTTP POST
 'stop'   where the 'href' field points to the URL for a HTTP POST
 'pause'  where the 'href' field points to the URL for a HTTP POST
 'resume' where the 'href' field points to the URL for a HTTP POST
 'kill'   where the 'href' field points to the URL for a HTTP POST

The jobs status can be one of the following:

 U - unknown
 Q - queued
 R - running
 C - completed
 P - paused
 A - aborted - stop/kill

So you would get the following links for the given status.

 A - delete, start
 C - delete
 P - resume
 Q - start, delete
 R - pause, stop, kill

If a log file exists, then you will get a link to the log file.

The data structure for a "jobs" response looks like this.

 "jobs": [
    {}
 ]

The data structure for a "log" response looks like this.

 "log" : {
    "jobid" : "40.bob",
    "lines" : [
        "TERM=xterm",
        "SHELL=/bin/bash",
        "MQSERVER=bob",
        "MXSERVER=mail.kesteb.us",
        "MQPORT=61613",
        "use_db_appservers=FALSE",
        "PATH=/sbin:/usr/sbin:/bin:/usr/bin",
        "_=/bin/env",
        "PWD=/",
        "os_is=LINUX",
        "LANG=en_US.UTF-8",
        "SHLVL=3",
        "HOME=/root",
        "MXPORT=25",
        "XAS_ROOT=/",
        "it works"
    ],
    "_links" : {
        "self" : {
            "href" : "/rexec/logs/40.bob",
            "title" : "40.bob"
        }
    },
 }

Where the "lines" array has one row per log line. This could get cumbersome
with really large log files.

The data structure for a "logs" response looks like this.

 "logs" : [
     {
         "jobid" : "70.bob",
         "mtime" : "2016-08-02 10:02:07",
         "size" : 3173,
         "_links" : {
             "self" : {
                 "href" : "/rexec/logs/70.bob",
                 "title" : "70.bob"
             }
         }
     }
 ]

The data structure for an "errors" response looks like this.

 "errors" : [
     {
         "detail" : "Unauthorized",
         "status" : 401,
         "title" : "HTTP Error: 401",
         "code" : "http client error"
     }
 ]

Even thou this is defined as an array. There is only one error message.

=head1 ENDPOINTS

The following endpoints have been defined for this service. The HTML
interface is self explanatory and follows standard web practices. The
following will explain the REST interface.

=head2 GET /rexec/jobs

This endpoint is used to query jobs. By default it returns all jobs.

=over 4

=item B<Example>

 #!/bin/sh
 #
 curl http://localhost:9507/rexec/jobs \
 -H "Accept: application/hal+json" -u kevin

The result should return a HTTP 200 status code and a "jobs" response. If
there are no jobs on this server, then the jobs array will be empty.

=back

=head2 GET /rexec/jobs/_search?...

Since the previous endpoint will return all jobs, search functionality has been
built in. This will allow you to select a subset of all of the jobs. The
following parameters are defined:

=over 4

=item B<start=0&limit=25>

The "start" and "limit" parameters will allow you to do paging of the
returned jobs.

=item B<sort=[{'field': 'username', 'direction': 'ASC'}]>

The "sort" parameter is used to sort the results. You may have noticed that
the value for the "sort" parameter is a JSON string, or more specifically,
an array of JSON objects, where "field" must be a valid field in the jobs
data structure, and "direction" must be either 'ASC' or 'DESC'.

=item B<group=[{'field': 'username', 'direction': 'ASC'}]>

The "group" parameter is used to group the results. You may have noticed that
the value for the "group" parameter is a JSON string, or more specifically,
an array of JSON objects, where "field" must be a valid field in the jobs
data structure, and "direction" must be either 'ASC' or 'DESC'.

=item B<filter=[{"field":"email", "type": "string", "value": "kevin@kesteb.us"}]>

The "filter" parameter will actually allow you to select which jobs to return.
You may have noticed that the value for the "filter" parameter is a JSON
string, or more specifically, an array of JSON objects, where "field" must be
a valid field in the jobs data structure, "type" must one of these: string,
number, list, boolean or date; "value" may be what is being selected upon.
There is an optional 'comparison' field that allows you to refine your selection
even more, 'comparison' must be one of these: lt, le, gt, ge, lk, be or qe.

For additional help on how to use this parameter, please see
L<XAS::Web::Search|XAS::Web::Search>.

=back

=head2 GET /rexec/jobs/_create

This endpoint will return a data structure for a HTML form. This is primarily
use for the HTML interface, but can be used for a Web application to display a
form.

=head2 POST /rexec/jobs

A POST to this endpoint, submits a new job for processing. This should return
a HTTP status code of 201 and a "job" response. You can use this to
monitor the job.

=over 4

=item B<Example>

 #!/bin/sh
 #
 DATA="{'username':'jdoe','command':'ls -la','action':'post'}"
 #
 curl -XPOST http://localhost:9507/rexec/jobs \
   -H "Content-Type: application/vnd.xas.rexec+json;version=1.0" \
   -H "Accept: application/hal+json" -u kevin -d $DATA

=back

=head2 GET /rexec/jobs/<jobid>

This endpoint allows you to retrieve a single "job" response. This can be used
to monitor a job.

=over 4

=item B<Example>

 #!/bin/sh
 #
 curl http://localhost:9507/rexec/jobs/40.bob \
 -H "Accept: application/hal+json" -u kevin

The result should return a HTTP 200 status code and a "job" response. If the
job doesn't exist, then a HTTP 404 status code will be returned with an "errors"
response.

=back

=head2 POST /rexec/jobs/<jobid>

A POST to this endpoint allows you to control a job. The action can be one
of the following: start, stop, pause, resume, kill

=over 4

=item B<Example>

 #!/bin/sh
 #
 DATA="{'action':'start'}"
 #
 curl -XPOST http://localhost:9507/rexec/jobs/40.bob \
   -H "Content-Type: application/vnd.xas.rexec+json;version=1.0" \
   -H "Accept: application/hal+json" -u kevin -d $DATA

The result should return a HTTP 202 status code with a "job" response. If the
job doesn't exist, or the status of the job won't allow a 'start' action,
then a HTTP 404 status code will be returned with an "errors" response.

=back

=head2 DELETE /rexec/jobs/<jobid>

A DELETE to this endpoint will remove the job entry from the database and any
associated log file.

=over 4

=item B<Example>

 #!/bin/sh
 #
 curl -XDELETE http://localhost:9507/rexec/jobs/40.bob \
   -H "Content-Type: application/vnd.xas.rexec+json;version=1.0" \
   -H "Accept: application/hal+json" -u kevin

The result should return a HTTP 204 status code. If the job doesn't exist,
or the status of the job won't allow a DELETE to happen, then a HTTP 404
status code will be returned with an "errors" response.

=back

=head2 GET /rexec/logs

A GET to this endpoint return an array of "logs" responses.

=over 4

=item B<Example>

 #!/bin/sh
 #
 curl http://localhost:9507/rexec/logs \
 -H "Accept: application/hal+json" -u kevin

The result should return a HTTP 200 status code and a "logs" response.

=back

=head2 GET /rexec/logs/_search?...

Since the previous endpoint will return all logs, search functionality has
been built in. This will allow you to select a subset of all of the logs.
This follows the same criteria as when searching for jobs. Please refer to
that section for details.

=head2 GET /rexec/logs/<jobid>

A GET to this endpoint returns a single "log" response.

=over 4

=item B<Example>

 #!/bin/sh
 #
 curl http://localhost:9507/rexec/logs/40.bob \
 -H "Accept: application/hal+json" -u kevin

The result should return a HTTP 200 status code and single "log" response.
If the log doesn't exist, then a HTTP 404 status code will be returned with
an "errors" response.

=back

=head1 CLIENTS

A Perl based client has been written. This will simplify the interaction with
the service. L<XAS::Rexec::Client|XAS::Rexec::Client> has the details on how
this client works.

=head1 SEE ALSO

=over 4

=item L<XAS::Rexec::Client|XAS::Rexec::Client>

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
