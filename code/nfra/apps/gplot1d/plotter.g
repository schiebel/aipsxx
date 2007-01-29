# plotter.g: convenience functions for glish client gplot1d
#
#   Copyright (C) 1995,1996,1997,1998,1999
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: plotter.g,v 19.0 2003/07/16 03:38:45 aips2adm Exp $
#
#-----------------------------------------------------------------------------

pragma include once
  
include "note.g"
include "printer.g"

const plotter:=function(async=F) 
  {

  public:=[=];

  self:=[=];
  self.async:=async;
  self.plotClient:=F;
  self.plotClient::Died:=T;
  self.lastreturn:=0;

# Private functions
#------------------------------------------------------------------------------
  const self.makeclient:=function(clientInit="gplot1d") {
    wider self;
    this:=client(clientInit);
    if(!is_agent(this)) {
      return throw('Failed to start ', clientInit);
    }
    whenever this->fail do this::Died:=T;
    whenever this->* do {
      self.lastreturn:=$value;
    }
    return this;
  }

# Public functions
#------------------------------------------------------------------------------
  const public.lastreturn:=function() {return self.lastreturn;};

  const public.initialize:=function() {
    if(is_boolean(self.plotClient)||self.plotClient::Died) {
      wider self;
      self.plotClient := self.makeclient();
      if(is_fail(self.plotClient)) fail;
    }
  }

  const public.gui:= ref public.initialize;

  const public.type := function() {
    return 'plotter';
  }

#------------------------------------------------------------------------------
  public.sleep := function (const seconds = 1)
    {  
      shell ("sleep", seconds); 
    }
#------------------------------------------------------------------------------
  public.id := function () {
    if(is_fail(public.initialize())) fail;
    self.plotClient->id ();
    if(self.async) return T;
    await self.plotClient->id_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.drawblockenter := function ()
    {
      if(is_fail(public.initialize())) fail;
      self.plotClient->drawBlockEnter();
      if(self.async) return T;
      await self.plotClient->drawBlockEnter_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.drawblockexit := function ()
    {
      if(is_fail(public.initialize())) fail;
      self.plotClient->drawBlockExit();
      if(self.async) return T;
      await self.plotClient->drawBlockExit_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.getx := function (dataset)
    {
      if(!is_integer(dataset)) fail 'dataset must be an integer';
      if(is_fail(public.initialize())) fail;
      self.plotClient->getX (dataset);
      if(self.async) return T;
      await self.plotClient->getX_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.gety := function (dataset)
    {
      if(!is_integer(dataset)) fail 'dataset must be an integer';
      if(is_fail(public.initialize())) fail;
      self.plotClient->getY (dataset);
      if(self.async) return T;
      await self.plotClient->getY_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.settopxaxis := function (onOffp)
    {
      if(is_fail(public.initialize())) fail;
      onOff := "off";
      if (is_numeric(onOffp))
	{ 
	  onOffB := as_boolean(onOffp);
	  if (onOffB) onOff := "on";
	}
      else if (is_string(onOffp))
	{
	  onOff := onOffp;
	}
      else
	fail 'onOffp must have a boolean meaning'
	  self.plotClient->setTopXAxis(onOff);
      if(self.async) return T;
      await self.plotClient->setTopXAxis_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setlefty2axis := function (onOffp)
    {
      if(is_fail(public.initialize())) fail;
    onOff := "off";
    if (is_numeric(onOffp))
      { 
	onOffB := as_boolean(onOffp);
	if (onOffB) onOff := "on";
      }
    else if (is_string(onOffp))
      {
	onOff := onOffp;
      }
    else
      fail 'onOffp must have a boolean meaning'
      self.plotClient->setLeftY2Axis(onOff);
      if(self.async) return T;
      await self.plotClient->setLeftY2Axis_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setrightyaxis := function (onOffp)
    {
      if(is_fail(public.initialize())) fail;
      onOff := "off";
      if (is_numeric(onOffp))
	{ 
	  onOffB := as_boolean(onOffp);
	  if (onOffB) onOff := "on";
	}
      else if (is_string(onOffp))
	{
	  onOff := onOffp;
	}
      else
	fail 'onOffp must have a boolean meaning';

      self.plotClient->setRightYAxis(onOff);
      if(self.async) return T;
      await self.plotClient->setRightYAxis_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setxaxislabel := function (newlabel)
    {
      if(is_fail(public.initialize())) fail;
      if(!is_string(newlabel)) fail 'label must be a string';
      self.plotClient->setXAxisLabel (newlabel);
      if(self.async) return T;
      await self.plotClient->setXAxisLabel_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setyaxislabel := function (newlabel)
    {
      if(!is_string(newlabel)) fail 'label must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setYAxisLabel (newlabel);
      if(self.async) return T;
      await self.plotClient->setYAxisLabel_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.sety2axislabel := function (newlabel)
    {
      if(!is_string(name)) fail 'label must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setY2AxisLabel (newlabel);
      if(self.async) return T;
      await self.plotClient->setY2AxisLabel_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setxaxisgrid := function (onOffp)
    {
      if(is_fail(public.initialize())) fail;
    onOff := "off";
    if (is_numeric(onOffp))
      { 
	onOffB := as_boolean(onOffp);
	if (onOffB) onOff := "on";
      }
    else if (is_string(onOffp))
      {
	onOff := onOffp;
      }
    else
      fail 'onOffp must have a boolean meaning'
      self.plotClient->setXAxisGrid(onOff);
      if(self.async) return T;
      await self.plotClient->setXAxisGrid_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setyaxisgrid := function (onOffp)
    {
      if(is_fail(public.initialize())) fail;
    onOff := "off";
    if (is_numeric(onOffp))
      { 
	onOffB := as_boolean(onOffp);
	if (onOffB) onOff := "on";
      }
    else if (is_string(onOffp))
      {
	onOff := onOffp;
      }
    else
      fail 'onOffp must have a boolean meaning'
      self.plotClient->setYAxisGrid(onOff);
      if(self.async) return T;
      await self.plotClient->setYAxisGrid_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.sety2axisgrid := function (onOffp)
    {
      if(is_fail(public.initialize())) fail;
    onOff := "off";
    if (is_numeric(onOffp))
      { 
	onOffB := as_boolean(onOffp);
	if (onOffB) onOff := "on";
      }
    else if (is_string(onOffp))
      {
	onOff := onOffp;
      }
    else
      fail 'onOffp must have a boolean meaning'
      self.plotClient->setY2AxisGrid(onOff);
      if(self.async) return T;
      await self.plotClient->setY2AxisGrid_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.swapy1y2 := function ()
    {
      if(is_fail(public.initialize())) fail;
      self.plotClient->swapY1Y2();
      if(self.async) return T;
      await self.plotClient->swapY1Y2_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setxaxiscolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setXAxisColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setXAxisColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setyaxiscolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setYAxisColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setYAxisColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.sety2axiscolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setY2AxisColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setY2AxisColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setxaxislabelcolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setXAxisLabelColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setXAxisLabelColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setyaxislabelcolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setYAxisLabelColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setYAxisLabelColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.sety2axislabelcolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setY2AxisLabelColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setY2AxisLabelColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setxaxisgridcolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setXAxisGridColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setXAxisGridColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setyaxisgridcolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setYAxisGridColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setYAxisGridColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.sety2axisgridcolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setY2AxisGridColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setY2AxisGridColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setplottitle := function (newlabel)
    {
      if(!is_string(newlabel)) fail 'title must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setPlotTitle (newlabel);
      if(self.async) return T;
      await self.plotClient->setPlotTitle_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setplottitlecolor := function(newcolor)
    {
      if(!is_string(color)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setPlotTitleColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setPlotTitleColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setcursorcolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setCursorColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setCursorColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setselectioncolor := function(newcolor)
    {
      if(!is_string(newcolor)) fail 'newcolor must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->setSelectionColor(newcolor);
      if(self.async) return T;
      await self.plotClient->setSelectionColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
#  public.setxaxisposition := function (strategy_, where_ = 0.0)
#    {
#      if(!is_numeric(where_)) fail 'position must be a number';
#      if(is_fail(public.initialize())) fail;
#      self.plotClient->setXAxis ([strategy=strategy_,where=where_]);
#      if(self.async) return T;
#      await self.plotClient->setXAxis_result;
#      return $value;
#    }
#------------------------------------------------------------------------------
#  public.setyaxisposition := function (strategy_, where_ = 0.0)
#    {
#      if(!is_numeric(where_)) fail 'position must be a number';
#      if(is_fail(public.initialize())) fail;
#      self.plotClient->setYAxis ([strategy=strategy_,where=where_]);
#      if(self.async) return T;
#      await self.plotClient->setYAxis_result;
#      return $value;
#    }
#------------------------------------------------------------------------------
#  public.sety2axisposition := function (strategy_, where_ = 0.0)
#    {
#      if(!is_numeric(where_)) fail 'position must be a number';
#      if(is_fail(public.initialize())) fail;
#      self.plotClient->setY2Axis ([strategy=strategy_,where=where_]);
#      if(self.async) return T;
#      await self.plotClient->setY2Axis_result;
#      return $value;
#    }
#------------------------------------------------------------------------------
  public.ploty := function (v_, name_="", style_ = "linespoints") {
    if(is_fail(public.initialize())) fail;
    if(!is_numeric(v_)) fail 'plot data must be a number';
    if(!is_string(name_)) fail 'name must be a string';

    rec := [data=v_, name=name_, style=style_];
    self.plotClient->vector (rec)
    if(self.async) return T;
    await self.plotClient->vector_result;
    return $value;
    
  }
#------------------------------------------------------------------------------
  public.plotxy := function (x_, y_, name_="", style_ = "linespoints") {
    if(is_fail(public.initialize())) fail;
    if(!is_numeric(x_)) fail 'plot x data must be a number';
    if(!is_numeric(y_)) fail 'plot y data must be a number';
    if(!is_string(name_)) fail 'name must be a string';
    
    rec := [x = x_, y = y_, name = name_, style = style_];
    self.plotClient->xy (rec)
    if(self.async) return T;
    await self.plotClient->xy_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.plotxy2 := function (x_, y_, name_="", style_ = "linespoints") {
    if(is_fail(public.initialize())) fail;
    if(!is_numeric(x_)) fail 'plot x data must be a number';
    if(!is_numeric(y_)) fail 'plot y data must be a number';
    if(!is_string(name_)) fail 'name must be a string';
    
    rec := [x = x_, y = y_, name = name_, style = style_, y2axis = T];
    self.plotClient->xy (rec)
	if(self.async) return T;
      await self.plotClient->xy_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.ploty2 := function (v_, name_="", style_ = "linespoints") {
    if(is_fail(public.initialize())) fail;
    if(!is_numeric(v_)) fail 'plot data must be a number';
    if(!is_string(name_)) fail 'name must be a string';
    
    rec := [data= v_, name = name_, style = style_, y2axis = T];
    self.plotClient->vector (rec)
	if(self.async) return T;
      await self.plotClient->vector_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.timey := function (x_, y_, name_="", style_ = "linespoints") {
    if(is_fail(public.initialize())) fail;
    if(!is_numeric(x_)) fail 'plot x data must be a number';
    if(!is_numeric(y_)) fail 'plot y data must be a number';
    if(!is_string(name_)) fail 'name must be a string';
    
    rec := [x = x_, y = y_, name = name_, style = style_];
    self.plotClient->timeY (rec)
	if(self.async) return T;
      await self.plotClient->timeY_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.timey2 := function (x_, y_, name_="", style_ = "linespoints") {
    if(is_fail(public.initialize())) fail;
    if(!is_numeric(x_)) fail 'plot x data must be a number';
    if(!is_numeric(y_)) fail 'plot y data must be a number';
    if(!is_string(name_)) fail 'name must be a string';
    
    rec := [x = x_, y = y_, name = name_, style = style_, y2axis = T];
    self.plotClient->timeY (rec)
	if(self.async) return T;
      await self.plotClient->timeY_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.skyy := function (x_, y_, name_="", style_ = "linespoints") {
    if(is_fail(public.initialize())) fail;
    if(!is_numeric(x_)) fail 'plot x data must be a number';
    if(!is_numeric(y_)) fail 'plot y data must be a number';
    if(!is_string(name_)) fail 'name must be a string';
    
    rec := [x = x_, y = y_, name = name_, style = style_];
    self.plotClient->skyY (rec)
	if(self.async) return T;
      await self.plotClient->skyY_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.skyy2 := function (x_, y_, name_="", style_ = "linespoints") {
    if(is_fail(public.initialize())) fail;
    if(!is_numeric(x_)) fail 'plot x data must be a number';
    if(!is_numeric(y_)) fail 'plot y data must be a number';
    if(!is_string(name_)) fail 'name must be a string';
    
    rec := [x = x_, y = y_, name = name_, style = style_, y2axis = T];
    self.plotClient->skyY (rec);
    if(self.async) return T;
    await self.plotClient->skyY_result;
    return $value;
  }
#------------------------------------------------------------------------------
#  public.appendxy := function (dataset , x_, y_) {
#      if(!is_integer(dataset)) fail 'dataset must be an integer';
#    if(!is_numeric(x_)) fail 'plot x data must be a number';
#    if(!is_numeric(y_)) fail 'plot y data must be a number';
#    if(is_fail(public.initialize())) fail;
#    
#    rec := [dataset = dataset, x = x_, y = y_];
#    self.plotClient->appendxy (rec);
#    if(self.async) return T;
#    await self.plotClient->appendxy_result;
#    return $value;
#  }
#------------------------------------------------------------------------------
  public.setxscale := function (min_, max_)
    {
      if(is_fail(public.initialize())) fail;
      if (!is_numeric(min_)) fail 'scale min must be a number';
      if (!is_numeric(max_)) fail 'scale max must be a number';
      rec := [min = min_, max = max_];
      self.plotClient->setXScale (rec);
      if(self.async) return T;
      await self.plotClient->setXScale_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setyscale := function (min_, max_)
    {
      if(is_fail(public.initialize())) fail;
      if (!is_numeric(min_)) fail 'scale min must be a number';
      if (!is_numeric(max_)) fail 'scale max must be a number';
      rec := [min = min_, max = max_];
      self.plotClient->setYScale (rec);
      if(self.async) return T;
      await self.plotClient->setYScale_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.sety2scale := function (min_, max_)
    {
      if(is_fail(public.initialize())) fail;
      if (!is_numeric(min_)) fail 'scale min must be a number';
      if (!is_numeric(max_)) fail 'scale max must be a number';
      rec := [min = min_, max = max_];
      self.plotClient->setY2Scale (rec);
      if(self.async) return T;
      await self.plotClient->setY2Scale_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.clear := function () {
    if(is_fail(public.initialize())) fail;
    
    self.plotClient->clear ()
	if(self.async) return T;
      await self.plotClient->clear_result;
    return T;
  }
#------------------------------------------------------------------------------
  public.cleardata := function () {
    if(is_fail(public.initialize())) fail;
    
    self.plotClient->clearData ()
	if(self.async) return T;
      await self.plotClient->clearData_result;
    return T;
  }
#------------------------------------------------------------------------------
  public.clearselections := function () {
    if(is_fail(public.initialize())) fail;
    
    self.plotClient->clearSelections ()
	if(self.async) return T;
      await self.plotClient->clearSelections_result;
    return T;
  }
#------------------------------------------------------------------------------
  public.showselections := function (onOffp) {
    if(is_fail(public.initialize())) fail;
    onOff := "off";
    if (is_numeric(onOffp))
      { 
	onOffB := as_boolean(onOffp);
	if (onOffB) onOff := "on";
      }
    else if (is_string(onOffp))
      {
	onOff := onOffp;
      }
    else
      fail 'onOffp must have a boolean meaning'

    self.plotClient->showSelections (onOff)
	if(self.async) return T;
      await self.plotClient->showSelections_result;
    return T;
  }
#------------------------------------------------------------------------------
  public.querydata := function () {
    if(is_fail(public.initialize())) fail;
    
    self.plotClient->queryData ()
	if(self.async) return T;
      await self.plotClient->queryData_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.deletedataset := function (dataSetNumber_) {
    if(is_fail(public.initialize())) fail;
      if(!is_integer(dataSetNumber_)) fail 'dataset must be an integer';
    
    self.plotClient->deleteDataSet (dataSetNumber_)
	if(self.async) return T;
      await self.plotClient->deleteDataSet_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.numberofselections := function () {
    if(is_fail(public.initialize())) fail;
    
    self.plotClient->numberOfSelectedRegions ()
	if(self.async) return T;
      await self.plotClient->numberOfSelectedRegions_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.getselection := function () {
    if(is_fail(public.initialize())) fail;
    
    self.plotClient->getSelection ()
	if(self.async) return T;
      await self.plotClient->getSelection_result;
    result :=  $value;
    if (is_record (result))
      return result;
    else
      return F;
  }
#------------------------------------------------------------------------------
  public.getselectionmask := function () {
    if(is_fail(public.initialize())) fail;
    
    self.plotClient->getSelectionMask ()
	if(self.async) return T;
      await self.plotClient->getSelectionMask_result;
    result :=  $value;
    if (is_record (result))
      return result;
    else
      return F;
  }
#------------------------------------------------------------------------------
  public.querystyles := function () {
    if(is_fail(public.initialize())) fail;
    
    self.plotClient->queryStyles ();
    if(self.async) return T;
    await self.plotClient->queryStyles_result;
    return $value;
  }
#------------------------------------------------------------------------------
  public.setlinecolor := function (dataset, newcolor)
    {
      if(!is_integer(dataset)) fail 'dataset must be an integer';
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      rec := [dataSet = dataset, color = newcolor];
      
      self.plotClient->setLineColor (rec);
      if(self.async) return T;
      await self.plotClient->setLineColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setlinestyle := function (dataset, newstyle)
    {
      if(!is_integer(dataset)) fail 'dataset must be an integer';
      if(!is_string(newstyle)) fail 'style must be a string';
      if(is_fail(public.initialize())) fail;
      rec := [dataSet = dataset, style = newstyle];
      
      self.plotClient->setLineStyle (rec);
      if(self.async) return T;
      await self.plotClient->setLineStyle_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setlinewidth := function (dataset, newwidth)
    {
      if(!is_integer(dataset)) fail 'dataset must be an integer';
      if(!is_numeric(newwidth)) fail 'width must be a number';
      if(is_fail(public.initialize())) fail;
      rec := [dataSet = dataset, width = newwidth];
      
      self.plotClient->setLineWidth (rec);
      if(self.async) return T;
      await self.plotClient->setLineWidth_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setpointcolor := function (dataset, newcolor)
    {
      if(!is_integer(dataset)) fail 'dataset must be an integer';
      if(!is_string(newcolor)) fail 'color must be a string';
      if(is_fail(public.initialize())) fail;
      rec := [dataSet = dataset, color = newcolor];
      
      self.plotClient->setPointColor (rec);
      if(self.async) return T;
      await self.plotClient->setPointColor_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setpointstyle := function (dataset, newstyle)
    {
      if(!is_integer(dataset)) fail 'dataset must be an integer';
      if(!is_string(newstyle)) fail 'style must be a string';
      if(is_fail(public.initialize())) fail;
      rec := [dataSet = dataset, style = newstyle];
      
      self.plotClient->setPointStyle (rec);
      if(self.async) return T;
      await self.plotClient->setPointStyle_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.setpointsize := function (dataset, newsize)
    {
      if(!is_integer(dataset)) fail 'dataset must be an integer';
      if(!is_numeric(newsize)) fail 'size must be a number';
      if(is_fail(public.initialize())) fail;
      rec := [dataSet = dataset, size = newsize];
      
      self.plotClient->setPointSize (rec);
      if(self.async) return T;
      await self.plotClient->setPointSize_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.marker := function (newmarkers)
    {
      if(!is_string(newmarkers)) fail 'markers must be a string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->showMarker (newmarkers);
      if(self.async) return T;
      await self.plotClient->showMarker_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.reversex := function ()
    {
      if(is_fail(public.initialize())) fail;
      self.plotClient->reverseXAxis ();
      if(self.async) return T;
      await self.plotClient->reverseXAxis_result
	return $value;
    }
#------------------------------------------------------------------------------
  public.reversey := function ()
    {
      if(is_fail(public.initialize())) fail;
      self.plotClient->reverseYAxis ();
      if(self.async) return T;
      await self.plotClient->reverseYAxis_result;
      return $value;
    }
#------------------------------------------------------------------------------
  public.reversey2 := function ()
    {
      if(is_fail(public.initialize())) fail;
      self.plotClient->reverseY2Axis ();
      if(self.async) return T;
      await self.plotClient->reverseY2Axis_result;
      return $value;
    }
#------------------------------------------------------------------------------
#  public.setlegendgeometry := function (newgeometry)
#    {
#      if(!is_string(newgeometry)) fail 'geometry must be an string';
#      if(is_fail(public.initialize())) fail;
#      self.plotClient->setLegendGeometry (newgeometry);
#      if(self.async) return T;
#      await self.plotClient->setLegendGeometry_result;
#      return $value;
#    }
#------------------------------------------------------------------------------
#  public.legendsoff := function()
#    {
#	if(is_fail(public.initialize())) fail;
#	public.setLegendGeometry ("hide");
#    }
#------------------------------------------------------------------------------
#  public.legendson := function()
#    {
#      if(is_fail(public.initialize())) fail;
#      public.setLegendGeometry ("show");
#    }
#------------------------------------------------------------------------------
  public.setprinter := function (printer)
    {
      if(is_fail(public.initialize())) fail;
      if (!is_string(printer)) fail 'printer name must be a string';
      command := paste("pri -P",printer,sep='');
      print paste("printCommand set to '",command,"'.",sep='');
      print "setprinter() deprecated - use setprintcommand()\n";
      self.plotClient->setPrintCommand (command);
      if(self.async) return T;
      await self.plotClient->setPrinterCommand_result;
      return $value;
      
    }
#------------------------------------------------------------------------------
   public.setprintcommand := function(newcmd)
     {
       if(!is_string(newcmd)) fail 'command must be a string';
       if(is_fail(public.initialize())) fail;
       self.plotClient->setPrintCommand(newcmd);
       if(self.async) return T;
       await self.plotClient->setPrintCommand_result;
       return $value;
     }
#------------------------------------------------------------------------------
  public.psprint := function (gui=T)
    {
      if(is_fail(public.initialize())) fail;
      filename := paste('/tmp/aips_plotter_print.',system.pid,'.ps',sep='');
      self.plotClient->printToFile (filename);
      await self.plotClient->printToFile_result;
      if (gui) {                    
        printer().gui(filename,T,T);
      } else {                      
        printer().print(filename,T);
      }                             
      return T
    }
#------------------------------------------------------------------------------
  public.psprinttofile := function (filename)
    {
      if(!is_string(filename)) fail 'file must be an string';
      if(is_fail(public.initialize())) fail;
      self.plotClient->printToFile (filename);
      if(self.async) return T;
      await self.plotClient->printToFile_result;
      return $value;      
    }

  public.summary := function () {
    return public.querydata();
  }
#------------------------------------------------------------------------------

  const public.drawBlockEnter:=public.drawblockenter;
  const public.drawBlockExit:=public.drawblockexit;
  const public.getX:=public.getx;
  const public.getY:=public.gety;
  const public.setTopXAxis:=public.settopxaxis;
  const public.setLeftY2Axis:=public.setlefty2axis;
  const public.setRightYAxis:=public.setrightyaxis;
  const public.setXAxisLabel:=public.setxaxislabel;
  const public.setYAxisLabel:=public.setyaxislabel;
  const public.setY2AxisLabel:=public.sety2axislabel;
  const public.setXAxisGrid:=public.setxaxisgrid;
  const public.setYAxisGrid:=public.setyaxisgrid;
  const public.setY2AxisGrid:=public.sety2axisgrid;
  const public.swapY1Y2:=public.swapy1y2;
  const public.setXAxisColor:=public.setxaxiscolor;
  const public.setYAxisColor:=public.setyaxiscolor;
  const public.setY2AxisColor:=public.sety2axiscolor;
  const public.setXAxisLabelColor:=public.setxaxislabelcolor;
  const public.setYAxisLabelColor:=public.setyaxislabelcolor;
  const public.setY2AxisLabelColor:=public.sety2axislabelcolor;
  const public.setXAxisGridColor:=public.setxaxisgridcolor;
  const public.setYAxisGridColor:=public.setyaxisgridcolor;
  const public.setY2AxisGridColor:=public.sety2axisgridcolor;
  const public.setPlotTitle:=public.setplottitle;
  const public.setPlotTitleColor:=public.setplottitlecolor;
  const public.setCursorColor:=public.setcursorcolor;
  const public.setSelectionColor:=public.setselectioncolor;
#  const public.setXAxisPosition:=public.setxaxisposition;
#  const public.setYAxisPosition:=public.setyaxisposition;
#  const public.setY2AxisPosition:=public.sety2axisposition;
  const public.timeY:=public.timey;
  const public.timeY2:=public.timey2;
  const public.skyY:=public.skyy;
  const public.skyY2:=public.skyy2;
  const public.setXScale:=public.setxscale;
  const public.setYScale:=public.setyscale;
  const public.setY2Scale:=public.sety2scale;
  const public.clearData:=public.cleardata;
  const public.clearSelections:=public.clearselections;
  const public.showSelections:=public.showselections;
  const public.queryData:=public.querydata;
  const public.deleteDataSet:=public.deletedataset;
  const public.numberOfSelections:=public.numberofselections;
  const public.getSelection:=public.getselection;
  const public.getSelectionMask:=public.getselectionmask;
  const public.queryStyles:=public.querystyles;
  const public.setLineColor:=public.setlinecolor;
  const public.setLineStyle:=public.setlinestyle;
  const public.setLineWidth:=public.setlinewidth;
  const public.setPointColor:=public.setpointcolor;
  const public.setPointStyle:=public.setpointstyle;
  const public.setPointSize:=public.setpointsize;
  const public.reverseX:=public.reversex;
  const public.reverseY:=public.reversey;
  const public.reverseY2:=public.reversey2;
#  const public.setLegendGeometry:=public.setlegendgeometry;
#  const public.legendsOff:=public.legendsoff;
#  const public.legendsOn:=public.legendson;

# setPrinter, setPrintCommand deprecated
#  const public.setPrintCommand:=public.setprintcommand;
#  const public.setPrinter:=public.setprinter;

  const public.psPrint:=public.psprint;
  const public.psPrintToFile:=public.psprinttofile;
#  if(is_fail(public.initialize())) fail;

  return public;

}

const defaultplotter:=plotter();
const dp:=ref defaultplotter;

const plottertest:=function() {
  if(!have_gui()) fail "No gui for plotter test";
  if(is_fail(dp.clear())) fail;
  if(is_fail(dp.plotxy(1:360,sin(pi*(1:360)/180)))) fail;
  if(is_fail(dp.setplottitle('Sin wave'))) fail;
  if(is_fail(dp.setxaxislabel('Phase'))) fail;
  if(is_fail(dp.setyaxislabel('Sin'))) fail;
  return T;
}

note('defaultplotter (dp) ready');
