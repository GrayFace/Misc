object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Scaler Controls'
  ClientHeight = 551
  ClientWidth = 367
  Color = clBtnFace
  Constraints.MinHeight = 111
  Constraints.MinWidth = 292
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  DesignSize = (
    367
    551)
  PixelsPerInch = 120
  TextHeight = 17
  object Label1: TLabel
    Left = 10
    Top = 483
    Width = 288
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Note: Same old key can be used multiple times.'
  end
  object ListView1: TListView
    Left = 10
    Top = 10
    Width = 347
    Height = 465
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'New Key'
        Width = 136
      end
      item
        Caption = 'Old Key'
        Width = 133
      end>
    HideSelection = False
    OwnerDraw = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    OnChanging = ListView1Changing
    OnDrawItem = ListView1DrawItem
    OnExit = ListView1Exit
    OnKeyDown = ListView1KeyDown
    OnResize = ListView1Resize
  end
  object Button1: TButton
    Left = 179
    Top = 507
    Width = 85
    Height = 33
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 272
    Top = 507
    Width = 85
    Height = 33
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 10
    Top = 507
    Width = 103
    Height = 33
    Anchors = [akLeft, akBottom]
    Caption = 'Clear All'
    TabOrder = 3
    OnClick = Button3Click
  end
end
