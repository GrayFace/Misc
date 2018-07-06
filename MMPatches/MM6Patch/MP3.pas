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
  RedbookHandle = pptr($9CF5A0);
  MSSHandle = pptr($9CF5A4);
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
var
  s: string;
begin
  AIL_redbook_stop_Hook(0);
  if MSSHandle^ <> nil then
  begin
    s:= Format('Music\%d.wav', [track]);
    if not FileExists(s) then
    begin
      s:= Format('Music\%d.mp3', [track]);
      if not FileExists(s) then
        s:= Format('Sounds\%d.mp3', [track]);
    end;
    mp3stream:= AIL_open_stream(MSSHandle^, ptr(s), false);
  end;

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
  mp3volume:= vol*4 + vol + vol div 3;
  if mp3stream <> nil then
    AIL_set_stream_volume(mp3stream, mp3volume);
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

function AIL_redbook_open_Hook:int;
begin
  AIL_set_preference(16, 32768*16);
  Result:= 1;
end;

const
  HooksList: array[1..10] of TRSHookInfo = (
    (p: $4B9288; newp: @AIL_redbook_track_info_Hook; t: RSht4),
    (p: $4B928C; newp: @AIL_redbook_play_Hook; t: RSht4),
    (p: $4B92A0; newp: @AIL_redbook_stop_Hook; t: RSht4),
    (p: $4B9284; newp: @AIL_redbook_set_volume_Hook; t: RSht4),
    (p: $4B9238; newp: @AIL_redbook_stop_Hook; t: RSht4),
    (p: $48FCF8; old: $4B8FA0; newp: @AIL_redbook_open_Hook; t: RShtCall),
    (p: $4B923C; newp: @AIL_redbook_pause_Hook; t: RSht4),
    (p: $4B925C; newp: @AIL_redbook_resume_Hook; t: RSht4),
    (p: $4B9258; newp: @AIL_redbook_tracks_Hook; t: RSht4),
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
        16: Result:= 1; // playing
        8: Result:= 2; // paused
      else
        Result:= 3;
        //2: Result:= 3; // stopped
      end;
  end else
  begin
    if RedbookHandle^ <> nil then
      Result:= AIL_redbook_status(RedbookHandle^);
  end;
end;

end.
