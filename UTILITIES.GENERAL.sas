/*====================================================================================\
|                               UTILITIES                                             |
|                                                                                     |
|  sas -nodms -noterminal                                                             |
|                                                                                     |
|  LOAD THE UTILITIES FILE ON THE SERVER:                                             |
|                                                                                     |
|  rsync -avR --progress --stats --human-readable                                     |
|                                   /Users/jankocizel/Documents/Dropbox/Projects/PhD\ |
|                                   Thesis/SAS/* wrds-cloud:~/UTILITIES/              |
\====================================================================================*/
*rsync -avR --progress --stats --human-readable  /Users/jankocizel/Documents/Dropbox/Projects/PhD\ Thesis/SAS/* wrds-cloud:~/UTILITIES/

options source nocenter ls=80 ps=max;


    /*=========================================================================\
    | PRODUCE A SUMMARY OF ALL DATASETS IN A LIBRARY                           |
    \=========================================================================*/
%MACRO DOCLIST(LIBRARY);
    /* DECLARE MACRO VARIABLES                                                */
    %LOCAL I NDATASET;

    /* GET LIST OF DATASETS IN A LIBRARY                                      */
    ODS LISTING CLOSE;
    ODS OUTPUT MEMBERS = DATASETLIST;

    PROC DATASETS MT=DATA LIBRARY = &LIBRARY;
    RUN;
    QUIT;

    ODS LISTING;

    TITLE3 "DATASETS IN LIBRARY &LIBRARY";

    PROC PRINT
        DATA = DATASETLIST(DROP=MEMTYPE)
        LABEL NOOBS;
        FORMAT FILE_SIZE COMMA20.;
    RUN;

     /* GET TOTAL NUMBER OF DATASETS IN A MACRO VARIABLE */

    DATA _NULL_;
        IF 0 THEN SET DATASETLIST
            NOBS = NOBS;
        CALL SYMPUT('NDATASET',NOBS);
    RUN;

    /* DECLARE DATA SET MACRO VARIABLES LOCAL                                 */
    %DO I=1 %TO &NDATASET;
        %LOCAL DATASET&I;
        %END;

    /* PUT DATA SET NAMES INTO MACRO VARIABLES                                */
    DATA _NULL_;
        SET DATASETLIST;
        CALL SYMPUT
            ('DATASET'||LEFT(_N_),NAME);
    RUN;

    /* LOOP THROUGH EACH DATASET                                              */
    %DO I=1 %TO &NDATASET;
        TITLE3 "STRUCTURE OF DATA SET &&DATASET&I";

        PROC CONTENTS
            DATA = &LIBRARY..&&DATASET&I
            OUT = &&DATASET&I
            /* DETAILS */
            VARNUM;
        RUN;

        /* PROC EXPORT DBMS=CSV DATA=&&DATASET&I  */
        /*     OUTFILE="/scratch/uvanl/LOOKUP.%trim(&&DATASET&I..).CSV"  */
        /*     REPLACE;  */
        /* RUN;  */
        
        /* TITLE3 "PARTIAL LISTING OF DATA SET &DATASET&I"; */
        /* PROC PRINT */
        /*     DATA = &LIBRARY..&&DATASET&I(OBS=5); */
        /* RUN; */

        %END;

    /* CLEAN-UP                                                               */
        TITLE3;
        PROC DATASETS NOLIST LIBRARY = WORK;
            DELETE DATASETLIST;
    RUN;
    QUIT;

    %MEND;

/* /\*=============================================================================\ */
/* | TEST THE ABOVE MACRO                                                         | */
/* \=============================================================================*\/ */
/* LIBNAME CIQ "/wrds/capitaliq/sasdata/capstructure"; */

/* ODS PDF FILE = "/scratch/uvanl/CIQ.CAPITALSTRUCTURE.DESCR.pdf"; */
/* %DOCLIST(CIQ); */
/* ODS PDF CLOSE; */

/* ODS PDF FILE = "/scratch/uvanl/SASHELP.DESCR.pdf"; */
/* %DOCLIST(SASHELP); */
/* ODS PDF CLOSE; */


    /*=========================================================================\
    | EXPORT ALL DATASETS IN A LIBRARY                                         |
    \=========================================================================*/
%MACRO CONVERT2CSV(LIBNAME,TARGETDIR);
    DATA MEMBERS;
        SET SASHELP.VMEMBER(WHERE=(LIBNAME = "&LIBNAME"));
        RETAIN OBS 0;
        OBS = OBS+1;
        KEEP MEMNAME OBS;
    RUN;
    PROC SQL;
        SELECT MIN(OBS) INTO :MIN
            FROM MEMBERS;
    QUIT;
    PROC SQL;
        SELECT MAX(OBS) INTO :MAX
            FROM MEMBERS;
    QUIT;
    %Local D;
    %DO D = &MIN %TO &MAX;
        PROC SQL;
            SELECT COMPRESS(MEMNAME) INTO: TABLE
                FROM MEMBERS
                WHERE OBS=&D;
        QUIT;

        %LET TABLE = &TABLE;
        
        PROC EXPORT DBMS=CSV DATA=&LIBNAME..&TABLE
            OUTFILE="&TARGETDIR./&TABLE..CSV"
            REPLACE;
        RUN;
        %END;
    %MEND;


/*=============================================================================\
| EXPORT TO EXCEL                                                              |
\=============================================================================*/

%MACRO DOCLIST2EXCEL(LIBRARY,FILE);
    /* DECLARE MACRO VARIABLES                                                */
    %LOCAL I NDATASET;

    /* GET LIST OF DATASETS IN A LIBRARY                                      */
    ODS LISTING CLOSE;
    ODS OUTPUT MEMBERS = DATASETLIST;

    PROC DATASETS MT=DATA LIBRARY = &LIBRARY;
    RUN;
    QUIT;

    ODS LISTING;

    TITLE3 "DATASETS IN LIBRARY &LIBRARY";

    PROC PRINT
        DATA = DATASETLIST(DROP=MEMTYPE)
        LABEL NOOBS;
        FORMAT FILE_SIZE COMMA20.;
    RUN;

     /* GET TOTAL NUMBER OF DATASETS IN A MACRO VARIABLE */

    DATA _NULL_;
        IF 0 THEN SET DATASETLIST
            NOBS = NOBS;
        CALL SYMPUT('NDATASET',NOBS);
    RUN;

    /* DECLARE DATA SET MACRO VARIABLES LOCAL                                 */
    %DO I=1 %TO &NDATASET;
        %LOCAL DATASET&I;
        %END;

    /* PUT DATA SET NAMES INTO MACRO VARIABLES                                */
    DATA _NULL_;
        SET DATASETLIST;
        CALL SYMPUT
            ('DATASET'||LEFT(_N_),NAME);
    RUN;

    /* LOOP THROUGH EACH DATASET                                              */
    %DO I=1 %TO &NDATASET;
        TITLE3 "STRUCTURE OF DATA SET &&DATASET&I";

        PROC CONTENTS
            DATA = &LIBRARY..&&DATASET&I
            OUT = &&DATASET&I
            /* DETAILS */
            VARNUM;
        RUN;
                
        PROC EXPORT DBMS=XLS DATA=&&DATASET&I                              
            OUTFILE=&FILE       
            REPLACE;
            SHEET = %trim(&&DATASET&I..);            
        RUN;                                                               
        
        /* TITLE3 "PARTIAL LISTING OF DATA SET &DATASET&I"; */
        /* PROC PRINT */
        /*     DATA = &LIBRARY..&&DATASET&I(OBS=5); */
        /* RUN; */

        %END;

    /* CLEAN-UP                                                               */
        TITLE3;
        PROC DATASETS NOLIST LIBRARY = WORK;
            DELETE DATASETLIST;
    RUN;
    QUIT;

    %MEND;


