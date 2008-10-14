#------------------- polylsq.g ----------------------------
#
# Glish script to demonstrate using matrix object to do
# least squares fitting to a polynomial with error analysis
#
#tablefromascii('begtable','begdata.txt','begdatahdr')
xydata := table('begtable')
xydata.getkeywords()                        # Print out needed keywords
x := xydata.getcol('XDATA')
y := xydata.getcol('YDATA')
N := length(y)
ydata := array(y,N,1)                       # Need array not vector for matrix input
A := array(0,N,3)
A[,1] := 1
for (i in 1:N) for (j in 2:3) A[i,j] := x[i]^(j-1)
mx := matrix_functions()
Atran := mx.transpose(A)
G := mx.mult(Atran,A)
Ginv := mx.invert(G)
Coef := mx.mult(Ginv,mx.mult(Atran,ydata))  # Solve for polynomial coefficients
ysoln := mx.mult(A,Coef)                    # Polynomial fit to y(x)
errsq := N*mx.mean((ydata - ysoln)^2)/(N-1)
Cov := errsq*Ginv                           # Covariance matrix
rms := errsq^0.5
for (j in 1:3) sigma[j] := Cov[j,j]^0.5     # Errors for polynomial coefficients
r := Cov                                    # Compute r = Correlation Matrix
for (j in 1:3) for (k in 1:3) r[j,k] := Cov[j,k]/(Cov[j,j]*Cov[k,k])^0.5
pl := pgplotter(background="white")         # Set up plot to plot data and fit
red := 2
blue := 4
pl.sci(blue)
pl.env(min(x),max(x),min(y),max(y),0,1)
pl.lab("x","y","Plot Data (Red) and 2nd Order Polynomial Fit to Data (Blue)")
pl.line(x,ysoln)
pl.sci(red)
pl.pt(x,ydata,4)

