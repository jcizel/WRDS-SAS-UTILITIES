/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: FM                                                                    */
/* Summary   : Performs Fama-MacBeth Regressions. Calculates FM coefficients         */
/*	            with Newey-West adjusted standard errors                             */
/* Date      : Nov, 2010                                                             */
/* Author    : Denys Glushkov, WRDS                                                  */
/* Parameters:                                                                       */
/*             - INSET and OUTSET are input and output datasets                      */
/*             - DATEVAR: date variable in FM cross-sectional regressions            */
/*             - DEPVAR:  dependent variable in FM regressions(e.g.,average returns) */
/*             - INDVARS: list of independent variable separated by space            */
/*             - LAG:     number of lags to be used in the Newey-West adjustments    */
/* ********************************************************************************* */

 %MACRO FM (INSET=,OUTSET=,DATEVAR=,DEPVAR=, INDVARS=,LAG=);
/*save existing options*/
  %local oldoptions errors;
  %let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes))
                  %sysfunc(getoption(source));
  %let errors=%sysfunc(getoption(errors));
  options nonotes nomprint nosource errors=0;

    %put ### START;
    %put ### SORTING...PREPARE DATA FOR RUNNING FM REGRESSIONS;
      proc sort data=&inset out=_temp;
        by &datevar;
      run;

      %put ### RUNNING CROSS-SECTIONAL FM REGRESSIONS;
      proc printto log=junk;run;
      proc reg data=_temp outest=_results edf noprint;
        by &datevar;
        model &depvar=&indvars;
      run;
      proc printto;run;

    /*create a dummy dataset for appending the results of FM regressions*/
      data &outset; set _null_;
        format parameter $32. estimate best8. stderr d8. tvalue 7.2 probt pvalue6.4
         df best12. stderr_uncorr best12. tvalue_uncorr 7.2  probt_uncorr pvalue6.4;
         label stderr='Corrected standard error of FM coefficient';
         label tvalue='Corrected t-stat of FM coefficient';
         label probt='Corrected p-value of FM coefficient';
         label stderr_uncorr='Uncorrected standard error of FM coefficient';
         label tvalue_uncorr='Uncorrected t-stat of FM coefficient';
         label probt_uncorr='Uncorrected p-value of FM coefficient';
         label df='Degrees of Freedom';
       run;

      %put ### COMPUTING FAMA-MACBETH COEFFICIENTS...;
      %do k=1 %to %nwords(&indvars);
        %let var=%scan(&indvars,&k,%str(' '));

      /*1. Compute Fama-MacBeth coefficients as time-series means*/
 	   ods listing close;
        proc means data=_results n std t probt;
          var &var;
          ods output summary=_uncorr;
        run;

 		/*2. Perform Newey-West adjustment using Bart kernel in PROC MODEL*/
        proc model data=_results;
          instruments const;
          &var=const;
          fit &var/gmm kernel=(bart,%eval(&lag+1),0);
          ods output parameterestimates=_params;
        quit;
        ods listing;

      /*3. put the results together*/
        data _params (drop=&var._n);
          merge _params
                _uncorr (rename=(&var._stddev=stderr_uncorr
                                 &var._t=tvalue_uncorr
                                 &var._probt=probt_uncorr)
                         );
                 stderr_uncorr=stderr_uncorr/&var._n**0.5;
          parameter="&var";
          drop esttype;
         run;

         proc printto log=junk;run;
         proc append base=&outset data=_params force; run;
         proc printto;run;
      %end;

    /*house cleaning */
      proc sql; drop table _temp, _params, _results, _uncorr;quit;

  options &oldoptions errors=&errors;
   %put ### DONE ;
   %put ### OUTPUT IN THE DATASET &outset;
   %MEND;
   
 /* ********************************************************************************* */
 /* *************  Material Copyright Wharton Research Data Services  *************** */
 /* ****************************** All Rights Reserved ****************************** */
 /* ********************************************************************************* */
