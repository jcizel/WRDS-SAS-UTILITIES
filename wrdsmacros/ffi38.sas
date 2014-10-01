/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: FFI38                                                                 */
/* Summary   : Creates Fama & French 38 Industry Classification Variable             */
/* Date      : April 14, 2009                                                        */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - SIC_CODE: SIC 4-digit Industry Code                                 */
/* ********************************************************************************* */

%MACRO FFI38(sic_code);
do; format FFI38_desc $5.;
if missing(&SIC_Code) then FFI38=.;
 else if 0100<=&SIC_Code<=0999 then do; FFI38=1; FFI38_desc='Agric'; end;
 else if 1000<=&SIC_Code<=1299 then do; FFI38=2; FFI38_desc='Mines'; end;
 else if 1300<=&SIC_Code<=1399 then do; FFI38=3; FFI38_desc='Oil'; end;
 else if 1400<=&SIC_Code<=1499 then do; FFI38=4; FFI38_desc='Stone'; end;
 else if 1500<=&SIC_Code<=1799 then do; FFI38=5; FFI38_desc='Cnstr'; end;
 else if 2000<=&SIC_Code<=2099 then do; FFI38=6; FFI38_desc='Food'; end;
 else if 2100<=&SIC_Code<=2199 then do; FFI38=7; FFI38_desc='Smoke'; end;
 else if 2200<=&SIC_Code<=2299 then do; FFI38=8; FFI38_desc='Txtls'; end;
 else if 2300<=&SIC_Code<=2399 then do; FFI38=9; FFI38_desc='Apprl'; end;
 else if 2400<=&SIC_Code<=2499 then do; FFI38=10; FFI38_desc='Wood'; end;
 else if 2500<=&SIC_Code<=2599 then do; FFI38=11; FFI38_desc='Chair'; end;
 else if 2600<=&SIC_Code<=2661 then do; FFI38=12; FFI38_desc='Paper'; end;
 else if 2700<=&SIC_Code<=2799 then do; FFI38=13; FFI38_desc='Print'; end;
 else if 2800<=&SIC_Code<=2899 then do; FFI38=14; FFI38_desc='Chems'; end;
 else if 2900<=&SIC_Code<=2999 then do; FFI38=15; FFI38_desc='Ptrlm'; end;
 else if 3000<=&SIC_Code<=3099 then do; FFI38=16; FFI38_desc='Rubbr'; end;
 else if 3100<=&SIC_Code<=3199 then do; FFI38=17; FFI38_desc='Lethr'; end;
 else if 3200<=&SIC_Code<=3299 then do; FFI38=18; FFI38_desc='Glass'; end;
 else if 3300<=&SIC_Code<=3399 then do; FFI38=19; FFI38_desc='Metal'; end;
 else if 3400<=&SIC_Code<=3499 then do; FFI38=20; FFI38_desc='MtlPr'; end;
 else if 3500<=&SIC_Code<=3599 then do; FFI38=21; FFI38_desc='Machn'; end;
 else if 3600<=&SIC_Code<=3699 then do; FFI38=22; FFI38_desc='Elctr'; end;
 else if 3700<=&SIC_Code<=3799 then do; FFI38=23; FFI38_desc='Cars'; end;
 else if 3800<=&SIC_Code<=3879 then do; FFI38=24; FFI38_desc='Instr'; end;
 else if 3900<=&SIC_Code<=3999 then do; FFI38=25; FFI38_desc='Manuf'; end;
 else if 4000<=&SIC_Code<=4799 then do; FFI38=26; FFI38_desc='Trans'; end;
 else if 4800<=&SIC_Code<=4829 then do; FFI38=27; FFI38_desc='Phone'; end;
 else if 4830<=&SIC_Code<=4899 then do; FFI38=28; FFI38_desc='TV'; end;
 else if 4900<=&SIC_Code<=4949 then do; FFI38=29; FFI38_desc='Utils'; end;
 else if 4950<=&SIC_Code<=4959 then do; FFI38=30; FFI38_desc='Garbg'; end;
 else if 4960<=&SIC_Code<=4969 then do; FFI38=31; FFI38_desc='Steam'; end;
 else if 4970<=&SIC_Code<=4979 then do; FFI38=32; FFI38_desc='Water'; end;
 else if 5000<=&SIC_Code<=5199 then do; FFI38=33; FFI38_desc='Whlsl'; end;
 else if 5200<=&SIC_Code<=5999 then do; FFI38=34; FFI38_desc='Rtail'; end;
 else if 6000<=&SIC_Code<=6999 then do; FFI38=35; FFI38_desc='Money'; end;
 else if 7000<=&SIC_Code<=8999 then do; FFI38=36; FFI38_desc='Srvc'; end;
 else if 9000<=&SIC_Code<=9999 then do; FFI38=37; FFI38_desc='Govt'; end;
 else do; FFI38=38; FFI38_desc='Other'; end;
label FFI38 ="Fama and French 38 Industries";
label FFI38_desc ="Fama and French 38 Industries - Description";
end;

%MEND FFI38;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
