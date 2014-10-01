/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: FFI5                                                                  */
/* Summary   : Creates Fama & French 5 Industry Classification Variable              */
/* Date      : April 14, 2009                                                        */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - SIC_CODE: SIC 4-digit Industry Code                                 */
/* ********************************************************************************* */

%MACRO FFI5(sic_code);
do; format FFI5_desc $5.;
if missing(&SIC_Code) then FFI5=.;
 else if 0100<=&SIC_Code<=0999 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 2000<=&SIC_Code<=2399 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 2700<=&SIC_Code<=2749 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 2770<=&SIC_Code<=2799 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3100<=&SIC_Code<=3199 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3940<=&SIC_Code<=3989 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 2500<=&SIC_Code<=2519 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 2590<=&SIC_Code<=2599 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3630<=&SIC_Code<=3659 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3710<=&SIC_Code<=3711 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3714<=&SIC_Code<=3714 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3716<=&SIC_Code<=3716 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3750<=&SIC_Code<=3751 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3792<=&SIC_Code<=3792 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3900<=&SIC_Code<=3939 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 3990<=&SIC_Code<=3999 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 5000<=&SIC_Code<=5999 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 7200<=&SIC_Code<=7299 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 7600<=&SIC_Code<=7699 then do; FFI5=1; FFI5_desc='Cnsmr'; end;
 else if 2520<=&SIC_Code<=2589 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 2600<=&SIC_Code<=2699 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 2750<=&SIC_Code<=2769 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 2800<=&SIC_Code<=2829 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 2840<=&SIC_Code<=2899 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3000<=&SIC_Code<=3099 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3200<=&SIC_Code<=3569 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3580<=&SIC_Code<=3621 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3623<=&SIC_Code<=3629 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3700<=&SIC_Code<=3709 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3712<=&SIC_Code<=3713 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3715<=&SIC_Code<=3715 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3717<=&SIC_Code<=3749 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3752<=&SIC_Code<=3791 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3793<=&SIC_Code<=3799 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3860<=&SIC_Code<=3899 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 1200<=&SIC_Code<=1399 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 2900<=&SIC_Code<=2999 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 4900<=&SIC_Code<=4949 then do; FFI5=2; FFI5_desc='Manuf'; end;
 else if 3570<=&SIC_Code<=3579 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 3622<=&SIC_Code<=3622 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 3660<=&SIC_Code<=3692 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 3694<=&SIC_Code<=3699 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 3810<=&SIC_Code<=3839 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7370<=&SIC_Code<=7372 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7373<=&SIC_Code<=7373 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7374<=&SIC_Code<=7374 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7375<=&SIC_Code<=7375 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7376<=&SIC_Code<=7376 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7377<=&SIC_Code<=7377 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7378<=&SIC_Code<=7378 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7379<=&SIC_Code<=7379 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 7391<=&SIC_Code<=7391 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 8730<=&SIC_Code<=8734 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 4800<=&SIC_Code<=4899 then do; FFI5=3; FFI5_desc='HiTec'; end;
 else if 2830<=&SIC_Code<=2839 then do; FFI5=4; FFI5_desc='Hlth'; end;
 else if 3693<=&SIC_Code<=3693 then do; FFI5=4; FFI5_desc='Hlth'; end;
 else if 3840<=&SIC_Code<=3859 then do; FFI5=4; FFI5_desc='Hlth'; end;
 else if 8000<=&SIC_Code<=8099 then do; FFI5=4; FFI5_desc='Hlth'; end;
 else do; FFI5=5; FFI5_desc='Other'; end;
label FFI5 ="Fama and French 5 Industries";
label FFI5_desc ="Fama and French 5 Industries - Description";
end;

%MEND FFI5;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
