#SingleInstance force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include %A_LineFile%\..\Lib\JSON.ahk

/*
	Class JSONFile
	Written by Runar "RUNIE" Borge
	
	Dependencies:
	JSON loader/dumper by cocobelgica: https://github.com/cocobelgica/AutoHotkey-JSON
	However the class can easily be modified to use another JSON dump/load lib.
	
	To create a new JSON file wrapper:
	MyJSON := new JSONFile(filepath)
	
	And to destroy it:
	MyJSON := ""
	
	Methods:
		.Save(Prettify := false) - save object to file
		.JSON(Prettify := false) - Get JSON text
		.Fill(Object) - fill keys in from another object into the instance object
		
	Instance variables:
		.File() - get file path
		.Object() - get data object
*/

Class JSONFile {
	static Instances := []
	
	__New(File) {
		FileExist := FileExist(File)
		JSONFile.Instances[this] := {File: File, Object: {}}
		ObjRelease(&this)
		FileObj := FileOpen(File, "rw")
		if !IsObject(FileObj)
			throw Exception("Can't access file for JSONFile instance: " File, -1)
		if FileExist {
			try
				JSONFile.Instances[this].Object := JSON.Load(FileObj.Read())
			catch e {
				this.__Delete()
				throw e
			} if (JSONFile.Instances[this].Object = "")
				JSONFile.Instances[this].Object := {}
		} else
			JSONFile.Instances[this].IsNew := true
		return this
	}
	
	__Delete() {
		if JSONFile.Instances.HasKey(this) {
			ObjAddRef(&this)
			JSONFile.Instances.Delete(this)
		}
	}
	
	__Call(Func, Param*) {
		; return instance value (File, Object, FileObj, IsNew)
		if JSONFile.Instances[this].HasKey(Func)
			return JSONFile.Instances[this][Func]
		
		; return formatted json
		if (Func = "JSON")
			return StrReplace(JSON.Dump(this.Object(),, Param.1 ? A_Tab : ""), "`n", "`r`n")
		
		; save the json file
		if (Func = "Save") {
			try
				New := this.JSON(Param.1)
			catch e
				return false
			FileObj := FileOpen(this.File(), "w")
			FileObj.Length := 0
			FileObj.Write(New)
			FileObj.__Handle
			return true
		}
		
		; fill from specified array into the JSON array
		if (Func = "Fill") {
			if !IsObject(Param.2)
				Param.2 := []
			for Key, Val in Param.1 {
				if (A_Index > 1)
					Param.2.Pop()
				HasKey := Param.2.MaxIndex()
						? this.Object()[Param.2*].HasKey(Key) 
						: this.Object().HasKey(Key)
				Param.2.Push(Key)
				if IsObject(Val) && HasKey
					this.Fill(Val, Param.2), Param.2.Pop()
				else if !HasKey
					this.Object()[Param.2*] := Val
			} return
		}
		
		return Obj%Func%(this.Object(), Param*)
	}
	
	__Set(Key, Val) {
		return this.Object()[Key] := Val
	}
	
	__Get(Key) {
		return this.Object()[Key]
	}
}

Refresh_Taskbar_Icons()
{
  eee := DllCall( "FindWindowEx", "uint", 0, "uint", 0, "str", "Shell_TrayWnd", "str", "")
  ddd := DllCall( "FindWindowEx", "uint", eee, "uint", 0, "str", "TrayNotifyWnd", "str", "")
  ccc := DllCall( "FindWindowEx", "uint", ddd, "uint", 0, "str", "SysPager", "str", "")
  hNotificationArea := DllCall( "FindWindowEx", "uint", ccc, "uint", 0, "str", "ToolbarWindow32", "str", "Notification Area")
  
  xx = 3
  yy = 5
  Transform, yyx, BitShiftLeft, yy, 16
  loop, 6 ;152
  {
    xx += 15
    SendMessage, 0x200, , yyx + xx, , ahk_id %hNotificationArea%
  }
}

;jf := new JSONFile("C:\Program Files (x86)\Steam\config\steamvr.vrsettings")
;steamPath := "C:\Program Files (x86)\Steam"
;steamPath := "C:\Program Files (x86)\Steamtest"
;steamVRPath := "C:\Program Files (x86)\Steam\steamapps\common\SteamVR"
settingsFile := "settings.ini"

steamPath := "C:\Program Files (x86)\Steam"
steamExecutable = %steamPath%\Steam.exe
if !FileExist(steamExecutable){
	IniRead, steamPath, %settingsFile%, paths, steamPath
	steamExecutable = %steamPath%\Steam.exe
	loop{	
		if !FileExist(steamExecutable){
			MsgBox, Please locate your Steam folder
			FileSelectFolder, steamPath
			steamExecutable = %steamPath%\Steam.exe
			steamPathError = 1
		}
		else{
			if (steamPathError == 1){
				IniWrite, %steamPath%, %settingsFile%, paths, steamPath
			}
			break
		}
	}
}
steamVRpath = %steamPath%\steamapps\common\SteamVR
steamVRexecutable = %steamVRpath%\bin\win32\vrstartup.exe
if !FileExist(steamVRexecutable){
	IniRead, steamVRPath, %settingsFile%, paths, steamVRPath
	loop{	
		steamVRexecutable = %steamVRpath%\bin\win32\vrstartup.exe
		if !FileExist(steamVRexecutable){
			MsgBox, Please locate your SteamVR folder
			FileSelectFolder, steamVRPath, , 2, Please locate your SteamVR folder (usually %steamPath%\steamapps\common\SteamVR)
			steamVRPathError = 1
		}
		else{
			if (steamVRPathError == 1){
				IniWrite, %steamVRPath%, %settingsFile%, paths, steamVRPath
			}
			break
		}
	}
}
steamvrJSONfile = %steamPath%\config\steamvr.vrsettings
if !FileExist(steamvrJSONfile){
	IniRead, steamvrJSONfile, %settingsFile%, paths, steamvrJSONfile
	loop{
		if !FileExist(steamvrJSONfile){
			MsgBox, Please locate your steamvr.vrsettings file.
			FileSelectFile, steamvrJSONfile, 1, %steamPath%, Please locate steamvr.vrsettings file (usually in %steamPath%\config\), steamvr.vrsettings
			steamvrJSONfileError = 1
		}
		else{
			if (steamvrJSONfileError == 1){
				IniWrite, %steamvrJSONfile%, %settingsFile%, paths, steamvrJSONfile
			}
			break
		}
	}
}


jf := new JSONFile(steamvrJSONfile)
	
; else{
	; IniRead, steamPath, settings.ini, paths, steamPath
; }
	
; if !FileExist(steamPath)
	; MsgBox, Steam Dir not found
; else
	; vrsettingsPath = %steamPath%\config\steamvr.vrsettings
	; if !FileExist(vrsettingsPath)
		; MsgBox, SteamVR settings file not found
	; steamVRPath = %steamPath%steamapps\common\SteamVR
	; if !FileExist(steamVRPath)
		; MsgBox, SteamVR path not found
		; steamVRexecutable = %steamVRPath%\bin\win32\vrstartup.exe	
		; if !FileExist(steamVRexecutable)
			; MsgBox, SteamVR exec found

;msgbox % jf.JSON(false)
;msgbox % jf.steamvr.activateMultipleDrivers

;jf.steamvr.forcedDriver := "new"
;jf.steamvr.activateMultipleDrivers := true
;jf.steamvr.new := "value"
;jf.steamvr.Delete("new")

; Other settings
; steamvr : "background" : "#0D0D0DFF"

; --- SteamVR
if(jf.steamvr.testValue == null)
	testValue := 0
else
	testValue := jf.steamvr.testValue

if(jf.steamvr.requireHmd == null)
	requireHmd := 1
else
	requireHmd := jf.steamvr.requireHmd

if (!jf.steamvr.forcedDriver)
	forcedDriver = 0
else 
	forcedDriver = 1
	
if(jf.steamvr.activateMultipleDrivers == null)
	activateMultipleDrivers := 0
else
	activateMultipleDrivers := jf.steamvr.activateMultipleDrivers
	
if(jf.steamvr.enableHomeApp == null)
	enableHomeApp := 1
else
	enableHomeApp := jf.steamvr.enableHomeApp
	
if(jf.steamvr.showMirrorView == null)
	showMirrorView := 0
else
	showMirrorView := jf.steamvr.showMirrorView
	
if(jf.steamvr.allowSupersampleFiltering == null)
	allowSupersampleFiltering := 0
else
	allowSupersampleFiltering := jf.steamvr.allowSupersampleFiltering
	
if(jf.steamvr.forceFadeOnBadTracking == null)
	forceFadeOnBadTracking := 1
else
	forceFadeOnBadTracking := jf.steamvr.forceFadeOnBadTracking
	
if(jf.steamvr.displayDebug == null)
	displayDebug := 0
else
	displayDebug := jf.steamvr.displayDebug
	
if(jf.steamvr.debugInputBinding == null)
	debugInputBinding := 0
else
	debugInputBinding := jf.steamvr.debugInputBinding
	
if(jf.steamvr.enableDistortion == null)
	enableDistortion := 1
else
	enableDistortion := jf.steamvr.enableDistortion
	
if(jf.steamvr.showStage == null)
	showStage := 0
else
	showStage := jf.steamvr.showStage
	
if(jf.steamvr.allowDisplayLockedMode == null)
	allowDisplayLockedMode := 0
else
	allowDisplayLockedMode := jf.steamvr.allowDisplayLockedMode
	
if(jf.steamvr.motionSmoothing == null)
	motionSmoothing := 1
else
	motionSmoothing := jf.steamvr.motionSmoothing
	
if(jf.steamvr.supersampleManualOverride == null or jf.steamvr.supersampleManualOverride == 0){
	supersampleManualOverride := 0
	GuiControl, Disable, supersampleScale
}
else
	supersampleManualOverride := jf.steamvr.supersampleManualOverride

if(jf.steamvr.supersampleScale == null)
	supersampleScale := 100
else
	supersampleScale := Ceil(jf.steamvr.supersampleScale * 100)

; --- Camera

if(jf.camera.enableCamera == null)
	enableCamera := 0
else
	enableCamera := jf.camera.enableCamera
	
if(jf.camera.enableCameraForRoomView == null)
	enableCameraForRoomView := 0
else
	enableCameraForRoomView := jf.camera.enableCameraForRoomView
	
if(jf.camera.enableCameraInDashboard == null)
	enableCameraInDashboard := 0
else
	enableCameraInDashboard := jf.camera.enableCameraInDashboard

; --- Dashboard
	
if(jf.dashboard.enableDashboard == null)
	enableDashboard := 1
else
	enableDashboard := jf.dashboard.enableDashboard
	
if(jf.dashboard.arcadeMode == null)
	arcadeMode := 0
else
	arcadeMode := jf.dashboard.arcadeMode
	
; --- User Interface

if(jf.userinterface.StatusAlwaysOnTop == null)
	StatusAlwaysOnTop := 1
else
	StatusAlwaysOnTop := jf.userinterface.StatusAlwaysOnTop
	
if(jf.userinterface.MinimizeToTray == null)
	MinimizeToTray := 0
else
	MinimizeToTray := jf.userinterface.MinimizeToTray
	
if(jf.userinterface.HidePopupsWhenStatusMinimized == null)
	HidePopupsWhenStatusMinimized := 0
else
	HidePopupsWhenStatusMinimized := jf.userinterface.HidePopupsWhenStatusMinimized
	
; --- Notifications

if(jf.notifications.DoNotDisturb == null)
	DoNotDisturb := 0
else
	DoNotDisturb := jf.notifications.DoNotDisturb
	
; --- Audio

if(jf.audio.viveHDMIGain == null)
	viveHDMIGain := 1
else
	viveHDMIGain := jf.audio.viveHDMIGain
	
; --- PerfCheck

if(jf.perfcheck.perfGraphInHMD == null)
	perfGraphInHMD := 0
else
	perfGraphInHMD := jf.perfcheck.perfGraphInHMD
	
; msgbox % forcedDriver
showGui:
Gui, New
Gui, Add, Text,, SteamVR
Gui, Add, Checkbox, Checked%activateMultipleDrivers% vactivateMultipleDrivers gactivateMultipleDrivers, Activate Multiple Drivers
activateMultipleDrivers_TT := "Activate Multiple Drivers in SteamVR."
Gui, Add, Checkbox, Checked%requireHmd% vrequireHmd grequireHmd, Require HMD
requireHmd_TT := "Disable HMD presence requirement in SteamVR."
Gui, Add, Checkbox, Checked%forcedDriver% vforcedDriver gforcedDriver, Force 'Null' Driver
forcedDriver_TT := "Force 'Null' Driver in SteamVR."
Gui, Add, Checkbox, Checked%enableHomeApp% venableHomeApp genableHomeApp, Enable Home App
enableHomeApp_TT := "Launch SteamVR Home Beta at Startup."
Gui, Add, Checkbox, Checked%showMirrorView% vshowMirrorView gshowMirrorView, Show Mirror View
showMirrorView_TT := "Enable the mirrored view."
Gui, Add, Checkbox, Checked%allowSupersampleFiltering% vallowSupersampleFiltering gallowSupersampleFiltering, Allow Supersample Filtering
allowSupersampleFiltering_TT := "Enable Advanced Supersample Filtering."
Gui, Add, Checkbox, Checked%forceFadeOnBadTracking% vforceFadeOnBadTracking gforceFadeOnBadTracking, Force Fade On Bad Tracking
forceFadeOnBadTracking_TT := "Show a grey screen when tracking is lost."
Gui, Add, Checkbox, Checked%displayDebug% vdisplayDebug gdisplayDebug, Display Debug
displayDebug_TT := "Display Debug."
Gui, Add, Checkbox, Checked%debugInputBinding% vdebugInputBinding gdebugInputBinding, Enable debugging options in the input binding user interface
debugInputBinding_TT := "Enable debugging options in the input binding user interface."
Gui, Add, Checkbox, Checked%enableDistortion% venableDistortion genableDistortion, Enable Distortion
enableDistortion_TT := "Enable Distortion."
Gui, Add, Checkbox, Checked%allowDisplayLockedMode% vallowDisplayLockedMode gallowDisplayLockedMode, Locked Mode
allowDisplayLockedMode_TT := "Allow rendering to headset while workstation is locked."
Gui, Add, Checkbox, Checked%showStage% vshowStage gshowStage, Show Stage
showStage_TT := "??? showStage ???"
Gui, Add, Checkbox, Checked%motionSmoothing% vmotionSmoothing gmotionSmoothing, Enable Motion Smoothing
motionSmoothing_TT := "SteamVR synthesizes new frames to maintain a good experience when the`nrunning application cannot make framerate."
Gui, Add, Checkbox, Checked%supersampleManualOverride% vsupersampleManualOverride gsupersampleManualOverride, Application Resolution Manual Override
supersampleManualOverride_TT := "When disabled, SteamVR automatically sets the application resolution based on the`nperformace of the GPU.`nWARNING : When enabled, the manual override will affect all applications."
Gui, Add, Slider, vsupersampleScale gsupersampleScale Range20-500 ToolTip, %supersampleScale%
Gui, Add, Text, vsupersampleScaleText, %supersampleScale%`%
if (supersampleManualOverride == 0){
	GuiControl, Disable, supersampleScale
}
Gui, Add, Text,, Camera
Gui, Add, Checkbox, Checked%enableCamera% venableCamera genableCamera, Enable Camera
enableCamera_TT := "Enable HMD camera."
Gui, Add, Checkbox, Checked%enableCameraForRoomView% venableCameraForRoomView genableCameraForRoomView, Enable Camera For Room View (System Button Double Click)
enableCameraForRoomView_TT := "Double-clicking the System button will activate the camera view."
Gui, Add, Checkbox, Checked%enableCameraInDashboard% venableCameraInDashboard genableCameraInDashboard, Enable Camera In Dashboard
enableCameraInDashboard_TT := "Activate the camera when the SteamVR Dashboard is opened.`nUpon pressing the Home button, a small color feed of the camera will appear next to the right-hand controller."
Gui, Add, Text,, Dashboard
Gui, Add, Checkbox, Checked%enableDashboard% venableDashboard genableDashboard, Enable Dashboard
enableDashboard_TT := "Enable VR Dashboard."
Gui, Add, Checkbox, Checked%arcadeMode% varcadeMode garcadeMode, Arcade Mode
arcadeMode_TT := "Enable Arcade Mode VR Dashboard."
Gui, Add, Text,, User Interface
Gui, Add, Checkbox, Checked%StatusAlwaysOnTop% vStatusAlwaysOnTop gStatusAlwaysOnTop, SteamVR Status window always on top
StatusAlwaysOnTop_TT := "SteamVR Status window always on top."
Gui, Add, Checkbox, Checked%MinimizeToTray% vMinimizeToTray gMinimizeToTray, When minimized, SteamVR Status minimizes to the system tray
MinimizeToTray_TT := "When minimized, SteamVR Status minimizes to the system tray."
Gui, Add, Checkbox, Checked%HidePopupsWhenStatusMinimized% vHidePopupsWhenStatusMinimized gHidePopupsWhenStatusMinimized, Suppress warnings and alerts when SteamVR Status is minimized
HidePopupsWhenStatusMinimized_TT := "Suppress warnings and alerts when SteamVR Status is minimized."
Gui, Add, Text,, Notifications
Gui, Add, Checkbox, Checked%DoNotDisturb% vDoNotDisturb gDoNotDisturb, Do Not Disturb
DoNotDisturb_TT := "When Do Not Disturb is enabled, incoming notifications will be suppressed."
Gui, Add, Text,, Audio
Gui, Add, Checkbox, Checked%viveHDMIGain% vviveHDMIGain gviveHDMIGain, Enable Gain reduction on VIVE HDMI Audio
viveHDMIGain_TT := "Enable Gain reduction on VIVE HDMI Audio."
Gui, Add, Text,, Performance Check
Gui, Add, Checkbox, Checked%perfGraphInHMD% vperfGraphInHMD gperfGraphInHMD, Show GPU Performance Graph in Headset (Beta)
perfGraphInHMD_TT := "Show GPU Performance Graph in Headset (Beta)."

Gui Add, Button, gsteamvrStart, Start
steamvrStart_TT := "Starts SteamVR."
Gui Add, Button, gsteamvrStop, Stop
steamvrStop_TT := "Stops SteamVR."
Gui Add, Button, gsteamvrRestart, Restart
steamvrRestart_TT := "Restarts SteamVR."
Gui Add, Button, , Submit
Gui Show
OnMessage(0x200, "WM_MOUSEMOVE")
return

WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    if (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 1000
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 5000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

steamvrStart:
	Run, %steamVRexecutable%
return

steamvrStop:
	RunWait, taskkill /im vrmonitor.exe /f
	RunWait, taskkill /im vrcompositor.exe /f
	RunWait, taskkill /im vrdashboard.exe /f
	RunWait, taskkill /im vrserver.exe /f
	MsgBox, , Stopping SteamVR Processes, Give SteamVR some time for a graceful shutdown`nPlease wait or click ok to continue..., 20
	Refresh_Taskbar_Icons()
return

steamvrRestart:
	GoSub steamvrStop
	GoSub steamvrStart
return

save:
{
	jf.Save(true)
	return
}
	
showMirrorView:
	GuiControlGet, showMirrorView
	if(showMirrorView==1)
		jf.steamvr.showMirrorView := 1
	else
		jf.steamvr.Delete("showMirrorView")
	Goto save
return

requireHmd:
	GuiControlGet, requireHmd
	if(requireHmd==1)
		jf.steamvr.Delete("requireHmd")
	else
		jf.steamvr.requireHmd := 0
	Goto save
return

forcedDriver:
	GuiControlGet, forcedDriver
	if(forcedDriver==1)
		jf.steamvr.forcedDriver := "null"
	else
		jf.steamvr.Delete("forcedDriver")
	Goto save
return

activateMultipleDrivers:
	GuiControlGet, activateMultipleDrivers
	if(activateMultipleDrivers==1)
		jf.steamvr.activateMultipleDrivers := 1
	else
		jf.steamvr.Delete("activateMultipleDrivers")
	Goto save
return

enableHomeApp:
	GuiControlGet, enableHomeApp
	if(enableHomeApp==1)
		jf.steamvr.Delete("enableHomeApp")
	else
		jf.steamvr.enableHomeApp := 0
	Goto save
return

allowSupersampleFiltering:
	GuiControlGet, allowSupersampleFiltering
	if(allowSupersampleFiltering==1)
		jf.steamvr.allowSupersampleFiltering := 1
	else
		jf.steamvr.allowSupersampleFiltering := 0
	Goto save
return

forceFadeOnBadTracking:
	GuiControlGet, forceFadeOnBadTracking
	if(forceFadeOnBadTracking==1)
		jf.steamvr.Delete("forceFadeOnBadTracking")
	else
		jf.steamvr.forceFadeOnBadTracking := 0
	Goto save
return

displayDebug:
	GuiControlGet, displayDebug
	if(displayDebug==0)
		jf.steamvr.Delete("displayDebug")
	else
		jf.steamvr.displayDebug := 1
	Goto save
return

debugInputBinding:
	GuiControlGet, debugInputBinding
	if(debugInputBinding==0)
		jf.steamvr.Delete("debugInputBinding")
	else
		jf.steamvr.debugInputBinding := 1
	Goto save
return

enableDistortion:
	GuiControlGet, enableDistortion
	if(enableDistortion==1)
		jf.steamvr.Delete("enableDistortion")
	else
		jf.steamvr.enableDistortion := 0
	Goto save
return

showStage:
	GuiControlGet, showStage
	if(showStage==0)
		jf.steamvr.Delete("showStage")
	else
		jf.steamvr.showStage := 1
	Goto save
return

allowDisplayLockedMode:
	GuiControlGet, allowDisplayLockedMode
	if(allowDisplayLockedMode==0)
		jf.steamvr.Delete("allowDisplayLockedMode")
	else
		jf.steamvr.allowDisplayLockedMode := 1
	Goto save
return

motionSmoothing:
	GuiControlGet, motionSmoothing
	if(motionSmoothing==1)
		jf.steamvr.Delete("motionSmoothing")
	else
		jf.steamvr.motionSmoothing := 0
	Goto save
return

supersampleManualOverride:
	GuiControlGet, supersampleManualOverride
	if(supersampleManualOverride==0){
		jf.steamvr.Delete("supersampleManualOverride")
		GuiControl, Disable, supersampleScale
	}
	else{
		jf.steamvr.supersampleManualOverride := 1
		GuiControl, Enable, supersampleScale
	}
	Goto save
return

supersampleScale:
	GuiControlGet, supersampleScale
	GuiControl, Text, supersampleScaleText , %supersampleScale%`%
	jf.steamvr.supersampleScale := supersampleScale / 100
	Goto save
return


; --- Camera
enableCamera:
	GuiControlGet, enableCamera
	if(enableCamera==1)
		jf.camera.enableCamera := 1
	else
		jf.camera.enableCamera := 0
	Goto save
return

enableCameraForRoomView:
	GuiControlGet, enableCameraForRoomView
	if(enableCameraForRoomView==1)
		jf.camera.enableCameraForRoomView := 1
	else
		jf.camera.enableCameraForRoomView := 0
	Goto save
return

enableCameraInDashboard:
	GuiControlGet, enableCameraInDashboard
	if(enableCameraInDashboard==1)
		jf.camera.enableCameraInDashboard := 1
	else
		jf.camera.enableCameraInDashboard := 0
	Goto save
return

; --- Dashboard

enableDashboard:
	GuiControlGet, enableDashboard
	if(jf.dashboard == null)
		jf.dashboard := {}
		
	if(enableDashboard==1)
		jf.dashboard.Delete("enableDashboard")
	else
		jf.dashboard.enableDashboard := 0
	Goto save
return

arcadeMode:
	GuiControlGet, arcadeMode
	if(jf.dashboard == null)
		jf.dashboard := {}
	if(arcadeMode==0)
		jf.dashboard.Delete("arcadeMode")
	else
		;jf.dashboard := {arcadeMode: "1"}
		jf.dashboard.arcadeMode := 1
	Goto save
return

; --- User Interface

StatusAlwaysOnTop:
	GuiControlGet, StatusAlwaysOnTop
	if(jf.userinterface == null)
		jf.userinterface := {}
	if(StatusAlwaysOnTop==1)
		jf.userinterface.Delete("StatusAlwaysOnTop")
	else
		jf.userinterface.StatusAlwaysOnTop := 0
	Goto save
return

MinimizeToTray:
	GuiControlGet, MinimizeToTray
	if(jf.userinterface == null)
		jf.userinterface := {}
	if(MinimizeToTray==0)
		jf.userinterface.Delete("MinimizeToTray")
	else
		jf.userinterface.MinimizeToTray := 1
	Goto save
return

HidePopupsWhenStatusMinimized:
	GuiControlGet, HidePopupsWhenStatusMinimized
	if(jf.userinterface == null)
		jf.userinterface := {}
	if(HidePopupsWhenStatusMinimized==0)
		jf.userinterface.Delete("HidePopupsWhenStatusMinimized")
	else
		jf.userinterface.HidePopupsWhenStatusMinimized := 1
	Goto save
return

; --- Notifications

DoNotDisturb:
	GuiControlGet, DoNotDisturb
	if(jf.notifications == null)
		jf.notifications := {}
	if(DoNotDisturb==0)
		jf.notifications.Delete("DoNotDisturb")
	else
		jf.notifications.DoNotDisturb := 1
	Goto save
return

; --- Audio

viveHDMIGain:
	GuiControlGet, viveHDMIGain
	if(jf.audio == null)
		jf.audio := {}
	if(viveHDMIGain==1)
		jf.audio.Delete("viveHDMIGain")
	else
		jf.audio.viveHDMIGain := 0
	Goto save
return

; --- PerfCheck

perfGraphInHMD:
	GuiControlGet, perfGraphInHMD
	if(jf.perfcheck == null)
		jf.perfcheck := {}
		
	if(perfGraphInHMD==0)
		jf.perfcheck.Delete("perfGraphInHMD")
	else
		jf.perfcheck.perfGraphInHMD := 1
	Goto save
return

; enableCameraInDashboard:
; {
	; Gui Submit
	; if(enableCameraInDashboard==1)
		; jf.camera.enableCameraInDashboard := 1
	; else
		; jf.camera.enableCameraInDashboard := 0
	; GoSub save
	; Goto showGui
; }

ButtonSubmit:
Gui Submit
; msgbox % testValue
if(testValue==1)
	jf.steamvr.testValue := 1
else
	jf.steamvr.testValue := 0
	
if(requireHmd==1)
	jf.steamvr.Delete("requireHmd")
else
	jf.steamvr.requireHmd := 0
	
if(forcedDriver==1)
	jf.steamvr.forcedDriver := "null"
else
	jf.steamvr.Delete("forcedDriver")
	
if(activateMultipleDrivers==1)
	jf.steamvr.activateMultipleDrivers := 1
else
	jf.steamvr.Delete("activateMultipleDrivers")
	
if(enableHomeApp==1)
	jf.steamvr.Delete("enableHomeApp")
else
	jf.steamvr.enableHomeApp := 0
	
if(showMirrorView==1)
	jf.steamvr.showMirrorView := 1
else
	jf.steamvr.Delete("showMirrorView")
	
if(allowSupersampleFiltering==1)
	jf.steamvr.allowSupersampleFiltering := 1
else
	jf.steamvr.allowSupersampleFiltering := 0

if(forceFadeOnBadTracking==1)
	jf.steamvr.Delete("forceFadeOnBadTracking")
else
	jf.steamvr.forceFadeOnBadTracking := 0
		
if(enableCamera==1)
	jf.camera.enableCamera := 1
else
	jf.camera.enableCamera := 0

if(enableCameraForRoomView==1)
	jf.camera.enableCameraForRoomView := 1
else
	jf.camera.enableCameraForRoomView := 0

if(enableCameraInDashboard==1)
	jf.camera.enableCameraInDashboard := 1
else
	jf.camera.enableCameraInDashboard := 0
		
jf.Save(true)
; to close the file object and clean up, simply delete the instance
jf := ""
ExitApp

GuiClose:
jf := ""
ExitApp