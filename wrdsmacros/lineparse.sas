/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: LINEPARSE                                                             */
/* Summary   : WRDS-SEC Line-by-Line Parser, Preserving Tabular Format               */
/* Date      : August, 2010                                                          */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - FNAME_FULL: Full Index of Target Filing Name                        */
/*             - TSTR: Text or Regular Expression used in string matching            */
/*             - LINE: Line number of Match                                          */
/*             - MATCH: Match number, 0 if no match in the entire filing             */
/*             - MATCH_TEXT: Cleaned Paragraph Extract around Matches                */
/* ********************************************************************************* */

%MACRO LINEPARSE(INSET=, OUTSET=, FNAME_FULL=, TSTR=);

%put ; %put ### START. LINEParse Macro to Parse Text Lines with <&tstr.> ;
options nonotes;
%let ln=250;
/* Parse Data Step */
data &outset;
set &inset;
format LINE 6. Match 6. Text Match_Text $&ln..;
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
options notes;
%put ### DONE . Dataset &outset Ready! ; %put;

%MEND LINEPARSE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
