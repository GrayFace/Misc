unit RSMemo;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 Supports Ctrl+A.
 When PageUp or PageDown is pressed and there's no more scrollling avalible,
  cursor goes to the first or last line.
 When you press up/down and cursor comes through an empty or shorter line,
  it recovers its position.

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, RSCommon, RSQ,
  Graphics, Forms, Math;

{$I RSWinControlImport.inc}

type
  TRSMemo = class(TMemo)
  private
    FOnCreateParams: TRSCreateParamsEvent;
    FProps: TRSWinControlProps;
    FSelAnchor: int;
    FPos: int;
    FLastChar: int;
    FCanvas: TCanvas;
    function GetCaret:int;
    procedure SetCaret(v:int);
    function GetLastChar:int;
    function GetLastCharWidth:int;
    function GetLastCharPos:int;
    function CharFromPosSimple(Pos:int; CurChar, CurPos:int):int;
  protected
    procedure CreateParams(var Params:TCreateParams); override;
    procedure TranslateWndProc(var Msg:TMessage);
    procedure WndProc(var Msg:TMessage); override;

    function GetCaretPos: TPoint; override;
    procedure Change; override;
    procedure KeyPress(var Key:Char); override;
    function CharFromPos(Pos:int; CurChar, CurPos:int):int;
    procedure FixCaretPosition(Pos:int; NeedPos:Boolean);
    procedure WMKeyDown(var Msg:TWMKeyDown); message WM_KeyDown;
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
    procedure GetSelection(var Anchor, Caret: Integer);
    procedure SetSelection(Anchor, Caret:int);
    function GetTextRange(start, stop: int): string; // Doesn't work with WordWrap
    property Canvas: TCanvas read FCanvas;
    property Caret: int read GetCaret write SetCaret;
  published
    property OnCanResize;
    property OnResize;
    {$I RSWinControlProps.inc}
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSMemo]);
end;

{
********************************** TRSMemo ***********************************
}
constructor TRSMemo.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  WindowProc:=TranslateWndProc;
  FPos:=-1;

  FCanvas:= TControlCanvas.Create;
  TControlCanvas(FCanvas).Control:= Self;
  ControlStyle:= ControlStyle - [csSetCaption]; // Annoying thing 
end;

destructor TRSMemo.Destroy;
begin
  FCanvas.Free;
  inherited Destroy;
end;

procedure TRSMemo.CreateParams(var Params:TCreateParams);
begin
  inherited CreateParams(Params);
  if Assigned(FOnCreateParams) then FOnCreateParams(self, Params);
end;

procedure TRSMemo.TranslateWndProc(var Msg:TMessage);
var b:Boolean;
begin
  if assigned(FProps.OnWndProc) then
  begin
    b:=false;
    FProps.OnWndProc(self, Msg, b, WndProc);
    if b then exit;
  end;
  WndProc(Msg);
end;

procedure TRSMemo.WndProc(var Msg:TMessage);
begin
  RSProcessProps(self, Msg, FProps);
  inherited;
  RSEditWndProcAfter(self, Msg, FSelAnchor);
  case Msg.Msg of
    WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK, EM_SETSEL:
      FPos:=-1;
  end;
end;

procedure TRSMemo.Change;
begin
  FPos:=-1;
  FLastChar:=0;
  inherited;
end;

procedure TRSMemo.KeyPress(var Key:Char);
begin
  inherited;
  if Key=#1 then // Ctrl+A
  begin
    SelectAll;
    Key:=#0;
  end;
end;

function TRSMemo.GetCaret:int;
begin
  Result:=RSEditGetCaret(self, FSelAnchor);
end;

procedure TRSMemo.SetCaret(v:int);
begin
  Perform(EM_SETSEL, v, v);
end;

function TRSMemo.GetCaretPos: TPoint;
begin
  Result.X:= GetCaret;
  Result.Y:= SendMessage(Handle, EM_LINEFROMCHAR, Result.X, 0);
  dec(Result.X, SendMessage(Handle, EM_LINEINDEX, Result.Y, 0));
end;

procedure TRSMemo.GetSelection(var Anchor, Caret: Integer);
begin
  RSEditGetSelection(self, Anchor, Caret, FSelAnchor);
end;

// Doesn't work with WordWrap
function TRSMemo.GetTextRange(start, stop: int): string;
var
  s: array of char;
  i, j, k: int;
begin
  Result:= '';
  if stop = -1 then
    stop:= Perform(WM_GETTEXTLENGTH, 0, 0);
  if start >= stop then
    exit;

  i:= Perform(EM_LINEFROMCHAR, start, 0);  // first line index
  if i < 0 then
    exit;
  j:= Perform(EM_LINEINDEX, i, 0);  // start of first line
  Assert(j >= 0);
  k:= Perform(EM_LINEINDEX, i + 1, 0);  // end of first line
  if (k < 0) or (k > stop) then
    k:= stop;

  SetLength(Result, stop - start);
  if stop - start >= k - j then
  begin
    // no need to realloc
    PWord(Result)^:= length(Result);
    Perform(EM_GETLINE, i, int(ptr(Result)));
    CopyMemory(ptr(Result), @Result[start - j + 1], k - start);
  end else
  begin
    SetLength(s, max(k - j, 2));
    PWord(s)^:= k - j;
    Perform(EM_GETLINE, i, int(s));
    CopyMemory(ptr(Result), @s[start - j], k - start);
  end;
  k:= k - start;
  while k < length(Result) do
  begin
    inc(i);
    PWord(@Result[k + 1])^:= $0A0D;  // line ending
    k:= Perform(EM_LINEINDEX, i, 0) - start;
    PWord(@Result[k + 1])^:= length(Result) - k;
    inc(k, Perform(EM_GETLINE, i, int(@Result[k + 1])));
  end;
  (PChar(Result) + length(Result))^:= #0; // may have been erased by PWord(...)^
end;

procedure TRSMemo.SetSelection(Anchor, Caret:int);
begin
  RSEditSetSelection(self, Anchor, Caret);
end;

function TRSMemo.GetLastChar:int;
var s:string;
begin
  {Result:=FLastChar;
  if Result=0 then
  begin}
    if Perform(EM_LINELENGTH, GetWindowTextLength(Handle), 0) > 0 then
    begin
      s:=Lines[Lines.Count-1];
      Result:=int(s[length(s)]);
    end else
      Result:=-1;
    FLastChar:=Result;
  //end;
end;

function TRSMemo.GetLastCharWidth:int;
begin
  if GetLastChar>=0 then
    with Canvas do
    begin
      Lock;
      Font:=self.Font;
      Result:=TextWidth(char(FLastChar));
      Unlock;
    end
  else
    Result:= 0;
end;

function TRSMemo.GetLastCharPos:int;
begin
  if GetLastChar>=0 then
  begin
    Result:= GetWindowTextLength(Handle)-1;
    Result:= Perform(EM_POSFROMCHAR, Result, 0) + GetLastCharWidth;
  end else
    Result:= 0;
end;

function TRSMemo.CharFromPosSimple(Pos:int; CurChar, CurPos:int):int;
var i,j,jx,k,lk:int;
begin
  i:=CurChar+1;
  j:=Pos;
  jx:=smallint(word(j));
  lk:=CurPos;
  while true do
  begin
    k:= Perform(EM_POSFROMCHAR, i, 0);
    if (k=-1) then
    begin
      if (lk + GetLastCharWidth <= jx) and (FLastChar >= 0) then  inc(i);
      break;
    end;
    if ((k xor j) shr 16 <> 0) then
      break;
    k:=smallint(word(k));
    if k > jx then
    begin
      if k - jx < jx - lk then
        inc(i);
      break;
    end;
    lk:=k;
    inc(i);
  end;
  Result:=i-1;
end;

 // EM_CHARFROMPOS doesn't work outside client area
function TRSMemo.CharFromPos(Pos:int; CurChar, CurPos:int):int;
var i:int;
begin
  Result:= CharFromPosSimple(Pos, CurChar, CurPos);
  if Result = GetWindowTextLength(Handle)-1 then
  begin
    i:=smallint(word(Perform(EM_POSFROMCHAR, Result, 0)));
    Pos:=smallint(word(Pos));
    if abs(i + GetLastCharWidth - Pos) < abs(i - Pos) then
      inc(Result);
  end;
end;

procedure TRSMemo.FixCaretPosition(Pos:int; NeedPos:Boolean);
var i,j,k:int;
begin
  j:= Perform(EM_POSFROMCHAR, FPos, 0);
  i:= Perform(EM_POSFROMCHAR, Pos, 0);
   // EM_POSFROMCHAR = -1 when Char is the end of text

  if WordWrap and (i >= 0) then
  begin
    k:= Perform(EM_LINEFROMCHAR, Pos, 0) - 1;
    if (k >= 0) and (Perform(EM_LINEFROMCHAR, Pos - 1, 0) = k) and ( (Pos < 2) or
        (Perform(EM_POSFROMCHAR, Pos - 1, 0) <> Perform(EM_POSFROMCHAR, Pos - 2, 0)) ) then
      exit;
    // Exit for now: Hard to find if the caret is at the end of line break or
    // the beginning of the next virtual line (character index is the same).
    // May emulate WM_HOME to do it in future.
  end;

  if NeedPos then
    if i=-1 then
    begin
      i:=$7fff0000;
      j:=$7fff;
    end else
  else
    if (j=-1) and (GetLastChar < 0) or (i=-1) then
      exit;

  if j=-1 then
    j:= GetLastCharPos;

  if not NeedPos and (int2(word(j)) <= int2(word(i))) then
    exit;

  if j and $ffff0000 <> i and $ffff0000 then
  begin
    j:= word(j) or (i and $ffff0000); // Desired position
    Pos:= CharFromPosSimple(j, Pos, i);
    i:= Perform(EM_POSFROMCHAR, Pos, 0);
  end else
  begin
    //Pos:= FPos;
    i:= j;
  end;
  
  if i<>-1 then
  begin
    i:=smallint(word(i));
    if i>ClientWidth then
    begin
      dec(i, smallint(word(Perform(EM_POSFROMCHAR, 0, 0))));
      Perform(WM_HSCROLL, SB_THUMBPOSITION or
                         ((i - ClientWidth*2 div 3) shl 16), 0);
      i:=Perform(EM_POSFROMCHAR, FPos, 0);
      if i=-1 then
        i:=GetLastCharPos;
      i:=smallint(word(i));
    end;
    j:=j and int($ffff0000) + i;
  end else
    j:=$7fff7fff;

  RSEditEmulateMouse(self, j);
end;

procedure TRSMemo.WMKeyDown(var Msg:TWMKeyDown);
var i:int; NeedPos:Boolean;
begin
  case Msg.CharCode of
    VK_LEFT, VK_RIGHT, VK_HOME, VK_END:
      FPos:=-1;
  end;

  if (GetKeyState(VK_CONTROL)<0) or (GetKeyState(VK_MENU)<0) then
  begin
    inherited;
    exit;
  end;

  case Msg.CharCode of
    VK_PGUP, VK_PGDN:
      i:=Perform(EM_GETFIRSTVISIBLELINE, 0, 0);
    else
      i:=-1;
  end;
  
  NeedPos:= FPos>=0;

  if FPos<0 then
    case Msg.CharCode of
      VK_UP, VK_DOWN, VK_PGUP, VK_PGDN:
      begin
        FPos:=Caret;
        if (FPos = GetWindowTextLength(Handle)) and (GetLastChar < 0) then
          FPos:=-1;
      end;
    end;

  inherited;

  if (i>=0) and (Perform(EM_GETFIRSTVISIBLELINE, 0, 0) = i) then
  begin
    if Msg.CharCode = VK_PGUP then
      i:=0
    else
      i:=Perform(EM_LINEINDEX, Perform(EM_GETLINECOUNT, 0, 0) - 1, 0);
    if FPos<0 then
      FPos:=Caret;
    NeedPos:=true;
  end else
    i:=-1;

  if NeedPos then
    case Msg.CharCode of
      VK_UP, VK_DOWN, VK_PGUP, VK_PGDN:
      begin
        if i<0 then
        begin
          i:=Caret;
          NeedPos:=false;
        end;

        FixCaretPosition(i, NeedPos);
      end;
    end;
end;

end.

