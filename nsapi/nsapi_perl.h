/* -------------------------------------------------------------------
    nsapi_perl.c - header file for nsapi_perl

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

/* Some versions of Netscape servers need this defined.  */
#ifndef NSAPI_PUBLIC
#define NSAPI_PUBLIC
#endif

/* Function prototypes */
void xs_init _((void));
SV *nsapi_perl_bless_request(Request *);
SV *nsapi_perl_bless_session(Session *);
SV *nsapi_perl_pblock2hash_ref(pblock *);
