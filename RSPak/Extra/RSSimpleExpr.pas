unit RSSimpleExpr;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  RSQ, Math, RSStrUtils;

type
  TRSOpType = (RSotNone = 0, RSotPush, RSotNot, RSotNeg, RSotAdd, RSotMul,
     RSotDiv, RSotMod, RSotIDIv, RSotPower, RSotEq, RSotMore, RSotLess, RSotOr,
     RSotAnd);

  TRSOperator = record
    Name: string;
    Val: ext;
    Priority: Byte;
    Op: TRSOpType;
    Op2: TRSOpType;
    RightHanded: Boolean;
  end;
  TRSOperatorArray = array of TRSOperator;

  TRSCustomOpKind = (RSokValue, RSokLeft, RSokBinary, RSokRight);

  TRSCustomOpEvent = function(const s: string; var k: int; var op: TRSOperator; kind: TRSCustomOpKind): Boolean of object;
  TRSGetVarEvent = function(const name: string; data: ptr): ext of object;

// Result = 0:           No error
// Result <= length(s):  Syntax error
// Result > length(s):   Unfinished expression
function RSParseExpr(const s: string; var a: TRSOperatorArray; Custom: TRSCustomOpEvent = nil; AcceptEmpty: Boolean = false): int;
function RSCalcExpr(const a: array of TRSOperator; const get: TRSGetVarEvent = nil; getData: ptr = nil): ext;

implementation

const
  Bracket = 0;
  BinOp: array[1..15] of TRSOperator = (
    (Name: 'or'; Priority: 1; Op: RSotOr),
    (Name: 'and'; Priority: 2; Op: RSotAnd),

    (Name: '<='; Priority: 3; Op: RSotMore; Op2: RSotNot),
    (Name: '>='; Priority: 3; Op: RSotLess; Op2: RSotNot),
    (Name: '<>'; Priority: 3; Op: RSotEq; Op2: RSotNot),
    (Name: '>'; Priority: 3; Op: RSotMore),
    (Name: '<'; Priority: 3; Op: RSotLess),
    (Name: '='; Priority: 3; Op: RSotEq),

    (Name: '+'; Priority: 4; Op: RSotAdd),
    (Name: '-'; Priority: 4; Op: RSotNeg; Op2: RSotAdd),

    (Name: '*'; Priority: 5; Op: RSotMul),
    (Name: '/'; Priority: 5; Op: RSotDiv),
    (Name: 'mod'; Priority: 5; Op: RSotMod),
    (Name: 'div'; Priority: 5; Op: RSotIDiv),

    (Name: '^'; Priority: 6; Op: RSotPower; RightHanded: true)
  );
  LOp: array[1..2] of TRSOperator = (
    (Name: '-'; Priority: 126; Op: RSotNeg),
    (Name: '('; Priority: Bracket)
  );
  ROp: array[1..1] of TRSOperator = (
    (Name: ')'; Priority: Bracket; RightHanded: true)
  );
  PushOp: TRSOperator = (Priority: 127; Op: RSotPush);

procedure AInsert(var a: TRSOperatorArray; i: int; const op: TRSOperator);
begin
  SetLength(a, length(a) + 1);
  ArrayInsert(a, i, SizeOf(TRSOperator));
  a[i]:= op;
end;

procedure ADel(var a: TRSOperatorArray; i: int);
begin
  ArrayDelete(a, i, SizeOf(TRSOperator));
  SetLength(a, high(a));
end;

function IsThere(p, p2: PChar): Boolean;
const
  aset = ['0'..'9','a'..'z','A'..'Z','_'];
var
  AlphaNum: Boolean;
begin
  Result:= false;
  AlphaNum:= p2^ in aset;
  while p2^ <> #0 do
  begin
    if p^ <> p2^ then  exit;
    inc(p);
    inc(p2);
  end;
  Result:= not AlphaNum or not (p^ in aset);
end;

function CheckOps(const s: string; var k: int; const a: array of TRSOperator; var op: TRSOperator): Boolean;
var
  i: int;
begin
  Result:= true;
  for i:= low(a) to high(a) do
    if IsThere(@s[k], PChar(a[i].Name)) then
    begin
      op:= a[i];
      inc(k, length(op.Name));
      exit;
    end;
  Result:= false;
end;

function CheckNum(const s: string; var k: int; var op: TRSOperator): Boolean;
var
  x: ext;
  i, j: int;
begin
  Result:= false;
  i:= k;
  while s[i] in ['+'] do
    inc(i);
  while s[i] in ['.','0'..'9'] do
    inc(i);
  if i = k then
    exit
  else if s[i] in ['e','E'] then
  begin
    repeat
      inc(i);
    until not (s[i] in ['+','-']);
    repeat
      inc(i);
    until not (s[i] in ['0'..'9']);
  end;
  Val(Copy(s, k, i - k), x, j);  // Val bug: Val('1.5+') = 15
  if (j = 2) and (s[k] in ['+','.']) then
    exit;
  if j > 0 then
  begin
    inc(k, j - 1);
    if s[k-1] in ['e','E'] then
      dec(k);
  end else
    k:= i;
  op:= PushOp;
  op.Val:= x;
  Result:= true;
end;

function CheckVar(const s: string; var k: int; var op: TRSOperator): Boolean;
var
  i: int;
begin
  i:= k;
  while s[k] in ['A'..'Z','a'..'z','0'..'9','.','_'] do
    inc(k);
  Result:= (k > i);
  if not Result then  exit;
  op:= PushOp;
  op.Name:= Copy(s, i, k - i);
end;

function RSParseExpr(const s: string; var a: TRSOperatorArray; Custom: TRSCustomOpEvent = nil; AcceptEmpty: Boolean = false): int;
var
  op: TRSOperator;
  left: Boolean;
  k, Idx: int;

  procedure FindIdx;
  begin
    while (Idx < length(a)) and (a[Idx].Priority > op.Priority) do
      inc(Idx);
    if not op.RightHanded and (Idx < length(a)) and (a[Idx].Priority = op.Priority)  then
      inc(Idx);
  end;

  function Cus(kind: TRSCustomOpKind): Boolean;
  begin
    while (k <= length(s)) and (s[k] <= ' ') do
      inc(k);
    Result:= Assigned(Custom) and Custom(s, k, op, kind);
  end;

begin
  a:= nil;
  if s = '' then
  begin
    Result:= BoolToInt[not AcceptEmpty];
    exit;
  end;
  left:= true;
  Idx:= 0;
  k:= 1;
  while true do
    if left then
    begin
      while Cus(RSokLeft) or CheckOps(s, k, LOp, op) do
        AInsert(a, Idx, op);
      if not Cus(RSokValue) and not CheckNum(s, k, op) and not CheckVar(s, k, op) then
        if AcceptEmpty and (a = nil) then
          break
        else begin
          Result:= k;  // operand expected
          exit;
        end;
      AInsert(a, Idx, op);
      left:= false;
    end else
    begin
      while Cus(RSokRight) or CheckOps(s, k, ROp, op) do
      begin
        FindIdx;
        if op.Priority <> Bracket then
        begin
          AInsert(a, Idx, op);
          inc(Idx);
        end
        else if (Idx = length(a)) or (a[Idx].Priority <> Bracket) then
        begin
          Result:= k - 1;  // opening bracket not found
          exit;
        end else
          ADel(a, Idx);
      end;
      if not Cus(RSokBinary) and not CheckOps(s, k, BinOp, op) then
        break;
      FindIdx;
      AInsert(a, Idx, op);
      left:= true;
    end;
  // syntax error?
  Result:= k;
  if k <= length(s) then
    exit;
  // unclosed bracket?
  for Idx:= Idx to high(a) do
    if a[Idx].Priority = Bracket then
      exit;
  // ok
  Result:= 0;
end;


{ CalcExpr }


type TMyArray = array of ext;

procedure ExecOp(var stack: TMyArray; var k: int; op: TRSOpType); inline;
var
  x, y: ext;
begin
  if op in [RSotNone, RSotPush] then
    exit;

  y:= stack[k];
  if not (op in [RSotNeg, RSotNot]) then
    dec(k);
  x:= stack[k];
  case op of
    RSotNot:   x:= BoolToInt[x = 0];
    RSotNeg:   x:= -x;
    RSotAdd:   x:= x + y;
    RSotMul:   x:= x * y;
    RSotDiv:   x:= x / y;
    RSotIDIv:  x:= Floor(x/y);
    RSotMod:   x:= x - Floor(x/y)*y;
    RSotPower: x:= Power(x, y);
    RSotEq:    x:= BoolToInt[x = y];
    RSotMore:  x:= BoolToInt[x > y];
    RSotLess:  x:= BoolToInt[x < y];
    RSotOr:    if x = 0 then  x:= y;
    RSotAnd:   if x <> 0 then  x:= y;
  end;
  stack[k]:= x;
end;

function RSCalcExpr(const a: array of TRSOperator; const get: TRSGetVarEvent = nil; getData: ptr = nil): ext;
var
  stack: TMyArray;
  i, k: int;
begin
  SetLength(stack, 25);
  k:= -1;
  for i:= 0 to high(a) do
    with a[i] do
    begin
      if Op = RSotPush then
      begin
        inc(k);
        if k >= length(stack) then
          SetLength(stack, k*2);
        if (Name <> '') and Assigned(get) then
          stack[k]:= get(Name, getData)
        else
          stack[k]:= Val;
      end;
      ExecOp(stack, k, Op);
      ExecOp(stack, k, Op2);
    end;
  Result:= stack[max(k, 0)];
end;

{
Usage example:

function ReadExpr(const s: string; var a: TRSOperatorArray): string;
const
  ParseError: array[Boolean] of string = ('Syntax error', 'Unfinished expression');
var
  i: int;
begin
  i:= RSParseExpr(s, a, nil, true);
  if i = 0 then  exit;
  Result:= Format('%s: %s',
     [ParseError[i > length(s)], Copy(s, (i-1) mod length(s) + 1, MaxInt)]);
end;

function DisplayExpr(const a: TRSOperatorArray): string;
var
  s: string;
  i: int;
begin
  for i:= 0 to high(a) do
  begin
    if s <> '' then
      s:= s + ' ';
    if a[i].Name <> '' then
      s:= s + a[i].Name
    else
      s:= s + FloatToStr(a[i].Val);
  end;
  Result:= s;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Set8087CW($137f);
end;

procedure TForm1.RSEdit1Change(Sender: TObject);
var
  s: string;
  a: TRSOperatorArray;
begin
  s:= ReadExpr(RSEdit1.Text, a);
  if s = '' then
  begin
    RSEdit2.Text:= DisplayExpr(a);
    RSEdit3.Text:= FloatToStr(RSCalcExpr(a));
  end else
  begin
    RSEdit2.Text:= s;
    RSEdit3.Text:= '';
  end;
end;
}

end.

