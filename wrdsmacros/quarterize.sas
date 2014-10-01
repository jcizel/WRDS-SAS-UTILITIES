/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: QUARTERIZE                                                            */
/* Summary   : Quarterizes Compustat YTM Cash Flow Variables in FUNDQ Dataset        */
/* Date      : May 18, 2009                                                          */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - FYEAR and FQTR: Fiscal Year and Fiscal Quarter identifiers          */
/*             - IDVAR: primary identifier when joined with fiscal year and quarter  */
/*             - VARS: YTM vars used to derive Quarterly vars (with _q suffixes)     */
/*                      (default is all Compustat YTM variables -- ending with 'y')  */ 
/* ********************************************************************************* */

%MACRO QUARTERIZE (INSET=comp.fundq,OUTSET=fundq_qtr,IDVAR=datafmt indfmt popsrc consol fyr gvkey,FYEAR=fyearq,FQTR=fqtr,VARS=);
/* Note: Quarterize only Cash Flow items in Compustat */
/*        I/S items in Compustat are quarterly numbers */
/*        GVKEY FYR Combination is necessary for unique identification of records */

option nonotes;
/* Count the Number of Cash Flow Variables */
%let nvars = %nwords(&vars);

/* If no pre-specified variables then quarterize all potential YTM CF variables */
%if &nvars = 0 
%then %do;
 /* Get Variable Names and Keep only Numerical YTM Variables (suffix 'y' in Compustat Quarterly) */
 proc contents data=&INSET. noprint out=_listvar (where=(type=1) keep=NAME TYPE VARNUM LABEL); run;
 proc sort data=_listvar; by varnum; run;
   data _listvar;
    set _listvar (drop=type);
    where strip(lowcase(name)) like '%y';
    name=strip(lowcase(name));
    name_q = cats(name,"_q");
    if strip(name) ne "gvkey"; /* Redundant if GVKEY is a character value */
   run;
 proc sql noprint;
   select distinct name into :vars separated by " " from _listvar; 
   select distinct name_q into :vars_q separated by " " from _listvar; 
   select distinct count(*) into :nvars separated by " " from _listvar;
   drop table _listvar; quit;
 quit;
 %end;
 %else %let vars_q = %sysfunc(tranwrd(&vars,%str( ),%str(_q )))_q;
 
%put ;
%put ### START. Quarterizing...;
%put ;
%put ## Number  of  Variables    :  &nvars;
%put ## List of  YTM CF Variables:  &vars;
%put ## List of New QTR Variables:  &vars_q;
%put ;

proc sort data=&inset out=__qtrz nodupkey; by &idvar &fyear &fqtr ; run;

data &outset;
set __qtrz;
by &idvar &fyear &fqtr;
array cfytd  {&nvars} &vars;
array cfqtr  {&nvars} &vars_q;
do i=1 to &nvars; cfqtr(i)=dif(cfytd(i)); end;
del = (dif(&fqtr) ne 1);  
if first.&fyear then
do;
 del = (&fqtr ne 1);
 do j=1 to &nvars; cfqtr(j)=cfytd(j); end;
end;
if del=1 then 
do; 
 do k=1 to &nvars; cfqtr(k)=.; end; 
end;
drop del i j k;
run;

/* House Cleaning */
proc sql; drop table __qtrz; quit; 
options notes;

%put ### DONE . ; %put;

%MEND QUARTERIZE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
