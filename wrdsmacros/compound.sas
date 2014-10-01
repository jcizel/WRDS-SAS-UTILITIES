/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: COMPOUND                                                              */
/* Summary   : Calculates continuosly compound returns                               */
/* Date      : May 19, 2009                                                          */
/* Author    : Denys Glushkov, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - INFREQ frequency of returns in INSET dataset, m/d for monthly/daily */
/*             - OUTFREQ compounding interval,                                       */
/*                         a(annual)/s(semiannual)/q(quarterly)/m(monthly)/w(weekly) */
/*             - DATEVAR name of the date variable in the INSET dataset,             */
/*                         MUST BE a SAS date value                                  */
/*             - DELIST in(ex)clude delisting returns (1-include,0-don't include)    */
/* ********************************************************************************* */

 %MACRO COMPOUND (INSET=, OUTSET=, INFREQ=, OUTFREQ=, DATEVAR=, DELIST=0);
  options nonotes nomprint;
  %local freq datecond totret setcond;
  %if %lowcase(&outfreq)=a %then %let freq='Year';
     %else %if %lowcase(&outfreq)=s %then %let freq='Semiyear';
  %else %if %lowcase(&outfreq)=q %then %let freq='Qtr';
     %else %if %lowcase(&outfreq)=m %then %let freq='Month';
      %else %if %lowcase(&outfreq)=w %then %let freq='Week';
  %if %lowcase(&infreq)=d %then %let datecond=(a.&datevar=b.date); %else
  %if %lowcase(&infreq)=m %then
     %let datecond=(intnx("month",a.&datevar,-1,"end")< b.date <= a.&datevar);

   %put ### START;
   %put ### Sorting... ;
   proc sort data=&inset out=_&inset; by permno &datevar;run;

    %if &delist=1 %then
      %do;
         %put ### ADDING DELISTING RETURNS;
         %let totret=sum(a.ret,b.dlret);
         %let setcond=&inset a left join _dlistret b
                      on a.permno=b.permno and &datecond;

        /*delisting returns during the specified period*/
          proc sql;
            create table _maxmin
              as select distinct a.permno, min(&datevar) as mindate format=date9.,
              max(&datevar) as maxdate format=date9.
              from _&inset a
              group by permno;

            create table _dlistret
              as select distinct a.permno, a.date, a.dlret
              from crsp.&infreq.se a, _maxmin b
              where (b.mindate <= a.date <= b.maxdate and a.event='DELIST'
              and a.permno=b.permno)
              order by a.permno, a.date;
          quit;
      %end;
    %else
        %if &delist=0 %then
          %do;
           %put ### NO DELISTING RETURNS;
           %let totret=a.ret;
           %let setcond=&inset a;
          %end;

   %put ### COMPOUNDING RETURNS FROM &INFREQ INTO &OUTFREQ FREQUENCY...;
   /*main part: compounding total returns within a specific date group*/
   proc sql;
     create table &outset
       as select distinct a.permno,
       year(a.&datevar)*100+intck(&freq,intnx('year',a.&datevar,0),
       a.&datevar)+1 as newdate label=&freq,
       exp(sum(log(1+&totret)))-1 as cret "Compound return",
       min(&totret) as minret "Min return", max(&totret) as maxret "Maximum return",
       nmiss(&totret) as nmiss "Number of total returns missing",
       n(a.&datevar) as nobs "Number of all observations in aggregation"
       from &setcond
       group by a.permno, newdate;
     quit;

   /*house cleaning*/
   proc sql; drop table _dlistret,_maxmin, _&inset;quit;
  options notes mprint;
 %put ### DONE ;
 %put ### OUTPUT IN THE DATASET &outset;
 %MEND;
 
 /* ********************************************************************************* */
 /* *************  Material Copyright Wharton Research Data Services  *************** */
 /* ****************************** All Rights Reserved ****************************** */
 /* ********************************************************************************* */

