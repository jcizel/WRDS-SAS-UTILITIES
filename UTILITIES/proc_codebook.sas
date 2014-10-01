/*--------------------------------------------------------------------------------------------------------------
** Filename:  proc_codebook.sas
** Authors:   Kim Chantala (HBHE, UNC Chapel Hill)
**            Jim Terry (CPC, UNC Chapel Hill)
** Purpose:   Macro to create a CODE BOOK for SAS data sets. 
**
** Software:  SAS 9.2
**
** RECOMMENDED REQUIREMENTS FOR THE SAS FILE TO BE DOCUMENTED:
   1. Have labels on all variables
   2. Have user FORMATs assigned to all categorical variables
   3. Have a data set label on the SAS file
   4. By default, the codebook is ordered by Variable Name.  See the instructions in ORDERING VARIABLES to control
      order of variables are listed in codebook.

** ORDERING VARIABLES IN CODEBOOK
    Create a simple two variable file called work.order before you call the macro.  The first variable is
    NAME, a 32 character field with your variable name in UPPER CASE. The second variable is ORDER, a 
    numeric field with the order you want the  variables to print, 1 to N.  see the following example:

        data order;
        length name $ 32;
        name = "T1    "; ORDER = 1; OUTPUT;
        name = "HHID09"; ORDER = 2; OUTPUT;
        name = "LINE09"; ORDER = 3; OUTPUT;
        name = "H1D   "; ORDER = 4; OUTPUT;
        run;

** TITLES AND FOOTNOTES
   User Specified:  TITLE1, TITLE2 and all FOOTNOTES are specified by user.
   PROC_CODEBOOK Specified: 
		TITLE4 lists the number of observations in Data set.
        TITLE5 lists the number of variables in the data set. 
        TITLE6 lists the organization of the data set, with the ORGANIZATION specified in the 
               global macro variable ORGANIZATION;

** VARIABLES SPECIFIED ON MACRO 
   Required Variables: 
        LIB = name of library for SAS data set (see FILE1 variable) used to create the codebook
        FILE1 = name of SAS data set used to create the codebook
        FMTLIB = 2-level name of format library
        PDFFILE = name of PDF file for the codebook created
   Optional Variables: 
        INCLUDE_WARN= flag to control printing of WARNING messages in Codebook (in addition to LOG file)
                      YES=prints warnings in file specified by PDFILE (default), 
                      OTHER=warnings printed only in LOG file. 

** OTHER GLOBAL VARIABLES
   Optional Variables:
        ORGANIZATION = user supplied text describing the organization of the data set printed on title6;


** MODIFICATIONS: 
   2/5/2010 - Renamed macro to proc_codebook
            - Print out a Codebook Warning Messeges w/PROC PRINT after PROC REPORT, all in same PDF file
            - Left justified variable names
            - Changed 'rtffile' macro variable to 'pdffile'
            - Now blank out 'range' if n=0
  2/11/2010 - Look for a "work.order" file and if found, use it to sort the Code Book in that order, "work.order"
              has 2 variables, the variable name (NAME $ 32) in Upper Case and the numeric order (ORDER) to print the variable.
  2/17/2010 - Change the labels for type, length, format and N to shorter labels to help prevent line wrapping.
  2/23/2010 - If format =: "TIME" then MIN/MAX is formated using TIME5. in the RANGE
            - For Continous variables, moved "N" to "FREQUENCY", calculated PERCENT non-missing and Dropped "N" from the report.
  3/08/2010 - Dropped warning messages for flag variables, if FORMAT =: "FLAG" then do not issue warning msg.
  3/11/2010 - Corrected problem where variable names from proc freq were truncated to 21 characters 
            - Formated MEAN in REPORT output so that the mean  for variables with a MMDDYY format are displayed as a date.
            - Added a macro variable "include_warn" to make the WARNING report optional.  
  3/23/2010 - Modified REPORT proc step to use an input data set sorted with "sortseq=linguistic(numeric_collation=on)"
              so that character variables that had both numbers and letters would be printed order numerically as well as
              alphabetically.
  4/08/2010 - Added length statement for the MEAN_CHAR variable in the "ALL_DATA" data step so that the convertion of 
              numeric to character would not be truncated.
; 
--------------------------------------------------------------------------------------------------------------------*/
%macro proc_codebook(lib,file1,fmtlib,pdffile,include_warn=YES);

ods listing close;

** SECTION 2 - Get the PROC CONTENTS data;

proc contents data=&lib..&file1 noprint out=var_info(keep=name format type length nobs label memlabel crdate); run;

data var_info;  
set var_info;
name = left(upcase(name));

proc sort data=var_info out=file_formats (keep=format) nodupkey; by format;
run;

proc sort data=var_info (rename=(type=ntype)); by name;

** SECTION 1 - Get the PROC MEANS Data, N, MEAN, STD_DEV, MIN, and MAX;

ods output 'Summary Statistics'=means;

*** Execute PROC MEANS on the Longitudinal File, 
    it produces 1 long observation              ***;

proc means data=&lib..&file1;
run;
ods output close;
run;

*** Rewrite the PROC MEANS o/p file as 1 observation per variable ***;

data mean_results;
  set means;
length name $ 32 desc $ 50;	  
** ARRAY for Numeric Variables, N, MEAN, STD_DEV, MIN, and MAX **;
array x {*} _numeric_;   
** ARRAY for Character Variables, VARIABLE and LABEL **;     
array z {*} _character_;  
** Determine Number of Character and Numeric Variables **;    
cv = dim(z); nv = dim(x);
vars = (dim(z) / 2) - 1; * Substract Out the 2 Computed Variables, variable and label;
*if _n_ = 1 then put vars= cv nv;
** O/P 1 observation per variable per by group **;
do i = 1 to vars;
   if i = 1 then do; numeric = 1; alpha = 1; end;
   n = x(numeric); mean = x(numeric+1); std_dev = x(numeric+2); 
   min = x(numeric+3); max = x(numeric+4);
   name = z(alpha); desc = z(alpha+1);
   name=upcase(name);
   output;
   numeric = numeric + 5;
   alpha   = alpha + 2;
end;

keep name desc n mean std_dev min max;
run;
proc sort data=mean_results; by name;
run;

***** SECTION 2 - Get the PROC CONTENTS data ------------------------------------------------------****; 

proc contents data=&lib..&file1 noprint out=var_info(keep=name format type length nobs label memlabel crdate); run;

data var_info;    
set var_info;
name = upcase(name);
run;

proc sort data=var_info (rename=(type=ntype)); by name;
**** --------------------------------------------------------------------------------------------------------***/

** SECTION 3 - Merge the PROC MEANS and PROC CONTENTS results;
data var_merge (drop=desc);
  merge var_info (in=a) mean_results (in=b);
    by name;
length range $ 40 c_max c_min $ 12;     
if max - int(max) > 0 then max = round(max,.01);
if min - int(min) > 0 then min = round(min,.01);
c_max = put(max,9.2);
c_min = put(min,9.2);
range = compress(c_min||'-'||c_max);
if ntype = 1 then type = 'Num ';
if ntype = 2 then type = 'Char';
drop ntype c_max c_min;
run;

** SECTION 4 - Create macro variables with number of obs and variables for the 
               Codebook titles and make all variable names Upper Case, also
               create macro variables with the data set label and dataset
               creation date/time for use in the title;

data var_data (drop=nvars nobs memlabel crdate);
  set var_merge end=lastone;
retain nvars;
if _n_ = 1 then do;
  nvars = 0;
  * Following 3 items from PROC CONTENTS;
  call symputx('obs_cnt',put(nobs,8.0));
  call symputx('ds_label',memlabel);
  call symputx('ds_date',put(crdate,datetime16.)); 
end;
nvars+1;
name = compress(upcase(name));
if lastone = 1 then call symputx('var_cnt',put(nvars,6.0));
run;

** SECTION 5 - Create a macro variable list of all the variables that
               have a FORMAT (Frequencies will only be generated for
               numeric variables that have a format) and run PROC FREQ
               for those variables ;

proc format library=&fmtlib 
	cntlout=fmt_defs(keep=fmtname type start end label hlo eexcl sexcl 
					rename=(fmtname=format 
							type=fmt_type
							start=fmt_start
							end=fmt_end
                            label=desc
                            hlo=fmt_hlo
                            eexcl=fmt_end_excl
                            sexcl=fmt_start_excl
							));
run;

data fmt_defs_2;
  set fmt_defs;
length fmt_hold $ 33;
format=compress(upcase(format)); 
if fmt_type =: 'C' then do;
  fmt_hold = format;
  substr(format,1,1) = '$';
  substr(format,2,30) = fmt_hold;
end;
seq = _n_;

proc sort data=fmt_defs_2; by format seq;

data fmt_defs (drop=seq);
  merge file_formats (in=a) fmt_defs_2 (in=b);
    by format;
** Only KEEP Formats that appear in the file AND are in the USER FORMAT LIBRARY;
if a = 1 and b = 1 then;
  else delete;

* Create 2 data sets, one with format definitations and one with
  format ranges; 

data fmt_defs (drop=range frange) fmt_labels (keep=format desc frange) test_fmt_labels;  
   set fmt_defs;  
length range frange $ 40;  * 40 is max size of format value text;
if compress(fmt_start) = compress(fmt_end) then range = trim(left(fmt_start));   
if compress(fmt_start) ne compress(fmt_end) then do;    
  range = (trim(left(fmt_start))||'-'||trim(left(fmt_end)));    
end; 
frange = range;
run;

*** Use format definitions, fmt_defs, to identify categorical variables (NUM & CHAR) to pass to PROC FREQ ***;
* Sort the user formats from the user format library;
proc sort data=fmt_defs  out=user_formats (keep=format) nodupkey; by format;
*Sort the variable names by format, some variables will not have formats;
proc sort data=var_data (keep=name format) out=formatted_vars; by format;
* Only keep variables that have a user format;
data user_formatted_variables; 
  merge user_formats (in=a) formatted_vars (in=b); 
    by format;
if a=0 then delete;
* Create a macro variable that is a list of all variables with user formats;
proc sql noprint;
select name into :tlist separated by ' ' from user_formatted_variables where not missing(format);
quit;

ods output 'One-Way Frequencies'=freqs;
proc freq data=&lib..&file1; 
  table &tlist / missing;
run;
ods output close; run;

** SECTION 6 - Create a variable name based frequency file for 
               merging with the MEANS and CONTENTS data;

data freq_results;
  set freqs;
length desc $ 80 name $ 32;
** ARRAY for Character Variables, VARIABLE and LABEL **;     
array z {*} _character_;  
cv = dim(z); 
missed = 0; 
do i = 1 to cv;
  if not missing(z(i)) then missed+1;
end;
  
desc = '                                    ';
  do i = 2 to cv;	* The 1st Variable is the Table variable;
     if not missing(z(i)) then do; desc = z(i); i = cv; end;
  end;
cnt = _n_;   * This variable is used to keep everything in sort order;
* Extract the variable Name from the Table Variable;
substr(table,1,5) = '     ';
table = left(table);
name = upcase(table);
keep name desc frequency percent cnt ;
run;

** SECTION 7 - Merge the Frequencies with the MEANS and CONTENTS data;

proc sort data=freq_results; by name cnt;
proc sort data=var_data; by name;

data fmt_merge;
  merge var_data (in=a) freq_results (in=b);
   by name;

** SECTION 8 - Merge the Format Ranges, based on format and format label (desc),
               note Format Ranges will override the Min/Max range;

proc sort data=fmt_merge; by format desc;
proc sort data=fmt_labels; by format desc;

data ranges;
length desc $ 80;  
  merge fmt_labels (in=a) fmt_merge (in=b);
   by format desc;
if a = 1 and b = 1 then do;
   range = frange;
 *  put 'After' a= b= format= desc= range= frange=;
end;
drop frange;

proc sort data=ranges; by name format cnt;

** SECTION 8 - Initial prep for printing;

options nocenter mergenoby=error linesize=170 pagesize=40 ORIENTATION=LANDSCAPE nofmterr missing=" ";

data all_data (drop=warning) msgs (keep=warning name format desc);
  set ranges  end=lastone;
length warning $ 50;
length mean_char $ 15;

if format =: 'MMDDYY' then mean_char=put(int(mean),mmddyy8.);
   else if format =: 'TIME' then mean_char=put(int(mean),time5.);
      else mean_char=put(mean,best10.);
label mean_char='Mean';

if format =: 'MMDDYY' then do;
   substr(range,1,8) = put(min,mmddyy8.);
   substr(range,9,1) = "-";
   substr(range,10,8) = put(max,mmddyy8.);
end;
if format =: 'TIME' then do;
   range = ' ';
   substr(range,1,5) = put(min,time5.);
   substr(range,6,1) = "-";
   substr(range,7,5) = put(max,time5.);
end;
if n = 0 then range = " ";
if frequency = . then do;
  frequency = n;
  percent   = round(((n / &obs_cnt) * 100),.01);
end;
if _n_ = 1 then put "********************** WARNING MESSAGES ***********************";
if missing(name) then do; 
    warning = 'NO OCCURANCES FOR FORMAT CATEGORY: ';
    output msgs;
    put 'Warning: NO OCCURANCES FOR FORMAT CATEGORY: ' FORMAT= DESC=; 
    * If a Format Category does not occur in the data, then delete it, only
      categories with one or more occurances are listed;
    delete;
end;
if n = 0 then do;
    warning = 'All values are missing for: ';
    put 'Warning: All values are missing for: ' name=;
    output msgs;
end;
if min = max and n > 0 and format ne: "FLAG" then do;
    warning = 'All Non-Missing values are the same for: '; 
    put 'Warning: All Non-Missing values are the same for: ' name=;
    output msgs;
end;
output all_data;
if lastone = 1 then put "******************* END OF WARNING MESSAGES ********************";
label name      = 'Variable Name'
      label     = 'Variable Label (VAR)'
      type      = 'VAR Type'
      length    = 'VAR Length'
      n         = 'N'                 /* 'Non-Missing Numeric Values' */
      mean      = 'Mean'
      range     = 'Range of Values'
      desc      = 'Frequency Category'
      frequency = 'Frequency'
      percent   = 'Percent'
      format    = 'VAR Format';
run;


data all_data;  *TESTING THIS DATA STEP;
set all_data;
if compress(range) in ('-', '.-.') and not missing(desc) then do; 
	range=desc; 
	desc=' '; 
	end;
run;

** SECTION 9 -  Now print the codebook ---------------------;
proc template;
define style Styles.custom;
parent=Styles.RTF;
replace fonts /
'TitleFont' = ("Times Roman",10pt,Bold Italic) 
'TitleFont2' = ("Times Roman",10pt,Bold Italic) 
'StrongFont' = ("Times Roman",10pt,Bold)       
'EmphasisFont' = ("Times Roman",10pt,Italic)    
'headingEmphasisFont' = ("Times Roman",10pt,Bold Italic)
'headingFont' = ("Times Roman",10pt,Bold)
'docFont' = ("Times Roman",10pt) 
'footFont' = ("Times Roman",9pt) 
'FixedEmphasisFont' = ("Courier",9pt,Italic)
'FixedStrongFont' = ("Courier",9pt,Bold)
'FixedHeadingFont' = ("Courier",9pt,Bold)
'BatchFixedFont' = ("Courier",6.7pt)
'FixedFont' = ("Courier",9pt); 

replace Body from Document /
	bottommargin = 0.25in
	topmargin = 0.25in
	rightmargin = 0.25in
	leftmargin = 0.25in;

replace color_list /
	'link' = blue  /*links */
	'bgH' = white  /*row and column header background*/
	'fg' = black   /*text color*/
	'bg' = white;  /* page background color */

replace Table from Output/
	frame=hsides
	rules=groups /*all*/
	cellpadding=3pt
	cellspacing=0pt
	borderwidth=.75pt;
	end;
	run;

ods pdf file="&pdffile" style=custom;

proc sort data=all_data; by name format cnt; run;

%if %sysfunc(exist(work.order)) %then %do;
%put ORDER File Available;
proc sort data=order ; by name order;
data seq_data;
  merge order (in=a) all_data (in=b);
    by name;
if a = 0 then put "Order Missing " name=;
run;

proc sort data=seq_data sortseq=linguistic(numeric_collation=on) ; by order name format range; *cnt;
run;

data seq_data;  set seq_data; order_flag=_n_; run;
proc report data=seq_data nocenter nowindows headline wrap split='~'  missing
	style(header)=[color=black backgroundcolor=very light grey ]
	style(summary)=[color=very light grey backgroundcolor=very light grey fontfamily="Times Roman" fontsize=1pt textalign=r];;
	*style(summary)=[color=cx000000 backgroundcolor=cxD3D3D3 fontfamily="Times Roman" fontsize=10pt textalign=r];;
	*style(summary)={style="border-bottom:solid"]} ;
column order name label type format length mean_char order_flag range cnt desc frequency percent;  *fmt_start fmt_end ;
define order / group noprint;
define name / group width=20;
define label / group flow width=40 ;  
define type / group center width=4 ;
define length / group center width=4;
define mean_char / group center width=10;
define order_flag/ order noprint;
define range / group center width=20;
define format / group width=12;
define cnt / group noprint ;
define desc  / group order flow width=30;  
define frequency / analysis width=10;  *was group;
define percent / analysis width=8 ;    *was group;
break after name  /suppress skip;
break after name  /summarize suppress; * style={textdecoration=underline}; * suppress;
title3 "DATA SET: &file1     LABEL: &ds_label    DATE CREATED: &ds_date";
title4 "Number of Observations: &obs_cnt";
title5 "Number of Variables: &var_cnt";
title6 "Organization of file: &organization";
run;
%end;
%else %do;
%put ORDER File NOT Available;
proc sort sortseq=linguistic(numeric_collation=on) data=all_data ; by name format range;* cnt; run;	*<KIM ADDED;
data flagged_data; set all_data; order_flag=_n_; run;	
proc report data=flagged_data nocenter nowindows headline wrap split='~'  missing
	style(header)=[color=black backgroundcolor=very light grey ]
	style(summary)=[color=very light grey backgroundcolor=very light grey fontfamily="Times Roman" fontsize=1pt textalign=r];;
	*style(summary)=[color=cx000000 backgroundcolor=cxD3D3D3 fontfamily="Times Roman" fontsize=10pt textalign=r];;
	*style(summary)={style="border-bottom:solid"]} ;
column name label type format length mean_char order_flag range /*cnt*/ desc frequency percent;  *fmt_start fmt_end ;
define order_flag/ order noprint;
define name /group width=15;  /* was 15 */
define label /group flow width=40;   /* was 40 */
define type / group center width=4;
define length / group center width=4;
define mean_char / group center width=10;
define range / group center width=20 ;*order=data;	*was order center etc.;
define format /group width=12;
*define cnt / group noprint;
define desc  / group order flow width=30;  	 /* was 30 */
define frequency / analysis width=10;  *was 10;
define percent / analysis width=8 ;    *was 8;
break after name  /suppress skip;
break after name  /summarize suppress; * style={textdecoration=underline}; * suppress;
title3 "DATA SET: &file1     LABEL: &ds_label    DATE CREATED: &ds_date";
title4 "Number of Observations: &obs_cnt";
title5 "Number of Variables: &var_cnt";
title6 "Organization of file: &organization";
run;

%end;

title;
%if %upcase(&include_warn)=YES %then %do;
title Codebook Warning Messages;
proc print data=msgs label;
  var warning name format desc;
run;
%end;
ods pdf close;
run;
ods listing;   
title3 ' ';
%mend;
