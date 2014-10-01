/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* INTERLEAVELISTS - Usage and Notes -------------------------------- */
/*                                                                    */
/* Summary   : Interleave 2 lists (lists A B and X Y become A X B Y)  */
/*                                                                    */
/* Syntax    : %interleavelists(list1,list2), where                   */
/*              LIST1 is a space separated list                       */
/*              LIST2 is a space separated list                       */
/*                                                                    */
/* Date      : October, 2011                                          */
/* Author    : M Keintz                                               */
/*                                                                    */
/* Examples  :                                                        */
/*   EX1:      %interleavelists(a b c, aa bb cc) ==> a aa b bb c cc   */
/*                                                                    */
/*   EX2:      %let alst=a1 a2 a3;                                    */
/*             %let blst=b1 b2 b3;                                    */
/*             %interleavelists(&alst,&blst) ==> a1 b1 a2 b2 a3 b3    */
/*                                                                    */
/*   EX3:      %interleavelists(&alst,x) ==> a1 x b1 x c1 x           */
/*                                                                    */
/*   EX4:      %let totallst=AT BT;                                   */
/*             %let longlst=A1 B1 A2 B2 A3 B3;                        */
/*             %interleavelists(&longlist,&totallst)                  */
/*               ==> A1 AT B1 BT A2 AT B2 BT A3 AT B3 BT              */
/*                                                                    */
/*   EX5:      Build a list of rename expression into macrovar RLIST  */
/*             %let X=x1 x2 x3;                                       */
/*             %let oldX=%prefixlist(&x,prefix=%str(=old_));          */
/*             %let rlist=%interleavelists(&x,&newx);                 */
/*                                                                    */
/* Notes     : If either LIST is empty, result is the other list.     */
/*                                                                    */
/*             Interleaving always starts with first item in LIST1,   */
/*             then first in LIST2, etc (EX1, EX2).                   */
/*                                                                    */
/*             Shorter list will be extended to match longer list.    */
/*             So this macro may call the EXTENDLIST macro (EX4).     */
/* ------------------------------------------------------------------ */

%macro interleavelists(list1,list2);
  %local list1 list2 n1 n2 I ;

  %let n1=%sysfunc(countw(&list1,%str( )));  /* N of items in LIST1 */
  %let n2=%sysfunc(countw(&list2,%str( )));  /* N of items in LIST2 */

  %if       &n2=0     %then &list1;
  %else %if &n1=0     %then &list2;
  %else %if &n1 = &n2 %then %do I=1 %to &n1; %scan(&list1,&I,%str( )) %scan(&list2,&I,%str( )) %end;
  %else %if &n2 = 1   %then %do I=1 %to &n1; %scan(&list1,&I,%str( )) &list2 %end;
  %else %if &n1 = 1   %then %do I=1 %to &n2; &list1 %scan(&list2,&I,%str( )) %end;
  %else %if &n1 < &n2 %then %interleavelists(%extendlist(&list1,extend=%eval(&n2-&n1)),&list2);
  %else %if &n1 > &n2 %then %interleavelists(&list1,%extendlist(&list2,extend=%eval(&n1-&n2)));
%mend;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
