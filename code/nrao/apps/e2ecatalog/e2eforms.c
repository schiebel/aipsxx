#include <stdlib.h>
#include <ctype.h>
#include <sys/types.h>
#include <pwd.h>
#include <math.h>
#include <sys/vfs.h>
#include <stdio.h>

#define MAX_ENTRIES 50
#define PI 3.141592654

typedef struct {
    char *name;
    char *val;
} entry;

int mypid;

char *makeword(char *line, char stop);
char *fmakeword(FILE *f, char stop, int *len);
char x2c(char *what);
void unescape_url(char *url);
void plustospace(char *str);

static int writeit ();

/******************************************************************/

main(int argc, char *argv[]) {


    struct sumhold 
    {
      char programid[24];
      char observername[24];
      char sourcename[24];
      double ra1950;
      double ra2000;
      double dec1950;
      double dec2000;
    } sumlist;

    entry entries[MAX_ENTRIES];
    int iword(), sindex(), fits_str2mjd();
    int x,m=0;
    int cl;
    short int empty=1;
    int i,j,k;
    float freq1, freq2;
    double ra1, ra2, dec1, dec2;
    double start_mjd, stop_mjd;
    float sdeg, smin, ssec;
    float rahr, ramin, rasec, decdeg, decmin, decsec;
    float racomb=-99.0;
    float deccomb=-99.0;
    double tos;
    double deltadec=0.017453293;  /*  1.0 degree */
    double deltara, deltacos, arg1, arg2;
    double temp1, temp2, temp3;
    char str1[10], str2[10], str3[10], str4[10], str5[10], str6[10];
    uid_t ii;
    char test[6];
    char string1[100], string2[100];
    char extra1val[30], extra2val[30], extra1[30], extra2[30];
    char obsbands_str[20];
    char str_startd[15], str_stopd[15];
    struct passwd *my_uid;

    short is_null[65];
    char dbName[30];
    char epoch[5];
    char coord[40];
    char query_string[1000];
    char query2_string[1000];
    char query3_string[1000];
    char glish_string[1000];

    FILE *pGlishFile;

    obsbands_str[0] = '\0';
    test[0] = '\0';
    coord[0] = '\0';
    extra1[0] = '\0';
    extra1val[0] = '\0';
    extra2[0] = '\0';
    extra2val[0] = '\0';
    query_string[0] = '\0';
    query2_string[0] = '\0';
    query3_string[0] = '\0';
    glish_string[0] = '\0';

    printf("Content-type: text/html%c%c",10,10);

/*
    if(strcmp(getenv("REQUEST_METHOD"),"POST")) {
        printf("This script should be referenced with a METHOD of POST.\n");
        printf("If you don't understand this, see this ");
        printf("<A HREF=\"http://www.ncsa.uiuc.edu/SDG/Software/Mosaic/Docs/fill-out-forms/overview.html\">forms overview</A>.%c",10);
        exit(1);
    }
*/

    if(strcmp(getenv("CONTENT_TYPE"),"application/x-www-form-urlencoded")) {
        printf("This script can only be used to decode form results. \n");
        exit(1);
    }

    /* create the temp file where full details are stored */
    /* this file be html and have anchors to each summary line selected */

    /* now get the list of name=value pair from the form */
    cl = atoi(getenv("CONTENT_LENGTH"));

    for(x=0;cl && (!feof(stdin));x++) {
        m=x;
        entries[x].val = fmakeword(stdin,'&',&cl);
        plustospace(entries[x].val);
        unescape_url(entries[x].val);
        entries[x].name = makeword(entries[x].val,'=');
    }
    printf("<head>\n");
    printf("<title>NRAO VLADB Query Results</title>\n");
    printf("</head>\n");
    printf("<body>\n");
    printf("<H1>E2E Archive Query Report</H1>");
    printf("You submitted the following name/value pairs:<p>%c",10);
    printf("<ul>%c",10);

    for(x=0; x <= m; x++)
    {
        printf("<li> <code>%s = %s</code>%c",entries[x].name, entries[x].val,10);
   /* we need this here since coords needs deltadec before calculating stuff */
	   if (strcmp(entries[x].name, "SRAD")==0 && entries[x].val!='\0')
	   {
		 i = sscanf(entries[x].val, "%f %f %f", &sdeg, &smin, &ssec);
		 if (i == 1)
		     deltadec= fabs(sdeg) * PI / 180.0;
		 else if (i==3)
		    deltadec = (fabs(sdeg) + smin/60.0 + ssec/3600.0) * PI / 180.0;
		 if (deltadec > (PI/4.0)) deltadec=PI/4.0;
	   }
	   if (strcmp(entries[x].name,"EXTRA1")==0)
	      sprintf(extra1, entries[x].val);
	   else if (strcmp(entries[x].name,"EXTRA1VAL")==0)
	      sprintf(extra1val, entries[x].val);
	   else if (strcmp(entries[x].name,"EXTRA2")==0)
	      sprintf(extra2, entries[x].val);
	   else if (strcmp(entries[x].name,"EXTRA2VAL")==0)
	      sprintf(extra2val, entries[x].val);
	   else if (strcmp(entries[x].name,"STARTD")==0)
	      sprintf(str_startd, entries[x].val);
	   else if (strcmp(entries[x].name,"STOPD")==0)
	      sprintf(str_stopd, entries[x].val);

    }
    printf("</ul>%c",10);

    /* Open the Glish query output file, contains name value pairs */
    if ((pGlishFile = fopen (entries[0].val,"w")) == (FILE *)NULL)
	{
	printf ("<H1>Error: Can not open the file %s</H1><p>%c", entries[0].val,10);
	exit (1);
	}
    printf ("<H3>Opened file : %s</H3><p>%c",entries[0].val,10);

 /* load the query file with name value  pairs */

 for(x=0; x <= m; x++)
 {
    if (entries[x].val[0] == '\0')
       continue;

    if (strcmp(entries[x].name, "EPOCH")==0)
    {
	fprintf(pGlishFile,"EPOCH = %s\n",entries[x].val);
    }
    else if (strncmp(entries[x].name, "OID",3)==0)
    {
      i = strlen(entries[x].val); 
      for (j=0;j<i;j++)
      {
	  if (isdigit(entries[x].val[j]) == 0) 
	  {
	     printf("<h3>Observer ID has to be numerical !  -> Ignored for this query</h3>\n");
	     break;
	  }
      }
      if (j==i)
      {
	   fprintf(pGlishFile,"OBSERVER_ID = %s\n", entries[x].val);
	   empty=0;
      }
    }
    else if (strncmp(entries[x].name, "PID",3)==0)
    {
      sscanf(entries[x].val, "%s", string2);
      i = strlen(string2); 
      k = 8;
      string2[k-1]='\0';
      for (j=0;j<k-1;j++)
      {
	  if (j>=i)
	     string2[j]=' ';
	  /*
	  else if (string2[j] == '*') 
	  {
	     string2[j]='%';
	     string2[j+1]='\0';
	     break;
	  }
	  else if (string2[j] == '?') 
	  {
	     string2[j]='_';
	  }
	  */
	  else
	     string2[j] = toupper(string2[j]);
      }
      fprintf(pGlishFile,"PROJECT_CODE = %s\n", stripWhite(string2));
      empty=0;
    }
    else if (strcmp(entries[x].name, "SOU")==0)
    {
      sscanf(entries[x].val, "%s", string2);
      i = strlen(string2); 
      k = 16;
      string2[k-1]='\0';
      for (j=0;j<k-1;j++)
      {
	  if (j>=i)
	     string2[j]=' ';
          /*
	  else if (string2[j] == '*') 
	  {
	     string2[j]='%';
	     string2[j+1]='\0';
	     break;
	  }
	  else if (string2[j] == '?') 
	  {
	     string2[j]='_';
	  }
          */
	  else
	     string2[j] = toupper(string2[j]);
      }
      /*      sprintf(string1," and sourcename like \'%-s\' ", string2); */
      fprintf(pGlishFile,"SOURCE_ID = %s\n", stripWhite(string2));
      empty=0;
    }
    else if (strcmp(entries[x].name, "CONFIG")==0)
    {
      sprintf(string2,"%s", entries[x].val);
      for (j=x+1;j<=m;j++)
      {
	   if (strcmp(entries[j].name, "CONFIG")==0)
	   {
	      sprintf(string1,",%s", entries[j].val);
              strcat(string2, string1);
	      x++;
	   }
	   else
	      break;
      }
        fprintf(pGlishFile,"TELESCOPE_CONFIG = %s\n", stripWhite(string2));
	empty=0;
    }
    else if (strcmp(entries[x].name, "CMODE")==0)
    {
      for (j=x+1;j<=m;j++)
      {
	   if (strcmp(entries[j].name, "CMODE")==0)
	   {
	      sprintf(string1,",\'%s\'", entries[j].val);
	      strcat(query_string, string1);
	      x++;
	   }
	   else
	      break;
      }
	empty=0;
    }
    else if (strcmp(entries[x].name, "APOPT")==0)
    {
      for (j=x+1;j<=m;j++)
      {
	   if (strcmp(entries[j].name, "APOPT")==0)
	   {
	      sprintf(string1,",\'%s\'", entries[j].val);
	      strcat(query_string, string1);
	      x++;
	   }
	   else
	      break;
      }
	empty=0;
    }
    else if (strcmp(entries[x].name, "PLANET")==0)
    {
      sprintf(string2,"%s", entries[x].val);
      for (j=x+1;j<=m;j++)
      {
	   if (strcmp(entries[j].name, "PLANET")==0)
	   {
	      sprintf(string1,",%s", entries[j].val);
              strcat (string2, string1);
	      x++;
	   }
	   else
	      break;
      }
      fprintf(pGlishFile,"SOURCE_TYPE = %s\n", stripWhite(string2));
    }
    else if (strcmp(entries[x].name, "CALIB")==0)
    {
      if (strcmp(entries[x].val,"Not")==0)
      {
	   sprintf(string1,"calcode is NULL");
      }
      else
      {
	  sprintf(string2,"%s", entries[x].val);
	  for (j=x+1;j<=m;j++)
	  {
	      if (strcmp(entries[j].name, "CALIB")==0)
	      {
		  sprintf(string1,",%s", entries[j].val);
                  strcat (string2, string1);
		  x++;
	      }
	      else
		  break;
	  }
	}
        fprintf(pGlishFile,"CALIB_TYPE = %s\n", stripWhite(string2));
	empty=0;
    }
    else if (strcmp(entries[x].name, "STARTD")==0)
    {
        sprintf(string1,"%s", entries[x].val);
        start_mjd = (double)fits_str2mjd(string1);
        printf("<p>start_mjd = %s %f\n",string1, start_mjd);
        fprintf(pGlishFile,"TIMERANGE = %f", start_mjd);
	empty=0;
    }
    else if (strcmp(entries[x].name, "STOPD")==0)
    {
        sprintf(string1,"%s", entries[x].val);
        stop_mjd = (double)fits_str2mjd(string1);
        printf("<p>stop_mjd = %s %f\n",string1, stop_mjd);
        fprintf(pGlishFile,",%f\n", stop_mjd);
	empty=0;
    }

    /**
     ** Time on source hack, Apr 29, 1998, SWW.
     **/
    else if (strcmp(entries[x].name, "TOS")==0)
    {
        tos = atof(entries[x].val);
	/*        tos *= 60.0; */
	fprintf(pGlishFile,"EXPOSURE = %f\n", tos);
	empty=0;
    }

    else if (strcmp(entries[x].name, "ACBAND")==0)
    {
      sprintf(string2,"%s", entries[x].val);
      for (j=x+1;j<=m;j++)
      {
	   if (strcmp(entries[j].name, "ACBAND")==0)
	   {
	      sprintf(string1,",%s", entries[j].val);
              strcat(string2,string1);
	      x++;
	   }
	   else
	      break;
      }
      strcat(obsbands_str, stripWhite(string2));
/*        fprintf(pGlishFile,"OBS_BANDS = %s\n", stripWhite(string2));*/
	empty=0;
    }

    else if (strcmp(entries[x].name, "BDBAND")==0)
    {
      sprintf(string2,"%s", entries[x].val);
      for (j=x+1;j<=m;j++)
      {
	   if (strcmp(entries[j].name, "BDBAND")==0)
	   {
	      sprintf(string1,",%s", entries[j].val);
              strcat(string2,string1);
	      x++;
	   }
	   else
	      break;
      }
      if (strlen(obsbands_str) > 0) strcat(obsbands_str, ",");
      strcat (obsbands_str, stripWhite(string2));
/*        fprintf(pGlishFile,"OBS_BDBANDS = %s\n", stripWhite(string2));*/
	empty=0;
    }

    else if (strcmp(entries[x].name, "COORD")==0)
    {
	  i = sscanf(entries[x].val,"%s %s %s %s %s %s", str1, str2, str3, str4, str5, str6);
	  if (i<2) coord[0]='\0';
	  if (i==2)   /* only two numbers thus decimal degrees for ra and dec */
	  {
	    if (str1[0]=='*' && str2[0]=='*')  /* if both are * skip this */
	    {
		coord[0]='\0';
	    }
	    else
	    {
		if (str1[0]=='*')  /* for all ra */
		{
		   sscanf(str2, "%f", &deccomb);
		   if (fabs(deccomb) >=90.0) deccomb=(abs(deccomb)/deccomb) * 89.98;
		   deccomb = (deccomb * PI) / 180.0;  /* dec in radians */
		   dec1 = deccomb + deltadec;
		   dec2 = deccomb - deltadec;
		   if (dec1 > PI/2.0) dec1 = PI/2.01;
		   if (dec2 < -1.0*PI/2.0) dec1 = -1.0*PI/2.01;
		   sprintf(string1, " and dec%s >= %f and dec%s <= %f",epoch,dec2,epoch,dec1);
		   strcat(query_string, string1);
		}
		else if (str2[0]=='*')   /* for all dec */
		{
		   sscanf(str1, "%f", &racomb);
		   racomb = (fabs(racomb) * PI) / 180.0;   /* ra in radians */
		   if (racomb >= 2.0*PI) racomb=1.99*PI;
		   ra1 = racomb + deltadec;
		   if (ra1 > 2.0*PI) ra1 = 1.99*PI;
		   ra2 = racomb - deltadec;
		   if (ra2 < 0.0) ra1 = 0.0;
		   sprintf(string1, " and ra%s >= %f and ra%s <= %f",epoch,ra2,epoch,ra1);
		   strcat(query_string, string1);
		}
		else   /* an entry for each ra and dec */
		{
		   sscanf(str1, "%f", &racomb);
		   racomb = (fabs(racomb) * PI) / 180.0;   /* ra in radians */
		   if (racomb >= 2.0*PI) racomb=1.99*PI;
		   sscanf(str2, "%f", &deccomb);
		   if (fabs(deccomb) >=90.0) deccomb=(fabs(deccomb)/deccomb) * 89.98;
		   deccomb = (deccomb * PI) / 180.0;  /* dec in radians */
		   dec1 = deccomb + deltadec;
		   dec2 = deccomb - deltadec;
		   if (dec1 >= PI/2.0) dec1 = PI/2.01;
		   if (dec2 <= -1.0*PI/2.0) dec1 = -1.0*PI/2.01;
		   arg1 = (cos(deltadec)-sin(dec1)*sin(dec1)) / (cos(dec1)*cos(dec1));
		   deltara = atan(sqrt(1.0 - arg1*arg1) / arg1);
		   ra1 = racomb + deltara;
		   if (ra1 > 2.0*PI) ra1 = 1.99*PI;
		   ra2 = racomb - deltara;
		   if (ra2 < 0.0) ra2 = 0.0;
		   sprintf(string1," and ra%s>=%f and ra%s<=%f", epoch,ra2,epoch,ra1);
		   strcat(query_string, string1);
		   sprintf(string1," and dec%s>=%f and dec%s<=%f", epoch,dec2,epoch,dec1);
		   strcat(query_string, string1);
		}
	    }
	    empty=0;
	  }
	  else if (i==4)   /* 4 numbers then a * with hr(deg) min sec */
	  {
	     if (str1[0] == '*')   /* for all ra */
	     {
		 sscanf(str2,"%f", &decdeg);
		 if (decdeg<0.0) 
		    j=-1;
		 else 
		    j=1;
		 sscanf(str3,"%f",&decmin);
		 sscanf(str4,"%f",&decsec);
		 deccomb = (fabs(decdeg) + decmin/60.0 + decsec/3600.0);
		 if (deccomb >=90.0) deccomb=89.98;
		 deccomb = j * (deccomb * PI) / 180.0;  /* dec in radians */
		 dec1 = deccomb + deltadec;
		 dec2 = deccomb - deltadec;
		 if (dec1 > PI/2.0) dec1 = PI/2.01;
		 if (dec2 < -1.0*PI/2.0) dec1 = -1.0*PI/2.01;
		 sprintf(string1," and dec%s>=%f and dec%s<=%f", epoch,dec2,epoch,dec1);
		 strcat(query_string, string1);
		 empty=0;
	     }
	     else if (str4[0] == '*')   /* for all dec */
	     {
		 sscanf(str1,"%f",&rahr);
		 sscanf(str2,"%f",&ramin);
		 sscanf(str3,"%f",&rasec);
		 racomb = fabs(rahr) + ramin/60.0 + rasec/3600.0;
		 if (racomb>=24.0) racomb=23.98;
		 racomb = racomb * PI / 12.0;
		 ra1 = racomb + deltadec;
		 ra2 = racomb - deltadec;
		 if (ra1 > 2.0*PI) ra1 = 1.99*PI;
		 if (ra2 < 0.0) ra2 = 0.0;
		 sprintf(string1, " and ra%s>=%f and ra%s<=%f",epoch,ra2,epoch,ra1);
		 strcat(query_string, string1);
		 empty=0;
	     }
	     else    /* wrong format dont know if first or last one in decimal deg */
	     {
		 printf("<h3>Coords has wrong format !  -> Ignored for this query</h3>\n");
		 coord[0]='\0';
	     }
	  }
	  else if (i==6)   /* 6 numbers then separate hr(deg) min sec */
	  {
	     sscanf(str1,"%f",&rahr);
	     sscanf(str2,"%f",&ramin);
	     sscanf(str3,"%f",&rasec);
	     racomb = fabs(rahr) + ramin/60.0 + rasec/3600.0;
	     if (racomb>=24.0) racomb=23.98;
	     racomb = racomb * PI / 12.0;

	     sscanf(str4,"%f", &decdeg);
	     if (decdeg< 0.0)
		 j=-1;
	     else
		 j=1;
	     sscanf(str5,"%f",&decmin);
	     sscanf(str6,"%f",&decsec);
	     deccomb = (fabs(decdeg) + decmin/60.0 + decsec/3600.0);
	     if (deccomb >=90.0) deccomb=89.98;
	     deccomb = j * (deccomb * PI) / 180.0;  /* dec in radians */
	     dec1 = deccomb + deltadec;
	     dec2 = deccomb - deltadec;
	     if (dec1 > PI/2.0) dec1 = PI/2.01;
	     if (dec2 < -1.0*PI/2.0) dec1 = -1.0*PI/2.01;

	     arg1 = (cos(deltadec) - sin(dec1)*sin(dec1)) / (cos(dec1)*cos(dec1));
	     deltara = atan(sqrt(1.0 - arg1*arg1) / arg1);
	     ra1 = racomb + deltara;
	     ra2 = racomb - deltara;
             if (ra2 >= 0.0) 
	     {
	        sprintf(string1," and CENTER_DIR[1]>=%f and CENTER_DIR[1]<=%f",
                        ra2,ra1);
             }
             if (ra2 < 0.0)
	     {

	        sprintf(string1," and ((CENTER_DIR[1]>=%f and CENTER_DIR[1]<=%f)",
                        ra2+2.0*PI,2.0*PI);
                strcat(query_string, string1);
	        sprintf(string1," or (CENTER_DIR[1]>=%f and CENTER_DIR[1]<=%f))",
                        0.0,ra1);
             }
	     strcat(query_string, string1);
	     sprintf(string1," and CENTER_DIR[2]>=%f and CENTER_DIR[2]<=%f",dec2,dec1);
	     strcat(query_string, string1);
	     empty=0;
	  }
	  else
	  {
	     printf("<h3>Coords has wrong format !  -> Ignored for this query</h3>\n");
	     coord[0]='\0';
	  }
          fprintf (pGlishFile,"CENTER_DIR[1] = %f,%f\n", ra2, ra1);
          fprintf (pGlishFile,"CENTER_DIR[2] = %f,%f\n", dec2, dec1);
	}
  }

   deltacos = cos(deltadec);
   if (strlen(obsbands_str) > 0)
       fprintf(pGlishFile,"OBS_BANDS = %s\n", obsbands_str);


   if (empty)
   {
      printf("<h3>Nothing selected in the form!</h3><p><h4>Query rejected</h4>");
      exit(1);
   }

   printf("<hr>\n");

   fprintf(pGlishFile,"EOF\n");
   fclose(pGlishFile);
   printf("</b></pre><p><hr>\n");
   printf("</body>\n");
}
 
