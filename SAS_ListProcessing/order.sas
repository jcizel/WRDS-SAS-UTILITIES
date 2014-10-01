/*http://listserv.uga.edu/cgi-bin/wa?A2=ind0410b&L=sas-l&F=P&S=&P=16933 Roland

%let listx=  bbb  nnnn eer rr rt  x x v  zz aaaaaa  gggg    j;

%put  %order(&listx) ;
*/


%macro order(str);
  %local swap words i list newlist scana scanb len lena lenb endpos;
  %let list=%sysfunc(compbl(%sysfunc(trim(%sysfunc(left(&str))))));
  %let words=%length(&list)-%length(%sysfunc(compress(&list,%str())))+1;
  %let len=%length(&list);
  %let swap=1;
  %do %while(&swap);
    %let swap=0;
    %do i=1 %to %eval(&words-1);
      %let scana=%scan(&list,&i,%str( ));
      %let scanb=%scan(&list,%eval(&i+1),%str( ));
      %let lena=%length(&scana);
      %let lenb=%length(&scanb);
      %if "&scana" GT "&scanb" %then %do;
        %let swap=1;
        %let newlist=;
        %let pos=%index(&list,&scana &scanb);
        %if &pos gt 1 %then %let newlist=%substr(&list,1,%eval(&pos-1));
        %let newlist=%left(&newlist &scanb &scana);
        %let endpos=%eval(&pos+&lena+&lenb);
        %if &endpos LT &len 
          %then %let newlist=%sysfunc(left(&newlist%substr(&list,%eval(&endpos+1))));
        %let list=&newlist;
      %end;
    %end;
  %end;
  &list
%mend;

