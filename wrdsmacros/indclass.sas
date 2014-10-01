/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: INDCLASS                                                              */
/* Summary   : Constructs 4 different industry classifications based on SIC, NAICS,  */
/*             GICS and Fama-French industry classifications                         */
/*                                                                                   */
/* Date      : Feb, 2010                                                             */
/* Author    : Denys Glushkov, WRDS                                                  */
/* Variables :                                                                       */
/*  - INSET  : Name of input dataset containing the list of distinct gvkeys          */
/*  - OUTSET : Output dataset containing codes and names of 4 industry               */
/*            classifications using SICH (Historical SIC code), NAICSH (Historical   */
/*            NAICS code), SPGIM (Historical GICS code) and FF classification as     */
/*            well industy names                                                     */
/*  - FFIND  : Number of Fama-French industries with values: 10,12,17,30,38,48,49    */
/*  - BEGDATE: Beginning date of the period for which classification is sought       */
/*             should be in DDMMYYYY format, e.g., 01jan1985                         */
/*  - ENDDATE: Ending date of the period for which classification is sought          */
/*             should be in DDMMYYYY format, e.g., 31dec2008                         */
/*  - FREQ   : Desired date frequency for the output. Can be day,week,month or year  */
/*             e.g, FREQ=YEAR                                                        */
/* ********************************************************************************* */

%MACRO INDCLASS (INSET=, OUTSET=, FFIND=, BEGDATE=,ENDDATE=,FREQ=);
 %local begdate1 enddate1;
 %local oldoptions errors;
 %let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes))
                 %sysfunc(getoption(source));
 %let errors=%sysfunc(getoption(errors));
 options nonotes nomprint nosource errors=0;

 %let begdate1=%sysfunc(putn("&begdate"d,5.));
 %let enddate1=%sysfunc(putn("&enddate"d,5.));

/*Create the list of dates at the user-requested frequency*/
 data _dates;
  &freq._date=intnx("&freq",intnx("&freq",&begdate1,-1),0,"END");
  do while (&freq._date < intnx("&freq",&enddate1,0,"END"));
  &freq._date=intnx("&freq",&freq._date,1,"END");
  output;
 end;

/*Populate date variable and limit the sample to the years covered by Compustat*/
 proc sql;
  create view _&outset.1
  as select a.*, b.&freq._date format=date9.
 from &inset a, _dates b;

 create view _&outset.2
  as select a.*
  from _&outset.1 a, comp.names (keep=gvkey year1 year2) b
  where a.gvkey=b.gvkey and b.year1 <= year(a.&freq._date)<= b.year2;
 quit;

 %put ; %put ### EXTRACTING HISTORICAL SIC AND NAICS...;
 proc printto log=junk;run;
 proc sql; create view _codes1
  as select a.*, b.naicsdesc
  from (select a.*, b.sicdesc
  from (select a.gvkey,a.naicsh,a.sich,a.datadate from comp.co_industry a,&inset b
        where a.gvkey=b.gvkey and a.consol='C' and a.popsrc='D') a
  left join comp.r_siccd b on a.sich=input(b.siccd,11.)) a left join comp.r_naiccd b
  on a.naicsh=input(b.naicscd,11.)
  order by gvkey, datadate desc; 
 quit;

/*Define the lead datadate for future merging*/
 data _codes; set _codes1;
  by gvkey descending datadate;
  leaddatadate=lag(datadate);
  if first.gvkey then leaddatadate=intnx('month',datadate,12,'end');
 run;
 proc printto;run;
 %put ### DONE!;

 %put ; %put ### MERGING IN INDUSTRY CODES AND DESCRIPTIONS...;
 proc sql;
   create view _&outset.3
    as select a.*, b.spgim
    from (select a.*, b.sich, b.naicsh, b.sicdesc, b.naicsdesc
    from _&outset.2 a left join _codes b
    on a.gvkey=b.gvkey and b.datadate < a.&freq._date <= b.leaddatadate) a
    left join comp.sec_mth (where=(missing(spgim)=0 and iid='01')) b
    on a.gvkey=b.gvkey and a.&freq._date=intnx('month',b.datadate,0,"END");

   create view _&outset.4
    as select a.*, b.gicdesc
    from _&outset.3 a left join comp.r_giccd b
    on a.spgim=b.giccd
    order by gvkey, &freq._date;
 quit;
 %put ### DONE!;

 %put ; %put ### ASSINGING FAMA-FRENCH INDUSTRIES...;
 data _&outset.5/view=_&outset.5; set _&outset.4;
  %ffi&ffind(sich);
 run;
 proc sort data=_&outset.5 out=&outset; by gvkey &freq._date;run;
 %put ### DONE!;

/*house cleaning*/
 proc sql; drop table _dates, _codes;
           drop view _&outset.1,_&outset.2, _&outset.3,
                       _&outset.4, _&outset.5, _codes1;quit;
 options errors=&errors &oldoptions;
%MEND;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
