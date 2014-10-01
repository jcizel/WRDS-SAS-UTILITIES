%macro range (
       to  =        /* end integer value */
     , from=1       /* starting integer value */
     , step=1       /* increment integer */
     , osep=%str( ) /* separator between integers */
     , opre=%str()  /* prefix for sequence of integers*/
     , osuf=%str()  /* suffix for sequence of integers*/
     ) ;

/*
return sequence of integers like 1 2 3 or
    strings ended with sequences of integers like data1 data2 data3
    starting at &FROM going to &TO in steps of &step

examples:
   %put %range(to=10);
   %put %range(to=10, opre=%str(data));
   %put %range(from=2,to=10,step=3,osep=%str(,));
   %put %range(from=2,to=10,step=3,osep=%str(,),osuf=%str(a));

   data a1;
	 a1=1;
   run;

   data a2;
	 a2=2;
   run;

   data a3;
	 a3=3;
   run;

	 data combine0;
	 	set a1-a3;
	run;

   %macro doit;
	   %let n=3;
	   data combine1;
		 set %do i=1 %to &n; a&i %end; ;
	   run;
   %mend;
   %doit
  
   %macro doit;
	   data combine2;
		 set %range(to=3,opre=%str(a));
	   run;
   %mend;
   %doit

	%macro doit;
		proc sql;                  
		  create table combine3 as    
		    select *      
		    from %range(to=3,osep=%str(,),opre=%str(a));
		quit;  
		%mend;
    %doit


	 %macro _list(n,pre=ds);
    %if &n=1 %then &pre.1;
     %else %_list(%eval(&n-1)),&pre.&n;
%mend _list;

%put %_list(10); 


Credit:
    source code from Ian Whitlock, Names, Names, Names - Make Me a List
               (SGF 2007)   http://www2.sas.com/proceedings/forum2007/052-2007.pdf
               (SESUG 2008) http://analytics.ncsu.edu/sesug/2008/SBC-128.pdf
    This snippet used a more efficient style from Chang Chung(http://changchung.com)
    Jiangtang Hu (2013, http://www.jiangtanghu.com):
        1)added two parameters (prefix/suffix) so it works more than generating sequence of integers
*/

 %local rg_i ;
 %do rg_i = &from %to &to %by &step ;
     %if &rg_i = &from %then
     %do;&opre.&rg_i.&osuf%end ;
     %else
     %do;&osep.&opre.&rg_i.&osuf%end ;
 %end ;
%mend range ;
