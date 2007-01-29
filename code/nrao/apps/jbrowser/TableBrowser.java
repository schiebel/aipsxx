import javax.swing.*;
import javax.swing.table.*;
import java.awt.*;
import java.awt.event.*;
import java.sql.*;
import java.util.*;
import java.io.*;
import java.lang.*;

/** This class is the MDI parent that models the Table Browser.
 * It instantiates and uses the JBDC driver.
 *
 * @author Jason Ye
 */

public class TableBrowser extends JFrame implements ActionListener{
    
   
    
    private Vector m_children;
    private JDesktopPane m_desktop;
  

    private JMenuBar m_menuBar;
    private JMenu m_filemenu;
    private JMenuItem m_queryItem;
    private JMenuItem m_quitItem;
    private JMenuItem m_saveItem;
    

    private BrowserChild m_current;
    
    private JMenu m_editmenu;
    private JMenuItem m_undoItem;
    private JMenuItem m_redoItem;
    private JMenuItem m_delrowItem;
    private JMenuItem m_addrowItem;

    private JMenu m_viewmenu;
    private JMenuItem m_keywordItem;
    private JMenuItem m_colkwItem;
    private Connection m_con;
    private JMenuItem m_colhideItem;
    private JMenuItem m_colshowItem;
    //jan 2004
    
    private JMenu m_exportmenu;
    private JMenuItem m_XMLItem;
    private JMenu m_plotmenu;
    private JMenuItem m_plotItem;
    private JMenuItem m_plot3dItem;
    private String lastquery;
    //end jan 2004
    private static String drivername = "TableDriver";

   
    /** Create a TableBrowser that makes a connection to the server s
     * and port number port. This is the where the ATADB is awaiting 
     * queries.
     *
     */
 
    
    public TableBrowser(String server, int port ){
	super("Table Browser");
	lastquery="";
	server+=":"+String.valueOf(port);

	m_children = new Vector();
	//m_qtable = new QueryTable(server, port);
	//m_interpreter = new DataInterpreter();

	m_current=null;
	m_desktop = new JDesktopPane();
	this.setContentPane(m_desktop);
	
	
	
	//set up menubar

	m_menuBar = new JMenuBar();
	this.setJMenuBar(m_menuBar);
	m_filemenu= new JMenu("File");
	m_menuBar.add(m_filemenu);
	m_filemenu.setMnemonic(KeyEvent.VK_F);

	m_queryItem = new JMenuItem("Query", KeyEvent.VK_Q);
	m_filemenu.add(m_queryItem);
	m_queryItem.addActionListener(this);


	m_saveItem = new JMenuItem("Save", KeyEvent.VK_S);
	m_filemenu.add(m_saveItem);
	m_saveItem.addActionListener(this);
	





	m_quitItem = new JMenuItem("Exit", KeyEvent.VK_X);
	m_filemenu.add(m_quitItem);
	m_quitItem.addActionListener(this);

	m_editmenu = new JMenu("Edit");
	m_menuBar.add(m_editmenu);
	
	m_editmenu.setMnemonic(KeyEvent.VK_E);
       	
	m_undoItem = new JMenuItem("Undo", KeyEvent.VK_D);
	m_editmenu.add(m_undoItem);
	m_undoItem.addActionListener(this);

	m_redoItem = new JMenuItem("Redo", KeyEvent.VK_R);
	m_editmenu.add(m_redoItem);
	m_redoItem.addActionListener(this);

	m_addrowItem = new JMenuItem("Add Row(s) [H]", KeyEvent.VK_H);
	m_editmenu.add(m_addrowItem);
	m_addrowItem.addActionListener(this);

	m_delrowItem = new JMenuItem("Delete Row(s)", KeyEvent.VK_W);
	m_editmenu.add(m_delrowItem);
	m_delrowItem.addActionListener(this);

	m_viewmenu = new JMenu("View");
	
	m_menuBar.add(m_viewmenu);
	m_viewmenu.setMnemonic(KeyEvent.VK_V);
	
	m_keywordItem = new JMenuItem("Table Keywords", KeyEvent.VK_K);
	m_viewmenu.add(m_keywordItem);
	m_keywordItem.addActionListener(this);
	
	m_colkwItem = new JMenuItem("Column Keywords", KeyEvent.VK_P);
	m_viewmenu.add(m_colkwItem);
	m_colkwItem.addActionListener(this);
	
	m_colhideItem =  new JMenuItem("Hide Column", KeyEvent.VK_T);
	m_viewmenu.add(m_colhideItem);
	m_colhideItem.addActionListener(this);

	m_colshowItem =  new JMenuItem("Show Column", KeyEvent.VK_B);
	m_viewmenu.add(m_colshowItem);
	m_colshowItem.addActionListener(this);

	//jan 2004

	m_exportmenu = new JMenu("Export");
	m_menuBar.add(m_exportmenu);
	m_XMLItem =  new JMenuItem("VOTable");
	m_exportmenu.add(m_XMLItem);
	m_XMLItem.addActionListener(this);
	

	m_plotmenu = new JMenu("Plot");
	m_menuBar.add(m_plotmenu);
	m_plotItem =  new JMenuItem("Plot 2D");
	m_plotmenu.add(m_plotItem);
	m_plotItem.addActionListener(this);
	
	m_plot3dItem =  new JMenuItem("Plot 3D");
	m_plotmenu.add(m_plot3dItem);
	m_plot3dItem.addActionListener(this);



	//end jan 2004


	addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent e) {
		    System.exit(0);
		}
	    });

	//connection variables


	

	try{
	    Class.forName(drivername);
	}

	catch(ClassNotFoundException e){
	    System.err.println("Invalid driver name: "+drivername);
	    System.exit(1);
	}


	try{
	    m_con = DriverManager.getConnection(server, "", "");
	}
	
	catch(SQLException e){
	    System.err.println("Could not make connection to : " + server);
	    
	}

	
    }

    public String getLastQuery(){
	return lastquery;
    }
    

    /** This method is called by the QueryDialog class. It relays the query
     * to correct method. The Vector v contains the following elements in order:
     *<li> TaQL query string
     *<li> Boolean indicating whether to open a new MDI child to display
     * the result
     *<li> Integer indicating number of rows to cache in the ResultSet
     */

    public void delegateQuery(Vector v){
	

	//	System.out.println(v);
	String q = (String)v.firstElement();
	if(!q.trim().equalsIgnoreCase("")){
	    boolean b = ((Boolean)v.elementAt(1)).booleanValue();
	    StringTokenizer tok = new StringTokenizer(q);
	    String test;
	    lastquery=q;
	    
	    this.query(b,q,0,((Integer)(v.elementAt(2))).intValue());

	
	}

	else{

	    //  System.out.println("empty query");
	}

	

    }
   
    /** Interprets the menu actions and calls the appropriate method.
     */


    public void actionPerformed(ActionEvent e){
	Object source = (e.getSource());

	
	if(source==m_queryItem){
	    
	 
	    QueryDialog.getQuery(this);
	 
	}
	


	
	else if(source==m_quitItem){
	    //check to see if really exit
	    System.exit(0);
	    
	}
	
	else if(source==m_undoItem){
	    if(m_current!=null)
		m_current.undoLast();
	    
	}
	
	else if(source==m_redoItem){
	    if(m_current!=null)
		m_current.redoLast();
	}
	
	else if(source==m_saveItem){
	    if(m_current!=null){
		String update = m_current.getUpdateCommand();
		try{
		    Statement stmt = m_con.createStatement();
		    stmt.executeUpdate(update);
		}
		catch(SQLException ex){
		    JOptionPane.showMessageDialog(this, "Problems while saving to database.", "Save Error", JOptionPane.WARNING_MESSAGE);	
	     
		}
		
		((BrowserTable)m_current.getTable()).clearChanges();
	    }
	    
	    else{

		//	System.out.println("save should be disabled");
	    }

	}

	else if(source==m_keywordItem){
	    if(m_current!=null)
		m_current.displayKeywords();
	}
	
	else if(source==m_colkwItem){
	    // System.out.println("viewing column keywords");
	    if(m_current!=null)
		m_current.dispColKW();
	}


	else if(source==m_delrowItem){
	    if( m_current!=null){

		m_current.deleteRows();
	    }
	    
	}

	else if(source==m_addrowItem){
	    if( m_current!=null){
		String s = (String)JOptionPane.showInputDialog(
							       this,
						       "Enter number of rows to add:\n",  "Add Rows",  JOptionPane.PLAIN_MESSAGE);

		try{
		    int abc = new Integer(s.trim()).intValue();
		    if(abc<0||abc>2000){
			throw new NumberFormatException();
		    }
		    m_current.addRows(abc);
		}
		catch(NumberFormatException except){
		    JOptionPane.showMessageDialog(this, "Not a valid number. Enter 0-2000.", "Input Error", JOptionPane.WARNING_MESSAGE);	
	     
		}
	    }
	    
	}



	else if(source == m_colhideItem){
	    if(m_current!=null)
		m_current.hideColumn();
	    
	}

	else if(source == m_colshowItem){
	    if(m_current!=null)
		m_current.showColumn();
	    
	}
	
    
	if(m_current!=null){


	    if(source==m_current.getPrevPage()){
	    m_current.setCursor(new Cursor(Cursor.WAIT_CURSOR));	
	    m_current.prevPage();
	    m_current.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
	    
	}
	else if(source==m_current.getNextPage()){
	    m_current.setCursor(new Cursor(Cursor.WAIT_CURSOR));	
	    m_current.nextPage();
	    m_current.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
	    
	}





 	else if(source == m_current.getPageGo() ){

	    int num = m_current.getPageNumber();
	    
 	    if(num>0&&num<=m_current.getTotalPageNumber()){
 		m_current.clearAddress();
		
		m_current.goToPage(num);
	    }
	    
	    else{
		JOptionPane.showMessageDialog(this, "Invalid Page Number", "Page Input Error", JOptionPane.WARNING_MESSAGE);	
		
		
	    }
	}

	else if(source == m_current.getRowButton()){
	    
	    int num = m_current.getGoRowNum();
	    if(m_current.getTotalRows()!=-1){
		System.out.println("go to row");
		if(num>0&&num<=m_current.getTotalRows()){
		
		    m_current.goToRow(num);
		}
		else{
		    JOptionPane.showMessageDialog(this, "Invalid Row Number", "Row Input Error", JOptionPane.WARNING_MESSAGE);	
		    
		    
		}
	    }

	}
	
	//jan 2004

	else if(source==m_XMLItem){
	    try{
	    JFileChooser chooser = new JFileChooser();
	    chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
	    int res= chooser.showSaveDialog(this);
	   
	    
	    if(res==JFileChooser.APPROVE_OPTION){
		File f = chooser.getSelectedFile();
		String tablename = f.getAbsolutePath();
		 
		int save = 0;
		if(f.exists()){
		    save=JOptionPane.showConfirmDialog(this, "Overwrite file "+tablename+"?", "Export VOTable", 2,JOptionPane.WARNING_MESSAGE);	
		    
		}
		
		

		if(save==0){
		    
		int buffsize = Integer.parseInt( JOptionPane.showInputDialog(this, "Enter JDBC buffer size. (5000 suggested)", "5000"));
			    
			    
		
		
		this.setCursor(new Cursor(Cursor.WAIT_CURSOR));
		m_current.setCursor(new Cursor(Cursor.WAIT_CURSOR));
		Statement stmt = m_con.createStatement();
		stmt.setFetchSize(buffsize);
		String s = m_current.getQueryString();		
		((TableConnection)m_con).setFullInfo(true);
		
		DataSet ret = (DataSet)stmt.executeQuery(s);
		((TableConnection)m_con).setFullInfo(false);
	    
		VOTableGenerator gen = new VOTableGenerator();
		
		gen.genVOTab(ret, 1, -1, tablename);
		
	
		this.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
		m_current.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
		}
	    }

		
	    }

	    catch(Exception ex){
		if(ex instanceof NumberFormatException)
		    JOptionPane.showMessageDialog(this, "Invalid Number.", "Error", JOptionPane.WARNING_MESSAGE);	
		    
		else{
		    ex.printStackTrace();
		}
		
	    }
	}

	else if(source==m_plotItem){
	       
	    
	    try{
		DataSet ds= m_current.getDataSet();
		Vector varnames = new Vector();
		Hashtable arraycols = new Hashtable();
		String query = m_current.getQueryString();
		for(int k=1; k<ds.getMetaData().getColumnCount()+1;k++){
		    varnames.add(ds.getMetaData().getColumnName(k));
		    if( ds.getMetaData().getColumnTypeName(k).trim().startsWith("TpArray"))
			
			arraycols.put(ds.getMetaData().getColumnName(k).trim(), ds.getMetaData().getColumnTypeName(k).trim());
		    
		}
		
		Plotter plotter = new Plotter(varnames, arraycols, query, this);
	

	
		m_desktop.add(plotter);
		    
		plotter.setSelected(true);
			
		
	    }
	    catch(Exception ex){
		ex.printStackTrace();
	    }
	   
	}

	    else if(source==m_plot3dItem){
	       
	    
		try{
		DataSet ds= m_current.getDataSet();
		Vector varnames = new Vector();
		Hashtable arraycols = new Hashtable();
		String query = m_current.getQueryString();
		for(int k=1; k<ds.getMetaData().getColumnCount()+1;k++){
		    varnames.add(ds.getMetaData().getColumnName(k));
		    if( ds.getMetaData().getColumnTypeName(k).trim().startsWith("TpArray"))
			
			arraycols.put(ds.getMetaData().getColumnName(k).trim(), ds.getMetaData().getColumnTypeName(k).trim());
		    
		}
		
		Plotter3D plotter = new Plotter3D(varnames, arraycols, query, this);
	

	
		m_desktop.add(plotter);
		    
		plotter.setSelected(true);
			
		
	    }
	    catch(Exception ex){
		ex.printStackTrace();
	    }
	   
	}   
	//end jan 2004


	 
	}
	
    }


    //jan 2004
    public DataSet getPlottingSet(String s, int rowsOnPage){
	DataSet ret=null;
	try{
	this.setCursor(new Cursor(Cursor.WAIT_CURSOR));
	m_current.setCursor(new Cursor(Cursor.WAIT_CURSOR));
	
	Statement stmt = m_con.createStatement();

	stmt.setFetchSize(rowsOnPage);
	((TableConnection)m_con).setFullInfo(true);
		
	ret = (DataSet)stmt.executeQuery(s);
	((TableConnection)m_con).setFullInfo(false);
	this.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
	m_current.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
	}
	catch(Exception e){
	    e.printStackTrace();
	}


	return ret;

    }


    //end jan2004



    /** Get the number of MDI children this TableBrowser contains.
     */
    public int getNumChildren(){
	return m_children.size();
    }


    /** Sends a TaQL query s to the JDBC driver. Start a display in 
     * an MDI child. Create a new one if none exist or if newWindow is true.
     * Display rows starting st and numbering n.
     */

    
    public void query(boolean newWindow, String s, int st, int n){
	
	try{
	    int start=st;
	    int numRows=n;
	
	    //If a string was returned, say so.
	    if ((s != null) && (s.length() > 0)) {
		
		//	System.out.println("query: "+ s);    
	    
	    
	    //do query and 
	    //if no errors display in BrowserChild
	    //otherwise popup dialog indicating error
	    
	    this.setCursor(new Cursor(Cursor.WAIT_CURSOR));

	    //jdbc stuff
	   
		Statement stmt = m_con.createStatement();
		stmt.setFetchSize(n);
		ResultSet rs = stmt.executeQuery(s);
		
	   
		DataSet resultset =  (DataSet)rs;
	       
		
	    
		if(""==resultset.getErrorMessage()){

		   
		    if(m_children.size()==0||newWindow){
			m_current = new BrowserChild(this);
			m_children.add(m_current);
			m_current.setVisible(true);
			m_desktop.add(m_current);
			try{
			    m_current.setSelected(true);
			    
			} 
			catch(java.beans.PropertyVetoException e){
			}
		    }
		    
		    m_current.setTitle(((DataSetMetaData)resultset.getMetaData()).getTableName());
		    
		    int tro = resultset.getTotalRows();
		    if(numRows==0){
			m_current.setTotalPageNumber(1);	
		 
		    }
		    else{
		    if(tro%numRows==0){
			m_current.setTotalPageNumber(tro/numRows);	
		    }
		    else{
			m_current.setTotalPageNumber(tro/numRows+1);
		    }
		    }
		  
		    m_current.setQueryString(s);
		    m_current.setFirstRow(start);
		  
		    m_current.setRowsPerPage(numRows);
		    m_current.initColToShow(resultset.getMetaData().getColumnCount());
		    m_current.displayRecord(resultset,st,n);
		    m_current.setCurrPageNumber(1);
		}
		
		else{
		    JOptionPane.showMessageDialog(this, resultset.getErrorMessage(), "Query Syntax Error", JOptionPane.WARNING_MESSAGE);	
		    
		}
		
		this.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
	    }
	
	}
    
	catch(SQLException exc){
	    // exc.printStackTrace();
	    JOptionPane.showMessageDialog(this, "Query failed: Database Error", "Query Error", JOptionPane.WARNING_MESSAGE);
		
	}
	
    }
    
    /** Set the BrowserChild bc as this class's current MDI child.
     */

    public void setAsCurrent(BrowserChild bc){
	m_current =bc;
	
    }

    /** Remove the BrowserChild bc from the list of MDI children and
     * set the first child as the current.
     */

    public void updateChildren(BrowserChild bc){
	m_children.remove(bc);
	if(m_current==bc){
	    
	    if(0==m_children.size()){
		m_current=null;
	    }


	    else{
		m_current=(BrowserChild)m_children.firstElement();
		m_current.toFront();
	    }

	}
	
    }
    
    /** Get the JDeskTopPane that manages the MDI interface.
     */

    public JDesktopPane getDeskTop(){
	return m_desktop;
    }

   
    /** Return the MDI child with "current" status.
     */

    public BrowserChild getCurrent(){
	return m_current;
    }
    
    /** Start the Table Browser.
     */

    public static void main(String[] args) {
	TableBrowser frame=null;
	int port = (new Integer(args[1])).intValue();

	frame = new TableBrowser(args[0], port);
	frame.setSize(800, 600);
	
	frame.setVisible(true);
    }
    
    
    
}
