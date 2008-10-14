import java.sql.*;
import java.util.*;

/** This class models an SQL type that contains an array object.
 * <p>
 * @author Jason Ye
 *<p>
 * 
 */ 

public class TableArray implements java.sql.Array{
    
    private Object m_array;
    private String m_typename;
    
    public TableArray(){

	m_typename="";
	m_array=null;
    }

    /** Sets the base type as a string.
     */

    public void setBaseTypeName(String a){

	m_typename=a;
    }

    /**Returns the string representing the base type.<p>
     * @exception SQLException if no type name is set. 
     */

    public String getBaseTypeName()
	throws SQLException{
	if(m_typename==null)
	    throw new SQLException("No type name set.");
	return m_typename;

    }
    
    /** Not implemented.<p>
     * @exception java.sql.SQLException if called
     */
    public int getBaseType()
	throws SQLException{
	throw new SQLException("not implemented");
    }
    
    /** Sets this instance's array object.
     */

    public void setArray(Object o){
	
	m_array=o;
    }

    /** Returns the array object stored in this instance.
     * <p>
     * @exception SQLException if no array object is set.
     */
    public Object getArray()
	throws SQLException{
	if(m_array==null)
	    throw new SQLException("No array object set.");
	return m_array;
    }

 
    /** Not implemented.<p>
     * @exception java.sql.SQLException if called
     */

    public Object getArray(Map map)
	throws SQLException{
	throw new SQLException("not implemented");

    }
    /** Not implemented.<p>
     * @exception java.sql.SQLException if called
     */
   
    
    public Object getArray(long index, int count)
	throws SQLException{

	throw new SQLException("not implemented");
    }


   
    /** Not implemented.<p>
     * @exception java.sql.SQLException if called
     */
   

    public Object getArray(long index, int count, Map map)
	throws SQLException{
	throw new SQLException("not implemented");
    }

  
    /** Not implemented.<p>
     * @exception java.sql.SQLException if called
     */
   
    public ResultSet getResultSet()
	throws SQLException{
	throw new SQLException("not implemented");
    }

   
    /** Not implemented.<p>
     * @exception java.sql.SQLException if called
     */
    public ResultSet getResultSet(Map map)
	throws SQLException{
	throw new SQLException("not implemented");
    }

  

    /** Not implemented.<p>
     * @exception java.sql.SQLException if called
     */
    
    public ResultSet getResultSet(long index, int count)
	throws SQLException{
	throw new SQLException("not implemented");

    }
    
    
    /** Not implemented.<p>
     * @exception java.sql.SQLException if called
     */
    
    public ResultSet getResultSet(long index, int count, Map map)
	throws SQLException{
	throw new SQLException("not implemented");

    }




}
