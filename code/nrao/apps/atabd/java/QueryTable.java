import java.io.*;
import java.net.*;
public class QueryTable {
   String server;
   int    portNumber;
   public  QueryTable( String s, int p){
      server = s;      //server = wotan
      portNumber = p;  // portNumber = 7002
   }
   public String queryTable(String query){
      Socket aipsSocket = null;
      DataOutputStream os = null;
      DataInputStream is = null;
      String results = new String("");
      try {
         aipsSocket = new Socket(server, portNumber);
         os = new DataOutputStream(aipsSocket.getOutputStream());
         is = new DataInputStream(aipsSocket.getInputStream());
      } catch (UnknownHostException e){
         System.out.println("Threw a socket");
      } catch (IOException e){
         System.out.println("Threw an IO");
      }
      
      if(aipsSocket != null && is != null && os != null){
         try {
            // query = new String("select Source, MJAD, Start, End, AC_Frequency, BD_Frequency, Mean_AC_Flux, Stddev_AC_Flux, Mean_BD_Flux, Stddev_BD_Flux from /tarzan/wyoung/antsol.sum where Source == \"3C84\"");
            String queryTable;
            String queryBytes;
            if(query.length() < 100){
               queryBytes = new String(" " + query.length());
            }else{
               queryBytes = new String("" + query.length());
            }
            queryTable = new String("send.table.query " + queryBytes + query);
            os.writeBytes(queryTable);
            String line;
            while((line=is.readLine()) != null){
               if(line.equals("thats.all.folks"))
                  break;
               results = results + line + ":";
            }
            is.close();
            os.close();
            aipsSocket.close();
         } catch(IOException e){
            System.out.println("Threw an IO write");
         }
      }
      return results;
   }
}
