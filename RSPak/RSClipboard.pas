unit RSClipboard;

interface

uses
  Classes, Clipbrd, Windows;

type
  TRSClipboard = class(TClipboard)
  private
    function GetText: WideString;
    procedure SetText(const v: WideString);
  public
    procedure SetBuffer(Format: Word; var Buffer; Size: Integer);
    property Text: WideString read GetText write SetText;
  end;

function Clipboard: TRSClipboard;
  
implementation

function TRSClipboard.GetText: WideString;
var
  Data: THandle;
begin
  Open;
  Data := GetClipboardData(CF_UNICODETEXT);
  try
    if Data <> 0 then
      Result := PWideChar(GlobalLock(Data))
    else
      Result := '';
  finally
    if Data <> 0 then GlobalUnlock(Data);
    Close;
  end;
end;

procedure TRSClipboard.SetBuffer(Format: Word; var Buffer; Size: Integer);
begin
  inherited;
end;

function Clipboard: TRSClipboard;
begin
  Result:= TRSClipboard(Clipbrd.Clipboard);
end;

procedure TRSClipboard.SetText(const v: WideString);
begin
  inherited SetBuffer(CF_UNICODETEXT, PWideChar(v)^, 2*(Length(v) + 1));
end;

end.
