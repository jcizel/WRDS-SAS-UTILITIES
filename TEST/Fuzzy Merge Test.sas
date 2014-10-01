OPTIONS SASAUTOS=('/wrds/wrdsmacros/', SASAUTOS) MAUTOSOURCE SOURCE NOCENTER LS=80 PS=MAX;
%INCLUDE "~/UTILITIES/UTILITIES.GENERAL.sas";


LIBNAME HOME "/scratch/uvanl";

LIBNAME AMA_L "/wrds/bvd/sasdata/ama_l";
LIBNAME AMA_S "/wrds/bvd/sasdata/ama_s";
LIBNAME AMA_M "/wrds/bvd/sasdata/ama_m";
LIBNAME AMA_V "/wrds/bvd/sasdata/ama_v";

LIBNAME BVD (AMA_L AMA_M AMA_V AMA_S);


LIBNAME COMPG "/wrds/comp/sasdata/global";

PROC SQL OUTOBS = 100;
    CREATE TABLE MERGE AS
        SELECT
        A.IDNR, A.SD_ISIN, A.SD_SEDOL, A.SD_TICKER, A.NAME, A.ADDRESS, A.ZIPCODE, A.CITY, A.COUNTRY, A.CNTRYCDE,
        B.*

        FROM
        BVD.AMADEUS_V AS A,
        COMPG.G_NAMESQ AS B;
        
RUN;
QUIT;

proc print data=merge; run;
