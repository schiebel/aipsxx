<?xml version="1.0"?>

<xsl:stylesheet version="1.0" 
          xmlns:pdt="http://www.aoc.nrao.edu/~sharring/psetdefTypes.html"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"     
         xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   

         <xsl:template match="/">
  
         <xsl:apply-templates/>
        
         </xsl:template>
  <xsl:template match="pdt:parametersetdef">  
 <xsl:text disable-output-escaping="yes">
\documentclass[11pt]{article}
\usepackage{graphicx}
\usepackage{longtable}
\usepackage{amssymb}
\textwidth = 6.5 in
\textheight = 9 in
\oddsidemargin = 0.0 in
\evensidemargin = 0.0 in
\topmargin = 0.0 in
\headheight = 0.0 in
\headsep = 0.0 in
\parskip = 0.2in
\parindent = 0.0in
 \begin{document}
         \subsection{</xsl:text><xsl:value-of select="name"/><xsl:text> - Task}
         \flushleft\vspace{.20in}\textbf{Description}\newline
         </xsl:text>
             <xsl:value-of select="comment"/>
          <xsl:text>
 \flushleft\vspace{.20in}\textbf{Synopsis}\newline
         </xsl:text>
         <xsl:value-of select="name"/><xsl:text>  </xsl:text><xsl:for-each select="parameter">
         <xsl:choose>
         <xsl:when test="required='true'"><xsl:value-of select="name"/><xsl:text> </xsl:text> 
         </xsl:when>
         <xsl:otherwise>(<xsl:value-of select="name"/>)<xsl:text> </xsl:text> 
         </xsl:otherwise>
         </xsl:choose>
      
         </xsl:for-each>

          <xsl:text>
           \flushleft\vspace{.20in}\textbf {Arguments}\\   \hfill \\
           \begin{longtable}{|l p{0.25in}p{0.5in}p{2.65in}|} 
           \hline

           </xsl:text>
  
           <xsl:for-each select="parameter">
           <xsl:value-of select="name"/><xsl:text disable-output-escaping="yes"> &amp; in &amp; \multicolumn{2}{p{3.36in}|}{</xsl:text><xsl:value-of select="help"/><xsl:text disable-output-escaping="yes">}\\
           		&amp; &amp; Allowed: &amp; </xsl:text> <xsl:choose>
                 <xsl:when test="@xsi:type='psetdefTypes:StringParameterType'">string</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:IntegerParameterType'"> integer</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:BoolParameterType'"> bool</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:FloatParameterType'"> float</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:DoubleParameterType'"> double</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:StringArrayParameterType'"> string array</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:IntegerArrayParameterType'"> integer array</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:BoolArrayParameterType'"> bool array</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:FloatArrayParameterType'"> float array</xsl:when>
                 <xsl:when test="@xsi:type='psetdefTypes:DoubleArrayParameterType'"> double array</xsl:when>
                 <xsl:otherwise>
                 <xsl:value-of select='@xsi:type'/>
                 </xsl:otherwise>
              </xsl:choose><xsl:text>\\</xsl:text>

            <xsl:text disable-output-escaping="yes">
           		&amp; &amp; Required: &amp; </xsl:text> <xsl:value-of select="required"/><xsl:text disable-output-escaping="yes">\\
           		&amp; &amp; Default: &amp; </xsl:text> <xsl:value-of select="default"/><xsl:text>\\ \hline
           		
           </xsl:text>
           </xsl:for-each>
           \end{longtable}
            \end{document}
  </xsl:template>
  
</xsl:stylesheet>
