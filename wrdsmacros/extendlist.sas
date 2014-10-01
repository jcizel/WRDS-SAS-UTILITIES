/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* EXTENDLIST - Usage and Notes ------------------------------------- */
/*                                                                    */
/* Summary   : Extend list by specified amount via list repetition.   */
/*                                                                    */
/* Syntax    : %extendlist(list,exby=), where                         */
/*              LIST   a space separated list                         */
/*              EXBY=  number of "words" by which to extend LIST      */
/*                                                                    */
/* Date      : October, 2011                                          */
/* Author    : M Keintz                                               */
/*                                                                    */
/* Examples  :                                                        */
/*   EX1:      %extendlist(a b c,exby=5) ==> a b c a b c a b          */
/*                                                                    */
/*   EX2:      %let lst=w x y z;                                      */
/*             %extendlist(&lst,exby=4) ==> w x y z w x y z           */
/*                                                                    */
/*   EX3:      %extendlist(ofr bid) ==> ofr bid                       */
/*                                                                    */
/*   EX4:      %let sumlst=asum bsum csum;                            */
/*             %let nextra=%eval(9-%nwords(&sumlst);                  */
/*             %extendlist(&sumlist,exby=&nextra)                     */
/*               ==> asum bsum csum asum bsum csum asum bsum csum     */
/*                                                                    */
/* Notes     : LIST is a positional parameter & must always be first. */
/*                                                                    */
/*             The EXBY= parameter is a "name=value" pair.            */
/*             Default is EXBY=0 (no extension - see Ex3).            */
/*                                                                    */
/*             Both full & partial list repetition done as needed-EX1.*/
/* ------------------------------------------------------------------ */

%macro extendlist(list,exby=0);
  %local list   /* Space-separated list */
         exby   /* Number of items to use in extending the list */
         nw I NREPS;
  %let nw=%sysfunc(countw(&list,%str( )));
  %if &nw=0 %then ;
  %else %if &exby < &nw %then %do; &list
	%if &exby > 0 %then %do I=1 %to &exby; %scan(&list,&I,%str( )) %end;
  %end;
  %else %do;
    %let nreps=%eval(&exby/&nw);  /* N of full repetitions needed */
    %do i=1 %to &nreps; &list %end;
    %extendlist(&list,exby=%eval(&exby-(&nrep*&nw)))  /* Partial repetition  */
  %end;
%mend;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
