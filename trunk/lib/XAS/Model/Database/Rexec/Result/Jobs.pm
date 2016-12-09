package XAS::Model::Database::Rexec::Result::Jobs;

our $VERSION = '0.01';

use XAS::Class
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM'
;

__PACKAGE__->load_components( qw/ InflateColumn::DateTime OptimisticLocking / );
__PACKAGE__->table( 'jobs' );
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_increment => 1,
        sequence          => 'jobs_id_seq',
        is_nullable       => 0,
    },
    status => {
        data_type     => 'varchar',
        size          => 1,
        is_nullable   => 0,
        default_value => 'Q',
    },
    queued_time => {
        data_type   => 'timestamp with time zone',
        timezone    => 'local',
        is_nullable => 0,
    },
    start_time => {
        data_type   => 'timestamp with time zone',
        timezone    => 'local',
        is_nullable => 1,
    },
    completion_time => {
        data_type   => 'timestamp with time zone',
        timezone    => 'local',
        is_nullable => 1,
    },
    exit_code => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    username => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0,
    },
    command => {
        data_type   => 'varchar',
        size        => 1024,
        is_nullable => 0,
    },
    priority => {
        data_type   => 'varchar',
        size        => 8,
        is_nullable => 0,
    },
    umask => {
        data_type   => 'varchar',
        size        => 4,
        is_nullable => 0,
    },
    xgroup => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0,
    },
    user => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0,
    },
    directory => {
        data_type   => 'varchar',
        size        => 256,
        is_nullable => 0,
    },
    environment => {
        data_type   => 'varchar',
        size        => 4096,
        is_nullable => 0,
    },
    revision => {
        data_type   => 'integer',
        is_nullable => 1
    }
);

__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->optimistic_locking_strategy('dirty');
#__PACKAGE__->optimistic_locking_strategy('version');
#__PACKAGE__->optimistic_locking_version_column('revision');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

}

sub table_name {
    return __PACKAGE__;
}

1;

__END__

=head1 NAME

XAS::Model::Database::Rexec::Results::Jobs - Table defination for XAS Model

=head1 DESCRIPTION

The definition for the log table.

=head1 FIELDS

=head2 id

An automatic incremental index.

=over 4

=item B<data type> - bigint

=item B<sequence name> - 'jobs_id_seq'

=item B<is nullable> - no

=back

=head2 status

Holds the current status of the job. It defaults to 'Q'.

=over 4

=item B<data type> - varchar

=item B<size> - 1

=item B<is nullable> - yes

=back

=head2 queued_time

The time that a job was queued on the local system.

=over 4

=item B<data type> - 'timestamp with time zone'

=item B<meta timezone> - 'local'

=item B<is_nullable> - no

=back

=head2 start_time

The time the job started on the local system.

=over 4

=item B<data type> - 'timestamp with time zone'

=item B<meta timezone> - 'local'

=item B<is_nullable> - no

=back

=head2 completion_time

The time the job completed on the local system.

=over 4

=item B<data type> - 'timestamp with time zone'

=item B<meta timezone> - 'local'

=item B<is_nullable> - no

=back

=head2 exit_code

The exit code for the job.

=over 4

=item B<data type> - integer

=item B<is_nullable> - yes

=back

=head2 username

The name of the user that requested the job.

=over 4

=item B<data type> - varchar

=item B<size> - 32

=item B<is nullable> - no

=back

=head2 command

The command to execute on the local system.

=over 4

=item B<data type> - varchar

=item B<size> - 1024

=item B<is nullable> - no

=back

=head2 priority

The priority to run the job at.

=over 4

=item B<data type> - varchar

=item B<size> - 9

=item B<is nullable> - no

=back

=head2 umask

The protection mask for the job.

=over 4

=item B<data type> - varchar

=item B<size> - 9

=item B<is nullable> - no

=back

=head2 xgroup

The group on the local system to run the job under.

=over 4

=item B<data type> - varchar

=item B<size> - 9

=item B<is nullable> - no

=back

=head2 user

The user on the local system to run the job under.

=over 4

=item B<data type> - varchar

=item B<size> - 32

=item B<is nullable> - no

=back

=head2 directory

The directory to run the job from.

=over 4

=item B<data type> - varchar

=item B<size> - 256

=item B<is nullable> - no

=back

=head2 environment

Environment variables to pass to the job.

=over 4

=item B<data type> - varchar

=item B<size> - 4096

=item B<is nullable> - no

=back

=head2 revision

Used by L<DBIx::Class::OptimisticLocking|https://metacpan.org/pod/DBIx::Class::OptimisticLocking>
to manage changes for this record.

=over 4

=item B<data type> - integer

=item B<is nullable> - yes

=back

=head1 METHODS

=head2 sqlt_deploy_hook($sqlt_table)

This method is used when a database schema is being generated. It can be used
to add additional features.

=over 4

=item B<$sqlt_table>

The DBIx::Class class for this table.

=back

=head2 table_name

Used by the helper functions mixed in from L<XAS::Model::DBM|XAS::Model::DBM>.

=head1 SEE ALSO

=over 4

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
