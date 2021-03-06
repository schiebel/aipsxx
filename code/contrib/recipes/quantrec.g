#
#RECIPE: Dimensional analysis in the quanta tool
#
#CATEGORY: General
#
#GOALS: Calculate antenna gain, carrying units throughout
#
#USING: quanta tool
#
#RESULTS: listing of data and units, with conversions
#
#ASSUME: 
#
#SYNOPSIS:
# The quanta tool enables the expression and manipulation of values
# and units.  This script demonstrates how this tool can be used
# for dimensional analsysis.
#

#SCRIPTNAME: quantrec.g

#SCRIPT:

include 'quanta.g';                      # initialize quanta tool

d:=25;                                   # the diameter of typical telescope

print 'A= ',A:=dq.quantity(v=pi*(d^2)/4, # make a quantity containing the
                           name='m2');   #  collection area w/ units sq. m
                                        

eff:=0.60;                               # the aperture efficiency

print 'k= ',k:=dq.constants(v='k');      # Retrieve Boltzmann's constant


num:=dq.mul(v=eff,                       # form product for numerator
            a=A);
dem:=dq.mul(v=2,                         # form product for denominator
            a=k);

g:=dq.div(v=num,                         # Calculate gain... 
          a=dem);

print 'Gain= ',dq.getvalue(v=g),         # ...and report it (in natural units)
               dq.getunit(v=g);

g:=dq.convert(g,'K/Jy');                 # Convert gain to familiar units
print 'Gain= ',dq.getvalue(v=g),
               dq.getunit(v=g);

Tant:='3K';                              # A hypothetical antenna temp as
                                         #  quantity-as-string

S:=dq.div(v=Tant,                        # Calculate flux density
          a=g);


S:=dq.convert(S,'Jy');                   # Express in Jy and report
print 'Flux Density= ',dq.getvalue(v=S),
                       dq.getunit(v=S);

                                         # Express in canonical units
print 'Flux Density= ',dq.canonical(v=S);


#OUTPUT:
# A= [value=490.873852, unit=m2]
# k= [value=1.3806578e-23, unit=J/K]
# Gain=  1.06660865e+25 m2/(J/K)
# Gain=  0.106660865 K/Jy
# Flux Density=  28.1265297 Jy
# Flux Density=  [value=2.81265297e-25, unit=kg.s-2]

#SUBMITTER: George Moellenbrock
#SUBMITAFFL: NRAO-Socorro
#SUBMITDATE: 2002-Jan-28

