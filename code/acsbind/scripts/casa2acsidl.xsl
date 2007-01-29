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
         #ifndef _<xsl:value-of select="aps:name"/>_IDL_
         #define _<xsl:value-of select="aps:name"/>_IDL_
         <xsl:text disable-output-escaping="yes">
         #include &lt;baci.idl&gt;
         #include &lt;acscomponent.idl&gt;
         #include &lt;casadefs.idl&gt;
         
         </xsl:text>
         module CASA {
              interface acs<xsl:value-of select="aps:name"/>  : ACS::ACSComponent {
           <xsl:for-each select="aps:method">
              <xsl:text>         </xsl:text><xsl:apply-templates select="aps:returns"/> <xsl:value-of select="aps:name"/>(<xsl:apply-templates select="aps:output"></xsl:apply-templates> <xsl:if test="aps:output and aps:input">, </xsl:if>
              <xsl:apply-templates select="aps:input">
              </xsl:apply-templates>);
            </xsl:for-each>
                  }; 
            };
            #endif
  </xsl:template>
  
  <xsl:template match="aps:input">  
  <xsl:call-template name="doargs">
   <xsl:with-param name="ioflag">in</xsl:with-param>
   </xsl:call-template>
   </xsl:template>
 
  <xsl:template match="aps:inout">  
  <xsl:call-template name="doargs">
   <xsl:with-param name="ioflag">inout</xsl:with-param>
   </xsl:call-template>
   </xsl:template>
   
  <xsl:template match="aps:output">  
  <xsl:call-template name="doargs">
   <xsl:with-param name="ioflag">out</xsl:with-param>  
   </xsl:call-template>
   </xsl:template>

<xsl:template name="doargs">
    <xsl:param name="ioflag"/>
     <xsl:for-each select="aps:param">
              <xsl:choose>
                 <xsl:when test="@xsi:type='string'"><xsl:value-of select="$ioflag"/> string<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='int'"><xsl:value-of select="$ioflag"/> long<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='bool'"><xsl:value-of select="$ioflag"/> bool<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='float'"><xsl:value-of select="$ioflag"/> float<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='double'"><xsl:value-of select="$ioflag"/> double<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='stringArray'"><xsl:value-of select="$ioflag"/> stringVec<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='intArray'"><xsl:value-of select="$ioflag"/> intVec<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='boolArray'"><xsl:value-of select="$ioflag"/> boolVec<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='floatArray'"><xsl:value-of select="$ioflag"/> floatVec<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:when test="@xsi:type='doubleArray'"><xsl:value-of select="$ioflag"/> doubleVec<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                 <xsl:otherwise>
                 <xsl:value-of select="$ioflag"/> <xsl:value-of select='@xsi:type'/><xsl:if test="position()&lt;last()">, </xsl:if>
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
