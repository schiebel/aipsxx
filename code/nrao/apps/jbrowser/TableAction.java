/** Abstract class for all update actions done in Table Browser
 *  that must eventually be done to the AIPS++ database. Each 
 *  subclass must know how to visually redo its change to the Table 
 *  Browser and undo the change. It must know how to turn the action
 *  it describes into an XML like string so that it may be sent
 *  to update the table.<p>
 *
 *  @author Jason Ye
 */
public abstract class TableAction{


    /** Undo this change from the Table Browser.
     */
    public abstract void undo();

    /** Redo this change to the Table Browser.
     */
    public abstract void redo();

    /** Create an XML String representing this action.
     */
    public abstract String toUpdateString();

}
