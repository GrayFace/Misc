unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, RSDef, RSSysUtils, RSQ, XPMan,
  RSTimer, Menus, RSMenus, RSSpeedButton, Math, ImgList, RSPainters, RSPanel,
  Themes, RSQHelp1, RSLang, RSGraphics, RSUtils, RSStringer, RSRegistry,
  RSRecent, RSComboBox, RSFileAssociation, RSDebug, RSC, IniFiles,
  RSStrUtils;

{
v1.1:
[+] Просмотр папки как в HommConverter
[+] Extract All for DefTool
[+] Language can be changed on the fly
[-] Groups for hero in combat weren't specified

v1.2:
[+] Errors handling improved
[+] "Extract In 24 Bits" option
[-] Groups numbers were exported incorrectly
[*] Proper delays for adventure map defs

v1.2.1:
[-] Previous version was crashing on Windows XP

}

{ TODO :
Bug: No special colors if the shadow is embedded
Разделить экспорт с отдельной тенью и внутренней
Shadow colors of fog of war
Use Extract Path option
Экспорт Gif
MultiSelect }

const
  AppTitle='Def Preview';

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    TreeView1: TTreeView;
    RSTimer1: TRSTimer;
    Panel2: TRSPanel;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Open1: TMenuItem;
    SaveAs1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    Edit1: TMenuItem;
    ExportDefList1: TMenuItem;
    LoadGroupsNumbers1: TMenuItem;
    ExportPictures1: TMenuItem;
    Options1: TMenuItem;
    Stretch1: TMenuItem;
    Help1: TMenuItem;
    SaveDialog1: TSaveDialog;
    SaveDialog2: TSaveDialog;
    SaveDialog3: TSaveDialog;
    ImageList1: TImageList;
    StatusBar1: TStatusBar;
    PopupMenu1: TPopupMenu;
    N40Sprite1: TMenuItem;
    N41Spritedef1: TMenuItem;
    N42Creature1: TMenuItem;
    N43Advobj1: TMenuItem;
    N44Hero1: TMenuItem;
    N45Tileset1: TMenuItem;
    N46Pointer1: TMenuItem;
    N47Interface1: TMenuItem;
    N48SpriteFrame1: TMenuItem;
    N49CombatHero1: TMenuItem;
    Panel1: TRSPanel;
    Groups42: TRSStringer;
    Groups44: TRSStringer;
    Associate1: TMenuItem;
    N2: TMenuItem;
    Transparent1: TMenuItem;
    NoShadow1: TMenuItem;
    Groups49: TRSStringer;
    RSComboBox1: TRSComboBox;
    ImageList2: TImageList;
    ExtractAll1: TMenuItem;
    SaveDialog4: TSaveDialog;
    RSStringer1: TRSStringer;
    N3: TMenuItem;
    Language1: TMenuItem;
    English1: TMenuItem;
    Extractin24bits1: TMenuItem;
    procedure Extractin24bits1Click(Sender: TObject);
    procedure RSComboBox1WndProc(Sender: TObject; var Message: TMessage;
      var Handled: Boolean; const NextWndProc: TWndMethod);
    procedure English1Click(Sender: TObject);
    procedure ExtractAll1Click(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure RSTimer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Collapsing(Sender: TObject; Node: TTreeNode;
      var AllowCollapse: Boolean);
    procedure TreeView1Editing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure TreeView1Edited(Sender: TObject; Node: TTreeNode;
      var S: String);
    procedure Open1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject);
    procedure Stretch1Click(Sender: TObject);
    procedure ExportPictures1Click(Sender: TObject);
    procedure ExportDefList1Click(Sender: TObject);
    procedure LoadGroupsNumbers1Click(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure N40Sprite1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure Help1Click(Sender: TObject);
    procedure TreeView1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure StatusBar1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure TreeView1AdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
      var PaintImages, DefaultDraw: Boolean);
    procedure Associate1Click(Sender: TObject);
    procedure Options1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Transparent1Click(Sender: TObject);
    procedure NoShadow1Click(Sender: TObject);
    procedure RSComboBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure RSComboBox1Select(Sender: TObject);
    procedure Panel2Paint(Sender: TRSCustomControl; State: TRSControlState;
      DefaultPaint: TRSProcedure);
    procedure Panel2Resize(Sender: TObject);
    procedure TreeView1KeyPress(Sender: TObject; var Key: Char);
  private
    FWasChanged: Boolean;
    FExtractPath: string;
    procedure SetExtractPath(const v: string);
    function GetExtractPath: string;
  protected
    fileName: string;
    Picture: TBitmap;
    PicError: string;
    Extracting: Boolean;
    DefToolFilter: string;
    DefToolNoShadowFilter: string;
    ToolButtons: TRSControlArray;
    CurrentLanguage: string;

    procedure WMActivate(var Msg:TWMActivate); message WM_Activate;
    procedure WMHelp(var Msg:TMessage); message WM_Help;
    procedure CreateParams(var Params: TCreateParams); override;
  public
    procedure PreparePal(Sender: TRSDefWrapper; Pal:PLogPal);
    function GetDefAnimTime: int;
    procedure WasChanged(b:boolean=true);
    procedure Load(FillFiles:Boolean);
    procedure DoExtractDefList;
    procedure SetType(t:int; Groups:boolean);
    procedure MakeTypeImages;
    procedure MenuGetText(Item: TMenuItem; var Result:string);
    procedure MenuFontColor(var c:TColor; Item: TMenuItem; State:TOwnerDrawState);
    procedure RecentClick(Sender:TRSRecent; Name:string);
    procedure ReadIni;
    procedure WriteIni;
    procedure FillFilesList;
    procedure FillLanguage(LangDir: string; Default: string);
    procedure CalculateSizes;
    procedure MakeDefToolFilter;
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);

    property ExtractPath: string read GetExtractPath write SetExtractPath;
  end;

var
  Form1: TForm1;

implementation

uses Registry;

{$R *.dfm}

var
  SGroup:string = 'Group';
  SWrongCompression:string = 'Error: Type requires different compression';
  SUnusedType:string = 'Hint: Unused type';

type
  TCompr = set of 0..3;

const
  Compressions: array[$40..$49] of TCompr =
    ([0,1], [], [0,1], [0,2,3], [0,2,3], [0,2,3], [0,1], [0,1], [], [0,1]);

var
  PicCount:int; Error:string;
  Def:TRSDefWrapper; LastBmp:int;
  AnimFrame:int; AnimNode:TTreeNode;
  TypeLeft, TypeRight:int;
  Groups: array[$40..$49] of TStrings;
  Recent: TRSRecent;
  Association: TRSFileAssociation;

{
function DoShift(Num:integer; b:TBitmap):TBitmap;
var w,h,dy:int; p,p1:PChar; l,l1:Char;
begin
  if (ShBmps[Num]=nil) and (b<>nil) then
  begin
    Result:=TBitmap.Create;
    with Result do
    begin
      Assign(b);
      l1:=#0;
      w:=Width;
      h:=Height;
      if (w=0) or (h=0) then exit;
      p:=Result.ScanLine[0];
      if h>=2 then
        dy:=int(Result.ScanLine[1])-int(p)
      else
        dy:=1;
      p1:=p;
      inc(p1, dy*h);
      dec(w);
      repeat
        l:=(p+w)^;
        CopyMemory(p+1, p, w);
        p^:=l1;
        l1:=l;
        inc(p,dy);
      until p=p1;
    end;
  end else
    Result:=ShBmps[Num];
end;
}

function DoLoadBmp(i:integer; Bmp:TBitmap=nil):TBitmap; overload;
begin
  Error:='';
  LastBmp:=i;
  if PicCount=0 then
  begin
    Result:=nil;
    exit;
  end;
  try
    Result:=Def.ExtractBmp(i, Bmp, RSFullBmp);
  except
    on e:Exception do
    begin
      Result:=nil;
      Error:=e.Message;
    end;
  end;

{  if Form1.Shift1.Checked then
    Result:=DoShift(i, Result);}
end;

procedure LoadBmp(i:integer); overload;
begin
  if DoLoadBmp(i, Form1.Picture)=nil then
    Form1.Picture.Assign(nil);
  Form1.PicError:= Error;

  with Form1.StatusBar1, Def.GetPicHeader(i)^ do
    Panels[7].Text:=IntToStr(Compression);

  Form1.StatusBar1.Panels[9].Text:=IntToStr(i);

  InvalidateRect(Form1.Panel2.Handle, nil, false);
end;

procedure TForm1.PreparePal(Sender: TRSDefWrapper; Pal:PLogPal);
var MapDef: Boolean;
begin
  if Def.PicturesCount <> 0 then
    case Def.GetPicHeader(0)^.Compression of
      1: MapDef:= false;
      2,3: MapDef:= true;
      else
        exit;
    end
  else
    MapDef:= 1 in Compressions[Sender.Header.TypeOfDef];

  if not Extracting and Transparent1.Checked then
  begin
    int(Pal.palPalEntry[0]):=ColorToRGB(clBtnFace);
    int(Pal.palPalEntry[4]):=RSMixColors(clBtnFace, 0, 124);
    int(Pal.palPalEntry[1]):=RSMixColors(clBtnFace, 0, 182);
    if not MapDef then
    begin
      int(Pal.palPalEntry[5]):=clYellow;
      int(Pal.palPalEntry[6]):=RSMixColors(clYellow, 0, 170); //clYellow;
      int(Pal.palPalEntry[7]):=RSMixColors(clYellow, 0, 210);// clYellow;
    end;
  end;
  
  if NoShadow1.Checked then
  begin
    int(Pal.palPalEntry[4]):=int(Pal.palPalEntry[0]);
    int(Pal.palPalEntry[1]):=int(Pal.palPalEntry[0]);
    {
    int(Pal.palPalEntry[6]):=int(Pal.palPalEntry[5]);
    int(Pal.palPalEntry[7]):=int(Pal.palPalEntry[5]);
  end;
  if NoSelection1.Checked then
  begin
    }
    if not MapDef then
    begin
      int(Pal.palPalEntry[5]):=int(Pal.palPalEntry[0]);
      int(Pal.palPalEntry[6]):=int(Pal.palPalEntry[4]);
      int(Pal.palPalEntry[7]):=int(Pal.palPalEntry[1]);
    end;
  end;
end;

procedure ReStretch(Bmp:TBitmap; Stretch:boolean; var w,h:int);
var w1,h1:int;
begin
  w1:=Bmp.Width;
  h1:=Bmp.Height;
  if (w1=0) or (h1=0) then
  begin
    w:=0;
    h:=0;
    exit;
  end;
  if Stretch or (w1>w) or (h1>h) then
    if w1*h>w*h1 then
      h:=(w*h1 + w1 div 2) div w1
    else
      w:=(h*w1 + h1 div 2) div h1
  else
  begin
    w:=w1;
    h:=h1;
  end;
end;

function MakeGroupName(i:int):string;
const
  Space = '    ';
var t:int;
begin
  t:=Def.Header.TypeOfDef;
  if (t in [$40..$49]) and (Groups[t]<>nil) and (i<Groups[t].Count) then
    Result:= IntToStr(i) + Space + Groups[t][i]
  else
    Result:= IntToStr(i) + Space + SGroup;
end;

procedure TForm1.TreeView1Change(Sender: TObject; Node: TTreeNode);
var i:int;
begin
  if Def=nil then exit;
  RSTimer1.Interval:=0;
  i:=int(Node.Data);
  if (i<0) or (Node.Parent=nil) then
  begin
    AnimNode:=Node;
    AnimFrame:=0;
    RSTimer1.Interval:= GetDefAnimTime;
    RSTimer1.OnTimer(nil);
  end else
    LoadBmp(i);
end;

procedure TForm1.RSTimer1Timer(Sender: TObject);
var i:int;
begin
  if AnimNode.Parent=nil then
    i:=Def.PicturesCount
  else
    i:=Def.Groups[not int(AnimNode.Data)].ItemsCount;

  if i=0 then
  begin
    RSTimer1.Interval:=0;
    Picture.Assign(nil);
    PicError:='';
    Exit;
  end;

  if AnimNode.Parent=nil then
    LoadBmp(AnimFrame)
  else
    LoadBmp(int(AnimNode[AnimFrame].Data));

  if i<>1 then
  begin
    inc(AnimFrame);
    if AnimFrame>=i then
      AnimFrame:=0;
  end else
    RSTimer1.Interval:=0;
end;

procedure TForm1.WMActivate(var Msg:TWMActivate);
begin
  inherited; 	
  RSTimer1.Enabled:= (Msg.Active<>WA_INACTIVE) and not Msg.Minimized;
  ShowHint:= Msg.Active<>WA_INACTIVE;
end;

procedure TForm1.ReadIni;
const
  Sect = 'General';
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini')) do
    try
      Recent.AsString:= ReadString(Sect, 'Recent Files', '');
      Transparent1.Checked:= ReadBool(Sect, 'Transparent Background', false);
      NoShadow1.Checked:= ReadBool(Sect, 'No Shadow', false);
      Extractin24bits1.Checked:= ReadBool(Sect, 'Extract In 24 Bits', true);
      FExtractPath:= ReadString(Sect, 'Extract Path', '');
      if FExtractPath<>'' then
        FExtractPath:= IncludeTrailingPathDelimiter(FExtractPath);
      FillLanguage(AppPath + 'Language\', ReadString(Sect, 'Language', 'English'));
    finally
      Free;
    end;
end;

procedure TForm1.WriteIni;
const
  Sect = 'General';
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini')) do
    try
      WriteString(Sect, 'Recent Files', Recent.AsString);
      WriteBool(Sect, 'Transparent Background', Transparent1.Checked);
      WriteBool(Sect, 'No Shadow', NoShadow1.Checked);
      WriteBool(Sect, 'Extract In 24 Bits', Extractin24bits1.Checked);
      WriteString(Sect, 'Extract Path', FExtractPath);
      WriteString(Sect, 'Language', CurrentLanguage);
    finally
      Free;
    end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var i:int;
begin
  AssertErrorProc:= RSAssertErrorHandler;
  RSDebugUseDefaults;
  RSDebugHook;
  Application.OnException:= ApplicationEvents1Exception;
  RSFixThemesBug;
  RSHookFlatBevels(self);
  HintWindowClass:=TRSSimpleHintWindow;
  Picture:= TBitmap.Create;

  Association:= TRSFileAssociation.Create('.def', 'DefPreview.Def',
         'DefPreview Backup', '"' + RSGetModuleFileName(0) + '" "%1"',
          RSGetModuleFileName(0) + ',0');

  Recent:= TRSRecent.Create(RecentClick, N1, false, false);
  Recent.Limit:=4;

  RSHelpCreate(AppTitle+' Help Form');

  with RSLanguage.AddSection('[Main Form]', self) do
  begin
    AddItem('SGroup', SGroup);
    AddItem('SWrongCompression', SWrongCompression);
    AddItem('SUnusedType', SUnusedType);
  end;

  Caption:=AppTitle;
  try
    RSLanguage.LoadLanguage(RSLoadTextFile(AppPath + 'Language\English.txt'), false);
  except
  end;
  RSLanguage.LanguageBackup:= '';
  CurrentLanguage:= 'English';


  MakeTypeImages;
  RSMenu.Add(MainMenu1);
  RSMenu.Add(PopupMenu1);
  RSMenu.OnGetText:=MenuGetText;
  RSMenu.OnGetFontColor:=MenuFontColor;
  RSBindToolBar:=true;
  RSMakeToolBar(Panel1, [Open1, SaveAs1, nil, ExportPictures1, ExportDefList1,
    ExtractAll1, nil, Stretch1, Transparent1,
    {NoSelection1,} NoShadow1, nil], ToolButtons, 4, 12);
  for i:=0 to high(ToolButtons) do
    TRSSpeedButton(ToolButtons[i]).OnContextPopup:=TreeView1.OnContextPopup;
  with ToolButtons[high(ToolButtons)] do
    RSComboBox1.Left:= 4 + Left + Width;
  RSComboBox1.Top:= (Panel1.ClientHeight - RSComboBox1.Height) div 2;
  TRSSpeedButton(ToolButtons[7]).GroupIndex:= 1;
  TRSSpeedButton(ToolButtons[8]).GroupIndex:= 2;
  TRSSpeedButton(ToolButtons[9]).GroupIndex:= 3;

  ReadIni;

  TRSSpeedButton(ToolButtons[7]).Down:= Stretch1.Checked;
  TRSSpeedButton(ToolButtons[8]).Down:= Transparent1.Checked;
  TRSSpeedButton(ToolButtons[9]).Down:= NoShadow1.Checked;
  Panel2.FullRepaint:=false;

  CalculateSizes;
  RSShowHint('', Point(0,0));
  RSHideHint(false);
  Groups[$42]:= Groups42.Items;
  Groups[$44]:= Groups44.Items;
  Groups[$49]:= Groups49.Items;
  RSToolBarEnable(Edit1, false);

  MakeDefToolFilter;

  if ParamStr(1)<>'' then
  begin
    fileName:=ParamStr(1);
    Load(true);
  end;
end;

function TForm1.GetDefAnimTime: int;
begin
  if Def = nil then
  begin
    Result:= 100;
    exit;
  end;

  case Def.Header.TypeOfDef of
    $40, $42, $49: Result:= 100;
    else Result:= 180;
  end;
end;

function TForm1.GetExtractPath: string;
begin
  Result:= ChangeFileExt(fileName, '');
  if FExtractPath <> '' then
    Result:= FExtractPath + ExtractFileName(Result);

  if FileExists(Result) then
    Result:= ExtractFilePath(ExcludeTrailingPathDelimiter(Result));
  Result:= IncludeTrailingPathDelimiter(Result);  
end;

procedure TForm1.TreeView1Collapsing(Sender: TObject; Node: TTreeNode;
  var AllowCollapse: Boolean);
begin
  if Node.Parent=nil then
    AllowCollapse:=false;
end;

procedure TForm1.TreeView1Editing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
begin
  AllowEdit:=int(Node.Data)<0;
end;

procedure TForm1.TreeView1Edited(Sender: TObject; Node: TTreeNode;
  var S: String);
var i,j:int;
begin
  val(s, i, j);
  if j<>1 then
  begin
    Def.Groups[not int(Node.Data)].GroupNum:=i;
    s:=MakeGroupName(i);
    WasChanged;
  end else
    s:=Node.Text;
end;

procedure TForm1.CalculateSizes;
var i,j: int;
begin
  Canvas.Font:=StatusBar1.Font;
  with StatusBar1, Canvas do
  begin
    Panels[0].Width:= TextWidth(Panels[0].Text) + 10;
    Panels[2].Width:= TextWidth(Panels[2].Text) + 10;
    Panels[4].Width:= TextWidth(Panels[4].Text) + 10;
    Panels[6].Width:= TextWidth(Panels[6].Text) + 10;
    Panels[8].Width:= TextWidth(Panels[8].Text) + 10;
    j:=0;
    for i:=0 to PopupMenu1.Items.Count-1 do
    begin
      j:=max(j, TextWidth(StripHotkey(PopupMenu1.Items[i].Caption)));
    end;
    Panels[5].Width:=j+10;

    TypeLeft:= 0;
    for i:=0 to 3 do
      inc(TypeLeft, Panels[i].Width);
    TypeRight:= TypeLeft + Panels[4].Width + Panels[5].Width;
  end;
end;

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WinClassName:=AppTitle+' Main Form';
end;

procedure TForm1.WasChanged(b:boolean=true);
begin
  FWasChanged:=b;
end;

procedure TForm1.Load(FillFiles:Boolean);
var i,j,k:int; a:TRSByteArray; Node,it:TTreeNode;
begin
  if FillFiles then
    if FileExists(fileName) then
      Recent.Add(fileName)
    else
      Recent.Delete(fileName)
  else
    if Recent.Delete(fileName) then
      Recent.Add(fileName);

  a:=RSLoadFile(fileName);
  RSTimer1.Interval:=0;
  FreeAndNil(Def);
  LastBmp:=0;

  try
    Def:=TRSDefWrapper.Create(a);
  except
    TreeView1.Items[0].DeleteChildren;
    Picture.Assign(nil);
    PicError:='';
    Def:=nil;
    raise;
  end;
  Def.OnPreparePalette:=PreparePal;
  j:=Def.PicturesCount;
  PicCount:=j;

  with StatusBar1, Def.Header^ do
  begin
    Panels[1].Text:=IntToStr(Width);
    Panels[3].Text:=IntToStr(Height);
    SetType(TypeOfDef, false);
  end;

  Node:=TreeView1.Items[0];
  //TreeView1.Items.BeginUpdate;
  TreeView1.Perform(WM_SETREDRAW, 0, 0);
  try
    Node.Text:=ExtractFileName(fileName);
    Node.DeleteChildren;
    k:=0;
    with Def do
      for i:=0 to length(Groups)-1 do
      begin
        it:=TreeView1.Items.AddChildObject(Node,
                         MakeGroupName(Groups[i].GroupNum), ptr(not i));
        for j:=0 to Groups[i].ItemsCount-1 do
        begin
          TreeView1.Items.AddChildObject(it,ItemNames[i][j],ptr(k));
          inc(k);
        end;
        it.Expand(false);
      end;
    Node.Expand(false);
  finally
//    TreeView1.Items.EndUpdate;
    TreeView1.Perform(WM_SETREDRAW, 1, 0);
  end;
  //TreeView1.Width:=145;
  TreeView1.Select(Node);
  TreeView1Change(nil, Node);
  InvalidateRect(Panel2.Handle, nil, false);
  TreeView1.Visible:=true;
  RSToolBarEnable(Edit1, true);
  RSToolBarEnable(SaveAs1, true);
  Caption:= ExtractFileName(fileName)+' - '+AppTitle;
  Application.Title:= Caption;
  if FillFiles then  FillFilesList;
  UpdateWindow(Panel2.Handle);
end;

procedure TForm1.Open1Click(Sender: TObject);
begin
  OpenDialog1.FileName:=fileName;
  if not OpenDialog1.Execute then exit;
  fileName:=OpenDialog1.FileName;
  Load(true);
end;

procedure TForm1.English1Click(Sender: TObject);
var
  i: int;
  c: TRSSpeedButton;
begin
  if SameText(TMenuItem(Sender).Caption, CurrentLanguage) then
    exit;

  CurrentLanguage:= TMenuItem(Sender).Caption;

  RSLanguage.LoadLanguage(RSLanguage.LanguageBackup, false);
  try
    RSLanguage.LoadLanguage(RSLoadTextFile(AppPath + 'Language\' + TMenuItem(Sender).Caption + '.txt'),
      false);
  except
  end;

  with RSHelp.Memo1 do
    Text:= RSStringReplace(Text, '%VERSION%', RSGetModuleVersion);
  
  for i := 0 to length(ToolButtons) - 1 do
  begin
    if not (ToolButtons[i] is TRSSpeedButton) then
      continue;

    c:= TRSSpeedButton(ToolButtons[i]);
    with TMenuItem(c.Tag) do
      c.Hint:= StripHotkey(Caption) + '|' + Hint;
  end;

  CalculateSizes;
  if Def<>nil then
    SetType(Def.Header.TypeOfDef, true);
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.SaveAs1Click(Sender: TObject);
begin
  if fileName='' then exit;
  SaveDialog1.FileName:=fileName;
  if not SaveDialog1.Execute then exit;
  fileName:=SaveDialog1.FileName;
  RSSaveFile(fileName, Def.Data);
end;

procedure TForm1.Stretch1Click(Sender: TObject);
begin
  RSToolBarReactCheck(Sender, Stretch1);
  InvalidateRect(Panel2.Handle, nil, false);
end;

procedure TForm1.ExportPictures1Click(Sender: TObject);
var i,j:int; Node, it:TTreeNode; s,s1:string; Bmp:TBitmap;
begin
  if fileName='' then exit;
  Node:=TreeView1.Selected;
  i:=Node.Level;
  s:= ExtractPath;
  s1:=fileName;
  with SaveDialog2 do
    case i of
      0:
      begin
        FileName:= ExtractPath + 'Extract Here';
        Options:=[ofHideReadOnly,ofEnableSizing];
        DefaultExt:='';
      end;
      1:
      begin
        FileName:= ExtractPath + 'Extract Here';
        Options:=[ofHideReadOnly,ofEnableSizing];
        DefaultExt:='';
      end;
      2:
      begin
        FileName:= ExtractPath + ChangeFileExt(Node.Text, '.bmp');
        Options:=[ofOverwritePrompt,ofHideReadOnly,ofEnableSizing];
        DefaultExt:='.bmp';
      end;
    end;

  if not SaveDialog2.Execute then exit;
  s:= ExtractFilePath(SaveDialog2.FileName);
  ExtractPath:= s;
  RSCreateDir(s);

  if i = 2 then
    s:=SaveDialog2.FileName;

  Bmp:=nil;
  Extracting:= true;
  try
    Def.RebuildPal;
    case i of
      0:
        for i:=0 to Node.Count-1 do
        begin
          it:=Node[i];
          for j:=0 to it.Count-1 do
          begin
            Bmp:= Def.ExtractBmp(int(it[j].Data));
            //Bmp:=DoLoadBmp(int(it[j].Data));
            if (Bmp<>nil) and Extractin24bits1.Checked then
              Bmp.PixelFormat:= pf24bit;
            if Bmp<>nil then
              Bmp.SaveToFile(s+ChangeFileExt(it[j].Text, '.bmp'));
            FreeAndNil(Bmp);
          end;
        end;
      1:
        for j:=0 to Node.Count-1 do
        begin
          Bmp:= Def.ExtractBmp(int(Node[j].Data));
          //Bmp:=DoLoadBmp(int(Node[j].Data));
          if (Bmp<>nil) and Extractin24bits1.Checked then
            Bmp.PixelFormat:= pf24bit;
          if Bmp<>nil then
            Bmp.SaveToFile(s+ChangeFileExt(Node[j].Text, '.bmp'));
          FreeAndNil(Bmp);
        end;
      2:
      begin
        //Bmp:=DoLoadBmp(int(Node.Data));
        Bmp:= Def.ExtractBmp(int(Node.Data));
        if (Bmp<>nil) and Extractin24bits1.Checked then
          Bmp.PixelFormat:= pf24bit;
        if Bmp<>nil then
          Bmp.SaveToFile(s);
        FreeAndNil(Bmp);
      end;
    end;
  finally
    Extracting:= false;
    Def.RebuildPal;
    Bmp.Free;
  end;
end;

procedure TForm1.DoExtractDefList;
const Bools:array[boolean] of string=('FALSE','TRUE');
var
  New: boolean;
  f2, fn, Dir:string; i,j:int;
begin
  if fileName='' then exit;
  SaveDialog3.FileName:= ExtractPath + ChangeFileExt(ExtractFileName(fileName), '.h3l');
  if not SaveDialog3.Execute then exit;
  ExtractPath:= ExtractFilePath(SaveDialog3.FileName);
  New:= SaveDialog3.FilterIndex <> 2;
  f2:='';
  fn:=SaveDialog3.FileName;
  Dir:='';//IncludeTrailingPathDelimiter(ExtractFileDir(fn));
  if New then
    with Def.Header^ do
    begin
      case Def.GetPicHeader(0).Compression of
        0: f2:=f2+'3';
        1: f2:=f2+'0';
        2: f2:=f2+'1';
        3: f2:=f2+'2';
        else
          f2:=f2+'0';
      end;
      f2:=f2+#13#10;
      i:=$49-TypeOfDef;
      if i<0 then i:=2;
      f2:=f2+IntToStr(i)+#13#10;
      f2:=f2+ExtractFileName(OpenDialog1.FileName)+#13#10;
      f2:=f2+Bools[false]+#13#10+Bools[false]+#13#10+Bools[false]+#13#10;
      f2:=f2+IntToStr(Width)+#13#10;
      f2:=f2+IntToStr(Height)+#13#10;
      f2:=f2+#13#10;
      if TypeOfDef=$42 then
        f2:=f2+'14'#13#10
      else
        f2:=f2+'0'#13#10;
      f2:=f2+Bools[false]+#13#10+Bools[false]+#13#10+Bools[false]+#13#10;
      f2:=f2+'Auto'+#13#10+'Auto'+#13#10;
    end;
  with Def do
    for i:=0 to length(Groups)-1 do
    begin
      f2:=f2+Dir+ChangeFileExt(ItemNames[i][0],'.bmp');
      for j:=1 to Groups[i].ItemsCount-1 do
        f2:=f2+#13#10+Dir+ChangeFileExt(ItemNames[i][j],'.bmp');
      if New then
        f2:= f2 + '  ' + IntToStr(Groups[i].GroupNum) + '+'#13#10
      else
        f2:= f2 + '+'#13#10;
    end;
  RSSaveTextFile(fn, f2);
end;

procedure TForm1.Extractin24bits1Click(Sender: TObject);
begin
  Extractin24bits1.Checked:= not Extractin24bits1.Checked;
end;

procedure TForm1.ExtractAll1Click(Sender: TObject);
var
  Errors: string;
  NoShadow: Boolean;
begin
  if fileName='' then exit;

  NoShadow:= (Def.Header.TypeOfDef in [$40, $45, $46, $47]) or NoShadow1.Checked;

  with SaveDialog4 do
  begin
    FileName:= ExtractPath + ChangeFileExt(ExtractFileName(self.fileName), '.hdl');

    if NoShadow then
      Filter:= DefToolNoShadowFilter
    else
      Filter:= DefToolFilter;

    if not Execute then exit;

    ExtractPath:= ExtractFilePath(FileName);
    NoShadow:= NoShadow or (FilterIndex = 2);
    Extracting:= true;
    try
      Def.RebuildPal;
      Errors:= Def.ExtractDefToolList(FileName, not NoShadow, Extractin24bits1.Checked);
    finally
      Extracting:= false;
      Def.RebuildPal;
    end;
  end;

  if Errors<>'' then
    RSMessageBox(Handle, Errors, Application.Title, MB_ICONERROR);
end;

procedure TForm1.ExportDefList1Click(Sender: TObject);
begin
  DoExtractDefList;
end;

procedure TForm1.LoadGroupsNumbers1Click(Sender: TObject);
var Def1:TRSDefWrapper; i,j:int; Node:TTreeNode;
begin
  if fileName='' then exit;
  OpenDialog1.FileName:='';
  if not OpenDialog1.Execute then exit;
  Node:=TreeView1.Items[0];
  Def1:=TRSDefWrapper.Create(RSLoadFile(OpenDialog1.FileName));
  try
    for i:=0 to min(length(Def.Groups),length(Def1.Groups))-1 do
    begin
      j:=Def1.Groups[i].GroupNum;
      Def.Groups[i].GroupNum:=j;
      Node[i].Text:=MakeGroupName(j);
    end;
  finally
    Def1.Free;
  end;
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
var p:TPoint;
begin
  if Def=nil then exit;
  p:=StatusBar1.ScreenToClient(Mouse.CursorPos);
  if (p.X>=TypeLeft) and (p.X<TypeRight) then
    with PopupMenu1 do
    begin
      p:=StatusBar1.ClientToScreen(Point(TypeLeft, 0));
      Tag:=Def.Header.TypeOfDef-$40;
      Items[Tag].Checked:=true;
      Popup(p.x, p.y);
    end;
  {
    with Mouse.CursorPos, PopupMenu1 do
    begin
      Tag:=Def.Header.TypeOfDef-$40;
      Items[Tag].Checked:=true;
      Popup(x, y);
    end;
  }
end;

procedure TForm1.N40Sprite1Click(Sender: TObject);
begin
  SetType(TMenuItem(Sender).Tag, true);
end;

procedure TForm1.PopupMenu1Popup(Sender: TObject);
var i:int;
begin
  for i:=0 to min(PopupMenu1.Tag, PopupMenu1.Items.Count-1) do
  begin
    keybd_event(VK_DOWN, 0, 0, 0);
    keybd_event(VK_DOWN, 0, KEYEVENTF_KEYUP, 0);
  end;
end;

procedure TForm1.SetExtractPath(const v: string);
begin
  if ExtractFileName(ExcludeTrailingPathDelimiter(v)) =
       ChangeFileExt(ExtractFileName(fileName), '') then
    FExtractPath:= ExtractFilePath(ExcludeTrailingPathDelimiter(v))
  else
    FExtractPath:= v;
end;

procedure TForm1.SetType(t:int; Groups:boolean);
var c:TCompr; i:int;
begin
  Def.Header.TypeOfDef:=t;
  with StatusBar1 do
    if (t>=$40) and (t<=$49) then
    begin
      Panels[5].Text:=StripHotkey(PopupMenu1.Items[t-$40].Caption);
      c:=Compressions[t];
      if Def.GetPicHeader(0)^.Compression in c then
        Panels[10].Text:=''
      else
        if c=[] then
          Panels[10].Text:=SUnusedType
        else
          Panels[10].Text:=SWrongCompression;
    end else
      Panels[5].Text:='$'+IntToHex(t, 0);

  if Groups and (t>=$40) and (t<=$49) then
    with TreeView1.Items[0] do
      for i:=0 to Count-1 do
      begin
        Item[i].Text:= MakeGroupName(Def.Groups[i].GroupNum);
      end;
end;

procedure TForm1.MakeDefToolFilter;
var
  i,j: int;
  s: string;
begin
  DefToolFilter:= SaveDialog4.Filter;
  s:= SaveDialog4.Filter;
  j:= 0;
  for i:= 1 to length(s) do
    if s[i] = '|' then
    begin
      inc(j);
      if j = 2 then
      begin
        DefToolNoShadowFilter:= Copy(s, i + 1, length(s) - i);
        exit;
      end;
    end;
end;

procedure TForm1.MakeTypeImages;
const
  _Flags: LongInt = DT_NOCLIP or DT_VCENTER or DT_END_ELLIPSIS or
                    DT_SINGLELINE or DT_LEFT;
var
  i:int; b:TBitmap; r:TRect; s:string;
begin
  b:=TBitmap.Create;
  with b, Canvas do
    try
      Font:=RSMenu.Font;
      Width:=TextWidth('$40')+4;
      Height:=TextHeight('W')+3;
      ImageList2.Width:=Width;
      ImageList2.Height:=Height;
      Brush.Color:=$FFFFFE;
      r:=ClipRect;
      inc(r.Left, 2);
      for i:=0 to PopupMenu1.Items.Count-1 do
      begin
        FillRect(ClipRect);
        s:='$4&'+chr(ord('0')+i);
        Windows.DrawText(Handle, PChar(s), Length(s), r, _Flags);
        ImageList2.AddMasked(b, Brush.Color);
        PopupMenu1.Items[i].ImageIndex:=i;
      end;
    finally
      b.Free;
    end;
end;

procedure TForm1.MenuGetText(Item: TMenuItem; var Result:string);
var i:int;
begin
  Result:=Item.Caption;
  if Item.GetParentMenu=PopupMenu1 then
  begin
    i:=5;//pos(s, ' ');
    Result:=copy(Result, i+1, length(Result)-i);
  end;
end;

procedure TForm1.MenuFontColor(var c:TColor; Item: TMenuItem; State:TOwnerDrawState);
begin
  if (Item.GetParentMenu=PopupMenu1) and
     not (Def.GetPicHeader(0)^.Compression in Compressions[Item.Tag]) then
    c:=clBtnShadow;
end;

procedure TForm1.RecentClick(Sender:TRSRecent; Name:string);
begin
  fileName:=Name;
  Load(true);
end;

procedure TForm1.Help1Click(Sender: TObject);
begin
  Perform(WM_HELP, 0, 0);
end;

procedure TForm1.WMHelp(var Msg:TMessage);
begin
  RSHelpShow([]);
end;

procedure TForm1.TreeView1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
  RSHelpHint(Sender);
end;

procedure TForm1.StatusBar1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
  StatusBar1Click(Sender);
end;

procedure TForm1.TreeView1AdvancedCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
  var PaintImages, DefaultDraw: Boolean);
var r:TRect;
begin
  if (Stage<>cdPostPaint) or (Node.Level>1) or (cdsSelected in State) then
    exit;
  r:=Node.DisplayRect(true);
  with Sender.Canvas do
    if Node.Level=0 then
    begin
      Brush.Color:=RSMixColors(clGrayText, clWindow, 160);
      FrameRect(r);
    end else
    begin
      Pen.Color:=RSMixColors(clGrayText, clWindow, 160);
      MoveTo(r.Right-1, r.Bottom-1);
      LineTo(r.Left, r.Bottom-1);
      LineTo(r.Left, (r.Bottom+r.Top) div 2 -1);
    end;
end;

{
function TForm1.Associated:boolean;
const
  RegName='DefPreview.Def';
  Backup='DefPreview Backup';
var s:string;
begin
  with TRSRegistry.Create do
  try
    RootKey:= HKEY_CLASSES_ROOT;
    Result:= OpenKeyReadOnly('\.def') and Read('', s) and (s=RegName) and
             OpenKeyReadOnly('\'+RegName+'\shell\open\command') and
             Read('', s) and SameText(s, AssociatePath);
  finally
    Free;
  end;
end;

procedure TForm1.Associate;
const
  RegName='DefPreview.Def';
  Backup='DefPreview Backup';
var s:string;
begin
  with TRSRegistry.Create do
  try
    RootKey:=HKEY_CLASSES_ROOT;

    Win32Check(OpenKey('\'+RegName+'\DefaultIcon', true));
    WriteString('', Application.ExeName+',0');
    Win32Check(OpenKey('\'+RegName+'\shell\open\command', true));
    WriteString('', AssociatePath);

    Win32Check(OpenKey('\.def', true));
    if Read('', s) and (s<>RegName) and (s<>'') then
      WriteString(Backup, s);
    WriteString('', RegName);
  finally
    Free;
  end;
end;

procedure TForm1.Unassociate;
const
  RegName='DefPreview.Def';
  Backup='DefPreview Backup';
var s:string;
begin
  with TRSRegistry.Create do
  try
    RootKey:=HKEY_CLASSES_ROOT;
    Win32Check(OpenKey('\.def', true));
    s:=ReadString('');
    if s=RegName then
    begin
      if not Read(Backup, s) then s:='';
      WriteString('', s);
      DeleteValue(Backup);
      DeleteKey('\'+RegName);
    end;
  finally
    Free;
  end;
end;
}

procedure TForm1.ApplicationEvents1Exception(Sender: TObject; E: Exception);
begin
  AppendDebugLog(RSLogExceptions);
end;

procedure TForm1.Associate1Click(Sender: TObject);
begin
  Association.Associated:= not Associate1.Checked;
end;

procedure TForm1.Options1Click(Sender: TObject);
begin
  Associate1.Checked:= Association.Associated;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  WriteIni;
end;

procedure TForm1.Transparent1Click(Sender: TObject);
begin
  RSToolBarReactCheck(Sender, Transparent1);
  if Def=nil then exit;
  Def.RebuildPal;
  LoadBmp(LastBmp);
end;

procedure TForm1.NoShadow1Click(Sender: TObject);
begin
  RSToolBarReactCheck(Sender, NoShadow1);
  if Def=nil then exit;
  Def.RebuildPal;
  LoadBmp(LastBmp);
end;

procedure TForm1.RSComboBox1DrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  if odSelected in State then
    State:= State + [odFocused];
  with TComboBox(Control) do
    RSPaintList(Control, Canvas, Items[Index], Rect, State);
end;

procedure TForm1.FillFilesList;
var s:string;
begin
  with TRSFindFile.Create(fileName) do
  begin
    if Found then
      s:= Data.cFileName
    else
      s:= ExtractFileName(self.fileName);
    Free;
  end;

  RSComboBox1.Clear;
  with TRSFindFile.Create(ExtractFilePath(fileName)+'*.def') do
    try
      while FindAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do
      begin
        RSComboBox1.Items.Add(Data.cFileName);
        if Data.cFileName = s then
          RSComboBox1.ItemIndex:= RSComboBox1.Items.Count-1;
        FindNext;
      end;
    finally
      Free;
    end;
end;

procedure TForm1.FillLanguage(LangDir: string; Default: string);
var
  Items: TStringList;
  i, eng, def: int;
  it: TMenuItem;
begin
  Items:= TStringList.Create;
  Items.Sorted:= true;
  try
    with TRSFindFile.Create(LangDir + '*.txt') do
      try
        while FindAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do
        begin
          Items.Add(ChangeFileExt(Data.cFileName, ''));
          FindNext;
        end;
      finally
        Free;
      end;

    eng:= Items.IndexOf('English');
    if eng <= 0 then
      eng:= Items.Add('English');

    def:= Items.IndexOf(Default);
    if def <= 0 then
      def:= eng;

    Language1.Clear;
    for i := 0 to Items.Count - 1 do
    begin
      it:= TMenuItem.Create(self);
      it.RadioItem:= true;
      it.GroupIndex:= 1;
      it.Caption:= Items[i];
      it.AutoCheck:= true;
      it.OnClick:= English1Click;
      Language1.Add(it);
      if i = def then
      begin
        it.Checked:= true;
        English1Click(it);
      end;
    end;

  finally
    Items.Free;
  end;
end;

procedure TForm1.RSComboBox1Select(Sender: TObject);
begin
  fileName:= ExtractFilePath(fileName) + RSComboBox1.Text;
  Load(false);
end;

procedure TForm1.RSComboBox1WndProc(Sender: TObject; var Message: TMessage;
  var Handled: Boolean; const NextWndProc: TWndMethod);
begin
  if (Message.Msg = WM_MOUSEWHEEL) and RSPtInControl(Mouse.CursorPos, TreeView1) then
  begin
    TreeView1.WindowProc(Message);
    Handled:= true;
  end;
end;

procedure TForm1.Panel2Paint(Sender: TRSCustomControl;
  State: TRSControlState; DefaultPaint: TRSProcedure);
var
  w,h:int; r,r1:TRect;
begin
  r:= Sender.ClientRect;
  Frame3D(Sender.Canvas, r, clBtnShadow, clBtnHighlight, 1);
  w:= r.Right - r.Left;
  h:= r.Bottom - r.Top;
  ReStretch(Picture, Stretch1.Checked, w, h);
  with Sender.Canvas do
  begin
    if w<>0 then
    begin
      r1:= Bounds(r.Left, r.Top, w, h);
      CopyRect(r1, Picture.Canvas, Picture.Canvas.ClipRect);
      RSExcludeClipRect(Handle, r1);
    end;

    Brush.Color:= clBtnFace;
    FillRect(r);
    if PicError<>'' then
    begin
      Font:= Panel2.Font;
      r1:=r;
      inc(r1.Left, 8);
      inc(r1.Top, 8);
      DrawText(Handle, ptr(PicError), length(PicError), r,
        DT_CENTER or DT_NOCLIP or DT_NOPREFIX or DT_WORDBREAK or DT_CALCRECT);
      DrawText(Handle, ptr(PicError), length(PicError), r,
        DT_CENTER or DT_NOCLIP or DT_NOPREFIX or DT_WORDBREAK);
    end;
  end;
end;

procedure TForm1.Panel2Resize(Sender: TObject);
begin
  if Stretch1.Checked then
    InvalidateRect(Panel2.Handle, nil, false);
end;

procedure TForm1.TreeView1KeyPress(Sender: TObject; var Key: Char);
begin
  if TreeView1.IsEditing then  exit;
  with TreeView1 do
    if (Key = #13) and (Selected<>nil) and (Selected.Level = 1) then
    begin
      Key:=#0;
      TreeView1.Selected.EditText;
    end;
end;

end.
