/* brukccd.c from ccd2ipf.c, Stan Swanson, TAMU, 25 April 2006 */
/* proteus.c conversion 033.26 */
/* based on difoff.c */
# include <stdio.h>
# include <stdlib.h>
# include <string.h>

int ccdata[1024][1024];
unsigned char ccbyte[4096]; unsigned short ccshort[4096];
unsigned int ccint[4096];

int readline(char *ch, int max)
{ int i; char c, z='\0'; fgets(ch,max,stdin);
  for (i=0;i<max;i++) { c = ch[i]; if (c==z) return i;
       if (c=='\n') { ch[i] = z;         /* LINUX,NT difference wr <cr>: */
       if (i>0 && ch[i-1]=='\r') { i--; ch[i] = z; }
       return i; }
  } /* for */  ch[max] = z; return max; }

int main (int argc, char *argv[])
{ int i,j,k,ku,ko,k4, err,m,n, hist[100], sump, summ;
  int swab,ii,jj,kk,jx,ky,mm,nn, nhoriz, nvert, hoff,max,thresh;
  int nunder=0, n2over=0, n4over=0, lendata=1, lenunder=1,
    nrows=1024, ncols=1024, zeroff=0, form=0,hdrblks=15,hdrlines=96;
        short s,sptp[3000], sptm[3000], delspt[3000];
        unsigned short bs;  unsigned char uc;
        /*      int bx = 1492, by = 1666 */
        int  pd, md, pdo, mdo, zz;
        double dsum, esum, rat;
      union { unsigned char b[2];  short s; unsigned short us; } u;
      union { unsigned char b[4];  int i; unsigned int ui; } u4;
  double twoth,omega,phi,chi,distance,wavelen,alpha1,alpha2,pixsizemm,
    angles[5],fullscale,d,
    cx1024,cy1024,cx512,cy512,centerx,centery,oscrange,pixpercm,delta;
  int maxpixel,ixis,verbo=1,debug=0,qunder=0,saturate,nsat,offset=0;
FILE *fi, *fc, *fo; char filename[60],infile[80],line[80],dettype[30];

 printf("argc %d %d argv[0] %s\n",argc,argv,argv[0]);

  fi = fo = fc = NULL;

  printf(" Proteus CCD  frame file:");
    n = readline(infile,60); /* scanf("%s",infile); */
  fi=fopen(infile,"rb");
        if (fi==NULL) { printf(" open error (in) \n"); exit(1); };

if (debug) {
 printf(" xdip outfile:");
    n = readline(filename,60); /* scanf("%s",filename); */
    if (n>0) {  fo=fopen(filename,"w");
      if (fo==NULL) { printf(" open error (xdip out) \n");  }; };

  printf(" header outfile [ ]:");
    n = readline(filename,60); /* scanf("%s",filename); */
    if (n>0) {  fc=fopen(filename,"w");
      if (fc==NULL) { printf(" open error (header out) \n");  }; };
} /* if (debug) */

  pd = md = pdo = mdo = zz = 0;   dsum = esum = 0.0;
  for (j=0; j<100; j++) hist[j] = 0;

  /* look for format info, etc. in header lines... */
  nhoriz = nvert = 1024;  swab = -1;
  /* initialize to zero, will have nonzero value if line read */
  twoth=omega=phi=chi=angles[0]=0.0;
  distance=wavelen=alpha1=alpha2=pixsizemm=0.0;
  centerx=centery=oscrange=pixpercm=delta=0.0;
  maxpixel=ixis=nsat=saturate=offset=0;

  /* 15 blocks of 80 char lines == 96 lines */
  for (j=0;j<hdrlines;j++) { n=fread(line,1,80,fi); // printf("%s\n",line);
                            if (fc) fprintf(fc,"%s\n",line);
  if (strncmp(line,"NOVERFL:",8)==0)
    { n = sscanf(line+8," %d %d %d",&nunder,&n2over,&n4over);
    if (verbo) printf(">>>>>overflows  %d %d %d\n",nunder,n2over,n4over); }
  else if (strncmp(line,"NPIXELB:",8)==0)
    { n = sscanf(line+8," %d %d",&lendata,&lenunder);
      if (verbo)
       printf(">>>>>pixel bytes data %d under %d\n",lendata,lenunder); }
  else if (strncmp(line,"NROWS  :",8)==0)
    { n = sscanf(line+8," %d",&nrows);
          if (verbo) printf(">>>>rows  %d \n",nrows); nvert = nrows; }
 else if (strncmp(line,"NCOLS  :",8)==0)
    { n = sscanf(line+8," %d",&ncols);
          if (verbo) printf(">>>>>columns  %d\n",ncols); nhoriz = ncols; }
 else if (strncmp(line,"NEXP   :",8)==0)
    { n = sscanf(line+8," %d %d %d",&k,&k,&zeroff);
          if (verbo) printf(">>>>>zero offset  %d \n",zeroff); }
 else if (strncmp(line,"MAXIMUM:",8)==0)
    { n = sscanf(line+8," %d",&maxpixel); thresh = maxpixel/2;
          if (verbo)
          printf(">>>>>maximum pixel (this frame) %d \n",maxpixel); }
 else if (strncmp(line,"ANGLES :",8)==0)
    { n = sscanf(line+8," %lg %lg %lg %lg",&twoth,&omega,&phi,&chi);
        angles[1]=twoth; angles[2]=omega; angles[3]=phi; angles[4]=chi;
    if (verbo)
      printf(">>>>>angles  2-theta %g omega %g phi %g\n",twoth,omega,phi); }
 else if (strncmp(line,"DISTANC:",8)==0)
    { n = sscanf(line+8," %lg",&distance);
      if (verbo) printf(">>>>>xtal detector distance  %lg (cm)\n",distance); }
 else if (strncmp(line,"WAVELEN:",8)==0)
    { n = sscanf(line+8," %lg %lg %lg",&wavelen,&alpha1,&alpha2);
          if (verbo) printf(">>>>>average wavelength  %g \n",wavelen); }
 else if (strncmp(line,"CENTER :",8)==0)
    { n = sscanf(line+8," %lg %lg %lg %lg",&cx1024,&cy1024,&cx512,&cy512);
      if (nhoriz==512) { centerx = cx512; centery = cy512; }
                  else { centerx = cx1024; centery = cy1024; }
          if (verbo) printf(">>>>>beam center  %g %g \n",centerx,centery); }
 else if (strncmp(line,"AXIS   :",8)==0)
    { n = sscanf(line+8," %d",&ixis);
    if (ixis != 2) printf(" ***** oscillation angle not omega\n");
          if (verbo) printf(">>>>>axis  %d angle %g\n",ixis,angles[ixis]); }
 else if (strncmp(line,"INCREME:",8)==0)
    { n = sscanf(line+8," %lg",&oscrange);
          if (verbo) printf(">>>>>oscillation range  %g \n",oscrange); }
 else if (strncmp(line,"CCDPARM:",8)==0)
    { n = sscanf(line+8," %lg %lg %lg %lg %lg",&d,&d,&d,&d,&fullscale);
      saturate = fullscale;
          if (verbo) printf(">>>>>fullscale  %g \n",fullscale); }
 else if (strncmp(line,"DETTYPE:",8)==0)
    { n = sscanf(line+8," %s %lg %lg",dettype,&pixpercm,&delta);
      pixsizemm = 5.0/pixpercm; if (nhoriz==512) pixsizemm *= 2.0;
      if (verbo)
      printf(">>>>> pixel siz  %g (mm)  %g\n det to phosphor %g (cm)\n",
           pixsizemm,pixpercm,delta); }
 else if (strncmp(line,"FORMAT :",8)==0)
    { n = sscanf(line+8," %d",&form);
        if ( (form!=100 || j!=0) && verbo )
         printf("****>>>format  %d record %d\n",form,j); }
 else if (strncmp(line,"HDRBLKS:",8)==0)
   { n = sscanf(line+8," %d",&hdrblks); k = (512*hdrblks)/80;
   if (k!=96 && verbo) { hdrlines = k;
      printf("***header blocks %d  lines %d\n",hdrblks,hdrlines);} }

  }

  /*********************************************/

  /* even though zeroff != 0, examined frames behave as if offset==0 */
  /* could set offset = zeroff; if needed */

  /* no observed underflow data (nunder == -1) although there are
     usually several thousand pixels with value zero */
  /* set qunder = 1; if data exists */

  /* *************  values of interest accumulated above:

     maxpixel -- seems to be the maximum pixel value, not necessarily
                 saturated.  testing "saturate" for this function.
     pixsizemm -- should be pixel size in mm. I assume they are square.
                  derived from pixpercm (pixels/cm for 512x512 pixel frame)
     omega -- angle (degrees) at start of oscillation for omega scan
              (ixis==2) which is geometrically a phi scan.  If ixis==3,
              one is rotating phi, mounted on chi (== 54... degrees).
     oscrange -- angular range of oscillation in degrees
     distance -- detector distance (cm).  relies on data entry by
                 experimenter and needs "delta" added (internal distance
                 of detector from external face) and multiply by 10.
     wavelen -- average wavelength of K alpha (Cu in our case)
     centerx, centery -- beam center in pixels from lower left corner
                         of frame: ccdata[0][0] has pixel indices 0,0.
                 I have messed with the indices of ccdata[jx][ky]
                 so that jx corresponds numerically to Bruker x-pixel
                 and ky corresponds to Bruker y-pixel
     twoth -- two theta in degrees.  Can be non-zero if experimenter
              offsets detector to get higher resolution data.
     (detector serial number) -- no such data on our frames currently.
            could probably modify site files to have this appear
            somewhere as a string.

     **************** */

  /*********************************************/

  ku = ko = 0; /* counts of under and overflows */
  kk = mm = 0; /*  byte swap counts */

if (lendata==1) { for (k=0; k<nrows; k++)
  {   n = fread(ccbyte , lendata, (size_t) ncols, fi);
      if (n != ncols) printf(" short data %d  row %d\n",n,k);
      for (j=0; j<ncols; j++) { /* ccdata[k][j] = uc = ccbyte[j]; */
        /* make indices consistent with Bruker pixel numbering */
        jx = j; ky = 1023 - k;
          ccdata[jx][ky] = uc = ccbyte[j];
              if (uc==0) ku++; else if (uc==255) ko++; }
  } /* for (k) */  }  /* if (lendata==1) */
 else if (lendata==2) { for (k=0; k<nrows; k++)
  {   n = fread(ccshort , lendata, (size_t) ncols, fi);
      if (n != ncols) printf(" short data %d  row %d\n",n,k);
      for (j=0; j<ncols; j++) { /* ccdata[k][j] = bs = ccshort[j];  */
        /* make indices consistent with Bruker pixel numbering */
        jx = j; ky = 1023 - k;
          ccdata[jx][ky] =  bs = ccshort[j];
                 u.s = bs; if (u.b[0]>8) kk++; if (u.b[1]>8) mm++;
              if (bs==0) ku++; else if (bs==65535) ko++; }
  } /* for (k) */  }  /* if (lendata==2) */
 else  printf("input not implemented for data length %d\n",lendata);

 if (verbo) {
       printf(" %4d large[0] %4d large[1]\n",kk,mm);
              { if (mm>kk) k = 1; else k = 0; }
       printf("old swab  %d  new swab %d \n",swab,k);
       if (swab<0) swab = k;
 printf(" %d byte data read under %d over %d\n",lendata,ku,ko);
 }

/*********** may need to swap bytes for short data **************/
 if (swab && lendata==2)
 { for (jx=0; jx<ncols; jx++) for (ky=0; ky<nrows; ky++)
        { u.us = ccdata[jx][ky];  bs = u.b[0]; u.b[0] = u.b[1];
                            u.b[1] = bs; ccdata[jx][ky] = u.us; }
 } /* if (swab&&lendata==2) */
/**********  need to verify zero offset behavior   **************/

 if (qunder) {
   nn = nunder; kk = jj = 0; mm = 512;
while (nn>0) { if (nn<512) mm = nn; nn -= 512; ii=0;
      n = fread(ccbyte, lenunder, (size_t) mm, fi);
      if (n != mm) printf(" short under %d at %d %d\n",n,kk,jj);
      while (ii<mm) {
        /* make indices consistent with Bruker pixel numbering */
        jx = jj; ky = 1023 - kk;
          ccdata[jx][ky] =  bs = ccshort[j];
             if (ccdata[kk][jj]==0)
                           { ccdata[kk][jj] = ccbyte[ii] - offset; ii++;}
                      jj++; if (jj>=ncols) { jj=0; if (kk<nrows-1) kk++; }
     }  /* while (ii<mm) */
} /* while (nn>0) get underflows */
  mm = nunder%16; if (mm>0)  n = fread(ccbyte,lenunder, (size_t) 16-mm, fi);

 printf(" underflows read,  %d\n",mm);

}  /* if (qunder) underflows .. ignore for now: qunder==0  */

nn = n2over; kk = jj = 0; mm = 512;  m = 255;
while (nn>0) { if (nn<512) mm = nn; nn -= 512; ii=0;
      n = fread(ccshort, 2, (size_t) mm, fi);
      if (n != mm) printf(" short over %d  at %d  %d\n",n,kk,jj);
     if (swab) { for (i=0;i<mm; i++)
                    { u.us = ccshort[i];  bs = u.b[0]; u.b[0] = u.b[1];
                      u.b[1] = bs; ccshort[i] = u.us; } }
      while (ii<mm) {
        /* make indices consistent with Bruker pixel numbering */
           jx = jj; ky = 1023 - kk;
        if (ccdata[jx][ky]==m)
        { ccdata[jx][ky] = ccshort[ii] - offset ; ii++;}
                      jj++; if (jj>=ncols) { jj=0; if (kk<nrows-1) kk++; }
     }  /* while (ii<mm) */
} /* while (nn>0) get 2 byte overflows */
  mm = n2over%8; if (mm>0)  n = fread(ccshort, 2, (size_t) 8-mm, fi);

 printf(" n2over read, extra %d\n", mm);

nn = n4over; kk = jj = k4 = 0; mm = 512;  m = 65535;
while (nn>0) { if (nn<512) mm = nn; nn -= 512; ii=0;
      n = fread(ccint, 4, (size_t) mm, fi);
      if (n != mm) printf(" int over %d  at %d  %d\n",n,kk,jj);
     if (swab) { for (i=0;i<mm; i++)
                    { u4.ui = ccint[i];
                      printf( "%d %x  %d ",u4.ui, u4.ui, u4.ui+offset);
                      bs = u4.b[0]; u4.b[0] = u4.b[3]; u4.b[3] = bs;
                      bs = u4.b[1]; u4.b[1] = u4.b[2]; u4.b[2] = bs;
                      printf( " swapped  %d %x \n",u4.ui,u4.ui);
                      ccint[i] = u4.ui; } }
      while (ii<mm) {
        /* make indices consistent with Bruker pixel numbering */
        jx = jj; ky = 1023 - kk;
                  if (ccdata[jx][ky]==m)
                           {
                             ccdata[jx][ky] = i = ccint[ii] - offset;
                   if (i>saturate-offset) nsat++;
                   if (k4<20 || i>thresh)
                       printf(" %5d-th n4over %8d at %d %d\n",k4,i,jx,ky);
                             ii++; k4++;}
                      jj++; if (jj>=ncols) { jj=0; if (kk<nrows-1) kk++; }
     }  /* while (ii<mm) */
} /* while (nn>0) get 4 byte overflows */
  mm = n4over%4; if (mm>0)  n = fread(ccshort, 4, (size_t) 4-mm, fi);

  /* even though zeroff != 0, examined frames behave as if offset==0 */
  if (offset)  { for (jx=0; jx<ncols; jx++) for (ky=0; ky<nrows; ky++)
                 ccdata[jx][ky] += offset; }

 printf(" n4over read %d counted %d header %d\n",k4,ko,n4over);
 printf(" %d saturated pixels > %d\n",nsat,saturate);


 while (1) { printf("local printout, x y center:");
   n = readline(line,80); if (n<1) break;
   m = sscanf(line," %d %d",&jx,&ky); if (m<2) break;
   printf("\n center %4d %4d  file %s\n\n",jx,ky,infile);
   for (k=ky+4; k>ky-5; k--)
   { for (j=jx-4; j<jx+5; j++) printf(" %7d",ccdata[j][k]);
     printf("\n"); }
 } /* while (1) */

   if (fi) err = fclose(fi);
   if (fc) err = fclose(fc);
   if (fo) err = fclose(fo);
exit(0);




# if (0)

/*************** conversion to xdip .ipf format *************/

 hoff = (3000-nhoriz)/2; max = 0;

  for (k=0; k<3000; k++) delspt[k] = zeroff;
if (fo) { for (k=0; k<hoff; k++)
             n = fwrite( delspt, sizeof(s),(size_t) 3000, fo); }

for (j = 0; j < nvert; j++)
{    for (k=0; k<nhoriz; k++) { m = ccdata[j][k]; if (m>max) max = m;
              if (m>32767) m = -m/32 - 1; delspt[k+hoff] = m; }
           if (fo) n = fwrite( delspt, sizeof(s),(size_t) 3000, fo);
        }

  for (k=0; k<3000; k++) delspt[k] = zeroff;
if (fo) { for (k=0; k<hoff; k++)
           n = fwrite( delspt, sizeof(s),(size_t) 3000, fo);
/* pseudo MAC Science trailer */
           n = fwrite( delspt, sizeof(s),(size_t) 512, fo);  }
printf(" max value %d\n",max);

/*************** conversion from xdip .ipf file *************/

for (j = 0; j < 3000; j++)
        {  n = fread( sptp, sizeof(s),(size_t) 3000, fi);
           if (n != 3000) { err = ferror(fi);
             printf(" (+) read err %d  n %d \n",err,n); /*exit(1);*/ }
           n = fread( sptm, sizeof(s),(size_t) 3000, fc);
           if (n != 3000) { err = ferror(fc);
             printf(" (-) read err %d  n %d \n",err,n); /*exit(1);*/ }
           for (i=0; i < 3000; i++)
           {  n = sptp[i]; if (n<0) n = 32*(65536+n);
              m = sptm[i]; if (m<0) m = 32*(65536+m);
              sump += n; summ += m;  }
           dsum += sump;  esum += summ;  rat = dsum; rat = rat/esum;

           for (i=0; i < 3000; i++)
           {  n = sptp[i]; if (n<0) n = 32*(65536+n);
              m = sptm[i]; if (m<0) m = 32*(65536+m);
              k = n - rat*m;
                if (k>0) { pd++; if (k>99) pdo++; }
/* use absolute value for initial statistics...  */
                if (k<0) { md++; if (k<-99) mdo++;  /* k = -k; */ }
        /*      if (k<99) hist[k]++; else hist[99]++;  */

 k += 100;  if (k<1) k = 0;

                if (k>32767) k = k/32 - 65536;
                if (n==0&&m==0) zz++;
                delspt[i] = k;
           }   /* for i */
           n = fwrite( delspt, sizeof(s),(size_t) 3000, fo);
        }  /* for j */
   printf(" pd %d md %d pdo %d mdo %d zz %d \n",pd,md,pdo,mdo,zz);
  printf(" +sum %g -sum %g ratio (+/-) %g \n",dsum,esum,dsum/esum);
   for (j=0; j<100; j += 10)
   { for (k=0; k<10; k++) printf("%6d ",hist[j+k]); printf("\n"); }

/* transfer one header-trailer */
        n = fread(sptp, 1, 1024, fi);
        n = fwrite(delspt, 1, 1024, fo);
   err = fclose(fi);
   err = fclose(fc);
   err = fclose(fo);
# endif /* xdip conversion */

} /* main() */
