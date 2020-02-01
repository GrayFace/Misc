program MMArchive;

uses
  Forms, RSUtils, RSSysUtils, XPMan,
  RSLodEdt;

{$R *.res}

begin
  Application.Initialize;
  RSLodEdit.Initialize(true);
  RSLodEdit.AppCaption:= 'MMArchive';

  AssertErrorProc:= RSAssertErrorHandler;
  RSFixThemesBug;
  HintWindowClass:= TRSSimpleHintWindow;

  RSLodEdit.Load(ParamStr(1));
  Application.Run;
end.

