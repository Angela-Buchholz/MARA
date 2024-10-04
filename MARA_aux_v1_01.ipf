
//======================================================================================================================================================================================
//	MARA_Aux_v1_01 is part of the MARA software. 
//	Copyright (C) 2024 Angela Buchholz 
//
//	This file is part of MARA.
//
//	MARA is a free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation,
//	either version 3 of the License, or any later version.
//
//	MARA is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//	See the GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License along with MARA. If not, see <https://www.gnu.org/licenses/>. 
//======================================================================================================================================================================================


#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


//======================================================================================
//======================================================================================

// Purpose:	check if all waves in a stringlist do exist (data folder is not changed)
// Input:		nameList	: stringlist with wavenames
// 				
// Output :	returns 1 if all waves exist
//				returns 0 if at least one wave does not exist 
//				returns -1 if something was wrong
//				NonExistIdx	wave with numbers of non existing waves

FUNCTION/D MARAaux_CheckWavesFromList(NameList)

String NameList

Variable check =-1	// return value

// check if string contains a list

Variable ii
Make/FREE/N=(itemsinlist(Namelist)) temp=nan

FOR (ii=0;ii<itemsinlist(NameList);ii+=1)
	IF(!waveexists($stringfromlist(ii,namelist)))	// wave does NOT exists
		check=0
		temp[ii]=ii	// store index number
	ENDIF

ENDFOR
// remove empty entries
Wavetransform zapnans temp
IF (numpnts(temp)==0)	// no entries=all waves exist
	check=1
ELSE
	Make/O/D/N=(numpnts(temp)) NonExistIdx=temp
ENDIF

RETURN check

END


//======================================================================================
//======================================================================================

// Purpose:	check if all SVAR or NVAR in a stringlist do exist (data folder is not changed)
// Input:		nameList	: stringlist with wavenames
// 				
// Output :	returns 1 if all waves exist
//				returns 0 if at least one wave does not exist 
//				returns -1 if something was wrong
//				NonExistIdx	wave with numbers of non existing waves

FUNCTION/D MARAaux_CheckVARFromList(NameList)

String NameList

Variable check =-1	// return value

// check if string contains a list

Variable ii
Make/FREE/N=(itemsinlist(Namelist)) temp=nan


FOR (ii=0;ii<itemsinlist(NameList);ii+=1)

	NVAR/Z DummyNVar=$stringfromlist(ii,namelist)
	
	IF(!NVAR_Exists(DummyNVar))	// no numeric variable exists
		
		// try if it is a string variable
		SVAR/Z DummySVar=$stringfromlist(ii,namelist)
		
		IF (!SVAR_exists(DummySVAR))
			check=0
			temp[ii]=ii	// store index number
		ENDIF
		
	ENDIF

ENDFOR
// remove empty entries
Wavetransform zapnans temp
IF (numpnts(temp)==0)	// no entries=all waves exist
	check=1
ELSE
	Make/O/D/N=(numpnts(temp)) NonExistIdx=temp
ENDIF



RETURN check

END

//======================================================================================
//======================================================================================

// Purpose:	like normal abort but check abortStr for length first
//				IF abortStr is too long -> print to history window instead
//				
// Input:		abortStr:	String with message for abort
//				
// Output:	either abort popup with message OR simple abort message and print to history

FUNCTION MARAaux_abort(abortStr)

String abortStr

String alertStr=""

// maximum length of string for abort popup
Variable MaxLength=254	// max length for Igor 7
IF (Igorversion()>=8.00)
	MaxLength=1023	// max length for Igor 8
ENDIF

//check abort String length
IF (Strlen(abortStr)>maxLength)
	// too long -> print to history
	
	// create simple alertStr: using \r\r to identify calling procedure
	alertStr=StringfromList(0,abortSTr,"\r\r")
	alertStr+="\r\r!Problem detected - aborting! Check History window for details."

	// print to history
	abortStr=replacestring("\r\r",abortStr,"\r")	// remove empty lines
	print "-----------------"
	print abortStr
	print "-----------------"
	
ELSE
	alertStr=abortStr
ENDIF

// display dialog with OK button
DoAlert 0,alertStr

// and abort
Abort

END

//======================================================================================
//======================================================================================

// Purpose:	converts date-time string to Igor julian seconds

// Input:		timeString: 	strng with dat-time stamps
//				format:		string defining the input format of the timeString
//								supported formats:
//									"dd.mm.yyyy hh:mm:ss"
//									"hh:mm:ss dd.mm.yyyy"
//									"yyyy-mm-dd hh:mm:ss"
//									"dd.mm.yyyy"
//									"dd/mm/yyyy"
//									"yyyy-mm-dd"
//									"hh:mm:ss"
//									"mm/dd/yy hh:mm:ss"	
//									"hh:mm:ss dd/mm/yy"
//									"dd/mm/yyyy hh:mm:ss"
//									"m/d/yyyy hh:mm:ss AM"
//				optional:
//					noABort:	1: do not abort but return -999
	
// Output:	julian seconds in Igor format

Function MARAaux_String2js(timeString,format[,noAbort])	//format is the format of the input string

string timeString, format

Variable noABort

IF (PAramisDefault(nOAbort))
	noAbort=0
ENDIF
//------------------------
Variable Seconds
String TempTimeStr,TempDateStr

String abortStr=""

String AMPM=""	// AMPM="" no AM indicator "PM" has indicator

IF (stringmatch("",timeString)!=1)
	StrSwitch (format)
		CASE "hh:mm:ss dd.mm.yyyy":
			IF (ItemsInList(TimeString," ")!=2)
				abortStr= "ERROR MPaux_String2js: given format does not match input data (1)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(0,TimeString," ")
			TempDateStr=StringFromList(1,TimeString," ")
			IF (ItemsInList(TempDateStr,".")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (2)"
			ENDIF
			BREAK
		CASE "dd.mm.yyyy hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (3)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(1,TimeString," ")
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,".")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (4)"
			ENDIF
			BREAK
		CASE "yyyy-mm-dd hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (5)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(1,TimeString," ")
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,"-")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (6)"
				BREAK
			ENDIF
			tempDateStr=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")	//put date into "standard" format: dd.mm.yyyy
			BREAK
		CASE "mm/dd/yy hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (7)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(1,TimeString," ")
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,"/")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (8)"
				BREAK
			ENDIF
			TempDateStr=StringFromList(1,TempDateStr,"/")+"."+StringFromList(0,TempDateStr,"/")+".20"+StringFromList(2,TempDateStr,"/")
			BREAK
		CASE "hh:mm:ss dd/mm/yy":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (9)"
				BREAK
			ENDIF
			TempTimeStr=StringFromList(0,TimeString," ")
			TempDateStr=StringFromList(1,TimeString," ")
			IF (ItemsInList(TempDateStr,"/")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (10)"
				BREAK
			ENDIF

			TempDateStr=StringFromList(0,TempDateStr,"/")+"."+StringFromList(1,TempDateStr,"/")+".20"+StringFromList(2,TempDateStr,"/")
			BREAK
		CASE "dd.mm.yyyy":
			IF (ItemsInList(TimeString," ")!=1)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (11)"
				BREAK
			ENDIF

			TempTimeStr="00:00:00"
			TempDateStr=TimeString
			IF (ItemsInList(TempDateStr,".")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (12)"
				BREAK
			ENDIF

			BREAK
		CASE "yyyy-mm-dd":
			IF (ItemsInList(TimeString," ")!=1)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (13)"
				BREAK
			ENDIF

			TempTimeStr="00:00:00"
			TempDateStr=TimeString
			tempDateStr=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")	//put date into "standard" format: dd.mm.yyyy
			BREAK
		CASE "dd/mm/yyyy":
			IF (ItemsInList(TimeString," ")!=1)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (14)"
				BREAK
			ENDIF

			TempTimeStr="00:00:00"
			TempDateStr=TimeString
			IF (strlen(StringFromList(2,TempDateStr,"/"))==4)
				TempDateStr=StringFromList(0,TempDateStr,"/")+"."+StringFromList(1,TempDateStr,"/")+"."+StringFromList(2,TempDateStr,"/")
			ELSE	//catch 2 digit year
				TempDateStr=StringFromList(0,TempDateStr,"/")+"."+StringFromList(1,TempDateStr,"/")+".20"+StringFromList(2,TempDateStr,"/")
			ENDIF
			
			BREAK
		CASE "hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=1)
				print timeString + " " +Format
				abort "ERROR MPaux_String2js: given format does not match input data (15)"
				BREAK
			ENDIF

			TempTimeStr=TimeString
			TempDateStr="01.01.1904"	//zero in igor Date
			BREAK
		CASE "dd/mm/yyyy hh:mm:ss":
			IF (ItemsInList(TimeString," ")!=2)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (16)"
				BREAK
			ENDIF

			TempTimeStr=StringFromList(1,TimeString," ")
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,"/")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (17)"
				BREAK
			ENDIF

			TempDateStr=StringFromList(0,TempDateStr,"/")+"."+StringFromList(1,TempDateStr,"/")+"."+StringFromList(2,TempDateStr,"/")
			BREAK
		CASE "m/d/yyyy hh:mm:ss AM":
			IF (ItemsInList(TimeString," ")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (18)"
				BREAK
			ENDIF

			TempTimeStr=StringFromList(1,TimeString," ")
			AMPM=StringFromList(2,TimeString," ")	// catch AM PM shit
			TempDateStr=StringFromList(0,TimeString," ")
			IF (ItemsInList(TempDateStr,"/")!=3)
				print timeString + " " +Format
				abortStr= "ERROR MPaux_String2js: given format does not match input data (19)"
				BREAK
			ENDIF

			TempDateStr=StringFromList(1,TempDateStr,"/")+"."+StringFromList(0,TempDateStr,"/")+"."+StringFromList(2,TempDateStr,"/")
			BREAK
		DEFAULT:
			abortStr= "ERROR MPaux_String2js: unknown time format "+format+"(20)"
	ENDSWITCH
	
	// check if problem occured and return -999
	IF (!StringMatch(abortSTr,""))
		IF (noAbort==1)
			seconds=-999
			print abortSTr
			Return seconds
		ELSE
			Abort abortSTr
		ENDIF

	ENDIF
		
	//check some common mistakes
	IF (ItemsInList(TempTimeStr,":")==2)
		TempTimeStr+=":00"	//add missing seconds
	ELSEIF (ItemsInList(TempTimeStr,":")!=3)
		abortStr= "ERROR MPaux_String2js: time part must be of format: ...hh:mm:ss..."
	ENDIF
	IF (strLen(StringFromList(2,TempDateStr,"."))==2)
		TempDateStr=StringFromList(0,tempDateStr,".")+"."+StringFromList(1,tempDateStr,".")+".20"+StringFromList(2,tempDateStr,".")	//convert two digit year to four digits (only works after 2000!!!!)
	ELSEIF(strLen(StringFromList(2,TempDateStr,"."))!=4)
		abortStr= "ERROR MPaux_String2js: use 4 digit year: make sure that date matches given format"
	ENDIF
	
	IF (StringMatch(abortSTr,""))
		
		Seconds=date2secs(str2num(StringFromList(2,TempDateSTr,".")),str2num(StringFromList(1,TempDateStr,".")),str2num(StringFromList(0,TempDateStr,".")))
		Seconds+=str2num(StringFromList(0,tempTimeStr,":"))*3600+str2num(StringFromList(1,tempTimeStr,":"))*60+str2num(StringFromList(2,tempTimeStr,":"))
		
		// catch AM/PM
		IF (stringmatch(AMPM,"PM") && stringmatch(StringFromList(0,tempTimeStr,":"),"12"))
			seconds+=12*3600	// add 12h
		ENDIF
	ELSE
		IF (noAbort==1)
			seconds=-999
			print abortSTr
		ELSE
			Abort abortSTr
		ENDIF
	ENDIF
ELSE
	seconds=NaN	//if empty field was passed: put in NaN
ENDIF
		
RETURN Seconds
END


//======================================================================================
//======================================================================================


// Purpose:	converts igor julian seconds to string

// Input:		seconds: 	seconds value that should be converted to a data-time string
//				format:	string defining the output format of the data-time string.
//							supported formats:
//								"dd.mm.yyyy hh:mm:ss"
//								"hh:mm:ss dd.mm.yyyy"
//								"yyyy-mm-dd hh:mm:ss"
//								"dd.mm.yyyy"
//								"dd/mm/yyyy"
//								"yyyy-mm-dd"
//								"hh:mm:ss"
// Output:	string with date+time in specified format


Function/S MARAaux_js2String(seconds,format[,noAbort])		//format is the format of the return string
String format
Variable Seconds
Variable noABort

IF (PAramisDefault(nOAbort))
	noAbort=0
ENDIF

String timeString
String TempDateStr=secs2Date(seconds,-2)		//yyyy-mm-dd
String TempTimeStr=secs2time(seconds,3)		//hh:mm:ss

IF (NumType(seconds)==0)
	StrSwitch (format)
		CASE "dd.mm.yyyy hh:mm:ss":
			timeString=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")
			timeString=timeString+" "+tempTimeStr
			BREAK
		CASE "hh:mm:ss dd.mm.yyyy":
			timeString=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")
			timeString=tempTimeStr+" "+timeString
			BREAK
		CASE "yyyy-mm-dd hh:mm:ss":
			timeString=tempDateStr+" "+ tempTimeStr
			BREAK
		CASE "dd.mm.yyyy":
			timeString=StringFromList(2,TempDateStr,"-")+"."+StringFromList(1,TempDateStr,"-")+"."+StringFromList(0,TempDateStr,"-")
			BREAK
		CASE "dd/mm/yyyy":
			timestring=StringFromList(2,TempDateStr,"-")+"/"+StringFromList(1,TempDateStr,"-")+"/"+StringFromList(0,TempDateStr,"-")
			BREAK
		CASE "yyyy-mm-dd":
			timeString=TempDateStr
			BREAK
		CASE "hh:mm:ss":
			timeString=tempTimeStr
			BREAK
		DEFAULT:
			IF (noabort==0)
				abort "MSaux_js2string: unknown time format "+format
			ELSE
				// return flag
				timeString="Wrong Format"
			ENDIF
	ENDSwitch
ELSE
	timeString=""		//if NaN or inf was passed: return empty field
ENDIF

RETURN timeString
END

//======================================================================================
//======================================================================================

// Purpose:	create multiple subfolders in one go
//				folder is created from current position

// Input:		NewFolderName:	full path for new folder 													
//				Set:				0: go back to current foledr, 1: set new folder
// Output:	folder tree down to NewFolderName


FUNCTION MARAaux_NewSubfolder(NewFolderName,set )

String NewFolderName
Variable Set

Variable nof=Itemsinlist(NewfolderName,":")
Variable ff

String OldFolder=getDataFolder(1)

FOR (ff=0;ff<nof;ff+=1) 
	String currentLevel=StringfromList(ff,NewFolderName,":")
	// first entry is root
	IF (stringmatch(currentlevel,"root"))
		setdatafolder root:
	ELSE
		// set to existing
		IF (datafolderexists(currentlevel) )
			setdatafolder $CurrentLevel
		ELSE
		// or make new one	
			Newdatafolder/S $Currentlevel
		ENDIF
	ENDIF
	
ENDFOR

// set back to old folder
IF (set==0)
	SetdataFolder $OldFolder
ELSE
	Setdatafolder $NewFOlderName
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	calculate the double and tripple charged sizes for the single charged DP
//			
// Input:	structure info from control
// Output:	adjusts values in the corresponding wave


FUNCTION MARAaux_calcSizes(ctrlStruct)

STRUCT WMSetVariableAction &ctrlStruct


// only activate if field lost focus
IF (ctrlStruct.eventCode==8)	//8: end edit
	// get wave with values
	Wave DpSize=root:MARA:MCE:DPsize
	Variable Dp_i=DPsize[0]/1e9	// single charge Dp in m
	
	SVAR abortStr=root:MARA:abortStr
	
	// get lookup waves
	Wave Dp_lookup=root:MARA:MCE:Dp_lookup
	Wave mobility_lookup=root:MARA:MCE:mobility_lookup
	
	// get mobility values
	Variable IDX_dp=round(binarySearchinterp(DP_lookup,DP_i))	// find Dp value in lookup table
	IF (numtype(idx_dp)!=0)	// catch if value is out of range
		abortStr="MARAaux_calcSizes():\r\rGiven Dp value out of lookup table range: "+num2str(Wavemin(DP_lookup)*1e9)+" - "+ num2str(WaveMax(Dp_lookup)*1e9)+" nm"
		MARAaux_abort(abortStr)
	ENDIF
	
	Variable mobility_i=mobility_lookup[idx_DP]	// mobility of single charged
	
	Variable mobility_ii=mobility_i/2
	Variable mobility_iii=mobility_i/3
	
	// find new mobility values
	Variable idx_ii=round(binarySearchinterp(mobility_lookup,mobility_ii))
	Variable idx_iii=round(binarySearchinterp(mobility_lookup,mobility_iii))
	
	IF (numtype(idx_ii)==0)
		// entry found
		DPsize[1]=DP_lookup[idx_ii]*1e9
	ELSE
		// nothing found
		DpSize[1]=NaN
	ENDIF

	IF (numtype(idx_iii)==0)
		// entry found
		DPsize[2]=DP_lookup[idx_iii]*1e9
	ELSE
		// nothing found
		DpSize[2]=NaN
	ENDIF	
	
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:	calculate the mobility for a single size (given in m)
//			
// Input:	Dp in m
// Output:	mobility value


FUNCTION/D MARAaux_calcMobility(Dp)

Variable Dp

Variable temp=293.15
Variable press=1.013e5
Variable visc=(174.+0.433*(temp-273.))*1.0e-7	// viscosity
Variable e_charge=1.6021773e-19;

Variable mobility=e_charge/(3*pi*visc*Dp)*MARAaux_Cunningham(Dp,temp,press);

RETURN mobility

END

//======================================================================================
//======================================================================================

// Purpose:	calculate CUnning ham slip correction values
//			
// Input:	dp:	diameter in m
//			temp:	temperature in K
//			press:	pressure in hPa
// Output:	cunningham slip value

Function/D MARAaux_Cunningham(dp,temp,press)

Variable dp
Variable temp
Variable press

//constants
Variable dm=3.7e-10;
Variable Na=6.022e23;
Variable Rgas=8.3143;

//check diameter unit
IF (dp>1e6)  // that would be 1um 
    dp=dp/1e9; // -> assume nm and convert to m
ENDIF

Variable rvalue=Rgas*temp/(sqrt(2.)*Na*press*pi*dm*dm);

Variable CS=1.0+ rvalue /dp *(2.514+0.800*exp(-0.55*dp/rvalue));

RETURN CS

END


//======================================================================================
//======================================================================================

// Purpose:	calculate charge probpability for -1, -2 , -3 at a specific size
//			
// Input:	Dp in m
//			polarity: 0: negative, 1:positive
// Output:	ChargeProp: wave with charge propability of -1,-2,-3 (wave is created in current folder)

FUNCTION MARAaux_calcChargeProp(Dp,polarity)

Variable Dp,polarity

// constants for equations
Variable temp=293.15
Variable press=1.013e5
Variable visc=(174.+0.433*(temp-273.))*1.0e-7	// viscosity
Variable e_charge=1.6021773e-19		//	electron charge
Variable k_boltz=1.381e-23			// Boltzman constant
Variable ep_value=8.8542e-12		// ?

// prepare container
Make/O/D/N=3 ChargeProp=0

// single and double charge have different equation than higher charges
// first column: negative parameters, second columns positive
Make/FREE/D /N=(6,2) params_single, params_double
//negative
params_single[][0]={-2.3197,0.6175,0.6201,-0.1105,-0.1260,0.0297}
params_double[][0]={-26.3328, 35.9044,-21.4608,7.0867,-1.3088,0.1051}
//positive
params_single[][1]={-2.3484,0.6044,0.4800,0.0013,-0.1553,0.0320}
params_double[][1]={-44.4756,79.3772,-62.8900,26.4492,-5.7480,0.5049}

Variable Dummy_1=0
Variable Dummy_2=0
Variable ii

FOR (ii=0;ii<dimsize(params_single,0);ii+=1)

	Dummy_1+=params_single[ii][polarity]*log(1e9*Dp)^(ii)
	Dummy_2+=params_double[ii][polarity]*(log(1e9*Dp)^(ii))

ENDFOR

ChargeProp[0]=10^dummy_1
ChargeProp[1]=10^dummy_2

// for triple charged
Variable ss=2*pi*ep_value*Dp*k_boltz*Temp

ChargeProp[2]=e_charge*(4*pi^2*ep_value*Dp*k_boltz*Temp)^(-1/2)*exp(-(-3-ss*ln(0.875)/e_charge^2)^2/(2*ss/e_charge^2))

END



//======================================================================================
//======================================================================================

// Purpose:	hook function to update the values when the cursor is moved in tseries plots
//			
// Input:	
// Output:	changes the values in CursorValue wave and by that updates the displayed values


FUNCTION MARAaux_CursorMoveHOOK(CsrStruct)

STRUCT WMWinHOOKStruct &CsrStruct

Variable statusCode= 0

strswitch( CsrStruct.eventName )
	case "cursormoved":	
		// see SetWindow's "Members of WMWinHookStruct Used with cursormoved Code"
		Wave CursorValue=root:MARA:CursorValue
		Wave CursorPos=root:MARA:CursorPos
		Wave/T CursorValue_txt=root:MARA:CursorValue_txt
		
		SVAR formatStr=root:MARA:TimeFormat_STR
		
		// Identify tseries or pToF (MARA_pToF_X or MARA_Tseries_X)
		String WindowName=removeEnding(CSrStruct.Winname,"#plot")	// remove subwindow name
		String plotType=StringFromList(1,WindowName,"_")
		
		// identify which compound (AS,AN,O)
		String TypeStr=StringFromList(2,WindowName,"_")	// 
		
		String LabelStr=plottype+"_"+TypeStr+"_"+CsrStruct.cursorname
		
		// get x axis value
		Wave XWave=XwaveRefFromTrace(CsrStruct.WinName,CsrStruct.tracename)
		Variable NewValue=xWave[CsrStruct.pointNumber]
		
		// store info
		CursorPos[%$LabelStr]=CsrStruct.pointNumber
		CursorValue[%$LabelStr]=NewValue
		
		CursorValue_Txt[%$LabelStr]=MARAaux_js2String(CursorValue[%$LabelStr],formatStr)
		BREAK
endswitch

RETURN statusCode

END
