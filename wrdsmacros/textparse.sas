/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: TEXTPARSE                                                             */
/* Summary   : WRDS-SEC Filings Text Parser                                          */
/* Date      : August, 2010                                                          */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - LN: Parsed text/paragraph size around match text                    */
/*             - FNAME_FULL: Full Index of Target Filing Name                        */
/*             - TSTR: Text or Regular Expression used in string matching            */
/*             - LINE: Line number of Match                                          */
/*             - MATCH: Match number, 0 if no match in the entire filing             */
/*             - MATCH_TEXT: Cleaned Paragraph Extract around Matches                */
/* ********************************************************************************* */

%MACRO TEXTPARSE(INSET=, OUTSET=, FNAME_FULL=, TSTR=, LN=200);

%put ; %put ### START. TEXTParse Macro to Parse &LN. Characters around <&TSTR.>;
options nonotes;
/* Initialize Text Length */
%if &ln<200 %then %let ln=200;
/* Parse Data Step */
data &outset ;
set &inset ;
format LINE 6. Match 4. PREVLINE $100. TEXT MATCH_TEXT $&ln.. ;
retain TEXT PREVLINE MATCH_TEXT "" LINE MATCH 0;
infile datfiles filevar=&fname_full end=lastline;
 DO UNTIL(lastline);
  input;
  LINE+1;
  _infile_ = compbl(htmldecode(_infile_));
  call rxchange(" $<5> to '' ",99,_INFILE_);
  _infile_ =compress(_infile_,' -.,()$%','NK');
  TEXT = substrn(CATX(" ",TEXT,_INFILE_),max(lengthn(CATX(" ",TEXT,_INFILE_))-&ln.+1,1)); 
  if prxmatch("/&tstr./i",strip(PREVLINE)||" "||strip(_INFILE_)) then
  if prxmatch("/&tstr./i",PREVLINE)=0 then 
      do; 
          MATCH_TEXT =  strip(TEXT);
          MATCH+1; output; 
          MATCH_TEXT=""; 
      end;
  PREVLINE=_INFILE_;
 END;
/* Non Matches Output */
if lastline and MATCH=0 then output;
TEXT=""; PREVLINE=""; MATCH_TEXT=""; LINE=0; MATCH=0;
label Line ="Match Line Number (Match>0) or Total Lines in Filing (Match=0)";
label Match="Match Number per Filing";
label Match_Text = "Match Paragrah with &ln. Characters for '&tstr.' String";
drop text PREVLINE;
run;
options notes;
%put ### DONE . Parsing &tstr. . Dataset &outset Ready! ; %put;
%MEND TEXTPARSE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
