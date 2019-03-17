unit RSQHelp1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Math, Themes, RSQ, RSLang, RSStrUtils;


procedure RSHelpCreate(ClassName:string='');
  
procedure RSHelpShow(HideForms:array of TControl;
            w:integer=440; h:integer=463);

type
  TRSHelp = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMSysCommand(var msg:TWMSysCommand); message WM_SysCommand;
  public

  end;

var RSHelp:TRSHelp;

implementation

var FClass:string;
    Hides:array of TControl;

{$R *.dfm}

procedure RSHelpCreate(ClassName:string='');
begin
  if ClassName='' then
    ClassName:= AppTitle + ' Help Form';
  FClass:=ClassName;
  RSHelp:=TRSHelp.Create(Application);
  RSHelp.DestroyHandle;
  RSLanguage.AddSection('[Help]', RSHelp);
end;

procedure RSHelpShow(HideForms:array of TControl;
            w, h:integer);
var i:integer;
begin
  if RSHelp.Visible then  exit;
   
  SetLength(Hides, high(HideForms)-low(HideForms)+1);
  for i:=0 to length(Hides)-1 do
    Hides[i]:=HideForms[low(HideForms)+i];
  with RSHelp do
  begin
    Width:=w;
    Height:=h;
    ShowModal;
    DestroyHandle;
  end;
end;

procedure TRSHelp.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  CopyMemory(@Params.WinClassName[0], ptr(FClass),
             min(SizeOf(Params.WinClassName)-1, length(FClass)+1));
  Params.WinClassName[63]:=#0;
end;

procedure TRSHelp.WMSysCommand(var msg:TWMSysCommand);
var i:integer;
begin
  if msg.CmdType=SC_MINIMIZE then
  begin
    msg.Result:=0;
    if length(Hides)=0 then
      Application.Minimize
    else
    begin
      for i:=0 to length(Hides)-1 do
        Hides[i].Hide;
      Hide;
    end;
  end else inherited;
end;

procedure TRSHelp.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TRSHelp.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_ESCAPE then Close;
end;

procedure TRSHelp.FormCreate(Sender: TObject);
begin
  if not ThemeServices.ThemesEnabled then
    with Memo1 do
    begin
      BorderStyle:=bsNone;
      BevelKind:=bkFlat;
    end;
end;

end.
