/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: POPULATE                                                              */
/* Summary   : Populates a Dataset with Any Frequency Into Monthly Intervals         */
/* Date      : May 18, 2009                                                          */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - DATEVAR: Original dataset date variable                             */
/*             - IDVAR: Primary identifier when combined with DATEVAR                */
/*             - MONTHVAR: Monthly Date Variable in Output Dataset (default=MDATE)   */
/*             - FORWARD_MAX: Periodicity of the original dataset, in months         */ 
/*                    e.g. Quarterly (=3), Semi-Annual(=6) or Annual(=12)            */
/*                   Also represents the maximum Carry-Forward Population Intervals  */
/* ********************************************************************************* */

%MACRO POPULATE (INSET=,OUTSET=,DATEVAR=,IDVAR=,MONTHVAR=MDATE,FORWARD_MAX=12);

%put ; %put ### START. Populating Data ;

/* nodupkey sort necessary */
options nonotes;
proc sort data=&inset. out=__TEMP nodupkey; by &idvar descending &datevar; run;

/* Populate Dates */
/* FORWARD_MAX is the Regular Periodicity or the Forward Population Intervals */
%let nid = %nwords(&idvar.);
%let id2 = %scan(&idvar.,&nid.,%str( ));

data &outset. ; format &MONTHVAR. date9.; label &MONTHVAR. = "Monthly Date";
set __TEMP ;
by &idvar. ;
&MONTHVAR. =&datevar. ;
output;
following = lag(&MONTHVAR. );
if first.&id2 then
 do i=1 to &forward_max. -1;
 &MONTHVAR. = intnx("month",&MONTHVAR. ,1,"E"); output;
 end;
else
 do;
  n = intck("month",&MONTHVAR. ,following);
  do i = 1 to min(n-1,&forward_max. -1);
   &MONTHVAR. = intnx("month",&MONTHVAR. ,1,"E"); output;
  end;
 end;
drop following n i;
run;

proc sort data=&outset. nodupkey; by &idvar. &datevar. &MONTHVAR.; run;
/* House Cleaning */
proc sql; drop table __temp; quit;
options notes;
%put ### DONE . Dataset &OUTSET. with Monthly Frequency Generated ; %put ;

%MEND POPULATE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
