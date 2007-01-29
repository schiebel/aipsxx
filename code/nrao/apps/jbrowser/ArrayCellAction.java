import javax.swing.*;

/** <p> Models an array cell edit action.
 *@author Jason Ye
*/

public class ArrayCellAction extends TableAction{

    private int[] m_coordinates;
    private Object m_oldVal;
    private Object m_newVal;
    private JTable m_arraytable;
    
    /** Create an action with index coord, previous value oldVal, and 
     * the table used to display the array, table.
     */

    public ArrayCellAction(int[] coord, Object oldVal, JTable table){
	
	m_coordinates = coord;

	m_oldVal = oldVal;
	m_arraytable = table;


    }
    
    /**<p> set the new value for this action*/

    public void setNewVal(Object val){
	
	    
	m_newVal=val;
    }

    public void undo(){
	
	((ArrayTable)m_arraytable).updateArray(m_coordinates, m_oldVal);
	((ArrayTable)m_arraytable).reshowSlice();
    }
    public void redo(){
	
	((ArrayTable)m_arraytable).updateArray(m_coordinates, m_newVal);
	((ArrayTable)m_arraytable).reshowSlice();
    

	
    }

    public String toUpdateString(){
	String ret="";
	
	int len = m_coordinates.length;
	String coord= "[ ";
	for(int i = 0;i<len;i++){
	    coord+=String.valueOf(m_coordinates[i])+" ";
	}
	coord+="]";
	

	ret+="<ARRAYCELLUPDATE coordinates = "+coord+" val = "+m_newVal+ " >\n";


	return ret;
	
    }

    /**<p> Get the n dimensional array index of this action.*/

    public int[] getCoord(){
	return m_coordinates;
    }

    /**<p> Get the value that used to be in this array cell.*/
    
    public Object getOldVal(){
	return m_oldVal;
    }
    
    /**<p> Get the value that is now in this array cell.*/
    
    public Object getNewVal(){
	return m_newVal;

    }

    
}
