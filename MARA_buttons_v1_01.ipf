#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


//======================================================================================================================================================================================//	MARA_butFuncs_v1_01 is a collection of auxilliary functions for MARA. 
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
//	You should have received a copy of the GNU General Public License along with MaS-PET. If not, see <https://www.gnu.org/licenses/>. 
//======================================================================================================================================================================================


//======================================================================================
//======================================================================================

// Purpose:		handle button procedures for MARA Panel (all but the graph pop buttons)
// Input:		triggered by buttons
//				
// Output:		creates panel and variables in folder root:MARA
//				
// called by:	button push in Main MARA Panel



FUNCTION MARAbut_buttonPROCS(B_struct) : BUttonControl

STRUCT WMButtonAction &B_Struct

IF(B_struct.eventCode==2)	
	
	SVAR abortStr=root:MARA:abortStr
	
	String oldFolder=getdatafolder(1)
	setdatafolder root:
	
	// get general info data 
	Wave/T Wavenames=root:MARA:Wavenames 
	IF (!Waveexists(Wavenames))
		abortStr="MARAbut_buttonPROCS("+B_struct.ctrlname+"):\r\r Wavenames wave does not exist"
		MARAaux_abort(abortStr)
	ENDIF
	
	String CurrentWaveList=""	// string list with Wavenames to useööö
	
	// check which button was pressed
	// calibration compound 
	Variable type	// 0: AN, 1: AS, 2: other
	String TypeStr=stringfromlist(1,B_struct.ctrlname,"_")	// all button names start with But_typeStr_
	IF (Stringmatch(TypeStr,"AN"))
		Type=0
	ENDIF
	IF (Stringmatch(TypeStr,"AS"))
		Type=1
	ENDIF
	IF (Stringmatch(TypeStr,"O"))
		Type=2
	ENDIF

	// get button name info
	String ButtonType=stringfromlist(2,B_struct.ctrlname,"_")	// But_typeStr_Name

	STRSWITCH (ButtonType)
		//---------------------------------
		// open multicharge calcualtor
		CASE "MCEPAnel":
			MARAbut_MCEpanel()
			BREAK
		
		//---------------------------------
		// plot AMS & CPC data time series
		CASE "plotTseries":
			MARAbut_plotTseries(type,Wavenames)
			BREAK
		
		//---------------------------------		
		// plot pTof size spectrum
		CASE "plotPTof":
			MARAbut_plotPToF(type,Wavenames)
			BREAK
		
		//---------------------------------
		// calculate single particle fraction
		CASE "calcFmulti":
			MARAbut_calcMulti(type,wavenames)
			BREAK
		
		//---------------------------------
		// plot AMS & CPC dat atime series
		CASE "calcIE":
			MARAbut_calcRIE(type,wavenames)
			BREAK
		// no button found
		DEFAULT :
			setdatafolder $oldFolder
			abortStr="MARAbut_buttonPROCS:\r\runable to determine button type:\r\r"+B_struct.ctrlname
			MARAaux_abort(abortStr)

	ENDSWITCH
	setdatafolder $oldFolder
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		handle pop graph buttons
// Input:		triggered by buttons
//				
// Output:		creates a standalone graph window of the related graph
//				
// called by:	button push in Main MARA Panel



FUNCTION MARAbut_PopGraph(B_struct) : BUttonControl

STRUCT WMButtonAction &B_Struct

IF(B_struct.eventCode==2)	
	
	SVAR abortStr=root:MARA:abortStr
	
	String oldFolder=getdatafolder(1)
	setdatafolder root:
	
	// get info about which graph is selected
	String GraphID=replacestring("BUT_pop_",B_struct.ctrlname,"")	//-> graph window name 
	String graphname=GraphID+"_pop"
	String WindowName="MARA_Panel#"+GraphID
	
	// get Type number 
	Variable type	// 0: AN, 1: AS, 2: other
	IF (Stringmatch(GraphID,"AN_*"))
		Type=0
	ENDIF
	IF (Stringmatch(GraphID,"AS_*"))
		Type=1
	ENDIF
	IF (Stringmatch(GraphID,"O_*"))
		Type=2
	ENDIF

	// get plot type 
	Variable GraphType	// 0: AN, 1: AS, 2: other
	IF (Stringmatch(GraphID,"*_IE"))
		GraphType=0
	ENDIF
	IF (Stringmatch(GraphID,"*_RIE"))
		GraphType=1
	ENDIF
	IF (Stringmatch(GraphID,"*_mIE_anion"))
		GraphType=2
	ENDIF
	IF (Stringmatch(GraphID,"*_mIE_cation"))
		GraphType=3
	ENDIF

	// get graph info
	Wave/T PanelPlotInfo_STR=root:MARA:PanelPlotInfo_STR
	Wave/T OnePlotInfo_STR=root:MARA:OnePlotInfo_STR
	Wave PanelPlotInfo_VAR=root:MARA:PanelPlotInfo_VAR
	Wave OnePlotInfo_VAR=root:MARA:OnePlotInfo_VAR

	OnePlotInfo_STR=PanelPlotInfo_STR[p][GraphType][Type]
	OnePlotInfo_VAR=PanelPlotInfo_VAR[p][GraphType][Type]
	
	//make new graph
	MARAbut_DoPanelplot(OnePlotInfo_STR,OnePlotInfo_VAR,GraphName,0)

	setdatafolder $oldFolder
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		plot tseries of AM and CPC data in seperate graph panel
//				uses wavenames from Panel

// Input:		type: 0: AN, 1: AS, 2: other
// Output:		new graph with tseries (will delete previous graph)
// called by:	MARAbut_buttonPROCS()

FUNCTION MARAbut_plotTseries(type,Wavenames)

variable Type
Wave/T wavenames

String TypeStr=""	//AN, AS,O
String NameIon1=""
String NameIon2=""

SVAR abortStr=root:MARA:abortStr

Variable ii

// set up names depending on Type
SWITCH (Type)
	CASE 0:	//AN
		TypeStr="AN"
		NameIon1="NH4"
		NameIon2="NO3"
		BREAK
		
	CASE 1:	//AS
		TypeStr="AS"
		NameIon1="NH4"
		NameIon2="SO4"
		BREAK
	
	CASE 2:	//other
		TypeStr="O"
		NameIon1="ion1"
		NameIon2="ion2"

		BREAK
	DEFAULT:
		abortStr="MARAbut_plotTseries("+TypeStr+"):\r\runable to determine type from passed value\r\r"+num2Str(Type)
		MARAaux_abort(abortStr)
		BREAK
ENDSWITCH

// make colour wave
Make/o/D/N=(6,3) root:Mara:colourWave
Wave colourWave=root:Mara:colourwave	// column are red/blue yellow, one row = 1 colour

Setdimlabel 0,0,NH4,colourWave	// orange
Setdimlabel 0,1,NO3,colourWave	// blue
Setdimlabel 0,2,SO4,colourWave	// red
Setdimlabel 0,3,ion1,colourWave	// black
Setdimlabel 0,4,ion2,colourWave	// grey
Setdimlabel 0,5,CPC,colourWave	// purple

colourWave[][0]={65535,0,65535,0,34952,44253}
colourWave[][1]={43690,0,0,0,34952,29492}
colourWave[][2]={0,65535,0,0,34952,58982}

// find wavenames from wave

String ListYwaves=""
String ListXwaves=""
String ListTypes="CPC;"+NameIon1+";"+NameIon2+";"

String dummyLabel=""

ListYWaves+="root:"+Wavenames[%CPC_numconc][%$TypeStr]+";"+"root:"+Wavenames[%AMS_cation_hz][%$TypeStr]+";root:"+Wavenames[%AMS_anion_hz][%$TypeStr]+";"
ListXWaves+="root:"+Wavenames[%CPC_tseries][%$TypeStr]+";"+"root:"+Wavenames[%AMS_tseries][%$TypeStr]+";root:"+Wavenames[%AMS_tseries][%$TypeStr]+";"

// capture "::" and duplicate root
ListYwaves=replaceString("root:root:",ListYwaves,"root:")
ListYwaves=replaceString("root::",ListYwaves,"root:")

ListXwaves=replaceString("root:root:",ListXwaves,"root:")
ListXwaves=replaceString("root::",ListXwaves,"root:")

// check if waves exist
// first x waves
IF (MARAaux_CheckWavesFromList(ListXwaves)!=1)
	Wave NonExistIdx
	abortStr="MARAbut_plotTseries("+TypeStr+"):\r\rOne or more waves not found. Check history for missing wave names."
	
	print "--------------------------------"
	print date() + " "+ time()
	print "MARAbut_plotTseries: missing waves"
	FOR (ii=0;ii<numpnts(NonExistIdx);ii+=1)
		print Stringfromlist(nonexistidx[ii],ListXwaves)
	ENDFOR
	
	MARAaux_abort(abortStr)
ENDIF

// second Y waves
IF (MARAaux_CheckWavesFromList(ListYwaves)!=1)
	Wave NonExistIdx
	
	// check for "others" if only one ion is selected
	Variable TestNum=0	// -> set to 1 if abort is still needed

	IF (type==2)	// -> others
		IF (numpnts(NonExistIdx)==1 && NonExistIdx[0]==2)	//entry 1 is ion2
			// check if the field was empty
			IF (Stringmatch(Stringfromlist(NonExistIdx[0],ListYwaves),"root:"))
				
				// remove entry from lists
				ListXWaves=removeListItem(NonExistIdx[0],ListXwaves)
				ListYWaves=removeListItem(NonExistIdx[0],ListYwaves)
				
				// info for user
				print "--------------------------------"
				print date() + " "+ time()
				print "MARAbut_plotTseries: only 1 ion detected for tseries plotting"
				testnum=1
				
			ENDIF
		ENDIF	
	ENDIF	
		
	IF (testnum==0)
		abortStr="MARAbut_plotTseries("+TypeStr+"):\r\rOne or more waves not found. Check history for missing wave names."
		
		print "--------------------------------"
		print date() + " "+ time()
		print "MARAbut_plotTseries: missing waves"
		FOR (ii=0;ii<numpnts(NonExistIdx);ii+=1)
			print Stringfromlist(nonexistidx[ii],ListYwaves)
		ENDFOR
		
		MARAaux_abort(abortStr)
	ENDIF
ENDIF

// check if average values exist
String resultFolder=getWavesDataFolder($(Stringfromlist(1,listYwaves)),1)+"RIE"	// use kation wave as indicator for the folder
Variable plotAVG=0	// switch to turn on plotting of average values

IF (datafolderexists(resultFolder))	// check if folder exists
	Wave/Z testWave=$(resultFolder+":"+TypeStr+"_AMS_tseries")
	
	IF (waveexists(testWave))	// check if wave exists
		// set switch
		plotAVG=1
		
		String ListXwaves_avg=resultFolder+":"+TypeStr+"_CPC_tseries;"
		String ListXWaves_sdev=resultFolder+":"+TypeStr+"_CPC_tseries_sdev;"
		String ListYWaves_avg=resultFolder+":"+TypeStr+"_CPC_conc;"
		String ListYWaves_sdev=resultFolder+":"+TypeStr+"_CPC_conc_sdev;"

		ListXwaves_avg+=resultFolder+":"+TypeStr+"_AMS_tseries;"
		ListXWaves_sdev+=resultFolder+":"+TypeStr+"_AMS_tseries_sdev;"
		ListYWaves_avg+=resultFolder+":"+TypeStr+"_AMS_"+NameIon1+"_Hz;"
		ListYWaves_sdev+=resultFolder+":"+TypeStr+"_AMS_"+NameIon1+"_Hz_sdev;"
		
		IF (testnum==0)	// both ions selected
			ListXwaves_avg+=resultFolder+":"+TypeStr+"_AMS_tseries;"
			ListXWaves_sdev+=resultFolder+":"+TypeStr+"_AMS_tseries_sdev;"
			ListYWaves_avg+=resultFolder+":"+TypeStr+"_AMS_"+NameIon2+"_Hz;"
			ListYWaves_sdev+=resultFolder+":"+TypeStr+"_AMS_"+NameIon2+"_Hz_sdev;"
		ENDIF
		
		
	ENDIF

ENDIF

//-----------------------------
// plotting

String GraphName="MARA_Tseries_"+TypeStr
String CurrentTrace=""
String LegendStr=""
 
String PanelName=GraphName
GraphName=PanelName+"#plot"

Killwindow/Z $Panelname

NewPanel/W=(10,10,600,550) as Panelname 
DoWindow/C $PanelName

// handle resizing
DefineGuide Guide_V1={FR,0.01,FL},Guide_V2={FL,0.01,FR}
DefineGuide Guide_H1={FB,0.35,FT},Guide_H2={FB,-189.75}
	
Display/W=(5,5,600,400) /HOST=$PanelName/FG=($"",$"",Guide_V1,Guide_H1) as "plot"
RenameWindow #,plot

// hook function for tracking cursor movement
SetWindow $Panelname hook(myHook)=MARAaux_CursorMoveHOOK

// looping through wave list

FOR (ii=0;ii<Itemsinlist(ListYwaves);ii+=1)
	
	// get waves
	Wave xwave1=$(Stringfromlist(ii,listXwaves))
	Wave ywave1=$(Stringfromlist(ii,listYwaves))
	
	String CurrentType=Stringfromlist(ii,ListTypes)
		
	//plot
	IF (!stringmatch(CurrentType,"CPC"))	
		//AMS
		appendtograph/W=$Graphname ywave1 vs xwave1	
	ELSE
		//CPC
		appendtograph/R/W=$Graphname ywave1 vs xwave1
	ENDIF
	
	// store tracename
	String FullList=TraceNameList("",";",1)
	CurrentTrace=Stringfromlist(Itemsinlist(Fulllist)-1,FullList)	// last entry is current one
	
	// legendStr
	LegendStr+="\\s("+CurrentTrace+") "+CurrentType+"\r"
	
	// set colour according to type
	modifygraph/W=$Graphname rgb($Currenttrace)=(colourWave[%$CurrentType][0],colourWave[%$CurrentType][1],colourWave[%$CurrentType][2])
	
	// set cursor on first trace and store corresponding time values
	IF (ii==1)
		ShowInfo /W=$Panelname 
		
		Wave/Z CursorPos=root:MARA:CursorPos
		Wave/Z CursorValue=root:MARA:CursorValue
		Wave/Z/T CursorValue_txt=root:MARA:CursorValue_txt
		
		SVAR/Z formatStr=root:MARA:TimeFormat_STR
		
		String CursorName_A="tseries_"+typeStr+"_A"
		String CursorName_B="tseries_"+typeStr+"_B"
		
		Cursor/P A, $CurrentTrace, CursorPos[%$CursorName_A][0] 
		
		CursorPos[%$CursorName_A]=pcsr(A)
		CursorValue[%$CursorName_A]=hcsr(A)
		
		Cursor/P B, $CurrentTrace, CursorPos[%$CursorName_B][0] 
		
		CursorPos[%$CursorName_B]=pcsr(B)
		CursorValue[%$CursorName_B]=hcsr(B)
		
		CursorValue_txt=MARAaux_js2String(CursorValue,formatStr)
	ENDIF
	
	//-------------------------------
	// add average values
	IF (plotAVG==1)
		// assign waves
		Wave xwave2=$(Stringfromlist(ii,listXwaves_avg))
		Wave ywave2=$(Stringfromlist(ii,listYwaves_avg))
		
		Wave errXWave=$(Stringfromlist(ii,listXwaves_sdev))
		Wave errYWave=$(Stringfromlist(ii,listYwaves_sdev))
	
		// plot
		IF (!stringmatch(CurrentType,"CPC"))	
			//AMS
			appendtograph/W=$Graphname ywave2 vs xwave2	
		ELSE
			//CPC
			appendtograph/R/W=$Graphname ywave2 vs xwave2
		ENDIF
			
		//get tracename
		FullList=TraceNameList("",";",1)
		CurrentTrace=Stringfromlist(Itemsinlist(Fulllist)-1,FullList)	// last entry is current one
		
		// add error bar
		ErrorBars/T=2/L=2 $CurrentTrace XY,wave=(errXWave,errXWave), wave=(errYWave,errYWave)
		
		// set colour and type
		Modifygraph/W=$Graphname rgb($Currenttrace)=(colourWave[%$CurrentType][0],colourWave[%$CurrentType][1],colourWave[%$CurrentType][2])
		Modifygraph/W=$Graphname mode($currenttrace)=3, marker($currenttrace)=19,useMrkStrokeRGB($CurrentTrace)=1,mrkThick($CurrentTrace)=1.5
		
	ENDIF
	
ENDFOR

// make graph pretty
ModifyGraph/W=$Graphname fStyle=1,axThick=2,standoff=0,gridHair=1,lsize=2,nticks=4, notation=1,fSize=16

// axis
ModifyGraph/W=$Graphname tick(left)=2,tick(right)=2,mirror(bottom)=2,nticks(bottom)=5,lblMargin(left)=10,lblMargin(right)=10

Label/W=$Graphname left,"AMS concentration / Hz * \r\f00( * user must check unit)"
Label/W=$Graphname right, "CPC number conc / #/cm\S3"
Label/W=$Graphname bottom, "time"

// legend
legendStr=removeending(LegendStr,"\r")
Legend LegendStr

//=======================
// set up controls for interval selection

// wave with interval values
Wave/T/Z IntervalTime=$("root:MARA:AMS_"+TypeStr+"_IntervalTime")
	
//start end index table
Edit/W=(5,400,300,550)/HOST=$Panelname/FG=($"",Guide_H2,$"",FB) IntervalTime
RenameWindow #,TBL_interval

ModifyTable/W=$(panelName+"#TBL_interval") format(Point)=1,width=125,width(point)=20,Size=10
ModifyTable/W=$(panelName+"#TBL_interval") selection=(0,0,0,1,0,0)	// select first row

// cursor info
// controls are in a subpanel for resizing
NewPanel/HOST=$Panelname/FG=($"",Guide_H2,$"",FB)/W=(305,400,595,545)
RenameWindow #,BOX_controls
String Boxname=PanelName+"#Box_Controls"

// create display values from cursor
Setvariable VARs_CursorA_value pos={100,10},title="Time A:",bodyWidth=100,value=CursorValue_TXt[%$CursorName_A],limits={0,inf,0},Win=$Boxname
Setvariable VARs_CursorB_value pos={100,25},title="Time B:",bodyWidth=100,value=CursorValue_txt[%$CursorName_B],limits={0,inf,0},Win=$Boxname

// buttons
button BUT_addInterval pos={10,100},size={80,20},title="add line", proc=MARAbut_Tseries_but,Win=$Boxname
button BUT_changeinterval pos={150,100},size={100,20},title="change current line", proc=MARAbut_Tseries_but,Win=$Boxname


//=======================
// clean up

END

//======================================================================================
//======================================================================================

// Purpose:		add or modify the entries in the AMS_XX_intervalTime wave
//				this uses values in the CursorValue_txt wave. 
//				This can be the direct cursor values or a manual value
//
// Input:		info from CursorValue_txt Wave
// Output:		add or modify the entries in the AMS_XX_intervalTime wave
// called by:	buttons in Tseries graph

FUNCTION MARAbut_Tseries_but(B_Struct) : buttonControl

STRUCT WMButtonAction &B_Struct

IF(B_struct.eventCode==2)	
	
	SVAR abortStr=root:MARA:abortStr
	
	// get info about the type (AN/AS/O)
	String WindowName=B_struct.win 
	String ID=stringfromlist(0,WindowName,"#")	// handle subwindow
	ID=stringfromlist(2,ID,"_")	// get identifier
	
	// get the data
	Wave/T AMS_intervalTime=$("root:MARA:AMS_"+ID+"_IntervalTime")
	Wave/T CursorValue_txt=root:MARA:CursorValue_txt
	
	String TimeA_txt=CursorValue_txt[%$("tseries_"+ID+"_A")]
	String TimeB_txt=CursorValue_txt[%$("tseries_"+ID+"_B")]
	
	// convert to numeric value tp check which one is smaller
	SVAR formatStr=root:MARA:TimeFormat_STR
	Variable TimeA_num=MARAaux_string2js(TimeA_txt,formatStr)
	Variable TimeB_num=MARAaux_string2js(TimeB_txt,formatStr)
	
	// find row to work on depending on button type (BUT_addInterval , BUT_changeinterval)
	STRSWITCH (B_struct.ctrlname)
		//-----------------------
		// add a new line
		CASE "BUT_addInterval":
			
			// remove any additional empty lines and add a new one at the end
			Variable ii
			FOR (ii=(dimsize(AMS_intervalTime,0)-1);ii>-1;ii-=1)	// reverse loop
				// remove row if both are empty
				IF (Strlen(AMS_intervalTime[ii][0])==0 &&  Strlen(AMS_intervalTime[ii][1])==0 )
					Deletepoints/M=0 ii,1,AMS_intervalTime
				ENDIF
			ENDFOR
			
			// add a new line at the end
			Insertpoints/M=0 dimsize(AMS_intervalTime,0),1, AMS_intervalTime
			// catch if all rows were removed
			IF (dimsize(AMS_INtervalTime,1)==0)
				Insertpoints/M=1 dimsize(AMS_intervalTime,1),1, AMS_intervalTime				
			ENDIF		
			
			// set values
			AMS_intervalTime[dimsize(AMS_intervalTime,0)-1][0]=MARAaux_js2String(min(TimeA_num,TimeB_num),formatStr)
			AMS_intervalTime[dimsize(AMS_intervalTime,0)-1][1]=MARAaux_js2String(max(TimeA_num,TimeB_num),formatStr)

			BREAK
			
		//-----------------------
		// change the currently selected line
		CASE "BUT_changeinterval":
		
			// get the active position in the table
			getselection table, $("MARA_tseries_"+ID+"#TBL_interval"),1
			Variable StartRow=V_startRow
			Variable EndRow=V_EndRow
			Variable StartCol=V_startCol
			Variable EndCol=V_EndCol
			
			// check if more than 1 row was selected
			IF (endRow!=StartRow)
				abortStr="MARAbut_Tseries_but():\r\rMore than one row was selected in the table. Change selection to a single row and try again"
				MARAaux_abort(abortStr)
			ENDIF
			
			// catch if "end of wave" is selected
			IF(Startrow>(Dimsize(AMS_intervalTime,0)-1))
				Insertpoints/M=0 dimsize(AMS_intervalTime,0),1, AMS_intervalTime			
			ENDIF
			
			// set values
			AMS_intervalTime[StartRow][0]=MARAaux_js2String(min(TimeA_num,TimeB_num),formatStr)
			AMS_intervalTime[StartRow][1]=MARAaux_js2String(max(TimeA_num,TimeB_num),formatStr)
			
			BREAK
		
		//----------------------
		DEFAULT :
			BREAK
	ENDSWITCH
	
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		plot pToF data in separate graph
//
// Input:		type: 0: AN, 1: AS, 2: other
// Output:		new graph with pToF size distribution
// called by:	MARAbut_buttonPROCS()

FUNCTION MARAbut_plotPToF(type,Wavenames)

variable Type
Wave/T wavenames

String TypeStr=""	//AN, AS,O
String NameIon1=""
String NameIon2=""

SVAR abortStr=root:MARA:abortStr

Variable ii

// set up names depending on Type
SWITCH (Type)
	CASE 0:	//AN
		TypeStr="AN"
		NameIon1="NH4"
		NameIon2="NO3"
		BREAK
		
	CASE 1:	//AS
		TypeStr="AS"
		NameIon1="NH4"
		NameIon2="SO4"
		BREAK
	
	CASE 2:	//other
		TypeStr="O"
		NameIon1="ion1"
		NameIon2="ion2"

		BREAK
	DEFAULT:
		abortStr="MARAbut_plotpToF("+TypeStr+"):\r\runable to determine type from passed value\r\r"+num2Str(Type)
		MARAaux_abort(abortStr)
		BREAK
ENDSWITCH

// assign and check waves
String XwaveStr="root:"+Wavenames[%AMS_ptof_dp][%$typeStr]
String YwaveStr="root:"+Wavenames[%AMS_ptof_signal][%$typeStr]

XwaveStr= replacestring("root:Root:",XwaveStr,"Root:")
XwaveStr= replacestring("root::",XwaveStr,"Root:")
YwaveStr= replacestring("root:Root:",YwaveStr,"Root:")
YwaveStr= replacestring("root::",YwaveStr,"Root:")

Wave/Z Xwave=$XwaveStr
Wave/Z Ywave=$YwaveStr

IF (!Waveexists(Xwave))	// wave exists?
	abortStr="MARAbut_plotPToF("+TypeStr+"):\r\rpToF Dp wave does not exist:\r\r"+XwaveStr
	MARAaux_abort(abortStr)	
ENDIF
IF (!Waveexists(Ywave))	// wave exists?
	abortStr="MARAbut_plotPToF("+TypeStr+"):\r\rpToF signal wave does not exist:\r\r"+YwaveStr
	MARAaux_abort(abortStr)	
ENDIF

//--------------------------------
// Plotting

String GraphName="MARA_pToF_"+TypeStr
String CurrentTrace=""
String LegendStr=""
 
Killwindow/Z $Graphname

Display/W=(10,10,600,400) as Graphname
Dowindow/C $Graphname

// hook function for tracking cursor movement
SetWindow $Graphname hook(myHook)=MARAaux_CursorMoveHOOK

// plot data
Appendtograph ywave vs xwave
CurrentTrace=TracenameList("",";",1)

// make it pretty
ModifyGraph fStyle=1,axThick=2,standoff=0,gridHair=1,nticks=4, notation=1
Modifygraph rgb=(65535,0,0),mode=4,marker=19,lsize=1.5

// axis
ModifyGraph tick(left)=2,mirror=2,nticks(bottom)=5,lblMargin(left)=10,log(bottom)=1

Label left,"AMS pToF"
Label bottom, "Dp"

SetAxis bottom 10,*

// legend
legendStr=removeending(LegendStr,"\r")
Legend LegendStr


// get values for cursors
Wave CursorPos=Root:MARA:cursorPos
Wave CursorValue=Root:MARA:cursorValue
Wave/T CursorValue_T=Root:MARA:cursorValue_txt

String CursorName_A="pToF_"+TypeStr+"_A"

// set cursor points
showinfo
String CursorName_B="pToF_"+TypeStr+"_B"

Cursor A,$(StringfromList(0,CurrentTrace)),CursorPos[%$CursorName_A]
Cursor B,$(StringfromList(0,CurrentTrace)),CursorPos[%$CursorName_B]

//-------------------------------
// add control to grab cursor position for multicharge fractoin calc
String GraphPanelName=Graphname+"#panel4but"
NewPanel/HOST=$GraphName /W=(90,20,238,95)/N=Panel4but
ModifyPanel /w=$GraphPanelName frameStyle=1

Setvariable VARs_CursorA_pos pos={25,10},title="A: Pos",bodyWidth=25,value=CursorPos[%$CursorName_A],limits={0,inf,0},Win=$GraphPanelName
Setvariable VARs_CursorB_pos pos={25,25},title="B: Pos",bodyWidth=25,value=CursorPos[%$CursorName_B],limits={0,inf,0},Win=$GraphPanelName

Setvariable VARs_CursorA_value pos={100,10},title="value:",bodyWidth=40,value=CursorValue[%$CursorName_A],limits={0,inf,0},Win=$GraphPanelName
Setvariable VARs_CursorB_value pos={100,25},title="value:",bodyWidth=40,value=CursorValue[%$CursorName_B],limits={0,inf,0},Win=$GraphPanelName

button But_pTofCursor pos={40,45},size={70,20}, title="use Cursors",win=$(Graphname+"#panel4but"),proc=MARAbut_pToF_but

END

//======================================================================================
//======================================================================================

// Purpose:		calculate the fraction of single charged particles from pToF data

// Input:		type: 0: AN, 1: AS, 2: other
// Output:		fraction of single particles will be updated in Panel variable
// called by:	MARAbut_buttonPROCS()

FUNCTION MARAbut_pToF_but(B_struct) : ButtonControl

Struct WMbuttonAction &B_struct

IF(B_struct.eventCode==2)	
	
	SVAR abortStr=root:MARA:abortStr
	
	// get Panel values
	String Graphname=B_struct.win
	Graphname=Stringfromlist(0,Graphname,"#")
	String ID=Stringfromlist(2,GraphName,"_")
	
	Wave pToF_DPidx=root:MARA:pToF_DPidx
	Wave CursorPos=Root:MARA:CursorPos
	
	// set new Values
	pToF_DPidx[%$ID][0]=CursorPos[%$("pTof_"+ID+"_A")]
	pToF_DPidx[%$ID][1]=CursorPos[%$("pTof_"+ID+"_B")]
	
ENDIF


END

//======================================================================================
//======================================================================================

// Purpose:		calculate the fraction of single charged particles from pToF data

// Input:		type: 0: AN, 1: AS, 2: other
// Output:		fraction of single particles will be updated in Panel variable
// called by:	MARAbut_buttonPROCS()

FUNCTION MARAbut_calcMulti(type,Wavenames)

variable Type
Wave/T wavenames

String TypeStr=""	//AN, AS,O
String NameIon1=""
String NameIon2=""

SVAR abortStr=root:MARA:abortStr

Variable ii

Wave pToF_Dpidx=root:MARA:ptof_dpidx

// set up names depending on Type
SWITCH (Type)
	CASE 0:	//AN
		TypeStr="AN"
		BREAK
		
	CASE 1:	//AS
		TypeStr="AS"
		BREAK
	
	CASE 2:	//other
		TypeStr="O"

		BREAK
	DEFAULT:
		abortStr="MARAbut_calcMulti("+TypeStr+"):\r\runable to determine type from passed value\r\r"+num2Str(Type)
		MARAaux_abort(abortStr)
		BREAK
ENDSWITCH

// check if fields are empty
IF (strlen(Wavenames[%AMS_pToF_Dp][%$TypeStr])==0)	// empty
	abortStr="MARAbut_calcMulti("+TypeStr+"):\r\rpToF Dp field is empty. Insert a valid wave name and try again."
	MARAaux_abort(abortStr)
ENDIF
IF (strlen(Wavenames[%AMS_pToF_signal][%$TypeStr])==0)	// empty
	abortStr="MARAbut_calcMulti("+TypeStr+"):\r\rpToF signal field is empty. Insert a valid wave name and try again."
	MARAaux_abort(abortStr)
ENDIF

// get waves
String DpStr="root:"+Wavenames[%AMS_pToF_Dp][%$TypeStr]
String pToFStr="root:"+Wavenames[%AMS_pToF_signal][%$TypeStr]

DpStr= replacestring("root:Root:",DpStr,"Root:")
DpStr= replacestring("root::",DpStr,"Root:")
pToFStr= replacestring("root:Root:",pToFStr,"Root:")
pToFStr= replacestring("root::",pToFStr,"Root:")

Wave/Z Dp=$Dpstr
Wave/Z pToF=$pToFstr

//check is waves exist
IF (!Waveexists(Dp))	// wave exists?
	abortStr="MARAbut_plotPToF("+TypeStr+"):\r\rpToF Dp wave does not exist:\r\r"+DpStr
	MARAaux_abort(abortStr)	
ENDIF
IF (!Waveexists(pToF))	// wave exists?
	abortStr="MARAbut_plotPToF("+TypeStr+"):\r\rpToF signal wave does not exist:\r\r"+pToFStr
	MARAaux_abort(abortStr)	
ENDIF


// calculate single charged particle fraction
IF (pToF_Dpidx[%$TypeStr][0]==0 && pToF_Dpidx[%$TypeStr][1]==0)
	// catch both values =0 -> no values set

ELSE
	// convert Dp to log Dp
	Duplicate/FREE DP, Dp_log
	Dp_log=log(Dp)
	
	//clean up "zeros"
	Dp_log = numtype(Dp_log[p]) == 0? Dp_log[p] : -10+1/(p+1)
	
	// integrate
	Variable totalSignal=areaXY(Dp_log,pToF)
	Variable singleSignal=areaXY(Dp_log,pToF,Dp_log[pToF_Dpidx[%$TypeStr][0]],Dp_log[pToF_Dpidx[%$TypeStr][1]])

	NVAR Frac_single=$("root:MARA:"+TypeStr+"_Frac_single_VAR")
	Frac_single=singleSignal/totalSignal
	// for testing
//	print "-----------"
//	print "logDp"	
//	print areaXY(Dp_log,pToF)
//	print areaXY(Dp_log,pToF,Dp_log[pToF_Dpidx[%$TypeStr][0]],Dp_log[pToF_Dpidx[%$TypeStr][1]])
//	print areaXY(Dp_log,pToF,Dp_log[pToF_Dpidx[%$TypeStr][0]],Dp_log[pToF_Dpidx[%$TypeStr][1]])/areaXY(Dp_log,pToF)
//	print "-----------"
//	print "Dp"	
//	print areaXY(Dp,pToF)
//	print areaXY(Dp,pToF,Dp[pToF_Dpidx[%$TypeStr][0]],Dp[pToF_Dpidx[%$TypeStr][1]])
//	print areaXY(Dp,pToF,Dp[pToF_Dpidx[%$TypeStr][0]],Dp[pToF_Dpidx[%$TypeStr][1]])/areaXY(Dp,pToF)
	
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		calcualte IE for nitrate in AN and RIE for everything else
//				1) calculate averages from intervals
//				2) convert CPC to molec and picog sec
//				3) plot results and fit
//
//				the averaging algorithm ignors the fact that AMS time stamp is at the END of hte measurement interval
// Input:		type: 0: AN, 1: AS, 2: other
// Output:		results are displayed in Panel and stored in waves
//				results waves will be put in same place as AMS tseries wave
//				all results waves start with the TypeStr (AN etc)
// called by:	MARAbut_buttonPROCS()

FUNCTION MARAbut_calcRIE(type,wavenames)

variable Type
Wave/T wavenames

String TypeStr=""	//AN, AS,O
String NameIon1=""
String NameIon2=""
String NameRIEion=""

SVAR abortStr=root:MARA:abortStr

Variable ii,testEmpty=0

Wave pToF_Dpidx=root:MARA:ptof_dpidx

// set up names depending on Type
SWITCH (Type)
	CASE 0:	//AN
		TypeStr="AN"
		NameIon1="NH4"
		NameIon2="NO3"
		NameRIEion="NH4"
		BREAK
		
	CASE 1:	//AS
		TypeStr="AS"
		NameIon1="NH4"
		NameIon2="SO4"
		NameRIEion="SO4"
		BREAK
	
	CASE 2:	//other
		TypeStr="O"
		NameIon1="ion1"
		NameIon2="ion2"
		NameRIEion="ion2"
		
		// check if second ion name is empty -> use ion1 twice
		IF (Stringmatch(Wavenames[%AMS_anion_hz][%$TypeStr],""))
			Wavenames[%AMS_anion_hz][%$TypeStr]=Wavenames[%AMS_cation_hz][%$TypeStr]
			testEmpty=1
		ENDIF
		
		BREAK
	DEFAULT:
		abortStr="MARAbut_calcRIE("+TypeStr+"):\r\runable to determine type from passed value\r\r"+num2Str(Type)
		MARAaux_abort(abortStr)
		BREAK

ENDSWITCH

// get input waves and parameters
// get parameters from Panel
Wave Params4Calc=root:MARA:Params4calc

IF (!Waveexists(Params4Calc))//	check for wave
	abortStr= "MARAbut_calcRIE("+TypeStr+"):\r\Params4Calc wave not found in folder root:MARA. Check if MARA Panel is active and start again"
	MARAaux_abort(abortStr)	
ENDIF

// make variables for easier reading of formulas
Variable MW_salt=Params4calc[%VARn_MW_salt][%$TypeStr]	//	g/mol
Variable MW_anion=Params4calc[%VARn_MW_anion][%$TypeStr]	//	g/mol
Variable MW_cation=Params4calc[%VARn_MW_cation][%$TypeStr]	//	g/mol

Variable DP_set=Params4calc[%VARn_DpDMA][%$TypeStr]*1e-7	// convert nm -> cm
Variable density=Params4calc[%VARn_density][%$TypeStr]		// g/cm3
Variable shape=Params4calc[%VARn_shape][%$TypeStr]			// no unit
Variable AMS_flow=Params4calc[%VARn_AMS_flow][%$TypeStr]/60		// convert sccm cm3/min -> cm3/sec

Variable NA=6.022e23	//Avogadro Number

// check if all waves are there
String WaveStr="AMS_tseries;AMS_cation_hz;AMS_anion_hz;CPC_tseries;CPC_numConc;"
String ListWaveStr=""

FOR (ii=0;ii<itemsinlist(WaveStr);ii+=1)
	listWaveStr+="root:"+Wavenames[%$Stringfromlist(ii,WaveStr)][%$TypeStr]+";"	
ENDFOR
listWaveStr= replacestring("root:Root:",listWaveStr,"Root:")
listWaveStr= replacestring("root::",listWaveStr,"Root:")

IF (MARAaux_CheckWavesFromList(listWaveStr)!=1)
	Wave NonExistIdx
	abortStr="MARAbut_calcRIE("+TypeStr+"):\r\rOne or more waves not found. Check history for missing wave names."
	
	print "--------------------------------"
	print date() + " "+ time()
	print "MARAbut_calcRIE: missing waves"
	FOR (ii=0;ii<numpnts(NonExistIdx);ii+=1)
		print Stringfromlist(nonexistidx[ii],listWaveStr)
	ENDFOR
	
	MARAaux_abort(abortStr)
ENDIF

// assign waves
// data waves with high time resolution
Wave AMS_tseries=$Stringfromlist(0,listWaveStr)
Wave AMS_cation_hz=$Stringfromlist(1,listWaveStr)
Wave AMS_anion_hz=$Stringfromlist(2,listWaveStr)

WAVE CPC_tseries=$Stringfromlist(3,listWaveStr)
Wave CPC_conc=$Stringfromlist(4,listWaveStr)

String/G ResultFolder=getWavesdatafolder(AMS_cation_hz,1)+"RIE"	// loaction of kation tseries wave

Newdatafolder/S/O $ResultFOlder

//------------------------
// average data

// convert from text to numeric
Wave/T AMS_intervalTime=$("root:MARA:AMS_"+TypeStr+"_IntervalTime")
SVAR TimeFormat_STR=root:MARA:TimeFormat_STR

Make/D/O/N=(dimsize(AMS_intervalTime,0),dimsize(AMS_intervalTime,1)) $(TypeStr+"_AvgInterval_time")//, AvgInterval_idx_AMS,AvgInterval_CPC
Wave AvgInterval_time=$(TypeStr+"_AvgInterval_time")
Setscale d 0,0, "dat", AvgInterval_time

AvgInterval_time=MARAaux_String2js(AMS_intervalTime, TimeFormat_STR,noabort=1)

//check for conversion problem (-999 is problem value)
FindValue /V=-999 Avginterval_time
IF (V_value>-1)	//-> at least one entry is -999
	abortStr="MARAbut_calcRIE("+TypeStr+"):\r\rProblem with converting Avgerage Interval Time strings to numeric values. Check history for details."
	setdatafolder root:
	MARAaux_abort(abortStr)
ENDIF

// check if everything is empty
Wavestats/Q AvgInterval_time
IF (V_npnts==0)
	abortstr="MARAbut_calcRIE("+TypeStr+"):\r\rAll entries in the Averaging Interval Table are empty. Insert at least one start/stop pair and try again."
	setdatafolder root:
	MARAaux_abort(abortStr)
ENDIF

// remove empty rows (also from table)
Variable noi=dimsize(AvgInterval_time,0)	// number of intervals in wave

FOR (ii=noi-1;ii>-1;ii-=1)
	IF (numtype(AvgInterval_time[ii][0])!=0 && numtype(AvgInterval_time[ii][1])!=0)
		// both are Nan -> remove row
		deletepoints/M=0 ii,1,AvgInterval_time
		deletepoints/M=0 ii,1,AMS_intervalTime
	ENDIF
ENDFOR

// check if there are still NaNs
Wavestats/Q AvgInterval_time
IF (V_numnans>0)
	abortstr="MARAbut_calcRIE("+TypeStr+"):\r\rAt least one entry in the Average Interval Table lead to a NaN value. Check input."
	setdatafolder root:
	MARAaux_abort(abortStr)
ENDIF

// prepare result waves
noi=dimsize(AvgInterval_time,0)	// check again in case it changed

Make/O/D/N=(noi) $(TypeStr+"_AMS_"+NameIon1+"_Hz")	// waves with average value
Make/O/D/N=(noi) $(TypeStr+"_AMS_"+NameIon2+"_Hz")
Make/O/D/N=(noi) $(TypeStr+"_AMS_tseries")

Wave AMS_cation_HZ_avg=$(TypeStr+"_AMS_"+NameIon1+"_Hz")
Wave AMS_anion_HZ_avg=$(TypeStr+"_AMS_"+NameIon2+"_Hz")
Wave AMS_tseries_avg=$(TypeStr+"_AMS_tseries")

Make/O/D/N=(noi) $(TypeStr+"_AMS_"+NameIon1+"_Hz_MCC")	// waves with average value -> multi charge corrected
Make/O/D/N=(noi) $(TypeStr+"_AMS_"+NameIon2+"_Hz_MCC")

Wave AMS_cation_HZ_MCC=$(TypeStr+"_AMS_"+NameIon1+"_Hz_MCC")
Wave AMS_anion_HZ_MCC=$(TypeStr+"_AMS_"+NameIon2+"_Hz_MCC")

Make/O/D/N=(noi) $(TypeStr+"_CPC_conc")	
Make/O/D/N=(noi) $(TypeStr+"_CPC_tseries")

Wave CPC_conc_avg=$(TypeStr+"_CPC_conc")
Wave CPC_tseries_avg=$(TypeStr+"_CPC_tseries")

Make/O/D/N=(noi) $(TypeStr+"_AMS_"+NameIon1+"_Hz_sdev")	// waves with stdev
Make/O/D/N=(noi) $(TypeStr+"_AMS_"+NameIon2+"_Hz_sdev")
Make/O/D/N=(noi) $(TypeStr+"_AMS_tseries_sdev")

Wave AMS_cation_HZ_sdev=$(TypeStr+"_AMS_"+NameIon1+"_Hz_sdev")
Wave AMS_anion_HZ_sdev=$(TypeStr+"_AMS_"+NameIon2+"_Hz_sdev")
Wave AMS_tseries_sdev=$(TypeStr+"_AMS_tseries_sdev")

Make/O/D/N=(noi) $(TypeStr+"_CPC_conc_sdev")
Make/O/D/N=(noi) $(TypeStr+"_CPC_tseries_sdev")

Wave CPC_conc_sdev=$(TypeStr+"_CPC_conc_sdev")
Wave CPC_tseries_sdev=$(TypeStr+"_CPC_tseries_sdev")

Setscale d 0,0, "dat", AMS_tseries_avg,AMS_tseries_sdev,CPC_tseries_avg,CPC_tseries_sdev

// extract intervals
FOR (ii=0;ii<noi;ii+=1)
	
	// AMS
	Extract/INDX/FREE AMS_tseries, SliceIDX, AMS_tseries>AvgInterval_time[ii][0] && AMS_tseries<AvgInterval_time[ii][1]

	SWITCH (numpnts(SliceIDX))
		CASE 0:		// no points found
			AMS_tseries_avg[ii]=AvgInterval_time[ii][0]
			AMS_tseries_sdev[ii]=0
			
			AMS_cation_HZ_avg[ii]=NaN
			AMS_cation_HZ_sdev[ii]=NaN
			AMS_anion_HZ_avg[ii]=NaN
			AMS_anion_HZ_sdev[ii]=NaN
			
			BREAK
			
		CASE 1:		// only 1 point found
			AMS_tseries_sdev[ii]=(AMS_tseries[SliceIDX[0]]-AMS_tseries[sliceIDX[numpnts(sliceIDX)-1]])/2
			AMS_tseries_avg[ii]=AMS_tseries[SliceIDX[0]]+AMS_tseries_sdev[ii]
			
			AMS_cation_HZ_avg[ii]=AMS_cation_HZ[SliceIDX[0]]
			AMS_cation_HZ_sdev[ii]=0
			AMS_anion_HZ_avg[ii]=AMS_anion_HZ[SliceIDX[0]]
			AMS_anion_HZ_sdev[ii]=0
						
			BREAk
			
		DEFAULT:	// at least 2 points found
			// time
			AMS_tseries_sdev[ii]=(AMS_tseries[sliceIDX[numpnts(sliceIDX)-1]]-AMS_tseries[SliceIDX[0]])/2
			AMS_tseries_avg[ii]=AMS_tseries[SliceIDX[0]]+AMS_tseries_sdev[ii]
			
			// cation
			WaveStats/Q/R=[SliceIDX[0],sliceIDX[numpnts(sliceIDX)-1]] AMS_cation_HZ
			AMS_cation_HZ_avg[ii]=V_avg
			AMS_cation_HZ_sdev[ii]=V_sdev
			
			// anion
			WaveStats/Q/R=[SliceIDX[0],sliceIDX[numpnts(sliceIDX)-1]] AMS_anion_HZ
			AMS_anion_HZ_avg[ii]=V_avg
			AMS_anion_HZ_sdev[ii]=V_sdev
			BREAK
	ENDSWITCH
	//--------------------------------
	// CPC
	Extract/INDX/FREE CPC_tseries, SliceIDX, CPC_tseries>AvgInterval_time[ii][0] && CPC_tseries<AvgInterval_time[ii][1]

	SWITCH (numpnts(SliceIDX))
		CASE 0:		// no points found
			CPC_tseries_avg[ii]=AvgInterval_time[ii][0]
			CPC_tseries_sdev[ii]=0
			
			CPC_conc_avg[ii]=NaN
			CPC_conc_sdev[ii]=NaN
							
			BREAK
			
		CASE 1:		// only 1 point found
			CPC_tseries_sdev[ii]=(CPC_tseries[SliceIDX[0]]-CPC_tseries[sliceIDX[numpnts(sliceIDX)-1]])/2
			CPC_tseries_avg[ii]=CPC_tseries[SliceIDX[0]]+CPC_tseries_sdev[ii]
			
			CPC_conc_avg[ii]=CPC_conc[SliceIDX[0]]
			CPC_conc_sdev[ii]=0
									
			BREAk
			
		DEFAULT:	// at least 2 points found
			// time
			CPC_tseries_sdev[ii]=(CPC_tseries[sliceIDX[numpnts(sliceIDX)-1]]-CPC_tseries[SliceIDX[0]])/2
			CPC_tseries_avg[ii]=CPC_tseries[SliceIDX[0]]+CPC_tseries_sdev[ii]
			
			// cation
			WaveStats/Q/R=[SliceIDX[0],sliceIDX[numpnts(sliceIDX)-1]] CPC_conc
			CPC_conc_avg[ii]=V_avg
			CPC_conc_sdev[ii]=V_sdev
			
			BREAK
	ENDSWITCH

	
ENDFOR	// interval loop

// apply multicharge correction to AMS values
NVAR Frac_Single_VAR=$("root:MARA:"+TypeStr+"_Frac_Single_VAR")

AMS_cation_HZ_MCC=Frac_Single_VAR*AMS_cation_HZ_avg
AMS_anion_HZ_MCC=Frac_Single_VAR*AMS_anion_HZ_avg

// calculate values for RIE direct fit
Make/O/D/N=(noi) $(TypeStr+"_AMS_"+NameIon1+"_4RIE")	// waves used for direct RIE fitting
Make/O/D/N=(noi) $(TypeStr+"_AMS_"+NameIon2+"_4RIE")

Wave AMS_cation_4RIE=$(TypeStr+"_AMS_"+NameIon1+"_4RIE")
Wave AMS_anion_4RIE=$(TypeStr+"_AMS_"+NameIon2+"_4RIE")

AMS_cation_4RIE=AMS_cation_HZ_MCC*MW_anion	// signal in Hz * MW of other ion
AMS_anion_4RIE=AMS_anion_HZ_MCC*MW_cation

//------------------------
// CPC based values

// prepare results wave
Make/D/O/N=(numpnts(CPC_tseries_avg)) $(TypeStr+"_CPC_molec")
Wave CPC_molec=$(TypeStr+"_CPC_molec")

Make/D/O/N=(numpnts(CPC_tseries_avg)) $(TypeStr+"_CPC_mass_"+NameIon1)
Wave CPC_mass_cation=$(TypeStr+"_CPC_mass_"+NameIon1)

Make/D/O/N=(numpnts(CPC_tseries_avg)) $(TypeStr+"_CPC_mass_"+NameIon2)
Wave CPC_mass_anion=$(TypeStr+"_CPC_mass_"+NameIon2)

// molecules of salt measured with CPC (unit 1/s = Hz)
CPC_molec = CPC_conc_avg*pi/6*Dp_set^3*density*shape*AMS_flow/MW_salt*NA	

// Signal of anion
CPC_mass_anion = CPC_molec*MW_anion/NA*1e12	// unit is  picogramm per second

// signal of cation
CPC_mass_cation = CPC_molec*MW_cation/NA*1e12 // unit is  picogramm per second

IF (stringmatch(typeStr, "AS"))	// $$$$ not sure about this: for AS we have 2 NH4 in each unit -> *2
	CPC_mass_cation*=2
ENDIF

// add values to table
String TableName="MARA_Panel#TBL_"+typeStr+"_interval"
Appendtotable/W=$tableName AMS_cation_HZ_avg,AMS_cation_HZ_MCC,AMS_anion_HZ_avg,AMS_anion_HZ_MCC,CPC_conc_avg,CPC_molec,CPC_mass_cation,CPC_mass_anion

//------------------------
// fit data for IE(NO3) and RIE

// waves for results	
Make/O/D/N=(4,2) $(TypeStr+"_fitparams")	// first column slope, second column sigma
Wave Fitparams=$(TypeStr+"_fitparams")

// set dim labels
setDimLabel 1,0,slope,Fitparams
SetDimLabel 1,1,sigma,Fitparams

String DummyLabel=NameIon2+"_IE"
SetDimlabel 0,0,$DummyLabel,Fitparams
DummyLabel=NameIon1+"_mIE"
SetDimlabel 0,1,$DummyLabel,Fitparams
DummyLabel=NameIon2+"_mIE"
SetDimlabel 0,2,$DummyLabel,Fitparams
DummyLabel=NameRIEion+"_RIE"
SetDimlabel 0,3,$DummyLabel,Fitparams

// fit values for plotting (must have same length as data waves)
Make/D/O/N=(noi) $(TypeStr+"_fit_IE_"+NameIon2)
Wave fitWave_IE=$(TypeStr+"_fit_IE_"+NameIon2)
fitWave_IE=CPC_mass_cation

Make/D/O/N=(noi) $(TypeStr+"_fit_mIE_"+NameIon1)
Wave fitWave_mIE_cation=$(TypeStr+"_fit_mIE_"+NameIon1)

Make/D/O/N=(noi) $(TypeStr+"_fit_mIE_"+NameIon2)
Wave fitWave_mIE_anion=$(TypeStr+"_fit_mIE_"+NameIon2)

Make/D/O/N=(noi) $(TypeStr+"_fit_RIE_"+NameRIEion)	// only used for AS and AN
Wave fitWave_RIE=$(TypeStr+"_fit_RIE_"+NameRIEion)

// AMS NO3 hz vs CPC molec
CurveFit/Q line, AMS_anion_HZ_MCC /X=CPC_molec/D=fitWave_IE/NWOK
Wave W_coef
Wave W_sigma

Fitparams[%$(NameIon2+"_IE")][0]=W_coef[1]	// slope
Fitparams[%$(NameIon2+"_IE")][1]=w_sigma[1]	// fit error

// AMS cation hz vs CPC cation mass/s
CurveFit/Q line, AMS_cation_HZ_MCC /X=CPC_mass_cation/D=fitWave_mIE_cation/NWOK
Wave W_coef
Wave W_sigma

Fitparams[%$(NameIon1+"_mIE")][0]=W_coef[1]	// slope
Fitparams[%$(NameIon1+"_mIE")][1]=w_sigma[1]	// fit error

// AMS anion hz vs CPC anion mass/s
CurveFit/Q line, AMS_anion_HZ_MCC /X=CPC_mass_anion/D=fitWave_mIE_anion/NWOK
Wave W_coef
Wave W_sigma

Fitparams[%$(NameIon2+"_mIE")][0]=W_coef[1]	// slope
Fitparams[%$(NameIon2+"_mIE")][1]=w_sigma[1]	// fit error

// calculate (R)IE
Make/O/D/N=(5) $(TypeStr + "_RIE_values")	// store in data folder
Wave RIE_values=$(TypeStr + "_RIE_values")

String labeldummy="IE_NO3"
Setdimlabel 0,0,$labeldummy, RIE_values
labeldummy="mIE_"+nameIon1
Setdimlabel 0,1,$labeldummy, RIE_values
labeldummy="mIE_"+nameIon2
Setdimlabel 0,2,$labeldummy, RIE_values
labeldummy="RIE_"+nameIon1
Setdimlabel 0,3,$labeldummy, RIE_values
labeldummy="RIE_"+nameIon2
Setdimlabel 0,4,$labeldummy, RIE_values

wave RIE_values_panel=root:MARA:RIE_values	// values for Panel display

RIE_values[0]=Fitparams[%$(NameIon2+"_IE")][0]
RIE_values[1]=Fitparams[%$(NameIon1+"_mIE")][0]
RIE_values[2]=Fitparams[%$(NameIon2+"_mIE")][0]

SWITCH (Type)
	CASE 0:	//AN
		// mIE method
		// RIE_values[3]=Fitparams[%$(NameIon1+"_mIE")][0]/Fitparams[%$(NameIon2+"_mIE")][0]	
		// RIE_values[4]=NaN
		
		//direct fit method
		CurveFit/Q line, AMS_cation_4RIE /X=AMS_anion_4RIE/D=fitWave_RIE/NWOK
		Wave W_coef
		Wave W_sigma
		Fitparams[%$(NameIon1+"_RIE")][0]=W_coef[1]		// slope
		Fitparams[%$(NameIon1+"_RIE")][1]=w_sigma[1]	// fit error
	
		RIE_Values[%$("RIE_"+NameRIEion)]=Fitparams[%$(NameRIEion+"_RIE")][0]	// slope of NH4 vs NO3 fit
		
		BREAK
		
	CASE 1:	//AS
		// check for RIE (NH4)
		IF (numtype(RIE_values_Panel[3][0])!=0)
			// activate the IE field for user input
			ControlInfo /W=MARA_Panel AN_box
			Titlebox TB_AN_RIE_1 pos={V_right+10+2*257-122,V_top+190+5+21}, title="\f01IE(NO3):",fsize=12,frame=0,win=MARA_Panel 
			Setvariable VARn_RIE_ion1 value=RIE_values_Panel[%IE_NO3][0], Title=" ",pos={V_right+10+257-122+45,V_top+190+5+20},limits={-inf,inf,0}, size={70,20},fsize=12,win=MARA_Panel 
	
			abortStr="RIE calculation requires an RIE value for NH4 but no RIE(NH4) value is found. Please, process a Ammonium Nitrate calibration first or insert a known IE(NO3) value in the Panel field."
			MARAaux_abort(abortStr)
		ENDIF
		
		// store used RIE NH4 value
		RIE_values[0]=RIE_values_Panel[3][0]
		setdimlabel 0,0,RIE_NH4_AN,RIE_values

		//calculate RIE

		//mIE method
		// RIE_values[4]=RIE_values_Panel[3][0]/(Fitparams[%$(NameIon1+"_mIE")][0]/Fitparams[%$(NameIon2+"_mIE")][0])
		// RIE_values[3]=NaN

		// direct fit method
		AMS_anion_4RIE*=2	// to account for 2 NH4 and 1 SO4 !
		AMS_anion_4RIE*=RIE_values[0]	// multiply SO4 signal with RIE_NH4(AN)
		
		CurveFit/Q line, AMS_anion_4RIE /X=AMS_cation_4RIE/D=fitWave_RIE/NWOK
		Wave W_coef
		Wave W_sigma
		Fitparams[%$(NameRIEion+"_RIE")][0]=W_coef[1]		// slope
		Fitparams[%$(NameRIEion+"_RIE")][1]=w_sigma[1]	// fit error

		RIE_Values[%$("RIE_"+NameRIEion)]=Fitparams[%$(NameRIEion+"_RIE")][0]	// slope of SO4 vs NH4 fit

		BREAK
	
	CASE 2:	//other
		// check for IE of NO3
		IF (numtype(RIE_values_Panel[0][0])!=0)
			// activate the IE field for user input
			ControlInfo /W=MARA_Panel AN_box
			
			Titlebox TB_AN_RIE_2 pos={V_right+10+257-122,V_top+190+5+21}, title="\f01IE(NO3):",fsize=12,frame=0,win=MARA_Panel 
			Setvariable VARn_IE_anion value=RIE_values_Panel[%IE_NO3][0], Title=" ",pos={V_right+10+257-122+45,V_top+190+5+20},limits={-inf,inf,0}, size={70,20},fsize=12,win=MARA_Panel 
	
			abortStr="RIE calculation requires an IE value for NO3 but no IE(NO3) value is found. Please, process a Ammonium Nitrate calibration first or insert a known IE(NO3) value in the Panel field."
			MARAaux_abort(abortStr)
		ENDIF

		// convert IE_NO3 to mass based
		Variable mIE_NO3=(RIE_values_Panel[%IE_NO3][0])*1e-12*6.022e23/62.004
		RIE_values[0]=RIE_values_Panel[%IE_NO3][0]
		// calc RIE
		RIE_values[3]=Fitparams[%$(NameIon1+"_mIE")][0]/mIE_NO3
		RIE_values[4]=Fitparams[%$(NameIon2+"_mIE")][0]/mIE_NO3

		BREAK

ENDSWITCH

RIE_values_Panel[][%$TypeStr]=RIE_values[p]	// store for use in Panel

//------------------------
// plot data in panel

MARAbut_panelplots(type,resultFolder)

// tidy up
Killwaves/Z NonExistIDX,W_coef, W_sigma

// remove dummy entry from Wavenames
IF (testEmpty==1)
	Wavenames[%AMS_anion_hz][%$TypeStr]=""
ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		top layer routine to draw plots in panel for 1 calibration compound
//				use this after averages and CPC related conc values were calculated
//				can also be used to redraw plots
// Input:		type: 0: AN, 1: AS, 2: other	-> to determin ion names etc
//				resultsFolder:	folder where the waves are living
//
// Output:		plots needed to determine slopes for IE and RIE
// called by:	MARAbut_calcRIE() 

FUNCTION MARAbut_panelplots(type,Foldername)

Variable Type
String Foldername

SVAR abortStr=root:MARA:abortStr

//---------------------------------
// prepare information for plotting

String TypeStr=""	//AN, AS,O
String NameIon1=""
String NameIon2=""
String NameRIEx=""
String nameRIEy=""

Variable ii
Variable doIE=0	// 0: no IE related things, 1: do the IE related things ()

// set up names depending on Type
SWITCH (Type)
	CASE 0:	//AN
		TypeStr="AN"
		NameIon1="NH4"	// cation
		NameIon2="NO3"	// anion
		NameRIEx="NO3"	// ion on xaxis of RIE plot
		NameRIEy="NH4"	// ion on xaxis of RIE plot
		doIE=1
		BREAK
		
	CASE 1:	//AS
		TypeStr="AS"	//
		NameIon1="NH4"
		NameIon2="SO4"
		NameRIEx="NH4"	// ion on xaxis of RIE plot
		NameRIEy="SO4"	// ion on xaxis of RIE plot
		BREAK
	
	CASE 2:	//other
		TypeStr="O"
		NameIon1="ion1"
		NameIon2="ion2"
		NameRIEx="ion1"	// ion on xaxis of RIE plot
		NameRIEy="ion2"	// ion on xaxis of RIE plot

		BREAK
	DEFAULT:
		abortStr="MARAbut_panelplots("+TypeStr+"):\r\rUnable to determine type from passed value\r\r"+num2Str(Type)
		MARAaux_abort(abortStr)
		BREAK

ENDSWITCH

// variables for drawing Panel plots
Wave/T PanelPlotInfo_STR=root:MARA:PanelPlotInfo_STR
Wave/T OnePlotInfo_STR=root:MARA:OnePlotInfo_STR
Wave PanelPlotInfo_VAR=root:MARA:PanelPlotInfo_VAR
Wave OnePlotInfo_VAR=root:MARA:OnePlotInfo_VAR

Wave FitParams=$(Foldername+":"+TypeStr+"_Fitparams")

// set values
Variable PlotWidth=257

String Boxname=TypeStr+"_box"	// this is th ebox araound each compound -> give x and y locations
ControlInfo /W=MARA_Panel $BoxName

PanelPlotInfo_VAR[%pos_x][][type]=V_right+(q+1)*10+q*plotWidth	// x position of each graph
IF (Type!=0)	// AN can have 3 plots
	PanelPlotInfo_VAR[%pos_x][2,3][type]=V_right+(q-1)*10+(q-2)*plotWidth
ENDIF
PanelPlotInfo_VAR[%pos_y][][type]=V_top+20						// y position of first graph
PanelPlotInfo_VAR[%width][][type]=plotWidth						// plot width
PanelPlotInfo_VAR[%height][][type]=190							// plot height

PanelPlotInfo_VAR[%slope][0][type]=Fitparams[%$(NameIon2+"_IE")][0]
PanelPlotInfo_VAR[%slope][1][type]=Fitparams[%$(NameRIEy+"_RIE")][0]	// RIE with direct signal fit
PanelPlotInfo_VAR[%slope][2][type]=Fitparams[%$(NameIon1+"_mIE")][0]	// mIE for other type
PanelPlotInfo_VAR[%slope][3][type]=Fitparams[%$(NameIon2+"_mIE")][0]	// mIE for other type

//set names
//xwaves
PanelPlotInfo_STR[%name_xwave][0][Type]=Foldername+":"+TypeStr+"_CPC_molec"
PanelPlotInfo_STR[%name_xwave][1][Type]=Foldername+":"+TypeStr+"_AMS_"+nameRIEx+"_4RIE"
PanelPlotInfo_STR[%name_xwave][2][Type]=Foldername+":"+TypeStr+"_CPC_mass_"+NameIon1
PanelPlotInfo_STR[%name_xwave][3][Type]=Foldername+":"+TypeStr+"_CPC_mass_"+NameIon2
//ywaves
PanelPlotInfo_STR[%name_ywave][0][Type]=Foldername+":"+TypeStr+"_AMS_"+NameIon2+"_Hz_MCC"
PanelPlotInfo_STR[%name_ywave][1][Type]=Foldername+":"+TypeStr+"_AMS_"+nameRIEy+"_4RIE"
PanelPlotInfo_STR[%name_ywave][2][Type]=Foldername+":"+TypeStr+"_AMS_"+NameIon1+"_Hz_MCC"
PanelPlotInfo_STR[%name_ywave][3][Type]=Foldername+":"+TypeStr+"_AMS_"+NameIon2+"_Hz_MCC"
//fit waves
PanelPlotInfo_STR[%name_fitywave][0][Type]=Foldername+":"+TypeStr+"_fit_IE_"+NameIon2
PanelPlotInfo_STR[%name_fitywave][1][Type]=Foldername+":"+TypeStr+"_fit_RIE_"+nameRIEy
PanelPlotInfo_STR[%name_fitywave][2][Type]=Foldername+":"+TypeStr+"_fit_mIE_"+NameIon1
PanelPlotInfo_STR[%name_fitywave][3][Type]=Foldername+":"+TypeStr+"_fit_mIE_"+NameIon2

PanelPlotInfo_STR[%name_fitxwave][][Type]=PanelPlotInfo_STR[%name_xwave][q]

//Labels x axis
PanelPlotInfo_STR[%label_x][0][Type]=NameIon2+" molecules / molec/sec"
PanelPlotInfo_STR[%label_x][1][Type]= "signal("+NameRIEx+")*Mw("+NameRIEy+")"
PanelPlotInfo_STR[%label_x][2][Type]= NameIon1 + "/ pg/sec"
PanelPlotInfo_STR[%label_x][3][Type]=NameIon2 + "/ pg/sec"
// labels y axis
PanelPlotInfo_STR[%label_y][0][Type]=NameIon2+" signal / hz"
PanelPlotInfo_STR[%label_y][1][Type]= "signal("+NameRIEy+")*Mw("+NameRIEx+")"
If (Type==1)	// catch AS needing factor 2
	PanelPlotInfo_STR[%label_y][1][Type]= "signal("+NameRIEy+")*2*Mw("+NameRIEx+")"
ENDIF
PanelPlotInfo_STR[%label_y][2][Type]= NameIon1+" signal / hz"
PanelPlotInfo_STR[%label_y][3][Type]=NameIon2+" signal / hz"
// plot type
PanelPlotInfo_STR[%plotType][0][Type]="IE"
PanelPlotInfo_STR[%plotType][1][Type]= "RIE"
PanelPlotInfo_STR[%plotType][2][Type]= "mIE"
PanelPlotInfo_STR[%plotType][3][Type]="mIE"


// slope info Str (catching +/-Inf in fit error)
String infoStr
// IE NO3
IF (numtype(Fitparams[%$(NameIon2+"_IE")][1])==0)
	sprintf infoStr,"IE: %1.4e\r      +/- %1.2e",Fitparams[%$(NameIon2+"_IE")][0],Fitparams[%$(NameIon2+"_IE")][1]
ELSE
	sprintf infoStr,"IE: %1.4e\r      +/- inf",Fitparams[%$(NameIon2+"_IE")][0]
ENDIF
PanelPlotInfo_STR[%infoStr][0][Type]=infoStr

// RIE
IF (numtype(Fitparams[%$(NameRIEy+"_RIE")][1])==0)
	sprintf infoStr,"RIE: %.4g\r        +/- %.2g",Fitparams[%$(NameRIEy+"_RIE")][0],Fitparams[%$(NameRIEy+"_RIE")][1]
ELSE
	sprintf infoStr,"RIE: %.4g\r      +/- inf",Fitparams[%$(NameRIEy+"_RIE")][0]
ENDIF
PanelPlotInfo_STR[%infoStr][1][Type]=infoStr

// mIE 1
IF (numtype(Fitparams[%$(NameIon1+"_mIE")][1])==0)
	sprintf infoStr,"mIE: %.2d\r        +/- %.1d",Fitparams[%$(NameIon1+"_mIE")][0],Fitparams[%$(NameIon1+"_mIE")][1]
ELSE
	sprintf infoStr,"mIE: %.2d\r      +/- inf",Fitparams[%$(NameIon1+"_mIE")][0]
ENDIF
PanelPlotInfo_STR[%infoStr][2][Type]=infoStr

//mIE2
IF (numtype(Fitparams[%$(NameIon2+"_mIE")][1])==0)
	sprintf infoStr,"mIE: %.2d\r        +/- %.1d",Fitparams[%$(NameIon2+"_mIE")][0],Fitparams[%$(NameIon2+"_mIE")][1]
ELSE
	sprintf infoStr,"mIE: %.2d\r      +/- inf",Fitparams[%$(NameIon2+"_mIE")][0]
ENDIF

PanelPlotInfo_STR[%infoStr][3][Type]=infoStr



//---------------------------------
// check if waves exist for this type

//data waves
String WaveCheckList=PanelPlotInfo_STR[%name_xwave][0][Type]+";"+PanelPlotInfo_STR[%name_xwave][1][Type]+";"+PanelPlotInfo_STR[%name_xwave][2][Type]+";"
WaveCheckList+=PanelPlotInfo_STR[%name_ywave][0][Type]+";"+PanelPlotInfo_STR[%name_ywave][1][Type]+";"+PanelPlotInfo_STR[%name_ywave][2][Type]+";"

IF (MARAaux_CheckWavesFromList(WaveCheckList)!=1)
	Wave NonExistIdx
	abortStr="MARAbut_panelplots("+TypeStr+"):\r\rOne or more waves not found. Check history for missing wave names."
	
	print "--------------------------------"
	print date() + " "+ time()
	print "MARAbut_panelplots: missing waves"
	FOR (ii=0;ii<numpnts(NonExistIdx);ii+=1)
		print Stringfromlist(nonexistidx[ii],WaveCheckList)
	ENDFOR
	
	MARAaux_abort(abortStr)
ENDIF

// fit waves
WaveCheckList=PanelPlotInfo_STR[%name_fitxwave][0][Type]+";"+PanelPlotInfo_STR[%name_fitxwave][1][Type]+";"+PanelPlotInfo_STR[%name_fitxwave][2][Type]+";"
WaveCheckList=PanelPlotInfo_STR[%name_fitywave][0][Type]+";"+PanelPlotInfo_STR[%name_fitywave][1][Type]+";"+PanelPlotInfo_STR[%name_fitywave][2][Type]+";"

IF (MARAaux_CheckWavesFromList(WaveCheckList)!=1)
	Wave NonExistIdx
	abortStr="MARAbut_panelplots("+TypeStr+"):\r\rOne or more waves not found. Check history for missing wave names."
	
	print "--------------------------------"
	print date() + " "+ time()
	print "MARAbut_panelplots: missing waves"
	FOR (ii=0;ii<numpnts(NonExistIdx);ii+=1)
		print Stringfromlist(nonexistidx[ii],WaveCheckList)
	ENDFOR
	
	MARAaux_abort(abortStr)
ENDIF

//---------------------------------
// do the plotting

Variable InPanel=1
String plotName
String WindowName="MARA_PAnel#IE_NO3#Panel4but"
String Hostname="MARA_Panel#IE_NO3"
String buttonName="BUT_pop_IE_NO3"
Variable subPanelPos_x=plotWidth-33
Variable subPanelPos_y=OnePlotInfo_VAR[%height]-21
	


IF (type==0)	// for AN -> do IE of NO3
	// info for current plot
	OnePlotInfo_STR=PanelPlotInfo_STR[p][0][Type]
	OnePlotInfo_Var=PanelPlotInfo_Var[p][0][Type]

	plotName="IE_NO3"	
	// draw
	MARAbut_DoPanelplot(OnePlotInfo_STR,OnePlotInfo_VAR,plotName,inPanel)
	
	// graph pop button
	WindowName="MARA_PAnel#IE_NO3#Panel4but"
	Hostname="MARA_Panel#IE_NO3"
	buttonName="BUT_pop_IE_NO3"

	NewPanel/HOST=$Hostname /W=(subPanelPos_x,subPanelPos_y,subPanelPos_x+33,subPanelPos_y+21)/N=Panel4but
	ModifyPanel /w=$WindowName frameStyle=0
		
	button $buttonName pos={0,0},size={25,16}, title="pop",win=$WindowName,proc=MARAbut_PopGraph
	
//	// add mIE NH4 (for scaling of "other" cases)
//	// info for current plot
//	OnePlotInfo_STR=PanelPlotInfo_STR[p][2][Type]
//	OnePlotInfo_Var=PanelPlotInfo_Var[p][2][Type]
//
//	plotName="mIE_NH4"	
//	// draw
//	MARAbut_DoPanelplot(OnePlotInfo_STR,OnePlotInfo_VAR,plotName,inPanel)
//	
//	// graph pop button
//	WindowName="MARA_PAnel#mIE_NH4#Panel4but"
//	Hostname="MARA_Panel#mIE_NH4"
//	buttonName="BUT_pop_mIE_NH4"
//
//	NewPanel/HOST=$Hostname /W=(subPanelPos_x,subPanelPos_y,subPanelPos_x+33,subPanelPos_y+21)/N=Panel4but
//	ModifyPanel /w=$WindowName frameStyle=0
//		
//	button $buttonName pos={0,0},size={25,16}, title="pop",win=$WindowName,proc=MARAbut_PopGraph
	
ENDIF

IF (Type!=2)
	// AN & AS -> direct signal fit
	OnePlotInfo_STR=PanelPlotInfo_STR[p][1][Type]
	OnePlotInfo_Var=PanelPlotInfo_Var[p][1][Type]
	
	plotName=TypeStr+"_RIE"
	
	MARAbut_DoPanelplot(OnePlotInfo_STR,OnePlotInfo_VAR,plotname,inPanel)
	
	// graph pop button	
	WindowName="MARA_Panel#"+TypeStr+ "_RIE#Panel4but"	
	hostname="MARA_panel#"+TypeStr+"_RIE"
	buttonname="BUT_pop_"+TypeStr+"_RIE"

	NewPanel/HOST=$Hostname /W=(subPanelPos_x,subPanelPos_y,subPanelPos_x+33,subPanelPos_y+21)/N=Panel4but
	ModifyPanel /w=$WindowName frameStyle=0
		
	button $buttonname pos={0,0},size={25,16}, title="pop",win=$WindowName,proc=MARAbut_PopGraph

ELSE
	// other -> mIE plots
	// mIE anion
	// info for current plot
	OnePlotInfo_STR=PanelPlotInfo_STR[p][2][Type]
	OnePlotInfo_Var=PanelPlotInfo_Var[p][2][Type]
	
	plotName=TypeStr+"_mIE_anion"
	
	MARAbut_DoPanelplot(OnePlotInfo_STR,OnePlotInfo_VAR,plotname,inPanel)
	
	// graph pop button	
	WindowName="MARA_Panel#"+TypeStr+ "_mIE_anion#Panel4but"	
	hostname="MARA_panel#"+TypeStr+"_mIE_anion"
	buttonname="BUT_pop_"+TypeStr+"_mIE_anion"

	NewPanel/HOST=$Hostname /W=(subPanelPos_x,subPanelPos_y,subPanelPos_x+33,subPanelPos_y+21)/N=Panel4but
	ModifyPanel /w=$WindowName frameStyle=0
		
	button $buttonname pos={0,0},size={25,16}, title="pop",win=$WindowName,proc=MARAbut_PopGraph
	
	// mIE cation
	OnePlotInfo_STR=PanelPlotInfo_STR[p][3][Type]
	OnePlotInfo_Var=PanelPlotInfo_Var[p][3][Type]
	
	plotName=TypeStr+"_mIE_cation"
	
	MARAbut_DoPanelplot(OnePlotInfo_STR,OnePlotInfo_VAR,plotName,inPanel)

	// graph pop button	
	WindowName="MARA_Panel#"+TypeStr+ "_mIE_cation#Panel4but"	
	hostname="MARA_panel#"+TypeStr+"_mIE_cation"
	buttonname="BUT_pop_"+TypeStr+"_mIE_cation"

	NewPanel/HOST=$hostname /W=(subPanelPos_x,subPanelPos_y,subPanelPos_x+33,subPanelPos_y+21)/N=Panel4but
	ModifyPanel /w=$WindowName frameStyle=0
		
	button $buttonname pos={0,0},size={25,16}, title="pop",win=$WindowName,proc=MARAbut_PopGraph

ENDIF

// add other info to Panel

// name of folder with data
Variable pos_y=PanelPlotInfo_VAR[%pos_y][0][%$TypeStr]+PanelPlotInfo_VAR[%height][0][%$TypeStr]-15

String TB_name="TB_"+TypeStr+"_mIE_"+num2Str(type*10)
Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][0][type],PanelPlotInfo_VAR[%pos_y][0][%$TypeStr]-17}, title="\f01data folder:",fsize=12,frame=0,win=MARA_Panel 
TB_name="TB_"+TypeStr+"_mIE_"+num2Str(type*10+1)
Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][0][type]+70,PanelPlotInfo_VAR[%pos_y][0][%$TypeStr]-17}, title=Foldername,fsize=12,frame=0,win=MARA_Panel 

// IE and RIE values
Wave RIE_values=root:MARA:RIE_values	
String VARname=""

Variable Type_AN=0
Variable pos_y_AN=PanelPlotInfo_VAR[%pos_y][0][%AN]+PanelPlotInfo_VAR[%height][0][%AN]-15
		
SWITCH (type)
	// AN
	CASE 0:
		// IE NO3
		TB_name="TB_"+TypeStr+"_mIE_"+num2Str(type*10+2)
		Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][1][type]-122,pos_y+21}, title="\f01IE(NO3):",fsize=12,frame=0,win=MARA_Panel 
		
		VarName="VARn_"+Getdimlabel(RIE_values,0,0)
		Setvariable $VarName value=RIE_values[%IE_NO3][Type], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][1][type]-120+45,pos_y+20},limits={-inf,inf,0}, size={70,20},fsize=12,format="%1.4e",win=MARA_Panel 
		
		// RIE NH4
		TB_name="TB_"+TypeStr+"_mIE_"+num2Str(type*10+3)
		Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][1][type],pos_y+21}, title="\f01RIE(NH4):",fsize=12,frame=0,win=MARA_Panel 
		
		VarName="VARn_RIE_NH4"
		Setvariable $VarName value=RIE_values[%RIE_ion1][Type], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][1][type]+60,pos_y+20},limits={-inf,inf,0},format="%.2f", size={40,20},fsize=12,win=MARA_Panel 
		
		BREAK
	// AS	
	CASE 1:
		// RIE SO4
		TB_name="TB_"+TypeStr+"_mIE_"+num2Str(type*10+3)
		Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][1][type],pos_y+21}, title="\f01RIE(SO4):",fsize=12,frame=0,win=MARA_Panel 
		
		VarName="VARn_RIE_SO4"
		Setvariable $VarName value=RIE_values[%RIE_ion2][Type], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][1][type]+55,pos_y+20},limits={-inf,inf,0},format="%.2f", size={40,20},fsize=12,win=MARA_Panel 
		
		// inform about RIE(NH4,AN)
		VarName="VARn_RIE_NH4_AN"
		Setvariable $VarName value=RIE_values[%RIE_ion1][0], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][3][type]-40+plotWidth,pos_y+20},limits={-inf,inf,0},disable=2,format="%.2f", size={40,20},fsize=12,win=MARA_Panel 
		
		// info about calculations
		TB_name="TB_"+TypeStr+"_Info1"
		TitleBox $TB_name title="RIE(SO4) = RIE(NH4,AN)*", pos={PanelPlotInfo_VAR[%pos_x][0][type],pos_y+15},fsize=12,frame=0,win=MARA_Panel
		TB_name="TB_"+TypeStr+"_Info2"
		TitleBox $TB_name title="SO4 Signal*2*MW(NH4)", pos={PanelPlotInfo_VAR[%pos_x][0][type]+133,pos_y+5},fsize=12,frame=0,win=MARA_Panel
		TB_name="TB_"+TypeStr+"_Info3"
		TitleBox $TB_name title="NH4 Signal*Mw(SO4)", pos={PanelPlotInfo_VAR[%pos_x][0][type]+140,pos_y+20},fsize=12,frame=0,win=MARA_Panel
		
		DrawLine/w=MARA_Panel 829,pos_y+20,955,pos_y+20
		
		TB_name="TB_"+TypeStr+"_Info4"
		TitleBox $TB_name title="\f01using RIE(NH4,AN):", pos={PanelPlotInfo_VAR[%pos_x][1][type]+55+50,pos_y+20},fsize=12,frame=0,win=MARA_Panel

		// add RIE NH4 box in AN part (needed to manually change RIE (NH4)
		TB_name="TB_AN_mIE_"+num2Str(Type_AN*10+3)	
		Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][1][Type_AN],pos_y_AN+21}, title="\f01RIE(NH4):",fsize=12,frame=0,win=MARA_Panel 
		
		VarName="VARn_RIE_NH4"
		Setvariable $VarName value=RIE_values[%RIE_ion1][Type_AN], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][1][type_AN]+60,pos_y_AN+20},limits={-inf,inf,0},format="%.2f", size={40,20},fsize=12,win=MARA_Panel 

		BREAK
		
	//other	
	CASE 2:
		// RIE other ion 1
		TB_name="TB_"+TypeStr+"_mIE_"+num2Str(type*10+4)
		Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][0][type]-50+plotWidth,pos_y+21}, title="\f01RIE(ion1):",fsize=12,frame=0,win=MARA_Panel 
		
		VarName="VARn_RIE_ion1"
		Setvariable $VarName value=RIE_values[%RIE_ion1][Type], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][0][type]+5+plotWidth,pos_y+20},limits={-inf,inf,0}, size={40,20},fsize=12,format="%.3f",win=MARA_Panel 
		
		// RIE other ion 2
		TB_name="TB_"+TypeStr+"_mIE_"+num2Str(type*10+5)
		Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][0][type]+50+plotwidth,pos_y+21}, title="\f01RIE(ion2):",fsize=12,frame=0,win=MARA_Panel 
		
		VarName="VARn_RIE_ion2"
		Setvariable $VarName value=RIE_values[%RIE_ion2][Type], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][0][type]+105+plotWidth,pos_y+20},limits={-inf,inf,0}, size={40,20},fsize=12,format="%.3f",win=MARA_Panel 
	
		// info about calculations
		TB_name="TB_"+TypeStr+"_Info1"
		TitleBox $TB_name title="RIE(ion)*CE = mIE(ion)/mIE(NO3,AN))", pos={PanelPlotInfo_VAR[%pos_x][0][type],pos_y+21},fsize=12,frame=0,win=MARA_Panel
		
		TB_name="TB_"+TypeStr+"_Info2"
		TitleBox $TB_name title="\f01IE(NO3):", pos={PanelPlotInfo_VAR[%pos_x][0][type]+425,pos_y+21},fsize=12,frame=0,win=MARA_Panel

		VarName="VARn_RIE_ion2"
		Setvariable $VarName value=RIE_values[%RIE_ion2][Type], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][0][type]+105+plotWidth,pos_y+20},limits={-inf,inf,0}, size={40,20},fsize=12,format="%.3f",win=MARA_Panel 

		VarName="VARn_IE_NO3_AN"
		Setvariable $VarName value=RIE_values[%IE_NO3][0], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][3][type]-50+plotWidth,pos_y+20},limits={-inf,inf,0},disable=2,format="%1.2e", size={50,20},fsize=12,win=MARA_Panel 

		// add IE NO3 box in AN part (needed to manually change IE (NO3)
		TB_name="TB_"+TypeStr+"_mIE_"+num2Str(type*10+2)
		Titlebox $TB_name pos={PanelPlotInfo_VAR[%pos_x][1][type]-122,pos_y_AN+21}, title="\f01IE(NO3):",fsize=12,frame=0,win=MARA_Panel 
		
		VarName="VARn_"+Getdimlabel(RIE_values,0,0)
		Setvariable $VarName value=RIE_values[%IE_NO3][Type_AN], Title=" ",pos={PanelPlotInfo_VAR[%pos_x][1][Type_AN]-120+45,pos_y_AN+20},limits={-inf,inf,0}, size={70,20},fsize=12,format="%1.4e",win=MARA_Panel 
		
		BREAK
ENDSWITCH

//------------------------------
Setdatafolder root:

END

//======================================================================================
//======================================================================================

// Purpose:		create one of the panel plots (either in the panel or seperate)
//				does not check if waves exist before plotting (assumes upper level has done that)
// Input:		PlotInfo_STR:	text wave with information about wavenames etc. (info in Wave labels)
// 				PlotInfo_VAR:	numeric wave with information about graph position etc. (info in Wave labels)
//				plotName:		name for the plot
//				inPanel		1: 	draw in panel, 0: draw stand alone graph window	
// Output:		1 plot in the panel or on its own

// called by:	MARAbut_calcRIE() -> MARAbut_panelplots()

FUNCTION MARAbut_DoPanelplot(PlotInfo_STR,PlotInfo_VAR,Plotname,inPanel)

Wave/T PlotInfo_STR
Wave PlotInfo_VAR
String plotName
Variable inPanel 

//---------------------------
// assign Waves
Wave xwave=$(PlotInfo_STR[%name_xwave])
Wave ywave=$(PlotInfo_STR[%name_ywave])
Wave fit_xwave=$(PlotInfo_STR[%name_fitxwave])
Wave fit_ywave=$(PlotInfo_STR[%name_fitywave])

//---------------------------
// prepare drawing environment
String Windowname="MARA_Panel#"+plotName

IF (inpanel==1)
	// part of Panel
	Killwindow/Z $Windowname
	
	Display/HOST=MARA_panel/N=$plotName/W=(PlotInfo_VAR[%pos_x],PlotInfo_VAR[%pos_y],PlotInfo_VAR[%pos_x]+PlotInfo_VAR[%width],PlotInfo_VAR[%pos_y]+PlotInfo_VAR[%height])
ELSE
	// standalone graph
	
	Killwindow/Z $PlotName
	
	Display/N=$plotName/W=(PlotInfo_VAR[%pos_x],PlotInfo_VAR[%pos_y],PlotInfo_VAR[%pos_x]+2*PlotInfo_VAR[%width],PlotInfo_VAR[%pos_y]+2*PlotInfo_VAR[%height]) as plotName
	DoWindow/C $plotName

	Windowname=PlotName
	
	Showinfo
		
ENDIF

//---------------------------
// plotting
appendtograph/W=$Windowname ywave vs xwave
appendtograph/W=$Windowname fit_ywave vs fit_xwave

// info box
String BoxName=PlotInfo_STR[%plotType]
TextBox/W=$Windowname/C/N=$BoxName/B=1/A=LT "\Z12"+PlotInfo_STR[%infoStr]

// axis labels
Label/W=$Windowname bottom,PlotInfo_STR[%label_x]
Label/W=$Windowname left,PlotInfo_STR[%label_y]

// make it pretty
// axis
ModifyGraph/W=$Windowname tick=2,mirror=1,nticks=3,fStyle=1,fSize=12,axThick=2,ZisZ=1,standoff=0,notation=1
ModifyGraph/W=$Windowname axoffset(left)=-4,lblLatPos(left)=25,axoffset(bottom)=-0.5

// traces
String ListTraces=TraceNameList(Windowname,";",1) //first is data, second is fit
ModifyGraph mode($Stringfromlist(0,ListTraces))=3,marker($Stringfromlist(0,ListTraces))=19,msize($Stringfromlist(0,ListTraces))=3
ModifyGraph lsize($Stringfromlist(1,ListTraces))=1.5,rgb($Stringfromlist(1,ListTraces))=(0,0,65535)


END

//======================================================================================
//======================================================================================

// Purpose:		open MCE panel for some multi charge estimation

// Input:		via panel: single charged size, concentration measured at single and corresponding double/tripple charged values
// Output:		number conc of double and triple charged and fraction of single charged in number and mass space
// called by:	MARAbut_buttonPROCS()

FUNCTION MARAbut_MCEPanel()

String oldFolder=getdatafolder(1)

// get old resolution setting and set standard (important for different screen resolutions)
Execute/Q/Z "SetIgorOption PanelResolution=?"
variable oldResolution = V_Flag
Execute/Q/Z "SetIgorOption PanelResolution=72"

// get variables and waves
Wave DpSize=root:MARA:MCE:DPSize
Wave conc_meas=root:MARA:MCE:conc_meas
Wave Num_atSingleDp=root:MARA:MCE:Num_atSingleDp
Wave Mass_atSingleDp=root:MARA:MCE:MaSS_atSingleDp
Wave MCE_CheckBoxSet=root:MARA:MCE:MCE_CheckBoxSet
	
NVAR SingleFrac_num_VAR=root:MARA:MCE:SingleFrac_num_VAR
NVAR SingleFrac_mass_VAR=root:MARA:MCE:SingleFrac_mass_VAR


//==============================================================
// build panel
//==============================================================

Killwindow/Z MCE_Panel
Newpanel/N=MCE_Panel/W=(50,20,445,215)/K=1 as "Multi Charge Estimator"

// text
titlebox TB_MCE_01 pos={60,5},title="\f01Size",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_02 pos={60+35+20+10,5},title="\f01meas conc",fsize=14,frame=0,win=MCE_Panel
titlebox TB_MCE_03 pos={55+35+10+70+20+20,5},title="\f01conc at Dp(single)",fsize=14,frame=0,win=MCE_Panel

titlebox TB_MCE_04 pos={5,25},title="Single",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_05 pos={5,2*25},title="Double",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_06 pos={5,3*25},title="Triple",fsize=14,frame=0,win=MCE_Panel 

titlebox TB_MCE_19 pos={60+32+10,25},title="nm",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_20 pos={60+32+10,2*25},title="nm",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_21 pos={60+32+10,3*25},title="nm",fsize=14,frame=0,win=MCE_Panel 

titlebox TB_MCE_07 pos={60+35+10+52+20,25},title="#/cc",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_08 pos={60+35+10+52+20,2*25},title="#/cc",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_09 pos={60+35+10+52+20,3*25},title="#/cc",fsize=14,frame=0,win=MCE_Panel 

titlebox TB_MCE_10 pos={55+35+10+70+20+20,4*25+10},title="\f01Single charged fraction:",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_11 pos={55+35+10+70+20+20+35,5*25+10},title="number",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_12 pos={55+35+10+70+20+20+35,6*25+10+5},title="mass",fsize=14,frame=0,win=MCE_Panel 

titlebox TB_MCE_13 pos={55+35+10+70+20+52+20,1*25},title="#/cc",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_14 pos={55+35+10+70+20+52+20,2*25},title="#/cc",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_15 pos={55+35+10+70+20+52+20,3*25},title="#/cc",fsize=14,frame=0,win=MCE_Panel 

titlebox TB_MCE_16 pos={55+35+10+70+20+55+30+52+20,1*25},title="ug/m3",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_17 pos={55+35+10+70+20+55+30+52+20,2*25},title="ug/m3",fsize=14,frame=0,win=MCE_Panel 
titlebox TB_MCE_18 pos={55+35+10+70+20+55+30+52+20,3*25},title="ug/m3",fsize=14,frame=0,win=MCE_Panel 

// frame for result
SetDrawEnv linefgc= (65535,0,52428),fillpat= 0,linethick= 2.50
DrawRect 239,162,359,190

// variables
// particle size
Setvariable VARn_MCE_size_1 pos={60,25},size={40,20},title=" ",value=DpSize[0],limits={0,inf,0},fsize=14,win=MCE_Panel, proc=MARAaux_calcSizes
Setvariable VARn_MCE_size_2 pos={60,2*25},size={40,20},title=" ",value=DpSize[1],disable=2,limits={0,inf,0},fsize=14,win=MCE_Panel, noproc
Setvariable VARn_MCE_size_3 pos={60,3*25},size={40,20},title=" ",value=DpSize[2],disable=2,limits={0,inf,0},fsize=14,win=MCE_Panel, noproc

// measured particle conc
Setvariable VARn_MCE_measConc_1 pos={60+35+10+20,25},size={50,20},title=" ",value=conc_meas[0],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc
Setvariable VARn_MCE_measConc_2 pos={60+35+10+20,2*25},size={50,20},title=" ",value=conc_meas[1],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc
Setvariable VARn_MCE_measConc_3 pos={60+35+10+20,3*25},size={50,20},title=" ",value=conc_meas[2],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc

// calculated number conc at Dp(SIngle)
Setvariable VARn_MCE_NConc_1 pos={55+35+10+70+20+20,1*25},size={50,20},disable=2,title=" ",value=Num_atSingleDp[0],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc
Setvariable VARn_MCE_NConc_2 pos={55+35+10+70+20+20,2*25},size={50,20},disable=2,title=" ",value=Num_atSingleDp[1],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc
Setvariable VARn_MCE_NConc_3 pos={55+35+10+70+20+20,3*25},size={50,20},disable=2,title=" ",value=Num_atSingleDp[2],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc

// calcaualted mass conc at Dp(single)
Setvariable VARn_MCE_MConc_1 pos={55+35+10+70+20+55+30+20,1*25},size={50,20},disable=2,title=" ",value=MaSS_atSingleDp[0],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc
Setvariable VARn_MCE_MConc_2 pos={55+35+10+70+20+55+30+20,2*25},size={50,20},disable=2,title=" ",value=MaSS_atSingleDp[1],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc
Setvariable VARn_MCE_MConc_3 pos={55+35+10+70+20+55+30+20,3*25},size={50,20},disable=2,title=" ",value=MaSS_atSingleDp[2],limits={0,inf,0},fsize=14,win=MCE_Panel, noproc

// fraction 
Setvariable VARn_MCE_SingleFrac_num pos={55+35+10+70+20+55+30+20,5*25+10},size={60,20},title=" ",value=SingleFrac_num_VAR,disable=2,limits={0,inf,0},fsize=14,win=MCE_Panel, noproc
Setvariable VARn_MCE_SingleFrac_mass pos={55+35+10+70+20+55+30+20,6*25+10+5},size={60,20},title=" ",value=SingleFrac_mass_VAR,disable=2,limits={0,inf,0},fsize=14,win=MCE_Panel, noproc

// button
Checkbox CB_MCEPanel_pos  pos={20,5*25+10},title="positive",mode=1,fsize=14,value=MCE_CheckBoxSet[0], proc=MARAbut_MCEpanel_pol_but
Checkbox CB_MCEPanel_neg  pos={20,6*25+10},title="negative",mode=1,fsize=14,value=MCE_CheckBoxSet[1], proc=MARAbut_MCEpanel_pol_but

Button  BUT_MCEpanel_calc pos={125,5*25+10},size={80,52},title="\f01calculate",fcolor=(65535,0,52428), fsize=14, proc=MARAbut_MCEpanel_calc_but

//==============================================================
// cleanup
//==============================================================

Setdatafolder $oldfolder

// reset old resolution value
Execute/Q/Z "SetIgorOption PanelResolution="+num2Str(oldResolution)

END

//======================================================================================
//======================================================================================

// Purpose:		set radio button for polatity in MCE panel
// Input:		
// Output:		display in Panel and 1/0 in wave
// called by:	MARAbut_buttonPROCS() -> MARAbut_MCEPanel()


FUNCTION MARAbut_MCEpanel_pol_but (cba) : CheckBoxControl

STRUCT WMCheckboxAction &cba

IF (cba.eventCode==2)
	
	Wave MCE_CheckBoxSet=root:MARA:MCE:MCE_CheckBoxSet
	NVAR polarity=root:MARA:MCE:polarity_VAR
		
	STRSWITCH(cba.ctrlName)
		CASE "CB_MCEPanel_pos":
			// positive polarity
			MCE_CheckBoxSet[0] = 1
			MCE_CheckBoxSet[1] = 0	
			polarity=0
					
			BREAK
		CASE "CB_MCEPanel_neg":
			// negative polarity
			MCE_CheckBoxSet[0] = 0
			MCE_CheckBoxSet[1] = 1	
			polarity=1		
			BREAK
	ENDSWITCH
	
	// set the button apperancve
	CheckBox CB_MCEPanel_pos, value = MCE_CheckBoxSet[0]
	CheckBox CB_MCEPanel_neg, value = MCE_CheckBoxSet[1]

ENDIF

END

//======================================================================================
//======================================================================================

// Purpose:		open MCE panel for some multi charge estimation

// Input:		via top level panel
// Output:		values in PAnel
// called by:	MARAbut_buttonPROCS() -> MARAbut_MCEPanel()

FUNCTION MARAbut_MCEpanel_calc_but(B_struct) : BUttonControl

STRUCT WMButtonAction &B_struct

IF(B_struct.eventCode==2)	// button release

	String oldFolder=getdatafolder(1)
	
	// get variables and waves
	Wave DpSize=root:MARA:MCE:DPSize					// sizes
	Wave conc_meas=root:MARA:MCE:conc_meas				// measured conc
	Wave Num_atSingleDp=root:MARA:MCE:Num_atSingleDp	// corrected number conc at desired Dp
	Wave Mass_atSingleDp=root:MARA:MCE:Mass_atSingleDp	// corrected mass conc at desired Dp using 1g/cc
	
	NVAR SingleFrac_num=root:MARA:MCE:SingleFrac_num_VAR
	NVAR SingleFrac_mass=root:MARA:MCE:SingleFrac_mass_VAR
	NVAR polarity=root:MARA:MCE:polarity_VAR
	SVAR abortStr=root:MARA:abortStr
	
	// basic checks
	// check that there are values which are >0
	IF (numtype(Conc_meas[0])!=0 || conc_meas[0]==0)	// single charge conc Nan of 0
		abortStr="MARAbut_MCEpanel_calc_but():\r\rconcentration of single charge particles must be a non zero number."
		MARAaux_abort(abortStr)
	ENDIF
	
	IF (numtype(Conc_meas[1])!=0 || conc_meas[1]==0)	// double charge conc Nan of 0
		abortStr="MARAbut_MCEpanel_calc_but():\r\rconcentration of double charge particles must be a non zero number."
		MARAaux_abort(abortStr)
	ENDIF
	
	// calculate charge distribution
	// double
	MARAaux_calcChargeProp(DPSize[1]*1e-9,polarity)
	Wave ChargeProp
	
	IF (numtype(DpSIze[1])==0)	// catch if Dp(ii) is NaN
		Variable TotalConc_2=conc_meas[1]/CHargeProp[0]	// meas conc at -2 / chargeProp(-1 at that size)
		Num_atSingleDp[1]=TotalConc_2*ChargeProp[1]
	ELSE
		Num_atSingleDp[1]=0
	ENDIF
	
	//triple
	IF (numtype(DpSIze[2])==0)	// catch if Dp(iii) is NaN
		MARAaux_calcChargeProp(DPSize[2]*1e-9,polarity)
		Wave ChargeProp
		
		Variable TotalConc_3=conc_meas[2]/CHargeProp[0]	// meas conc at -2 / chargeProp(-1 at that size)
		Num_atSingleDp[2]=TotalConc_3*ChargeProp[1]
	ELSE
		Num_atSingleDp[2]=0
	ENDIF
	
	Num_atSingleDp[0]=conc_meas[0]-Num_atSingleDp[1]-Num_atSingleDp[2]
	
	SingleFrac_num=Num_atSingleDp[0]/conc_meas[0]
	
	//--------------------
	//convert to mass space
	Variable rho=1 // 1g/cc 
	Variable UNitConvert=1e12	// to convert g/cc -> ug/m3
	Mass_atSingleDP=pi/6 * (DpSize[p]*1e-7)^3*rho*num_atSingleDp[p]*unitCOnvert	// ug/m3
	Mass_atSingleDP = numtype(Mass_atSingleDP[p]) == 0 ? Mass_atSingleDP[p] : 0
	
	SingleFrac_Mass=Mass_atSingleDP[0]/(Mass_atSingleDP[0]+Mass_atSingleDP[1]+Mass_atSingleDP[2])
	
	
	//==============================================================
	// cleanup
	//==============================================================
	Killwaves/Z ChargeProp
	
	Setdatafolder $oldfolder
ENDIF

END