import java.sql.*;
import java.lang.*;
import java.util.*;

/** TableDriver is an implementation of java.sql.Driver.
 *<p> 
 *@author Jason Ye
 */

public class TableDriver implements Driver{

    // register this driver with the DriverManager

    static {
	try{
	    DriverManager.registerDriver (new TableDriver());
	}catch(SQLException e){
	    System.err.println("Cannot Register Driver");
	}
                                }
    /** Default Constructor.
     */
    public TableDriver(){

    }

   

    /** Checks to see if this driver will accept the given url.
     * The driver should accept url's with format:<br>
     * <li> host:server
     * <li> bernoulli:7003 <p>
     *
     * @param url the url in question
     * @return true if acceptable, false if unacceptable 
     * @exception SQLException if database error occurs
     *
     */
    public boolean  acceptsURL(String url) throws SQLException{

	boolean ret = true;
	StringTokenizer tok = new StringTokenizer(url, ":", false);
	String token="";
	while(tok.hasMoreTokens()){
	    token = tok.nextToken();
	    token = tok.nextToken();
	}
	try{
	    //System.out.println("port number: "+token);
	    Integer i = new Integer(token);
	    
	}
	
	catch(NumberFormatException e){
	    // System.out.println("unacceptable url");
	    ret=false;
	}
	
	return ret;
    }
    /** Get a Connection to the database.
     * @param url the url to connect to
     * @param info currently this parameter does not affect the 
     * connection in any way
     * @return the connection formed
     * @exception SQLException if database error occurs
     */
    public  Connection connect(String url, Properties info) throws SQLException {
	//no properites are required to connect

	//	System.out.println("TableDriver::conect");
	Connection con =null;
	if(acceptsURL(url)){
	    
	    con = new TableConnection(url, info);
	    

		
	}

	return con;
    }


    public int getMajorVersion(){

	return 1;
    }


    public int getMinorVersion(){
	return 0;
    }


    /** Not implemented.
     *@exception SQLException if called
     */

    public DriverPropertyInfo[] getPropertyInfo(String url, Properties info) throws SQLException
    {
	throw new SQLException("not implemented");
	
    }

    public boolean jdbcCompliant(){

	return false;
    }
    




}
