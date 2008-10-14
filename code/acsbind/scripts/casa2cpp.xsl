<?xml version="1.0"?>

<xsl:stylesheet version="1.0" 
          xmlns:aps="http://www.aoc.nrao.edu/~wyoung/psetTypes.html"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"     
         xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   
<xsl:param name="needscomma"></xsl:param>
<xsl:template match="/">
<xsl:apply-templates/>
</xsl:template>
<xsl:template match="aps:tool">  
<xsl:variable name="toolname">acs<xsl:value-of select="aps:name"/></xsl:variable>
<xsl:text disable-output-escaping="yes">
#include &lt;vltPort.h&gt;
#include &lt;maciACSComponentDefines.h&gt;
#include &lt;</xsl:text><xsl:value-of select="aps:name"/>Impl.h<xsl:text disable-output-escaping="yes">&gt;
#include &lt;corba.h&gt;
#include &lt;casaacsdefs.h&gt;
#include &lt;casa/Containers/Record.h&gt;
#include &lt;RDOPATH/RDO</xsl:text><xsl:value-of select="aps:name"/><xsl:text disable-output-escaping="yes">.h&gt;

NAMESPACE_USE(baci);
 </xsl:text>

acs<xsl:value-of select="aps:name"/>::acs<xsl:value-of select="aps:name"/><xsl:text disable-output-escaping="yes">(PortableServer::POA_ptr poa, const ACE_CString &amp;name) :
         ACSComponentImpl(poa, name)
{                           ACS_TRACE("::</xsl:text>acs<xsl:value-of select="aps:name"/>::acs<xsl:value-of select="aps:name"/>");
}<xsl:text>

</xsl:text>acs<xsl:value-of select="aps:name"/>::~acs<xsl:value-of select="aps:name"/><xsl:text disable-output-escaping="yes">(){
        ACS_TRACE("::</xsl:text>acs<xsl:value-of select="aps:name"/>::~acs<xsl:value-of select="aps:name"/>");
  <xsl:text>      ACS_DEBUG("::</xsl:text>acs<xsl:value-of select="aps:name"/>::~acs<xsl:value-of select="aps:name"/>", "dtor started");
 <xsl:text>       ACS_DEBUG("::</xsl:text>acs<xsl:value-of select="aps:name"/>::~acs<xsl:value-of select="aps:name"/>", <xsl:text>"dtor ended");
 }
 
 </xsl:text>
           <xsl:for-each select="aps:method">
           <xsl:if test="@type!='Constructor'">
<xsl:text>  </xsl:text><xsl:apply-templates select="aps:returns" mode="decl"/> <xsl:value-of select="$toolname"/>::<xsl:value-of select="aps:name"/>(<xsl:apply-templates select="aps:output" mode="oargs"></xsl:apply-templates> <xsl:if test="aps:output and aps:input">, </xsl:if>
              <xsl:apply-templates select="aps:input" mode="iargs">
              </xsl:apply-templates>)
              <xsl:text>               throw (CORBA::SystemException){ 
                                casa::Record rdoRec;
   </xsl:text>
              <xsl:apply-templates select="aps:output" mode="buildorec"></xsl:apply-templates>
              <xsl:apply-templates select="aps:input" mode="buildirec"></xsl:apply-templates>
              <xsl:apply-templates select="aps:returns" mode="return"><xsl:with-param name="method"><xsl:value-of select="aps:name"/></xsl:with-param></xsl:apply-templates>
               <xsl:text>
              }
</xsl:text></xsl:if>
            </xsl:for-each>
  <xsl:text>
  
  MACI_DLL_SUPPORT_FUNCTIONS(acs</xsl:text><xsl:value-of select="aps:name"/>)
  </xsl:template>
  
  <xsl:template match="aps:input" mode="iargs">  
  <xsl:call-template name="doargs">   
    <xsl:with-param name="ioflag"><xsl:text></xsl:text></xsl:with-param>
   <xsl:with-param name="constflag">const</xsl:with-param>
   </xsl:call-template>
   </xsl:template>
   
  <xsl:template match="aps:input" mode="buildirec">  
  <xsl:call-template name="buildrec">   
   </xsl:call-template>
   </xsl:template>
   
  <xsl:template match="aps:output" mode="buildorec">  
  <xsl:call-template name="buildrec">   
   </xsl:call-template>
   </xsl:template>
 
   <xsl:template match="aps:inout" mode="buildiorec">  
  <xsl:call-template name="buildrec">   
   </xsl:call-template>
   </xsl:template>
 
  <xsl:template match="aps:inout" mode="ioargs">  
  <xsl:call-template name="doargs"> 
  <xsl:with-param name="constflag"></xsl:with-param>
   <xsl:with-param name="ioflag"> <xsl:text disable-output-escaping="yes">_inout </xsl:text></xsl:with-param>
   </xsl:call-template>
   </xsl:template>
   
  <xsl:template match="aps:output" mode="oargs">  
  <xsl:call-template name="doargs">
  <xsl:with-param name="constflag"></xsl:with-param>
   <xsl:with-param name="ioflag"><xsl:text disable-output-escaping="yes">_out </xsl:text> </xsl:with-param>  
   </xsl:call-template>
   </xsl:template>
   
   <xsl:template name="buildrec">
   <xsl:for-each select="aps:param">
   <xsl:choose>
   <xsl:when test="@xsi:type='stringArray'"> <xsl:text disable-output-escaping="yes">                             rdoRec.define("</xsl:text><xsl:value-of select="aps:name"/>", <xsl:text disable-output-escaping="yes">casa_wrappers::fromCASAVec&lt;casa::String, CASA::StringVec&gt;(</xsl:text><xsl:value-of select="aps:name"/>));
   </xsl:when>
   <xsl:when test="@xsi:type='intArray'"><xsl:text disable-output-escaping="yes">                             rdoRec.define("</xsl:text><xsl:value-of select="aps:name"/>", <xsl:text disable-output-escaping="yes">casa_wrappers::fromCASAVec&lt;casa::Int, CASA::IntVec&gt;(</xsl:text><xsl:value-of select="aps:name"/>));
   </xsl:when>
   <xsl:when test="@xsi:type='boolArray'"><xsl:text disable-output-escaping="yes">                             rdoRec.define("</xsl:text><xsl:value-of select="aps:name"/>",<xsl:text disable-output-escaping="yes">casa_wrappers::fromCASAVec&lt;casa::Bool, CASA::BoolVec&gt;(</xsl:text> <xsl:value-of select="aps:name"/>));
   </xsl:when>
   <xsl:when test="@xsi:type='floatArray'"><xsl:text disable-output-escaping="yes">                             rdoRec.define("</xsl:text><xsl:value-of select="aps:name"/>", <xsl:text disable-output-escaping="yes">casa_wrappers::fromCASAVec&lt;casa::Float, CASA::FloatVec&gt;(</xsl:text><xsl:value-of select="aps:name"/>));
   </xsl:when>
   <xsl:when test="@xsi:type='doubleArray'"><xsl:text disable-output-escaping="yes">                             rdoRec.define("</xsl:text><xsl:value-of select="aps:name"/>", <xsl:text disable-output-escaping="yes">casa_wrappers::fromCASAVec&lt;casa::Double, DoubleVec&gt;(</xsl:text><xsl:value-of select="aps:name"/>));
   </xsl:when>
   <xsl:otherwise> <xsl:text>                             rdoRec.define("</xsl:text><xsl:value-of select="aps:name"/>", <xsl:value-of select="aps:name"/>);
   </xsl:otherwise>
   </xsl:choose>
   </xsl:for-each>
   </xsl:template>

<xsl:template name="doargs">
    <xsl:param name="ioflag"/>
    <xsl:param name="constflag"/>
     <xsl:for-each select="aps:param">
       <xsl:choose>
                 <xsl:when test="$constflag='const'">
                  <xsl:choose>
                 <xsl:when test="@xsi:type='string'">const char *<xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='int'">int <xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='bool'">bool <xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='float'">float <xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='double'">double <xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='stringArray'">const CASA::StringVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='intArray'">const CASA::IntVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='boolArray'">const CASA::BoolVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='floatArray'">const CASA::FloatVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='doubleArray'">const CASA::DoubleVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:otherwise>
                  const CASA::<xsl:value-of select='@xsi:type'/> <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if>
                 </xsl:otherwise>
                 </xsl:choose>
                 </xsl:when>
                 <xsl:otherwise>
                 <xsl:choose>
                 <xsl:when test="@xsi:type='string'">char *<xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='int'">int <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='bool'">bool <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='float'">float <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='double'">double> <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='stringArray'">CASA::StringVec<xsl:value-of select="$ioflag"/> <xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='intArray'">CASA::IntVec<xsl:value-of select="$ioflag"/>  <xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='boolArray'">CASA::BoolVect<xsl:value-of select="$ioflag"/>  <xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='floatArray'">CASA::FloatVec<xsl:value-of select="$ioflag"/>  <xsl:value-of select="aps:name"/>  <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='doubleArray'">CASA::DoubleVec<xsl:value-of select="$ioflag"/>  <xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:otherwise>
                  CASA::<xsl:value-of select='@xsi:type'/><xsl:value-of select="$ioflag" disable-output-escaping="yes"/><xsl:value-of select="aps:name"/> <xsl:if test="position()&lt;last()">, </xsl:if>
                 </xsl:otherwise>
                 </xsl:choose>
                 </xsl:otherwise>
            </xsl:choose>
     </xsl:for-each>   
</xsl:template>
     <xsl:template match="aps:returns" mode="decl">  
              <xsl:choose>
                <xsl:when test="@xsi:type='string'">string </xsl:when>
                 <xsl:when test="@xsi:type='int'">long </xsl:when>
                  <xsl:when test="@xsi:type='bool'">bool </xsl:when>
                 <xsl:when test="@xsi:type='float'">float </xsl:when>
                 <xsl:when test="@xsi:type='double'">double </xsl:when>
                 <xsl:when test="@xsi:type='stringArray'">StringVec </xsl:when>
                 <xsl:when test="@xsi:type='intArray'">IntVec </xsl:when>
                 <xsl:when test="@xsi:type='boolArray'">BoolVec </xsl:when>
                 <xsl:when test="@xsi:type='floatArray'">FloatVec </xsl:when>
                 <xsl:when test="@xsi:type='doubleArray'">DoubleVec </xsl:when>
                 <xsl:when test="@xsi:type='void'">void </xsl:when>
                  <xsl:when test="@xsi:type=''">void </xsl:when>
                 <xsl:otherwise>
                   <xsl:choose>
                    <xsl:when test="string-length(@xsi:type)=0">void </xsl:when>
                    <xsl:otherwise>
                                      <xsl:value-of select='@xsi:type'/>
                   </xsl:otherwise>
                    </xsl:choose>
                    </xsl:otherwise>
              </xsl:choose>

  
  </xsl:template>     
     
       <xsl:template match="aps:returns" mode="return"> 
       <xsl:param name="method"/>
       <xsl:choose>
              <xsl:when test="@xsi:type='bool'"><xsl:text>                             return myRdo.</xsl:text> <xsl:value-of select="$method"/>(rdoRec);</xsl:when>
              <xsl:otherwise>
              return mrRdo.asBlah("returns");
              </xsl:otherwise>
       </xsl:choose>
       </xsl:template>
 
  <!-- templates go here -->
</xsl:stylesheet>
