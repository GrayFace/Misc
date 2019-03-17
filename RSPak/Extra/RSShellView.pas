unit RSShellView;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 To use TRSShellView on Windows 95/98/Me  Microsoft® Layer for Unicode
  must be installed. It can be downloaded from
  http://www.microsoft.com/msdownload/platformsdk/sdkupdate/psdkredist.htm

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Windows, Messages, SysUtils, ActiveX, ComObj, ShlObj, ShellAPI, Controls,
  Forms, Contnrs, CommCtrl, RSShellBrowse, RSSysUtils, ComCtrls, RSQ,
  Classes, RSCommon, Graphics, Themes, UxTheme, RSShellCtrls;

{ TODO :
TRSShellViewDefActionEvent = TRSShellListViewOpenFileEvent
TabStop
StatusBar
IRSShellViewEnumItems.HasNext
From TRSListView
SetSelected
IShellView::SelectItem
}

{$I RSWinControlImport.inc}

type
  TRSShellViewFile = class;
  TRSShellView = class;

  IRSShellViewFile = interface
    ['{DCDBFD33-411C-4C21-ADF1-52F3619B621C}']
    procedure Assign(Source:TRSShellFile; FullAssign:Boolean = false);
    function FullName(NameType:TRSFileNameType = [RSForParsing]):string;
    function ShortName(NameType:TRSFileNameType = []):string;
    function ImageIndex(Open: Boolean = false; Async: Boolean = false): int;
    function ImageIndexReady(Open: Boolean = false): Boolean;
    function ContextMenu: IContextMenu;
    function CreateParentFolder(FolderClass: TRSShellFileClass): TRSShellFile;
    function ExecuteDefaultCommand: Boolean;
    function GetSelf: TRSShellViewFile;
    function GetAttributes(AttribsSFGAO:DWord):DWord;
    function Rename(const Name: WideString;
      NameType: TRSFileNameType = [RSForEditing];
      FullPath: Boolean = false):TRSShellFile;
    function Exists: Boolean;
    function IsFolder: Boolean;
    function IsFileSystem: Boolean;
    function SamePIDL(f: TRSShellFile): Boolean;

    function PIDL: PItemIDList;
    function FullPIDL: PItemIDList;
    function Parent: IShellFolder;

    function Owner: TRSShellView;
  end;

  TRSShellViewFile = class(TRSShellFile, IRSShellViewFile)
  private
    {IRSShellViewFile}
    function GetPIDL: PItemIDList;
    function IRSShellViewFile.PIDL = GetPIDL;
    function GetFullPIDL: PItemIDList;
    function IRSShellViewFile.FullPIDL = GetFullPIDL;
    function GetParent: IShellFolder;
    function IRSShellViewFile.Parent = GetParent;
    function GetOwner: TRSShellView;
    function IRSShellViewFile.Owner = GetOwner;
  protected
    FOwner: TRSShellView;

    {IUnknown}
    FRefCount: Integer;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(AOwner:TRSShellView; PIDL:PItemIDList; OwnIDList:Boolean = true);

    function GetSelf: TRSShellViewFile;
    property Owner: TRSShellView read FOwner;

    {IUnknown}
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    class function NewInstance: TObject; override;
    property RefCount: Integer read FRefCount;
  end;

  TRSShellViewFolder = class(TRSShellFolder)
    // Nothing here for now
  end;

  IRSShellViewEnumItems = interface
    ['{860940C7-AA30-4C7F-AA5B-F123865D91BF}']
    function Next: IRSShellViewFile;
    procedure Reset;
    function Skip(Count:int):Boolean;
    function Count:int;
  end;

  TRSShellViewEnumItems = class(TInterfacedObject, IRSShellViewEnumItems)
  protected
    FEnum: IEnumIDList;
    FView: TRSShellView;
    FCount: int;
    FLastItem: int;
  public
    constructor Create(View: TRSShellView; Count:int; Enum: IEnumIDList);
    function Next: IRSShellViewFile;
    procedure Reset;
    function Skip(Count:int):Boolean;
    function Count:int;
  end;

	TRSShellViewStyle = (RSvsIcon, RSvsSmallIcon, RSvsList, RSvsDetails,
    RSvsThumnail, RSvsTile, RSvsThumbstrip);

  TRSShellViewDefActionEvent = procedure(Sender: TRSShellView;
    Node: IRSShellViewFile; var Handled: Boolean) of object;

   // Based on TShellView from DCodeBot package
  TRSShellView = class(TRSCustomControl, IOleWindow, IShellBrowser,
     ICommDlgBrowser, ICommDlgBrowser2)
  private
    FBorderStyle: TBorderStyle;
    FOnCreateParams: TRSCreateParamsEvent;
    FProps: TRSWinControlProps;

    FStatusBar: TWinControl;
    FMultiSelect: Boolean;
    FShowAllFiles: Boolean;
    FHideSelection: Boolean;
    FAutoArrange: Boolean;
    FIconsArrangement: TIconArrangement;

    FOnFolderChanged: TNotifyEvent;
    FOnDefaultAction: TRSShellViewDefActionEvent;
    FOnCanAddItem: TRSShellFolderCanAddEvent;
    FOnBack: TRSApproveEvent;
    FOnCanRefresh: TRSApproveEvent;

{
    FOnViewChanged: TNotifyEvent;
}

    procedure SetBorderStyle(v: TBorderStyle);
    function GetViewStyle: TRSShellViewStyle;
		procedure SetViewStyle(v: TRSShellViewStyle);
    function GetItem(Index: Integer): IRSShellViewFile;
    function GetSelected: IRSShellViewFile;
    procedure SetSelected(v:IRSShellViewFile);
    function GetItemsCount: Integer;
    procedure SetHideSelection(v: Boolean);
    procedure SetMultiSelect(v: Boolean);
    procedure SetShowAllFiles(v: Boolean);
    procedure SetIconsArrangement(v: TIconArrangement);
    procedure SetAutoArrange(v: Boolean);
    function GetSelCount: Integer;
    function GetNeedRefresh: Boolean;
    function GetPath: string;
  protected
    FRoot: TRSShellViewFolder;
    FNotifier: TRSShellChangeNotifier;
    FShellBrowser: TRSShellBrowser;
    FNeedRefresh: Boolean;
    FAutoRefresh: Boolean;

    FDefListViewProc: Pointer;
    FListViewInstance: Pointer;
    FListViewHandle: HWND;

    FDefShellViewProc: Pointer;
    FShellViewInstance: Pointer;
    FShellViewHandle: HWND;

    FShellView: IShellView;
    FFolderView: IFolderView;
    FStream: IStream;

    FViewStyle: TRSShellViewStyle;

    function DoBrowse(f: TRSShellViewFolder; FindFile: TRSShellFile = nil):Boolean;

    procedure ShowException(e: Exception);
    procedure DoNeedRefresh(Sender:TObject);
    function GetSelectedIndex(var Index: Integer): Boolean;
    function GetPIDL(Index: Integer; var PIDL: PItemIDList):Boolean;
    procedure DestroyView;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure TranslateWndProc(var Msg:TMessage);
    procedure WndProc(var Msg:TMessage); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure ListViewWndProc(var Message: TMessage); virtual;
    procedure ShellViewWndProc(var Message: TMessage); virtual;

    procedure WMGetDlgCode(var Msg: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMNCPaint(var Msg: TWMNCPaint); message WM_NCPAINT;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure WMLButtonDown(var Msg:TWMLButtonDown); message WM_LButtonDown;

    { IOleWindow }
    function GetWindow(out wnd: HWnd): HResult; stdcall;
    function ContextSensitiveHelp(fEnterMode: BOOL): HResult; stdcall;
    { IShellBrowser }
    function InsertMenusSB(hMenuShared: HMENU;
      out MenuWidths: TOleMenuGroupWidths): HResult; stdcall;
    function SetMenuSB(hMenuShared: HMENU;
      hOleMenuReserved: HOLEMENU; hwndActiveObject: HWND): HResult; stdcall;
    function RemoveMenusSB(hMenuShared: HMENU): HResult; stdcall;
    function SetStatusTextSB(StatusText: POleStr): HResult; stdcall;
    function EnableModelessSB(Enable: BOOL): HResult; stdcall;
    function TranslateAcceleratorSB(Msg: PMsg; ID: Word): HResult; stdcall;
    function BrowseObject(pidl: PItemIDList; flags: UINT): HResult; stdcall;
    function GetViewStateStream(Mode: DWORD; out Stream: IStream): HResult; stdcall;
    function GetControlWindow(ID: UINT; out Wnd: HWND): HResult; stdcall;
    function SendControlMsg(ID, Msg: UINT; wParam: WPARAM; lParam: LPARAM;
      var Rslt: LResult): HResult; stdcall;
    function QueryActiveShellView(var ShellView: IShellView): HResult; stdcall;
    function OnViewWindowActive(var ShellView: IShellView): HResult; stdcall;
    function SetToolbarItems(TBButton: PTBButton;
      nButtons, uFlags: UINT): HResult; stdcall;
    { ICommDlgBrowser }
    function OnDefaultCommand(const ppshv: IShellView): HResult; stdcall;
    function OnStateChange(const ppshv: IShellView; Change: ULONG): HResult; stdcall;
    function IncludeObject(const ppshv: IShellView; pidl: PItemIDList): HResult; stdcall;
    { ICommDlgBrowser2 }
    function Notify(ppshv: IShellView; dwNotifyType: DWORD): HResult; stdcall;
    function GetDefaultMenuText(ppshv: IShellView; pszText: PWideChar;
    	cchMax: Integer): HResult; stdcall;
    function GetViewFlags(out pdwFlags: DWORD): HResult; stdcall;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Back;
    function Browse(const Path:string):Boolean; overload;
    function Browse(SpecialFolderCSIDL:int = CSIDL_DESKTOP):Boolean; overload;
    function Browse(const Item:IRSShellViewFile):Boolean; overload;
    procedure Clear;
    function SelectedItems: IRSShellViewEnumItems;

    procedure RefreshFolder;
    property NeedRefresh: Boolean read GetNeedRefresh;
    property Path: string read GetPath;
    property Items[Index:Integer]: IRSShellViewFile read GetItem;
    property ItemsCount: Integer read GetItemsCount;
    property SelectedItem: IRSShellViewFile read GetSelected write SetSelected;
    property SelCount: Integer read GetSelCount;
    property Root: TRSShellViewFolder read FRoot;
    property ShellView: IShellView read FShellView;
    property FolderView: IFolderView read FFolderView;
    property ListViewHandle: HWND read FListViewHandle;
    property ShellViewHandle: HWND read FShellViewHandle;
  published
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;

    property AutoRefresh: Boolean read FAutoRefresh write FAutoRefresh default false;
		property ViewStyle: TRSShellViewStyle read GetViewStyle write SetViewStyle default RSvsIcon;
    property ShowAllFiles: Boolean read FShowAllFiles write SetShowAllFiles default true;
      // Show hidden and system files
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect default false;
    property HideSelection: Boolean read FHideSelection write SetHideSelection default false;
    property AutoArrange: Boolean read FAutoArrange write SetAutoArrange default true;
    property IconsArrangement: TIconArrangement read FIconsArrangement write SetIconsArrangement default iaTop;
    property OnFolderChanged: TNotifyEvent read FOnFolderChanged write FOnFolderChanged;
    property OnDefaultAction: TRSShellViewDefActionEvent read FOnDefaultAction write
      FOnDefaultAction;
    property OnCanAddItem: TRSShellFolderCanAddEvent read FOnCanAddItem
      write FOnCanAddItem;
    property OnBack: TRSApproveEvent read FOnBack write FOnBack; 
    property OnCanRefresh: TRSApproveEvent read FOnCanRefresh write FOnCanRefresh;
{
    property OnViewChanged: TNotifyEvent read FOnViewChanged write FOnViewChanged;
    property StatusBar: TWinControl read FStatusBar write SetStatusBar;
}
    {$I RSWinControlProps.inc}
    property Align;
    property Anchors;
    property BevelEdges;
    property BevelInner;
    property BevelKind default bkNone;
    property BevelOuter;
    property BevelWidth;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ParentCtl3D;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnCanResize;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSShellView]);
end;

{
******************************* TRSShellViewFile *******************************
}

constructor TRSShellViewFile.Create(AOwner:TRSShellView; PIDL:PItemIDList;
  OwnIDList:Boolean = true);
var p1: PItemIDList;
begin
  try
    if AOwner.Root = nil then
      p1:= RSCopyPIDL(PIDL)
    else
      p1:= RSConcatPIDLs(AOwner.Root.FullPIDL, PIDL);
  except
    if OwnIDList then
      RSSHMalloc.Free(PIDL);
    raise;
  end;
  FKeepIDList:= not OwnIDList;
  if AOwner.Root<>nil then
  begin
    FKeepIDList:= not OwnIDList;
    inherited Create(AOwner.Root.ShellFolder, p1, PIDL, Application.Handle);
  end else
    inherited Create(nil, p1, nil, Application.Handle);
  FOwner:= AOwner;
end;

{ TRSShellViewFile.IUnknown }

function TRSShellViewFile._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TRSShellViewFile._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

function TRSShellViewFile.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TRSShellViewFile.AfterConstruction;
begin
// Release the constructor's implicit refcount
  InterlockedDecrement(FRefCount);
end;

procedure TRSShellViewFile.BeforeDestruction;
begin
  if RefCount <> 0 then
    System.Error(reInvalidPtr);
end;

class function TRSShellViewFile.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TRSShellViewFile(Result).FRefCount := 1;
end;

{ TRSShellViewFile.IRSShellViewFile }

function TRSShellViewFile.GetSelf: TRSShellViewFile;
begin
  Result:= self;
end;

function TRSShellViewFile.GetFullPIDL: PItemIDList;
begin
  Result:= FullPIDL;
end;

function TRSShellViewFile.GetParent: IShellFolder;
begin
  Result:= Parent;
end;

function TRSShellViewFile.GetPIDL: PItemIDList;
begin
  Result:= PIDL;
end;

function TRSShellViewFile.GetOwner: TRSShellView;
begin
  Result:= FOwner;
end;

{
**************************** TRSShellViewEnumItems *****************************
}

constructor TRSShellViewEnumItems.Create(View: TRSShellView; Count:int;
   Enum: IEnumIDList);
begin
  FLastItem:=-1;
  FView:= View;
  FCount:= Count;
  FEnum:= Enum;
end;

function TRSShellViewEnumItems.Next: IRSShellViewFile;
var p:PItemIDList; i:int;
begin
  Result:= nil;
  if FEnum = nil then
  begin
    if FView.ListViewHandle = 0 then  exit;
    i:= ListView_GetNextItem(FView.ListViewHandle, FLastItem, LVNI_SELECTED);
    if i>=0 then
    begin
      FLastItem:=i;
      Result:= FView.GetItem(i);
    end;
  end else
    if (FEnum.Next(1, p, uint(i))>=0) and (i = 1) then
      Result:= TRSShellViewFile.Create(FView, p);
end;

procedure TRSShellViewEnumItems.Reset;
begin
  if FEnum = nil then
    FLastItem:= -1
  else
    RSOleCheck(FEnum.Reset);
end;

function TRSShellViewEnumItems.Skip(Count: int): Boolean;
var i,j:int;
begin
  if Count = 0 then
    Result:= true
  else
    if FEnum = nil then
    begin
      j:=FLastItem;
      for i:=Count downto 1 do
      begin
        j:=ListView_GetNextItem(FView.ListViewHandle, j, LVNI_SELECTED);
        if j<0 then  break;
        FLastItem:= j;
      end;
      Result:= j>=0;
    end else
      Result:= FEnum.Skip(Count) = NOERROR;
end;

function TRSShellViewEnumItems.Count:int;
begin
  Result:=FCount;
end;

{
********************************* TRSShellView *********************************
}

constructor TRSShellView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width:= 250;
  Height:= 200;
  ParentColor:= false;
  Color:= clWindow;
  ControlStyle:= ControlStyle - [csSetCaption];
  FBorderStyle:= bsSingle;
  FShowAllFiles:= true;
  FAutoArrange:= true;
  FListViewInstance:= MakeObjectInstance(ListViewWndProc);
  FShellViewInstance:= MakeObjectInstance(ShellViewWndProc);
  WindowProc:=TranslateWndProc;
  FNotifier:= TRSShellChangeNotifier.Create(DoNeedRefresh);
  FShellBrowser:= TRSShellBrowser.Create;
  FShellBrowser.ShellFolderClass:= TRSShellViewFolder;
end;

destructor TRSShellView.Destroy;
begin
  FStream:= nil;
  FreeObjectInstance(FListViewInstance);
  FreeObjectInstance(FShellViewInstance);
  FShellBrowser.Free;
  FNotifier.Free;
  FRoot.Free;
  inherited Destroy;
end;

procedure TRSShellView.CreateParams(var Params: TCreateParams);
begin
	inherited CreateParams(Params);
  with Params do
  begin
    if FBorderStyle = bsSingle then
      if NewStyleControls and Ctl3D then
        ExStyle:= ExStyle or WS_EX_CLIENTEDGE
      else
        Style:= Style or WS_BORDER;
    WindowClass.style:= WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
  end;
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

procedure TRSShellView.CreateWnd;
begin
  inherited;
  if FRoot<>nil then
    try
      DoBrowse(FRoot);
    except
      Application.HandleException(self);
    end;
end;

procedure TRSShellView.DestroyWnd;
begin
  DestroyView;
  inherited;
end;

procedure TRSShellView.ListViewWndProc(var Message: TMessage);
var
  Form: TCustomForm;
begin
  with Message do
  try
    case Msg of
      WM_SETFOCUS:
      begin
        Form := GetParentForm(self);
        if (Form <> nil) and Enabled and not Form.SetFocusedControl(Self) then
          exit;
      end;
      WM_KILLFOCUS:
        if csFocusing in ControlState then  exit;
      WM_KEYDOWN, WM_SYSKEYDOWN:
        if DoKeyDown(TWMKey(Message)) then  exit;
      WM_CHAR:
        if DoKeyPress(TWMKey(Message)) then  exit;
      WM_KEYUP, WM_SYSKEYUP:
        if DoKeyUp(TWMKey(Message)) then  exit;
      WM_NCHITTEST:
        if csDesigning in ComponentState then
        begin
          Result := HTTRANSPARENT;
          exit;
        end;
      WM_MOUSEMOVE:
      begin
        with TWMMouseMove(Message) do
          MouseMove(KeysToShiftState(Keys), XPos, YPos);
        Application.HintMouseMessage(Self, Message);
      end;
{
      CN_BASE..CN_NOTIFY: //CN_KEYDOWN, CN_CHAR, CN_SYSKEYDOWN, CN_SYSCHAR:
      begin
        WndProc(Message);
        Exit;
      end;
}      
    end;
    Result := CallWindowProc(FDefListViewProc, FListViewHandle, Msg, WParam, LParam);
    if (Msg = WM_LBUTTONDBLCLK) and (csDoubleClicks in ControlStyle) then
      DblClick;
  except
    Application.HandleException(Self);
  end;
end;

procedure TRSShellView.ShellViewWndProc(var Message: TMessage);
const
  DefaultMenu = $7900;
var
  MenuItemInfo: TMenuItemInfo;
begin
  with Message do
  try
    case Msg of
      WM_NCHITTEST:
        if csDesigning in ComponentState then
        begin
          Result := HTTRANSPARENT;
          Exit;
        end;
      WM_INITMENUPOPUP:
        with TWMInitMenuPopup(Message) do
          if GetMenuItemID(MenuPopup, 0) = DefaultMenu then
          begin
            RemoveMenu(MenuPopup, 0, MF_BYPOSITION);
            RemoveMenu(MenuPopup, 0, MF_BYPOSITION);
            FillChar(MenuItemInfo, SizeOf(TMenuItemInfo), #0);
            with MenuItemInfo do
            begin
              cbSize := SizeOf(TMenuItemInfo);
              fMask := MIIM_STATE or MIIM_ID;
              fState := MFS_DEFAULT;
              wID := DefaultMenu;
            end;
            SetMenuItemInfo(MenuPopup, 0, True, MenuItemInfo);
          end;
    end;
    Result := CallWindowProc(FDefShellViewProc, FShellViewHandle, Msg, WParam,
      LParam);
  except
    Application.HandleException(Self);
  end;
end;

procedure TRSShellView.Back;
var f:TRSShellViewFolder; Handled:Boolean;
begin
  if FRoot=nil then
    exit;

  Handled:=false;
  if Assigned(FOnBack) then  FOnBack(self, Handled);
  if Handled then  exit;

  try
    f:= TRSShellViewFolder(FRoot.CreateParentFolder(TRSShellViewFolder));
  except
    f:= TRSShellViewFolder.Create(CSIDL_DESKTOP, Application.Handle);
  end;

  if f<>nil then
    DoBrowse(f, FRoot);
end;

procedure TRSShellView.SetBorderStyle(v: TBorderStyle);
begin
	if v <> FBorderStyle then
  begin
  	FBorderStyle:= v;
    if HandleAllocated then
    begin
    	Perform(WM_SIZE, Width, Height);
			Invalidate;
    end;
  end;
end;

{ TRSShellView.IOleWindow }

function TRSShellView.GetWindow(out wnd: HWnd): HResult;
begin
  wnd:= Handle;
  Result:= S_OK;
end;

function TRSShellView.ContextSensitiveHelp(fEnterMode: BOOL): HResult;
begin
  Result:= S_OK;
end;

{ TRSShellView.IShellBrowser }

function TRSShellView.InsertMenusSB(hMenuShared: HMENU;
  out MenuWidths: TOleMenuGroupWidths): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.SetMenuSB(hMenuShared: HMENU;
  hOleMenuReserved: HOLEMENU; hwndActiveObject: HWND): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.RemoveMenusSB(hMenuShared: HMENU): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.SetStatusTextSB(StatusText: POleStr): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.EnableModelessSB(Enable: BOOL): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.TranslateAcceleratorSB(Msg: PMsg; ID: Word): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.BrowseObject(pidl: PItemIDList; flags: UINT): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.GetViewStateStream(Mode: DWORD; out Stream: IStream): HResult;
begin
  Stream:= FStream;
  Result:= S_OK;
end;

function TRSShellView.GetControlWindow(ID: UINT; out Wnd: HWND): HResult;
begin
  Wnd:= 0;
  case ID of
    FCW_STATUS:
      if FStatusBar <> nil then
        Wnd:= FStatusBar.Handle;
{
    FCW_TOOLBAR:
      if FToolBar <> nil then
        Rslt:= SendMessage(FToolBar.Handle, Msg, wParam, lParam);
    FCW_TREE:
      if FTreeView <> nil then
        Wnd:= FTreeView.Handle;
}
  end;
  Result:= S_OK;
end;

function TRSShellView.SendControlMsg(ID, Msg: UINT; wParam: WPARAM; lParam: LPARAM;
  var Rslt: LResult): HResult;
begin
  case ID of
    FCW_STATUS:
      if FStatusBar <> nil then
        Rslt:= SendMessage(FStatusBar.Handle, Msg, wParam, lParam);
{
    FCW_TOOLBAR:
      if FToolBar <> nil then
        Rslt:= SendMessage(FToolBar.Handle, Msg, wParam, lParam);
}
  end;
  Result := S_OK;
end;

function TRSShellView.QueryActiveShellView(var ShellView: IShellView): HResult;
begin
  ShellView:= FShellView;
  Result:= S_OK;
end;

function TRSShellView.OnViewWindowActive(var ShellView: IShellView): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.SetToolbarItems(TBButton: PTBButton;
  nButtons, uFlags: UINT): HResult;
begin
  Result:= S_OK;
end;

{ TRSShellView.ICommDlgBrowser }

function TRSShellView.OnDefaultCommand(const ppshv: IShellView): HResult;
var
	Handled: Boolean;
  it: IRSShellViewFile;
begin
	Handled:= false;
  if Assigned(FOnDefaultAction) then
  try
    FOnDefaultAction(Self, SelectedItem, Handled);
  except
    Application.HandleException(Self);
  end;

  if not Handled then
  try
    it:=SelectedItem;
    if (it<>nil) and it.IsFolder then
    begin
      Handled:=true;
      Browse(it);
    end;
  except
    Application.HandleException(Self);
  end;

  Result:= RSOleBoolean[Handled];
end;

function TRSShellView.OnStateChange(const ppshv: IShellView; Change: ULONG): HResult;
begin
  Result:= S_OK;
end;

function TRSShellView.IncludeObject(const ppshv: IShellView; pidl: PItemIDList): HResult;
var
	CanAdd: Boolean;
  f: TRSShellViewFile;
begin
	CanAdd:= True;

	if Assigned(FOnCanAddItem) then
	try
    f:=TRSShellViewFile.Create(self, pidl, false);
    try
      FOnCanAddItem(self, f, CanAdd);
    finally
      f.Free;
    end;
  except
    Application.HandleException(Self);
  end;

  Result:= RSOleBoolean[CanAdd];
end;

{ TRSShellView.ICommDlgBrowser2 }

function TRSShellView.Notify(ppshv: IShellView; dwNotifyType: DWORD): HResult;
begin
{
	if dwNotifyType = CDB2N_CONTEXTMENU_DONE then
    try
      DoViewChanged;
    except
      Application.HandleException(Self);
    end;
}
	Result := S_OK;
end;

function TRSShellView.GetDefaultMenuText(ppshv: IShellView; pszText: PWideChar;
	cchMax: Integer): HResult;
begin
	PWord(pszText)^:=0;
	Result := S_OK;
end;

function TRSShellView.GetViewFlags(out pdwFlags: DWORD): HResult;
begin
  if FShowAllFiles then
    pdwFlags:= CDB2GVF_SHOWALLFILES
  else
    pdwFlags:= 0;
	Result:= S_OK;
end;


procedure TRSShellView.WMGetDlgCode(var Msg: TWMGetDlgCode);
begin
  Msg.Result:= DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

procedure TRSShellView.WMNCPaint(var Msg: TWMNCPaint);
var
	PS: TPaintStruct;
  r: TRect;
begin
  inherited;
  if not ThemeServices.ThemesEnabled or
    (TRSWnd(Handle).ExStyle and WS_EX_CLIENTEDGE <> 0) then  exit;
  with TCanvas.Create do
    try
      Handle:= GetWindowDC(self.Handle);
      ExcludeClipRect(Handle, 2, 2, Width - 2, Height - 2);
      r:= Rect(0, 0, Width, Height);
      with ThemeServices do
        DrawElement(Handle, GetElementDetails(tlListviewRoot), r);
    finally
      if HandleAllocated then
        ReleaseDC(self.Handle, Handle);
      Free;
    end;
  EndPaint(Handle, PS);
end;

procedure TRSShellView.WMSize(var Msg: TWMSize);
var r:TRect;
begin
  if FShellViewHandle <> 0 then
  begin
    r:= ClientRect;
    AdjustClientRect(r);
    TRSWnd(FShellViewHandle).BoundsRect:=r;
  end;
  inherited;
end;

 // Copy ControlAtom & WindowAtom to handle CM_MOUSEENTER etc properly.
function EnumPropsProc(Wnd:HWnd; Str:PChar; Data:THandle; self:TRSShellView):Bool; stdcall;
begin
  Result:= true;
  if ptr(Data) = self then
  begin
    SetProp(self.FListViewHandle, Str, Data);
    SetProp(self.FShellViewHandle, Str, Data);
  end;
end;

function TRSShellView.DoBrowse(f: TRSShellViewFolder; FindFile: TRSShellFile = nil):Boolean;
var
	WasFocused: Boolean;
  FolderSettings: TFolderSettings;
  r: TRect;
  View: IShellView;
  fv: IFolderView;
  SVHandle: HWnd;
begin
  if (f<>nil) and not f.IsFolder then
    try
      f.ExecuteDefaultCommand;
      Result:= true;
      exit;
    finally
      f.Free;
    end;

  Result:= false;
  if HandleAllocated then
  try

    if (FShellView<>nil) and FRoot.SamePIDL(f) then
    begin
      FShellView.Refresh;
      Result:= true;
      exit;
    end;

    WasFocused := IsChild(Handle, Windows.GetFocus);
    FStream:= nil;

    if (f<>nil) and not RSIsSpecialFolder(f.FFullIDList, CSIDL_INTERNET) then
      try
        RSOleCheck(CreateStreamOnHGlobal(GlobalAlloc(GMEM_MOVEABLE or
          GMEM_DISCARDABLE, 0), True, FStream));

        if RSOleCheck(f.ShellFolder.CreateViewObject(Handle,
                         IID_IShellView, View)) <> S_OK then
          exit;

        with FolderSettings do
        begin
          ViewMode:= Byte(ViewStyle) + 1;
          fFlags:= FWF_NOCLIENTEDGE;
          if not FMultiSelect then  inc(fFlags, FWF_SINGLESEL);
          if not FHideSelection then  inc(fFlags, FWF_SHOWSELALWAYS);
          if FAutoArrange then  inc(fFlags, FWF_AUTOARRANGE);
          if FIconsArrangement = iaLeft then  inc(fFlags, FWF_ALIGNLEFT);
        end;

        r:= ClientRect;

        if RSOleCheck(View.CreateViewWindow(FShellView, FolderSettings,
                        Self as IShellBrowser, r, SVHandle)) <> S_OK then
          exit;

        View.QueryInterface(IFolderView, fv);
        EnumPropsEx(Handle, @EnumPropsProc, int(self));
      except
        on e:EOleSysError do
        begin
          FShellBrowser.ShowException(e);
          exit;
        end;
      end
    else
      SVHandle:=0;

    Result:= true;
    zSwap(f, FRoot);
    zSwap(View, FShellView);
    FFolderView:= fv;
    if FShellView<>nil then
      FNotifier.SetOptions(FRoot.FullName)
    else
      FNotifier.Cancel;

    if View <> nil then
    begin
      if FDefShellViewProc<>nil then
        SetWindowLong(FShellViewHandle, GWL_WNDPROC, int(FDefShellViewProc));
      if FDefListViewProc<>nil then
        SetWindowLong(FListViewHandle, GWL_WNDPROC, int(FDefListViewProc));
      View.DestroyViewWindow;
    end;
    FShellViewHandle:=SVHandle;

    if FShellView<>nil then
    begin
      FShellView.UIActivate(1);
      FListViewHandle:= FindWindowEx(FShellViewHandle, 0, WC_LISTVIEW, nil);
      FDefListViewProc:=
        ptr(SetWindowLong(FListViewHandle, GWL_WNDPROC, int(FListViewInstance)));
      FDefShellViewProc:=
        ptr(SetWindowLong(FShellViewHandle, GWL_WNDPROC, int(FShellViewInstance)));

      if FindFile<>nil then
        FShellView.SelectItem(FindFile.PIDL,
           SVSI_SELECT or SVSI_FOCUSED or SVSI_ENSUREVISIBLE);
           
      if WasFocused then
        Windows.SetFocus(FShellViewHandle);
    end else
      FListViewHandle:= 0;

  finally
    if f<>FRoot then
      f.Free;

    if Result and (f<>FRoot) and Assigned(OnFolderChanged) then
      OnFolderChanged(self);

  end else
    if FRoot<>f then
    begin
      zSwap(FRoot, f);
      f.Free;
    end;
end;

function TRSShellView.GetViewStyle: TRSShellViewStyle;
var a:TFolderSettings;
begin
  if (FShellView <> nil) and (FShellView.GetCurrentInfo(a) = S_OK) then
    Byte(FViewStyle):= a.ViewMode - 1;
  Result:= FViewStyle;
end;

procedure TRSShellView.SetViewStyle(v: TRSShellViewStyle);
begin
  FViewStyle:= v;
  if FFolderView<>nil then
    FFolderView.SetCurrentViewMode(Byte(v) + 1)
  else
    DoBrowse(FRoot);
end;

function TRSShellView.Browse(const Path: string):Boolean;
var f:TRSShellFolder;
begin
  f:= FShellBrowser.Browse(FRoot, Path);
  Result:= (f<>nil) and DoBrowse(ptr(f));
end;

function TRSShellView.Browse(SpecialFolderCSIDL:int = CSIDL_DESKTOP):Boolean;
var f:TRSShellFolder;
begin
  f:= FShellBrowser.Browse(FRoot, SpecialFolderCSIDL);
  Result:= (f<>nil) and DoBrowse(ptr(f));
end;

function TRSShellView.Browse(const Item:IRSShellViewFile):Boolean;
var f:TRSShellFolder;
begin
  f:= FShellBrowser.Browse(FRoot, Item.GetSelf);
  Result:= (f<>nil) and DoBrowse(ptr(f));
end;

procedure TRSShellView.TranslateWndProc(var Msg: TMessage);
var b:Boolean;
begin
  if Assigned(FProps.OnWndProc) then
  begin
    b:=false;
    FProps.OnWndProc(Self, Msg, b, WndProc);
    if b then exit;
  end;
  WndProc(Msg);
end;

procedure TRSShellView.WndProc(var Msg: TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
end;

function TRSShellView.GetPIDL(Index: Integer;
  var PIDL: PItemIDList): Boolean;
var a:TLVItem; i:int;
begin
  if FFolderView <> nil then
    Result:= FFolderView.Item(Index, PIDL) = S_OK
  else
    if FShellView<>nil then
      with a do
      begin
        iItem:= Index;
        iSubItem:= 0;
        mask:= LVIF_PARAM;
        Result:= ListView_GetItem(FListViewHandle, a);
        if Result then
        begin
          i:=RSGetPIDLSize(ptr(a.lParam));
          PIDL:=CoTaskMemAlloc(i);
          CopyMemory(PIDL, ptr(a.lParam), i);
        end;
      end
    else
      Result:= false;
end;

function TRSShellView.GetItem(Index: Integer): IRSShellViewFile;
var p: PItemIDList;
begin
  if GetPIDL(Index, p) then
    Result:= TRSShellViewFile.Create(self, p)
  else
    Result:= nil;
end;

function TRSShellView.GetSelected: IRSShellViewFile;
var i:int;
begin
  if (FFolderView <> nil) and GetSelectedIndex(i) then
    Result:= Items[i]
  else
    Result:= nil;
end;

procedure TRSShellView.SetSelected(v:IRSShellViewFile);
begin
  if FShellView<>nil then
    RSOleCheck(FShellView.SelectItem(v.PIDL,
       SVSI_FOCUSED or SVSI_SELECT or SVSI_DESELECTOTHERS));
end;

function TRSShellView.GetSelectedIndex(var Index: Integer): Boolean;
var i:int;
begin
  i:= ListView_GetNextItem(FListViewHandle, -1, LVIS_SELECTED or LVIS_FOCUSED);
  Result:= i>=0;
  if Result then
    Index:= i;
end;

function TRSShellView.GetItemsCount: Integer;
begin
  if (FFolderView = nil) or
     (FFolderView.ItemCount(SVGIO_ALLVIEW, Result) <> S_OK) then
    if FShellViewHandle<>0 then
      Result:= ListView_GetItemCount(FListViewHandle)
    else
      Result:= 0;
end;

function TRSShellView.GetSelCount: Integer;
begin
  if (FFolderView = nil) or
     (FFolderView.ItemCount(SVGIO_SELECTION, Result) <> S_OK) then
    if FShellViewHandle<>0 then
      Result:= ListView_GetSelectedCount(FListViewHandle)
    else
      Result:= 0;
end;

function TRSShellView.SelectedItems: IRSShellViewEnumItems;
var Enum:IEnumIDList;
begin
  if FFolderView<>nil then
    RSOleCheck(FFolderView.Items(SVGIO_SELECTION, IID_IEnumIDList, Enum));

  Result:= TRSShellViewEnumItems.Create(self, SelCount, Enum);
end;

procedure TRSShellView.SetHideSelection(v: Boolean);
begin
  if v = FHideSelection then  exit;
  FHideSelection:= v;
  DoBrowse(FRoot);
end;

procedure TRSShellView.SetMultiSelect(v: Boolean);
begin
  if v = FMultiSelect then  exit;
  FMultiSelect:= v;
  DoBrowse(FRoot);
end;

procedure TRSShellView.SetShowAllFiles(v: Boolean);
begin
  if v = FShowAllFiles then  exit;
  FShowAllFiles:= v;
  DoBrowse(FRoot);
end;

procedure TRSShellView.SetIconsArrangement(v: TIconArrangement);
begin
  if v = FIconsArrangement then  exit;
  FIconsArrangement:= v;
  DoBrowse(FRoot);
end;

procedure TRSShellView.SetAutoArrange(v: Boolean);
begin
  if v = FAutoArrange then  exit;
  FAutoArrange:= v;
  DoBrowse(FRoot);
end;

procedure TRSShellView.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (FRoot = nil) or not HandleAllocated then  exit;

  if Key = VK_BACK then
  begin
    Back;
    Key:=0;
  end;
end;

procedure TRSShellView.WMLButtonDown(var Msg: TWMLButtonDown);
begin
  inherited;
  if FShellView = nil then
    SetFocus;
end;

procedure TRSShellView.RefreshFolder;
begin
  if FShellView<>nil then
    FShellView.Refresh;
end;

procedure TRSShellView.DoNeedRefresh(Sender: TObject);
var Handled: Boolean;
begin
  if FRoot = nil then  exit;
  FNeedRefresh:= true;
  Handled:= false;
  if Assigned(FOnCanRefresh) then
    FOnCanRefresh(self, Handled);
  if (not Handled and FAutoRefresh) or not FRoot.Exists then
    RefreshFolder;
end;

function TRSShellView.GetNeedRefresh: Boolean;
begin
  Result:= (FNeedRefresh or FNotifier.NeedRefresh) and HandleAllocated;
end;

function TRSShellView.GetPath: string;
begin
  if Root<>nil then
    Result:= Root.FullName([RSForParsing, RSForAddressBar])
  else
    Result:='';
end;

procedure TRSShellView.Clear;
begin
  DestroyView;
  FreeAndNil(FRoot);
end;

procedure TRSShellView.DestroyView;
begin
  if FShellView <> nil then
  begin
    FNotifier.Cancel;
    SetWindowLong(FShellViewHandle, GWL_WNDPROC, int(FDefShellViewProc));
    SetWindowLong(FListViewHandle, GWL_WNDPROC, int(FDefListViewProc));
    FShellView.DestroyViewWindow;
    FShellView:= nil;
    FFolderView:= nil;
  end;
end;

procedure TRSShellView.ShowException(e: Exception);
var Msg:string;
begin
  Msg := e.Message;
  if (Msg <> '') and (AnsiLastChar(Msg) > '.') then  Msg := Msg + '.';
  Application.MessageBox(PChar(Msg), PChar(Application.Title),
     MB_ICONINFORMATION);
end;

end.
