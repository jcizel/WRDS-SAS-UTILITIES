/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* SNGLQUOTELIST - Usage and Notes ---------------------------------- */
/*                                                                    */
/* Summary   : Put each item in space-separated list in single quotes.*/
/*                                                                    */
/* Syntax    : %snglquotelist(list), where                            */
/*              LIST is a space separated list                        */
/*                                                                    */
/* Date      : October, 2011                                          */
/* Author    : M Keintz                                               */
/*                                                                    */
/* Examples  :                                                        */
/*   EX1:      %snglquotelist(bid  ofr   vol) ==> 'bid' 'ofr' 'vol'   */
/*                                                                    */
/*   EX2:      %let names=Sam Joe Ted;                                */
/*             %let wh=%snglquotelist(%upcase(&names));               */
/*                 ==>'SAM' 'JOE' 'TED'                               */
/*                                                                    */
/*   EX3:      %let names=Sam Joe Ted;                                */
/*             %let wh=%commaseplist(%snglquotelist(%upcase(&names)));*/
/*                 ==>'SAM','JOE','TED'                               */
/*                                                                    */
/* Notes     : SNGLQUOTELIST removes excess blanks (see EX1)          */
/*                                                                    */
/*             EX2 and EX3 show macro nesting.                        */
/* ------------------------------------------------------------------ */

%macro snglquotelist(list) ;
  %local list   /* Space-separated list */
         nw I;
  %let nw=%sysfunc(countw(&list,%str( )));
  %if &nw>0 %then
  %do I=1 %to &nw; %str(%')%scan(&list,&I)%str(%') %end;
  %else %str( );
%mend;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
