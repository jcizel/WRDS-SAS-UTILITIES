/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: FFI12                                                                 */
/* Summary   : Creates Fama & French 12 Industry Classification Variable             */
/* Date      : April 14, 2009                                                        */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - SIC_CODE: SIC 4-digit Industry Code                                 */
/* ********************************************************************************* */

%MACRO FFI12(sic_code);
do; format FFI12_desc $5.;
if missing(&SIC_Code) then FFI12=.;
 else if 0100<=&SIC_Code<=0999 then do; FFI12=1; FFI12_desc='NoDur'; end;
 else if 2000<=&SIC_Code<=2399 then do; FFI12=1; FFI12_desc='NoDur'; end;
 else if 2700<=&SIC_Code<=2749 then do; FFI12=1; FFI12_desc='NoDur'; end;
 else if 2770<=&SIC_Code<=2799 then do; FFI12=1; FFI12_desc='NoDur'; end;
 else if 3100<=&SIC_Code<=3199 then do; FFI12=1; FFI12_desc='NoDur'; end;
 else if 3940<=&SIC_Code<=3989 then do; FFI12=1; FFI12_desc='NoDur'; end;
 else if 2500<=&SIC_Code<=2519 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 2590<=&SIC_Code<=2599 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 3630<=&SIC_Code<=3659 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 3710<=&SIC_Code<=3711 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 3714<=&SIC_Code<=3714 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 3716<=&SIC_Code<=3716 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 3750<=&SIC_Code<=3751 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 3792<=&SIC_Code<=3792 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 3900<=&SIC_Code<=3939 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 3990<=&SIC_Code<=3999 then do; FFI12=2; FFI12_desc='Durbl'; end;
 else if 2520<=&SIC_Code<=2589 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 2600<=&SIC_Code<=2699 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 2750<=&SIC_Code<=2769 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3000<=&SIC_Code<=3099 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3200<=&SIC_Code<=3569 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3580<=&SIC_Code<=3629 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3700<=&SIC_Code<=3709 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3712<=&SIC_Code<=3713 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3715<=&SIC_Code<=3715 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3717<=&SIC_Code<=3749 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3752<=&SIC_Code<=3791 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3793<=&SIC_Code<=3799 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3830<=&SIC_Code<=3839 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 3860<=&SIC_Code<=3899 then do; FFI12=3; FFI12_desc='Manuf'; end;
 else if 1200<=&SIC_Code<=1399 then do; FFI12=4; FFI12_desc='Enrgy'; end;
 else if 2900<=&SIC_Code<=2999 then do; FFI12=4; FFI12_desc='Enrgy'; end;
 else if 2800<=&SIC_Code<=2829 then do; FFI12=5; FFI12_desc='Chems'; end;
 else if 2840<=&SIC_Code<=2899 then do; FFI12=5; FFI12_desc='Chems'; end;
 else if 3570<=&SIC_Code<=3579 then do; FFI12=6; FFI12_desc='BusEq'; end;
 else if 3660<=&SIC_Code<=3692 then do; FFI12=6; FFI12_desc='BusEq'; end;
 else if 3694<=&SIC_Code<=3699 then do; FFI12=6; FFI12_desc='BusEq'; end;
 else if 3810<=&SIC_Code<=3829 then do; FFI12=6; FFI12_desc='BusEq'; end;
 else if 7370<=&SIC_Code<=7379 then do; FFI12=6; FFI12_desc='BusEq'; end;
 else if 4800<=&SIC_Code<=4899 then do; FFI12=7; FFI12_desc='Telcm'; end;
 else if 4900<=&SIC_Code<=4949 then do; FFI12=8; FFI12_desc='Utils'; end;
 else if 5000<=&SIC_Code<=5999 then do; FFI12=9; FFI12_desc='Shops'; end;
 else if 7200<=&SIC_Code<=7299 then do; FFI12=9; FFI12_desc='Shops'; end;
 else if 7600<=&SIC_Code<=7699 then do; FFI12=9; FFI12_desc='Shops'; end;
 else if 2830<=&SIC_Code<=2839 then do; FFI12=10; FFI12_desc='Hlth'; end;
 else if 3693<=&SIC_Code<=3693 then do; FFI12=10; FFI12_desc='Hlth'; end;
 else if 3840<=&SIC_Code<=3859 then do; FFI12=10; FFI12_desc='Hlth'; end;
 else if 8000<=&SIC_Code<=8099 then do; FFI12=10; FFI12_desc='Hlth'; end;
 else if 6000<=&SIC_Code<=6999 then do; FFI12=11; FFI12_desc='Money'; end;
 else do; FFI12=12; FFI12_desc='Other'; end;
label FFI12 ="Fama and French 12 Industries";
label FFI12_desc ="Fama and French 12 Industries - Description";
end;

%MEND FFI12;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
