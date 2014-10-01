/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* COMMASEPLIST - Usage and Notes ----------------------------------- */
/*                                                                    */
/* Summary   : Convert Space-separated list to comma-separated        */
/*                                                                    */
/* Syntax    : %commaseplist(list), where                             */
/*              LIST is a space separated list                        */
/*                                                                    */
/* Date      : October, 2011                                          */
/* Author    : M Keintz                                               */
/*                                                                    */
/* Examples  :                                                        */
/*   EX1:      %commaseplist(bid  ofr   vol) ==> bid,ofr,vol          */
/*                                                                    */
/*   EX2:      %let mylist=sal int dis;                               */
/*             %let slist=%commaseplist(&mylist) ==> sal,int,dis      */
/*                                                                    */
/*   EX3:      %let names="Sam" "Joe" "Ted";                          */
/*             %let wh=%commaseplist(%upcase(&names));                */
/*                 ==>"SAM","JOE","TED"                               */
/*                                                                    */
/*   EX4:      %let names=Sam Joe Ted;                                */
/*             %let wh=%commaseplist(%dblquotelist(%upcase(&names))); */
/*                 ==> "SAM","JOE","TED"                              */
/*                                                                    */
/* Notes     : COMMASEPLIST removes tranesous blanks (see EX1).       */
/* ------------------------------------------------------------------ */

%macro commaseplist(list);
  %local list;    /* Space-separated list */
  %sysfunc(tranwrd(%sysfunc(compbl(&list)),%str( ),%nrstr(,)))
%mend;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */

