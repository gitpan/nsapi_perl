# --- Makefile.PL for nsapi_perl
use Config;

# Sorry about the boneheaded Makefile.PL script.  The reason this is
# not as simple as it should be is that there are two different systems
# (Perl and your Netscape Server) that have been built in two very
# different ways.

# This script therefore creates two separate Makefiles.  One compiles,
# links and installs the nsapi_perl.c NSAPI function.  This Makefile
# will be written to ./nsapi.

# The other Makefile is a more typical Perl XS Makefile as produced by
# ExtUtils::MakeMaker.  This one is written to ./perl/lib/Netscape.

# Before running this script, you should double check the values in
# the configuration section below.  The ones most like to need
# changing to reflect your local environment are:
#       $ld             - the linker command to produce *.so files
#       $ns_server_root - the location of your Netscape server
#       $nsapi_ccopts   - cc options for building NSAPI functions on
#                         your system

# If you create a more elegant and intuitive Makefile.PL, let me know
# and you will be the subject of great praise!

# -Ben Sugars
# <bsugars@canoe.ca>
# November 13, 1997

# ----------------------------------------------------------------------
# --- Configuration section
# ----------------------------------------------------------------------

#  This section defines arguments for compiling and linking your code.
#  The default behaviour is to pull these values out of the Config.pm
#  module.

#  $cc is the cc comand used to compile Perl.
$cc = $Config{cc};


#  $ld is the command you wish to use to link your objects and create
#  a shared object file.  THIS MAY NOT BE THE SAME AS THAT USED TO
#  BUILD PERL... it should probably be the same as that used when
#  linking NSAPI functions.
$ld = $Config{ld};


#  $perl_ccopts are the arguments to cc when perl was built.
$perl_ccopts    = "$Config{ccflags} -I$Config{archlib}/CORE";


#  $perl_ldlibs are the extra libraries perl was linked against
$perl_ldlibs    = "$Config{libs}";


#  $perl_ldopts are the arguments to $ld when perl was linked
$perl_ldopts    = "$Config{ccdlflags} -L$Config{archlib}/CORE $perl_ldlibs";


#  $perl_lib is just a string identifying libperl.so.  This string will
#  be passed as an argument to all subsequent linking commands. You can
#  probably leave this alone and not do any harm
$perl_lib       =  '-lperl';


#  $perl_dynalib is the path to the Perl DynaLoader library. 
$perl_dynalib   = "$Config{archlib}/auto/DynaLoader/DynaLoader.a";


# $man3ext is the filename suffix on library man pages
$man3ext        = $Config{man3ext};



#  $ns_server_root is the root directory of your netscape server
#  (the directory that contains https-* and nsapi as subdirectories.
$ns_server_root = '/usr/local/suitespot';


#  $ns_inc_dir is the directory containing the NSAPI header files.
$ns_inc_dir     = "$ns_server_root/include";


#  $nsapi_ccopts are the arguments cc expects when compiling NSAPI
#  functions.  The values shown here work for Enterprise 3.x servers
#  on Solaris.  For other operating systems, consult the Makefile in
#  $ns_server_root/nsapi/examples.
$nsapi_ccopts   = "-DNET_SSL -DSOLARIS -D_REENTRANT -DMCC_HTTPD -DXP_UNIX -DSPAPI20 -Wall";


#  $ns_inst_dir is the final location for the nsapi_perl.so to
#  be installed.
$ns_inst_dir    = "$ns_server_root/lib";



# ----------------------------------------------------------------------
# --- END OF CONFIGURATION SECTION
# ----------------------------------------------------------------------

print "Creating nsapi_perl Makefiles for NSAPI and Perl extensions.\n\n";

# --- Exension module section
print "Makefile.PL: entering ./perl/lib/Netscape\n";
chdir './perl/lib/Netscape' or
    die "Makefile.PL: couldn't chdir to ./perl/lib/Netscape\n";
use ExtUtils::MakeMaker;
print "Makefile.PL: creating ./perl/lib/Netscape/Makefile\n";
WriteMakefile(
	      'CC' => "$cc $nsapi_ccopts",
	      'INC' => "-I$ns_inc_dir -I$ns_inc_dir/frame -I$ns_inc_dir/base -I../../../nsapi -I$Config{archlib}/CORE",
	      'NAME'	=> 'Netscape::Server',
	      'LIBS'	=> [$perl_lib],
	      'LD' => $ld,
	      'LDDLFLAGS' => "$perl_ldopts $perl_lib ../../../nsapi/nsapi_perl.o ../../../nsapi/xsinit.o $perl_dynalib",
	      'VERSION' => '0.10',
);

# --- NSAPI C code section
print "Makefile.PL: leaving ./perl/lib/Netscape\n";
chdir '../../..' or
    die "Makefile.PL: couldn't leave ./perl/lib\n";
print "Makefile.PL: entering ./nsapi\n";
chdir './nsapi' or
    die "Makefile.PL: couldn't chdir to ./nsapi\n";

# --- Create xsinit.c
print "Makefile.PL: creating ./nsapi/xsinit.c\n";
$command = 'perl -MExtUtils::Embed -e xsinit -- -o xsinit.c';
system $command and do {
    warn "Makefile.PL: trouble creating ./nsapi/xinit.c\n";
    die "Makefile.Pl: '$command' had exit status $?\n";
};

# --- Make the NSAPI Makefile
if (-e 'Makefile') {
    rename 'Makefile', 'Makefile.old'
	or die "Makefile.PL: couldn't create backup of ./nsapi/Makefile: $!\n";
}
open(MAKEFILE, '>Makefile') or
    die "Makefile.PL: couldn't create ./nsapi/Makefile: $!\n";

print "Makefile.PL: creating ./nsapi/Makefile\n";

print MAKEFILE <<"__END_OF_MAKEFILE__";
# --- Makefile generated by Makefile.PL (But not by MakeMaker!!!)

# --- Commands
CC=$cc
LD=$ld

# --- NSAPI Compilation flags
NSAPI_CCOPTS=$nsapi_ccopts -I$ns_inc_dir -I$ns_inc_dir/base -I$ns_inc_dir/frame

# --- Perl compilation flags
PERL_CCOPTS=$perl_ccopts
PERL_LDOPTS=$perl_ldopts

# --- List of object files to compile
OBJS = nsapi_perl.o xsinit.o

# --- Targets
nsapi_perl.so: \$(OBJS)
	\$(LD) \$(PERL_LDOPTS) $perl_lib \$(OBJS) $perl_dynalib -o nsapi_perl.so

%.o : %.c
	\$(CC) \$(NSAPI_CCOPTS) \$(PERL_CCOPTS) -c \$<

all:	nsapi_perl.so

clean:
	rm -f \$(OBJS) xsinit.c nsapi_perl.so

realclean:
	rm -f \$(OBJS) nsapi_perl.so Makefile Makefile.old

install: nsapi_perl.so
	cp nsapi_perl.so $ns_inst_dir  
	cp ../conf/nsapi_perl.conf $ns_inst_dir  
	\@echo "insert the following lines in magnus.conf or obj.conf to load Perl into your Netscape server:" 
	\@echo "Init fn=load-modules shlib=$ns_inst_dir/nsapi_perl.so funcs=nsapi_perl_init,nsapi_perl_handler" 
	\@echo "Init fn=nsapi_perl_init conf=$ns_inst_dir/nsapi_perl.conf"
__END_OF_MAKEFILE__

print "\nDone creating Makefiles.\n";
print "It's a good idea to look at ./nsapi/Makefile\n";
print "and ./perl/lib/Netscape/Makefile to see if they look right.\n";


exit;

#sub MY::manifypods {
#    package MY;
#    # --- Coerces Makefile into producing the man pages
#    my $inherited = shift->SUPER::manifypods(@_);
#    $inherited .= "\\\n\tpod/nsapi_perl.pod \\\n\t\$(INST_MAN3DIR)/nsapi_perl.\$(MAN3EXT)";
#    $inherited;
#}
