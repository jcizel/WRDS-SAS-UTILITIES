/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: PARAPARSE                                                             */
/* Summary   : WRDS-SEC Paragraph Parser, from a text string                         */
/* Date      : August, 2010                                                          */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - FNAME_FULL: Full Index of Target Filing Name                        */
/*             - TSTR: Text or Regular Expression used in string matching            */
/*             - NLINE: # of Lines before and after the Match to be Extracted        */
/* ********************************************************************************* */

%MACRO PARAPARSE(INSET=, OUTSET=, FNAME_FULL=, TSTR=, NLINE=);

%put ; %put ### START. PARAParse Macro to Parse &NLINE Lines around <&tstr.> ;
options nonotes;
/* Parse Data Step */
%put ## Step 1: Finding Matches for <&tstr.> ;
data _step1; format FNAME3 $100. ;
set &inset;
FNAME3=strip(&fname_full.);
format LINE 6. Match 6. Text Match_Text $100.;
retain LINE Match 0 Text Match_Text "";
infile datfiles filevar=&fname_full end=lastline;
 DO UNTIL(lastline);
  input;
  LINE+1;
  _infile_ = htmldecode(_infile_);
  call rxchange(" $<5> to '' ",99,_INFILE_);
  _infile_ =compress(_infile_,' -.,()$%','NK');
  if prxmatch("/&tstr./i",strip(TEXT)||" "||strip(_INFILE_)) then
  if prxmatch("/&tstr./i",TEXT)=0 then 
        do; 
          MATCH_TEXT = _INFILE_;
          MATCH+1; output; MATCH_TEXT=""; 
        end;
  TEXT=_INFILE_;
 END;
/* Non Matches Output */
if lastline and MATCH=0 then output;
LINE=0; MATCH=0; TEXT=""; MATCH_TEXT="";
label Line ="Match Line Number (Match>0) or Total Lines in Filing (Match=0)";
label Match="Match Number per Filing";
label Match_Text = "Match Text Line for '&tstr.' String";
drop TEXT;
run;
proc sort data=_step1; by Match fname3; run;
%put ## Step 2: Getting &NLINE. Lines Before and After Text;
%LINEPARAParse(INSET=_STEP1,OUTSET=&outset,FNAME_FULL=FNAME3,LINE=Line,NLINE=&NLINE)
proc sort data=&outset; by iname Match; run;
/* House Cleaning */
proc sql; drop table _step1; quit;
options notes;
%put ### DONE . Dataset &outset Ready! ; %put;

%MEND PARAPARSE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
