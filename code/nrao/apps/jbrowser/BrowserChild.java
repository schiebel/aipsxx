import java.awt.event.*;
import java.awt.*;
import java.util.*;

import javax.swing.JTable;
import javax.swing.JScrollPane;
import javax.swing.JPanel;
import javax.swing.JFrame;
import javax.swing.table.*;
import java.lang.*;
import javax.swing.*;
import java.sql.*;

/** This models an MDI child which is used to display the ResultSet.
 * @author Jason Ye
 */

public class BrowserChild extends JInternalFrame {
  
  
    private TableBrowser m_parent;
    private Vector m_colHeaders;
    private Vector m_colTypes;
    private Vector m_data;
    private BrowserTable table;
    private JScrollPane scrollPane;
    private String m_queryString;
    private KeywordSet m_kwset;
    private Hashtable m_colkws;
    private Hashtable m_arrays;
    private RowNumber rowHeaders;
    private JButton m_previous;
    private JButton m_next;
    private int m_firstRow;
    private int m_rowsOnPage;
    private JButton m_getPage;
    private JTextField m_address;
    private JLabel m_pagelabel;
    private JLabel m_currpagelabel;
    private String m_name;
    private Hashtable m_hash;
    private ResultSet m_resultSet;
    private JTextField m_goToEntryField;
    private JButton m_goToEntry;
    private Hashtable m_colToShow;
  
    /** Create a BrowserChild with a reference to the MDI parent parent.
     */

    public BrowserChild(TableBrowser parent) {
        super("", 
              true, //resizable
              true, //closable
              true, //maximizable
              true);//iconifiable

	m_parent=parent;
	

	setSize(500,400);
	

	
	table =null;
	toFront();
	rowHeaders=null;

	JToolBar toolBar = new JToolBar();
	toolBar.setVisible(true);
        toolBar.setFloatable(false);
	getContentPane().add(toolBar,BorderLayout.SOUTH);
	m_previous = new JButton(new ImageIcon("icons/left.gif"));
	m_previous.setToolTipText("Previous Page");
	m_previous.addActionListener(m_parent);
	toolBar.add(m_previous);

	m_next = new JButton(new ImageIcon("icons/right.gif"));
	m_next.setToolTipText("Next Page");
	m_next.addActionListener(m_parent);
	toolBar.add(m_next);
	
	toolBar.addSeparator();
	
	toolBar.add(new JLabel("Page: "));
	m_address = new JTextField();
	m_address.setToolTipText("Enter Number of Page to View");

	

	toolBar.add(m_address);
	m_getPage = new JButton("GO");
	m_getPage.setToolTipText("Go to Page");
	m_getPage.addActionListener(m_parent);
	toolBar.add(m_getPage);
	toolBar.addSeparator();
	
	m_currpagelabel=new JLabel("pagenumber");
	toolBar.add(m_currpagelabel);
	
	m_pagelabel = new JLabel("/total");
	toolBar.add(m_pagelabel);
	toolBar.addSeparator();
	JLabel gotoentrylabel = new JLabel("Row: ");
	toolBar.add(gotoentrylabel);
	m_goToEntryField = new JTextField();
	m_goToEntryField.setToolTipText("Enter number of the first row to show");
	toolBar.add(m_goToEntryField);
	
	m_goToEntry = new JButton("GO");
	m_goToEntry.setToolTipText("Go To Row");
	m_goToEntry.addActionListener(m_parent);
	toolBar.add(m_goToEntry);
	    
	
	m_hash=new Hashtable();
	

	//  setLocation(xOffset*openFrameCount, yOffset*openFrameCount);
	m_colToShow = new Hashtable();
	
	
    }
    //jan 2004
    /*Get the DataSet shown in this frame.

    */

    public DataSet getDataSet(){
	return (DataSet)m_resultSet;
    }
    //end jan 2004

    /** Get the name of column i.
     */

    public String getColNames(int i){
    //System.out.println("time:" +(String)m_colTypes.elementAt(i) );
	return (String)m_colHeaders.elementAt(i);
    }
    
    /** Set the total page number label at the lower right hand corner
     * of the BrowserChild.
     */

    public void setTotalPageNumber(int i){

	m_pagelabel.setText("/"+i);
    }
    
    /** Display the previous page. 
     */
    public void prevPage(){
	if(m_rowsOnPage!=0){
	    
	    int fs =m_firstRow-m_rowsOnPage;
	    if(fs< 0)
		fs=0;
	    
	   
	    
	    this.displayRecord(m_resultSet,fs, m_rowsOnPage );
	}

    }

     /** Display the next page. 
     */

    public void nextPage(){
	if(m_rowsOnPage!=0)
	    
	    this.displayRecord(m_resultSet,m_firstRow+m_rowsOnPage, m_rowsOnPage );

    }


    /** Set the title of the browser to name.
     */

    public void setTitle(String name){
	super.setTitle(name);
	m_name = name;
	
    }

    /** Get the total number of pages the displayed ResultSet contains.
     */

    public int getTotalPageNumber(){

	int a=0;
	try{
	    a = (new Integer(m_pagelabel.getText().replaceAll("/",""))).intValue();
	}
	
	catch(NumberFormatException e){
	    
	}
	
	return a;

    }

    /** Get the number in the go to row field.
     */
    public int getGoRowNum(){
	int a=0;
	try{
	    a = (new Integer(m_goToEntryField.getText())).intValue();
	}
	
	catch(NumberFormatException e){

	    
	}
	
	return a;

    }

    /** Get a reference of the button pressed to jump to a row.
     */
    
    public JButton getRowButton(){
	return m_goToEntry;
    }
    /** Jump to row a. a starts at 1.
     */

    public int getTotalRows(){
	int ret = -1;
	try{
	    m_resultSet.last();
	    ret= m_resultSet.getRow();
	}catch (SQLException e){

	    System.err.println("Fatal Error with ResultSet. Closing Browser window.");
	    this.dispose();

	}
	System.out.println("BrowserChild: total rows: "+ret);
	return ret;
    }

    public void goToRow(int a){

	this.setCursor(new Cursor(Cursor.WAIT_CURSOR));
	this.displayRecord(m_resultSet, a-1, m_rowsOnPage);
// 	int curr = m_resultSet.getRow();
// 	System.out.println("resultset's current row "+ curr);
// 	m_resultSet.last();
// 	System.out.println("resultset's numb rows "+m_resultSet.getRow());
// 	m_resultSet.absolute(curr);
// 	System.out.println("resultset's current row "+ curr);

	int pnum = (a-1)/m_rowsOnPage+1;
	if((a-1)%m_rowsOnPage!=0)
	    pnum++;
	
	m_goToEntryField.setText("");
	this.setCurrPageNumber(pnum);
	this.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
	
    }

    public void goToPage(int a){
	this.setCursor(new Cursor(Cursor.WAIT_CURSOR));
	
	int num = (a-1)*m_rowsOnPage;
	
	this.displayRecord(m_resultSet, num, m_rowsOnPage);
	this.setCurrPageNumber(a);
	this.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));

	
    }

    /** Set the current page number label.
     */


    public void setCurrPageNumber(int a){

	m_currpagelabel.setText(String.valueOf(a));
    }

    
    /** Get the current page number label.
     */
    public int getCurrPageNumber(){
	return (new Integer(m_currpagelabel.getText())).intValue();
    }

    /** Get the number of the page in the JTextField for jumping 
     * to a particular page.
     */

    public int getPageNumber(){
	int a=0;
	try{
	    a = (new Integer(m_address.getText())).intValue();
	}

	catch(NumberFormatException e){

		  
	}
	
	return a;

    }

    /** Clear the jump to page field.
     */

    public void clearAddress(){
	m_address.setText("");
    }
    
    /** Get a reference to the button that is pressed to jump to 
     *	a page.
     */

    public JButton getPageGo(){
	return m_getPage;
    }
    
    /** Get the number of the first row displayed.
     */

    public int getFirstRow(){
	return m_firstRow;
    }
    
   
    /** Set the number of the first row displayed.
     */

    public void setFirstRow(int r){

	m_firstRow=r;
    }

    /** Get the number of the  rows displayed per page.
     */
    public int getRowsPerPage(){
	return m_rowsOnPage;
    }

    /** Set the number of the  rows displayed per page.
      */
    public void setRowsPerPage(int r){
	m_rowsOnPage=r;
    }
    
    /** Get a reference to the button that is pressed to go to 
     *	the previous page.
     */

    public JButton getPrevPage(){
	return m_previous;
    }
    
    /** Get a reference to the button that is pressed to go to 
     *	the next page.
     */

    public JButton getNextPage(){
	return m_next;
    }


    /** Get a reference to the parent TableBrowser.
     */

    public TableBrowser getTableBrowser(){
	return m_parent;
    }

    /** Add a rows to the end of the table.
     */

    public void addRows(int a){
	
	for (int i=0;i<a;i++){
	    Vector temp = new Vector();
	    for(int j=1;j<m_colTypes.size()+1;j++){
		if(m_arrays.containsKey(new Integer(j))){
		    temp.add("ARRAY");
		}
		else{
		    temp.add("");
		}
	
	    }
	    table.insertRows(table.getRowCount(),temp,true);
	    
	    
	



	    Enumeration elem = m_arrays.elements();
	    while(elem.hasMoreElements()){
		((Vector)elem.nextElement()).add("EMPTY ARRAY");
		
	    }
	}
    }
    

    /** Delete a row from table.
     */
    
    public void deleteRows(){
	table.deleteRows(-1);


    }

    /** Set the TaQL query string that resulted in this table.
     */

    public void setQueryString(String s){
	m_queryString =s;

    }

    /** Get the TaQL query string that resulted in this table.
     */
    
    public String getQueryString(){
	return m_queryString;
    }


    /** Returns the Table that displays the row numbers on the left
     * side of the table.
     */

    public RowNumber getRowNumber(){
	return rowHeaders;
    }


    /** Return the table that displays the data.
     */

    public JTable getTable(){
	return table;
    }

    /** Close this window and update its parent's list of children.
     */

    public void dispose(){
	super.dispose();
	m_parent.updateChildren(this);
    }
    /** Initialize this Browser child to show all columns up to number i.
     */
    public void initColToShow(int i){
	System.out.println("showing columns 1 to "+i);
	m_colToShow.clear();
	for (int j=1;j<i+1;j++){
	    m_colToShow.put(new Integer(j), new Integer(j));

	}
    }


    /** Display the ResultSet rs starting from row number start and
     * numbering number rows total.
     */

    public void displayRecord(ResultSet rs, int start, int number){
	
	boolean error=true;
	try{
	    if(start>=0)
	if(rs.absolute(start+1)){
	    //if(m_resultSet==null)
	    m_resultSet = rs;

	m_colkws = ((DataSetMetaData)rs.getMetaData()).getColumnKW();

	m_arrays=new Hashtable();


	//change to getresultsetmetadata	
	m_kwset = ((DataSetMetaData)rs.getMetaData()).getTableKW();
	ResultSetMetaData metaData = rs.getMetaData();
	int colNum = metaData.getColumnCount();
	m_colHeaders= new Vector();
	m_colTypes = new Vector();

	for (int i=1;i<colNum+1;i++){
	    
	  
	    m_colHeaders.add(metaData.getColumnName(i));
	    m_colTypes.add(metaData.getColumnTypeName(i));
	    //  System.out.println(metaData.getColumnName(i)+ " : " + metaData.getColumnTypeName(i));
	    if(metaData.getColumnTypeName(i).startsWith("TpArray")){
		//	System.out.println("array detected");
		m_arrays.put(new Integer(i), new Vector());
	    }

	    
	
	
	
	    
	}
	
	m_data = new Vector();

	

	int row =-1;

	// start manipulation
	int icou=0;
	
	
	    
	    do{
		
		row++;
		m_data.add(new Vector());
	
		  
		  
		for (int j=1;j<colNum+1;j++){
		     if(m_arrays.containsKey(new Integer(j))){
			 
 			Vector arrayCol = (Vector)m_arrays.get(new Integer(j));
 			arrayCol.add(rs.getString(j));
// 			((Vector)m_data.elementAt(row)).add("ARRAY");  
		


 			}
// 		    else{
		    
			((Vector)m_data.elementAt(row)).add(rs.getString(j));
			
			//	if(((String)(m_colTypes.elementAt(j-1))).trim().equalsIgnoreCase("TpDate")){
			    //	System.out.println("date string: "+rs.getString(j));
			//	}
			// }
		}
		
		
		
		icou++;
		//System.out.println("icou: "+icou+ ", number: "+number);

		if(icou==number){
		    //  System.out.println("should break from do while :"+icou);
		    break;
		}
	
	    }
	    while(rs.next());
	    
	    if(start==m_firstRow-m_rowsOnPage){
		if(m_currpagelabel.getText().trim().equalsIgnoreCase("pagenumber")){
		    m_currpagelabel.setText("1");
		}
		//	System.out.println("page error: " +m_currpagelabel.getText());
		m_currpagelabel.setText(String.valueOf((new Integer(m_currpagelabel.getText())).intValue()-1));
	    }
	    else if(start==m_firstRow+m_rowsOnPage){
		m_currpagelabel.setText(String.valueOf((new Integer(m_currpagelabel.getText())).intValue()+1));
	    	
	    }

	    if(table!=null){
		table.setVisible(false);
		table=null;
	    }
	    if(scrollPane!=null){
		scrollPane.setVisible(false);
		getContentPane().remove(scrollPane);
		scrollPane=null;
		
	    }
	
		
	table = new BrowserTable(m_data, m_colHeaders, this);
	table.setInsRow(((DataSetMetaData)rs.getMetaData()).getInsRow());
	table.setDelRow(((DataSetMetaData)rs.getMetaData()).getDelRow());
	table.setMetaData(rs.getMetaData());
	table.setRowSelectionAllowed(false);
	table.setColumnSelectionAllowed(false);
	table.setPreferredScrollableViewportSize(new Dimension(500, 400));
	scrollPane = new JScrollPane(table);
	
	table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
	getContentPane().add(scrollPane, BorderLayout.CENTER);
	//System.out.println("row #: " + table.getRowCount());
	// Start add row numbers
	Vector rowNumVector = new Vector();
	Vector rowNumHeader = new Vector();
	m_firstRow = start;
	rowNumHeader.add("Row");
	//	System.out.println("first row on page: "+m_firstRow);
	for (int m=1+m_firstRow; m<table.getRowCount()+1+m_firstRow;m++){
	    Vector temp = new Vector();
	    temp.add(String.valueOf(m));
	    rowNumVector.add(temp);
	  
	}
	
	

	rowHeaders = new RowNumber(rowNumVector,rowNumHeader);
		

	
	rowHeaders.setPreferredScrollableViewportSize(new Dimension(50, 200));
	rowHeaders.setVisible(true);
	scrollPane.setRowHeaderView(rowHeaders);
	rowHeaders.disable();
	rowHeaders.doLayout();
	rowHeaders.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);

	for(int o=0;o<rowHeaders.getRowCount();o++){
	    ((DefaultTableCellRenderer)rowHeaders.getCellRenderer(o,0)).setBackground(table.getTableHeader().getBackground());

	}
	//end add row numbers
	Point old =this.getLocation();
	this.setLocation(new Point((int)old.getX()+1, (int)old.getY()+1));
	this.setLocation(old);
	error=false;
	
	}
	
	}
	catch(Exception e){
	    e.printStackTrace();
	}

	
	if(!error){
	   
	    
	TableColumnModel tcm = table.getColumnModel();
	int numberofcolumns=table.getColumnCount();
	int colsmax=65;
	FontMetrics fm = table.getFontMetrics(table.getFont());
	JTableHeader hed = table.getTableHeader();
	hed.setToolTipText("tool tips");
	
		
	MouseMotionAdapter tipman = new MouseMotionAdapter(){
		TableColumn curr;
		
		
		
		public void mouseMoved(MouseEvent e){
		    try{
		    JTableHeader head = (JTableHeader)e.getSource();
		    TableColumnModel colmodel = head.getTable().getColumnModel();
		    int coord = colmodel.getColumnIndexAtX(e.getX());
		    
		    TableColumn col = colmodel.getColumn(coord);
		    if(col!=curr){
			head.setToolTipText((String)m_hash.get(col));
		
			curr = col;
		
		    }
		    }
		    catch(ArrayIndexOutOfBoundsException ex2){
			
		    }
		}
		

	    };
	

	MouseAdapter selector = new MouseAdapter(){

		TableColumn curr;
		
		
		
		public void mouseClicked(MouseEvent e){
		    try{
		    JTableHeader head = (JTableHeader)e.getSource();
		    TableColumnModel colmodel = head.getTable().getColumnModel();
		    int coord = colmodel.getColumnIndexAtX(e.getX());
		    
		    TableColumn col = colmodel.getColumn(coord);
		    if(col!=curr){
			table.setRowSelectionAllowed(false);
			table.setColumnSelectionAllowed(true);
			table.changeSelection(0,coord, false, false);
			
			curr = col;
			
		    }
		    }

		    catch(ArrayIndexOutOfBoundsException ecx3){

		    }
		}
		
		
	    };


	for(int counter=0;counter<numberofcolumns;counter++){
	    TableColumn colmod = tcm.getColumn(counter);
	    this.setTipText(colmod, "type: "+m_colTypes.elementAt(counter));
	    String headertext = (String)colmod.getHeaderValue();
	    int nextwidth = fm.stringWidth(headertext);
	    // System.out.println("text: "+headertext+" width: "+nextwidth);
	    
	    if(nextwidth>colsmax)
		colsmax=nextwidth;
	    for(int roco=0;roco<table.getRowCount();roco++){

		if(fm.stringWidth((String)table.getValueAt(roco,counter))>colsmax)
		    colsmax= fm.stringWidth((String)table.getValueAt(roco,counter));
	    }
	    

	    if(-1!=((Integer)m_colToShow.get(new Integer(counter+1))).intValue())
		colmod.setPreferredWidth(colsmax+20);
	    else{
		colmod.setMinWidth(0);
		colmod.setPreferredWidth(0);
	    }

	}

	
	hed.addMouseMotionListener(tipman);
	hed.addMouseListener(selector);

	}

    }

    /** Set the type information t to the TableColumn col.
     */

    public void setTipText(TableColumn col, String t){
	m_hash.put(col, t);

    }
    
    /** Move this BrowserChild to the front and set it as the 
     * parent's current child.
     */

    public void toFront(){
	super.toFront();
	//set as parent's current
	//System.out.println("moving "+getTitle()+" to the front");
	m_parent.setAsCurrent(this);
    }
    
    /** Move this BrowserChild to the front and set it as the 
     * parent's current child if b is true. 
     */

    public void setSelected(boolean b) throws java.beans.PropertyVetoException{
	
	super.setSelected(b);
	if(b)
	    m_parent.setAsCurrent(this);


    }

    /** Undo the last change.
     */

    public void undoLast(){
	table.undoLastChange();
    }
    
    /** Redo the last change.
     */

    public void redoLast(){
	table.redoLastChange();
    }

    /** Get the XML string representing updates to the table.
     */

    public String getUpdateCommand(){
	String ret ="";
	ret+="<QUERY> "+ m_queryString +" </QUERY>\n";
	ret+="<COMMAND>\n";
	ret+=table.constructUpdate();
	ret+="</COMMAND>\n";
	return ret;

    }
    
    /** Show the table's keywords.
     */

    public void displayKeywords(){

	KeywordViewer kview = new KeywordViewer(m_parent);
	kview.setTitle(m_name+ ": Keywords");
	kview.display(m_kwset);
	m_parent.getDeskTop().add(kview);
	try{
	    kview.setSelected(true);
	} catch(Exception e){
	    // e.printStackTrace();
	}
	
	
    }

    /** Make the column visible. Start numbering at 1;
     */
    public void setColumnVisible(int column){
	m_colToShow.put(new Integer(column), new Integer(column));

    }
    /** Show the hidden column.
     */

    public void showColumn(){

	new ShowColumnDialog(this, m_colToShow);
    }
    
    /** Called after hiding visible or showing hidden columns.
     */
    public void refreshDisplay(){

	displayRecord(m_resultSet, m_firstRow, m_rowsOnPage);


    }

    /** Hide the given column.
     */

    public void hideColumn(){

	int a = table.getSelectedColumn();
	
	
	m_colToShow.remove( new Integer(a+1));
	m_colToShow.put( new Integer(a+1), new Integer(-1));

	
	refreshDisplay();
	
    }

    /** Show the currently selected column's keywords.
     */

    public void dispColKW(){

	int a = table.getSelectedColumn();
	Integer key = new Integer(a);
	if(m_colkws.containsKey(key)){
	    KeywordSet kwset = (KeywordSet)m_colkws.get(key);
	    KeywordViewer kview = new KeywordViewer(m_parent);
	    kview.setTitle(m_name+ "[" +(String)m_colHeaders.elementAt(a)+"] "+ "Keywords");

	    kview.display(kwset);
	    m_parent.getDeskTop().add(kview);
	    try{
		kview.setSelected(true);
	    } catch(Exception e){
		//	e.printStackTrace();
	    }
	}
	
	else{
	    JOptionPane.showMessageDialog(m_parent, "No Keywords for column "+(String)m_colHeaders.elementAt(a), "Column Keywords", JOptionPane.INFORMATION_MESSAGE);	
	    
	}

    }

    /** Get the Hashtable containing array info.
     */

    public Hashtable getArrays(){
	return m_arrays;
    }
    
    /** Query and display array at index row, col of the AIPS++ table.
     */

    public void displayArray(int row, int col){
	try{
	if(m_resultSet.absolute(row+1)){
	    java.sql.Array array = m_resultSet.getArray(col+1);
	    
	    
	    //String s =m_parent.getArray(m_queryString, row, col, (String)m_colTypes.elementAt(col));
	    ArrayAction aaction = new ArrayAction(row, col);
	    	    
	    //System.out.println("creating array browser with String:\n"+s);
	    //	    ArrayBrowser browser = new ArrayBrowser(m_parent, s, (String)m_colTypes.elementAt(col));
	    
	    ArrayBrowser browser = (ArrayBrowser)array.getArray();
	    browser.display(m_parent);
	   
	    browser.setTitle(m_name+": Array at: "+ (row+1)+", "+(col+1));
	    browser.setArrayAction(aaction);
	    browser.setRow(row);
	    browser.setCol(col);
	    m_parent.getDeskTop().add(browser);
	    try{
		browser.setSelected(true);
	    } catch(Exception e){
		//	e.printStackTrace();
	    }
	}
	}

	catch(SQLException exc){
	    JOptionPane.showMessageDialog(m_parent, "Unable to get Array.","Array Error", JOptionPane.WARNING_MESSAGE);	
	    
	    
	}
    }

}
