# floatcheck.g: Routine for checking for floating point descrepancies
# Copyright (C) 2001,2002,2003
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: floatcheck.g,v 19.2 2004/08/25 02:44:53 cvsmgr Exp $

# include guard
pragma include once
 
# 
# function floatcheck compares two test results differences files and 
# determines if there are only floating point differences.  If so it then
# calculates an RMS difference for the floating point numbers, otherwise
# if fails the verification
#

floatcheck := function(fileOne, fileTwo)
{
   EOF:=F;
   rstat := 0;
   sumSquares := 0;
   count := 0;
      # open files
   f1 := open(paste("< ", fileOne));
   f2 := open(paste("< ", fileTwo));
   while(!EOF){
         # read till no more input
      line1 := read(f1);
      line2 := read(f2);
      if(line1 == '' || line2 ==''){
        EOF := T;
      } else {
        if(line1 != line2){
              # lines are different now check field by field
              # numbers can be put as a vector, so replace square brackets
              # and commas by blanks.
	   line1 := line1 ~ s/[][,]/ /g;
	   line2 := line2 ~ s/[][,]/ /g;
           fields1 := split(line1);
           fields2 := split(line2);
           if(len(fields1) == len(fields2)){
             for(i in 1:len(fields1)){
                if(fields1[i] != fields2[i]){
                      # Check to see if it's a (floating point) number
		   if( fields1[i] ~ m/^[+-]?\.?\d+(e[+-]?\d+)?$/  ||
		       fields1[i] ~ m/^[+-]?\d+\.\d*(e[+-]?\d+)?$/ ) {
                     a := as_double(fields1[i]);
                     b := as_double(fields2[i]);
                        # Yup it's a number sum it up, taking care to avoid a=0
		        # Ignore numbers very close to zero.
                     if (abs(a) > 1e-10  &&  abs(b) > 1e-10) {
                       if(a != 0.0){
                         sumSquares +:= (a-b)*(a-b)/(a*a);
                         count +:= 1;
		       } else if (b != 0.0) {
                         sumSquares +:= (a-b)*(a-b)/(b*b);
                         count +:= 1;
		       }
                     }
                   } else {
                     rstat := -1;
                     EOF := T;
                     break;
                   }
                }
             }
           } else {
              rstat := -1;
              EOF := T;
           } 
        }
      }
   }
   if(rstat != -1){
      if(count > 1){
         rstat := sqrt(sumSquares/(count*(count-1)));
      } else {
         rstat := sqrt(sumSquares);
      }
   }
   return rstat;
}
