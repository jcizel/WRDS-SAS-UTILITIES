/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: TRADE_DATE_WINDOWS                                                    */
/* Summary   : Using a trading date calendar file (either daily or monthly), create  */
/*             a dataset of trading date "windows". dataset will contain one record  */ 
/*             per window, with three variables: BEG_DATE, END_DATE,and WINDOW_SIZE).*/
/*             All windows will be entirely within the range of the calendar file.   */
/* Date      : September 22, 2009                                                    */
/* Version:   1.0                                                                    */  
/* Author    : Mark Keintz, WRDS                                                     */
/* Variables : -                                                                     */
/*             -                                                                     */
/* ***********************************************************************************/

%macro trade_date_windows(freq=m,size=60,minsize=,outdsn=temp,help=no) 
  /des="Create a dataset of DATE windows";

  %if %lowcase(&help)=yes %then %do;
  
/**************************************************************************************/
/*                                                                                    */
/* Parameters:                                                                        */
/*   FREQ:    Calendar File Frequency: either m for monthly, or d                     */
/*            for daily.  Default is m.                                               */
/*                                                                                    */
/*    SIZE:    Length (in months or days) of desired window. Default                  */
/*             is 60.  If no windows of user-requested SIZE can be                    */
/*             generated from the calendar file (in the event it is                   */
/*             too "short") then SIZE is adjusted to the maximum size                 */
/*             supportable by the calendar file, as long as the                       */
/*             adjusted size is at least as large as MINSIZE (see                     */
/*             below).  If windows of size MINSIZE are not possible                   */
/*             then the adjusted SIZE is set to 0, which will be a                    */
/*             signal to prevent craation of the windows dataset.                     */
/*                                                                                    */
/*    MINSIZE: Minimum acceptable window size.  This is relevant when                 */
/*             a candidate window start date (variable BEG_DATE) is                   */
/*             so near to the end of the calendar file that the                       */
/*             longest possible window is shorter than SIZE.  MINSIZE                 */
/*             allows the user to specify the shortest acceptable                     */
/*             window.  MINSIZE defaults to the value of SIZE.                        */
/*                                                                                    */
/*    OUTDSN:  Name of the resulting trading-date-window dataset.                     */
/*                                                                                    */
/*  Other local macrovars:                                                            */
/*    FRQTEXT  Calendar File Frequency, in text form (e.g. "Month"                    */
/*             instead of "M").                                                       */
/*                                                                                    */
/*  Dependencies:                                                                     */
/*       No other WRDS macros are used by this macro.                                 */
/*                                                                                    */
/*  Usage:                                                                            */
/*                                                                                    */
/* %nrstr(%%)trade_date_windows(freq=d,size=180,minsize=120,outdsn=mylib.cal)%str(;)  */
/*                                                                                    */
/*     The macro call above reads the CRSP dsi dataset, and creates                   */
/*     a dataset (mylib.cal) of date ranges, each range covering 181                  */
/*     trading dates, except those near the end of the calendar,                      */
/*     which will cover as few as 121 trading dates.                                  */
/*                                                                                    */
/*  Other Notes:                                                                      */
/*    Future developments: Establish a calendar file with trading                     */
/*    dates for a variety of exchanges.  This will allow use of an                    */
/*    additional parameter (say "exchange") providing the user with                   */
/*    trading date windows specific to a giving trading exchange.                     */
/*                                                                                    */
/**************************************************************************************/

    %goto endmac; 
  %end;

  %let freq=%lowcase(&freq);
  %if       &freq=m %then %let frqtext=Months;
  %else %if &freq=d %then %let frqtext=Days;

  %** Initialize MINSIZE, if neccessary **;
  %if %length(&minsize)=0 %then %let minsize=&size;

  %** First make sure the calendar file is long enough to accomodate at least 
      one window >= MINSIZE.  This step may reset SIZE to a smallr number, or
      to 0 (no acceptable windows are possible) **;
  data _null_;
    set crsp.&freq.si nobs=ndates;  ** NDATES gets number of dates in this calendar **;
    max_possible_size=ndates - 1;   ** Max possible windows size this calendar    **;
      if max_possible_size >= &size then ;  ** No adjustment to SIZE needed         **;
      else do;
        if max_possible_size < &minsize then do;  ** No acceptable window possible  **;
          put '** ****************************************************** **' /
            "** Largest trading-date window size in crsp.&freq.si is " max_possible_size  @59 '**' /
            "** which is smaller than the user-requested MINSIZE (&minsize.)." @59 '**' /
            '** THEREFORE NO TRADING-DATE WINDOWS WILL BE GENERATED.   **' /
            '** ****************************************************** **' /;
        call symput ('size','0');  ** Reset SIZE to zero to skip window-building **;
      end;
      else do;   ** &minsize <= max_possible_size < &size **;
        put '** ****************************************************** **' /
            "** Largest trading-date window size in crsp.&freq.si is " max_possible_size  @59 '**' /
            "** which is smaller than the user-requested SIZE (&size.)." @59 '**' /
            "** ONLY TRADING-DATE WINDOWS BETWEEN SIZE &MINSIZE (MINSIZE)"  @59 '**'/
            '** AND ' max_possible_size 'WILL BE GENERATED. '@59 '**' /
            '** ****************************************************** **' /;
        call symput ('size',left(put(max_possible_size,5.)));
      end;
    end;
    stop;
  run;

  %if &size ^= 0 %then %do;    %* If any acceptable windows possible, generate the dataset **;
    data &outdsn (drop=_end_date label="Trading Windows in &frqtext. - size &minsize to &size");
      retain beg_date end_date ;
      retain window_size &size  _end_date;

      %** In this merge statement, the second dataset allows looking ahead to end-of-window **;
      merge crsp.&freq.si (keep=date rename=(date=beg_date))
            crsp.&freq.si (keep=date firstobs=%eval(1+&size) rename=(date=end_date))
            ;

      if end_date ^= . then window_size=&size;
      else window_size=window_size-1;

      end_date=max(end_date,_end_date);
      _end_date=end_date;
      if window_size >= &minsize;

      label beg_date    = "Beginning Date of this trading window"
            end_date    = "Ending Date of this trading window"
            window_size = "Size of this window in Trading &frqtext"
            ;
    run;
  %end;  %*of %if &size ^= 0 %then %do;

%endmac: %mend trade_date_windows ;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */

