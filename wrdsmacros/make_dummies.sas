/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: MAKE_DUMMIES                                                          */
/* Summary   :                                                                       */
/* Date      :                                                                       */  
/* Author    : Mark Keintz, WRDS                                                     */
/* Variables : -                                                                     */
/*             -                                                                     */
/* ***********************************************************************************/

%macro make_dummies(indsn=_last_,var=name,outdsn=,help=no,cleanup=yes)
  /Des="Make a series of dummy variables representing each distinct value of user-specified variable";

  %local vrs;
  %let vrs=1.0;  %** Initial version of this macro **;

  %if %upcase(&help)=YES %then %do;
  
    /* *******************************************************************************/
    /*   MAKE_DUMMIES                                                                */
    /*                                                                               */
    /*   Version &vrs                                                                */
    /*                                                                               */
    /*   PURPOSE:                                                                    */
    /*   From a user specified dataset, make a copy with a series of                 */
    /*   dummy variables added, where each new dummy variable                        */
    /*   corresponds to a distinct value of a user-specified variable                */
    /*   in the input dataset.                                                       */
    /*                                                                               */
    /*   For example, if the variable NAME took on 4 values (e.g.                    */
    /*   "smith", "jones", "white", "johnson"), in the input dataset                 */
    /*   then 4 dummy variables (NAME_DUM1, NAME_DUM2,NAME_DUM3,                     */
    /*   NAME_DUM4) will be added to output dataset  There also will be              */
    /*   a "dummy pointer" variable (NAME_DNUM) - see note below).                   */
    /*                                                                               */
    /*   (Secondary Purpose): Make a "lookup" dataset mapping each                   */
    /*   unique value of the variable to an index between 1 and K (where             */
    /*   K is the number of unique values of the incoming variable).                 */
    /*                                                                               */
    /*   PARAMETERS:                                                                 */
    /*   All parameters take the "name=value" format.                                */
    /*                                                                               */
    /*   INDSN= (Optional, default=_last_).  Name of the dataset                     */
    /*     to use as input to the process.  If the INDSN parameter is                */
    /*     not specified by the user, then the most-recently-created                 */
    /*     dataset (in the current SAS session) will be used.                        */
    /*                                                                               */
    /*   VAR= (Optional, default=name).  Name of the variable in                     */
    /*     INDSN for which dummy variables will be generated in                      */
    /*     OUTDSN (see below).                                                       */
    /*                                                                               */
    /*   OUTDSN= (Optional, default=blank).  Name of the dataset                     */
    /*     to generate. It will include all variables in INDSN                       */
    /*     plus K new dummy variables (where K is the number of                      */
    /*     unique values of VAR in INDSN), plus one other variable                   */
    /*     identifying which dummy variable is associated with                       */
    /*     the current value of VAR.  If OUTDSN is blank, then the                   */
    /*     standard SAS practice of generating DATA1, then DATA2, etc.               */
    /*     will be applied.                                                          */
    /*                                                                               */
    /*     If OUTDSN=_NULL_ then an output dataset is NOT created.  You              */
    /*     might use this with CLEANUP=no (see below) which will                     */
    /*     generated a lookup dataset.  So if you wanted only the lookup             */
    /*     dataset, then use OUTDSN=_NULL_ with CLEANUP=no.                          */
    /*                                                                               */
    /*   CLEANUP= (Optional, default=yes).  If no, then do NOT delete                */
    /*     the intermediate data view and dataset used to generate                   */
    /*     OUTDSN.  In particular, the dataset __XXXX_lookup (where XXXX             */
    /*     is the VAR name) shows the mapping between each value of XXXX             */
    /*     and a pointer to the corresponding dummy variable. Otherwise              */
    /*     the intermediate dataset and dataview are deleted.                        */
    /*                                                                               */
    /*     You might want to use CLEANUP=no if you want to generated a               */
    /*     "lookup" dataset linking each value of VAR with a unique                  */
    /*     consecutive integer.                                                      */
    /*                                                                               */
    /*   Notes on the new variables in the output dataset:                           */
    /*     If the name of VAR is XXXX, then                                          */
    /*     The dummy variables:                                                      */
    /*      - Will be named XXXX_DUM1, XXXX_DUM2, XXXX_DUM3, ...                     */
    /*          XXXX_DUMK (where K is number of distinct values of XXXX).            */
    /*      - Will have length 3.                                                    */
    /*      - Will have a label of the form  'Dummy for NAME="jones"'                */
    /*     The dummy pointer variable:                                               */
    /*      - Will be named XXXX_DNUM                                                */
    /*      - Will have values 1,2,3,...,K                                           */
    /*      - Will have length 3                                                     */
    /*                                                                               */
    /*  OTHER NOTES:                                                                 */
    /*    MAKE_DUMMIES works with both character and numeric variables.              */
    /*                                                                               */
    /*  OTHER LOCAL MACROVARS                                                        */
    /*    LABEL_LIST:  Contains all the label assignments for the newly-             */
    /*    created dummy variables.                                                   */
    /*                                                                               */
    /*  DEPENDENCIES:                                                                */
    /*    No dependencies on any WRDS macros.                                        */
    /*                                                                               */
    /*  HISTORY:                                                                     */
    /*    Version 1.0:  (11/11/2009)  First Version.                                 */
    /*                                                                               */
    /* *******************************************************************************/
    
	%goto done;
  %end;

  %let var=%upcase(&var);

  proc sql noprint;
    /* Generate list of all UNIQUE values of &var, in ascending order            */
    create view  __&var._list as select distinct &var from &indsn order by &var;

    /* Put list above into a lookup table, first var mapped to 1, 2nd to 2, etc. */
    create table __&var._lookup as select &var
       , monotonic() as &var._DNUM length=3 label="Dummy Number for this value of &var"
       from __&var._list;

    /* Generate a set of variable labels for the dummy variables                */
    select cats("&var._DUM",&var._dnum,'= "Dummy for ""',&var,'"""')
       into : label_list separated by ' ' 
       from __&var._lookup;
  quit;

  %if %upcase(&outdsn) ^= _NULL_ %then %do;
    data &outdsn;
      /* Before declaring the hash table, get all the variables into the PDV */
      if 0 then set &indsn __&var._lookup;

      declare hash lookup (dataset:"__&var._lookup");
        lookup.definekey("&var");
        lookup.definedata("&var._dnum");
        lookup.definedone();

      array &var._DUM {&sqlobs} 3 ;
      retain &var._DUM: 0 ;

      label 
        &label_list
        ;

      do until (end_of_data);
        set &indsn end=end_of_data;

        /* Fetch correct value of &var._DNUM */
        lookup.find();

        /* Set the indicated dummy to 1 and output the record */
        &var._dum{&var._dnum}=1;
        output;

        /* Reset the indicated dummy to 0 */
        &var._dum{&var._dnum}=0;
      end;

    run;
  %end;

  /* Now do housekeeping, clean up the no-longer needed dataset and dataview */

  proc datasets library=work nolist;
    delete __&var._list /mt=view ;
    %if %upcase(&cleanup)=YES %then delete __&var._lookup;;
  quit;
%done: 
%mend make_dummies;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
