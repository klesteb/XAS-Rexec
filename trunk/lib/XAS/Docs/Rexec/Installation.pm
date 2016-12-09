package XAS::Docs::Rexec::Installation;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Rexec::Installation - how to install the XAS Rexec environment

XAS is operations middleware for Perl. It provides standardized methods, 
modules and philosophy for constructing large distributed applications. This 
system is based on production level code.

=head1 GETTING THE CODE

Since the code repository is git based, you can use the following commands:

    # mkdir XAS-Rexec
    # cd XAS-RExec
    # git init
    # git pull http://scm.kesteb.us/git/XAS-Rexec master

Or you can download the code from CPAN in the following manner:

    # cpan -g XAS-Rexec
    # tar -xvf XAS-Rexec-0.01.tar.gz
    # cd XAS-Rexec-0.01

It is suggested that you do not do an automated cpan based install, as it 
will not set up the environment correctly. In either case the following 
commands are run from that directory.

=head1 INSTALLATION

On Unix like systems, using pure Perl, run the following commands:

    # perl Build.PL --installdirs site
    # ./Build
    # ./Build test
    # ./Build install

If you are DEB based, Debian build files have been provided. If you have a 
Debian build environment, then you can do the following:

    # debian/rules build
    # debian/rules clean
    # dpkg -i ../libxas-rexec-perl_0.01-1_all.deb

If you are RPM based, a spec file has been included. If you have a
rpm build environment, then you can do the following:

    # perl Build.PL
    # ./Build
    # ./Build test
    # ./Build dist
    # rpmbuild -ta XAS-Rexec-0.01.tar.gz
    # cd ~/rpmbuild/RPMS/noarch
    # yum --nogpgcheck localinstall perl-XAS-Rexec-0.01-1.noarch.rpm

Each of these installation methods will overlay the local file system and
tries to follow Debian standards for file layout and package installation. 

On Windows, do the following:

    > perl Build.PL
    > Build
    > Build test
    > Build install

It is recommended that you useL<Strawberry Perl|http://strawberryperl.com/>, 
L<ActiveState Perl|http://www.activestate.com/activeperl>
doesn't have all of the necessary modules available.

B<WARNING>

    Not all of the Perl modules have been included to make the software 
    run. You may need to load additional CPAN modules. How you do this,
    is dependent on how you manage your systems. This software requires 
    Perl 5.8.8 or higher to operate.

=head1 POST INSTALLATION

 <place holder>

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc XAS-Rexec

Extended documentation is available here:

    http://scm.kesteb.us/trac

The latest and greatest is always available at:

    http://scm.kesteb.us/git/XAS-Rexec

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
