/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* Summary   : Compute Market-Model Betas                                            */
/* Date      : January, 2011                                                         */
/* Author    : Rabih Moussawi                                                        */
/* Variables : - S: Monthly/Daily, defaults to Monthly, but s=d for CRSP Daily data  */
/*             - BEGDATE: Sample Start Date                                          */
/*             - ENDDATE: Sample End Date                                            */
/*             - WINDOW: Window of Estimation                                        */
/*             - MINWIN: Minimum Window of Estimation for non-missing betas          */
/*             - INDEX: Market Return Variable, with default Value-Weighted (VWRETD) */
/*             - OUTSET: Output Dataset Name (default names crsp_m or crsp_d)        */
/* ********************************************************************************* */

%MACRO BETA (S=m,START=01JAN2000,END=30JUN2001,WINDOW=36,MINWIN=12,INDEX=VWRETD,OUTSET=beta_&s.);

/* Check Series: Daily or Monthly and define datasets - Default is Monthly  */
%if &s=D %then %let s=d; %else %if &s ne d %then %let s=m;
%if (%sysfunc(libref(crsp))) %then %do; 
  %let cs=/wrds/crsp/sasdata/; 
  libname crsp ("&cs/m_stock","&cs/q_stock","&cs/a_stock"); 
%end;
%let sf = crsp.&s.sf ;
%let si = crsp.&s.si ;

options nonotes;
%put #### START. Computing Betas from &sf Using &WINDOW Estimation Window ;
data _crsp1 /view=_crsp1;
set &sf. ;
where "&START."D<=date<="&END."D;
keep permno date ret;
run;

proc sql;
create table _crsp2
as select a.*, b.&index, b.&index*(abs(a.ret)>=0) as X, a.ret*b.&index as XY, 
  (abs(a.ret*b.&index)>=0) as count
from _crsp1 as a left join &si. as b
on a.date=b.date
order by a.permno, a.date;
quit;

proc printto log = junk; run;
proc expand data=_crsp2 out=_crsp3 method=none;
by permno;
id date;
convert X=X2      / transformout= (MOVUSS &WINDOW.);
convert X=X       / transformout= (MOVSUM &WINDOW.);
convert XY=XY     / transformout= (MOVSUM &WINDOW.);
convert ret=Y     / transformout= (MOVSUM &WINDOW.);
convert count=n   / transformout= (MOVSUM &WINDOW.);
quit;
run; 
proc printto; run;

data &outset;
set _crsp3;
if n>=&MINWIN. then beta=(XY-X*Y/n) / (X2-(X**2)/n);
label beta = "Stock Beta";
label n = "Number of Observations used to compute Beta";
drop X X2 XY Y COUNT;
format beta comma8.2 ret &index percentn8.2;
run;

/* House Cleaning */
proc sql; 
drop view _crsp1;
drop table _crsp2, _crsp3; 
quit; 

options notes;
%put #### DONE . Dataset &outset. Created! ;	%put ;

%MEND BETA;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
