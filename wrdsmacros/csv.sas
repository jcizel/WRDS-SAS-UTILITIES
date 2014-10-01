/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: WINSORIZE                                                             */
/* Summary   : Exports a SAS dataset Into an Excel or CSV file                       */
/* Date      : April 14, 2009                                                        */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - EXCEL: export option 1. Excel spreadsheet, 0. CSV file (default)    */
/* ********************************************************************************* */

%MACRO CSV(INSET=,OUTSET=&INSET.,EXCEL=0);

/* Exporting the SAS dataset into Excel Spreadsheet */
options nosource nonotes;
%if &excel=1 %then 
 %do;
  filename _temp_ "&outset..xls";
  ods noresults; ods listing close;
  ods chtml file=_temp_ rs=none;
  proc print data=&inset. noobs; run;
  ods chtml close;
  ods results;
  ods listing;
  filename _temp_;
  %put ### Excel spreadsheet &outset..xls Generated; %put ;
 %end;
/* Exporting the SAS dataset into csv file / comma delimited */
%else 
%do;
  proc export data=&inset. outfile="&outset..csv" dbms=csv replace; run;
  %put ### CSV file &outset..csv Generated;	%put ;
%end;
options source notes;

%MEND CSV;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
