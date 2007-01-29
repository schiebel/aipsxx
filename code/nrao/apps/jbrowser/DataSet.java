import java.sql.*;
import java.lang.*;
import java.io.*;
import java.math.*;
import java.net.*;
import java.util.*;
import java.nio.*;
import java.sql.Date;

/**
 * Implementation of java.sql.ResultSet. Uses a vector that contains the
 * rows of the table, which are in turn vectors themselves. 
 *<p>
 *
 * This ResultSet does not do type check on get or update methods. It 
 * is up to the user to make sure that s/he is getting or updating the
 * correct type in order to prevent a ClassCastException.
 *
 * Get and UpdateMethods may be called when the cursor is not on a valid
 * row, but it will cause an SQLException. It is up to the user to 
 *make sure that the cursor is on a valid row before calling these.
 *
 * Take caution when making a ResultSet from a TaQL string that has
 * conditions. For example SELECT FROM table WHERE ANTENNA1 == 5.
 * If any of the entries of the resulting table are altered such that
 * the condition no longer applies, that row will not appear in subsequent
 * cachings. To prevent this, make a temporary table by querying:
 * SELECT FROM table WHERE ANTENNA1==5 GIVING temptable while making sure
 * you have write access for the path of temptable and then query:
 * SELECT FROM temptable to get the desired resultset.
 *
 * After updating a row, must call updateRow() to save the updates.
 * Moving the cursor away before calling updateRow(), will cause the
 * updates not to be saved to the database. Furthermore, these updates
 * may or may not be reflected in the ResultSet. To prevent complications
 * also call cancelRowUpdates before moving the cursor away, if saving
 * is not desired.
 *
 * @author Jason Ye
*/


public class DataSet implements ResultSet{

    public static int FETCH_FORWARD =8986;
    public static int FETCH_REVERSE =8867;
    public static int FETCH_UNKNOWN =1345;
    public static int TYPE_FORWARD_ONLY=3452;
    public static int TYPE_SCROLL_INSENSITIVE = 1344;
    public static int TYPE_SCROLL_SENSITIVE = 3145;
    public static int CONCUR_READ_ONLY=2762;
    public static int CONCUR_UPDATABLE=3169;
    public static int INSERT_ROW_INDEX=-9;
    
    private Vector m_rows;
    private int m_rowIndex;
    private DataSetMetaData m_metaData;
    private int m_totalRows;
    private int m_firstIndex;
    private int m_rowsPerPage;
    private TableConnection m_con;
    private String m_query;
    private Statement m_stmt;
    private Vector m_updatelog;
    private Vector m_insertRow;
    private int m_fetchdirection=FETCH_FORWARD;
    private int m_type = TYPE_SCROLL_INSENSITIVE;
    private int m_concurrency =CONCUR_UPDATABLE;
    private boolean m_deleted=false;
    private int m_rememberedrow=-1;
    private Hashtable m_rowsInserted;
    private Hashtable m_rowsUpdated;
    private Vector m_insRowUpdates;
    private boolean fullinfo;
    /** Constructor.
     */
    
    public DataSet(){

	m_rows = new Vector();
	m_rowIndex=0;
	m_firstIndex=1;
	m_rowsPerPage=1000;
	m_metaData = new DataSetMetaData();
	m_totalRows=0;
	m_query="";
	m_rowsInserted=new Hashtable();
	m_rowsUpdated=new Hashtable();
	m_insRowUpdates=new Vector();
	m_updatelog=new Vector();
	m_insertRow=new Vector();

    }

    public void setFullInfo(boolean b){
	fullinfo=b;
    }


    /** Insert a vector of Update's in to hashtable.
     */
    public void insertUpdate(Update up){
	if(m_rowIndex==INSERT_ROW_INDEX){

	    m_insRowUpdates.add(up);
	}
	
	else {
	   
	    m_updatelog.add(up);
	}
    }

 //    /** Retrieve the vector of Update's from the hashtable at
//      * key row.
//      */
//     public Vector getUpdate(int row){
// 	return (Vector)m_updatelog.get(new Integer(row));
//     }

    /** Set the Statement that created this ResultSet.
     */
    public void setStatement(Statement stmt){
	m_stmt=stmt;
	
    }



    /** Set the TaQL String that resulted in this DataSet to q.
     */



    public void setQuery(String q){
	m_query=q;
    }

    /** Set the Connection reference of this DataSet to con.
     */

    public void setConnection(TableConnection con){
	
	m_con =con;
    }
    
    /** Set number of rows to show per page.
     */

    public void setRowsPerPage(int row){
	m_rowsPerPage=row;
    }
    
    /** Insert the KeywordSet for column a.
     */

    public void insertColKW(KeywordSet kws , int a){
	m_metaData.getColumnKW().put(new Integer(a), kws);
	
    }

    /** Get the data Vector.
     */

    public Vector getDataVector(){
	return m_rows;
    }
    /** Set the data Vector to rows. Rows must be a Vector of Vectors.
     */

    public void setDataVector(Vector rows){
	
	m_rows=rows;
    }

    /** Set the total number of rows to a.
     */

    public void setTotalRows(int a){

	m_totalRows=a;
    }

    /** Get the total number of rows.
     */

    public int getTotalRows(){

	return m_totalRows;
    }
    

    /** Get the error message.
     */
    
    public String getErrorMessage(){
	return m_metaData.getErrorMessage();

    }

    /** 
     * Creates a new row and appends it to the end of table.
     * Use to manually create the table.
     */

    public void addRow() {
	Vector newRow = new Vector();
	m_rows.add(newRow);
	//System.out.println("add row");

    }
    
  
    /** See java.sql.ResultSet. Type of ResultSet not considered.
     * @throws SQLException only if database error 
     */

    public boolean absolute(int row) throws SQLException{
	boolean ret = false;
	
	
	if(row>0 && row<m_totalRows+1){
	    m_rowIndex=row;
	    ret=true;
	}
	else if(row<0 && Math.abs(row)<m_totalRows+1){
	    m_rowIndex = m_totalRows+1+row;
	    ret=true;
	}
	
	
	if(m_rowIndex>=m_firstIndex+m_rowsPerPage){
	    m_firstIndex=m_rowIndex;
	    m_rows =null;
	    m_con.setFullInfo(fullinfo);
	    DataSet das = (DataSet)m_con.query(m_query, m_rowIndex-1, m_rowsPerPage, m_stmt);
	    m_con.setFullInfo(false);
	    m_rows=das.getDataVector();
	    
	    
	    }
	
	else if(m_rowIndex<m_firstIndex){
	    m_firstIndex=m_rowIndex;
	    m_rows =null;
	    
	    m_con.setFullInfo(fullinfo);
	    DataSet das = (DataSet)m_con.query(m_query, m_rowIndex-1, m_rowsPerPage, m_stmt);
	    m_con.setFullInfo(false);
	    m_rows=das.getDataVector();
	    
	    
	}
	
	
// 	ret=true;
//     }
    
//     else if(row<0 && Math.abs(row)<m_totalRows+1){
// 	m_rowIndex = m_totalRows+1+row;
	
	    


// 	    m_firstIndex=m_rowIndex;
// 	    m_rows =null;
// 	    DataSet das = (DataSet)m_con.query(m_query, m_rowIndex-1, m_rowsPerPage);
// 	    m_rows=das.getDataVector();
// 	    ret=true;
// 	}

	
// 	//type not considered

	m_updatelog.clear();
	
	return ret;

    }

 
    /** See java.sql.ResultSet. Type of ResultSet not considered.
     * @throws SQLException only if database error 
     */

    public void afterLast() throws SQLException{
	if(m_totalRows!=0){
	    last();
	    m_rowIndex = m_totalRows+1;
	}
	//type not considered
	m_updatelog.clear();
    }

  
    /** See java.sql.ResultSet. Type of ResultSet not considered.
     * @throws SQLException only if database error 
     */
    public void beforeFirst() throws SQLException{
	if(m_totalRows!=0){
	    first();
	    m_rowIndex=0 ;
	}
	//type not considered
	m_updatelog.clear();


    }


  
    /** See java.sql.ResultSet. 
     */
    public void cancelRowUpdates() throws SQLException{
	if(m_rowIndex==INSERT_ROW_INDEX){
	    throw new SQLException("Cannot cancel updates from insertrow");
	    
	}
	else{
	   
	    for(int i=0;i<m_updatelog.size();i++){
		
		undo((Update)m_updatelog.elementAt(i));
		
	    }
	    
	}
	
	m_updatelog.clear();

    }

    /** This method undos the changes to a particular row in the case
     * of a call to method cancelRowUpdates()
     */

    private void undo(Update up){
	int col = up.getColumn();
	int row = up.getRow();
	Object oldVal = up.getOld();
	Vector r = (Vector)m_rows.elementAt(row-m_firstIndex);
	r.setElementAt(oldVal,col-1);
	//System.out.println("undo row: "+row+" col: "+col+" old: "+oldVal);

    }
    /** Not implemented.
     *@throws SQLException if called
     */
    
    public void clearWarnings() throws SQLException {
	throw new SQLException("Not Implemented");
    }

    /** Not implemented.
     *@throws SQLException if called
     */
    
    public void close()throws SQLException{
	throw new SQLException("Not Implemented");
    }

    /** @see java.sql.ResultSet.
     */

    public void deleteRow() throws SQLException{
	//System.out.println("num rows before delete: "+m_totalRows);
	if(m_rowIndex==INSERT_ROW_INDEX)
	    throw new SQLException("cannot delete the insert row");
	String s = "<DELROW " +(m_rowIndex-1)+" >\n";
	String query = makeUpdateCommand(s);
	String res = m_con.update(query);
	res=res.replaceAll("thats.all.folks", "");
	if(!res.trim().equalsIgnoreCase("Done")){
	    throw new SQLException("DataBase Error: "+res);

	}
	m_deleted=true;
	

	
	m_rows.remove(m_rowIndex-1);
	for(int i=1;i<m_totalRows+1;i++){
	    if(i==m_rowIndex){
		m_rowsUpdated.remove(new Integer(i));
	    }
	    else if(i>m_rowIndex){
		if(m_rowsUpdated.containsKey(new Integer(i))){
		    m_rowsUpdated.remove(new Integer(i));
		    m_rowsUpdated.put(new Integer(i-1),"T");
		}
	    }
	}
	m_totalRows--;
	
	m_con.setFullInfo(fullinfo);
	DataSet das = (DataSet)m_con.query(m_query, m_firstIndex-1, m_rowsPerPage, m_stmt);
	m_con.setFullInfo(false);
	m_rows=das.getDataVector();
	
	
	m_updatelog.clear();

    }
   
    /** @see java.sql.ResultSet.
     */

    public int findColumn(String columnName) throws SQLException{
	int ret =-1;
	
	try{
	    
	for(int i=1; i<m_metaData.getColumnCount()+1;i++){
	    
	    if(columnName.equals(m_metaData.getColumnName(i)))
		ret=i;
 
	}
	}catch(SQLException e){
	    //   e.printStackTrace();
	}

	if(ret==-1)
	    throw new SQLException("column name is invalid");
	
	return ret;
    }

    /** See java.sql.ResultSet. Type of ResultSet not considered.
     * @throws SQLException only if database error 
     */


    public boolean first()  throws SQLException{
	//type not considered
	boolean ret= true;
	if(m_totalRows==0)
	    ret=false;
	this.absolute(1);
	m_updatelog.clear();
	return ret;
    }

    /** Get the Array value in the given column. Because array info is not
     * stored in the ResultSet, this method queries ATABD for the array. 
     * See java.sql.ResultSet.
     *@exception SQLException if ATABD cannot be reached or database error
     */
   

    public Array getArray (int i)throws SQLException  {
	

	if(m_rowIndex==INSERT_ROW_INDEX){
	    return (Array)m_insertRow.elementAt(i);
	}
	
	else{
	    if(fullinfo){
		Array a=null;
		try{
		    a =(Array)((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).elementAt(i-1);
		}
		catch(Exception e){
		    System.out.println((String)((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).elementAt(i-1));
		    e.printStackTrace();
		}
		return a;
	    }
	    else{
		System.out.println("ds: rowindex: "+(m_rowIndex-1));
		String s =m_con.getArray(m_query, m_rowIndex-1, i-1, m_metaData.getColumnTypeName(i));
		if(s.equals(""))
		    throw new SQLException("Database access error");
		
	    
		ArrayBrowser b = new ArrayBrowser( s, m_metaData.getColumnTypeName(i));
		TableArray a = new TableArray();
		a.setBaseTypeName( m_metaData.getColumnTypeName(i));
		a.setArray(b);
		return a;
	    }
	}

    }
 
    /**@see getArray(int i)
     *@see java.sql.ResultSet
     *@exception SQLException if colName does not exist
     */
    
    
    public Array getArray (String colName) throws SQLException
    {
	
	return getArray(findColumn(colName));

    }
    
    /**@see java.sql.ResultSet
     */
    
    public InputStream getAsciiStream(int columnIndex) throws SQLException{
	try{
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (InputStream)m_insertRow.elementAt(columnIndex-1);
	    else
		return (InputStream)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}

    }
    
    /**@see java.sql.ResultSet
     */
    
    public InputStream getAsciiStream(String colName) throws SQLException{
	
	return getAsciiStream(findColumn(colName));
	
    }

    /**@see java.sql.ResultSet
     */
    
    public BigDecimal getBigDecimal(int columnIndex) throws SQLException{

	//null not considered
	try{
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (BigDecimal)m_insertRow.elementAt(columnIndex-1);
	    else
		return	(BigDecimal)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
    }
   
    /** Not Implemented. Deprecated.
     *@exception SQLException if called
     */

    public BigDecimal getBigDecimal(int columnIndex, int scale) throws SQLException
    {
	throw new SQLException("Not Implemented, Depricated");
    }
  
    

     /**@see java.sql.ResultSet
     */
    public BigDecimal getBigDecimal(String columnName) throws SQLException {
	
	return getBigDecimal(findColumn(columnName));
	
    }

 
    /** Not Implemented. Deprecated.
     *@exception SQLException if called
     */
    public BigDecimal getBigDecimal(String columnName, int scale)throws SQLException
    {
    	throw new SQLException("Not Implemented, Depricated");
    }
   
   
    /**@see java.sql.ResultSet
	*/

    public InputStream getBinaryStream(int columnIndex) throws SQLException {
	
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (InputStream)m_insertRow.elementAt(columnIndex-1);
	    else
		return	(InputStream)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
	
    }
   
  

    /**@see java.sql.ResultSet
	*/

    public InputStream getBinaryStream(String columnName)  throws SQLException{
	
	return getBinaryStream(findColumn(columnName));

    }

    

    /**@see java.sql.ResultSet
	*/



    public Blob getBlob(int columnIndex) throws SQLException {
	try{
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (Blob)m_insertRow.elementAt(columnIndex-1);
	    else
		return (Blob)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}	
    }

 
    /**@see java.sql.ResultSet
	*/
    

    public Blob getBlob(String columnName)  throws SQLException {
	return getBlob(findColumn(columnName));
    }
    
    /**@see java.sql.ResultSet
     */

    public boolean getBoolean(int columnIndex)throws SQLException {
	//null not considered
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX)
		return ((Boolean)m_insertRow.elementAt(columnIndex-1)).booleanValue();
	    else
		return ((Boolean)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1)).booleanValue();
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}

	
    }
      /**@see java.sql.ResultSet
     */
    public boolean getBoolean(String columnName) throws SQLException{
	//null not considered
	return getBoolean(findColumn(columnName));
	

    }
    
 /**@see java.sql.ResultSet
     */
    public byte getByte(int columnIndex)throws SQLException {

	//null not considered
	try{

	    
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return ((Byte)m_insertRow.elementAt(columnIndex-1)).byteValue();
	    else
		return	((Byte)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1)).byteValue();
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
	
    }
    
    /**@see java.sql.ResultSet
     */
    
    public byte getByte(String columnName)throws SQLException{
	
	//null not considered
	return getByte(findColumn(columnName));
	
    }
    
    /**@see java.sql.ResultSet
     */

    public byte[] getBytes(int columnIndex)throws SQLException{
	//null not considered
	try{

	    
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return ((ByteBuffer)m_insertRow.elementAt(columnIndex-1)).array();
	    else
		return ((ByteBuffer)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1)).array();
	}
	
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
    }

   /**@see java.sql.ResultSet
     */
    public byte[] getBytes(String columnName)throws SQLException{

	//null not considered
	
	return getBytes(findColumn(columnName));
	
    }	


    /**@see java.sql.ResultSet
	*/

  
    public Reader getCharacterStream(int columnIndex)throws SQLException{
	try{

	    
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (Reader)m_insertRow.elementAt(columnIndex-1);
	    else
		return (Reader)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);
	}
	
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
	
    }
    


    /**@see java.sql.ResultSet
     */
	
    public Reader getCharacterStream(String columnName)throws SQLException{
	return getCharacterStream(findColumn(columnName));

    }
   
  
    /**@see java.sql.ResultSet
     */

    public Clob getClob(int columnIndex)throws SQLException{
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (Clob)m_insertRow.elementAt(columnIndex-1);
	    else
		return (Clob)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);
	}
	
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
    }
  

    /**@see java.sql.ResultSet
     */

    public Clob getClob(String columnName)throws SQLException{
	return getClob(findColumn(columnName));
    }
    
    /**@see java.sql.ResultSet
     */

    public int getConcurrency ()throws SQLException{
	return m_concurrency;
	
    }
   
    /** Always returns "UPDATABLE_SCROLLABLE".
     *
     */
  
    public String getCursorName ()throws SQLException{
	return "UPDATABLE_SCROLLABLE";
    }
    
    /**@see java.sql.ResultSet
     */
    
    public Date getDate(int columnIndex)throws SQLException{
	//null not considered
	try{
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (Date)m_insertRow.elementAt(columnIndex-1);
	    else
	    
		return (Date)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);

	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}

    }


    /**Not implemented.
     *@exception SQLException if called
     */
    public  Date getDate(int columnIndex, Calendar cal)throws SQLException {

		throw new SQLException("Not Implemented");
    }
    
     /**@see java.sql.ResultSet
     */

    public Date getDate(String columnName)throws SQLException{

	//null not considered
	return getDate(findColumn(columnName));
    }

    /**@see java.sql.ResultSet
     */
    
    public  Date getDate(String columnName, Calendar cal)throws SQLException {
	throw new SQLException("Not Implemented");
	
    }

    /**@see java.sql.ResultSet
     */
    public double getDouble(int columnIndex)throws SQLException {
	//null not considered
	try{
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return ((Double)m_insertRow.elementAt(columnIndex-1)).doubleValue();
	    else
		
		return ((Double)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1)).doubleValue();
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
	
    }

    /**@see java.sql.ResultSet
     */
    
    public double getDouble(String columnName)throws SQLException {
	//null not considered
	return getDouble(findColumn(columnName));
    }

  
    /**@see java.sql.ResultSet
     *
     */
    public int getFetchDirection() throws SQLException
    {

	return m_fetchdirection;
    }

    /**
     *@see java.sql.ResultSet
     */
    

    public int  getFetchSize()throws SQLException{
	return m_rowsPerPage;
    }
  /**@see java.sql.ResultSet
     */
    public float getFloat(int columnIndex)throws SQLException{
	//null not considered
	try{
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return ((Float)m_insertRow.elementAt(columnIndex-1)).floatValue();
	    else
		return ((Float)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1)).floatValue();
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
	
    }
  /**@see java.sql.ResultSet
     */
    public float getFloat(String columnName)throws SQLException{
	return getFloat(findColumn(columnName));

    }
    
    /**@see java.sql.ResultSet
     */

    public int getInt(int columnIndex) throws SQLException{

	try{
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return ((Integer)m_insertRow.elementAt(columnIndex-1)).intValue();
	    else
		return ((Integer)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1)).intValue();
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
    }

    /**@see java.sql.ResultSet
     */
    public int getInt(String columnName)throws SQLException {
	return getInt(findColumn(columnName));
    }

  /**@see java.sql.ResultSet
     */

    public long getLong(int columnIndex)throws SQLException{
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX)
		return ((Long)m_insertRow.elementAt(columnIndex-1)).longValue();
	    else
		return ((Long)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1)).longValue();
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}

    }
    /**@see java.sql.ResultSet
     */
    public long getLong(String columnName)throws SQLException{
	return getLong(findColumn(columnName));
    }

  /**@see java.sql.ResultSet
     */
    public ResultSetMetaData getMetaData()throws SQLException{
	
	return m_metaData;
    }
    
    /**@see java.sql.ResultSet
     */


    public Object getObject(int columnIndex) throws SQLException{
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX)
		return m_insertRow.elementAt(columnIndex-1);
	    else
		return ((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
	
}


    /**Not implemented.
     *@exception SQLException if called
     */
    public Object getObject(int i, Map map)throws SQLException{
	throw new SQLException("Not Implemented");
	
    }


      /**@see java.sql.ResultSet
     */
    public Object getObject(String columnName)throws SQLException
    {
	return getObject(findColumn(columnName));
    }

    /**Not implemented.
     *@exception SQLException if called
     */
    public Object getObject(String colName, Map map)throws SQLException{
	throw new SQLException("Not Implemented");
    }

    /**@see java.sql.ResultSet
     */
    
    public Ref getRef(int columnIndex) throws SQLException{
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (Ref)m_insertRow.elementAt(columnIndex-1);
	    else
		return (Ref)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
	
    }

   /**@see java.sql.ResultSet
	*/
    public Ref getRef(String columnName)throws SQLException{
	
	return getRef(findColumn(columnName));
    }

    /**@see java.sql.ResultSet
     */

    public int getRow()throws SQLException {

	return m_rowIndex;
    }

    /**@see java.sql.ResultSet
     */
    public short  getShort(String columnName) throws SQLException {

	
	return getShort(findColumn(columnName));

    }
                 
    /**@see java.sql.ResultSet
     */          
    public short getShort(int columnIndex) throws SQLException {
	try{ 
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return ((Short)m_insertRow.elementAt(columnIndex-1)).shortValue();
	    else
		return ((Short)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1)).shortValue();
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
	

    }

     /**@see java.sql.ResultSet
     */  
  
    public Statement getStatement() throws SQLException{


	return m_stmt;
	
    }

    /**@see java.sql.ResultSet
     */

    public String getString(int columnIndex) throws SQLException{

	try{
	    if(m_rowIndex==INSERT_ROW_INDEX){
		return (String)m_insertRow.elementAt(columnIndex-1); 
	    }
	    else{
		return (String)((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).elementAt(columnIndex-1);
	    }
	}
	catch(ArrayIndexOutOfBoundsException e){
	   
	    throw new SQLException("invalid column or row");
	}
	
    }

    /**@see java.sql.ResultSet
     */

    public String getString(String columnName) throws SQLException{
	int index = findColumn(columnName);
	return getString(index);

    }

    /**@see java.sql.ResultSet
     */

    public Time getTime(int columnIndex)throws SQLException{
	try{
	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (Time)m_insertRow.elementAt(columnIndex-1);
	    else
		return (Time)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);	
	}

	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}
    }
    

    /**Not implemented.
     *@exception SQLException if called
     */

    public Time getTime(int columnIndex, Calendar cal)throws SQLException{
	throw new SQLException("Not Implemented");

    }

    /**@see java.sql.ResultSet
     */
    public Time getTime(String columnName)throws SQLException{
	return getTime(findColumn(columnName));

    }

    /**Not implemented.
     *@exception SQLException if called
     */
    public Time getTime(String columnName, Calendar cal)throws SQLException{

	throw new SQLException("Not Implemented");
    }

    /**@see java.sql.ResultSet
     */
    public Timestamp getTimestamp(int columnIndex) throws SQLException{
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (Timestamp)m_insertRow.elementAt(columnIndex-1);
	    else
		return (Timestamp)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);	
	}

	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}

    }

    /**Not implemented.
     *@exception SQLException if called
     */
    
    public Timestamp getTimestamp(int columnIndex, Calendar cal)throws SQLException{
	throw new SQLException("Not Implemented");

    }

    /**@see java.sql.ResultSet
     */
    public Timestamp getTimestamp(String columnName)throws SQLException{
	return getTimestamp(findColumn(columnName));
    }

    /**Not implemented.
     *@exception SQLException if called
     */
    public Timestamp getTimestamp(String columnName, Calendar cal)throws SQLException{

	throw new SQLException("Not Implemented");

    }

    /**@see java.sql.ResultSet
     */
    public  int  getType()throws SQLException{
	
	return m_type;
    }

   
    
 
    /**@see java.sql.ResultSet
	*/


    public InputStream getUnicodeStream(int columnIndex)throws SQLException{
	
	try{


	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (InputStream)m_insertRow.elementAt(columnIndex-1);
	    else
		return (InputStream)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);	
	}

	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}


    }

    /**@see java.sql.ResultSet
	*/


    public InputStream getUnicodeStream(String columnName)throws SQLException{
	return getUnicodeStream(findColumn(columnName));
	
    }
    
    /**@see java.sql.ResultSet
     */
    public URL getURL(int columnIndex)throws SQLException{
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX)
		return (URL)m_insertRow.elementAt(columnIndex-1);
	    else
		return (URL)((Vector)m_rows.elementAt(m_rowIndex-1)).elementAt(columnIndex-1);	
	}
	catch(ArrayIndexOutOfBoundsException e){
	    throw new SQLException("invalid column or row");
	}

	
    }


    /**@see java.sql.ResultSet
     */
    public URL getURL(String columnName)throws SQLException{
	return getURL(findColumn(columnName));
    }


 
    /**Not implemented.
     *@exception SQLException if called
     */

    
    public SQLWarning getWarnings()throws SQLException{
	throw new SQLException("Not Implemented");
 
    }
    
  
    /**@see java.sql.ResultSet
     */
    public void insertRow() throws SQLException{
	if(m_rowIndex!=INSERT_ROW_INDEX)
	    throw new SQLException("Cannot insert row when cursor is not on the insert row");
	m_rows.add(m_insertRow);
	//insert into database
	//increase total row number. insert this number in rowinserted.
	String s = "<ADDROW>\n";
	//	System.out.println("insrowupdates size: "+m_insRowUpdates.size() );
	for (int i=0; i<m_insRowUpdates.size();i++){
	    s+=((Update)(m_insRowUpdates.elementAt(i))).toUpdateString();
	    
	}
	
	String query = makeUpdateCommand(s);
	m_totalRows++;
	//	System.out.println("insertRow command:\n "+query);
	String res = m_con.update(query);

	res= res.replaceAll("thats.all.folks", "");
	//System.out.println("result of ins row "+res);
	if(!res.trim().equalsIgnoreCase("Done"))
	    throw new SQLException("Database Error: "+res);
	m_rowsInserted.put(new Integer(m_totalRows), "#");
	m_insRowUpdates.clear();
	m_insertRow = new Vector();
	
    }

    /**@see java.sql.ResultSet
     */
    public boolean isAfterLast() throws SQLException {
	boolean ret= false;
	if(m_rowIndex==m_totalRows+1)
	    ret=true;

	return ret;
    }

     /**Insert the insert row into the bottom of the table.
      *@see java.sql.ResultSet
      */
    public boolean isBeforeFirst()throws SQLException {
	boolean ret= false;
	if(m_rowIndex==0)
	    ret=true;

	return ret;
    }

    /**@see java.sql.ResultSet
     */
    
    public boolean isFirst()throws SQLException{
	boolean ret = false;
	if(m_rowIndex==1)
	    ret=true;
	
	return ret;
    }

    /**@see java.sql.ResultSet
     */
    public boolean isLast()throws SQLException{
	boolean ret = false;
	if(m_rowIndex==m_totalRows)
       	    ret =true;
	
	return ret;
    }

    /**Type of ResultSet not considered.
     *@see java.sql.ResultSet
     */
    public boolean last()throws SQLException{
       boolean ret= true;
       if(m_totalRows==0)
	   ret=false;
       this.absolute(-1);
       m_updatelog.clear();
       return ret;
       
    }
    
 
    /**
     *@see java.sql.ResultSet
     */
    public void moveToCurrentRow()throws SQLException{
	if(m_rowIndex==INSERT_ROW_INDEX)
	    m_rowIndex=m_rememberedrow;
	m_updatelog.clear();
    }

  
     /**
     *@see java.sql.ResultSet
     */
    public void moveToInsertRow()throws SQLException{
	m_insRowUpdates.clear();
	initInsertRow();
	if(m_rowIndex!=INSERT_ROW_INDEX){
	    m_rememberedrow=m_rowIndex;
	    m_rowIndex=INSERT_ROW_INDEX;
	}
	m_updatelog.clear();
    }

    /**
     * @see java.sql.ResultSet
     */
    public boolean next(){
	boolean ret= true;

	if(m_rowIndex< m_totalRows){
	    m_rowIndex++;
	    //System.out.println("next: total rows in table : "+m_totalRows);
	    
	    
	    if(m_rowIndex>=m_firstIndex+m_rowsPerPage){
		if(m_con!=null){
		    //  System.out.println("next not within range: "+m_rowIndex+" of "+m_firstIndex+" + "+m_rowsPerPage);
			
		    m_rows =null;
		    
		    m_firstIndex=m_rowIndex;
		    // System.out.println("the first index is: " +m_firstIndex);
		    //m_con.updateResultSet(m_query, m_rowIndex, m_rowsPerPage, this);
		    
		    m_con.setFullInfo(fullinfo);
		    DataSet das = (DataSet)m_con.query(m_query, m_rowIndex-1, m_rowsPerPage, m_stmt);
		    m_con.setFullInfo(false);
		    m_rows=das.getDataVector();
		    
		    // System.out.println("size of datavector: "+m_rows.size());
		}
	    }
	    
	}
	//no rows left, reset to after last
	else{
	    
	    m_rowIndex=m_totalRows+1;
	    ret=false;

	}


	m_updatelog.clear();
	return ret;
	}

    /** Type of resultSet not considered.
     *@see java.sql.ResultSet
     */
    
    public boolean previous() throws SQLException{
	boolean ret = true;
	
	if(m_rowIndex> 1){
	    m_rowIndex--;
	    
	    
	    if(m_rowIndex<m_firstIndex){
		if(m_con!=null){
		   			
		    m_rows =null;
		    
		    m_firstIndex=m_rowIndex-m_rowsPerPage+1;
		    if(m_firstIndex<1)
			m_firstIndex=1;
		    m_con.setFullInfo(fullinfo);
		    DataSet das = (DataSet)m_con.query(m_query, m_firstIndex-1, m_rowsPerPage, m_stmt);
		    m_con.setFullInfo(false);
		    m_rows=das.getDataVector();
		    
		    
		}
	    }
	    
	}
	//no rows left, reset to beginning
	else{
	    
	    m_rowIndex=0;
	    ret=false;

	}
	m_updatelog.clear();
	return ret;
    }
    

    /**Not implemented.
     *@exception SQLException if called
     */
    public void refreshRow()throws SQLException  {
	throw new SQLException("Not Implemented");
    }
    

    public boolean relative(int rows) throws SQLException {
	boolean ret= true;
	
	if(rows>0){
	    for(int i=0; i<rows; i++){
	
		ret=next();

	    }
	    
	}

	else if(rows<0) {
	    for(int j=0; j<Math.abs(rows); j++){
		ret=previous();
	    }
	    
	}
	
	return ret;

    }

    
    /** 
     *@see java.sql.ResultSet
     */
   
    public boolean rowDeleted() throws SQLException {
	return m_deleted;
    }

     /** 
     *@see java.sql.ResultSet
     */
    public boolean rowInserted()throws SQLException{

	boolean ret= false;
	if(m_rowsInserted.containsKey(new Integer(m_rowIndex)))
	    ret= true;

	return ret;

    }
      /** 
     *@see java.sql.ResultSet
     */
   
    public boolean rowUpdated()throws SQLException{
	boolean ret=false;
	if(m_rowsUpdated.containsKey(new Integer(m_rowIndex)))
	    ret=true;
	
	return ret;

    }

    /** Currently, the fetch direction does not affect
     * the efficiency of the data aquisition. If the cache
     * runs out while calling next() or absolute(int), it 
     * optimizes for forward scrolling.
     * if the cache runs out while calling previous(), it 
     * optimizes for backward scrolling.
     *@see java.sql.ResultSet
     * 
     */
    
    public void setFetchDirection(int direction)throws SQLException{
	m_fetchdirection = direction;
	

    }
   
    /** Does not take into account Statement.getMaxRows()
     *@see java.sql.ResultSet
     */
    public void setFetchSize(int rows)throws SQLException {
	if(rows==0){
	    m_rowsPerPage=1000;
	}
	
	else if(rows>0){
	    m_rowsPerPage=rows;
	}
    }


    /**@see java.sql.ResultSet
     */
    public void updateArray(int columnIndex, Array x)throws SQLException{

	try{
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = 	m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getArray(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);

		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
	    }

	}catch(ArrayIndexOutOfBoundsException e){

	    throw new SQLException("invalid column or row");
	}

    }

    /**@see java.sql.ResultSet
     */
    public void updateArray(String columnName, Array x)throws SQLException{
	updateArray(findColumn(columnName), x);
    }


    /**Not implemented.
     *@exception SQLException if called
     */
    public void updateAsciiStream(int columnIndex, InputStream x, int length)throws SQLException{
	
	throw new SQLException("Not Implemented");
	

    }

    /**Not implemented.
     *@exception SQLException if called
     */
    public void updateAsciiStream(String columnName, InputStream x, int length)throws SQLException{
	throw new SQLException("Not Implemented");
 


    }

    /**@see java.sql.ResultSet
     */
    public void updateBigDecimal(int columnIndex, BigDecimal x) throws SQLException{
	try{

	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
		
		
	    }
	    
	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}

    }
    
    /**@see java.sql.ResultSet
     */
    public void updateBigDecimal(String columnName, BigDecimal x)throws SQLException {

	updateBigDecimal(findColumn(columnName), x);
    }
   

    /**Not implemented.
     *@exception SQLException if called
     */
    public  void updateBinaryStream(int columnIndex, InputStream x, int length)throws SQLException {
	throw new SQLException("Not Implemented");
    }
   
    /**Not implemented.
     *@exception SQLException if called
     */
    public void updateBinaryStream(String columnName, InputStream x, int length)throws SQLException {
	throw new SQLException("Not Implemented");
	
    }
    
   
    /**@see java.sql.ResultSet
     */
    public void updateBlob(int columnIndex, Blob x)throws SQLException{
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }
	    
	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
		
		
	    }
	    
	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}

	
    }
    /**@see java.sql.ResultSet
     */
    public void updateBlob(String columnName, Blob x)throws SQLException{

	updateBlob(findColumn(columnName), x);
    }
    

    /**@see java.sql.ResultSet
     */
    public void updateBoolean(int columnIndex, boolean x)throws SQLException{
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, new Boolean(x), m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(new Boolean(x),columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, new Boolean(x), m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(new Boolean(x),columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}
    }
  

    /**@see java.sql.ResultSet
     */
  public void updateBoolean(String columnName, boolean x)throws SQLException{
      updateBoolean(findColumn(columnName), x);
  }
   

    /**@see java.sql.ResultSet
     */
    public void updateByte(int columnIndex, byte x)throws SQLException{
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, new Byte(x), m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(new Byte(x),columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, new Byte(x), m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(new Byte(x),columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}


	
    }
   

    /**@see java.sql.ResultSet
     */
    public void updateByte(String columnName, byte x)throws SQLException{
	updateByte(findColumn(columnName), x);
    }
    

   /**Not implemented.
     *@exception SQLException if called
     */
    public void updateBytes(int columnIndex, byte[] x)throws SQLException{

	throw new SQLException("Not Implemented");
    }
    
    /**Not implemented.
     *@exception SQLException if called
     */
    public void updateBytes(String columnName, byte[] x) throws SQLException{
	throw new SQLException("Not Implemented");
	
    }

    
    /**Not implemented.
     *@exception SQLException if called
     */

    
    public void updateCharacterStream(int columnIndex, Reader x, int length)
 	throws SQLException{
	throw new SQLException("Not Implemented");
    }
    
    /**Not implemented.
     *@exception SQLException if called
     */

    public void updateCharacterStream(String columnName, Reader reader, int length)throws SQLException{
	throw new SQLException("Not Implemented");
      
    }
   
   /**@see java.sql.ResultSet
     */
    public void updateClob(int columnIndex, Clob x)throws SQLException {
	try{
		    
	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}



    }
  
    /**@see java.sql.ResultSet
     */
 
  public void updateClob(String columnName, Clob x) throws SQLException{
      updateClob(findColumn(columnName), x);
  }
  
    /**@see java.sql.ResultSet
     */
    public void updateDate(int columnIndex, Date x)throws SQLException{

	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}



    }

    

    /**@see java.sql.ResultSet
     */

    public void updateDate(String columnName, Date x)throws SQLException{
	updateDate(findColumn(columnName), x);
    }
  
    /**@see java.sql.ResultSet
     */
    
    public void updateDouble(int columnIndex, double x)throws SQLException{
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, new Double(x), m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(new Double(x),columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, new Double(x), m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(new Double(x),columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}

    }
    
    /**@see java.sql.ResultSet
     */
    public void updateDouble(String columnName, double x)throws SQLException{
	
	updateDouble(findColumn(columnName), x);
    }
   
    /**@see java.sql.ResultSet
     */

    public void updateFloat(int columnIndex, float x)throws SQLException{
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, new Float(x), m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(new Float(x),columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, new Float(x), m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(new Float(x),columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}


    }
   
    /**@see java.sql.ResultSet
     */

    public void updateFloat(String columnName, float x)throws SQLException{
	updateFloat(findColumn(columnName), x);
    }
    
    /**@see java.sql.ResultSet
     */

    public void updateInt(int columnIndex, int x)throws SQLException{


	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, new Integer(x), m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(new Integer(x),columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, new Integer(x), m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(new Integer(x),columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}

    }
   
    /**@see java.sql.ResultSet
     */
    
    public void updateInt(String columnName, int x)throws SQLException{
	updateInt(findColumn(columnName), x);
    }
    
    /**@see java.sql.ResultSet
     */
    
    public void updateLong(int columnIndex, long x)throws SQLException{
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, new Long(x), m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(new Long(x),columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, new Long(x), m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(new Long(x),columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}

    }
    
    /**@see java.sql.ResultSet
     */
    public void  updateLong(String columnName, long x)throws SQLException{
	updateLong(findColumn(columnName), x);
    }
   
    /**Not implemented.
     *@exception SQLException if called
     */
    
    public void  updateNull(int columnIndex)throws SQLException{

	throw new SQLException("Not Implemented");
    }
  
    /**Not implemented.
     *@exception SQLException if called
     */

    public void updateNull(String columnName)throws SQLException{
	throw new SQLException("Not Implemented");
    }

   
    /**@see java.sql.ResultSet
     */

    public void  updateObject(int columnIndex, Object x)throws SQLException{

	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}


    }

    
    /**Not implemented.
     *@exception SQLException if called
     */
    
   
    public void updateObject(int columnIndex, Object x, int scale)throws SQLException{
	throw new SQLException("Not Implemented");
    }
    
    /**@see java.sql.ResultSet
     */
   public void updateObject(String columnName, Object x)throws SQLException{
       updateObject(findColumn(columnName), x);

   }

    
    /**Not implemented.
     *@exception SQLException if called
     */
    

   public  void updateObject(String columnName, Object x, int scale)throws SQLException{
       
       throw new SQLException("Not Implemented");
       
   }
   
    /**Not implemented.
     *@exception SQLException if called
     */

    public void updateRef(int columnIndex, Ref x)throws SQLException{
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}

    }
 
    /**@see java.sql.ResultSet
     */
    
   public void updateRef(String columnName, Ref x)throws SQLException{
       updateRef(findColumn(columnName), x);
       
   }
    

    /**Must call this method before moving cursor, or the updates to this
     * row will be lost.
     *@see java.sql.ResultSet
     * 
     */

    public void updateRow() throws SQLException {
	if(m_rowIndex==INSERT_ROW_INDEX){

	    throw new SQLException("Cannot update the insert row to the table");
	}

	else{
	    String s="";
	   
	    for(int i= 0; i< m_updatelog.size(); i++){
		s+= ((Update)m_updatelog.elementAt(i)).toUpdateString();
	    }
	    m_rowsUpdated.put(new Integer(m_rowIndex), "T");
	    String query = makeUpdateCommand(s);
	    String res = m_con.update(query);
	    res= res.replaceAll("thats.all.folks", "");
	    if(!res.trim().equalsIgnoreCase("Done"))
		throw new SQLException("Database Error: "+res);

	    m_updatelog.clear();
	}
	//	System.out.println("exitting update row with # "+m_totalRows);
    }


    /**@see java.sql.ResultSet
     */

    public void updateShort(int columnIndex, short x) throws SQLException {
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, new Short(x), m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(new Short(x),columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, new Short(x), m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(new Short(x),columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}



    }
    
   
    /**@see java.sql.ResultSet
     */
    public void updateShort(String columnName, short x)throws SQLException{
	updateShort(findColumn(columnName), x);
    
    }

    /**@see java.sql.ResultSet
     *
     */

    public void updateString(int columnIndex, String x)throws SQLException{
	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}


    }
  
    /** Insert object o into the current row. Used during initial construction
     * of the ResultSet.
     */
   public void insertIntoRow(Object o){
	((Vector)m_rows.elementAt(m_rowIndex-1)).add(o);
    }


    /**@see java.sql.ResultSet
     *
     */
    public void updateString(String columnName, String x)throws SQLException{
	updateString(findColumn(columnName), x);
    }
    /**@see java.sql.ResultSet
     *
     */

    public void updateTime(int columnIndex, Time x)throws SQLException{

	try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}



	
    }
    /**@see java.sql.ResultSet
     *
     */
    public void updateTime(String columnName, Time x)throws SQLException{
	updateTime(findColumn(columnName), x);

    }

    
    /**@see java.sql.ResultSet
     *
     */
    
    public void updateTimestamp(int columnIndex, Timestamp x)throws SQLException{
		try{

	  
	    if(m_rowIndex==INSERT_ROW_INDEX){
		
		Object old = m_insertRow.elementAt(columnIndex-1);
		Update up = new Update(old, x, m_totalRows+1, columnIndex);
		m_insRowUpdates.add(up);
		m_insertRow.setElementAt(x,columnIndex-1);
		
	    }

	    else{
		Object old = getString(columnIndex);
		Update up = new Update(old, x, m_rowIndex, columnIndex);
		insertUpdate(up);
		
		((Vector)m_rows.elementAt(m_rowIndex-m_firstIndex)).setElementAt(x,columnIndex-1);
	
		
	    }

	}catch(ArrayIndexOutOfBoundsException e){
	    
	    throw new SQLException("invalid column or row");

	}

    }

 /**@see java.sql.ResultSet
     *
     */
    public void updateTimestamp(String columnName, Timestamp x)throws SQLException{
	updateTimestamp(findColumn(columnName), x);

    }

	/**Not implemented.
     *@exception SQLException if called
     */

    public boolean wasNull()throws SQLException{

	
	throw new SQLException("Not Implemented");

    }

    /** This method constructs an update for s.
     */
    
    public String makeUpdateCommand(String s){
	String ret="<QUERY> "+ m_query +" </QUERY>\n";
	ret+="<COMMAND>\n";
	ret+= s;
	ret+="</COMMAND>\n";
	
	return ret;
    }


    /** This method initializes the insert row with place holder values.
     * These place holder values will not be stored in the table upon
     * update. The user must make sure to set eat column in the insert row
     * manually in order for those values to be updated to the table.
     */

    public void initInsertRow(){
	try{
	  
	    
	    if(m_insertRow.size()!=m_metaData.getColumnCount()){
		
		for(int i=0; i< m_metaData.getColumnCount();i++){
		    
		    
		    m_insertRow.add(new Object());
		    
		}
	    }
	}
	
	catch(Exception e){
	    
	    System.err.println("Error while trying to init insert row.");
	}
	
	
	
    }


} 


