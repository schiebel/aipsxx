import java.util.*;

/** Models an action for a specific array, that encompasses all
 * edit operations done to the array.
 * @author Jason Ye
 */

public class ArrayAction extends TableAction{

    private String m_operations;
    private int m_row;
    private int m_col;
   
    /** Create an ArrayAction for the Array in the row row and col column
     * of the AIPS++ table.
     */
 
    public ArrayAction(int row, int col){
	m_operations ="";
	m_row =row;
	m_col =col;
    }

    /** Set the string representing all changes made to the array.
     */

    public void setOperations(String s){
	m_operations=s;
    }
    
    public void undo(){}

    public void redo(){}

    public String toUpdateString(){
	String ret="";
	ret+="<ARRAYUPDATE row = "+m_row+" col = "+m_col+" >\n";
	ret+=m_operations;
	ret+="</ARRAYUPDATE>\n";

	return ret;
	
    }

}
