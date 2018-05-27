unit Unit1;

{
v1.2:
[+] Find&Replace dialogs
[+] Select Row, Select Column
[+] "Add to context menu for *.txt" option
[+] Immediate language switching

v1.2.1:
[+] Drag&drop files onto TxtEdit
[-] Crash on some computers
[-] Find/Replace didn't select text in multiline cells properly

v1.3:
[+] File name in app title, full path in caption
[+] Support Ctrl+Y shortcut for Redo
[+] Esc key to exit edits
[+] Grid popup menu
[+] "Associate with *.ert" and "Associate with *.ers" options 
[-] First column corruption
[-] Undo/Redo bugs
[-] Wrong font was used instead of default system font
[-] DPI above 100% wasn't supported

v1.3.1:
[-] Previous version was crashing on Windows XP
[-] Copy-Paste didn't warrant close warning
[-] Undo bugs
[-] Ctrl+A was buggy
}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Grids, RSSpinEdit, RSQ, RSC, RSStrUtils, XPMan,
  RSSysUtils, Math, Menus, RSMenus, RSWinController, Clipbrd, Consts, RSUtils,
  RSSpeedButton, Buttons, ImgList, RSGraphics, Themes, RSRecent, IniFiles,
  ComCtrls, RSMemo, RSCommon, RichEdit, RSStringGrid, RSLang, RSQHelp1,
  RSDialogs, Utils, ShellAPI, RSPopupMenu, RSFileAssociation;

type
  TForm1 = class(TForm)
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    StringGrid1: TRSStringGrid;
    Splitter1: TSplitter;
    Memo1: TRSMemo;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    Save1: TMenuItem;
    SaveAs1: TMenuItem;
    N6: TMenuItem;
    Exit1: TMenuItem;
    Edit1: TMenuItem;
    InsertRow1: TMenuItem;
    DeleteRow1: TMenuItem;
    InsertColumn1: TMenuItem;
    DeleteColumn1: TMenuItem;
    AddRow1: TMenuItem;
    AddColumn1: TMenuItem;
    RSWinController1: TRSWinController;
    N2: TMenuItem;
    Undo1: TMenuItem;
    Redo1: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    Cut1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    SelectAll1: TMenuItem;
    N5: TMenuItem;
    ImageList1: TImageList;
    Panel1: TPanel;
    EditX: TRSSpinEdit;
    EditY: TRSSpinEdit;
    Help1: TMenuItem;
    N1: TMenuItem;
    WordWrap1: TMenuItem;
    Recent1: TMenuItem;
    StatusBar1: TStatusBar;
    RSWinController2: TRSWinController;
    PopupMenu1: TPopupMenu;
    Undo2: TMenuItem;
    Redo2: TMenuItem;
    N7: TMenuItem;
    Cut2: TMenuItem;
    Copy2: TMenuItem;
    Paste2: TMenuItem;
    SelectAll2: TMenuItem;
    N8: TMenuItem;
    Delete1: TMenuItem;
    Find1: TMenuItem;
    Replace1: TMenuItem;
    FindNext1: TMenuItem;
    RSFindReplaceDialog1: TRSFindReplaceDialog;
    Options1: TMenuItem;
    Language1: TMenuItem;
    N10: TMenuItem;
    Associate1: TMenuItem;
    English1: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    SelectRow1: TMenuItem;
    SelectColumn1: TMenuItem;
    N13: TMenuItem;
    RSPopupMenu1: TRSPopupMenu;
    Associatewithert1: TMenuItem;
    Associatewithers1: TMenuItem;
    procedure StringGrid1ColumnResize(Sender: TStringGrid; Index,
      OldSize: Integer);
    procedure Associatewithers1Click(Sender: TObject);
    procedure Associatewithert1Click(Sender: TObject);
    procedure Delete1Click(Sender: TObject);
    procedure Memo1WndProc(Sender: TObject; var m: TMessage;
      var Handled: Boolean; const NextWndProc: TWndMethod);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure StatusBar1Hint(Sender: TObject);
    procedure SelectColumn1Click(Sender: TObject);
    procedure SelectRow1Click(Sender: TObject);
    procedure English1Click(Sender: TObject);
    procedure Language1Click(Sender: TObject);
    procedure Options1Click(Sender: TObject);
    procedure Associate1Click(Sender: TObject);
    procedure RSFindReplaceDialog1Replace(Sender: TObject);
    procedure RSFindReplaceDialog1Find(Sender: TObject);
    procedure FindNext1Click(Sender: TObject);
    procedure Replace1Click(Sender: TObject);
    procedure Find1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure StringGrid1ColumnMoved(Sender: TObject; FromIndex,
      ToIndex: Integer);
    procedure StringGrid1RowMoved(Sender: TObject; FromIndex,
      ToIndex: Integer);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure Memo1KeyPress(Sender: TObject; var Key: Char);
    procedure StringGrid1DblClick(Sender: TObject);
    procedure RSWinController1WndProc(sender: TObject; var Msg: TMessage;
      var Handled: Boolean; NextWndProc: TWndMethod);
    procedure StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Save1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Copy1Click(Sender: TObject);
    procedure Cut1Click(Sender: TObject);
    procedure Paste1Click(Sender: TObject);
    procedure Undo1Click(Sender: TObject);
    procedure SelectAll1Click(Sender: TObject);
    procedure InsertRow1Click(Sender: TObject);
    procedure DeleteRow1Click(Sender: TObject);
    procedure AddRow1Click(Sender: TObject);
    procedure InsertColumn1Click(Sender: TObject);
    procedure DeleteColumn1Click(Sender: TObject);
    procedure AddColumn1Click(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject);
    procedure New1Click(Sender: TObject);
    procedure StringGrid1Enter(Sender: TObject);
    procedure Memo1Enter(Sender: TObject);
    procedure EditXChanged(Sender: TObject);
    procedure EditYChanged(Sender: TObject);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure Help1Click(Sender: TObject);
    procedure WordWrap1Click(Sender: TObject);
    procedure StringGrid1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure StringGrid1MouseWheelDown(Sender: TObject;
      Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure StringGrid1MouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure File1Click(Sender: TObject);
    procedure RSWinController2WndProc(Sender: TObject; var Msg: TMessage;
      var Handled: Boolean; const NextWndProc: TWndMethod);
    procedure Redo1Click(Sender: TObject);
    procedure Memo1Exit(Sender: TObject);
    procedure Memo1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure StringGrid1CreateEditor(Sender: TStringGrid;
      var Editor: TInplaceEdit);
    procedure StringGrid1BeforeSetEditText(Sender: TObject; ACol,
      ARow: Integer; var Value: String);
  private
    FLanguage: string;
    procedure SetLanguage(const v: string);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMHelp(var Msg:TMessage); message WM_Help;
    procedure WMDropFiles(var m: TWMDropFiles); message WM_DropFiles;
  public
    FindHelper: TRSFindReplaceHelper;
    Toolbar: TRSControlArray;
    UndoLock: int;
    UndoHit: Boolean;
    Association1: TRSFileAssociationCmd;
    AssociationERT, AssociationERS: TRSFileAssociation;
    procedure DoLoad(s:string);
    procedure Load(fname:string);
    function SaveAsSel:boolean;
    procedure Save;
    function SaveQuery:boolean;
    procedure memoLoad(x,y:integer); overload;
    procedure memoLoad(const s:string); overload;
    procedure memoSave(x,y:integer);
    procedure CancelHint;
    procedure RecentClick(Sender:TRSRecent; Name:string);
    procedure ReadIni;
    procedure WriteIni;
    procedure AddUndo(composite: Boolean = false);
    procedure UpdateUndo(composite: Boolean = false);
    procedure ReleaseUndo;
    procedure Undo;
    procedure Redo;
    function CurrentEdit: TCustomEdit;
    procedure StartFind(Replace: Boolean);
    procedure Find(Replace: Boolean);
    procedure ReplaceAll;
    property Language: string read FLanguage write SetLanguage;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

type
  TUndo = class(TObject)
  public
    procedure OptimizeData; virtual; abstract;
    procedure StoreData; virtual; abstract;
    procedure StoreState(Redo: Boolean); virtual; abstract;
    procedure RestoreState(Redo: Boolean); virtual; abstract;
    procedure UpdateState; virtual; abstract;
    function CanIgnoreKey: Boolean; virtual; abstract;
  end;

  TMyStringGrid = class(TRSStringGrid)
  end;

var
  SSaveQuestion: string = 'Save changes to "%s"?';
  SSaveQuestionUntitled: string = 'Save changes to Untitled?';
  SCaption: string;
  SReopenQuestion: string = 'Are you sure you want to reopen "%s"?';
  SStatusText: string;
  SSearchOtherEnd: string = 'Continue search from the other end of the file?';
  SSearchNotFound: string = 'Search string "%s" not found';

var
  FileName:String; wasChanged:boolean; currX,currY:integer;
  Leng:array of int; memoOk:boolean=true;
  WordWrapButton:TRSSpeedButton;
  LastMouseCellRect:TRect;
  HintWindow:THintWindow;
  Recent:TRSRecent;
  EmptyBmp: array[0..2] of TBitmap; EmptyBmpColorsLast: array[0..5] of TColor;
  InplaceEditAnchor: int; NoStr: string;
  UndoList: array of TUndo; CurUndo: int = -1;
  IsCharInput: Boolean = false;
  CallSetEditText: Boolean = true;

const
  LangDir = 'Language\';
  EmptyBmpColors: array[0..5] of TColor =
    (clBtnShadow, clWindow, clBtnShadow, clHighlight, clBtnShadow, clBtnFace);

var EnterReaderModeHelper: function(Wnd: HWND): BOOL; stdcall;

type
  TMyHintWindow = class(THintWindow)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure NCPaint(DC: HDC); override;
  end;

procedure TMyHintWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
    Style:= Style and not CS_DROPSHADOW;
end;

procedure TMyHintWindow.NCPaint(DC: HDC);
var R:TRect; Br:TBrush;
begin
  R:=Rect(0, 0, Width, Height);
  Br:=TBrush.Create;
  try
    Br.Color:=clMedGray; //clSilver;
    FrameRect(DC, R, Br.Handle);
  finally
    Br.Free;
  end;
end;

{---------------------------------------------------------------}

function InplaceEditor:TInplaceEdit;
begin
  Result:=Form1.StringGrid1.InplaceEditor;
end;

function GetCellText(x, y: int): string;
begin
  with Form1.StringGrid1 do
    if EditorMode and (x = currX) and (y = currY) then
      Result:= InplaceEditor.Text
    else
      Result:= Cells[x, y];
end;

{---------------------------------------------------------------}

type
  TCustomUndoData = record
    Focus: TWinControl;
    MemoSel1, MemoSel2, MemoScrollX, MemoScrollY: int;
    InplaceSel1, InplaceSel2, InplaceScrollX: int;
    GridSel: TGridRect;
    GridX, GridY, GridScrollX, GridScrollY, GridFixedX, GridFixedY: int;
  end;

  TGridUndoData = record
    w, h: int;
    Arr: array of string;
    Len: array of int;
  end;

  TCustomUndo = class(TUndo)
  protected
    FCustomData: array[Boolean] of TCustomUndoData;
    ColW: array of int;
    FData: TGridUndoData;
    IsCharUndo: Boolean;
    Time: uint;
  public
    procedure OptimizeData; override;
    procedure StoreData; override;
    procedure StoreState(IsRedo: Boolean); override;
    procedure RestoreState(IsRedo: Boolean); override;
    procedure UpdateState; override;
    function CanIgnoreKey: Boolean; override;
  end;

function TCustomUndo.CanIgnoreKey: Boolean;
begin
  with Form1, FCustomData[false] do
    IsCharUndo:= IsCharUndo and (GridX = currX) and (GridY = currY);
  Result:= IsCharUndo and IsCharInput and (GetTickCount - Time < 30000);
  if Result then
    StoreState(false);
end;

procedure TCustomUndo.OptimizeData;
var x,y:int;
begin
  with Form1.StringGrid1, FData do
  begin
    for y:=0 to h-1 do
      for x:=0 to w-1 do
        if Arr[y*w + x] = GetCellText(x, y) then
          Arr[y*w + x]:= NoStr;
  end;
  IsCharUndo:= false;
end;

procedure TCustomUndo.StoreData;
var x,y:int;
begin
  with Form1.StringGrid1, FData do
  begin
    SetLength(Len, length(Leng));
    CopyMemory(ptr(Len), ptr(Leng), length(Leng)*4);
    w:=ColCount;
    h:=RowCount;
    Arr:=nil;
    SetLength(Arr, w*h);
    for y:=0 to h-1 do
      for x:=0 to w-1 do
        Arr[y*w + x]:= GetCellText(x, y);
  end;
  IsCharUndo:= false;
end;

procedure TCustomUndo.UpdateState;

  function GetScrollX(c:TCustomEdit):int;
  begin
    Result:=c.Perform(EM_POSFROMCHAR, 0, 0);
    if Result<>-1 then
      Result:=smallint(word(Result))
    else
      Result:=0;
  end;

var
  old: TCustomUndoData;
  i: int;
begin
  if IsCharUndo then
    old:= FCustomData[false];
  with Form1, FCustomData[false] do
  begin
    if StringGrid1.EditorMode then
      Focus:=nil
    else
      if Memo1.Focused then
        Focus:=Memo1
      else
        Focus:=StringGrid1;

    GridX:= CurrX; //StringGrid1.Col;
    GridY:= CurrY; //StringGrid1.Row;
    GridSel:= StringGrid1.Selection;
    GridScrollX:= GetScrollPos(StringGrid1.Handle, SB_HORZ);
    GridScrollY:= GetScrollPos(StringGrid1.Handle, SB_VERT);
    GridFixedX:= StringGrid1.FixedCols;
    GridFixedY:= StringGrid1.FixedRows;
    ColW:= nil;
    SetLength(ColW, StringGrid1.ColCount);
    for i:= 0 to high(ColW) do
      ColW[i]:= StringGrid1.ColWidths[i];

    Memo1.GetSelection(MemoSel1, MemoSel2);
    MemoScrollX:= GetScrollX(Memo1);
    MemoScrollY:= Memo1.Perform(EM_GETFIRSTVISIBLELINE, 0, 0);

    if Focus = nil then
    begin
      RSEditGetSelection(InplaceEditor, InplaceSel1, InplaceSel2, InplaceEditAnchor);
      InplaceScrollX:= GetScrollX(InplaceEditor);
    end;
    if IsCharUndo then
      IsCharUndo:= (Focus = old.Focus) and (GridX = old.GridX) and (GridY = old.GridY)
        and (MemoSel1 = old.MemoSel1) and (MemoSel2 = old.MemoSel2)
        and (InplaceSel1 = old.InplaceSel1) and (InplaceSel2 = old.InplaceSel2);
  end;
end;

procedure TCustomUndo.StoreState(IsRedo: Boolean);
begin
  StoreData;
  UpdateState;
  IsCharUndo:= IsCharInput;
  if IsCharInput then
    Time:= GetTickCount;
  if not IsRedo then
    FCustomData[true]:= FCustomData[false];
end;

procedure TCustomUndo.RestoreState(IsRedo: Boolean);
var
  Sel:TGridRect; i,x,y:int;
begin
  CallSetEditText:=false;
  try
    with Form1, StringGrid1, FData do
    begin
      SetLength(Leng, length(Len));
      CopyMemory(ptr(Leng), ptr(Len), length(Leng)*4);
      ColCount:=w;
      RowCount:=h;
      for y:=0 to h-1 do
        for x:=0 to w-1 do
          if ptr(Arr[y*w + x])<>ptr(NoStr) then
            Cells[x,y]:= Arr[y*w + x];
    end;

    with Form1, FCustomData[IsRedo] do
    begin
      EditX.Value:= GridFixedX;
      StringGrid1.FixedCols:= GridFixedX;
      EditY.Value:= GridFixedY;
      StringGrid1.FixedRows:= GridFixedY;
      Sel:=StringGrid1.Selection;
      if not CompareMem(@Sel, @GridSel, SizeOf(Sel)) or (GridX <> CurrX) or (GridY <> CurrY) then
        with Sel do
        begin
          TMyStringGrid(StringGrid1).FocusCell(GridX, GridY, true);
          Sel:= GridSel;
          if GridX = Left then  zSwap(Left, Right);
          if GridY = Top then  zSwap(Top, Bottom);
          StringGrid1.Selection:= Sel;
          CurrX:= GridX;
          CurrY:= GridY;
        end;
      for i:= 0 to min(high(ColW), StringGrid1.ColCount - 1) do
        StringGrid1.ColWidths[i]:= ColW[i];
      StringGrid1.Perform(WM_HSCROLL, SB_THUMBPOSITION or GridScrollX shl 16, 0);
      StringGrid1.Perform(WM_VSCROLL, SB_THUMBPOSITION or GridScrollY shl 16, 0);

      memoLoad(CurrX, CurrY);

      if Focus = nil then
      begin
        StringGrid1.EditorMode:= true;
        InplaceEditor.Perform(WM_HSCROLL, SB_THUMBPOSITION or InplaceScrollX shl 16, 0);
        RSEditSetSelection(InplaceEditor, InplaceSel1, InplaceSel2);
      end else
      begin
        StringGrid1.EditorMode:= false;
        Memo1.Perform(WM_HSCROLL, SB_THUMBPOSITION or MemoScrollX shl 16, 0);
        Memo1.Perform(WM_VSCROLL, SB_THUMBPOSITION or MemoScrollY shl 16, 0);
        Memo1.SetSelection(MemoSel1, MemoSel2);
        Memo1.Perform(EM_SCROLLCARET, 0, 0);
        Focus.SetFocus;
      end;
    end;
  finally
    CallSetEditText:=true;
  end;
end;

{---------------------------------------------------------------}

{
type
  TMyGridDestroyer = class(TCustomGrid)
  public
    destructor MyDestroy;
  end;

destructor TMyGridDestroyer.MyDestroy;
begin
  inherited Destroy;
end;
}

{---------------------------------------------------------------}

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WinClassName:='Txt Tables Editor Main Form';
end;

procedure TForm1.WMDropFiles(var m: TWMDropFiles);
var
  s: string;
begin
  m.Result:= 0;
  try
    if DragQueryFile(m.Drop, $FFFFFFFF, nil, 0) = 0 then
      exit;
    SetLength(s, DragQueryFile(m.Drop, 0, nil, 0));
    if (s = '') or (int(DragQueryFile(m.Drop, 0, ptr(s), length(s)+1)) <> length(s)) then
      exit;
  finally
    DragFinish(m.Drop);
  end;
  if not SaveQuery then exit;
  Load(s);
end;

procedure TForm1.WMHelp(var Msg:TMessage);
begin
  RSHelpShow([]);
end;

procedure SetCaption;
begin
  if FileName='' then
  begin
    Form1.Caption:= SCaption;
    Application.Title:= AppTitle;
  end else
  begin
    Form1.Caption:= FileName + ' - ' + SCaption;
    Application.Title:= ExtractFileName(FileName) + ' - ' + AppTitle;
  end;
end;

function IsNumber(s:string):boolean;
var
  i: int;
begin
  Result:= RSVal(s, i);
{  try
    StrToInt(s);
    Result:=true;
  except
    Result:=false;
  end;}
end;

procedure SetLeng(x,y:integer);
var i,j:integer;
begin
  j:=length(leng);
  if j<=y then
  begin
    SetLength(Leng, y+1);
    for i:=j to y do
      leng[i]:=1;
  end;
  if leng[y]<=x then
  begin
    leng[y]:=x+1;
    Form1.StringGrid1.Invalidate;
  end;
  for i:=0 to y-1 do
    if leng[i]=0 then
      leng[i]:=1;
end;

procedure PutString(s:string; x,y:integer; put:boolean=true);
begin
  with Form1, StringGrid1 do
  begin
    if ColCount<=x then
    begin
      ColCount:=x+1;
      ColWidths[x]:=DefaultColWidth;
    end;
    if RowCount<=y then RowCount:=y+1;
    SetLeng(x,y);
    if put then Cells[x,y]:=s;
    if (CurrX=x) and (CurrY=y) and memoOk then
      memoLoad(s);
  end;
end;

function IsEmpty(x,y:integer):boolean;
begin
  Result:=(length(leng)<=y) or (leng[y]<=x);
end;

procedure DeleteCells(x,y:integer; dx:integer=1; dy:integer=1);
var i,j:integer;
begin
  with Form1 do
    try
      UpdateUndo;
      for j:=y to y+dy-1 do
      begin
        for i:=x to x+dx-1 do
          StringGrid1.Cells[i,j]:='';
        if leng[j]<=x+dx then
          leng[j]:=min(leng[j],max(x,1));
      end;
      if x=0 then
        if dx=1 then exit
        else
        begin
          inc(x);
          dec(dx);
        end;
      if StringGrid1.ColCount<=x+dx then
      begin
        for y:=length(leng)-1 downto 0 do
          if leng[y]>x then x:=leng[y];
        if x<2 then
          x:=2;
        if CurrX=x then
        begin
          dec(CurrX);
          StringGrid1.Col:=CurrX;
        end;
        StringGrid1.ColCount:=x;
      end;
    finally
      AddUndo;
    end;
end;

procedure PutText(s:string; x,y:integer; dx:integer=MaxInt; dy:integer=MaxInt);
var ps1,ps2:TRSParsedString; i,j,l:integer;
begin
  ps1:=nil; ps2:=nil;

  ps1:=RSParseString(s, [#13#10]);
  l:=RSGetTokensCount(ps1);
  for j:=min(l-1, dy-1) downto 0 do
  begin
    ps2:=RSParseString(RSGetToken(ps1,j),[#9]);
    for i:=min(RSGetTokensCount(ps2)-1, dx-1) downto 0 do
      PutString(RSGetToken(ps2,i),x+i,y+j);
  end;
end;

function GetText(x,y:integer; dx:integer=MaxInt; dy:integer=MaxInt):string;
var i,j:integer;
begin
  with Form1 do
  begin
    Result:= GetCellText(x, y);
    for i:= x+1 to min(leng[0]-1, x+dx-1) do
      Result:= Result + #9 + GetCellText(i, y);
    for j:= y+1 to min(StringGrid1.RowCount-1, y+dy-1) do
    begin
      if leng[j]=0 then  exit;
      Result:= Result + #13#10 + GetCellText(x, j);
      for i:= x+1 to min(leng[j]-1, x+dx-1) do
        Result:= Result + #9 + GetCellText(i, j);
    end;
  end;
end;

procedure TForm1.memoLoad(x,y:integer);
begin
  memoLoad(GetCellText(x, y));
end;

procedure TForm1.memoLoad(const s:string);
var s1:string;
begin
  memoOk:=false;
  try
    Form1.Memo1.Clear;
    s1:=RSStringReplace(s, #10, #13#10);
    if Memo1.Text<>s1 then
    begin
      Memo1.Text:=s1;
      Memo1.SelStart:=0;
      Memo1.SelLength:=0;
    end;
  finally
    memoOk:=true;
  end;
end;

procedure TForm1.memoSave(x,y:integer);
begin
  memoOk:=false;
  try
    PutString(RSStringReplace(Memo1.Text, #13#10, #10),x,y);
  finally
    memoOk:=true;
  end;
end;

procedure TForm1.ReadIni;
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini')) do
    try
      Recent.AsString:= ReadString('General', 'Recent Files', '');
      Width:= ReadInteger('Main Form', 'Width', Width);
      Height:= ReadInteger('Main Form', 'Height', Height);
      if ReadBool('Main Form', 'Maximized', false) then
        WindowState:=wsMaximized;
      Language:= ReadString('General', 'Language', 'English');
    finally
      Free;
    end;
end;

procedure TForm1.WriteIni;
var wp:TWindowPlacement;
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini')) do
    try
      WriteString('General', 'Recent Files', Recent.AsString);
      wp.length:=SizeOf(wp);
      GetWindowPlacement(Handle, @wp);
      with wp.rcNormalPosition do
      begin
        WriteInteger('Main Form', 'Width', Right-Left);
        WriteInteger('Main Form', 'Height', Bottom-Top);
      end;
      WriteBool('Main Form', 'Maximized', IsZoomed(Handle));
      WriteString('General', 'Language', Language);
    finally
      Free;
    end;
end;

procedure DrawEmptyBmp(i:int; NewWidth:int);
var Bmp:TBitmap;
begin
  Bmp:=EmptyBmp[i];
  i:=i*2;
  with Bmp, Canvas do
  begin
    if NewWidth>Width then
      Width:=NewWidth
    else
      if (ColorToRGB(EmptyBmpColors[i])=EmptyBmpColorsLast[i]) and
         (ColorToRGB(EmptyBmpColors[i+1])=EmptyBmpColorsLast[i+1]) then
        exit;

    EmptyBmpColorsLast[i]:=ColorToRGB(EmptyBmpColors[i]);
    EmptyBmpColorsLast[i+1]:=ColorToRGB(EmptyBmpColors[i+1]);

    Pen.Color:=EmptyBmpColorsLast[i+1];
    Brush.Color:=EmptyBmpColorsLast[i+1];
    Brush.Style:=bsSolid;
    FillRect(ClipRect);
    Brush.Color:=EmptyBmpColorsLast[i];
    Brush.Style:=bsBDiagonal;
    Rectangle(ClipRect);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  a: TRSControlArray;
  s, s1: string;
  i: int;
begin
  AppTitle:= 'TxtEdit';
  Application.Title:= AppTitle;
  AssertErrorProc:= RSAssertErrorHandler;
  RSFixThemesBug;
  HintWindowClass:= TRSSimpleHintWindow;
  RSHintWindowClass:= TMyHintWindow;
  if ThemeServices.ThemesEnabled then
    RSRemoveBevels(self);
  Screen.HintFont:= StringGrid1.Font;
  HintWindow:= HintWindowClass.Create(self);
  SetLength(NoStr, 1);
  DragAcceptFiles(Handle, true);
  s:= RSGetModuleFileName(0);
  s1:= '"' + s + '" "%1"';
  Association1:= TRSFileAssociationCmd.Create('.txt', 'TxtEdit Table',
    s1, 'Open as TxtEdit table');
  AssociationERT:= TRSFileAssociation.Create('.ert', 'TxtEdit.Ert',
    'TxtEdit Backup', s1, s + ',0');
  AssociationERS:= TRSFileAssociation.Create('.ers', 'TxtEdit.Ers',
    'TxtEdit Backup', s1, s + ',0');

  RSHelpCreate('Txt Tables Editor Help Form');
  with RSLanguage.AddSection('[Main Form]', self) do
  begin
    AddItem('SSaveQuestion', SSaveQuestion);
    AddItem('SSaveQuestionUntitled', SSaveQuestionUntitled);
    AddItem('SReopenQuestion', SReopenQuestion);
    AddItem('SSearchNotFound', SSearchNotFound);
    AddItem('SSearchOtherEnd', SSearchOtherEnd);
    AddItem('STxtAssociationCaption', Association1.CommandCaption);
  end;
  SCaption:= Caption;

  Recent:=TRSRecent.Create(RecentClick, Recent1, true);

  StringGrid1.DefaultRowHeight:= HintWindow.CalcHintRect(MaxInt, 'A', nil).Bottom + 3;
  for i:=0 to high(EmptyBmp) do
  begin
    EmptyBmp[i]:=TBitmap.Create;
    EmptyBmp[i].Height:=StringGrid1.DefaultRowHeight;
    DrawEmptyBmp(i, Screen.Width);
  end;

  DeleteColumn1.GroupIndex:=0;
  RSMenu.Add(MainMenu1);
  StringGrid1.Options:=StringGrid1.Options+[goEditing]+[goRangeSelect];
  RSBindToolBar:= true;
  RSMakeToolBar(Panel1,
    [New1, Open1, Recent1, Save1, SaveAs1, nil, InsertRow1, DeleteRow1, AddRow1, nil,
     InsertColumn1, DeleteColumn1, AddColumn1, nil, SelectRow1, SelectColumn1, nil, WordWrap1], a, 1, 13);
  Toolbar:= a;
  EditX.Left:= EditX.Left + a[high(a)].BoundsRect.Right;
  EditY.Left:= EditY.Left + a[high(a)].BoundsRect.Right;
  WordWrapButton:=(a[high(a)]) as TRSSpeedButton;
  with WordWrapButton do
  begin
    AllowAllUp:=true;
    GroupIndex:=1;
  end;
  WordWrap1Click(nil);
  RSPopupMenu1.SetItems(Edit1);
  ReadIni;

  StringGrid1Enter(nil);
  SetCaption;
  New1Click(nil);
  Load(ParamStr(1));
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Shift = [ssCtrl]) and (Key = ord('Y')) then
  begin
    Redo;
    Key:= 0;
  end;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = ChrCtrl['Y'] then
  begin
    //Redo;
    Key:= #0;
  end;
end;

procedure TForm1.AddUndo(composite: Boolean);
var i:int;
begin
  wasChanged:= true;
  if composite then
    dec(UndoLock);
  if UndoLock > 0 then
  begin
    UndoHit:= true;
    exit;
  end;
  UndoHit:= false;
  if (CurUndo>=0) and UndoList[CurUndo].CanIgnoreKey then
    exit;
  for i:=CurUndo+1 to high(UndoList) do
    UndoList[i].Free;
  if CurUndo>=0 then
    UndoList[CurUndo].OptimizeData;
  inc(CurUndo);
  SetLength(UndoList, CurUndo+1);
  UndoList[CurUndo]:=TCustomUndo.Create;
  UndoList[CurUndo].StoreState(false);
  Redo1.Enabled:=false;
  Undo1.Enabled:= CurUndo > 0;
end;

procedure TForm1.UpdateUndo(composite: Boolean);
begin
  if (CurUndo >= 0) and (UndoLock <= 0) then
    UndoList[CurUndo].UpdateState;
  if composite then
    inc(UndoLock);
end;

procedure TForm1.Undo;
begin
  if CurUndo<=0 then  exit;
  wasChanged:= true;
  UpdateUndo;
  dec(CurUndo);
  UndoList[CurUndo].RestoreState(false);
  UndoList[CurUndo].StoreData;
  UndoList[CurUndo+1].OptimizeData;
  Redo1.Enabled:=true;
  Undo1.Enabled:=CurUndo>0;
end;

procedure TForm1.Redo;
begin
  if CurUndo>=high(UndoList) then  exit;
  wasChanged:= true;
  UpdateUndo;
  inc(CurUndo);
  UndoList[CurUndo].RestoreState(true);
  UndoList[CurUndo].StoreData;
  UndoList[CurUndo-1].OptimizeData;
  Redo1.Enabled:=CurUndo<high(UndoList);
  Undo1.Enabled:=true;
end;

procedure TForm1.Memo1Change(Sender: TObject);
begin
  if not memoOk then exit;
  memoSave(CurrX,CurrY);
  AddUndo;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=SaveQuery;
  if CanClose then
  begin
    WriteIni;
{
    try
      StringGrid1.Free;
    except
      TMyGridDestroyer(StringGrid1).MyDestroy;
    end;
    StringGrid1:=nil;
}    
  end;
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  self.perform(wm_syscommand,$f008,1);
end;

procedure TForm1.StringGrid1SelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  MemoLoad(ACol,ARow);
  CurrX:=ACol;
  CurrY:=ARow;
  if SStatusText<>'' then
    StatusBar1.Panels[0].Text:=Format(SStatusText, [CurrY+1, CurrX+1]);
  LastMouseCellRect.Left:=MaxInt;
  RSHideHint(false);
{
  with StringGrid1.Selection do
  begin
    if (Left=Right) and (Top<>Bottom) then
      StringGrid1.Options:=StringGrid1.Options+[goRowSelect]
    else
      StringGrid1.Options:=StringGrid1.Options-[goRowSelect];
  end;
}  
end;

procedure TForm1.StringGrid1ColumnMoved(Sender: TObject; FromIndex,
  ToIndex: Integer);
var i:integer;
begin
  if CurrX=FromIndex then CurrX:=ToIndex;
  if ToIndex>FromIndex then
  begin
    for i:=0 to StringGrid1.RowCount-1 do
      if not IsEmpty(fromIndex,i) then SetLeng(ToIndex,i);
  end else
  begin
    for i:=0 to StringGrid1.RowCount-1 do
      if not IsEmpty(fromIndex,i) and (length(leng)>i) and (leng[i]>toIndex) then
        leng[i]:=leng[i]+1;
  end;

  memoLoad(CurrX,CurrY);
  AddUndo;
end;

procedure TForm1.StringGrid1ColumnResize(Sender: TStringGrid; Index,
  OldSize: Integer);
begin
  UpdateUndo;
end;

procedure TForm1.StringGrid1RowMoved(Sender: TObject; FromIndex,
  ToIndex: Integer);
var i,j,k:integer;
begin
  if CurrY=fromIndex then CurrY:=ToIndex;
  memoLoad(CurrX,CurrY);
 //lengs
  if ToIndex>FromIndex then
  begin
    j:=length(leng)-1;
    k:=leng[fromIndex];
    for i:=fromIndex to ToIndex-1 do
    begin
      if i<j then leng[i]:=leng[i+1]
      else leng[i]:=1;
    end;
    leng[toIndex]:=k;
  end else
  begin
    j:=length(leng)-1;
    k:=leng[fromIndex];
    if j>fromIndex then j:=fromIndex;
    for i:=j downto ToIndex+1 do
    begin
      leng[i]:=leng[i-1];
    end;
    leng[toIndex]:=k;
  end;
  AddUndo;
end;

procedure AddXLine(Pos:integer; ExtendLeng:boolean=true);
var i,j:integer;
begin
  with Form1,StringGrid1 do
  begin
    UpdateUndo;
    EditorMode:= false;
   //lengs
    j:=length(leng)-1;
    if pos<=j then
    begin
      SetLength(leng,Length(leng)+1);
      for i:=j+1 downto pos+1 do
        leng[i]:=leng[i-1];
    end else
      SetLength(leng,Pos+1);
      
    if ExtendLeng then
    begin
      if (pos = RowCount) and (leng[pos-1]=0) then
        leng[pos-1]:=1;
      leng[pos]:=1;
    end else
      leng[pos]:=0;
   //cells
    RowCount:=RowCount+1;
    for j:=0 to ColCount-1 do
    begin
      for i:=RowCount-1 downto pos+1 do
      begin
        Cells[j,i]:=Cells[j,i-1];
      end;
      Cells[j,pos]:='';
    end;
    if (row>=pos) and (row<RowCount-1) then row:=row+1;
    CurrX:=col;
    CurrY:=row;
    EditY.MaxValue:=EditY.MaxValue+1;
    AddUndo;
  end;
end;

procedure AddYLine(Pos:integer; ExtendLeng:boolean=true);
var i,j:integer;
begin
  with Form1,StringGrid1 do
  begin
    UpdateUndo;
    EditorMode:= false;
    if ExtendLeng then
      for i:=0 to length(leng)-1 do
        if (leng[i]>=pos) and
           ((leng[i]<>1) or (Cells[pos,i]<>'')) then
          leng[i]:=leng[i]+1;

    ColCount:=ColCount+1;
    for j:=0 to RowCount-1 do
    begin
      for i:=ColCount-1 downto pos+1 do
      begin
        Cells[i,j]:=Cells[i-1,j];
      end;
      Cells[pos,j]:='';
    end;
    
    for i:=ColCount-1 downto pos+1 do
      ColWidths[i]:=ColWidths[i-1];

    ColWidths[pos]:=DefaultColWidth;

    if (col>=pos) and (Col<ColCount-1) then col:=col+1;
    CurrX:=col;
    EditX.MaxValue:=EditX.MaxValue+1;
    AddUndo;
  end;
end;


procedure DelXLine;
var i,j:integer;
begin
  with Form1,StringGrid1 do
  begin
    UpdateUndo;
    EditorMode:= false;
    if RowCount<=1 then
    begin
      leng[0]:=1;
      setLength(leng,1);
      for i:=0 to ColCount-1 do
        cells[i,CurrY]:='';
      ColCount:=2;
      exit;
    end;
   //lengs
    j:=length(leng)-1;
    for i:=CurrY to j-1 do leng[i]:=leng[i+1];
    SetLength(leng,j);
   //
    for j:=0 to ColCount-1 do
    begin
      for i:=CurrY to RowCount-1 do
      begin
        Cells[j,i]:=Cells[j,i+1];
      end;
      Cells[j,RowCount]:='';
    end;
    if (Row=RowCount-1) and (FixedRows=Row) then
    begin
      FixedRows:=Row-1;
      EditY.Value:=FixedRows;
    end;
    if Row=RowCount-1 then  //Row:=Row-1;
      TMyStringGrid(StringGrid1).FocusCell(Col, Row-1, true);
    if RowCount>2 then
    begin
      RowCount:=RowCount-1;
      EditY.MaxValue:=EditY.MaxValue-1;
    end else
      SetLength(leng,length(leng)+1);
    if leng[0]=0 then
      leng[0]:=1;
    CurrX:=col;
    CurrY:=row;
    memoLoad(CurrX,CurrY);
    StringGrid1.Invalidate;
    AddUndo;
  end;
end;

procedure DelYLine;
var i,j:integer;
begin
  with Form1,StringGrid1 do
  begin
    UpdateUndo;
    EditorMode:= false;
    for i:=0 to length(leng)-1 do if (leng[i]-1>=CurrX) and (leng[i]>1) then leng[i]:=leng[i]-1;
    if ColCount<=1 then
    begin
      SetLength(leng,2);
      leng[1]:=0;
      for i:=0 to RowCount-1 do cells[0,i]:='';
      RowCount:=2;
      exit;
    end;
    for j:=0 to RowCount-1 do
    begin
      for i:=CurrX to ColCount-1 do
      begin
        Cells[i,j]:=Cells[i+1,j];
      end;
      Cells[ColCount,j]:='';
    end;

    for i:=CurrX to ColCount-2 do
      ColWidths[i]:=ColWidths[i+1];

    if (Col = ColCount-1) and (FixedCols = Col) then
    begin
      FixedCols:=Col-1;
      EditX.Value:=FixedCols;
    end;
    if Col=ColCount-1 then
      Col:=Col-1;
      
    if ColCount>2 then
    begin
      ColCount:=ColCount-1;
      EditX.MaxValue:=EditX.MaxValue-1;
    end;
    CurrX:=col;
    CurrY:=row;
    memoLoad(CurrX,CurrY);
    StringGrid1.Invalidate;
    AddUndo;
  end;
end;

procedure TForm1.StringGrid1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_CONTROL then Key:=0;
  if StringGrid1.EditorMode then
  begin
    if (Key = VK_ESCAPE) and (Shift = []) then
      StringGrid1.EditorMode:= false;
    exit;
  end;
  case Key of
    VK_RETURN: begin
//      StringGrid1.Options:=StringGrid1.Options+[goEditing]+[goRangeSelect];
    end;
    VK_DELETE:
    begin
      with StringGrid1.Selection do
        DeleteCells(Left, Top, Right-Left+1, Bottom-Top+1);
      StringGrid1.Selection:=TGridRect(Rect(CurrX, CurrY, CurrX, CurrY));
    end;
{
    VK_RIGHT:
      if (StringGrid1.ColCount = CurrX + 1) and (GetKeyState(VK_CONTROL) < 0) then
        AddYLine(CurrX + 1, false);
    VK_DOWN:
      if (StringGrid1.RowCount = CurrY + 1) and (GetKeyState(VK_CONTROL) < 0) then
      begin
        AddXLine(CurrY + 1, false);
        StringGrid1.Row:= CurrY + 1;
        Key:=0;
      end;
}
{
    VK_LEFT:
      if
}
  end;
end;

procedure TForm1.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var r:TRect; i:int;
begin
  if IsEmpty(ACol,ARow) then
    with (sender as TStringGrid).Canvas do
    begin
      if State<>[] then
        if State=[gdFixed] then
          i:=2
        else
          i:=1
      else
        i:=0;

      r:=SizeRect(Rect);
      DrawEmptyBmp(i, r.Right);
      CopyRect(Rect, EmptyBmp[i].Canvas, r);
    end;
end;

procedure TForm1.Memo1KeyPress(Sender: TObject; var Key: Char);
begin
  if (key=#19) or (key=#12) then key:=#0;
end;

procedure TForm1.Memo1WndProc(Sender: TObject; var m: TMessage;
  var Handled: Boolean; const NextWndProc: TWndMethod);
begin
  if (m.Msg = WM_CHAR) and (TWMChar(m).CharCode >= 32) then
    try
      IsCharInput:= true;
      NextWndProc(m);
      Handled:= true;
    finally
      IsCharInput:= false;
    end;

  if m.Msg = WM_PASTE then
    try
      UpdateUndo(true);
      NextWndProc(m);
      Handled:= true;
    finally
      ReleaseUndo;
    end;
end;

procedure TForm1.StartFind(Replace: Boolean);
var
  edit: TCustomEdit;
begin
  if RSFindReplaceDialog1.Handle = 0 then
  begin
    edit:= CurrentEdit;
    if (edit.SelStart = 0) and (edit.SelLength = 0) and (GetFocus = StringGrid1.Handle) then
      edit.SelectAll;
    RSFindReplaceDialog1.FindText:= edit.SelText;
    RSFindReplaceDialog1.ReplaceMode:= Replace;
  end;
  if StringGrid1.EditorMode then
    StringGrid1.EditorMode:= false;
  RSFindReplaceDialog1.Execute;
end;

procedure TForm1.StatusBar1Hint(Sender: TObject);
begin
  if (Application.Hint = '') and (SStatusText <> '') then
    StatusBar1.Panels[0].Text:= Format(SStatusText, [CurrY+1, CurrX+1])
  else
    StatusBar1.Panels[0].Text:= Application.Hint;
end;

procedure TForm1.StringGrid1BeforeSetEditText(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
  if not CallSetEditText or (Value = StringGrid1.Cells[ACol, ARow]) then
    exit;

  CurrX:=ACol;
  CurrY:=ARow;
  PutString(RSStringReplace(Value, #13#10, #10),ACol,ARow,not StringGrid1.EditorMode);
  AddUndo;
end;

procedure TForm1.StringGrid1DblClick(Sender: TObject);
begin
  with StringGrid1 do
  begin
    if not PtInRect(CellRect(Col, Row), ScreenToClient(Mouse.CursorPos)) then
      exit;
    StringGrid1.EditorMode:=true;
    InplaceEditor.SelectAll;
  end;
end;

procedure TForm1.RSFindReplaceDialog1Find(Sender: TObject);
begin
  FindHelper.Create(RSFindReplaceDialog1.FindText, RSFindReplaceDialog1.Options);
  Find(false);
end;

procedure TForm1.RSFindReplaceDialog1Replace(Sender: TObject);
begin
  FindHelper.Create(RSFindReplaceDialog1.FindText, RSFindReplaceDialog1.Options);
  if frReplaceAll in RSFindReplaceDialog1.Options then
    ReplaceAll
  else
    Find(true);
end;

procedure TForm1.RSWinController1WndProc(sender: TObject;
  var Msg: TMessage; var Handled: Boolean; NextWndProc: TWndMethod);
var p:TPoint;
begin
  case msg.Msg of
    WM_LBUTTONDOWN:
      with StringGrid1 do
      begin
        p:=ScreenToClient(Mouse.CursorPos);
        if not PtInRect(CellRect(Col, Row), p) then
          Options:=Options-[goEditing]+[goRangeSelect];
      end;
    WM_KEYDOWN:
      if TWMKey(Msg).CharCode = VK_CONTROL then
        Handled:=true;
    WM_COPY:
      with StringGrid1.Selection do
        Clipboard.AsText:=GetText(Left, Top, Right-Left+1, Bottom-Top+1);
    WM_PASTE:
    begin
      UpdateUndo;
      PutText(Clipboard.AsText, StringGrid1.Selection.Left, StringGrid1.Selection.Top);
      AddUndo;
    end;
    WM_CUT:
    begin
      with StringGrid1.Selection do
      begin
        Clipboard.AsText:=GetText(Left, Top, Right-Left+1, Bottom-Top+1);
        DeleteCells(Left, Top, Right-Left+1, Bottom-Top+1);
      end;
      StringGrid1.Selection:=TGridRect(Rect(CurrX, CurrY, CurrX, CurrY));
      UpdateUndo;
    end;
    CM_MOUSELEAVE, WM_HSCROLL, WM_VSCROLL, WM_NCMOUSEMOVE:
      CancelHint;
  end;
  if not Handled then
  try
    Handled:=true;
    NextWndProc(Msg);
  except
    on e:EInvalidGridOperation do
      if e.Message<>SIndexOutOfRange then raise;
      // StringGrid bug
  end;
end;

procedure TForm1.StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then
    StringGrid1.Options:=StringGrid1.Options+[goEditing]+[goRangeSelect];
end;

procedure TForm1.Save;
begin
  if FileName='' then
    if not SaveAsSel then
      exit;
  RSSaveTextFile(FileName,GetText(0,0));
  wasChanged:=false;
end;

procedure TForm1.Save1Click(Sender: TObject);
begin
  Save;
end;

procedure TForm1.Open1Click(Sender: TObject);
begin
  OpenDialog1.FileName:=fileName;
  if not OpenDialog1.Execute then exit;
  if OpenDialog1.FileName=fileName then
  begin
    if RSMessageBox(Handle, Format(SReopenQuestion,[ExtractFileName(fileName)]),
         AppTitle, MB_ICONQUESTION or MB_YESNO) <> mrYes then
      exit;
  end else
    if not SaveQuery then exit;
  Load(OpenDialog1.FileName);
end;

procedure TForm1.Options1Click(Sender: TObject);
begin
  Associate1.Checked:= Association1.Associated;
  Associatewithert1.Checked:= AssociationERT.Associated;
  Associatewithers1.Checked:= AssociationERS.Associated;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure SendKeyboardLayout(Wnd, Msg:int; lParam:int=0; wParam:int=0);
var a:HKL; s:string;
begin
  SetLength(s,8);
  Win32Check(GetKeyboardLayoutName(ptr(s)));
  if s='00000409' then
  begin
    a:=ActivateKeyboardLayout(
         LoadKeyBoardLayout(ptr(intToHex(GetUserDefaultLangID,8)),0),0);
    if a=0 then RaiseLastOSError;
    SendMessage(Wnd, Msg, lParam, wParam);
    if ActivateKeyboardLayout(a,0)=0 then RaiseLastOSError;
  end else
    SendMessage(Wnd, Msg, lParam, wParam);
end;

procedure TForm1.Copy1Click(Sender: TObject);
begin
  SendKeyboardLayout(GetFocus, WM_COPY);
end;

function TForm1.CurrentEdit: TCustomEdit;
begin
  if StringGrid1.EditorMode then
    Result:= StringGrid1.InplaceEditor
  else
    Result:= Memo1;
end;

procedure TForm1.Cut1Click(Sender: TObject);
begin
  UpdateUndo;
  SendKeyboardLayout(GetFocus, WM_CUT);
end;

procedure TForm1.Paste1Click(Sender: TObject);
begin
  UpdateUndo;
  SendMessage(GetFocus, WM_PASTE, 0, 0);
end;

procedure TForm1.Undo1Click(Sender: TObject);
begin
  if Memo1.Focused or StringGrid1.Focused or StringGrid1.EditorMode then
    Undo
  else
    SendMessage(GetFocus, WM_UNDO, 0, 0);
end;

procedure TForm1.Redo1Click(Sender: TObject);
begin
  Redo;
end;

procedure TForm1.ReleaseUndo;
begin
  if UndoHit then
    AddUndo(true)
  else
    dec(UndoLock);
end;

procedure TForm1.Replace1Click(Sender: TObject);
begin
  StartFind(true);
end;

procedure TForm1.ReplaceAll;
var
  found: Boolean;
  edit: TCustomEdit;
  sel1, sel2: int;
  x, y: int;

  procedure ReplaceCell(cur: Boolean);
  var
    s, snew: string;
    dn, i: int;
  begin
    if cur then
      s:= edit.Text
    else
      s:= StringGrid1.Cells[x, y];

    i:= FindHelper.Find(s);
    if i < 0 then
      exit;

    if not found then
      UpdateUndo(true);
    found:= true;
      
    snew:= RSFindReplaceDialog1.ReplaceText;
    dn:= 0;
    if cur then
      dn:= length(snew) - length(FindHelper.SearchStr);

    repeat
      s:= copy(s, 1, i) + snew + copy(s, i + length(FindHelper.SearchStr) + 1);
      if dn <> 0 then
      begin
        if sel1 > i then  sel1:= max(i, sel1 + dn);
        if sel2 > i then  sel2:= max(i, sel2 + dn);
      end;
      i:= FindHelper.Find(s, i, length(snew));
    until i < 0;

    if cur then
    begin
      edit.Text:= s;
      RSEditSetSelection(edit, sel1, sel2);
    end else
      StringGrid1.Cells[x, y]:= s;
  end;

begin
  found:= false;
  edit:= CurrentEdit;
  if edit = Memo1 then
    Memo1.GetSelection(sel1, sel2)
  else
    RSEditGetSelection(edit, sel1, sel2, InplaceEditAnchor);

  for y := 0 to StringGrid1.RowCount - 1 do
    for x := 0 to leng[y] - 1 do
      ReplaceCell((y = currY) and (x = currX));

  if found then
    AddUndo(true);
end;

procedure TForm1.SelectAll1Click(Sender: TObject);
begin
  if Memo1.Focused then
    Memo1.SelectAll
  else
    if StringGrid1.EditorMode then
      InplaceEditor.SelectAll
    else
      with StringGrid1 do
        Selection:=TGridRect(Rect(0, 0, ColCount-1, RowCount-1));
end;

procedure TForm1.SelectColumn1Click(Sender: TObject);
var
  r: TGridRect;
begin
  r:= StringGrid1.Selection;
  r.Top:= 0;
  r.Bottom:= StringGrid1.RowCount;
  StringGrid1.Selection:= r;
end;

procedure TForm1.SelectRow1Click(Sender: TObject);
var
  r: TGridRect;
begin
  r:= StringGrid1.Selection;
  r.Left:= 0;
  r.Right:= StringGrid1.ColCount;
  StringGrid1.Selection:= r;
end;

procedure TForm1.SetLanguage(const v: string);
var
  s: string;
  i: int;
begin
  Caption:= SCaption;
  s:= AppPath + LangDir + v + '.txt';
  if not FileExists(s) then
  begin
    //if SameText(FLanguage, 'English') then  exit;
    FLanguage:= 'English';
    s:= AppPath + LangDir + 'English.txt';
  end else
    FLanguage:= v;
  RSLanguage.LoadLanguage(RSLanguage.LanguageBackup, true);
  try
    RSLanguage.LoadLanguage(RSLoadTextFile(s), true);
  except
  end;
  //RSSaveTextFile(AppPath + LangDir + 'tmp.txt', RSLanguage.CompareLanguage(RSLoadTextFile(s), RSLanguage.MakeLanguage));

  Undo2.Caption:=Undo1.Caption;
  Redo2.Caption:= Redo1.Caption;
  Cut2.Caption:= Cut1.Caption;
  Copy2.Caption:= Copy1.Caption;
  Paste2.Caption:= Paste1.Caption;
  SelectAll2.Caption:= SelectAll1.Caption;
  SStatusText:=StatusBar1.Panels[0].Text;
  SCaption:=Caption;
  AppTitle:= Application.Title;
  SetCaption;
  with RSHelp.Memo1 do
    Text:= RSStringReplace(Text, '%VERSION%', RSGetModuleVersion);

  for i := 0 to length(Toolbar) - 1 do
    if Toolbar[i] is TRSSpeedButton then
      with TRSSpeedButton(Toolbar[i]) do
        if Tag <> 0 then
          Hint:= StripHotkey(TMenuItem(Tag).Caption);
end;

procedure TForm1.InsertRow1Click(Sender: TObject);
begin
  if Memo1.Focused then
    RSSetFocus(StringGrid1)
  else
    if StringGrid1.Focused then
      AddXLine(CurrY);
end;

procedure TForm1.Language1Click(Sender: TObject);
var
  s: string;
  m: TMenuItem;
  i: int;
begin
  for i := Language1.Count - 1 downto 1 do
    Language1.Items[i].Free;

  English1.Checked:= SameText(FLanguage, 'English');
  with TRSFindFile.Create(AppPath + LangDir + '*.txt') do
    try
      while FindAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do
      begin
        s:= ChangeFileExt(Data.cFileName, '');
        if not SameText(s, 'English') then
        begin
          m:= TMenuItem.Create(self);
          m.RadioItem:= true;
          m.Caption:= s;
          m.OnClick:= English1Click;
          m.OnDrawItem:= English1.OnDrawItem;
          m.OnAdvancedDrawItem:= English1.OnAdvancedDrawItem;
          m.OnMeasureItem:= English1.OnMeasureItem;
          Language1.Add(m);
          m.Checked:= SameText(FLanguage, s);
        end;
        FindNext;
      end;
    finally
      Free;
    end;
end;

procedure TForm1.Load(fname: string);
var s:string;
begin
  if fname='' then  exit;

  if FileExists(fname) then
    Recent.Add(fname)
  else
    Recent.Delete(fname);

  s:= RSLoadTextFile(fname);
  try
    FileName:=fname;
    DoLoad(s);
  except
    wasChanged:=true;
    raise;
  end;
end;

procedure TForm1.DeleteRow1Click(Sender: TObject);
begin
  if StringGrid1.Focused then
    DelXLine;
end;

procedure TForm1.DoLoad(s: string);
var
  s1: string; i,j,k:integer; b:boolean;
begin
  with StringGrid1 do
    try
      Rows[0].BeginUpdate;
      Memo1.Clear;
      SetCaption;
      for j:=0 to RowCount do
        for i:=0 to ColCount do
          Cells[i,j]:='';
      SetLength(leng,2);
      leng[0]:=1;
      leng[1]:=0;
      RowCount:=2;
      ColCount:=2;

      PutText(s,0,0);

      EditY.MaxValue:=RowCount-1;
      i:= 0;
      for j:= 0 to min(RowCount-1, 2) do
      begin
        s1:= Cells[0,j];
        if not IsNumber(s1) and IsNumber(Cells[0,j+1]) or
           not IsNumber(Cells[1,j]) and IsNumber(Cells[1,j+1]) then
          if i > 0 then
          begin
            i:= 0;
            break;
          end else
            i:= j + 1;
      end;
      for j:= i to min(RowCount-1, 2) do
      begin
        s1:= Cells[0,j];
        if (s1 = '#') or (s1 = 'Name') or (s1 = 'Name$') or (s1 = 'Item #') or
           (s1 = 'Stats Descriptions') or (s1 = 'Bonus Stat') or
           (s1 = 'Singular') and (j = 1) and (Cells[0,0] = 'Name') then
          i:= j + 1;
      end;

      EditX.MaxValue:=StringGrid1.ColCount-1;
      if (ColCount>2) and IsNumber(Cells[0,i]) then
        EditX.Value:=1
      else
        EditX.Value:=0;

      while (i > 0) and (Cells[0,i-1] = '') and (Cells[1,i-1] = '') do
        dec(i);
      for j:= i-1 downto 0 do
        if (Cells[0,j] = '#') or (Cells[0,j] = 'Msg#') then
          i:= j + 1;
      EditY.Value:= i;

      if (EditX.Value = 0) and (EditY.Value <= 1) and
         ({(Cells[0,0] = '') or} (Cells[0,0] = 'Class') or (Cells[0,0] = 'Skill'))
         and (Cells[0,1] <> '') and (Cells[1,0] <> '') then
      begin
        EditX.Value:= 1;
        EditY.Value:= 1;
      end;

      FixedCols:=EditX.Value;
      FixedRows:=EditY.Value;

      TMyStringGrid(StringGrid1).FocusCell(EditX.Value, EditY.Value, true);
      CurrX:=EditX.Value;
      CurrY:=EditY.Value;
      StringGrid1SelectCell(nil, CurrX, CurrY, b);
      //MemoLoad(StringGrid1.Cells[CurrX,CurrY]);

      with Canvas do
      begin
        Font:= StringGrid1.Font;
        for i:=0 to StringGrid1.ColCount-1 do
        begin
          if s = '' then
            k:= DefaultColWidth
          else
            k:=10;
          for j:=length(leng)-1 downto 0 do
          begin
            k:=max(k, TextWidth(StringGrid1.Cells[i,j])+5);
          end;
          StringGrid1.ColWidths[i]:=min(k,StringGrid1.Width*2 div 3);
        end;
      end;
    finally
      Rows[0].EndUpdate;
    end;

  if Visible and not Memo1.Focused then
    RSSetFocus(StringGrid1);
  CurUndo:=-1;
  AddUndo;
  wasChanged:=false;
end;

procedure TForm1.AddRow1Click(Sender: TObject);
begin
  with StringGrid1 do
//    if Focused then
      AddXLine(RowCount);
end;

procedure TForm1.Associate1Click(Sender: TObject);
begin
  Association1.Associated:= not Associate1.Checked;
end;

procedure TForm1.Associatewithert1Click(Sender: TObject);
begin
  AssociationERT.Associated:= not Associatewithert1.Checked;
end;

procedure TForm1.Associatewithers1Click(Sender: TObject);
begin
  AssociationERS.Associated:= not Associatewithers1.Checked;
end;

procedure TForm1.InsertColumn1Click(Sender: TObject);
begin
//  if StringGrid1.Focused then
  StringGrid1.EditorMode:=false;
  AddYLine(CurrX);
end;

procedure TForm1.Delete1Click(Sender: TObject);
begin
  UpdateUndo;
  if Memo1.Focused then
    Memo1.SelText:= ''
  else if StringGrid1.EditorMode then
    InplaceEditor.SelText:= '';
end;

procedure TForm1.DeleteColumn1Click(Sender: TObject);
begin
//  if StringGrid1.Focused then
  StringGrid1.EditorMode:=false;
  DelYLine;
end;

procedure TForm1.AddColumn1Click(Sender: TObject);
begin
  with StringGrid1 do
//    if Focused then
      AddYLine(ColCount);
end;

procedure TForm1.SaveAs1Click(Sender: TObject);
begin
  if SaveAsSel then  Save;
end;

function TForm1.SaveAsSel: boolean;
begin
  SaveDialog1.FileName:=FileName;
  Result:=SaveDialog1.Execute;
  if Result then FileName:=SaveDialog1.FileName;
end;

function TForm1.SaveQuery: boolean;
var s:string;
begin
  Result:=true;
  if not wasChanged then  exit;

  if fileName='' then
    s:=SSaveQuestionUntitled
  else
    s:=Format(SSaveQuestion, [ExtractFileName(fileName)]);

  case RSMessageBox(Handle, s, AppTitle, MB_ICONQUESTION or MB_YESNOCANCEL) of
    mrYes:
    begin
      Result:=(fileName<>'') or SaveAsSel;
      if Result then  Save;
    end;

    mrCancel:
      Result:=false;
  end;
end;

procedure TForm1.New1Click(Sender: TObject);
begin
  if not SaveQuery then exit;
  FileName:='';
  DoLoad('');
end;

procedure TForm1.StringGrid1Enter(Sender: TObject);
begin
  StringGrid1.Color:=clWindow;
  Memo1.Color:=RSMixColors(clBtnFace, clWindow, 90);
  Undo1.Enabled:=CurUndo>0;
end;

procedure TForm1.Memo1Enter(Sender: TObject);
begin
  Memo1.Color:=clWindow;
  StringGrid1.Color:=RSMixColors(clBtnFace, clWindow, 90);
  Undo1.Enabled:=CurUndo>0;
end;

procedure TForm1.EditXChanged(Sender: TObject);
var x,y:integer;
begin
  if EditX.MaxValue = EditX.MinValue then
  begin
    EditX.Value:=EditX.MinValue;
    exit;
  end;
  x:=StringGrid1.Col;
  y:=StringGrid1.Row;
  if x<EditX.Value then x:=EditX.Value;
  TMyStringGrid(StringGrid1).FocusCell(x, y, true);
  StringGrid1.FixedCols:=EditX.Value;
  TMyStringGrid(StringGrid1).FocusCell(x, y, true);
  memoLoad(x,y);
//  UpdateUndo;
end;

procedure TForm1.EditYChanged(Sender: TObject);
var x,y:integer;
begin
  if EditY.MaxValue = EditY.MinValue then
  begin
    EditY.Value:=EditY.MinValue;
    exit;
  end;
  x:=StringGrid1.Col;
  y:=StringGrid1.Row;
  if y<EditY.Value then y:=EditY.Value;
  TMyStringGrid(StringGrid1).FocusCell(x, y, true);
  StringGrid1.FixedRows:=EditY.Value;
  TMyStringGrid(StringGrid1).FocusCell(x, y, true);
  memoLoad(x,y);
//  UpdateUndo;
end;

procedure TForm1.English1Click(Sender: TObject);
begin
  with TMenuItem(Sender) do
    if not Checked then
      Language:= StripHotkey(Caption);
end;

procedure TForm1.Memo1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  UpdateUndo;
  if (Key=VK_TAB) and (ssCtrl in Shift) then
    Key:=0;
  if (Key = VK_ESCAPE) and (Shift = []) then
    StringGrid1.SetFocus;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  Splitter1.Top:=0;
end;

procedure TForm1.Help1Click(Sender: TObject);
begin
  Perform(WM_HELP, 0, 0);
end;

procedure TForm1.WordWrap1Click(Sender: TObject);
begin
  WordWrap1.Checked:=not WordWrap1.Checked;
  WordWrapButton.Down:=WordWrap1.Checked;
  with Memo1 do
    if WordWrap1.Checked then
    begin
      WordWrap:=true;
      ScrollBars:=ssVertical;
    end else
    begin
      WordWrap:=false;
      ScrollBars:=ssBoth;
    end;
end;

procedure TForm1.StringGrid1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
label NoCell;
var s:string; p,p1:TPoint; r:TRect;
begin
  if PtInRect(LastMouseCellRect, Point(x,y)) then exit;
  with StringGrid1 do
  begin
    RSHideHint(false);
    if (x<0) or (y<0) or (x>=Width) or (y>=Height) or
       (GetForegroundWindow<>self.Handle) then
      goto NoCell;
    MouseToCell(x, y, x, y);
    if (x<0) or (y<0) or (GetKeyState(VK_LBUTTON) and 128<>0) or
       (GetKeyState(VK_MBUTTON) and 128<>0) or (x=currX) and (y=currY) then
      goto NoCell;
    LastMouseCellRect:=CellRect(x, y);
    inc(LastMouseCellRect.Right);
    inc(LastMouseCellRect.Bottom);
    s:=RSStringReplace(Cells[x,y], #10, #13#10);
    if s='' then goto NoCell;

    p:=ClientToScreen(LastMouseCellRect.TopLeft);
    dec(p.X);
    dec(p.Y);
    with LastMouseCellRect do
    begin
      p1.X:=Right-Left+3;
      p1.Y:=Bottom-Top-3;
    end;

    r:=HintWindow.CalcHintRect(Screen.Width, s, nil);
    if (r.Right<p1.X) and (r.Bottom<p1.Y) then
      exit;
    r.Bottom:=max(r.Bottom, p1.Y);
    r.Right:=max(r.Right, p1.X - 2);
    OffsetRect(r, p.X, p.Y);
    RSShowHint(s, r, MaxInt, true);
    exit;
  end;

NoCell:
  LastMouseCellRect.Left:=MaxInt;
end;

procedure TForm1.CancelHint;
begin
  LastMouseCellRect.Left:=MaxInt;
  RSHideHint(false);
end;

procedure TForm1.StringGrid1MouseWheelDown(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var i:int;
begin
  Handled:=true;
  for i:=Mouse.WheelScrollLines downto 1 do
    StringGrid1.Perform(WM_VSCROLL, SB_LINEDOWN, 0);
end;

procedure TForm1.StringGrid1MouseWheelUp(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var i:int;
begin
  Handled:=true;
  for i:=Mouse.WheelScrollLines downto 1 do
    StringGrid1.Perform(WM_VSCROLL, SB_LINEUP, 0);
end;

procedure TForm1.StringGrid1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TGridCoord;
begin
  if (Button = mbMiddle) and (@EnterReaderModeHelper<>nil) then
    EnterReaderModeHelper(StringGrid1.Handle);
  if Button = mbRight then
    with StringGrid1 do
    begin
      p:= MouseCoord(X, Y);
      if p.X >= 0 then
      begin
        if p.X < FixedCols then
          p.X:= FixedCols;
        if p.Y < FixedRows then
          p.Y:= FixedRows;
        TMyStringGrid(StringGrid1).FocusCell(p.X, p.Y, true);
      end;
    end;
  CancelHint;
end;

procedure TForm1.RecentClick(Sender:TRSRecent; Name:string);
begin
  if not SaveQuery then exit;
  Load(Name);
end;

procedure TForm1.File1Click(Sender: TObject);
begin
  Recent1.Visible:=Recent1.Count>0;
end;

procedure TForm1.Find(Replace: Boolean);
var
  edit: TCustomEdit;
  wnd: HWND;

  function OtherEndQuestion: Boolean;
  begin
    Result:= (RSMessageBox(Handle, SSearchOtherEnd, AppTitle,
       MB_OKCANCEL or MB_ICONINFORMATION) = ID_OK);
    SetForegroundWindow(wnd);
  end;

  function SelectInEdit(i: int): Boolean;
  begin
    Result:= true;
    edit.SelStart:= i;
    edit.SelLength:= length(FindHelper.SearchStr);
    edit.SetFocus;
    SetForegroundWindow(wnd);
  end;

  function FindInCell(x, y: int; OtherEnd: Boolean = false): Boolean;
  var
    i: int;
  begin
    i:= FindHelper.Find(StringGrid1.Cells[x, y]);
    Result:= (i >= 0);
    if Result and (not OtherEnd or OtherEndQuestion) then
    begin
      TMyStringGrid(StringGrid1).FocusCell(x, y, true);
      edit:= CurrentEdit;
      SelectInEdit(FindHelper.Find(edit.Text));
    end;
  end;

var
  s: string;
  i, x, y: int;
begin
  edit:= CurrentEdit;
  TEdit(edit).HideSelection:= false;
  wnd:= GetForegroundWindow;
  s:= edit.Text;
  i:= FindHelper.Find(s, edit.SelStart, edit.SelLength, Replace);
  Replace:= Replace and (i = edit.SelStart);
  if Replace then
  begin
    UpdateUndo(true);
    edit.SelText:= RSFindReplaceDialog1.ReplaceText;
    AddUndo(true);
    i:= FindHelper.Find(s, edit.SelStart, edit.SelLength);
  end;

  if (i >= 0) and SelectInEdit(i) then
    exit;

  if frDown in RSFindReplaceDialog1.Options then
  begin
    y:= CurrY;
    for x := CurrX + 1 to leng[y] - 1 do
      if FindInCell(x, y) then
        exit;

    for y := CurrY + 1 to StringGrid1.RowCount - 1 do
      for x := 0 to leng[y] - 1 do
        if FindInCell(x, y) then
          exit;

    if Replace then  exit;

    for y := 0 to CurrY - 1 do
      for x := 0 to leng[y] - 1 do
        if FindInCell(x, y, true) then
          exit;

    y:= CurrY;
    for x := 0 to CurrX - 1 do
      if FindInCell(x, y, true) then
        exit;
  end else
  begin
    y:= CurrY;
    for x := CurrX - 1 downto 0 do
      if FindInCell(x, y) then
        exit;

    for y := CurrY - 1 downto 0 do
      for x := leng[y] - 1 downto 0 do
        if FindInCell(x, y) then
          exit;

    if Replace then  exit;

    for y := StringGrid1.RowCount - 1 downto CurrY + 1 do
      for x := leng[y] - 1 downto 0 do
        if FindInCell(x, y, true) then
          exit;

    y:= CurrY;
    for x := leng[y] - 1 downto CurrX + 1 do
      if FindInCell(x, y, true) then
        exit;
  end;

  i:= FindHelper.Find(s, edit.SelStart, edit.SelLength, false, true);
  if (i >= 0) and OtherEndQuestion then
    SelectInEdit(i);
  if i >= 0 then
    exit;

  RSMessageBox(Handle, Format(SSearchNotFound, [RSFindReplaceDialog1.FindText]),
     AppTitle, MB_ICONINFORMATION);
  SetForegroundWindow(wnd);
end;

procedure TForm1.Find1Click(Sender: TObject);
begin
  StartFind(false);
end;

procedure TForm1.FindNext1Click(Sender: TObject);
begin
  if FindHelper.SearchStr = '' then
    StartFind(false)
  else
    Find(false);
end;

procedure TForm1.RSWinController2WndProc(Sender: TObject;
  var Msg: TMessage; var Handled: Boolean; const NextWndProc: TWndMethod);
begin
  if Msg.Msg = WM_KEYDOWN then
    UpdateUndo; // Можно и после NextWndProc
  if (Msg.Msg = WM_CHAR) and (TWMChar(Msg).CharCode >= 32) then
    try
      IsCharInput:= true;
      NextWndProc(Msg);
    finally
      IsCharInput:= false;
    end
  else if Msg.Msg = WM_PASTE then
    try
      UpdateUndo(true);
      NextWndProc(Msg);
    finally
      ReleaseUndo;
    end
  else
    NextWndProc(Msg);
  Handled:=true;
  RSEditWndProcAfter(InplaceEditor, Msg, InplaceEditAnchor);
end;

procedure TForm1.Memo1Exit(Sender: TObject);
begin
  Undo1.Enabled:= CurUndo>0;
end;

procedure TForm1.Memo1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var b:boolean; i:int;
begin
  with Sender as TCustomEdit do
  begin
    Undo2.Enabled:=Undo1.Enabled;
    Redo2.Enabled:=Redo1.Enabled;
    i:=SelLength;
    b:= i>0;
    Cut2.Enabled:=b;
    Copy2.Enabled:=b;
    Delete1.Enabled:=b;
    Paste2.Enabled:=Clipboard.HasFormat(CF_TEXT);
    SelectAll2.Enabled:=i<GetWindowTextLength(Handle);
  end;
end;

procedure TForm1.StringGrid1CreateEditor(Sender: TStringGrid;
  var Editor: TInplaceEdit);
begin
  InplaceEditAnchor:=0;
  Form1.RSWinController2.Control:=Editor;
  TEdit(Editor).PopupMenu:=Form1.PopupMenu1;
  TEdit(Editor).OnContextPopup:=Form1.Memo1ContextPopup;
  TEdit(Editor).HideSelection:= false;
end;

initialization
  RSLoadProc(@EnterReaderModeHelper, user32, 'EnterReaderModeHelper');

end.
