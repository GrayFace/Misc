unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, Buttons, RSSpeedButton, XPMan,
  RSQ, RSSpinEdit, RSLabel, Themes, RSComboBox, RSPanel, RSUtils, RSSysUtils,
  RSPageControl, RSShape, RSStringer, RSStrUtils, RSWinController, ShellAPI,
  RSGraphics, CommCtrl, Math, Menus, RSC, RSRecent, RSMenus, RSRegistry,
  IniFiles, RSListView, RSShellBrowse, AppEvnts, Unit2, RSDef, Lod, RSEdit,
  ExtDlgs, GifImage, RSShellListView, RSSplitter, RSJvPcx, RSFileAssociation,
  RSLang, RSMemo, RSTreeView, RSDebug, RSTimer;

{

3.2:
[+] Transparent color can be chosen automatically
[+] Chosen group of frames is animated if the General tab is selected
[-] Compression of 32*32 map pictures without palette was set to 1 instead of 0
[-] "Make .msk and .msg files" didn't work
[-] Long .hdl def lists weren't loaded properly

3.2.1:
[-] Reposition could mess up pictures

3.3:
[+] If all pictures have the same palette and it doesn't conflict with selected special colors, the palette is preserved
[+] Command line option "/g" to silently generate the def and exit
[+] Proper animation delays
[-] When default "Pictures Extension" is set, it didn't effect extension of def lists created with DefPreview
[-] Automatic transparent color didn't trigger save notification
[-] Grid.pcx was loaded incorrectly
[-] Bug fixed in adding files to lod

3.3.1:
[+] "Create Msk Files But Not Msg" option in H3DefTool.ini
[-] 32x32 adventure objects were created with type 2, causing problems with shadow

3.3.2:
[+] RLE bitmaps support (including those saved by PhotoShop)
[-] Attempt to open H3DefTool.exe as .hdl on start
[-] The check for all frames having the same palette was buggy
[-] "Standard Special Colors" check had no effect if all frames have the same palette

3.4:
[+] Drag&drop frames in tree
[+] Group option in Reposition tab
[-] Possability of crash on some computers
[*] Now Reposition works like this: if frame is moved, shadow is also moved. If shadow is selected, it's moved on its own

3.4.1:
[-] Crash on exit sometimes
[-] Inability to load some bitmaps

3.4.2:
[-] Previous version was crashing on Windows XP


http://heroescommunity.com/viewthread.php3?TID=37925

Не обрезать имена файлов, а выдавать ошибку

1. при загрузке деф-листа в кадрах "начало движения" и "конец движения" ничего нет,
 эти кадры расположены в "выстрел вверх" (начало) и "выстрел прямо" (конец движения).
 приходится вручную вставлять начало и конец движения в нужные места, иначе в игре
 допустим грифон будет стоять, а потом тут же резко уже лететь - что смотрится конечно
 отвратительно . если возможно это поправить, был бы признателен.

1. хотелось бы при создании дефа видеть progressbar с сообщением в конце о том,
 сколько весит конечный def и сколько там кадров
2. было еще очень неплохо наличие возможности увеличить картинку при создании тени...
 а то пытаться попасть в нужный пиксель, по которому нужно провести тень...
 это, знаешь ли, не очень удобно
3. к перечню combat animation и sound добавить перечень существ как объектов на карте

ladimir-maestro (15:46:47 29/08/2009)
можно дать идею\севет относительно твоего тулза для создания дефов для Г3? Заметил, что некоторые (да что там, все!) объекты на карте и прочие вещи имеют размеры кратные 32! Можно ли как-нибудь задать параметры этой сетки сразу? мол мой спрайт больше чем 64х64, но он будет расчитываться как 120х150, а надо=то 64х64 - 2 на 2 квадрата. можно задать опцию, которая бы сразу "условно обрезала" поле будущего дефа. Гораздо удобнее будет потом подвинуть изображение в нужный мне квадратик, а не обрезать кадры в фотошопе до нужного размера.

 vladimir-maestro (15:48:54 29/08/2009)
так как было для монстров на 2 клетки и на 1 клетку. все ставили их в 1ю и оно работало для 1клеточного существа. сделать бы настраиваемый предел в клетках по 32 пикселя. И будет создан деф именно в этом пределе, а остальные поля будут обрезаны.

 vladimir-maestro (17:17:57 29/08/2009)
то же заметил и с монстрами  пытался состряпать монстра из спрайта 120х120 - хексов вообще не было видно =\ пришлось все поля увеличивать где-то до 500х500

 vladimir-maestro (17:24:10 29/08/2009)
и еще совет  во время распределения дефов по движениям (кадры) именно на шкале их нельзя двигать. вот я ошибся, а подвинуть кадры не могу - приходится всю последовательность заново набирать

 234340048 (17:25:04 29/08/2009)
при вставке можно выбирать куда ставить

 vladimir-maestro (17:25:34 29/08/2009)
пробывал. именно вопрос с кадром номер 1. вставляется куда угодно, кроме как на 1е место


AV при Make!! (обращение к GroupNodes[i].Count в MakeFramesList)
Reposition группы
Из RotatePic
TreeView Items Drag
Выделить процедуру из DrawTreeNode и Make

}

const
  DefPlayerColors: array[0..31] of int =
    ($401F13, $4F2618, $552819, $5A2C1D, $632F1D, $69321F, $6D3320, $6D3420,
     $653828, $6E3420, $713521, $713622, $733622, $733722, $743722, $773823,
     $773923, $793923, $793A24, $7B3A24, $7D3B24, $7F3C25, $823D26, $833F27,
     $864027, $724232, $8B4128, $824A37, $90452A, $9C4B2F, $905B49, $A37A6C);

type
  TColorBoxInfo =  packed record
    FullBox: TControl;
    Box: TGroupBox;
    Shapes: array[0..8] of TShape;
    Checks: array[0..8] of TCheckBox;
    PlayerColors: array[0..31] of TColor;
    Count: int;
    Tolerance: Byte;
  end;
  PColorBoxInfo = ^TColorBoxInfo;

  TForm1 = class(TForm)
    TreeView1: TRSTreeView;
    PageControl1: TRSPageControl;
    TabSheet1: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet2: TTabSheet;
    Panel3: TPanel;
    Splitter1: TRSSplitter;
    TabSheet4: TTabSheet;
    TabSheet6: TTabSheet;
    MemoHelp: TRSMemo;
    Splitter2: TRSSplitter;
    TabSheet5: TTabSheet;
    Panel4: TPanel;
    GroupBox1: TGroupBox;
    Edit4: TRSEdit;
    RSLabel3: TRSLabel;
    RSLabel2: TRSLabel;
    Edit2: TRSEdit;
    RSLabel1: TRSLabel;
    RSComboBox2: TRSComboBox;
    Panel1: TRSPanel;
    SpeedButtonMake: TRSSpeedButton;
    SpeedButtonLod: TRSSpeedButton;
    EditLod: TRSEdit;
    CheckLod: TCheckBox;
    CheckDefPath: TCheckBox;
    EditDefPath: TRSEdit;
    SpeedButtonDefPath: TRSSpeedButton;
    Edit5: TRSEdit;
    RSSpeedButton9: TRSSpeedButton;
    ComboType: TRSComboBox;
    RSLabel4: TRSLabel;
    RSSpeedButton14: TRSSpeedButton;
    RSSpeedButton13: TRSSpeedButton;
    RSSpeedButton12: TRSSpeedButton;
    RSSpeedButton11: TRSSpeedButton;
    Panel6: TPanel;
    Splitter3: TRSSplitter;
    Panel7: TPanel;
    RSPanel1: TRSPanel;
    RSSpeedButton20: TRSSpeedButton;
    RSSpeedButton19: TRSSpeedButton;
    RSSpeedButton18: TRSSpeedButton;
    RSSpeedButton21: TRSSpeedButton;
    RSSpeedButton22: TRSSpeedButton;
    Panel5: TPanel;
    GroupColors1: TGroupBox;
    CheckColor8: TCheckBox;
    Shape6: TRSShape;
    Shape5: TRSShape;
    CheckColor7: TCheckBox;
    CheckColor6: TCheckBox;
    Shape4: TRSShape;
    Shape3: TRSShape;
    CheckColor5: TCheckBox;
    CheckColor2: TCheckBox;
    Shape2: TRSShape;
    Shape1: TRSShape;
    CheckColor1: TCheckBox;
    CheckColor9: TCheckBox;
    Shape13: TRSShape;
    Panel2: TPanel;
    Panel8: TPanel;
    RSSpinEdit1: TRSSpinEdit;
    RSLabel6: TRSLabel;
    RSSpinEdit2: TRSSpinEdit;
    RSLabel5: TRSLabel;
    GroupColors2: TGroupBox;
    Shape7: TRSShape;
    Shape8: TRSShape;
    Shape9: TRSShape;
    Shape10: TRSShape;
    Shape11: TRSShape;
    Shape12: TRSShape;
    CheckBox10: TCheckBox;
    CheckBox11: TCheckBox;
    CheckBox12: TCheckBox;
    CheckBox13: TCheckBox;
    CheckBox14: TCheckBox;
    CheckBox15: TCheckBox;
    RSSpeedButton1: TRSSpeedButton;
    ColorDialog1: TColorDialog;
    GroupsOther: TRSStringer;
    Groups44: TRSStringer;
    Groups42: TRSStringer;
    GroupBox3: TGroupBox;
    CheckBox1: TCheckBox;
    EditLodDefault: TRSEdit;
    CheckColor3: TCheckBox;
    RSShape1: TRSShape;
    CheckColor4: TCheckBox;
    RSShape2: TRSShape;
    CheckBox4: TCheckBox;
    RSShape3: TRSShape;
    CheckBox5: TCheckBox;
    RSShape4: TRSShape;
    PaintBox1: TRSPanel;
    PaintBox2: TRSPanel;
    PaintBox3: TRSPanel;
    PaintBox4: TRSPanel;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    PopupMenu1: TPopupMenu;
    RSShellListView1: TRSShellListView;
    RSShellListView2: TRSShellListView;
    RSEdit1: TRSEdit;
    RSEdit2: TRSEdit;
    OpenLodDialog: TOpenDialog;
    SaveDefDialog: TSaveDialog;
    RSSpeedButton2: TRSSpeedButton;
    Panel9: TPanel;
    RSSpeedButton3: TRSSpeedButton;
    RSSpeedButton4: TRSSpeedButton;
    CheckStColors: TCheckBox;
    CheckMsk: TCheckBox;
    CheckBackup1: TCheckBox;
    CheckBackup2: TCheckBox;
    SaveShadowDialog: TSavePictureDialog;
    RSPanel2: TRSPanel;
    RSSpeedButton5: TRSSpeedButton;
    RSSpeedButton6: TRSSpeedButton;
    RSSpeedButton7: TRSSpeedButton;
    RSSpeedButton8: TRSSpeedButton;
    ButtonCurrent: TRSSpeedButton;
    ButtonAll: TRSSpeedButton;
    ButtonApply: TRSSpeedButton;
    ButtonCancel: TRSSpeedButton;
    PaintBox5: TRSPanel;
    SpeedButtonLodDefault: TRSSpeedButton;
    RSLabel7: TRSLabel;
    RSSpeedButton10: TRSSpeedButton;
    SpeedButtonPictures: TRSSpeedButton;
    SpeedButtonByOne: TRSSpeedButton;
    EditBitmapsPath: TRSEdit;
    SpeedButtonBitmaps: TRSSpeedButton;
    CheckBitmaps: TCheckBox;
    CheckBitmapsLod: TCheckBox;
    EditBitmapsLod: TRSEdit;
    SpeedButtonBitmapsLod: TRSSpeedButton;
    RSLabel8: TRSLabel;
    EditLodBitmaps: TRSEdit;
    SpeedButtonLodBitmaps: TRSSpeedButton;
    EditPicsExtension: TRSEdit;
    RSLabel9: TRSLabel;
    Groups49: TRSStringer;
    CheckBackupPics: TCheckBox;
    RSLabel10: TRSLabel;
    RSLabel11: TRSLabel;
    ComboGameLang: TRSComboBox;
    ComboLang: TRSComboBox;
    SpeedButtonFaintShadow: TRSSpeedButton;
    RSTimer1: TRSTimer;
    ButtonGroup: TRSSpeedButton;
    DragTimer: TTimer;
    procedure TreeView1EndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure TreeView1StartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure TreeView1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure TreeView1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure DragTimerTimer(Sender: TObject);
    procedure RSTimer1Timer(Sender: TObject);
    procedure ComboGameLangSelect(Sender: TObject);
    procedure ComboLangSelect(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RSSpeedButton11Click(Sender: TObject);
    procedure Shape1Click(Sender: TObject);
    procedure ComboTypeSelect(Sender: TObject);
    procedure RSSpeedButton9Click(Sender: TObject);
    procedure PageControl1DrawTab(Control: TCustomTabControl;
      TabIndex: Integer; const ARect: TRect; Active: Boolean);
    procedure ComboTypeDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure RSSpeedButton18Click(Sender: TObject);
    procedure RSSpeedButton19Click(Sender: TObject);
    procedure RSSpeedButton20Click(Sender: TObject);
    procedure RSSpeedButton12Click(Sender: TObject);
    procedure RSSpeedButton13Click(Sender: TObject);
    procedure RSSpeedButton14Click(Sender: TObject);
    procedure WasChangedChange(Sender: TObject);
    procedure CheckDefPathClick(Sender: TObject);
    procedure CheckLodClick(Sender: TObject);
    procedure OpenDialog1TypeChange(Sender: TObject);
    procedure TabSheet2Show(Sender: TObject);
    procedure RSShellListView1CanRefresh(Sender: TObject;
      var Handled: Boolean);
    procedure TabSheet3Show(Sender: TObject);
    procedure RSShellListView1OpenFile(Sender: TRSShellListView;
      AFile: TRSShellFile; var Handled: Boolean);
    procedure RSShellListView1CanAdd(Sender: TObject;
      ShellFile: TRSShellFile; var CanAdd: Boolean);
    procedure TreeView1Deletion(Sender: TObject; Node: TTreeNode);
    procedure RSShellListView1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure RSShellListView1FolderChanged(Sender: TObject);
    procedure RSShellListView2FolderChanged(Sender: TObject);
    procedure TreeView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SpeedButtonMakeClick(Sender: TObject);
    procedure RSEdit1KeyPress(Sender: TObject; var Key: Char);
    procedure RSEdit2KeyPress(Sender: TObject; var Key: Char);
    procedure RSSpeedButton2Click(Sender: TObject);
    procedure SpeedButtonDefPathClick(Sender: TObject);
    procedure SpeedButtonLodClick(Sender: TObject);
    procedure PaintBox1Paint(Sender: TRSCustomControl;
      State: TRSControlState; DefaultPaint: TRSProcedure);
    procedure TabSheet1Show(Sender: TObject);
    procedure TabSheet4Show(Sender: TObject);
    procedure PaintBox4Paint(Sender: TRSCustomControl;
      State: TRSControlState; DefaultPaint: TRSProcedure);
    procedure PaintBox4MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox4MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ShadowChanged(Sender: TObject);
    procedure TreeView1Collapsed(Sender: TObject; Node: TTreeNode);
    procedure TreeView1Expanded(Sender: TObject; Node: TTreeNode);
    procedure RSSpeedButton3Click(Sender: TObject);
    procedure RSSpeedButton4Click(Sender: TObject);
    procedure RSSpeedButton21Click(Sender: TObject);
    procedure PaintBox5Paint(Sender: TRSCustomControl;
      State: TRSControlState; DefaultPaint: TRSProcedure);
    procedure PageControl1Changing(Sender: TObject;
      var AllowChange: Boolean);
    procedure TabSheet4Hide(Sender: TObject);
    procedure PaintBox5MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox5MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBox5MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RSSpeedButton5Click(Sender: TObject);
    procedure RSSpeedButton7Click(Sender: TObject);
    procedure RSSpeedButton6Click(Sender: TObject);
    procedure RSSpeedButton8Click(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonApplyClick(Sender: TObject);
    procedure TabSheet5Show(Sender: TObject);
    procedure RSComboBox2Select(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure SpeedButtonLodDefaultClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TreeView1Editing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure TreeView1Edited(Sender: TObject; Node: TTreeNode;
      var s: String);
    procedure Shape13Click(Sender: TObject);
    procedure CheckBackup1Click(Sender: TObject);
    procedure ContextHelpPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure RSSpeedButton10Click(Sender: TObject);
    procedure TreeView1WndProc(Sender: TObject; var M: TMessage;
      var Handled: Boolean; const NextWndProc: TWndMethod);
    procedure CheckBitmapsClick(Sender: TObject);
    procedure SpeedButtonBitmapsLodClick(Sender: TObject);
    procedure SpeedButtonBitmapsClick(Sender: TObject);
    procedure SpeedButtonLodBitmapsClick(Sender: TObject);
    procedure TabSheet5Hide(Sender: TObject);
    procedure SpeedButtonByOneClick(Sender: TObject);
    procedure SpeedButtonPicturesClick(Sender: TObject);
    procedure PaintBox1Resize(Sender: TObject);
    procedure RSEdit1Resize(Sender: TObject);
    procedure Edit5WndProc(Sender: TObject; var Msg: TMessage;
      var Handled: Boolean; const NextWndProc: TWndMethod);
    procedure Edit5ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure CheckBitmapsLodClick(Sender: TObject);
    procedure TabSheet6Show(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure RSShellListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure RSShellListView1DblClick(Sender: TObject);
    procedure TreeView1KeyPress(Sender: TObject; var Key: Char);
  private
    FFileName: string;
    function GetTypeIndex: int;
    procedure SetTypeIndex(v: int);
    procedure SetFileName(v:string);
    function GetShadowType:int;
    procedure SetShadowType(v:int);
  protected
    DragHWnd: HWND;
    OldDragWndProc: ptr;
    DragTargetNode, DragNode : TTreeNode;
    procedure HookDragWindow;
    procedure DragWndProc(var m: TMessage);

    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMActivate(var Msg:TWMActivate); message WM_Activate;
    procedure WMHelp(var Msg:TMessage); message WM_Help;
  public
    FileChosen: Boolean;
    WasChanged: Boolean;
    LastAnimIndex: int;
    LastAnimNode: TTreeNode;
    Picture: TBitmap;
    PictureReady: TBitmap;
    PictureName: string;
    PictureError: string;
    PictureNode: TTreeNode;

    FramesPath: string;
    ShadowPath: string;

    ShadowSet: Boolean;
    ShadowBase: int;

    List: TStringList;

    MonGrid: TBitmap;
    AdvGrid: TBitmap;
    Grid: TBitmap;
    PicturePos: array of TPoint;

    BlockRepaint: Boolean;
    Focuses: array[0..5] of HWnd;
    OnShows: array[0..5] of TNotifyEvent;

    Bmp, BmpSpec: array of TBitmap;  // for Make

    CmdLineSilent: Boolean;
    DontCreateMsgFiles: Boolean;

    function FormsCreated: Boolean;
    procedure LoadIni;
    procedure SaveIni;

     { Save, Load }
    procedure DoLoad(AFileName:string);
    procedure DoLoadH3L(AFileName:string);
    procedure DoSave(AFileName:string);
    procedure Load(AFileName:string);
    function Save:Boolean;
    function SaveAsSel:Boolean;
    function SaveQuery:boolean;
    procedure RecentClick(Sender:TRSRecent; Name:string);
    function ApplyMoveQuery:Boolean;

     { Make }
    function MakeListNodeName(Node:TTreeNode; IncludeShadow:Boolean = true):string;
    function MakeFramesList(IncludeShadow: Boolean = true; ExternalShadow:Boolean = false):TStringList;
    procedure SetMaxShadowColor;
    procedure DoMakeShadow(BmpSpec:TBitmap);
    procedure DoMakeBmpSpec(Node:TTreeNode; OrigBmpSpec:TBitmap;
      var BmpSpec:TBitmap);
    procedure ClearMake;
    procedure BeginMake(SameSize:Boolean);
    procedure UseStandardColors;
    function CheckSamePalette: Boolean;
    procedure ConvertBmps(ColorBox:TColorBoxInfo; ByOne:Boolean = false;
      Compatibility:Boolean = true);
    procedure DoAdd(Lod:TLod; const a:TRSByteArray; const Name:string);
    procedure EndMake;
    procedure MakePictures(ByOne:Boolean);

     { Interface }
    function MakeNodeName(i:int):string;
    function AddToTree(s:string; Shadow:Boolean; it:TTreeNode = nil):TTreeNode;
    function GetDefaultLod(const LodName:string): string;
    procedure ShowShell(List:TRSShellListView; Path:string; const AltPath:string);
    procedure RedrawPicture(Update:Boolean);
    procedure DrawTreeBitmap(AnimIndex: int = -1; it: TTreeNode = nil);
    procedure SetPicture(const s:string; Update:Boolean);
    procedure PaintPicture(Sender:TRSCustomControl; ShadowLine:Boolean = false);
    procedure DoMovePicture(dx, dy: int);
    procedure MakeMovedPicture(Old, New:TBitmap; const p: TPoint; it:TTreeNode);
    procedure SetSaveShadowDialogPath;
    procedure MakeBackup(const Name:string);
    procedure DrawListFile(View:TRSShellListView);
    procedure Refocus(Page:int; DefFocus:HWnd = 0);
    function FindFrame(Level:int = 1):TTreeNode;
    procedure FillLanguage(Items: TStrings; LangDir: string);
    procedure SetLanguage(Combo: TComboBox; Lang: string);
    procedure UpdateLanguage;
    procedure ApplicationEvents1Exception(Sender: TObject; e: Exception);

    property FileName: string read FFileName write SetFileName;
    property ShadowType: int read GetShadowType write SetShadowType;
    property TypeIndex: int read GetTypeIndex write SetTypeIndex;
  end;

  EMakeError = class(Exception)
  end;

var
  Form1: TForm1;

procedure InitColorsBox(Box:TGroupBox; Count:int; var Info:TColorBoxInfo);
function ColorBoxGetTransparent(const Info: TColorBoxInfo): TColor;
procedure ColorBoxUpdateTransparent(var Info: TColorBoxInfo);
procedure SaveColorBoxIni(Ini:TInifile; var Info: TColorBoxInfo; const Name:string);
procedure LoadColorBoxIni(Ini:TInifile; var Info: TColorBoxInfo; const Name:string);
procedure ColorBoxToColors(var Info:TColorBoxInfo; Clear:Boolean = true);
procedure ProcessColorsBox(var Info:TColorBoxInfo; TypeIndex:int);

implementation

uses Unit3;

{$R *.dfm}

const
  SPicBackup = 'DefTool Backup';
  H3Sprite = 'H3sprite.lod';
  H3Bitmap = 'H3bitmap.lod';
  LangDir = 'Language\';
  GameLangDir = 'GameLanguage\';
  TVSI_NOSINGLEEXPAND = $8000;

var
  SSaveQuestion: string = 'Save changes to "%s"?';
  SSaveQuestionUntitled: string = 'Save changes to Untitled?';
  SSaveQuestionCaption: string = 'Def Tool';
  SReopenQuestion: string = 'Are you sure you want to reopen "%s"?';
  SReopenQuestionCaption: string = 'Def Tool';
  SUntitled: string = 'Untitled';
  SWrongPicSize: string = 'All pictures must of the same size';
  SWrongPicSize32: string = 'The size of adventure pictures must be a multiple of 32';
  SSuccessfulMake: string = 'Def file generated successfully';
  SSuccessfulMake8Bit: string = 'Def file generated successfully, palette preserved';
  SNoDefName: string = 'You must specify the Def file name first';
  SNoAutoDefName: string = 'You must save the Def List first or specify the Def file name manually';
  SNoFrames: string = 'You must specify at least one picture';
  SSaveHere: string = 'Save Here';
  SLeaveReposiion: string = 'Would you like to save the changes made to pictures'' positions?';
  SLeaveReposiionCaption: string = 'Def Tool';
  SSaveShadowQuestion: string = 'Are you sure you want to change the shadow in your frames?'#13#10'(Use this to delete contained shadow from the frames. In most of other cases it''s better not to do this)';
  SSaveShadowQuestionCaption: string = 'Def Tool';
  SNoBitmapsPath: string = 'You must specify the path for bitmaps first';
  SSuccessfulBitmapsMake: string = 'Bitmaps generated successfully';
  SWrongShadowSize: string = 'Frames and shadow frames must be of the same size';
  SAutoTransparentHint: string = 'Chosen automatically';

const
  ColorMasks: array[0..9] of int =
    (0, $1111111{-}, $1111001, $11001, $11001,
     $1111, 0, $10001001, $1111111{-}, $1001);
   // ColorMasks: Digits represent colors present from right to left, excluding
   //  transparent color. The last digit represents Player's Colors.

  DefShadowBase = 260;

var
  ColorBox1, ColorBox2: TColorBoxInfo;
  Color5Name: array[Boolean] of string;
  DefColors: array[0..7] of TColor;
  GroupNodes: array of TTreeNode;
  TypeGroups: array[0..9] of TStrings;
  Recent: TRSRecent;
  ChosenDefPath: string;
  Association: TRSFileAssociation;

function PtInControl(const pt:TPoint; c:TControl):boolean;
begin
  Result:= PtInRect(c.BoundsRect, pt);
end;

function AnyControlAtPos(c:TWinControl; const pt:TPoint):TControl;
var i:int;
begin
  Result:=nil;
  for i:=c.ControlCount-1 downto 0 do
    if PtInRect(c.Controls[i].BoundsRect, pt) then
      Result:=c.Controls[i];
end;

procedure InitColorsBox(Box:TGroupBox; Count:int; var Info:TColorBoxInfo);
var
  First: int;
  Step: int;
  Shape: int;
  Check: int;
  i:int; p:TPoint;
begin
  with Form1.CheckColor1 do
  begin
    First:= Top + Height div 2;
    Check:= Left + Width div 2;
  end;

  Shape:= Form1.Shape1.Left + Form1.Shape1.Width div 2;
  Step:= Form1.CheckColor2.Top - Form1.CheckColor1.Top;

  Info.Box:= Box;
  Info.Count:= Count;
  p.X:=Shape;
  p.Y:=First;
  for i:=0 to Count-1 do
  begin
    Info.Shapes[i]:= ptr(AnyControlAtPos(Box, p));
    if Info.Shapes[i] = nil then
      msgz(i);
    Info.Shapes[i].Tag:= int(@Info);
    inc(p.Y, Step);
  end;
  p.X:=Check;
  p.Y:=First;
  for i:=0 to Count-1 do
  begin
    Info.Checks[i]:= ptr(AnyControlAtPos(Box, p));
    if Info.Checks[i] = nil then
      msgz(i, 0);
    inc(p.Y, Step);
  end;
end;

function ColorBoxGetTransparent(const Info: TColorBoxInfo): TColor;
var
  b: TBitmap;
  i, lev: int;
begin
  Result:= Info.Shapes[0].Brush.Color;
  with Info do
  begin
    if Count > 8 then
      lev:= 1
    else
      lev:= 2;

    b:= nil;
    with Form1.TreeView1.Items do
      for i := 0 to Count - 1 do
        if Item[i].Level = lev then
          try
            b:= RSLoadBitmap(string(Item[i].Data));
            if (b.Width > 0) and (b.Height > 0) then
            begin
              Result:= b.Canvas.Pixels[0, 0];
              FreeAndNil(b);
              exit;
            end;
            FreeAndNil(b);
          except
            FreeAndNil(b);
          end;
  end;
end;

procedure ColorBoxUpdateTransparent(var Info: TColorBoxInfo);
begin
  with Info.Shapes[0] do
    if Pen.Style <> psSolid then
      Brush.Color:= ColorBoxGetTransparent(Info);
end;

procedure ProcessColorsBox(var Info:TColorBoxInfo; TypeIndex:int);
var
  //H1Add = 169 - 146;
  Step: int;
  i, h0, h1, h2, Mask, bit:int; b:boolean;
begin
  Step:= Form1.CheckColor2.Top - Form1.CheckColor1.Top;
  Mask:=ColorMasks[TypeIndex];
  with Info do
  begin
    h0:=Shapes[0].Top;
    for i:=1 to Count-1 do
      if Shapes[i].Visible then
        inc(h0, Step);
    h1:=Shapes[0].Top;
    h2:=Checks[0].Top;
    bit:=1;
    for i:=1 to Count-1 do
    begin
      b:= Mask and bit <> 0;
      if b then
      begin
        inc(h1, Step);
        inc(h2, Step);
        Shapes[i].Top:=h1;
        Checks[i].Top:=h2;
      end;
      Shapes[i].Visible:= b;
      Checks[i].Visible:= b;
      bit:=bit shl 4;
    end;
    Checks[5].Caption:= Color5Name[Mask = ColorMasks[3]]; // 3,4
    FullBox.Height:= FullBox.Height + h1 - h0;
    if Shapes[0].Pen.Style <> psSolid then
      Shapes[0].Hint:= SAutoTransparentHint
    else
      Shapes[0].Hint:= '';
  end;
end;

procedure ColorBoxToColors(var Info:TColorBoxInfo; Clear:Boolean = true);
var i:int;
begin
  if Clear then
    RSFillDWord(@SpecColors, 256, -1);
  if Clear then
  begin
    SpecL:=256;
    SpecH:=-2;
  end;

  with Info do
  begin
    ColorBoxUpdateTransparent(Info);
    for i:=0 to 7 do
      if Checks[i].Checked and Checks[i].Visible then
      begin
        SpecColors[i]:= RSSwapColor(Shapes[i].Brush.Color);
        if SpecL>i then  SpecL:=i;
        if SpecH<i then  SpecH:=i;
      end;

    if (Checks[8]<>nil) and Checks[8].Checked and Checks[8].Visible then
      for i:=0 to 31 do
        SpecColors[i + 224]:= RSSwapColor(PlayerColors[i]);
  end;

  if SpecL = 256 then
    SpecL:= -1;
end;

procedure LoadColorBoxIni(Ini:TInifile; var Info: TColorBoxInfo; const Name:string);
const
  Sect = 'Data';
var
  i,j:int; s:string; ps:TRSParsedString;
begin
  with Info do
  begin
     // Defaults
    for i:=0 to 7 do
      Shapes[i].Brush.Color:=DefColors[i];
    if Count = 8 then
      for i:=1 to Count-1 do
        Checks[i].Checked:= true
    else
      for i:=1 to Count-1 do
        Checks[i].Checked:= false;
    Checks[0].Checked:=true;
    CopyMemory(@PlayerColors, @DefPlayerColors, 32*4);

     // Load
    s:= Ini.ReadString(Sect, Name + 'Colors', '');
    ps:= RSParseString(s, ['|']);
    for i:=0 to min(7, RSGetTokensCount(ps, true)-1) do
      if RSVal(RSGetToken(ps, i), j) then
        Shapes[i].Brush.Color:= j;

    Shapes[0].Pen.Style:= psSolid;
    if ini.ReadBool(Sect, Name + 'AutoTransparent', false) then
    begin
      Shapes[0].Pen.Style:= psClear;
      Shapes[0].Brush.Color:= ColorBoxGetTransparent(Info);
    end;

    s:= Ini.ReadString(Sect, Name + 'ColorChecks', '');
    ps:= RSParseString(s, ['|']);
    for i:=0 to min(Count, RSGetTokensCount(ps, true))-1 do
      if RSVal(RSGetToken(ps, i), j) then
        Checks[i].Checked:= j<>0;

    if Count > 8 then
    begin
      s:= Ini.ReadString(Sect, Name + 'PlayerColors', '');
      ps:= RSParseString(s, ['|']);
      for i:=0 to min(31, RSGetTokensCount(ps, true))-1 do
        if RSVal(RSGetToken(ps, i), j) then
          PlayerColors[i]:= j;
      Tolerance:= Ini.ReadInteger(Sect, Name + 'Tolerance', 0);
    end;
  end;
end;

procedure SaveColorBoxIni(Ini:TInifile; var Info: TColorBoxInfo; const Name:string);
const
  Sect = 'Data';
  Bools: array[Boolean] of string = ('0', '1');
var
  i:int; s:string;
begin
  with Info do
  begin
    ini.WriteBool(Sect, Name + 'AutoTransparent', Shapes[0].Pen.Style <> psSolid);

    for i:=0 to 7 do
      s:= s + '$' + IntToHex(Shapes[i].Brush.Color, 6) + '|';
    Ini.WriteString(Sect, Name + 'Colors', s);

    s:='';
    for i:=0 to Count-1 do
      s:= s + Bools[Checks[i].Checked] + '|';
    Ini.WriteString(Sect, Name + 'ColorChecks', s);

    if Count > 8 then
    begin
      s:='';
      for i:=0 to 31 do
        s:= s + '$' + IntToHex(PlayerColors[i], 6) + '|';
      Ini.WriteString(Sect, Name + 'PlayerColors', s);
      Ini.WriteInteger(Sect, Name + 'Tolerance', Tolerance);
    end;
  end;
end;

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WinClassName:='Def Tool Main Form';
end;

procedure TForm1.WMActivate(var Msg: TWMActivate);
begin
  if TabSheet2.Visible and RSShellListView1.NeedRefresh then
    RSShellListView1.RefreshFolder;
  if RSShellListView2.NeedRefresh and RSIsControlVisible(RSShellListView2) then
    RSShellListView2.RefreshFolder;
end;

procedure TForm1.WMHelp(var Msg: TMessage);
begin
  PageControl1.TabIndex:= 5;
end;

procedure TForm1.FormCreate(Sender: TObject);
var i:int;
begin
  RSDebugUseDefaults;
  RSDebugHook;
  Application.OnException:= ApplicationEvents1Exception;
  Randomize;
  RSFixThemesBug;
  RSHookFlatBevels(self);
  AssertErrorProc:=RSAssertErrorHandler;
  HintWindowClass:=TRSSimpleHintWindow;
  RSMenu.Add(PopupMenu1.Items, true, false);
  Recent:=TRSRecent.Create(RecentClick, PopupMenu1.Items, true);
  AppTitle:='Def Tool';
  Application.Title:=AppTitle;

  with TRSShellFile.Create(Application.ExeName) do
    try
      Association:= TRSFileAssociation.Create('.hdl', 'DefTool.hdl',
         'DefTool.Backup', '"' + FullName + '" "%1"', FullName + ',0');
    finally
      Free;
    end;

  InitColorsBox(GroupColors1, 9, ColorBox1);
  ColorBox1.FullBox:=GroupColors1;
  InitColorsBox(GroupColors2, 8, ColorBox2);
  ColorBox2.FullBox:=Panel8;
  for i:=0 to 7 do
    DefColors[i]:=ColorBox1.Shapes[i].Brush.Color;
  for i:=0 to 9 do
    TypeGroups[i]:= GroupsOther.Items;
  TypeGroups[2]:= Groups42.Items;
  TypeGroups[4]:= Groups44.Items;
  TypeGroups[9]:= Groups49.Items;
  Picture:= TBitmap.Create;
  PaintBox1.ControlStyle:= PaintBox1.ControlStyle + [csOpaque];
  PaintBox2.ControlStyle:= PaintBox2.ControlStyle + [csOpaque];
  PaintBox3.ControlStyle:= PaintBox3.ControlStyle + [csOpaque];
  PaintBox4.ControlStyle:= PaintBox4.ControlStyle + [csOpaque];
  PaintBox5.ControlStyle:= PaintBox5.ControlStyle + [csOpaque];
  MemoHelp.DoubleBuffered:= true;

  for i:=0 to PageControl1.PageCount-1 do
    SetClassLong(PageControl1.Pages[i].Handle, GCL_STYLE,
       GetClassLong(PageControl1.Pages[i].Handle, GCL_STYLE) and not (CS_HREDRAW or CS_VREDRAW));

  for i:=0 to ComponentCount-1 do
    with TPanel(Components[i]) do
    begin
      {
      if not InheritsFrom(TControl) then  continue;
      ControlStyle:= ControlStyle - [csParentBackground];
      }
      if not InheritsFrom(TPanel) then  continue;
      FullRepaint:=false;
    end;
  PageControl1.OwnerDraw:= true;
  MemoHelp.WordWrap:= true;

  with RSLanguage.AddSection('[Main Form]', self) do
  begin
    AddItem('SSaveQuestion', SSaveQuestion);
    AddItem('SSaveQuestionUntitled', SSaveQuestionUntitled);
    AddItem('SSaveQuestionCaption', SSaveQuestionCaption);
    AddItem('SReopenQuestion', SReopenQuestion);
    AddItem('SReopenQuestionCaption', SReopenQuestionCaption);
    AddItem('SUntitled', SUntitled);
    AddItem('SWrongPicSize', SWrongPicSize);
    AddItem('SWrongPicSize32', SWrongPicSize32);
    AddItem('SSuccessfulMake', SSuccessfulMake);
    AddItem('SSuccessfulMake8Bit', SSuccessfulMake8Bit);
    AddItem('SNoDefName', SNoDefName);
    AddItem('SNoAutoDefName', SNoAutoDefName);
    AddItem('SNoFrames', SNoFrames);
    AddItem('SSaveHere', SSaveHere);
    AddItem('SLeaveReposiion', SLeaveReposiion);
    AddItem('SLeaveReposiionCaption', SLeaveReposiionCaption);
    AddItem('SSaveShadowQuestion', SSaveShadowQuestion);
    AddItem('SSaveShadowQuestionCaption', SSaveShadowQuestionCaption);
    AddItem('SNoBitmapsPath', SNoBitmapsPath);
    AddItem('SSuccessfulBitmapsMake', SSuccessfulBitmapsMake);
    AddItem('SWrongShadowSize', SWrongShadowSize);
    AddItem('SAutoTransparentHint', SAutoTransparentHint);
  end;

  for i:=0 to 5 do
  begin
    OnShows[i]:= PageControl1.Pages[i].OnShow;
    PageControl1.Pages[i].OnShow:= nil;
  end;

  FillLanguage(ComboLang.Items, AppPath + LangDir);
  FillLanguage(ComboGameLang.Items, AppPath + GameLangDir);

{
  for i:=0 to PageControl1.PageCount-1 do
    PageControl1.Pages[i].Parent:=self;
  TForm1(PageControl1).DestroyHandle;
}
end;

function TForm1.FormsCreated: Boolean;
var
  fname, s: string;
  i: int;
begin
//  RSSaveTextFile(AppPath + 'Language.txt', RSLanguage.MakeLanguage);
  LoadIni;

  fname:= '';
  for i := 1 to MaxInt do
  begin
    s:= ParamStr(i);
    if s = '' then  break;
    if s[1] <> '/' then
      fname:= s
    else if s = '/g' then
      CmdLineSilent:= true;
  end;

  if fname <> '' then
  begin
    Load(fname);
    if CmdLineSilent then
      SpeedButtonMakeClick(nil);
  end else
    RSSpeedButton11Click(nil);

  if not CmdLineSilent then
    RSSetFocus(TreeView1);
  Result:= not CmdLineSilent;
end;

procedure TForm1.Shape1Click(Sender: TObject);
begin
  with ColorDialog1, TShape(Sender) do
  begin
    if (Sender = PColorBoxInfo(Tag).Shapes[0]) and (Pen.Style = psSolid) then
    begin
      Pen.Style:= psClear;
      Brush.Color:= ColorBoxGetTransparent(PColorBoxInfo(Tag)^);
      Hint:= SAutoTransparentHint;
      RSErrorHint(TControl(Sender), SAutoTransparentHint, 0, true, 0);
      WasChanged:= true;
      exit;
    end;
    Hint:= '';
    Color:=Brush.Color;
    if not Execute then exit;
    Brush.Color:=Color;
    Pen.Style:= psSolid;
    WasChanged:=true;
  end;
end;

procedure TForm1.ComboTypeSelect(Sender: TObject);
var i,j:int; Groups:TStrings; Last:TTreeNode;
begin
  WasChanged:=true;
  i:= TypeIndex;
  ProcessColorsBox(ColorBox1, i);
  ProcessColorsBox(ColorBox2, i);
  if (i = 2) xor RSSpeedButton22.Visible then  // Monster
  begin
    RSSpeedButton22.Visible:= i = 2;
    if i = 2 then
      Panel9.Left:= Panel9.Left + 24
    else
      Panel9.Left:= Panel9.Left - 24;
  end;
  TabSheet3.TabVisible:= i in [2, 3, 4, 9];
  CheckMsk.Visible:= i in [3, 4]; // Adventure Object, Hero
  RSTimer1.Enabled:= not (i in [5, 6, 7]);
  if i in [0, 2, 9] then
    RSTimer1.Interval:= 100
  else
    RSTimer1.Interval:= 180;

  Groups:=TypeGroups[i];
  for i:=length(GroupNodes)-1 downto Groups.Count do
    if (GroupNodes[i]<>nil) and (GroupNodes[i].Count=0) then
    begin
      GroupNodes[i].Delete;
      GroupNodes[i]:=nil;
    end;
  SetLength(GroupNodes, max(length(GroupNodes), Groups.Count));

  j:=Groups.Count;
  Last:=nil;
  for i:=high(GroupNodes) downto 0 do
  begin
    if (GroupNodes[i]=nil) and (i<j) then
      if Last<>nil then
        GroupNodes[i]:=TreeView1.Items.InsertObject(Last, '', ptr(i))
      else
        GroupNodes[i]:=TreeView1.Items.AddObject(nil, '', ptr(i));
    if GroupNodes[i]<>nil then
      Last:=GroupNodes[i];
  end;

  for i:=0 to length(GroupNodes)-1 do
  begin
    if GroupNodes[i]=nil then
      continue;
    GroupNodes[i].Text:= MakeNodeName(i);
  end;
  TreeView1.Perform(WM_VSCROLL, SB_TOP, 0);
end;

procedure TForm1.RSSpeedButton9Click(Sender: TObject);
begin
  Edit5.Text:= RSIntToStr(random(36*36*36), 36, #0, false, 3);
end;

procedure TForm1.RSTimer1Timer(Sender: TObject);
var
  it: TTreeNode;
begin
  if GetForegroundWindow <> Handle then  exit;
  it:= TreeView1.Selected;
  if (it = nil) or (it.Level <> 0) or (it.Count = 0) then  exit;
  if LastAnimIndex + 1 >= it.Count then
    LastAnimIndex:= -1;
  DrawTreeBitmap(LastAnimIndex + 1);
end;

procedure GradientLine(c:TCanvas; x1, x2, y:int; Middle, Side:TColor);
var r:TRect;
begin
  r:=Rect(x1, y, (x1+x2) div 2, y+1);
  RSGradientH(c, r, Side, Middle);
  r.Left:=r.Right;
  r.Right:=x2;
  RSGradientH(c, r, Middle, Side);
end;

procedure TForm1.PageControl1DrawTab(Control: TCustomTabControl;
  TabIndex: Integer; const ARect: TRect; Active: Boolean);
const
  Flags = DT_CENTER	or DT_SINGLELINE or DT_VCENTER;
  ActiveColor = $408CFF; //$ddbb00;
  Side = 0;

var
  s:string; r,r1:TRect; c:TCanvas;
  i:int;
begin
  s:=PageControl1.Tabs[TabIndex].Caption;
  c:=PageControl1.Canvas;
  r:=ARect;
  inc(r.Top, 2);
  if Active then
  begin
    inc(r.Left, 2);
    dec(r.Right, 2);
  end else
    inc(r.Bottom,2);

  if Active then
    i:=RSMixColors(clBtnHighlight, clBtnFace, 170)
  else
    i:=RSMixColors(clBtnHighlight, clBtnFace, 135);

  RSGradientV(c, r, i, clBtnFace);

  {
  if Active then
    GradientLine(c, r.Left + Side, r.Right - Side, r.Top,
       ActiveColor, RSMixColorsRGBNorm(ActiveColor, i, 30));
  {}
  if not Active then
  begin
    with r do
      r1:=Rect(Left, Bottom-1, Right, Bottom);
    RSGradientH(c, r1,
                RSMixColors(clBtnFace, clBtnShadow, 160),
                RSMixColors(clBtnFace, clBtnShadow, 120));
{
    if PageControl1.ActivePageIndex = TabIndex+1 then
    begin
      with r do
        r1:=Rect(Right-1, Top, Right, Bottom);
      RSGradientV(c, r1,
                  RSMixColorsNorm(clBtnFace, clBtnShadow, 160),
                  RSMixColorsNorm(clBtnFace, clBtnShadow, 120));
    end;
}
  end else
  begin
    {
    with r do
      r1:=Rect(Left, Top, Right-1, Top+1);
    RSGradientH(c, r1,
                clBtnHighlight,
                clBtnHighlight);
    }
    {
    with r do
      r1:=Rect(Right-1, Top, Right, Bottom);
    RSGradientV(c, r1,
                clBtnHighlight,
                clBtnHighlight);
    {}
  end;

  c.Brush.Style:= bsClear;
  c.Font:= PageControl1.Font;
{
  if not Active then
    c.Font.Color:=RSMixColorsNorm(c.Font.Color, clBtnFace, 190);
}
  if Active then
    c.Font.Color:= RSMixColors(clBtnShadow, clBtnFace, 110);

  DrawText(c.Handle, ptr(s), -1, r, Flags);
  if Active then
  begin
    dec(r.Bottom,2);
    inc(r.Left, 2);
    DrawText(c.Handle, ptr(s), -1, r, Flags);
    dec(r.Left, 2);
    dec(r.Top, 2);
    c.Font.Color:=PageControl1.Font.Color;
    DrawText(c.Handle, ptr(s), -1, r, Flags);
  end;
end;

var
  ReadStringBuffer: array[0..65535] of char;

function ReadLongString(ini: TIniFile; Sect, Ident, Default: string): string;
begin
  SetString(Result, ReadStringBuffer, GetPrivateProfileString(PChar(Sect),
    PChar(Ident), PChar(Default), ReadStringBuffer, SizeOf(ReadStringBuffer), PChar(ini.FileName)));
end;

procedure TForm1.DoLoad(AFileName:string);
const
  Sect = 'Data';
var
  i, j:int; s, ss:string; ps:TRSParsedString; Ini:TIniFile;
begin
  ps:=nil;
  Ini:= TIniFile.Create(AFileName);
  with Ini do
    try
      BlockRepaint:= true;

      TreeView1.Selected:= nil;
      TreeView1.Items.Clear;
      GroupNodes:=nil;
      SetPicture('', false);

      SetCurrentDir(ExtractFilePath(AFileName));
      i:=ReadInteger(Sect, 'Groups Number', 0);
      SetLength(GroupNodes, i);
      for i:=0 to i-1 do
      begin
        ss:= ReadLongString(Ini, Sect, 'Group'+IntToStr(i), '');
        if ss='' then  continue;
        ps:= RSParseString(ss, ['|']);
        GroupNodes[i]:=TreeView1.Items.AddObject(nil, '', ptr(i));
        for j:=0 to RSGetTokensCount(ps, true)-1 do
        begin
          s:=RSGetToken(ps, j);
          s:=ExpandFileName(s);
          TreeView1.Items.AddChildObject(GroupNodes[i], ExtractFileName(s), ptr(s));
          ptr(s):=nil;
        end;
        GroupNodes[i].Expand(false);

        ss:= ReadLongString(Ini, Sect, 'Shadow'+IntToStr(i), '');
        if ss='' then  continue;
        ps:= RSParseString(ss, ['|']);
        for j:=0 to min(RSGetTokensCount(ps, true), GroupNodes[i].Count)-1 do
        begin
          s:=RSGetToken(ps, j);
          if s='' then  continue;
          s:=ExpandFileName(s);
          TreeView1.Items.AddChildObject(GroupNodes[i].Item[j], ExtractFileName(s), ptr(s));
          ptr(s):=nil;
        end;
      end;

      LoadColorBoxIni(Ini, ColorBox1, 'ColorsBox.');
      LoadColorBoxIni(Ini, ColorBox2, 'ShadowColorsBox.');

      TypeIndex:= ReadInteger(Sect, 'Type', 2);
      ComboTypeSelect(nil);

      CheckDefPath.Checked:= ReadBool(Sect, 'Def Path Check', false);
      CheckLod.Checked:= ReadBool(Sect, 'Lod Path Check', false);

      ChosenDefPath:= ReadString(Sect, 'Def Path', '');

      EditLod.Text:= ReadString(Sect, 'Lod Path', EditLodDefault.Text);
      if EditLod.Text = '' then
        EditLod.Text:= GetDefaultLod(H3Sprite);

      CheckBitmaps.Checked:= ReadBool(Sect, 'Bitmaps Check', false);
      CheckBitmapsLod.Checked:= ReadBool(Sect, 'Bitmaps Lod Check', false);
      EditBitmapsPath.Text:= ReadString(Sect, 'Bitmaps Path', '');
      EditBitmapsLod.Text:= ReadString(Sect, 'Bitmaps Lod Path', EditLodBitmaps.Text);
      if EditBitmapsLod.Text = '' then
        EditBitmapsLod.Text:= GetDefaultLod(H3Bitmap);

      CheckDefPathClick(nil);
      CheckLodClick(nil);
      CheckBitmapsClick(nil);

      CheckStColors.Checked:= ReadBool(Sect, 'Standard Special Colors', false);
      CheckMsk.Checked:= ReadBool(Sect, 'Generate Mask Files', false);

      if EditPicsExtension.Text <> '' then
        Edit5.Text:= EditPicsExtension.Text
      else
        RSSpeedButton9Click(nil);
      Edit5.Text:= ReadString(Sect, 'Pictures Extension', Edit5.Text);

      FramesPath:= ReadString(Sect, 'Frames Dir', FramesPath);
      ShadowPath:= ReadString(Sect, 'Shadow Dir', ShadowPath);

      RSSpeedButton22.Down:= ReadBool(Sect, 'Generate Selection', true);
      RSSpeedButton1.Down:= ReadBool(Sect, 'Delete Contained Shadow', false);
      SpeedButtonFaintShadow.Down:= ReadBool(Sect, 'Faint Shadow', false);
      ShadowType:= ReadInteger(Sect, 'Shadow Type', 0);
      ShadowBase:= ReadInteger(Sect, 'Shadow Base', MaxInt);
      ShadowSet:= ShadowBase<>MaxInt;
      RSSpinEdit1.Value:= ReadInteger(Sect, 'Shadow Shift X', 0);
      RSSpinEdit2.Value:= ReadInteger(Sect, 'Shadow Shift Y', 0);

    finally
      BlockRepaint:= false;
      Free;
    end;
end;

procedure TForm1.DoSave(AFileName:string);
const
  Sect = 'Data';
var i, j:int; s, s1, s2:string; p:ptr; HasShadow:Boolean; Ini:TIniFile;
begin
  RSCreateDir(ExtractFilePath(AFileName));
  Ini:= TIniFile.Create(AFileName);
  with Ini do
    try
      WriteInteger(Sect, 'Type', TypeIndex);
      WriteString(Sect,  'Pictures Extension', Edit5.Text);
      WriteBool(Sect, 'Def Path Check', CheckDefPath.Checked);
      WriteBool(Sect, 'Lod Path Check', CheckLod.Checked);
      if EditDefPath.Enabled then
        WriteString(Sect, 'Def Path', EditDefPath.Text)
      else
        WriteString(Sect, 'Def Path', ChosenDefPath);
      s:= EditLod.Text;
      if s = GetDefaultLod(H3Sprite) then
        s:= '';
      WriteString(Sect, 'Lod Path', s);

      WriteBool(Sect, 'Bitmaps Check', CheckBitmaps.Checked);
      WriteBool(Sect, 'Bitmaps Lod Check', CheckBitmapsLod.Checked);
      WriteString(Sect, 'Bitmaps Path', EditBitmapsPath.Text);
      s:= EditBitmapsLod.Text;
      if s = GetDefaultLod(H3Bitmap) then
        s:= '';
      WriteString(Sect, 'Bitmaps Lod Path', EditBitmapsLod.Text);

      WriteBool(Sect, 'Standard Special Colors', CheckStColors.Checked);
      WriteBool(Sect, 'Generate Mask Files', CheckMsk.Checked);
      WriteString(Sect, 'Frames Dir', FramesPath);
      WriteString(Sect, 'Shadow Dir', ShadowPath);
      WriteBool(Sect, 'Generate Selection', RSSpeedButton22.Down);
      WriteBool(Sect, 'Delete Contained Shadow', RSSpeedButton1.Down);
      WriteBool(Sect, 'Faint Shadow', SpeedButtonFaintShadow.Down);
      WriteInteger(Sect, 'Shadow Type', ShadowType);
      if ShadowSet then
        WriteInteger(Sect, 'Shadow Base', ShadowBase);
      WriteInteger(Sect, 'Shadow Shift X', RSSpinEdit1.Value);
      WriteInteger(Sect, 'Shadow Shift Y', RSSpinEdit2.Value);

      SaveColorBoxIni(Ini, ColorBox1, 'ColorsBox.');
      SaveColorBoxIni(Ini, ColorBox2, 'ShadowColorsBox.');

      s2:= ExtractFilePath(AFileName);
      i:= length(GroupNodes) - 1;
      while (i>=0) and (GroupNodes[i]=nil) do  dec(i);
      WriteInteger(Sect, 'Groups Number', i+1);
      for i:=0 to length(GroupNodes) - 1 do
      begin
        s:='';
        HasShadow:=false;
        if GroupNodes[i]<>nil then
          for j:=0 to GroupNodes[i].Count-1 do
          begin
            if GroupNodes[i][j].Count>0 then  HasShadow:=true;
            p:= GroupNodes[i][j].Data;

            s1:= ExtractRelativePath(s2, string(p));
            s:= s + s1 + '|';
          end;
          
        //WriteString(Sect, 'Group'+IntToStr(i), s);
        WritePrivateProfileString(Sect, ptr('Group'+IntToStr(i)), ptr(s), ptr(AFileName));

        s:='';
        if HasShadow then
          for j:=0 to GroupNodes[i].Count-1 do
          begin
            if GroupNodes[i][j].Count > 0 then
            begin
              p:= GroupNodes[i][j][0].Data;
              s1:= ExtractRelativePath(s2, string(p));
            end else
              s1:= '';
              
            s:= s + s1 + '|';
          end;
        //WriteString(Sect, 'Shadow'+IntToStr(i), s);
        WritePrivateProfileString(Sect, ptr('Shadow'+IntToStr(i)), ptr(s), ptr(AFileName));
      end;

    finally
      Free;
    end;
end;

procedure TForm1.DoLoadH3L(AFileName:string);
const
  DefMon0: array[0..20] of byte = (0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21); // Zealot
  DefMon1: array[0..17] of byte = (0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 20, 21); // Titan
  DefMon2: array[0..14] of byte = (0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 20, 21); // Golem
  DefMon3: array[0..17] of byte = (0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 17, 18, 19, 20, 21); // Green Dragon

var
  MonGroups: array of byte;
  UsedGroups: array of Boolean;

  function CheckGroup(i:int):Boolean;
  begin
    if i>255 then
    begin
      Result:=false;
      exit;
    end;
    if i>=length(UsedGroups) then
      SetLength(UsedGroups, i+1);
    Result:= not UsedGroups[i];
    UsedGroups[i]:=true;
  end;

  procedure UseMonster(const a: array of byte);
  begin
    SetLength(MonGroups, length(a));
    CopyMemory(ptr(MonGroups), @a[0], length(a));
  end;

var
  ps, ps1: TRSParsedString;
  NewFormat: Boolean;
  ss, s, s1: string;
  i, j, k: int;
  Node: TTreeNode;
  p: PChar;
begin
  ss:=RSLoadTextFile(AFileName);
  DoLoad(ChangeFileExt(Application.ExeName, '.ini'));
  ps:=RSParseString(ss, [#13#10, #10]);
  ps1:=nil;

  SetCurrentDir(ExtractFilePath(AFileName));
  NewFormat:= (int(ps[1])-int(ps[0])<4) and (RSGetTokensCount(ps)>=15);
  if NewFormat then
  begin
    if RSVal(RSGetToken(ps, 1), i) then
      TypeIndex:= 9 - i;
    s:=RSGetToken(ps, 2);
    if s<>'Temp.def' then
    begin
      EditDefPath.Text:= ExpandFileName(s);
      CheckDefPath.Checked:= true;
      CheckDefPathClick(nil);
    end;
    if SameText(RSGetToken(ps, 3), 'TRUE') then
      ShadowType:=1;
    if SameText(RSGetToken(ps, 4), 'FALSE') then
      RSSpeedButton22.Down:=false;

    if (TypeIndex = 2) and RSVal(RSGetToken(ps, 9), i) then
      case i of
        0:  UseMonster(DefMon0);
        2..5:  UseMonster(DefMon1);
        7..10:  UseMonster(DefMon2);
        12:  UseMonster(DefMon3);
      end;

    s:=RSGetTokens(ps, 15);
    ss:=s;
  end;
  if TypeIndex = 2 then
    CheckGroup(6); // Unused Group

  ps:=RSParseString(ss, ['+'#13#10, '+'#10]);

  try
    for i:=0 to RSGetTokensCount(ps, true)-1 do
    begin
      p:=ps[i*2+1];
      repeat
        dec(p);
      until RSCharToInt(p^, 10)<0;

      if (p^=' ') and ((p-1)^=' ') then
      begin
        j:=RSStrToIntEx(p+1, nil);
        ps[i*2+1]:=ptr(p-1);
      end else
        j:=0;

      if length(MonGroups)>i then
        j:=MonGroups[i]
      else
        if not CheckGroup(j) then
        begin
          if j>255 then j:=0;
          repeat
            inc(j);
          until CheckGroup(j) or (j>255);
          if j>255 then  break;
        end;

      if j>=length(GroupNodes) then
      begin
        SetLength(GroupNodes, j+1);
        //TreeView1.Items.AddChildObject(GroupNodes[i].Item[j], ExtractFileName(s), nil);
        GroupNodes[j]:=TreeView1.Items.AddObject(nil, '', ptr(j));
      end;

      ps1:=RSParseToken(ps, i, [#13#10, #10]);
      for k:=0 to RSGetTokensCount(ps1, true)-1 do
      begin
        s:=RSGetToken(ps1, k);
        s1:=ExpandFileName(s);
        TreeView1.Items.AddChildObject(GroupNodes[j], ExtractFileName(s), ptr(s1));
        ptr(s1):=nil;
      end;
      GroupNodes[j].Expand(false);
    end;
  finally
    BlockRepaint:= false;
  end;

  Node:= FindFrame(1);
  if Node<>nil then
    FramesPath:= ExtractFilePath(string(Node.Data))
  else
    FramesPath:= ExtractFilePath(AFileName);

  Node:= FindFrame(2);
  if Node<>nil then
    ShadowPath:= ExtractFilePath(string(Node.Data))
  else
    ShadowPath:= FramesPath;

  ComboTypeSelect(nil);
end;

procedure TForm1.ComboGameLangSelect(Sender: TObject);
begin
  UpdateLanguage;
end;

procedure TForm1.ComboLangSelect(Sender: TObject);
begin
  UpdateLanguage;
end;

procedure TForm1.ComboTypeDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  with TComboBox(Control) do
    RSPaintList(Control, Canvas, Items[Index], Rect, State);
end;

function TForm1.AddToTree(s:string; Shadow:Boolean; it:TTreeNode = nil):TTreeNode;

  function GetShadowNode(it:TTreeNode):TTreeNode;
  var i,j:int;
  begin
    i:=0;
    j:=0;
    if it <> nil then
      case it.Level of
        0:
          i:= int(it.Data);
        1:
        begin
          i:= int(it.Parent.Data);
          j:= it.Parent.IndexOf(it);
        end;
        2:
        begin
          it:=it.Parent;
          i:= int(it.Parent.Data);
          j:= it.Parent.IndexOf(it);
        end;
      end;
    while i < length(GroupNodes) do
    begin
      if GroupNodes[i]<>nil then
        with GroupNodes[i] do
          for j:=j to Count-1 do
            if Item[j].Count = 0 then
            begin
              Result:=Item[j];
              exit;
            end;

      j:=0;
      inc(i);
    end;
    Result:= nil;
  end;

var
  it1:TTreeNode; s1:string;
  ColorBox: PColorBoxInfo;
  AddFirst: Boolean;
  i, lev: int;
begin
  // Chack is auto transparent color needs an update
  if Shadow then
  begin
    ColorBox:= @ColorBox2;
    lev:= 2;
  end else
  begin
    ColorBox:= @ColorBox1;
    lev:= 1;
  end;

  with TreeView1.Items do
    if ColorBox.Shapes[0].Pen.Style <> psSolid then
    begin
      i:= Count;
      repeat
        dec(i);
      until (i < 0) or (Item[i].Level = lev);
      if i >= 0 then
        ColorBox:= nil;
    end else
      ColorBox:= nil;

  // Add item
  Result:=nil;
  if it = nil then
    it:=TreeView1.Selected;
  it1:=nil;
  AddFirst:= false;
  if Shadow then
  begin
    it:= GetShadowNode(it);
    if it = nil then  exit;
  end else
    if it = nil then
      if TreeView1.Items.Count > 0 then
        it:= TreeView1.Items[0]
      else
        exit
    else
      if it.Level>0 then
      begin
        while it.Level>1 do
          it:= it.Parent;
        it1:= it.getNextSibling;
        it:= it.Parent;
      end else
        AddFirst:= true;

  WasChanged:=true;
  s1:=s;
  s:=ExtractFileName(s);
  if it1 = nil then
    if AddFirst then
      Result:= TreeView1.Items.AddChildObjectFirst(it, s, ptr(s1))
    else
      Result:= TreeView1.Items.AddChildObject(it, s, ptr(s1))
  else
    Result:= TreeView1.Items.InsertObject(it1, s, ptr(s1));
  ptr(s1):=nil;
  if Shadow then
    TreeView1.Select(it)
  else
    TreeView1.Select(Result);

  if ColorBox <> nil then
    ColorBoxUpdateTransparent(ColorBox^);
end;

procedure TForm1.RSSpeedButton18Click(Sender: TObject);
begin
  WasChanged:=true;
  if Panel6.Visible then
    TreeView1.SetFocus;
  ShadowType:= 0;
  DrawTreeBitmap;
end;

procedure TForm1.RSSpeedButton19Click(Sender: TObject);
begin
  WasChanged:=true;
  if Panel6.Visible then
    TreeView1.SetFocus;
  ShadowType:= 1;
  DrawTreeBitmap;
end;

procedure TForm1.RSSpeedButton20Click(Sender: TObject);
begin
  if Panel6.Visible then exit;
  WasChanged:=true;
  ShadowType:= 2;
  ShowShell(RSShellListView2, ShadowPath, FramesPath);
  RSShellListView2.SetFocus;
end;

procedure TForm1.Load(AFileName: string);
begin
  if SameText(ExtractFileExt(AFileName), '.h3l') then
  begin
    DoLoadH3L(AFileName);
    if not CmdLineSilent then
      Recent.StoreLast;
    FileChosen:= false;
    FileName:= ChangeFileExt(AFileName, '.hdl');
    WasChanged:= false;
  end else
  begin
    if not FileExists(AFileName) then
    begin
      if not CmdLineSilent then
        Recent.Delete(AFileName);
      exit;
    end;
    DoLoad(AFileName);
    if not CmdLineSilent then
      Recent.Add(AFileName);
    FileChosen:= true;
    FileName:= AFileName;
    CheckDefPathClick(nil);
    WasChanged:= false;
  end;
  if not CmdLineSilent then
    DrawTreeBitmap;
end;

function TForm1.Save:Boolean;
begin
  Result:= FileChosen or SaveAsSel;
  if not Result then  exit;
  Recent.Add(FileName);
  DoSave(FileName);
  FileName:= FileName;
  WasChanged:=false;
end;

function TForm1.SaveAsSel: Boolean;
begin
  if FileName = '' then
    if (RSShellListView1.Root<>nil) and RSShellListView1.Root.IsFileSystem then
      SaveDialog1.FileName:= RSShellListView1.Path+'\Temp.hdl'
    else
      if (RSShellListView2.Root<>nil) and RSShellListView1.Root.IsFileSystem then
        SaveDialog1.FileName:= RSShellListView2.Path+'\Temp.hdl'
      else
        SaveDialog1.FileName:=''
  else
    SaveDialog1.FileName:= FileName;
  Result:= SaveDialog1.Execute;
  if Result then
    FileName:= SaveDialog1.FileName;
  if not FileChosen and (FindFrame = nil) then
  begin
    FramesPath:= ExtractFilePath(FileName);
    ShadowPath:= FramesPath;
  end;
  FileChosen:= Result;
end;

function TForm1.SaveQuery: boolean;
var s:string;
begin
  Result:= true;
  if not WasChanged or (FindFrame = nil) then  exit;

  if FileChosen then
    s:=Format(SSaveQuestion, [ExtractFileName(FileName)])
  else
    s:=SSaveQuestionUntitled;

  case RSMessageBox(Handle, s, SSaveQuestionCaption,
                     MB_ICONQUESTION or MB_YESNOCANCEL) of
    mrYes:  Result:= Save;
    mrCancel:  Result:= false;
  end;
end;

procedure TForm1.RSSpeedButton11Click(Sender: TObject);
begin
  if SaveQuery then
  begin
    Recent.StoreLast;
    DoLoad(ChangeFileExt(Application.ExeName, '.ini'));
    FileChosen:=false;
    FileName:= ExtractFilePath(FileName);
    if FileName<>'' then
      FileName:= FileName + 'Temp.hdl';
    WasChanged:=false;
    DrawTreeBitmap;
  end;
end;

procedure TForm1.RSSpeedButton12Click(Sender: TObject);
begin
  OpenDialog1.FileName:= '';
  OpenDialog1.InitialDir:= ExtractFilePath(FileName);
  if not OpenDialog1.Execute then  exit;
  if FileChosen and (OpenDialog1.FileName = FileName) then
  begin
    if RSMessageBox(Handle, Format(SReopenQuestion,[ExtractFileName(fileName)]),
         SReopenQuestionCaption, MB_ICONQUESTION or MB_YESNO) <> mrYes then
      exit;
  end else
    if not SaveQuery then exit;
  Load(OpenDialog1.FileName);
end;

procedure TForm1.RSSpeedButton13Click(Sender: TObject);
begin
  Save;
end;

procedure TForm1.RSSpeedButton14Click(Sender: TObject);
begin
  if SaveAsSel then
    Save;
end;

procedure TForm1.RecentClick(Sender: TRSRecent; Name: string);
begin
  if SaveQuery then
    Load(Name);
end;

function TForm1.GetDefaultLod(const LodName:string): string;
const
  WogKey = 'SOFTWARE\New Life of Heroes\Heroes of Might and Magic III\3.5';
  H3Key = 'SOFTWARE\New World Computing\Heroes of Might and Magic® III\1.0';
begin
  Result:= '';
  with TRSRegistry.Create(KEY_READ) do
    try
      RootKey:=HKEY_LOCAL_MACHINE;
      if OpenKeyReadOnly(WogKey) then
        Read('AppPath', Result);
      if (Result='') and OpenKeyReadOnly(H3Key) then
        Read('AppPath', Result);
    finally
      Free;
    end;

  if Result<>'' then
    Result:= IncludeTrailingPathDelimiter(Result) + 'Data\' + LodName;
end;

procedure TForm1.WasChangedChange(Sender: TObject);
begin
  WasChanged:=true;
end;

procedure TForm1.SetFileName(v:string);
begin
  FFileName:=v;
  if not CheckDefPath.Checked then
    if FileChosen then
      EditDefPath.Text:= ChangeFileExt(v, '.def')
    else
      EditDefPath.Text:= '';

  if CheckBitmaps.Checked and (EditBitmapsPath.Text = '') and FileChosen then
    EditBitmapsPath.Text:= ExtractFilePath(FileName) + 'Ready\';

  if v = '' then
    v:= SUntitled
  else
    v:= ExtractFileName(v);
  Caption:= v + ' - ' + AppTitle;
end;

procedure TForm1.SetLanguage(Combo: TComboBox; Lang: string);
var i: int;
begin
  i:= Combo.Items.IndexOf(Lang);
  if i < 0 then
    i:= Combo.Items.IndexOf('English');
  Combo.ItemIndex:= i;  
end;

procedure TForm1.CheckDefPathClick(Sender: TObject);
var b:Boolean;
begin
  b:=CheckDefPath.Checked;
  EditDefPath.Enabled:=b;
  SpeedButtonDefPath.Enabled:=b;
  WasChanged:= true;
  with EditDefPath do
    if not Enabled or (ChosenDefPath = '') then
    begin
      if not Enabled then
        ChosenDefPath:= Text;
      if FileChosen then
        Text:= ChangeFileExt(FileName, '.def')
      else
        Text:= ''
    end else
      Text:= ChosenDefPath;
end;

procedure TForm1.CheckLodClick(Sender: TObject);
var b:Boolean;
begin
  b:=CheckLod.Checked;
  EditLod.Enabled:=b;
  SpeedButtonLod.Enabled:=b;
  WasChanged:= true;
end;

function TForm1.CheckSamePalette: Boolean;
var
  pal1: array[-1..255] of int;
  pal2: array[0..255] of int;
  NeedChange: Boolean;
  n: uint;
  i: int;
begin
  Result:= false;
  if length(Bmp) < 1 then  exit;
  for i := 0 to length(Bmp) - 1 do
    if RSGetPixelFormat(Bmp[i]) <> pf8bit then
      exit;

  n:= GetPaletteEntries(Bmp[0].Palette, 0, 256, ptr(@pal1[0])^);
  if n = 0 then  exit;
  for i := SpecL to min(n - 1, SpecH) do
    if (SpecColors[i] >= 0) and (RSSwapColor(pal1[i] and $ffffff) <> SpecColors[i]) then
      exit;

  for i := 1 to high(Bmp) do
    if (GetPaletteEntries(Bmp[i].Palette, 0, 256, pal2) <> n) or
      not CompareMem(@pal1, @pal2, n*SizeOf(TPaletteEntry)) then
        exit;

  Result:= true;

  if CheckStColors.Checked then  // change palettes of all bitmaps
  begin
    UseStandardColors;
    NeedChange:= false;
    for i := SpecL to min(n - 1, SpecH) do
      if (SpecColors[i] >= 0) and (RSSwapColor(pal1[i] and $ffffff) <> SpecColors[i]) then
      begin
        pal1[i]:= RSSwapColor(SpecColors[i]);
        NeedChange:= true;
      end;

    if NeedChange then
      for i := 0 to high(Bmp) do
        Bmp[i].Palette:= CreatePalette(PLogPalette(@pal1)^);
  end;
end;

procedure TForm1.OpenDialog1TypeChange(Sender: TObject);
begin
  with OpenDialog1 do
    if FilterIndex = 3 then
      DefaultExt:='.h3l'
    else
      DefaultExt:='.hdl';
end;

function TForm1.GetShadowType:int;
begin
  if RSSpeedButton18.Down then
    Result:= 0
  else
    if RSSpeedButton19.Down then
      Result:= 1
    else
      Result:= 2;
end;

function TForm1.GetTypeIndex: int;
begin
  Result:= ComboType.ItemIndex;
  if Result > 0 then  inc(Result);
  if Result > 7 then  inc(Result);
end;

procedure TForm1.HookDragWindow;
var
  ObjInst: ptr;
begin
  DragHWnd:= GetCapture;
  ObjInst:= Classes.MakeObjectInstance(DragWndProc);
  if OldDragWndProc <> nil then
    Classes.FreeObjectInstance(OldDragWndProc);
  OldDragWndProc:= ptr(SetWindowLong(DragHWnd, GWL_WNDPROC, int(ObjInst)));
  if ptr(GetWindowLong(DragHWnd, GWL_WNDPROC)) <> ObjInst then
    Classes.FreeObjectInstance(ObjInst);
end;

procedure TForm1.SetShadowType(v:int);
begin
  case v of
    0: RSSpeedButton18.Down:=true;
    1: RSSpeedButton19.Down:=true;
    2: RSSpeedButton20.Down:=true;
  end;
  if v = 2 then
  begin
    Panel9.Hide;
    Panel6.Visible:= true;
    PaintBox4.Hide;
  end else
  begin
    PaintBox4.Visible:= true;
    Panel6.Hide;
    Panel9.Hide;
  end;
end;

procedure TForm1.SetTypeIndex(v: int);
begin
  if v > 7 then  dec(v);
  if v > 0 then  dec(v);
  if v < 0 then  v:= 1;
  ComboType.ItemIndex:= v;
end;

procedure TForm1.TabSheet2Show(Sender: TObject);
begin
  Refocus(1, RSShellListView1.Handle);

  ShowShell(RSShellListView1, FramesPath, ShadowPath);
end;

procedure TForm1.RSShellListView1CanRefresh(Sender: TObject;
  var Handled: Boolean);
begin
  Handled:=true;
end;

procedure TForm1.TabSheet3Show(Sender: TObject);
begin
  if RSSpeedButton20.Down then
  begin
    Refocus(2, RSShellListView2.Handle);
    ShowShell(RSShellListView2, ShadowPath, FramesPath);
  end else
  begin
    Refocus(2);
    DrawTreeBitmap;
  end;
end;

procedure TForm1.TabSheet1Show(Sender: TObject);
begin
  Refocus(0);

  DrawTreeBitmap;
//  SetActiveWindow(TabSheet1.Handle);
  //TabSheet1.SetFocus
end;

procedure TForm1.RSShellListView1CanAdd(Sender: TObject;
  ShellFile: TRSShellFile; var CanAdd: Boolean);
begin
  CanAdd:= ShellFile.IsFolder or ShellFile.IsFileSystem and
        SameText(ExtractFileExt(ShellFile.ShortName([RSForParsing])), '.bmp');
//        and not RSIsSpecialFolder(TRSShellListView(Sender).Root.FullName);
{
  if ShellFile.IsFolder then  exit;
  if ExtractFileExt(ShellFile.ShortName([RSForParsing])) <> '.bmp' then  exit;
  if ShellFile.InFileSystem then  msgz('1');
  if ExtractFileExt(ShellFile.ShortName([RSForParsing])) = '.bmp' then  msgz('2');
  if not RSIsSpecialFolder(TRSShellListView(Sender).Root.FullName) then  msgz('3');
}
{
  CanAdd:= ShellFile.IsFolder or ShellFile.InFileSystem and
        (ExtractFileExt(ShellFile.ShortName([RSForParsing])) = '.bmp')
        and not RSIsSpecialFolder(TRSShellListView(Sender).Root.FullName);
}
end;

procedure TForm1.RSShellListView1OpenFile(Sender: TRSShellListView;
  AFile: TRSShellFile; var Handled: Boolean);
begin
  Handled:= not AFile.IsFolder;
end;

procedure TForm1.TreeView1Deletion(Sender: TObject; Node: TTreeNode);
var s:string;
begin
  if Node.Level>0 then
    ptr(s):= Node.Data;
end;

procedure TForm1.TreeView1DragDrop(Sender, Source: TObject; X, Y: Integer);
var
  Node, PNode: TTreeNode;
begin
  if Source <> Sender then  exit;

  with Sender as TTreeView do
  begin
    WasChanged:= true;
    Node:= GetNodeAt(x, y);

    if DragNode.Level = 2 then
    begin
      // swap shadows
      PNode:= Node;
      if Node.Level = 2 then
        PNode:= Node.Parent
      else
        Node:= PNode.getFirstChild;

      if Node <> nil then
        Node.MoveTo(DragNode.Parent, naAddChild);
      DragNode.MoveTo(PNode, naAddChild);
    end else
    if Node.Level = 1 then
    begin
      // insert before (or after in a special case)
      if DragNode.getNextSibling = Node then
        Node.MoveTo(DragNode, naInsert)
      else
        DragNode.MoveTo(Node, naInsert);
    end else
    begin
      // add
      DragNode.MoveTo(Node, naAddChild);
    end;
  end;
end;

procedure TForm1.TreeView1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
var
  TimerOn: Boolean;
  DropItem: TTreeNode;
begin
  Accept:= false;
  if Source <> Sender then  exit;
  TimerOn:= false;
  DropItem:= (Sender as TTreeView).GetNodeAt(x, y);
  if DropItem <> DragTargetNode then
  begin
    DragTargetNode:= DropItem;
    DragTimer.Enabled:= false;
    TimerOn:= (DropItem <> nil) and (DropItem.Level < DragNode.Level);
  end;
  if (DropItem = nil) or (DropItem = DragNode) then
    exit;
  if (DropItem = DragNode) or DropItem.HasAsParent(DragNode) then
    exit;
  if TimerOn then
    DragTimer.Enabled:= not DragNode.HasAsParent(DropItem);
  if not (DragNode.Level - DropItem.Level in [0, 1]) then
    exit;  // drop real frame onto a shadow or shadow onto group
  Accept:= true;
end;

procedure TForm1.RedrawPicture(Update:Boolean);

  procedure DoRedraw(pb:TRSPanel);
  begin
    InvalidateRect(pb.Handle, nil, false);
    if Update then
      UpdateWindow(pb.Handle);
  end;

begin
  case PageControl1.ActivePageIndex of
    0:
      DoRedraw(PaintBox1);
    1:
      DoRedraw(PaintBox2);
    2:
    begin
      DoRedraw(PaintBox3);
      DoRedraw(PaintBox4);
    end;
    3:
      DoRedraw(PaintBox5);
  end;
end;

procedure TForm1.RSShellListView1SelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  if not Selected then  exit;
  DrawListFile(TRSShellListView(Sender));
end;

procedure TForm1.DrawTreeBitmap(AnimIndex: int = -1; it: TTreeNode = nil);
var
  View: TRSShellListView;
  b, b1: TBitmap;
  ExtShadow: Boolean;
  p: TPoint;
  k, shd: int;
begin
  if BlockRepaint then  exit;
  if AnimIndex >= 0 then
    LastAnimNode:= TreeView1.Selected
  else
    if TreeView1.Selected = LastAnimNode then
      AnimIndex:= LastAnimIndex;
  if it = nil then
    it:= TreeView1.Selected;
  if it <> nil then
  begin
    if AnimIndex >= it.Count then
      AnimIndex:= -1;
    if it.Level = 0 then
      if it.Count > 0 then
        if AnimIndex >= 0 then
          it:= it.Item[AnimIndex]
        else
          it:= it.Item[0]
      else
        it:= nil;
  end else
  begin
    it:= TreeView1.Items.Item[0];
    if it.Count > 0 then
      it:= it.Item[0]
    else
      it:= nil;
  end;
  LastAnimIndex:= AnimIndex;
  PictureNode:= it;

  if it = nil then
  begin
    View:= nil;
    if PageControl1.TabIndex = 1 then
      View:= RSShellListView1
    else
      if (PageControl1.TabIndex = 2) and RSSpeedButton20.Down then
        View:= RSShellListView2;

    if View<>nil then
      DrawListFile(View)
    else
      SetPicture('', false);
  end else
    SetPicture(string(it.Data), false);

  if PictureReady.Empty then
    exit;

  ExtShadow:= (it <> nil) and (ShadowType = 2) and (it.Count<>0) and not it.Expanded;

  if (PageControl1.ActivePageIndex = 3) and (it<>nil) and (PicturePos<>nil) then
  begin
    PictureReady:= TBitmap.Create;
    Assert(List.Find(string(it.Data), k));
    p:= PicturePos[k];
    if ExtShadow then
    begin
      Assert(List.Find(string(it.getFirstChild.Data), shd));
      dec(p.X, PicturePos[shd].X);
      dec(p.Y, PicturePos[shd].Y);
    end;
    MakeMovedPicture(Picture, PictureReady, p, it);
  end;

  if it<>nil then
    if (PageControl1.ActivePageIndex in [0,2,3]) and
       (it.Level = 1) and TabSheet3.TabVisible and
       ((ShadowType<>0) or RSSpeedButton1.Down or
        RSSpeedButton22.Down and RSSpeedButton22.Visible or
        SpeedButtonFaintShadow.Down) then
    begin
      b:=TBitmap.Create;
      b1:=b;
      try
        NonSpecialColor:=0;
        SetMaxShadowColor;

        if ExtShadow then
        begin
          ColorBoxToColors(ColorBox2);
          try
            RSLoadBitmap(string(it[0].Data), b);
          except
            on e:Exception do
            begin
              PictureError:= e.Message;
              exit;
            end;
          end;
          b1:= TBitmap.Create;
          MakeBmpSpec(b, b1, 0);
          MoveBmpSpec(b1, RSSpinEdit1.Value, RSSpinEdit2.Value, 0);
        end;

        ColorBoxToColors(ColorBox1);
        MakeBmpSpec(PictureReady, b, 0);
        if RSSpeedButton1.Down then
          DeleteShadow(b);

        if ExtShadow then
        begin
          ColorBoxToColors(ColorBox2);
          ColorBoxToColors(ColorBox1, false);
        end;

        if ShadowType = 1 then  DoMakeShadow(b);

        DoMakeBmpSpec(it, b, b1);
        if PictureReady = Picture then
        begin
          PictureReady:= TBitmap.Create;
          PictureReady.Assign(Picture);
        end;
        if CheckStColors.Checked then
          UseStandardColors;
        PutBmpSpec(PictureReady, b1);
      finally
        b.Free;
        if b1<>b then
          b1.Free;
      end;
    end;

  if (PageControl1.ActivePageIndex = 3) and (it<>nil) and (PicturePos<>nil) then
  begin
    if ExtShadow then
    begin
      b:= PictureReady;
      PictureReady:= TBitmap.Create;
      try
        MakeMovedPicture(b, PictureReady, PicturePos[shd], it);
      finally
        if b <> Picture then
          b.Free;
      end;
    end;
    PictureReady.Canvas.Draw(0, 0, Grid);
  end;

  if PictureReady.Empty then
    PictureReady:= nil;

  RedrawPicture(true);
end;

procedure TForm1.SetPicture(const s: string; Update:Boolean);
begin
  if s = '' then
    PictureNode:= nil;

  if (PictureError<>'') or not SameText(s, PictureName) then
  begin
    PictureError:='';
    PictureName:=s;
    if s<>'' then
      try
        RSLoadBitmap(s, Picture);
      except
        on e:Exception do
        begin
          PictureError:= e.Message;
//          Application.ShowException(e);
          Picture.Assign(nil);
        end;
      end
    else
      Picture.Assign(nil);
  end;

  if PictureReady<>Picture then
    FreeAndNil(PictureReady);

  PictureReady:= Picture;
  RedrawPicture(Update);
end;

procedure TForm1.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  DrawTreeBitmap;
end;

procedure TForm1.RSShellListView1FolderChanged(Sender: TObject);
begin
  with RSShellListView1.Root do
    if (FramesPath<>'') or IsFileSystem then
      FramesPath:= FullName;
  RSEdit1.Text:= RSShellListView1.Path;
  RSEdit1.SelectAll;
end;

procedure TForm1.RSShellListView2FolderChanged(Sender: TObject);
begin
  with RSShellListView2.Root do
    if (ShadowPath<>'') or IsFileSystem then
      ShadowPath:= FullName;
  RSEdit2.Text:= RSShellListView2.Path;
  RSEdit2.SelectAll;
end;

procedure TForm1.ShowShell(List:TRSShellListView; Path:string; const AltPath:string);
begin
  Application.ProcessMessages;
  if not DirectoryExists(Path) or not List.Browse(Path) then
  begin
    Path:= AltPath;
    if not DirectoryExists(Path) or not List.Browse(Path) then
    begin
      Path:= ExtractFilePath(FFileName);
      if not DirectoryExists(Path) or not List.Browse(Path) then
        List.Browse(CSIDL_DRIVES);
    end;
  end;
  if GetFocus = List.Handle then
    List.OnSelectItem(List, List.SelectedItem, true)
  else
    DrawTreeBitmap;
end;

procedure TForm1.TreeView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var it:TTreeNode;
begin
  if (Key = VK_DELETE) and not TreeView1.IsEditing then
  begin
    Key:= 0;
    it:= TreeView1.Selected;
    if it = nil then
      exit
    else
      if it.Count<>0 then
        it.DeleteChildren
      else
        if it.Level>0 then
          it.Delete
        else
          exit;
          
    DrawTreeBitmap;
  end;
end;

{ Make }

procedure MakeError(Assertion:Boolean; const Msg:string);
begin
  if not Assertion then
    raise EMakeError.Create(Msg);
end;

function TForm1.MakeListNodeName(Node: TTreeNode; IncludeShadow: Boolean): string;
begin
  Result:= string(Node.Data);
  if IncludeShadow and (Node.Count>0) then
    Result:= Result + #10 + string(Node[0].Data);
end;

function TForm1.MakeFramesList(IncludeShadow: Boolean = true; ExternalShadow:Boolean = false):TStringList;
var i,j,k:int;
begin
  Result:= TStringList.Create;
  Result.Sorted:= true;
  Result.Duplicates:= dupIgnore;
  Result.CaseSensitive:= false;

  for i:=0 to length(GroupNodes)-1 do
    if GroupNodes[i]<>nil then
      with GroupNodes[i] do
        for j:=0 to Count-1 do
        begin
          k:= Result.AddObject(MakeListNodeName(Item[j], IncludeShadow), Item[j]);
          if ExternalShadow then
          begin
            Result.Objects[k]:= Item[j];
            if Item[j].Count>0 then
              Result.AddObject(MakeListNodeName(Item[j].Item[0], false), Item[j].Item[0]);
          end;
        end;
end;

procedure TForm1.DoMakeBmpSpec(Node:TTreeNode; OrigBmpSpec:TBitmap;
   var BmpSpec:TBitmap);

  function FindText(s:string; Group:int):Boolean;
  var i:int;
  begin
    Result:= true;
    if (length(GroupNodes)>Group) and (GroupNodes[Group]<>nil) then
      with GroupNodes[Group] do
        for i:=0 to Count-1 do
          if SameText(string(Item[i].Data), s) then
            exit;
    Result:= false;
  end;

var
  s:string;
begin
  if BmpSpec = nil then
    BmpSpec:= OrigBmpSpec;
  if BmpSpec<>OrigBmpSpec then
    if TypeIndex in [3..5] then
      AddBmpSpec(BmpSpec, OrigBmpSpec, 5)
    else
      AddBmpSpec(BmpSpec, OrigBmpSpec, 0);

  s:= string(Node.Data);
  with RSSpeedButton22 do
    if Down and Visible and (FindText(s, 1) or FindText(s, 2)) then
    begin
      MakeSelection(BmpSpec);
      if SpecColors[5]<0 then  SpecColors[5]:= RSSwapColor(DefColors[5]);
      if SpecColors[6]<0 then  SpecColors[6]:= RSSwapColor(DefColors[6]);
      if SpecColors[7]<0 then  SpecColors[7]:= RSSwapColor(DefColors[7]);
    end;

  if SpeedButtonFaintShadow.Down and TabSheet3.TabVisible then
    MakeShadowFaint(BmpSpec);
end;

procedure TForm1.ClearMake;
var i:int;
begin
  FreeAndNil(List);

  for i:=0 to length(Bmp)-1 do  Bmp[i].Free;
  Bmp:=nil;

  for i:=0 to length(BmpSpec)-1 do  BmpSpec[i].Free;
  BmpSpec:=nil;
end;

procedure TForm1.DoMakeShadow(BmpSpec:TBitmap);
begin
  if not ShadowSet then
    ShadowBase:= min(BmpSpec.Height, DefShadowBase);

  SetMaxShadowColor;
  if TypeIndex in [3..5] then
    MakeShadow(BmpSpec, ShadowBase, -100, -44, -62)
  else
    MakeShadow(BmpSpec, ShadowBase, -3, 0, -1);

  if SpecColors[1]<0 then  SpecColors[1]:= RSSwapColor(DefColors[1]);
  if SpecColors[4]<0 then  SpecColors[4]:= RSSwapColor(DefColors[4]);
end;

procedure TForm1.SetMaxShadowColor;
begin
  if TypeIndex in [3..5] then
    MaxShadowColor:= 4
  else
    MaxShadowColor:= 7;
end;

procedure TForm1.BeginMake(SameSize:Boolean);
var
  ShType: int;
  i:int; b, b1:TBitmap; w,h:int;
begin
  ClearMake;
  List:= MakeFramesList;
  MakeError(List.Count <> 0, SNoFrames);

  SetLength(Bmp, List.Count);
  SetLength(BmpSpec, List.Count);

  ColorBoxToColors(ColorBox1);
  HasSpecialColors:=false;
  NonSpecialColor:=-1;
  SetMaxShadowColor;
  ShType:= ShadowType*BoolToInt[TabSheet3.TabVisible];

  for i:= 0 to List.Count-1 do
  begin
    Bmp[i]:= TBitmap.Create;
    RSLoadBitmap(string(TTreeNode(List.Objects[i]).Data), Bmp[i]);
    BmpSpec[i]:= TBitmap.Create;
  end;
  if not CheckSamePalette then
  begin
    for i:= 0 to List.Count-1 do
    begin
      MakeBmpSpec(Bmp[i], BmpSpec[i], ColorBox1.Tolerance);
        // Заодно устанавливает NonSpecialColor и HasSpecialColors
      if SpecColors[255]<0 then
        HasSpecialColors:=true;
    end
  end else
  begin
    for i:= 0 to List.Count-1 do
      MakeBmpSpec8Bit(Bmp[i], BmpSpec[i]);
  end;

  w:= Bmp[0].Width;
  h:= Bmp[0].Height;
  if TypeIndex in [3,4,5] then
    MakeError((w mod 32 = 0) and (h mod 32 = 0), SWrongPicSize32);

  if SameSize then
    for i:=1 to length(Bmp)-1 do
    begin
      MakeError((Bmp[i].Width = w) and (Bmp[i].Height = h), SWrongPicSize);
      if (ShType = 2) and (BmpSpec[i]<>nil) then
        MakeError((BmpSpec[i].Width=w) and (BmpSpec[i].Height=h), SWrongPicSize);
    end
  else
    if ShType = 2 then
      for i:=1 to length(Bmp)-1 do
        if BmpSpec[i]<>nil then
          MakeError((BmpSpec[i].Width = Bmp[i].Width) and
                    (BmpSpec[i].Height = Bmp[i].Height), SWrongShadowSize);

  if RSSpeedButton1.Down then
    for i:= 0 to length(Bmp)-1 do
      DeleteShadow(BmpSpec[i]);

  b:=nil;
  b1:=nil;
  try
    case ShType of
      1:
        for i:=0 to length(BmpSpec)-1 do
        begin
          DoMakeShadow(BmpSpec[i]);
          DoMakeBmpSpec(TTreeNode(List.Objects[i]), BmpSpec[i], BmpSpec[i]);
        end;
      0, 2:
      begin
        ColorBoxToColors(ColorBox2);
        for i:=0 to length(BmpSpec)-1 do
        begin
          b:=BmpSpec[i];
          BmpSpec[i]:= nil;

          with TTreeNode(List.Objects[i]) do
            if (ShType = 2) and (Count > 0) then
            begin
              b1:= TBitmap.Create;
              RSLoadBitmap(string(Item[0].Data), b1);
              BmpSpec[i]:= TBitmap.Create;
              MakeBmpSpec(b1, BmpSpec[i], 0);
              FreeAndNil(b1);
              MoveBmpSpec(BmpSpec[i], RSSpinEdit1.Value, RSSpinEdit2.Value, 0);
            end;

          DoMakeBmpSpec(TTreeNode(List.Objects[i]), b, BmpSpec[i]);
          if b = BmpSpec[i] then
            b:= nil
          else
            FreeAndNil(b);
        end;
      end;
    end;
  finally
    b.Free;
    b1.Free;
  end;
end;

procedure TForm1.UpdateLanguage;

  procedure LoadLang(const s: string);
  begin
    if FileExists(s) then
      try
        RSLanguage.LoadLanguage(RSLoadTextFile(s), true);
      except
      end;
  end;

var
  TypIndex: int;
  CreatureIndex: int;
  i: int;
begin
  TypIndex:= TypeIndex;
  CreatureIndex:= RSComboBox2.ItemIndex;
  RSLanguage.LoadLanguage(RSLanguage.LanguageBackup, true);
  LoadLang(AppPath + LangDir + ComboLang.Text + '.txt');
  LoadLang(AppPath + GameLangDir + ComboGameLang.Text + '.txt');

  Color5Name[false]:= GetShortHint(CheckColor6.Caption);
  Color5Name[true]:= GetLongHint(CheckColor6.Caption);
  CheckColor6.Caption:='';
  for i:=0 to 7 do
    ColorBox2.Checks[i].Caption:= ColorBox1.Checks[i].Caption;
  ColorBox2.Box.Caption:= ColorBox1.Box.Caption;
  with MemoHelp do
    Text:= RSStringReplace(Text, '%VERSION%', RSGetModuleVersion);

  TypeIndex:= TypIndex;
  RSComboBox2.ItemIndex:= CreatureIndex;
  ProcessColorsBox(ColorBox1, TypIndex);
  ProcessColorsBox(ColorBox2, TypIndex);
  for i:=0 to length(GroupNodes)-1 do
  begin
    if GroupNodes[i]=nil then
      continue;
    GroupNodes[i].Text:= MakeNodeName(i);
  end;
end;

procedure TForm1.UseStandardColors;
var i:int;
begin
  for i:=0 to 7 do
    if SpecColors[i]>=0 then
      SpecColors[i]:= RSSwapColor(DefColors[i]);
end;

 // !!! Убрать обращения к форме
procedure TForm1.ConvertBmps(ColorBox: TColorBoxInfo; ByOne:Boolean = false;
   Compatibility:Boolean = true);
var
  i,j:int; Pal:HPALETTE; Bm:TBitmap; PicList:TList;
  PlayerBmp: array of TBitmap;
begin
  ColorBoxToColors(ColorBox, false);

  if SpecColors[255]>=0 then
    SetLength(PlayerBmp, length(Bmp));

  try
    for i:=0 to length(Bmp)-1 do
      if PlayerBmp<>nil then
      begin
        PlayerBmp[i]:= TBitmap.Create;
        MakePlayerBmp(Bmp[i], PlayerBmp[i], ColorBox.Tolerance);
        if HasSpecialColors and (NonSpecialColor>=0) then
          ReplaceSpecColors(Bmp[i], NonSpecialColor, ColorBox.Tolerance);
      end;

     // Count number of colors and delete colors that shouldn't be in palette
    j:=256;
    if SpecColors[255]>=0 then
      dec(j, 32);

    if not Compatibility then
      for i:= SpecL to SpecH do
        SpecColors[i]:= -1
    else
      for i:= SpecL to SpecH do
        if SpecColors[i]>=0 then
          dec(j);

     // Make palette

    if not ByOne then
    begin
      PicList:= TList.Create;
      try
{        for i:=0 to length(Bmp)-1 do  // !!!
          Bmp[i].SaveToFile(AppPath + 'before\' + IntToStr(i) + '.bmp');}
        for i:=0 to length(Bmp)-1 do
          PicList.Add(Bmp[i]);
        Pal:= CreateOptimizedPaletteFromManyBitmaps(PicList, j, 8, false);
      finally
        PicList.Free;
      end;
    end else
      Pal:= 0; // To avoid compiler warning

    if CheckStColors.Checked then
      UseStandardColors;
       // !!! Use Standard Player's colors ?

     // Convert pictures
    Bm:= TBitmap.Create;
    try
      Bm.HandleType:= bmDIB;
      Bm.PixelFormat:= pf8bit;
      if not ByOne then
      begin
        MakeNewPal(Pal, j);
        Bm.Palette:= Pal;
      end;
      for i:=0 to length(Bmp)-1 do
        with Bm do
        begin
          Height:= 0;
          if ByOne then
          begin
            Pal:= CreateOptimizedPaletteFromSingleBitmap(Bmp[i], j, 8, false);
            MakeNewPal(Pal, j);
            Palette:= Pal;
          end;

          Width:= Bmp[i].Width;
          Height:= Bmp[i].Height;
          BitBlt(Canvas.Handle, 0, 0, Width, Height, Bmp[i].Canvas.Handle, 0, 0,
             SRCCOPY);

          ExtractPic(Bm, Bmp[i]);
          if PlayerBmp<>nil then
            AddBmpSpec(Bmp[i], PlayerBmp[i]);
{          Bm.SaveToFile(AppPath + 'after1\' + IntToStr(i) + '.bmp');  // !!!
          Bmp[i].SaveToFile(AppPath + 'after2\' + IntToStr(i) + '.bmp');}
        end;
    finally
      Bm.Free;
    end;
  finally
    for i:= high(PlayerBmp) downto 0 do
      PlayerBmp[i].Free;
  end;
end;

procedure TForm1.DoAdd(Lod: TLod; const a:TRSByteArray; const Name: string);
begin
  if CheckBackup1.Checked then
    Lod.BackupFile(Name, CheckBackup2.Checked);

  Lod.Add(a, Name);
end;

procedure TForm1.EndMake;
var
  a,b:TRSByteArray; Stream:TStream; Msk:TMsk; s:string;
  i,j,x,w,h:int; Lod:TLod;
begin
   // Make Def
  with TRSDefMaker.Create do
  try
    DefType:= TypeIndex + $40;

    w:=Bmp[0].Width;
    h:=Bmp[0].Height;

    if DefType in [$43, $44, $45] then
      if (DefType = $45) and (w = 32) and (h = 32) then
        if HasSpecialColors then
          Compression:=2
        else
          Compression:=0
      else
        Compression:=3
    else
      Compression:=1;

    for i:=0 to List.Count-1 do
      AddPic(ChangeFileExt(TTreeNode(List.Objects[i]).Text, '.' + Edit5.Text),
         Bmp[i], BmpSpec[i]);

    {
    for i:=0 to length(Pics)-1 do
    begin
      Picture.Assign(Pics[i]);
      RedrawPicture;
      Application.ProcessMessages;
      Sleep(50);
    end;

    for i:=0 to length(Pics)-1 do
    begin
      Picture.Assign(PicsSpec[i]);
      RedrawPicture;
      Application.ProcessMessages;
      Sleep(50);
    end;
    }

    for i:=0 to length(GroupNodes)-1 do
      if GroupNodes[i]<>nil then
        with GroupNodes[i] do
          for j:=0 to Count-1 do
            if List.Find(MakeListNodeName(Item[j]), x) then
              AddItem(i, x);

    Stream:= TRSArrayStream.Create(a);
    try
      Make(Stream);
    finally
      Stream.Free;
    end;
  finally
    Free;
  end;

   // Save, Msk, Lod
   
  s:= EditDefPath.Text;
  RSSaveFile(s, a);
  if CheckMsk.Visible and CheckMsk.Checked then
  begin
    RSMakeMsk(a, Msk);
    SetLength(b, SizeOf(Msk));
    CopyMemory(ptr(b), @Msk, SizeOf(Msk));
    RSSaveFile(ChangeFileExt(s, '.msk'), b);
    if not DontCreateMsgFiles then
      RSSaveFile(ChangeFileExt(s, '.msg'), b);
  end;

  if CheckLod.Checked then
  begin
    Lod:= TLOD.Create;
    try
      Lod.LodFileName:= EditLod.Text;
      if FileExists(Lod.LodFileName) then
        Lod.Open
      else
        Lod.New;

      s:= ExtractFileName(s);
      DoAdd(Lod, a, s);
      if b<>nil then
      begin
        DoAdd(Lod, b, ChangeFileExt(s, '.msk'));
        if not DontCreateMsgFiles then
          DoAdd(Lod, b, ChangeFileExt(s, '.msg'));
      end;
    finally
      Lod.Free;
    end;
  end;
end;

procedure TForm1.SpeedButtonMakeClick(Sender: TObject);
var
  s: string;
begin
  if EditDefPath.Text = '' then
    if CheckDefPath.Checked then
      MakeError(false, SNoDefName)
    else
      MakeError(false, SNoAutoDefName);

  try
    BeginMake(true);
    if (length(Bmp) = 0) or (RSGetPixelFormat(Bmp[0]) <> pf8bit) then
    begin
      ConvertBmps(ColorBox1);
      s:= SSuccessfulMake
    end else
      s:= SSuccessfulMake8Bit;

    EndMake;
    if not CmdLineSilent then
      RSErrorHint(EditBitmapsLod, s, 0, false, MB_ICONINFORMATION);
  finally
    ClearMake;
  end;
end;

procedure TForm1.MakePictures(ByOne:Boolean);
var
  i:int; s:string; Lod:TLod;
begin
  s:= EditBitmapsPath.Text;
  MakeError(s <> '', SNoAutoDefName);
  s:= IncludeTrailingPathDelimiter(s);

  RSWin32Check(RSCreateDir(s));
  try
    BeginMake(false);
    HasSpecialColors:= true;
    ConvertBmps(ColorBox1, ByOne);

     // Save Pictures

    for i:=0 to List.Count-1 do
    begin
      AddBmpSpec(Bmp[i], BmpSpec[i], 255, 255);
      Bmp[i].SaveToFile(s + TTreeNode(List.Objects[i]).Text);
        // !!! Смысл Text может измениться
    end;

     // Add to Lod

    if CheckBitmapsLod.Checked then
    begin
      Lod:= TLOD.Create;
      try
        Lod.LodFileName:= EditBitmapsLod.Text;
        if FileExists(Lod.LodFileName) then
          Lod.Open
        else
          Lod.New;

        for i:=0 to List.Count-1 do
        begin
          s:= ChangeFileExt(TTreeNode(List.Objects[i]).Text, '.pcx');
          if CheckBackup1.Checked then
            Lod.BackupFile(s, CheckBackup2.Checked);

          Lod.Add(Bmp[i], s);
            // !!! Смысл Text может измениться
        end;
      finally
        Lod.Free;
      end;
    end;

    RSErrorHint(EditBitmapsLod, SSuccessfulBitmapsMake, 0, false, MB_ICONINFORMATION);

  finally
    ClearMake;
  end;
end;

procedure TForm1.RSEdit1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key:=#0;
    RSShellListView1.Browse(TEdit(Sender).Text);
  end;
end;

procedure TForm1.RSEdit2KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key:=#0;
    RSShellListView2.Browse(TEdit(Sender).Text);
  end;
end;

procedure TForm1.RSSpeedButton2Click(Sender: TObject);
var
  a: array of string;
  i,j,k,L:int; it:TTreeNode;
begin
  with RSShellListView2, MakeFramesList(false) do
    try
      SetLength(a, Count);
      j:=-1;
      for i:=0 to Count-1 do
      begin
        j:= NextSelected(j);
        while (j>=0) and (Files[j].IsFolder or not Files[j].IsFileSystem) do
          j:=RSShellListView2.NextSelected(j);

        if j<0 then
        begin
          SetLength(a, i);
          break;
        end;
        a[i]:= RSShellListView2.Files[j].FullName([RSForParsing]);
      end;
      if a=nil then  exit;

      BlockRepaint:= true;
      L:=length(a);
      for i:=0 to length(GroupNodes)-1 do
        if GroupNodes[i]<>nil then
          for j:=0 to GroupNodes[i].Count - 1 do
          begin
            it:=GroupNodes[i][j];
            if (it.Count = 0) and Find(string(it.Data), k) and (k<L) then
              AddToTree(a[k], true, it);
          end;

    finally
      BlockRepaint:= false;
      Free;
    end;
  DrawTreeBitmap;  
end;

procedure TForm1.SpeedButtonDefPathClick(Sender: TObject);
begin
  with SaveDefDialog, EditDefPath do
  begin
    FileName:= Text;
    if Execute then
    begin
      Text:= FileName;
      WasChanged:= true;
    end;
  end;
end;

procedure TForm1.SpeedButtonLodClick(Sender: TObject);
begin
  with OpenLodDialog, EditLod do
  begin
    FileName:= Text;
    if Execute then
    begin
      Text:= FileName;
      WasChanged:= true;
    end;
  end;
end;

procedure TForm1.PaintPicture(Sender: TRSCustomControl; ShadowLine:Boolean = false);
var r, r1:TRect;

  procedure DrawLine;
  begin
    with Sender, Canvas do
    begin
      Pen.Color:= clBlack;
      MoveTo(0, (Height - PictureReady.Height) div 2 + ShadowBase);
      LineTo(Width,  (Height - PictureReady.Height) div 2 + ShadowBase);
    end;
  end;

begin
  with Sender, Canvas do
  begin
    if PictureError <> '' then
    begin
      Brush.Color:=clBtnFace;
      FillRect(ClipRect);
      r:= ClientRect;
      DrawText(Handle, ptr(PictureError), length(PictureError), r,
        DT_CENTER or DT_NOCLIP or DT_NOPREFIX or DT_WORDBREAK or DT_CALCRECT);
      r.Top:= (Height - r.Bottom) div 2;
      r.Right:= Width;
      inc(r.Bottom, r.Top);
      DrawText(Handle, ptr(PictureError), length(PictureError), r,
        DT_CENTER or DT_NOCLIP or DT_NOPREFIX or DT_WORDBREAK);
      exit;
    end;

     // r - on Canvas, r1 - on Picture, r2 - ClipRect
    if PictureReady<>nil then
    begin
      r:= Rect(0, 0, PictureReady.Width, PictureReady.Height);
      r1:=r;
      OffsetRect(r1, (Width - PictureReady.Width) div 2,
                     (Height - PictureReady.Height) div 2);

      IntersectRect(r, r1, Canvas.ClipRect);
      r1:= r;
      OffsetRect(r1, - (Width - PictureReady.Width) div 2,
                     - (Height - PictureReady.Height) div 2);
    end;

    with Canvas do
    begin
      if PictureReady<>nil then
      begin
        CopyRect(r, PictureReady.Canvas, r1);
        if ShadowLine then
          DrawLine;
        with r do
          ExcludeClipRect(Canvas.Handle, Left, Top, Right, Bottom);
      end;

      Brush.Color:=clBtnFace;
      FillRect(ClipRect);
      if ShadowLine and (PictureReady<>nil) then
        DrawLine;
    end;
  end;
end;

procedure TForm1.PaintBox1Paint(Sender: TRSCustomControl;
  State: TRSControlState; DefaultPaint: TRSProcedure);
begin
  PaintPicture(Sender);
end;

procedure TForm1.PaintBox4Paint(Sender: TRSCustomControl;
  State: TRSControlState; DefaultPaint: TRSProcedure);
begin
  if not ShadowSet then
    ShadowBase:= min(Picture.Height, DefShadowBase);
  PaintPicture(Sender, ShadowType = 1);
end;

procedure TForm1.PaintBox4MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or (ShadowType<>1) then  exit;
  if PictureReady = nil then  exit;
  ShadowSet:= true;
  ShadowBase:= Y - (PaintBox4.Height - PictureReady.Height) div 2;
  DrawTreeBitmap;
end;

procedure TForm1.PaintBox4MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if not (ssLeft in Shift) or (ShadowType<>1) then  exit;
  if PictureReady = nil then  exit;
  ShadowSet:= true;
  ShadowBase:= Y - (PaintBox4.Height - PictureReady.Height) div 2;
  DrawTreeBitmap;
end;

procedure TForm1.ShadowChanged(Sender: TObject);
begin
  WasChanged:=true;
  if GetFocus<>RSShellListView2.Handle then
    DrawTreeBitmap;
end;

procedure TForm1.TreeView1Collapsed(Sender: TObject; Node: TTreeNode);
begin
  DrawTreeBitmap;
end;

procedure TForm1.TreeView1Expanded(Sender: TObject; Node: TTreeNode);
begin
  DrawTreeBitmap;
end;

procedure TForm1.RSSpeedButton3Click(Sender: TObject);
begin
  if not ShadowSet then
    ShadowBase:= min(Picture.Height, DefShadowBase);
  dec(ShadowBase);
  ShadowSet:=true;
  WasChanged:=true;
  DrawTreeBitmap;
end;

procedure TForm1.RSSpeedButton4Click(Sender: TObject);
begin
  if not ShadowSet then
    ShadowBase:= min(Picture.Height, DefShadowBase);
  inc(ShadowBase);
  ShadowSet:=true;
  WasChanged:=true;
  DrawTreeBitmap;
end;

procedure TForm1.RSSpeedButton21Click(Sender: TObject);
var i:int; s:string;
begin
  SetSaveShadowDialogPath;
  if not SaveShadowDialog.Execute then  exit;
  s:= ExtractFilePath(SaveShadowDialog.FileName);
  RSWin32Check(RSCreateDir(s));

  try
    BeginMake(false);
    ColorBoxToColors(ColorBox1, false);
    if CheckStColors.Checked then
      UseStandardColors;

    for i:=0 to List.Count-1 do
    begin
      PutBmpSpec(Bmp[i], BmpSpec[i]);
      Bmp[i].SaveToFile(s + TTreeNode(List.Objects[i]).Text);
        // !!! Смысл Text может измениться
    end;
  finally
    ClearMake;
  end;
end;

procedure TForm1.TabSheet4Show(Sender: TObject);
var x,y:int;
begin
  Refocus(3);

  if MonGrid = nil then
  begin
    MonGrid:= TJvPcx.Create;
    MonGrid.LoadFromFile(AppPath + 'Grid.pcx');
    MonGrid.Transparent:= true;
  end;
  if AdvGrid = nil then
  begin
    AdvGrid:= TBitmap.Create;
    with AdvGrid, Canvas do
    begin
      Width:= 8*32;
      Height:= 6*32;
      Brush.Color:= 0;
      FillRect(ClipRect);
      Brush.Style:= bsClear;
      Pen.Color:= clRed;
      for y:=0 to 5 do
        for x:=0 to 7 do
          Rectangle(x*32, y*32, x*32 + 32, y*32 + 32);
      TransparentColor:= 0;
      Transparent:= true;
    end;
  end;
  case TypeIndex of
    2, 9:  Grid:= MonGrid;
    3, 4:  Grid:= AdvGrid;
    else  Grid:= nil;
  end;
  List:= MakeFramesList(false, true);
  PicturePos:= nil;
  SetLength(PicturePos, List.Count);

  DrawTreeBitmap;
end;

procedure TForm1.PaintBox5Paint(Sender: TRSCustomControl;
  State: TRSControlState; DefaultPaint: TRSProcedure);
begin
  PaintPicture(Sender);
end;

procedure TForm1.PageControl1Changing(Sender: TObject;
  var AllowChange: Boolean);
var h:HWnd;
begin
  AllowChange:= ApplyMoveQuery;
  if not AllowChange then  exit;

  if PictureReady = Picture then
    PictureReady:= nil
  else
    FreeAndNil(PictureReady);

  h:= GetFocus;
  if not IsChild(PageControl1.ActivePage.Handle, h) then
    h:= 0;

  Focuses[PageControl1.ActivePageIndex]:= h;
end;

procedure TForm1.TabSheet4Hide(Sender: TObject);
begin
  PicturePos:= nil;
  FreeAndNil(List);
end;

var
  MoveX:int = MaxInt;
  StartX, StartY, MoveY:int;
  DirectionChosen, DirectionX: Boolean;

procedure TForm1.PaintBox5MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or (PictureName = '') then  exit;
  DirectionChosen:= false;
  StartX:= X;
  StartY:= Y;
  MoveX:= X;
  MoveY:= Y;
end;

procedure TForm1.PaintBox5MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
const
  Sens = 10;  
begin
  if (MoveX = MaxInt) or not (ssLeft in Shift) then exit;
  if ssCtrl in Shift then
  begin
    if not DirectionChosen then
      DirectionX:= abs(X - StartX) >= abs(Y - StartY);
    if DirectionX then
      Y:= StartY
    else
      X:= StartX;
    DirectionChosen:= DirectionChosen or (abs(X-StartX) + abs(Y-StartY) > Sens);
  end;
  DoMovePicture(X - MoveX, Y - MoveY);
  MoveX:= X;
  MoveY:= Y;
end;

procedure TForm1.PaintBox5MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    MoveX:= MaxInt;
end;

procedure TForm1.DoMovePicture(dx, dy: int);
var
  need: array of Boolean;
  it, it2: TTreeNode;
  i, j, lev:int;
begin
  if PictureNode = nil then  exit;
  lev:= PictureNode.Level;
  if ButtonCurrent.Down then
  begin
    Assert(List.Find(string(PictureNode.Data), i));
    inc(PicturePos[i].X, dx);
    inc(PicturePos[i].Y, dy);
    it:= PictureNode.getFirstChild;
    if (it <> nil) and List.Find(string(it.Data), j) and (j <> i) then
    begin
      inc(PicturePos[j].X, dx);
      inc(PicturePos[j].Y, dy);
    end;
  end else
  if ButtonGroup.Down then
  begin
    // select needed pics
    SetLength(need, length(PicturePos));
    it:= PictureNode.Parent;
    if lev = 2 then
      it:= it.Parent;
    it:= it.getFirstChild;
    while it <> nil do
    begin
      if lev = 1 then
      begin
        Assert(List.Find(string(it.Data), i));
        need[i]:= true;
      end;
      it2:= it.getFirstChild;
      if it2 <> nil then
      begin
        Assert(List.Find(string(it2.Data), i));
        need[i]:= true;
      end;
      it:= it.getNextSibling;
    end;
    // move pictures
    for i:=0 to high(PicturePos) do
      if need[i] then
      begin
        inc(PicturePos[i].X, dx);
        inc(PicturePos[i].Y, dy);
      end;
  end else
    for i:=0 to high(PicturePos) do
      if TTreeNode(List.Objects[i]).Level >= lev then
      begin
        inc(PicturePos[i].X, dx);
        inc(PicturePos[i].Y, dy);
      end;

  DrawTreeBitmap;
end;

procedure TForm1.RSSpeedButton5Click(Sender: TObject);
begin
  DoMovePicture(-1, 0);
end;

procedure TForm1.RSSpeedButton7Click(Sender: TObject);
begin
  DoMovePicture(0, -1);
end;

procedure TForm1.RSSpeedButton6Click(Sender: TObject);
begin
  DoMovePicture(1, 0);
end;

procedure TForm1.RSSpeedButton8Click(Sender: TObject);
begin
  DoMovePicture(0, 1);
end;

procedure TForm1.ButtonCancelClick(Sender: TObject);
begin
  RSFillDWord(ptr(PicturePos), length(PicturePos)*2, 0);
  DrawTreeBitmap;
end;

procedure TForm1.ButtonApplyClick(Sender: TObject);
var
  Old, New:TBitmap;
  i:int;
begin
  New:= nil;
  Old:= TBitmap.Create;
  try
    for i:=0 to high(PicturePos) do
      if PicturePos[i].X or PicturePos[i].Y <> 0 then
      begin
        New:= TBitmap.Create;
        RSLoadBitmap(List[i], Old);
        MakeMovedPicture(Old, New, PicturePos[i], ptr(List.Objects[i]));
        MakeBackup(List[i]);
        New.SaveToFile(List[i]);
        PicturePos[i]:= Point(0,0);
        FreeAndNil(New);
      end;
  finally
    Old.Free;
    New.Free;
    PictureName:='';
    DrawTreeBitmap;
  end;
end;

procedure TForm1.MakeMovedPicture(Old, New: TBitmap; const p: TPoint;
  it: TTreeNode);
begin
  with New, Canvas do
  begin
    Width:= Old.Width;
    Height:= Old.Height;
    if it.Level = 2 then
      Brush.Color:= ColorBox2.Shapes[0].Brush.Color
    else
      Brush.Color:= ColorBox1.Shapes[0].Brush.Color;

    FillRect(ClipRect);
    BitBlt(Handle, p.X, p.Y, Width, Height, Old.Canvas.Handle, 0, 0, SRCCOPY);
  end;
end;


type
  TCreatureRecord = packed record
    Def: array[0..11] of Char;
    Sound: array[0..7] of Char;
  end;
  TCreaturesArray = array[Byte] of TCreatureRecord;
  PCreaturesArray = ^TCreaturesArray;

var
  MonDataArray: TRSByteArray;
  MonData: PCreaturesArray absolute MonDataArray;

{
procedure MakeMonData;
type
  TCreatureRecordNew = packed record
    Sound: array[0..7] of Char;
    Def: array[0..11] of Char;
  end;
  TCreaturesArrayNew = array[Byte] of TCreatureRecordNew;
  PCreaturesArrayNew = ^TCreaturesArrayNew;

var
  MonDataNewArray: TRSByteArray;
  i, j, k, n: int;
  p: PChar;
  s: string;
begin
  MonDataNewArray:= RSLoadFile(AppPath + 'MonDataNew.dat');
  j:= length(MonDataArray) div SizeOf(TCreatureRecord);
  n:= 197;
  SetLength(MonDataArray, n*SizeOf(TCreatureRecord));
  p:= ptr(MonDataNewArray);
  for i := j to n - 1 do
  begin
    while p^ = #0 do  inc(p);
    k:= StrLen(p);
    Move(p^, MonData[i].Sound, k);
    p:= p + k;

    while p^ = #0 do  inc(p);
    k:= StrLen(p);
    Move(p^, MonData[i].Def, k);
    p:= p + k;
  end;
  RSSaveFile(AppPath + 'MonData.dat', MonDataArray);
end;
}

procedure TForm1.TabSheet5Show(Sender: TObject);
begin
  Refocus(4);

  if MonDataArray = nil then
  begin
    MonDataArray:= RSLoadFile(AppPath + 'MonData.dat');
    //MakeMonData;
    RSComboBox2.ItemIndex:= 0;
    RSComboBox2Select(nil);
  end;
  CheckBox1.Checked:= Association.Associated;
end;

procedure TForm1.RSComboBox2Select(Sender: TObject);
begin
  Edit2.Text:= MonData[RSComboBox2.ItemIndex].Def;
  Edit4.Text:= MonData[RSComboBox2.ItemIndex].Sound;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  try
    Association.Associated:= CheckBox1.Checked;
  finally
    CheckBox1.Checked:= Association.Associated;
  end;
end;

procedure TForm1.SpeedButtonLodDefaultClick(Sender: TObject);
begin
  with OpenLodDialog, EditLodDefault do
  begin
    FileName:= Text;
    if Execute then
      Text:= FileName;
  end;
end;

procedure TForm1.LoadIni;
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini')) do
    try
      EditLodDefault.Text:= ReadString('Data', 'Lod Path', '');
      if EditLodDefault.Text = '' then
        EditLodDefault.Text:= GetDefaultLod(H3Sprite);

      EditLodBitmaps.Text:= ReadString('Data', 'Bitmaps Lod Path', '');
      if EditLodBitmaps.Text = '' then
        EditLodBitmaps.Text:= GetDefaultLod(H3Bitmap);

      EditPicsExtension.Text:= ReadString('Data', 'Pictures Extension', '');

      Recent.AsString:= ReadString('Options', 'Recent Files', '');
      self.FileName:= ExtractFilePath(Recent.Path[0]);
      if self.FileName<>'' then
        self.FileName:= self.FileName + 'Temp.hdl';
      CheckBackup1.Checked:= ReadBool('Options', 'Backup Files From Lods', true);
      CheckBackup2.Checked:= ReadBool('Options', 'Ovewrite Last Backup', false);
      CheckBackupPics.Checked:= ReadBool('Options', 'Backup Pictures Before Changing', true);
      Form3.OpenPictureDialog1.FileName:= ReadString('Options', 'Player Colors Path', '');

      SetLanguage(ComboLang, ReadString('Options', 'Language', ''));
      SetLanguage(ComboGameLang, ReadString('Options', 'GameLanguage', ''));
      UpdateLanguage;

      DontCreateMsgFiles:= ReadBool('Options', 'Create Msk Files But Not Msg', false);

    finally
      Free;
    end;
end;

procedure TForm1.SaveIni;
var s:string;
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini')) do
    try
      s:= EditLodDefault.Text;
      if SameText(s, GetDefaultLod(H3Sprite)) then
        s:= '';
      WriteString('Data', 'Lod Path', s);

      s:= EditLodBitmaps.Text;
      if SameText(s, GetDefaultLod(H3Bitmap)) then
        s:= '';
      WriteString('Data', 'Bitmaps Lod Path', s);

      // WritePrivateProfileString will delete the key if string is null
      WritePrivateProfileString('Data', 'Pictures Extension',
         ptr(EditPicsExtension.Text), ptr(FileName));

      WriteString('Data', 'Frames Dir', FramesPath);
      WriteString('Data', 'Shadow Dir', ShadowPath);

      WriteString('Options', 'Recent Files', Recent.AsString);
      WriteBool('Options', 'Backup Files From Lods', CheckBackup1.Checked);
      WriteBool('Options', 'Ovewrite Last Backup', CheckBackup2.Checked);
      WriteBool('Options', 'Backup Pictures Before Changing', CheckBackupPics.Checked);
      WriteString('Options', 'Player Colors Path', Form3.OpenPictureDialog1.FileName);

      WriteString('Options', 'Language', ComboLang.Text);
      WriteString('Options', 'GameLanguage', ComboGameLang.Text);

      WriteBool('Options', 'Create Msk Files But Not Msg', DontCreateMsgFiles);

    finally
      Free;
    end;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:= ApplyMoveQuery and SaveQuery;
  if CanClose then
    SaveIni;
end;

procedure TForm1.TreeView1Editing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
begin
  AllowEdit:= Node.Level = 0;
end;

procedure TForm1.TreeView1EndDrag(Sender, Target: TObject; X, Y: Integer);
begin
  DragNode:= nil;
  DragTimer.Enabled:= false;
  InvalidateRect(TreeView1.Handle, nil, false);
end;

procedure TForm1.TreeView1Edited(Sender: TObject; Node: TTreeNode;
  var s: String);
var i,j:int;
begin
  if (RSValEx(S, j)<>1) and (j<256) and (j>=0) and (j<>int(Node.Data)) then
  begin
    if length(GroupNodes)<=j then  SetLength(GroupNodes, j+1);
    if GroupNodes[j] = nil then
    begin
      for i:= j+1 to high(GroupNodes) do
        if GroupNodes[i]<>nil then
          GroupNodes[j]:= TreeView1.Items.InsertObject(GroupNodes[i],
                                                     MakeNodeName(j), ptr(j));
      if GroupNodes[j] = nil then
        GroupNodes[j]:= TreeView1.Items.AddObject(nil, MakeNodeName(j), ptr(j));
    end;
    for i:=Node.Count-1 downto 0 do
      Node[0].MoveTo(GroupNodes[j], naAddChild);

    if int(Node.Data)>=TypeGroups[TypeIndex].Count then
      PostMessage(TreeView1.Handle, TVM_DELETEITEM, 0, int(Node.ItemId));

    DrawTreeBitmap;
  end;
  s:= Node.Text;
end;

function TForm1.MakeNodeName(i: int): string;
begin
  if i < TypeGroups[TypeIndex].Count then
    Result:= IntToStr(i) + '   ' + TypeGroups[TypeIndex][i]
  else
    Result:= IntToStr(i) + '   ' + GroupsOther.Items[0];
end;

procedure TForm1.Shape13Click(Sender: TObject);
begin
  WasChanged:= (Form3.Execute(ColorBox1) = mrOk) or WasChanged;
end;

procedure TForm1.CheckBackup1Click(Sender: TObject);
begin
  CheckBackup2.Enabled:= CheckBackup1.Checked;
end;

function TForm1.ApplyMoveQuery: Boolean;
var i:int;
begin
  Result:= true;
  if TabSheet4.Visible then
    for i:=0 to high(PicturePos) do
      if PicturePos[i].X or PicturePos[i].Y <> 0 then
      begin
        case RSMessageBox(Handle, SLeaveReposiion, SLeaveReposiionCaption,
           MB_YESNOCANCEL or MB_ICONQUESTION) of
          mrYes:  ButtonApplyClick(nil);
          mrNo: ButtonCancelClick(nil);
          mrCancel:  Result:= false;
        end;
        break;
      end;
end;

procedure TForm1.ContextHelpPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
begin
  Handled:= true;
  RSHelpHint(Sender);
end;

procedure TForm1.SetSaveShadowDialogPath;
var i:int;
begin
  with TreeView1 do
    for i:=0 to Items.Count - 1 do
      if Items[i].Level>0 then
      begin
        SaveShadowDialog.FileName:= ExtractFilePath(string(Items[i].Data));
        if Items[i].Level = 1 then
          break;
      end;

  if SaveShadowDialog.FileName = '' then
    if (RSShellListView1.Root<>nil) and RSShellListView1.Root.IsFileSystem then
      SaveShadowDialog.FileName:= RSShellListView1.Path + '\'
    else
      if FileName = '' then
        SaveShadowDialog.FileName:= ''
      else
        SaveShadowDialog.FileName:= ExtractFilePath(FileName);
        
  SaveShadowDialog.FileName:= SaveShadowDialog.FileName + SSaveHere;
end;

procedure TForm1.MakeBackup(const Name: string);
var s:string;
begin
  if not CheckBackupPics.Checked then  exit;
  s:= ExtractFilePath(Name) + SPicBackup;
  RSWin32Check(RSCreateDir(s));
  s:= IncludeTrailingPathDelimiter(s) + ExtractFileName(Name);
  DeleteFile(s);
  MoveFile(ptr(Name), ptr(s));
end;

procedure TForm1.RSSpeedButton10Click(Sender: TObject);
var i:int;
begin
  if RSMessageBox(Handle, SSaveShadowQuestion,
       SSaveShadowQuestionCaption, MB_ICONQUESTION or MB_YESNO) <> mrYes then
    exit;

  try
    BeginMake(false);
    ColorBoxToColors(ColorBox1, false);
    if CheckStColors.Checked then
      UseStandardColors;

    for i:=0 to List.Count-1 do
    begin
      PutBmpSpec(Bmp[i], BmpSpec[i]);
      MakeBackup(string(TTreeNode(List.Objects[i]).Data));
      Bmp[i].SaveToFile(string(TTreeNode(List.Objects[i]).Data));
    end;
  finally
    ClearMake;
  end;

  WasChanged:= true;
  ShadowType:= 0;
  RSSpeedButton1.Down:= false;
  RSSpeedButton22.Down:= false;
end;

procedure TForm1.DragTimerTimer(Sender: TObject);
begin
  DragTargetNode.Expanded := not DragTargetNode.Expanded;
  DragTimer.Enabled:= false;
end;

procedure TForm1.DragWndProc(var m: TMessage);
var
  dir: int;
  P: TPoint;
begin
  if m.Msg = WM_RBUTTONUP then
  begin
    TreeView1.EndDrag(false);
    exit;
  end;

  with m do
    Result:= CallWindowProc(OldDragWndProc, DragHWnd, Msg, WParam, LParam);

  if m.Msg = WM_MOUSEMOVE then
  begin
    P:= SmallPointToPoint(TWMMouse(m).Pos);
    Windows.ClientToScreen(DragHWnd, p);
    with TreeView1 do
    begin
      p:= ScreenToClient(p);
      if p.Y < 0 then
        dir:= SB_LINEUP
      else if p.Y >= ClientHeight then
        dir:= SB_LINEDOWN
      else
        exit;

      Perform(WM_VSCROLL, dir, 0);
    end;
  end;
end;

procedure TForm1.DrawListFile(View: TRSShellListView);
begin
  with View.SelectedFile do
    if (GetSelf<>nil) and not IsFolder then
      SetPicture(FullName, true)
    else
//      DrawTreeBitmap;     // !!! Щас так уже нельзя будет
      SetPicture('', true);
end;

procedure TForm1.TreeView1WndProc(Sender: TObject; var M: TMessage;
   var Handled: Boolean; const NextWndProc: TWndMethod);
var
  View: TRSShellListView;
  Item: TTVItem;
begin
  with TWMChar(M) do
    case Msg of
      WM_CHAR, WM_KEYDOWN, WM_KEYUP:
        if (CharCode = VK_RETURN) and not TreeView1.IsEditing then
        begin
          View:= nil;
          if PageControl1.TabIndex = 1 then
            View:= RSShellListView1
          else
            if (PageControl1.TabIndex = 2) and RSSpeedButton20.Down then
              View:= RSShellListView2;

          if View<>nil then
          begin
            Handled:= true;
            View.WindowProc(M);
            View.SetFocus;
          end;
        end;
      CN_NOTIFY:
        with TreeView1, TWMNotify(m), PNMTreeView(NMHdr).itemNew do
          if NMHdr^.code = TVN_BEGINDRAG then
            if TreeView_GetParent(Handle, hItem) = nil then
            begin
              Handled:= true;
              Item.mask := TVIF_STATE;
              Item.hItem := hItem;
              if TreeView_GetItem(Handle, Item) and ((Item.state and TVIS_SELECTED) = 0) then
                Perform(TVM_SELECTITEM, TVGN_CARET or TVSI_NOSINGLEEXPAND, int(hItem));
            end;
      WM_LBUTTONDOWN:
        if DragNode = nil then
        begin
          NextWndProc(m);
          Handled:= true;
          if DragNode <> nil then
            HookDragWindow;
        end;
    end;
end;

procedure TForm1.CheckBitmapsClick(Sender: TObject);
var b:Boolean;
begin
  b:= CheckBitmaps.Checked;
  if b and (EditBitmapsPath.Text = '') and FileChosen then
    EditBitmapsPath.Text:= ExtractFilePath(FileName) + 'Ready\';
  EditBitmapsPath.Enabled:= b;
  CheckBitmapsLod.Enabled:= b;
  SpeedButtonBitmaps.Enabled:= b;
  SpeedButtonPictures.Enabled:= b;
  SpeedButtonByOne.Enabled:= b;
  SpeedButtonPictures.DrawFrame:= b;
  SpeedButtonByOne.DrawFrame:= b;
  b:= b and CheckBitmapsLod.Checked;
  EditBitmapsLod.Enabled:= b;
  SpeedButtonBitmapsLod.Enabled:= b;
  wasChanged:= true;
end;

procedure TForm1.SpeedButtonBitmapsLodClick(Sender: TObject);
begin
  with OpenLodDialog, EditBitmapsLod do
  begin
    FileName:= Text;
    if Execute then
    begin
      Text:= FileName;
      WasChanged:= true;
    end;
  end;
end;

procedure TForm1.SpeedButtonBitmapsClick(Sender: TObject);
begin
  if EditBitmapsPath.Text = '' then
    SetSaveShadowDialogPath
  else
    SaveShadowDialog.FileName:=
      IncludeTrailingPathDelimiter(EditBitmapsPath.Text) + SSaveHere;

  if not SaveShadowDialog.Execute then  exit;
  EditBitmapsPath.Text:= ExtractFilePath(SaveShadowDialog.FileName);
  WasChanged:= true;
end;

procedure TForm1.SpeedButtonLodBitmapsClick(Sender: TObject);
begin
  with OpenLodDialog, EditLodBitmaps do
  begin
    FileName:= Text;
    if Execute then
      Text:= FileName;
  end;
end;

procedure TForm1.TabSheet5Hide(Sender: TObject);
begin
  SaveIni;
end;

procedure TForm1.SpeedButtonByOneClick(Sender: TObject);
begin
  MakePictures(true);
end;

procedure TForm1.SpeedButtonPicturesClick(Sender: TObject);
begin
  MakePictures(false);
end;

procedure TForm1.PaintBox1Resize(Sender: TObject);
begin
  InvalidateRect(TWinControl(Sender).Handle, nil, false);
  UpdateWindow(TWinControl(Sender).Handle);
end;

procedure TForm1.RSEdit1Resize(Sender: TObject);
begin
  UpdateWindow(TWinControl(Sender).Handle);
end;

procedure TForm1.Edit5WndProc(Sender: TObject; var Msg: TMessage;
  var Handled: Boolean; const NextWndProc: TWndMethod);
begin
  NextWndProc(Msg);
  Handled:= true;
  if Msg.Msg = WM_RBUTTONUP then
    RSHelpHint(Sender);
end;

procedure TForm1.Edit5ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
  Handled:= true;
end;

procedure TForm1.CheckBitmapsLodClick(Sender: TObject);
var b:Boolean;
begin
  b:= CheckBitmaps.Checked and CheckBitmapsLod.Checked;
  EditBitmapsLod.Enabled:= b;
  SpeedButtonBitmapsLod.Enabled:= b;
  wasChanged:= true;
end;

procedure TForm1.Refocus(Page:int; DefFocus:HWnd = 0);
var h:HWnd;
begin
  h:= GetFocus;
  if not IsChild(PageControl1.Pages[Page].Handle, h) and (h<>PageControl1.Handle) then
    exit;

  h:= Focuses[Page];
  if h = 0 then
    if DefFocus = 0 then
      PageControl1.SetFocus
    else
      Windows.SetFocus(DefFocus)
  else
    Windows.SetFocus(h);
end;

procedure TForm1.TabSheet6Show(Sender: TObject);
begin
  Refocus(5, MemoHelp.Handle);
end;

procedure TForm1.PageControl1Change(Sender: TObject);
var i:int;
begin
  i:= PageControl1.ActivePageIndex;
  if Assigned(OnShows[i]) then
    OnShows[i](PageControl1)
  else
    Refocus(i);

  RSTimer1.Enabled:= (i = 0) and not (TypeIndex in [5, 6, 7]);
end;

procedure TForm1.RSShellListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var i:int; b:Boolean;
begin
  with TRSShellListView(Sender) do
    case Key of
      VK_RETURN:
        if (not GetSelectedIndex(i) or
              (Files[i]<>nil) and not Files[i].IsFolder) and
           (Root <> nil) and Root.IsFileSystem then
        begin
          b:= Sender = RSShellListView2;
          i:= NextSelected;
          if i<0 then  exit;

          BlockRepaint:= true;
          try
            repeat
              with Files[i] do
                if (GetSelf <> nil) and not IsFolder and IsFileSystem then
                  AddToTree(Files[i].FullName, b);

              i:= NextSelected(i);
            until i<0;
          finally
            BlockRepaint:= false;
            DrawTreeBitmap;
          end;
        end;

      ord('A'):
        if (Shift*[ssShift, ssAlt, ssCtrl] = [ssCtrl]) then
        begin
          for i:=0 to length(Root.Files)-1 do
            ListView_SetItemState(Handle, i, LVIS_SELECTED *
              BoolToInt[(Root.Files[i]<>nil) and not Root.Files[i].IsFolder],
              LVIS_SELECTED);

          Key:=0;
        end;
  end;
end;

procedure TForm1.FillLanguage(Items: TStrings; LangDir: string);
begin
  Items.Clear;
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

  if Items.IndexOf('English')<=0 then
    Items.Add('English');
end;

function TForm1.FindFrame(Level:int = 1):TTreeNode;
var i:int;
begin
  for i:= 0 to TreeView1.Items.Count-1 do
    if TreeView1.Items[i].Level = Level then
    begin
      Result:= TreeView1.Items[i];
      exit;
    end;
  Result:= nil;
end;

procedure TForm1.ApplicationEvents1Exception(Sender: TObject;
  e: Exception);
begin
  if not (e is EMakeError) and not (e is EFOpenError) then
    AppendDebugLog(RSLogExceptions);
  Application.ShowException(E);
end;

procedure TForm1.RSShellListView1DblClick(Sender: TObject);
begin
  with TRSShellListView(Sender).SelectedFile do
    if (GetSelf <> nil) and not IsFolder and IsFileSystem then
      AddToTree(FullName, Sender = RSShellListView2);
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

procedure TForm1.TreeView1StartDrag(Sender: TObject;
  var DragObject: TDragObject);
begin
  with Sender as TTreeView do
    DragNode:= Selected;
  DragTargetNode:= nil;
  DragTimer.Enabled:= false;
  InvalidateRect(TreeView1.Handle, nil, false);
end;

end.
