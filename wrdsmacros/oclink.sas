/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: OCLINK                                                                */
/* Summary   : Creates OptionMetrics-CRSP Link Table                                 */
/* Date      : November 1, 2010                                                      */  
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - OPTIONMID and CRSPID are OptionMetrics and CRSP Names Datasets      */
/*             - OUTSET: OptionMetrics-CRSP link table output dataset                */
/* ********************************************************************************* */

%MACRO OCLINK (OPTIONMID=OPTIONM.SECNMD,CRSPID=CRSP.MSENAMES,OUTSET=WORK.OCLINK);

options nonotes;
/* Check Validity of Library Assignments */
%if (%sysfunc(libref(crsp))) %then %do; 
  %let cs=/wrds/crsp/sasdata/; 
  libname crsp ("&cs/m_stock","&cs/q_stock","&cs/a_stock"); 
%end;
%if (%sysfunc(libref(optionm))) %then %do; libname optionm "/wrds/optionm/sasdata"; %end;

%put; %put ## START. ;

/* Step 1: Link by CUSIP between CRSP's PERMNO and OptionMetrics' SECID */
proc sort data=&OPTIONMID out=_OPT1 (keep=secid cusip issuer effect_date);
  by secid cusip effect_date;
run;

/* Create first and last 'start dates' for CUSIP link */
proc sql;
  create table _OPT2
  as select *, min(effect_date) as fdate, max(effect_date) as ldate
  from _OPT1
  group by secid, cusip
  order by secid, cusip, effect_date;
quit;

/* Label date range variables and keep only most recent company name for CUSIP link */
data _OPT2;
  set _OPT2;
  by secid cusip;
  if last.cusip;
  label fdate="First Start date of CUSIP record";
  label ldate="Last Start date of CUSIP record";
  format fdate ldate date9.;
  drop effect_date;
run;

/* CRSP: Get all PERMNO-NCUSIP combinations */
proc sort data=&CRSPID out=_CRSP1 (keep=PERMNO NCUSIP comnam namedt nameendt);
  where not missing(NCUSIP);
  by PERMNO NCUSIP namedt; 
run;

/* Arrange effective dates for CUSIP link */
proc sql;
  create table _CRSP2
  as select PERMNO,NCUSIP,comnam,min(namedt)as namedt,max(nameendt) as nameenddt
  from _CRSP1
  group by PERMNO, NCUSIP
  order by PERMNO, NCUSIP, NAMEDT;
quit;

/* Label date range variables and keep only most recent company name */
data _CRSP2;
  set _CRSP2;
  by permno ncusip;
  if last.ncusip;
  label namedt="Start date of CUSIP record";
  label nameenddt="End date of CUSIP record";
  format namedt nameenddt date9.;
run;

/* Create CUSIP Link Table */ 
/* CUSIP date ranges are only used in scoring as CUSIPs are not reused for 
    different companies overtime */
proc sql;
  create table _LINK1_1
  as select *
  from _OPT2 as a, _CRSP2 as b
  where a.CUSIP = b.NCUSIP
  order by SECID, PERMNO, ldate;
quit; 

/* Score links using CUSIP date range and company name spelling distance */
/* Idea: date ranges the same cusip was used in CRSP and OptionMetrics should intersect */
data _LINK1_2;
  set _LINK1_1;
  by SECID PERMNO;
  if last.permno; /* Keep link with most recent company name */
  name_dist = min(spedis(issuer,comnam),spedis(comnam,issuer));
  if (not ((ldate < namedt) or (fdate > nameenddt))) and name_dist < 30 then SCORE = 0;
    else if (not ((ldate < namedt) or (fdate > nameenddt))) then score = 1;
	else if name_dist < 30 then SCORE = 2; 
	  else SCORE = 3;
  keep SECID PERMNO issuer comnam score;
run;

%put ## # Step2: Linking using TICKERs... ;
/* Step 2: Find links for the remaining unmatched cases using Exchange Ticker */
/* Identify remaining unmatched cases */
proc sql;
  create table _NOMATCH1
  as select distinct a.*
  from _OPT1 (keep=secid) as a 
  where a.secid NOT in (select distinct secid from _LINK1_2)
  order by a.secid;
quit; 

/* Drop Step1 Tables*/
proc sql; drop table _OPT1,_OPT2,_CRSP1,_CRSP2; quit;

/* Add OptionMetrics identifying information & drop tickers that have ? or ZZZZ */
proc sql;
  create table _NOMATCH2
  as select b.SECID, b.issuer, b.ticker, b.effect_date, b.cusip
  from _NOMATCH1 as a, &OPTIONMID as b
  where a.SECID = b.SECID and not (missing(b.ticker))
   and ticker not like '%?%' and ticker not like '%ZZZZ%' 
  order by secid, ticker, effect_date;
quit;  

/* Create first and last 'start dates' for Exchange Tickers */
proc sql;
  create table _NOMATCH3
  as select *, min(effect_date) as fdate, max(effect_date) as ldate
  from _NOMATCH2
  group by secid, ticker
  order by secid, ticker, effect_date;
quit;

/* Label date range variables and keep only most recent company name */
data _NOMATCH3;
  set _NOMATCH3;
  by secid ticker;
  if last.ticker;
  label fdate="First Start date of OFTIC record";
  label ldate="Last Start date of OFTIC record";
  format fdate ldate date9.;
  drop effect_date;
run;

/* Get entire list of CRSP stocks with Exchange Ticker information */
/* Give CRSP's Trading Ticker precedence over CRSP Standardized Ticker */
proc sql;
create table _CRSP1
as select coalesce(tsymbol,ticker) as ticker, comnam, permno, 
   ncusip, namedt, nameendt 
from &CRSPID 
order by permno, ticker, namedt; 
run;

/* Arrange effective dates for link by Exchange Ticker */
proc sql;
  create table _CRSP2
  as select permno,comnam,ticker,ncusip,
              min(namedt)as namedt,max(nameendt) as nameenddt
  from _CRSP1
  where not missing(ticker)
  group by permno, ticker
  order by permno, ticker, namedt;
quit; 

/* Label date range variables and keep only most recent company name */
data _CRSP2;
  set _CRSP2;
  by permno ticker;
  if  last.ticker;
  label namedt="Start date of exch. ticker record";
  label nameenddt="End date of exch. ticker record";
  format namedt nameenddt date9.;
run;

/* Merge remaining unmatched cases using Exchange Ticker */
/* Note: Use ticker date ranges as exchange tickers are reused overtime */
proc sql;
  create table _LINK2_1
  as select a.secid,a.ticker, b.permno, a.issuer, b.comnam, a.cusip, b.ncusip, a.ldate
  from _NOMATCH3 as a, _CRSP2 as b
  where strip(a.ticker) = strip(b.ticker) and 
	 (ldate >= namedt) and (fdate <= nameenddt)
  order by secid, ticker, ldate;
quit; 

/* Score using company name using 6-digit CUSIP and company name spelling distance */
data _LINK2_2;
  set _LINK2_1;
  name_dist = min(spedis(issuer,comnam),spedis(comnam,issuer));
  if substr(cusip,1,6)=substr(ncusip,1,6) and name_dist < 30 then SCORE=0;
  else if substr(cusip,1,6)=substr(ncusip,1,6) then score = 4;
  else if name_dist < 30 then SCORE = 5; 
      else SCORE = 6;
run;

/* Some companies may have more than one SECID-PERMNO link,           */
/* so re-sort and keep the case (PERMNO & Company name from CRSP)     */
/* that gives the lowest score for each OptionM SECID (first.secid=1) */
proc sort data=_LINK2_2; by secid score; run;
data _LINK2_3;
  set _LINK2_2;
  by secid score;
  if first.secid;
  keep secid permno issuer comnam permno score;
run;

%put ## # Step3: Finalizing Links and Scores... ;
/* Step 3: Add Exchange Ticker links to CUSIP links      */ 
/* Create Labels for OCLINK dataset and variables        */
/* Create final link table and save it in prespecified directory */
data &OUTSET (label="OptionMetrics-CRSP Link Table");
  set _LINK1_2 _LINK2_3;
label ISSUER = "Company Name in OptionMetrics";
label COMNAM= "Company Name in CRSP";
label SCORE= "Link Score: 0(best) - 6";
run;

/* Final Sort */
proc sort data=&OUTSET; by SECID SCORE PERMNO; run;

%put ## # Step4: Link Table &OUTSET Ready... ;
/* House Cleaning */
proc sql; 
drop table _CRSP1,_CRSP2,
           _LINK1_1,_LINK1_2,_LINK2_1,_LINK2_2,_LINK2_3,
           _NOMATCH1,_NOMATCH2,_NOMATCH3;
quit;
%put ## DONE .; %put;
options notes;
%MEND OCLINK;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
