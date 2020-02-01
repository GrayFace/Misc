program H3DefTool;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas',
  Unit3 in 'Unit3.pas' {Form3};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Def Tool';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm3, Form3);
  if Form1.FormsCreated then
    Application.Run;
end.
