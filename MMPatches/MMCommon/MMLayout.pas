unit MMLayout;

interface

uses
  Forms, Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Math, Types,
  RSStrUtils, RSSimpleExpr, MMSystem;

type
  TLayoutParam = (lpCond, lpX, lpY, lpW, lpH, lpNX, lpNY, lpNW, lpNH, lpCmdFmt);
  TLayoutCmd = (lcArea, lcScreen, lcVar, lcDefault, lcPersist, lcIf, lcFor, lcLoop,
     lcRecover, lcCheckVer, lcErase, lcStage, lcTimer, lcAction);
  TDrawKind = (ldkTransparent, ldkNone, ldkOpaque, ldkBehind, ldkErase, ldkAnd, ldkOverlay, ldkNot);
  TClickKind = (lckTransparent, lckNone, lckOpaque);
  TIfOp = (lioNone, lioElse, lioAnd, lioOr, lioXor);
  TIfUOp = (liuNone, liuEmpty, liuOnce, liuHover, liuDown);
  ELayoutException = class(Exception);

  TLayoutStrItem = record
    Params: array[TLayoutParam] of TRSOperatorArray;
    Cmd: TLayoutCmd;
    CmdParam, CmdParam2: string;
    IconLoaded: int;
    Canvas, NewCanvas, MainCanvas: int;
    Click: TClickKind;
    Draw: TDrawKind;
    DrawColor: Word;
    IfOp: TIfOp;
    IfUOp: TIfUOp;
    Line, Jump, JumpLast: int;
    Computed: ext;
  end;

  PLayoutItem = ^TLayoutItem;
  TLayoutItem = record
    Base, New: TRect;
    Icon: string[16];
    IconLoaded: int;
    Canvas, NewCanvas, IfCanvas: int;
    IfXY: TPoint;
    IfId: int;
    IfOp: TIfOp;
    IfUOp: TIfUOp;
    Click: TClickKind;
    Draw: TDrawKind;
    DrawColor: Word;
    Line, Stage: int;
    Visible: Boolean;  // used by TDrawLayout
  end;
  TLayoutItems = array of TLayoutItem;

  TLayoutCanvas = record
    Size: TPoint;
    Persist, Recovered, Fixed: Boolean;
  end;

  TLayoutAction = record
    Canvas: int;
    X, Y: int;
  end;

  TLayout = class
  protected
    CanvasNames: TStringList;
    Stages: TStringList;
    Def: array of TLayoutStrItem;
    TmpItems: TLayoutItems;
    VarNames: TStringList;
    VarVals: array[0..1] of array of ext;
    ScreenSize: array[0..1] of ext;
    ScreenScale: array[0..1] of ext;
    CurCanvasSize: array[0..1] of ext;
    ElSize: array[0..1] of ext;
    QVarVertical: int;
    procedure Error(const str: string; line: int);
    function CustomOp(const s: string; var k: int; var op: TRSOperator; kind: TRSCustomOpKind): Boolean;
    procedure ReadExpr(const s: string; var a: TRSOperatorArray; row, col: int);
    procedure SetVar(const Name: string; idx: int; v: ext);
    function GetVar(const Name: string; idx: int): ext;
    function GetQVar(const s: string; var v: ext): Boolean;
    function GetVar2(const Name: string; idx: ptr): ext;
    procedure SetVarEx(const Name: string; v: ext; default: Boolean);
    procedure SetupScreen(w, h: ext);
    procedure UseCanvas(i: int; JustGet: Boolean);
    function MyFormat(const s: string; v: ext): string;
    procedure DoUpdate(JustLimits: Boolean);
  public
    Updated: Boolean;
    UpdateId: int;
    MinWidth, MinHeight, DefaultCanvas: int;
    Items: TLayoutItems;
    Canvases: array of TLayoutCanvas;
    Actions: array of TLayoutAction;
    OnLoadIcon: procedure(const Name: string; var Loaded: Integer; out w, h: Extended) of object;
    OnDefaultValue: procedure(const Name: string; v: Extended) of object;
    OnCanAdd: procedure(var it: TLayoutItem; var add: Boolean) of object;
    OnUnsetVar: procedure(const Name: string; write: Boolean) of object;
    constructor Create;
    destructor Destroy; override;
    function AddCanvas(const Name: string): int;
    procedure DoRead(const ss: string);
    procedure Read(const fname: string);
    function Update(JustLimits: Boolean = false): Boolean;
    function HasVar(const Name: string): Boolean;
    property Vars[const Name: string]: ext index 0 read GetVar write SetVar;
    property Locals[const Name: string]: ext index 1 read GetVar write SetVar;
  end;

  TDrawCanvas = record
    Buf: TWordDynArray;
    CurSize: TPoint;
    // for constant canvases:
    OpIcon: int;
    OpBase, OpNew: TRect;
    OpDraw: TDrawKind;
    OpDirty: Boolean;
  end;

  TDrawLayout = class
  protected
    OwnLayout: Boolean;
    DrawCanvas: array of TDrawCanvas;
    Icons: array of TWordDynArray;
    IconSize: array of TPoint;
    IconNames: TStringList;
    UpdateId: int;
    procedure LoadIcon(const Name: string; var n: int; out wf, hf: ext);
    procedure CheckCleanCanvas(c: int);
    function CheckConstCanvas(const it: TLayoutItem): Boolean;
    function CanvasInfo(c: int; var d: int): ptr; overload;
    function CanvasInfo(const it: TLayoutItem; var d: int): ptr; overload;
    function CheckPixel(c: int; x, y: int): Boolean;
    procedure DrawTimer(const it: TLayoutItem);
    procedure DoDrawItem(const it: TLayoutItem);
    procedure SetMouseDown(v: Boolean);
  public
    Layout: TLayout;
    FixedCanvases: array of ptr;
    PressCanvas, MouseCanvas: int;
    OnLoadIcon: procedure(const Name: string; var a: TWordDynArray; out w: int) of object;
    OnDrawArea: procedure(const Item: TLayoutItem; Buf: ptr; Stride: int) of object;
    OnBeforeDraw: procedure(var Item: TLayoutItem; OnlyVirtual: Boolean) of object;
    constructor Create(ALayout: TLayout = nil; Own: Boolean = true);
    destructor Destroy; override;
    procedure Draw(OnlyVirtual: Boolean = false);
    function HitTest(var x, y: int): Boolean;
    function AddFixedCanvas(const Name: string; p: ptr; w, h: int): int;
    procedure ClearCache;
    property MouseDown: Boolean write SetMouseDown;
  end;

procedure Draw16(ps, pd: PWord; ds, dd, w, h: int; c0: Word; Kind: TDrawKind);
procedure TileDraw16(ps, pd: PWord; ds, dd, ws, hs, wd, hd: int; c0: Word; Kind: TDrawKind);
function FindContextMenu(p: ptr; c0: Word): TRect;

const
  lvWidth = 'Game.Width';
  lvHeight = 'Game.Height';
  lvMinWidth = 'Game.MinWidth';
  lvMinHeight = 'Game.MinHeight';
  lvMinScale = 'Game.MinScale';
  lvScreen = 'Game.Screen';
  lvRenderedScreen = 'Game.RenderedScreen';
  lvMainMenuCode = 'Game.MainMenuCode';
  lvLoading = 'Game.Loading';
  lvPlayers = 'Game.Players';
  lvTopbar2 = 'Game.Topbar2';
  lvNeutral = 'Game.Neutral';
  lvGood = 'Game.Good';
  lvEvil = 'Game.Evil';
  lvTextColor = 'Game.TextColor';
  lvTextShadowColor = 'Game.TextShadowColor';
  lvOpaqueScreen = 'Game.OpaqueScreen';
  lvFullScreen = 'Game.FullScreen';
  lvArcomage = 'Game.Arcomage';
  lvMoviePlaying = 'Game.VideoPlaying';
  lvCustomRightSide = 'Game.CustomRightSide';
  lvPaperDollInChests = 'Game.PaperDollInChests';
  lvRenderCenterX = 'Game.RenderCenterX';
  lvRenderCenterY = 'Game.RenderCenterY';
  lvFOVMul = 'Game.FOVMul';
  lvDebug = 'Game.dbg';
  lvUpdateCountdown = 'Game.UpdateCountdown';
  lvReloadLayout = 'Game.ReloadLayout';
  lvVersion = 'Game.Version';
  lvKeyPressed = 'KeyPressed.';
  CanvasScreen = -1;
  CanvasTimer = -2;
  CanvasBase = 0;       lvcBase = 'Game.BaseUI';
  CanvasRender = 1;  lvcRender = 'Game.Render';
  CanvasStatus = 2;  lvcStatus = 'Game.Status';
  CanvasPopup = 3;      lvcPopup = 'Game.RightButtonMenu';
  CanvasMouseItem = 4;  lvcMouseItem = 'Game.MouseItem';
  CanvasLockMouse = 5;  lvcLockMouse = 'Game.LockMouse';
  CanvasPopupArea = 6;  lvcPopupArea = 'Game.RightButtonMenuArea';
  CanvasPopupArea2 = 7;  lvcPopupArea2 = 'Game.RightButtonMenuArea2';
  CanvasPartyBuffs = 8;  lvcPartyBuffs = 'Game.PartyBuffs';
  CanvasMax = 8;
  TransparentColor16 = $FFFF shr 5;

implementation

const
  ParamNames: array[TLayoutParam] of string =
     ('Condition', 'X', 'Y', 'Width', 'Height', 'NewX', 'NewY', 'NewWidth', 'NewHeight', 'Format');
  CmdName: array[TLayoutCmd] of string = ('icon', 'screen', 'var', 'default',
     'persist', 'if', 'for', 'loop', 'recover', 'version', 'erase', 'stage', 'timer', 'action');
  DrawName: array[TDrawKind] of string = ('', '-', '+', 'behind', 'erase', 'and', 'overlay', 'not');
  ClickName: array[TClickKind] of string = ('', '-', '+');
  IfOpName: array[TIfOp] of string = ('', 'else', 'and', 'or', 'xor');
  IfUOpName: array[TIfUOp] of string = ('', 'empty', 'once', 'hover', 'down');

  Delta = 1e-12;  // round 0.500000000001 down to 0

function FindStr(const s: string; var r; const a: array of string): Boolean;
var
  i: int1;
begin
  Result:= true;
  for i:= high(a) downto low(a) do
  begin
    int1(r):= i;
    if SameText(s, a[i]) then  exit;
  end;
  Result:= false;
end;

function ToColor16(v: int): Word;
begin
  Result:= (v and $F8) shr 3 + (v and $FC00) shr 5 + (v and $F80000) shr 8;
end;

{ TLayout }

function TLayout.AddCanvas(const Name: string): int;
begin
  with CanvasNames do
    Result:= int(Objects[AddObject(Name, ptr(Count))]);
  if Result >= length(Canvases) then
    SetLength(Canvases, Result + 1);
end;

constructor TLayout.Create;
begin
  CanvasNames:= TStringList.Create;
  with CanvasNames do
  begin
    CaseSensitive:= true;
    Duplicates:= dupIgnore;
    Sorted:= true;
  end;
  VarNames:= TStringList.Create;
  with VarNames do
  begin
    CaseSensitive:= true;
    Duplicates:= dupIgnore;
    Sorted:= true;
  end;
  Stages:= TStringList.Create;
  Stages.CaseSensitive:= true;
  Stages.Add('');
  Vars['Game.LayoutEngine']:= 1;
end;

const
  PushOp: TRSOperator = (Priority: 127; Op: RSotPush);

function ReadStr(const s: string; var k0: int; var op: TRSOperator): Boolean;
var
  GoOn: Boolean;
  i, k: int;
  v: uint64;
begin
  Result:= false;
  GoOn:= true;
  k:= k0;
  v:= 0;
  for i:= 0 to 7 do
  begin
    v:= v*256;
    if GoOn then
    begin
      inc(k);
      if s[k] = #0 then  exit;
      if (s[k] = '"') and (s[zSet(k, k+1)] <> '"') then
      begin
        k0:= k;
        GoOn:= false;
      end else
        inc(v, ord(s[k]));
    end;
  end;
  op:= PushOp;
  op.Val:= v;
  Result:= true;
end;

function ReadColor(const s: string; var k: int; var op: TRSOperator): Boolean;
var
  p: PChar;
  v, code: int;
begin
  p:= @s[k + 1];
  v:= RSStrToIntVar(p, @code, 16);
  Result:= (code mod 4 = 0);
  if not Result then  exit;
  op:= PushOp;
  op.Val:= ToColor16(v);
  k:= p - @s[1] + 1;
end;

function TLayout.CustomOp(const s: string; var k: int; var op: TRSOperator;
  kind: TRSCustomOpKind): Boolean;
begin
  Result:= false;
  if kind <> RSokValue then
    exit;
  if s[k] = '"' then
    Result:= ReadStr(s, k, op)
  else if s[k] = '#' then
    Result:= ReadColor(s, k, op);
end;

procedure TLayout.DoUpdate(JustLimits: Boolean);
const
  EmptyItem: TLayoutItem = (IconLoaded: -1; Click: lckNone; Draw: ldkNone);
var
  IfXY: TPoint;
  x, y: ext;
  i, IfId, stag, n: int;
  IfCond, IfUsed: Boolean;
  IfItem: ^TLayoutStrItem;

  function Calc(param: TLayoutParam; default: ext = 0): ext;
  begin
    if Def[i].Params[param] = nil then
      Result:= default
    else
      Result:= RSCalcExpr(Def[i].Params[param], GetVar2, ptr(1));
  end;

  procedure XY(param, param2: TLayoutParam; var x, y: ext; def1: ext = 0; def2: ext = 0);
  var
    tmp: ext;
  begin
    tmp:= Calc(param, def1);
    QVarVertical:= 1;
    y:= Calc(param2, def2);
    QVarVertical:= 0;
    x:= tmp;
  end;

  function CheckCond: Boolean;
  begin
    Result:= IfCond and (Calc(lpCond, 1) <> 0);
  end;

  function Fmt(const s: string): string;
  begin
    if Def[i].Params[lpCmdFmt] = nil then
      Result:= s
    else
      Result:= MyFormat(s, Calc(lpCmdFmt));
  end;

  procedure StoreRect(var r: TRect; canvas: int; check: Boolean = false);
  var
    mx, my: ext;
  begin
    mx:= 1;
    my:= 1;
    if canvas = CanvasScreen then
    begin
      mx:= ScreenScale[0];
      my:= ScreenScale[1];
    end;
    r.Left:= Round(x*mx - Delta);
    r.Top:= Round(y*my - Delta);
    r.Right:= Round((x + ElSize[0])*mx - Delta);
    r.Bottom:= Round((y + ElSize[1])*my - Delta);
    if (canvas <> CanvasScreen) and ((r.Left < 0) or (r.Top < 0)) then
      Error(Format('Negative coordinate: (%d, %d .. %d, %d)',
         [r.Left, r.Top, r.Right, r.Bottom]), Def[i].Line);
    if check and (canvas >= 0) then
      with r, Canvases[canvas].Size do
        if Canvases[canvas].Recovered then
        begin
          Right:= min(Right, X);
          Bottom:= min(Bottom, Y);
        end else
        begin
          X:= max(Right, X);
          Y:= max(Bottom, Y);
        end;
  end;

  procedure SetIf(var a: TLayoutItem);
  begin
    a.Stage:= stag;
    a.IfXY:= IfXY;
    a.IfId:= IfId;
    if IfItem <> nil then
      with IfItem^ do
      begin
        a.IfCanvas:= Canvas;
        a.IfUOp:= IfUOp;
        a.IfOp:= IfOp;
      end;
  end;

  function NewItem: PLayoutItem;
  begin
    if n >= length(TmpItems) then
      SetLength(TmpItems, n + length(Def));
    Result:= @TmpItems[n];
    inc(n);
  end;

  function AddItem(var a: TLayoutItem): Boolean;
  begin
    with Def[i] do
    begin
      a.Icon:= Fmt(CmdParam);
      if CmdParam <> '' then
        OnLoadIcon(a.Icon, IconLoaded, CurCanvasSize[0], CurCanvasSize[1])
      else
        UseCanvas(Canvas, true);
      XY(lpW, lpH, ElSize[0], ElSize[1], CurCanvasSize[0], CurCanvasSize[1]);
      ElSize[0]:= min(ElSize[0], CurCanvasSize[0]);
      ElSize[1]:= min(ElSize[1], CurCanvasSize[1]);
      XY(lpX, lpY, x, y);
      ElSize[0]:= min(ElSize[0], CurCanvasSize[0] - x);
      ElSize[1]:= min(ElSize[1], CurCanvasSize[1] - y);
      StoreRect(a.Base, Canvas);

      UseCanvas(NewCanvas, false);
      XY(lpNW, lpNH, ElSize[0], ElSize[1], ElSize[0], ElSize[1]);
      XY(lpNX, lpNY, x, y);
      StoreRect(a.New, NewCanvas, true);

      UseCanvas(CanvasScreen, true);
      a.IconLoaded:= IconLoaded;
      a.Canvas:= Canvas;
      a.NewCanvas:= NewCanvas;
      a.Click:= Click;
      a.Draw:= Draw;
      a.DrawColor:= DrawColor;
      a.Line:= Line;
      if Params[lpCmdFmt] <> nil then
        IconLoaded:= -1;
    end;
    SetIf(a);
    Result:= not IsRectEmpty(a.Base) and not IsRectEmpty(a.New);
    IfUsed:= IfUsed or Result;
  end;

  procedure AddEmptyItem(var a: TLayoutItem);
  begin
    a:= EmptyItem;
    a.Line:= IfItem^.Line;
    SetIf(a);
  end;

  // timer StatesCount Delay   (NewCanvas)
  function AddTimer(var a: TLayoutItem): Boolean;
  begin
    AddEmptyItem(a);
    with Def[i] do
    begin
      UseCanvas(Canvas, true);
      XY(lpX, lpY, x, ElSize[0]);
      a.Base:= Rect(0, 0, Round(x - Delta), 1);
      x:= 0;
      y:= 0;
      ElSize[1]:= 1;
      UseCanvas(NewCanvas, false);
      if NewCanvas = CanvasScreen then
        Error('Timer canvas not specified', Line);
      StoreRect(a.New, NewCanvas, true);
      UseCanvas(CanvasScreen, true);
      a.Canvas:= CanvasTimer;
      a.NewCanvas:= NewCanvas;
      a.Draw:= ldkOpaque;
      a.Line:= Line;
    end;
    Result:= not IsRectEmpty(a.Base) and not IsRectEmpty(a.New);
    IfUsed:= IfUsed or Result;
  end;

  procedure EraseStage(n: int; k: int);
  var
    i: int;
  begin
    for i:= 0 to n - 1 do
      if TmpItems[i].Stage = k then
        TmpItems[i].Stage:= -1;
  end;

  procedure EraseCanvas(n: int; k: int);
  var
    i: int;
  begin
    for i:= 0 to n - 1 do
      with TmpItems[i] do
        if (Canvas = k) or (NewCanvas = k) or (IfCanvas = k) and (IfXY.X >= 0) then
          Stage:= -1;
  end;

  procedure EraseDraw(n: int; k1, k2: int);
  var
    i: int;
  begin
    for i:= 0 to n - 1 do
      with TmpItems[i] do
        if (Canvas = k1) and (NewCanvas = k2) then
          Stage:= -1;
  end;

var
  j: int;
  InScreen, CanAdd: Boolean;
begin
  for i:= 0 to high(Canvases) do
    with Canvases[i] do
    begin
      Persist:= true;
      Recovered:= JustLimits or Fixed;
    end;
  FillChar(ScreenSize, SizeOf(ScreenSize), 0);
  SetLength(TmpItems, length(Def));
  UseCanvas(CanvasScreen, true);
  InScreen:= false;
  stag:= 0;
  n:= 0;
  IfCond:= true;
  IfXY.X:= -1;
  IfXY.Y:= -1;
  IfId:= 0;
  IfItem:= nil;
  IfUsed:= true;
  if JustLimits then
  begin
    Locals[lvMinWidth]:= Canvases[0].Size.X;
    Locals[lvMinHeight]:= Canvases[0].Size.Y;
  end;
  Actions:= nil;
  i:= -1;
  while zSet(i, i + 1) < length(Def) do
    with Def[i] do
    try
      FillChar(ElSize, SizeOf(ElSize), 0);
      QVarVertical:= 0;
      case Cmd of
        lcIf:
        begin
          IfCond:= (Calc(lpCond, 1) <> 0);
          if JustLimits or not IfCond then
            continue;
          if (IfOp <> lioNone) and not IfUsed then
            AddEmptyItem(NewItem^);
          UseCanvas(Canvas, true);
          XY(lpX, lpY, x, y, -1, 0);
          IfXY.X:= Round(x - Delta);
          IfXY.Y:= Round(y - Delta);
          if (IfXY.X >= 0)  and ((IfXY.X >= CurCanvasSize[0]) or
                 (IfXY.Y < 0) or (IfXY.Y >= CurCanvasSize[1])) then
            IfXY.X:= -1;
          UseCanvas(CanvasScreen, true);
          inc(IfId);
          IfItem:= @Def[i];
          IfUsed:= not InScreen;
        end;
        lcFor:
          if CheckCond then
          begin
            if CmdParam <> '' then
            begin
              UseCanvas(MainCanvas, true);
              x:= Calc(lpNX, Calc(lpX));
              Computed:= Calc(lpNY, Calc(lpY, x));
              UseCanvas(CanvasScreen, true);
              Locals[CmdParam]:= x;
              if x > Computed then
                i:= Jump - 1;
            end;
          end else
            i:= Jump - 1;
        lcLoop:
          if CheckCond then
          begin
            with Def[Jump] do
              if CmdParam <> '' then
              begin
                x:= Locals[CmdParam] + 1;
                Locals[CmdParam]:= x;
                if x > Computed then
                  continue;
              end;
            i:= Jump;
          end;
        lcVar, lcDefault:
          if CheckCond then
          begin
            UseCanvas(MainCanvas, true);
            XY(lpX, lpY, x, y);
            XY(lpNX, lpNY, x, y, x, y);
            UseCanvas(CanvasScreen, true);
            SetVarEx(Fmt(CmdParam), x, Cmd = lcDefault);
            if CmdParam2 <> '' then
              SetVarEx(Fmt(CmdParam2), y, Cmd = lcDefault);
          end;
        lcPersist:
          if not JustLimits and CheckCond then
            Vars[Fmt(CmdParam)]:= Locals[Fmt(CmdParam)];
        lcScreen:
          if JustLimits or CheckCond then
          begin
            InScreen:= true;
            XY(lpW, lpH, x, y, ScreenSize[0], ScreenSize[1]);
            XY(lpNX, lpNY, x, y, x, y);
            XY(lpNW, lpNH, x, y, x, y);
            SetupScreen(x, y);
            if JustLimits then
            begin
              Locals[lvMinWidth]:= max(Locals[lvMinWidth], x);
              Locals[lvMinHeight]:= max(Locals[lvMinHeight], y);
            end;
          end else
            InScreen:= false;
        lcArea:
          if not JustLimits and InScreen and CheckCond then
          begin
            CanAdd:= AddItem(NewItem^);
            if Assigned(OnCanAdd) then
              OnCanAdd(TmpItems[n - 1], CanAdd);
            if not CanAdd then
              dec(n);
          end;
        lcRecover:
          if not JustLimits and InScreen and CheckCond then
            with Canvases[Canvas] do
            begin
              Recovered:= true;
              if not Fixed then
              begin
                XY(lpW, lpH, x, y, Size.X, Size.Y);
                Size.X:= Round(x + Delta);
                Size.Y:= Round(y + Delta);
              end;
            end;
        lcStage:
          if not JustLimits and CheckCond then
            stag:= Stages.IndexOf(CmdParam);
        lcErase:
          if not JustLimits and CheckCond then
            if SameText(CmdParam, 'stage') then
              EraseStage(n, Stages.IndexOf(CmdParam2))
            else if SameText(CmdParam, 'canvas') then
              EraseCanvas(n, MainCanvas)
            else if SameText(CmdParam, 'draw') then
              EraseDraw(n, Canvas, NewCanvas);
        lcTimer:
          if not JustLimits and InScreen and CheckCond then
            AddTimer(NewItem^);
        lcAction:
          if not JustLimits and InScreen and CheckCond then
          begin
            j:= length(Actions);
            SetLength(Actions, j + 1);
            Actions[j].Canvas:= Canvas;
            Actions[j].X:= Round(Calc(lpNX, Calc(lpX)));
            Actions[j].Y:= Round(Calc(lpNY, Calc(lpY)));
          end;
      end;
    except
      on e: ELayoutException do
        raise;
      on e: Exception do
        Error(e.Message, Line);
    end;

  FillChar(ElSize, SizeOf(ElSize), 0);
  if JustLimits then
  begin
    MinWidth:= Ceil(Locals[lvMinWidth]);
    MinHeight:= Ceil(Locals[lvMinHeight]);
  end else
  begin
    SetLength(Items, n);
    i:= 0;
    for stag:= 0 to Stages.Count - 1 do
      for j:= 0 to n - 1 do
        if TmpItems[j].Stage = stag then
        begin
          Items[i]:= TmpItems[j];
          inc(i);
        end;
    SetLength(Items, i);
  end;
end;

procedure TLayout.Error(const str: string; line: int);
begin
  raise ELayoutException.CreateFmt('UI Layout, line %d: %s', [line, str]);
end;

function QVarKind(c: Char): int; inline;
begin
  case c of
    'R','L': Result:= 1;
    'T','B': Result:= 2;
    'C':     Result:= 0;
    else     Result:= 4;
  end;
end;

function QVarMul(c: Char): ext; inline;
begin
  case c of
    'R','B': Result:= 1;
    'C':     Result:= 0.5;
    else     Result:= 0;
  end;
end;

function TLayout.GetQVar(const s: string; var v: ext): Boolean;
var
  c1, c2: char;
  i, k: int;
begin
{ QVars:
LL, LC, LR, L
RL, RC, RR, R
CL, CC, CR, C
}
  Result:= false;
  i:= length(s);
  if not (i in [1, 2]) then  exit;
  c1:= s[1];
  c2:= s[i];
  k:= (QVarKind(c1) or QVarKind(c2)) - 1;
  if k > 1 then  exit;
  if k < 0 then  k:= QVarVertical;
  v:= CurCanvasSize[k]*QVarMul(c1) - ElSize[k]*QVarMul(c2);
  Result:= true;
end;

function TLayout.GetVar(const Name: string; idx: int): ext;
var
  i: int;
begin
  if not GetQVar(Name, Result) then
    if not VarNames.Find(Name, i) then
    begin
      Result:= 0;
      if Assigned(OnUnsetVar) then
        OnUnsetVar(Name, false);
    end else
      Result:= VarVals[idx][int(VarNames.Objects[i])]
end;

function TLayout.GetVar2(const Name: string; idx: ptr): ext;
begin
  Result:= GetVar(Name, int(idx));
end;

function TLayout.HasVar(const Name: string): Boolean;
begin
  Result:= VarNames.IndexOf(Name) >= 0;
end;

function TLayout.MyFormat(const s: string; v: ext): string;
var
  s0, s1: array[0..8] of char;
  i: int;
begin
  Result:= '';
  if s = '' then  exit;
  i:= 1;
  while (s[i] <> '%') or (s[zSet(i, i + 1)] = '%') do
    inc(i);
  while not (s[i] in ['a'..'z', 'A'..'Z', #0]) do
    inc(i);
  case s[i] of
    'd', 'D', 'u', 'U', 'x', 'X':
      Result:= Format(s, [Round(v - Delta)]);
    'p', 'P':
      Result:= Format(s, [ptr(Round(v - Delta))]);
    's', 'S':
    begin
      if v >= $80000000*2.0*$80000000 then
        v:= v - $80000000*4.0*$80000000;
      pint64(@s0[0])^:= Round(v - Delta);
      for i:= 7 downto 0 do
        s1[i]:= s0[7 - i];
      s1[8]:= #0;
      Result:= Format(s, [PChar(@s1)]);
    end;
    else
      Result:= Format(s, [v]);
  end;
end;

procedure TLayout.Read(const fname: string);
begin
  DoRead(RSLoadTextFile(fname));
end;

procedure TLayout.ReadExpr(const s: string; var a: TRSOperatorArray; row,
  col: int);
const
  ParseError: array[Boolean] of string = ('Syntax error', 'Unfinished expression');
var
  i: int;
begin
  i:= RSParseExpr(s, a, CustomOp, true);
  if i <> 0 then
    raise EParserError.CreateFmt('UI layout: %s at line %d column %d: %s',
       [ParseError[i > length(s)], row, col, Copy(s, (i-1) mod length(s) + 1, MaxInt)]);
end;

function FindCaption(const ps: TRSParsedString; const s: string): int;
begin
  Result:= RSGetTokensCount(ps, true);
  while (Result >= 0) and not SameText(RSGetToken(ps, Result), s) do
    dec(Result);
end;

destructor TLayout.Destroy;
begin
  CanvasNames.Free;
  inherited;
end;

procedure TLayout.DoRead(const ss: string);
var
  ps, ps2, ps3: TRSParsedString;
  use: Boolean;

  function Get(pos: int): string;
  begin
    Result:= RSGetToken(ps2, pos);
    use:= use or (Result <> '');
  end;

  function Canv(const s: string; def: int): int;
  begin
    Result:= def;
    if s <> '' then
      with CanvasNames do
        Result:= int(Objects[AddObject(s, ptr(Count))]);
  end;

var
  ParamPos: array[TLayoutParam] of int;
  lp: TLayoutParam;
  CmdPos, ClickPos, DrawPos, CanvasPos, NewCanvasPos, ForLine: int;
  skip: Boolean;
  i, j, k, stag: int;
begin
  Assert(CanvasNames.Count > 0);
  ps:= RSParseString(ss, [#13#10]);
  ps2:= RSParseToken(ps, 0, [#9]);
  for lp:= low(TLayoutParam) to high(TLayoutParam) do
    ParamPos[lp]:= FindCaption(ps2, ParamNames[lp]);
  CmdPos:= FindCaption(ps2, 'Command');
  ClickPos:= FindCaption(ps2, 'Click');
  DrawPos:= FindCaption(ps2, 'Draw');
  CanvasPos:= FindCaption(ps2, 'Canvas');
  NewCanvasPos:= FindCaption(ps2, 'NewCanvas');
  stag:= 0;
  k:= length(Def);
  SetLength(Def, k + RSGetTokensCount(ps, true) - 1);
  ForLine:= -1;
  skip:= false;
  try
    for i:= 1 to length(Def) do
      with Def[k] do
      begin
        ps2:= RSParseToken(ps, i, [#9]);
        // Command
        ps3:= RSParseToken(ps2, CmdPos, [' ']);
        CmdParam:= RSGetToken(ps3, 1);
        CmdParam2:= RSGetToken(ps3, 2);
        use:= RSGetTokensCount(ps3, true) > 0;
        if not FindStr(RSGetToken(ps3, 0), Cmd, CmdName) and use then
          if SameText(RSGetToken(ps3, 0), 'pcx') then
            CmdParam:= CmdParam + '.pcx'
          else
            continue;
        if skip and (Cmd <> lcCheckVer) then
          continue;
        // Params
        for lp:= low(TLayoutParam) to high(TLayoutParam) do
          ReadExpr(Get(ParamPos[lp]), Params[lp], i+1, ParamPos[lp]+1);
        // Other params
        Canvas:= Canv(Get(CanvasPos), DefaultCanvas);
        NewCanvas:= Canv(Get(NewCanvasPos), CanvasScreen);
        if Get(CanvasPos) <> '' then
          MainCanvas:= Canvas
        else
          MainCanvas:= NewCanvas;
        FindStr(Get(ClickPos), Click, ClickName);
        Get(DrawPos);
        ps3:= RSParseToken(ps2, DrawPos, ['#']);
        FindStr(RSGetToken(ps3, 0), Draw, DrawName);
        DrawColor:= TransparentColor16;
        if RSGetTokensCount(ps3) > 1 then
          DrawColor:= ToColor16(StrToInt('$' + RSGetToken(ps3, 1)));
        IconLoaded:= -1;
        Line:= i + 1;
        Jump:= MaxInt;
        case Cmd of
          lcIf:
          begin
            if FindStr(CmdParam, IfOp, IfOpName) then
              zSwap(CmdParam, CmdParam2);
            FindStr(CmdParam, IfUOp, IfUOpName);
          end;
          lcFor:
          begin
            JumpLast:= ForLine;
            ForLine:= k;
          end;
          lcLoop:
          begin
            if ForLine < 0 then
              Error('Corresponding FOR not found', Line);
            Jump:= ForLine;
            Def[ForLine].Jump:= k + 1;
            ForLine:= Def[ForLine].JumpLast;
          end;
          lcCheckVer:
          begin
            use:= false;
            skip:= (Params[lpCond] <> nil) and (RSCalcExpr(Params[lpCond], GetVar2) = 0);
          end;
          lcStage:
          begin
            j:= Stages.IndexOf(CmdParam);
            if j < 0 then
              if SameText(CmdParam2, 'insert') or SameText(CmdParam2, 'before') then
              begin
                j:= stag;
                if CmdParam2[1] in ['i', 'I'] then
                  inc(j);
                Stages.Insert(j, CmdParam);
              end else
                j:= Stages.Add(CmdParam);
            stag:= j;
          end;
        end;
        if use then
          inc(k);
        if (Cmd = lcErase) and SameText(CmdParam, 'layout') and
           ((Params[lpCond] = nil) or (RSCalcExpr(Params[lpCond], GetVar2) <> 0)) then
        begin
          k:= 0;
          if stag = 0 then
          begin
            Stages.Clear;
            Stages.Add('');
          end;
        end;
      end;
    SetLength(Canvases, CanvasNames.Count);
    SetLength(Def, k);
  finally
  end;
  Updated:= false;
  if ForLine >= 0 then
    Error('Corresponding LOOP not found', Def[ForLine].Line);
end;

procedure TLayout.SetupScreen(w, h: ext);
var
  fw, fh: ext;
begin
  fw:= Locals[lvWidth];
  fh:= Locals[lvHeight];
  ScreenScale[0]:= min(fw/w, fh/h);
  if ScreenScale[0] < Locals[lvMinScale] then
    ScreenScale[0]:= 1;
  ScreenScale[1]:= ScreenScale[0];

  if ScreenScale[0] = fw/w then
    ScreenSize[0]:= w
  else
    ScreenSize[0]:= fw/ScreenScale[0];

  if ScreenScale[1] = fh/h then
    ScreenSize[1]:= h
  else
    ScreenSize[1]:= fh/ScreenScale[1];
end;

procedure TLayout.SetVar(const Name: string; idx: int; v: ext);
var
  i, n: int;
begin
  n:= VarNames.Count;
  i:= int(VarNames.Objects[VarNames.AddObject(Name, ptr(n))]);
  if i >= n then
  begin
    SetLength(VarVals[0], i + 1);
    SetLength(VarVals[1], i + 1);
    if Assigned(OnUnsetVar) then
      OnUnsetVar(Name, true);
  end;
  Updated:= Updated and (VarVals[idx][i] = v);
  VarVals[idx][i]:= v;
end;

procedure TLayout.SetVarEx(const Name: string; v: ext; default: Boolean);
begin
  if default and (VarNames.IndexOf(Name) >= 0) then
    exit;
  Locals[Name]:= v;
  if not default then
    exit;
  Vars[Name]:= v;
  if Assigned(OnDefaultValue) then
    OnDefaultValue(Name, v);
end;

function TLayout.Update(JustLimits: Boolean): Boolean;
begin
  Result:= not Updated;
  if Updated then  exit;
  inc(UpdateId);
  CopyMemory(ptr(VarVals[1]), ptr(VarVals[0]), length(VarVals[0])*SizeOf(ext));
  DoUpdate(JustLimits);
  Updated:= not JustLimits;
end;

procedure TLayout.UseCanvas(i: int; JustGet: Boolean);
begin
  if i = CanvasScreen then
  begin
    CurCanvasSize[0]:= ScreenSize[0];
    CurCanvasSize[1]:= ScreenSize[1];
  end else
    with Canvases[i] do
    begin
      if Persist and not Recovered then
        if JustGet then
        begin
          FillChar(CurCanvasSize, SizeOf(CurCanvasSize), 0);
          exit;
        end else
        begin
          Persist:= false;
          Size:= Point(0, 0);
        end;
      CurCanvasSize[0]:= Size.X;
      CurCanvasSize[1]:= Size.Y;
    end;
end;

{ Procedures }

procedure DrawOp(p, p2: PWord; c0: Word; Kind: TDrawKind); inline;
begin
  case Kind of
    ldkOpaque:
      p2^:= p^;
    ldkTransparent:
      if p^ <> c0 then
        p2^:= p^;
    ldkBehind:
      if p2^ = c0 then
        p2^:= p^;
    ldkErase:
      if p2^ = p^ then
        p2^:= c0;
    ldkAnd:
      if p^ = c0 then
        p2^:= c0;
    ldkOverlay:
      if p2^ <> c0 then
        p2^:= p^;
    ldkNot:
      if p^ <> c0 then
        p2^:= c0;
  end;
end;

procedure DoDraw16(ps, pd: PWord; ds, dd, w, h: int; c0: Word; Kind: TDrawKind); inline;
var
  x: int;
begin
  dec(ds, w*2);
  dec(dd, w*2);
  for h:= h downto 1 do
  begin
    for x:= w downto 1 do
    begin
      DrawOp(ps, pd, c0, Kind);
      inc(ps);
      inc(pd);
    end;
    inc(PChar(ps), ds);
    inc(PChar(pd), dd);
  end;
end;

procedure DoTileDraw16(ps, pd: PWord; ds, dd, ws, hs, wd, hd: int; c0: Word; Kind: TDrawKind); inline;
var
  warpY: ptr;
  x, dy: int;
begin
  if (ws = wd) and (hs = hd) then
  begin
    DoDraw16(ps, pd, ds, dd, ws, hs, c0, Kind);
    exit;
  end;
  dy:= ds*hs;
  dec(dd, wd*2);
  warpY:= PChar(ps) + dy;
  for hd:= hd downto 1 do
  begin
    for x:= 0 to wd - 1 do
    begin
      DrawOp(ptr(PChar(ps) + (x mod ws)*2), pd, c0, Kind);
      inc(pd);
    end;
    inc(PChar(ps), ds);
    inc(PChar(pd), dd);
    if ps = warpY then
      dec(PChar(ps), dy);
  end;
end;

procedure TileDraw16_start(ps, pd: PWord; ds, dd, ws, hs, wd, hd: int; c0: Word; Kind: TDrawKind); inline;
begin
  case Kind of
    ldkOpaque:
      DoTileDraw16(ps, pd, ds, dd, ws, hs, wd, hd, c0, ldkOpaque);
    ldkTransparent:
      DoTileDraw16(ps, pd, ds, dd, ws, hs, wd, hd, c0, ldkTransparent);
    ldkBehind:
      DoTileDraw16(ps, pd, ds, dd, ws, hs, wd, hd, c0, ldkBehind);
    ldkErase:
      DoTileDraw16(ps, pd, ds, dd, ws, hs, wd, hd, c0, ldkErase);
    ldkAnd:
      DoTileDraw16(ps, pd, ds, dd, ws, hs, wd, hd, c0, ldkAnd);
    ldkOverlay:
      DoTileDraw16(ps, pd, ds, dd, ws, hs, wd, hd, c0, ldkOverlay);
    ldkNot:
      DoTileDraw16(ps, pd, ds, dd, ws, hs, wd, hd, c0, ldkNot);
  end;
end;

procedure Draw16(ps, pd: PWord; ds, dd, w, h: int; c0: Word; Kind: TDrawKind);
begin
  TileDraw16_start(ps, pd, ds, dd, w, h, w, h, c0, Kind);
end;

procedure TileDraw16(ps, pd: PWord; ds, dd, ws, hs, wd, hd: int; c0: Word; Kind: TDrawKind);
begin
  TileDraw16_start(ps, pd, ds, dd, ws, hs, wd, hd, c0, Kind);
end;

// test middle of rectangle, break it into 4 rectangles, repeat
procedure DoFindContextMenu(var p0: ptr; c0: Word; var ox, oy: int);
var
  p: PWordArray;
  x, y, k, n, dx, dy: int;
begin
  n:= 1;
  for k:= 0 to 3 do
  begin
    dx:= 640 div n;
    dy:= 640*480 div n;
    p:= ptr(PChar(p0) + dx + dy);
    for y:= 0 to n - 1 do
      for x:= 0 to n - 1 do
        if p[x*dx + y*dy] <> c0 then
        begin
          p0:= @p[x*dx + y*dy];
          ox:= (x*2 + 1)*320 div n;
          oy:= (y*2 + 1)*240 div n;
          exit;
        end;
    n:= n*2;
  end;
  ox:= -1;
end;

function FindLim(p: PWord; c0: Word; dx, n: int): int;
var
  i: int;
begin
  Result:= 0;
  for i:= 1 to n do
  begin
    inc(p, dx);
    if p^ = c0 then  exit;
    inc(Result);
  end;
end;

function FindContextMenu(p: ptr; c0: Word): TRect;
var
  x, y: int;
begin
  DoFindContextMenu(p, c0, x, y);
  if x < 0 then
  begin
    Result:= Rect(-1, -1, -1, -1);
    exit;
  end;
  Result.Left:= x - FindLim(p, c0, -1, x);
  Result.Right:= x + FindLim(p, c0, 1, 640 - x) + 1;
  Result.Top:= y - FindLim(p, c0, -640, y);
  Result.Bottom:= y + FindLim(p, c0, 640, 480 - y) + 1;
end;

{ TDrawLayout }

function TDrawLayout.AddFixedCanvas(const Name: string; p: ptr; w, h: int): int;
begin
  with Layout do
  begin
    Result:= AddCanvas(Name);
    with Canvases[Result] do
    begin
      Updated:= Updated and (Size.X = w) and (Size.Y = h) and Fixed;
      Size:= Point(w, h);
      Fixed:= true;
    end;
  end;
  if Result >= length(FixedCanvases) then
    SetLength(FixedCanvases, Result + 1);
  FixedCanvases[Result]:= p;
end;

function TDrawLayout.CanvasInfo(const it: TLayoutItem; var d: int): ptr;
begin
  if it.IconLoaded >= 0 then
  begin
    d:= IconSize[it.IconLoaded].X*2;
    Result:= Icons[it.IconLoaded];
  end else
  begin
    CheckCleanCanvas(it.Canvas);
    Result:= CanvasInfo(it.Canvas, d);
  end;
end;

function TDrawLayout.CanvasInfo(c: int; var d: int): ptr;
begin
  d:= Layout.Canvases[c].Size.X*2;
  Result:= FixedCanvases[c];
  if Result = nil then
    Result:= DrawCanvas[c].Buf;
end;

procedure TDrawLayout.CheckCleanCanvas(c: int);
begin
  with DrawCanvas[c] do
    if OpDirty and (FixedCanvases[c] = nil) then
    begin
      OpDirty:= false;
      OpIcon:= 0;
      Draw16(@Buf[0], @Buf[0], 0, 0, length(Buf), 1, TransparentColor16, ldkNot);
    end;
end;

function TDrawLayout.CheckConstCanvas(const it: TLayoutItem): Boolean;
begin
  Result:= false;
  with DrawCanvas[it.NewCanvas], it do
    if (OpIcon > 0) and (OpIcon = IconLoaded + 1) and (OpDraw = Draw) and
       CompareMem(@OpBase, @Base, SizeOf(Base)) and CompareMem(@OpNew, @New, SizeOf(New)) then
    begin
      Result:= true;
      OpDirty:= false;
    end
    else if OpDirty or (OpIcon = 0) and (IconLoaded >= 0) or
       (Draw = ldkOpaque) and (New.Left = 0) and (New.Top = 0) and
       (New.Right = CurSize.X) and (New.Bottom = CurSize.Y) then
    begin
      CheckCleanCanvas(it.NewCanvas);
      OpIcon:= IconLoaded + 1;
      OpDraw:= Draw;
      OpBase:= Base;
      OpNew:= New;
    end else
      OpIcon:= -1;
end;

function TDrawLayout.CheckPixel(c: int; x, y: int): Boolean;
var
  p: PChar;
  d: int;
begin
  p:= CanvasInfo(c, d);
  with DrawCanvas[c] do
    if OpDirty and (FixedCanvases[c] = nil) then
      Result:= false  // no need to clean it up with CheckCleanCanvas(c) for a simple check
    else
      Result:= PWord(p + y*d + x*2)^ <> TransparentColor16;
end;

procedure TDrawLayout.ClearCache;
var
  i: int;
begin
  Layout.Updated:= false;
  for i:= 0 to high(IconSize) do
    IconSize[i].X:= -1;
  for i:= 0 to high(DrawCanvas) do
    if FixedCanvases[i] = nil then
      with Layout.Canvases[i], DrawCanvas[i], CurSize do
      begin
        OpIcon:= 0;
        X:= 0;
        Y:= 0;
        Buf:= nil;
        if not Fixed then
          Size:= CurSize;
      end;
end;

constructor TDrawLayout.Create(ALayout: TLayout; Own: Boolean);
begin
  if ALayout = nil then
    ALayout:= TLayout.Create;
  Layout:= ALayout;
  OwnLayout:= Own;
  IconNames:= TStringList.Create;
  IconNames.CaseSensitive:= false;
  Layout.OnLoadIcon:= LoadIcon;
  PressCanvas:= -2;
end;

destructor TDrawLayout.Destroy;
begin
  if OwnLayout then
    FreeAndNil(Layout);
  IconNames.Free;
  inherited;
end;

procedure TDrawLayout.DoDrawItem(const it: TLayoutItem);
var
  d, dd: int;
  p, pd: PChar;
begin
  with it do
    if Canvas = CanvasTimer then
      DrawTimer(it)
    else begin
      p:= CanvasInfo(it, d);
      with Base do
        inc(p, Top*d + Left*2);
      if NewCanvas <> CanvasScreen then
      begin
        if CheckConstCanvas(it) then
          exit;
        pd:= CanvasInfo(it.NewCanvas, dd);
        with New do
          TileDraw16(ptr(p), ptr(pd + Top*dd + Left*2), d, dd,
             Base.Right - Base.Left, Base.Bottom - Base.Top,
             Right - Left, Bottom - Top, DrawColor, it.Draw);
      end else
        if Assigned(OnDrawArea) then
          OnDrawArea(it, p, d);
    end;
end;

procedure TDrawLayout.Draw(OnlyVirtual: Boolean);
var
  IfVis{, upd}: Boolean;

  function CheckIf(var it: TLayoutItem): Boolean;
  begin
    with it do
      case IfUOp of
        liuNone:   Result:= (IfXY.X < 0) or CheckPixel(it.IfCanvas, IfXY.X, IfXY.Y);
        liuEmpty:  Result:= (IfXY.X >= 0) and not CheckPixel(it.IfCanvas, IfXY.X, IfXY.Y);
        liuHover:  Result:= (MouseCanvas = IfCanvas);
        liuDown:   Result:= (MouseCanvas = IfCanvas) and (PressCanvas = IfCanvas);
        liuOnce:
        begin
          Result:= (IfXY.X < 0) or CheckPixel(it.IfCanvas, IfXY.X, IfXY.Y);
          if Result then
          begin
            IfUOp:= liuEmpty;
            IfXY.X:= -1;
          end;
        end;
        else
          Result:= true;
      end;
  end;

var
  i, CurIf: int;
begin
  Layout.Update;
  SetLength(DrawCanvas, length(Layout.Canvases));
  SetLength(FixedCanvases, length(Layout.Canvases));
  for i:= 0 to high(DrawCanvas) do
    with DrawCanvas[i], Layout.Canvases[i], Size do
      if not Persist or (FixedCanvases[i] = nil) and not CompareMem(@Size, @CurSize, SizeOf(Size)) then
      begin
        SetLength(Buf, X*Y);
        OpDirty:= true;
        if (OpIcon <= 0) or not CompareMem(@Size, @CurSize, SizeOf(Size)) then
          CheckCleanCanvas(i);
        CurSize:= Size;
      end;
  CurIf:= 0;
  IfVis:= true;
  for i:= 0 to high(Layout.Items) do
    with Layout, Items[i] do
    begin
      Visible:= false;
      if IfId <> CurIf then
      begin
        case IfOp of
          lioNone:   IfVis:= CheckIf(Items[i]);
          lioElse:   IfVis:= not IfVis and CheckIf(Items[i]);
          lioAnd:    IfVis:= IfVis and CheckIf(Items[i]);
          lioOr:     IfVis:= IfVis or CheckIf(Items[i]);
          lioXor:    IfVis:= IfVis xor CheckIf(Items[i]);
        end;
        CurIf:= IfId;
      end;
      if not IfVis then
        continue;
      Visible:= true;
      if Assigned(OnBeforeDraw) then
        OnBeforeDraw(Items[i], OnlyVirtual);
      if not Visible or (Draw = ldkNone) or OnlyVirtual and (NewCanvas = CanvasScreen) then
        continue;
      DoDrawItem(Items[i]);
    end;
  UpdateId:= Layout.UpdateId;
end;

procedure TDrawLayout.DrawTimer(const it: TLayoutItem);
var
  t, d: int;
begin
  with it do
    t:= timeGetTime div uint(Base.Right) mod uint(New.Right);
  CheckConstCanvas(it);
  PWordArray(CanvasInfo(it.NewCanvas, d))[t]:= 0;
end;

function TDrawLayout.HitTest(var x, y: int): Boolean;
var
  i, x1, y1: int;
begin
  Layout.Update;
  if UpdateId <> Layout.UpdateId then
    Draw(true);
  MouseCanvas:= CanvasScreen;
  Result:= true;
  for i:= high(Layout.Items) downto 0 do
    with Layout, Items[i], New do
    begin
      if (NewCanvas <> MouseCanvas) or (Click = lckNone) or not Visible
         or (x < Left) or (y < Top) or (x >= Right) or (y >= Bottom) then
        continue;
      x1:= (x*2 - Left*2 + 1)*RectW(Base) div (RectW(New)*2) + Base.Left;
      y1:= (y*2 - Top*2 + 1)*RectH(Base) div (RectH(New)*2) + Base.Top;
      if (Click = lckOpaque) or CheckPixel(Items[i].Canvas, x1, y1) then
      begin
        if (MouseCanvas = CanvasScreen) or (Canvas <> 0) then
          MouseCanvas:= Canvas;
        if IconLoaded >= 0 then
          break;
        x:= x1;
        y:= y1;
        if Canvas = 0 then
          exit;
      end;
    end;
  Result:= (MouseCanvas <> CanvasScreen);
  x:= -1;
  y:= -1;
end;

procedure TDrawLayout.LoadIcon(const Name: string; var n: int; out wf,
  hf: ext);
begin
  if n < 0 then
    n:= IconNames.IndexOf(Name);
  if n < 0 then
  begin
    n:= IconNames.Add(Name);
    SetLength(Icons, n + 1);
    SetLength(IconSize, n + 1);
    IconSize[n].X:= -1;
  end;
  if IconSize[n].X < 0 then
  begin
    OnLoadIcon(Name, Icons[n], IconSize[n].X);
    with IconSize[n] do
      Y:= length(Icons[n]) div X;
  end;
  wf:= IconSize[n].X;
  hf:= IconSize[n].Y;
end;

procedure TDrawLayout.SetMouseDown(v: Boolean);
begin
  if v and (PressCanvas = -2) then
    PressCanvas:= MouseCanvas
  else if not v then
    PressCanvas:= -2;
end;

end.

