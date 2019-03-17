unit RSWindowProc;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 Safe hooking of WindowProc property.

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses Windows, Messages, SysUtils, Classes, Controls, RSQ, RSCommon, RSSysUtils;

type
  TRSWndProcHookEvent = procedure (Sender:TObject; var Msg:TMessage;
          const NextWndProc:TWndMethod) of object;

function RSHookWindowProc(Control:TControl; Proc:TRSWndProcHookEvent;
   Priority:int=200):ptr;

function RSUnhookWindowProc(Control:TControl; Proc:TRSWndProcHookEvent):boolean; overload;
procedure RSUnhookWindowProc(HookObj:ptr); overload;

implementation

type
  TWindowHook = class(TRSEventHook)
  protected
    FTarget: TControl;
    FCallback: TRSWndProcHookEvent;
    function GetEvent:TMethod; override;
    procedure SetEvent(const v:TMethod); override;
    procedure WndProc(var Msg: TMessage);
  public
    constructor Create(c:TControl; Proc:TRSWndProcHookEvent; Priority:int);
  end;

constructor TWindowHook.Create(c:TControl; Proc:TRSWndProcHookEvent;
  Priority:int);
begin
  FEventProc:=@TWindowHook.WndProc;
  FTarget:=c;
  inherited Create(Priority);
  FCallback:=Proc;
end;

procedure TWindowHook.WndProc(var Msg: TMessage);
var Last:TRSEventHook;
begin
  if FDeleting then exit;
  Last:=GetLast; // It's very important that Last is stored in a local variable
                 // because self may be destroyed in the FCallback
  if Last<>nil then  Last.Lock(true);
  try
    FCallback(FTarget, Msg, TWndMethod(FLastProc));
  finally
    if Last<>nil then  Last.Lock(false);
  end;
end;

function TWindowHook.GetEvent:TMethod;
begin
  Result:=TMethod(FTarget.WindowProc);
end;

procedure TWindowHook.SetEvent(const v:TMethod);
begin
  FTarget.WindowProc:=TWndMethod(v);
end;


function RSHookWindowProc(Control:TControl; Proc:TRSWndProcHookEvent;
   Priority:int=200):ptr;
begin
  Result:=TWindowHook.Create(Control, Proc, Priority);
end;

function RSUnhookWindowProc(Control:TControl; Proc:TRSWndProcHookEvent):boolean; overload;
var Obj:TWindowHook; WndProc:TMethod;
begin
  Result:=true;
  WndProc:=TMethod(Control.WindowProc);
  while WndProc.Code=@TWindowHook.WndProc do
  begin
    Obj:=WndProc.Data;
    WndProc:=Obj.FLastProc;
    if (TMethod(Obj.FCallback).Data = TMethod(Proc).Data) and
       (TMethod(Obj.FCallback).Code = TMethod(Proc).Code) then
    begin
      Obj.Delete;
      exit;
    end;
  end;
  Result:=false;
end;

procedure RSUnhookWindowProc(HookObj:ptr); overload;
begin
  TWindowHook(HookObj).Delete;
end;

end.
