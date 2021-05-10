unit RSStrUtils;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{ See copyright notice for PosMod function (MPL).                         }
{                                                                         }
{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  SysUtils, Windows, RSQ, Math;

type
  TRSParsedString = array of PChar;


function RSParseRange(FromP, ToP:pointer; const Separators:array of string; Limit: int = MaxInt):TRSParsedString;
function RSParseString(const s:string; const Separators:array of string; From:int=1; Limit: int = MaxInt):TRSParsedString;
function RSParseToken(const ps:TRSParsedString; Index:int; const Separators:array of string; Limit: int = MaxInt):TRSParsedString;
function RSParseTokens(const ps:TRSParsedString; IndexFrom,IndexTo:int; const Separators:array of string; Limit: int = MaxInt):TRSParsedString;

function RSGetToken(const ps:TRSParsedString; Index:int):string;
function RSGetTokenSep(const ps:TRSParsedString; Index:int):string;
function RSGetTokens(const ps:TRSParsedString; IndexFrom:int; IndexTo:int = MaxInt div 2):string;
function RSGetTokensEx(const ps:TRSParsedString; IndexFrom:int; IndexTo:int = MaxInt):string;
function RSGetTokensCount(const ps:TRSParsedString; IgnoreEmptyEnd:boolean=false):int;
procedure RSChangeStr(var ps:TRSParsedString; const OldStr, NewStr:string);

function RSParseStringSingleToken(const s:string; token: int; const Separators:array of string; From:int=1): string;
function RSSetString(lim1, lim2: PChar): string;
function RSPos(const substr, str: string; Offset: int = 1; PosAfter: Boolean = false): int;
function RSStartsStr(const substr, str: string; After: pint = nil; Offset: int = 1): Boolean;

function RSStringReplace(const Str, OldPattern, NewPattern: string;
  Flags: TReplaceFlags=[rfReplaceAll]): string; overload;
function RSStringReplace(const Str: string; const OldPatterns: array of string;
  const NewPattern: string; Flags: TReplaceFlags=[rfReplaceAll]): string; overload;
function RSStringReplace(const Str: string; const ps: TRSParsedString;
  const NewPattern: string): string; overload;

function RSIntToStr(Value:LongInt; Base:byte = 10; ThousSep:char = #0; BigChars:boolean=true; Digits:int = 0):string;
function RSUIntToStr(Value:DWord; Base:byte = 10; ThousSep:char = #0; BigChars:boolean=true; Digits:int = 0):string;
function RSInt64ToStr(Value:Int64; Base:DWord = 10; ThousSep:char = #0; BigChars:boolean=true; Digits:int = 0):string;

function RSVal(const s:string; var i:integer):boolean; overload;
function RSVal(const s: string; var v: ext): Boolean; overload;
function RSVal(const s: string; var v: Double): Boolean; overload;
function RSVal(const s: string; var v: Single): Boolean; overload;
function RSValEx(const s:string; var i:integer):int;
function RSStrToInt(const Str:string; Base:DWord = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):LongInt; overload;
function RSStrToIntEx(const Str:string; var ErrorCode:int; Base:DWord = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):LongInt; overload;
function RSStrToIntEx(Str:PChar; ErrorCode:pint; Base:DWord = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):LongInt; overload;
function RSStrToIntVar(var Str:PChar; ErrorCode:pint; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):LongInt; overload;
function RSStrToInt64(const s:string; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):Int64; overload;
function RSStrToInt64Ex(const s:string; var ErrorCode:int; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):Int64; overload;
function RSStrToInt64Ex(s:PChar; ErrorCode:pint; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):Int64; overload;
function RSStrToInt64Var(var s:PChar; ErrorCode:pint; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):Int64; overload;

{ Error Codes:
0:  ok
1:  Пустая строка (result = 0)
2:  Слишком болшое число (result = high(Integer) или low(Integer) )
3:  Неверная система счисления (result = 0)
4:  Неверные символы в строке (result = "нормальная" часть строки)
6:  Строка со слишком большим числом и неверными символами после него
                         (result = high(Integer) или low(Integer) )
}

function RSStrToIntFloatVar(var s:PChar; ErrorCode:pint; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):Extended; overload;

function RSFloatToStr(const Value:Extended):string;
function RSStrToFloat(s:string):extended;

function RSCharToInt(c:char; Base:LongInt=36):LongInt;
//function RSFloatToStr()

implementation

{$R-} // No range checking

resourcestring
  SRSStrToIntEx1='RSStrToInt: The string is empty';
  SRSStrToIntEx2='RSStrToInt: The value is too big';
  SRSStrToIntEx3='RSStrToInt: Wrong base';
  SRSStrToIntEx4='RSStrToInt: Bad string';

var CharValues: array[0..255] of byte;

function IsThere1(a:PChar; s:string):boolean;
var l:int;
begin
  l:=length(s);
  if l=1 then Result:= a^=s[1]
  else
    if l=0 then Result:=false
    else
      Result:=CompareMem(a,PChar(s),l);
end;

function SimpleParse(p, p2:PChar; const Sep:string; Limit: int):TRSParsedString;
//const Mem=64;
var n:int; k:DWord;
begin
  SetLength(Result,2);
  Result[0]:=p;
  n:=1;
  k:=DWord(length(Sep));
  while p <> p2 do
    if (p + k <= p2) and IsThere1(p, Sep) then
    begin
      Result[n]:=p;
      inc(n);
      //if n div Mem = 0 then
      SetLength(Result,n+2);
      inc(p, max(k, 1));
      Result[n]:=p;
      inc(n);
      dec(Limit);
      if Limit <= 0 then
        p:= p2;
    end else
      inc(p);
  Result[n]:=p;
  //SetLength(Result,n+1);
end;

function DoParse(p, p2:PChar; const Sep:array of string; Limit: int):TRSParsedString;
label continue2;
//const Mem=64;
var j,n:int; k:DWord;
begin
  if low(Sep)=high(Sep) then
  begin
    Result:=SimpleParse(p, p2, Sep[low(Sep)], Limit);
    exit;
  end;
  SetLength(Result,2);
  Result[0]:=p;
  n:=1;
  while p <> p2 do
  begin
    for j:=low(Sep) to high(Sep) do
    begin
      k:=length(Sep[j]);
      if (p + k <= p2) and IsThere1(p, Sep[j]) then
      begin
        Result[n]:=p;
        inc(n);
        //if n div Mem = 0 then
        SetLength(Result,n+2);
        inc(p, max(k, 1));
        Result[n]:=p;
        inc(n);
        dec(Limit);
        if Limit <= 0 then
          p:= p2;
        goto continue2;
      end;
    end;
    inc(p);
continue2:
  end;
  Result[n]:=p;
  //SetLength(Result,n+1);
end;

function RSParseRange(FromP, ToP:pointer; const Separators:array of string; Limit: int = MaxInt):TRSParsedString;
begin
  Result:=DoParse(FromP, ToP, Separators, Limit);
end;

function RSParseString(const s:string; const Separators:array of string;
  From:int=1; Limit: int = MaxInt):TRSParsedString;
begin
  Result:=DoParse(PChar(s)+(From-1), PChar(s) + length(s), Separators, Limit);
end;

function RSParseToken(const ps:TRSParsedString; Index:int;
   const Separators:array of string; Limit: int = MaxInt):TRSParsedString;
begin
  Index:= Index*2;
  if uint(Index) < uint(length(ps)) then
    Result:= DoParse(ps[Index], ps[Index+1], Separators, Limit)
  else
    Result:= nil;
end;

function RSParseTokens(const ps:TRSParsedString; IndexFrom,IndexTo:int;
   const Separators:array of string; Limit: int = MaxInt):TRSParsedString;
begin
  IndexFrom:= IndexFrom*2;
  IndexTo:= min(min(IndexTo, MaxInt div 2)*2, length(ps)) - 1;
  if IndexTo > IndexFrom then
    Result:=DoParse(ps[IndexFrom], ps[IndexTo], Separators, Limit)
  else
    Result:=nil
end;

function RSGetToken(const ps:TRSParsedString; Index:int):string;
begin
  Index:= Index*2;
  if uint(Index) < uint(length(ps)) then
    SetString(Result, PChar(ps[Index]), DWord(ps[Index+1]) - DWord(ps[Index]))
  else
    Result:= '';
end;

function RSGetTokenSep(const ps:TRSParsedString; Index:int):string;
begin
  Index:= Index*2 + 1;
  if uint(Index) < uint(length(ps)) then
    SetString(Result, PChar(ps[Index]), DWord(ps[Index+1]) - DWord(ps[Index]))
  else
    Result:= '';
end;

function RSGetTokens(const ps:TRSParsedString; IndexFrom, IndexTo:int):string;
begin
  Result:= RSGetTokensEx(ps, IndexFrom*2, min(IndexTo, MaxInt div 2)*2);
end;

function RSGetTokensEx(const ps:TRSParsedString; IndexFrom:int; IndexTo:int = MaxInt):string;
begin
  IndexTo:= min(IndexTo, length(ps)) - 1;
  IndexFrom:= max(IndexFrom, 0);
  if IndexTo > IndexFrom then
    SetString(Result, ps[IndexFrom], ps[IndexTo] - ps[IndexFrom])
  else
    Result:= '';
end;

function RSGetTokensCount(const ps:TRSParsedString; IgnoreEmptyEnd:boolean):int;
begin
  if not IgnoreEmptyEnd then
    Result:=length(ps) div 2
  else begin
    Result:=length(ps)-2;
    while (Result>=0) and (DWord(ps[Result])=DWord(ps[Result+1])) do
      dec(Result,2);
    Result:=Result div 2 + 1;
  end;
end;

procedure RSChangeStr(var ps:TRSParsedString; const OldStr, NewStr:string);
var i,n:int;
begin
  n:=int(NewStr)-int(OldStr);
  for i:=high(ps) downto 0 do
    ps[i]:=ptr(int(ps[i])+n);
end;

function RSParseStringSingleToken(const s:string; token: int; const Separators:array of string; From:int=1): string;
var
  ps: TRSParsedString;
begin
  ps:= RSParseString(s, Separators, from, token + 1);
  Result:= RSGetToken(ps, token);
end;

function RSSetString(lim1, lim2: PChar): string;
begin
  SetString(Result, lim1, lim2 - lim1);
end;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The implementation of function PosMod is subject to the
 * Mozilla Public License Version 1.1 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Fastcode
 *
 * The Initial Developer of the Original Code is Fastcode
 *
 * Portions created by the Initial Developer are Copyright (C) 2002-2004
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s): Aleksandr Sharahov
 *
 * ***** END LICENSE BLOCK ***** *)
function PosMod(const substr: AnsiString; str: PChar; len: int): Integer;
asm
       push  ebx
       push  esi
       add   esp, -16
       test  edx, edx
       jz    @NotFound
       test  eax, eax
       jz    @NotFound
       mov   esi, ecx     //Length(Str)
       mov   ebx, [eax-4] //Length(Substr)
       cmp   esi, ebx
       jl    @NotFound
       test  ebx, ebx
       jle   @NotFound
       dec   ebx
       add   esi, edx
       add   edx, ebx
       mov   [esp+8], esi
       add   eax, ebx
       mov   [esp+4], edx
       neg   ebx
       movzx ecx, byte ptr [eax]
       mov   [esp], ebx
       jnz   @FindString

       sub   esi, 2
       mov   [esp+12], esi

@FindChar2:
       cmp   cl, [edx]
       jz    @Matched0ch
       cmp   cl, [edx+1]
       jz    @Matched1ch
       add   edx, 2
       cmp   edx, [esp+12]
       jb    @FindChar4
       cmp   edx, [esp+8]
       jb    @FindChar2
@NotFound:
       xor   eax, eax
       jmp   @Exit0ch

@FindChar4:
       cmp   cl, [edx]
       jz    @Matched0ch
       cmp   cl, [edx+1]
       jz    @Matched1ch
       cmp   cl, [edx+2]
       jz    @Matched2ch
       cmp   cl, [edx+3]
       jz    @Matched3ch
       add   edx, 4
       cmp   edx, [esp+12]
       jb    @FindChar4
       cmp   edx, [esp+8]
       jb    @FindChar2
       xor   eax, eax
       jmp   @Exit0ch

@Matched2ch:
       add   edx, 2
@Matched0ch:
       inc   edx
       mov   eax, edx
       sub   eax, [esp+4]
@Exit0ch:
       add   esp, 16
       pop   esi
       pop   ebx
       ret

@Matched3ch:
       add   edx, 2
@Matched1ch:
       add   edx, 2
       xor   eax, eax
       cmp   edx, [esp+8]
       ja    @Exit1ch
       mov   eax, edx
       sub   eax, [esp+4]
@Exit1ch:
       add   esp, 16
       pop   esi
       pop   ebx
       ret

@FindString4:
       cmp   cl, [edx]
       jz    @Test0
       cmp   cl, [edx+1]
       jz    @Test1
       cmp   cl, [edx+2]
       jz    @Test2
       cmp   cl, [edx+3]
       jz    @Test3
       add   edx, 4
       cmp   edx, [esp+12]
       jb    @FindString4
       cmp   edx, [esp+8]
       jb    @FindString2
       xor   eax, eax
       jmp   @Exit1

@FindString:
       sub   esi, 2
       mov   [esp+12], esi
@FindString2:
       cmp   cl, [edx]
       jz    @Test0
@AfterTest0:
       cmp   cl, [edx+1]
       jz    @Test1
@AfterTest1:
       add   edx, 2
       cmp   edx, [esp+12]
       jb    @FindString4
       cmp   edx, [esp+8]
       jb    @FindString2
       xor   eax, eax
       jmp   @Exit1

@Test3:
       add   edx, 2
@Test1:
       mov   esi, [esp]
@Loop1:
       movzx ebx, word ptr [esi+eax]
       cmp   bx, word ptr [esi+edx+1]
       jnz   @AfterTest1
       add   esi, 2
       jl    @Loop1
       add   edx, 2
       xor   eax, eax
       cmp   edx, [esp+8]
       ja    @Exit1
@RetCode1:
       mov   eax, edx
       sub   eax, [esp+4]
@Exit1:
       add   esp, 16
       pop   esi
       pop   ebx
       ret

@Test2:
       add   edx,2
@Test0:
       mov   esi, [esp]
@Loop0:
       movzx ebx, word ptr [esi+eax]
       cmp   bx, word ptr [esi+edx]
       jnz   @AfterTest0
       add   esi, 2
       jl    @Loop0
       inc   edx
@RetCode0:
       mov   eax, edx
       sub   eax, [esp+4]
       add   esp, 16
       pop   esi
       pop   ebx
end;

function RSPos(const substr, str: string; Offset: int = 1; PosAfter: Boolean = false): int;
begin
  dec(Offset);
  if Offset < 0 then
    Offset:= 0;
  Result:= PosMod(substr, @str[Offset + 1], length(str) - Offset);
  if Result > 0 then
  begin
    inc(Result, Offset);
    if PosAfter then
      inc(Result, length(substr));
  end;
end;

function RSStartsStr(const substr, str: string; After: pint = nil; Offset: int = 1): Boolean;
var
  n: int;
begin
  n:= length(substr);
  Result:= (length(str) >= n + Offset - 1) and CompareMem(@substr[1], @str[Offset], n);
  if Result and (After <> nil) then
    After^:= Offset + n;
end;

{------------------------- StringReplace ----------------------------}

function DoStringReplace(const ps: TRSParsedString; const Str, NewPattern: string; len: int): string;
var
  p: PChar;
  ds: IntPtr;
  i, j, n, newlen: DWord;
begin
  if (length(ps) = 2) and (len = length(Str)) then
  begin
    Result:=Str;
    exit;
  end;
  SetLength(Result, len);
  ds:= PChar(ptr(Str)) - ps[0];
  newlen:= length(NewPattern);
  j:= 1;
  for i:= 0 to high(ps) - 1 do
  begin
    if i mod 2 = 0 then
    begin
      p:= ps[i] + ds;
      n:= ps[i+1] - ps[i];
    end else
    begin
      p:= ptr(NewPattern);
      n:= newlen;
    end;
    CopyMemory(@Result[j], p, n);
    inc(j, n);
  end;
end;

function RSStringReplace(const Str, OldPattern, NewPattern: string;
   Flags: TReplaceFlags=[rfReplaceAll]): string; overload;
var
  ps: TRSParsedString;
  lim: int;
begin
  if rfReplaceAll in Flags then
    lim:= MaxInt
  else
    lim:= 1;

  if rfIgnoreCase in Flags then
    ps:= RSParseString(AnsiLowerCase(Str), [AnsiLowerCase(OldPattern)], 1, lim)
  else
    ps:= RSParseString(Str, [OldPattern], 1, lim);

  Result:= DoStringReplace(ps, Str, NewPattern,
     length(Str) + (length(NewPattern) - length(OldPattern))*(high(ps) div 2));
end;

function RSStringReplace(const Str: string; const OldPatterns: array of string;
   const NewPattern: string; Flags: TReplaceFlags=[rfReplaceAll]): string; overload;
var
  ps: TRSParsedString;
  Pat2: array of string;
  i, lim: int;
begin
  if rfReplaceAll in Flags then
    lim:= MaxInt
  else
    lim:= 1;

  if rfIgnoreCase in Flags then
  begin
    SetLength(Pat2, length(OldPatterns));
    for i:= 0 to high(OldPatterns) do
      Pat2[i]:= AnsiLowerCase(OldPatterns[i]);
    ps:= RSParseString(AnsiLowerCase(Str), Pat2, 1, lim);
  end else
    ps:= RSParseString(Str, OldPatterns, 1, lim);

  Result:= RSStringReplace(Str, ps, NewPattern);
end;

function RSStringReplace(const Str: string; const ps: TRSParsedString;
   const NewPattern: string): string; overload;
var
  i, len: int;
begin
  Assert(PChar(ps[high(ps)]) - PChar(ps[0]) <= length(Str));
  i:= high(ps) div 2;
  len:= length(NewPattern)*i;
  for i:= 0 to i do
    inc(len, ps[i*2 + 1] - ps[i*2]);
  Result:= DoStringReplace(ps, Str, NewPattern, len);
end;

{-------------------------- Int -> Str -----------------------------}

(*
These two functions work, but have less functionality than RSIntToStr does and
have the same speed.

procedure MyCvtInt;
// Based on CvtInt from SysUtils
{ IN:
    EAX:  The integer value to be converted to text
    ESI:  Ptr to the right-hand side of the output buffer:  LEA ESI, StrBuf[16]
    ECX:  Base for conversion: negative for signed, no 0 anymore
    EDX:  Precision: zero padded minimum field width
  OUT:
    ESI:  Ptr to start of converted text (not start of buffer)
    ECX:  Length of converted text
}
asm
        OR      ECX,ECX
        JNS     @CvtLoop
        NEG     ECX
@C1:    OR      EAX,EAX
        JNS     @CvtLoop
        NEG     EAX
        CALL    @CvtLoop
        MOV     AL,'-'
        INC     ECX
        DEC     ESI
        MOV     [ESI],AL
        RET

@CvtLoop:
        PUSH    EDX
        PUSH    ESI
@D1:    XOR     EDX,EDX
        DIV     ECX
        DEC     ESI
        ADD     DL,'0'
        CMP     DL,'0'+10
        JB      @D2
        ADD     DL,('A'-'0')-10
@D2:    MOV     [ESI],DL
        OR      EAX,EAX
        JNE     @D1
        POP     ECX
        POP     EDX
        SUB     ECX,ESI
        SUB     EDX,ECX
        JBE     @D5
        ADD     ECX,EDX
        MOV     AL,'0'
        SUB     ESI,EDX
        JMP     @z
@zloop: MOV     [ESI+EDX],AL
@z:     DEC     EDX
        JNZ     @zloop
        MOV     [ESI],AL
@D5:
end;

function IntToStrBase(Value: LongInt; Base:LongInt=10): string;
// Based on IntToStr     Use negateve base for signed value
asm
  PUSH    ESI
  MOV     ESI, ESP
  SUB     ESP, 33
  PUSH    ECX            // result ptr
  MOV     ECX, Base      // base
  XOR     EDX, EDX       // zero filled field width: 0 for no leading zeros
  CALL    MyCvtInt
  MOV     EDX, ESI
  POP     EAX            // result ptr
  CALL    System.@LStrFromPCharLen
  ADD     ESP, 33
  POP     ESI
end;

*)

function MyIntToStr(Value:DWord; Base:DWord; ThousSep:char;
                     BigChars:boolean; buf:pointer; Digits:byte):PChar;
var a:^byte; i,d:byte;
begin
  if BigChars then BigChars:=boolean($37) else BigChars:=boolean($57);

  a:=buf;
  if ThousSep=#0 then
    repeat
      i:=Value mod Base;
      Value:=Value div Base;
      if i<10 then inc(i,$30)
      else inc(i,byte(BigChars));
      a^:=i;
      dec(a);
    until Value=0
  else
  begin
    d:=0;
    repeat
      if d=3 then
      begin
        a^:=ord(ThousSep);
        dec(a);
        d:=0;
      end;
      i:=Value mod Base;
      Value:=Value div Base;
      if i<10 then inc(i,$30)
      else inc(i,byte(BigChars));
      a^:=i;
      dec(a);
      inc(d);
    until Value=0;
  end;

  if Digits>41 then  Digits:=41;
  for i:=uint(buf)-uint(a)+1 to Digits do
  begin
    a^:=ord('0');
    dec(a);
  end;
  Result:=ptr(a);
end;

function RSUIntToStr(Value:DWord; Base:byte = 10; ThousSep:char = #0; BigChars:boolean=true; Digits:int = 0):string;
var buf:array[0..41] of char; a:PChar; i:int;
begin
  Result:='';
  if (Base<2) or (Base>36) then
    exit;

  a:=MyIntToStr(Value, Base, ThousSep, BigChars, @buf[41], Digits);
  i:=int(@buf[41])-int(a);
  inc(a);
  SetLength(Result, i);
  CopyMemory(ptr(result), a, i);
end;

function RSIntToStr(Value:int; Base:byte = 10; ThousSep:char = #0; BigChars:boolean=true; Digits:int = 0):string;
var buf:array[0..41] of char; a:PChar; i:int;
begin
  Result:='';
  if (Base<2) or (Base>36) then
    exit;

  if Value>=0 then
  begin
    a:=MyIntToStr(Value, Base, ThousSep, BigChars, @buf[41], Digits);
    i:=int(@buf[41])-int(a);
    inc(a);
  end else
  begin
    a:=MyIntToStr(-Value, Base, ThousSep, BigChars, @buf[41], Digits);
    i:=int(@buf[41])-int(a)+1;
    a^:='-';
  end;
  SetLength(Result, i);
  CopyMemory(ptr(result), a, i);
end;

function RSInt64ToStr(Value:Int64; Base:DWord = 10; ThousSep:char = #0; BigChars:boolean=true; Digits:int = 0):string; overload;
var i:LongInt; bo:boolean; a:^byte; d:byte; buf:array[0..84] of char;
begin
  if int(Value) = Value then
  begin
    Result:=RSIntToStr(Value, Base, ThousSep, BigChars, Digits);
    exit;
  end else
    if uint(Value) = Value then
    begin
      Result:=RSUIntToStr(Value, Base, ThousSep, BigChars, Digits);
      exit;
    end;
  if (Base<2) or (Base>36) then
  begin
    result:='';
    exit;
  end;
  if Value<0 then bo:=true else bo:=false;

  if BigChars then BigChars:=boolean($37) else BigChars:=boolean($57);

  a:=@buf[84];
  if ThousSep=#0 then
    repeat
      a^:=abs(value mod Base);
      value:=value div Base;
      if a^<10 then inc(a^,$30)
      else inc(a^,byte(BigChars));
      dec(a);
    until value=0
  else
  begin
    d:=0;
    repeat
      if d=3 then
      begin
        a^:=ord(ThousSep);
        dec(a);
        d:=0;
      end;
      a^:=abs(value mod Base);
      value:=value div Base;
      if a^<10 then inc(a^,$30)
      else inc(a^,byte(BigChars));
      inc(d);
      dec(a);
    until value=0;
  end;

  if Digits>84 then  Digits:=84;
  for i:=uint(@buf[84])-uint(a)+1 to Digits do
  begin
    a^:=ord('0');
    dec(a);
  end;

  if bo then
  begin
    i:=DWord(@buf[84])-DWord(a)+1;
    a^:=ord('-');
  end else
  begin
    i:=DWord(@buf[84])-DWord(a);
    inc(a);
  end;
  SetLength(Result,i);
  CopyMemory(ptr(result),a,i);
end;



{-------------------------- Int <- Str -----------------------------}

function RSVal(const s:string; var i:integer):boolean; overload;
var j:integer;
begin
  val(s, i, j);
  Result:= j=0;
end;

function RSVal(const s: string; var v: ext): Boolean; overload;
var
  code: int;
begin
  Val(s, v, code);
  Result:= (code = 0);
end;

function RSVal(const s: string; var v: Double): Boolean; overload;
var
  code: int;
begin
  Val(s, v, code);
  Result:= (code = 0);
end;

function RSVal(const s: string; var v: Single): Boolean; overload;
var
  code: int;
begin
  Val(s, v, code);
  Result:= (code = 0);
end;

function RSValEx(const s:string; var i:integer):int;
begin
  val(s, i, Result);
end;

function RSStrToInt(const Str:string; Base:DWord = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):LongInt; overload;
var i:integer; p:PChar;
begin
  p:=ptr(Str);
  Result:= RSStrToIntVar(p, @i, Base, IgnoreChar,
                         IgnoreLeadSpaces, IgnoreTrailSpaces);
  case i of
    1: raise Exception.Create(SRSStrToIntEx1);
    2: raise Exception.Create(SRSStrToIntEx2);
    3: raise Exception.Create(SRSStrToIntEx3);
    4,5,6: raise Exception.Create(SRSStrToIntEx4);
  end;
end;

function RSStrToIntEx(const Str:string; var ErrorCode:int; Base:DWord = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):LongInt; overload;
var p:PChar;
begin
  p:=ptr(Str);
  Result:= RSStrToIntVar(p, @ErrorCode, Base, IgnoreChar,
                         IgnoreLeadSpaces, IgnoreTrailSpaces);
end;

function RSStrToIntEx(Str:PChar; ErrorCode:pint; Base:DWord = 10;
  IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false;
  IgnoreTrailSpaces:boolean=false):LongInt; overload;
begin
  Result:= RSStrToIntVar(Str, @ErrorCode, Base, IgnoreChar,
                         IgnoreLeadSpaces, IgnoreTrailSpaces);
end;

function RSStrToIntVar(var Str:PChar; ErrorCode:pint; Base:integer = 10;
  IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false;
  IgnoreTrailSpaces:boolean=false):LongInt; overload;
label over, done, trail;
var z:int; i,j:uint; neg:boolean; s:PChar;
begin
{ Error Codes:
0:  ok
1:  Empty string (result is 0)
2:  The value is too big (result is a maxum or a minimum integer value)
3:  Wrong Base (result is 0)
4:  String contains wrong chars (result is the valid part of string)
5:  String contains only wrong characters (result is 0)
6:  The value is too big and the string contains wrong chars
                         (result is a maximum or a minimum integer value)
}
  s:=Str;
  if ErrorCode=nil then ErrorCode:=@z;
  ErrorCode^:=0;
  Str:=s;
  Result:=0;
  if s=nil then
  begin
    ErrorCode^:=1;
    exit;
  end;
  if (Base<2) or (Base>36) then
  begin
    ErrorCode^:=3;
    exit;
  end;

  if IgnoreLeadSpaces then
    while s^=' ' do inc(s);

  neg:= (s^ = '-');
  if neg or (s^ = '+') then
    inc(s);

  if s^='$' then
  begin
    Base:=16;
    inc(s);
  end;

  i:=0;
  Str:=s;
  if IgnoreChar=#0 then
    while true do
    begin
      j:=CharValues[ord(s^)];
      if j>=uint(Base) then
        goto done;
      i:=i*uint(Base);
      asm
        jo over
      end;
      i:=i+j;
      asm
        jo over
      end;
      inc(s);
    end
  else
    while true do
    begin
      j:=CharValues[ord(s^)];
      if j>=uint(Base) then
        if s^=IgnoreChar then
        begin
          inc(s);
          continue;
        end else
          goto done;
      i:=i*uint(Base);
      asm
        jo over
      end;
      i:=i+j;
      asm
        jo over
      end;
      inc(s);
    end;

over:
  if neg then Result:=low(int)
  else Result:=high(int);
  ErrorCode^:=2;

  if IgnoreChar=#0 then
    while true do
    begin
      if CharValues[ord(s^)]>=Base then
        goto trail;
      inc(s);
    end
  else
    while true do
    begin
      if s^=IgnoreChar then
      begin
        inc(s);
        continue;
      end;
      if CharValues[ord(s^)]>=Base then
        goto trail;
      inc(s);
    end;

done:
  if s=Str then // Empty String
  begin
    ErrorCode^:=1;
    goto trail;
  end;

  if neg then
    j:=1
  else
    j:=0;
  if i>uint(high(int))+j then
  begin
    Result:=int(j+uint(high(int)));
    ErrorCode^:=2;
  end else
    if neg then
      Result:=-int(i)
    else
      Result:=i;

trail:
  if IgnoreTrailSpaces then
    while s^=' ' do
      inc(s);
  if s^<>#0 then
    ErrorCode^:=ErrorCode^ or 4;
  Str:=s;
end;

function RSStrToInt64(const s:string; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):Int64; overload;
var i:integer;
begin
  Result:=RSStrToInt64Ex(Pointer(s), @i, Base, IgnoreChar,
                                  IgnoreLeadSpaces, IgnoreTrailSpaces);
  case i of
    1: raise Exception.Create(SRSStrToIntEx1);
    2: raise Exception.Create(SRSStrToIntEx2);
    3: raise Exception.Create(SRSStrToIntEx3);
    4,5,6: raise Exception.Create(SRSStrToIntEx4);
  end;
end;

function RSStrToInt64Ex(const s:string; var ErrorCode:int; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):Int64; overload;
begin
  Result:=RSStrToInt64Ex(Pointer(s), @ErrorCode, Base, IgnoreChar,
                                  IgnoreLeadSpaces, IgnoreTrailSpaces);
end;

function RSStrToInt64Ex(s:PChar; ErrorCode:pint; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):int64; overload;
var z:LongInt; bo:boolean; b:byte; vMax:int64;
begin
{ Error Codes:
0:  ok
1:  Empty string (result is 0)
2:  The value is too big (result is a maxum or a minimum integer value)
3:  Wrong Base (result is 0)
4:  String contains wrong chars (result is the valid part of string)
6:  The value is too big and the string contains wrong chars
                         (result is a maxum or a minimum integer value)
}
  if ErrorCode=nil then ErrorCode:=@z;
  if (s=nil) or (s=#0) then
  begin
    result:=0;
    ErrorCode^:=1;
    exit;
  end;
  if IgnoreChar=' ' then
  begin
    IgnoreLeadSpaces:=true;
    IgnoreTrailSpaces:=false;
  end;
  ErrorCode^:=0;
  if (Base<2) or (Base>36) then
  begin
    result:=0;
    ErrorCode^:=3;
    exit;
  end;
  bo:=false; // Positive
  result:=0;
  if IgnoreLeadSpaces then
    while (s^<>#0) and ((s^=' ') or (s^=IgnoreChar)) do
      Inc(s);

  if s^='-' then
  begin
    bo:=true;
    inc(s);
  end else
    if s^='+' then inc(s);

  if s^='$' then
  begin
    Base:=16;
    inc(s);
  end;

  if bo then vMax:=low(int64) div Base
  else vMax:=high(int64) div Base;

  if IgnoreChar=#0 then
    if not bo then
      while s^<>#0 do
      begin
        b:=CharValues[ord(s^)];
        if b>=Base then
        begin
          ErrorCode^:=4;
          break;
        end;

        // Range checking doesn't work with int64
        if (result>vMax) or (high(int64)-b<result*Base) then
        begin
          Result:=high(int64);
          ErrorCode^:=2;
          break;
        end else
          result:=result*Base+b;

        inc(s);
      end
    else
      while s^<>#0 do
      begin
        b:=CharValues[ord(s^)];
        if b>=Base then
        begin
          ErrorCode^:=4;
          break;
        end;

        // Range checking doesn't work with int64
        if (result<vMax) or (low(int64)+b>result*Base) then
        begin
          Result:=low(int64);
          ErrorCode^:=2;
          break;
        end else
          result:=result*Base-b;

        inc(s);
      end
  else
    if not bo then
      while s^<>#0 do
      begin
        if s^=IgnoreChar then
        begin
          inc(s);
          continue;
        end;
        b:=CharValues[ord(s^)];
        if b>=Base then
        begin
          ErrorCode^:=4;
          break;
        end;

        // Range checking doesn't work with int64
        if (result>vMax) or (high(int64)-b<result*Base) then
        begin
          Result:=high(int64);
          ErrorCode^:=2;
          break;
        end else
          result:=result*Base+b;

        inc(s);
      end
    else
      while s^<>#0 do
      begin
        if s^=IgnoreChar then
        begin
          inc(s);
          continue;
        end;
        b:=CharValues[ord(s^)];
        if b>=Base then
        begin
          ErrorCode^:=4;
          break;
        end;

        // Range checking doesn't work with int64
        if (result<vMax) or (low(int64)+b>result*Base) then
        begin
          Result:=low(int64);
          ErrorCode^:=2;
          break;
        end else
          result:=result*Base-b;

        inc(s);
      end;

//  if (ErrorCode^<>0) and (ErrorCode^<>2) then exit;
  if ErrorCode^=4 then exit;

  if ErrorCode^=2 then
    while s^<>#0 do
    begin
      if s^=IgnoreChar then
      begin
        inc(s);
        continue;
      end;

      b:=CharValues[ord(s^)];
      if b>=Base then
        if (s^=' ') and IgnoreTrailSpaces then break
        else begin
          ErrorCode^:=6;
          exit;
        end;
      inc(s);
    end;

  if IgnoreTrailSpaces then
    while s^<>#0 do
      if (s^=IgnoreChar) or (s^=' ') then
        inc(s)
      else begin
        ErrorCode^:=ErrorCode^ or 4;
        exit;
      end;
end;

function RSStrToInt64Var(var s:PChar; ErrorCode:pint; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):int64; overload;
var z:LongInt; bo:boolean; b:byte; vMax:int64;
begin
{ Error Codes:
0:  ok
1:  Empty string (result is 0)
2:  The value is too big (result is a maxum or a minimum integer value)
3:  Wrong Base (result is 0)
4:  String contains wrong chars (result is the valid part of string)
6:  The value is too big and the string contains wrong chars
                         (result is a maxum or a minimum integer value)
}
  if ErrorCode=nil then ErrorCode:=@z;
  if (s=nil) or (s^=#0) then
  begin
    result:=0;
    ErrorCode^:=1;
    exit;
  end;
  if IgnoreChar=' ' then
  begin
    IgnoreLeadSpaces:=true;
    IgnoreTrailSpaces:=false;
  end;
  ErrorCode^:=0;
  if (Base<2) or (Base>36) then
  begin
    result:=0;
    ErrorCode^:=3;
    exit;
  end;
  bo:=false; // Positive
  result:=0;
  if IgnoreLeadSpaces then
    while (s^<>#0) and ((s^=' ') or (s^=IgnoreChar)) do
      Inc(s);

  if s^='-' then
  begin
    bo:=true;
    inc(s);
  end else
    if s^='+' then inc(s);

  if s^='$' then
  begin
    Base:=16;
    inc(s);
  end;

  if bo then vMax:=low(int64) div Base
  else vMax:=high(int64) div Base;

  if IgnoreChar=#0 then
    if not bo then
      while s^<>#0 do
      begin
        b:=CharValues[ord(s^)];
        if b>=Base then
        begin
          ErrorCode^:=4;
          break;
        end;

        // Range checking doesn't work with int64
        if (result>vMax) or (high(int64)-b<result*Base) then
        begin
          Result:=high(int64);
          ErrorCode^:=2;
          break;
        end else
          result:=result*Base+b;

        inc(s);
      end
    else
      while s^<>#0 do
      begin
        b:=CharValues[ord(s^)];
        if b>=Base then
        begin
          ErrorCode^:=4;
          break;
        end;

        // Range checking doesn't work with int64
        if (result<vMax) or (low(int64)+b>result*Base) then
        begin
          Result:=low(int64);
          ErrorCode^:=2;
          break;
        end else
          result:=result*Base-b;

        inc(s);
      end
  else
    if not bo then
      while s^<>#0 do
      begin
        if s^=IgnoreChar then
        begin
          inc(s);
          continue;
        end;
        b:=CharValues[ord(s^)];
        if b>=Base then
        begin
          ErrorCode^:=4;
          break;
        end;

        // Range checking doesn't work with int64
        if (result>vMax) or (high(int64)-b<result*Base) then
        begin
          Result:=high(int64);
          ErrorCode^:=2;
          break;
        end else
          result:=result*Base+b;

        inc(s);
      end
    else
      while s^<>#0 do
      begin
        if s^=IgnoreChar then
        begin
          inc(s);
          continue;
        end;
        b:=CharValues[ord(s^)];
        if b>=Base then
        begin
          ErrorCode^:=4;
          break;
        end;

        // Range checking doesn't work with int64
        if (result<vMax) or (low(int64)+b>result*Base) then
        begin
          Result:=low(int64);
          ErrorCode^:=2;
          break;
        end else
          result:=result*Base-b;

        inc(s);
      end;

//  if (ErrorCode^<>0) and (ErrorCode^<>2) then exit;
  if ErrorCode^=4 then exit;

  if ErrorCode^=2 then
    while s^<>#0 do
    begin
      if s^=IgnoreChar then
      begin
        inc(s);
        continue;
      end;

      b:=CharValues[ord(s^)];
      if b>=Base then
        if (s^=' ') and IgnoreTrailSpaces then break
        else begin
          ErrorCode^:=6;
          exit;
        end;
      inc(s);
    end;

  if IgnoreTrailSpaces then
    while s^<>#0 do
      if (s^=IgnoreChar) or (s^=' ') then
        inc(s)
      else begin
        ErrorCode^:=ErrorCode^ or 4;
        exit;
      end;
end;

function RSStrToIntFloatVar(var s:PChar; ErrorCode:pint; Base:LongInt = 10; IgnoreChar:char=#0; IgnoreLeadSpaces:boolean=false; IgnoreTrailSpaces:boolean=false):Extended; overload;
var z, sgn:LongInt; b:byte;
begin
{ Error Codes:
0:  ok
1:  Empty string (result is 0)
3:  Wrong Base (result is 0)
4:  String contains wrong chars (result is the valid part of string)
}
  if ErrorCode=nil then ErrorCode:=@z;
  if (s=nil) or (s=#0) then
  begin
    result:=0;
    ErrorCode^:=1;
    exit;
  end;
  if IgnoreChar=' ' then
  begin
    IgnoreLeadSpaces:=true;
    IgnoreTrailSpaces:=false;
  end;
  ErrorCode^:=0;
  if (Base<2) or (Base>36) then
  begin
    result:=0;
    ErrorCode^:=3;
    exit;
  end;
  sgn:=1; // Positive
  result:=0;
  if IgnoreLeadSpaces then
    while (s^<>#0) and ((s^=' ') or (s^=IgnoreChar)) do
      Inc(s);

  if s^='-' then
  begin
    sgn:=-1;
    inc(s);
  end else
    if s^='+' then inc(s);

  if s^='$' then
  begin
    Base:=16;
    inc(s);
  end;

  if IgnoreChar=#0 then
    while s^<>#0 do
    begin
      b:=CharValues[ord(s^)];
      if b>=Base then
      begin
        ErrorCode^:=4;
        exit;
      end;
      result:=result*Base + sgn*b;
      inc(s);
    end
  else
    while s^<>#0 do
    begin
      if s^=IgnoreChar then
      begin
        inc(s);
        continue;
      end;
      b:=CharValues[ord(s^)];
      if b>=Base then
      begin
        ErrorCode^:=4;
        exit;
      end;

      result:=result*Base+sgn*b;

      inc(s);
    end;

  if IgnoreTrailSpaces then
    while s^<>#0 do
      if (s^=IgnoreChar) or (s^=' ') then
        inc(s)
      else begin
        ErrorCode^:=ErrorCode^ or 4;
        exit;
      end;
end;

function RSCharToInt(c:char; Base:LongInt=36):LongInt;
begin
  result:=CharValues[ord(c)];
  if result>=Base then result:=-1;
end;

function RSFloatToStr(const Value:Extended):string;
begin
  Result:=FloatToStrF(Value, ffGeneral, 18, 0);
end;

function RSStrToFloat(s:string):extended;
begin
  Result:= StrToFloat(RSStringReplace(s, '.', DecimalSeparator,[rfReplaceAll]));
end;

function InitCharToInt(c:char; Base:LongInt=36):LongInt;
begin
  result:=ord(c);
  if (result>=$30) and (result<=$39) then Dec(result,$30) else
  if (result>=$41) and (result<=$5a) then Dec(result,$37) else
  if (result>=$61) and (result<=$7a) then Dec(result,$57) else
  begin
    result:=-1;
    exit;
  end;
  if result>=Base then result:=-1;
end;

var i:LongInt;
initialization
  for i:=0 to 255 do
    CharValues[i]:=byte(smallInt(InitCharToInt(chr(i))));

end.
