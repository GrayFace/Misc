unit RSRecent;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 List of recent files implementaion.

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses
  SysUtils, Classes, Windows, Menus, RSStrUtils, RSQ, Math;

type
  TRSRecent = class;

  TRSRecentEvent = procedure(Sender:TRSRecent; FileName:string) of object;

  TRSRecent = class(TObject)
  private
    FLimit: int;
    FOnClick: TRSRecentEvent;
    function GetAsString:string;
    procedure SetAsString(const v:string);
    procedure SetLimit(v:int);
    procedure SetSpace(const v:string);
    function GetPath(Index: int): string;
  protected
    FCount: int;
    FParent: TMenuItem;
    FLast: string;
    FFullPath: boolean;
    FSpace: string;
    FTarget: TMenuItem;
    function GetAfter:int;
    procedure Clicked(Sender:TObject);
    procedure RefreshNames;
    procedure DoDelete(it:TMenuItem); overload;
    function DoDelete(const FileName: string):boolean; overload;
    function DoStoreLast:boolean;
  public
    constructor Create(AOnClick:TRSRecentEvent; ATarget:TMenuItem;
        SubMenu:boolean; AFullPath:boolean=true);
    destructor Destroy; override;
    procedure Add(const FileName: string);
    procedure StoreLast;
    function Delete(const FileName: string):boolean;
    procedure Clear;
    property Path[Index:int]:string read GetPath;
    property Limit: int read FLimit write SetLimit;
    property FullPath: boolean read FFullPath; //write
    property AsString: string read GetAsString write SetAsString;
    property Space: string read FSpace write SetSpace;
    property OnClick: TRSRecentEvent read FOnClick write FOnClick;
  end;

implementation

const
  FilesSep = '|';
  DefLimit = 10;

type
  TRSRecentMenuItem = class(TMenuItem)
  public
    Path: string;
  end;

procedure CopyProps(ATo, From:TMenuItem);
var a:TMenuItem;
begin
  a:=From;
  with ATo do
  begin
    OnAdvancedDrawItem:=a.OnAdvancedDrawItem;
//    OnClick:=a.OnClick;
    OnDrawItem:=a.OnDrawItem;
    OnMeasureItem:=a.OnMeasureItem;
    AutoCheck:=a.AutoCheck;
    AutoHotkeys:=a.AutoHotkeys;
    AutoLineReduction:=a.AutoLineReduction;
  end;
end;

constructor TRSRecent.Create(AOnClick:TRSRecentEvent; ATarget:TMenuItem;
    SubMenu:boolean; AFullPath:boolean=true);
begin
  Assert(ATarget<>nil);
  FTarget:=ATarget;
  OnClick:=AOnClick;
  if not SubMenu then
  begin
    FParent:=ATarget.Parent;
    Assert(FParent<>nil);
  end else
    FParent:=ATarget;
  FFullPath:=AFullPath;
  FSpace:='  ';
  FLimit:=10;
end;

destructor TRSRecent.Destroy;
begin
  Clear;
  inherited;
end;

function TRSRecent.GetAfter:int;
begin
  if FParent=FTarget then
    Result:=-1
  else
    Result:=FParent.IndexOf(FTarget);
end;

procedure TRSRecent.Clicked(Sender:TObject);
begin
  if Assigned(FOnClick) then
    FOnClick(self, TRSRecentMenuItem(Sender).Path);
end;

procedure TRSRecent.RefreshNames;
var i,j:int;
begin
  j:=GetAfter+1;
  with FParent do
    if FFullPath then
      for i:=0 to FCount-1 do
        Items[i+j].Caption:= IntToHex(i,0) + FSpace +
           TRSRecentMenuItem(Items[i+j]).Path
    else
      for i:=0 to FCount-1 do
        Items[i+j].Caption:= IntToHex(i,0) + FSpace +
           ExtractFileName(TRSRecentMenuItem(Items[i+j]).Path);
end;

function TRSRecent.DoStoreLast:boolean;
var a:TRSRecentMenuItem; i:int;
begin
  Result:= FLast<>'';
  if not Result then exit;
  with FParent do
  begin
    a:= TRSRecentMenuItem.Create(FParent.GetParentMenu);
    CopyProps(a, FTarget);
    a.OnClick:=Clicked;
    a.Path:= FLast;
    FLast:='';
    i:=GetAfter;
    if FCount>=FLimit then
      DoDelete(Items[i+FCount]);
    Insert(i+1, a);
    inc(FCount);
  end;
end;

procedure TRSRecent.StoreLast;
begin
  if DoStoreLast then
    RefreshNames;
end;

procedure TRSRecent.Add(const FileName:string);
var b:boolean;
begin
  if SameText(FileName, FLast) then exit;
  b:=DoDelete(FileName);
  b:=DoStoreLast or b;
  FLast:=FileName;
  if b then
    RefreshNames;
end;

procedure TRSRecent.DoDelete(it:TMenuItem);
begin
  it.Free;
  dec(FCount);
end;

function TRSRecent.DoDelete(const FileName: string):boolean;
var i:int;
begin
  i:=GetAfter;
  for i:=i+1 to i+FCount do
    if SameText(TRSRecentMenuItem(FParent[i]).Path, FileName) then
    begin
      DoDelete(FParent[i]);
      Result:=true;
      exit;
    end;
  Result:=false;
end;

function TRSRecent.Delete(const FileName: string):boolean;
begin
  Result:=DoDelete(FileName);
  if Result then RefreshNames;
  if not Result and (FLast=FileName) then
  begin
    FLast:='';
    Result:=true;
  end;
end;

procedure TRSRecent.Clear;
var i:int;
begin
  FLast:='';
  i:=GetAfter;
  for i:=i+FCount downto i+1 do
    DoDelete(FParent[i]);
end;

procedure TRSRecent.SetLimit(v:int);
var i:int;
begin
  if v<FCount then
  begin
    i:=GetAfter;
    for i:=i+FCount downto i+v+1 do
      DoDelete(FParent[i]);
  end;
  FLimit:=v;
end;

procedure TRSRecent.SetSpace(const v:string);
begin
  if FSpace=v then exit;
  FSpace:=v;
  RefreshNames;
end;

function TRSRecent.GetAsString:string;
var i,j:int;
begin
  Result:=FLast;
  j:=FCount;
  if Result<>'' then
  begin
    Result:=Result+'|';
    if j=FLimit then
      dec(j);
  end;
  i:=GetAfter;
  for i:=i+1 to i+j do
    Result:= Result + TRSRecentMenuItem(FParent[i]).Path + '|';
end;

procedure TRSRecent.SetAsString(const v:string);
var i:int; ps:TRSParsedString;
begin
  Clear;
  ps:=RSParseString(v, ['|']);
  for i:=min(RSGetTokensCount(ps, true), FLimit)-1 downto 0 do
    Add(RSGetToken(ps, i));
  StoreLast;
end;


function TRSRecent.GetPath(Index: int): string;
begin
  if FLast<>'' then
    if Index = 0 then
    begin
      Result:= FLast;
      exit;
    end else
      dec(Index);

  if Index<FCount then
    Result:= TRSRecentMenuItem(FParent.Items[GetAfter + Index + 1]).Path
  else
    Result:='';
end;

end.
