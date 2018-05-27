unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, RSLabel, RSSpinEdit, ExtCtrls, RSShape, Buttons,
  RSSpeedButton, ExtDlgs, Unit1, RSQ, RSLang;

type
  TForm3 = class(TForm)
    RSSpinEdit1: TRSSpinEdit;
    RSLabel1: TRSLabel;
    ButtonOk: TButton;
    ButtonCancel: TButton;
    RSShape1: TRSShape;
    RSShape2: TRSShape;
    RSShape3: TRSShape;
    RSShape4: TRSShape;
    RSShape5: TRSShape;
    RSShape6: TRSShape;
    RSShape7: TRSShape;
    RSShape8: TRSShape;
    RSShape9: TRSShape;
    RSShape10: TRSShape;
    RSShape11: TRSShape;
    RSShape12: TRSShape;
    RSShape13: TRSShape;
    RSShape14: TRSShape;
    RSShape15: TRSShape;
    RSShape16: TRSShape;
    RSShape17: TRSShape;
    RSShape18: TRSShape;
    RSShape19: TRSShape;
    RSShape20: TRSShape;
    RSShape21: TRSShape;
    RSShape22: TRSShape;
    RSShape23: TRSShape;
    RSShape24: TRSShape;
    RSShape25: TRSShape;
    RSShape26: TRSShape;
    RSShape27: TRSShape;
    RSShape28: TRSShape;
    RSShape29: TRSShape;
    RSShape30: TRSShape;
    RSShape31: TRSShape;
    RSShape32: TRSShape;
    SpeedButtonLoad: TRSSpeedButton;
    SpeedButtonDefault: TRSSpeedButton;
    OpenPictureDialog1: TOpenPictureDialog;
    ColorDialog1: TColorDialog;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RSShape1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButtonDefaultClick(Sender: TObject);
    procedure SpeedButtonLoadClick(Sender: TObject);
    procedure ButtonOkClick(Sender: TObject);
  private
    Shapes: array[0..31] of TShape;
    Info: PColorBoxInfo;
  public
    function Execute(var Info: TColorBoxInfo): TModalResult;
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.FormCreate(Sender: TObject);
begin
  RSLanguage.AddSection('[Player Colors Form]', self);
  DestroyHandle;
end;

procedure TForm3.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

function TForm3.Execute(var Info: TColorBoxInfo): TModalResult;
var i:int;
begin
  self.Info:= @Info;
  RSSpinEdit1.Value:= Info.Tolerance;
  for i:=0 to 31 do
  begin
    Shapes[i]:= ptr(FindComponent('RSShape'+IntToStr(i+1)));
    Shapes[i].Brush.Color:= Info.PlayerColors[i];
  end;
  Result:= ShowModal;
  DestroyHandle;
end;

procedure TForm3.RSShape1Click(Sender: TObject);
begin
  with ColorDialog1, TShape(Sender) do
  begin
    Color:= Brush.Color;
    if not Execute then exit;
    Brush.Color:= Color;
  end;
end;

procedure TForm3.SpeedButtonDefaultClick(Sender: TObject);
var i:int;
begin
  for i:=0 to 31 do
    Shapes[i].Brush.Color:= DefPlayerColors[i];
end;

procedure TForm3.SpeedButtonLoadClick(Sender: TObject);
var
  Pal: array[0..31] of TColor;
  i:int;
begin
  if not OpenPictureDialog1.Execute then  exit;
  with TBitmap.Create do
    try
      LoadFromFile(OpenPictureDialog1.FileName);
      if PixelFormat = pf8bit then
      begin
        GetPaletteEntries(Palette, 224, 32, Pal);
        for i:=0 to 31 do
          Shapes[i].Brush.Color:= Pal[i] and $ffffff;
      end;
    finally
      Free;
    end;
end;

procedure TForm3.ButtonOkClick(Sender: TObject);
var i:int;
begin
  Info.Tolerance:= RSSpinEdit1.Value;
  for i:=0 to 31 do
    Info.PlayerColors[i]:= Shapes[i].Brush.Color;
end;

end.
