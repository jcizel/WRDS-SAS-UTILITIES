/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: CRSPMERGE                                                             */
/* Summary   : Merges CRSP Stocks and Events Data                                    */
/* Date      : April 14, 2009                                                        */
/* Author    : Rabih Moussawi and Luis Palacios, WRDS                                */
/* Variables : - S: Monthly/Daily, defaults to Monthly, but s=d for CRSP Daily data  */
/*             - START, END: Start and End Dates. Example Date Format: 01JAN2000     */
/*             - SFVARS: Stock File Vars to extract. e.g. PRC VOL SHROUT             */
/*             - SEVARS: Event File Vars to extract. e.g. TICKER NCUSIP SHRCD EXCHCD */
/*                  warning: including DIVAMT may result in multiple obs per period  */ 
/*             - FILTERS: Additional screens using variables in SFVARS or SEVARS     */ 	              
/*                          (default no filters                                      */
/*             - OUTSET: Output Dataset Name (default names crsp_m or crsp_d)        */
/* ********************************************************************************* */

%MACRO CRSPMERGE (S=m,START=01JAN2000,END=30JUN2001,SFVARS=prc ret shrout,SEVARS=ticker ncusip exchcd shrcd siccd,FILTERS=,OUTSET=crsp_&s.);

/* Check Series: Daily or Monthly and define datasets - Default is Monthly  */
%if &s=D %then %let s=d; %else %if &s ne d %then %let s=m;
%if (%sysfunc(libref(crsp))) %then %do; 
  %let cs=/wrds/crsp/sasdata/; 
  libname crsp ("&cs/m_stock","&cs/q_stock","&cs/a_stock"); 
%end;
%let sf       = crsp.&s.sf ;
%let se       = crsp.&s.seall ;
%let senames  = crsp.&s.senames ;

%put ; 
%put #### START. Merging CRSP Stock File (&s.sf) and Event File (&s.se) ;

options nonotes;
%let sdate = %sysfunc(putn("&start"d,5.)) ; 
%let edate = %sysfunc(putn("&end"d,5.)) ; 

%let sevars   = %sysfunc(compbl(&sevars));
%let sevars   = %sysfunc(lowcase(&sevars));
%let nsevars  = %nwords(&sevars);

/* create lag event variable names to be used in the RETAIN statement */
%let sevars_l = lag_%sysfunc(tranwrd(&sevars,%str( ),%str( lag_))); 

%if %length(&filters) > 2 %then %let filters = and &filters; 
  %else %let filters = %str( );

/* Get stock data */
proc sql;
	create table __sfdata 
	as select *
	from &sf (keep= permno date &sfvars)
	where date between &sdate and &edate and permno in 
	(select distinct permno from 
      &senames(WHERE=(&edate>=NAMEDT and &sdate<=NAMEENDT) 
         keep=permno namedt nameendt) )
	order by permno, date;
	quit; 

/* Get event data */
proc sql;
   create table __sedata
   as select a.*
   from &se (keep= permno date &sevars) as a,
    (select distinct permno, min(namedt) as minnamedt from 
      &senames(WHERE=(&edate>=NAMEDT and &sdate<=NAMEENDT) 
         keep=permno namedt nameendt) group by permno) as b
	where a.date >= b.minnamedt and a.date <= &edate and a.permno =b.permno 
   order by a.permno, a.date;
   quit;

/* Merge stock and event data */
%let eventvars = ticker comnam ncusip shrout siccd exchcd shrcls shrcd shrflg trtscd nmsind mmcnt nsdinx;

data &outset. (keep=permno date &sfvars &sevars);
merge __sedata (in=eventdata) __sfdata (in=stockdata);
by permno date; retain &sevars_l;
%do i = 1 %to &nsevars;
  %let var   = %scan(&sevars,&i,%str( ));
  %let var_l = %scan(&sevars_l,&i,%str( ));
  %if %sysfunc(index(&eventvars,&var))>0 %then
   %do; 
     if eventdata or first.permno then &var_l = &var. ;
	 else if not eventdata then &var = &var_l. ;
   %end;
 %end;
if eventdata and not stockdata then delete;
drop &sevars_l ;
run;

/* Some companies have many distribution on the same date (e.g. a stock and cash dist)  */
/* Records will identical except for different DISTCD and DISTAMT */
proc sort data=&outset. noduplicates;
where 1 &filters;
    by permno date;
run;

/* House Cleaning */
proc sql; 
drop table __sedata, __sfdata; 
quit; 

options notes;
%put #### DONE . Dataset &outset. Created! ;	%put ;

%MEND CRSPMERGE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
