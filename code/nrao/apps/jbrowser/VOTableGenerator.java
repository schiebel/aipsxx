import org.jdom.*;
import org.jdom.output.XMLOutputter;
import java.util.*;
import com.megginson.sax.DataWriter;
import org.xml.sax.*;
import java.io.*;
import org.xml.sax.helpers.AttributesImpl;



public class VOTableGenerator{

    public VOTableGenerator(){
	
	
    }

    /*The first row is 1.
     */
    public void genVOTab(DataSet ds, int start, int end, String filename){
	if(ds!=null){
	    try{
		
	    System.out.println("generating xml.......\n\n\n");
	  
	    
	   
	    XMLOutputter fmt = new XMLOutputter();
	    fmt.setIndent("  "); // use two space indent
	    fmt.setNewlines(true);
	    FileOutputStream stream = new FileOutputStream(filename);
	    
	    DocType dt = new DocType("VOTABLE", "http://us-vo.org/xml/VOTable.dtd");
	    fmt.output(dt, stream);
	    
	    
	    DataWriter w = new DataWriter(new OutputStreamWriter(stream));

	    DataSetMetaData metaData = (DataSetMetaData)ds.getMetaData();
	    
	    w.setIndentStep(2);
	    
	    w.startDocument();
	    
	    AttributesImpl al = new AttributesImpl();
	    al.addAttribute("","version","", "", "1.0");
	    w.startElement("","VOTABLE","", al);
	    
	    al.clear();
	    al.addAttribute("","name","", "", metaData.getTableName() );
	    w.startElement("","RESOURCE","", al);
	    
	    w.startElement("TABLE");


	    // column names

	    int colNum = metaData.getColumnCount();
	    
	    for (int i=1;i<colNum+1;i++){
	    
		al.clear();
		al.addAttribute("","ID","", "",  metaData.getColumnName(i));
		al.addAttribute("","name","", "",  metaData.getColumnName(i));
		al.addAttribute("","datatype","", "",  metaData.getColumnTypeName(i));
		w.emptyElement("","FIELD","", al);
		

	
	
	    }
	      
	    w.startElement("DATA");
	    w.startElement("TABLEDATA");
	    
	    //rows of data
	    int row = start-1;
	    if(1==start)
		ds.beforeFirst();
	    else{
		
		ds.absolute(start-1);
	    }
	    while(ds.next()){
		row++;
		w.startElement("TR");
		for(int j=1;j<colNum+1; j++){
		    if(ds.getMetaData().getColumnTypeName(j).startsWith("TpArray")){
			String str = ((AIPSArray)(ds.getArray(j).getArray())).linearForm();
			w.dataElement("TD", str);
		    }

		    else{
			w.dataElement("TD", ds.getString(j));
		    }
			
		}
		
		w.endElement("TR");
		if(end!=-1){
		    if(row==end)
			break;
		}
	    }
	   
	    w.endElement("TABLEDATA");
	    w.endElement("DATA");
	    w.endElement("TABLE");
	    w.endElement("RESOURCE");
	    w.endElement("VOTABLE");
	    w.endDocument();
   
	    stream.close();

	    }
	    catch(Exception e){
		System.out.println("exception caught");
		e.printStackTrace();
	    }
	}
    }




  //   public static void main(String[] args){
	
// 	VOTableGenerator g = new VOTableGenerator();
// 	try{
// 	DataSet ds = new DataSet();
// 	DataSetMetaData md =((DataSetMetaData)ds.getMetaData());
// 	md.setTableName("adfa");
// 	md.insertColumnName("col1");
// 	md.insertColumnName("col2");
// 	md.insertColumnName("col3");
// 	md.insertColumnTypeName("char");
// 	md.insertColumnTypeName("float");
// 	md.insertColumnTypeName("int");	
// 	ds.beforeFirst();
// 	ds.addRow();
// 	ds.beforeFirst();
// 	ds.next();
// 	ds.insertIntoRow("a");
// 	ds.insertIntoRow("12.2");
// 	ds.insertIntoRow("5");
// 	ds.addRow();
// 	ds.next();
// 	ds.insertIntoRow("b");
// 	ds.insertIntoRow("16.2");
// 	ds.insertIntoRow("6");
// 	ds.addRow();
// 	ds.next();
// 	ds.insertIntoRow("c");
// 	ds.insertIntoRow(".112");
// 	ds.insertIntoRow("8");
	
// 	g.genVOTab(ds, 1, 1, "a" );
// 	}

// 	catch(Exception e){
// 	    e.printStackTrace();
// 	}
//     }
    
    
}
