/* -------------------------------------------------------------------
    Server.xs - Perl extension to integrate Netscape web server

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

#ifdef __cplusplus
extern "C" {
#endif
#include "base/util.h"
#include "base/pblock.h"
#include "base/session.h"
#include "base/cinfo.h"
#include "frame/http.h"
#include "frame/req.h"
#include "frame/protocol.h"
#include "frame/log.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "nsapi_perl.h"
#ifdef __cplusplus
}
#endif

static int
not_here(s)
     char *s;
{
  croak("%s not implemented on this architecture", s);
  return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
  errno = 0;
  switch (*name) {
  case 'L':
    if (strEQ(name, "LOG_CATASTROPHE"))
#ifdef LOG_CATASTROPHE
      return LOG_CATASTROPHE;
#else
    goto not_there;
#endif
    if (strEQ(name, "LOG_FAILURE"))
#ifdef LOG_FAILURE
      return LOG_FAILURE;
#else
    goto not_there;
#endif
    if (strEQ(name, "LOG_INFORM"))
#ifdef LOG_INFORM
      return LOG_INFORM;
#else
    goto not_there;
#endif
    if (strEQ(name, "LOG_MISCONFIG"))
#ifdef LOG_MISCONFIG
      return LOG_MISCONFIG;
#else
    goto not_there;
#endif
    if (strEQ(name, "LOG_SECURITY"))
#ifdef LOG_SECURITY
      return LOG_SECURITY;
#else
    goto not_there;
#endif
    if (strEQ(name, "LOG_WARN"))
#ifdef LOG_WARN
      return LOG_WARN;
#else
    goto not_there;
#endif
    break;
  case 'P':
    if (strEQ(name, "PROTOCOL_BAD_REQUEST"))
#ifdef PROTOCOL_BAD_REQUEST
      return PROTOCOL_BAD_REQUEST;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_FORBIDDEN"))
#ifdef PROTOCOL_FORBIDDEN
      return PROTOCOL_FORBIDDEN;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_NOT_FOUND"))
#ifdef PROTOCOL_NOT_FOUND
      return PROTOCOL_NOT_FOUND;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_NOT_IMPLEMENTED"))
#ifdef PROTOCOL_NOT_IMPLEMENTED
      return PROTOCOL_NOT_IMPLEMENTED;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_NOT_MODIFIED"))
#ifdef PROTOCOL_NOT_MODIFIED
      return PROTOCOL_NOT_MODIFIED;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_NO_RESPONSE"))
#ifdef PROTOCOL_NO_RESPONSE
      return PROTOCOL_NO_RESPONSE;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_OK"))
#ifdef PROTOCOL_OK
      return PROTOCOL_OK;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_PROXY_UNAUTHORIZED"))
#ifdef PROTOCOL_PROXY_UNAUTHORIZED
      return PROTOCOL_PROXY_UNAUTHORIZED;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_REDIRECT"))
#ifdef PROTOCOL_REDIRECT
      return PROTOCOL_REDIRECT;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_SERVER_ERROR"))
#ifdef PROTOCOL_SERVER_ERROR
      return PROTOCOL_SERVER_ERROR;
#else
    goto not_there;
#endif
    if (strEQ(name, "PROTOCOL_UNAUTHORIZED"))
#ifdef PROTOCOL_UNAUTHORIZED
      return PROTOCOL_UNAUTHORIZED;
#else
    goto not_there;
#endif
    break;
  case 'R':
    if (strEQ(name, "REQ_ABORTED"))
#ifdef REQ_ABORTED
      return REQ_ABORTED;
#else
    goto not_there;
#endif
    if (strEQ(name, "REQ_EXIT"))
#ifdef REQ_EXIT
      return REQ_EXIT;
#else
    goto not_there;
#endif
    if (strEQ(name, "REQ_NOACTION"))
#ifdef REQ_NOACTION
      return REQ_NOACTION;
#else
    goto not_there;
#endif
    if (strEQ(name, "REQ_PROCEED"))
#ifdef REQ_PROCEED
      return REQ_PROCEED;
#else
    goto not_there;
#endif
    break;
  }
  errno = EINVAL;
  return 0;
  
 not_there:
  errno = ENOENT;
  return 0;
}

char* pblock_access(pblock *pb, char* name, char* value) {
  char *current_value;
  pb_param *pp;
  /* Get or set the value in the provided pblock */
  if (value == NULL) {
    /* Return the value */
    value = pblock_findval(name, pb);
  }
  else {
    /* Find and replace the value */
    current_value = pblock_findval(name, pb);
    if (current_value == NULL) {
      /* Value isn't there, so add it */
      pblock_nvinsert(name, value, pb);
    } else {
      pp = pblock_find(name, pb);
      FREE(pp->value);
      pp->value = STRDUP(value);
    }
  }
  
  return value;
}

MODULE = Netscape::Server		PACKAGE = Netscape::Server

 # These functions implement Netscape::Server functions

double
constant(name, arg)
     char * name
     int arg

void
log_error(degree, sub, session, request, gripe)
     int degree
     char* sub
     Session* session
     Request* request
     char* gripe
   PREINIT:
     int success;
   PPCODE:
     success = log_error(degree, sub, session, request, gripe);
     if (success) {
       PUSHs(sv_2mortal(newSViv(success)));
     } else {
       PUSHs(sv_2mortal(newSVsv(&sv_undef)));
     }

MODULE = Netscape::Server		PACKAGE = Netscape::Server::Session

 # These functions implement Netscape::Server::Session
 # methods that return your common CGI variables

void
remote_addr(session)
     Session* session
   INIT:
     char* remote_addr;
   PPCODE:
     remote_addr = pblock_findval("ip", session->client);
     remote_addr == NULL ? XSRETURN_UNDEF : XSRETURN_PV(remote_addr);

void
remote_host(session)
     Session* session
   INIT:
     char* remote_host;
   PPCODE:
     remote_host = session_maxdns(session);
     remote_host == NULL ? XSRETURN_UNDEF : XSRETURN_PV(remote_host);

 # These methods implement some standard NSAPI functions that
 # expect a Session* to be passed to them

void
protocol_status(session, request, status, reason=NULL)
     Request* request
     Session* session
     int status
     char* reason

int
protocol_start_response(session, request)
     Request* request
     Session* session

int
net_write(session, message)
     Session* session
     char* message
   CODE:
     RETVAL = net_write(session->csd, message, strlen(message));
   OUTPUT:
     RETVAL
     

MODULE = Netscape::Server		PACKAGE = Netscape::Server::Request	

 # These functions implement Netscape::Server::Request
 # methods that return your common CGI variables

void
auth_type(request, auth_type=NULL)
     Request* request
     char* auth_type
   PPCODE:
     auth_type = pblock_access(request->vars, "auth-type", auth_type);
     auth_type == NULL ? XSRETURN_UNDEF : XSRETURN_PV(auth_type);

void
path_info(request, path_info=NULL)
     Request* request
     char* path_info
   PPCODE:
     path_info = pblock_access(request->headers, "path-info", path_info);
     path_info == NULL ? XSRETURN_UNDEF : XSRETURN_PV(path_info);

void
query_string(request, query_string=NULL)
     Request* request
     char* query_string
   PPCODE:
     query_string = pblock_access(request->vars, "query", query_string);
     query_string == NULL ? XSRETURN_UNDEF : XSRETURN_PV(query_string);

void
remote_user(request, remote_user=NULL)
     Request* request
     char* remote_user
   PPCODE:
     remote_user = pblock_access(request->headers, "auth-user", remote_user);
     remote_user == NULL ? XSRETURN_UNDEF : XSRETURN_PV(remote_user);

void
request_method(request, request_method=NULL)
     Request* request
     char* request_method
   PPCODE:
     request_method = pblock_access(request->reqpb, "method", request_method);
     request_method == NULL ? XSRETURN_UNDEF : XSRETURN_PV(request_method);

void
server_protocol(request, server_protocol=NULL)
     Request* request
     char* server_protocol
   PPCODE:
     server_protocol = pblock_access(request->reqpb, "protocol", server_protocol);
     server_protocol == NULL ? XSRETURN_UNDEF : XSRETURN_PV(server_protocol);

void
user_agent(request, user_agent=NULL)
     Request* request
     char* user_agent
   PPCODE:
     user_agent = pblock_access(request->headers, "user-agent", user_agent);
     user_agent == NULL ? XSRETURN_UNDEF : XSRETURN_PV(user_agent);


 # These methods implement some standard NSAPI functions that
 # expect a Request* to be passed to them

void
protocol_status(request, session, status, reason=NULL)
     Request* request
     Session* session
     int status
     char* reason
   CODE:
     protocol_status(session, request, status, reason);

int
protocol_start_response(request, session)
     Request* request
     Session* session
   CODE:
     RETVAL = protocol_start_response(session, request);
   OUTPUT:
     RETVAL

 # These functions implement methods used to access properties
 # of the request object

void
vars(request, key=NULL, value=NULL)
     Request* request
     char* key
     char* value
   PREINIT:
     SV* hash_ref;
   PPCODE:
     if (items == 1) {
 # Return a ref to the whole hash
       hash_ref = nsapi_perl_pblock2hash_ref(request->vars);
       XPUSHs(hash_ref);
       XSRETURN(1);
     }
     else if (items == 2 || items == 3) {
       value = pblock_access(request->vars, key, value); 
       value == NULL ? XSRETURN_UNDEF : XSRETURN_PV(value);
     }

void
reqpb(request, key=NULL, value=NULL)
     Request* request
     char* key
     char* value
   PREINIT:
     SV* hash_ref;
   PPCODE:
     if (items == 1) {
 # Return a ref to the whole hash
       hash_ref = nsapi_perl_pblock2hash_ref(request->reqpb);
       XPUSHs(hash_ref);
       XSRETURN(1);
     }
     else if (items == 2 || items == 3) {
       value = pblock_access(request->reqpb, key, value); 
       value == NULL ? XSRETURN_UNDEF : XSRETURN_PV(value);
     }

void
headers(request, key=NULL, value=NULL)
     Request* request
     char* key
     char* value
   PREINIT:
     SV* hash_ref;
   PPCODE:
     if (items == 1) {
 # Return a ref to the whole hash
       hash_ref = nsapi_perl_pblock2hash_ref(request->headers);
       XPUSHs(hash_ref);
       XSRETURN(1);
     }
     else if (items == 2 || items == 3) {
       value = pblock_access(request->headers, key, value); 
       value == NULL ? XSRETURN_UNDEF : XSRETURN_PV(value);
     }

void
srvhdrs(request, key=NULL, value=NULL)
     Request* request
     char* key
     char* value
   PREINIT:
     SV* hash_ref;
   PPCODE:
     if (items == 1) {
 # Return a ref to the whole hash
       hash_ref = nsapi_perl_pblock2hash_ref(request->srvhdrs);
       XPUSHs(hash_ref);
       XSRETURN(1);
     }
     else if (items == 2 || items == 3) {
 # Return or set the named value
       value = pblock_access(request->srvhdrs, key, value); 
       value == NULL ? XSRETURN_UNDEF : XSRETURN_PV(value);
     }

