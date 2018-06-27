unit MP3;

interface

uses
  Windows, Messages, SysUtils, RSSysUtils, RSQ, RSCodeHook, Math, Common;

procedure HookMP3;
function RedbookStatus: int;

implementation

function AIL_open_stream(mainHandle: ptr; fileName: ptr; unk: Bool):ptr; stdcall; external 'MSS32.dll' name '_AIL_open_stream@12';
procedure AIL_close_stream(stream: ptr); stdcall; external 'MSS32.dll' name '_AIL_close_stream@4';
procedure AIL_pause_stream(stream: ptr; pause: Bool); stdcall; external 'MSS32.dll' name '_AIL_pause_stream@8';
procedure AIL_set_stream_volume(stream: ptr; volume: int); stdcall; external 'MSS32.dll' name '_AIL_set_stream_volume@8';
procedure AIL_set_stream_loop_count(stream: ptr; count: int); stdcall; external 'MSS32.dll' name '_AIL_set_stream_loop_count@8';
procedure AIL_service_stream(stream: ptr; service: Bool); stdcall; external 'MSS32.dll' name '_AIL_service_stream@8';
function AIL_last_error: PChar; stdcall; external 'MSS32.dll' name '_AIL_last_error@0';
procedure AIL_serve; stdcall; external 'MSS32.dll' name '_AIL_serve@0';
procedure AIL_start_stream(stream: ptr); stdcall; external 'MSS32.dll' name '_AIL_start_stream@4';
procedure AIL_set_stream_ms_position(stream: ptr; pos: int); stdcall; external 'MSS32.dll' name '_AIL_set_stream_ms_position@8';

procedure AIL_set_preference(pref, val: int); stdcall; external 'MSS32.dll' name '_AIL_set_preference@8';
function AIL_redbook_status(handle: ptr): int; stdcall; external 'MSS32.dll' name '_AIL_redbook_status@4';
function AIL_stream_status(handle: ptr): int; stdcall; external 'MSS32.dll' name '_AIL_stream_status@4';

const
  RedbookHandle = pptr($FEB604);
  MSSHandle = pptr($FEB608);
var
  mp3stream: ptr;
  mp3volume: int;

procedure AIL_redbook_track_info_Hook(this, track:int; pos, myparam:pint); stdcall;
begin
  pos^:= 0;
  myparam^:= track;
end;

procedure AIL_redbook_stop_Hook(this: int); stdcall;
begin
  if mp3stream <> nil then
  begin
    AIL_close_stream(mp3stream);
    mp3stream:= nil;
  end;
end;

procedure AIL_redbook_play_Hook(this, pos, track: int); stdcall;
begin
  AIL_redbook_stop_Hook(0);
  if MSSHandle^ <> nil then
    mp3stream:= AIL_open_stream(MSSHandle^, ptr(Format('Music\%d.mp3', [track])), false);

  if mp3stream <> nil then
  begin
    AIL_set_stream_volume(mp3stream, mp3volume);
    AIL_service_stream(mp3stream, true);
    AIL_set_stream_ms_position(mp3stream, pos);
    AIL_start_stream(mp3stream);
  end;
end;

procedure AIL_redbook_set_volume_Hook(this, vol: int); stdcall;
begin
  mp3volume:= vol*4 + vol div 15;
  if mp3stream <> nil then
    AIL_set_stream_volume(mp3stream, mp3volume);
end;

function AIL_redbook_volume_Hook(this: int):int; stdcall;
begin
  Result:= 120;
end;

procedure AIL_redbook_pause_Hook(this: int); stdcall;
begin
  if mp3stream <> nil then
    AIL_pause_stream(mp3stream, true);
end;

procedure AIL_redbook_resume_Hook(this: int); stdcall;
begin
  if mp3stream <> nil then
    AIL_pause_stream(mp3stream, false);
end;

function AIL_redbook_tracks_Hook(this: int):int; stdcall;
begin
  Result:= 100000; // 16 tracks normally on CD
end;

function AIL_redbook_open_drive_Hook(drive: int):int;
begin
  AIL_set_preference(16, 32768*16);
  Result:= 1;
end;

const
  HooksList: array[1..11] of TRSHookInfo = (
    (p: $4E832C; newp: @AIL_redbook_track_info_Hook; t: RSht4),
    (p: $4E8330; newp: @AIL_redbook_play_Hook; t: RSht4),
    (p: $4E8328; newp: @AIL_redbook_stop_Hook; t: RSht4),
    (p: $4E82F4; newp: @AIL_redbook_set_volume_Hook; t: RSht4),
    (p: $4E8364; newp: @AIL_redbook_volume_Hook; t: RSht4),
    (p: $4E8308; newp: @AIL_redbook_stop_Hook; t: RSht4),
    (p: $4E834C; newp: @AIL_redbook_open_drive_Hook; t: RSht4),
    (p: $4E8324; newp: @AIL_redbook_pause_Hook; t: RSht4),
    (p: $4E8320; newp: @AIL_redbook_resume_Hook; t: RSht4),
    (p: $4E8360; newp: @AIL_redbook_tracks_Hook; t: RSht4),
    ()
  );


procedure HookMP3;
begin
  RSApplyHooks(HooksList);
end;

function RedbookStatus: int;
begin
  Result:= 0;
  if Options.PlayMP3 then
  begin
    if mp3stream <> nil then
      case AIL_stream_status(mp3stream) of
        4: Result:= 1; // playing
        8: Result:= 2; // paused
        2: Result:= 3; // stopped
      end;
  end else
  begin
    if RedbookHandle^ <> nil then
      Result:= AIL_redbook_status(RedbookHandle^);
  end;
end;

end.
