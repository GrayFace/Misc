unit RSShellListView;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 RSShellListView is based on TListView and thus is fully controlable, but
  everything is implemented manually. It doesn't support vsReport style and
  Drag&Drop yet.
 RSShellListView can work on Win9x, but cannot show images without MSLU,
  while RSShellView approach doesn't work without MSLU at all.
 RSShellView supports thumbnails, pretty selection rect, groups in 'My computer'
 RSShellListView supports '..' item, Cancel button and works faster

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Windows, Messages, SysUtils, Classes, ComObj, ShlObj, ShellAPI, CommCtrl,
  RSShellBrowse, RSSysUtils, RSListView, ComCtrls, Controls, Forms, Math, RSQ,
  ActiveX, RSUtils, Graphics, RSGraphics, StdCtrls, RSShellCtrls, RSCommon;

{ TODO :
Может быть, подменять Idle, в нем слать мессагу и ставить Done:=true
Button Settings
Report style
Enum objects in different thread ? or only set cursor in another thread
Drag&Drop
IQueryInfo ?
}

type
  TRSShellListView = class;

  TRSShellObjectTypes = set of
    (RSotFolders, RSotNonFolders, RSotHidden, RSotBack);
  TRSShellListViewOpenFileEvent = procedure(Sender: TRSShellListView;
    AFile: TRSShellFile; var Handled: Boolean) of object;

  TRSShellListViewHotKeys = set of (RSskBack, RSskDelete, RSskAltEnter,
    RSskCtrlA, RSskCopy, RSskPaste, RSskCut, RSskF5, RSskCtrlR, RSskF2);

  TRSShellListView = class(TRSListView)
  private
    FAutoContextPopup: Boolean;
    FAutoRefresh: Boolean;
    FHotKeys: TRSShellListViewHotKeys;
    FOnFolderChanged: TNotifyEvent;
    FOnCanRefresh: TRSApproveEvent;
    FOnOpenFile: TRSShellListViewOpenFileEvent;
    FOnBack: TRSApproveEvent;
    FOnCompare: TRSShellFolderCompareEvent;
    FOnCanAddItem: TRSShellFolderCanAddEvent;
    FButtonWidth: int;
    FButtonHeight: int;
    FButtonCaption: string;

    function GetFiles: TRSShellFilesArray;
    function GetNeedRefresh: Boolean;
    procedure SetObjectTypes(v: TRSShellObjectTypes);
    function GetPath: string;
    procedure SetOnCanAddItem(const Value: TRSShellFolderCanAddEvent);
    procedure SetOnCompare(const Value: TRSShellFolderCompareEvent);
    function GetRoot: TRSShellFolder;
  protected
    FRoot: TRSShellFolder;
    FNewRoot: TRSShellFolder;
    FNotifier: TRSShellChangeNotifier;
    FLastRoot: TRSShellFolder;
    FLastNotifier: TRSShellChangeNotifier;
    FLastColumnWidth: int;
    FShellBrowser: TRSShellBrowser;
    FNeedRefresh: Boolean;
    FBlockNotification: Byte; // 2 = Block, 1 = Was Blocked, 0 = Refreshed
    FObjectTypes: TRSShellObjectTypes;
    FColumnWidth: int;

    FEnumDelay: uint;
    FEnumButton: TButton;
    FEnumSaveCursor: TCursor;
    FEnumSaveFocus: HWnd;
    FEnumStart: uint;
    FEnumAction: uint;

    FBackgroundColumnWidth: int;
    FBackgroundFile: int;
    FBackgroundAction: Boolean;
    FNeedIcons: Boolean;
    FNeedIcon: array of Boolean;

    FNothing: string;

    procedure CreateWnd; override;
    procedure DestroyWnd; override;

    function DoBrowse(f:TRSShellFolder; FindFile:TRSShellFile = nil):Boolean;
    procedure DoRefresh(FindFile:TRSShellFile = nil);
    function DoEnumFiles(f:TRSShellFolder):Boolean;
    procedure ShellFolderLoadFile(Sender:TRSShellFolder;
      SortedCount, EnumeratedCount:int; var Proceed:Boolean);

    procedure DoNeedRefresh(Sender:TObject);
    procedure LastNotifierChange(Sender:TObject);
    procedure Back;
    procedure ShowProperties;
    procedure DoExecuteCommand(const s:string; CM:IContextMenu = nil;
      Cmd:int = -1);
    procedure DoRename(i:int; const s:WideString);
    function GetSelContextMenu: IContextMenu;

    function DoCompare(Sender:TObject; Folder:TRSShellFolder;
      f1, f2:TRSShellFile; var Column:int; var Inverse:Boolean): Integer;
    procedure DoCanAdd(Sender:TObject; ShellFile:TRSShellFile;
      var CanAdd:Boolean);
    function CanShowBack(f:TRSShellFolder): Boolean; virtual;

    procedure SetRootProps(f:TRSShellFolder); virtual;
    function SameRootProps(f1, f2:TRSShellFolder):Boolean; virtual;

    procedure NeedBackgrounAction;
    function BackgrounAction: Boolean;

    procedure CalcColSize(SelIndex:int);
    function OwnerDataFetch(Item: TListItem; Request: TItemRequest): Boolean; override;
    function OwnerDataFind(Find: TItemFind; const FindString: string;
      const FindPosition: TPoint; FindData: Pointer; StartIndex: Integer;
      Direction: TSearchDirection; Wrap: Boolean): Integer; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DblClick; override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
    procedure CNSysKeyDown(var Msg: TWMKeyDown); message CN_SYSKEYDOWN;
    function CanEdit(Item: TListItem): Boolean; override;
    procedure Edit(const Item: TLVItem); override;
    procedure CNNotify(var Msg: TWMNotify); message CN_NOTIFY;
    procedure LVMSetColumnWidth(var Msg: TMessage); message LVM_SETCOLUMNWIDTH;
    procedure DoDrawItem(var a:TNMCustomDraw);
    procedure WMPaint(var Msg:TWMPaint); message WM_PAINT;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Browse(const Path:string):Boolean; overload;
    function Browse(SpecialFolderCSIDL:int = CSIDL_DESKTOP):Boolean; overload;
    function Browse(ShellFile: TRSShellFile):Boolean; overload;
    procedure Clear; override;
    function ShowContextPopup(MousePos: TPoint; Default: string = '';
      NoSeparator:Boolean = false):Boolean;
    procedure OpenFile;
    property Root: TRSShellFolder read GetRoot;
    property Files: TRSShellFilesArray read GetFiles;
    function SelectedFile: TRSShellFile;

    procedure RefreshFolder(FlushCache:Boolean = false);
    procedure ExecuteCommand(const Command:string);
    property Path: string read GetPath;
    property NeedRefresh: Boolean read GetNeedRefresh;
  published
    property AutoContextPopup: Boolean read FAutoContextPopup write FAutoContextPopup default true;
    property AutoRefresh: Boolean read FAutoRefresh write FAutoRefresh default false;
    property ObjectTypes: TRSShellObjectTypes read FObjectTypes write SetObjectTypes default [RSotFolders, RSotNonFolders, RSotHidden, RSotBack];
    property HotKeys: TRSShellListViewHotKeys read FHotKeys write FHotKeys default [RSskBack, RSskDelete, RSskAltEnter, RSskCtrlA, RSskCopy, RSskPaste, RSskCut, RSskF5, RSskCtrlR, RSskF2];

    property ButtonCaption: string read FButtonCaption write FButtonCaption;
    property ButtonWidth: int read FButtonWidth write FButtonWidth default 100;
    property ButtonHeight: int read FButtonHeight write FButtonHeight default 50;

    property OnOpenFile: TRSShellListViewOpenFileEvent read FOnOpenFile write FOnOpenFile;
    property OnBack: TRSApproveEvent read FOnBack write FOnBack;
    property OnFolderChanged: TNotifyEvent read FOnFolderChanged write FOnFolderChanged;
    property OnCanRefresh: TRSApproveEvent read FOnCanRefresh write FOnCanRefresh;
    property OnCompare: TRSShellFolderCompareEvent read FOnCompare write SetOnCompare;
    property OnCanAddItem: TRSShellFolderCanAddEvent read FOnCanAddItem write SetOnCanAddItem;

     // Yes, this isn't good, but inheriting from TCustom* means publishing all
     // the needed properties which change from version to version.
    property OwnerData: string read FNothing;
    property LargeImages: string read FNothing;
    property SmallImages: string read FNothing;
    property StateImages: string read FNothing;
    property SortType: string read FNothing;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSShellListView]);
end;

const
  ColPadding = 28;
  ColMinSize = 112;
  AListColumnSize = MaxInt;
  ABackgroundAction = MaxInt - 1;


{ TRSShellListViewButton }

type
  TRSShellListViewButton = class(TButton)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMLButtonUp(var Msg:TWMLButtonUp); message WM_LButtonUp;
    procedure WMKeyDown(var Msg:TWMKey); message WM_KeyDown;
    procedure WMKeyUp(var Msg:TWMKey); message WM_KeyUp;
  public
    Proceed: Boolean;
  end;

  
procedure TRSShellListViewButton.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style:= Params.Style or BS_MULTILINE;
end;

procedure TRSShellListViewButton.WMLButtonUp(var Msg: TWMLButtonUp);
begin
  inherited;
  with Msg do
    if (XPos >= 0) and (XPos < Width) and (YPos >= 0) and (YPos < Height) then
      Proceed:= false;
end;

procedure TRSShellListViewButton.WMKeyDown(var Msg: TWMKey);
begin
  inherited;
  with Msg do
    if CharCode in [VK_ESCAPE, VK_RETURN] then
      Proceed:= false;
end;

procedure TRSShellListViewButton.WMKeyUp(var Msg:TWMKey);
begin
  inherited;
  with Msg do
    if CharCode = VK_SPACE then
      Proceed:= false;
end;

{
******************************* TRSShellListView *******************************
}

constructor TRSShellListView.Create(AOwner: TComponent);
begin
  inherited;
  FHotKeys:= [RSskBack, RSskDelete, RSskAltEnter, RSskCtrlA, RSskCopy,
     RSskPaste, RSskCut, RSskF5, RSskCtrlR, RSskF2];
  FAutoContextPopup:= true;
  FObjectTypes:= [RSotFolders, RSotNonFolders, RSotHidden, RSotBack];
  FNotifier:= TRSShellChangeNotifier.Create(nil);
  FLastNotifier:= TRSShellChangeNotifier.Create(nil);
  FShellBrowser:= TRSShellBrowser.Create;
  FShellBrowser.ShellFolderClass:= TRSShellFolder;
  inherited OwnerData:= true;
  FEnumButton:= TRSShellListViewButton.Create(self);
  FEnumButton.Visible:= false;
  FEnumDelay:= 3000;
  FButtonCaption:= 'Cancel';
  FButtonWidth:= 100;
  FButtonHeight:= 50;
end;

destructor TRSShellListView.Destroy;
begin
  FShellBrowser.Free;
  FNotifier.Free;
  FLastNotifier.Free;
  FEnumButton.Free;
  FRoot.Free;
  inherited;
end;

procedure TRSShellListView.ShellFolderLoadFile(Sender: TRSShellFolder;
  SortedCount, EnumeratedCount: int; var Proceed: Boolean);
var
  r:TRect; Msg:TMsg; j:uint;
begin
  j:= GetTickCount;
  if j <= FEnumAction then  exit;
  if FEnumStart = FEnumAction then
  begin
    if FEnumSaveCursor = crHourGlass then
      SetCursor(Screen.Cursors[crDefault])
    else
      SetCursor(Screen.Cursors[FEnumSaveCursor]);

    FEnumButton.Parent:= self;
     // Use text to calculate the width
    r:= ClientRect;
    if FButtonWidth < r.Right then
    begin
      r.Left:= (r.Right - FButtonWidth) div 2;
      r.Right:= r.Left + FButtonWidth;
    end;
    if FButtonHeight < r.Bottom then
    begin
      r.Top:= (r.Bottom - FButtonHeight) div 2;
      r.Bottom:= r.Top + FButtonHeight;
    end;
    FEnumButton.BoundsRect:= r;
    FEnumButton.Show;
    TRSShellListViewButton(FEnumButton).Proceed:= true;
    FEnumButton.SetFocus;
  end;
  FEnumAction:= j + 10;

  FEnumButton.Caption:= IntToStr(SortedCount) +'/'+ IntToStr(EnumeratedCount) +
       #13#10 + FButtonCaption;

  while PeekMessage(Msg, FEnumButton.Handle, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
  Proceed:= TRSShellListViewButton(FEnumButton).Proceed;
end;

function TRSShellListView.DoEnumFiles(f: TRSShellFolder):Boolean;
begin
  FEnumSaveCursor:= Screen.Cursor;
  FEnumSaveFocus:= GetFocus;
  SetCursor(Screen.Cursors[crHourglass]);
  try
    f.ClearFiles;
    if CanShowBack(f) then  SetLength(f.Files, 1);
    FEnumStart:= GetTickCount + FEnumDelay;
    FEnumAction:= FEnumStart;
    Result:= false;
    try
      Result:= f.EnumFiles(
        Byte(ObjectTypes*[RSotFolders, RSotNonFolders, RSotHidden])*32, true);
    except
      on e:EOleSysError do
      begin
        FShellBrowser.ShowException(e);
        exit;
      end;
      on e:Exception do
        raise;
    end;
  finally
    SetCursor(Screen.Cursors[FEnumSaveCursor]);
  end;
  
  if FEnumButton.HandleAllocated  then
    Windows.SetFocus(FEnumSaveFocus);
  FEnumButton.Visible:= false;
  FEnumButton.Parent:= nil;
end;

function TRSShellListView.DoBrowse(f:TRSShellFolder; FindFile:TRSShellFile = nil):Boolean;
var
  i:int;
begin
  Result:= FNewRoot = nil;
  if not Result then  exit;

  if not f.IsFolder then
    try
      f.ExecuteDefaultCommand;
      exit;
    finally
      f.Free;
    end;

  if not HandleAllocated then
  begin
    if FRoot<>f then
    begin
      zSwap(FRoot, f);
      f.Free;
    end;
    exit;
  end;

  if (FRoot<>nil) and FRoot.SamePIDL(f) then
    try
      if (f = FRoot) or (f = FLastRoot) then
        f:=nil;
      if (FNeedRefresh or FNotifier.NeedRefresh) and (FBlockNotification<2) then
        DoRefresh(FindFile);
      exit;
    finally
      f.Free;
    end;

  SetRootProps(f);

  if f.SamePIDL(FLastRoot) and SameRootProps(f, FLastRoot) then
  begin
    f.Free;
    f:= FLastRoot;
  end;

  Result:= false;
  FNewRoot:=f;
  try
    if (f<>FLastRoot) and (f<>nil) then
    begin
      Result:= DoEnumFiles(f);
      if not Result then  exit;
      zSwap(FLastRoot, f);
    end else
      Result:= true;

    zSwap(FRoot, FLastRoot);
    FNeedRefresh:= false;
    zSwap(FNotifier, FLastNotifier);
    FNotifier.OnChange:= DoNeedRefresh;
    FLastNotifier.OnChange:= LastNotifierChange;
    FNotifier.SetOptions(FRoot.FullName);
    FNeedIcons:= false;
    FNeedIcon:= nil;
    SetLength(FNeedIcon, length(Files));

    if FindFile<>nil then
      i:=FRoot.FindShellFile(FindFile)
    else
      i:=-1;

    FNewRoot:= nil;
    Items.BeginUpdate;
    try
      Items.Count:=0; // Important. OwnerDataFetch is called otherwise
      ListView_DeleteAllItems(Handle); // Refresh columns sizes.
        // Don't work after customizing ColumnWidth

      Items.Count:= length(FRoot.Files);

      FBackgroundFile:= MaxInt;
      if f <> FRoot then
      begin
        FLastColumnWidth:= FColumnWidth;
        FColumnWidth:= ColMinSize;
        if ViewStyle = vsList then
          CalcColSize(i);
      end else
      begin
        zSwap(FColumnWidth, FLastColumnWidth);
        ListView_SetColumnWidth(Handle, 0, FColumnWidth);
      end;

      if i>=0 then
      begin
        ListView_SetItemState(Handle, i, LVIS_SELECTED or LVIS_FOCUSED,
                                         LVIS_SELECTED or LVIS_FOCUSED);
        ListView_EnsureVisible(Handle, i, false);
      end else
      begin
        i:= LVIS_FOCUSED;
        if (FindFile=nil) and (FRoot.Files<>nil) and (FRoot.Files[0]=nil) then
          i:= i or LVIS_SELECTED;
        ListView_SetItemState(Handle, 0, i, i);
        ListView_EnsureVisible(Handle, 0, false);
      end;

    finally
      Items.EndUpdate;

      FBackgroundFile:= 0;
      FBackgroundColumnWidth:= FColumnWidth;
      NeedBackgrounAction;
    end;
  finally
    FNewRoot:= nil;
    if f<>FRoot then
      f.Free;
    if Result and Assigned(OnFolderChanged) then
      OnFolderChanged(self);
  end;
end;

procedure TRSShellListView.DoRefresh(FindFile:TRSShellFile = nil);
var
  Sel: array of int;
  i,j,k:int;
  f: TRSShellFolder;
begin
  if (FRoot = nil) or not HandleAllocated or (FNewRoot<>nil) then  exit;
  if not FRoot.Exists then
    with FRoot do
      try
        FRoot:= nil;
        Items.Count:=0;
        FNotifier.Cancel;

        f:= TRSShellFolder(CreateParentFolder(TRSShellFolder));
        try
          while not f.Exists do
            with f do
            begin
              f:= TRSShellFolder(CreateParentFolder(TRSShellFolder));
              Free;
            end;
        except
          f.Free;
          f:= TRSShellFolder.Create;
        end;
        DoBrowse(f);
        exit;
      finally
        Free;
      end;

  f:=nil;
  try
    f:= TRSShellFolder.Create(FRoot);
    SetRootProps(f);

    if not DoEnumFiles(f) then  exit;
    zSwap(f, FRoot);
    FNeedRefresh:= false;
    FNotifier.Reset;
    FNeedIcons:= false;
    FNeedIcon:= nil;
    SetLength(FNeedIcon, length(Files));
    i:=-1;
    if FindFile = nil then
    begin
      k:=ListView_GetNextItem(Handle, -1, LVIS_FOCUSED);
      if k<>-1 then
      begin
        i:= FRoot.FindShellFile(f.Files[k]);
        if i<>k then
          ListView_SetItemState(Handle, k, 0, LVIS_FOCUSED);
        if i<0 then
          i:= not i;  
      end;

      SetLength(Sel, SelCount);
      j:=0;
      k:= ListView_GetNextItem(Handle, -1, LVIS_SELECTED);
      while k<>-1 do
      begin
        if f.Files[k] <> nil then
        begin
          Sel[j]:=FRoot.FindShellFile(f.Files[k]);
          ListView_SetItemState(Handle, k, 0, LVIS_SELECTED or LVIS_FOCUSED);
          inc(j);
        end else
          if FRoot.Files[k] <> nil then
            ListView_SetItemState(Handle, k, 0, LVIS_SELECTED or LVIS_FOCUSED);
        k:=ListView_GetNextItem(Handle, k, LVIS_SELECTED);
      end;
      SetLength(Sel, j);

       // If there's no focused item, focus the last selected item
      if i<0 then
        for j:= j-1 downto 0 do
          if Sel[j]>i then
            i:=Sel[j];

    end else
    begin
      i:=FRoot.FindShellFile(FindFile);
      if i>=0 then
      begin
        SetLength(Sel, 1);
        Sel[0]:= i;
      end else
        i:= not i;
    end;
    FBackgroundFile:= MaxInt;
    Items.BeginUpdate;
    try
      Items.Count:= length(FRoot.Files);

      for j:=length(Sel)-1 downto 0 do
        ListView_SetItemState(Handle, Sel[j], LVIS_SELECTED, LVIS_SELECTED);

      ListView_EnsureVisible(Handle, i, false);
      ListView_SetItemState(Handle, i, LVIS_FOCUSED, LVIS_FOCUSED);

      if Assigned(FOnFolderChanged) then
        FOnFolderChanged(self);

    finally
      Items.EndUpdate;
      if ViewStyle = vsList then
      begin
        FBackgroundFile:= 0;
        FBackgroundColumnWidth:= FColumnWidth;
        NeedBackgrounAction;
      end;
      FRoot.CreateIconsThread;
    end;
  finally
    f.Free;
  end;
end;

function TRSShellListView.Browse(const Path: string):Boolean;
var f:TRSShellFolder;
begin
  f:= FShellBrowser.Browse(FRoot, Path);
  Result:= (f<>nil) and DoBrowse(f);
end;

function TRSShellListView.Browse(SpecialFolderCSIDL:int = CSIDL_DESKTOP):Boolean;
var f:TRSShellFolder;
begin
  f:= FShellBrowser.Browse(FRoot, SpecialFolderCSIDL);
  Result:= (f<>nil) and DoBrowse(f);
end;

function TRSShellListView.Browse(ShellFile: TRSShellFile):Boolean;
var f:TRSShellFolder;
begin
  f:= FShellBrowser.Browse(FRoot, ShellFile);
  Result:= (f<>nil) and DoBrowse(f);
end;

procedure TRSShellListView.Clear;
begin
  if FNewRoot <> nil then  exit;
  FNotifier.Cancel;
  if HandleAllocated then
  begin
    Items.Count:=0;
    ListView_DeleteAllItems(Handle);
    InvalidateRect(Handle, nil, true);
  end;
  FreeAndNil(FRoot);
end;

procedure TRSShellListView.Back;
var f:TRSShellFolder; Handled:Boolean;
begin
  if (FRoot = nil) or (FNewRoot <> nil) then
    exit;

  Handled:=false;
  if Assigned(FOnBack) then  FOnBack(self, Handled);
  if Handled then  exit;

  try
    f:= TRSShellFolder(FRoot.CreateParentFolder(TRSShellFolder));
  except
    DoRefresh;
    exit;
  end;
  if f<>nil then
    DoBrowse(f, FRoot);
end;

procedure TRSShellListView.OpenFile;
var f:TRSShellFile; Handled:Boolean; i:int;
begin
  if (FNewRoot <> nil) or not GetSelectedIndex(i) then  exit;
  f:=FRoot.Files[i];
  if f = nil then
  begin
    Back;
    exit;
  end;

  Handled:=false;
  if Assigned(FOnOpenFile) then  FOnOpenFile(self, f, Handled);
  if Handled then  exit;

  if f.IsFolder then
    Browse(f)
  else
    f.ExecuteDefaultCommand;
end;

function TRSShellListView.ShowContextPopup(MousePos: TPoint;
   Default: string = ''; NoSeparator:Boolean = false):Boolean;
var
  i:int; CM:IContextMenu; s:string;
begin
  Result:=false;
  if FNewRoot <> nil then  exit;
  with MousePos do
    if GetExactItemAt(X, Y) = nil then  exit;
  CM:=GetSelContextMenu;
  if CM = nil then  exit;

  Windows.ClientToScreen(Handle, MousePos);
  i:= RSOpenContextMenu(Handle, CM, MousePos, not ReadOnly,
         Default, NoSeparator);
  Result:= i = -1;
  if i>0 then
  begin
    dec(i);
    s:=RSGetCommandVerb(CM, i);
    DoExecuteCommand(s, CM, i);
  end;
end;

procedure TRSShellListView.ShowProperties;
begin
  ExecuteCommand('properties');
end;

procedure TRSShellListView.ExecuteCommand(const Command:string);
begin
  DoExecuteCommand(Command);
end;

procedure TRSShellListView.DoExecuteCommand(const s:string;
   CM:IContextMenu = nil; Cmd:int = -1);

  function DoExec:Boolean;
  begin
    if CM = nil then
      CM:=GetSelContextMenu;

    if CM = nil then
      Result:=false
    else  
      if Cmd<0 then
        Result:= RSContextMenuVerb(Handle, CM, ptr(s))
      else
        Result:= RSContextMenuVerb(Handle, CM, Cmd);
  end;

var k:int;
begin
  if (FNewRoot <> nil) or (FRoot = nil) then  exit;
  if SameText(s, 'delete') or SameText(s, 'link') then
    try
      FBlockNotification:= 255;
      if DoExec then
        RefreshFolder // Success doesn't always mean that the file is deleted
      else
        if FBlockNotification <> 0 then
          if FBlockNotification < 255 then
          begin
            FBlockNotification:=0;
            DoNeedRefresh(nil);
          end else
            FBlockNotification:=0;
    finally
      FBlockNotification:= 0;
    end
  else
    if not SameText(s, 'rename') then
      DoExec
    else
      if GetSelectedIndex(k) then
        ListView_EditLabel(Handle, k);
end;

procedure TRSShellListView.DoRename(i:int; const s:WideString);
var f:TRSShellFile;
begin
  if (FNewRoot <> nil) or (FRoot.Files[i] = nil) then  exit;
  f:=FRoot.Files[i].Rename(s);
  if f = nil then  exit;
  try
    DoRefresh(f);
  finally
    f.Free;
  end;
end;

procedure TRSShellListView.CNSysKeyDown(var Msg: TWMKeyDown);
begin
  if (Msg.CharCode = VK_RETURN) and (RSskAltEnter in FHotKeys) then
  begin
    Msg.Result:= 1;
    ShowProperties;
  end else
    inherited;
end;

function TRSShellListView.CanEdit(Item: TListItem): Boolean;
begin
  if Item = nil then  Item:= SelectedItem;
  Result:= (Item <> nil) and (FRoot.Files[Item.Index]<>nil) and
           (FRoot.Files[Item.Index].GetAttributes(SFGAO_CANRENAME) <> 0);
  if Result and Assigned(OnEditing) then  OnEditing(Self, Item, Result);
end;

procedure TRSShellListView.CNNotify(var Msg: TWMNotify);
var h:HWnd;
begin
  with Msg do
    case NMHdr^.code of
      LVN_BEGINLABELEDIT:
      begin
        inherited;
        if Result = 0 then
          with PLVDispInfo(NMHdr)^.item do
          begin
            h:=ListView_GetEditControl(Handle);
            if (h<>0) and (FRoot.Files[iItem]<>nil) then
              TRSWnd(h).Text:= FRoot.Files[iItem].ShortName([RSForEditing]);
          end;
      end;
      NM_CUSTOMDRAW:
        with PNMCustomDraw(NMHdr)^ do
        begin
          if dwDrawStage and (CDDS_POSTPAINT or CDDS_ITEM or CDDS_SUBITEM) =
                             (CDDS_POSTPAINT or CDDS_ITEM) then
            DoDrawItem(PNMCustomDraw(NMHdr)^);

          inherited;

          if dwDrawStage and CDDS_PREPAINT = CDDS_PREPAINT then
            Result:= (Result or CDRF_NOTIFYITEMDRAW or CDRF_NOTIFYPOSTPAINT)
                       and not CDRF_DODEFAULT;
        end;
    else
      inherited;
  end;
end;

procedure TRSShellListView.Edit(const Item: TLVItem);
var
  s: string;
begin
  with Item do
  begin
    s:= pszText;
    if Assigned(OnEdited) then  OnEdited(self, SelectedItem, s);
    if s <> '' then
      DoRename(iItem, s);
  end;
end;

procedure TRSShellListView.DoContextPopup(MousePos: TPoint;
  var Handled: Boolean);
begin
  inherited;
  with MousePos do
    if AutoContextPopup and not Handled and (GetExactItemAt(X, Y) <> nil) then
    begin
      Handled:=true;
      ShowContextPopup(MousePos);
    end;
end;

procedure TRSShellListView.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if FRoot=nil then  exit;
  if ListView_GetEditControl(Handle) = 0 then
    case Key of
      VK_RETURN:
        if not (ssAlt in Shift) then
        begin
          OpenFile;
          Key:=0;
        end;
      VK_BACK:
        if (RSskBack in FHotKeys) then
        begin
          Back;
          Key:=0;
        end;
      VK_DELETE:
        if (RSskDelete in FHotKeys) and (Shift*[ssAlt, ssCtrl] = []) then
        begin
          ExecuteCommand('delete');
          Key:=0;
        end;
      ord('A'):
        if (Shift*[ssShift, ssAlt, ssCtrl] = [ssCtrl]) and
           (RSskCtrlA in FHotKeys) then
        begin
          SelectAll;
          if (length(Root.Files) > 1) and (Root.Files[0] = nil) then
            ListView_SetItemState(Handle, 0, 0, LVIS_SELECTED);
          Key:=0;
        end;
      VK_F5:
        if (Shift*[ssShift, ssAlt] = []) and (RSskF5 in FHotKeys) then
        begin
          RefreshFolder(true);
          Key:=0;
        end;
      ord('R'):
        if (Shift*[ssShift, ssAlt, ssCtrl] = [ssCtrl]) and
           (RSskCtrlR in FHotKeys) then
        begin
          RefreshFolder;
          Key:=0;
        end;
      VK_F2:
        if (Shift*[ssShift, ssAlt, ssCtrl] = []) and (RSskF2 in FHotKeys) then
        begin
          ExecuteCommand('rename');
          Key:=0;
        end;
      ord('C'):
        if (Shift*[ssShift, ssAlt, ssCtrl] = [ssCtrl]) and
           (RSskCopy in FHotKeys) then
        begin
          ExecuteCommand('copy');
          Key:=0;
        end;
      ord('V'):
        if (Shift*[ssShift, ssAlt, ssCtrl] = [ssCtrl]) and
           (RSskPaste in FHotKeys) then
        begin
          ExecuteCommand('paste');
          Key:=0;
        end;
      ord('X'):
        if (Shift*[ssShift, ssAlt, ssCtrl] = [ssCtrl]) and
           (RSskCut in FHotKeys) then
        begin
          ExecuteCommand('cut');
          Key:=0;
        end;
      VK_INSERT:
        if (Shift*[ssShift, ssAlt, ssCtrl] = [ssCtrl]) and
           (RSskCopy in FHotKeys) then
        begin
          ExecuteCommand('copy');
          Key:=0;
        end else
          if (Shift*[ssShift, ssAlt, ssCtrl] = [ssShift]) and
             (RSskPaste in FHotKeys) then
          begin
            ExecuteCommand('paste');
            Key:=0;
          end;
    end;
end;

procedure TRSShellListView.DblClick;
begin
  inherited;
  OpenFile;
end;

{
procedure TRSShellListView.CalcPadding;
const
  PadAdd = 8;
var
  HTInfo:TLVHitTestInfo; r:TRect;
  s:string;
begin
   // Calculate padding for vsList style. Needed to correct ColumnWidth
  if (ViewStyle = vsList) and (FRoot.Files<>nil) then
  begin
    ListView_GetItemRect(Handle, 0, r, LVIR_SELECTBOUNDS);
    HTInfo.pt := Point(r.Right, r.Top);
    repeat
      dec(HTInfo.pt.X);
    until (HTInfo.pt.X < r.Left) or
          (ListView_HitTest(Handle, HTInfo) <> -1) and
          (HTInfo.flags and LVHT_ONITEM <> 0);
    if FRoot.Files[0] = nil then
      s:= '..'
    else
      s:= FRoot.Files[0].ShortName;
    FPadding:= HTInfo.pt.X - r.Left + 1 + PadAdd -
                  ListView_GetStringWidth(Handle, ptr(s));
  end else
    FPadding:=0;
end;
}

procedure TRSShellListView.NeedBackgrounAction;
begin
  if not FBackgroundAction then
  begin
    FBackgroundAction:= true;
    PostMessage(Handle, LVM_SETCOLUMNWIDTH, ABackgroundAction, 0);
  end;
end;

function TRSShellListView.BackgrounAction: Boolean;
var i,j,k:int; r,r1:TRect;
begin
  if FNeedIcons then
    r1:= ClientRect;
    
  if ViewStyle in [vsList, vsReport] then
    i:= ListView_GetTopIndex(Handle)
  else
    i:= 0;

  if FNeedIcons then
    for i:= i to length(Froot.Files) - 1 do
      if FRoot.Files[i]<>nil then
        with FRoot.Files[i] do
          if FNeedIcon[i] then
          begin
            FNeedIcon[i]:=false;
            if not ListView_GetItemRect(Handle, i, r, LVIR_ICON) then
              continue;

            with r1 do
              if (r.Right <= 0) or (r.Bottom <= 0) or
                 (r.Left >= Right) or (r.Top >= Bottom) then
               if ViewStyle in [vsList, vsReport] then
                 break
               else
                 continue;

            j:= FRoot.Files[i].ImageIndex(false, true);
            k:= FRoot.Files[i].OverlayIconIndex(true);

            if (FRoot.Files[i].ImageIndex<>j) or
               (FRoot.Files[i].OverlayIconIndex(false)<>k) then
            begin
              ListView_RedrawItems(Handle, i, i);
              Result:= true;
              exit;
            end;

        end;

  FNeedIcons:= false;

  if FBackgroundFile < length(FRoot.Files) then
  begin
    with FRoot.Files[FBackgroundFile] do
      if GetSelf<>nil then
      begin
        if ViewStyle = vsList then
        begin
          i:= ListView_GetStringWidth(Handle, ptr(ShortName)) + ColPadding;
          if i > FBackgroundColumnWidth then
            FBackgroundColumnWidth:= i;
        end else
          ShortName;
          
        ImageIndex(false, true);
      end;
    inc(FBackgroundFile);
    Result:=true;
    exit;
  end;

  Result:= false;
end;

procedure TRSShellListView.CalcColSize(SelIndex:int);
var
  i,j:int; r:TRect;
begin
  j:= SelIndex;
  if j<0 then  j:=0;
  if not ListView_GetItemRect(Handle, j, r, LVIR_BOUNDS) then  exit;
  if Files = nil then  exit;
  dec(r.Bottom, r.Top);
  i:= (ClientHeight div r.Bottom)*((ClientWidth + r.Right - 1) div ColMinSize);

  for i:= min(j + i*2, length(Files)-1) downto max(0, j - i + 1) do
    if Files[i]<>nil then
    begin
      j:= ListView_GetStringWidth(Handle, ptr(Files[i].ShortName)) + ColPadding;
      if j>FColumnWidth then  FColumnWidth:=j;
    end;

  ListView_SetColumnWidth(Handle, 0, FColumnWidth);
end;

procedure TRSShellListView.LVMSetColumnWidth(var Msg: TMessage);
begin
  with Msg do
    case WParam of
      AListColumnSize:
        if (FNewRoot = nil) and (ViewStyle = vsList) and
           (LParam = FColumnWidth) then
        begin
          WParam:= 0;
          if FColumnWidth >= FBackgroundColumnWidth then
            FBackgroundColumnWidth:= FColumnWidth
          else
            FColumnWidth:= FBackgroundColumnWidth;
          LParam:= FColumnWidth;
        end else
          exit;

      ABackgroundAction:
      begin
        FBackgroundAction:= BackgrounAction;
        if FBackgroundAction then
        begin
          RSProcessMessages;
          PostMessage(Handle, LVM_SETCOLUMNWIDTH, ABackgroundAction, 0);
        end;
        exit;
      end;
{
      MaxInt - 1:
      begin
        FColumnWidthAsync:= ColPadding +
          ListView_GetStringWidth(Handle, ptr(Files[LParam].ShortName)) ;
      end;
}
    end;
  inherited;
end;

function TRSShellListView.OwnerDataFetch(Item: TListItem;
  Request: TItemRequest): Boolean;
var
  j:int;
begin
  Result:= true;
  if length(FRoot.Files)>Item.Index then
    with FRoot.Files[Item.Index] do
    begin
      if GetSelf <> nil then
      begin
        if irText in Request then  Item.Caption:= ShortName;
        if irImage in Request then
        begin
          Item.ImageIndex:= ImageIndex(false, true);
          if not ImageIndexReady(false) then
          begin
            FNeedIcons:= true;
            FNeedIcon[Item.Index]:= true;
            NeedBackgrounAction;
          end;
        end;

        if ViewStyle = vsList then
        begin
          j:= ListView_GetStringWidth(Handle, ptr(Item.Caption)) + ColPadding;
          if j>FColumnWidth then
          begin
            FColumnWidth:=j;
            PostMessage(Handle, LVM_SETCOLUMNWIDTH, AListColumnSize, j);
          end;
        end;

      end else
      begin
        if irText in Request then  Item.Caption:= '..';
        if irImage in Request then  Item.ImageIndex:= FRoot.ImageIndex(true);
      end;

    end;

  inherited OwnerDataFetch(Item, Request);
end;

function TRSShellListView.OwnerDataFind(Find: TItemFind;
  const FindString: string; const FindPosition: TPoint; FindData: Pointer;
  StartIndex: Integer; Direction: TSearchDirection;
  Wrap: Boolean): Integer;
begin
  Result:=-1;
  if Assigned(OnDataFind) then  OnDataFind(Self, Find, FindString,
    FindPosition, FindData, StartIndex, Direction, Wrap, Result);

  if (Result = -1) and (Find in [ifPartialString, ifExactString]) then
    Result:= FRoot.FindFile(FindString, StartIndex, Wrap);
end;

procedure TRSShellListView.RefreshFolder(FlushCache:Boolean = false);
begin
  if FlushCache then
    FRoot.FlushCache;
  DoRefresh;
end;

procedure TRSShellListView.DoNeedRefresh(Sender:TObject);
var Handled: Boolean;
begin
  if (FRoot = nil) or (FNewRoot<>nil) then  exit;
  if FBlockNotification > 0 then  dec(FBlockNotification);
  if FBlockNotification > 0 then  exit;
  FNeedRefresh:= true;
  Handled:= false;
  if Assigned(FOnCanRefresh) then
    FOnCanRefresh(self, Handled);
  if (not Handled and FAutoRefresh) or not FRoot.Exists then
    RefreshFolder;
end;

procedure TRSShellListView.LastNotifierChange(Sender:TObject);
begin
  FreeAndNil(FLastRoot);
  FLastNotifier.Cancel;
end;

function TRSShellListView.GetFiles: TRSShellFilesArray;
var r: TRSShellFolder;
begin
  r:= FNewRoot;
  if r = nil then  r:= FRoot;
  if r <> nil then
    Result:= Root.Files
  else
    Result:= nil;
end;

function TRSShellListView.SelectedFile: TRSShellFile;
var i:int;
begin
  if GetSelectedIndex(i) then
    Result:= FRoot.Files[i]
  else
    Result:= nil;
end;

function TRSShellListView.GetNeedRefresh: Boolean;
begin
  Result:= (FNeedRefresh or FNotifier.NeedRefresh) and (FBlockNotification < 2)
     and HandleAllocated;
end;

procedure TRSShellListView.SetObjectTypes(v: TRSShellObjectTypes);
begin
  FObjectTypes:= v;
  DoRefresh;
end;

procedure TRSShellListView.DoCanAdd(Sender: TObject;
  ShellFile: TRSShellFile; var CanAdd: Boolean);
begin
  if Assigned(OnCanAddItem) then
    OnCanAddItem(self, ShellFile, CanAdd);
end;

function TRSShellListView.DoCompare(Sender: TObject; Folder: TRSShellFolder;
   f1, f2: TRSShellFile; var Column: int; var Inverse:Boolean): Integer;
begin
  if Assigned(OnCompare) then
    Result:= OnCompare(self, Folder, f1, f2, Column, Inverse)
  else
    Result:= 0; // Supress warning
end;

procedure TRSShellListView.CreateWnd;
begin
  inherited;
  RSApplySystemImageList(Handle, true);
  RSApplySystemImageList(Handle, false);
end;

procedure TRSShellListView.DestroyWnd;
begin
  FNotifier.Cancel;
  inherited;
  if FRoot<>nil then
    FRoot.ClearFiles;
end;

function TRSShellListView.GetPath: string;
begin
  if Root<>nil then
    Result:= Root.FullName([RSForParsing, RSForAddressBar])
  else
    Result:='';
end;

procedure TRSShellListView.SetRootProps(f:TRSShellFolder);
begin
  if Assigned(OnCompare) then  f.OnCompare:= DoCompare
  else  f.OnCompare:= nil;

  if Assigned(OnCanAddItem) then  f.OnCanAdd:= DoCanAdd
  else  f.OnCanAdd:= nil;

  f.OnIconLoaded:= nil;
  f.OnLoadFile:= ShellFolderLoadFile;
  f.UseDefaultSorting;
end;

function TRSShellListView.SameRootProps(f1, f2:TRSShellFolder): Boolean;
begin
  Result:= int64(TMethod(f1.OnCompare)) = int64(TMethod(f2.OnCompare));
  if not Result then  exit;
  Result:= int64(TMethod(f1.OnCanAdd)) = int64(TMethod(f2.OnCanAdd));
  if not Result then  exit;
  Result:= (f1.SortColumn = f2.SortColumn) and (f1.SortInverse = f2.SortInverse);
end;

procedure TRSShellListView.SetOnCanAddItem(const Value: TRSShellFolderCanAddEvent);
begin
  FOnCanAddItem:= Value;
  if FRoot<>nil then  SetRootProps(FRoot);
end;

procedure TRSShellListView.SetOnCompare(const Value: TRSShellFolderCompareEvent);
begin
  FOnCompare:= Value;
  if FRoot<>nil then  SetRootProps(FRoot);
end;

function TRSShellListView.CanShowBack(f:TRSShellFolder): Boolean;
begin
  Result:= (RSotBack in FObjectTypes) and (f.PIDL.mkid.cb <> 0) and
               not RSIsSpecialFolder(f.PIDL, CSIDL_DRIVES);
end;

function TRSShellListView.GetRoot: TRSShellFolder;
begin
  Result:= FNewRoot;
  if Result = nil then
    Result:= FRoot;
end;

function TRSShellListView.GetSelContextMenu: IContextMenu;
var
  a: array of PItemIDList;
  i,j: int;
begin
  i:=0;
  j:=NextSelected;
  while j>=0 do
  begin
    if Files[j]<>nil then
    begin
      SetLength(a, i+1);
      a[i]:=FRoot.Files[j].PIDL;
      inc(i);
    end;
    j:=NextSelected(j);
  end;
  if length(a)=0 then  exit;
  FRoot.ShellFolder.GetUIObjectOf(Handle, length(a), a[0],
     IID_IContextMenu, nil, Result);
end;

procedure TRSShellListView.DoDrawItem(var a:TNMCustomDraw);
const
  Styles: array[Boolean] of int = (ILD_NORMAL, ILD_FOCUS);
var
  i,x,y:int; r:TRect; f:TRSShellFile; b:TBitmap; il:uint;
begin
  with a do
    if dwItemSpec < DWord(length(FRoot.Files)) then
    begin
      i:= dwItemSpec;
      f:= FRoot.Files[i];
      if f = nil then
        f:= FRoot;

      if f = FRoot then
        f.OverlayIndex(false)
      else
        if f.OverlayPending then
        begin
          FNeedIcons:= true;
          FNeedIcon[dwItemSpec]:= true;
          NeedBackgrounAction;
        end;

      b:= nil;
      if ((f.OverlayIconIndex(true) > 0) or
           (f.GetAttributes(SFGAO_GHOSTED) <> 0)) and
         ListView_GetItemRect(Handle, i, r, LVIR_ICON) then
        with TCanvas.Create do
        try
          Handle:= hdc;
          b:= TBitmap.Create;
          with b, Canvas do
          begin
            PixelFormat:= pf32bit;
            Width:= r.Right - r.Left;
            Height:= r.Bottom - r.Top;
            Brush.Color:= Color;
            FillRect(ClipRect);
          end;
          case ViewStyle of
            vsIcon:  il:= ListView_GetImageList(self.Handle, LVSIL_NORMAL);
            else  il:= ListView_GetImageList(self.Handle, LVSIL_SMALL);
          end;
          if ImageList_GetIconSize(il, x, y) and
             ImageList_Draw(il, f.ImageIndex(f = FRoot, true), b.Canvas.Handle,
                (b.Width - x) div 2, (b.Height - y) div 2,
                Styles[Perform(LVM_GETITEMSTATE, i, LVIS_SELECTED)<>0] or
                f.OverlayIconIndex(true)) then
          begin
            if f.GetAttributes(SFGAO_GHOSTED) <> 0 then
              RSMixPicColor32(b, b, Color, 1, 1);
            BitBlt(Handle, r.Left, r.Top, b.Width, b.Height, b.Canvas.Handle,
               0, 0, SRCCOPY);
          end;
        finally
          if b<>nil then  b.Free;
          Free;
        end;
    end;
end;

procedure TRSShellListView.WMPaint(var Msg: TWMPaint);
begin
  if not DoubleBuffered or (Msg.DC <> 0) then
    inherited
  else
    RSDoubleBufferedPaint(self, Msg);
end;

end.
