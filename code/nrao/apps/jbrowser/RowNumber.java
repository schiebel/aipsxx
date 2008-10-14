import javax.swing.*;
import java.util.*;
import javax.swing.table.*;

/** This table is used exclusively to display row numbers for the BrowserTable 
 * and ArrayTable classes.
 *
 *@author Jason Ye
 */
public class RowNumber extends JTable{

    public RowNumber(Vector a, Vector b){
	super(a, b);

    }

    /** Delete the last row number. Called when a row is deleted from the
     * table.
    */

    public void deleteRowNumber(){
	if(getRowCount()>0)
	    ((DefaultTableModel)dataModel).removeRow(getRowCount()-1);
    }
    
    /** Insert a row number. Called when a row is inserted to the
     * table.
     */



    public void insertRowNumber(){
	Vector temp = new Vector();
	temp.add(String.valueOf(getRowCount()+1));
	((DefaultTableModel)dataModel).insertRow(getRowCount(), temp);
    }
}
