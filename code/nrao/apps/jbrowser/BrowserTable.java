import javax.swing.*;
import java.util.*;
import javax.swing.event.*;
import java.awt.event.*;
import java.lang.*;
import java.sql.*;
import javax.swing.table.*;

/** Models a table that is used to display AIPS++ tables.
 *@author Jason Ye
 */

public class BrowserTable extends JTable implements KeyListener{

    private TableAction m_currentAction;
    private Stack m_actionLog;
    private Stack m_redoStack;
    private boolean m_undoOK;
    private ResultSetMetaData m_metaData;
    private boolean m_format;
    private BrowserChild  m_window;
    private boolean m_delRowOk;
    private boolean m_insRowOk;
    private Vector m_data;

    /** Construct a BrowserTable with the data vectors headers and data and
     * a reference to the BrowserChild that contains it.
     */

    public BrowserTable(Vector headers, Vector data, BrowserChild window){
	
	super(headers, data);
	m_currentAction=null;
	m_actionLog = new Stack();
	m_redoStack = new Stack();
	m_undoOK=true;
	this.addKeyListener(this);
	m_metaData=null;
	m_format=false;
	m_window=window;
	m_delRowOk=false;
	m_insRowOk=false;
	m_data=headers;
	JTableHeader head = this.getTableHeader();
	head.setReorderingAllowed(false);
	

    }

    /** Delete the row numbered rownumber.
     */

    public void deleteRows(int rownumber){
	
	if(-1==rownumber){
	    if(m_delRowOk){
	    
		m_currentAction=null;
		int[] numbers = this.getSelectedRows();
		//	System.out.println("number rows in model: " +m_data.size());
		
		for(int i=numbers.length-1; i>=0;i--){
		    // System.out.println("attemping to delete row: "+numbers[i]);
		   
		    Vector row = (Vector)m_data.elementAt(numbers[i]);
		   
		    DelRowAction action = new DelRowAction(numbers[i], row, this);
		    m_actionLog.push(action);
		    m_redoStack.clear();
		    ((DefaultTableModel)this.dataModel).removeRow(numbers[i]);
		    m_window.getRowNumber().deleteRowNumber();
		    m_undoOK=true;
		    
		}
		
		
		
	    }
	    else{
		JOptionPane.showMessageDialog(null, "Rows may not be deleted from this table", "Delete Row Error",JOptionPane.WARNING_MESSAGE );
		
	    }
	}

	else{
	    m_currentAction=null;
	    
	    ((DefaultTableModel)this.dataModel).removeRow(rownumber);
	    m_window.getRowNumber().deleteRowNumber();
	    m_undoOK=true;
	}

    }
    
    /** Add a rows, each with data Vector b.
     */

    public void addRows(int a, Vector b){
	
	for (int i=0;i<a;i++){
	    int rowNum = this.getRowCount();
	    insertRows(rowNum, b, true);
	   
	    
	}

    }

    /** Insert the data Vector data at row number rownumber. If create Action
     * is true, create and log a TableAction describing action.
     */

    public void insertRows(int rownumber, Vector data, boolean createAction){

	if(createAction){
	    if(m_insRowOk){
		m_currentAction=null;
	       	((DefaultTableModel)this.dataModel).insertRow(rownumber, data);
		InsRowAction action = new InsRowAction(rownumber, this);
		m_actionLog.push(action);
		m_redoStack.clear();
		m_window.getRowNumber().insertRowNumber();
		m_undoOK=true;
		//	System.out.println("insert row called");
	    }
	}

	else{
	    m_currentAction=null;
	    ((DefaultTableModel)this.dataModel).insertRow(rownumber, data);
	    m_window.getRowNumber().insertRowNumber();
	    m_undoOK=true;
	}

    }

    /** Set whether deleting rows is enabled.
     */
    public void setDelRow(boolean b){
	m_delRowOk=b;
	//	System.out.println("setting delete row to: "+b);
    }

    
    /** Set whether inserting rows is enabled.
     */
    public void setInsRow(boolean b){
	//	System.out.println("setting insert row to: "+b);
	m_insRowOk=b;
    }

    /** This method is called when the table changes. It is responsible
     * for logging the action that occured. Do not call explicitly.
     */

    public void tableChanged(TableModelEvent e){
	int firstRow=0;
	
	super.tableChanged(e);
	if(m_window!=null){
	    firstRow =m_window.getFirstRow();
	    
	}
	if(e.getType()==TableModelEvent.UPDATE){
	if(m_currentAction!=null){
	    if(e.getFirstRow()==-1||e.getColumn()==-1||e.getLastRow()==-1){
		//	System.out.println("row change has coordinate -1" );
	    }
	    else{
		if(firstRow+e.getFirstRow()== ((CellUpdateAction)m_currentAction).getRow()&&e.getColumn()==((CellUpdateAction)m_currentAction).getCol()){
		    //   System.out.println("new value is:" +this.getValueAt(e.getFirstRow(), e.getColumn()));
		    
		    ((CellUpdateAction)m_currentAction).setNewVal(getValueAt(e.getFirstRow(), e.getColumn()));
		    // System.out.println("\n\ncurrent action before push");
		    // System.out.println("row: "+ ((CellUpdateAction)m_currentAction).getRow() );
		  //   System.out.println("col: "+((CellUpdateAction)m_currentAction).getCol());
// 		    System.out.println("old: " +((CellUpdateAction)m_currentAction).getOldVal());
// 		    System.out.println("new: " +((CellUpdateAction)m_currentAction).getNewVal());
		    
		    if(((CellUpdateAction)m_currentAction).getOldVal()!=((CellUpdateAction)m_currentAction).getNewVal()){
			m_actionLog.push(m_currentAction);
			m_redoStack.clear();
		    }
		    else{
			//	System.out.println("no change made to cell, not pushed");
		    }
		    m_currentAction=null;
		    m_undoOK=true;
		   //  System.out.println("column "+e.getColumn() );
// 		    System.out.println("rowstart "+e.getFirstRow() );
		    
		    if(e.getFirstRow()!=e.getLastRow()){
		// 	System.err.println("WARNING MULTIPLIE ROWS Changed");
// 			System.out.println("rowend "+e.getLastRow() );
		    }
		}
	    
	    else{

		//	System.out.println("\n\n\naction not made, indicies do not correspond\n\n\n");
		m_format=false;
		m_currentAction =null;
		m_undoOK=true;
		setValueAt("",e.getFirstRow(),e.getColumn() );
		int r =e.getFirstRow()+1;
		int c = e.getColumn()+1;
		
		JOptionPane.showMessageDialog(null, "You must press ENTER after typing value.\n Failure to do so will cause cell value to be empty.\n Cell @ row: "+r +", col: "+c , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
		
		
		
		
	    }
	    }
	}
	else{
	    //  System.out.println("no m action");
	}
	}

	else if(e.getType()==TableModelEvent.INSERT){

	}

	else if(e.getType()==TableModelEvent.DELETE){
	    //  System.out.println("deleting rows: "+e.getFirstRow()+" to "+e.getLastRow());
	}

    }
    
    /** Log the TableAction change.
     */

    public void insertChange(TableAction change){
	m_actionLog.push(change);
	    
	
    }

    /** Method is invoked when a cell is editted. This is responsible for
     * dynamic array querying, etc... Do not call explicitly.
     */

    public boolean editCellAt(int row, int col, EventObject e){
	this.setRowSelectionAllowed(false);
	this.setColumnSelectionAllowed(false);
	Hashtable arrays = m_window.getArrays();
	Integer num = new Integer(col+1);
	if(arrays!=null&&arrays.containsKey(num)){
	    // System.out.println("edit array at: "+(row+m_window.getFirstRow())+" , " +col);
	    
	    if(((String)((Vector)arrays.get(num)).elementAt(row)).equalsIgnoreCase("EMPTY ARRAY")){
		
		String s = (String)JOptionPane.showInputDialog(
							       null,
							       "Enter dimensions of new array:\n",  "New Array",  JOptionPane.PLAIN_MESSAGE);
		if(s!=null){
		StringTokenizer tok = new StringTokenizer(s);
		Vector dimensions= new Vector();
		while(tok.hasMoreTokens()){
		    try{
			Integer in = new Integer(tok.nextToken());
			dimensions.add(in);
		    }
		    catch(NumberFormatException exc){
			JOptionPane.showMessageDialog(null, "Invalid dimensions." , "Input Error",JOptionPane.WARNING_MESSAGE );
		    }
		   
		}
		//	System.out.println(dimensions);
		ArrayAction aaction = new ArrayAction(row+m_window.getFirstRow(), col);
	
		ArrayBrowser b = new ArrayBrowser(m_window.getTableBrowser(), dimensions);
		b.setRow(row);
		b.setCol(col);
		b.setArrayAction(aaction);
		}
	    }
	    
	    else{
		Vector arrayCol = (Vector)arrays.get(num);
		String arrayString = (String)arrayCol.elementAt(row);
	
		m_window.displayArray(row+m_window.getFirstRow(), col);
		//to do store action
		
	    }

	   
	}
	else{
	    
	   
	m_currentAction=null;
	m_undoOK=false;
	m_format=true;
// 	System.out.println("edit started");
	
// 	System.out.println("row " + (row+m_window.getFirstRow()));
// 	System.out.println("col " + col);
// 	System.out.println("value is "+ getValueAt(row, col));
	
	m_currentAction = new CellUpdateAction(row+m_window.getFirstRow(), col, getValueAt(row, col), this);
	}
	return super.editCellAt(row, col, e);

    }

    /** Undo the last change.
     */

    public void undoLastChange(){
	if(m_undoOK){
	try{
	    // System.out.println("\n\nundo: " + m_actionLog.size() );
	TableAction action = (TableAction)m_actionLog.pop();
	
	
	
	
// 	System.out.println("row: "+ ((CellUpdateAction)action).getRow() );
// 	System.out.println("col: "+((CellUpdateAction)action).getCol());
// 	System.out.println("old: " +((CellUpdateAction)action).getOldVal());
// 	System.out.println("new: " +((CellUpdateAction)action).getNewVal());
	action.undo();
	m_redoStack.push(action);
	}catch(EmptyStackException e){
	    //System.out.println("no more undos");
	}
	}
	else{
	    // System.out.println("\n\n\ncannot undo\n\n\n");
	    JOptionPane.showMessageDialog(null, "You must press ENTER or ESC before choosing UNDO." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
	}

    }

    /** Redo the last change.
     */

    public void redoLastChange(){
	if(m_undoOK){	
	try{
	    //	System.out.println("redo:" + m_redoStack.size());
	TableAction action = (TableAction)m_redoStack.pop();

// 	System.out.println("row: "+ ((CellUpdateAction)action).getRow() );
// 	System.out.println("col: "+((CellUpdateAction)action).getCol());
// 	System.out.println("old: " +((CellUpdateAction)action).getOldVal());
// 	System.out.println("new: " +((CellUpdateAction)action).getNewVal());



	action.redo();

	
	m_actionLog.push(action);
	}catch(EmptyStackException e){
	    //System.out.println("no more redos");
	}
	}

	else{
	    // System.out.println("\n\n\ncannot redo\n\n\n");
	    JOptionPane.showMessageDialog(null, "You must press ENTER or ESC before choosing REDO." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
	}


    }


    /** Clear the redo log and the action log.
     */

    public void clearChanges(){
	m_actionLog.clear();
	m_redoStack.clear();
    }

  

    /** Create XML string describing the changes in the action log.
     */

    public String constructUpdate(){
	
	String ret="";
	for(int i=0; i<m_actionLog.size(); i++){
	    TableAction action = (TableAction)m_actionLog.elementAt(i);
	    ret+= action.toUpdateString();
	    
	}
	

	return ret;
    }

  
    public void editingCanceled(ChangeEvent e){
	super.editingCanceled(e);
	//System.out.println("\nWarning, must press enter, value not yet stored\n");
	m_currentAction=null;
	
    }


    /** Starts the type formatting of the last entry.
     */

    public void editingStopped(ChangeEvent e){

	super.editingStopped(e);
	if(m_format){
	    checkFormat((CellUpdateAction)m_actionLog.peek());
	}
	//System.out.println("\neditting stopped\n");
	
    }
    

    /** Reset the editting cycle if ESCAPE is pressed.
     */
    

    public void keyPressed(KeyEvent e){
	if(e.getKeyCode()==KeyEvent.VK_ESCAPE){
	    // System.out.println("escape pressed");
	    m_undoOK=true;
	    m_currentAction=null;
	    //	    m_currentAction=(CellUpdateAction)m_actionLog.lastElement();
	}
    }

    /** Does nothing.
     */
    public void keyReleased(KeyEvent e){
	
    }
     /** Does nothing.
     */
    public void keyTyped(KeyEvent e){
	
    }


    /** Set the reference to the DataSet's meta data.
     */

    public void setMetaData(ResultSetMetaData md){

	m_metaData = md;
	
    }

    /** Format the new value in CellUpdateAction according to the datatype
     * for the column.
     */

    public void checkFormat(CellUpdateAction a){

	int col = a.getCol();
	//System.out.println("action log size: "+m_actionLog.size());
	if(m_metaData!=null){
	    try{
		System.out.println("getting column type of " + a);
		String tp = m_metaData.getColumnTypeName(col+1);
		tp=tp.trim();
		System.out.println("type is: " + tp);
		
		if(tp.equals("TpShort")){
		    try{
			Short b = new Short((String)a.getNewVal());
		    }catch(NumberFormatException e){
			System.out.println("invalid short");
			JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Short." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
			a.undo();
			m_actionLog.remove(a);
		

		

		    
		
		    }
	  
	    
		    
		}
		
		else if(tp.equals("TpInt")){
		    try{
			Integer b = new Integer((String)a.getNewVal());
		    }catch(NumberFormatException e){
			System.out.println("invalid int");
			JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Integer." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
			a.undo();
			m_actionLog.remove(a);
			System.out.println("redo stack size is: "+m_redoStack.size());
		
	
			

		

		    
		
		    }
		}

		else if(tp.equals("TpString")){

		}

		else if(tp.equals("TpFloat")){
		    try{
			Float b = new Float((String)a.getNewVal());
		    }catch(NumberFormatException e){
			System.out.println("invalid float");
			JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Float." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
			a.undo();
			m_actionLog.remove(a);
		

		    
		
		    }
		}

		else if(tp.equals("TpDouble")){
		    try{
			Double b = new Double((String)a.getNewVal());
		    }catch(NumberFormatException e){
			System.out.println("invalid double");
			JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Double." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
			
			a.undo();
			m_actionLog.remove(a);
		

		

		    
		
		    }
		}

		else if(tp.equals("TpBool")){
		    String nval = (String)a.getNewVal();
		    if(!( nval.equalsIgnoreCase("true")||nval.equalsIgnoreCase("false")||nval.equalsIgnoreCase("0")||nval.equalsIgnoreCase("1")))
			{
			    System.out.println("  invalid boolean: "+nval);
			    a.undo();
			    m_actionLog.remove(a);
			    	JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Bool. (0 or 1 or true or false)" , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );

			}

		    
			
		}

		else if(tp.equals("TpUChar")){
		    System.out.println("Unsupported: TpUChar");
		
		}

		else if(tp.equals("TpUInt")){
		    
		    try{
			Integer b = new Integer((String)a.getNewVal());
			if(b.intValue()<0)
			    throw new NumberFormatException("negative uInt");
		    }catch(NumberFormatException e){
		
			JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Unsigned Integer." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
			
			a.undo();
			m_actionLog.remove(a);
			System.out.println("redo stack size is: "+m_redoStack.size());
		
	
			

		

		    
		
		    }
		    
		}

		else if(tp.equals("TpComplex")){
		    String nval = (String)a.getNewVal();
		    String real="";
		    String imag="";
		    StringTokenizer tok = new StringTokenizer(nval, "(,)", false);
		    if(tok.hasMoreTokens())
			real = tok.nextToken();
		    if(tok.hasMoreTokens())
			imag = tok.nextToken();
		 
		    try{
			Float c = new Float(real.trim());
			Float b = new Float(imag.trim());
			
		    }catch(NumberFormatException e){
			
			JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Complex." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
			a.undo();
			m_actionLog.remove(a);
		

		    
		
		    }
		 
		}

		else if(tp.equals("TpDComplex")){

		    String nval = (String)a.getNewVal();
		    String real="";
		    String imag="";
		    StringTokenizer tok = new StringTokenizer(nval, "(,)", false);
		    if(tok.hasMoreTokens())
			real = tok.nextToken();
		    if(tok.hasMoreTokens())
			imag = tok.nextToken();
		 
		    try{
			Double c = new Double(real.trim());
			Double b = new Double(imag.trim());
			
		    }catch(NumberFormatException e){
			
			JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: DComplex." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
			a.undo();
			m_actionLog.remove(a);
		

		    
		
		    }


		    
		}
		else if(tp.equals("TpDate")){
		    String nval = (String)a.getNewVal();
		    
		   
		    StringTokenizer tok = new StringTokenizer(nval, "-:",false);
		    
		    try{
			if(tok.countTokens()!=6)
			    throw new NumberFormatException("missing date components");
			int year= (new Integer(tok.nextToken().trim())).intValue();
			int month= (new Integer(tok.nextToken().trim())).intValue();	
			int day= (new Integer(tok.nextToken().trim())).intValue();
			int hour= (new Integer(tok.nextToken().trim())).intValue();	
			int min= (new Integer(tok.nextToken().trim())).intValue();
			int sec= (new Integer(tok.nextToken().trim())).intValue();

			if(month>12||month<1||day>31||day<1||hour>23||hour<1||min>59||min<1||sec<1||sec>59)
			    throw new NumberFormatException("invalid date");

		    }catch(NumberFormatException e){
			
			JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Date." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
			a.undo();
			m_actionLog.remove(a);
		

		    
		
		    }

		    
		}
		
		else{

		    System.out.println("Unknown Type: "+tp);
		}

		
		}

	    catch(SQLException e){
		e.printStackTrace();
	    }

	}

    }

}
