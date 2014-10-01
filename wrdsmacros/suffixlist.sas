/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* SUFFIXLIST Usage and notes --------------------------------------- */
/*                                                                    */
/* Summary   : Each list item gets a text item (or items) appended.   */
/*                                                                    */
/* Syntax    : %suffixlist(list,suffix=suffixval), where              */
/*              LIST is a space separated list                        */
/*              suffixval is a single item (or space separated list)  */
/*                                                                    */
/* Date      : October, 2011                                          */
/* Author    : M Keintz                                               */
/*                                                                    */
/* Examples  :                                                        */
/*   EX1.      %suffixlist(a b c, suffix=1) ==> a1 b1 c1              */
/*                                                                    */
/*   EX2.      %let v=x y z;                                          */
/*             %let n=1 2;                                            */
/*             %suffixlist(&v,suffix=&n)==> x1 x2 y1 y2 z1 z2         */
/*                                                                    */
/*                                                                    */
/* Notes     : If suffix is empty, result is the unmodified list.     */
/*             Otherwise the number of items in the result is the     */
/*             product of the number of items in list and in suffix.  */
/*                                                                    */
/*             SUFFIXLIST removes extraneous blanks.                  */
/*                                                                    */
/*             EX2 orders the result as x1 x2 y1 y2 z1 z2 (i.e. major */
/*             order by LIST, minor by SUFFIX).  To produce major     */
/*             order by SUFFIX, minor by LIST, swap arguments and use */
/*             the PREFIXLIST macro:  %PREFIXLIST(&n,prefix=&v).      */
/* ------------------------------------------------------------------ */

%macro suffixlist(list,suffix=%str( ));
  %local list    /*Space-separated list */
         suffix  /* Single item or space-separated list */
         nw np w p;
  %let nw=%sysfunc(countw(&list,%str( )));
  %let np=%sysfunc(countw(&suffix,%str( )));
  %if &np=0       %then &list;
  %else %if &nw=0 %then ;
  %else %if &np=1 %then
	%sysfunc(tranwrd(%sysfunc(compbl(&list))%str( ),%str( ),&suffix%str( )));
  %else %do W=1 %to &nw;
    %do P=1 %to &NP; %scan(&list,&W)%scan(&suffix,&P) %end;
  %end;
%mend;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
