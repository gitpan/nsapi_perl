# This Makefile.PL script is based on the original by:
#
# -Ben Sugars
# <bsugars@canoe.ca>
# December 11, 1997
#
# This script will generate a Makefile.PL script for both the Netscape
# plugin (in ./nsapi) and the perl Netscape extension (in ./perl/lib/Netscape).
#
# Both Makefile.PL scripts use MakeMaker to generate platform dependent
# Makefiles.
#
# This script will prompt the user for the location of Netscape Enterprise
# Server root directory and for the location of where to install the
# Netscape plugin. The server root is expected to be a fully qualified
# directory path and the plugin installation directory relative to
# the server root.
#
# Every attempt has been made to minimize the platform differences between
# MSWin32 and the various UN*Xs. Please help keep it that way.
# 
# All ideas and improvements to this script are welcome.
#
# -Steve Nielsen
# <spn@enteract.com>
# Janurary 20, 1998
#
# Confirmed to work on:
# =====================
#	MSWin32:
#		NT 4.0 sp3, Netscape Enterprise Server 2.01, perl 5.004_04
#	Sun/Solaris
#               SunOS 5.5.1 sun4m, Netscape Enterprise Server 2.01, perl 5.004_01

BEGIN { $^W = 1 }
BEGIN { require 5.004 }

use strict;
use Config;

# ----------------------------------------------------------------------

##-- Introduction
print <<EOM;

Welcome to nsapi_perl.  This program will ask some questions and then
generate Makefiles that will be used to compile the nsapi_perl server
plug in and the Netscape:: perl extensions.

Some questions may have default answers.  If a question has a default
answer, it will be presented between square brackets [ ... ] when the
question is asked.  Just hit <return> to accept the default answer.

Proceed? [y]
EOM
{
	my $default_answer = 'y';
	my $answer = <>;
	chomp $answer;
	$answer = ($answer or $default_answer);
	$answer =~ /^y/i or exit;
}

##-- get Netscape Server root directory
print <<EOM;

Enter your Netscape server's root directory:
EOM
my $ns_server_root = <>;
chomp $ns_server_root;
$ns_server_root =~ s#(\/|\\)+$##;
$ns_server_root =~ s#\\#\/#;

##-- get NSAPI include directory.  Why did Netscape
##-- change this?
print <<EOM;

Enter the directory where the NSAPI header files can
be found.  This is most likely one of
    $ns_server_root/nsapi/include
    $ns_server_root/include
depending upon the vintage of your server.
NSAPI header directory? [$ns_server_root/nsapi/include]
EOM
my $ns_inc_dir;
{
	my $default_answer = "$ns_server_root/nsapi/include";
	my $answer = <>;
	chomp $answer;
	$ns_inc_dir = ($answer or $default_answer);
}

##-- get plugin installation directory
print <<EOM;

Enter where you want to install the Netscape plugin (relative
to Netscape Enterprise server root) and the nsapi_perl_init.pl
start-up script: [lib]
EOM
my $ns_inst_dir;
{
	my $default_answer = 'lib';
	my $reldir = <>;
	chomp $reldir;
	$reldir = ($reldir or $default_answer);
	$reldir =~ s#(\/|\\)+$##;
	$reldir =~ s#\\#\/#;
	$ns_inst_dir     = $ns_server_root . '/' . $reldir;
}

##-- get OS type
my $os = $^O;
my $osvers = $Config{osvers};
$osvers =~ s/^\s*(\d+\.\d+).*/$1/;  # drop sub-sub-version: 2.5.1 -> 2.5

##-- base set of compilation defines
my $ns_defines = "-DNET_SSL -DMCC_HTTPD";

##-- Unix platforms need not be thread-safe for older servers
if ($os ne 'MSWin32') {
	print <<EOM;

Should we compile a thread-safe Netscape plugin?  Basically for 1.x
Unix servers you should answer 'no', but for 2.x and higher Unix
servers you should answer 'yes'.  Compile thread-safe? [yes]
EOM
	my $default_answer = 'yes';
	my $answer = <>;
	chomp $answer;
	$answer = ($answer or $default_answer);
	if ($answer =~ /^y/) {
		$ns_defines .= " -DNP_THREAD_SAFE";
	}
} else {
	##-- MSWin32 must be thread-safe
	$ns_defines .= " -DNP_THREAD_SAFE";
}

##-- MSWin32 specific compile options
if($os eq 'MSWin32') {
	$ns_defines .= " -DWIN32 -DXP_WIN32";
	}
##-- Solaris-specific compile options
elsif ($os eq 'solaris') {
	$ns_defines .= " -DSOLARIS -D_REENTRANT -DXP_UNIX -DSPAPI20 -Wall";
	}
##-- Untested operating systems
else {
	if ($os eq 'irix') {
		$ns_defines .= " -DXP_UNIX -DIRIX -D_SGI_MP_SOURCE -fullwarn";
	}
	elsif ($os eq 'hpux') {
		$ns_defines .= " -DXP_UNIX -DHPUX -D_HPUX_SOURCE -Aa +DA1.0 +z -c";
	}
	print <<EOM;

Warning: build of nsapi_perl on $os is untested.  If successful,
please let me (Ben Sugars, bsugars\@canoe.ca) know.

(You made need to fiddle with the ./nsapi/Makefile to get
nsapi_perl to work.  Please be patient.)

Enter NSAPI compile options for $os (These can generally be found
from the Makefile in the nsapi/examples directory.):
[$ns_defines]
EOM
	my $answer = <>;
	chomp $answer;
	$ns_defines = ($answer or $ns_defines);
}

##-- change directory to ./nsapi and generate Makefile.PL
print "\nMakefile.PL: entering ./nsapi\n";
chdir './nsapi' or
    die "Makefile.PL: couldn't chdir to ./nsapi: $!\n";
MF_nsapi_perl($ns_server_root, $ns_inst_dir, $os, $ns_defines, $ns_inc_dir);

##-- change directory to ./perl/lib/Netscape and generate Makefile.PL
print "Makefile.PL: entering ./perl/lib/Netscape\n";
chdir '../perl/lib/Netscape' or
    die "Makefile.PL: couldn't chdir to ./perl/lib/Netscape: $!\n";
MF_perl_ext($ns_server_root, $ns_inst_dir, $os, $ns_defines, $ns_inc_dir);

print <<EOM;
See the INSTALL file for further instructions.  Please Contact
Ben Sugars (bsugars\@canoe.ca) in the event of success/failure.

Good Luck!
EOM

exit(0);

##===============================================================
## 
## MF_nsapi_perl():
##
##	This subroutine generates the Makefile.PL for the nsapi_perl
##	plugin.
##
##===============================================================

sub MF_nsapi_perl
{
my($ns_server_root, $ns_inst_dir, $os, $ns_defines, $ns_inc_dir) = @_;

my $OTHERLDFLAGS;

##-- If we need to in the future have &MF_nsapi_perl rework
##-- $ns_defines, that should happen here.  For now, we just
##-- take it as is.
##XXX prompt for PERL_TRACE
my $DEFINES = $ns_defines . " -D PERL_TRACE";

##-- MSWin32 specific compile options
if($os eq 'MSWin32') {
	$OTHERLDFLAGS = "$ns_server_root/nsapi/examples/libhttpd.lib";
	}
##-- Unix compile options
else {
	$OTHERLDFLAGS = "$Config{ccdlflags} -L$Config{archlib}/CORE $Config{libs} -lperl $Config{archlib}/auto/DynaLoader/DynaLoader.a";
}

##-- start Makefile.PL generation
local(*FH);
open(FH, ">Makefile.PL") || die $!;

print "Creating Makefile.PL for nsapi_perl\n\n";

##---------------------------------------------------------------
##
## Makefile.PL static section #1
##
## Ticks around here-document delimeter will cause perl to
## qoute the here-document text without variable interpolation.
##
##---------------------------------------------------------------
print FH <<'EOM';
# Makefile.PL for nsapi_perl
BEGIN { $^W = 1 }
BEGIN { require 5.004 }
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Embed;
use Config;

# Create xsinit.c
print "Makefile.PL: creating xsinit.c\n";
xsinit("xsinit.c");

EOM

##---------------------------------------------------------------
##
## Makefile.PL dynamic section
##
## Variable interpolation takes place in this here docuemnt.
##
##---------------------------------------------------------------
print FH <<EOM;
my \$ns_server_root = "$ns_server_root";
my \$ns_inst_dir = "$ns_inst_dir";
my \$ns_inc_dir = "$ns_inc_dir";

# options for MakeMaker
my \%opts = ();
\$opts{DEFINE} = "$DEFINES";
\$opts{dynamic_lib} = {
	OTHERLDFLAGS => "$OTHERLDFLAGS"
	};
EOM

##---------------------------------------------------------------
##
## Makefile.PL static section #2
##
## Ticks around here-document delimeter will cause perl to
## qoute the here-document text without variable interpolation.
##
##---------------------------------------------------------------
print FH <<'EOM';
$opts{NAME} = 'nsapi_perl';
$opts{OBJECT} = '$(O_FILES)';
$opts{INC} = "-I$ns_inc_dir";

# create the Makefile
WriteMakefile(%opts);

exit(0);

# override install section in Makefile
sub MY::install
{
   "
install :: all
	\$(CP) \$(INST_ARCHAUTODIR)/\$(BASEEXT).\$(DLEXT) $ns_inst_dir/.
	\$(CP) nsapi_perl_init.pl $ns_inst_dir/.
";
}

# override dlsyms section in Makefile
sub MY::dlsyms
{
	"
\$(EXPORT_LIST):
	\$(TOUCH) \$(EXPORT_LIST)
";
}
EOM

##-- end Makefile.PL generation

close(FH);
}

##===============================================================
## 
## MF_perl_ext():
##
##	This subroutine generates the Makefile.PL for the Netscape
##	perl extension.
##
##===============================================================

sub MF_perl_ext
{
my($ns_server_root, $ns_inst_dir, $os, $ns_defines, $ns_inc_dir) = @_;

print "Creating Makefile.PL for Netscape perl extension\n\n";

my $OTHERLDFLAGS;

##-- If we need to in the future have &MF_perl_ext rework
##-- $ns_defines, that should happen here.  For now, we just
##-- take it as is.
my $DEFINES = $ns_defines;

##-- MSWin32 specific compile options
if($os eq 'MSWin32') {
	$OTHERLDFLAGS = "$ns_server_root/nsapi/examples/libhttpd.lib";
	$OTHERLDFLAGS .= " ../../../nsapi/blib/arch/auto/nsapi_perl/nsapi_perl.lib";
	}
##-- Unix compile options
else {
	$OTHERLDFLAGS = "$Config{ccdlflags} -L$Config{archlib}/CORE $Config{libs} -lperl";
	$OTHERLDFLAGS .= " ../../../nsapi/nsapi_perl.o ../../../nsapi/xsinit.o";
	$OTHERLDFLAGS .= " $Config{archlib}/auto/DynaLoader/DynaLoader.a";
	}
##-- Untested operating systems

##-- start Makefile.PL generation
local(*FH);
open(FH, ">Makefile.PL") || die $!;

##---------------------------------------------------------------
##
## Makefile.PL static section #1
##
## Ticks around here-document delimeter will cause perl to
## qoute the here-document text without variable interpolation.
##
##---------------------------------------------------------------
print FH <<'EOM';
# Makefile.PL for perl Netscape Extension
BEGIN { $^W = 1 }
BEGIN { require 5.004 }
use strict;
use ExtUtils::MakeMaker;
use Config;

EOM

##---------------------------------------------------------------
##
## Makefile.PL dynamic section #1
##
## Variable interpolation takes place in this here docuemnt.
##
##---------------------------------------------------------------
print FH <<EOM;
my \$ns_server_root = "$ns_server_root";
my \$ns_inst_dir = "$ns_inst_dir";
my \$ns_inc_dir = "$ns_inc_dir";

# options for MakeMaker
my \%opts = ();
\$opts{DEFINE} = "$DEFINES";
\$opts{dynamic_lib} = {
	OTHERLDFLAGS => "$OTHERLDFLAGS"
	};
EOM

##---------------------------------------------------------------
##
## Makefile.PL static section #2
##
## Ticks around here-document delimeter will cause perl to
## qoute the here-document text without variable interpolation.
##
##---------------------------------------------------------------
print FH <<'EOM';
$opts{NAME} = 'Netscape::Server';
$opts{VERSION_FROM} = 'Server.pm';
$opts{OBJECT} = '$(O_FILES)';
$opts{INC} = "-I$ns_inc_dir -I../../../nsapi";
$opts{PMLIBDIRS} = [qw(Server eg)];

# Create the Makefile
WriteMakefile(%opts);

exit(0);
EOM

##-- end Makefile.PL generation

close(FH);
}
