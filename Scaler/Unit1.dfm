object Form1: TForm1
  Left = 0
  Top = 0
  AutoSize = True
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  BorderWidth = 12
  Caption = 'Scaler for MMF Games'
  ClientHeight = 226
  ClientWidth = 225
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 0
    Top = 0
    Width = 225
    Height = 57
    AutoSize = False
    Caption = 
      'Run the game then press specified hot key in it to go full scree' +
      'n'
    WordWrap = True
  end
  object Label2: TLabel
    Left = 0
    Top = 162
    Width = 43
    Height = 16
    Caption = 'Hot Key'
  end
  object CheckBlackBack: TCheckBox
    Left = 0
    Top = 63
    Width = 225
    Height = 17
    Caption = 'Black Border'
    Checked = True
    State = cbChecked
    TabOrder = 0
    OnClick = CheckBlackBackClick
  end
  object CheckScaling: TCheckBox
    Left = 0
    Top = 86
    Width = 225
    Height = 17
    Caption = 'Non-integer Scaling'
    TabOrder = 1
    OnClick = CheckBlackBackClick
  end
  object HotKey1: THotKey
    Left = 56
    Top = 159
    Width = 169
    Height = 27
    HotKey = 49165
    Modifiers = [hkCtrl, hkAlt]
    TabOrder = 5
    OnChange = HotKey1Change
  end
  object ButtonControls: TButton
    Left = 8
    Top = 194
    Width = 209
    Height = 32
    Caption = 'Configure Controls'
    TabOrder = 6
    OnClick = ButtonControlsClick
  end
  object CheckOnlyControls: TCheckBox
    Left = 0
    Top = 132
    Width = 225
    Height = 17
    Caption = 'Only modify controls'
    TabOrder = 4
    OnClick = CheckBlackBackClick
  end
  object CheckWindowed: TCheckBox
    Left = 0
    Top = 109
    Width = 113
    Height = 17
    Caption = 'Windowed'
    TabOrder = 2
    OnClick = CheckBlackBackClick
  end
  object CheckMax: TCheckBox
    Left = 112
    Top = 109
    Width = 113
    Height = 17
    Caption = 'Maximized'
    TabOrder = 3
    OnClick = CheckBlackBackClick
  end
  object RSWinController1: TRSWinController
    OnWndProc = RSWinController1WndProc
    Control = HotKey1
    Priority = 200
    Left = 168
    Top = 31
  end
  object TrayIcon1: TTrayIcon
    Hint = 'Scaler for MMF Games'
    Visible = True
    OnClick = TrayIcon1Click
    Left = 168
    Top = 64
  end
end
