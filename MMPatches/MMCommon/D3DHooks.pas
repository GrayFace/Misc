unit D3DHooks;

interface

uses
  Windows, Messages, SysUtils, Classes, RSSysUtils, RSQ, Common, RSCodeHook,
  Math, MP3, RSDebug, IniFiles, Direct3D, Graphics, MMSystem, RSStrUtils,
  DirectDraw, DXProxy, RSResample, RSGraphics, MMCommon, MMHooks;

{$I MMPatchVer.inc}
  
procedure CheckHooksD3D;
procedure ApplyHooksD3D;

implementation

//----- Precise sprites placement

var
  DrawSpritePos: array of array[0..1] of int2;
  DrawSpriteCount: int;
  DrawSpriteOff: int;
  FloatToIntShl16: single = 6755399441055744/$10000;

procedure ExtendDrawSpritePos(n: int);
begin
  DrawSpriteCount:= n + max(501, DrawSpriteCount);
  SetLength(DrawSpritePos, DrawSpriteCount);
end;

procedure CheckDrawSpriteCount;
asm
  push eax
  mov eax, [__SpritesToDrawCount]
  cmp eax, DrawSpriteCount
  jl @ok
  push edx
  push ecx
  call ExtendDrawSpritePos
  pop ecx
  pop edx
@ok:
  pop eax
end;

procedure StoreSpriteRemainder;
asm
  call CheckDrawSpriteCount
  // store ax as int16
  push edx
  mov edx, [__SpritesToDrawCount]
  shl edx, 2
  and DrawSpriteOff, 2
  add edx, DrawSpriteOff
  xor DrawSpriteOff, 2
  add edx, DrawSpritePos
  mov [edx], ax
  pop edx
end;

procedure StoreSpriteRemainderAndShr16;
asm
  call StoreSpriteRemainder
  add eax, $8000
  sar eax, 16
end;

{$IFDEF MM7}
procedure StoreSpriteRemainderIndoor;
asm
  push eax
  cmp DrawSpriteOff, 2
  jz @y
  neg eax
@y:
  call StoreSpriteRemainder
  pop eax
  add eax, $8000
  sar eax, 16
end;
{$ELSE}
procedure StoreSpriteRemainderIndoor;
asm
  cmp DrawSpriteOff, 2
  jz StoreSpriteRemainderAndShr16
  neg eax
  call StoreSpriteRemainder
  neg eax
  add eax, $8000
  sar eax, 16
end;
{$ENDIF}

procedure LoadSpriteRemainder;
asm
  call CheckDrawSpriteCount
  push ecx
  shl eax, 16
  mov ecx, DrawSpriteOff
  add ecx, DrawSpritePos
  add DrawSpriteOff, 2
  movsx ecx, word ptr [ecx]
  sub eax, ecx
// check for loop end:
  mov ecx, [__SpritesToDrawCount]
  shl ecx, 2
  cmp ecx, DrawSpriteOff
  jg @ok
  and DrawSpriteOff, 2
@ok:
  pop ecx
end;

procedure FShr16;
const
  a: int = $10000;
asm
  fidiv a
end;

procedure FShr16x;
const
  a: int = $10000;
asm
  fild dword ptr [ebp - $14]
  fidiv a
  fld dword ptr [ebp + $C]
end;

//----- Precise mouse

procedure LoadMouseRemainderX;
asm
  fadd MouseDX
end;

procedure LoadMouseRemainderY;
asm
  fadd MouseDY
end;

procedure FacetViewIntersectionProc(var x, y: int);
begin
  x:= Round(x*GetCoordCorrectionIndoorX);
  y:= Round(y*GetCoordCorrectionIndoorY);
end;

//----- Support any FOV indoors

procedure FacetViewIntersectionHook;
asm
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  push [esp + 7*4]
  call eax
  mov eax, [esp + 5*4]
  mov edx, [esp + 6*4]
  call FacetViewIntersectionProc
  ret 7*4
end;

//----- HooksList

var
{$IFDEF MM7}
  HooksD3D: array[1..22] of TRSHookInfo = (
    (p: $436ABE; old: $4D8578; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (indoor)
    (p: $436AED; old: $4D8578; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (indoor)
    (p: $436AC2; newp: @StoreSpriteRemainderIndoor; t: RShtAfter; size: 6), // Precise sprites placement (indoor)
    (p: $436AF1; newp: @StoreSpriteRemainderIndoor; t: RShtAfter; size: 6), // Precise sprites placement (indoor)
    (p: $47B30D; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (items outdoor)
    (p: $47B336; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (items outdoor)
    (p: $47AD93; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (decor outdoor)
    (p: $47ADB9; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (decor outdoor)
    (p: $47B8BD; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (monsters outdoor)
    (p: $47B8E6; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (monsters outdoor)
    (p: $440D3D; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $440D46; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $4A4485; newp: @FShr16x; t: RShtCall; size: 6), // Precise sprites placement (indoor)
    (p: $4A44A6; newp: @FShr16; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $47BB3C; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $47BB49; newp: @LoadSpriteRemainder; t: RShtBefore), // Precise sprites placement (outdoor)
    (p: $4A40FD; newp: @FShr16; t: RShtAfter; size: 6), // Precise sprites placement (outdoor)
    (p: $4A4120; newp: @FShr16; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $44EB1B; newp: @LoadMouseRemainderX; t: RShtBefore; size: 7), // Precise mouse
    (p: $44EB1B; newp: @LoadMouseRemainderY; t: RShtAfter), // Precise mouse
    (p: $423BD1; newp: @FacetViewIntersectionHook; t: RShtCallStore), // Support any FOV indoors (portals D3D)
    ()
  );
{$ELSE}
  HooksD3D: array[1..24] of TRSHookInfo = (
    (p: $43443B; old: $4E8590; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (indoor)
    (p: $43446A; old: $4E8590; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (indoor)
    (p: $43443F; newp: @StoreSpriteRemainderIndoor; t: RShtAfter; size: 6), // Precise sprites placement (indoor)
    (p: $43446E; newp: @StoreSpriteRemainderIndoor; t: RShtAfter; size: 6), // Precise sprites placement (indoor)
    (p: $47A5D5; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (items outdoor)
    (p: $47A5FE; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (items outdoor)
    (p: $479FFB; old: $4E8798; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (decor outdoor)
    (p: $47A021; old: $4E8798; newp: @FloatToIntShl16; t: RSht4), // Precise sprites placement (decor outdoor)
    (p: $479FFF; newp: @StoreSpriteRemainderAndShr16; t: RShtAfter; size: 6), // Precise sprites placement (decor outdoor)
    (p: $47A025; newp: @StoreSpriteRemainderAndShr16; t: RShtAfter; size: 6), // Precise sprites placement (decor outdoor)
    (p: $47ABA4; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (monsters outdoor)
    (p: $47ABD3; newp: @StoreSpriteRemainder; t: RShtAfter; size: 6), // Precise sprites placement (monsters outdoor)
    (p: $43DC89; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $43DC8F; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    (p: $4A2338; newp: @FShr16; t: RShtAfter; size: 10), // Precise sprites placement (indoor)
    (p: $4A2359; newp: @FShr16; t: RShtBefore; size: 6), // Precise sprites placement (indoor)
    // 476B97, 48A85E - immediately used remainder
    (p: $47AE2F; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $47AE35; newp: @LoadSpriteRemainder; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $4A1FB2; newp: @FShr16; t: RShtAfter), // Precise sprites placement (outdoor)
    (p: $4A1FD9; newp: @FShr16; t: RShtBefore; size: 6), // Precise sprites placement (outdoor)
    (p: $44C273; newp: @LoadMouseRemainderX; t: RShtBefore; size: 7), // Precise mouse
    (p: $44C273; newp: @LoadMouseRemainderY; t: RShtAfter), // Precise mouse
    (p: $42203F; newp: @FacetViewIntersectionHook; t: RShtCallStore), // Support any FOV indoors (portals D3D)
    ()
  );
{$ENDIF}

procedure CheckHooksD3D;
begin
  CheckHooks(HooksD3D);
end;

procedure ApplyHooksD3D;
begin
  RSApplyHooks(HooksD3D);
end;

end.
