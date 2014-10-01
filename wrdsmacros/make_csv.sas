%macro make_csv(dsn=_LAST_,outcsv=mydata.csv,header_recs=NL,vars=_ALL_,datefmt=yymmddn8.) 
   / minoperator
     des="Make a CSV file from a SAS dataset, with optional header lines";

  /* -------------------------- MAKE_CSV ----------------------------------------- */
  /* PURPOSE:    From a user-specified data set (either a data set FILE or a data  */
  /*             set VIEW), make a CSV file, with user-specified variables, and    */
  /*             optional variables NAMES and/or LABELS as the first line(s).      */
  /*                                                                               */
  /* PARAMETERS: (defaults in parentheses).                                        */
  /*             All parameters take "name=value" format.  Because they all have   */
  /*             defaults, they are all optional.                                  */
  /*                                                                               */
  /*  DSN           Name of the SAS data set to process, can be a two-level name   */
  /*  (_LAST_)      or one-level name.                                             */
  /*                                                                               */
  /*  OUTCSV        Name of the CSV file to create.  It can include directory path */
  /*  (mydata.csv)  if needed.                                                     */
  /*                                                                               */
  /*  HEADER_RECS   Specifies which header lines to write (if any) , and in what   */
  /*  (NL)          order.  Possible values are:                                   */
  /*                   NL  = varNAMEs in line 1, varLABELS in line 2               */
  /*                   LN  = varLABELs in line 1, varNAMES in line 2               */
  /*                   N   = varNAMES only, in line 1                              */
  /*                   L   = varLABLES only, in line 1                             */
  /*                   _   = No header lines                                       */
  /*                                                                               */
  /*  VARS          List of variables to write to CSV.  Either provide a space-    */
  /*  (_ALL_)       separated list of var names, or one of the SAS keywords        */
  /*                 _ALL_, _NUMERIC_, or _CHARACTER_                              */
  /*                                                                               */
  /*  DATEFMT       Format to use for all apparent data variables (i.e. all vars   */
  /*  (yymmddn8.)   that already have one of the common  data-related formats).    */
  /*                To leave all such variables  with their formats unchanged, use */
  /*                "DATEFMT=_".                                                   */
  /*                                                                               */
  /* DEPENDENCIES:  No dependencies on any WRDS macros                             */
  /*                                                                               */
  /* OTHER NOTES:   The MINOPERATOR option says to enable the macro IN operator    */
  /*                (e.g. the symbol # or keyword IN) during parsing of the macro. */
  /*                                                                               */
  /*                Only the most common date formats are used in the "format like"*/
  /*                Others can trivially be added.                                 */
  /*                                                                               */
  /* HISTORY:         Version 1.0  (06/27/2014)                                    */
  /*                                                                               */
  /* ----------------------------------------------------------------------------- */

  /* Preliminaries --------------------------------------------------------------- */

  /* If DSN=_LAST_, then find the actual DSN value before _LAST_ gets reset ------ */
  %if %upcase(&dsn)=_LAST_ %then %let dsn=%sysfunc(getoption(_LAST_));

  /* Determine N_HEADERS, the number of header records --------------------------- */
  %let header_recs=%upcase(&header_recs);
  %if &header_recs  # N L NL LN %then %let n_headers=%length(&header_recs) ;
  %else %let n_headers=0;
 
  /* Step 1: make template data set (no data, but all metadata on requested vars)  */
  data _temp0;
    set &dsn (keep=&vars);
    stop;
  run;

  /* Step 2: Put a list of all the likely DATE variables into macrovar DATEVARS    */
  %if &datefmt=_ %then %let n_datevars=0;      /* Number of date vars to reformat  */
  %else %do;
    proc sql noprint ;
      select name into :datevars separated by ' '
      from dictionary.columns
      where memname='_TEMP0' and libname='WORK' and
           (format like 'DATE%' or 
            format like 'DDMMYY%' or
            format like 'MMDDYY%' or
            format like 'YYMMDD%') ;
    quit;
    %let n_datevars=&sqlobs ;  /* SQLOBS is N of "rows" created by SELECT statement*/
  %end; 

  /* Step 3: for each header type, write a one-line CSV with corresponding metadata*/
  %if &n_headers ^= 0 %then %do I=1 %to &n_headers;
    %let header_type=%substr(&header_recs,&I,1) ;       /* i.e. header_type=N or L */

    filename _tmeta&I   temp;
	proc export data=_temp0 (obs=0) dbms=dlm outfile=_tmeta&I 
	  %if &header_type=L %then %str(label) ;
	  ;
	  delimiter=',';
    run;
  %end; 

  /* Step 4: Process the data ---------------------------------------------------- */ 
  data _null_; 
    file "&outcsv" dsd dlm=","; 

    if _n_=1 then do;
      %if &n_headers > 0 %then %do I=1 %to &n_headers;
        infile _tmeta&i;
        input;
        put _infile_ ;
      %end;
    end;

    set &dsn (keep=&vars);
    %if &n_datevars > 0 %then %str(format &datevars &datefmt ;) ;
    put (_all_) (:) ;
  run;

%mend make_csv;
