/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: IDVOL                                                                 */
/* Summary   : Calculates idiosyncratic volatility using time-series monthly/daily   */
/*              regressions for various risk models                                  */
/* Date      : July 07, 2009                                                         */
/* Author    : Denys Glushkov, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - DATEVAR: name of the date variable in INSET dataset                 */
/*             - RETVAR : name of the raw return variable in INSET dataset           */
/*             - FREQ   : frequency of returns in incoming INSET dataset,            */
/*                        m (monthly) or d(daily)                                    */
/*             - WINDOW : the length of the rolling estimation window in             */
/*                        months/trading days over which the idiosyncratic volatility*/
/*                        is estimated                                               */
/*             - STEP   : number of months/trading days by which the estimation      */
/*                        window is rolled forward                                   */
/*             - MIN    : minimum number of non-missing returns in the esitmation    */
/*                        window required for generating valid estimates of IDVOL    */
/*             - MODEL  : risk model used in estimation of idiosyncratic volatility  */
/*                        m (market), ff (Fama-French 3 factor), ffm (FF+Momentum)   */
/* ********************************************************************************* */
   
 %MACRO IDVOL (INSET=, OUTSET=, DATEVAR=, RETVAR=, FREQ=, WINDOW=,STEP=, MIN=, MODEL=);
   
   %local oldoptions errors;
   %let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes))
                   %sysfunc(getoption(source));
   %let errors=%sysfunc(getoption(errors));
   options nonotes nomprint nosource errors=0;
   %let model=%lowcase(&model);%let freq=%lowcase(&freq); 
   
  /*Depending on the incoming return frequency, create ancillary macro variables*/
  %if &freq=m %then %do; %let file=monthly; %let inc=month;%let dateff=dateff;%end;%else
  %if &freq=d %then %do; %let file=daily;   %let inc=day;  %let dateff=date;%end;
   
  /*Depending on the type of the risk model, create the variable list to be extracted*/
  %if &model=m   %then %let vars=mktrf;            %else
  %if &model=ff  %then %let vars=mktrf smb hml;    %else
  %if &model=ffm %then %let vars=mktrf smb hml umd;
   
  %put ### CREATING TRADING CALENDAR;
  proc printto log=junk;
  %Trade_Date_Windows (freq=&freq, size=&window, minsize=&min, outdsn=_caldates);
  proc printto;run;
  %put ### DONE!;
   
  %put ### MERGING IN THE RISK FACTORS;
  proc sql noprint; create table _vol
     as select a.*, b.*, (&retvar-rf) as exret
     from &inset a left join ff.factors_&file (keep=&dateff rf &vars) b
     on a.&datevar=b.&dateff
     order by a.permno, a.&datevar;
     select distinct min(&datevar) format date9.,
                     max(&datevar) format date9. into :mindate,:maxdate
    from _vol;
  quit;
%put ### DONE!;
   
 /*Save the beginning and ending position of the earliest    */
 /*and the latest dates in the trading calendar              */
  data _caldates; set _caldates;
    n+1;
    if intnx('month',beg_date,0,'e')=
    intnx('month',"&mindate"d,0,'e') then call symput ('start',n);
    if intnx('month',end_date,0,'e')=
    intnx('month',"&maxdate"d,0,'e') then call symput ('finish',n);
  run;
   
 /*Main part. Estimate Idiosyncratic Volatility using   */
 /*rolling time-series regressions. Boundaries for      */
 /*regressions are based on start and end dates in the  */
 /*trading calendar                                     */
  %put ### ESTIMATING IDIOSYNCRATIC VOLATILITY;
  proc printto log=junk;run;
  %do j=&start %to &finish %by &step;
   
   data _null_; set _caldates (sortedby=n where=(n=&j));
    call symput ('beg',beg_date);call symput ('end',end_date);
   run;
   
   data _sample/view=_sample;
     do k=1 by 1 until (last.permno);
      set _vol; by permno;
      where &beg<=date<&end;
      if missing(ret) then continue;
      mcount=sum(mcount,1);
    end;
   keep permno mcount;
   run;
   
  data _vvol/view=_vvol;
  merge _vol (sortedby=date where=(&beg<=date<&end)) _sample;
   by permno;
   if mcount>=&min;
   drop mcount;
  run;
   
  proc reg data=_vvol edf noprint outest=_stats;
   by permno;
   model exret=&vars;
  quit;
   
  data _stats; set _stats;
   format start_date end_date date9.;
   start_date=&beg;end_date=&end;
   nused=_p_+_edf_;
   label _rmse_ = " "; rename _rmse_=Idrisk_std;
   keep permno start_date end_date _rmse_ nused;
  run;
   
 /*Pool all estimates of idiosyncratic risk together*/
  proc append base=_idvol data=_stats force;run;
  %end;
  proc printto;run;
   
 /*Merge the incoming dataset with idiosyncratic risk estimates*/
  proc sql; create table &outset
   as select *
   from &inset a left join _idvol b
   on a.permno=b.permno and a.date=b.end_date;
   /* house cleaning*/
   drop table _stats, _vol, _caldates;
   drop view _vvol, _sample;
  quit;
  options &oldoptions errors=&errors;
  %put ### DONE!;
  %put ### OUTPUT IN THE DATASET &outset;
 %MEND;
    
 /* ********************************************************************************* */
 /* *************  Material Copyright Wharton Research Data Services  *************** */
 /* ****************************** All Rights Reserved ****************************** */
 /* ********************************************************************************* */
