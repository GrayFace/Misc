unit RSSpinEditRegister;

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
  SysUtils, Classes, RSSpinEdit, DesignIntf, DesignEditors;//, DesignMenus, VCLEditors;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSSpinEdit]);
  RegisterComponents('RSPak', [TRSFloatSpinEdit]);
  RegisterComponents('RSPak', [TRSSpinButton]);

  RegisterPropertyEditor(TComponent.ClassInfo, TRSSpinEdit, 'Button', TClassProperty);
  RegisterPropertyEditor(TComponent.ClassInfo, TRSSpinButton, 'UpButton', TClassProperty);
  RegisterPropertyEditor(TComponent.ClassInfo, TRSSpinButton, 'DownButton', TClassProperty);
end;

end.
 