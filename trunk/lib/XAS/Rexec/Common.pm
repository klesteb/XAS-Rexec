package XAS::Rexec::Common;

our $VERSION = '0.01';

use XAS::Model::Database
  schema => 'XAS::Model::Database::Rexec',
  tables => ':all'
;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  import     => 'class',
  utils      => ':validation',
  constants  => 'HASHREF',
  filesystem => 'File Dir',
  mixins     => 'build_id build_log get_id check_stat get_job get_jobs stat_job del_job find_job log_files check_id',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub build_id {
    my $self = shift;
    my ($id) = validate_params(\@_, [1]);

    return sprintf('%s.%s', $id, $self->env->host);

}

sub check_id {
    my $self = shift;
    my ($id) = validate_params(\@_, [1]);

    my ($job, $host) = split('\.', $id, 2);

    my $truth = ((($job =~ m/[0-9]+/) && ($host =~ m/[a-zA-Z0-9\-]+/)) && $host eq $self->env->host) || 0;

    return $truth ? 0 : 1;

};

sub build_log {
    my $self = shift;
    my ($id) = validate_params(\@_, [1]);

    my $log = File($self->env->log, 'rexec', "$id.log");

    return $log;
}

sub log_files {
    my $self = shift;

    my $dir = Dir($self->env->log, 'rexec');
    my @files = $dir->files;

    return wantarray ? @files : \@files;

}

sub get_id {
    my $self  = shift;
    my ($jobid) = validate_params(\@_, [1]);

    my ($id, $host) = split('\.', $jobid, 2);

    return $id;

}

sub check_stat {
    my $self = shift;
    my ($stat) = validate_params(\@_, [{
        callbacks => {
            "must have a value" => sub {
                 return (shift() ne '') ? 1 : 0;
            }
        }
    }]);

    return (($stat ne 'U') and ($stat ne 'C'));

}

sub get_job {
    my $self  = shift;
    my ($jobid) = validate_params(\@_, [1]);

    my $schema = $self->schema;

    my $key = {
        id => $self->get_id($jobid)
    };

    return Jobs->read_record($schema, $key);

}

sub get_jobs {
    my $self     = shift;
    my ($criteria, $options) = validate_params(\@_, [
        { type => HASHREF },
        { type => HASHREF },
    ]);

    my $schema = $self->schema;

    return Jobs->load_records($schema, $criteria, $options);

}

sub stat_job {
    my $self  = shift;
    my ($jobid) = validate_params(\@_, [1]);

    my $stat   = 'U';
    my $schema = $self->schema;

    my $key = {
        id => $self->get_id($jobid)
    };

    if (my $job = Jobs->find($schema, $key)) {

        $stat = $job->status;

    }

    return $stat;

}

sub find_job {
    my $self  = shift;
    my ($jobid) = validate_params(\@_, [1]);

    my $schema = $self->schema;

    my $key = {
        id => $self->get_id($jobid)
    };

    return Jobs->find($schema, $key);

}

sub del_job {
    my $self  = shift;
    my ($jobid) = validate_params(\@_, [1]);

    my $schema = $self->schema;
    my $key = {
        id => $self->get_id($jobid)
    };

    Jobs->delete_record($schema, $key);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Rexec::Common - A mixin of common routines

=head1 SYNOPSIS

 use XAS::Class;
     version => '1.0',
     base    => 'XAS::Base',
     mixin   => 'XAS::Rexec::Common'
 ;

=head1 DESCRIPTION

This is a mixin that contains multiple routines that are common between
multiple modules.

=head1 METHODS

=head2 build_id($id)

Creates a job id based on the database index and the host name.

=over 4

=item B<$id>

The id from the database index.

=back

=head2 check_id($jobid)

Checks to see that the job id conforms to this pattern \d+\.\w+ and that
the host matches the local host name. Return true/false depending on the
match.

=over 4

=item B<$jobid>

A job id to check.

=back

=head2 build_log($jobid)

Returns a log file name based on the job id.

=over 4

=item B<$jobid>

The job id to be used for the log file name.

=back

=head2 log_files

This method returns all the log files within the log directory.

=head2 get_id($jobid)

This method returns the database index from the job id.

=over 4

=item B<$jobid>

The job id to extract the id from.

=back

=head2 check_stat($stat)

The method checks a job status to see wither it is not "U" or "C". Returns
true/false depending on the comparison.

=over 4

=item B<$stat>

The job status to check.

=back

=head2 get_job($jobid)

This method returns the job record from the database.

=over 4

=item B<$jobid>

The job id to use when retrieving the record.

=back

=head2 get_jobs($criteria, $options)

This method returns all of the jobs from the database that match the criteria.

=over 4

=item B<$criteria>

The data structure used to perform the query.

=item B<$options>

The data structure used to sort the results.

=back

=head2 stat_job($jobid)

This method will return the status of a job.

=over 4

=item B<$jobid>

The job id to use when retrieving the record.

=back

=head2 del_job($jobid)

This method will remove a job from the database.

=over 4

=item B<$jobid>

The job id to use when deleting the record.

=back

=head2 find_job($jobid>

This method returns a database row object for job id.

=over 4

=item B<$jobid>

The job id to use when retrieving the record.

=back

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
