import java.sql.*;
import java.util.*;

/** Implementation of java.sql.ResultSetMetaData. This class also
 * contains methods for storing and accessing AIPS++ table specific
 * meta data such as keywords, etc...
 * @author Jason Ye 
 */

public class DataSetMetaData implements ResultSetMetaData{
    
    static int columnNoNulls = 0;
    static int columnNullable = 1;
    static int columnNullableUnknown =2;
    private Vector m_colNames;
    private Vector m_colType;
    private String m_tableName;
    private boolean m_readOnly;
    private String m_aipsTableName;
    private boolean m_delrow;
    private boolean m_insrow;
    private String m_errorMessage;
    private KeywordSet m_tableKeywords;
    private Hashtable m_colkw;
    
    /** Constructor.
     */
    
    public DataSetMetaData(){
	
	m_colNames = new Vector();
	m_colType = new Vector();
	m_readOnly= true;
	m_tableName="";
	m_delrow=false;
	m_insrow=false;
	m_errorMessage="";
	m_colkw = new Hashtable();
	m_tableKeywords = new KeywordSet();
	
    }

    /** Return the table keywords in a KeywordSet.
     * @return KeywordSet containing this table's keywords.
     */

    public KeywordSet getTableKW(){
	return m_tableKeywords;
	
    }

    /** Return a Hashtable mapping each column number to a KeywordSet
     * containing that column's Keywords. Not all columns will have keywords.
     * Column numbering for the map starts at 1.
     */

    public Hashtable getColumnKW(){
	return m_colkw;
    }

    /** Set the error message to t.
     */


    public void setErrorMessage(String t){
	m_errorMessage =t;
    }
    
    /** Get the error message.
     *@return the error message.
     */
    public String getErrorMessage(){
	return m_errorMessage;
    }

    /** Set the name of the table that the parent DataSet represents.
     * @param t table name
     */
    public void setTableName(String t){
	m_aipsTableName=t;
	
    }


    /** Set the name of the table that the parent DataSet represents.
     * @return table name
     */

    public String getTableName(){
	return m_aipsTableName;
    }

    /** Set whether deleting rows from the table is allowed.
     * @param b true if allowed, false if not
     */

    public void setDelRow(boolean b){
	m_delrow=b;
    }

    

    /** Get whether deleting rows from the table is allowed.
     * @return true if allowed, false if not
     */

    
    public boolean getDelRow(){
	return m_delrow;
    }

    /** Set whether inserting rows from the table is allowed.
     * @param b true if allowed, false if not
     */

    public void setInsRow(boolean b){

	m_insrow=b;
    }


    /** Get whether inserting rows from the table is allowed.
     * @return true if allowed, false if not
     */
    

    public boolean getInsRow(){

	return m_insrow;
    }

    /** Not implemented.
     *@exception SQLException if called
     */


    public String getCatalogName(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }
    
    /** Not implemented.
     *@exception SQLException if called
     */
    
    public String getColumnClassName(int column) throws SQLException {
	throw new SQLException("Not Implemented");
    }

    /** Get the number of columns in the parent DataSet.
     * @return the number of rows.
     * @exception if database error
     */

    public int getColumnCount() throws SQLException{
	return m_colNames.size();
	
    }

    /** Not implemented.
     *@exception SQLException if called
     */

    public int getColumnDisplaySize(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }
    /** Not implemented.
     *@exception SQLException if called
     */


    public String getColumnLabel(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }


    /** Insert the name of the next column.
     * @param a name of next column
     * @exception SQLException if database error
     */

    public void insertColumnName(String a) throws SQLException{
	m_colNames.add(a);
    }

    /** Get the name of the i-th column. Numbering starts at 1.
     * @param column the column number
     * @return the column name
     *@exception SQLException if database error 
     */

    public String getColumnName(int column) throws SQLException{
	return (String)m_colNames.elementAt(column-1);
    }

    /** Not implemented.
     *@exception SQLException if called
     */

    public int getColumnType(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }


    /** Insert the type of the next column as a string.
     * @param a type of next column
     * @exception SQLException if database error
     */


    public void insertColumnTypeName(String a) throws SQLException{
	m_colType.add(a);
    }
 
    /** Get the type of the i-th column as a string. Numbering starts at 1.
     * @param column the column number
     * @return the column type name
     *@exception SQLException if database error 
     */
    public String getColumnTypeName(int column) throws SQLException{
	if(column-1>=m_colType.size()||column<1){
	    throw new SQLException("invalid column number: "+column);
	}
	
	
	return (String)m_colType.elementAt(column-1);
	
    }

 /** Not implemented.
     *@exception SQLException if called
     */

    public int getPrecision(int column) throws SQLException{
	throw new SQLException("Not Implemented");

    }

 /** Not implemented.
     *@exception SQLException if called
     */

    public int getScale(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }
     
 /** Not implemented.
     *@exception SQLException if called
     */

    public String getSchemaName(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }
    
   
    /** Not implemented.
     *@exception SQLException if called
     */

    public String getTableName(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }

 /** Not implemented.
     *@exception SQLException if called
     */


    public boolean isAutoIncrement(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }
 /** Not implemented.
     *@exception SQLException if called
     */


    public boolean isCaseSensitive(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }
 /** Not implemented.
     *@exception SQLException if called
     */


    public boolean isCurrency(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }

 /** Not implemented.
     *@exception SQLException if called
     */

    public boolean isDefinitelyWritable(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }

 /** Not implemented.
     *@exception SQLException if called
     */


    public int isNullable(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }

   /** Not implemented.
     *@exception SQLException if called
     */
    public boolean isReadOnly(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }
    
 /** Not implemented.
     *@exception SQLException if called
     */

    public boolean isSearchable(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }
    
 /** Not implemented.
     *@exception SQLException if called
     */


    public boolean isSigned(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }

    
 /** Not implemented.
     *@exception SQLException if called
     */

    public boolean isWritable(int column) throws SQLException{
	throw new SQLException("Not Implemented");
    }

}

