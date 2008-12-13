/*
 * Copyright (c) 2009 Miek Gieben
 * See LICENSE for the license
 */

#include "rdup-up.h"

void
usage_up(FILE *f)
{
        fprintf(f, _("USAGE: %s [OPTION]... \n"), PROGNAME);
	fputs( _("\
Pietje\n\
format: \'%p%T %b %u %g %l %s %n\\n\'.\n\
\n\
\n\
    OPTIONS:\n\
        -c\t\tforce output to tty\n\
        -Pcmd,opt1,...,opt7\n\
	    \t\tfilter through cmd\n\
	\t\tthis may be repeated, output will be filtered\n\
	\t\tthrough all commands\n\
	-h\t\tthis help\n\
	-V\t\tprint version\n\
        -Ofmt\t\toutput format: pax, cpio, tar or rdup\n\
	\t\trdup uses format: \"%p%T %b %u %g %l %s\\n%n%C\"\n\
	-L\t\tset input format to a list of pathnames\n\
	-v\t\tbe more verbose and print process files to stderr\n\
\n\
Report bugs to <miek@miek.nl>\n\
Licensed under the GPL version 3.\n\
See the file LICENSE in the source distribution of rdup.\n"), f);
}