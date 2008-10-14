import numarray as NUM

from _tConvert import *

t = tConvert();

print t.testbool (True);
print t.testbool (False);
print t.testint (-1);
print t.testint (10);
print t.testfloat (3.14);
print t.testfloat (12);
print t.teststring ("this is a string");

print t.testvecint ([1,2,3,4]);
print t.testveccomplex ([1+2j, -1-3j, -1.5+2.5j]);
print t.testvecstr (["a1","a2","b1","b2"])
print t.testipos ([2,3,4]);

print t.testvh (True);
print t.testvh (2);
print t.testvh (1.3);
print t.testvh (10-11j);
print t.testvh ("str");
print t.testvh ([True]);
print t.testvh ([2,4,6,8,10]);
print t.testvh ([1.3,4,5,6]);
print t.testvh ([10-11j,1+2j]);
print t.testvh (["str1","str2"]);
print t.testvh ({"shape":[2,2],"array":["str1","str2","str3","str4"]});
a  =  t.testvh ({"shape":[2,2],"array":["str1","str2","str3","str4"]});
print a;
print t.testvh (a);

a  =  t.testvh ([10-11j,1+2j]);
print a.shape;
print a.type();
print t.testvh (a);

b  =  NUM.array([[2,3],[4,5]]);
print b;
print t.testvh (b);
