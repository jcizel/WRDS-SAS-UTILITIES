
/*http://listserv.uga.edu/cgi-bin/wa?A2=ind0410b&L=sas-l&F=P&S=&P=25822

%sortc

%put ***%sorted(list=


SG FJLKDSN GEWO OPITHUI GJSERO TNJEOWIJ TW9345Y TWES SDJGJSRL NWOITJN RET
POTREPOR _5TWT WPST NWP4 T924YW P9YTP9W4 NT599P DLKFGBLK SDGSGIW A AEG AEF
ZG
EGH A G HA HESH AIT4Y8W3 HAW T83PTQ3Y O OYTP53YT PQYP8Y3Q SSLKGH SLIEUH
AERH
DQLUEIUR SL SLSHIH4 AEK AH5WO TA AEH EU DJGLKDJ ERHISHKL QLR UHER GHSLHLSH
RBGHSD SLH SKEHRT RSKIEHB Q87O3WSL B SDKLQI WPE WEGIUQ HIHQPIG H QPGKLXK
ZLQA
HQP GTHQPG Z AOIRPH PGT3Q PGHSE QAPUR HPQYPQ A XC N SLKG PZEAF RQIUH RS H
T38753QO SL KG OW7TY OQ HSL QP YOQ287 _W7 TOQR TL DSLSD YSIUYG RISWYG
VQ369R4
ORA47Q3 Y94 Z Q374R R462QTQ
)***;



*/

%macro sorted(list=, maxItemLen=100);

  %local i item mvars;

  %do %while (1);
    %let i = %eval(&i.+1);
    %let item = %qscan(%superq(list),&i.);
    %let len  = %length(%superq(item));
    %if &len.=0 %then %goto out;
    %local SORTED_&i.;
    %let SORTED_&i. = &item.%qsysfunc(repeat(%str( ), &maxItemLen.-&len.-1));
    %if &i.=1 %then
      %let mvars = SORTED_1;
    %else
      %let mvars = &mvars., SORTED_&i.;
  %end;

  %out:
  %syscall sortc(&mvars.);

  %local r;
  %do i = 1 %to %eval(&i.-1);
    %let r = &r. &&SORTED_&i..;
  %end;

  %*;&r.

%mend;

