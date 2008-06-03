/* (N)compress42.c - File compression ala IEEE Computer, Mar 1992.
 *
 * Authors:
 *   Spencer W. Thomas   (decvax!harpo!utah-cs!utah-gr!thomas)
 *   Jim McKie           (decvax!mcvax!jim)
 *   Steve Davies        (decvax!vax135!petsd!peora!srd)
 *   Ken Turkowski       (decvax!decwrl!turtlevax!ken)
 *   James A. Woods      (decvax!ihnp4!ames!jaw)
 *   Joe Orost           (decvax!vax135!petsd!joe)
 *   Dave Mack           (csu@alembic.acs.com)
 *   Peter Jannesen, Network Communication Systems
 *                       (peter@ncs.nl)
 *
 * Revision unlabelled: 04/10/12 cowtan@ysbl.york.ac.uk
 *   Reduce to minimal subset for slow decompression.
 *
 * Revision 4.2.3  92/03/14 peter@ncs.nl
 *   Optimise compress and decompress function and a lot of cleanups.
 *   New fast hash algoritme added (if more than 800Kb available).
 *
 * Revision 4.1  91/05/26 csu@alembic.acs.com
 *   Modified to recursively compress directories ('r' flag). As a side
 *   effect, compress will no longer attempt to compress things that
 *   aren't "regular" files. See Changes.
 *
 * Revision 4.0  85/07/30  12:50:00  joe
 *   Removed ferror() calls in output routine on every output except first.
 *   Prepared for release to the world.
 * 
 * Revision 3.6  85/07/04  01:22:21  joe
 *   Remove much wasted storage by overlaying hash table with the tables
 *   used by decompress: tab_suffix[1<<BITS], stack[8000].  Updated USERMEM
 *   computations.  Fixed dump_tab() DEBUG routine.
 *
 * Revision 3.5  85/06/30  20:47:21  jaw
 *   Change hash function to use exclusive-or.  Rip out hash cache.  These
 *   speedups render the megamemory version defunct, for now.  Make decoder
 *   stack global.  Parts of the RCS trunks 2.7, 2.6, and 2.1 no longer apply.
 *
 * Revision 3.4  85/06/27  12:00:00  ken
 *   Get rid of all floating-point calculations by doing all compression ratio
 *   calculations in fixed point.
 *
 * Revision 3.3  85/06/24  21:53:24  joe
 *   Incorporate portability suggestion for M_XENIX.  Got rid of text on #else
 *   and #endif lines.  Cleaned up #ifdefs for vax and interdata.
 *
 * Revision 3.2  85/06/06  21:53:24  jaw
 *   Incorporate portability suggestions for Z8000, IBM PC/XT from mailing list.
 *   Default to "quiet" output (no compression statistics).
 *
 * Revision 3.1  85/05/12  18:56:13  jaw
 *   Integrate decompress() stack speedups (from early pointer mods by McKie).
 *   Repair multi-file USERMEM gaffe.  Unify 'force' flags to mimic semantics
 *   of SVR2 'pack'.  Streamline block-compress table clear logic.  Increase 
 *   output byte count by magic number size.
 * 
 * Revision 3.0   84/11/27  11:50:00  petsd!joe
 *   Set HSIZE depending on BITS.  Set BITS depending on USERMEM.  Unrolled
 *   loops in clear routines.  Added "-C" flag for 2.0 compatibility.  Used
 *   unsigned compares on Perkin-Elmer.  Fixed foreground check.
 *
 * Revision 2.7   84/11/16  19:35:39  ames!jaw
 *   Cache common hash codes based on input statistics; this improves
 *   performance for low-density raster images.  Pass on #ifdef bundle
 *   from Turkowski.
 *
 * Revision 2.6   84/11/05  19:18:21  ames!jaw
 *   Vary size of hash tables to reduce time for small files.
 *   Tune PDP-11 hash function.
 *
 * Revision 2.5   84/10/30  20:15:14  ames!jaw
 *   Junk chaining; replace with the simpler (and, on the VAX, faster)
 *   double hashing, discussed within.  Make block compression standard.
 *
 * Revision 2.4   84/10/16  11:11:11  ames!jaw
 *   Introduce adaptive reset for block compression, to boost the rate
 *   another several percent.  (See mailing list notes.)
 *
 * Revision 2.3   84/09/22  22:00:00  petsd!joe
 *   Implemented "-B" block compress.  Implemented REVERSE sorting of tab_next.
 *   Bug fix for last bits.  Changed fwrite to putchar loop everywhere.
 *
 * Revision 2.2   84/09/18  14:12:21  ames!jaw
 *   Fold in news changes, small machine typedef from thomas,
 *   #ifdef interdata from joe.
 *
 * Revision 2.1   84/09/10  12:34:56  ames!jaw
 *   Configured fast table lookup for 32-bit machines.
 *   This cuts user time in half for b <= FBITS, and is useful for news batching
 *   from VAX to PDP sites.  Also sped up decompress() [fwrite->putc] and
 *   added signal catcher [plus beef in write_error()] to delete effluvia.
 *
 * Revision 2.0   84/08/28  22:00:00  petsd!joe
 *   Add check for foreground before prompting user.  Insert maxbits into
 *   compressed file.  Force file being uncompressed to end with ".Z".
 *   Added "-c" flag and "zcat".  Prepared for release.
 *
 * Revision 1.10  84/08/24  18:28:00  turtlevax!ken
 *   Will only compress regular files (no directories), added a magic number
 *   header (plus an undocumented -n flag to handle old files without headers),
 *   added -f flag to force overwriting of possibly existing destination file,
 *   otherwise the user is prompted for a response.  Will tack on a .Z to a
 *   filename if it doesn't have one when decompressing.  Will only replace
 *   file if it was compressed.
 *
 * Revision 1.9  84/08/16  17:28:00  turtlevax!ken
 *   Removed scanargs(), getopt(), added .Z extension and unlimited number of
 *   filenames to compress.  Flags may be clustered (-Ddvb12) or separated
 *   (-D -d -v -b 12), or combination thereof.  Modes and other status is
 *   copied with copystat().  -O bug for 4.2 seems to have disappeared with
 *   1.8.
 *
 * Revision 1.8  84/08/09  23:15:00  joe
 *   Made it compatible with vax version, installed jim's fixes/enhancements
 *
 * Revision 1.6  84/08/01  22:08:00  joe
 *   Sped up algorithm significantly by sorting the compress chain.
 *
 * Revision 1.5  84/07/13  13:11:00  srd
 *   Added C version of vax asm routines.  Changed structure to arrays to
 *   save much memory.  Do unsigned compares where possible (faster on
 *   Perkin-Elmer)
 *
 * Revision 1.4  84/07/05  03:11:11  thomas
 *   Clean up the code a little and lint it.  (Lint complains about all
 *   the regs used in the asm, but I'm not going to "fix" this.)
 *
 * Revision 1.3  84/07/05  02:06:54  thomas
 *   Minor fixes.
 *
 * Revision 1.2  84/07/05  00:27:27  thomas
 *   Add variable bit length output.
 *
 */
#include	<stdio.h>
#include	<fcntl.h>
#include	<ctype.h>
#include	<signal.h>
#include	<sys/types.h>
#include	<sys/stat.h>
#include	<errno.h>

#ifdef DIRENT
#	include	<dirent.h>
#	define	RECURSIVE		1
#	undef	SYSDIR
#endif
#ifdef SYSDIR
#	include	<sys/dir.h>
#	define	RECURSIVE		1
#endif
#ifdef UTIME_H
#	include	<utime.h>
#else
	struct utimbuf {
		time_t actime;
		time_t modtime;
	};
#endif

#ifdef	__STDC__
#	define	ARGS(a)				a
#else
#	define	ARGS(a)				()
#endif

#define	LARGS(a)	()	/* Relay on include files for libary func defs. */

#ifndef SIG_TYPE
#	define	SIG_TYPE	void (*)()
#endif

#define	MARK(a)	{ asm(" .globl M.a"); asm("M.a:"); }

#ifdef	DEF_ERRNO
	extern int	errno;
#endif

#undef	min
#define	min(a,b)	((a>b) ? b : a)

#ifndef	IBUFSIZ
#	define	IBUFSIZ	BUFSIZ	/* Defailt input buffer size							*/
#endif
#ifndef	OBUFSIZ
#	define	OBUFSIZ	BUFSIZ	/* Default output buffer size							*/
#endif

#define MAXPATHLEN 1024		/* MAXPATHLEN - maximum length of a pathname we allow 	*/
#define	SIZE_INNER_LOOP		256	/* Size of the inter (fast) compress loop			*/

							/* Defines for third byte of header 					*/
#define	MAGIC_1		(char_type)'\037'/* First byte of compressed file				*/
#define	MAGIC_2		(char_type)'\235'/* Second byte of compressed file				*/
#define BIT_MASK	0x1f			/* Mask for 'number of compresssion bits'		*/
									/* Masks 0x20 and 0x40 are free.  				*/
									/* I think 0x20 should mean that there is		*/
									/* a fourth header byte (for expansion).    	*/
#define BLOCK_MODE	0x80			/* Block compresssion if table is full and		*/
									/* compression rate is dropping flush tables	*/

			/* the next two codes should not be changed lightly, as they must not	*/
			/* lie within the contiguous general code space.						*/
#define FIRST	257					/* first free entry 							*/
#define	CLEAR	256					/* table clear output code 						*/

#define INIT_BITS 9			/* initial number of bits/code */

#ifndef SACREDMEM
	/*
 	 * SACREDMEM is the amount of physical memory saved for others; compress
 	 * will hog the rest.
 	 */
#	define SACREDMEM	0
#endif

#ifndef USERMEM
	/*
 	 * Set USERMEM to the maximum amount of physical user memory available
 	 * in bytes.  USERMEM is used to determine the maximum BITS that can be used
 	 * for compression.
	 */
#	define USERMEM 	450000	/* default user memory */
#endif

#ifndef	BYTEORDER
#	define	BYTEORDER	0000
#endif

#ifndef	NOALLIGN
#	define	NOALLIGN	0
#endif

/*
 * machine variants which require cc -Dmachine:  pdp11, z8000, DOS
 */

#ifndef	O_BINARY
#	define	O_BINARY	0	/* System has no binary mode							*/
#endif

#ifndef BITS		/* General processor calculate BITS								*/
#	if USERMEM >= (800000+SACREDMEM)
#		define FAST
#	else
#	if USERMEM >= (433484+SACREDMEM)
#		define BITS	16
#	else
#	if USERMEM >= (229600+SACREDMEM)
#		define BITS	15
#	else
#	if USERMEM >= (127536+SACREDMEM)
#		define BITS	14
#   else
#	if USERMEM >= (73464+SACREDMEM)
#		define BITS	13
#	else
#		define BITS	12
#	endif
#	endif
#   endif
#	endif
#	endif
#endif /* BITS */

#ifdef FAST
#	define	HBITS		17			/* 50% occupancy */
#	define	HSIZE	   (1<<HBITS)
#	define	HMASK	   (HSIZE-1)
#	define	BITS		   16
#	undef	MAXSEG_64K
#else
#	if BITS == 16
#		define HSIZE	69001		/* 95% occupancy */
#	endif
#	if BITS == 15
#		define HSIZE	35023		/* 94% occupancy */
#	endif
#	if BITS == 14
#		define HSIZE	18013		/* 91% occupancy */
#	endif
#	if BITS == 13
#		define HSIZE	9001		/* 91% occupancy */
#	endif
#	if BITS <= 12
#		define HSIZE	5003		/* 80% occupancy */
#	endif
#endif

#define CHECK_GAP 10000

typedef long int			code_int;

#ifdef SIGNED_COMPARE_SLOW
	typedef unsigned long int	count_int;
	typedef unsigned short int	count_short;
	typedef unsigned long int	cmp_code_int;	/* Cast to make compare faster	*/
#else
	typedef long int	 		count_int;
	typedef long int			cmp_code_int;
#endif

typedef	unsigned char	char_type;

#define ARGVAL() (*++(*argv) || (--argc && *++argv))

#define MAXCODE(n)	(1L << (n))



union	bytes
{
	long	word;
	struct
	{
#if BYTEORDER == 4321
		char_type	b1;
		char_type	b2;
		char_type	b3;
		char_type	b4;
#else
#if BYTEORDER == 1234
		char_type	b4;
		char_type	b3;
		char_type	b2;
		char_type	b1;
#else
#	undef	BYTEORDER
		int				dummy;
#endif
#endif
	} bytes;
} ;
#if BYTEORDER == 4321 && NOALLIGN == 1
#define	output(b,o,c,n)	{													\
							*(long *)&((b)[(o)>>3]) |= ((long)(c))<<((o)&0x7);\
							(o) += (n);										\
						}
#else
#ifdef BYTEORDER
#define	output(b,o,c,n)	{	char_type	*p = &(b)[(o)>>3];				\
							union bytes i;									\
							i.word = ((long)(c))<<((o)&0x7);				\
							p[0] |= i.bytes.b1;								\
							p[1] |= i.bytes.b2;								\
							p[2] |= i.bytes.b3;								\
							(o) += (n);										\
						}
#else
#define	output(b,o,c,n)	{	char_type	*p = &(b)[(o)>>3];				\
							long		 i = ((long)(c))<<((o)&0x7);	\
							p[0] |= (char_type)(i);							\
							p[1] |= (char_type)(i>>8);						\
							p[2] |= (char_type)(i>>16);						\
							(o) += (n);										\
						}
#endif
#endif
#if BYTEORDER == 4321 && NOALLIGN == 1
#define	input(b,o,c,n,m){													\
							(c) = (*(long *)(&(b)[(o)>>3])>>((o)&0x7))&(m);	\
							(o) += (n);										\
						}
#else
#define	input(b,o,c,n,m){	char_type 		*p = &(b)[(o)>>3];			\
							(c) = ((((long)(p[0]))|((long)(p[1])<<8)|		\
									 ((long)(p[2])<<16))>>((o)&0x7))&(m);	\
							(o) += (n);										\
						}
#endif

char			*progname;			/* Program name									*/
int 			silent = 0;			/* don't tell me about errors					*/
int 			quiet = 1;			/* don't tell me about compression 				*/
int				do_decomp = 0;		/* Decompress mode								*/
int				force = 0;			/* Force overwrite of files and links			*/
int				nomagic = 0;		/* Use a 3-byte magic number header,			*/
									/* unless old file 								*/
int				block_mode = BLOCK_MODE;/* Block compress mode -C compatible with 2.0*/
int				maxbits = BITS;		/* user settable max # bits/code 				*/
int 			zcat_flg = 0;		/* Write output on stdout, suppress messages 	*/
int				recursive = 0;  	/* compress directories 						*/
int				exit_code = -1;		/* Exitcode of compress (-1 no file compressed)	*/

char_type		inbuf[IBUFSIZ+64];	/* Input buffer									*/
char_type		outbuf[OBUFSIZ+2048];/* Output buffer								*/

struct stat		infstat;			/* Input file status							*/
char			*ifname;			/* Input filename								*/
int				remove_ofname = 0;	/* Remove output file on a error				*/
char 			ofname[MAXPATHLEN];	/* Output filename								*/
int				fgnd_flag = 0;		/* Running in background (SIGINT=SIGIGN)		*/

long 			bytes_in;			/* Total number of byte from input				*/
long 			bytes_out;			/* Total number of byte to output				*/

/* Normal machine */
	count_int		htab[HSIZE];
	unsigned short	codetab[HSIZE];

#	define	htabof(i)				htab[i]
#	define	codetabof(i)			codetab[i]
#	define	tab_prefixof(i)			codetabof(i)
#	define	tab_suffixof(i)			((char_type *)(htab))[i]
#	define	de_stack				((char_type *)&(htab[HSIZE-1]))
#	define	clear_htab()			memset(htab, -1, sizeof(htab))
#	define	clear_tab_prefixof()	memset(codetab, 0, 256);


void  	decompress		ARGS((int,int));
void  	read_error		ARGS((void));
void  	write_error		ARGS((void));
void 	abort_compress	ARGS((void));


/*
 * Decompress stdin to stdout.  This routine adapts to the codes in the
 * file building the "string" table on-the-fly; requiring no table to
 * be stored in the compressed file.  The tables used herein are shared
 * with those of the compress() routine.  See the definitions above.
 */

void
decompress(int fdin, int fdout)
{
  char_type 	*stackp;
  code_int	 code;
  int		 finchar;
  code_int	 oldcode;
  code_int	 incode;
  int		 inbits;
  int		 posbits;
  int		 outpos;
  int		 insize;
  int		 bitmask;
  code_int	 free_ent;
  code_int	 maxcode;
  code_int	 maxmaxcode;
  int		 n_bits;
  int		 rsize;

		bytes_in = 0;
		bytes_out = 0;
		insize = 0;

		while (insize < 3 && (rsize = read(fdin, inbuf+insize, IBUFSIZ)) > 0)
			insize += rsize;

		if (insize < 3 || inbuf[0] != MAGIC_1 || inbuf[1] != MAGIC_2)
		{
			if (rsize < 0)
				read_error();

			if (insize > 0)
			{
				fprintf(stderr, "%s: not in compressed format\n",
									(ifname[0] != '\0'? ifname : "stdin"));
				exit_code = 1;
			}

			return ;
		}

		maxbits = inbuf[2] & BIT_MASK;
		block_mode = inbuf[2] & BLOCK_MODE;
		maxmaxcode = MAXCODE(maxbits);

		if (maxbits > BITS)
		{
			fprintf(stderr,
					"%s: compressed with %d bits, can only handle %d bits\n",
					(*ifname != '\0' ? ifname : "stdin"), maxbits, BITS);
			exit_code = 4;
			return;
		}

		bytes_in = insize;
	    maxcode = MAXCODE(n_bits = INIT_BITS)-1;
		bitmask = (1<<n_bits)-1;
		oldcode = -1;
		finchar = 0;
		outpos = 0;
		posbits = 3<<3;

	    free_ent = ((block_mode) ? FIRST : 256);

		clear_tab_prefixof();	/* As above, initialize the first
								   256 entries in the table. */

	    for (code = 255 ; code >= 0 ; --code)
			tab_suffixof(code) = (char_type)code;

		do
		{
resetbuf:	;
			{
				int	i;
				int				e;
				int				o;

				e = insize-(o = (posbits>>3));

				for (i = 0 ; i < e ; ++i)
					inbuf[i] = inbuf[i+o];

				insize = e;
				posbits = 0;
			}

			if (insize < sizeof(inbuf)-IBUFSIZ)
			{
				if ((rsize = read(fdin, inbuf+insize, IBUFSIZ)) < 0)
					read_error();

				insize += rsize;
			}

			inbits = ((rsize > 0) ? (insize - insize%n_bits)<<3 : 
									(insize<<3)-(n_bits-1));

			while (inbits > posbits)
			{
				if (free_ent > maxcode)
				{
					posbits = ((posbits-1) + ((n_bits<<3) -
									 (posbits-1+(n_bits<<3))%(n_bits<<3)));

					++n_bits;
					if (n_bits == maxbits)
						maxcode = maxmaxcode;
					else
					    maxcode = MAXCODE(n_bits)-1;

					bitmask = (1<<n_bits)-1;
					goto resetbuf;
				}

				input(inbuf,posbits,code,n_bits,bitmask);

				if (oldcode == -1)
				{
					outbuf[outpos++] = (char_type)(finchar = (int)(oldcode = code));
					continue;
				}

				if (code == CLEAR && block_mode)
				{
					clear_tab_prefixof();
	    			free_ent = FIRST - 1;
					posbits = ((posbits-1) + ((n_bits<<3) -
								(posbits-1+(n_bits<<3))%(n_bits<<3)));
				    maxcode = MAXCODE(n_bits = INIT_BITS)-1;
					bitmask = (1<<n_bits)-1;
					goto resetbuf;
				}

				incode = code;
			    stackp = de_stack;

				if (code >= free_ent)	/* Special case for KwKwK string.	*/
				{
					if (code > free_ent)
					{
						char_type 		*p;

						posbits -= n_bits;
						p = &inbuf[posbits>>3];

						fprintf(stderr, "insize:%d posbits:%d inbuf:%02X %02X %02X %02X %02X (%d)\n", insize, posbits,
								p[-1],p[0],p[1],p[2],p[3], (posbits&07));
			    		fprintf(stderr, "uncompress: corrupt input\n");
						abort_compress();
					}

        	    	*--stackp = (char_type)finchar;
		    		code = oldcode;
				}

				while ((cmp_code_int)code >= (cmp_code_int)256)
				{ /* Generate output characters in reverse order */
			    	*--stackp = tab_suffixof(code);
			    	code = tab_prefixof(code);
				}

				*--stackp =	(char_type)(finchar = tab_suffixof(code));

			/* And put them out in forward order */

				{
					int	i;

					if (outpos+(i = (de_stack-stackp)) >= OBUFSIZ)
					{
						do
						{
							if (i > OBUFSIZ-outpos) i = OBUFSIZ-outpos;

							if (i > 0)
							{
								memcpy(outbuf+outpos, stackp, i);
								outpos += i;
							}

							if (outpos >= OBUFSIZ)
							{
								if (write(fdout, outbuf, outpos) != outpos)
									write_error();

								outpos = 0;
							}
							stackp+= i;
						}
						while ((i = (de_stack-stackp)) > 0);
					}
					else
					{
						memcpy(outbuf+outpos, stackp, i);
						outpos += i;
					}
				}

				if ((code = free_ent) < maxmaxcode) /* Generate the new entry. */
				{
			    	tab_prefixof(code) = (unsigned short)oldcode;
			    	tab_suffixof(code) = (char_type)finchar;
	    			free_ent = code+1;
				} 

				oldcode = incode;	/* Remember previous code.	*/
			}

			bytes_in += rsize;
	    }
		while (rsize > 0);

		if (outpos > 0 && write(fdout, outbuf, outpos) != outpos)
			write_error();
	}

void
read_error()
	{
		fprintf(stderr, "\nread error on");
	    perror((ifname[0] != '\0') ? ifname : "stdin");
		abort_compress();
	}

void
write_error()
	{
		fprintf(stderr, "\nwrite error on");
	    perror((ofname[0] != '\0') ? ofname : "stdout");
		abort_compress();
	}

void
abort_compress()
	{
		if (remove_ofname)
	    	unlink(ofname);

		exit(1);
	}


