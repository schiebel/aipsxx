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
         #!/usr/bin/env python
         #import sys
         #import types
         #import CASA

          <xsl:variable name="objname"><xsl:value-of select="aps:name"/></xsl:variable>
          class <xsl:value-of select="aps:name"/>  :
           <xsl:for-each select="aps:method">
           <xsl:text>        def  </xsl:text> <xsl:value-of select="aps:name"/>(self<xsl:if test="aps:output or aps:input">, </xsl:if><xsl:apply-templates select="aps:output"></xsl:apply-templates> <xsl:if test="aps:output and aps:input">, </xsl:if><xsl:apply-templates select="aps:input"><xsl:with-param name="defargs">yes</xsl:with-param></xsl:apply-templates>) :
           <xsl:choose>
           <xsl:when test="not(aps:returns) or aps:returns/@xsi:type='void' or aps:returns/@xsi:type=''">
           <xsl:text>            CASA.</xsl:text>acs<xsl:value-of select="$objname"/>.<xsl:value-of select="aps:name"/>(self <xsl:if test="aps:output or aps:input">, </xsl:if><xsl:apply-templates select="aps:output"></xsl:apply-templates> <xsl:if test="aps:output and aps:input">, </xsl:if>
           <xsl:apply-templates select="aps:input">
           <xsl:with-param name="defargs">no</xsl:with-param>
           </xsl:apply-templates>)
           <xsl:text>            return
           </xsl:text>
           </xsl:when>
           <xsl:otherwise>
           <xsl:text>            return CASA.</xsl:text>acs<xsl:value-of select="$objname"/>.<xsl:value-of select="aps:name"/>(self <xsl:if test="aps:output or aps:input">, </xsl:if><xsl:apply-templates select="aps:output"></xsl:apply-templates> <xsl:if test="aps:output and aps:input">, </xsl:if>
           <xsl:apply-templates select="aps:input">
           <xsl:with-param name="defargs">no</xsl:with-param>
           </xsl:apply-templates>)
           </xsl:otherwise>
           </xsl:choose>
            </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="aps:input">  
  <xsl:param name="defargs"></xsl:param>
  <xsl:call-template name="doargs">
  <xsl:with-param name="defargs"><xsl:value-of select="$defargs"/>
 </xsl:with-param>
   </xsl:call-template>
   </xsl:template>
 
  <xsl:template match="aps:inout">  
  <xsl:call-template name="doargs"/>
   </xsl:template>
   
  <xsl:template match="aps:output">  
  <xsl:call-template name="doargs" />
   </xsl:template>

<xsl:template name="doargs">
    <xsl:param name="defargs"></xsl:param>
     <xsl:for-each select="aps:param">
         <xsl:value-of select="aps:name"/><xsl:choose>
             <xsl:when test="aps:value and $defargs='yes'"><xsl:choose>
                  <xsl:when test="@xsi:type='string'">="<xsl:value-of select="aps:value"/>"<xsl:if test="position()&lt;last()">, </xsl:if></xsl:when>
                  <xsl:otherwise>=<xsl:value-of select="aps:value"/><xsl:if test="position()&lt;last()">, </xsl:if></xsl:otherwise>
            </xsl:choose>
            </xsl:when>
            <xsl:otherwise><xsl:if test="position()&lt;last()">, </xsl:if>
            </xsl:otherwise>
         </xsl:choose>
     </xsl:for-each>   
</xsl:template>
     
   
 
  <!-- templates go here -->
</xsl:stylesheet>
