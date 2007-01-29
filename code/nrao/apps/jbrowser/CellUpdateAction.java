import javax.swing.*;


/** CellUpdateAction models a change done to a table.
 *
 * @author Jason Ye
 *
 */

public class CellUpdateAction extends TableAction{

    private int m_row;
    private int m_col;
    private Object  m_oldVal;
    private Object m_newVal;
    private JTable m_table;

    /** Create a CellUpdateAction with row nubmer row, column number col,
     * previous value oldVal and the owner JTable table.
     */

    public CellUpdateAction(int row, int col, Object oldVal, JTable table){

	m_row=row;
	m_col=col;
	m_oldVal=oldVal;
	m_table=table;
	
    }
    
    /** Set the new value of this Action to val. 
     *
     */

    public void setNewVal(Object val){
		    
	m_newVal=val;
	
	    
	
    }

    public void undo(){
	m_table.setValueAt(m_oldVal,m_row, m_col);
	

    }
    public void redo(){
	m_table.setValueAt(m_newVal, m_row, m_col);

	

    }

    public String toUpdateString(){
	String ret="";
	
	ret+="<UPDATE row = "+ m_row+" col = "+m_col+" val = "+m_newVal+ " >\n";


	return ret;
	
    }

    /** Get the row number.
     */

    public int getRow(){
	return m_row;
    }

    /** Get the column number.
     */

    public int getCol(){
	return m_col;
    }


    /** Get the value of the cell prior to changing.
     */

    public Object getOldVal(){
	return m_oldVal;
    }

    
    /** Get the value of the cell after changing.
     */

    public Object getNewVal(){
	return m_newVal;

    }


    
    /** Set the row number.
     */

    public void setRow(int a){
	m_row =a;
    }


    /** Set the column number.
     */
    public void setCol(int a){
	m_col=a;
    }

}
