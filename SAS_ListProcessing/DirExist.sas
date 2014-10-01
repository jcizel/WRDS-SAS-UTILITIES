%macro DirExist(dir) ; 
   %sysfunc(filename(fileref,&dir)) 
%mend DirExist;