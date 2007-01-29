#include <casa/aips.h>
#include <casa/iostream.h>

#include <display/Display/XTkPixelCanvas.h>
#include <display/Display/PanelDisplay.h>
#include <images/Images/PagedImage.h>
#include <display/DisplayDatas/LatticeAsRaster.h>
#include <display/DisplayEvents/MWCRTZoomer.h>
#include <display/Display/WorldCanvas.h>
#include <casa/Inputs/Input.h>

#include <display/Display/StandAloneDisplayApp.h>
		// configures pgplot for stand-alone DL apps.

#include <casa/namespace.h>

int setZIndex(ClientData pd, Tcl_Interp* tcl, Int argc, Char* argv[]) {
  Long zIndex = 0l;
  if(Tcl_ExprLong(tcl, argv[1], &zIndex)==TCL_OK) {
    Int zindex = zIndex;
    AttributeBuffer zInd, zIncr;
    zInd.set("zIndex", zindex); zIncr.set("zIndex", 1);
    ((PanelDisplay*)pd)->setLinearRestrictions(zInd, zIncr);  }
  return TCL_OK;  }
  

class XTkPDMotEH : public WCMotionEH {
 public:
  XTkPDMotEH(Tcl_Interp* tcl, DisplayData* dd) : tcl_(tcl), dd_(dd) {  };
  virtual ~XTkPDMotEH() {  };
  virtual void operator()(const WCMotionEvent &ev);
 private:
  Tcl_Interp* tcl_;
  DisplayData* dd_;  };

  
  
void XTkPDMotEH::operator()(const WCMotionEvent &ev) {

  String TrkMsg ="\n\n";
  
  if(ev.worldCanvas()->inDrawArea(ev.pixX(),ev.pixY())) {
	// Don't track motion off draw area (must explicitly test this now).
  
    dd_->conformsTo(ev.worldCanvas());
	// 'focus' DD on WC[H] of interest (including its zIndex).

    TrkMsg = dd_->showValue(ev.world()) + "\n" +
             dd_->showPosition(ev.world());  }

  XTkPixelCanvas::evalTcl(tcl_, ".m configure -text {"+TrkMsg+"}");  }
 
 
	  
int main(int argc, char** argv) {

  Input inputs(1);
  inputs.version("");
  inputs.create("in", "/users/dking/a2d/6503.im", "Input file name");
  inputs.readArguments(argc, argv);
  String infile = inputs.getString("in");

  Tcl_Interp *tcl = Tcl_CreateInterp();
  Tcl_Init(tcl);
  Tk_Init(tcl);
    
  TkPixelCanvas::init(tcl);		//  TclTkPixelCanvas_Init(tcl);
    
  Vector<Int> minclrs(1,8), maxclrs(1,80); 
  XTkPixelCanvas* xtpc = new XTkPixelCanvas(tcl, ".p", minclrs, maxclrs);
  
  PanelDisplay* pd = new PanelDisplay(xtpc);
  
  ImageInterface<Float>* im = new PagedImage<Float>
				  (infile, TableLock::UserNoReadLocking);
  
  IPosition pos(im->ndim(), 0);
  LatticeAsRaster<Float>* dd = new LatticeAsRaster<Float>(im, 0,1,2, pos);
    
  Colormap *cmap = new Colormap(String("Hot Metal 2"));
  dd->setColormap(cmap, 1.0);
    
  pd->addTool("zoomer", new MWCRTZoomer(Display::K_Pointer_Button1));
  
  Record rec, recOut;
  rec.define("labelcharsize", 1.1);
  //rec.define("axislabelswitch", True);
  dd->setOptions(rec, recOut);

  XTkPDMotEH* meh = new XTkPDMotEH(tcl, dd);
  dd->addMotionEventHandler(meh);
  
  
  pd->addDisplayData(*dd);
  
  im->unlock();		// Needed (for unknown reasons) to avoid
			// blocking other users of the image file....

  Tcl_CreateCommand( tcl, "setzindex", setZIndex, (ClientData)pd,
  		     (Tcl_CmdDeleteProc*)NULL );
     
//Tcl_Eval(tcl, "scale .s -orient horizontal -command {.l config -text}");
  Tcl_Eval(tcl, "scale .s -orient horizontal -command setzindex");
  Tcl_Eval(tcl, "message .m -relief sunken -text {\n\n}"
		" -aspect 100000 -anchor nw");
  Tcl_Eval(tcl, "pack .s");
  Tcl_Eval(tcl, "pack .m -fill both");
  Tcl_Eval(tcl, "wm geometry . =600x500");

   
  while (Tk_GetNumMainWindows() > 0) Tcl_DoOneEvent(0);  }
  
  
  
