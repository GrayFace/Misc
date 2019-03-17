object Form1: TForm1
  Left = 192
  Top = 114
  BorderStyle = bsDialog
  Caption = 'RSPak Debug Demo'
  ClientHeight = 593
  ClientWidth = 747
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 17
  object RSPanel1: TRSPanel
    Left = 0
    Top = 551
    Width = 747
    Height = 42
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object Button1: TButton
      Left = 6
      Top = 6
      Width = 143
      Height = 31
      Caption = 'Delphi Exception'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 158
      Top = 6
      Width = 148
      Height = 31
      Caption = 'Access Violation'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 315
      Top = 6
      Width = 149
      Height = 31
      Caption = 'Exceptions Chain'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 473
      Top = 6
      Width = 149
      Height = 31
      Caption = 'Corrupt Exception'
      TabOrder = 3
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 630
      Top = 6
      Width = 110
      Height = 31
      Caption = 'Information'
      TabOrder = 4
      OnClick = Button5Click
    end
  end
  object Memo1: TRSMemo
    Left = 0
    Top = 0
    Width = 747
    Height = 551
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Tahoma'
    Font.Style = []
    Lines.Strings = (
      
        'The report starts with the date and time. The normal time is out' +
        'put using user'#39's regional settings than the UTC output using Rus' +
        'sian default settings.'
      ''
      'Function Calls:'
      ''
      
        'You can see that there are "|" and "?" as separators. "?" means ' +
        'that the function is guessed from a value in stack that looks li' +
        'ke an address to code and it may be a wrong guess. "|" means tha' +
        't there is a stack frame before which the address was pushed. Th' +
        'is was is more reliable.'
      
        'Using the Search -> Find Error menu item in Delphi you can easil' +
        'y go to the line of code at a reported address.'
      
        'However this requires the same units as those you used to compil' +
        'e the program. So you may want to use a MAP file or some other k' +
        'ind of debug information. To do so assign your own handler to RS' +
        'DebugOptions.OnAddressDetails. For example, you can find MAP fil' +
        'e parser in JEDI packege.'
      ''
      'Stack Trace:'
      ''
      
        '"|" and "?" separators have the same meaning, but here may be so' +
        'me special comments:'
      
        '"Last EBP" indecates a stack frame. It stores the EBP register b' +
        'efore the stack frame creation and next to it there'#39's a return a' +
        'ddress. (stack frames are created at the beginning of functions ' +
        'that store some data in the stack)'
      
        '"TExcFrame.next" means that there was try..finally or try..excep' +
        't and next to it there goes the address of "except" or "finally"' +
        ' block. Then there may go "TExcFrame.EBP" which is the EBP regis' +
        'ter at the moment of entering the "try" statement. The "TExcFram' +
        'e.EBP" comment is added only if the "try" block is within the pr' +
        'ogram code.')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
  end
  object ApplicationEvents1: TApplicationEvents
    OnException = ApplicationEvents1Exception
    Left = 8
    Top = 8
  end
end
