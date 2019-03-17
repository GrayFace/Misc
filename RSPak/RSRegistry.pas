unit RSRegistry;

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
  SysUtils, Registry, RSQ;

type
  TRSRegistry = class(TRegistry)
  public
    function GetData(const Name: string; Buffer: Pointer;
      BufSize: Integer; var RegData: TRegDataType): Integer;
    procedure PutData(const Name: string; Buffer: Pointer; BufSize: Integer;
      RegData: TRegDataType);
    function Read(const Name: string; var v: Boolean):boolean; overload;
    function Read(const Name: string; var v: TDateTime):boolean; overload;
    function Read(const Name: string; var v: Double):boolean; overload;
    function Read(const Name: string; var v: Currency):boolean; overload;
    function Read(const Name: string; var v: Integer):boolean; overload;
    function Read(const Name: string; var v: string):boolean; overload;
    // Maybe will do same things with Write...
  end;

implementation

function TRSRegistry.GetData(const Name: string; Buffer: Pointer;
  BufSize: Integer; var RegData: TRegDataType): Integer;
begin
  Result:=inherited GetData(Name, Buffer, BufSize, RegData);
end;

procedure TRSRegistry.PutData(const Name: string; Buffer: Pointer;
  BufSize: Integer; RegData: TRegDataType);
begin
  inherited PutData(Name, Buffer, BufSize, RegData);
end;

function TRSRegistry.Read(const Name: string; var v: Boolean):boolean;
begin
  try
    v:=ReadBool(Name);
    Result:=true;
  except
    Result:=false;
  end;
end;

function TRSRegistry.Read(const Name: string; var v: TDateTime):boolean;
begin
  try
    v:=ReadDateTime(Name);
    Result:=true;
  except
    Result:=false;
  end;
end;

function TRSRegistry.Read(const Name: string; var v: Double):boolean;
begin
  try
    v:=ReadFloat(Name);
    Result:=true;
  except
    Result:=false;
  end;
end;

function TRSRegistry.Read(const Name: string; var v: Currency):boolean;
begin
  try
    v:=ReadCurrency(Name);
    Result:=true;
  except
    Result:=false;
  end;
end;

function TRSRegistry.Read(const Name: string; var v: Integer):boolean;
begin
  try
    v:=ReadInteger(Name);
    Result:=true;
  except
    Result:=false;
  end;
end;

function TRSRegistry.Read(const Name: string; var v: string):boolean;
begin
  try
    v:= ReadString(Name);
    Result:= GetDataSize(Name)>=0;
  except
    Result:= false;
  end;
end;

end.
