
import java.util.Calendar;
import java.io.*;
import java.net.*;

/** This class forms a connection to ATABD on the C++ side of the JDBC
 * driver. It uses TCP/IP sockets to transfer queries and table information.
 *
 * @author Wes Young, Jason Ye, Boyd Waters
 */

public class QueryTable {
    String server;
    int    portNumber;
    int packetSize=65000;
    boolean fullinfo=false;
    
    /** Create a connection on server s, port p
     */
   public QueryTable( String s, int p){
      server = s;      //server = wotan
      portNumber = p;  // portNumber = 7002
   }

    /** Perform query query, get the rows starting with rowStart and numbering
     * numRows total.
     */

    public void setFullInfo(boolean b){
	fullinfo=b;
    }
    public String queryTable(String query, int rowStart, int numRows){
	//System.out.println("queryTable called");
	String additional = "\n<START = "+rowStart+" number = "+numRows+" >\n";
	query+=additional;
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
	 e.printStackTrace();
      } catch (IOException e){
         System.out.println("Threw an IO");
	 e.printStackTrace();
      }
      
      if(aipsSocket != null && is != null && os != null){
         try {
        
            String queryTable;
            String queryBytes;
            if(query.length() < 100){
               queryBytes = new String(" " + query.length());
            }else{
               queryBytes = new String("" + query.length());
            }
	    if(fullinfo)
		queryTable = new String("send.table.qfull " + queryBytes + query);
	    else{
		queryTable = new String("send.table.query " + queryBytes + query);
	    }
            os.writeBytes(queryTable);
        
	    //expecting an int indicating length of the string
	
	    
       
	    int len=is.readInt();
	    //    System.out.println("int is : "+ len);
	   
	    
	    

	   
	    
	    byte[] buf = new byte[len+16];
	    

	    int numread =0;

	    while(numread<len+16){
		if((len+16-numread)>packetSize)
		    numread += is.read(buf, numread, packetSize);
		else
		    numread+= is.read(buf, numread, len+16-numread);
		//System.out.println("read: "+numread);
	    }
	    results=new  String(buf);



	
            is.close();
            os.close();
            aipsSocket.close();
         } catch(IOException e){
            System.out.println("Threw an IO write");
         }
      }
     
      return results;
   }

    /** Updates a table using the String query. Currently, query is in XML
     * format to increase efficiency(see readme). In the future, if TaQl is
     * extended to allow updates to specified columns and rows, this method 
     * will become obsolete and all updates will be funneled through queryTable.
     */


  public String updateTable(String query){
     
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
	 e.printStackTrace();
      } catch (IOException e){
         System.out.println("Threw an IO");
	 e.printStackTrace();
      }
      
      if(aipsSocket != null && is != null && os != null){
         try {
        
            String queryTable;
            String queryBytes;
            if(query.length() < 100){
               queryBytes = new String(" " + query.length());
            }else{
               queryBytes = new String("" + query.length());
            }

	 
            queryTable = new String("send.table.updat " + queryBytes + query);
            os.writeBytes(queryTable);
        
	    //expecting an int indicating length of the string
	
	 
       
	    int len=is.readInt();
	    //   System.out.println("int is : "+ len);
	   
	    
	    

	   
	 
	 
	    byte[] buf = new byte[len+16];
	    int numread =0;

	    while(numread<len+16){
		if((len+16-numread)>packetSize)
		    numread += is.read(buf, numread, packetSize);
		else
		    numread+= is.read(buf, numread, len+16-numread);
		//	System.out.println("read: "+numread);
	    }
	    
	   
	    results=new  String(buf);



	
            is.close();
            os.close();
            aipsSocket.close();
	    
	   
         } catch(IOException e){
            System.out.println("Threw an IO write");
         }
      }
      
      return results;
   }

    /** Get the array indicated by query. Currently this is in XML 
     *format to allow for max efficiency. All arrays are obtained on
     * as as needed basis. If TaQL is extend to allow querying specific
     *rows and columns, this will become obsolete and array requests
     *will be funnelled through queryTable(string)
     */

    public String arrayInfo(String query){
	System.out.println("arrayQuery:" + query);
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
	 e.printStackTrace();
      } catch (IOException e){
         System.out.println("Threw an IO");
	 e.printStackTrace();
      }
      
      if(aipsSocket != null && is != null && os != null){
         try {
        
            String queryTable;
            String queryBytes;
            if(query.length() < 100){
               queryBytes = new String(" " + query.length());
            }else{
               queryBytes = new String("" + query.length());
            }

	 
            queryTable = new String("send.table.array " + queryBytes + query);
            os.writeBytes(queryTable);
        
	    //expecting an int indicating length of the string
	
	 
       
	    int len=is.readInt();
	    //   System.out.println("int is : "+ len);
	   
	    
	    

	   
	 
	 
	    byte[] buf = new byte[len+16];
	    int numread =0;

	    while(numread<len+16){
		if((len+16-numread)>packetSize)
		    numread += is.read(buf, numread, packetSize);
		else
		    numread+= is.read(buf, numread, len+16-numread);
		//	System.out.println("read: "+numread);
	    }
	    
	   
	    results=new  String(buf);



	
            is.close();
            os.close();
            aipsSocket.close();
	    
	   
         } catch(IOException e){
            System.out.println("Threw an IO write");
         }
      }
      System.out.println("array: "+results);
      return results;
   }

}

