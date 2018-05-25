unit RSShellBrowse;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 Some routines in this unit require MS Layer for Unicode to run under
  Windows 95/98/Me system. It can be downloaded from
  http://www.microsoft.com/msdownload/platformsdk/sdkupdate/psdkredist.htm

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Windows, Messages, SysUtils, Classes, ActiveX, ComObj, ShlObj, ShellAPI, RSQ,
  Contnrs, CommCtrl, RSSysUtils, Math;

{ TODO :
Возможна ли корзина с другими колонками ?
Bugs with mixed locales ?
}

type
  TRSFileNameType = set of (RSForEditing, RSForAddressBar, RSForParsing);
   // Descriptions for those can be found for IShellFolder::GetDisplayNameOf.
   // I can't explan it better than MSDN. :)

  TRSShellFile = class;
  TRSShellFileClass = class of TRSShellFile;

  TRSShellFilesArray = array of TRSShellFile;

  TRSShellFile = class(TObject)
  protected
    FParent: IShellFolder;
    FIDList: PItemIDList;
    FFullIDList: PItemIDList;
    FImageIndex: array[Boolean, Boolean] of int;
    FImageIndexReady: array[Boolean] of Boolean;
    FNames: array[0..15] of string;
    FKnownAttribs: DWord;
    FAttribs: DWord;
    FWnd: HWnd;

    FShellIcon: IShellIcon;
    FNoShellIcon: Boolean;

    FOverlayIndex: int;
    FShellIconOverlay: IShellIconOverlay;

    FKeepIDList: Boolean;
    FKeepFullIDList: Boolean;

    procedure Initialize; virtual;
    procedure Created; virtual;
    procedure ClearAll;
    procedure DoAssign(Source:TRSShellFile; Full:Boolean); virtual;
    function GetName(NameType:TRSFileNameType; i:Integer):string;
  public
    constructor Create(const Parent:IShellFolder; FullPIDL:PItemIDList;
      PIDL:PItemIDList; Wnd:HWnd = 0); overload;
    constructor Create(const Path:WideString; Wnd:HWnd = 0;
      ParentFolder:IShellFolder = nil; ParentPIDL:PItemIDList = nil); overload;
    constructor Create(SpecialFolderCSIDL:int = CSIDL_DESKTOP; Wnd:HWnd = 0); overload;
    constructor Create(ShellFile: TRSShellFile; FullAssign:Boolean = false); overload; virtual;
    destructor Destroy; override;
    procedure Assign(Source:TRSShellFile; FullAssign:Boolean = false);
    function FullName(NameType:TRSFileNameType = [RSForParsing]):string;
    function ShortName(NameType:TRSFileNameType = []):string;
    function ImageIndex(Open: Boolean = false; Async: Boolean = false): int;
    function ImageIndexReady(Open: Boolean = false): Boolean;
    function OverlayIndex(Async: Boolean): int;
    function OverlayIconIndex(Async: Boolean): int;
    function OverlayPending: Boolean;
    function ContextMenu: IContextMenu;
    function CreateParentFolder(FolderClass: TRSShellFileClass): TRSShellFile;
    function ExecuteDefaultCommand: Boolean;
    function GetSelf: TRSShellFile; // Convinient in 'with' statement
    function GetAttributes(AttribsSFGAO:DWord):DWord;
    function Rename(const Name: WideString;
      NameType: TRSFileNameType = [RSForEditing];
      FullPath: Boolean = false):TRSShellFile;
    function Exists: Boolean;
    function IsFolder: Boolean;
    function IsFileSystem: Boolean;
    function SamePIDL(f: TRSShellFile): Boolean;

    property PIDL: PItemIDList read FIDList;
    property FullPIDL: PItemIDList read FFullIDList;
    property Parent: IShellFolder read FParent;
  end;

  TRSShellFolder = class;
  TRSShellFolderClass = class of TRSShellFolder;

  TRSShellFolderCompareEvent = function(Sender:TObject; Folder:TRSShellFolder;
    f1, f2:TRSShellFile; var Column:int; var Inverse:Boolean):Integer of object;
   // Set Column to -1 to indicate that you compared the files manually

  TRSShellFolderCanAddEvent = procedure(Sender:TObject;
    ShellFile:TRSShellFile; var CanAdd:Boolean) of object;
  TRSShellFolderIconLoadedEvent = procedure(Sender:TObject;
    Folder:TRSShellFolder; Index:Integer) of object;
  TRSShellFolderLoadFileEvent = procedure(Sender:TRSShellFolder;
    SortedCount, EnumeratedCount:int; var Proceed:Boolean) of object;

  TRSShellFolder = class(TRSShellFile)
  private
    FOnCanAdd: TRSShellFolderCanAddEvent;
    FOnCompare: TRSShellFolderCompareEvent;
    FOnIconLoaded: TRSShellFolderIconLoadedEvent;
    FOnLoadFile: TRSShellFolderLoadFileEvent;
    FSortColumn: int;
    FSortInverse: Boolean;
    function GetShellFolder: IShellFolder;
  protected
    FShellFolder: IShellFolder;
    FIconsThread: THandle;
    FSortedFiles: TStringList;
    FIconsThreadStopped: Boolean;
    FIsRecicledBin: int1;

    FThreadOnIconLoaded: TRSShellFolderIconLoadedEvent;
    FThreadOnTextsLoaded: TNotifyEvent;
    FOwnShellIcon: IShellIcon;

    procedure Initialize; override;
    procedure DoAssign(Source:TRSShellFile; Full:Boolean); override;

    function DoEnumFiles(Enum:IEnumIDlist; Stack:TRSObjStack):Boolean;
    procedure DoCanAdd(var ShellFile:TRSShellFile);
    function CreateShellFile(PIDL:PItemIDList): TRSShellFile; virtual;
    function IconThreadProc: int; virtual;

    function DoCompare(f1, f2:TRSShellFile):int; virtual;
    function DoFindFile(ShellFile:TRSShellFile; L:int; Compare:ptr;
      var Index:int; I:int = -1):Boolean;
    procedure QuickSort(L,R:int; Compare:ptr); // Not used
    procedure DoSort; // Not used
    procedure NeedSortedFiles;
    function GiveShellIcon: Boolean; // Gives ShellIcon to children
  public
    Files: TRSShellFilesArray;
    destructor Destroy; override;
    function EnumFiles(Enum:IEnumIDlist; Append:Boolean = false):Boolean; overload; virtual;
    function EnumFiles(FlagsSHCONTF: int = SHCONTF_FOLDERS or
      SHCONTF_NONFOLDERS or SHCONTF_INCLUDEHIDDEN; Append:Boolean = false):Boolean; overload;
    procedure ClearFiles;
    procedure RemoveFile(i:int); // Removes from Files array only

    function FindFile(const Name:string; StartIndex:int;
      Wrap:Boolean = true; AllowPartial:Boolean = true):int;
    function FindShellFile(ShellFile:TRSShellFile):int;
     // not Result ( = -Result-1) if not found

    procedure CreateIconsThread(Priority: int = THREAD_PRIORITY_BELOW_NORMAL);
    procedure StopIconsThread;

    procedure UseDefaultSorting;
    function IsRecicledBin: Boolean;
    procedure FlushCache;
    property ShellFolder: IShellFolder read GetShellFolder;
    property SortColumn: int read FSortColumn write FSortColumn;
    property SortInverse: Boolean read FSortInverse write FSortInverse;
    property OnCanAdd: TRSShellFolderCanAddEvent read FOnCanAdd write FOnCanAdd;
     // If OnCompare handler compares items itself, it should set Column to -1
    property OnCompare: TRSShellFolderCompareEvent read FOnCompare write FOnCompare;
    property OnLoadFile: TRSShellFolderLoadFileEvent read FOnLoadFile write FOnLoadFile;

     // These two run in another thread:
    property OnIconLoaded: TRSShellFolderIconLoadedEvent read FOnIconLoaded write FOnIconLoaded;
  end;

  
function RSOleCheck(AResult: HResult): HResult;

type
  TDllVersionInfo = packed record
    cbSize: DWord;
    dwMajorVersion: DWord;
    dwMinorVersion: DWord;
    dwBuildNumber: DWord;
    dwPlatformID: DWord;
  end;

  TDllVersionInfo2 = packed record
    info1: TDLLVersionInfo;
    dwFlags: dword;
    ullVersion: Int64;
  end;

const
  DLLVER_PLATFORM_WINDOWS = 1;
  DLLVER_PLATFORM_NT = 2;

function RSGetDllVersion(const DllName: string): DWord; overload;
function RSGetDllVersion(const DllName: string; var pdvi: TDllVersionInfo): Boolean; overload;
function RSCheckDllVersion(const DllName: string; Major, Minor: word): Boolean;
  
function RSSHMalloc: IMalloc;
function RSSHDesktopFolder: IShellFolder;

function RSGetFileIconIndex(const FilePath: string; Open: Boolean = false;
   Folder:Boolean = false): int; overload;
 // The version that takes FilePath as parameter can retrieve icons of files
 //  that don't exist as well as of existing ones.
 // You should specify Folder for folders that don't exist or are on FTP.
function RSGetFileIconIndex(PIDL:PItemIDList; Open: Boolean = false): int; overload;
function RSGetFileIconIndex(ShellFolder: IShellFolder;
  PIDL, FullPIDL:PItemIDList; Open: Boolean = false): int; overload;
 // The leter RSGetFileIconIndex is faster on new operating systems

function RSIsSpecialFolder(PIDL:PItemIDList; CSIDL:int):Boolean;
function RSSpecialFolderName(CSIDL:int):string;
function RSSpecialFolderNameW(CSIDL:int):WideString;
function RSIsInternetFile(PIDL:PItemIDList):Boolean;

function RSStrRetToString(var StrRet:TStrRet; PIDL:PItemIDList):string;
function RSStrRetToWideString(var StrRet:TStrRet; PIDL:PItemIDList):WideString;
procedure RSApplySystemImageList(ListView: HWnd; Small: Boolean = true);
function RSGetPIDLCount(IDList:PItemIDList):Integer;
function RSGetPIDLSize(IDList:PItemIDList; IncludeLast:Boolean = true):Integer;
function RSConcatPIDLs(IDList1, IDList2: PItemIDList): PItemIDList;
function RSCopyPIDL(IDList: PItemIDList): PItemIDList;
function RSStripLastPIDL(IDList: PItemIDList): PItemIDList;
function RSExtractRelativePIDL(IDList: PItemIDList): PItemIDList;
function RSGetFirstPIDL(IDList:PItemIDList):PItemIDList;

function RSGetCommandVerb(const CM:IContextMenu; Cmd:int):string;
function RSContextMenuVerb(Owner:HWnd; const CM:IContextMenu; Verb:PChar):Boolean; overload;
function RSContextMenuVerb(Owner:HWnd; const CM:IContextMenu; Cmd:int):Boolean; overload;
function RSOpenContextMenu(Owner:HWnd; const CM:IContextMenu; p:TPoint;
   CanRename:Boolean; const DefaultItem:string = ''; NoSeparator:Boolean = false):int;
  // Returns -1 for default item, 0 for no item, >0 for others


const
  RSOleBoolean: array[Boolean] of int = (S_FALSE, S_OK);

  SHCONTF_INIT_ON_FIRST_NEXT = $80;
  SHCONTF_NETPRINTERSRCH = $100;
  SHCONTF_SHAREABLE = $200;
  SHCONTF_STORAGE = $400;

  CMF_EXTENDEDVERBS = $100;
  OI_ASYNC = int($FFFFEEEE);

{ From ShellAPI }
  {$EXTERNALSYM SHGFI_ICON}
  SHGFI_ICON              = $000000100;     { get icon }
  {$EXTERNALSYM SHGFI_DISPLAYNAME}
  SHGFI_DISPLAYNAME       = $000000200;     { get display name }
  {$EXTERNALSYM SHGFI_TYPENAME}
  SHGFI_TYPENAME          = $000000400;     { get type name }
  {$EXTERNALSYM SHGFI_ATTRIBUTES}
  SHGFI_ATTRIBUTES        = $000000800;     { get attributes }
  {$EXTERNALSYM SHGFI_ICONLOCATION}
  SHGFI_ICONLOCATION      = $000001000;     { get icon location }
  {$EXTERNALSYM SHGFI_EXETYPE}
  SHGFI_EXETYPE           = $000002000;     { return exe type }
  {$EXTERNALSYM SHGFI_SYSICONINDEX}
  SHGFI_SYSICONINDEX      = $000004000;     { get system icon index }
  {$EXTERNALSYM SHGFI_LINKOVERLAY}
  SHGFI_LINKOVERLAY       = $000008000;     { put a link overlay on icon }
  {$EXTERNALSYM SHGFI_SELECTED}
  SHGFI_SELECTED          = $000010000;     { show icon in selected state }
  {$EXTERNALSYM SHGFI_LARGEICON}
  SHGFI_LARGEICON         = $000000000;     { get large icon }
  {$EXTERNALSYM SHGFI_SMALLICON}
  SHGFI_SMALLICON         = $000000001;     { get small icon }
  {$EXTERNALSYM SHGFI_OPENICON}
  SHGFI_OPENICON          = $000000002;     { get open icon }
  {$EXTERNALSYM SHGFI_SHELLICONSIZE}
  SHGFI_SHELLICONSIZE     = $000000004;     { get shell size icon }
  {$EXTERNALSYM SHGFI_PIDL}
  SHGFI_PIDL              = $000000008;     { pszPath is a pidl }
  {$EXTERNALSYM SHGFI_USEFILEATTRIBUTES}
  SHGFI_USEFILEATTRIBUTES = $000000010;     { use passed dwFileAttribute }
{/From ShellAPI }
  SHGFI_ATTR_SPECIFIED    = $000020000;     { get only specified attributes }
  SHGFI_ADDOVERLAYS       = $000000020;     { apply the appropriate overlays }
  SHGFI_OVERLAYINDEX      = $000000040;     { Get the index of the overlay }

{ From ShlObj }
  CSIDL_DESKTOP                       = $0000;
  {$EXTERNALSYM CSIDL_INTERNET}
  CSIDL_INTERNET                      = $0001;
  {$EXTERNALSYM CSIDL_PROGRAMS}
  CSIDL_PROGRAMS                      = $0002;
  {$EXTERNALSYM CSIDL_CONTROLS}
  CSIDL_CONTROLS                      = $0003;
  {$EXTERNALSYM CSIDL_PRINTERS}
  CSIDL_PRINTERS                      = $0004;
  {$EXTERNALSYM CSIDL_PERSONAL}
  CSIDL_PERSONAL                      = $0005;
  {$EXTERNALSYM CSIDL_FAVORITES}
  CSIDL_FAVORITES                     = $0006;
  {$EXTERNALSYM CSIDL_STARTUP}
  CSIDL_STARTUP                       = $0007;
  {$EXTERNALSYM CSIDL_RECENT}
  CSIDL_RECENT                        = $0008;
  {$EXTERNALSYM CSIDL_SENDTO}
  CSIDL_SENDTO                        = $0009;
  {$EXTERNALSYM CSIDL_BITBUCKET}
  CSIDL_BITBUCKET                     = $000a; // Recicled Bin
  {$EXTERNALSYM CSIDL_STARTMENU}
  CSIDL_STARTMENU                     = $000b;
  {$EXTERNALSYM CSIDL_DESKTOPDIRECTORY}
  CSIDL_DESKTOPDIRECTORY              = $0010;
  {$EXTERNALSYM CSIDL_DRIVES}
  CSIDL_DRIVES                        = $0011; // My Computer
  {$EXTERNALSYM CSIDL_NETWORK}
  CSIDL_NETWORK                       = $0012;
  {$EXTERNALSYM CSIDL_NETHOOD}
  CSIDL_NETHOOD                       = $0013;
  {$EXTERNALSYM CSIDL_FONTS}
  CSIDL_FONTS                         = $0014;
  {$EXTERNALSYM CSIDL_TEMPLATES}
  CSIDL_TEMPLATES                     = $0015;
  {$EXTERNALSYM CSIDL_COMMON_STARTMENU}
  CSIDL_COMMON_STARTMENU              = $0016;
  {$EXTERNALSYM CSIDL_COMMON_PROGRAMS}
  CSIDL_COMMON_PROGRAMS               = $0017;
  {$EXTERNALSYM CSIDL_COMMON_STARTUP}
  CSIDL_COMMON_STARTUP                = $0018;
  {$EXTERNALSYM CSIDL_COMMON_DESKTOPDIRECTORY}
  CSIDL_COMMON_DESKTOPDIRECTORY       = $0019;
  {$EXTERNALSYM CSIDL_APPDATA}
  CSIDL_APPDATA                       = $001a;
  {$EXTERNALSYM CSIDL_PRINTHOOD}
  CSIDL_PRINTHOOD                     = $001b;
  {$EXTERNALSYM CSIDL_ALTSTARTUP}
  CSIDL_ALTSTARTUP                = $001d;         // DBCS
  {$EXTERNALSYM CSIDL_COMMON_ALTSTARTUP}
  CSIDL_COMMON_ALTSTARTUP         = $001e;         // DBCS
  {$EXTERNALSYM CSIDL_COMMON_FAVORITES}
  CSIDL_COMMON_FAVORITES          = $001f;
  {$EXTERNALSYM CSIDL_INTERNET_CACHE}
  CSIDL_INTERNET_CACHE            = $0020;
  {$EXTERNALSYM CSIDL_COOKIES}
  CSIDL_COOKIES                   = $0021;
  {$EXTERNALSYM CSIDL_HISTORY}
  CSIDL_HISTORY                   = $0022;
{/From ShlObj }
  CSIDL_FLAG_CREATE = $8000;
  CSIDL_MYDOCUMENTS = $000c; // Don't work for me!
  CSIDL_MYMUSIC = $000d;
  CSIDL_MYVIDEO = $000e;
  CSIDL_LOCAL_APPDATA = $001c;
  CSIDL_COMMON_APPDATA = $0023;
  CSIDL_WINDOWS = $0024;
  CSIDL_SYSTEM = $0025;
  CSIDL_PROGRAM_FILES = $0026;
  CSIDL_MYPICTURES = $0027;
  CSIDL_PROFILE = $0028;
  CSIDL_PROGRAM_FILES_COMMON = $002b;
  CSIDL_COMMON_TEMPLATES = $002d;
  CSIDL_COMMON_DOCUMENTS = $002e;
  CSIDL_COMMON_ADMINTOOLS = $002f;
  CSIDL_COMMON_MUSIC = $0035;
  CSIDL_COMMON_PICTURES = $0036;
  CSIDL_COMMON_VIDEO = $0037;
  CSIDL_CDBURN_AREA = $003b;
  CSIDL_PROFILES = $003e;
//  $29 = C:\WINDOWS\system32
//  $31 = Net Connections (Сетевые подключения)
//  $38 = C:\WINDOWS\Resources
//  $3D = Net WorkGroup

  SVGIO_TYPE_MASK	= $0000000f;
  SVGIO_FLAG_VIEWORDER = $80000000;


{ From ShlIntf and ShlExt modules of DCodeBot package with some changes: }
// There's a lot of useful stuff, but I decided to copy only what I need

const
  CLSID_AutoComplete: TGUID = (
    D1:$00BB2763; D2:$6A77; D3:$11D0; D4:($A5,$35,$00,$C0,$4F,$D7,$D0,$62));
  CLSID_ACLHistory: TGUID = (
    D1:$00BB2764; D2:$6A77; D3:$11D0; D4:($A5,$35,$00,$C0,$4F,$D7,$D0,$62));
  CLSID_ACListISF: TGUID = (
    D1:$03C036F1; D2:$A186; D3:$11D0; D4:($82,$4A,$00,$AA,$00,$5B,$43,$83));
  CLSID_ACLMRU: TGUID = (
    D1:$6756A641; D2:$DE71; D3:$11D0; D4:($83,$1B,$00,$AA,$00,$5B,$43,$83));
  CLSID_ACLMulti: TGUID = (
    D1:$00BB2765; D2:$6A77; D3:$11D0; D4:($A5,$35,$00,$C0,$4F,$D7,$D0,$62));

  SID_IFolderView              = '{CDE725B0-CCC9-4519-917E-325D72FAB4CE}';
  SID_ICommDlgBrowser2         = '{10339516-2894-11D2-9039-00C04F8EEB3E}';
  SID_IAutoComplete            = '{00BB2762-6A77-11D0-A535-00C04FD7D062}';
  SID_IAutoComplete2           = '{EAC04BC0-3791-11D2-BB95-0060977B464C}';
  SID_IACList                  = '{77A130B0-94FD-11D0-A544-00C04FD7d062}';
  SID_IACList2                 = '{470141A0-5186-11D2-BBB6-0060977B464C}';
  SID_ICurrentWorkingDirectory = '{91956D21-9276-11D1-921A-006097DF5BD4}';
  SID_IObjMgr                  = '{00BB2761-6A77-11D0-A535-00C04FD7D062}';
  SID_IShellFolderViewCB = '{2047E320-F2A9-11CE-AE65-08002B2E1262}';

{
	FWF_AUTOARRANGE	= $1;
	FWF_ABBREVIATEDNAMES = $2;
	FWF_SNAPTOGRID = $4;
	FWF_OWNERDATA = $8;
	FWF_BESTFITWINDOW = $10;
	FWF_DESKTOP = $20;
	FWF_SINGLESEL = $40;
	FWF_NOSUBFOLDERS = $80;
	FWF_TRANSPARENT = $100;
	FWF_NOCLIENTEDGE = $200;
	FWF_NOSCROLL = $400;
	FWF_ALIGNLEFT = $800;
	FWF_NOICONS = $1000;
}  
	FWF_SHOWSELALWAYS = $2000;
	FWF_NOVISIBLE = $4000;
{
	FWF_SINGLECLICKACTIVATE = $8000;
}
	FWF_NOWEBVIEW = $10000;
	FWF_HIDEFILENAMES = $20000;
	FWF_CHECKSELECT = $40000;

	FVM_ICON = 1;
	FVM_SMALLICON = 2;
	FVM_LIST = 3;
	FVM_DETAILS = 4;
	FVM_THUMBNAIL = 5;
	FVM_TILE = 6;
	FVM_THUMBSTRIP = 7;

  SVSI_DESELECT = $00000000;
  SVSI_SELECT = $00000001;
  SVSI_EDIT = $00000003;
  SVSI_DESELECTOTHERS = $00000004;
  SVSI_ENSUREVISIBLE = $00000008;
  SVSI_FOCUSED = $00000010;
  SVSI_TRANSLATEPT = $00000020;
  SVSI_SELECTIONMARK = $00000040;
  SVSI_POSITIONITEM = $00000080;
  SVSI_CHECK = $00000100;
  SVSI_NOSTATECHANGE = $80000000;

	CDB2N_CONTEXTMENU_DONE = $00000001;
	CDB2N_CONTEXTMENU_START = $00000002;

  CDB2GVF_SHOWALLFILES = $00000001;

type
	IFolderView = interface(IUnknown)
  	[SID_IFolderView]
		function GetCurrentViewMode(out ViewMode: UINT): HResult; stdcall;
		function SetCurrentViewMode(ViewMode: UINT): HResult; stdcall;
		function GetFolder(riid: TIID; out ppv): HResult; stdcall;
		function Item(iItemIndex: Integer; out ppidl: PItemIDList): HResult; stdcall;
		function ItemCount(uFlags: UINT; out pcItems: Integer): HResult; stdcall;
		function Items(uFlags: UINT; const riid: TIID; out ppv): HResult; stdcall;
		function GetSelectionMarkedItem(out ppidl: PItemIDList): HResult; stdcall;
		function GetFocusedItem(out piItem: Integer): HResult; stdcall;
		function GetItemPosition(pidl: PItemIDList; out ppt: TPoint): HResult; stdcall;
		function GetSpacing(out ppt: TPoint): HResult; stdcall;
		function GetDefaultSpacing(out ppt: TPoint): HResult; stdcall;
		function GetAutoArrange: HResult; stdcall;
		function SelectItem(iItem: Integer; dwFlags: DWORD): HResult; stdcall;
		function SelectAndPositionItems(cidl: UINT; pidl: PItemIDList;
    	const apt: TPoint; dwFlags: DWORD): HResult; stdcall;
  end;

  ICommDlgBrowser2 = interface(ICommDlgBrowser)
		[SID_ICommDlgBrowser2]
    function Notify(ppshv: IShellView; dwNotifyType: DWORD): HResult; stdcall;
    function GetDefaultMenuText(ppshv: IShellView; pszText: PWideChar;
    	cchMax: Integer): HResult; stdcall;
    function GetViewFlags(out pdwFlags: DWORD): HResult; stdcall;
	end;

  IAutoComplete = interface(IUnknown)
    [SID_IAutoComplete]
    function Init(hwndEdit: HWND; punkACL: IUnknown; pwszRegKeyPath: PWideChar;
      pwszQuickComplete: PWideChar): HResult; stdcall;
    function Enable(fEnable: Boolean): HResult; stdcall;
  end;

const
 //                        uMsg       wParam             lParam
  SFVM_MERGEMENU           =  1;    // uFlags             LPQCMINFO
  SFVM_INVOKECOMMAND       =  2;    // idCmd              -
  SFVM_GETHELPTEXT         =  3;    // idCmd,cchMax       pszText
  SFVM_GETTOOLTIPTEXT      =  4;    // idCmd,cchMax       pszText
  SFVM_GETBUTTONINFO       =  5;    // -                  LPTBINFO
  SFVM_GETBUTTONS          =  6;    // idCmdFirst,cbtnMax LPTBBUTTON
  SFVM_INITMENUPOPUP       =  7;    // idCmdFirst,nIndex  hmenu
  SFVM_GETSELECTEDOBJECTS  =  9;    // DWORD              LPTBBUTTON
  SFVM_FSNOTIFY            = 14;    // LPITEMIDLIST       DWrd - SHCNE_ value
  SFVM_WINDOWCREATED       = 15;    // hwnd               PDVSELCHANGEINFO
  SFVM_GETDETAILSOF        = 23;    // iColumn            DETAILSINFO*
  SFVM_COLUMNCLICK         = 24;    // iColumn            -
  SFVM_QUERYFSNOTIFY       = 25;    // -                  SHChangeNotifyEntry *
  SFVM_DEFITEMCOUNT        = 26;    // -                  UINT* number of items in the folder view
  SFVM_DEFVIEWMODE         = 27;    // -                  FOLDERVIEWMODE*
  SFVM_UNMERGEMENU         = 28;    // -                  hmenu
  SFVM_UPDATESTATUSBAR     = 31;    // fInitialize        -
  SFVM_BACKGROUNDENUM      = 32;    // -                  -
  SFVM_DIDDRAGDROP         = 36;    // dwEffect           IDataObject *
  SFVM_SETISFV             = 39;    // -                  IShellFolderView*
  SFVM_THISIDLIST          = 41;    // -                  LPITMIDLIST*
  SFVM_ADDPROPERTYPAGES    = 47;    // -                  SFVM_PROPPAGE_DATA *
  SFVM_BACKGROUNDENUMDONE  = 48;    // -                  -
  SFVM_GETNOTIFY           = 49;    // LPITEMIDLIST*      LONG*
  SFVM_GETSORTDEFAULTS     = 53;    // iDirection         iParamSort
  SFVM_SIZE                = 57;    // -                  -
  SFVM_GETZONE             = 58;    // -                  DWORD*
  SFVM_GETPANE             = 59;    // Pane ID            DWORD*
  SFVM_GETHELPTOPIC        = 63;    // -                  SFVM_HELPTOPIC_DATA *
  SFVM_GETANIMATION        = 68;    // HInstance          widechar
  
type  
  IShellFolderViewCB = interface
    [SID_IShellFolderViewCB]
    function MessageSFVCB(uMsg : UINT; wParam : WPARAM; lParam : LPARAM) : HResult; stdcall;
  end;
   
const
  ACO_NONE               = $0000;
  ACO_AUTOSUGGEST        = $0001;
  ACO_AUTOAPPEND         = $0002;
  ACO_SEARCH             = $0004;
  ACO_FILTERPREFIXES     = $0008;
  ACO_USETAB             = $0010;
  ACO_UPDOWNKEYDROPSLIST = $0020;
  ACO_RTLREADING         = $0040;

type
  IAutoComplete2 = interface(IAutoComplete)
    [SID_IAutoComplete2]
    function SetOptions(dwFlag: DWORD): HResult; stdcall;
    function GetOptions(out dwFlag: DWORD): HResult; stdcall;
  end;

  IACList = interface(IUnknown)
    [SID_IACList]
    function Expand(pszExpand: PWideChar): HResult; stdcall;
  end;

const
  ACLO_NONE            = 0;    // don't enumerate anything
  ACLO_CURRENTDIR      = 1;    // enumerate current directory
  ACLO_MYCOMPUTER      = 2;    // enumerate MyComputer
  ACLO_DESKTOP         = 4;    // enumerate Desktop Folder
  ACLO_FAVORITES       = 8;    // enumerate Favorites Folder
  ACLO_FILESYSONLY     = 16;   // enumerate only the file system

type
  IACList2 = interface(IACList)
    [SID_IACList2]
    function SetOptions(dwFlag: DWORD): HResult; stdcall;
    function GetOptions(out pdwFlag: DWORD): HResult; stdcall;
  end;

  ICurrentWorkingDirectory = interface(IUnknown)
    [SID_ICurrentWorkingDirectory]
    function GetDirectory(pwzPath: PWideChar; cchSize: DWORD): HResult; stdcall;
    function SetDirectory(pwzPath: PWideChar): HResult; stdcall;
  end;

  IObjMgr = interface(IUnknown)
    [SID_IObjMgr]
    function Append(punk: IUnknown): HResult; stdcall;
    function Remove(punk: IUnknown): HResult; stdcall;
  end;

  TCSFV = record
    cbSize: DWORD;
    pshf: IShellFolder;
    psvOuter: IShellView;
    pidl: PITEMIDLIST;
    IEvents: DWORD;
    pfnCallback: Pointer;
      // function (psvUser: integer; psf: IShellFolder; hwndMain: HWND;
      //   uMsg: uint; WParam: WParam; lParam: LParam): HResult; stdcall;
    fvm: int;
  end;
  PCSFV = ^TCSFV;

function SHCreateShellFolderViewEx(const csfv: TCSFV; out ppsv: IShellView):HResult; stdcall; external shell32;

const
  SHCIDS_ALLFIELDS = $80000000;
  SHCIDS_CANONICALONLY = $10000000;

{/From ShlIntf module of DCodeBot package }

implementation

var
  Malloc: IMalloc;

function RSSHMalloc: IMalloc;
begin
  if Malloc = nil then
//    RSOleCheck(SHGetMalloc(Malloc)); // New MSDN tells us not to use it
    RSOleCheck(CoGetMalloc(1, Malloc));
  Result:= Malloc;
end;

function RSSHDesktopFolder: IShellFolder;
begin
  RSOleCheck(SHGetDeskTopFolder(Result));
end;


var
  SHMapPIDLToSystemImageListIndex: function (pshf : IShellFolder; pidl : PItemIdList; var piIndexSel : integer) : integer; stdcall;

{
function RSGetFileIconIndexVirtual(FilePath: string; Open: Boolean;
  Directory:Boolean): int;
begin

end;
}

  // !!! Requires MS Layer for Unicode
function DoGetFileIconIndex(FilePath:PChar; Flags: int; Open: Boolean;
   Attrib:int = 0): int;
var
  FileInfo: TSHFileInfo;
begin
  Flags:= Flags or SHGFI_SYSICONINDEX;
  if Open then
    Flags:= Flags or SHGFI_OPENICON;

  if SHGetFileInfo(FilePath, Attrib, FileInfo, SizeOf(FileInfo), Flags)<>0 then
    Result:= FileInfo.iIcon
  else
    Result:= -1;
end;

function RSGetFileIconIndex(const FilePath: string; Open: Boolean = false; Folder:Boolean = false): int; overload;
begin
  if Folder then
    Result:= DoGetFileIconIndex(ptr(FilePath), SHGFI_USEFILEATTRIBUTES, Open,
      FILE_ATTRIBUTE_DIRECTORY)
  else
    Result:= DoGetFileIconIndex(ptr(FilePath), SHGFI_USEFILEATTRIBUTES, Open,
      FILE_ATTRIBUTE_NORMAL);
end;

function RSGetFileIconIndex(PIDL:PItemIDList; Open: Boolean = false): int; overload;
begin
  Result:=DoGetFileIconIndex(ptr(PIDL), SHGFI_PIDL, Open);
end;

function RSGetFileIconIndex(ShellFolder: IShellFolder; PIDL, FullPIDL:PItemIDList; Open: Boolean = false): int;
begin
  if (@SHMapPIDLToSystemImageListIndex = nil) and RSCheckDllVersion(shell32, 5, 0) then
    @SHMapPIDLToSystemImageListIndex:= GetProcAddress(GetModuleHandle(shell32), 'SHMapPIDLToSystemImageListIndex');
    
  if @SHMapPIDLToSystemImageListIndex <> nil then
  begin
    if Open then
      SHMapPIDLToSystemImageListIndex(ShellFolder, PIDL, Result)
    else
      Result:= SHMapPIDLToSystemImageListIndex(ShellFolder, PIDL, pint(nil)^);

    if Result = 0 then  Result:=-1;
  end else
    Result:= DoGetFileIconIndex(ptr(FullPIDL), SHGFI_PIDL, false);
end;

{
  // Doesn't work
function DoGetFileOverlayIndex(FilePath:PChar; Flags:int; Attrib:int = 0): int;
var
  FileInfo: TSHFileInfo;
begin
  Flags:= Flags or SHGFI_OVERLAYINDEX;

  FileInfo.iIcon:=0;
  if RSCheckDllVersion(shell32, 5, 0) and
     (SHGetFileInfo(FilePath,Attrib,FileInfo,SizeOf(FileInfo),Flags)<>0) then
    Result:= FileInfo.iIcon shr 24
  else
    Result:= 0;
end;

function RSGetFileOverlayIndex(const FilePath: string): int; overload;
begin
  Result:= DoGetFileOverlayIndex(ptr(FilePath), SHGFI_USEFILEATTRIBUTES, FILE_ATTRIBUTE_NORMAL);
end;

function RSGetFileOverlayIndex(PIDL: PItemIDList): int; overload;
begin
  Result:= DoGetFileOverlayIndex(ptr(PIDL), SHGFI_PIDL);
end;
}


var
  SpecialPIDL: array[0..255] of PItemIDList;

function RSIsSpecialFolder(PIDL:PItemIDList; CSIDL:int):Boolean;
var p:PItemIDList;
begin
  if (CSIDL<=255) and (SpecialPIDL[CSIDL] <> nil) then
    p:= SpecialPIDL[CSIDL]
  else
    if SHGetSpecialFolderLocation(0, CSIDL, p)<>S_OK then
    begin
      Result:= false;
      exit;
    end else
      if CSIDL<=255 then
        SpecialPIDL[CSIDL]:= p;

  Result:= RSSHDesktopFolder.CompareIDs(SHCIDS_CANONICALONLY,
              p, PIDL) and $8000FFFF = 0;

  if CSIDL>=255 then
    RSSHMalloc.Free(p);
end;

function RSSpecialFolderName(CSIDL:int):string;
var p:PItemIDList; StrRet:TStrRet;
begin
  if (CSIDL<=255) and (SpecialPIDL[CSIDL] <> nil) then
    p:= SpecialPIDL[CSIDL]
  else
    if (SHGetSpecialFolderLocation(0, CSIDL, p) <> S_OK)  then
      exit
    else
      if CSIDL<=255 then
        SpecialPIDL[CSIDL]:= p;

  if RSSHDesktopFolder.GetDisplayNameOf(p, SHGDN_NORMAL, StrRet) = S_OK then
    Result:= RSStrRetToString(StrRet, p);

  if CSIDL>=255 then
    RSSHMalloc.Free(p);
end;

function RSSpecialFolderNameW(CSIDL:int):WideString;
var p:PItemIDList; StrRet:TStrRet;
begin
  if (CSIDL<=255) and (SpecialPIDL[CSIDL] <> nil) then
    p:= SpecialPIDL[CSIDL]
  else
    if (SHGetSpecialFolderLocation(0, CSIDL, p) <> S_OK)  then
      exit
    else
      if CSIDL<=255 then
        SpecialPIDL[CSIDL]:= p;

  if RSSHDesktopFolder.GetDisplayNameOf(p, SHGDN_NORMAL, StrRet) = S_OK then
    Result:= RSStrRetToWideString(StrRet, p);

  if CSIDL>=255 then
    RSSHMalloc.Free(p);
end;

function RSIsInternetFile(PIDL:PItemIDList):Boolean;
var p:PItemIDList;
begin
  p:= RSGetFirstPIDL(PIDL);
  try
    Result:= RSIsSpecialFolder(p, CSIDL_INTERNET);
  finally
    Malloc.Free(p); // RSGetFirstPIDL ensures Malloc is valid
  end;
end;

function RSStrRetToString(var StrRet:TStrRet; PIDL:PItemIDList):string;
begin
  case StrRet.uType of
    STRRET_CSTR:
      Result:= StrRet.cStr;
    STRRET_OFFSET:
      Result:= PChar(PIDL) + StrRet.uOffset;
    STRRET_WSTR:
    begin
      Result:= StrRet.pOleStr;
      RSSHMalloc.Free(StrRet.pOleStr);
      ptr(StrRet.pOleStr):=nil;
    end;
  end;
end;

function RSStrRetToWideString(var StrRet:TStrRet; PIDL:PItemIDList):WideString;
begin
  case StrRet.uType of
    STRRET_CSTR:
      Result:= StrRet.cStr;
    STRRET_OFFSET:
      Result:= PChar(PIDL) + StrRet.uOffset;
    STRRET_WSTR:
    begin
      Result:= StrRet.pOleStr;
      RSSHMalloc.Free(StrRet.pOleStr);
      ptr(StrRet.pOleStr):=nil;
    end;
  end;
end;

procedure RSApplySystemImageList(ListView: HWnd; Small: Boolean = true);
const
  Flags: array[Boolean] of int = (SHGFI_SYSICONINDEX,
                               SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
var
  h:THandle;
  FileInfo: TSHFileInfo;
begin
  h:= SHGetFileInfo('C:\', 0, FileInfo, SizeOf(FileInfo), Flags[Small]);
  RSWin32Check(h);
  SendMessage(ListView, LVM_SETIMAGELIST, BoolToInt[Small], h);
end;

function NextPIDL(IDList: PItemIDList): PItemIDList;
begin
  Result := IDList;
  Inc(PChar(Result), IDList^.mkid.cb);
end;

function RSGetPIDLCount(IDList:PItemIDList):Integer;
begin
  Result:=0;
  while IDList.mkid.cb <> 0 do
  begin
    inc(Result);
    IDList:=NextPIDL(IDList);
  end;
end;

function RSGetPIDLSize(IDList:PItemIDList; IncludeLast:Boolean = true):Integer;
var i:int;
begin
  Result:=0;
  if Assigned(IDList) then
  begin
    Result:=SizeOf(IDList^.mkid.cb);
    i:=0;
    while IDList^.mkid.cb <> 0 do
    begin
      inc(Result, i);
      i:=IDList^.mkid.cb;
      IDList:=NextPIDL(IDList);
    end;
    if IncludeLast then
      inc(Result, i)
    else
      if (Result = SizeOf(IDList^.mkid.cb)) and (i = 0) then
        Result:=0;
  end;
end;

function RSConcatPIDLs(IDList1, IDList2: PItemIDList): PItemIDList;
var
  cb1, cb2: Integer;
begin
  if IDList1 <> nil then
    cb1:= RSGetPIDLSize(IDList1) - SizeOf(IDList1^.mkid.cb)
  else
    cb1:= 0;

  cb2:= RSGetPIDLSize(IDList2);

  Result:= RSSHMalloc.Alloc(cb1 + cb2);
  if Result = nil then
    exit;
  if IDList1<>nil then
    CopyMemory(Result, IDList1, cb1);
  CopyMemory(PChar(Result) + cb1, IDList2, cb2);
end;

function RSCopyPIDL(IDList: PItemIDList): PItemIDList;
var i:int;
begin
  i:= RSGetPIDLSize(IDList);
  Result:= RSSHMalloc.Alloc(i);
  CopyMemory(Result, IDList, i);
end;

function RSStripLastPIDL(IDList: PItemIDList): PItemIDList;
var i:int;
begin
  i:= RSGetPIDLSize(IDList, false);
  if i <> 0 then
  begin
    Result:= RSSHMalloc.Alloc(i);
    CopyMemory(Result, IDList, i);
    PWord(PChar(Result) + i - 2)^:=0;
  end else
    Result:=nil;
end;

function RSExtractRelativePIDL(IDList:PItemIDList):PItemIDList;
begin
  Result:= nil;
  if IDList <> nil then
  begin
    while IDList^.mkid.cb <> 0 do
    begin
      Result:= IDList;
      IDList:= NextPIDL(IDList);
    end;
    Result:= RSCopyPIDL(Result);
  end;
end;

function RSGetFirstPIDL(IDList:PItemIDList):PItemIDList;
var i:int;
begin
  i:= int(NextPIDL(IDList)) - int(IdList);
  Result:= RSSHMalloc.Alloc(i + SizeOf(IDList^.mkid.cb));
  CopyMemory(Result, IDList, i);
  PItemIDList(PChar(Result)+i).mkid.cb:=0;
end;

procedure RaiseOleError(ErrorCode: HResult; Offset: ptr);
begin
  raise EOleSysError.Create('', ErrorCode, 0) at Offset;
end;

function RSOleCheck(AResult: HResult): HResult;
asm
  test eax, $80000000
  jz @Exit
  cmp eax, $800704C7 // User Abort
  jz @Exit
  mov edx, [esp]
  sub edx, 5
  jmp RaiseOleError
@Exit:
end;

function RSGetDllVersion(const DllName: string): DWord; overload;
var
  Version: TDllVersionInfo;
begin
  Version.cbSize:= SizeOf(Version);
  if RSGetDllVersion(DllName, Version) then
    Result:= Version.dwMajorVersion shl 16 or Version.dwMinorVersion
  else
    Result:= 0;
end;

function RSGetDllVersion(const DllName: string; var pdvi: TDllVersionInfo): Boolean; overload;
var
  DllGetVersion: function(var pdvi: TDllVersionInfo):HResult; stdcall;
  h: HInst;
begin
  h:= RSLoadProc(@DllGetVersion, DllName, 'DllGetVersion', true);
  Result:= (h<>0) and (DllGetVersion(pdvi) = 0);
  if h<>0 then  FreeLibrary(h);
end;

function RSCheckDllVersion(const DllName: string; Major, Minor: word): Boolean;
begin
  Result:= (Major shl 16 or Minor) <= RSGetDllVersion(DllName);
end;



type
  TMyContextMenuHook = class
  private
    FHandle: HWnd;
    DefProc: ptr;
    MyProc: ptr;
    procedure SetHandle(const Value: HWnd);
    procedure WndProc(var m: TMessage);
  public
    CM2: IContextMenu2;
    destructor Destroy; override;
    property Handle: HWnd read FHandle write SetHandle;
  end;

destructor TMyContextMenuHook.Destroy;
begin
  if DefProc<>nil then
    SetWindowLong(Handle, GWL_WNDPROC, int(DefProc));
  FreeObjectInstance(MyProc);
end;

procedure TMyContextMenuHook.SetHandle(const Value: HWnd);
begin
  FHandle:= Value;
  MyProc:= MakeObjectInstance(WndProc);
  DefProc:= ptr(SetWindowLong(Value, GWL_WNDPROC, int(MyProc)));
end;

procedure TMyContextMenuHook.WndProc(var m: TMessage);
begin
  case m.Msg of
    WM_INITMENUPOPUP, WM_DRAWITEM, WM_MENUCHAR, WM_MEASUREITEM:
    begin
      CM2.HandleMenuMsg(m.Msg, m.wParam, m.lParam);
      m.Result:=0;
    end;

    else
      m.Result:= CallWindowProc(DefProc, Handle, m.Msg, m.wParam, m.lParam);
  end;
end;


function RSGetCommandVerb(const CM:IContextMenu; Cmd:int):string;
var Verb: array[0..255] of char;
begin
  if CM.GetCommandString(Cmd, GCS_VERBA, nil, Verb, SizeOf(Verb)) = S_OK then
    Result:= Verb;
end;

function RSContextMenuVerb(Owner:HWnd; const CM:IContextMenu; Verb:PChar):Boolean;
var ICI:TCMInvokeCommandInfo;
begin
  Result:= false;
  if CM=nil then  exit;
  FillChar(ICI, SizeOf(ICI), #0);
  with ICI do
  begin
    cbSize:= SizeOf(ICI);
    hWND:= Owner;
    lpVerb:= Verb;
    nShow:= SW_SHOWNORMAL;
  end;
  Result:= CM.InvokeCommand(ICI) = S_OK;
end;

function RSContextMenuVerb(Owner:HWnd; const CM:IContextMenu; Cmd:int):Boolean;
begin
  Result:= RSContextMenuVerb(Owner, CM, MakeIntResource(Cmd));
end;

procedure AddDefaultItem(Menu:HMenu; const Name:string);
var it:TMenuItemInfo;
begin
  with it do
  begin
    cbSize:=SizeOf(it);
    fMask:=MIIM_ID or MIIM_TYPE or MIIM_STATE;
    fType:=MFT_STRING;
    dwTypeData:=ptr(Name);
    wID:=$ffff;
    fState:=MFS_DEFAULT;
  end;
  RSWin32Check(InsertMenuItem(Menu, 0, true, it));
end;

function RSOpenContextMenu(Owner:HWnd; const CM:IContextMenu; p:TPoint;
   CanRename:Boolean; const DefaultItem:string = ''; NoSeparator:Boolean = false):int;
var
  Menu: HMenu;
  CMHook: TMyContextMenuHook;
  CM2: IContextMenu2;
  Flags:int;
begin
  Result:= 0;
  if CM=nil then  exit;
  Menu := CreatePopupMenu;
  try
    if DefaultItem<>'' then
      AddDefaultItem(Menu, DefaultItem);
    Flags:= 0; //CMF_EXPLORE;
      // Some home-made menus aren't drown correctly without CMF_EXPLORE flag,
      // but CMF_EXPLORE rearranges the items of folders' menu
    if CanRename then
      Flags:= Flags or CMF_CANRENAME;
    if DefaultItem<>'' then
      Flags:= Flags or CMF_NODEFAULT;
    if GetKeyState(VK_SHIFT) < 0 then
      Flags:= Flags or CMF_EXTENDEDVERBS;
    if not Succeeded(RSOleCheck(CM.QueryContextMenu(Menu,
             BoolToInt[DefaultItem<>''], 1, $7FFF, Flags))) then  exit;
    if (DefaultItem<>'') and NoSeparator and
       (GetMenuState(Menu, 1, MF_BYPOSITION) and MF_SEPARATOR	<> 0) then
      DeleteMenu(Menu, 1, MF_BYPOSITION);
    CM.QueryInterface(IID_IContextMenu2, CM2); // For OwnerDraw
    CMHook:= nil;
    if CM2<>nil then
    begin
      CMHook:= TMyContextMenuHook.Create;
      CMHook.CM2:= CM2;
      CM2:= nil;
      CMHook.Handle:= Owner;
    end;

    try
      Result:= int2(TrackPopupMenu(Menu, TPM_LEFTALIGN or TPM_LEFTBUTTON or
                     TPM_RIGHTBUTTON or TPM_RETURNCMD, P.X, P.Y, 0, Owner, nil));
    finally
      CMHook.Free;
    end;
  finally
    DestroyMenu(Menu);
  end;
end;

{ TRSShellFile }

constructor TRSShellFile.Create(const Parent:IShellFolder;
   FullPIDL:PItemIDList; PIDL:PItemIDList; Wnd:HWnd = 0);
begin
  FIDList:= PIDL;
  FFullIDList:= FullPIDL;
  FWnd:= Wnd;
  FParent:= Parent;
  FillChar(FImageIndex, 4*4, -1);
  FOverlayIndex:=-1;
  RSSHMalloc;
  if PIDL = nil then
  begin
    PIDL:= RSStripLastPIDL(FullPIDL);
    if (PIDL = nil) or (PIDL.mkid.cb = 0) then
    begin
      FParent:= RSSHDesktopFolder;
      FIDList:= FFullIDList;
      FKeepIDList:= true;
    end else
      try
//        if DesktopFolder.BindToObject(PIDL, nil, IID_IShellFolder, FParent)
//             <> S_OK then  Abort;
        if RSOleCheck(RSSHDesktopFolder.BindToObject
                  (PIDL, nil, IID_IShellFolder, FParent)) <> S_OK then  Abort;

        FIDList:= RSExtractRelativePIDL(FFullIDList);
      finally
        Malloc.Free(PIDL);
      end;
  end;
  Initialize;
  Created;
end;

function BetterError(var Error:uint; NewError:uint):uint;
begin
  Result:= NewError;
  if NewError = S_OK then
    Error:= NewError
  else
    case NewError of
      $80070057, $80070002, $80004001:;
        // Invalid argument, Path not found, Not supported
      else
        case Error of
          $80070057, $80070002:
            Error:= NewError;
        end;
    end;
end;

constructor TRSShellFile.Create(const Path:WideString; Wnd:HWnd = 0;
   ParentFolder:IShellFolder = nil; ParentPIDL:PItemIDList = nil);
const
  SpecialFolders: array[0..6] of Byte = (0, 3, 4, 5, $A, $11, $12);
var
  Flags: uint;
  pidl: PItemIDList;
  i, j: uint;
begin
  RSSHMalloc;
  Flags:=SFGAO_FOLDER;

  j:= RSSHDesktopFolder.ParseDisplayName(Wnd, nil, PWideChar(Path),
         puint(nil)^, pidl, Flags);
  if j <> S_OK then
  begin
    if (length(Path) = 2) and (Path[2] = ':') then
    begin
      BetterError(j, RSSHDesktopFolder.ParseDisplayName(Wnd, nil,
                       PWideChar(Path + '\'), puint(nil)^, pidl, Flags));
    end else
      if ParentFolder <> nil then
      begin
        if BetterError(j, ParentFolder.ParseDisplayName(Wnd, nil,
              PWideChar(Path), puint(nil)^, pidl, Flags)) = S_OK then
          FParent:= ParentFolder;
      end;

    if (j <> S_OK) and (Path <> '') then
      for i:=0 to high(SpecialFolders) do
        if Path = RSSpecialFolderNameW(SpecialFolders[i]) then
        begin
          BetterError(j, SHGetSpecialFolderLocation(0,SpecialFolders[i],pidl));
          break;
        end;

    if RSOleCheck(j) <> S_OK then  Abort;
  end;

  if FParent<>nil then
  begin
    FIDList:= pidl;
    FFullIDList:= RSConcatPIDLs(ParentPIDL, pidl);
    Create(FParent, FFullIDList, pidl, Wnd);
  end else
    Create(FParent, pidl, nil, Wnd);
    
  FKnownAttribs:= SFGAO_FOLDER or Flags;
  FAttribs:= Flags;
end;

constructor TRSShellFile.Create(SpecialFolderCSIDL:int = CSIDL_DESKTOP; Wnd:HWnd = 0);
var pidl:PItemIDList;
begin
  RSSHMalloc;
  if RSOleCheck(SHGetSpecialFolderLocation(Wnd, SpecialFolderCSIDL, pidl))
                                                           <> S_OK then  Abort;

  Create(nil, pidl, nil, Wnd);
  FKnownAttribs:= SFGAO_FOLDER;
  FAttribs:= SFGAO_FOLDER;
end;

constructor TRSShellFile.Create(ShellFile: TRSShellFile; FullAssign:Boolean = false);
begin
  Initialize;
  Assign(ShellFile);
  Created;
end;

procedure TRSShellFile.Initialize;
begin
end;

procedure TRSShellFile.Created;
begin
end;

destructor TRSShellFile.Destroy;
begin
  ClearAll;
  inherited;
end;

procedure TRSShellFile.ClearAll;
begin
  if not FKeepFullIDList then
    Malloc.Free(FFullIDList);
  FFullIDList:=nil;

  if not FKeepIDList then
    Malloc.Free(FIDList);
  FIDList:=nil;
end;

procedure TRSShellFile.DoAssign(Source: TRSShellFile; Full:Boolean);
var i:int;
begin
  ClearAll;
  FIDList:= RSCopyPIDL(Source.FIDList);
  FFullIDList:= RSCopyPIDL(Source.FFullIDList);
  FKeepIDList:= false;
  FKeepFullIDList:= false;
  FParent:= Source.FParent;
  FKnownAttribs:= Source.FKnownAttribs;
  FAttribs:= Source.FAttribs;
  FWnd:= Source.FWnd;
  FImageIndex[false]:= Source.FImageIndex[false];
  FImageIndex[true]:= Source.FImageIndex[true];
  for i:=0 to high(FNames) do
    FNames[i]:= Source.FNames[i];
  FShellIcon:= Source.FShellIcon;
  FNoShellIcon:= Source.FNoShellIcon;
  FOverlayIndex:= Source.FOverlayIndex;
  FShellIconOverlay:= Source.FShellIconOverlay;
end;

procedure TRSShellFile.Assign(Source: TRSShellFile; FullAssign:Boolean = false);
begin
  if Source <> self then
    DoAssign(Source, FullAssign);
end;

function TRSShellFile.GetName(NameType:TRSFileNameType; i:Integer):string;
var
  j,k:int; StrRet:TStrRet;
begin
  if Self = nil then
  begin
    zD;
    exit;
  end;
  j:=byte(NameType)*2 + i;
  Result:= FNames[j];
  if Result<>'' then  exit;

  Result:= FNames[j];
  if Result = '' then
  begin
    k:=byte(NameType);
    k:=(k and not 1)*SHGDN_FOREDITING*2 or (k and 1)*SHGDN_FOREDITING or i;
    //RSOleCheck(FParent.GetDisplayNameOf(FIDList, k, StrRet));
    if FParent.GetDisplayNameOf(FIDList, k, StrRet) = S_OK then
    begin
      Result:= RSStrRetToString(StrRet, FIDList);
      if FNames[j] = '' then
        FNames[j]:=Result;
    end;
  end;
end;

function TRSShellFile.FullName(NameType: TRSFileNameType = [RSForParsing]): string;
begin
  Result:= GetName(NameType, 0);
end;

function TRSShellFile.ShortName(NameType: TRSFileNameType = []): string;
begin
  Result:= GetName(NameType, 1);
end;

function TRSShellFile.ImageIndex(Open: Boolean = false; Async: Boolean = false):int;
var Flags:int;
begin
  if (FImageIndex[Open, Async] = -1) and (FImageIndex[Open, Async] = -1) then
  begin
    if not FNoShellIcon and (FShellIcon = nil) then
      FNoShellIcon:=
        not Succeeded(Parent.QueryInterface(IID_IShellIcon, FShellIcon));

    Flags:= GIL_FORSHELL;
    if Open then  Flags:= Flags or GIL_OPENICON;
    if Async then  Flags:= Flags or GIL_ASYNC;

    if FShellIcon <> nil then
      case FShellIcon.GetIconOf(FIDList, Flags, FImageIndex[Open, Async]) of
        S_OK:  FImageIndex[Open, false]:= FImageIndex[Open, Async];
        E_PENDING:;
        else  FImageIndex[Open, Async]:=-1;
      end;

    if (FImageIndex[Open, Async] = -1) and (FImageIndex[Open, false] = -1) then
      FImageIndex[Open, false]:=
        RSGetFileIconIndex(FParent, FIDList, FFullIDList, Open);
  end;

  Result:= FImageIndex[Open, false];
  if Result = -1 then
    Result:= FImageIndex[Open, Async];
end;

function TRSShellFile.ImageIndexReady(Open: Boolean = false):Boolean;
begin
  Result:= FImageIndex[Open, false] <> -1;
end;

function TRSShellFile.OverlayIndex(Async: Boolean): int;
begin
  if (FOverlayIndex = -1) or (FOverlayIndex < -1) and not Async then
  begin
    if FShellIconOverlay = nil then
      Parent.QueryInterface(IShellIconOverlay, FShellIconOverlay);

    if FShellIconOverlay <> nil then
    begin
      FOverlayIndex:= BoolToInt[Async]*OI_ASYNC;
      case FShellIconOverlay.GetOverlayIndex(FIDList, FOverlayIndex) of
        S_OK, E_PENDING:;
        else  FOverlayIndex:= 0;
      end;
    end else
{
      if RSCheckDllVersion(shell32, 5, 0) then
        if Async then
          FOverlayIndex:= OI_ASYNC
        else
          FOverlayIndex:= RSGetFileOverlayIndex(FFullIDList)
      else
}      
        FOverlayIndex:= 0
  end;

  if FOverlayIndex >= 0 then
    Result:= FOverlayIndex
  else
    Result:= 0;
end;

function TRSShellFile.OverlayIconIndex(Async: Boolean): int;
begin
  Result:= OverlayIndex(Async) shl 8;
end;

function TRSShellFile.OverlayPending: Boolean;
begin
  OverlayIndex(true);
  Result:= FOverlayIndex = OI_ASYNC;
end;

function TRSShellFile.IsFolder: Boolean;
begin
  Result:= GetAttributes(SFGAO_FOLDER)<>0;
end;

function TRSShellFile.IsFileSystem: Boolean;
begin
  Result:= GetAttributes(SFGAO_FILESYSTEM)<>0;
end;

function TRSShellFile.SamePIDL(f: TRSShellFile): Boolean;
begin
  Result:= (f<>nil) and (RSSHDesktopFolder.CompareIDs(SHCIDS_CANONICALONLY,
                            FFullIDList, f.FFullIDList) and $8000FFFF = 0);
end;

function TRSShellFile.ContextMenu: IContextMenu;
begin
  Parent.GetUIObjectOf(FWnd, 1, FIDList, IID_IContextMenu, nil, Result);
end;

function TRSShellFile.CreateParentFolder(FolderClass: TRSShellFileClass): TRSShellFile;
var p:PItemIDList;
begin
  p:=RSStripLastPIDL(FFullIDList);
  if p <> nil then
  begin
    Result:= FolderClass.Create(nil, p, nil, FWnd);
    Result.FKnownAttribs:= SFGAO_FOLDER;
    Result.FAttribs:= SFGAO_FOLDER;
  end else
    Result:= nil;
end;

function TRSShellFile.ExecuteDefaultCommand: Boolean;
var
  SEI: TShellExecuteInfo;
begin
  FillChar(SEI, SizeOf(SEI), 0);
  with SEI do
  begin
    cbSize := SizeOf(SEI);
    wnd := FWnd;
    fMask := SEE_MASK_INVOKEIDLIST;
    lpIDList := FFullIDList;
    nShow := SW_SHOW;
  end;
  Result := ShellExecuteEx(@SEI);
end;

function TRSShellFile.GetSelf: TRSShellFile;
begin
  Result:= self;
end;

function TRSShellFile.GetAttributes(AttribsSFGAO:DWord):DWord;
var Flags: DWord;
begin
  if AttribsSFGAO and SFGAO_VALIDATE <> 0 then
  begin
    FKnownAttribs:=0;
    FAttribs:=0;
  end;
  Result:= AttribsSFGAO and FAttribs;
  AttribsSFGAO:= AttribsSFGAO and not FKnownAttribs;
  if AttribsSFGAO<>0 then
  begin
    Flags:= AttribsSFGAO;
    if FParent.GetAttributesOf(1, FIDList, Flags) <> S_OK then  exit;
    Result:= Result or (Flags and AttribsSFGAO);
    FAttribs:= FAttribs or Flags;
    FKnownAttribs:= FKnownAttribs or AttribsSFGAO or Flags;
  end;
end;

function TRSShellFile.Rename(const Name:WideString; NameType:TRSFileNameType;
   FullPath:Boolean):TRSShellFile;
var i:int; p,p1,p2:PItemIDList;
begin
  Result:= nil;
  if GetAttributes(SFGAO_CANRENAME) = 0 then  exit;
  i:=byte(NameType);
  i:=(i and not 1)*SHGDN_FOREDITING*2 or (i and 1)*SHGDN_FOREDITING;
  if FullPath then
    i:= i or 1;
  if (Parent.SetNameOf(FWnd, FIDList, ptr(Name), i, p) <> S_OK) or (p=nil) then
    exit;
  p1:= nil;
  p2:= nil;
  try
    p1:= RSExtractRelativePIDL(p);
    Malloc.Free(p);
    p:= nil;
    p:= RSStripLastPIDL(FFullIDList);
    p2:= RSConcatPIDLs(p, p1);
  finally
    Malloc.Free(p);
    if p2=nil then // Exception
    begin
      Malloc.Free(p1);
    end;
  end;
  Result:= TRSShellFile.Create(Parent, p2, p1, FWnd);
end;

function TRSShellFile.Exists: Boolean;
var Flags:DWord;
begin
  Flags:= SFGAO_VALIDATE;
  Result:= Parent.GetAttributesOf(1, FIDList, Flags) = S_OK;
end;

{ TRSShellFolder }

type
  TCompareProc = function (Self:TObject; f1, f2:TRSShellFile):int;
  TCompareEvent = function (f1, f2:TRSShellFile):int of object;

  TMyStringList = class(TStringList)
    function CompareStrings(const S1, S2: string): Integer; override;
  end;

function MyCompare(const S1, S2: string): Integer;
begin
  Result := CompareString(LOCALE_SYSTEM_DEFAULT, NORM_IGNORECASE, PChar(S1),
    Length(S1), PChar(S2), Length(S2)) - 2;
end;

function TMyStringList.CompareStrings(const S1, S2: string): Integer;
begin
  Result:=MyCompare(S1, S2);
end;


procedure TRSShellFolder.Initialize;
begin
  inherited;
  FSortedFiles:= TMyStringList.Create;
  FSortedFiles.Sorted:= true;
  UseDefaultSorting;
end;

destructor TRSShellFolder.Destroy;
begin
  ClearFiles;
  inherited;
  FSortedFiles.Free;
end;

procedure TRSShellFolder.DoAssign(Source: TRSShellFile; Full:Boolean);
begin
  ClearAll;
  inherited;
  if Source is TRSShellFolder then
    with TRSShellFolder(Source) do
    begin
      if Full and (Source is TRSShellFolder) then
      begin
        self.Files:= Files;
        self.FSortedFiles.Assign(FSortedFiles);
        self.FOnCanAdd:= FOnCanAdd;
        self.FOnCompare:= FOnCompare;
        self.FOnIconLoaded:= FOnIconLoaded;
        self.FSortColumn:= FSortColumn;
        self.FSortInverse:= FSortInverse;
      end;
      self.FShellFolder:= FShellFolder;
      self.FIsRecicledBin:= FIsRecicledBin;
      self.FOwnShellIcon:= FOwnShellIcon;
    end;
end;

function TRSShellFolder.GetShellFolder: IShellFolder;
var i:int;
begin
  if FShellFolder = nil then
  begin
    i:=FParent.BindToObject(FIDList, nil, IID_IShellFolder, FShellFolder);
    if i<0 then
      if FIDList.mkid.cb = 0 then
        FShellFolder:= FParent
      else
        RSOleCheck(i);
  end;
  Result:= FShellFolder;
end;

procedure FreePIDLs(Block:pint);
var i:int; p: pptr;
begin
  try
    p:= ptr(Block);
    inc(pint(p));
    try
      for i:=Block^ downto 1 do
      begin
        RSSHMalloc.Free(p^);
        inc(p);
      end;
    finally
      FreeMem(Block, Block^*2 + 4);
    end;
  except
    // no idea why there's an exception when the program is closing...
  end;
end;

procedure TRSShellFolder.ClearFiles;
var i:int; Thread:THandle; p:pptr; Block:ptr;
begin
  StopIconsThread;
  if FSortedFiles<>nil then
    FSortedFiles.Clear;
  if Files<>nil then
  begin
    GetMem(Block, length(Files)*2*SizeOf(ptr) + 4);
    p:=Block;
    pint(p)^:= length(Files)*2;
    inc(pint(p));
    for i:=0 to high(Files) do
    begin
      if (Files[i]<>nil) and not Files[i].FKeepIDList then
      begin
        p^:= Files[i].FIDList;
        Files[i].FIDList:= nil;
      end else
        p^:= nil;
      inc(p);

      if (Files[i]<>nil) and not Files[i].FKeepFullIDList then
      begin
        p^:= Files[i].FFullIDList;
        Files[i].FFullIDList:= nil;
      end else
        p^:= nil;
      inc(p);

      Files[i].Free;
    end;
    Files:= nil;

    Thread:= BeginThread(nil, 4096, @FreePIDLs, Block, 0, uint(i));
    if Thread<>0 then
      SetThreadPriority(Thread, THREAD_PRIORITY_IDLE)
    else
      FreePIDLs(Block);
  end;
end;

procedure TRSShellFolder.RemoveFile(i:int);
var j,k:int;
begin
  if FSortedFiles.Count<>0 then
    for j:=FSortedFiles.Count-1 downto 0 do
    begin
      k:=int(FSortedFiles.Objects[j]);
      if k > i then
        FSortedFiles.Objects[j]:=ptr(k-1)
      else
        if k = i then
          FSortedFiles.Delete(j);
    end;
  Files[i].Free;
  j:=high(Files);
  CopyMemory(@Files[i], @Files[i+1], 4*(j-i));
  SetLength(Files, j);
end;

function TRSShellFolder.DoEnumFiles(Enum:IEnumIDlist; Stack:TRSObjStack):Boolean;
const
  BufLen = 32;
    // In fact I don't know in which cases the whole Buffer is used
    // System usually uses only one element
var
  i, n: uint;
  IDLists: array[0..BufLen-1] of PItemIDList;
  f: TRSShellFile;
begin
  Result:=true;
  if Assigned(FOnLoadFile) then
    FOnLoadFile(self, 0, length(Files), Result);
  if not Result then
    exit;
      
  while true do
  begin
    i:= Enum.Next(BufLen, IDLists[0], n); // No RSOleCheck here!
    if not Succeeded(i) then 
    begin
      Result:= false;
      exit;
    end;
    if n = 0 then  exit;

    i:=0;
    try
      while i<n do
      begin
        f:= CreateShellFile(IDLists[i]);
        if f <> nil then
          Stack.Push(f);
        inc(i);
      end;
    except
      inc(i);
      while i<n do
      begin
        Malloc.Free(IDLists[i]);
        inc(i);
      end;
      raise;
    end;

    if Assigned(FOnLoadFile) then
      FOnLoadFile(self, 0, length(Files) + Stack.Count, Result);
    if not Result then
    begin
      ClearFiles;
      SetLength(Files, Stack.Count);
      Stack.PeakAll(Files[0]);
      ClearFiles;
      exit;
    end;
  end;
end;

function TRSShellFolder.EnumFiles(Enum:IEnumIDlist; Append:Boolean = false):Boolean;
var
  Stack: TRSObjStack;
  f: TRSShellFile;
  i,j,k: int; Compare:TCompareEvent;
begin
  Result:=false;
  if Append then
  begin
    StopIconsThread;
    if FSortedFiles<>nil then
      FSortedFiles.Clear;
  end else
    ClearFiles;

  Stack:= TRSObjStack.Create;
  try
    Result:= DoEnumFiles(Enum, Stack);
    if not Result then  exit;

    i:= length(Files);
    k:= Stack.Count + i;
    j:= k;
    SetLength(Files, k);

     // Comparing items by name takes much more time than CopyMemory
    Compare:=DoCompare;
    for i:= k downto i + 1 do
    begin
      f:=ptr(Stack.Pop);
      DoFindFile(f, i, TMethod(Compare).Code, j, j-1);
      if j<>i then
        CopyMemory(@Files[i-1], @Files[i], (j-i)*SizeOf(TRSShellFile));
      Files[j-1]:= f;
      if Assigned(FOnLoadFile) then
        FOnLoadFile(self, k - i + 1, k, Result);
      if not Result then
      begin
        ClearFiles;
        SetLength(Files, Stack.Count);
        Stack.PeakAll(Files[0]);
        ClearFiles;
        exit;
      end;
    end;
    GiveShellIcon;

  finally
    Stack.Free;
  end;
end;

function TRSShellFolder.EnumFiles(FlagsSHCONTF: int = SHCONTF_FOLDERS or
   SHCONTF_NONFOLDERS or SHCONTF_INCLUDEHIDDEN; Append:Boolean = false):Boolean;
var
  Enum:IEnumIDlist;
begin
  Result:= (RSOleCheck(ShellFolder.EnumObjects(FWnd, FlagsSHCONTF, Enum)) = 0)
             and EnumFiles(Enum, Append);
end;

procedure TRSShellFolder.DoCanAdd(var ShellFile:TRSShellFile);
var CanAdd:Boolean;
begin
  if Assigned(FOnCanAdd) then
  begin
    CanAdd:=true;
    FOnCanAdd(self, ShellFile, CanAdd);
    if not CanAdd then
    begin
      ShellFile.Free;
      ShellFile:=nil;
    end;
  end;
end;

function TRSShellFolder.CreateShellFile(PIDL:PItemIDList):TRSShellFile;
var p:PItemIDList;
begin
  try
    p:=RSConcatPIDLs(FFullIDList, PIDL);
  except
    Malloc.Free(PIDL);
    raise;
  end;
  Result:= TRSShellFile.Create(ShellFolder, p, PIDL, FWnd);
   // TRSShellFile first of all sets FIDList to PIDL, so the PIDL memory is
   // sure to be released
  DoCanAdd(Result);
end;

function TRSShellFolder.GiveShellIcon: Boolean;
var i:int;
begin
  Result:= (FOwnShellIcon = nil) and
     not Succeeded(ShellFolder.QueryInterface(IID_IShellIcon, FOwnShellIcon));

  for i:=0 to length(Files)-1 do
    if Files[i]<>nil then
    begin
      Files[i].FShellIcon:= FOwnShellIcon;
      Files[i].FNoShellIcon:= Result;
    end;
  Result:= not Result;
end;

procedure TRSShellFolder.CreateIconsThread(Priority: int = THREAD_PRIORITY_BELOW_NORMAL);
var i:uint;
begin
  if (FIconsThread <> 0) or (FOwnShellIcon <> nil) then  exit;
  FIconsThreadStopped:=false;
  FThreadOnIconLoaded:= OnIconLoaded;
  FIconsThread:= BeginThread(nil, 0, @TRSShellFolder.IconThreadProc, self, 0, i);
   // No need in big stack. No Win32Check, cause the thread doesn't metter much.
  SetThreadPriority(FIconsThread, Priority);
end;

function TRSShellFolder.IconThreadProc: int;
var i,n:int;
begin
  Result:=0;
  n:=high(Files);
  if FOwnShellIcon = nil then
    for i:=0 to n do
      if not FIconsThreadStopped then
        try
          if (Files = nil) or (Files[i] = nil) then
            exit;
          Files[i].ImageIndex;
          if Assigned(FThreadOnIconLoaded) then
            FThreadOnIconLoaded(self, self, i);
        except
        end
      else
        exit;
end;

procedure TRSShellFolder.StopIconsThread;
begin
  if FIconsThread = 0 then  exit;
  FIconsThreadStopped:=true;
  SetThreadPriority(FIconsThread, THREAD_PRIORITY_ABOVE_NORMAL);
  WaitForSingleObject(FIconsThread, INFINITE);
  CloseHandle(FIconsThread);
  FIconsThread:=0;
end;

function TRSShellFolder.DoCompare(f1, f2:TRSShellFile):int;
var i:int; Inverse:Boolean;
begin
  if f1 = nil then
  begin
    if f2 = nil then
      Result:= 0
    else
      Result:= -1;
    exit;
  end;
  if f2 = nil then
  begin
    Result:= 1;
    exit;
  end;

  i:= FSortColumn;
  Inverse:= FSortInverse;

  if Assigned(FOnCompare) then
  begin
    Result:= FOnCompare(self, self, f1, f2, i, Inverse);
    if i = -1 then  exit;
  end;
  Result:= BoolToInt[f2.IsFolder] - BoolToInt[f1.IsFolder];
  if Result = 0 then
  begin
    Result:= int2(word(ShellFolder.CompareIDs(i, f1.FIDList, f2.FIDList)));
    if Inverse then
      Result:= -Result;
  end;
end;

{
function TRSShellFolder.DoFullCompare(f1, f2:TRSShellFile):int;
var b:Boolean;
begin
  if Assigned(FOnCompare) then
  begin
    b:=false;
    Result:= FOnCompare(self, self, f1, f2, b);
    if b then  exit;
  end;
  Result:= BoolToInt[f1.IsFolder] - BoolToInt[f2.IsFolder];
  if Result = 0 then
    Result:= int2(DesktopFolder.CompareIDs(0, f1.FFullIDList, f2.FFullIDList));
end;
}

function TRSShellFolder.DoFindFile(ShellFile:TRSShellFile; L:int;
   Compare:ptr; var Index:int; I:int = -1):Boolean;
var
  H, C: Integer;
begin
  H := high(Files);
  if i < 0 then
    I := (L + H) shr 1;
  while L <= H do
  begin
    C := TCompareProc(Compare)(Self, Files[I], ShellFile);
    if C < 0 then L := I + 1 else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Index := I;
        Result := True;
        exit;
      end;
    end;
    I := (L + H) shr 1;
  end;
  Index := L;
  Result := False;
end;

procedure TRSShellFolder.QuickSort(L,R:int; Compare:ptr);
var
  I, J, P: Integer; f:TRSShellFile;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      while TCompareProc(Compare)(Self, Files[I], Files[P]) < 0 do Inc(I);
      while TCompareProc(Compare)(Self, Files[J], Files[P]) > 0 do Dec(J);
      if I <= J then
      begin
        f:=Files[I];
        Files[I]:=Files[J];
        Files[J]:=f;
        if P = I then
          P := J
        else if P = J then
          P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J, Compare);
    L := I;
  until I >= R;
end;

procedure TRSShellFolder.DoSort;
var
  CompareEvent: TCompareEvent;
begin
  CompareEvent:= DoCompare;
  QuickSort(0, length(Files)-1, TMethod(CompareEvent).Code);
end;

function IsThere(const s1, s2:string):boolean;
begin
  if length(s1)>=length(s2) then
    Result := CompareString(LOCALE_SYSTEM_DEFAULT, NORM_IGNORECASE, ptr(s1),
      length(s2), ptr(s2), length(s2)) = 2
  else
    Result:=false;
end;

procedure TRSShellFolder.NeedSortedFiles;
var i:int;
begin
  if FSortedFiles.Count<>0 then  exit;
  FSortedFiles.Capacity:= length(Files);
  for i:=0 to high(Files) do
    if Files[i]<>nil then
      FSortedFiles.AddObject(Files[i].ShortName, ptr(i));
end;

function TRSShellFolder.FindFile(const Name:string; StartIndex:int;
   Wrap:Boolean = true; AllowPartial:Boolean = true):int;
const
  ManualScan: array[Boolean] of Byte = (100, 5);
var
  i, j, Dist, Count:int; Found:Boolean;
begin
  i:= ManualScan[FSortedFiles.Count<>0];
  for Result:= StartIndex to StartIndex + min(i, high(Files)) do
    if (Files[Result mod length(Files)]<>nil) and
       IsThere(Files[Result mod length(Files)].ShortName, Name) then  exit;

  NeedSortedFiles;

  Count:=length(Files);
  Found:= FSortedFiles.Find(Name, i);
  if AllowPartial then
  begin
    Result:=-1;
    Dist:=MaxInt;
    while (i<Count) and IsThere(FSortedFiles[i], Name) do
    begin
      j:= int(FSortedFiles.Objects[i]) - StartIndex;
      if (j>=0) or Wrap then
      begin
        if j<0 then
          inc(j, length(Files));
        if j<Dist then
        begin
          Dist:=j;
          Result:= int(FSortedFiles.Objects[i]);
        end;
      end;
      inc(i);
    end;
  end else
    if Found then
      Result:= int(FSortedFiles.Objects[i])
    else
      Result:= -1;
end;

function TRSShellFolder.FindShellFile(ShellFile:TRSShellFile):int;
var Compare: TCompareEvent;
begin
  if length(Files) = 0 then
  begin
    Result:=-1;
    exit;
  end;
  Compare:=DoCompare;
  if not DoFindFile(ShellFile, 0, TMethod(Compare).Code, Result) then
    Result:= not Result;
end;

function TRSShellFolder.IsRecicledBin: Boolean;
begin
  if (FIsRecicledBin = 0) and (FFullIDList<>nil) then
    if RSIsSpecialFolder(FFullIDList, CSIDL_BITBUCKET) then
      FIsRecicledBin:= 1
    else
      FIsRecicledBin:= -1;
  Result:= FIsRecicledBin = 1;
end;

procedure TRSShellFolder.UseDefaultSorting;
begin
  if IsRecicledBin then
  begin
    FSortColumn:= 2;
    FSortInverse:= true;
  end else
  begin
    FSortColumn:= 0;
    FSortInverse:= false;
  end;
end;

procedure TRSShellFolder.FlushCache;
var Flags:DWord;
begin
  Flags:= SFGAO_VALIDATE;
  ShellFolder.GetAttributesOf(0, PItemIDList(nil^), Flags);
end;



procedure FreeSpecialPIDLs;
var i:int;
begin
  for i:=0 to 255 do
    if SpecialPIDL[i]<>nil then
      RSSHMalloc.Free(SpecialPIDL[i]);
end;

initialization

finalization
  if IsLibrary then
    FreeSpecialPIDLs;
end.
