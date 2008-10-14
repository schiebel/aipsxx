/** This class logs updates to the ResultSet within the ResultSet
 * itself. The row numbers and column numbers start at 1.
 */

public class Update{

    public static int CELL = 87987;
    public static int ARRAY = 69879;
    private Object m_old;
    private Object m_new;
    private int m_row;
    private int m_col;
    private int m_type;
    

    /** Constructor.
     */
    public Update(){}


    /** Construct an Update with the values given.
     */

    public Update(Object old, Object nw, int row, int col){
	m_old=old;
	m_new=nw;
	m_row=row;
	m_col=col;
	m_type=CELL;
    } 

    /** Set the old value.
     */
    public void setOld(Object val){
	m_old = val;
    }

    /** Set the new value.
     */

    public void setNew(Object val){
	m_new = val;
    }


    /** Get the old value.
     */

    public Object getOld(){
	return m_old;
    }
    

    /** Get the new value.
     */

    public Object get(){
	return m_new;
    }

    /** Set the row number.
     */
    public void setRow(int i){
	m_row = i;
    }

    /** Set the column number.
     */
    public void setColumn(int i){
	m_col = i;
    }

    /** Set the type.
     */
    public void setType(int i){
	m_type = i;
    }

    /** Get the row number.
     */

    
    public int getRow(){

	return m_row;
    }

    /** Get the column number.
     */

    
    public int getColumn(){

	return m_col;
    }


    /** Get the type.
     */

    
    public int getType(){

	return m_type;
    }


    public String toUpdateString(){
	String ret ="";
	if(m_type==CELL){
	    ret+="<UPDATE row = "+ (m_row-1)+" col = "+(m_col-1)+" val = "+m_new+ " >\n";
 

	}

	else if(m_type==ARRAY){


	}
	

	return ret;
    }

}
