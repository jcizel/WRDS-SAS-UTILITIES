
/*
%put %get_label(sashelp.iris,SepalLength);
*/

%macro get_label(data,variable);
	%local label;  
   	%let dsid = %sysfunc(open(&data));
  	%if &dsid %then %do;
         %let label=%sysfunc(varlabel(&dsid,%sysfunc(varnum(&dsid,&variable))));
         %let rc = %sysfunc(close(&dsid));		
   	%end;
    &label;
%mend;  


