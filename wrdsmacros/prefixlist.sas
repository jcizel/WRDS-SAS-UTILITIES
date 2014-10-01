/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* PREFIXLIST Usage and notes --------------------------------------- */
/*                                                                    */
/* Summary   : Each list item gets a text item (or items) prefixed.   */
/*                                                                    */
/* Syntax    : %prefixlist(list,prefix=prefixval), where              */
/*              LIST is a space separated list                        */
/*              prefixval is a single item (or space separated list)  */
/*                                                                    */
/* Date      : October, 2011                                          */
/* Author    : M Keintz                                               */
/*                                                                    */
/* Examples  :                                                        */
/*   EX1.      %prefixlist(1 2 3, prefix=a) ==> a1 a2 a3              */
/*                                                                    */
/*   EX2.      %let v=x y z;                                          */
/*             %let n=1 2;                                            */
/*             %prefixlist(&n,prefix=&v)==> x1 y1 z1 x2 y2 z2         */
/*                                                                    */
/* Notes     : If PREFIX is empty, result is the unmodified LIST.     */
/*             Otherwise the number of items in the result is the     */
/*             product of the number of items in list and in prefix.  */
/*                                                                    */
/*             PREFIXLIST removes extraneous blanks.                  */
/*                                                                    */
/*             EX2 orders the result as x1 y1 z1 x2 y2 z2 (i.e. major */
/*             order by LIST, minor by PREFIX).  To produce major     */
/*             order by PREFIX, minor by LIST, swap arguments and use */
/*             the SUFFIXLIST macro:  %SUFFIXLIST(&v,suffix=&n).      */
/* ------------------------------------------------------------------ */

%macro prefixlist(list,prefix=%str( ));
  %local list   /*Space-separated list */
         prefix /* Single item or space-separated list */
         nw np w p;
  %let nw=%sysfunc(countw(&list,%str( )));
  %let np=%sysfunc(countw(&prefix,%str( )));
  %if &np=0       %then &list;
  %else %if &nw=0 %then ;
  %else %if &np=1 %then
	%sysfunc(tranwrd(%str( )%sysfunc(compbl(&list)),%str( ),%str( )&prefix));
  %else %do W=1 %to &nw;
    %do P=1 %to &NP; %scan(&prefix,&P)%scan(&list,&W) %end;
  %end;
%mend;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
