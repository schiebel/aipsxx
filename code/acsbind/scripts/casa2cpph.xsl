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
#ifndef _ACS<xsl:value-of select="aps:name"/>_H_
#define _ACS<xsl:value-of select="aps:name"/>_H_
<xsl:text disable-output-escaping="yes">
#include &lt;</xsl:text><xsl:value-of select="aps:name"/>S.h<xsl:text disable-output-escaping="yes">&gt;
#include &lt;corba.h&gt;
NAMESPACE_USE(baci);
NAMESPACE_USE(acscomponent);
#include&lt;RDOPATH/RDO</xsl:text><xsl:value-of select="aps:name"/><xsl:text disable-output-escaping="yes">.h&gt;
</xsl:text>
class acs<xsl:value-of select="aps:name"/> : public ACSComponentImpl,
                                          public virtual POA_CASA::acs<xsl:value-of select="aps:name"/> {
    public :
                       acs<xsl:value-of select="aps:name"/><xsl:text disable-output-escaping="yes">(PortableServer::POA_ptr poa, const ACE_CString &amp;name);
                       </xsl:text>acs<xsl:value-of select="aps:name"/><xsl:text disable-output-escaping="yes">(PortableServer::POA_ptr poa, const ACE_CString &amp;name, bool baseClass);
           </xsl:text>
           <xsl:text>virtual ~acs</xsl:text><xsl:value-of select="aps:name"/>();
           <xsl:for-each select="aps:method">
           <xsl:if test="@type!='Constructor'">
              <xsl:text>         </xsl:text><xsl:apply-templates select="aps:returns"/> <xsl:value-of select="aps:name"/>(<xsl:apply-templates select="aps:output"></xsl:apply-templates> <xsl:if test="aps:output and aps:input">, </xsl:if>
              <xsl:apply-templates select="aps:input">
              </xsl:apply-templates>)
              <xsl:text>               throw (CORBA::SystemException);
              </xsl:text></xsl:if>
            </xsl:for-each>
            private :
                 casa::RDO<xsl:value-of select="aps:name"/> myRdo;
}; 
#endif
  </xsl:template>
  
  <xsl:template match="aps:input">  
  <xsl:call-template name="doargs">   
    <xsl:with-param name="ioflag"></xsl:with-param>
   <xsl:with-param name="constflag">const</xsl:with-param>
   </xsl:call-template>
   </xsl:template>
 
  <xsl:template match="aps:inout">  
  <xsl:call-template name="doargs"> 
  <xsl:with-param name="constflag"></xsl:with-param>
   <xsl:with-param name="ioflag"><xsl:text disable-output-escaping="yes">_inout</xsl:text>
   </xsl:with-param>
   </xsl:call-template>
   </xsl:template>
   
  <xsl:template match="aps:output">  
  <xsl:call-template name="doargs">
  <xsl:with-param name="constflag"></xsl:with-param>
   <xsl:with-param name="ioflag"><xsl:text disable-output-escaping="yes">_out</xsl:text> </xsl:with-param>  
   </xsl:call-template>
   </xsl:template>

<xsl:template name="doargs">
    <xsl:param name="ioflag"/>
    <xsl:param name="constflag"/>
     <xsl:for-each select="aps:param">
              <xsl:choose>
                 <xsl:when test="$constflag='const'">
                 <xsl:choose>
                 <xsl:when test="@xsi:type='string'">const char * <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='int'">int <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='bool'">bool <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='float'">float <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='double'">double <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='stringArray'">const CASA::StringVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='intArray'">const CASA::IntVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='boolArray'">const CASA::BoolVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='floatArray'">const CASA::FloatVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='doubleArray'">const CASA::DoubleVec <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:otherwise>
                  const CASA::<xsl:value-of select='@xsi:type'/><xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if>
                 </xsl:otherwise></xsl:choose>
                 </xsl:when>
                 <xsl:otherwise>
                 <xsl:choose>
                 <xsl:when test="@xsi:type='string'">char *<xsl:value-of select="$ioflag" disable-output-escaping="yes"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='int'">int <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='bool'">bool <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='float'">float <xsl:text disable-output-escaping="yes">&amp;</xsl:text><xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='double'">double<xsl:text disable-output-escaping="yes">&amp;</xsl:text> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='stringArray'">CASA::StringVec<xsl:value-of select="$ioflag" disable-output-escaping="yes"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='intArray'">CASA::IntVec<xsl:value-of select="$ioflag" disable-output-escaping="yes"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='boolArray'">CASA::BoolVec<xsl:value-of select="$ioflag" disable-output-escaping="yes"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='floatArray'">CASA::FloatVec<xsl:value-of select="$ioflag" disable-output-escaping="yes"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='doubleArray'">CASA::DoubleVec<xsl:value-of select="$ioflag" disable-output-escaping="yes"/> <xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:otherwise>
                 CASA::<xsl:value-of select='@xsi:type'/><xsl:value-of select="$ioflag" disable-output-escaping="yes"/><xsl:if test="position()&lt;last()">, </xsl:if>
                 </xsl:otherwise>
                 </xsl:choose>                 
                 </xsl:otherwise>
              </xsl:choose>
     </xsl:for-each>   
</xsl:template>
     <xsl:template match="aps:returns">  
              <xsl:choose>
                <xsl:when test="@xsi:type='string'">string </xsl:when>
                 <xsl:when test="@xsi:type='int'">long </xsl:when>
                  <xsl:when test="@xsi:type='bool'">bool </xsl:when>
                 <xsl:when test="@xsi:type='float'">float </xsl:when>
                 <xsl:when test="@xsi:type='double'">double </xsl:when>
                 <xsl:when test="@xsi:type='stringArray'">stringVec </xsl:when>
                 <xsl:when test="@xsi:type='intArray'">intVec </xsl:when>
                 <xsl:when test="@xsi:type='boolArray'">boolVec </xsl:when>
                 <xsl:when test="@xsi:type='floatArray'">floatVec </xsl:when>
                 <xsl:when test="@xsi:type='doubleArray'">doubleVec </xsl:when>
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
     
   
 
  <!-- templates go here -->
</xsl:stylesheet>
