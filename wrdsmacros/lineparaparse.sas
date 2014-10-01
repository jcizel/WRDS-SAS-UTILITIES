/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: LINEPARAPARSE                                                         */
/* Summary   : WRDS-SEC Paragraph Parser, Around a Predefined Line Number            */
/* Date      : August, 2010                                                          */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - FNAME_FULL: Full Index of Target Filing Name                        */
/*             - LINE: Line of Match                                                 */
/*             - NLINE: # of Lines before and after the Match to be Extracted        */
/* ********************************************************************************* */

%MACRO LINEPARAPARSE(INSET=,OUTSET=,FNAME_FULL=,LINE=,NLINE=);
/* Width of Character Variable */
%let LN = %eval(100*&NLINE);
/* Start Parsing Into Paragraph */
data &OUTSET;
set &INSET;
_LINE1 = &LINE - &NLINE. ;
format PARAGRAPH $&ln.. ;
retain PARAGRAPH "";
infile datfiles filevar=&FNAME_FULL LINE=_LINEVAR end=LASTLINE;
 DO UNTIL(lastline);
  input;
  if _LINEVAR>=_LINE1 then
  do;
    _infile_ = htmldecode(_infile_);
    call rxchange(" $<5> to '' ",99,_INFILE_);
    _infile_ =compbl(compress(_infile_,' -.,()$%','NK'));
    PARAGRAPH = substrn(CATX(" ",PARAGRAPH,_INFILE_),max(lengthn(CATX(" ",PARAGRAPH,_INFILE_))-&ln.+1,1));
    if lastline=1 or _LINEVAR=&LINE.+&NLINE. then do; output; lastline=1; paragraph=""; end;
  end;
 END;
PARAGRAPH="";
label PARAGRAPH= "Match Paragraph &nLine. Lines Before and After '&tstr.' String";
drop _LINE1;
run;
%MEND LINEPARAPARSE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
