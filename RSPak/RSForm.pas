unit RSForm;

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
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, Forms, RSCommon,
  RSQ;

{$I RSWinControlImport.inc}

type
  TRSForm = class(TForm)
  protected
    procedure ReadState(Reader: TReader); override;
  end;

implementation

{
*********************************** TRSForm ************************************
}


{ TRSForm }

procedure TRSForm.ReadState(Reader: TReader);
begin
  pint(@Screen.PixelsPerInch)^:= 96;
  inherited;
end;

end.
