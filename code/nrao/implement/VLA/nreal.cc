//# ClassFileName.cc:  this defines ClassName, which ...
//# Copyright (C) 1997,1999,2000
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: nreal.cc,v 19.1 2004/02/02 05:47:05 wyoung Exp $

//# Includes

/*
   _olroutines - Routines for fetching data from shared memory

   _olopen  - opens the on online status record
   _olread  - returns a data from the shared memory
   _olclose - close out the online status record

Dec 1992  Modified by George Martin to remove timeout while waiting for data

Dec 1992 Switched to _ol for AIPS compatibility

Feb 1993 Added changes made by Wes Young and a little other cleanup 

Jun 1993 Changed "sleep()" to sleep1() for fractions of a second 

Mar 1994 Begin changes to get rid of "slots", add printing of
         internet addresses instead of slot numbers 

Sep 1994 Changed routines to wait only when last_record == last_record
         avoids alot of hanging problems.  Also olopen_ forks aoc_clnt
         if it's aips.  Probably don't want this for miranda.

*/

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <syslog.h>

#include <nrao/VLA/nreal.h>


static DataStatus *OnLineStatus;
static char *SharedMemBuffer[MAX_ONLINE];
/*int MAX_TIME = 60; */

char *IP_addr;
static int Last_Record;
static int vis_client_pid = 0;
static int place_holder;

void  ThatsAllFolks(int);
void  client_died(int);
char *getVisServer();
char *getVisClient();
int   startVisClient();
int   startClient();
void  ConvertLogical2Physical(char *buffer, char *DataBuffer, TapeHeader *Tape, int RecordSize);
void  sleep1(double);

int olopen_(int *unit_no)
{
   key_t shm_key;
   int   shmid;
   int   i, j;
   int   aips_flag;
   char *shmem_addr;
   extern char *IP_addr;

   signal(SIGCHLD, client_died);
   signal(SIGUSR1, ThatsAllFolks);

   if (*unit_no == -99){  /* called by aips */
      aips_flag = -1;
   }
   else if (*unit_no == 99) /* non aips call */
      aips_flag = 1;
   else { /* illegal call */
      *unit_no = 0;
      return (*unit_no);
      }

               /* Set up the sharred memory area for the vis records */
   if(access(STATUS_FILE, F_OK) == -1){
      FILE *fp = fopen(STATUS_FILE, "w");
      fprintf(fp, "Dummy file used for retrieving VLA data.  Do not remove.\n");
      fclose(fp);
      }

   shm_key = ftok(STATUS_FILE, 'a');
  /*  printf ("shm_key %8.8x ", shm_key); */
   shmid = shmget(shm_key, sizeof(DataStatus), 0666 | IPC_CREAT );
   if (shmid == -1) {
      perror("bad call on shmget");
      exit(1);
      }
   OnLineStatus = (DataStatus *)shmat(shmid, static_cast<char *>(0), 0);
   if (OnLineStatus == (DataStatus *) -1) {
      if(!startClient()){
         perror ("Client startup failed!");
         fprintf(stderr, "Contact George Martin or Wes Young.\n");
         exit(1);
         }
      }

   if (Get_num_attached(shmid) < 2) {  /* No client for sure */
      if(!startClient()){
         perror ("Client startup failed!");
         fprintf(stderr, "Contact George Martin or Wes Young.\n");
         exit(1);
         }
      }
/*
    Here we set the filler number to support multiple fills
*/    

   for(i=0;i<6;i++){
      if(!OnLineStatus->Fillers[i]){
         OnLineStatus->Fillers[i] = 1;
         break;
      }
   }
   if(i < 6)
      aips_flag *= (i+1); /* aips units are < 0 */
   else 
      aips_flag = 0;

   /* N.B.  2 or more attaches does not gaurantee that client is running */

   for(i=0;i<MAX_ONLINE;i++) {
      shmem_addr = (char *) shmat(OnLineStatus->Queue[i].ShMId, 
                       static_cast<char *>(0), SHM_RDONLY);
      if (shmem_addr == (char *) -1) {  /* can't get a sement somehow */
         perror("Can't connect sharred memory buffer");
         fprintf(stderr, "Trying to connect segment %d\n", i);
         for (j=0; i-1; j++) {
             shmdt(SharedMemBuffer[j]);
             }
         shmdt((char *)OnLineStatus);
         return (*unit_no);
         }
      SharedMemBuffer[i] = shmem_addr;
      }

   IP_addr = (char *) NULL;
       /*
        I would guess that Last_Record should be OnLineStatus->Last rather
        than -1 so we don't retransfer anydata in the buffer already.
        */
   Last_Record = -1;
   *unit_no = aips_flag;
   place_holder = *unit_no-1;
   return(*unit_no);
}
/*
   Function to terminate Data stream
*/
void ThatsAllFolks(int dummy){
/*   MAX_TIME=0; */
   QUIT = TRUE;
   return;
}

void client_died(int dummy){
   QUIT = TRUE;
   fprintf(stderr, "The aoc_clnt process has terminated unexpectedly.");
   vis_client_pid = -1;
   return;
   }

int nrtread_(int *unit_no, char *buffer)
{
   static int i;

   long LRSize;
   int SleepCount;

/*
   Ok here we go, Determine the number of physical records in a logical record
   and size up the last physical record properly
*/
   QUIT = FALSE;
   SleepCount = 0;
   if(Last_Record < OnLineStatus->First)
      Last_Record = OnLineStatus->First;
   if(Last_Record > OnLineStatus->Last)            /* Ok things seem to hang so this may take care of it */
      Last_Record = OnLineStatus->Last;
   while(Last_Record == OnLineStatus->Last && !QUIT) {
      sleep1(0.25);
      SleepCount++;
      if (QUIT)
         return(0);
   }
   if(Last_Record > OnLineStatus->Last)        /* If the shared memory counter was reset reset Last_Record counter */
      Last_Record = OnLineStatus->Last;
   if (QUIT)  /* Was a USR1 signal sent ? */
      return(0);
   i = Last_Record%MAX_ONLINE;
   Last_Record++;
   memcpy((void *)&LRSize, SharedMemBuffer[i], sizeof(LRSize));
   LRSize *= 2; /* Convert from Modcomp words to bytes */
   memcpy(buffer, SharedMemBuffer[i], LRSize);
   
   if (IP_addr != (char *) NULL)
      fprintf(stderr, "%s %d\n", IP_addr, Last_Record-1);
   return(LRSize);
}


int olread_(int *unit_no, char *buffer, int buff_len)
{
   static int Locked = 0;
   static int NumPhysRecords;
   static int PhysRecord;
   static int LastPhysRecord = 0;
   static int LastSize;
   static int i;

   int RecordSize = PHYS_RECORD_SIZE-4;
   long LRSize;
   TapeHeader Tape;
   int SleepCount;

   int Filler;

   if(*unit_no < 0)
      Filler = -1 * *unit_no; /* AIPS */
   else
      Filler = *unit_no; /* Isis */

   Filler--; /* Unit numbers run 1-12 but array is 0-11 */

/*
   Ok here we go, Determine the number of physical records in a logical record
   and size up the last physical record properly
*/
   if(!Locked){
      SleepCount = 0;
      if(OnLineStatus->Current[Filler] < OnLineStatus->First)
         OnLineStatus->Current[Filler] = OnLineStatus->First;
      while(OnLineStatus->Current[Filler] == OnLineStatus->Last && !QUIT){
         SleepCount++;
         sleep(1);
      }
      if(QUIT)
         return(0);
      i = OnLineStatus->Current[Filler]%MAX_ONLINE;
/*      LockShMem(OnLineStatus->Queue[i].SemId); */
      OnLineStatus->Current[Filler]++;
      Locked = TRUE;
      memcpy((void *)&LRSize, SharedMemBuffer[i], sizeof(LRSize));
      LRSize *= 2; /* Convert from Modcomp words to bytes */
      PhysRecord = 0;
      NumPhysRecords = LRSize/(PHYS_RECORD_SIZE-4);
      if(LRSize%(PHYS_RECORD_SIZE-4)){
         NumPhysRecords += 1;
         LastSize = 2048*((LRSize%(PHYS_RECORD_SIZE-4))/2048);
         if((LRSize%(PHYS_RECORD_SIZE-4))%2048)
            LastSize += 2044;  /* Ignore the Tape header */
      }
      else
         LastSize = PHYS_RECORD_SIZE-4;
   }
   PhysRecord++;
   if(PhysRecord == NumPhysRecords){
      RecordSize = LastSize;
      LastPhysRecord = TRUE;
      Locked = FALSE;
      fprintf(stderr, "%d ", OnLineStatus->Current[Filler]);
   }
   Tape.Current = PhysRecord;
   Tape.Total   = NumPhysRecords;
   ConvertLogical2Physical(buffer, SharedMemBuffer[i], &Tape, RecordSize);
/*
   if(LastPhysRecord)
      UnLockShMem(OnLineStatus->Queue[i].SemId);
*/
   return(RecordSize+sizeof(TapeHeader));
}
/*
   This routine takes the logical record and puts it into a buffer that looks
   like a tape buffer
*/
void  ConvertLogical2Physical(char *buffer, char *DataBuffer, TapeHeader *Tape, int RecordSize)
{
   memcpy(buffer, (void *)Tape, sizeof(TapeHeader));
   memcpy(buffer+sizeof(TapeHeader), DataBuffer+((PHYS_RECORD_SIZE-4)*(Tape->Current-1)), RecordSize);
   return;
}
void clear_flag(int unit_no){
   OnLineStatus->Fillers[unit_no] = 0;
   return; 
   }

int olclose_(int *unit_no)
{
   int i, fill_id;

   if(*unit_no < 0)
      fill_id = -1**unit_no - 1;
   else
      fill_id = *unit_no - 1;
   OnLineStatus->Fillers[fill_id] = 0;
   for(i=0;i<MAX_ONLINE;i++)
      shmdt(SharedMemBuffer[i]);
   shmdt( (char *) OnLineStatus);
   if(vis_client_pid > 1)
     kill(vis_client_pid, SIGKILL);
   return(0);
   }

/* Implement a "sleep()" function which also suspends for fractions of
   a second.  Following a GNU implementation of usleep(), this routine
   calls select() with NULL pointers of the I/O descriptor sets to 
   do the actual delay.  This is potentially better than sleep() which
   only does integer seconds and usleep() which only does micro seconds */

#include <sys/time.h>
#include <sys/types.h>
#ifdef R6000
#include <sys/select.h>
#endif

void sleep1(double sleep_time) {

   struct timeval wait;
   double wait_mu;
   int ready;

   if ( (sleep_time <= 0.0) || (sleep_time > 1.0e8) )
      return;

                /* convert floating seconds to integer
                   seconds and micro seconds */

   wait_mu = sleep_time*1000000.0;    /* secs to micro secs */

   wait.tv_sec = (long int) (wait_mu/1000000.0);
   wait.tv_usec = (long int) (wait_mu - ( (double) wait.tv_sec*1000000.0));

   ready = select(1, (fd_set *) NULL, (fd_set *) NULL, (fd_set *) NULL,  &wait);   if (ready < 0) {
      perror ("error on calling setitimer");
      return;
      }
   return;
   }

char *getVisServer(){
   char *vis_server = 0;
   vis_server = getenv("VIS_SERVER");
   if(!vis_server){
     vis_server = strdup("something");
   }
   if(!strcmp(vis_server, "miranda"))
      vis_server = 0;
   return vis_server; }

char *getVisClient(){
   char *vis_client = 0;
   char *path_name;
   path_name = getenv("NEARREAL");
   if(!path_name)
      path_name = getenv("ONLINE");
   if(path_name)
      vis_client = strdup(strcat(path_name, "/aoc_clnt"));
   return vis_client; }

int startClient(){
   int i;
   int vis_client_pid = 1;           /* On the machine at the site we need no vis_server */
   char *vis_client = getVisClient();
   char *vis_server = getVisServer();
   
   if(vis_client && vis_server){     /* Ok fork the server process if you are aips and know */
      for(i=0;i<6;i++)
         OnLineStatus->Fillers[i] = 0;
      vis_client_pid = fork();                              /* what to spawn. */
      if(!vis_client_pid){
         execl(vis_client, vis_client, vis_server, (char *)NULL);
         perror("Exec failed!");
         } else if(vis_client_pid > 0){
             sleep1(10.5);             /* sleep for a few minutes to allow the server to spawn */
             } else if(vis_client_pid == -1){
                perror("Server fork failed!");
                vis_client_pid = 0;
                }
      }
   free(vis_client);
   free(vis_server);
   return vis_client_pid;}

void ClearMemory(int arg){
  syslog(LOG_ERR | LOG_DAEMON, "Clearing Placeholder!");
  QUIT = 1;
/*
  OnLineStatus->Fillers[place_holder] = 0;
*/
  return;
  }

