/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: INDRATIOS                                                             */
/* Summary   : Computes a broad range of financial ratios aggregated at              */
/*              the industry level using Fama-French industry classification         */
/* Date      : Apr, 2009                                                             */
/* Modified  : Nov, 2010                                                             */
/* Author    : Denys Glushkov, WRDS                                                  */
/* Parameters:                                                                       */
/*    - BEG_YR     : First Fiscal Year For Ratios Computation, e.g. 1980             */
/*    - END_YR     : Last Fiscal Year For  Ratios Computation, e.g. 2010             */
/*    - NIND       : Number (integer) of Fama-French Industries that                 */
/*                    Can take values of 5,10,12,17,30,38,48 or 49                   */
/*    - AVR        : Defines how industry average is calculated.                     */
/*                    Can be either Mean or Median.                                  */
/*    - FREQ       : The vintage update frequency to be used                         */
/*                    Q (A) - quarterly (annual) updates of Compustat annual data    */
/*                    the availability will depend on your school's subscription     */
/*    - OUTSET_IND : Output SAS dataset containing the time-series of                */
/*                   Industry Mean/Median Ratios b/w BEG_YR to END_YR                */
/*    - OUTSET_FIRM: Output dataset containing financial ratios at the firm level    */
/* ********************************************************************************* */

%MACRO INDRATIOS (BEG_YR=, END_YR=, NIND=, AVR=, FREQ=, OUTSET_IND=, OUTSET_FIRM=);
  %local comp_filter vars comp_vars drop_vars;
  %local oldoptions errors;
  %let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes))
                  %sysfunc(getoption(source));
  %let errors=%sysfunc(getoption(errors));
   options nonotes nomprint nosource errors=0;
  %let freq=%lowcase(&freq);
  libname home '~';
  
  /*Impose filter to obtain unique gvkey-datadate records*/
  %let comp_filter=indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C';

  /*List of Ratios to be calculated*/
  %let vars=  eps_exi eps_inci mcap ep pe ps bm dvy dpr
              gpm opmad ptpm npm cfm roe roa ros
              rect_turn pay_turn inv_turn nwc_turn at_turn cash_turn
              der der1 der2 der3 intcov rds
              curr_ratio quick_ratio cashr invtonwc;

   /*Compustat variables to extract*/
  %let comp_vars=  che cshpri ajex ibc dpc esubc ib dp epspx sich
                   epspi xint idit cogs xrd sale oibdp oiadp pi dlc
                   txpd act lct invt rect ni seq ceq ap  pstk at lt fic
                   pstkrv pstkl txditc ibadj dvc dvt tie tii dltt curcd;

   /*Variables to be dropped from the intermediate datasets*/ 
  %let drop_vars=shrcd exchcd date public_date linkdt indfmt datafmt popsrc consol
                  linkenddt linktype linkprim usedflag lpermno;    
 
   /*Run the CrspMerge.sas Macro that merges CRSP stock and event files*/
   /*Limit the sample only to common stocks (CRSP Share Code 10 and 11)*/
  %put ; %put ### MERGING CRSP EVENT AND STOCK FILES FOR COMMON STOCKS;
  proc printto log=junk;run;
  %CrspMerge(s=m, start=01jan&beg_yr, end=31dec&end_yr, sfvars=prc shrout cfacpr,
         sevars=shrcd exchcd siccd, filters=shrcd in (10,11), outset=_crsp_data);
 proc printto;run;
  %put ### DONE!;

 /*Extracting data for Ratios Based on Annual Data and link it with CRSP identifier*/
 %put ; %put ### EXTRACTING ANNUAL FUNDAMENTALS AND MERGING IN CRSP IDENTIFIER;
 proc printto log=junk;run;
 proc sql;
  create view _comp_data1
   as select *
   from comp&freq..funda
   (keep=gvkey datadate indfmt popsrc consol datafmt fyear &comp_vars
    where=(&beg_yr-1 <= FYEAR <= &end_yr+1 and &comp_filter
          and curcd='USD' and fic='USA')) a left join crsp&freq..ccmxpf_linktable b
    on a.GVKEY = b.GVKEY
       and (b.LINKDT <= a.DATADATE or b.LINKDT = .B)
       and (a.DATADATE <= b.LINKENDDT or b.LINKENDDT = .E)
    and b.usedflag=1 and linkprim in ('P','C');

  /*Link in data on Post-Retirement Benefit Assets */
  /*needed for calculating book value of equity   */
  create view _comp_data2
   as select *
   from _comp_data1 a left join comp&freq..aco_pnfnda
   (keep=gvkey datadate indfmt popsrc consol datafmt PRBA
    where=(&comp_filter)) b
   on a.gvkey=b.gvkey and a.datadate=b.datadate;

  /*get the total annualized dividend rate for a company*/
  create view _dvrate
   as select a.gvkey, a.datadate, sum(dvrate) as dvrate
   from comp&freq..sec_mthdiv (where=(curcddvm='USD')) a
   group by a.gvkey, a.datadate;

  /*Link in data on Dividend Rate*/
  create view _comp_data3
   as select a.*,b.dvrate, intnx('month',a.datadate,3,'end') as public_date
   from _comp_data2 a left join _dvrate b
   on a.gvkey=b.gvkey and a.datadate=b.datadate;

  /*Link with CRSP data - we need month-end price and SIC code         */
  /*as Compustat Historical SIC is missing for many firm-year obs      */
  /*price needs to correspond to fundamentals, therefore, 3 month lead */
  create table _all_data (drop=&drop_vars)
   as select a.*, b.*, abs(prc)*shrout as mcap
   from _comp_data3 a left join _crsp_data b
   on a.lpermno=b.permno and put(a.public_date, yymmn6.)=put(b.date, yymmn6.);
  quit;
  proc printto;run;

  proc sort data=_all_data nodupkey; by gvkey datadate;run;

 /*NB: Book Value of Equity definition is from Daniel and Titman, Appendix A*/
 /*     "Market Reactions to Tangible and Intangible Information", JF 2006) */
 /*Ratio definitions are from the Compustat "Using the data" manual         */
  %put ;%put ### CALCULATING THE RATIOS AT THE FIRM LEVEL;
  proc printto log=junk;run;
  data home.&outset_firm; set _all_data;
   by gvkey datadate;
   lagfyear=lag(fyear);
   if first.gvkey then lagfyear=.;
   gap=fyear-lagfyear; * year gap between consecutive records;
  /*Shareholder's Equity*/
    if missing(seq)=0 then se=seq; else
    if missing(ceq)=0 and missing(pstk)=0 then se=sum(ceq,pstk); else
    if missing(at)=0 and missing(lt)=0 then se=sum(at,-lt); else se=.;
  /*Computing Book Value of Equity*/
    if missing(pstkrv)=0 then bv=sum(se,-pstkrv); else
    if missing(pstkl)=0 then bv=sum(se,-pstkl);else
    if missing(pstk)=0 then bv=sum(se,-pstk);else bv=.;
    bv=sum(bv,txditc,-prba);
    if bv<0 then bv=.;
    mcap=mcap/1000;
    rds=xrd/sale;  
    adjprc=abs(prc)/cfacpr;
  /*Current Valuation Ratios*/
    eps_exi=epspx/ajex; 
    eps_inci=epspi/ajex;
    ep=eps_exi/adjprc;  
    pe=adjprc/eps_exi;  
    ps=adjprc/(sale/(cshpri*ajex)); 
    if mcap ne 0 then bm=bv/mcap;else bm=.;
    dvy=dvrate/adjprc;                                        
    dpr=dvc/ibadj;                                           
  /*Profitability Ratios*/
    npm=ib/sale;                                             
    opmad=(oibdp-dp)/sale;                                   
    gpm=(sale-cogs)/sale;                                     
    ptpm=pi/sale;                                             
    cfm=(ibc+dpc)/sale;                                        
    roa=(ni+xint)/((at+lag(at))/2);                           
    ros=ni/((sale+lag(sale))/2);                               
    roe=ni/((bv+lag(bv))/2);                                   
    nwc=act-lct;                                              
  /*Activity Ratios*/
    inv_turn=sale/((invt+lag(invt))/2);                        
    at_turn=sale/((at+lag(at))/2);                             
    rect_turn=sale/((rect+lag(rect))/2);                      
    pay_turn=sale/((ap+lag(ap))/2);                            
    nwc_turn=sale/((nwc+lag(nwc))/2);                          
    cash_turn=sale/((che+lag(che))/2);                      
  /*Leverage Ratios*/
    der=dltt/mcap;                                            
    der1=(dltt+dlc)/mcap;                                     
    der2=dltt/bv;                                             
    der3=dltt/(act-lct);                                      
    oper_cf=(oibdp-txpd-((act-lct)-lag(act-lct)));            
    intcov=(xint-idit)/oper_cf;                              
  /*Liquidity Ratios*/
    curr_ratio=act/lct;                                      
    quick_ratio=(act-invt)/lct;                             
    cashr=che/lct;                                           
    invtonwc=invt/(act-lct);                                 
 
  if first.gvkey or gap ne 1 then do; 
    inv_turn=.;at_turn=.;rect_turn=.;
    pay_turn=.;nwc_turn=.;cash_turn=.;
    roa=.;roe=.;ros=.;oper_cf=.;
   end;

  if sich=0 then sich=.;if siccd=0 then siccd=.;
  label mcap='Market Value of Equity (mil.$)'
        eps_exi='EPS Excluding Extraordinary Items (Adjusted)'
        eps_inci='EPS Including Extraordinary Items (Adjusted)'
        rds='R&D Intensity'
        cfm='Cash Flow Margin'
        ep='Earnings Yield'
        pe='P/E Ratio'
        ps='Price/Sales Ratio'
        npm='Net (After-Tax) Profit Margin'
        opmad='Operating Profit Margin After Depreciation'
        gpm='Gross Profit Margin'
        ptpm='Pre-Tax Profit Margin'
        inv_turn='Inventory turnover'
        rect_turn='Receivables Turnover'
        pay_turn='Payables Turnover'
        at_turn='Total Asset Turnover'
        nwc_turn='Net Working Capital Turnover'
        cash_turn='Cash Turnover'
        cashr='Cash Ratio'
        invtonwc='Inventory to Net Working Capital'
        der='Long-Term Debt/Equty Ratio (Market Value of Equity)'
        der2='Long-Term Debt/Equity Ratio (Book Value of Equity)'
        der1='Financial Debt/Equty Ratio (Market Value of Equity)'
        der3='Debt/Net Working Capital Ratio'
        bm='Book/Market Ratio'
        roa='Return on Average Assets'
        roe='Return on Average (Book) Equity'
        ros='Return on Average Sales'
        intcov='Interest Coverage'
        curr_ratio='Current Ratio'
        quick_ratio='Quick Ratio (Acid Test)'
        dvy='Dividend Yield'
        dpr='Dividend Payout Ratio';
   if missing(sich)=0 then %FFI&nind(sich);
   if missing(ffi&nind)=1 and missing(siccd)=0 then %FFI&nind(siccd);
   ffi&nind._desc=upcase(ffi&nind._desc);
   keep &vars fyear sich siccd gvkey permno datadate ffi&nind ffi&nind._desc;
   run;
   proc printto;run;
   %put ### DONE!;

   proc sort data=home.&outset_firm nodupkey out=_temp;
    by fyear FFI&nind gvkey;
   run;

   /*Computing Mean/Median Statistics for Industries at the year end*/
  %put ;%put ### CALCULATING THE RATIOS FOR &NIND FAMA-FRENCH INDUSTRIES;
  proc printto log=junk;run;  
   proc means data=_temp noprint;
    by fyear FFI&nind;
    var &vars;id ffi&nind._desc;
    output out=_ind_ratios &avr=/autoname;
   run;
   proc sort data=_ind_ratios;
    by fyear ffi&nind._desc;
   run;
   proc transpose data=_ind_ratios out=home.&outset_ind;
    by fyear; id FFI&nind._desc;
	where &beg_yr<=fyear<=&end_yr;
   run;
  proc printto;run;
  %put ### DONE!;
    
   /*House Cleaning*/
  proc sql; 
    drop view _comp_data1, _comp_data2, _comp_data3, _dvrate;
    drop table _temp, _ind_ratios, _all_data, _crsp_data;
   quit;
  %put ;
  options errors=&errors &oldoptions;
  %put ### FIRM-LEVEL RATIOS IN &OUTSET_FIRM,INDUSTRY-LEVEL IN &OUTSET_IND;
%MEND INDRATIOS;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
