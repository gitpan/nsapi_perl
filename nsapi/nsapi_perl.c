/* -------------------------------------------------------------------
    nsapi_perl.c - embed Perl interpreter in a Netscape web server

    Copyright (C) 1997 Benjamin Sugars

    This is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.
 
    This software is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
 
    You should have received a copy of the GNU General Public License
    along with this software. If not, write to the Free Software
    Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
------------------------------------------------------------------- */

#include "base/util.h"
#include "base/pblock.h"
#include "base/session.h"
#include "base/cinfo.h"
#include "frame/req.h"
#include "frame/log.h"
#include <EXTERN.h>
#include <perl.h>
#include <string.h>
#include "nsapi_perl.h"

static PerlInterpreter *nsapi_perl;     /* The perl interpreter */

NSAPI_PUBLIC int nsapi_perl_init(pblock * pb, Session * sn, Request * rq)
{
    char *conf;
    char *perl_argv[2];
    SV *perl_version;
    int exitstatus = 0;

    /* Find the location of the config file */
    conf = pblock_findval("conf", pb);

    /* Construct an argv for perl to parse */
    perl_argv[0] = (char *) MALLOC(strlen("perl") + 1);
    perl_argv[1] = (char *) MALLOC(strlen(conf) + 1);
    util_sprintf(perl_argv[0], "perl");
    util_sprintf(perl_argv[1], conf);

    /* Initialise the perl interpreter */
    nsapi_perl = perl_alloc();
    perl_construct(nsapi_perl);

    /* Parse and run the configuration file */
    exitstatus = perl_parse(nsapi_perl, xs_init, 2, perl_argv, NULL);
    if (exitstatus) {
        fprintf(stderr, "nsapi_perl_init: Yikes! problem compiling %s\n", conf);
        log_error(LOG_CATASTROPHE, "nsapi_perl_init", sn, rq, "trouble compiling %s", conf);
        return REQ_ABORTED;
    }
    exitstatus = perl_run(nsapi_perl);
    if (exitstatus) {
        fprintf(stderr, "nsapi_perl_init: Yikes! problem running %s\n", conf);
        log_error(LOG_CATASTROPHE, "nsapi_perl_init", sn, rq, "trouble running %s", conf);
        return REQ_ABORTED;
    }
    /* Get the version of the perl interpreter */
    perl_version = perl_get_sv("main::]", FALSE);

    /* Looks good.  Print out a progress message */
    log_error(LOG_INFORM, "nsapi_perl_init", sn, rq, "loaded a perl version %s interpreter", SvPV(perl_version, na));
    fprintf(stderr, "nsapi_perl_init: loaded a perl version %s interpreter\n", SvPV(perl_version, na));
    return REQ_PROCEED;
}

NSAPI_PUBLIC int nsapi_perl_handler(pblock * pb, Session * sn, Request * rq)
{
    char *module, *sub, *handler;
    I32 response;
    SV *request = sv_newmortal();
    SV *session = sv_newmortal();
    SV *pblock;

    /* Enter a new perl scope */
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);

    /* Get the name of the perl module */
    module = pblock_findval("module", pb);
    if (module == NULL) {
        log_error(LOG_MISCONFIG, "nsapi_perl_handler", sn, rq, "no module argument specified");
        return REQ_ABORTED;
    }
    /* Get the name of perl subroutine to call */
    sub = pblock_findval("sub", pb);
    if (sub == NULL) {
        sub = "handler";
    }
    /* Create the fully qualified subroutine name */
    handler = (char *) MALLOC(strlen(module) + strlen(sub) + 1);
    util_sprintf(handler, "%s::%s", module, sub);

    /* Create the Request and Session objects */
    request = nsapi_perl_bless_request(rq);
    session = nsapi_perl_bless_session(sn);

    /* Create the pb hash table */
    pblock = nsapi_perl_pblock2hash_ref(pb);

    /* Call the sucker */
    XPUSHs(pblock);
    XPUSHs(session);
    XPUSHs(request);
    PUTBACK;
    perl_call_pv(handler, G_SCALAR);
    SPAGAIN;

    /* Pop the return value from the stack */
    response = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;

    /* Clean up */
    FREE(handler);

    /* Done */
    return (response);
}

SV *
 nsapi_perl_bless_request(Request * rq)
{
    SV *request = sv_newmortal();
    sv_setref_iv(request, "Netscape::Server::Request", (IV) rq);
    return (request);
}

SV *
 nsapi_perl_bless_session(Session * sn)
{
    SV *session = sv_newmortal();
    sv_setref_iv(session, "Netscape::Server::Session", (IV) sn);
    return (session);
}

SV *
 nsapi_perl_pblock2hash_ref(pblock * pb)
{
    char *key;
    char **pblock_contents;
    HV *pblock;
    SV *value, *pblock_ref;
    int i;

    /* Mortalize the pblock hash */
    pblock = newHV();
    sv_2mortal((SV *) pblock);

    /* Shove the pb into an array of strings */
    pblock_contents = pblock_pb2env(pb, NULL);

    /* Loop through each string in pblock_contents */
    for (; *pblock_contents != NULL; ++pblock_contents) {
        key = MALLOC(strlen(*pblock_contents));

        /* Look for an '=' sign in the string */
        i = 0;
        while (*(*pblock_contents + i) != '=')
            ++i;

        /* Split on the '=' */
        *(*pblock_contents + i) = '\0';
        key = *pblock_contents;
        value = sv_newmortal();
        sv_setpv(value, *pblock_contents + i + 1);

        /* Store the key/value pair */
        hv_store(pblock, key, strlen(key), value, 0);

        /* Increment the reference count of the hash elements */
        SvREFCNT_inc(value);
    }

    /* Create the reference to the hash */
    pblock_ref = newRV_noinc((SV *) pblock);
    return (pblock_ref);
}
