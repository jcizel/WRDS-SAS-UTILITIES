/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: NEUT                                                                  */
/* Summary   : Neutralizes (orthogonalizes) a set of variables by a list of          */
/*              numerical or categorical factors                                     */
/* Date      : May 18, 2009                                                          */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - DATEVAR: Period within which cross-sectional regressions are run    */
/*             - IDVAR: primary identifier when joined with datevar                  */
/*             - NEUTVAR: Dependent Variables to neutralize from common factors      */
/*             - SUFFIX: suffix of the newly created neutralized variables           */
/*             - NEUTFAC: Numerical common factors (e.g. Fama-French Risk Factors)   */
/*             - NEUTCFAC: Categorical common factors (e.g. Industry Codes)          */
/*             - WEIGHT: weight used in cross sectional regressions                  */
/* ********************************************************************************* */

%MACRO NEUT (INSET=,OUTSET=,IDVAR=,DATEVAR=,NEUTVAR=,SUFFIX=,NEUTFAC=,NEUTCFAC=,WEIGHT=);

%put ; %put ### START. Neutralization;
options nonotes;

/* Prepare the list of factors */
%let nvars = %nwords(&neutvar);
%if %length(&neutcfac)>2 %then %let cvars = %nwords(&neutcfac);
%else %let cvars=0;
%put ## Variables to Neutralize    : &neutvar;
%put ## # by Numerical Factor(s)   : &neutfac. ;
%if &cvars>0 %then 
%do;
  %put ## # & &cvars. Categorical Factor(s): &neutcfac. ;
  %let class= class &neutcfac;
%end;
%else %let class = %str( );
/* Finalize the weight statement */
%if %length(&weight)>2 %then 
%put ## #                    weight: &weight;
%put ;

/* Start the Neutralization process, variable by variable */
%put ## Neutralizing: ;

proc sort data=&inset out=__neut; by &datevar &idvar ; run;

%let neutfac  = %sysfunc(compbl(&neutfac));
%let neutfacr = %sysfunc(tranwrd(&neutfac,%str( ),%str(,)));

%if %length(&weight)>2 %then 
  %do;
    %let weight_where= and not missing(&weight);
    %let weight_cond = weight &weight;
   %end; 
%else 
  %do;
    %let weight_where= %str( );
    %let weight_cond = %str( );
  %end;
/* Loop */
%do varcount=1 %to &nvars ;
 %let invar  = %scan(&neutvar,&varcount,%str( ));
 %if &suffix ne %str() %then %let outvar = &invar._&suffix;
  %else %let outvar = &invar;
 %put ##      - &invar. ; 
  proc glm data=__neut noprint;
   where not missing(&invar.) and N(&neutfacr.)>0 &weight_where. ;
   by &datevar.; &class ;
    &weight_cond;
    model &invar=&neutfac / noint;
    output out=&invar (keep= &datevar &idvar outvar rename=(outvar=&outvar)) r=outvar;
  quit;
  data &invar; set &invar; label &outvar=" "; run;
%end;

/* Merge new neutralized variables with old dataset */
data &outset;
merge __neut(in=a) &neutvar;
by &datevar &idvar ;
if a;
run; %put ;
 
/* House Cleaning */
proc datasets library=work NoList; delete __neut &neutvar; quit; run;
options notes;

%put ### DONE . ; %put;

%MEND NEUT;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
