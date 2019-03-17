unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, RSMemo, ExtCtrls, RSPanel, AppEvnts, RSDebug, XPMan,
  RSSysUtils;

type
  TForm1 = class(TForm)
    RSPanel1: TRSPanel;
    Memo1: TRSMemo;
    ApplicationEvents1: TApplicationEvents;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    FInfo: string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  RSDebugUseDefaults;
  RSDebugHook;
  Memo1.WordWrap:= true;
  FInfo:= Memo1.Text;
end;

procedure TForm1.ApplicationEvents1Exception(Sender: TObject;
  E: Exception);
begin
  Memo1.WordWrap:= false;
  Memo1.Text:= RSLogExceptions;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  raise Exception.Create('Hi There');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  self:= nil;
  Tag:= 0;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  self:=nil;
  try
    try
      Tag:=0;
    finally
      raise Exception.Create('First');
    end;
  except
    raise Exception.Create('Second');
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  raise TObject(1);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  Memo1.Text:= FInfo;
  Memo1.WordWrap:= true;
end;

end.
