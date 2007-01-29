import java.sql.*;
import java.lang.*;
import java.util.*;

/** Models an implementation of java.sql.Connection.
 *<p>
 *@author Jason Ye
 */

public class TableConnection implements Connection{

    public static final int TRANSACTION_NONE = 11;
    public static final  int TRANSACTION_READ_COMMITTED= 12;
    public static final int TRANSACTION_READ_UNCOMMITED=13;
    public static final int TRANSACTION_REPEATABLE_READ=14;
    public static final int TRANSACTION_SERIALIZABLE=15; 
    private QueryTable m_qtable;
    private DataInterpreter m_parser;
    private boolean fullinfo= false;
	
    /** Construct a TableConnection to the table with the given url.
     * Currently, prop does not affect the connection in any way.
     *
     */

    public TableConnection(String url, Properties prop){
	StringTokenizer tok = new StringTokenizer(url, ":", false);
	String server="";
	int port=-1;

	if(tok.hasMoreTokens()){
	    server = tok.nextToken().trim();
	    if(tok.hasMoreTokens())
		port = (new Integer(tok.nextToken().trim())).intValue();
	    else
		System.err.println("Invalid url");
	}
	else
	    System.err.println("Invalid url");
	
	m_qtable =new QueryTable(server, port);
	m_parser = new DataInterpreter();
	

	
	

    }

    public void setFullInfo(boolean b){
	fullinfo=b;
    }

    /** Return a ResultSet of the result of querying with string qu
     * containing rows starting at start and numbering num.
     *
     *@param qu the TaQL query
     *@param start row number of the first row to get
     *@param num total number of rows to get
     * @return the result
     */

    public ResultSet query(String qu, int start, int num, Statement stmt){
	m_qtable.setFullInfo(fullinfo);
	String a =m_qtable.queryTable(qu, start, num);
	m_qtable.setFullInfo(false);
	ResultSet result;
	if(fullinfo){
	    m_parser.setFullInfo(true);
	    result = m_parser.parseResult(a,null);
	    m_parser.setFullInfo(false);
	    
	}
	else{
	    result = m_parser.parseResult(a,null);
	}
	((DataSet)result).setConnection(this);
	((DataSet)result).setStatement(stmt);
	
	int tqi=qu.indexOf("GIVING");
	if(tqi!=-1){
	    String tq = qu.substring(tqi);
	    tq= tq.replaceFirst("GIVING","").trim();
	    qu="SELECT FROM "+tq;
	    
	}
	((DataSet)result).setQuery(qu);
	((DataSet)result).setRowsPerPage(num);
	
	return result;
    }

    

    /**Update the table using the string qu. Currently qu is not official
     * TaQL. See readme for details.
     * @param qu the query
     *@return Result of the update
     */

    public String update(String qu){
	return m_qtable.updateTable(qu);

    }


    /** Create a Statement. 
     *@return Statement instance created
     * @throws SQLException if a database error occurs
     */
    
    public Statement createStatement() throws SQLException{
	return  new TaQLStatement(this);
	
    }
   

    /** Method used to get array info from the database.
     *@param s string representing the query that resulted in the ResultSet
     *@param row row number in the AIPS++ table
     *@param col column number in the AIPS++ table
     *@param type datatype of the array
     *@return string representing the array, in the format returned by
     *       putting an AIPS++ Array template into a stream
     */

    public String getArray(String s, int row, int col, String type){
	String arrayString="";
	arrayString+="<ARRAYINFO>\n";
	arrayString+="<QUERY> "+s+" </QUERY>\n";
	arrayString+="<ROW> "+row+" </ROW>\n";
	arrayString+="<COLUMN> "+col+"</COLUMN>\n";
	arrayString+="<TYPE> "+type+ " </TYPE>\n";
	arrayString+="</ARRAYINFO>\n";
	
	
	return m_qtable.arrayInfo(arrayString);

    }
    

    /** Not implemented.
     *@throws SQLException if called
     */

    
    public PreparedStatement prepareStatement(String sql)throws SQLException{
	throw new SQLException("not implemented");
	
	

    }


    /** Not implemented.
     *@throws SQLException if called
     */

    public CallableStatement prepareCall(String sql)    throws SQLException{
    
	throw new SQLException("not implemented");	
    }

    /** Not implemented.
     *@throws SQLException if called
     */

    public String nativeSQL(String sql)	throws SQLException{
	throw new SQLException("not implemented");

    }

    /** Not implemented.
     *@throws SQLException if called
     */

    public void setAutoCommit(boolean autoCommit)
	throws SQLException{
	throw new SQLException("not implemented");
	
    }

    /** Not implemented.
     *@throws SQLException if called
     */

    public boolean getAutoCommit()
	throws SQLException{

	throw new SQLException("not implemented");
	}								


    /** Not implemented.
     *@throws SQLException if called
     */


    public void commit()
	throws SQLException{

	throw new SQLException("not implemented");
	
	}
	  

     
    /** Not implemented.
     *@throws SQLException if called
     */


    public void rollback()
	throws SQLException{

	throw new SQLException("not implemented");
	}


    /** Not implemented.
     *@throws SQLException if called
     */


    public void close()
	throws SQLException{
	throw new SQLException("not implemented");

	}
    


    /** Not implemented.
     *@throws SQLException if called
     */

    public boolean isClosed()
	throws SQLException{
		throw new SQLException("not implemented");
		
	}



  /** Not implemented.
     *@throws SQLException if called
     */

    public DatabaseMetaData getMetaData()
	throws SQLException{
	throw new SQLException("not implemented");
	}

  /** Not implemented.
     *@throws SQLException if called
     */


    public void setReadOnly(boolean readOnly)
	throws SQLException{

	throw new SQLException("not implemented");
	}

  /** Not implemented.
     *@throws SQLException if called
     */

    public boolean isReadOnly()
	throws SQLException{
	throw new SQLException("not implemented");
	
	}
   
  /** Not implemented.
     *@throws SQLException if called
     */

    public void setCatalog(String catalog)
	throws SQLException {
	throw new SQLException("not implemented");

	}


  /** Not implemented.
     *@throws SQLException if called
     */
    
    public String getCatalog()
	throws SQLException{
	throw new SQLException("not implemented");

	}

  /** Not implemented.
     *@throws SQLException if called
     */


    public void setTransactionIsolation(int level)
	throws SQLException{
	throw new SQLException("not implemented");
	}



  /** Not implemented.
     *@throws SQLException if called
     */
    public int getTransactionIsolation()
	throws SQLException{
	throw new SQLException("not implemented");
	
	}

  /** Not implemented.
     *@throws SQLException if called
     */

    public SQLWarning getWarnings()
	throws SQLException{
	throw new SQLException("not implemented");
	
	}


 /** Not implemented.
     *@throws SQLException if called
     */
    public void clearWarnings()
	throws SQLException{
	throw new SQLException("not implemented");
	
	}
 /** Not implemented.
     *@throws SQLException if called
     */

    public Statement createStatement(int resultSetType,
				     int resultSetConcurrency)
	throws SQLException{
	throw new SQLException("not implemented");

	}
 /** Not implemented.
     *@throws SQLException if called
     */
    
    public PreparedStatement prepareStatement(String sql,
                                          int resultSetType,
                                          int resultSetConcurrency)
	throws SQLException{
throw new SQLException("not implemented");

	}


     /** Not implemented.
     *@throws SQLException if called
     */

    public CallableStatement prepareCall(String sql,
                                     int resultSetType,
                                     int resultSetConcurrency)
	throws SQLException{

	throw new SQLException("not implemented");
	
	}

 /** Not implemented.
     *@throws SQLException if called
     */
    public Map getTypeMap()
	throws SQLException{
	throw new SQLException("not implemented");
	
	}

 /** Not implemented.
     *@throws SQLException if called
     */
    public void setTypeMap(Map map)
	throws SQLException{
	throw new SQLException("not implemented");

	}
	
    /** Not implemented.
     *@throws SQLException if called
     */
    public void setHoldability(int holdability)
	throws SQLException{

	throw new SQLException("not implemented");
	}

 /** Not implemented.
     *@throws SQLException if called
     */
    public int getHoldability()
	throws SQLException{
	throw new SQLException("not implemented");
	
	}

    
 /** Not implemented.
     *@throws SQLException if called
     */

    public Savepoint setSavepoint()
	throws SQLException{
	throw new SQLException("not implemented");
	
	}

    /** Not implemented.
     *@throws SQLException if called
     */

    
    public Savepoint setSavepoint(String name)
	throws SQLException{
	throw new SQLException("not implemented");
	
	}

/** Not implemented.
     *@throws SQLException if called
     */

    public void rollback(Savepoint savepoint)
	throws SQLException{
	throw new SQLException("not implemented");

	}


/** Not implemented.
     *@throws SQLException if called
     */

    public void releaseSavepoint(Savepoint savepoint)
	throws SQLException{

	throw new SQLException("not implemented");
	}

    
/** Not implemented.
     *@throws SQLException if called
     */


    public Statement createStatement(int resultSetType,
				     int resultSetConcurrency,
				     int resultSetHoldability)
	throws SQLException{
	throw new SQLException("not implemented");

	}

/** Not implemented.
     *@throws SQLException if called
     */


    public PreparedStatement prepareStatement(String sql,
					      int resultSetType,
					      int resultSetConcurrency,
					      int resultSetHoldability)
	throws SQLException{
	throw new SQLException("not implemented");


	}
    
    
    /** Not implemented.
     *@throws SQLException if called
     */

    public CallableStatement prepareCall(String sql,
					 int resultSetType,
					 int resultSetConcurrency,
					 int resultSetHoldability)
	throws SQLException{
	throw new SQLException("not implemented");
	
	}

    /** Not implemented.
     *@throws SQLException if called
     */

    
    public PreparedStatement prepareStatement(String sql,
					      int autoGeneratedKeys)
	throws SQLException{
	throw new SQLException("not implemented");
	
	}

    /** Not implemented.
     *@throws SQLException if called
     */


    public PreparedStatement prepareStatement(String sql,
					      int[] columnIndexes)
	throws SQLException{
	throw new SQLException("not implemented");
	
	}
    
    
/** Not implemented.
     *@throws SQLException if called
     */

    public PreparedStatement prepareStatement(String sql,
					      String[] columnNames)
	throws SQLException{
	throw new SQLException("not implemented");

	}

    
}
