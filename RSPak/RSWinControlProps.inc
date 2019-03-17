  public
    property MouseInside: Boolean read FProps.MouseIn;
    property State: TRSControlState read FProps.State;
  published
    property OnCreateParams: TRSCreateParamsEvent read FOnCreateParams write FOnCreateParams;
{$IFNDEF D2006}
    property OnMouseEnter: TNotifyEvent read FProps.OnMouseEnter write FProps.OnMouseEnter;
    property OnMouseLeave: TNotifyEvent read FProps.OnMouseLeave write FProps.OnMouseLeave;
{$ELSE}
    property OnMouseEnter;
    property OnMouseLeave;
{$ENDIF}
    property OnWndProc: TRSWndProcEvent read FProps.OnWndProc write FProps.OnWndProc;

