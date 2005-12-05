; Copyright (c) 2005
; CACE Technologies
; All rights reserved.
; 
; Redistribution and use in source and binary forms, with or without 
; modification, are permitted provided that the following conditions 
; are met:
; 
; 1. Redistributions of source code must retain the above copyright 
; notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright 
; notice, this list of conditions and the following disclaimer in the 
; documentation and/or other materials provided with the distribution. 
; 3. Neither the name of the Politecnico di Torino nor the names of its 
; contributors may be used to endorse or promote products derived from 
; this software without specific prior written permission. 
; 
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; 
; This is the NSIS project for WinPcap installation. It will require NSIS
; from http://nsis.sourceforge.net/, plus three plugins:
;
;   - nsweb (http://nsis.sourceforge.net/wiki/NsWeb:_A_plugin_to_display_the_web_browser_control_in_a_custom_page)
;   - Internet (http://nsis.sourceforge.net/wiki/Internet_plugin)
;   - ExecDos (http://nsis.sourceforge.net/wiki/ExecDos)
;

;This includes the modern user interface
!include "MUI.nsh"

;--------------------------------
;Project definitions

  !define WINPCAP_PRJ_MAJOR "3"
  !define WINPCAP_PRJ_MINOR "2"
  !define WINPCAP_PRJ_REV "1"
  !define WINPCAP_PRJ_BUILD "28"
  !define WINPCAP_PROJ_VERSION_DOTTED "3.2.1.28"
  !define WINPCAP_LEGAL_COPYRIGHT "� 2005 CACE Technologies"
  !define WINPCAP_PRODUCT_NAME "WinPcap 3.2 beta1"
  !define WINPCAP_COMPANY_NAME "CACE Technologies"
  !define WINPCAP_FILE_NAME "WinPcap_${WINPCAP_PRJ_MAJOR}_${WINPCAP_PRJ_MINOR}_beta1.exe"
 
  ;Default installation folder
  InstallDir "$PROGRAMFILES\WinPcap"


;--------------------------------
;Includes and definitions


  ;the following two lines include the "Locate" function to find files
  !include "FileFunc.nsh"
  !insertmacro Locate

  !define VAR_0 0 ;$0
  !define VAR_1 1 ;$1
  !define VAR_2 2 ;$2
  !define VAR_3 3 ;$3
  !define VAR_4 4 ;$4
  !define VAR_5 5 ;$5
  !define VAR_6 6 ;$6
  !define VAR_7 7 ;$7
  !define VAR_8 8 ;$8
  !define VAR_9 9 ;$9

  ShowInstDetails nevershow
  ShowUninstDetails nevershow
  XPStyle on


  Var WINPCAP_OLD_FOUND
  Var WINPCAP_UNINSTALL_EXEC
  Var WINPCAP_OLD_PROJ_VERSION_DOTTED
  Var WINPCAP_TARGET_OS
  Var WINPCAP_TARGET_ARCHITECTURE
  Var WINPCAP_OLD_PRJ_MAJOR
  Var WINPCAP_OLD_PRJ_MINOR
  Var WINPCAP_OLD_PRJ_REV
  Var WINPCAP_OLD_PRJ_BUILD
  Var WINPCAP_OLD_PRJ_SAME_VERSION
  Var WINPCAP_OLD_INSTALLER
  Var WINPCAP_OLD_REBOOT_NEEDED
  Var WINPCAP_IS_ADMIN
  Var VARIABLE_1
  Var WOW_FS_REDIR_OLD_VAL
  Var BOOL_RET  
;--------------------------------
;General


  ;Name and file
  Name "${WINPCAP_PRODUCT_NAME}"
  OutFile "${WINPCAP_FILE_NAME}"
  
;Get Installation folder from registry if available
  InstallDirRegKey HKLM "Software\WinPcap" ""
  
;--------------------------------
;User interface Configuration

  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP "distribution\winpcap_nsis.bmp"
  !define MUI_ABORTWARNING
  !define MUI_CUSTOMFUNCTION_GUIINIT myGuiInit
  !define MUI_CUSTOMFUNCTION_ABORT .onInstFailed
  
; This is needed to give focus to the main window after the initial "installer loading..." dialog is shown.
  Function myGUIInit
    ShowWindow $HWNDPARENT 2
  FunctionEnd

;--------------------------------
;Installer Pages

  ;Installer
  Page custom "ShowHtmlPage" "" ""
  !insertmacro MUI_PAGE_LICENSE "distribution\license.txt"
  !insertmacro MUI_PAGE_INSTFILES
  !define MUI_FINISHPAGE_TEXT_REBOOT "An old version of WinPcap was present on the system. You should reboot the system in order for the new version to work properly."
  !insertmacro MUI_PAGE_FINISH

  ;Uninstaller
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH
  
;--------------------------------
;Languages
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Init function: copy the files we need during the installer

  Function .onInit

; Initialize the plugin directorty. Needed??
    InitPluginsDir

; Deny any attempt to start a silent installation of WinPcap
    SetSilent normal

;Detect the current Windows version
; this will set the WINPCAP_TARGET_OS variable
    Call GetWindowsVersion
    StrCmp $WINPCAP_TARGET_OS "vista" ContinueVistaInstallation
    goto NoVistaInstallation

ContinueVistaInstallation:
;NSIS seems to crash calling {Locate} on VISTA.
    Messagebox MB_YESNO|MB_ICONINFORMATION "This machine is running Microsoft Windows Vista/Longhorn. WinPcap has not been tested on this platform.$\nDo you want to continue with the installation? (Note: if you click 'No', this installer will abort.)" IDYES ForceVistaInstallation
    Abort

ForceVistaInstallation:
    StrCpy $WINPCAP_OLD_FOUND "false"
    goto SkipWinPcapVersionCheck
	

NoVistaInstallation:

;Detect all parameters of a previous installation of WinPcap
;after this call, all the WINPCAP_OLD_xxx variables are correctly set
    Call IsWinPcapInstalled

SkipWinPcapVersionCheck:

;check that the OS is supported....
    StrCmp $WINPCAP_TARGET_OS "95" SupportedOsOk
    StrCmp $WINPCAP_TARGET_OS "98" SupportedOsOk
    StrCmp $WINPCAP_TARGET_OS "ME" SupportedOsOk
    StrCmp $WINPCAP_TARGET_OS "NT" SupportedOsOk
    StrCmp $WINPCAP_TARGET_OS "2000" SupportedOsOk
    StrCmp $WINPCAP_TARGET_OS "XP" SupportedOsOk
    StrCmp $WINPCAP_TARGET_OS "2003" SupportedOsOk
    StrCmp $WINPCAP_TARGET_OS "vista" SupportedOsOk 

; if we reach this point, the OS is not supported. Simply exit.
    MessageBox MB_ICONEXCLAMATION|MB_OK "This version of Windows is not supported by ${WINPCAP_PRODUCT_NAME}.$\nThe installation will be aborted."
    Quit
   

SupportedOsOk:

;   If no previous installations of winpcap were found, skip to the normal installer checks
    StrCmp $WINPCAP_OLD_FOUND "false" CheckAdmin

; some winpcap version has been found. check if it's the same one or a newer one and abort.
    StrCmp $WINPCAP_OLD_PRJ_SAME_VERSION "same" SameVersionExit
    StrCmp $WINPCAP_OLD_PRJ_SAME_VERSION "newer" NewerVersionExit

; if we reach this point, an older installation has been found, skip to the normal installer checks
    goto CheckAdmin

NewerVersionExit:
; A newer version was found. Abort
    MessageBox MB_ICONEXCLAMATION|MB_OK "A newer version of WinPcap (internal version $WINPCAP_OLD_PROJ_VERSION_DOTTED) is already installed on this machine.$\nThe installation will be aborted."
    Quit

SameVersionExit:
; WinPcap has already been installed
    MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "${WINPCAP_PRODUCT_NAME} is already installed on this machine.$\nPress Ok if you want to force the installation, or Cancel if you want to abort the installation." IDOK ForceInstallation
    Quit

ForceInstallation:
; Reset the old installation found flag, so that the new installer will simply overwrite the files
StrCpy $WINPCAP_OLD_FOUND "false"

CheckAdmin:
; Only admins can install winpcap
    Call IsUserAdmin
    StrCmp $WINPCAP_IS_ADMIN "true" CheckX86

    MessageBox MB_ICONEXCLAMATION|MB_OK "${WINPCAP_PRODUCT_NAME} requires administrator privileges to be installed.$\nThe installation will be aborted."
    Quit

CheckX86:
; Check that the target platform is x86. On 9x/ME, this check can be skipped.
    StrCmp $WINPCAP_TARGET_OS "95" NormalInstallation
    StrCmp $WINPCAP_TARGET_OS "98" NormalInstallation
    StrCmp $WINPCAP_TARGET_OS "ME" NormalInstallation
	
	MessageBox MB_OK $WINPCAP_TARGET_ARCHITECTURE

    StrCmp $WINPCAP_TARGET_ARCHITECTURE "x86" NormalInstallation
    StrCmp $WINPCAP_TARGET_ARCHITECTURE "AMD64" AmdInstallationWarning
    
AmdInstallationWarning: 
    
    MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL  "You are about to install ${WINPCAP_PRODUCT_NAME} on Windows x64.$\nThe support for this operating system is still *highly* experimental.$\nPress Ok if you want to continue, or Cancel if you want to abort the installation." IDOK NormalInstallation

    Quit

NormalInstallation:

; if the OS is windows 2000/XP/2003 or similar, the installer will download the winpcap banner from the website.
; on OT windows, downloading that banner is not working properly: when no internet connection is available, the timeout in NSISdl::download is ignored
; As a consequence, we use our local copy.
    StrCmp $WINPCAP_TARGET_OS "95" WindowsOTBanner
    StrCmp $WINPCAP_TARGET_OS "98" WindowsOTBanner
    StrCmp $WINPCAP_TARGET_OS "ME" WindowsOTBanner
    StrCmp $WINPCAP_TARGET_OS "NT" WindowsOTBanner  ; on NT4 the timeout of download quiet is ignored, and it usually takes 30 seconds to retrun
    StrCmp $WINPCAP_TARGET_OS "2000" WindowsNTBanner
    StrCmp $WINPCAP_TARGET_OS "XP" WindowsNTBanner
    StrCmp $WINPCAP_TARGET_OS "2003" WindowsNTBanner
    StrCmp $WINPCAP_TARGET_OS "vista" WindowsNTBanner

WindowsNTBanner:
; Meantime the installer is downloading the banner, we should a "wait" dialog to the user, so that he doesn't think the
; installer is not working.
    nxs::Show /NOUNLOAD  "${WINPCAP_PRODUCT_NAME} Installer" /top "The installer is loading into memory. Please wait..." /end
    nxs::Update /NOUNLOAD /sub "0% complete" /pos 0 /end

; this approach does not work on win95/98/me, since the timeout is not respected, and the installer seems to be hanged.
    NSISdl::download_quiet /TIMEOUT=5000 "http://www.winpcap.org/install/banner/${WINPCAP_PROJ_VERSION_DOTTED}/banner.htm" "$TEMP\WpBann.htm"
    pop $R0
    nxs::Update /NOUNLOAD /sub "12% complete" /pos 0 /end
    StrCmp $R0 "success"  WindowsNTBannerDlImageG1 WindowsNTBannerFailed

WindowsNTBannerDlImageG1:
    NSISdl::download_quiet /TIMEOUT=2000 "http://www.winpcap.org/install/banner/${WINPCAP_PROJ_VERSION_DOTTED}/1.gif" "$TEMP\1.gif"
    pop $R0
    nxs::Update /NOUNLOAD /sub "25% complete" /pos 0 /end
    StrCmp $R0 "success"  WindowsNTBannerDlImageG2 WindowsNTBannerDlImageJ1

WindowsNTBannerDlImageG2:
    NSISdl::download_quiet /TIMEOUT=2000 "http://www.winpcap.org/install/banner/${WINPCAP_PROJ_VERSION_DOTTED}/2.gif" "$TEMP\2.gif"
    pop $R0
    nxs::Update /NOUNLOAD /sub "37% complete" /pos 0 /end
    StrCmp $R0 "success"  WindowsNTBannerDlImageG3 WindowsNTBannerDlImageJ1

WindowsNTBannerDlImageG3:
    NSISdl::download_quiet /TIMEOUT=2000 "http://www.winpcap.org/install/banner/${WINPCAP_PROJ_VERSION_DOTTED}/3.gif" "$TEMP\3.gif"
    pop $R0
    nxs::Update /NOUNLOAD /sub "50% complete" /pos 0 /end
    StrCmp $R0 "success"  WindowsNTBannerDlImageJ1

WindowsNTBannerDlImageJ1:
    NSISdl::download_quiet /TIMEOUT=2000 "http://www.winpcap.org/install/banner/${WINPCAP_PROJ_VERSION_DOTTED}/1.jpg" "$TEMP\1.jpg"
    pop $R0
    nxs::Update /NOUNLOAD /sub "62% complete" /pos 0 /end
    StrCmp $R0 "success"  WindowsNTBannerDlImageJ2 WindowsNTBannerEnded

WindowsNTBannerDlImageJ2:
    NSISdl::download_quiet /TIMEOUT=2000 "http://www.winpcap.org/install/banner/${WINPCAP_PROJ_VERSION_DOTTED}/2.jpg" "$TEMP\2.jpg"
    pop $R0
    nxs::Update /NOUNLOAD /sub "75% complete" /pos 0 /end
    StrCmp $R0 "success"  WindowsNTBannerDlImageJ3 WindowsNTBannerEnded

WindowsNTBannerDlImageJ3:
    NSISdl::download_quiet /TIMEOUT=2000 "http://www.winpcap.org/install/banner/${WINPCAP_PROJ_VERSION_DOTTED}/3.jpg" "$TEMP\3.jpg"
    pop $R0
    nxs::Update /NOUNLOAD /sub "88% complete" /pos 0 /end
    StrCmp $R0 "success"  WindowsNTBannerEnded

; We reach this point if the download failed. Use our local copy.
WindowsNTBannerFailed:
    File /oname=$TEMP\WpBann.htm WpBann.htm

WindowsNTBannerEnded:
    nxs::Update /NOUNLOAD /sub "100% complete" /pos 100 /end
; we sleep a bit to allow the user to see our "wait" dialog at 100% for a little bit.
    Sleep 500
    nxs::Destroy

    goto Ended

WindowsOTBanner:
; Windows OT. Simply use our local copy of the banner.
    File /oname=$TEMP\WpBann.htm WpBann.htm
Ended:

  FunctionEnd


;--------------------------------
;Init function for the uninstaller: disable support for silent removal
  Function un.onInit
    InitPluginsDir
; Deny any attempt to start a silent uninstallation of WinPcap
    SetSilent normal

;Detect the current Windows version
; this will set the WINPCAP_TARGET_OS variable
    Call un.GetWindowsVersion

; Only admins can uninstall winpcap
    Call un.IsUserAdmin
    StrCmp $WINPCAP_IS_ADMIN "true" NormalUninstallation

    MessageBox MB_ICONEXCLAMATION|MB_OK "${WINPCAP_PRODUCT_NAME} requires administrator privileges to be uninstalled.$\nThe uninstallation will be aborted."
    Quit

NormalUninstallation:
; go with the installation
  FunctionEnd

;--------------------------------
;Called when the installation fails. Just remove any temp file on the machine.
  Function .onInstFailed
    call CleanupTempFiles
  FunctionEnd

;--------------------------------
;Called when the installation succeeds. Just remove any temp file on the machine.
  Function .onInstSuccess
    call CleanupTempFiles
  FunctionEnd

;--------------------------------
;Remove any temp file used during the installation
  Function CleanupTempFiles
    Delete /REBOOTOK $TEMP\WpBann.htm
    Delete /REBOOTOK $TEMP\1.gif
    Delete /REBOOTOK $TEMP\1.jpg
    Delete /REBOOTOK $TEMP\2.gif
    Delete /REBOOTOK $TEMP\2.jpg
    Delete /REBOOTOK $TEMP\3.gif
    Delete /REBOOTOK $TEMP\3.jpg
  FunctionEnd

;--------------------------------
;Called to show the initial web page with the banneer.
  Function "ShowHtmlPage"

!insertmacro MUI_HEADER_TEXT "${WINPCAP_PRODUCT_NAME} Installer" "Welcome to the ${WINPCAP_PRODUCT_NAME} Installation Wizard"

    nsWeb::ShowWebInPage "$TEMP\WpBann.htm"

  FunctionEnd

;--------------------------------
;Main Installer Section
Section "Main Installer Section" MainInstall

;
; First of all, we delete the intermediate files used only by the installer
;
    Call CleanupTempFiles

;Assume no reboot by default
    SetRebootFlag false

; if no previous version of WinPcap is installed, skip to the copy procedure.
    StrCmp $WINPCAP_OLD_FOUND "false" MainInstallationProcedure

; ok, some version of WinPcap has been detected. Let's see if we can remove it.
; Uninstallation heuristic:
; First, we check if WinPcap is detected (packet.dll)
; if it's not detected, ok
; if it's detected, check if some app is still using it: try to rename packet.dll.
; If it fails, then maybe some user is using it. Warn the user (stop the app and restart the installation), and abort the installation.
; If it succeeds, if the uninsntaller is present, warn the user and call the uninstaller (advising to choose not to reboot). Then continue.
; If rename succeeds and the uninstaller is not present, ask the user what to do (abort, continue+reboot).
    CopyFiles "$SYSDIR\packet.dll" "$SYSDIR\_packet.dlluninstall"
    Delete "$SYSDIR\packet.dll"
    IfErrors WinPcapIsInUse

;first of all, revert the file name change
    Rename "$SYSDIR\_packet.dlluninstall" "$SYSDIR\packet.dll"

; now let's check if an uninstaller is available
    ReadRegStr $WINPCAP_UNINSTALL_EXEC HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" "UninstallString"
    IfErrors WinpcapUninstallerNotDetected
  
;An uninstaller has been detected. Ask the user if he wants to remove it.
    Messagebox MB_YESNO|MB_ICONINFORMATION "A previous version of WinPcap has been detected on this system and needs to be removed before proceeding.$\nDo you want to uninstall it? (Note: if you click 'No', this installer will abort.)" IDYES RemoveRecent IDNO AbortInstallation

; Winpcap is still used. Abor the installation.
WinPcapIsInUse:
    Messagebox MB_OK|MB_ICONEXCLAMATION "A previous version of WinPcap has been detected on this system and cannot be removed because in use by another application. Please close all the WinPcap-based applications and run the installer again.$\n$\nThis installation will now abort." IDOK AbortInstallation

RemoveRecent:
    MessageBox MB_ICONINFORMATION|MB_OK "The uninstaller for a previous version of WinPcap will now run.$\n$\nNOTE: if the uninstaller asks you to reboot at the end of the procedure, please choose to NOT reboot."
; look if it's a NSIS based installation, or a GHOST one. they have different uninstall command lines.
    StrCmp $WINPCAP_OLD_INSTALLER "nsis"  NSISSetupRemoval

;OldSetupremoval
    ExecWait "$WINPCAP_UNINSTALL_EXEC"
    goto EndRemoval

NSISSetupRemoval:
     ExecWait '"$INSTDIR\uninstall.exe" _?=$INSTDIR'

; look if we need a reboot after the uninstallation
; basically, we do not need a reboot if the previous version was >= 3.0.0.14
EndRemoval:

     SetRebootFlag true
     StrCmp $WINPCAP_OLD_REBOOT_NEEDED "true" MainInstallationProcedure
     SetRebootFlag false
     Goto MainInstallationProcedure

WinPcapUninstallerNotDetected:
    Messagebox MB_YESNO|MB_ICONINFORMATION "A previous version of WinPcap has been detected on this system. Unfortunately, this installer is not able to remove it.$\nDo you want to continue with the installation?" IDYES OldWinPcapNotUninstalled IDNO AbortInstallation

OldWinPcapNotUninstalled:
; We detected an OLD version of winpcap, and we were not able to remove it. Just force a reboot at the end.
    SetRebootFlag true
    Goto MainInstallationProcedure

AbortInstallation:
    Abort "Installation aborted. The old version of WinPcap has not been removed. Click Cancel to Exit."
    Goto EndInstallation

MainInstallationProcedure:

;
;tell the installer to put the start menu stuff under "all users"
;this prevents NSIS from having craziness during uninstallation
;
; The best should be to have it on the admin (=current) user, but
; the link to winpcap is useful, as well.
    SetShellVarContext all

    SetOutPath "$INSTDIR"

;
;Copy Files
;

;Common Files
    File "Distribution\2000\daemon_mgm.exe"
    File "Distribution\2000\NetMonInstaller.exe"
    File "Distribution\2000\npf_mgm.exe"
    File "Distribution\2000\rpcapd.exe"

;Move to the system folder, whatever system we are
    SetOutPath "$SYSDIR"

;Copy wpcap and the pthreads
    File "Distribution\wpcap.dll"
    File "Distribution\pthreadVC.dll"

;Now jump to the copy functions related to this OS
    StrCmp $WINPCAP_TARGET_OS "95" CopyFiles9x
    StrCmp $WINPCAP_TARGET_OS "98" CopyFiles9x
    StrCmp $WINPCAP_TARGET_OS "ME" CopyFiles9x
    StrCmp $WINPCAP_TARGET_OS "NT" CopyFilesNT4
    StrCmp $WINPCAP_TARGET_OS "2000" CopyFilesNT5
    StrCmp $WINPCAP_TARGET_OS "XP" CopyFilesNT5
    StrCmp $WINPCAP_TARGET_OS "2003" CopyFilesNT5
    StrCmp $WINPCAP_TARGET_OS "vista" CopyFilesVista  ; vista (beta1) seems not to have the netmon stuff...
  
	

CopyFilesNT5:
    File "Distribution\2000\packet.dll"
    File "Distribution\2000\wanpacket.dll"
	
	StrCmp $WINPCAP_TARGET_ARCHITECTURE "x86" CopyX86DriverLabel
	StrCmp $WINPCAP_TARGET_ARCHITECTURE "AMD64" CopyAMD64DriverLabel
	
CopyX86DriverLabel:	
	Call CopyX86Driver
    goto CopiedNT5Files
    
CopyAMD64DriverLabel:
	Call CopyAMD64Driver
    goto CopiedNT5Files

CopiedNT5Files:    
  
;Run install commands
; Todo add error checking for these apps
    ExecDos::exec '$INSTDIR\npf_mgm.exe -r'
    Pop $R0
    StrCmp $R0 "0" NpfMgmOkLabel1
    
	MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while registering the NPF service (npf_mgm.exe -r failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."

NpfMgmOkLabel1:    
    ExecDos::exec '$INSTDIR\daemon_mgm.exe -r'
    Pop $R0
    StrCmp $R0 "0" DaemonMgmOkLabel1
    
	MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while registering the rpcapd service (daemon_mgm.exe -r failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."

DaemonMgmOkLabel1:    

; The NetMon component is not available on x64 and on vista!
	StrCmp $WINPCAP_TARGET_ARCHITECTURE "AMD64" EndCopy
    StrCmp $WINPCAP_TARGET_OS "vista" EndCopy
    
    ExecDos::exec '$INSTDIR\NetMonInstaller.exe i'
    Pop $R0
    StrCmp $R0 "0" EndCopy
    
	MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while installing the NetMon service (NetMonInstaller.exe i failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."

    Goto EndCopy

CopyFilesNT4:
    File 'Distribution\NT\packet.dll'
    Call CopyNT4Driver

;Run install commands
; Todo add error checking for these apps
    ExecDos::exec '$INSTDIR\npf_mgm.exe -r'
    Pop $R0
    ExecDos::exec '$INSTDIR\daemon_mgm.exe -r'
    Pop $R0

    Goto EndCopy

CopyFiles9x:
    File "Distribution\9x\packet.dll"
    File "Distribution\9x\npf.vxd"
    Goto EndCopy

CopyFilesVista:
    File "Distribution\nt\packet.dll"

	StrCmp $WINPCAP_TARGET_ARCHITECTURE "x86" CopyX86DriverVistaLabel
	StrCmp $WINPCAP_TARGET_ARCHITECTURE "AMD64" CopyAMD64DriverVistaLabel
	
CopyX86DriverVistaLabel:	
    Call CopyX86Driver
    goto CopiedVistaFiles
    
CopyAMD64DriverVistaLabel:	
    Call CopyAMD64Driver
    goto CopiedVistaFiles

CopiedVistaFiles:    
  
;Run install commands
; Todo add error checking for these apps
    ExecDos::exec '$INSTDIR\npf_mgm.exe -r'
    Pop $R0
    ExecDos::exec '$INSTDIR\daemon_mgm.exe -r'
    Pop $R0

    Goto EndCopy

EndCopy:

;
;Store installation folder
;
    WriteRegStr HKLM "SOFTWARE\WinPcap" "" $INSTDIR
 
;
;Create an "add/remove programs" entry
;
    WriteRegStr HKLM \
	"Software\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"DisplayName" "${WINPCAP_PRODUCT_NAME}"

    WriteRegStr HKLM \
	"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"UninstallString" "$INSTDIR\uninstall.exe"  

    WriteRegStr HKLM \
	"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"Publisher" "CACE Technologies"  

    WriteRegStr HKLM \
	"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"URLInfoAbout" "http://www.cacetech.com"
  
    WriteRegStr HKLM \
	"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"URLUpdateInfo" "http://www.winpcap.org"

    WriteRegStr HKLM \
	"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"VersionMajor" "${WINPCAP_PRJ_MAJOR}"  

    WriteRegStr HKLM \
	"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"VersionMinor" "${WINPCAP_PRJ_MINOR}"  

    WriteRegStr HKLM \
	"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"DisplayVersion" "${WINPCAP_PROJ_VERSION_DOTTED}"

;this is a sort of hack: on windows 2000 for some strange reason it puts an ugly icon in the control panel
;for this OS, since we don't have a winpcap icon, yet, we use the uninstall icon, better than nothing....

    StrCmp $WINPCAP_TARGET_OS "2000" AddWinpcapIcon  
    goto NoWinpcapIcon

AddWinpcapIcon:

    WriteRegStr HKLM \
	"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst" \ 
	"DisplayIcon" "$INSTDIR\uninstall.exe"  

NoWinpcapIcon:

    CreateDirectory "$SMPROGRAMS\WinPcap"

;
;Create start menu shortcuts
;
    WriteINIStr "$SMPROGRAMS\WinPcap\WinPcap Web Site.url" \
          "InternetShortcut" "URL" "http://www.winpcap.org/"
    CreateShortCut "$SMPROGRAMS\WinPcap\Uninstall ${WINPCAP_PRODUCT_NAME}.lnk" "$INSTDIR\uninstall.exe"

;Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"

EndInstallation:

SectionEnd

;--------------------------------
;Language-related stuff
;Language strings
  LangString DESC_MainInstall ${LANG_ENGLISH} "WinPcap installation section. No panels"

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${MainInstall} $(DESC_MainInstall)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------
;Uninstaller Section
Section "Uninstall" MainUnistall

    SetShellVarContext all

;Move to the system folder, whatever system we are
    SetOutPath "$SYSDIR"

;
;Delete files
;
;Now jump to the remove functions related to this OS
    StrCmp $WINPCAP_TARGET_OS "95" RmFiles9x
    StrCmp $WINPCAP_TARGET_OS "98" RmFiles9x
    StrCmp $WINPCAP_TARGET_OS "ME" RmFiles9x
    StrCmp $WINPCAP_TARGET_OS "NT" RmFilesNT4
    StrCmp $WINPCAP_TARGET_OS "2000" RmFilesNT5
    StrCmp $WINPCAP_TARGET_OS "XP" RmFilesNT5
    StrCmp $WINPCAP_TARGET_OS "2003" RmFilesNT5
    StrCmp $WINPCAP_TARGET_OS "vista" RmFilesVista
  
RmFilesNT4:
RmFilesNT5:
RmFilesVista:

;Run uninstall commands
; Todo add error checking for these apps
    ExecDos::exec '"$INSTDIR\npf_mgm.exe" "-u"'
    Pop $R0
    StrCmp $R0 "0" NpfMgmOkLabel1
    
	MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while deregistering the NPF service (npf_mgm.exe -u failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."

NpfMgmOkLabel1:    
    ExecDos::exec '"$INSTDIR\daemon_mgm.exe" "-u"'
    Pop $R0
    StrCmp $R0 "0" DaemonMgmOkLabel1
    
	MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while deregistering the rpcapd service (daemon_mgm.exe -u failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."

DaemonMgmOkLabel1:    

;Delete files
; The rebootok is used to delete the files on reboot if they are in use.
;NOTE: this file does not exist on Vista and NT4, but NSIS ignores any file that doesn't exist :-))
    Delete /REBOOTOK "$SYSDIR\wanpacket.dll"

	StrCmp $WINPCAP_TARGET_ARCHITECTURE "x86" RemoveX86DriverLabel
	StrCmp $WINPCAP_TARGET_ARCHITECTURE "AMD64" RemoveAMD64DriverLabel

RemoveX86DriverLabel:
	Call un.RemoveX86Driver
	Goto EndRm

RemoveAMD64DriverLabel:
	Call un.RemoveAMD64Driver
	Goto EndRm

RmFiles9x:
    Delete /REBOOTOK "$SYSDIR\npf.vxd"
    Goto EndRm

EndRm:

;Delete common files
    Delete /REBOOTOK "$INSTDIR\INSTALL.LOG" ;may be present after removing winpcap 2.3
    Delete /REBOOTOK "$INSTDIR\daemon_mgm.exe"
    Delete /REBOOTOK "$INSTDIR\NetMonInstaller.exe"
    Delete /REBOOTOK "$INSTDIR\npf_mgm.exe"
    Delete /REBOOTOK "$INSTDIR\rpcapd.exe"
    Delete /REBOOTOK "$SYSDIR\packet.dll"
    Delete /REBOOTOK "$SYSDIR\wpcap.dll"
    Delete /REBOOTOK "$SYSDIR\pthreadVC.dll"

;
;remove start menu entries
;

    SetOutPath "$SMPROGRAMS"
    RMDir /r "$SMPROGRAMS\WinPcap"

;
;delete the installation directory
;
    RMDir /r "$INSTDIR"

;
;remove registry entries
;
    DeleteRegKey /ifempty HKLM "Software\WinPcap"
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinPcapInst"

SectionEnd

;--------------------------------
;Installer Version Information
  VIProductVersion "${WINPCAP_PROJ_VERSION_DOTTED}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${WINPCAP_PRODUCT_NAME}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" ""
  VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${WINPCAP_COMPANY_NAME}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" ""
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "${WINPCAP_LEGAL_COPYRIGHT}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${WINPCAP_PRODUCT_NAME} installer"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${WINPCAP_PROJ_VERSION_DOTTED}"


Function CopyAMD64Driver
	
	; these two stupid assignments are used to avoid a compilation warning...
	StrCpy $BOOL_RET "1"
	StrCpy $WOW_FS_REDIR_OLD_VAL "1"
	
	System::Call 'kernel32::Wow64DisableWow64FsRedirection(*i .$WOW_FS_REDIR_OLD_VAL).$BOOL_RET'
	
	StrCmp $BOOL_RET "error" ErrorCannotLoadDll
	StrCmp $BOOL_RET 0 ErrorCannotDisableFsRedirector
    
	push $R0
	push $OUTDIR
	SetOutPath $SYSDIR
    File /oname=drivers\npf.sys Distribution\x86-64\npf.sys
	pop $R0
	SetOutPath $R0
	pop $R0

	System::Call 'kernel32::Wow64RevertWow64FsRedirection(*i $WOW_FS_REDIR_OLD_VAL).$BOOL_RET'

	StrCmp $BOOL_RET "error" ErrorCannotLoadDll2
	StrCmp $BOOL_RET 0 ErrorCannotRevertFsRedirector
	
	goto End

	ErrorCannotLoadDll:
		MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while disabling the WOW64 FileSystem Redirector (cannot load Wow64DisableWow64FsRedirection). Please contact the WinPcap Team <winpcap-team@winpcap.org>."
		SetErrors
		goto End
		
	ErrorCannotDisableFsRedirector:
		MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while disabling the WOW64 FileSystem Redirector (Wow64DisableWow64FsRedirection failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."
		SetErrors
		goto End

	ErrorCannotLoadDll2:
		MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while disabling the WOW64 FileSystem Redirector (cannot load Wow64RevertWow64FsRedirection). Please contact the WinPcap Team <winpcap-team@winpcap.org>."
		SetErrors
		goto End
		
	ErrorCannotRevertFsRedirector:
		MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while disabling the WOW64 FileSystem Redirector (Wow64RevertWow64FsRedirection failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."
		SetErrors
		goto End
		
End:

FunctionEnd

Function CopyX86Driver
	
	push $R0
	push $OUTDIR
	SetOutPath $SYSDIR
    File /oname=drivers\npf.sys Distribution\2000\npf.sys
	pop $R0
	SetOutPath $R0
	pop $R0

FunctionEnd

Function CopyNT4Driver
	
	push $R0
	push $OUTDIR
	SetOutPath $SYSDIR
    File /oname=drivers\npf.sys Distribution\NT\npf.sys
	pop $R0
	SetOutPath $R0
	pop $R0

FunctionEnd


Function un.RemoveAMD64Driver
	
	; these two stupid assignments are used to avoid a compilation warning...
	StrCpy $BOOL_RET "1"
	StrCpy $WOW_FS_REDIR_OLD_VAL "1"
	
	System::Call 'kernel32::Wow64DisableWow64FsRedirection(*i .$WOW_FS_REDIR_OLD_VAL).$BOOL_RET'
	
	StrCmp $BOOL_RET "error" ErrorCannotLoadDll
	StrCmp $BOOL_RET 0 ErrorCannotDisableFsRedirector
    
    Delete /REBOOTOK "$SYSDIR\drivers\npf.sys"

	System::Call 'kernel32::Wow64RevertWow64FsRedirection(*i $WOW_FS_REDIR_OLD_VAL).$BOOL_RET'

	StrCmp $BOOL_RET "error" ErrorCannotLoadDll2
	StrCmp $BOOL_RET 0 ErrorCannotRevertFsRedirector
	
	goto End

	ErrorCannotLoadDll:
		MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while disabling the WOW64 FileSystem Redirector (cannot load Wow64DisableWow64FsRedirection). Please contact the WinPcap Team <winpcap-team@winpcap.org>."
		SetErrors
		goto End
		
	ErrorCannotDisableFsRedirector:
		MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while disabling the WOW64 FileSystem Redirector (Wow64DisableWow64FsRedirection failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."
		SetErrors
		goto End

	ErrorCannotLoadDll2:
		MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while disabling the WOW64 FileSystem Redirector (cannot load Wow64RevertWow64FsRedirection). Please contact the WinPcap Team <winpcap-team@winpcap.org>."
		SetErrors
		goto End
		
	ErrorCannotRevertFsRedirector:
		MessageBox MB_OK|MB_ICONEXCLAMATION "An error occurred while disabling the WOW64 FileSystem Redirector (Wow64RevertWow64FsRedirection failed). Please contact the WinPcap Team <winpcap-team@winpcap.org>."
		SetErrors
		goto End
		
End:		

FunctionEnd

Function un.RemoveX86Driver
	
    Delete /REBOOTOK "$SYSDIR\drivers\npf.sys"

FunctionEnd

;--------------------------------
;--------------------------------
;--------------------------------
;--------------------------------
; EXTERNAL FUNCTIONS TAKEN ON THE WEB
;--------------------------------
;--------------------------------
;--------------------------------
;--------------------------------
; GetWindowsVersion Function, coming from nsis manual but slightly
; modified by LD to return NT without number
;
; Based on Yazno's function, http://yazno.tripod.com/powerpimpit/
; Updated by Joost Verburg
;
; Returns on top of stack
;
; Windows Version (95, 98, ME, NT, 2000, XP, 2003)
; or
; '' (Unknown Windows Version)
;
; Usage:
;   Call GetWindowsVersion
;   Pop $R0
;   ; at this point $R0 is "NT 4.0" or whatnot
 
 Function GetWindowsVersion
 
   Push $R0
   Push $R1
 
   ClearErrors
 
   ReadRegStr $R0 HKLM \
   "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion

   IfErrors 0 lbl_winnt
   
   ; we are not NT
   ReadRegStr $R0 HKLM \
   "SOFTWARE\Microsoft\Windows\CurrentVersion" VersionNumber
 
   StrCpy $R1 $R0 1
   StrCmp $R1 '4' 0 lbl_error
 
   StrCpy $R1 $R0 3
 
   StrCmp $R1 '4.0' lbl_win32_95
   StrCmp $R1 '4.9' lbl_win32_ME lbl_win32_98
 
   lbl_win32_95:
     StrCpy $WINPCAP_TARGET_OS '95'
   Goto lbl_done
 
   lbl_win32_98:
     StrCpy $WINPCAP_TARGET_OS '98'
   Goto lbl_done
 
   lbl_win32_ME:
     StrCpy $WINPCAP_TARGET_OS 'ME'
   Goto lbl_done
 
   lbl_winnt:

   StrCpy $R1 $R0 1
 
   StrCmp $R1 '3' lbl_winnt_x
   StrCmp $R1 '4' lbl_winnt_x
 
   StrCpy $R1 $R0 3
 
   StrCmp $R1 '5.0' lbl_winnt_2000
   ; note: this is not true on x64 machines, the version is 5.2
   StrCmp $R1 '5.1' lbl_winnt_XP
   StrCmp $R1 '5.2' lbl_winnt_XP64_2003
   StrCmp $R1 '6.0' lbl_vista lbl_error
 
 
 
   lbl_winnt_x:
     StrCpy $WINPCAP_TARGET_OS 'NT'

	 ReadRegStr $WINPCAP_TARGET_ARCHITECTURE HKEY_LOCAL_MACHINE "System\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"

   Goto lbl_done
 
   lbl_winnt_2000:
     Strcpy $WINPCAP_TARGET_OS '2000'

	 ReadRegStr $WINPCAP_TARGET_ARCHITECTURE HKEY_LOCAL_MACHINE "System\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"

   Goto lbl_done
 
   lbl_winnt_XP:
     Strcpy $WINPCAP_TARGET_OS 'XP'

	 ReadRegStr $WINPCAP_TARGET_ARCHITECTURE HKEY_LOCAL_MACHINE "System\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
	 
	 IfErrors lbl_error

   Goto lbl_done
 
   lbl_winnt_XP64_2003:

	 ReadRegStr $WINPCAP_TARGET_ARCHITECTURE HKEY_LOCAL_MACHINE "System\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
	 IfErrors lbl_error

	StrCmp $WINPCAP_TARGET_ARCHITECTURE 'x86' lbl_winnt_2003 lbl_winnt_XP

lbl_winnt_2003:

     Strcpy $WINPCAP_TARGET_OS '2003'

   Goto lbl_done
 
   lbl_vista:
     Strcpy $WINPCAP_TARGET_OS 'vista'

	 ReadRegStr $WINPCAP_TARGET_ARCHITECTURE HKEY_LOCAL_MACHINE "System\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
	 IfErrors lbl_error

   Goto lbl_done

   lbl_error:
     Strcpy $WINPCAP_TARGET_OS ''
   lbl_done:
 
   Pop $R1
   Pop $R0
 
 FunctionEnd

;--------------------------------
;Exactly the same of previous function, but the name starts with "un."
;The reason is that the NSIS uninstaller accepts only function that start with "un."
 
 Function un.GetWindowsVersion
 
   Push $R0
   Push $R1
 
   ClearErrors
 
   ReadRegStr $R0 HKLM \
   "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion

   IfErrors 0 lbl_winnt
   
   ; we are not NT
   ReadRegStr $R0 HKLM \
   "SOFTWARE\Microsoft\Windows\CurrentVersion" VersionNumber
 
   StrCpy $R1 $R0 1
   StrCmp $R1 '4' 0 lbl_error
 
   StrCpy $R1 $R0 3
 
   StrCmp $R1 '4.0' lbl_win32_95
   StrCmp $R1 '4.9' lbl_win32_ME lbl_win32_98
 
   lbl_win32_95:
     StrCpy $WINPCAP_TARGET_OS '95'
   Goto lbl_done
 
   lbl_win32_98:
     StrCpy $WINPCAP_TARGET_OS '98'
   Goto lbl_done
 
   lbl_win32_ME:
     StrCpy $WINPCAP_TARGET_OS 'ME'
   Goto lbl_done
 
   lbl_winnt:

   StrCpy $R1 $R0 1
 
   StrCmp $R1 '3' lbl_winnt_x
   StrCmp $R1 '4' lbl_winnt_x
 
   StrCpy $R1 $R0 3
 
   StrCmp $R1 '5.0' lbl_winnt_2000
   ; note: this is not true on x64 machines, the version is 5.2
   StrCmp $R1 '5.1' lbl_winnt_XP
   StrCmp $R1 '5.2' lbl_winnt_XP64_2003
   StrCmp $R1 '6.0' lbl_vista lbl_error
 
 
 
   lbl_winnt_x:
     StrCpy $WINPCAP_TARGET_OS 'NT'
   Goto lbl_done
 
   lbl_winnt_2000:
     Strcpy $R0 '2000'
   Goto lbl_done
 
   lbl_winnt_XP:
     Strcpy $WINPCAP_TARGET_OS 'XP'

	 ReadRegStr $WINPCAP_TARGET_ARCHITECTURE HKEY_LOCAL_MACHINE "System\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
	 
	 IfErrors lbl_error

   Goto lbl_done
 
   lbl_winnt_XP64_2003:

	 ReadRegStr $WINPCAP_TARGET_ARCHITECTURE HKEY_LOCAL_MACHINE "System\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
	 IfErrors lbl_error

	StrCmp $WINPCAP_TARGET_ARCHITECTURE 'x86' lbl_winnt_2003 lbl_winnt_XP

lbl_winnt_2003:

     Strcpy $WINPCAP_TARGET_OS '2003'

   Goto lbl_done
 
   lbl_vista:
     Strcpy $WINPCAP_TARGET_OS 'vista'

	 ReadRegStr $WINPCAP_TARGET_ARCHITECTURE HKEY_LOCAL_MACHINE "System\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
	 IfErrors lbl_error

   Goto lbl_done

   lbl_error:
     Strcpy $WINPCAP_TARGET_OS ''
   lbl_done:
 
   Pop $R1
   Pop $R0
 
 FunctionEnd

;--------------------------------
;this function checks if WinPcap is installed, and stores all the information into the WINPCAP_OLD_xxx variable
Function IsWinPcapInstalled

  StrCpy $WINPCAP_OLD_FOUND "false"
  ${Locate} "$SYSDIR" "/M=packet.dll" 'PacketFound'

FunctionEnd

; this callback is called when packet.dll is found. It stores the version of the dll 
; into  WINPCAP_OLD_PROJ_VERSION_DOTTED
Function PacketFound

  StrCpy $WINPCAP_OLD_FOUND "true"

  GetDLLVersion "$SYSDIR\packet.dll" $R0 $R1
  IfErrors IWINT_Exit 
 
  IntOp $WINPCAP_OLD_PRJ_MAJOR $R0 / 0x00010000
  IntOp $WINPCAP_OLD_PRJ_MINOR $R0 & 0x0000FFFF
  IntOp $WINPCAP_OLD_PRJ_REV $R1 / 0x00010000
  IntOp $WINPCAP_OLD_PRJ_BUILD $R1 & 0x0000FFFF

  StrCpy $WINPCAP_OLD_PROJ_VERSION_DOTTED "$WINPCAP_OLD_PRJ_MAJOR.$WINPCAP_OLD_PRJ_MINOR.$WINPCAP_OLD_PRJ_REV.$WINPCAP_OLD_PRJ_BUILD"

;
;   Check if a newer version is already running
;   we look at the version of the files, rather at the times.
    IntCmp $WINPCAP_OLD_PRJ_MAJOR ${WINPCAP_PRJ_MAJOR} SameVer1 Older Newer
SameVer1:
    IntCmp $WINPCAP_OLD_PRJ_MINOR ${WINPCAP_PRJ_MINOR} SameVer2 Older Newer
SameVer2:
    IntCmp $WINPCAP_OLD_PRJ_REV ${WINPCAP_PRJ_REV} SameVer3 Older Newer
SameVer3:
    IntCmp $WINPCAP_OLD_PRJ_BUILD ${WINPCAP_PRJ_BUILD} SameVersion Older Newer

Older:
   StrCpy $WINPCAP_OLD_PRJ_SAME_VERSION "older"
   Goto NsisInstallerCheck

Newer:
   StrCpy $WINPCAP_OLD_PRJ_SAME_VERSION "newer"
   Goto NsisInstallerCheck

SameVersion:
   StrCpy $WINPCAP_OLD_PRJ_SAME_VERSION "same"
   Goto NsisInstallerCheck

NsisInstallerCheck:

; we started using nsis from version 3.1.0.26

    IntCmp $WINPCAP_OLD_PRJ_MAJOR "3" NsisSameVer1 NoNsisInst NsisInst
NsisSameVer1:
    IntCmp $WINPCAP_OLD_PRJ_MINOR "1" NsisSameVer2 NoNsisInst NsisInst
NsisSameVer2:
    IntCmp $WINPCAP_OLD_PRJ_REV "0" NsisSameVer3 NoNsisInst NsisInst
NsisSameVer3:
    IntCmp $WINPCAP_OLD_PRJ_BUILD "26" NsisInst NoNsisInst NsisInst
    
NoNsisInst:
    StrCpy $WINPCAP_OLD_INSTALLER "ghost"
    Goto CheckForReboot

NsisInst:
    StrCpy $WINPCAP_OLD_INSTALLER "nsis"
    Goto PF_End

CheckForReboot:

  StrCmp $WINPCAP_OLD_PROJ_VERSION_DOTTED "3.0.0.14" NoRebootNeeded
  StrCmp $WINPCAP_OLD_PROJ_VERSION_DOTTED "3.0.0.15" NoRebootNeeded
  StrCmp $WINPCAP_OLD_PROJ_VERSION_DOTTED "3.0.0.16" NoRebootNeeded
  StrCmp $WINPCAP_OLD_PROJ_VERSION_DOTTED "3.0.0.17" NoRebootNeeded
  StrCmp $WINPCAP_OLD_PROJ_VERSION_DOTTED "3.0.0.18" NoRebootNeeded
  StrCmp $WINPCAP_OLD_PROJ_VERSION_DOTTED "3.0.0.19" NoRebootNeeded
  StrCpy $VARIABLE_1 $WINPCAP_OLD_PROJ_VERSION_DOTTED 3
  StrCmp $VARIABLE_1 "3.1" NoRebootNeeded

  goto RebootNeeded

NoRebootNeeded:
  
  StrCpy $WINPCAP_OLD_REBOOT_NEEDED "false"
  goto PF_End

RebootNeeded:
  StrCpy $WINPCAP_OLD_REBOOT_NEEDED "true"
  goto PF_End

IWINT_Exit:
; this means "old version"
  StrCpy $WINPCAP_OLD_PROJ_VERSION_DOTTED  "0.0.0.0"
  StrCpy $WINPCAP_OLD_PRJ_MAJOR            "0"
  StrCpy $WINPCAP_OLD_PRJ_MINOR            "0"
  StrCpy $WINPCAP_OLD_PRJ_REV              "0"
  StrCpy $WINPCAP_OLD_PRJ_BUILD            "0"


PF_End:

FunctionEnd

; Author: Lilla (lilla@earthlink.net) 2003-06-13
; function IsUserAdmin uses plugin \NSIS\PlusgIns\UserInfo.dll
; This function is based upon code in \NSIS\Contrib\UserInfo\UserInfo.nsi
; This function was tested under NSIS 2 beta 4 (latest CVS as of this writing).
;
; Usage:
;   Call IsUserAdmin
;        ; $WINPCAP_IS_ADMIN  is "true" or "false"
;
Function IsUserAdmin
Push $R1
Push $R2

ClearErrors
UserInfo::GetName
IfErrors Win9x
Pop $R1
UserInfo::GetAccountType
Pop $R2

StrCmp $R2 "Admin" 0 Continue
; Observation: I get here when running Win98SE. (Lilla)
; The functions UserInfo.dll looks for are there on Win98 too,
; but just don't work. So UserInfo.dll, knowing that admin isn't required
; on Win98, returns admin anyway. (per kichik)
; MessageBox MB_OK 'User "$R1" is in the Administrators group'
StrCpy $WINPCAP_IS_ADMIN "true"
Goto Done

Continue:
; You should still check for an empty string because the functions
; UserInfo.dll looks for may not be present on Windows 95. (per kichik)
StrCmp $R2 "" Win9x
StrCpy $WINPCAP_IS_ADMIN "false"
;MessageBox MB_OK 'User "$R1" is in the "$R2" group'
Goto Done

Win9x:
; comment/message below is by UserInfo.nsi author:
; This one means you don't need to care about admin or
; not admin because Windows 9x doesn't either
;MessageBox MB_OK "Error! This DLL can't run under Windows 9x!"
StrCpy $WINPCAP_IS_ADMIN "true"

Done:
;MessageBox MB_OK 'User= "$R1"  AccountType= "$R2"  IsUserAdmin= "$WINPCAP_IS_ADMIN"'

Pop $R2
Pop $R1
FunctionEnd

; Author: Lilla (lilla@earthlink.net) 2003-06-13
; function IsUserAdmin uses plugin \NSIS\PlusgIns\UserInfo.dll
; This function is based upon code in \NSIS\Contrib\UserInfo\UserInfo.nsi
; This function was tested under NSIS 2 beta 4 (latest CVS as of this writing).
;
; Usage:
;   Call un.IsUserAdmin
;        ; $WINPCAP_IS_ADMIN  is "true" or "false"
;
Function un.IsUserAdmin
Push $R1
Push $R2

ClearErrors
UserInfo::GetName
IfErrors Win9x
Pop $R1
UserInfo::GetAccountType
Pop $R2

StrCmp $R2 "Admin" 0 Continue
; Observation: I get here when running Win98SE. (Lilla)
; The functions UserInfo.dll looks for are there on Win98 too,
; but just don't work. So UserInfo.dll, knowing that admin isn't required
; on Win98, returns admin anyway. (per kichik)
; MessageBox MB_OK 'User "$R1" is in the Administrators group'
StrCpy $WINPCAP_IS_ADMIN "true"
Goto Done

Continue:
; You should still check for an empty string because the functions
; UserInfo.dll looks for may not be present on Windows 95. (per kichik)
StrCmp $R2 "" Win9x
StrCpy $WINPCAP_IS_ADMIN "false"
;MessageBox MB_OK 'User "$R1" is in the "$R2" group'
Goto Done

Win9x:
; comment/message below is by UserInfo.nsi author:
; This one means you don't need to care about admin or
; not admin because Windows 9x doesn't either
;MessageBox MB_OK "Error! This DLL can't run under Windows 9x!"
StrCpy $WINPCAP_IS_ADMIN "true"

Done:
;MessageBox MB_OK 'User= "$R1"  AccountType= "$R2"  IsUserAdmin= "$WINPCAP_IS_ADMIN"'

Pop $R2
Pop $R1
FunctionEnd


   






