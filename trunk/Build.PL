use strict;
use warnings FATAL => 'all';
use Module::Build;

my $install_path = {
    db            => '/var/lib/xas',
    etc           => '/etc/xas',
    web           => '/var/lib/xas/web',
    sbin          => '/usr/sbin',
    script        => '/usr/bin',
    sysconfig     => '/etc/sysconfig',
    'init.d'      => '/etc/init.d',
    'logrotate.d' => '/etc/logrotate.d',
};

my $requires = {
     'XAS'          => '0.15',
     'XAS::Service' => '0.01',
};

if ($^O eq 'MSwin32') {

    my $path = defined($ENV{CTS_ROOT}) ? $ENV{CTS_ROOT} :
               defined($ENV{xas_ROOT}) ? $ENV{xas_ROOT} : 'D:\\xas';

   $install_path = {
       db            => $path . '\\lib',
       etc           => $path . '\\etc',
       web           => $path . '\\var\\lib\\web',
       sbin          => $path . '\\sbin',
       script        => $path . '\\bin',
       sysconfig     => $path . '\\etc\\sysconfig',
       'init.d'      => $path . '\\etc\\init.d',
       'logrotate.d' => $path . '\\etc\\logrotate.d',
       'profile.d'   => $path . '\\etc\\profile.d',
   };

}

my $class = Module::Build->subclass(code => <<'EOC');

    use strict;
    use warnings;

    use IO::File;
    use File::Find;
    use File::Basename;
    use File::Spec::Functions qw( catfile catdir rel2abs );

    # override and add a few things

    sub new {
        my $class = shift;

        my $self = $class->SUPER::new(@_);

        my $blib = $self->{properties}{blib};
        my $sbin = catfile($blib, 'sbin');
        $self->{properties}{sbindoc_dirs} = [ $sbin ];

        return $self;

    }

    # create man pages for files within sbin

    sub manify_sbin_pods {
        my $self    = shift;

        my $files  = $self->_find_pods(
            $self->{properties}{sbindoc_dirs},
            exclude => [ $self->file_qr('\.bat$') ]
        );

        return unless keys %$files;

        my $mandir = File::Spec->catdir( $self->blib, 'bindoc' );
        File::Path::mkpath( $mandir, 0, oct(777) );

        require Pod::Man;

        foreach my $file (keys %$files) {

            # Pod::Simple based parsers only support one document per instance.
            # This is expected to change in a future version
            # (Pod::Simple > 3.03).

            # binaries go in section 1p

            my $parser  = Pod::Man->new( section => '1p' );
            my $manpage = $self->man1page_name( $file ) . '.' .
                $self->config( 'man1ext' );

            my $outfile = File::Spec->catfile($mandir, $manpage);

            next if $self->up_to_date( $file, $outfile );

            $self->log_verbose("Manifying $file -> $outfile\n");

            eval { $parser->parse_from_file( $file, $outfile ); 1 }
                 or $self->log_warn("Error creating '$outfile': $@\n");

            $files->{$file} = $outfile;

        }

    }

   # additional switch processing

    sub ACTION_post_install {
        my $self = shift;

        # create wise owner/group

        unless ($^O eq 'MSWin32') {

            # use the standard unix filesystem layout

            system("mkdir /var/log/xas/rexec") unless ( -e '/var/log/xas/rexec');

            # set ownership/permissions on the files/directories

            system("chown -R xas.xas /var/log/xas/rexec");
            system("chmod 0775 /var/log/xas/rexec");
            system("chmod g+s /var/log/xas/rexec");

        } else {

            my $dir;
            my $base = defined($ENV{XAS_ROOT})
                    ? $ENV{XAS_ROOT}
                    : ['D:', 'xas'];

            $dir = catdir($base, 'var', 'log', 'rexec');
            system("mkdir $dir") unless ( -e $dir);

        }

        return $self;

    }

    # correctly process additional directories

    sub process_etc_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'etc');
        my $files = $self->find_etc_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_db_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'lib');
        my $files = $self->find_db_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_web_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'web');
        my $files = $self->find_web_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_sbin_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'sbin');
        my $files = $self->find_sbin_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to) or next;
            $self->make_executable($result);

        }

        return $self;

    }

    sub process_initd_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'init.d');
        my $files = $self->find_initd_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to) or next;
            $self->make_executable($result);

        }

        return $self;

    }

    sub process_sysconf_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'sysconfig');
        my $files = $self->find_sysconf_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to) or next;
            $self->make_executable($result);

        }

        return $self;

    }

    sub process_profiled_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'profile.d');
        my $files = $self->find_profiled_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to) or next;
            $self->make_executable($result);

        }

        return $self;

    }

    sub process_logrotated_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'logrotate.d');
        my $files = $self->find_logrotated_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub find_db_files { shift->find_all_files_no_scm('db'); }
    sub find_etc_files { shift->find_all_files_no_scm('etc'); }
    sub find_web_files { shift->find_all_files_no_scm('web'); }
    sub find_sbin_files { shift->find_all_files_no_scm('sbin'); }
    sub find_initd_files { shift->find_all_files_no_scm('init.d'); }
    sub find_sysconf_files { shift->find_all_files_no_scm('sysconfig'); }
    sub find_profiled_files { shift->find_all_files_no_scm('profile.d'); }
    sub find_logrotated_files { shift->find_all_files_no_scm('logrotate.d'); }

    sub find_all_files_no_scm {
        my ($self, $dir) = @_;

        my $sub = sub {
            return ((($File::Find::name !~ /SVN/i)  and
                     ($File::Find::name !~ /GIT/i)) and
                    ( -f $File::Find::name));
        };

        return { map {$_, $_} @{ $self->rscan_dir($dir, $sub) } };

    }

    # fix for scm files in the script directory

    sub _files_in {
        my ($self, $dir) = @_;
        return unless -d $dir;

        local *DH;
        opendir DH, $dir or die "Can't read directory $dir: $!";

        my @files;
        while (defined (my $file = readdir DH)) {
           my $full_path = File::Spec->catfile($dir, $file);
           next if -d $full_path;
           next if (($file =~ /SVN/i) or ($file =~ /GIT/i));
           push @files, $full_path;
       }
       return @files;
    }
EOC

my $builder = $class->new(
    module_name         => 'XAS::Rexec',
    license             => 'perl',
    dist_author         => q{Kevin L. Esteb <kevin@kesteb.us>},
    dist_version_from   => 'lib/XAS/Rexec.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup     => [ 'XAS-Rexec-*' ],
    create_makefile_pl => 'traditional',
    requires           => $requires,
    install_path       => $install_path,
);

$builder->add_build_element('db');
$builder->add_build_element('etc');
$builder->add_build_element('web');
$builder->add_build_element('sbin');
$builder->add_build_element('initd');
$builder->add_build_element('sysconf');
$builder->add_build_element('logrotated');

$builder->create_build_script();

