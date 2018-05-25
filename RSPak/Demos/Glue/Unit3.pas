unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RSWinController, RSGlue;

type
  TForm3 = class(TForm)
    RSGlue1: TRSGlue;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

uses Unit1, Unit2;

{$R *.dfm}

procedure TForm3.FormCreate(Sender: TObject);
begin
  with Form1.RSGlue1 do
  begin
    AddMagnet(Form2);
    AddMagnet(Form3);
  end;
  with Form2.RSGlue1 do
  begin
    AddMagnet(Form1);
    AddMagnet(Form3);
  end;
  with Form3.RSGlue1 do
  begin
    AddMagnet(Form1);
    AddMagnet(Form2);
  end;
end;

end.
