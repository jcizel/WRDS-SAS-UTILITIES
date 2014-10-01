%macro roc(version, data=, var=, response=, contrast=, details=no,
           alpha=.05);

%let _version=1.7;
%if &version ne %then %put ROC macro Version &_version;

%let opts = %sysfunc(getoption(notes))
            _last_=%sysfunc(getoption(_last_));
options nonotes;

/* Check for newer version */
 %if %sysevalf(&sysver >= 8.2) %then %do;
  filename _ver url 'http://ftp.sas.com/techsup/download/stat/versions.dat' termstr=crlf;
  data _null_;
    infile _ver;
    input name:$15. ver;
    if upcase(name)="&sysmacroname" then call symput("_newver",ver);
    run;
  %if &syserr ne 0 %then
    %put ROC: Unable to check for newer version;
  %else %if %sysevalf(&_newver > &_version) %then %do;
    %put ROC: A newer version of the ROC macro is available.;
    %put %str(         ) You can get the newer version at this location:;
    %put %str(         ) http://support.sas.com/ctx/samples/index.jsp;
  %end;
 %end;

title "The ROC Macro";
title2 " ";

%let error=0;

/* Verify that DATA= option is specified */
%if &data= %then %do;
    %put ERROR: Specify DATA= containing the OUT= data sets of models to be compared;
    %goto exit;
%end;

/* Verify that VAR= option is specified */
%if &var= %then %do;
    %put ERROR: Specify predictor or XBETA variables in the VAR= argument;
    %goto exit;
%end;

/* Verify that RESPONSE= option is specified */
%if &response= %then %do;
    %put ERROR: Specify response variable in the RESPONSE= argument;
    %goto exit;
%end;

%let i=1;
%do %while (%scan(&data,&i) ne %str() );
  %let data&i=%scan(&data,&i);
  %let i=%eval(&i+1);
%end;
%let ndata=%eval(&i-1);

data _comp(keep = &var &response);
 %if &data=%str() or &ndata=1 %then set;
 %else merge;
  &data;
  if &response not in (0,1) then call symput('error',1);
  run;
%if &error=1 %then %do;
  %put ERROR: Response must have values 0 or 1 only.;
  %goto exit;
%end;

/* Original SAS/IML code from author follows */
proc iml;
   start mwcomp(psi,z);
    *;
    * program to compute the mann-whitney components  ;
    * z is (nn by 2);
    *  z[,1] is the column of data values;
    *  z[,2] is the column of indicator variables;
    *   z[i,2]=1 if the observation is from the x population;
    *   z[i,2]=0 if the observation is from the y population;
    *
    * psi is the returned vector of u-statistic components;

    rz  = ranktie( z[,1] );                        * average ranks;
    nx  = sum( z[,2] );                            * num. of Xs  ;
    ny  = nrow(z)-nx;                              * num of Ys   ;
    loc = loc( z[,2]=1 );                          * x indexes   ;
    psi = j(nrow(z),1,0);
    psi[loc] = (rz[loc] - ranktie(z[loc,1]))/ny;   * x components ;
    loc = loc( z[,2]=0 );                          * y indexes    ;
    psi[loc] = ( nx+ranktie(z[loc,1])-rz[loc])/nx; * y components ;
    free rz loc nx ny;                             * free space   ;
   finish;

   start mwvar(t,v,nx,ny,z);
    *;
    * compute mann-whitney statistics and variance;
    * input z, n by (k+1);
    *  z[,1:k] are the different variables;
    *  z[,k+1] are indicator values,
    *    1 if the observation is from population x and ;
    *    0 if the observation is from population y;
    * t is the k by k vector of estimated statistics;
    *  the (i,j) entry is the MannWhitney statistic for the
    *  i-th column when used with the j-th column. The only
    *  observations with nonmissing values in each column are
    *  used. The diagonal elements are, hence, based only on the
    *  single column of values.
    * v is the k by k estimated variance matrix;
    * nx is the matrix of x population counts on a pairwise basis;
    * ny is the matrix of y population counts on a pairwise basis;

    k   = ncol(z)-1;
    ind = z[,k+1];
    v   = j(k,k,0); t=v; nx=v; ny=v;

    * The following computes components after pairwise deletion of
    *  observations with missing values. If either there are no missing
    *  values or it is desired to use the components without doing
    *  pairwise deletion first, the nested do loops could be evaded.
    *;
    do i=1 to k;
      do j=1 to i;
         who = loc( (z[,i]^=.)#(z[,j]^=.) );    * nonmissing pairs;
         run mwcomp(psii,(z[,i]||ind)[who,]);   * components;
         run mwcomp(psij,(z[,j]||ind)[who,]);
         inow = ind[who,];                      * Xs and Ys;
         m = inow[+];                           * current Xs;
         n = nrow(psii)-m;                      * current Ys;
         nx[i,j] = m; ny[i,j] = n;
         mi = (psii#inow)[+] / m;               * means;
         mj = (psij#inow)[+] / m;
         t[i,j] = mi; t[j,i] = mj;
         psii = psii-mi; psij = psij-mj;        * center;
         v[i,j] = (psii#psij#inow)[+]     / (m#(m-1))
                + (psii#psij#(1-inow))[+] / (n#(n-1));
         v[j,i] = v[i,j];
      end;
    end;
    free psii psij inow ind who;
   finish;

   /* start of execution of the IML program */
   use _comp var {&var &response};
   read all into data [colname=names];
   run mwvar(t,v,nx,ny,data);                 * estimates and variances;
   vname = names[1:(ncol(names)-1)];
   manwhit = vecdiag(t);

   /* omit: 0 for intercept-only model; not needed for further
      computations
   c=sqrt( vecdiag(v) );  c=v / (c@c`);
   %if %upcase(%substr(&details,1,1)) ne N %then %do;
    print c [label='Estimated Correlations' colname=vname rowname=vname];
   %end;
   */

 %if &contrast= %then %do;
  %put ROC: No contrast specified.  Pairwise contrasts of all;
  %put %str(    ) curves will be generated.;
   call symput('col',char(ncol(data)-1));
  %if &col=1 %then %str(l=1;); %else %do;
   l=(j(&col-1,1)||-i(&col-1))
    %do i=&col-2 %to 1 %by -1;
        //(j(&i,&col-&i-1,0)||j(&i,1)||-i(&i))
    %end;
   ;
   %end;
   call symput('maxrow',char(comb(max(nrow(l),2),2)));
 %end;
 %else %do;
   l = { &contrast };
   call symput('maxrow',char(nrow(l)));
 %end;

   lt=l*manwhit;
   lv=l*v*l`;
   c = ginv(lv);
   chisq = lt`*c*lt;
   df = trace(c*lv);
   p = 1 - probchi( chisq, df );
/* Original SAS/IML code by author ends */

   /* Individual area stderrs and CIs */
   stderr=sqrt(vecdiag(v));
   arealcl=manwhit-probit(1-&alpha/2)*stderr;
   areaucl=manwhit+probit(1-&alpha/2)*stderr;
   areastab=putn(manwhit||stderr||arealcl||areaucl,'7.4');

   /* Pairwise difference stderrs and CIs */
   sediff=sqrt(vecdiag(lv));
   difflcl=lt-probit(1-&alpha/2)*sediff;
   diffucl=lt+probit(1-&alpha/2)*sediff;
   diffchi=(lt##2)/vecdiag(lv);
   diffp=1-probchi(diffchi,1);

  %if %upcase(%substr(&details,1,1)) ne N %then %do;
   print t [label='Pairwise Deletion Mann-Whitney Statistics' colname=vname
   rowname=vname];
  %end;

   print areastab [label=
   "ROC Curve Areas and %sysevalf(100*(1-&alpha))% Confidence Intervals"
   rowname=vname colname={'ROC Area' 'Std Error' 'Confidence' 'Limits'}];

   rname='Row1':"Row&maxrow";
%if %upcase(%substr(&details,1,1)) ne N %then %do;
   print v [label='Estimated Variance Matrix' colname=vname rowname=vname];
   print nx [label='X populations sample sizes' colname=vname rowname=vname];
   print ny [label='Y populations sample sizes' colname=vname rowname=vname];
   print lv [label='Variance Estimates of Contrast' rowname=rname
             colname=rname];
  %end;
   print l [label='Contrast Coefficients' rowname=rname colname=vname];

   fdiffchi=putn(diffchi,'9.4');
   fdiffp=putn(diffp,'pvalue.');
   diffs=putn(lt||sediff||difflcl||diffucl,'7.4');
   diffstab=diffs||fdiffchi||fdiffp;
   print diffstab [label=
   "Tests and %sysevalf(100*(1-&alpha))% Confidence Intervals for Contrast Rows"
   rowname=rname colname={'Estimate' 'Std Error' 'Confidence' 'Limits'
   'Chi-square' 'Pr > ChiSq'}];

   c2=putn(chisq,'9.4');
   df2=putn(df,'3.');
   p2=putn(p,'pvalue.');
   ctest=c2||df2||p2;
   print ctest [label='Contrast Test Results'
         colname={'Chi-Square' '  DF' 'Pr > ChiSq'}];

   /* Make overall p-value available */
   %global pvalue;
   call symput('pvalue',p2);

quit;

%exit:
options &opts;
title; title2;
%mend;

