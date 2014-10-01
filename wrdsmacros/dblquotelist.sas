/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* DBLQUOTELIST - Usage and Notes ----------------------------------- */
/*                                                                    */
/* Summary   : Put each item in space-separated list in double quotes.*/
/*                                                                    */
/* Syntax    : %dblquotelist(list), where                             */
/*              LIST is a space separated list                        */
/*                                                                    */
/* Date      : October, 2011                                          */
/* Author    : M Keintz                                               */
/*                                                                    */
/* Examples  :                                                        */
/*   EX1:      %dblquotelist(bid ofr   vol) ==> "bid" "ofr" "vol"     */
/*                                                                    */
/*   EX2:      %let names=Sam Joe Ted;                                */
/*             %let wh=%dblquotelist(%upcase(&names));                */
/*                 ==>"SAM" "JOE" "TED"                               */
/*                                                                    */
/*   EX3:      %let names=Sam Joe Ted;                                */
/*             %let wh=%commaseplist(%dblquotelist(%upcase(&names))); */
/*                 ==>"SAM","JOE","TED"                               */
/*                                                                    */
/* Notes     : DBLQUOTELIST removes excess blanks (see EX1).          */
/*                                                                    */
/*             EX2 and EX3 show macro nesting.                        */
/* ------------------------------------------------------------------ */

%macro dblquotelist(list);
  %local list;     /* Space-separated list */
  %if %sysfunc(countw(&list,%str( )))>0 %then
  "%sysfunc(tranwrd(%sysfunc(compbl(&list)),%str( ),%str(%" %")))";
  %else %str( );
%mend;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
