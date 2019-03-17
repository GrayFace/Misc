unit RSMenus;

{ *********************************************************************** }
{                                                                         }
{ RSPak                                    Copyright (c) Rozhenko Sergey  }
{ http://sites.google.com/site/sergroj/                                   }
{ sergroj@mail.ru                                                         }
{                                                                         }
{ See copyright notice at the end of RSSysUtils.pas file (MIT license).   }
{                                                                         }
{ *********************************************************************** )

 Usage:  RSMenu.Add(MainMenu1);  RSMenu.Add(PopupMenu1);

 Special thanks to Alexey Rumiantsev. This unit was based on RyMenus.

{ *********************************************************************** }
{$I RSPak.inc}

interface

uses Windows, SysUtils, Classes, Messages, Graphics, ImgList, Menus, Forms,
  RSGraphics, RSPainters, RSQ, RSCommon, UxTheme, RSImgList;

type
  TRSMenuGetTextEvent = procedure(Item: TMenuItem; var Result:string) of Object;
  TRSMenuGetFontColorEvent =
    procedure(var c:TColor; Item: TMenuItem; State:TOwnerDrawState) of Object;

  TRSMenu = class(TObject)
  private
    FAroundImages: int;
    FAroundText: int;
    FMinHeight: int;
    FFont: TFont;
    FSeparatorsHints: Boolean;
    FOnGetText: TRSMenuGetTextEvent;
    FGetShortCut: TRSMenuGetTextEvent;
    FOnGetFontColor: TRSMenuGetFontColorEvent;
    procedure SetFont(const Value: TFont);
    function GetColors:TRSColorTheme;
    procedure SetColors(v: TRSColorTheme);
  protected
    FLastSel: TMenuItem;
    FCurrSel: TMenuItem;
    FColors: TRSColorTheme;
    procedure CheckColors;
    function GetHeight(IL:TCustomImageList; ACanvas:TCanvas):integer;
    function GetGutter(IL:TCustomImageList; Height:integer):integer;
    function GetWidth(Text:string; Item:TMenuItem; ACanvas: TCanvas; Height:integer):integer;
    function GetText(Item:TMenuItem):string;
    function GetShortCut(Item:TMenuItem):string;
    procedure MeasureItem(Sender: TObject; ACanvas: TCanvas;
                var Width, Height: Integer);
    procedure DrawTopSelected(ACanvas:TCanvas; ARect:TRect;
                AFlat, AShadow, AEmpty:boolean); virtual;
    procedure AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;
                ARect: TRect; State: TOwnerDrawState); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Item: TMenuItem; IncludeSelf:boolean=false; IncludeChildren:boolean=true); overload;
    procedure Add(Menu: TMenu); overload;
    procedure MakeBreaks(Item:TMenuItem; RemoveOldBreaks:boolean=true); overload;
    procedure MakeBreaks(Menu:TMenu; RemoveOldBreaks:boolean=true); overload;

    property ColorTheme: TRSColorTheme read GetColors write SetColors;

    property Font: TFont read FFont write SetFont;
    property MinHeight: int read FMinHeight write FMinHeight;
    property SeparatorsHints:Boolean read FSeparatorsHints write FSeparatorsHints;
    property SpaceAroundImages: int read FAroundImages write FAroundImages;
    property SpaceAroundText: int read FAroundText write FAroundText;
    property OnGetText: TRSMenuGetTextEvent read FOnGetText write FOnGetText;
    property OnGetShortCut: TRSMenuGetTextEvent read FGetShortCut write FGetShortCut;
    property OnGetFontColor: TRSMenuGetFontColorEvent read FOnGetFontColor write FOnGetFontColor;
    property OnPrepareFont: TRSMenuGetFontColorEvent read FOnGetFontColor write FOnGetFontColor;
  end;

var RSMenu:TRSMenu;

{ TODO : Поддержка TMenuItem.Bitmap }

implementation

{$R RSMenus.res}

const
  ShWidth = 4;
  ShHeight = 5;
  ShTop = 3;
  TopImgSpace = 5;
  SpaceAfterGutter = 6;
  TopSpace = 16;
  ArrowWidth = 18;
  LineLSpace = SpaceAfterGutter-1;
  LineTextSpace = 3;
  LineRSpace = 0;
  GutterAdd = 2;
  SepWidth = 5;
  SepHeight = 5;
  CheckSize = 15;

var
  BmpCheck: array[Boolean] of TBitmap;
  ShBmp: TBitmap=nil;
  MenuBarColor: TColor;

procedure MakeShadow;
// Редко нужно, поэтому почти без оптимизации
const
  ShW = ShWidth;
  ShH = ShHeight;
  Width = ShWidth;
  Height = ShHeight;// + ShY - 1;
  ShArr : array[0..ShH-1, 0..ShW-1] of byte =
          (
            (242, 246, 250, 253),
            (217, 227, 241, 250),
            (180, 199, 227, 245),
            (155, 180, 217, 242),
            (144, 172, 213, 241)
          );
var
  X, Y: Integer;
  RGBArray: PIntegerArray;
  Bmp: TBitmap;
begin
  ShBmp.Width:=Width;
  ShBmp.Height:=Height;
  Bmp := TBitmap.Create;
  Bmp.HandleType := bmDIB;
  Bmp.PixelFormat := pf32bit;
  Bmp.Width:=Width;
  Bmp.Height:=Height;
  with Bmp.Canvas do
  begin
    Brush.Color:=MenuBarColor;
    FillRect(ClipRect);
  end;
  try
    //i:=0;
    for Y := 0 to ShH-1 do
    begin
      RGBArray  := Bmp.Scanline[Y];
      for X := 0 to Width - 1 do
      begin
        RGBArray[X]:=RSAdjustIntensity(RGBArray[X], ShArr[Y,x]-255);
      end;
      //if i < ShH-1 then inc(i);
    end;
    with ShBmp.Canvas do CopyRect(ClipRect, Bmp.Canvas, ClipRect);
  finally
    Bmp.Free;
  end;
end;

(*
procedure DrawMonoBmp(ACanvas:TCanvas; AImgList: TCustomImageList;
  ImageIndex: Word; AColor: TColor; ALeft, ATop: Integer; UseMask:boolean);
const
  ILD : array[boolean] of DWord = (ILD_NORMAL, ILD_MASK);
var Bmp:TBitmap;
begin
  Bmp := TBitmap.Create;
  with Bmp do
    try
      Monochrome := True;
      Width := AImgList.Width;
      Height := AImgList.Height;
      BitBlt(Canvas.Handle, 0, 0, Width, Height, 0, 0, 0, WHITENESS);
      ImageList_DrawEx(AImgList.Handle, ImageIndex,
        Canvas.Handle, 0, 0, 0, 0, CLR_DEFAULT, 0, ILD[UseMask]);
      RSDrawMonoBmp(ACanvas, Bmp, AColor, ALeft, ATop);
    finally
      Free;
    end;
end;

procedure DrawBlendBmp(ACanvas:TCanvas; AImgList: TCustomImageList;
  ImageIndex: Word; ALeft, ATop: Integer; ABlendColor: TColor;
  Percent1:integer; Percent2:integer=-1);
var Bmp:TBitmap;
begin
  if Percent2<0 then Percent2:=256-Percent1;
  Bmp := TBitmap.Create;
  try
    with Bmp, Canvas do
    begin
      Brush.Color:=ABlendColor;
      FillRect(ClipRect);
      PixelFormat := pf32bit;
      Width := AImgList.Width;
      Height := AImgList.Height;
//      AImgList.Draw(Canvas,0,0,ImageIndex);
      ImageList_DrawEx(AImgList.Handle, ImageIndex,
        Canvas.Handle, 0, 0, 0, 0, CLR_DEFAULT, CLR_DEFAULT, ILD_TRANSPARENT);
    end;
    Bmp.TransparentColor := ABlendColor;
    Bmp.TransparentMode := tmFixed;
    Bmp.Transparent := true;
    RSMixPicColor32(Bmp, Bmp, ABlendColor, Percent1, Percent2);
    with ACanvas do
      Draw(ALeft, ATop, Bmp);
  finally
    Bmp.Free;
  end;
end;
*)

constructor TRSMenu.Create;
begin
  FColors:= RSColorTheme;
  FFont:= TFont.Create;
  FFont.Assign(Screen.MenuFont);
  FCurrSel:= nil;
  FLastSel:= nil;
  FAroundImages:= 3;
  FAroundText:= 1;
  FMinHeight:= 20;
end;

destructor TRSMenu.Destroy;
begin
  FFont.Free;
  inherited;
end;

function TRSMenu.GetColors:TRSColorTheme;
begin
  Result:=FColors;
  if Result=RSColorTheme then
    Result:=nil;
end;

procedure TRSMenu.SetColors(v: TRSColorTheme);
begin
  if v=nil then
    FColors:=RSColorTheme
  else
    FColors:=v;
end;

procedure TRSMenu.Add(Item:TMenuItem; IncludeSelf:boolean=false;
    IncludeChildren:boolean=true);

  procedure InitItem(Item:TMenuItem);
  begin
    Item.OnAdvancedDrawItem:=AdvancedDrawItem;
    Item.OnMeasureItem:=MeasureItem;
  end;

  procedure InitItems(Item:TMenuItem);
  var i:int;
  begin
    for i:=0 to Item.Count-1 do
    begin
      InitItem(Item[i]);
      if Item[i].Count>0 then InitItems(Item[i]);
    end;
  end;

  procedure UnBug(Item:TMenuItem);
  var aa:TMenuItem;
  begin
    aa:=TMenuItem.Create(nil);
    try
      aa.Caption:='Antibug'; // Чтобы побороть глюк с прорисовкой
      Item.Add(aa);
      Item.Delete(Item.Count-1);
    finally
      aa.Free;
    end;
  end;

begin
  if Item=nil then exit;
  if IncludeChildren then InitItems(Item);
  Item.GetParentMenu.OwnerDraw:=true;
  if IncludeSelf then
  begin
    InitItem(Item);
    if Item.Parent <> nil then
      Item:= Item.Parent;
  end;
  if Item.Parent=nil then
    UnBug(Item);
end;

procedure TRSMenu.Add(Menu: TMenu);
begin
  if Menu=nil then exit;
  Add(Menu.Items);
end;

function TRSMenu.GetHeight(IL:TCustomImageList; ACanvas:TCanvas):integer;
var i:integer;
begin
  Result := ACanvas.TextHeight('W') + FAroundText*2;
  if (IL<>nil) then
  begin
    i:=IL.Height + FAroundImages*2;
    if Result<i then Result := i;
  end;
  if Result<FMinHeight then Result:=FMinHeight;
end;

function TRSMenu.GetGutter(IL:TCustomImageList; Height:integer):integer;
var i:integer;
begin
  Result := Height + GutterAdd;
  if IL<>nil then
  begin
    i := IL.Width + FAroundImages*2;
    if Result<i then Result := i;
  end;
end;

function TRSMenu.GetWidth(Text:string; Item:TMenuItem; ACanvas: TCanvas;
   Height:integer):integer;
const
  AutoAdd = 12; // добавляется автоматически
var
  IL: TCustomImageList; Top:boolean; SC:string;
begin
  with Item do
  begin
    IL:= GetImageList;
    Top:= GetParentComponent is TMainMenu;
    Text:= StripHotkey(Text);
    if Top then
      if IsLine then
        if (IL<>nil) and (ImageIndex>=0) then
          Result := IL.Width + TopSpace
        else
          Result := SepWidth
      else
      begin
        Result := ACanvas.TextWidth(Text) + TopSpace;
        if (IL<>nil) and (ImageIndex>=0) then
          Result := Result + IL.Width + TopImgSpace;
      end
    else
    begin
      if IsLine then
        Result:= ACanvas.TextWidth(Text) + LineLSpace + LineTextSpace
      else
      begin
        SC:=GetShortCut(Item);

        if SC='' then
          Result:= ArrowWidth + SpaceAfterGutter + ACanvas.TextWidth(Text)
        else
          Result:= ArrowWidth*2 + SpaceAfterGutter + ACanvas.TextWidth(Text+SC);
      end;

      inc(Result, GetGutter(IL, Height));
    end;
  end;
  dec(Result, AutoAdd);
end;

function TRSMenu.GetText(Item:TMenuItem):string;
begin
  Result:= Item.Caption;
  if SeparatorsHints and Item.IsLine and (Item.Hint<>'') then
    Result:= Item.Hint;
  if Assigned(OnGetText) then OnGetText(Item, Result);
end;

function TRSMenu.GetShortCut(Item:TMenuItem):string;
begin
  Result:= ShortCutToText(Item.ShortCut);
  if Assigned(OnGetShortCut) then OnGetShortCut(Item, Result);
end;

procedure TRSMenu.MeasureItem(Sender: TObject; ACanvas: TCanvas;
            var Width, Height: Integer);
var
  TopLevel:boolean; Text:string;
begin
  with Sender as TMenuItem do
  begin
    Text:=GetText(ptr(Sender));
    TopLevel := GetParentComponent is TMainMenu;
    ACanvas.Font := FFont;
    if Default then
      ACanvas.Font.Style:= ACanvas.Font.Style + [fsBold];
    if not TopLevel then Height := GetHeight(GetImageList, ACanvas);
    Width := GetWidth(Text, ptr(Sender), ACanvas, Height);
    if not TopLevel and IsLine then
      if Text<>'-' then
        Height := ACanvas.TextHeight(Text) + FAroundText*2
      else
        Height := SepHeight;
  end;
end;

procedure TRSMenu.MakeBreaks(Item:TMenuItem; RemoveOldBreaks:boolean=true);
var i,j,k,dy,h,count:integer; b:TBitmap; Line, NoBr:boolean; LineRed:boolean;
begin
  if Item.Count=0 then exit;
  h:=Screen.Height-6;
  j:=0;
  NoBr:=(Item.Parent=nil) and (Item.GetParentMenu is TMainMenu);
  LineRed := (Item.AutoLineReduction = maAutomatic) or
             (Item.AutoLineReduction = maParent) and
             (Item.GetParentMenu.AutoLineReduction = maAutomatic);
  count:=Item.Count;
  i:=0;
  if LineRed then
    while (i<count) and Item[i].IsLine do inc(i);

  if i=count then exit;

  b:=TBitmap.Create;
  try
    b.Canvas.Font:=FFont;
    dy := GetHeight(Item[i].GetImageList, b.Canvas);
    NoBr := NoBr or (dy*(count-i)<=h); // Оптимизация

    Line:=false;
    for i:=i to count-1 do
      with Item[i] do
      begin
        MakeBreaks(Item[i]);
        if NoBr then k:=0
        else
          if IsLine then
            if Line then k:=0
            else k:=SepHeight
          else k:=dy;
        j:=j+k;
        if j>h then
        begin
          Break:=mbBreak;
          j:=k;
        end else
          if RemoveOldBreaks then Break:=mbNone;
        Line:=LineRed and IsLine;
      end;
  finally
    b.Free;
  end;
end;

procedure TRSMenu.MakeBreaks(Menu:TMenu; RemoveOldBreaks:boolean=true);
begin
  MakeBreaks(Menu.Items,RemoveOldBreaks);
end;

procedure TRSMenu.DrawTopSelected(ACanvas:TCanvas; ARect:TRect;
            AFlat, AShadow, AEmpty:boolean);
var bs:TBrushStyle;
begin
  with ACanvas do
  begin
    AFlat := AFlat and not AEmpty;
    Pen.Color := clBtnShadow;
    bs := Brush.Style;
    Brush.Style := bsClear;
    Rectangle(ARect);
    Brush.Style := bs;
    if AFlat then inc(ARect.Bottom);
    RSGradientV(ACanvas, DecRect(ARect), FColors.Light, FColors.Gutter);
  end;
end;

procedure TRSMenu.AdvancedDrawItem(Sender: TObject; ACanvas: TCanvas;
            ARect: TRect; State: TOwnerDrawState);
const
  //текстовые флаги
  Flags: LongInt = DT_NOCLIP or DT_VCENTER or DT_END_ELLIPSIS or DT_SINGLELINE;
  FlagsTopLevel: array[Boolean] of Longint = (DT_LEFT, DT_CENTER);
  FlagsShortCut: Longint = DT_RIGHT;
  RectEl: array[Boolean] of Byte = (1, 6); //закругленный прямоугольник
  CheckEl: array[Boolean] of Byte = (0, 100); //при отсутствии картинки
  CheckEdge: array[Boolean] of Byte = (1, 2);
var
  TopLevel: Boolean;
  Gutter: Word;
  ImageList: TCustomImageList;
  i, j: integer;
  SysFlat, SysShadow: bool;
  Bmp: TBitmap;
  ImgLeft: int;
  Text: string;
begin
  CheckColors;

  with Sender as TMenuItem, ACanvas do
  begin
    TopLevel := GetParentComponent is TMainMenu;
    ImageList := GetImageList;

     // Для стирания тени.

    if TopLevel and CheckWin32Version(5,1) and
      (State*[odSelected, odHotLight]<>[]) then
    begin
      FLastSel := FCurrSel;
      if odSelected in State then
        FCurrSel := TMenuItem(Sender)
      else
        FCurrSel := nil;
    end;

     // Рассчеты

    if not TopLevel then
      Gutter := GetGutter(ImageList, GetHeight(ImageList, ACanvas))
    else
      if Assigned(ImageList) and (ImageIndex>=0) then
        Gutter:=ImageList.Width + TopSpace div 2 + TopImgSpace
      else Gutter:=0;

    if Assigned(ImageList) and not TopLevel then
      ImgLeft:=(Gutter-ImageList.Width) div 2
    else
      ImgLeft:=TopSpace div 2;

     // System Parameters

    if CheckWin32Version(5,1) then
    begin
      if not SystemParametersInfo(SPI_GETDROPSHADOW, 0, @SysShadow, 0) then
        SysShadow:=false;
      if not SystemParametersInfo(SPI_GETFLATMENU, 0, @SysFlat, 0) then
        SysFlat:=false;
    end else
    begin
      SysShadow:=false;
      SysFlat:=false;
    end;

     // Тень

    if TopLevel then
      if State * [odSelected, odDisabled] = [odSelected] then
      begin
        if SysShadow and (Count>0) then
        begin
          BitBlt(ACanvas.Handle, ARect.Right, ARect.Top + ShTop,
                 ShWidth, ShHeight, ShBmp.Canvas.Handle, 0, 0, SRCCOPY);
          ACanvas.CopyRect(
            Rect(ARect.Right, ARect.Top + ShTop + ShHeight,
                  ARect.Right + ShWidth, ARect.Bottom),
            ShBmp.Canvas,
            Rect(0, ShHeight - 1, ShWidth, ShHeight));
        end else
          FCurrSel:=nil;
      end else
         // Стираем тень
         // К счастью, между крайним справа пунктом меню и рамкой окна
         // всегда есть зазор.
        if (FCurrSel=Sender) or (FLastSel=Sender) and (FCurrSel<>nil) and
           (FCurrSel.MenuIndex<>FLastSel.MenuIndex+1) then
        begin
          Brush.Color:=MenuBarColor;
          FillRect(Rect(ARect.Right,ARect.Top,ARect.Right+ShWidth,ARect.Bottom));
        end;

     // Фон (выделение, полоса слева, ...)

    if TopLevel then
      if State * [odSelected, odDisabled] = [odSelected] then
        DrawTopSelected(ACanvas, ARect, SysFlat, SysShadow, Count=0)
      else
        if State * [odSelected, odDisabled] = [odSelected, odDisabled] then
        begin
          Pen.Color:=FColors.Disabled;
          Brush.Color := MenuBarColor;
          Rectangle(ARect);
        end else
          if not (odHotLight in State) then
          begin
            Brush.Color := MenuBarColor;
            FillRect(ARect);
          end else
            FColors.DrawHotTrackBackground(ACanvas, ARect)

    else  // not TopLevel
      if State * [odSelected, odDisabled] <> [odSelected] then
      begin
        Brush.Color := FColors.Menu;
        FillRect(Rect(ARect.Left+Gutter, ARect.Top, ARect.Right, ARect.Bottom));
         // Gutter
        Brush.Color := FColors.Gutter;
        FillRect(Rect(ARect.Left, ARect.Top, ARect.Left+Gutter, ARect.Bottom));
        if State * [odSelected, odDisabled] = [odSelected, odDisabled] then
        begin
          Brush.Color := FColors.Disabled;
          FrameRect(ARect);
        end;
      end else
        FColors.DrawHotTrackBackground(ACanvas, ARect);

    Brush.Style:=bsSolid;

     // Checked, Radio

    if Checked and not TopLevel then
      if Assigned(ImageList) and (ImageIndex > -1) then
      begin
        with ARect do
          FColors.DrawCheck(ACanvas,
            Rect(Left+1, Top+1, Left+Gutter-1, Bottom-1),
            not (odDisabled in State), RectEl[RadioItem]);
      end else
      begin
        Bmp:=BmpCheck[RadioItem];

        i:=ARect.Left+(Gutter-CheckSize) div 2;
        j:=(ARect.Top+ARect.Bottom-CheckSize) div 2;
        FColors.DrawCheck(ACanvas, Rect(i, j, i+CheckSize, j+CheckSize),
          not (odDisabled in State), CheckEl[RadioItem],
          CheckEdge[RadioItem]);

        if RadioItem then
          with ACanvas do
          begin
            Pixels[i+2, j+1]:=FColors.Gutter;
            Pixels[i+2, j+CheckSize-2]:=FColors.Gutter;
            Pixels[i+CheckSize-3, j+1]:=FColors.Gutter;
            Pixels[i+CheckSize-3, j+CheckSize-2]:=FColors.Gutter;
          end;

        if Enabled then
          Draw( i + (CheckSize - Bmp.Width) div 2,
                j + (CheckSize - Bmp.Height) div 2, Bmp)
        else
          RSDrawMask(ACanvas, Bmp, FColors.Disabled,
                     i + (CheckSize - Bmp.Width) div 2,
                     j + (CheckSize - Bmp.Height) div 2);
      end;

     // Picture

    Bmp:=nil;
    if Assigned(ImageList) and (ImageIndex>=0) then
    try
      Bmp:=RSImgListToBmp(ImageList, ImageIndex);
      if Checked and not (odDisabled in State) then
        ACanvas.Draw(ARect.Left + ImgLeft,
                     (ARect.Top + ARect.Bottom - ImageList.Height) div 2, Bmp)
      else
        FColors.DrawGlyph(ACanvas, ARect.Left + ImgLeft,
           (ARect.Top + ARect.Bottom - ImageList.Height) div 2,
           Bmp, State, FColors.Gutter, true);
    finally
      Bmp.Free;
    end;

     // Text etc.

    Text:= GetText(ptr(Sender));

    Font := FFont;
    i:=Font.Color;
    if (odDisabled in State) then  i:= FColors.Disabled;
    if (odDefault in State) then  Font.Style:= [fsBold];
    if Assigned(OnGetFontColor) then
      OnGetFontColor(TColor(i), ptr(Sender), State);
    Font.Color:=i;

    Inc(ARect.Left, Gutter); //отступ для текста
    Brush.Style := bsClear;
    if IsLine then
    begin
      Pen.Color := FColors.Disabled;
      if TopLevel then
      begin
        //MoveTo((ARect.Left + ARect.Right) div 2, ARect.Top + 4);
        //LineTo((ARect.Left + ARect.Right) div 2, ARect.Bottom - 3);
      end else
        if Text<>'-' then
        begin
          i:=TextWidth(Text);
          MoveTo(ARect.Left + LineLSpace, (ARect.Bottom + ARect.Top) div 2);
          if ARect.Left + LineLSpace <= ARect.Right - LineTextSpace*2 - i then
            LineTo(ARect.Right - LineTextSpace*2 - i + 1,
               (ARect.Bottom + ARect.Top) div 2);
          TextOut(ARect.Right - LineTextSpace - i + 1, ARect.Top + FAroundText,
             Text);
        end else
        begin
          MoveTo(ARect.Left + LineLSpace, (ARect.Bottom + ARect.Top) div 2);
          LineTo(ARect.Right - LineRSpace + 1, (ARect.Bottom + ARect.Top) div 2);
        end;
    end else
    begin
      if not TopLevel then Inc(ARect.Left, SpaceAfterGutter);
      Windows.DrawText(Handle, PChar(Text), Length(Text), ARect,
        Flags or FlagsTopLevel[TopLevel and (Gutter=0)]);
         // Gutter<>0 if picture presents
         
      Text:=GetShortCut(ptr(Sender));

      if (Text <> '') and not TopLevel then
      begin
        Dec(ARect.Right, ArrowWidth);
        DrawText(Handle, ptr(Text), length(Text), ARect, Flags or FlagsShortCut);
      end;
    end;
  end;
end;

procedure TRSMenu.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

procedure TRSMenu.CheckColors;
var i:integer;
begin
  FColors.CheckColors;
  if (@IsAppThemed<>nil) and IsAppThemed or
      CheckWin32Version(5,1) and (GetSysParamsInfo(SPI_GETFLATMENU)<>0) then
    i:=ColorToRGB(clMenuBar)
  else
    i:=ColorToRGB(clBtnFace);

  if i<>MenuBarColor then
  begin
    MenuBarColor:=i;
    MakeShadow;
  end;
end;

function InitBmp(var Bmp:TBitmap; Name:string; Transparent:boolean=true):boolean;
var h:HBITMAP;
begin
  if Bmp=nil then Bmp:=TBitmap.Create;
  h:=LoadBitmap(HInstance, PChar(Name));
  Bmp.Handle:=h;
  Bmp.HandleType:=bmDIB;
  Bmp.Transparent:=Transparent;
  Result:=h<>0;
end;

initialization
  InitBmp(BmpCheck[false], 'RSMENUSCHECK');
  if not InitBmp(BmpCheck[true], 'RSMENUSRADIO') then
    InitBmp(BmpCheck[true], 'RSMENUSCHECK');

  MenuBarColor:=clDefault; // Чтобы не совпал ни с чем
  ShBmp:=TBitmap.Create;
  ShBmp.HandleType:=bmDDB;
  //MakeShadow;

  RSMenu:=TRSMenu.Create;

finalization
  BmpCheck[true].Free;
  BmpCheck[false].Free;

  ShBmp.Free;
  RSMenu.Free;
end.
