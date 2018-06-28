unit RSResample15;

interface

uses
  Windows, Messages, SysUtils, RSSysUtils, Classes, RSQ, Math, RSResample;

type
  TRSResampleInfo = RSResample.TRSResampleInfo;

//procedure RSResample16(const info: TRSResampleInfo; Src: ptr; SrcPitch: IntPtr; Dest: ptr; DestPitch: IntPtr); overload;
procedure RSResampleTrans15(const info: TRSResampleInfo; Src: ptr; SrcPitch: int; Dest: ptr; DestPitch: int; Trans: int);
//procedure RSResampleTrans16_NoAlpha(const info: TRSResampleInfo; Src: ptr; SrcPitch: int; Dest: ptr; DestPitch: int; Trans: int);

implementation

function GetPixel16(c: uint): uint;
begin
  // r,b components - 5 bit: *(2^5 + 1) shr 2
  Result:= (c and $1F)*33 shr 2 + (c and $7B00)*33 shr 12 shl 16;
  inc(Result, (c and $3E0)*33 shr 7 shl 8);  // g component - 5 bit
end;

procedure RSResample16_Any(const info: TRSResampleInfo; Src: ptr; SrcPitch: int;
   Dest: ptr; DestPitch: int; Trans: int; HasTrans: Boolean; NoAlpha: Boolean); inline; forward;

procedure RSResampleTrans15(const info: TRSResampleInfo; Src: ptr; SrcPitch: int; Dest: ptr; DestPitch: int; Trans: int);
begin
  RSResample16_Any(info, Src, SrcPitch, Dest, DestPitch, Trans, true, false);
end;

{$DEFINE RSResample15}
{$I RSResample.pas}
