import java.awt.*;
import java.awt.image.*;

public class GraphCanvas extends Canvas{
    
    private Image im;
    
    public GraphCanvas(DataSet ds,int xc, int[] xind,int yc, int[] yind, int start, int end){
	super();
	try{
        int w = 500;
        int h = 500;
        int pix[] = new int[w * h];
        int index = 0;
        for (int y = 0; y < h; y++) {
            int red = (y * 255) / (h - 1);
            for (int x = 0; x < w; x++) {
                int blue = (x * 255) / (w - 1);
                pix[index++] = (255 << 24) | (red << 16) | blue;
            }
        }

  // 	for(int i=0;i<h/5*w;i++){
//   	    pix[i]=( << 16) | blue;

//   	}
        im = createImage(new MemoryImageSource(w, h, pix, 0, w));
 
	
	
// 	if(1>start||start>ds.getTotalRows())
// 	    ds.beforeFirst();
// 	else
// 	    ds.absolute(start-1);
	
// 	int curr = start-1;
// 	Number x=null;
// 	Number y=null;
// 	while(ds.next()){
// 	    curr++;
	    

// 	    if(curr==end)
// 		break;
		
// 	}


	

	}
	catch(Exception e){
	    e.printStackTrace();
	}

    }

    public void paint(Graphics g){
	g.drawImage(im, 0, 0, this);

    }

}
