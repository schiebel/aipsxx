import java.sql.*;
import java.lang.*;
import java.util.*;

/** Models a java.sql.Statement.
 * @author Jason Ye
 */


public class TaQLStatement implements Statement{


    public static final int CLOSE_CURRENT_RESULT=987;
    public static final int KEEP_CURRENT_RESULT=988;
    public static final int CLOSE_ALL_RESULTS=989;
    public static final int SUCCESS_NO_INFO=990;
    public static final int EXECUTE_FAILED=991;
    public static final int RETURN_GENERATED_KEYS=992;
    public static final int NO_GENERATED_KEYS=993;
    private TableConnection m_con;
    private int m_fetchsize;
   
    /** Create a TaQLStatememt with TableConnection con.
     * fetchsize property defaults to 1000.
    */
 
    public TaQLStatement(TableConnection con){
	m_con=con;
	m_fetchsize=1000;
    }

    /** Excecute the TaQL query.
     * @param taql query 
     * @return ResultSet 
     * @exception SQLException if database error occurs
     */

    public ResultSet executeQuery(String taql)
	throws SQLException{
	
	ResultSet res= m_con.query(taql, 0, m_fetchsize, this);
	
	return res ;
	
    }
    

  /** Update the table. Currently taql is not official TaQL syntax.
   * This was done to increase efficiency. See readme for more info.
   * This method always returns 0.
   *<p>
     * @param taql query 
     * @return number rows updated
     * @exception SQLException if database error occurs
     */

    public int executeUpdate(String taql)
	throws SQLException{
	String res = m_con.update(taql);
	//System.out.println("Statement: Result of update is: "+res);
	res = res.replaceAll("thats.all.folks", "");
	if(!res.trim().equalsIgnoreCase("Done"))
	    throw new SQLException("update failed: "+res);
	//for now, always return 0, future, return number of rows modified
	return 0;
    }

    /** Not implemented. 
     * @throws SQLException if called
     */

    public void close()
	throws SQLException{
	throw new SQLException("not implemented");
    }
    /** Not implemented. 
     * @throws SQLException if called
     */


    public int getMaxFieldSize()
	throws SQLException{
	throw new SQLException("not implemented");

    }
    /** Not implemented. 
     * @throws SQLException if called
     */

    public void setMaxFieldSize(int max)
	throws SQLException{
	throw new SQLException("not implemented");
    }


    /** Not implemented. 
     * @throws SQLException if called
     */

    public int getMaxRows()
	throws SQLException{

	throw new SQLException("not implemented");
    }

    /** Not implemented. 
     * @throws SQLException if called
     */

    public void setMaxRows(int max)
	throws SQLException{
	throw new SQLException("not implemented");	
    }
    /** Not implemented. 
     * @throws SQLException if called
     */

    public void setEscapeProcessing(boolean enable)
	throws SQLException{
	throw new SQLException("not implemented");
    }
    /** Not implemented. 
     * @throws SQLException if called
     */

    public int getQueryTimeout()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }
    /** Not implemented. 
     * @throws SQLException if called
     */

    public void setQueryTimeout(int seconds)
	throws SQLException{
	throw new SQLException("not implemented");
    }
    /** Not implemented. 
     * @throws SQLException if called
     */

    public void cancel()
	throws SQLException{

	throw new SQLException("not implemented");
    }
    /** Not implemented. 
     * @throws SQLException if called
     */

    public SQLWarning getWarnings()
	throws SQLException{

	throw new SQLException("not implemented");
	
    } 
    /** Not implemented. 
     * @throws SQLException if called
     */

    public void clearWarnings()
	throws SQLException{
	throw new SQLException("not implemented");
    }
    /** Not implemented. 
     * @throws SQLException if called
     */

    public void setCursorName(String name)
	throws SQLException{
	throw new SQLException("not implemented");
    }
    /** Not implemented. 
     * @throws SQLException if called
     */
    
    public boolean execute(String sql)
	throws SQLException{
	throw new SQLException("not implemented");

	
    
    }
    /** Not implemented. 
     * @throws SQLException if called
     */
    
    public ResultSet getResultSet()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }

    /** Not implemented. 
     * @throws SQLException if called
     */

    public int getUpdateCount()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }			
    /** Not implemented. 
     * @throws SQLException if called
     */

    public boolean getMoreResults()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }


    /** Not implemented. 
     * @throws SQLException if called
     */

    public void setFetchDirection(int direction)
	throws SQLException{
	throw new SQLException("not implemented");
    }
    
    /** Not implemented. 
     * @throws SQLException if called
     */

    public int getFetchDirection()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }
    /** Set the number of rows to get at one time.
     *@param rows number of rows to get at one time
     */

    public void setFetchSize(int rows)
	throws SQLException{
	if(rows>1)
	    m_fetchsize=rows;
	
    }

    /** Gets the number of rows of data to get at one time. 
     * @return number of rows to get at a time
     * @throws SQLException if database error occurs
     */

    public int getFetchSize()
	throws SQLException{

	return m_fetchsize;
	
	
    }

    /** Not implemented. 
     * @throws SQLException if called
     */


    public int getResultSetConcurrency()
	throws SQLException{
	throw new SQLException("not implemented");

    }

    /** Not implemented. 
     * @throws SQLException if called
     */

    public int getResultSetType()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }
    /** Not implemented. 
     * @throws SQLException if called
     */

    public void addBatch(String sql)
	throws SQLException{
	throw new SQLException("not implemented");
    }
    /** Not implemented. 
     * @throws SQLException if called
     */


    public void clearBatch()
	throws SQLException{
	throw new SQLException("not implemented");
    }

    /** Not implemented. 
     * @throws SQLException if called
     */

    public int[] executeBatch()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }
    
    /** Not implemented. 
     * @throws SQLException if called
     */


    public Connection getConnection()
	throws SQLException{
	return m_con;
    }
    
    /** Not implemented. 
     * @throws SQLException if called
     */


    public boolean getMoreResults(int current)
	throws SQLException{
	throw new SQLException("not implemented");
	
    }

    /** Not implemented. 
     * @throws SQLException if called
     */


    

    public ResultSet getGeneratedKeys()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }


    /** Not implemented. 
     * @throws SQLException if called
     */

    public int executeUpdate(String sql,
			     int autoGeneratedKeys)
	throws SQLException

    {

	throw new SQLException("not implemented");
	
    }
    


    /** Not implemented. 
     * @throws SQLException if called
     */

    public int executeUpdate(String sql,
			     int[] columnIndexes)
	throws SQLException{

	throw new SQLException("not implemented");
	
    }
    

    /** Not implemented. 
     * @throws SQLException if called
     */

    public int executeUpdate(String sql,
			     String[] columnNames)
	throws SQLException{
	throw new SQLException("not implemented");
	
    }

    /** Not implemented. 
     * @throws SQLException if called
     */


    public boolean execute(String sql,
			   int autoGeneratedKeys)
	throws SQLException{
	throw new SQLException("not implemented");
		
    }	       
	

    /** Not implemented. 
     * @throws SQLException if called
     */

       
    public boolean execute(String sql,
                       int[] columnIndexes)
	throws SQLException{
	throw new SQLException("not implemented");
	
	
    }


    /** Not implemented. 
     * @throws SQLException if called
     */


    public boolean execute(String sql,
                       String[] columnNames)
	throws SQLException{
	throw new SQLException("not implemented");
	
    }
    

    /** Not implemented. 
     * @throws SQLException if called
     */


    public int getResultSetHoldability()
	throws SQLException{
	throw new SQLException("not implemented");
	
    }
    
    
}
