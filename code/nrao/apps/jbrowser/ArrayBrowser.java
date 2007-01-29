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
import javax.swing.event.*;


import javax.swing.ListSelectionModel;
import javax.swing.event.ListSelectionListener;
import javax.swing.event.ListSelectionEvent;



/** This class represents an n-dimensional array. It provides methods
 * for slicing, editing and graphically viewing the array.
 * 
 *<p> 
 *@author Jason Ye
 */


public class ArrayBrowser extends JInternalFrame implements ActionListener {
  
  
  
    private JScrollPane scrollPane;
    private ArrayTable table;
    private JTable rowHeaders;
    
    
    private JMenuBar m_menuBar;
    private int dim;
    private int[] indexingFactors;
    private TableBrowser m_browser;
    private Vector entries;
    private int[] axisLengths;
    private JMenu m_view;
    private JMenuItem m_slicer;
    private JMenu m_edit;
    private JMenuItem m_undo;
    private JMenuItem m_redo;
    private Stack m_actionLog;
    private Stack m_redoStack;
    private BrowserTable m_btable;
    private int[] m_sliceStart;
    private int[] m_sliceEnd;
    private ArrayAction m_arrayAction;
    private JMenu m_file;
    private JMenuItem m_commit;
    private JLabel dimlabel;
    private JToolBar toolbar;
    private JLabel slicelabel;
    private String m_type;
    private JLabel typelabel;
    private String m_arrayinfo;
    private int row;
    private int col;
    

    /** Construct an ArrayBrowser with parent TableBrowser browser, 
     *and a vector of Integers indicating dimensions. This creates an
     * empty array that may be filled with new values.
     */
    public ArrayBrowser(TableBrowser browser, Vector a){

	super("", 
              true, //resizable
              true, //closable
              true, //maximizable
              true);//iconifiable
	m_actionLog = new Stack();
	m_redoStack = new Stack();
	m_btable = (BrowserTable)browser.getCurrent().getTable();
	m_browser =browser;
	m_menuBar = new JMenuBar();
	this.setJMenuBar(m_menuBar);
	

	m_file= new JMenu("File [A]");
	m_menuBar.add(m_file);
	m_file.setMnemonic(KeyEvent.VK_A);

	m_commit = new JMenuItem("Commit", KeyEvent.VK_C);
	m_file.add(m_commit);
	m_commit.addActionListener(this);

	m_edit= new JMenu("Edit");
	m_menuBar.add(m_edit);
	m_edit.setMnemonic(KeyEvent.VK_I);

	m_undo = new JMenuItem("Undo", KeyEvent.VK_N);
	m_edit.add(m_undo);
	m_undo.addActionListener(this);

	m_redo = new JMenuItem("Redo [M]", KeyEvent.VK_M);
	m_edit.add(m_redo);
	m_redo.addActionListener(this);

	m_view= new JMenu("View [T]");
	m_menuBar.add(m_view);
	m_view.setMnemonic(KeyEvent.VK_T);
	
	m_slicer = new JMenuItem("Slice [Y]", KeyEvent.VK_Y);
	m_view.add(m_slicer);
	m_slicer.addActionListener(this);
	

	toolbar = new JToolBar();
	toolbar.setVisible(true);
	toolbar.setFloatable(false);
	getContentPane().add(toolbar, BorderLayout.SOUTH);

	slicelabel= new JLabel("slice");
	toolbar.add(slicelabel);
	toolbar.addSeparator();

	dimlabel = new JLabel("dimension");
	toolbar.add(dimlabel);
	toolbar.addSeparator();
	
	typelabel = new JLabel("type");
	toolbar.add(typelabel);
	


	toFront();
	
	
	setVisible(true);
	




	this.displayNew(a);
	m_browser.getDeskTop().add(this);

	try{
	    this.setSelected(true);
	} catch(Exception e){
	    //e.printStackTrace();
	}


    }

    /** Construct an ArrayBrowser from a string s and with the datatype type.
     *  s must be in the same format produced by C++ code, when an AIPS++ Array 
     *  is fed into a stream. 
     */
    public void setRow(int r){
	row=r;
    }
    
    public void setCol(int c){
	col=c;
    }
    
    public ArrayBrowser(String s, String type) {
        super("", 
              true, //resizable
              true, //closable
              true, //maximizable
              true);//iconifiable
	m_actionLog = new Stack();
	m_redoStack = new Stack();

	m_menuBar = new JMenuBar();
	this.setJMenuBar(m_menuBar);
	
	m_arrayinfo =s;
	m_file= new JMenu("File [A]");
	m_menuBar.add(m_file);
	m_file.setMnemonic(KeyEvent.VK_A);

	m_commit = new JMenuItem("Commit", KeyEvent.VK_C);
	m_file.add(m_commit);
	m_commit.addActionListener(this);

	m_edit= new JMenu("Edit");
	m_menuBar.add(m_edit);
	m_edit.setMnemonic(KeyEvent.VK_I);

	m_undo = new JMenuItem("Undo", KeyEvent.VK_N);
	m_edit.add(m_undo);
	m_undo.addActionListener(this);

	m_redo = new JMenuItem("Redo [M]", KeyEvent.VK_M);
	m_edit.add(m_redo);
	m_redo.addActionListener(this);

	m_view= new JMenu("View [T]");
	m_menuBar.add(m_view);
	m_view.setMnemonic(KeyEvent.VK_T);
	
	m_slicer = new JMenuItem("Slice [Y]", KeyEvent.VK_Y);
	m_view.add(m_slicer);
	m_slicer.addActionListener(this);
	
	toolbar = new JToolBar();
	toolbar.setVisible(true);
	toolbar.setFloatable(false);
	getContentPane().add(toolbar, BorderLayout.SOUTH);

	slicelabel= new JLabel("slice");
	toolbar.add(slicelabel);

	toolbar.addSeparator();
	dimlabel = new JLabel("dimension");
	toolbar.add(dimlabel);
	toolbar.addSeparator();

	typelabel = new JLabel("type");
	toolbar.add(typelabel);
	

	toFront();
	
	
	setVisible(true);
	this.setType(type);

	//	currentrow=-1;



	
    }

    /** Display the array.
     *
     * @param browser - parent TableBrowser
     */

    public void display(TableBrowser browser){
	m_btable = (BrowserTable)browser.getCurrent().getTable();
	m_browser =browser;
	this.display(m_arrayinfo);

    }

    public void parse(){
	this.silentInitiate(m_arrayinfo);
    }


    /** Set the type of the array.
     */
    
    public void setType(String s){
	m_type=s;
	typelabel.setText("type: "+s);
	
	
    }
    
    /** Get the type of the array.
     */

    public String getType(){
	return m_type;
    }

    /** Set the ArrayAction that will log changes to this array.
     */

    public void setArrayAction(ArrayAction a){
	m_arrayAction=a;
    }

    /** Get the log of changes to this array.
     */

    public Stack getActionLog(){
	return m_actionLog;
    }
    
    /** Get the redo stack associated with the array.
     */

    public Stack getRedoStack(){
	return m_redoStack;
    }

    /** Maps user button input to appropriate actions.
     */

    public void actionPerformed(ActionEvent e){
	JMenuItem source = (JMenuItem)(e.getSource());
	if(source==m_slicer){

	    // bring up slicing option

	    try{
		// to be replaced later with better dialog
		String s="";
		s= (String)JOptionPane.showInputDialog(
							       this,
							       "See Slice:\n",
						       
							       "Slicer",
							       JOptionPane.PLAIN_MESSAGE);
		//parse the new slice coordinates
		
		
		int[] arr = new int[dim];
		int[] startArr = new int[dim];
		try{
		StringTokenizer tok =new StringTokenizer(s);
		String token;
		for(int i=0;i<dim;i++){
		    token = tok.nextToken();
		    StringTokenizer t2= new StringTokenizer(token.trim(), ":");
		    startArr[i]= (new Integer(t2.nextToken())).intValue();
		    
		    arr[i]= (new Integer(t2.nextToken())).intValue();
		}
		}catch(Exception nex){
		    startArr=m_sliceStart;
		    arr= m_sliceEnd;
		}
		
		m_sliceStart=startArr;
		m_sliceEnd=arr;

		//get and show the slice
		Vector newdata = getSlice(arr, startArr);
		Vector columns = new Vector();
		//System.out.println("slicedata size: "+newdata.size());
		for(int x=0;x<((Vector)newdata.elementAt(0)).size();x++){
		    columns.add(String.valueOf(x));
		}	
		
		
		table = new ArrayTable(newdata, columns, this);
		
		scrollPane.setViewportView(table);
		
		table.setPreferredScrollableViewportSize(new Dimension(300, 200));
		setSize(new Dimension(300, 200));
		
		
		table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
		table.doLayout();
		
		// Start add row numbers
		Vector rowNumVector = new Vector();
		Vector rowNumHeader = new Vector();
		rowNumHeader.add("");
		for (int m=1; m<table.getRowCount()+1;m++){
		    Vector temp = new Vector();
		    temp.add(String.valueOf(m-1));
		    rowNumVector.add(temp);
		    
		}
		
		rowHeaders = new JTable(rowNumVector,rowNumHeader);
		
		
		
		
		
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
		
		
		String sltext="slice: ";
		for(int khu=0;khu<m_sliceStart.length;khu++){
		    sltext+=m_sliceStart[khu]+":"+m_sliceEnd[khu]+" ";
		    
		}
		slicelabel.setText(sltext.trim());
		
		TableColumnModel tcm = table.getColumnModel();
		int numberofcolumns=table.getColumnCount();
		int colsmax=65;
		FontMetrics fm = table.getFontMetrics(table.getFont());
		
		// resize columns
		
		for(int counter=0;counter<numberofcolumns;counter++){
		    TableColumn colmod = tcm.getColumn(counter);
		    
		    
		    
		    for(int roco=0;roco<table.getRowCount();roco++){
			
			if(fm.stringWidth((String)table.getValueAt(roco,counter))>colsmax)
			    colsmax= fm.stringWidth((String)table.getValueAt(roco,counter));
		    }
		    
		    colmod.setPreferredWidth(colsmax+20);
		}    
		table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
		
	    }
	    catch(ArrayIndexOutOfBoundsException ex){
		JOptionPane.showMessageDialog(this, "Invalid Slice Coordinates.", "View Slice Error",JOptionPane.WARNING_MESSAGE );
	    }
	}
	
	    
	else if(source==m_undo){
	    table.undoLastChange();
	}
	else if(source==m_redo){
	    table.redoLastChange();
	}

	else if(source==m_commit){
	    
	    if(m_arrayAction!=null){
		TableAction action;
		String arrayupdates="";
		for(int i=0;i<m_actionLog.size();i++){
		    action=(TableAction)m_actionLog.elementAt(i);
		    arrayupdates+=action.toUpdateString();

		}


		//commit the changes to the master action log in browser child

		m_arrayAction.setOperations(arrayupdates);
		
		m_actionLog.clear();
		m_redoStack.clear();
		m_btable.insertChange(m_arrayAction);
	
		if(dim==1){
		    
		    
		    Vector tmp = (Vector)entries.elementAt(0);
		    String newst = "[";
		    for(int ko=0;ko<tmp.size()-1;ko++){
			newst+=((String)tmp.elementAt(ko)).trim()+", ";
		    }
		    newst+=((String)tmp.elementAt(tmp.size()-1)).trim();
		    newst+="]";
		    //System.out.println(newst);
		    m_btable.setValueAt(newst, row, col);
		}
		
		JOptionPane.showMessageDialog(this, "Any changes done to array will not\nbe reflected until the table has been\nsaved to the database.", "Reminder",JOptionPane.INFORMATION_MESSAGE );
		
		
		
	    }

	    else{
		System.err.println("Array Error: no array action set");
	    }
	}

	
    }



    /** Set the cell at index arr to newVal.
     */

    public void setEntry(int[] arr, Object newVal){
	if(dim==1){
	    Vector temp = (Vector)entries.elementAt(0);
	    temp.removeElementAt(arr[0]);
	    // System.out.println("putting: "+newVal+ " at "+arr[0]);
	    temp.insertElementAt(newVal, arr[0]);
	}
	else if( dim==2){
	    Vector temp = (Vector)entries.elementAt(arr[0]);
	    temp.removeElementAt(arr[1]);
	    // System.out.println("putting: "+newVal+ " at "+arr[0]);
	    temp.insertElementAt(newVal, arr[1]);
	}
	else{
	    int len = indexingFactors.length;
	    for (int a=0;a<arr.length;a++){
		//	System.out.println("entry: arr["+a+"] : "+arr[a] );
	    }
	    
	    int index=0;
	    for (int i=0;i<len;i++){
		//	System.out.println("indexingF["+i+"]="+indexingFactors[i]);
		index+=indexingFactors[i]*arr[i+2];
		
	    }
	    
	    index+=arr[1];
	    // System.out.println("index : "+index);
	    //System.out.println("size of Entries: "+entries.size());
	
	    Vector temp = (Vector)entries.elementAt(index);
	    
	    temp.removeElementAt(arr[0]);
	    //System.out.println("putting: "+newVal+ " at "+arr[0]);
	    temp.insertElementAt(newVal, arr[0]);
	}
    }
    

    /** Create a new ArrayBrowser with dimensions dimensions
     */

    public void displayNew(Vector dimensions){
	Vector columns = new Vector();
	Vector data = new Vector();
	entries = new Vector();
	if(dimensions.size()==1){
	    dim =1;
	    axisLengths= new int[dim];
	   
	    
	    //  data.add(new Vector());

	    
	    
	    Vector tempVector = new Vector();
	    entries.add(tempVector);
	    for(int i=0;i<((Integer)dimensions.elementAt(0)).intValue();i++){
		
		//System.out.println("blank "+i);
		tempVector.add("blank");
		
		
		
	    }
	    axisLengths[0]=((Integer)dimensions.elementAt(0)).intValue();
	    
	    indexingFactors=null;
	    int[] stest = new int[1];
	    stest[0]=0;
	    m_sliceStart=stest;
            m_sliceEnd = stest;
	    data=getSlice(stest, stest);
	    columns.add(String.valueOf(0));
	   
	}

	else{
	    dim=dimensions.size();
	    axisLengths= new int[dim];
	    for(int ghi=0;ghi<dimensions.size();ghi++){
		axisLengths[ghi]=((Integer)dimensions.elementAt(ghi)).intValue();

	    }
	    if(dimensions.size()==2){
		indexingFactors=null;
		
	    }
	    else{
		indexingFactors = new int[dim-2];
		indexingFactors[0] = axisLengths[1];
		for(int f=1;f<dim-2;f++){
		    
		    indexingFactors[f]=indexingFactors[f-1]*axisLengths[f+1];
		
		    
		}
	    }

	    int prod=1;
	    
	    for(int ij=1;ij<dimensions.size();ij++){
		prod=prod*((Integer)dimensions.elementAt(ij)).intValue();
	    }
	    
	    //System.out.println("product is: "+ prod);
	    for(int abc=0;abc<prod;abc++){
	    Vector tempVector = new Vector();
	    entries.add(tempVector);
	    for(int def =0;def<((Integer)dimensions.elementAt(0)).intValue();def++)
		tempVector.add("blank");
	    }
	    
	    int[] stest = new int[dim];
	    
	    for(int fa=0;fa<dim;fa++){
		stest[fa]=0;
	    }
	    m_sliceStart=stest;
	    m_sliceEnd = stest;
	    data=getSlice(stest, stest);
	    columns.add(new Integer(0));
	}
	table = new ArrayTable(data, columns,this);
       

	table.setPreferredScrollableViewportSize(new Dimension(300, 200));
	setSize(new Dimension(300, 200));
	scrollPane = new JScrollPane(table);

	
	getContentPane().add(scrollPane, BorderLayout.CENTER);

	table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
	table.doLayout();
	
	// Start add row numbers
	Vector rowNumVector = new Vector();
	Vector rowNumHeader = new Vector();
	rowNumHeader.add("Row");
	for (int m=1; m<table.getRowCount()+1;m++){
	    Vector temp = new Vector();
	    temp.add(String.valueOf(m-1));
	    rowNumVector.add(temp);
	  
	}
	
	rowHeaders = new JTable(rowNumVector,rowNumHeader);
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

	String dltext="dim: ";
	dltext+= axisLengths[0];
	for(int yew=1; yew<axisLengths.length;yew++){
	    dltext+=" x "+ axisLengths[yew];
	    
	}
	dimlabel.setText(dltext.trim());

	String sltext="slice: ";
	for(int khu=0;khu<m_sliceStart.length;khu++){
	    sltext+=m_sliceStart[khu]+":"+m_sliceEnd[khu]+" ";
	    
	}
	slicelabel.setText(sltext.trim());

	table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
	
    }

    /** Display the array represented by string s. */

    public void display(String s ){
	Vector columns = new Vector();
	Vector data = new Vector();
	entries = new Vector();
	//	System.out.println("ArrayBrowser parsing string: " + s);
	if(s.startsWith("[")){
	    dim =1;
	    axisLengths= new int[dim];
	    //  System.out.println("1D array type: "+m_type);
	   
	    // System.out.println("1-D");
	    int end = s.indexOf(']');
	    s = s.substring(0,end+1);
	    //System.out.println("1D string is:\n "+s );
	    int i=0;
	    if (m_type.trim().equals("TpArrayComplex")||m_type.trim().equals("TpArrayDComplex")){
		//System.out.println("1d if entered");
		StringTokenizer tok = new StringTokenizer(s, "[(,)]", true);
		String val= "";
		
		String ival="";
		String com="";
		Vector tempVector = new Vector();
		entries.add(tempVector);
		
		while(tok.hasMoreTokens()){
		    val = tok.nextToken();
		    if(val.trim().equals("(")){
			val=tok.nextToken().trim();
			com = tok.nextToken();
			ival= tok.nextToken().trim();
			tempVector.add("("+val+","+ival+")");
			i++;
		    }
		}
		
	    }
	    
	    else{
	   
	    StringTokenizer tok = new StringTokenizer(s, "[,]");
	    String val="";
	  
	    
	    Vector tempVector = new Vector();
	    entries.add(tempVector);
	    while(tok.hasMoreTokens()){
		
		val = tok.nextToken();
		
		//System.out.println("array token: "+ val);
		tempVector.add(val);
	
		i++;
		
	    }

	    }
	    axisLengths[0]=i;
	    
	    indexingFactors=null;
	    int[] stest = new int[1];
	    stest[0]=0;
	    m_sliceStart=stest;
            m_sliceEnd = new int[1];
	    
	    m_sliceEnd[0] = (axisLengths[0]-1);
	    
	    data=getSlice(m_sliceEnd, m_sliceStart );
	    
	    
	   
	    for(int ewk = 0; ewk < axisLengths[0]; ewk++){
		columns.add(String.valueOf(ewk));

	    }
	    



	    
	}
	
	else if(s.startsWith("Axis Lengths:")){
	    //System.out.println("2-D");
	    dim=2;
	    axisLengths=new int[dim];
	    StringTokenizer tok = new StringTokenizer(s, "[,]");
	    String val="";
	    val=tok.nextToken();
	    //System.out.println("arraytoken: "+val);
	   
	   
	    int rowNum = (new Integer(tok.nextToken().trim())).intValue();
	    axisLengths[0]=rowNum;
	    //System.out.println("row number: "+rowNum);
	   
	    int colNum = (new Integer(tok.nextToken().trim())).intValue();
	    axisLengths[1]=colNum;
	    //System.out.println("col number: "+colNum);
	    for (int i=0; i<rowNum;i++){
		entries.add(new Vector());
	    }
	    val=tok.nextToken();
	    //System.out.println("arraytoken: "+val);
	    
	    for (int j=0; j<rowNum;j++){
		for(int k=0; k<colNum;k++){
		    val=tok.nextToken(" \n[]").trim();
		    if(val.endsWith(",")){
			int end = val.lastIndexOf(',');
			val = val.substring(0,end);
		    }
		    //    System.out.println("arraytoken: "+val);
		    ((Vector)entries.elementAt(j)).add(val);
		    
		}
	    }
	  
	    indexingFactors=null;
	    int[] stest = new int[dim];
	    stest[0]=0;
	    stest[1]=0;
	    m_sliceStart=stest;
            m_sliceEnd = new int[dim];
	    m_sliceEnd[0]= axisLengths[0]-1;
	    m_sliceEnd[1]= axisLengths[1]-1;
	    data=getSlice(m_sliceEnd, m_sliceStart);
	    for(int ewk = 0; ewk<axisLengths[1]; ewk++){
		columns.add(new Integer(ewk));
	    }
		
	}

	else if(s.startsWith("Ndim=")){
	    //System.out.println("Multi_D");
	 
	    StringTokenizer tok= new StringTokenizer(s, "= ");
	    String val="";
	    val=tok.nextToken();
	    //System.out.println("Ndim: "+val);
	    dim =  (new Integer(tok.nextToken().trim())).intValue();
	    //System.out.println("dim  number: "+dim);
	    axisLengths = new int[dim];
	    String temp = tok.nextToken("[,]");
	    int numElements=1;
	    for (int a=0;a<dim;a++){
		temp = tok.nextToken("[,]");
		//System.out.println("Axis length: " +temp);
		axisLengths[a]= (new Integer(temp.trim())).intValue();
		numElements=numElements*(new Integer(temp.trim())).intValue();
	    }


	    
	    for(int b=0;b<(numElements/axisLengths[0]);b++){
		for(int c=0; c<dim; c++){
		    //skip tokens
		    temp = tok.nextToken("[,]");
		    if(temp.trim().equals(""))
			temp = tok.nextToken("[,]");
		    //  System.out.println("skipping: " +temp);   

		}
		Vector tempVector = new Vector();
		entries.add(tempVector);
		for(int d=0;d<axisLengths[0];d++){
		    temp = tok.nextToken("[,]");
		    // System.out.println("the goods: " +temp);   
		    tempVector.add(temp.trim());
		    
		}
	       

	    }

	    indexingFactors = new int[dim-2];
	    indexingFactors[0] = axisLengths[1];
	    for(int f=1;f<dim-2;f++){
		
		indexingFactors[f]=indexingFactors[f-1]*axisLengths[f+1];


	    }

	    int[] stest = new int[dim];
	    for(int fa=0;fa<dim;fa++){
		stest[fa]=0;
	    }
	    m_sliceStart=stest;
	    m_sliceEnd = stest;
	    data=getSlice(stest, stest);
	    for(int x=0;x<((Vector)data.elementAt(0)).size();x++){
		columns.add(String.valueOf(x));
	    }
	    for(int y=0;y<data.size();y++){
		
		//	System.out.println("------------------");
		Vector t=(Vector)data.elementAt(y);
		for(int z=0;z<t.size();z++){
		    
		    //  System.out.println(t.elementAt(z));
		}

	    }
	}
	
	else if(s.trim().startsWith("AipsError")){
	    JOptionPane.showMessageDialog(this, s, "Display Array Error", JOptionPane.WARNING_MESSAGE);	
	    //System.out.println("array error");
	}
	
	table = new ArrayTable(data, columns,this);
       

	table.setPreferredScrollableViewportSize(new Dimension(300, 200));
	setSize(new Dimension(300, 200));
	scrollPane = new JScrollPane(table);

	
	getContentPane().add(scrollPane, BorderLayout.CENTER);

	table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
	table.doLayout();
	
	// Start add row numbers
	Vector rowNumVector = new Vector();
	Vector rowNumHeader = new Vector();
	rowNumHeader.add("");
	for (int m=1; m<table.getRowCount()+1;m++){
	    Vector temp = new Vector();
	    temp.add(String.valueOf(m-1));
	    rowNumVector.add(temp);
	  
	}
	
	rowHeaders = new JTable(rowNumVector,rowNumHeader);
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
	String dltext="dim: ";
	dltext+= axisLengths[0];
	for(int yew=1; yew<axisLengths.length;yew++){
	    dltext+=" x "+ axisLengths[yew];
	    
	}
	dimlabel.setText(dltext.trim());

	String sltext="slice: ";
	
	for(int khu=0;khu<m_sliceStart.length;khu++){
	    sltext+=m_sliceStart[khu]+":"+m_sliceEnd[khu]+" ";
	    
	}
	slicelabel.setText(sltext.trim());


	TableColumnModel tcm = table.getColumnModel();
	int numberofcolumns=table.getColumnCount();
	int colsmax=65;
	FontMetrics fm = table.getFontMetrics(table.getFont());

	for(int counter=0;counter<numberofcolumns;counter++){
	    TableColumn colmod = tcm.getColumn(counter);
	    
	    
	    
	    for(int roco=0;roco<table.getRowCount();roco++){

		if(fm.stringWidth((String)table.getValueAt(roco,counter))>colsmax)
		    colsmax= fm.stringWidth((String)table.getValueAt(roco,counter));
	    }
	    
	colmod.setPreferredWidth(colsmax+20);
	   
	    

	}
	
	    
	table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
    }


  
  //   public String getMultiDValue(int[] arr){
// 	int index=0;
// 	for (int i=dim-1;i>1;i--){
// 	    index=index+arr[i]*indexingFactors[i-2];
// 	}
// 	index+=arr[1]+1;
// //	System.out.println("accessing index: "+index);
// 	Vector temp=(Vector)entries.elementAt(index);
// 	String ret = (String)temp.elementAt(arr[0]);
// 	return ret;
	
//     }
    
    /** Get a Vector from the slice starting at arrStart and
	ending at arr. The returned Vector is readily displayable
	by this an ArrayTable without futher manipulation.
    */


    public void silentInitiate(String s){

	Vector columns = new Vector();
	Vector data = new Vector();
	entries = new Vector();
	//	System.out.println("ArrayBrowser parsing string: " + s);
	if(s.startsWith("[")){
	    dim =1;
	    axisLengths= new int[dim];
	    //  System.out.println("1D array type: "+m_type);
	   
	    // System.out.println("1-D");
	    int end = s.indexOf(']');
	    s = s.substring(0,end+1);
	    //System.out.println("1D string is:\n "+s );
	    int i=0;
	    if (m_type.trim().equals("TpArrayComplex")||m_type.trim().equals("TpArrayDComplex")){
		//System.out.println("1d if entered");
		StringTokenizer tok = new StringTokenizer(s, "[(,)]", true);
		String val= "";
		
		String ival="";
		String com="";
		Vector tempVector = new Vector();
		entries.add(tempVector);
		
		while(tok.hasMoreTokens()){
		    val = tok.nextToken();
		    if(val.trim().equals("(")){
			val=tok.nextToken().trim();
			com = tok.nextToken();
			ival= tok.nextToken().trim();
			tempVector.add("("+val+","+ival+")");
			i++;
		    }
		}
		
	    }
	    
	    else{
	   
	    StringTokenizer tok = new StringTokenizer(s, "[,]");
	    String val="";
	  
	    
	    Vector tempVector = new Vector();
	    entries.add(tempVector);
	    while(tok.hasMoreTokens()){
		
		val = tok.nextToken();
		
		//System.out.println("array token: "+ val);
		tempVector.add(val);
	
		i++;
		
	    }

	    }
	    axisLengths[0]=i;
	    
	    indexingFactors=null;
	    int[] stest = new int[1];
	    stest[0]=0;
	    m_sliceStart=stest;
            m_sliceEnd = new int[1];
	    
	    m_sliceEnd[0] = (axisLengths[0]-1);
	    
	    data=getSlice(m_sliceEnd, m_sliceStart );
	    
	    
	   
	    for(int ewk = 0; ewk < axisLengths[0]; ewk++){
		columns.add(String.valueOf(ewk));

	    }
	    



	    
	}
	
	else if(s.startsWith("Axis Lengths:")){
	    //System.out.println("2-D");
	    dim=2;
	    axisLengths=new int[dim];
	    StringTokenizer tok = new StringTokenizer(s, "[,]");
	    String val="";
	    val=tok.nextToken();
	    //System.out.println("arraytoken: "+val);
	   
	   
	    int rowNum = (new Integer(tok.nextToken().trim())).intValue();
	    axisLengths[0]=rowNum;
	    //System.out.println("row number: "+rowNum);
	   
	    int colNum = (new Integer(tok.nextToken().trim())).intValue();
	    axisLengths[1]=colNum;
	    //System.out.println("col number: "+colNum);
	    for (int i=0; i<rowNum;i++){
		entries.add(new Vector());
	    }
	    val=tok.nextToken();
	    //System.out.println("arraytoken: "+val);
	    
	    for (int j=0; j<rowNum;j++){
		for(int k=0; k<colNum;k++){
		    val=tok.nextToken(" \n[]").trim();
		    if(val.endsWith(",")){
			int end = val.lastIndexOf(',');
			val = val.substring(0,end);
		    }
		    //    System.out.println("arraytoken: "+val);
		    ((Vector)entries.elementAt(j)).add(val);
		    
		}
	    }
	  
	    indexingFactors=null;
	    int[] stest = new int[dim];
	    stest[0]=0;
	    stest[1]=0;
	    m_sliceStart=stest;
            m_sliceEnd = new int[dim];
	    m_sliceEnd[0]= axisLengths[0]-1;
	    m_sliceEnd[1]= axisLengths[1]-1;
	    data=getSlice(m_sliceEnd, m_sliceStart);
	    for(int ewk = 0; ewk<axisLengths[1]; ewk++){
		columns.add(new Integer(ewk));
	    }
		
	}

	else if(s.startsWith("Ndim=")){
	    //System.out.println("Multi_D");
	 
	    StringTokenizer tok= new StringTokenizer(s, "= ");
	    String val="";
	    val=tok.nextToken();
	    //System.out.println("Ndim: "+val);
	    dim =  (new Integer(tok.nextToken().trim())).intValue();
	    //System.out.println("dim  number: "+dim);
	    axisLengths = new int[dim];
	    String temp = tok.nextToken("[,]");
	    int numElements=1;
	    for (int a=0;a<dim;a++){
		temp = tok.nextToken("[,]");
		//System.out.println("Axis length: " +temp);
		axisLengths[a]= (new Integer(temp.trim())).intValue();
		numElements=numElements*(new Integer(temp.trim())).intValue();
	    }


	    
	    for(int b=0;b<(numElements/axisLengths[0]);b++){
		for(int c=0; c<dim; c++){
		    //skip tokens
		    temp = tok.nextToken("[,]");
		    if(temp.trim().equals(""))
			temp = tok.nextToken("[,]");
		    //  System.out.println("skipping: " +temp);   

		}
		Vector tempVector = new Vector();
		entries.add(tempVector);
		for(int d=0;d<axisLengths[0];d++){
		    temp = tok.nextToken("[,]");
		    // System.out.println("the goods: " +temp);   
		    tempVector.add(temp.trim());
		    
		}
	       

	    }

	    indexingFactors = new int[dim-2];
	    indexingFactors[0] = axisLengths[1];
	    for(int f=1;f<dim-2;f++){
		
		indexingFactors[f]=indexingFactors[f-1]*axisLengths[f+1];


	    }

	    int[] stest = new int[dim];
	    for(int fa=0;fa<dim;fa++){
		stest[fa]=0;
	    }
	    m_sliceStart=stest;
	    m_sliceEnd = stest;
	    data=getSlice(stest, stest);
	    for(int x=0;x<((Vector)data.elementAt(0)).size();x++){
		columns.add(String.valueOf(x));
	    }
	    for(int y=0;y<data.size();y++){
		
		//	System.out.println("------------------");
		Vector t=(Vector)data.elementAt(y);
		for(int z=0;z<t.size();z++){
		    
		    //  System.out.println(t.elementAt(z));
		}

	    }
	}
	
	else if(s.trim().startsWith("AipsError")){
	    JOptionPane.showMessageDialog(this, s, "Display Array Error", JOptionPane.WARNING_MESSAGE);	
	    //System.out.println("array error");
	}
	
	
    }

    public Vector getSlice(int[] arr, int[] arrStart){
	//check to see if they satisfy the axis info
	m_sliceStart = arrStart;
	m_sliceEnd =arr;
	Vector data = new Vector();
	int index1=0;
	int index2=0;
	int numEl1=0;
	int numEl2=0;
	int whichIndex=0;
	int extra=0;
	for(int i=0;i<arr.length; i++){
	    if(arr[i]!=0){
		if(whichIndex==0){
		    index1= i;
		    numEl1=arr[i];
		    whichIndex=1;
		}

		else if (whichIndex==1){
		    index2=i;
		    numEl2=arr[i];
		    whichIndex=2;
		}

		else{

		    extra=1;
		}
	    }

	}
	

	int sindex1=index1;
	int sindex2=index2;
	int snumEl1=arrStart[sindex1];
	int snumEl2=arrStart[sindex2];
	if(arr.length==1||sindex1==sindex2){
	    snumEl2=0;
	    numEl2=0;
	}

// 	System.out.println("snumEl1: "+snumEl1+ " at "+ sindex1);
// 	System.out.println("snumEl2: "+snumEl2+ " at "+sindex2);

// 	System.out.println("numEl1: "+numEl1+" at "+ index1);
// 	System.out.println("numEl2: "+numEl2+"at "+ index2);
// 	System.out.println("extra: "+extra);
	if(numEl1<=axisLengths[index1]&&numEl2<=axisLengths[index2]&&extra==0&&snumEl1<=numEl1&&snumEl2<=numEl2){
	    int[] entry = new int[dim];
	    if(dim ==1){
		
		Vector newVec = new Vector();
		data.add(newVec);
		for(int k=arrStart[0];k<arr[0]+1;k++){
		    entry[0]=k;
		    newVec.add(getEntry(entry));
		    //   System.out.println("1dslice");
		}
	    }
	    else{
	    for(int k=snumEl1;k<numEl1+1;k++){
	    
		for (int j=0;j<dim;j++){
		    entry[j]=0;

		}
		entry[index1]=k;
		Vector newVec = new Vector();
		
	
		data.add(newVec);
		for(int l=snumEl2;l<numEl2+1;l++){
		   //  System.out.println("arr["+index1+"] = "+k);
// 		    System.out.println("arr["+index2+"] = "+l);
// 		    System.out.println("=================");
		    if(whichIndex==1){
			//second index not assigned
			
		    }
		    else{
			entry[index2]=l;
		    }
		    newVec.add(getEntry(entry));
		    
		}
		
		}
	    }
	}
	else{
	     JOptionPane.showMessageDialog(this,"Invalid slice parameters." ,"View Slice Error" , JOptionPane.WARNING_MESSAGE);	
	    
	}
	return data;
    }

    /** Get the enty indicated by index arr*/

    public String getEntry(int[] arr){
	String ret="";
	if(1==dim){
	    Vector temp =  (Vector)entries.elementAt(0);
	    ret = (String)temp.elementAt(arr[0]);
	    
	}
	    
	else if(2==dim){

	    Vector temp =(Vector)entries.elementAt(arr[0]);
	    ret =(String)temp.elementAt(arr[1]);
	}
	else{	
	    int len = indexingFactors.length;
	    for (int a=0;a<arr.length;a++){
		// System.out.println("entry: arr["+a+"] : "+arr[a] );
	    }
	  
	    int index=0;
	    for (int i=0;i<len;i++){
		// System.out.println("indexingF["+i+"]="+indexingFactors[i]);
		index+=indexingFactors[i]*arr[i+2];
		
	    }
	    
	    index+=arr[1];
	    //	System.out.println("index : "+index);
	    //	System.out.println("size of Entries: "+entries.size());
	    
	    Vector temp = (Vector)entries.elementAt(index);
	
	    ret= (String)temp.elementAt(arr[0]);
	    //	System.out.println("ret : "+ret);
	}
	
	return ret;
	
	
    }
    /** Get the int array representing the start of current slice.*/

    public int[] getStartSlice(){
	return m_sliceStart;
    }

    /** Get the int array representing the end of current slice.*/
    public int[] getEndSlice(){
	return m_sliceEnd;

    }
    /** Refreshes the view of the array. This is usually called after
     * manipulating the array.
     */

    public void reshowSlice(){

  
	Vector newdata = getSlice(m_sliceEnd, m_sliceStart);
	Vector columns = new Vector();
	for(int x=0;x<((Vector)newdata.elementAt(0)).size();x++){
	    columns.add(String.valueOf(x));
	}	
	table = new ArrayTable(newdata, columns, this);
	scrollPane.setViewportView(table);

	table.setPreferredScrollableViewportSize(new Dimension(300, 200));
	// 		setSize(new Dimension(300, 200));
	// 		scrollPane = new JScrollPane(table);
	
	
// 		getContentPane().add(scrollPane, BorderLayout.CENTER);
	
	table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
	table.doLayout();
	
	// Start add row numbers
		Vector rowNumVector = new Vector();
		Vector rowNumHeader = new Vector();
		rowNumHeader.add("Row");
		for (int m=1; m<table.getRowCount()+1;m++){
		    Vector temp = new Vector();
		    temp.add(String.valueOf(m-1));
		    rowNumVector.add(temp);
		    
		}
		
		rowHeaders = new JTable(rowNumVector,rowNumHeader);

		
		
		
		
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
		


		String sltext="slice: ";
		for(int khu=0;khu<m_sliceStart.length;khu++){
		    sltext+=m_sliceStart[khu]+":"+m_sliceEnd[khu]+" ";
		    
		}
		slicelabel.setText(sltext.trim());
		



		TableColumnModel tcm = table.getColumnModel();
		int numberofcolumns=table.getColumnCount();
		int colsmax=65;
		FontMetrics fm = table.getFontMetrics(table.getFont());
		
		for(int counter=0;counter<numberofcolumns;counter++){
		    TableColumn colmod = tcm.getColumn(counter);
		    
	    
		    
		    for(int roco=0;roco<table.getRowCount();roco++){
			
			if(fm.stringWidth((String)table.getValueAt(roco,counter))>colsmax)
			    colsmax= fm.stringWidth((String)table.getValueAt(roco,counter));
		    }
		    
		    colmod.setPreferredWidth(colsmax+20);
		    
		    
		    
		}
		
		

		
		table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
    }
    
    public int[] getAxisLengths(){
	return axisLengths;
    }

}
