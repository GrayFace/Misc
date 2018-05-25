unit RSMessages;

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
  SysUtils, Classes, Controls, Buttons, Graphics, Messages, Forms, Windows;


type
  TRSWMNoParams = packed record
    Msg: Cardinal;
    UnusedW: Longint;
    UnusedL: Longint;
    Result: Longint;
  end;

  TCMMouseLeave = packed record
    Msg: Cardinal;
    Unused: Longint;
    Sender: TControl;
    Result: Longint;
  end;

  TCMMouseEnter = TCMMouseLeave;

  TCMParentFontChanged = packed record
    Msg: Cardinal;
    FontIncluded: Longbool;
    Font: TFont;
    Result: Longint;
  end;

  TCMParentColorChanged = packed record
    Msg: Cardinal;
    ColorIncluded: Longbool;
    Color: TColor;
    Result: Longint;
  end;

  TCMVisibleChanged = packed record
    Msg: Cardinal;
    Visible: Longbool;
    Unused: Longint;
    Result: Longint;
  end;

  TCMParentCtl3DChanged = packed record
    Msg: Cardinal;
    Ctl3DIncluded: Longbool;
    Ctl3D: Longbool;
    Result: Longint;
  end;

  TCMAppSysCommand = packed record
    Msg: Cardinal;
    Unused: Longint;
    Message: PMessage;
    Result: Longint;
  end;

  TCMButtonPressed = packed record
    Msg: Cardinal;
    GroupIndex: Longint;
    Sender: TSpeedButton;
    Result: Longint;
  end;

  TCMInvokeHelp = packed record
    Msg: Cardinal;
    Command: Longint;
    Data: Longint;
    Result: Longint;
  end;

  TCMWindowHook = packed record
    Msg: Cardinal;
    UnHook: Longbool;
    WindowHook: ^TWindowHook;
    Result: Longint;
  end;

  TCMDocWindowActivate = packed record
    Msg: Cardinal;
    Active: Longbool;
    Unused: Longint;
    Result: Longint;
  end;

  TCMDialogHandle = packed record
    Msg: Cardinal;
    Get: LongBool; // 1 - Get, otherwise Set
    Handle: HWnd;
    Result: Longint;
  end;

  TCMInvalidate = packed record
    Msg: Cardinal;
    Notification: Longbool;
    Unused: Longint;
    Result: Longint;
  end;

  TCMBiDiModeChanged = packed record
    Msg: Cardinal;
    NoMiddleEastRecreate: Longbool;
    Unused: Longint;
    Result: Longint;
  end;

  TCMActionUpdate = packed record
    Msg: Cardinal;
    Unused: Longint;
    Action: TBasicAction;
    Result: Longint;
  end;

  TCMActionExecute = TCMActionUpdate;

  TCMAppKeyDown = TWMKey;
  TCMWinIniChange = TWMWinIniChange;
  TCMIsShortCut = TWMKey;

  TCMEnabledChanged = TRSWMNoParams;
  TCMColorChanged = TRSWMNoParams;
  TCMFontChanged = TRSWMNoParams;
  TCMCursorChanged = TRSWMNoParams;
  TCMCtl3DChanged = TRSWMNoParams;
  TCMTextChanged = TRSWMNoParams;
  TCMMenuChanged = TRSWMNoParams;
  TCMShowingChanged = TRSWMNoParams;
  TCMIconChanged = TRSWMNoParams;
  TCMRelease = TRSWMNoParams;
  TCMShowHintChanged = TRSWMNoParams;
  TCMParentShowHintChanged = TRSWMNoParams;
  TCMSysColorChange = TRSWMNoParams;
  TCMFontChange = TRSWMNoParams;
  TCMTimeChange = TRSWMNoParams;
  TCMTabStopChanged = TRSWMNoParams;
  TCMUIActivate = TRSWMNoParams;
  TCMUIDeactivate = TRSWMNoParams;
  TCMGetDataLink = TRSWMNoParams;
  TCMIsToolControl = TRSWMNoParams;
  TCMRecreateWnd = TRSWMNoParams;
  TCMSysFontChanged = TRSWMNoParams;
  TCMBorderChanged = TRSWMNoParams;
  TCMParentBiDiModeChanged = TRSWMNoParams;
  TCMAllChildrenFlipped = TRSWMNoParams;

// CN messages are equal to WM analogs

implementation

end.
 