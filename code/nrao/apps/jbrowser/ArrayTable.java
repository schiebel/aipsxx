import javax.swing.*;
import java.util.*;
import javax.swing.event.*;
import java.awt.event.*;
import java.lang.*;
import java.sql.*;

/** Models a table that is used to specifically display arrays.
 *  Contains many methods relating to the editing of an array.
 *<p>
 *@author Jason Ye
 */
public class ArrayTable extends JTable implements KeyListener{

    private TableAction m_currentAction;
    private Stack m_actionLog;
    private Stack m_redoStack;
    private boolean m_undoOK;
    private ResultSetMetaData m_metaData;
    private boolean m_format;
    private ArrayBrowser  m_window;
    public ArrayTable(Vector data, Vector headers, ArrayBrowser window){
	
	super(data, headers);
	m_currentAction=null;
	m_actionLog = window.getActionLog();
	m_redoStack = window.getRedoStack();
	m_undoOK=true;
	this.addKeyListener(this);
	m_metaData=null;
	m_format=false;
	m_window=window;
	
	
    }

 
    /** This method is invoked every time a table changes. Do not call
     *  explicitly. It creates an ArrayAction that will store the action 
     *  that triggered this method.
     * 
     */
    
    public void tableChanged(TableModelEvent e){
	
	super.tableChanged(e);
	//	System.out.println("array changed called");
	
	if(m_currentAction!=null){
	    if(e.getFirstRow()==-1||e.getColumn()==-1||e.getLastRow()==-1){
		//System.out.println("row change has coordinate -1" );
		// invalid action
	    }
	    else{

		// find the coordinates of the change within the n-dimensional
		// array

		int trow = e.getFirstRow();
		int tcol = e.getColumn();
	
		int[] sliceStart = m_window.getStartSlice();
		int[] sliceEnd =m_window.getEndSlice();
		int[] coord = new int[sliceStart.length];
		
		for (int id=0;id<sliceStart.length;id++){
		    coord[id]=0;
		}
		int sindex1=-1;
		int sindex2=-1;
		int snumEl1=0;
		int snumEl2=0;
		int swhichIndex=0;
		int sextra=0;
		for(int si=0;si<sliceStart.length; si++){
		    if(sliceEnd[si]!=0){
			if(swhichIndex==0){
			    sindex1= si;
			    snumEl1=sliceStart[si];
			    swhichIndex=1;
			}
			
			else if (swhichIndex==1){
		    sindex2=si;
		    snumEl2=sliceStart[si];
		    swhichIndex=2;
			}
			
			else{
			    
		    sextra=1;
			}
		    }
		    
		}

		if(coord.length==1){
		    sindex1=0;
		    coord[0]= snumEl1+tcol;
		    sindex2=0;
		}
		else{
		if(sindex1!=-1){
		    int abc= (snumEl1+trow);
		    coord[sindex1]=abc;
		}
		else{
		    sindex1=0;
		}
		if(sindex2!=-1){
		    int bcd = (snumEl2+tcol);
	    
		    coord[sindex2]=bcd;
		}	
		else{sindex2=0;}
		}
		
		
		int[] actcoord = ((ArrayCellAction)m_currentAction).getCoord();
		//System.out.println("oldval: " +((ArrayCellAction)m_currentAction).getOldVal());
	// 	System.out.println("first index of action:"+actcoord[sindex1]);
// 		System.out.println("second index of action:"+actcoord[sindex2]);
// 		System.out.println("first: "+sindex1);
// 		System.out.println("second: "+sindex2);
		
		if(actcoord[sindex1]==coord[sindex1]&&actcoord[sindex2]==coord[sindex2]){
		    //System.out.println("new value is:" +this.getValueAt(e.getFirstRow(), e.getColumn()));

		    //the ArrayAction is valid, finalize
				      



		    ((ArrayCellAction)m_currentAction).setNewVal(getValueAt(e.getFirstRow(), e.getColumn()));

		   
		    
		    if(((ArrayCellAction)m_currentAction).getOldVal()!=((ArrayCellAction)m_currentAction).getNewVal()){
			
			// insert onto the update log
			
			m_actionLog.push(m_currentAction);
			// must format here
		    
			m_window.setEntry(coord,this.getValueAt(e.getFirstRow(), e.getColumn()) );
		    
		    //System.out.println("calling redo's clear");
		    m_redoStack.clear();
		    
		    }
		    else{
			//System.out.println("no change made to cell, not pushed");
		    }
		    m_currentAction=null;
		    m_undoOK=true;
		    
		    
		    if(e.getFirstRow()!=e.getLastRow()){
			System.err.println("WARNING MULTIPLIE ROWS Changed");
			//System.out.println("rowend "+e.getLastRow() );
		    }
		}
	    
	    else{

		//System.out.println("\n\n\naction not made, indicies do not correspond\n\n\n");
		
		// if the indices do not correspond, then the action is invalid
		
		m_format=false;
		m_currentAction =null;
		setValueAt("",e.getFirstRow(),e.getColumn() );
		int r =e.getFirstRow()+1;
		int c = e.getColumn()+1;
		
		JOptionPane.showMessageDialog(null, "You must press ENTER after typing value.\n Failure to do so will cause cell value to be empty or unchanged.\n Cell @ row: "+r +", col: "+c , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
		
		
		
		
	    }
	    }
	}
	else{
	    //System.out.println("no m action");
	}


    }

    /** This method is called when a cell is clicked. It instantiates
     * the ArrayAction that will later be finalized by tableChanged method.
     * Do not call explicitly.
     */
    
    public boolean editCellAt(int row, int col, EventObject e){
	
	//System.out.println("Edit cell at called");

	// map the row - col number to coordinates in an n-dimensional
	//array

	m_currentAction=null;
	
	m_undoOK=false;
	m_format=true;
	int[] sliceStart = m_window.getStartSlice();
	int[] sliceEnd = m_window.getEndSlice();

	
	//	System.out.println("row " + row);
	//System.out.println("col " + col);
	//System.out.println("value is "+ getValueAt(row, col));
	
	int[] coord = new int[sliceStart.length];
	for (int id=0;id<sliceStart.length;id++){
	    coord[id]=0;
	}
	int sindex1=-1;
	int sindex2=-1;
	int snumEl1=0;
	int snumEl2=0;
	int swhichIndex=0;
	int sextra=0;
	for(int si=0;si<sliceStart.length; si++){
	    if(sliceEnd[si]!=0){
		if(swhichIndex==0){
		    sindex1= si;
		    snumEl1=sliceStart[si];
		    swhichIndex=1;
		}

		else if (swhichIndex==1){
		    sindex2=si;
		    snumEl2=sliceStart[si];
		    swhichIndex=2;
		}

		else{

		    sextra=1;
		}
	    }

	}
	if(coord.length ==1){
	    coord[0]=snumEl1+col;
	}
	else{
	if(sindex1!=-1){
	    int abc= (snumEl1+row);
	    coord[sindex1]=abc;
	    //  System.out.println("coord1: "+coord[sindex1]);
	}
	if(sindex2!=-1){
	    int bcd = (snumEl2+col);
	    
	    coord[sindex2]=bcd;
	    //System.out.println("coord2: "+coord[sindex2]);
	}	

	}

	// create the ArrayAction

	m_currentAction = new ArrayCellAction(coord, getValueAt(row, col), this);
	//System.out.println("ending editCell: "+m_currentAction);
	return super.editCellAt(row, col, e);

    }

    /** This method pops the last change off the log, and undos it, 
     * and puts it on the redo stack.
     */

    public void undoLastChange(){
	if(m_undoOK){


	try{
	    
	    TableAction action = (TableAction)m_actionLog.pop();
	    
	
	
	

	    action.undo();
	    m_redoStack.push(action);
	
	}catch(EmptyStackException e){//System.out.println("no more undos");
	}
	}
	else{
	    
	    JOptionPane.showMessageDialog(null, "You must press ENTER or ESC before choosing UNDO." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
	    
	}
	
    }
  
    /** This method pops the last change off the redo log, and redo's it, 
     * and puts it on the action log.
     */

    public void redoLastChange(){
	if(m_undoOK){	
	    try{
		
		TableAction action = (TableAction)m_redoStack.pop();



		
		action.redo();

		
		m_actionLog.push(action);
	    }catch(EmptyStackException e){
		//System.out.println("no more redos");
	    }
	}
	
	else{
	    
	    JOptionPane.showMessageDialog(null, "You must press ENTER or ESC before choosing REDO." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
	    
	}
	
	
    }
    

    //public void clearChanges(){}

  
    /** This method constructs an XML string representing all the
     * changes to this array.
     */ 
    public String constructUpdate(){
	
	String ret="";
	for(int i=0; i<m_actionLog.size(); i++){
	    TableAction action = (TableAction)m_actionLog.elementAt(i);
	    ret+= action.toUpdateString();
	    
	}
	
	
	return ret;
    }
    
    /** Do not call explicitly.
     */
    
    public void editingCanceled(ChangeEvent e){
	super.editingCanceled(e);
	//System.out.println("\nWarning, must press enter, value not yet stored\n");
	m_currentAction=null;
	
    }



    /** Do not call explicitly. Triggered after edit, calls method that
     * formats the entry.
     */
    public void editingStopped(ChangeEvent e){
	
	super.editingStopped(e);
	m_currentAction=null;
	    checkFormat((ArrayCellAction)m_actionLog.peek());

	    //System.out.println("\neditting stopped\n");
	
    }

    /** If ESCAPE key is pressed, reset the editing cycle.
     */
    public void keyPressed(KeyEvent e){
	if(e.getKeyCode()==KeyEvent.VK_ESCAPE){
	    //    System.out.println("escape pressed");
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
    

    /** Redisplays the current slice of the array.
     */
    public void reshowSlice(){
	
	m_window.reshowSlice();
    }

    /** Changes the value of the cell indicated by coord to newVal.
     */
    public void updateArray(int[] coord, Object newVal){
	m_window.setEntry(coord, newVal);
    }

    
    /** Check if the input indicated by a matches the type
     * of this array.
     */

    public void checkFormat(ArrayCellAction a){
	
	String tp = m_window.getType().trim();
	//	System.out.println("Array's type is: "+tp);
	if(tp.equals("TpArrayShort")){
	    try{
		Short b = new Short((String)a.getNewVal());
	    }catch(NumberFormatException e){
		//System.out.println("invalid short");
		JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Short." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
		a.undo();
		m_actionLog.remove(a);
		

		
		
		    
		
	    }
	  
	    
	    
	}
	else if(tp.equals("TpArrayUShort")){
	    //	    System.out.println("unsupported: "+tp);
	   //  try{
// 		Short b = new Short((String)a.getNewVal());
// 	    }catch(NumberFormatException e){
// 		System.out.println("invalid short");
// 		JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Short." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
// 		a.undo();
// 		m_actionLog.remove(a);
		

		
		
		    
		
// 	    }
	    
	    
	    
	}
	
	else if(tp.equals("TpArrayInt")){
	    try{
		Integer b = new Integer((String)a.getNewVal());
	    }catch(NumberFormatException e){
		//System.out.println("invalid int");
		JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Integer." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
		a.undo();
		m_actionLog.remove(a);
		//	System.out.println("redo stack size is: "+m_redoStack.size());
		
		
		
		
		
		
		
		
	    }
	}
	
	else if(tp.equals("TpArrayString")){
	    //no type check required
	}
	
	else if(tp.equals("TpArrayFloat")){
	    try{
		Float b = new Float((String)a.getNewVal());
	    }catch(NumberFormatException e){
		//System.out.println("invalid float");
		JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Float." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
		a.undo();
		m_actionLog.remove(a);
		
		
		
		
	    }
	}
	
	else if(tp.equals("TpArrayDouble")){
	    try{
		Double b = new Double((String)a.getNewVal());
	    }catch(NumberFormatException e){
		//	System.out.println("invalid double");
		JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Double." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
		a.undo();
		m_actionLog.remove(a);
		
		
		
		
		
		
	    }
	}
	
	else if(tp.equals("TpArrayBool")){
	    String nval = (String)a.getNewVal();
	    if(!( nval.equalsIgnoreCase("true")||nval.equalsIgnoreCase("false")||nval.equalsIgnoreCase("0")||nval.equalsIgnoreCase("1")))
		{
		    // System.out.println("  invalid boolean: "+nval);
		    a.undo();
		    m_actionLog.remove(a);
		    	JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Bool (0 or 1 or true or false)." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );	
		}
	    
	    
	}
	
	else if(tp.equals("TpArrayUChar")){
	    //System.out.println("Unsupported: "+tp);
	    
	}
	
	else if(tp.equals("TpArrayChar")){
	    //System.out.println("Unsupported: "+tp);
	    
	}
	

	else if(tp.equals("TpArrayUInt")){

	    try{
		Integer b = new Integer((String)a.getNewVal());
		if(b.intValue()<0)
		    throw new NumberFormatException("negative uInt");
	    }catch(NumberFormatException e){
		
		JOptionPane.showMessageDialog(null, "Invalid Format. Type Required: Unsigned Integer." , "Data Entry Warning",JOptionPane.WARNING_MESSAGE );
		
		a.undo();
		m_actionLog.remove(a);
		
		
		
		
		
		

		    
		
	    }

	    //System.out.println("Unsupported: "+tp);
	}
	
	else if(tp.equals("TpArrayComplex")){
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
	
	else if(tp.equals("TpArrayDComplex")){
	    
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
	
	else{
	    
	    System.err.println("Unknown Type: "+tp);
	}
	
    }
	
    
	
}
   


