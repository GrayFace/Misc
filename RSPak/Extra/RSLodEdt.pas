unit RSLodEdt;

interface

uses
  SysUtils, Windows, Messages, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, RSDef, ExtCtrls, RSSysUtils, RSQ, RSPanel, RSTrackBar,
  ComCtrls, RSUtils, RSTimer, Buttons, RSSpeedButton, RSLod, Themes, RSGraphics,
  CommCtrl, Menus, ImgList, RSTreeView, Math, RSClipboard, RSListView, RSMenus,
  RSDialogs, RSMemo, RSPopupMenu, RSLang, RSFileAssociation, RSComboBox,
  RSJvPcx, ShellAPI, Types, RSDefLod, MMSystem, RSRadPlay, IniFiles, RSRecent,
  RSQHelp1, dzlib, RSRegistry, GIFImage, RSStrUtils, DragDrop, DropSource,
  DragDropFile;

{
Version 1.0.1:
[-] MMArchive couldn't find palettes for variations of some sprites.
[-] After picking def type filter and opening archive without Def files no files were shown.

Version 1.0.2:
[-] Bitmaps import didn't work for many bitmaps (power of 4 check instead of power of 2)

Version 1.0.3:
[-] Double click on file resulted in an error
[-] Pressing any key while extension filter is focused triggered an exit

Version 1.1:
[+] Full files Drag&Drop and Copy&Paste support
[+] "Merge With..." menu item
[+] "Extract For DefTool..." menu item 
[+] When importing 24 bit bitmaps into icons.lod an adequate palette is generated
[+] Drag&dropping an archive gets it opened. You can still add an archive as a file using "Add" menu item.
[+] *.pac files association
[+] Def frame shown under trackbar
[+] Text format for Favorites list ("Store Favorites As Text" menu item)
[+] Favorites can be sorted manually
[+] Shift+Delete removes the file without creating a backup
[+] Rename
[+] Custom lods support
[+] RLE bitmaps support (including those saved by PhotoShop) 
[-] Palette numbers weren't displayed for bitmaps.lod files in MM
[-] Critical bug in adding files to VID archives
[-] Adding files to games.lod wasn't handled properly
[-] File backups were only created for LOD archives
[-] Files added to MM SND archives weren't being compressed
[-] Crash when quickly browsing through SND archives
[-] Big Favorites list was causing a delay on close
[-] Favorites list wasn't saved in some usage scenarios
[-] Drag&drop issues of Favorites list
[-] Sometimes MMArchive wasn't able to select the file chosen in Favorites
[*] Better handling of corrupt files in SND archives
[*] Proper delays for adventure map defs

Version 1.1.1:
[-] Crash on some computers

Version 1.2:
[+] "Compare To..." and "Export Selection As Archive" items incorpotate LodCompare functionality
[+] "Common Extraction Folder" option - this was the default, now files are extracted into the archive folder by default
[+] Extract overwrite prompt
[-] Extra bytes were added to MM7&MM8 .vid archives
[-] Rename was buggy, corrupting files
[-] Wrong fonts on Vista and above
[-] MM8 saves detection: was .mm8 instead of .dod
[-] Inability to load some bitmaps

Version 1.2.1:
[-] Previous version was crashing on Windows XP
[-] Clipboard-related crash on exit
[-] Crash when loading another archive while in Compare To mode
[-] After drag-drop of the same archive, files list wasn't updated after operations

Version 1.3:
[+] bitmaps.lwd support
[+] Better transparent color detection
[+] Palettes preview
[+] After you create an archive from a selection of files, it's added to recent files list
[-] Unpacking errors while dragging files onto other apps were leading to MMArchive hanging
[-] "Ignore Unpacking Errors" option state wasn't preserved on program restart
[-] When creating new archive default file type was misleading  

Возможность выбора номера анимации дефа для показа
other file types
}

//var aDragging:Boolean;

type
  TRSLodEdit = class;
  //TRSLodPreviewMode = set of (RSlpNoFavorites, RSlpNoPreview);
  TRSLodSelectFileEvent = procedure(Sender: TRSLodEdit; Index: Integer) of object;

  TRSLodEdit = class(TForm)
    OpenDialog1: TRSOpenSaveDialog;
    Panel2: TRSPanel;
    Panel3: TRSPanel;
    Panel1: TRSPanel;
    Image1: TImage;
    RSSpeedButton1: TRSSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    ListView1: TRSListView;
    RSSpeedButton2: TRSSpeedButton;
    Timer1: TRSTimer;
    TreeView1: TRSTreeView;
    PopupTree: TRSPopupMenu;
    AddFolder1: TMenuItem;
    AddFile1: TMenuItem;
    ImageList1: TImageList;
    Rename1: TMenuItem;
    N1: TMenuItem;
    PopupList: TRSPopupMenu;
    Extract1: TMenuItem;
    AddtoFavorites1: TMenuItem;
    ExtractTo1: TMenuItem;
    Cut1: TMenuItem;
    Paste1: TMenuItem;
    MergeFavorites1: TMenuItem;
    N2: TMenuItem;
    Delete1: TMenuItem;
    Copy1: TMenuItem;
    Panel4: TRSPanel;
    Panel5: TRSPanel;
    Button1: TButton;
    Button2: TButton;
    Select1: TMenuItem;
    OpenDialog2: TRSOpenSaveDialog;
    Timer2: TRSTimer;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    N3: TMenuItem;
    RecentFiles1: TMenuItem;
    N4: TMenuItem;
    Exit1: TMenuItem;
    Edit1: TMenuItem;
    Extract2: TMenuItem;
    ExtractTo2: TMenuItem;
    AddtoFavorites2: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    Rebuild1: TMenuItem;
    N7: TMenuItem;
    Delete2: TMenuItem;
    SaveDialogExport: TSaveDialog;
    RSMemo1: TRSMemo;
    TrackBar1: TRSTrackBar;
    Add1: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    Delete3: TMenuItem;
    Options1: TMenuItem;
    Help1: TMenuItem;
    Associate1: TMenuItem;
    ComboExtFilter: TRSComboBox;
    OpenDialogImport: TOpenDialog;
    N10: TMenuItem;
    SaveDialogNew: TSaveDialog;
    Associate3: TMenuItem;
    Associate2: TMenuItem;
    Sortbyextension1: TMenuItem;
    OpenDialogBitmapsLod: TOpenDialog;
    TmpRecent1: TMenuItem;
    Def1: TMenuItem;
    OriginalPalette1: TMenuItem;
    NormalPalette1: TMenuItem;
    TransparentBackground1: TMenuItem;
    N11: TMenuItem;
    Backup1: TMenuItem;
    Language1: TMenuItem;
    English1: TMenuItem;
    Label1: TLabel;
    Palette1: TMenuItem;
    Default1: TMenuItem;
    FirstKind1: TMenuItem;
    SecondKind1: TMenuItem;
    ThirdKind1: TMenuItem;
    IgnoreUnpackingErrors1: TMenuItem;
    N12: TMenuItem;
    ShowAll1: TMenuItem;
    Spells1: TMenuItem;
    ShowMapObjects1: TMenuItem;
    ShowHeroes1: TMenuItem;
    ShowTerrain1: TMenuItem;
    ShowCursors1: TMenuItem;
    ShowInterface1: TMenuItem;
    ShowCombatHeroes1: TMenuItem;
    ShowCreatures1: TMenuItem;
    MergeWith1: TMenuItem;
    OpenDialogMerge: TRSOpenSaveDialog;
    PanelRebuilding: TRSPanel;
    Copy3: TMenuItem;
    Associate4: TMenuItem;
    ExtractForDefTool1: TMenuItem;
    ExtractForDefTool2: TMenuItem;
    N13: TMenuItem;
    ExtractWithExternalShadow1: TMenuItem;
    ExtractIn24Bits1: TMenuItem;
    N14: TMenuItem;
    StoreAsText1: TMenuItem;
    MoveUp1: TMenuItem;
    MoveDown1: TMenuItem;
    N15: TMenuItem;
    SortTreeByName1: TMenuItem;
    SortByName1: TMenuItem;
    DragTimer: TTimer;
    Rename2: TMenuItem;
    UnusedMenu: TPopupMenu;
    DropFileSource1: TDropFileSource;
    N16: TMenuItem;
    CopyName1: TMenuItem;
    Paste2: TMenuItem;
    Copy2: TMenuItem;
    N17: TMenuItem;
    Paste3: TMenuItem;
    Rename3: TMenuItem;
    DeselectTimer: TTimer;
    CommonExtractionFolder1: TMenuItem;
    SaveSelectionAsArchive1: TMenuItem;
    SaveDialogSaveSelectionAs: TSaveDialog;
    CompareTo1: TMenuItem;
    OpenDialogCompare: TRSOpenSaveDialog;
    Associate5: TMenuItem;
    procedure Associate5Click(Sender: TObject);
    procedure CompareTo1Click(Sender: TObject);
    procedure SaveSelectionAsArchive1Click(Sender: TObject);
    procedure CommonExtractionFolder1Click(Sender: TObject);
    procedure DeselectTimerTimer(Sender: TObject);
    procedure SaveDialogNewTypeChange(Sender: TObject);
    procedure CopyName1Click(Sender: TObject);
    procedure Paste2Click(Sender: TObject);
    procedure DropFileSource1AfterDrop(Sender: TObject; DragResult: TDragResult;
      Optimized: Boolean);
    procedure DropFileSource1Drop(Sender: TObject; DragType: TDragType;
      var ContinueDrop: Boolean);
    procedure PopupListAllowShortCut(Sender: TMenu; var Message: TWMKey;
      var Allow: Boolean);
    procedure Rename2Click(Sender: TObject);
    procedure ListView1Editing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure ListView1Edited(Sender: TObject; Item: TListItem; var S: string);
    procedure DragTimerTimer(Sender: TObject);
    procedure TreeView1WndProc(Sender: TObject; var m: TMessage;
      var Handled: Boolean; const NextWndProc: TWndMethod);
    procedure TreeView1StartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure SortTreeByName1Click(Sender: TObject);
    procedure SortByName1Click(Sender: TObject);
    procedure MoveDown1Click(Sender: TObject);
    procedure MoveUp1Click(Sender: TObject);
    procedure StoreAsText1Click(Sender: TObject);
    procedure ExtractForDefTool1Click(Sender: TObject);
    procedure Associate4Click(Sender: TObject);
    procedure Copy2Click(Sender: TObject);
    procedure MergeWith1Click(Sender: TObject);
    procedure ComboExtFilterKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ComboExtFilterDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure ShowCombatHeroes1Click(Sender: TObject);
    procedure ShowInterface1Click(Sender: TObject);
    procedure ShowCursors1Click(Sender: TObject);
    procedure ShowTerrain1Click(Sender: TObject);
    procedure ShowHeroes1Click(Sender: TObject);
    procedure ShowCreatures1Click(Sender: TObject);
    procedure ShowMapObjects1Click(Sender: TObject);
    procedure Spells1Click(Sender: TObject);
    procedure ShowAll1Click(Sender: TObject);
    procedure IgnoreUnpackingErrors1Click(Sender: TObject);
    procedure Default1Click(Sender: TObject);
    procedure Help1Click(Sender: TObject);
    procedure Language1Click(Sender: TObject);
    procedure English1Click(Sender: TObject);
    procedure Backup1Click(Sender: TObject);
    procedure Image1DblClick(Sender: TObject);
    procedure Sortbyextension1Click(Sender: TObject);
    procedure Rebuild1Click(Sender: TObject);
    procedure Associate3Click(Sender: TObject);
    procedure Associate2Click(Sender: TObject);
    procedure ListView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Add1Click(Sender: TObject);
    procedure ComboExtFilterSelect(Sender: TObject);
    procedure Options1Click(Sender: TObject);
    procedure Associate1Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RSSpeedButton1Click(Sender: TObject);
    procedure RSSpeedButton2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure TreeView1Collapsing(Sender: TObject; Node: TTreeNode;
      var AllowCollapse: Boolean);
    procedure TreeView1Editing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure TreeView1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure AddFolder1Click(Sender: TObject);
    procedure AddFile1Click(Sender: TObject);
    procedure TreeView1Edited(Sender: TObject; Node: TTreeNode;
      var S: String);
    procedure TreeView1CancelEdit(Sender: TObject; Node: TTreeNode);
    procedure Delete1Click(Sender: TObject);
    procedure TreeView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Rename1Click(Sender: TObject);
    procedure TreeView1KeyPress(Sender: TObject; var Key: Char);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure AddtoFavorites1Click(Sender: TObject);
    procedure ListView1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure TreeView1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure TreeView1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Cut1Click(Sender: TObject);
    procedure Paste1Click(Sender: TObject);
    procedure Copy1Click(Sender: TObject);
    procedure TreeView1CreateNodeClass(Sender: TCustomTreeView;
      var NodeClass: TTreeNodeClass);
    procedure Button1Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure MergeFavorites1Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure ListView1Change(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure RSSpeedButton3Click(Sender: TObject);
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure Open1Click(Sender: TObject);
    procedure File1Click(Sender: TObject);
    procedure New1Click(Sender: TObject);
    procedure ListView1DataFind(Sender: TObject; Find: TItemFind;
      const FindString: String; const FindPosition: TPoint;
      FindData: Pointer; StartIndex: Integer; Direction: TSearchDirection;
      Wrap: Boolean; var Index: Integer);
    procedure Delete2Click(Sender: TObject);
    procedure Extract1Click(Sender: TObject);
    procedure ExtractTo1Click(Sender: TObject);
    procedure Panel1Paint(Sender: TRSCustomControl; State: TRSControlState;
      DefaultPaint: TRSProcedure);
    procedure PopupListPopup(Sender: TObject);
    procedure Edit1Click(Sender: TObject);
    procedure TrackBar1AdjustClickRect(Sender: TRSTrackBar; var r: TRect);
    procedure ListView1WndProc(Sender: TObject; var Msg: TMessage;
      var Handled: Boolean; const NextWndProc: TWndMethod);
    procedure Exit1Click(Sender: TObject);
    procedure TreeView1EndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure PopupTreePopup(Sender: TObject);
    procedure PopupTreeAfterPopup(Sender: TObject);
    procedure DefaultPalette1Click(Sender: TObject);
  private
    FLanguage: string;
    FDefFilter: int;
    FAppCaption: string;
    FOnSelectFile: TRSLodSelectFileEvent;
    procedure SetAppCaption(const v: string);
    procedure SetLanguage(const v: string);
    procedure SetDefFilter(v: int);
  protected
    DragHWnd: HWND;
    OldDragWndProc: ptr;
    DragNodes: array of TTreeNode;
    DragTargetNode, DragNode : TTreeNode;

    PreviewBmp: TBitmap;
    FLightLoad: Boolean;
    FavsAsText: Boolean;
    FEditing: Boolean;
    Recent: TRSRecent;
    ItemIndexes: array of int;
    ItemCaptions: array of string;
    ArchiveIndexes: array of int;
    LastSel: int;
    Toolbar: TRSControlArray;
    FirstActivate: Boolean;
    FileBuffer: TRSByteArray;
    FileBitmap: TBitmap;
    PalFixList: TStringList;
    VideoPlayer: TRSRADPlayer;
    VideoStream: TStream;
    VideoPlayers: array[0..2] of TRSRADPlayer;
    LastPalString: string;
    FSFT: TMemoryStream;
    FSFTNotFound: Boolean;
    FSFTKind: int;
    FMyTempPath: string;
    FCopyStr: WideString;
    FDragFilesList: TStringList;
    FDragException: string;
    Ini: TIniFile;
    FilterItemVisible: array of Boolean;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMActivate(var Msg:TWMActivate); message WM_Activate;
    procedure WMSysCommand(var Msg:TWMSysCommand); message WM_SysCommand;
    procedure WMThemeChanged(var Msg:TMessage); message WM_ThemeChanged;
    procedure WMDropFiles(var m: TWMDropFiles); message WM_DropFiles;
    procedure WMHelp(var Msg:TMessage); message WM_Help;
    procedure FillDropSource(copy: Boolean = false);
    procedure ExtractDropSource(copy: Boolean = false);

    procedure HookDragWindow;
    procedure DragWndProc(var m: TMessage);

    procedure SetPreviewBmp(bmp: TBitmap);
    procedure UpdatePreviewBmp;
    function NeedPreviewBmp: TBitmap;
    function ConfirmBox(const msg: string): Boolean;
    procedure ErrorBox(const msg: string);
    procedure PreparePal(Sender: TRSDefWrapper; Pal:PLogPal);
    function SelCaption:string;
    procedure ThemeChanged;
    procedure MenuShortCut(Item: TMenuItem; var Result:string);
    function SwitchCheck(Item: TMenuItem; State: Boolean): Boolean;
    procedure UpdateToolbarState;
    procedure UpdateRecent;
    procedure RecentClick(Sender:TRSRecent; FileName:string);

    function DialogToFolder(dlg: TOpenDialog): string;
    function DefFilterProc(Sender: TRSLodEdit; i: int; var Str: string): Boolean;
    function ArrayFilterProc(Sender: TRSLodEdit; i: int; var Str: string): Boolean;
    function CancelCompare: Boolean;
    function GetDefAnimTime: int;
    function CanExtractDef: Boolean;
    procedure ListViewSelectItem(i: int; Chosen: Boolean);

    procedure LoadIni;
    procedure SaveIni;

    function AddTreeNode(s:string; Image:integer; EditName:boolean; Select:boolean=true):TTreeNode;
    procedure MoveNodeChildren(Source, Destination: TTreeNode; BaseIndex: int = 0);
    procedure MoveSelectedNodes(MoveUp: Boolean);
    procedure SortNode(Node: TTreeNode; Recursive: Boolean);
    procedure SortSelectedNodesByName(Recursive: Boolean);
    procedure DoLoadTree(const a: string; Node:TTreeNode=nil);
    function SaveNodes(Nodes:array of TTreeNode): string;
    function SaveTextNodes(Nodes:array of TTreeNode): string;
    function GetTreePath(FileName:string):string;
    procedure LoadTree(FileName:string);
    procedure SaveTree(FileName:string);
    procedure TrySaveTree;
    procedure UpdateNodeVisibility(Node: TTreeNode);
    procedure UpdateFavsVisibility(Node: TTreeNode = nil);

    procedure PrepareLoad;
    function BeginLoad(FileName, Filter:string):boolean;
    procedure EndLoad(SameFavs: Boolean);
    procedure ExtQSort(L, R: int);
    procedure ExtSort;
    function CompareArchivesItem(new, old: TRSMMArchive; i: int): Boolean;

    procedure CreateArchive(FileName: string);
    procedure FreeArchive;
    procedure ArchiveCreated;
    function ArchiveFileName: string;
    procedure CheckFileChanged;
    procedure DoRebuild(snd: Boolean);
    procedure DoExtract(Choose: Boolean; DefTool: Boolean = false);
    procedure DoAdd(Files:TStrings);
    procedure DoDelete(Backup: Boolean = true);
    procedure DoRename(i: int; const Name: string);
    procedure LoadFile(Index: int);
    procedure NeedBitmapsLod(Sender: TObject);
    procedure NeedPalette(Sender: TRSLod; Bitmap: TBitmap; var Palette: int);
    function NormalizePalette(b: TBitmap; HPal: HPALETTE): HPALETTE;
    procedure ConvertToPalette(Sender: TRSLod; b, b1: TBitmap);
    procedure SpritePaletteFixup(Sender: TRSLod; Name: string; var pal: int2; var Data);
    procedure FindSpritePal(name: string; var pal: int2; Kind: int = 1);
    procedure PlayVideo;
    procedure FreeVideo;
    procedure PleaseWait(const s: string = '');
    property Language: string read FLanguage write SetLanguage;
    property DefFilter: int read FDefFilter write SetDefFilter;
  public
    Favorites: string;
    ExtractPath: string;
    EmulatePopupShortCuts: boolean;
    Archive: TRSMMArchive;
    SpecFilter: function(Sender: TRSLodEdit; Index: int; var Str: string): Boolean of object;
    ShowOneGroup: Boolean;
    TrackBarMoveByTimer: Boolean;
    function LoadShowModal(Filter, DefSel:string; FileName:string=''):TModalResult;
    procedure Load(FileName:string);
    procedure Initialize(Editing:boolean=false; UseRSMenus:boolean=true);
    property AppCaption: string read FAppCaption write SetAppCaption;
    property OnSelectFile: TRSLodSelectFileEvent read FOnSelectFile write FOnSelectFile;
  end;

var
  RSLodEdit: TRSLodEdit;
  RSLodResult: string;

implementation

uses Registry;

{$R *.dfm}

type
  TMyFileType = (aNone, aDef, aBmp, aTxt, aMsk, aWav, aVideo, aPal, aPcx);

const
  AnyExt = '*.*';
  LangDir = 'Language\';
  TVSI_NOSINGLEEXPAND = $8000;

var
  FilterExt: string = AnyExt; DefaultSel:string;
  SelectingIndex:pint;
  CanSelectListView:boolean=true;
  ClipboardFormat:DWord; ClipboardBackup: string;
  Association1, Association2, Association3, Association4, Association5: TRSFileAssociation;
  ExceptionsSilenced: Boolean;
  DefColumnWidth: int = -1;
  FavsChanged: Boolean;

var
  Errors:array of Boolean; TrackBarChanging:boolean; Def:TRSDefWrapper;
  LastBmp:int;
  FileType: TMyFileType;

var
  EnterReaderModeHelper: function(Wnd: HWND): BOOL; stdcall;
  
var
  SDeleteQuestion: string = 'Are you sure you want to delete the file "%s" from archive?';
  SDeleteManyQuestion: string = 'Are you sure you want to delete the selected files from archive?';
  SNewFolder: string = 'New Folder';
  SExtractAs: string = 'Extract As...';
  SExtractTo: string;
  SEPaletteNotFound: string = 'Failed to find matching palette in bitmaps.lod';
  SEPaletteMustExist: string = 'Image must be in 256 colors mode and palette must be added to bitmaps.lod';
  SPalette: string = 'Palette: %d';
  SPaletteChanged: string = 'Palette: %d (shown: %d)';
  SFavorites: string = 'Favorites';
  SRenameOverwriteQuestion: string = 'A file with specified name (%s) already exists. Overwrite?';
  SExtractOverwriteFileQuestion: string = 'The following files already exist. Overwrite?%s';
  SExtractOverwriteDirQuestion: string = 'The following folders already exist. Overwrite?%s';
  SPleaseWait: string = 'Please wait...';
  SPleaseWaitRebuilding: string = 'Rebuilding the archive. Please wait...';

type
  PPalFix = ^TPalFix;
  TPalFix = record
    Name: string;
    Pal: int;
    Data: string;
  end;

const
  PalFix: array[1..53] of TPalFix = (
    (Name: 'BATATA0'; Pal: 156; Data: #211#26#0#0#226#0#226#0#166#1#0#0#60#0#255#255#75#101#0#0),
    (Name: 'BATATB0'; Pal: 156; Data: #188#37#0#0#254#0#17#1#166#1#0#0#0#0#255#255#218#113#0#0),
    (Name: 'BATATC0'; Pal: 156; Data: #75#51#0#0#62#1#44#1#166#1#0#0#1#0#255#255#169#148#0#0),
    (Name: 'BATATD0'; Pal: 156; Data: #212#50#0#0#23#1#29#1#166#1#0#0#1#0#255#255#209#145#0#0),
    (Name: 'BATATE0'; Pal: 156; Data: #167#27#0#0#114#1#176#0#166#1#0#0#1#0#255#255#236#107#0#0),
    (Name: 'BATATF0'; Pal: 156; Data: #225#22#0#0#114#1#85#0#166#1#0#0#1#0#255#255#41#55#0#0),
    (Name: 'BATDEA0'; Pal: 156; Data: #173#74#0#0#202#0#200#0#166#1#0#0#0#0#255#255#101#103#0#0),
    (Name: 'BATDEB0'; Pal: 156; Data: #34#47#0#0#13#1#119#0#166#1#0#0#0#0#255#255#155#64#0#0),
    (Name: 'BATDEC0'; Pal: 156; Data: #179#54#0#0#40#1#152#0#166#1#0#0#1#0#255#255#83#94#0#0),
    (Name: 'BATDED0'; Pal: 156; Data: #29#70#0#0#3#1#219#0#166#1#0#0#35#0#255#255#40#95#0#0),
    (Name: 'BATDEE0'; Pal: 156; Data: #219#28#0#0#197#0#110#0#166#1#0#0#7#0#255#255#155#33#0#0),
    (Name: 'BATDEF0'; Pal: 156; Data: #73#19#0#0#201#0#100#0#166#1#0#0#1#0#255#255#215#25#0#0),
    (Name: 'BATWAA0'; Pal: 156; Data: #40#25#0#0#45#1#228#0#166#1#0#0#69#0#255#255#202#91#0#0),
    (Name: 'BATWAA1'; Pal: 156; Data: #207#61#0#0#60#1#12#1#166#1#0#0#91#0#255#255#137#98#0#0),
    (Name: 'BATWAA2'; Pal: 156; Data: #69#53#0#0#184#0#22#1#166#1#0#0#93#0#255#255#68#69#0#0),
    (Name: 'BATWAA3'; Pal: 156; Data: #80#53#0#0#18#1#6#1#166#1#0#0#77#0#255#255#246#102#0#0),
    (Name: 'BATWAA4'; Pal: 156; Data: #28#22#0#0#84#1#234#0#166#1#0#0#54#0#255#255#247#105#0#0),
    (Name: 'BATWAB0'; Pal: 156; Data: #19#26#0#0#45#1#228#0#166#1#0#0#67#0#255#255#56#79#0#0),
    (Name: 'BATWAB1'; Pal: 156; Data: #91#53#0#0#60#1#12#1#166#1#0#0#90#0#255#255#251#87#0#0),
    (Name: 'BATWAB2'; Pal: 156; Data: #85#49#0#0#184#0#22#1#166#1#0#0#92#0#255#255#100#60#0#0),
    (Name: 'BATWAB3'; Pal: 156; Data: #181#58#0#0#18#1#6#1#166#1#0#0#76#0#255#255#149#97#0#0),
    (Name: 'BATWAB4'; Pal: 156; Data: #43#24#0#0#84#1#234#0#166#1#0#0#53#0#255#255#123#96#0#0),
    (Name: 'BATWAC0'; Pal: 156; Data: #104#21#0#0#45#1#228#0#166#1#0#0#68#0#255#255#25#71#0#0),
    (Name: 'BATWAC1'; Pal: 156; Data: #48#39#0#0#60#1#12#1#166#1#0#0#90#0#255#255#71#75#0#0),
    (Name: 'BATWAC2'; Pal: 156; Data: #52#39#0#0#184#0#22#1#166#1#0#0#93#0#255#255#143#47#0#0),
    (Name: 'BATWAC3'; Pal: 156; Data: #176#46#0#0#18#1#6#1#166#1#0#0#76#0#255#255#109#82#0#0),
    (Name: 'BATWAC4'; Pal: 156; Data: #72#22#0#0#84#1#234#0#166#1#0#0#53#0#255#255#168#89#0#0),
    (Name: 'BATWAD0'; Pal: 156; Data: #51#21#0#0#45#1#228#0#166#1#0#0#35#0#255#255#108#76#0#0),
    (Name: 'BATWAD1'; Pal: 156; Data: #250#40#0#0#60#1#12#1#166#1#0#0#47#0#255#255#48#71#0#0),
    (Name: 'BATWAD2'; Pal: 156; Data: #207#30#0#0#184#0#22#1#166#1#0#0#45#0#255#255#132#38#0#0),
    (Name: 'BATWAD3'; Pal: 156; Data: #98#33#0#0#18#1#6#1#166#1#0#0#34#0#255#255#186#69#0#0),
    (Name: 'BATWAD4'; Pal: 156; Data: #223#24#0#0#84#1#234#0#166#1#0#0#20#0#255#255#74#91#0#0),
    (Name: 'BATWAE0'; Pal: 156; Data: #237#48#0#0#45#1#228#0#166#1#0#0#56#0#255#255#239#76#0#0),
    (Name: 'BATWAE1'; Pal: 156; Data: #240#46#0#0#60#1#12#1#166#1#0#0#78#0#255#255#96#69#0#0),
    (Name: 'BATWAE2'; Pal: 156; Data: #213#20#0#0#184#0#22#1#166#1#0#0#80#0#255#255#137#25#0#0),
    (Name: 'BATWAE3'; Pal: 156; Data: #181#39#0#0#18#1#6#1#166#1#0#0#64#0#255#255#8#62#0#0),
    (Name: 'BATWAE4'; Pal: 156; Data: #235#55#0#0#84#1#234#0#166#1#0#0#40#0#255#255#189#89#0#0),
    (Name: 'BATWAF0'; Pal: 156; Data: #182#27#0#0#45#1#228#0#166#1#0#0#61#0#255#255#18#61#0#0),
    (Name: 'BATWAF1'; Pal: 156; Data: #139#43#0#0#60#1#12#1#166#1#0#0#83#0#255#255#167#65#0#0),
    (Name: 'BATWAF2'; Pal: 156; Data: #142#40#0#0#184#0#22#1#166#1#0#0#85#0#255#255#18#50#0#0),
    (Name: 'BATWAF3'; Pal: 156; Data: #162#43#0#0#18#1#6#1#166#1#0#0#69#0#255#255#92#62#0#0),
    (Name: 'BATWAF4'; Pal: 156; Data: #63#34#0#0#84#1#234#0#166#1#0#0#45#0#255#255#82#73#0#0),
    (Name: 'BATWIA0'; Pal: 156; Data: #130#23#0#0#223#0#205#0#166#1#0#0#47#0#255#255#240#89#0#0),
    (Name: 'BATWIB0'; Pal: 156; Data: #225#95#0#0#78#1#180#0#166#1#0#0#1#0#255#255#16#142#0#0),
    (Name: 'BATWIC0'; Pal: 156; Data: #231#108#0#0#56#1#208#0#166#1#0#0#1#0#255#255#134#161#0#0),
    (Name: 'BATWID0'; Pal: 156; Data: #157#101#0#0#82#1#217#0#166#1#0#0#2#0#255#255#13#151#0#0),
    (Name: 'BATWIE0'; Pal: 156; Data: #70#45#0#0#61#1#155#0#166#1#0#0#1#0#255#255#146#72#0#0),
    (Name: 'BATWIF0'; Pal: 156; Data: #130#28#0#0#193#0#251#0#166#1#0#0#1#0#255#255#238#61#0#0),
    (Name: 'swptree1'; Pal: 120; Data: #217#34#0#0#112#0#211#0#172#3#0#0#0#0#18#0#203#50#0#0),
    (Name: 'swptree2'; Pal: 120; Data: #184#71#0#0#136#0#73#1#172#3#0#0#0#0#18#0#220#105#0#0),
    (Name: 'swptree3'; Pal: 120; Data: #98#76#0#0#210#0#193#0#172#3#0#0#0#0#18#0#137#122#0#0),
    (Name: 'swptree4'; Pal: 120; Data: #30#68#0#0#25#1#71#1#172#3#0#0#0#0#18#0#163#213#0#0),
    ()
  );


type
  TMyStringList = class(TStringList)
    // expose important protected member GetTextStr
  end;

  TMyTreeNode = class(TTreeNode)
  private
    FHidden: Boolean;
    function GetIndex: int;
    procedure SetIndex(v: int);
    procedure SetHidden(v: Boolean);
    function GetFullCount:int;
    function DoAddItem(it: TMyTreeNode; hdn: Boolean; Index: int = MaxInt):TMyTreeNode; overload;
    procedure DoRemoveItem(it: TMyTreeNode);
  public
    AllItems: array of TMyTreeNode;
    GetParent: TMyTreeNode;
    FileName: string;
    Param2: string;
    destructor Destroy; override;
    function AddItem(s: string; hdn: Boolean; Index: int = MaxInt):TMyTreeNode; overload;
    function AddItem(it: TMyTreeNode; hdn: Boolean; Index: int = MaxInt):TMyTreeNode; overload;
    procedure MoveTo(Destination: TTreeNode; Mode: TNodeAttachMode); override;
    procedure MoveToIndex(NewParent: TTreeNode; i: int);
    procedure DeleteChildren;
    property Hidden: Boolean read FHidden write SetHidden;
    property FullCount:int read GetFullCount;
    property Index: int read GetIndex write SetIndex;
  end;
  TMyNode = TMyTreeNode;


destructor TMyTreeNode.Destroy;
var i:int;
begin
  FavsChanged:= true;
  for i:= length(AllItems)-1 downto 0 do
    if AllItems[i].Hidden then
      AllItems[i].Free;
  AllItems:= nil;
  if Parent <> nil then
    TMyTreeNode(Parent).DoRemoveItem(self);

  inherited Destroy;
end;

function TMyTreeNode.DoAddItem(it: TMyTreeNode; hdn: Boolean; Index: int): TMyTreeNode;
var i:int;
begin
  FavsChanged:= true;
  i:=length(AllItems);
  SetLength(AllItems, i+1);
  AllItems[i]:= it;
  if Index < i then
    ArrayInsert(AllItems, Index, SizeOf(AllItems[i]));
  Result:= it;
  it.FHidden:= hdn;
  it.GetParent:= self;
end;

procedure TMyTreeNode.DoRemoveItem(it: TMyTreeNode);
var
  i: int;
begin
  FavsChanged:= true;
  for i := length(AllItems) - 1 downto 0 do
    if AllItems[i] = it then
    begin
      ArrayDelete(AllItems, i, SizeOf(AllItems[0]));
      SetLength(AllItems, length(AllItems) - 1);
      break;
    end;
  it.GetParent:= nil;
end;

procedure TMyTreeNode.DeleteChildren;
var i:int;
begin
  FavsChanged:= true;
  for i:= length(AllItems)-1 downto 0 do
    if AllItems[i].Hidden then
      AllItems[i].Free;
  AllItems:= nil;
  inherited DeleteChildren;
end;

function TMyTreeNode.GetFullCount:int;
begin
  Result:= length(AllItems);
end;

function TMyTreeNode.GetIndex: int;
var
  i: int;
begin
  Result:= 0;
  if GetParent <> nil then
    with GetParent do
      for i := high(AllItems) downto 0 do
        if AllItems[i] = self then
        begin
          Result:= i;
          exit;
        end;
end;

function TMyTreeNode.AddItem(s: string; hdn: Boolean; Index: int): TMyTreeNode;
begin
  Result:= AddItem(TMyTreeNode.Create(Owner), hdn, Index);
  Result.Text:=s;
end;

function TMyTreeNode.AddItem(it: TMyTreeNode; hdn: Boolean; Index: int): TMyTreeNode;
begin
  Result:= DoAddItem(it, true, Index);
  it.Hidden:= hdn;
end;

procedure TMyTreeNode.MoveTo(Destination: TTreeNode; Mode: TNodeAttachMode);
var
  Dest: TMyNode;
  i, OldPos: int;
begin
  FavsChanged:= true;
  // check and exit if Destination.HasAsParent(self)
  Dest:= TMyNode(Destination);
  if Dest <> self then
    while Dest <> nil do
    begin
      if Dest = self then  exit;
      Dest:= Dest.GetParent;
    end;
  
  Dest:= TMyTreeNode(Destination);
  if (Dest <> nil) and not (Mode in [naAddChild, naAddChildFirst]) then
    Dest:= Dest.GetParent;
    
  if (GetParent = Dest) and (Dest <> nil) then
    OldPos:= Index
  else
    OldPos:= -1;

  if GetParent <> nil then
    GetParent.DoRemoveItem(self);
  if Dest <> nil then
  begin
    case Mode of
      naAddFirst, naAddChildFirst:
        i:= 0;
      naInsert:
        i:= TMyTreeNode(Destination).GetIndex;
      else
        i:= MaxInt;
    end;
    Dest.DoAddItem(self, Hidden, i);
  end;
  if not Hidden and (Dest <> nil) then  Dest.Hidden:= false;

  if (Destination <> nil) and TMyTreeNode(Destination).Hidden then
    case Mode of
      naAdd:
      begin
        Mode:= naAddChild;
        Destination:= Dest;
      end;
      naAddFirst:
      begin
        Mode:= naAddChildFirst;
        Destination:= Dest;
      end;
      naInsert:
      begin
        i:= TMyTreeNode(Destination).Index;
        Mode:= naAddChild;
        Destination:= Dest;
        for i := i + 1 to high(Dest.AllItems) do
          if not Dest.AllItems[i].Hidden then
          begin
            Mode:= naInsert;
            Destination:= Dest.AllItems[i];
          end;
      end;
    end;

  if Hidden then  exit;

  if OldPos >= 0 then  // check if physical moving is needed
  begin
    i:= Index;
    for i := min(i, OldPos) to max(i, OldPos) do
      if (Dest.AllItems[i] <> self) and not Dest.AllItems[i].Hidden then
        OldPos:= -1;
    if OldPos >= 0 then  exit;
  end;
  inherited;
end;



procedure TMyTreeNode.MoveToIndex(NewParent: TTreeNode; i: int);
var
  Dest: TMyTreeNode absolute NewParent;
  k: int;
begin
  if Dest = nil then
  begin
    MoveTo(Dest, naAddChild);
    exit;
  end;
  if i < 0 then
    i:= 0;

  if NewParent = GetParent then
  begin
    i:= min(i, high(Dest.AllItems));
    k:= Index;
    if k = i then  exit;
    if k < i then  inc(i);
  end;
  if i < length(Dest.AllItems) then
    MoveTo(Dest.AllItems[i], naInsert)
  else
    MoveTo(Dest, naAddChild);
end;

procedure TMyTreeNode.SetHidden(v: Boolean);
var
  TreeViewItem: TTVItem;
  i: int;
begin
  if FHidden = v then  exit;
  FHidden:= v;
  GetParent.Hidden:= false;
  if v then
  begin
    // crude way
    with TreeViewItem do
    begin
      mask := TVIF_PARAM;
      hItem := ItemId;
      lParam := 0;
    end;
    TreeView_SetItem(Handle, TreeViewItem);
    TreeView_DeleteItem(Handle, ItemId);
    pptr(@ItemId)^:= nil;
    for i := 0 to high(GetParent.AllItems) do
      if not GetParent.AllItems[i].Hidden then
        exit;
    GetParent.Expanded:= false;
    GetParent.HasChildren:= false;
  end else
  begin
    for i := Index + 1 to high(GetParent.AllItems) do
      if not GetParent.AllItems[i].Hidden then
      begin
        GetParent.Owner.InsertNode(self, GetParent.AllItems[i], Text, Data);
        exit;
      end;
    GetParent.Owner.AddNode(self, GetParent, Text, Data, naAddChild);
  end;
end;

procedure TMyTreeNode.SetIndex(v: int);
begin
  MoveToIndex(GetParent, v);
end;







{ functions }

procedure LoadBmp(i:integer; Bitmap:TBitmap);
begin
  if FileType<>aDef then exit;
  LastBmp:=i;
  if (length(Errors)>i) and not Errors[i] then
    try
{      if RSLodEdit.ShowOneGroup and (length(Def.Groups)>2) then
        Def.ExtractBmp(2, i, Bitmap, RSFullBmp)
      else
}
        Def.ExtractBmp(i, Bitmap, RSFullBmp);
    except
      on e:Exception do
      begin
        Errors[i]:=true;
        RSErrorHint(RSLodEdit.TrackBar1, e.Message, MaxInt);
      end;
    end
  else
    Bitmap.Assign(nil);
end;

procedure DoReStretch(Stretch: Boolean; w, h: int; var w1, h1: int);
begin
  if (w1 = 0) or (h1 = 0) then
  begin
    w1:= 1;
    h1:= 1;
    exit;
  end;
  if Stretch or (w1 > w) or (h1 > h) then
    if w1*h>w*h1 then
    begin
      h1:=(w*h1 + w1 div 2) div w1;
      w1:= w;
    end else
    begin
      w1:=(h*w1 + h1 div 2) div h1;
      h1:= h;
    end;
  if w1=0 then w1:=1;
  if h1=0 then h1:=1;
end;

procedure GetSortedSelectedNodes(tree: TRSTreeView; var ResizedNodesArray; Inverse: Boolean = false);
var
  Nodes: array of TMyNode absolute ResizedNodesArray;
  i, j: int;
begin
  for i:= 0 to high(Nodes) do
  begin
    Nodes[i]:= ptr(tree.Selections[i]);
    for j := 0 to i - 1 do
      if (Nodes[i].GetParent = Nodes[j].GetParent) and
         ((Nodes[i].Index > Nodes[j].Index) = Inverse) then
      begin
        CopyMemory(@Nodes[j + 1], @Nodes[j], PChar(@Nodes[i]) - PChar(@Nodes[j]));
        Nodes[j]:= ptr(tree.Selections[i]);
        break;
      end;
  end;
end;

procedure AddTextClipboardFormat(const s: WideString);
var
  Data: THandle;
  DataPtr: Pointer;
begin
  Clipboard.Open;
  try
    Data := GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE, (length(s) + 1)*SizeOf(s[1]));
    try
      DataPtr := GlobalLock(Data);
      try
        Move(PWideChar(s)^, DataPtr^, (length(s) + 1)*SizeOf(s[1]));
        SetClipboardData(CF_UNICODETEXT, Data);
      finally
        GlobalUnlock(Data);
      end;
    except
      GlobalFree(Data);
      raise;
    end;
  finally
    Clipboard.Close;
  end;
end;

{ TRSLodEdit }

procedure TRSLodEdit.WMActivate(var Msg:TWMActivate);
begin
  inherited;
  Timer1.Enabled:= (Msg.Active<>WA_INACTIVE) and not Msg.Minimized;
  Timer2.Enabled:= false;
  if (VideoPlayer <> nil) and (Timer1.Interval <> 0) then
    VideoPlayer.Pause:= not Timer1.Enabled;
  FSFTNotFound:= false;

  if FirstActivate then
  begin
    RSSetFocus(ListView1);
    ListView_EnsureVisible(ListView1.Handle, LastSel, false);
    FirstActivate:= false;
  end;

  if Msg.Active <> WA_INACTIVE then
    CheckFileChanged;
end;

procedure TRSLodEdit.WMDropFiles(var m: TWMDropFiles);
var
  i,n: int;
  s: string;
  sl: TStringList;
begin
  if not FEditing then  exit;

  sl:= TStringList.Create;
  try
    m.Result:= 0;
    n:= DragQueryFile(m.Drop, $FFFFFFFF, nil, 0);
    try
      for i := 0 to n - 1 do
      begin
        SetLength(s, DragQueryFile(m.Drop, i, nil, 0));
        if (s<>'') and (int(DragQueryFile(m.Drop, i, ptr(s), length(s)+1)) = length(s)) then
          sl.Add(s);
      end;
    finally
      DragFinish(m.Drop);
    end;
    if sl.Count = 1 then
    begin
      s:= LowerCase(ExtractFileExt(sl[0])) + '!';
      if RSParseStringSingleToken(s, 1, ['.lod', '.lwd', '.snd', '.vid', '.pac', '.mm6', '.mm7', '.dod']) = '!' then
      begin
        BeginLoad(sl[0], AnyExt);
        EndLoad(false);
        exit;
      end;
    end;
    CheckFileChanged;
    if Archive <> nil then
      DoAdd(sl);
  finally
    sl.Free;
  end;
end;

procedure TRSLodEdit.WMHelp(var Msg: TMessage);
begin
  if FEditing then
    RSHelpShow([], 600, 600);
end;

{
procedure TRSLodEdit.WMClose(var Msg:TWMClose);
begin
  Closing:=true;
  inherited;
end;
}

procedure TRSLodEdit.WMSysCommand(var Msg:TWMSysCommand);
begin
  if Msg.CmdType=SC_MINIMIZE then
  begin
    Msg.Result:=0;
    Application.Minimize;
  end else inherited;
end;

procedure TRSLodEdit.WMThemeChanged(var Msg:TMessage);
begin
  inherited;
  ThemeChanged;
end;

procedure TRSLodEdit.Backup1Click(Sender: TObject);
begin
  Backup1.Checked:= not Backup1.Checked;
  if Archive <> nil then
  begin
    Archive.BackupOnAdd:= Backup1.Checked;
    Archive.BackupOnDelete:= Backup1.Checked;
  end;
end;

function TRSLodEdit.BeginLoad(FileName, Filter:string):boolean;
var
  b: Boolean;
begin
  //s:=Lod.LodFileName;
  Result:=true;
  PrepareLoad;
  b:= CancelCompare;
  if (Archive <> nil) and (Archive.RawFiles.FileName = FileName) then
  begin
    FLightLoad:= (Filter = FilterExt) and not b;
    exit;
  end;
  CreateArchive(FileName);
  OpenDialog1.FileName:= FileName;
  if not CommonExtractionFolder1.Checked then
  begin
    ExtractPath:= '';
    SaveDialogExport.InitialDir:= ExtractFilePath(FileName);
    SaveDialogExport.FileName:= '';
    OpenDialogImport.InitialDir:= SaveDialogExport.InitialDir;
    OpenDialogImport.FileName:= '';
  end;
end;

procedure TRSLodEdit.EndLoad(SameFavs: Boolean);

  function FindDefs: Boolean;
  var
    i: int;
  begin
    Result:= true;
    with Archive.RawFiles do
      for i:=0 to Count-1 do
        if SameText(ExtractFileExt(Name[i]), '.def') then
          exit;
    Result:= false;
  end;

const
  ColPadding = 28;
var
  i, j, ColW: int;
  s, s1: string;
  sl: TStringList;
begin
  Def1.Visible:= (Archive is TRSLod) and (TRSLod(Archive).Version = RSLodHeroes) and FindDefs;
  if DefFilter <> 0 then
    if Def1.Visible then
      SpecFilter:= DefFilterProc
    else if FilterItemVisible <> nil then
      SpecFilter:= ArrayFilterProc
    else
      SpecFilter:= nil;

  Add1.Enabled:=true;
  TreeView1.Enabled:=true;

  if not SameFavs then
  begin
    CanSelectListView:= false;
    try
      TMyNode(TreeView1.Items[0]).DeleteChildren;
    except
    end;
    LoadTree(GetTreePath(ArchiveFileName));
    CanSelectListView:= true;
    FavsChanged:= false;
  end;

  if not FLightLoad then
  begin
    sl:= TStringList.Create;
    with Archive do
    try
      Timer1.Interval:=0;
      Timer2.Enabled:=false;

      sl.Sorted:= true;
      sl.Duplicates:= dupIgnore;
      SetPreviewBmp(nil);
      TrackBar1.Hide;
      RSSpeedButton1.Hide;
      RSSpeedButton2.Hide;
      ListView1.Items.Clear;
      ItemCaptions:=nil;
      SetLength(ItemCaptions, RawFiles.Count);
      ItemIndexes:=nil;
      SetLength(ItemIndexes, RawFiles.Count);
      SetLength(ArchiveIndexes, RawFiles.Count);

      if DefColumnWidth < 0 then
        DefColumnWidth:= ListView_GetColumnWidth(ListView1.Handle, 0);
      ColW:= DefColumnWidth;
      j:=0;
      for i:=0 to RawFiles.Count-1 do
      begin
        s:= RawFiles.Name[i];
        s1:= ExtractFileExt(s);
        sl.Add(LowerCase(s1));
        if (FilterExt <> AnyExt) and not SameText(s1, FilterExt) or
           (@SpecFilter <> nil) and not SpecFilter(self, i, s) then
        begin
          ArchiveIndexes[i]:=-1
        end else
        begin
          ItemCaptions[j]:=s;
          ItemIndexes[j]:=i;
          ArchiveIndexes[i]:=j;
          inc(j);
          ColW:= max(ColW, ListView_GetStringWidth(ListView1.Handle, ptr(s)) + ColPadding);
        end;
      end;
      ListView_SetColumnWidth(ListView1.Handle, 0, ColW);

      SetLength(ItemCaptions, j);
      SetLength(ItemIndexes, j);

      ListView1.Items.Count:=j;
      j:= sl.Add(AnyExt);
      if (FilterExt <> AnyExt) and not sl.Find(FilterExt, j) then
        j:= -1;

      if Sortbyextension1.Checked then
        ExtSort;

      ComboExtFilter.Items:= sl;
      ComboExtFilter.ItemIndex:= j
    finally
      sl.Free;
    end;
  end;
  FLightLoad:= false;


(*
      try
        Timer1.Interval:=0;
        Timer2.Enabled:=false;

        Image1.Picture.Bitmap:=nil;
        TrackBar1.Hide;
        RSSpeedButton2.Hide;
        RSSpeedButton3.Hide;
        ProgressBar1.Show;
        ProgressBar1.Position:=0;
        ProgressBar1.Max:=Lod.Count;
        Clear;
        for i:=0 to Lod.Count-1 do
        begin
          s:=GetFileName(i);
          if (FilterExt<>'') and not SameText(ExtractFileExt(s), FilterExt) or
             (@SpecFilter<>nil) and not SpecFilter(self, i, s) then

            PInt(Lod.UserData[i])^:=-1
          else
            with Add do
            begin
              Data:=ptr(i);
              Caption:=s;
              PInt(Lod.UserData[i])^:=Index;
            end;
  {          with it do
            begin
              mask:=LVIF_TEXT;
              iItem:=0;
              iSubItem:=0;
              state:=0;
              stateMask:=uint(-1);
              pszText:=ptr(s);
              ListView_InsertItem(ListView1.Handle, it);
              //Lod.FFilesStruct[i].Unk:=Index;
            end }
          if i mod 64 = 0 then
          begin
            ProgressBar1.Position:=i;
            Application.ProcessMessages;
            if Closing then exit;
          end;
        end;

        BeginUpdate;

            Add.Index:=i;
            ListView1.Items.Count:=5;
      finally
        ProgressBar1.Hide;
        if Closing then
        begin
          Lod.LodFileName:='';
          Clear;
        end;
        EndUpdate;
      end;
*)

  if (DefaultSel <> '') and Archive.RawFiles.FindFile(DefaultSel, i) then
  begin
    i:= ArchiveIndexes[i];
    if i>=0 then
    begin
      ListView_SetItemState(ListView1.Handle, i, LVIS_SELECTED or LVIS_FOCUSED,
                                              LVIS_SELECTED or LVIS_FOCUSED);
      ListView_EnsureVisible(ListView1.Handle, i, false);
    end;
  end;
  FirstActivate:= true;
end;

procedure TRSLodEdit.English1Click(Sender: TObject);
begin
  with TMenuItem(Sender) do
    if not Checked then
      Language:= StripHotkey(Caption);
end;

procedure TRSLodEdit.ErrorBox(const msg: string);
begin
  RSMessageBox(Handle, msg, '', MB_ICONERROR);
end;

function TRSLodEdit.LoadShowModal(Filter, DefSel:string;
  FileName:string=''):TModalResult;
begin
  Result:=mrCancel;
  if FileName<>'' then
    OpenDialog1.FileName:= FileName
  else
    if not OpenDialog1.Execute then  exit;

  if not BeginLoad(OpenDialog1.FileName, Filter) then exit;
  FilterExt:=Filter;
  DefaultSel:=DefSel;
  EndLoad(false);
  Result:=ShowModal;
  DestroyHandle;
//  Closing:=false;
end;

procedure TRSLodEdit.Load(FileName:string);
begin
  if (FileName<>'') and BeginLoad(FileName, AnyExt) then
  begin
    FilterExt:= AnyExt;
    EndLoad(false);
  end;
end;

function TRSLodEdit.SelCaption:string;
begin
  Result:= Archive.RawFiles.Name[ItemIndexes[LastSel]];
end;

procedure TRSLodEdit.SetAppCaption(const v: string);
var
  s, s1: string;
begin
  FAppCaption:= v;
  s:= ArchiveFileName;
  if (AppCaption <> '') and (s <> '') then
    s1:= ' - ' + AppCaption
  else
    s1:= AppCaption;

  if FEditing then
  begin
    Caption:= s + s1;
    Application.Title:= ExtractFileName(s) + s1;
  end else
    Caption:= ExtractFileName(s) + s1;
end;

procedure TRSLodEdit.SetDefFilter(v: int);
begin
  if v = FDefFilter then  exit;
  FDefFilter:= v;
  if ListView1.Selected<>nil then
    DefaultSel:= SelCaption;
  if Archive <> nil then
    EndLoad(true);
end;

procedure TRSLodEdit.SetLanguage(const v: string);
var
  s: string;
  i: int;
begin
  s:= AppPath + LangDir + v + '.txt';
  if not FileExists(s) then
  begin
    if SameText(FLanguage, 'English') then  exit;
    FLanguage:= 'English';
    s:= AppPath + LangDir + 'English.txt';
  end else
    FLanguage:= v;
  RSLanguage.LoadLanguage(RSLanguage.LanguageBackup, true);
  try
    RSLanguage.LoadLanguage(RSLoadTextFile(s), true);
  except
  end;
  //RSSaveTextFile(AppPath + LangDir + 'tmp.txt', RSLanguage.MakeLanguage);

  RSMenu.Font.Charset:= Font.Charset;
  TreeView1.Items[0].Text:= SFavorites;

  for i := 0 to length(Toolbar) - 1 do
    if Toolbar[i] is TRSSpeedButton then
      with TRSSpeedButton(Toolbar[i]) do
        Hint:= StripHotkey(TMenuItem(Tag).Caption);

  UpdateToolbarState;

  with RSHelp.Memo1 do
    Text:= RSStringReplace(Text, '%VERSION%', RSGetModuleVersion);
end;

procedure TRSLodEdit.SetPreviewBmp(bmp: TBitmap);
begin
  PreviewBmp.Free;
  PreviewBmp:= bmp;
  UpdatePreviewBmp;
end;

procedure TRSLodEdit.ShowAll1Click(Sender: TObject);
begin
  SwitchCheck(Sender as TMenuItem, true);
  DefFilter:= 0;
end;

procedure TRSLodEdit.ShowCombatHeroes1Click(Sender: TObject);
begin
  SwitchCheck(Sender as TMenuItem, true);
  DefFilter:= $49;
end;

procedure TRSLodEdit.ShowCreatures1Click(Sender: TObject);
begin
  SwitchCheck(Sender as TMenuItem, true);
  DefFilter:= $42;
end;

procedure TRSLodEdit.ShowCursors1Click(Sender: TObject);
begin
  SwitchCheck(Sender as TMenuItem, true);
  DefFilter:= $46;
end;

procedure TRSLodEdit.ShowHeroes1Click(Sender: TObject);
begin
  SwitchCheck(Sender as TMenuItem, true);
  DefFilter:= $44;
end;

procedure TRSLodEdit.ShowInterface1Click(Sender: TObject);
begin
  SwitchCheck(Sender as TMenuItem, true);
  DefFilter:= $47;
end;

procedure TRSLodEdit.ShowMapObjects1Click(Sender: TObject);
begin
  SwitchCheck(Sender as TMenuItem, true);
  DefFilter:= $43;
end;

procedure TRSLodEdit.ShowTerrain1Click(Sender: TObject);
begin
  SwitchCheck(Sender as TMenuItem, true);
  DefFilter:= $45;
end;

procedure TRSLodEdit.Sortbyextension1Click(Sender: TObject);
begin
  SwitchCheck(Sortbyextension1, not Sortbyextension1.Checked);
  if ListView1.Selected<>nil then
    DefaultSel:= SelCaption;
  if Archive <> nil then
    EndLoad(true);
end;

procedure TRSLodEdit.SortTreeByName1Click(Sender: TObject);
begin
  SortSelectedNodesByName(true);
end;

procedure TRSLodEdit.SortByName1Click(Sender: TObject);
begin
  SortSelectedNodesByName(false);
end;

procedure TRSLodEdit.SortNode(Node: TTreeNode; Recursive: Boolean);
const
  NamePrefix: array[0..1] of string = ('2', '1');
var
  sl: TStringList;
  b: Boolean;
  i: int;
begin
  sl:= TStringList.Create;
  with TMyNode(Node) do
    try
      sl.Sorted:= true;
      sl.CaseSensitive:= false;
      sl.Duplicates:= dupAccept;
      for i := high(AllItems) downto 0 do
        sl.AddObject(NamePrefix[AllItems[i].ImageIndex] + AllItems[i].Text, AllItems[i]);
      for i := 0 to sl.Count - 1 do
        with TMyNode(sl.Objects[i]) do
        begin
          b:= Expanded;
          Index:= i;
          Expanded:= b;
        end;
    finally
      sl.Free;
    end;

  if Recursive then
    with TMyNode(Node) do
      for i := 0 to high(AllItems) do
        SortNode(AllItems[i], Recursive);
end;

procedure TRSLodEdit.SortSelectedNodesByName(Recursive: Boolean);
var
  Nodes: array of TMyNode;
  CurSel: TTreeNode;
  i: int;
begin
  with TreeView1 do
  begin
    SetLength(Nodes, SelectionCount);
    for i:= 0 to high(Nodes) do
      Nodes[i]:= ptr(Selections[i]);
    CurSel:= Selected;
    if CurSel = nil then
      CurSel:= Nodes[0];
    Items.BeginUpdate;
  end;

  try
    TreeView1.ClearSelection;
    for i := 0 to high(Nodes) do
      SortNode(Nodes[i], Recursive);
  finally
    TreeView1.Items.EndUpdate;
  end;

  with TreeView1 do
  begin
    Perform(TVM_SELECTITEM, TVGN_CARET or TVSI_NOSINGLEEXPAND, int(CurSel.ItemId));
    for i:= 0 to high(Nodes) do
      if Nodes[i] <> CurSel then
        Subselect(Nodes[i]);
  end;
end;

procedure TRSLodEdit.Spells1Click(Sender: TObject);
begin
  DefFilter:= $40;
end;

procedure TRSLodEdit.SpritePaletteFixup(Sender: TRSLod; Name: string;
  var pal: int2; var Data);
var
  a: PPalFix;
  i: int;
  last: int2;
begin
  last:= pal;
  if PalFixList.Find(Name, i) then
  begin
    a:= PPalFix(PalFixList.Objects[i]);
    if CompareMem(@Data, ptr(a.Data), length(a.Data)) then
      pal:= a.Pal;
  end;
  if FSFTKind > 0 then
    FindSpritePal(Name, pal, FSFTKind);
  if pal <> last then
    LastPalString:= Format(SPaletteChanged, [last, pal])
  else
    LastPalString:= Format(SPalette, [last]);
end;

procedure TRSLodEdit.StoreAsText1Click(Sender: TObject);
begin
  FavsAsText:= not FavsAsText;
  FavsChanged:= true;
end;

function TRSLodEdit.SwitchCheck(Item: TMenuItem; State: Boolean): Boolean;
begin
  Result:= Item.Checked;
  Item.Checked:= State;
  if Item.Tag <> 0 then
    TRSSpeedButton(Item.Tag).Down:= State;
end;

procedure TRSLodEdit.LoadFile(Index: int);
const
  DimStr: array[Boolean] of string = ('%dx%d', '%dx%d. %s');
var
  ft: TMyFileType;
  s: string;
  a: TStream;
  WasPlayed: Boolean;
  j: int;
begin
  ft:= aNone;
  if (Index >= 0) and (Index < length(ItemIndexes)) then
    if Archive is TRSLod then
      with TRSLod(Archive) do
      begin
        s:= LowerCase(ExtractFileExt(Archive.Names[ItemIndexes[Index]]));
        if Version = RSLodHeroes then
        begin
          if s = '.def' then
            ft:= aDef
          else if s = '.pcx' then
            ft:= aBmp
          else if s = '.txt' then
            ft:= aTxt
          //else if (s = '.msk') or (s = '.msg') then
          //  ft:= aMsk;
        end
        else if Version = RSLodSprites then
          ft:= aBmp
        else if (s = '.txt') or (s = '.str') then
          ft:= aTxt
        else if s = '.pcx' then
          ft:= aPcx
        else if s = '.wav' then
          ft:= aWav
        else if (s = '') and (Version in [RSLodBitmaps, RSLodIcons, RSLodMM8]) then
          ft:= aBmp;
      end
    else if Archive is TRSSnd then
      ft:= aWav
    else if Archive is TRSVid then
      ft:= aVideo
    else
      Assert(false);

  if FileType = aWav then
    sndPlaySound(nil, SND_ASYNC or SND_MEMORY or SND_NODEFAULT);
  FreeAndNil(FileBitmap);
  WasPlayed:= VideoPlayer <> nil;
  FreeVideo;
  // Stop current sound
  if ft = aWav then
    sndPlaySound(nil, 0);
  FileBuffer:= nil;
  LastPalString:= '';
  if (ft <> aNone) and (ft <> aVideo) then
  begin
    Index:= ItemIndexes[Index];
    a:= nil;
    try
      if ft = aPcx then
      begin
        a:= TMemoryStream.Create;
        Archive.Extract(Index, a);
        a.Seek(0, 0);
        FileBitmap:= TJvPcx.Create;
        FileBitmap.LoadFromStream(a);
        ft:= aBmp;
      end else
      begin
        FileBitmap:= Archive.ExtractArrayOrBmp(Index, FileBuffer);
        if (ft = aBmp) and (FileBitmap = nil) then
          ft:= aPal;
      end;
    except
      ft:= aNone;
      a.Free;
    end;
  end;
  if ft = aBmp then
  begin
    if (LastPalString = '') and (Archive is TRSLod) and (TRSLod(Archive).LastPalette <> 0) then
      s:= Format(SPalette, [TRSLod(Archive).LastPalette])
    else
      s:= LastPalString;
  end else
    s:= '';
  if FileBitmap <> nil then
    s:= Format(DimStr[s <> ''], [FileBitmap.Width, FileBitmap.Height, s]);
  Label1.Caption:= s;

  Timer1.Interval:=0;
  Timer2.Enabled:=false;
  //RSSpeedButton2.Hide;
  //RSSpeedButton3.Hide;
  Def.Free;
  Def:=nil;
  Errors:=nil;

  j:=0;
  FileType:= ft;
  try
    case ft of
      aDef:
      begin
        Def:=TRSDefWrapper.Create(FileBuffer);
        Def.OnPreparePalette:=PreparePal;
        if not ShowOneGroup then
          j:=Def.PicturesCount
        else
{          if length(Def.Groups)>2 then
            j:=Def.Groups[2].ItemsCount
          else}
            if length(Def.Groups)>0 then
              j:=Def.Groups[0].ItemsCount;
        // RSSpeedButton3.Show; // !!!
      end;
      aBmp:
      begin
        j:=1;
        SetPreviewBmp(FileBitmap);
        FileBitmap:= nil;
      end;
      aPal:
      begin
        j:=1;
        SetPreviewBmp(RSMMPaletteToBitmap(FileBuffer));
      end;
      aTxt:
      begin
        j:=0;
        SetString(s, PChar(FileBuffer), length(FileBuffer));
        RSMemo1.Text:=s;
      end;
      aWav:
      begin
        if RSSpeedButton2.Down then
          sndPlaySound(@FileBuffer[0], SND_ASYNC or SND_MEMORY or SND_NODEFAULT);
      end;
      aVideo:
        if RSSpeedButton2.Down then
        begin
          if WasPlayed then
            Sleep(1); // Avoid Bink and Smack thread synchronization bug in most cases
                      // RSSetSilentExceptionsFiter is used to handle other cases
          PlayVideo;
          if VideoPlayer <> nil then
            j:= 1;
        end;
    end;
  except
    j:=0;
  end;
  if RSMemo1.Visible <> (ft = aTxt) then
  begin
    RSMemo1.Visible:= ft = aTxt;
    InvalidateRect(Panel1.Handle, nil, false);
  end;
  SetLength(Errors, j);
  if j=0 then
    SetPreviewBmp(nil);
  RSSpeedButton1.Visible:= (ft <> aWav) and (ft <> aNone);
  RSSpeedButton2.Visible:= (ft = aDef) or (ft = aWav) or (ft = aVideo);
  RSSpeedButton2.Enabled:= (ft <> aDef) or (j > 1);
  TrackBar1.Visible:=j>1;
  TrackBar1.Max:=j-1;
  TrackBarMoveByTimer:= true;
  TrackBar1.Position:=0;
  if (j>0) and (Def<>nil) then
    TrackBar1Change(nil);
  TrackBarMoveByTimer:= false;
  if RSSpeedButton2.Down and (j>1) then
    Timer1.Interval:= GetDefAnimTime;
  if Assigned(OnSelectFile) then
  begin
    if (Index >= 0) and (Index < length(ItemIndexes)) then
      Index:= ItemIndexes[Index]
    else
      Index:= -1;
    OnSelectFile(self, Index);
  end;
end;

procedure TRSLodEdit.LoadIni;
begin
  //RSSaveTextFile(AppPath + 'Lang.txt', RSLanguage.MakeLanguage);
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini')) do
    try
      Recent.AsString:= ReadString('General', 'Recent Files', '');
      Language:= ReadString('General', 'Language', 'English');
      SwitchCheck(Sortbyextension1, ReadBool('General', 'Sort By Extension', false));
      Backup1.Checked:= ReadBool('General', 'Backup Original Files', true);
      IgnoreUnpackingErrors1.Checked:= ReadBool('General', 'Ignore Unpacking Errors', false);
      OpenDialog1.InitialDir:= ReadString('General', 'Open Path', '');
      SaveDialogExport.InitialDir:= ReadString('General', 'Export Path', '');
      CommonExtractionFolder1.Checked:= (ReadString('General', 'Export Path', '|') <> SaveDialogExport.InitialDir);
      if CommonExtractionFolder1.Checked then
        OpenDialogImport.InitialDir:= ReadString('General', 'Import Path', '');
      OpenDialogBitmapsLod.FileName:= ReadString('General', 'BitmapsLod Path', '');
      ExtractWithExternalShadow1.Checked:= ReadBool('General', 'Def Extract With External Shadow', true);
      ExtractIn24Bits1.Checked:= ReadBool('General', 'Def Extract In 24 Bits', false);
    finally
      Free;
    end;
  UpdateRecent;
end;

procedure TRSLodEdit.TrackBar1Change(Sender: TObject);
var
  r: TRect;
  p: TPoint;
begin
  if TrackBarChanging then  exit;
  TrackBarChanging:=true;
  try
    Application.ProcessMessages;
    if TrackBar1.Position>=length(Errors) then
      TrackBar1.Position:=0;
    if TrackBar1.Visible and not TrackBarMoveByTimer then
    begin
      TrackBar1.Perform(TBM_GETTHUMBRECT, 0, int(@r));
      p:= TrackBar1.ClientToScreen(Point(r.Left, r.Bottom + 1));
      RSShowHint(IntToStr(TrackBar1.Position), p);
    end else
      RSHideHint(false);
    LoadBmp(TrackBar1.Position, NeedPreviewBmp);
    UpdatePreviewBmp;
  finally
    TrackBarChanging:=false;
  end;
end;

procedure TRSLodEdit.PreparePal(Sender: TRSDefWrapper; Pal:PLogPal);
const
  DefColors: array[0..7] of int =
    ($FFFF00, $FF96FF, $FF64FF, $FF32FF, $FF00FF, $00FFFF, $FF00B4, $00FF00);

  ColorMasks: array[0..9] of int =
    (0, $1111111{-}, $1111001, $11001, $11001, $1111, 0, $1001, $1111111{-}, $1001);

var i,j,k:int;
begin
  if NormalPalette1.Checked then
  begin
    for i:=0 to 7 do
      int(Pal.palPalEntry[i]):=DefColors[i];
    for i:=8 to 255 do
      int(Pal.palPalEntry[i]):=DefColors[0];
  end else
    if TransparentBackground1.Checked then
    begin
      int(Pal.palPalEntry[0]):=ColorToRGB(clBtnFace);
      int(Pal.palPalEntry[1]):=RSMixColors(clBtnFace, 0, 182);
      int(Pal.palPalEntry[2]):=RSMixColors(clBtnFace, 0, 163);
      int(Pal.palPalEntry[3]):=RSMixColors(clBtnFace, 0, 143);
      int(Pal.palPalEntry[4]):=RSMixColors(clBtnFace, 0, 124);

      int(Pal.palPalEntry[5]):=clYellow;
      int(Pal.palPalEntry[6]):=RSMixColors(clYellow, 0, 170); //clYellow;
      int(Pal.palPalEntry[7]):=RSMixColors(clYellow, 0, 210);// clYellow;
      //for i:=5 to 7 do
      //  int(Pal.palPalEntry[i]):=DefColors[i];
      k:=int(Pal.palPalEntry[0]);
      for i:=8 to 255 do
        int(Pal.palPalEntry[i]):=k;
      j:=Sender.Header^.TypeOfDef - $40;
      if (j>=0) and (j<=9) then
      begin
        j:= ColorMasks[j];
        k:= 1;
        for i:= 1 to 7 do
        begin
          if j and k = 0 then
            int(Pal.palPalEntry[i]):=int(Pal.palPalEntry[0]);
          k:=k shl 4;
        end;
      end;
    end;
//  exit;
//  if Def.GetPicHeader(0)^.Compression=0 then exit;
{
  if RSSpeedButton3.Down then
  begin
    int(Pal.palPalEntry[0]):=ColorToRGB(clBtnFace);
    int(Pal.palPalEntry[4]):=RSMixColorsNorm(clBtnFace, 0, 124);
    int(Pal.palPalEntry[1]):=RSMixColorsNorm(clBtnFace, 0, 182);
//    int(Pal.palPalEntry[5]):=clYellow;
//    int(Pal.palPalEntry[6]):=RSMixColorsNorm(clYellow, 0, 170); //clYellow;
//    int(Pal.palPalEntry[7]):=RSMixColorsNorm(clYellow, 0, 210);// clYellow;
  end;
}
end;

procedure TRSLodEdit.ThemeChanged;
begin
  if ThemeServices.ThemesEnabled then
  begin
    TreeView1.BorderWidth:=0;
    with RSMemo1 do
    begin
      Align:=alNone;
      BorderStyle:=bsSingle;
      Top:=0;
      Left:=0;
      Width:=Panel1.Width;
      Height:=Panel1.Height;
    end;
    //ListView1.BorderWidth:=2; // Глючит - текст залазит за границу
  end else
    RSMemo1.Align:=alClient;
end;

procedure TRSLodEdit.FormCreate(Sender: TObject);
var
  a: PPalFix;
  s: string;
begin
  // Delphi messes up window height
  ClientHeight:= RDiv(740*ClientWidth, 985);
  RSHookFlatBevels(self);
  if not ThemeServices.ThemesEnabled then
    ComboExtFilter.BevelKind:= bkFlat;
  ThemeChanged;
  SExtractTo:=ExtractTo1.Caption;
  //Image1.ControlStyle:=Image1.ControlStyle+[csOpaque];

  ClipboardFormat:= RegisterClipboardFormat('RSLodEdit Favorites');

  s:= RSGetModuleFileName(0);
  Association1:= TRSFileAssociation.Create('.lod', 'MMArchive.Lod',
         'MMArchive Backup', '"' + s + '" "%1"', s + ',0');
  Association2:= TRSFileAssociation.Create('.snd', 'MMArchive.Snd',
         'MMArchive Backup', '"' + s + '" "%1"', s + ',0');
  Association3:= TRSFileAssociation.Create('.vid', 'MMArchive.Vid',
         'MMArchive Backup', '"' + s + '" "%1"', s + ',0');
  Association4:= TRSFileAssociation.Create('.pac', 'MMArchive.Pac',
         'MMArchive Backup', '"' + s + '" "%1"', s + ',0');
  Association5:= TRSFileAssociation.Create('.lwd', 'MMArchive.Lwd',
         'MMArchive Backup', '"' + s + '" "%1"', s + ',0');

  PalFixList:= TStringList.Create;
  PalFixList.Sorted:= true;
  PalFixList.CaseSensitive:= false;
  a:= @PalFix[1];
  while a.Name <> '' do
  begin
    PalFixList.AddObject(a.Name, TObject(a));
    inc(a);
  end;
  FDragFilesList:= TMyStringList.Create;
end;

procedure TRSLodEdit.ListView1Edited(Sender: TObject; Item: TListItem;
  var S: string);
begin
  DoRename(Item.Index, S);
end;

procedure TRSLodEdit.ListView1Editing(Sender: TObject; Item: TListItem;
  var AllowEdit: Boolean);
begin
  AllowEdit:= FEditing;
end;

procedure TRSLodEdit.ComboExtFilterDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  if odSelected in State then
    State:= State + [odFocused];
  with TComboBox(Control) do
    RSPaintList(Control, Canvas, Items[Index], Rect, State);
end;

procedure TRSLodEdit.ComboExtFilterKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  w: HWND;
begin
  w:= TRSComboBox(Sender).ListBoxHandle;
  if (Key = VK_ESCAPE) and ((w = 0) or not IsWindowVisible(w)) then
  begin
    Button2Click(nil);
    Key:=0;
  end;
end;

procedure TRSLodEdit.ComboExtFilterSelect(Sender: TObject);
var
  s:string;
begin
  if ListView1.Selected<>nil then
    DefaultSel:= SelCaption;
  s:= ComboExtFilter.Text;
  if (s <> FilterExt) and BeginLoad(ArchiveFileName, s) then
  begin
    FilterExt:= s;
    if ListView1.Selected<>nil then
      DefaultSel:= SelCaption;
    EndLoad(true);
    CanSelectListView:= false;
    UpdateFavsVisibility;
    CanSelectListView:= true;
  end;
end;

procedure TRSLodEdit.CommonExtractionFolder1Click(Sender: TObject);
begin
  with Ini do
    if CommonExtractionFolder1.Checked then
    begin
      WriteString('General', 'Export Path', '');
      WriteString('General', 'Import Path', '');
    end else
    begin
      DeleteKey('General', 'Export Path');
      DeleteKey('General', 'Import Path');
    end;
end;

function TRSLodEdit.CompareArchivesItem(new, old: TRSMMArchive; i: int): Boolean;
var
  mem1, mem2: TMemoryStream;
  r: TStream;
  j: int;
begin
  j:= i;
  Result:= (i < old.Count) and SameText(new.Names[i], old.Names[i]) or
    old.RawFiles.FindFile(new.Names[i], j);

  Result:= Result and (new.RawFiles.UnpackedSize[i] = old.RawFiles.UnpackedSize[j]);
  if not Result then
    exit;

  mem1:= TMemoryStream.Create;
  mem2:= TMemoryStream.Create;
  try
    // raw compare
    Result:= new.RawFiles.Size[i] = old.RawFiles.Size[j];
    if Result then
    begin
      mem1.SetSize(new.RawFiles.Size[i]);
      r:= new.RawFiles.GetAsIsFileStream(i);
      try
        r.ReadBuffer(mem1.Memory^, mem1.Size);
      finally
        new.RawFiles.FreeAsIsFileStream(i, r);
      end;

      mem2.SetSize(new.RawFiles.Size[i]);
      r:= old.RawFiles.GetAsIsFileStream(j);
      try
        r.ReadBuffer(mem2.Memory^, mem2.Size);
      finally
        old.RawFiles.FreeAsIsFileStream(j, r);
      end;

      Result:= CompareMem(mem1.Memory, mem2.Memory, mem1.Size);
    end;

    if Result or not new.RawFiles.IsPacked[i] and not old.RawFiles.IsPacked[j] then
      exit;

    // compare unpacked
    try
      if new.RawFiles.IsPacked[i] then
      begin
        mem1.SetSize(new.RawFiles.UnpackedSize[i]);
        mem1.Position:= 0;
        new.RawFiles.RawExtract(i, mem1);
      end;
      if old.RawFiles.IsPacked[j] then
      begin
        mem2.SetSize(old.RawFiles.UnpackedSize[j]);
        mem2.Position:= 0;
        old.RawFiles.RawExtract(j, mem2);
      end;
      Result:= (mem1.Size = mem2.Size) and CompareMem(mem1.Memory, mem2.Memory, mem1.Size);
    except
      Result:= false;
    end;
  finally
    mem1.Free;
    mem2.Free;
  end;
end;

procedure TRSLodEdit.CompareTo1Click(Sender: TObject);
var
  arc: TRSMMArchive;
  i: int;
begin
  if CancelCompare then
  begin
    EndLoad(true);
    exit;
  end;
  OpenDialogCompare.InitialDir:= ExtractFilePath(Archive.RawFiles.FileName);
  if not OpenDialogCompare.Execute then  exit;
  SetLength(FilterItemVisible, Archive.Count);
  arc:= RSLoadMMArchive(OpenDialogCompare.FileName);
  try
    PleaseWait(SPleaseWait);
    arc.RawFiles.IgnoreUnzipErrors:= Archive.RawFiles.IgnoreUnzipErrors;
    for i:= 0 to Archive.Count - 1 do
      FilterItemVisible[i]:= not CompareArchivesItem(Archive, arc, i);
  finally
    PleaseWait;
    arc.Free;
  end;
  SwitchCheck(CompareTo1, true);
  SpecFilter:= ArrayFilterProc;
  if ListView1.Selected<>nil then
    DefaultSel:= SelCaption;
  EndLoad(true);
end;

procedure TRSLodEdit.RSSpeedButton1Click(Sender: TObject);
begin
  UpdatePreviewBmp;
end;

procedure TRSLodEdit.RSSpeedButton2Click(Sender: TObject);
begin
  case FileType of
    aDef:
      if RSSpeedButton2.Down and (length(Errors)>1) then
        Timer1.Interval:= GetDefAnimTime
      else
        Timer1.Interval:= 0;
    aWav:
      if RSSpeedButton2.Down then
        sndPlaySound(@FileBuffer[0], SND_ASYNC or SND_MEMORY or SND_NODEFAULT)
      else
        sndPlaySound(nil, SND_ASYNC or SND_MEMORY or SND_NODEFAULT);
    aVideo:
      if not RSSpeedButton2.Down then
      begin
        Timer1.Interval:= 0;
        if VideoPlayer <> nil then
          VideoPlayer.Pause:= true;
      end else
        PlayVideo;
  end
end;

procedure TRSLodEdit.Timer1Timer(Sender: TObject);
var
  i:int;
begin
  case FileType of
    aDef:
    begin
      i:=TrackBar1.Position;
      inc(i);
      if i>=length(Errors) then
        i:=0;
      TrackBarMoveByTimer:= true;
      TrackBar1.Position:=i;
      TrackBarMoveByTimer:= false;
    end;
    aVideo:
    begin
      if (VideoPlayer = nil) or VideoPlayer.Wait then  exit;
      VideoPlayer.NextFrame;
      VideoPlayer.ExtractFrame(NeedPreviewBmp);
      UpdatePreviewBmp;
    end;
  end;
end;

procedure TRSLodEdit.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ListView1.IsEditing then
    exit;

  if Shift = [ssCtrl] then
    case Key of
      VK_LEFT:
        if TrackBar1.Visible then
          TrackBar1.Position:= TrackBar1.Position - 1
        else
          exit;
      VK_RIGHT:
        if TrackBar1.Visible then
          TrackBar1.Position:= TrackBar1.Position + 1
        else
          exit;
      VK_RETURN:
        if EmulatePopupShortCuts then
          AddtoFavorites1Click(nil)
        else
          exit;
      ord('A'):
        ListView1.SelectAll;
      else
        exit;
    end
  else if EmulatePopupShortCuts and (Key = VK_RETURN) and (Shift = []) then
    Button1Click(nil)
  else if ListView1.IsEditing and (Key = VK_RETURN) and (Shift = []) then
    ListView1.Perform(TVM_ENDEDITLABELNOW, 0, 0)
  else if (Key = VK_ESCAPE) and (Shift = []) then //and not FEditing then
    Button2Click(nil)
  else if (Key = VK_DELETE) and (Shift = [ssShift]) then
    DoDelete(false)
  else
    exit;
  Key:=0;
end;

procedure TRSLodEdit.ListView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button=mbMiddle) and (@EnterReaderModeHelper<>nil) then
    EnterReaderModeHelper(ListView1.Handle);

  if FEditing and (ListView1.SelCount <> 0) and (Button = mbLeft) then
    if DragDetectPlus(ListView1) then
    begin
      FillDropSource;
      DragAcceptFiles(Handle, false);
      DropFileSource1.Execute;
    end;
end;

procedure TRSLodEdit.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  {if (Archive <> nil) and (Archive is TRSVid) and TRSVid(Archive).RebuildNeeded then
    DoRebuild(false);}
  TrySaveTree;
end;

procedure TRSLodEdit.FormDestroy(Sender: TObject);
begin
  if FEditing then
    SaveIni;
  if FMyTempPath <> '' then
  begin
    // remove temp folder
    //RSFileOperation(ExcludeTrailingPathDelimiter(FMyTempPath), '', FO_DELETE);
    RSDeleteAll(ExcludeTrailingPathDelimiter(FMyTempPath), true);
    // check if clipboard contains files from the archive, clear it
    try
      with Clipboard do
        if (FCopyStr <> '') and (HasFormat(CF_HDROP)) and (Text = FCopyStr) then
          Text:= Text;
    except
    end;
  end;
  // !!!
  //PPtr(@ListView1.Items.Owner)^:=self; // Чтоб не тормозило
  FreeAndNil(Archive);
  FreeAndNil(FileBitmap);
  FreeAndNil(Def);
  if FileType = aWav then
    sndPlaySound(nil, SND_ASYNC or SND_MEMORY or SND_NODEFAULT);
  FileBuffer:= nil;
  FreeAndNil(PalFixList);
  FreeAndNil(VideoPlayers[0]);
  FreeAndNil(VideoPlayers[1]);
  FreeAndNil(VideoPlayers[2]);
end;

procedure TRSLodEdit.FreeArchive;
begin
  if SwitchCheck(CompareTo1, false) and (DefFilter <> 0) then
    SpecFilter:= nil;
  FilterItemVisible:= nil;
  FreeVideo;
  FreeAndNil(Archive);
  FreeAndNil(FSFT);
  FSFTNotFound:= false;
  ListView1.Items.Count:= 0;
  Palette1.Visible:= false;
//  AppCaption:= AppCaption;
end;

procedure TRSLodEdit.FreeVideo;
begin
  if VideoPlayer <> nil then
  begin
    VideoPlayer.Close;
    VideoPlayer:= nil;
  end;
  if VideoStream <> nil then
    Archive.RawFiles.FreeAsIsFileStream(0, VideoStream);
  VideoStream:= nil;
end;

procedure TRSLodEdit.TreeView1Collapsing(Sender: TObject; Node: TTreeNode;
  var AllowCollapse: Boolean);
begin
  AllowCollapse:= Node.Level<>0;
end;

procedure TRSLodEdit.TreeView1Editing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
begin
//  AllowEdit:= Node.ImageIndex = 1;
  AllowEdit:= Node.Parent <> nil;
end;

procedure TRSLodEdit.TreeView1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
  with TreeView1 do
    if (Selected=nil) or not PtInRect(Selected.DisplayRect(false),
                                        ScreenToClient(Mouse.CursorPos)) then
    begin
      mouse_event(MOUSEEVENTF_LEFTDOWN,0,0,0,0);
      mouse_event(MOUSEEVENTF_LEFTUP,0,0,0,0);
    end;
  Application.ProcessMessages;
  with Mouse.CursorPos do
    PopupTree.Popup(x, y);
end;

function TRSLodEdit.AddTreeNode(s:string; Image:integer; EditName:boolean; Select:boolean=true):TTreeNode;
var
  Node, Sel:TTreeNode;
  it:TMyTreeNode;
  i: int;
begin
  Sel:=TreeView1.Selected;
  if Sel=nil then Sel:=TreeView1.Items[0];
  if Sel.ImageIndex=0 then
    Node:=Sel.Parent
  else
    Node:=Sel;
  //TreeDeleteNeedeed:=false;
  Result:= nil;
  if Image <> 0 then
  begin
    i:= 0;
    with TMyNode(Node) do
      while (i < length(AllItems)) and (AllItems[i].ImageIndex <> 0) do
      begin
        if not EditName and SameText(AllItems[i].Text, s) then
          exit;
        inc(i);
      end;
  end else
  begin
    with TMyNode(Node) do
      for i := 0 to high(AllItems) do
        if (AllItems[i].ImageIndex = 0) and SameText(AllItems[i].FileName, s) then
          exit;
    i:= MaxInt;
  end;
  it:= TMyNode(Node).AddItem(s, false, i);
  Result:=it;
  {if not EditName then
  begin
    Node.CustomSort(nil, 0, false);
    if TreeDeleteNeedeed then
    begin
      it.Delete;
      exit;
    end;
  end;}
  if Image=0 then
    it.FileName:=s;
  Node.Expand(false);
  with it do
  begin
    ImageIndex:=Image;
    SelectedIndex:=Image;
    Application.ProcessMessages;
    if Select then
      TreeView1.Select(it);
    if EditName then
      EditText;
  end;
end;

procedure TRSLodEdit.ArchiveCreated;
begin
  FLightLoad:= false;
  AppCaption:= AppCaption;
  Archive.RawFiles.IgnoreUnzipErrors:= IgnoreUnpackingErrors1.Checked;
  Archive.BackupOnAdd:= Backup1.Checked;
  Archive.BackupOnDelete:= Backup1.Checked;
  if Archive is TRSLod then
    with TRSLod(Archive) do
    begin
      OnNeedBitmapsLod:= NeedBitmapsLod;
      OnNeedPalette:= NeedPalette;
      OnConvertToPalette:= ConvertToPalette;
      OnSpritePalette:= SpritePaletteFixup;
      if Version = RSLodSprites then
        Palette1.Visible:= true;
    end;
  if Recent <> nil then
  begin
    Recent.Add(ArchiveFileName);
    UpdateRecent;
  end;
  Edit1.Visible:= true;
  UpdateToolbarState;
end;

function TRSLodEdit.ArchiveFileName: string;
begin
  if Archive <> nil then
    Result:= Archive.RawFiles.FileName
  else
    Result:= '';
end;

function TRSLodEdit.ArrayFilterProc(Sender: TRSLodEdit; i: int;
  var Str: string): Boolean;
begin
  Result:= FilterItemVisible[i];
end;

procedure TRSLodEdit.Associate1Click(Sender: TObject);
begin
  Association1.Associated:= not Associate1.Checked;
end;

procedure TRSLodEdit.Associate2Click(Sender: TObject);
begin
  Association2.Associated:= not Associate2.Checked;
end;

procedure TRSLodEdit.Associate3Click(Sender: TObject);
begin
  Association3.Associated:= not Associate3.Checked;
end;

procedure TRSLodEdit.Associate4Click(Sender: TObject);
begin
  Association4.Associated:= not Associate4.Checked;
end;

procedure TRSLodEdit.Associate5Click(Sender: TObject);
begin
  Association5.Associated:= not Associate5.Checked;
end;

procedure TRSLodEdit.AddFolder1Click(Sender: TObject);
begin
  AddTreeNode(SNewFolder, 1, true);
end;

procedure TRSLodEdit.Add1Click(Sender: TObject);
begin
  if OpenDialogImport.Execute then
    DoAdd(OpenDialogImport.Files);
end;

procedure TRSLodEdit.AddFile1Click(Sender: TObject);
begin
  if ListView1.Selected=nil then exit;
  AddTreeNode(SelCaption, 0, false);
end;

procedure TRSLodEdit.TreeView1Edited(Sender: TObject; Node: TTreeNode;
  var S: String);
begin
  if s='' then
    Node.Delete
  else
  begin
    FavsChanged:= true;
    Node.Text:=s;
    //Node.Parent.CustomSort(nil, 0);
  end;
end;

procedure TRSLodEdit.TreeView1CancelEdit(Sender: TObject; Node: TTreeNode);
begin
  if Node.Text='' then
    Node.Delete
  {else
    Node.Parent.CustomSort(nil, 0);}
end;

procedure TRSLodEdit.Delete1Click(Sender: TObject);
var i:uint;
begin
  with TreeView1 do
  begin
    if Items[0].Selected then exit;
    for i:=SelectionCount-1 downto 0 do
      Selections[i].Delete;
  end;
end;

procedure TRSLodEdit.TreeView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_DELETE:
      if not TreeView1.IsEditing then
      begin
        Delete1Click(nil);
        Key:=0;
      end;
    VK_RIGHT:
      if ssCtrl in Shift then
      begin
        AddFolder1Click(nil);
        Key:=0;
      end;
    VK_RETURN:
      if ssCtrl in Shift then
      begin
        AddFile1Click(nil);
        Key:=0;
      end else
        if Shift=[] then
        begin
          Rename1Click(nil);
          Key:=0;
        end;
    VK_ESCAPE:
      if not TreeView1.IsEditing then
      begin
        Button2Click(nil);
        Key:=0;
      end;
    VK_UP:
      if Shift*[ssShift, ssAlt, ssCtrl] = [ssAlt] then
      begin
        MoveUp1Click(nil);
        Key:=0;
      end;
    VK_DOWN:
      if Shift*[ssShift, ssAlt, ssCtrl] = [ssAlt] then
      begin
        MoveDown1Click(nil);
        Key:=0;
      end;
  end;
end;

procedure TRSLodEdit.Rebuild1Click(Sender: TObject);
var
  WasPlaying: Boolean;
begin
  WasPlaying:= (FileType = aVideo) and (Timer1.Interval <> 0);
  DoRebuild(true);
  if WasPlaying then
    PlayVideo;
end;

procedure TRSLodEdit.RecentClick(Sender: TRSRecent; FileName: string);
begin
  if not FileExists(FileName) then
  begin
    Sender.Delete(FileName);
    MessageBeep(MB_ICONERROR);
    exit;
  end;

  FilterExt:= AnyExt;

  CreateArchive(FileName);
  EndLoad(false);
end;

procedure TRSLodEdit.Rename1Click(Sender: TObject);
var Node:TTreeNode;
begin
  Node:=TreeView1.Selected;
  if (Node=nil) {or (Node.ImageIndex<>1)} then exit;
  Node.EditText;
end;

procedure TRSLodEdit.Rename2Click(Sender: TObject);
const
  b = LVIS_FOCUSED or LVIS_SELECTED;
begin
  if (LastSel >= 0) and (ListView_GetItemState(ListView1.Handle, LastSel, b) = b) then
    ListView_EditLabel(ListView1.Handle, LastSel);
end;

procedure TRSLodEdit.TreeView1KeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
    #13, #10, #27:
    begin
      Key:=#0;
      exit;
    end;
  end;
  if not TreeView1.IsEditing then
    case Key of
      #24: Cut1Click(nil);
      #3: Copy1Click(nil);
      #22: Paste1Click(nil);
      else
        exit;
    end
  else
    exit;
  Key:=#0;
end;


function TRSLodEdit.GetDefAnimTime: int;
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

function TRSLodEdit.GetTreePath(FileName:string):string;
const MyExt='.lf';
begin
  if FileName <> '' then
    if Favorites <> '' then
      Result:= Favorites + ChangeFileExt(ExtractFileName(FileName), MyExt)
    else
      Result:= AppPath + 'Favorites\' +
                 ChangeFileExt(ExtractFileName(FileName), MyExt)
  else
    Result:= FileName;
end;

procedure TRSLodEdit.Help1Click(Sender: TObject);
begin
  Perform(WM_HELP, 0, 0);
end;

procedure TRSLodEdit.HookDragWindow;
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

type
  TMyTreeHeader = packed record
    Size: word;
    Version: byte;
  end;
  PMyTreeHeader = ^TMyTreeHeader;

(*

Stupid Binary Format: <Header> {File}

File: <Text> <End Byte> <Number In Lod (if not a folder!)> <FileName> <Reserved>

End Byte bits:

1 - Folder
2 - Has items
4 - Last in folder

FileName String (only used for files)
Reserved String: Here may be a Hint string
2-byte file index

*)

procedure ReadNode(Items:TTreeNodes; var p:PByte; Node:TMyNode);
var
  p1:Ptr; i:Byte; j:int; it:TMyNode; s:string;
begin
  i:=0;
  while i < 4 do
  begin
    p1:=p;
    while p^>=8 do
      inc(p);
    SetString(s, PChar(p1), int(p)-int(p1));
    i:=p^;
    j:=i and 1;
    it:= Node.AddItem(s, true);
    inc(p);
    with it do
    begin
      ImageIndex:= j;
      SelectedIndex:= j;
      if j = 0 then
      begin
        Data:=ptr(DWord(PWord(p)^));
        inc(p, 2);
      end;
      p1:=p;
      while p^<>0 do // FileName
        inc(p);
      SetString(s, PChar(p1), int(p)-int(p1));
      FileName:=s;
      inc(p);
      p1:=p;
      while p^<>0 do // Reserved
        inc(p);
      SetString(s, PChar(p1), int(p)-int(p1));
      it.Param2:=s;
      inc(p);
      if ImageIndex = 1 then
        FileName:= ''
      else if FileName = '' then
        FileName:= Text;
      RSLodEdit.UpdateNodeVisibility(it);
      if i and 2 <> 0 then
        ReadNode(Items, p, it);
    end;
  end;
end;

procedure ReadTextNodes(Items:TTreeNodes; const a:string; Node:TMyNode);
var
  ps0, ps: TRSParsedString;
  CurNode, it: TMyNode;
  IsFolder: Boolean;
  i, lev, CurLev: int;
begin
  ps0:= RSParseRange(ptr(a), @a[length(a) + 1], [#13#10]);
  CurNode:= Node;
  it:= Node;
  CurLev:= 0;
  for i := 1 to RSGetTokensCount(ps0, true) - 1 do
  begin
    ps:= RSParseToken(ps0, i, ['+', '-', '=', '!'], 1);
    if length(ps) = 2 then  continue;
    if ps[1]^ = '=' then
    begin
      it.Text:= RSGetToken(ps, 1);
      continue;
    end;
    if ps[1]^ = '!' then
    begin
      it.Param2:= RSGetToken(ps, 1);
      continue;
    end;
    lev:= ps[1] - ps[0];
    while CurLev > lev do
    begin
      CurNode:= CurNode.GetParent;
      dec(CurLev);
    end;

    IsFolder:= (ps[1]^ = '+');
    it:= CurNode.AddItem(RSGetToken(ps, 1), true);
    if IsFolder then
    begin
      CurNode:= it;
      inc(CurLev);
    end else
      it.FileName:= it.Text;
    it.ImageIndex:= ord(IsFolder);
    it.SelectedIndex:= ord(IsFolder);
    RSLodEdit.UpdateNodeVisibility(it);
  end;
end;

procedure TRSLodEdit.DoLoadTree(const a:string; Node:TTreeNode=nil);
var
  p:PByte;
  i: int;
begin
  if (length(a) < 3) or (PMyTreeHeader(a).Size < 256) and (length(a) <= PMyTreeHeader(a).Size) then
    exit;

  if Node=nil then
  begin
    Node:= TreeView1.Items[0];
    FavsAsText:= PMyTreeHeader(a).Size >= 256;
  end;
  with TreeView1.Items do
  begin
    BeginUpdate;
    try
      i:= length(TMyNode(Node).AllItems);
      if PMyTreeHeader(a).Size < 256 then
      begin
        p:=ptr(a);
        inc(p, PMyTreeHeader(a).Size);
        ReadNode(TreeView1.Items, p, TMyNode(Node));
      end else
        ReadTextNodes(TreeView1.Items, a, TMyNode(Node));

      MoveNodeChildren(Node, Node, i);
      Node.Expanded:= true;
      //Node.CustomSort(nil, 0);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TRSLodEdit.DoRebuild(snd: Boolean);
begin
  FreeVideo;
  PleaseWait(SPleaseWaitRebuilding);
  try
    Archive.RawFiles.Rebuild;
  finally
    PleaseWait;
  end;

  if snd then
    MessageBeep(MB_ICONINFORMATION);
end;

procedure TRSLodEdit.DoRename(i: int; const Name: string);
var
  j: int;
begin
  Archive.RawFiles.CheckName(Name);
  if Archive.RawFiles.FindFile(Name, j) then
    if not ConfirmBox(Format(SRenameOverwriteQuestion, [Name])) then
      exit;

  Archive.RawFiles.Rename(ItemIndexes[i], Name);
  CancelCompare;
  DefaultSel:= Name;
  EndLoad(true);
end;

procedure TRSLodEdit.DragTimerTimer(Sender: TObject);
begin
  DragTargetNode.Expanded := not DragTargetNode.Expanded;
  DragTimer.Enabled:= false;
end;

procedure TRSLodEdit.DragWndProc(var m: TMessage);
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

procedure TRSLodEdit.DropFileSource1AfterDrop(Sender: TObject;
  DragResult: TDragResult; Optimized: Boolean);
var
  e: Exception;
begin
  DragAcceptFiles(Handle, true);
  if FDragException <> '' then
  begin
    e:= Exception.Create(FDragException);
    try
      Application.ShowException(e);
    finally
      e.Free;
    end;
  end;
end;

procedure TRSLodEdit.DropFileSource1Drop(Sender: TObject; DragType: TDragType;
  var ContinueDrop: Boolean);
begin
  try
    ExtractDropSource;
    FDragException:= '';
  except
    on e: Exception do
      FDragException:= e.Message;
  end;
end;

procedure TRSLodEdit.LoadTree(FileName:string);
//var a:TRSByteArray;
begin
  //a:=nil;
  if FileName='' then exit;
  if not FileExists(FileName) then exit;
  {a:=RSLoadFile(FileName);
  if (length(a)<=3) or (length(a)<=PMyTreeHeader(a).Size) then exit;}

  DoLoadTree(RSLoadTextFile(FileName));
  TreeView1.Items[0].Expand(false);
end;

procedure TRSLodEdit.SaveDialogNewTypeChange(Sender: TObject);
begin
  case SaveDialogNew.FilterIndex of
    3, 4: SaveDialogNew.DefaultExt:= '.snd';
    5, 6: SaveDialogNew.DefaultExt:= '.vid';
    7: SaveDialogNew.DefaultExt:= '';
    8: SaveDialogNew.DefaultExt:= '.icons.lod';
    9: SaveDialogNew.DefaultExt:= '.sprites.lod';
    10: SaveDialogNew.DefaultExt:= '.T.lod';
    11, 12: SaveDialogNew.DefaultExt:= '.games.lod';
    else
      SaveDialogNew.DefaultExt:= '.lod';
  end;
end;

procedure TRSLodEdit.SaveIni;
begin
  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini')) do
    try
      WriteString('General', 'Recent Files', Recent.AsString);
      WriteString('General', 'Language', Language);
      WriteBool('General', 'Sort By Extension', Sortbyextension1.Checked);
      WriteBool('General', 'Backup Original Files', Backup1.Checked);
      WriteBool('General', 'Ignore Unpacking Errors', IgnoreUnpackingErrors1.Checked);
      WriteString('General', 'Open Path', DialogToFolder(OpenDialog1));
      WriteString('General', 'Export Path', DialogToFolder(SaveDialogExport));
      WriteString('General', 'Import Path', DialogToFolder(OpenDialogImport));
      WriteString('General', 'BitmapsLod Path', OpenDialogBitmapsLod.FileName);
      WriteBool('General', 'Def Extract With External Shadow', ExtractWithExternalShadow1.Checked);
      WriteBool('General', 'Def Extract In 24 Bits', ExtractIn24Bits1.Checked);
    finally
      Free;
    end;
end;

function SingleNodeSize(Node:TMyNode):int;
begin
  if Node.Text=Node.FileName then
    Result:=length(Node.Text) + length(Node.Param2) + 3
  else
    Result:=length(Node.Text) + length(Node.FileName) + length(Node.Param2) + 3;
  if Node.ImageIndex=0 then
    inc(Result, 2);
end;

function CountNodeSize(Node:TMyNode):int;
var i:int;
begin
  Result:=0;
  for i:=Node.FullCount-1 downto 0 do
  begin
    inc(Result, SingleNodeSize(Node.AllItems[i])
                                   + CountNodeSize(Node.AllItems[i]));
  end;
end;

procedure WriteSingleNode(var p:PByte; it:TMyNode; Last:boolean);
var j:int; s:string;
begin
  s:=it.Text;
  CopyMemory(p, ptr(s), length(s));
  inc(p, length(s));
  j:=it.ImageIndex;
  if it.FullCount>0 then
    j:= j or 2;
  if Last then
    j:= j or 4;
  p^:=Byte(j);
  inc(p);
  if j and 1 = 0 then // if file
  begin
    //PWord(p)^:=word(it.Data);
    PWord(p)^:= 0;
    inc(p,2);
  end;

  s:=it.FileName;
  if s=it.Text then
    s:='';
  CopyMemory(p, ptr(s), length(s));
  inc(p, length(s));
  p^:=0;
  inc(p);

  s:=it.Param2; // Reserved
  CopyMemory(p, ptr(s), length(s));
  inc(p, length(s));
  p^:=0;
  inc(p);
end;

procedure WriteNode(var p:PByte; Node:TMyNode);
var i:int; it:TMyNode;
begin
  for i:=0 to Node.FullCount-1 do
  begin
    it:= Node.AllItems[i];
    WriteSingleNode(p, it, i=Node.FullCount-1);
    WriteNode(p, it);
  end;
end;

function TRSLodEdit.SaveNodes(Nodes:array of TTreeNode): string;
var i, j:int; p:PByte;
begin
  j:=SizeOf(TMyTreeHeader);
  if Nodes[0].Level=0 then
    inc(j, CountNodeSize(TMyNode(Nodes[0])))
  else
    for i:=0 to high(Nodes) do
      inc(j, SingleNodeSize(TMyNode(Nodes[i])) + CountNodeSize(TMyNode(Nodes[i])));

  SetLength(Result, j);
  with PMyTreeHeader(Result)^ do
  begin
    Size:=SizeOf(TMyTreeHeader);
    Version:=0;
  end;
  p:=ptr(Result);
  inc(p, SizeOf(TMyTreeHeader));
  if Nodes[0].Level=0 then
    WriteNode(p, TMyNode(Nodes[0]))
  else
    for i:=0 to high(Nodes) do
    begin
      WriteSingleNode(p, TMyNode(Nodes[i]), i=high(Nodes));
      WriteNode(p, TMyNode(Nodes[i]));
    end;
end;

procedure TRSLodEdit.SaveSelectionAsArchive1Click(Sender: TObject);
var
  sl: TStringList;
  a, a0: TStream;
  output: TRSMMArchive;
  s: string;
  ps: TRSParsedString;
  i, k: int;
begin
  SaveDialogSaveSelectionAs.DefaultExt:= ExtractFileExt(ArchiveFileName);
  s:= ExtractFileName(ArchiveFileName);
  ps:= RSParseString(s, ['.']);
  i:= RSGetTokensCount(ps);
  if i > 2 then
    s:= RSGetTokens(ps, i - 2);
  if SameText(s, 'EnglishT.lod') or SameText(s, 'EnglishD.lod') then
    s:= Copy(s, 8, 5);
  SaveDialogSaveSelectionAs.FileName:= ExtractFilePath(ArchiveFileName) + 'new.' + s;
  if not SaveDialogSaveSelectionAs.Execute then  exit;
  a0:= nil;
  output:= Archive.CloneForProcessing(SaveDialogSaveSelectionAs.FileName, ListView1.SelCount);
  sl:= TStringList.Create;
  try
    PleaseWait(SPleaseWait);
    sl.CaseSensitive:= false;
    sl.Sorted:= true;
    with ListView1, Items do
      for i:=0 to Count-1 do
        if Item[i].Selected then
          sl.Add(Archive.Names[ItemIndexes[i]]);

    a0:= TFileStream.Create(SaveDialogSaveSelectionAs.FileName, fmCreate);
    output.RawFiles.AssignStream(a0);
    for i:= 0 to Archive.Count - 1 do  // maintain original order
      if sl.Find(Archive.Names[i], k) then
      begin
        a:= Archive.RawFiles.GetAsIsFileStream(i);
        try
          if Archive.RawFiles.IsPacked[i] then
            output.RawFiles.Add(Archive.Names[i], a, Archive.RawFiles.Size[i], clNone,
               Archive.RawFiles.UnpackedSize[i])
          else
            output.RawFiles.Add(Archive.Names[i], a, Archive.RawFiles.Size[i], clNone);

        finally
          Archive.RawFiles.FreeAsIsFileStream(i, a);
        end;
      end;

    if sl.Count = 0 then
      output.RawFiles.DoSave;

  finally
    PleaseWait;
    sl.Free;
    if a0 <> nil then  output.RawFiles.FreeAsIsFileStream(0, a0);
    output.Free;
  end;
  Recent.Add(SaveDialogSaveSelectionAs.FileName, false);
end;

procedure WriteTextNode(sl: TStringList; Node: TMyNode; Indent: string);
const
  Symbols: array[0..1] of string = ('-', '+');
var
  i: int;
begin
  if Node.Hidden or (Node.Level <> 0) then
  begin
    if (Node.FileName <> '') and (Node.FileName <> Node.Text) then
    begin
      sl.Add(Indent + Symbols[Node.ImageIndex] + Node.FileName);
      sl.Add(Indent + '=' + Node.Text);
    end else
      sl.Add(Indent + Symbols[Node.ImageIndex] + Node.Text);
    if Node.Param2 <> '' then
      sl.Add(Indent + '!' + Node.Param2);
    Indent:= Indent + #9;
  end;
  for i := 0 to high(Node.AllItems) do
    WriteTextNode(sl, Node.AllItems[i], Indent);
end;

function TRSLodEdit.SaveTextNodes(Nodes: array of TTreeNode): string;
var
  sl: TMyStringList;
  i: int;
begin
  sl:= TMyStringList.Create;
  try
    sl.Add('Favorites');
    for i := 0 to high(Nodes) do
      WriteTextNode(sl, TMyNode(Nodes[i]), '');
    Result:= sl.GetTextStr;
  finally
    sl.Free;
  end;
end;

procedure TRSLodEdit.SaveTree(FileName:string);
var a,a1: string; s:string;
begin
  if (FileName='') then exit;
  if not FileExists(FileName) and (TMyNode(TreeView1.Items[0]).FullCount=0) then
    exit;
  s:=ChangeFileExt(FileName, '.bak');
  if FavsAsText then
    a:= SaveTextNodes([TreeView1.Items[0]])
  else
    a:= SaveNodes([TreeView1.Items[0]]);

  if FileExists(FileName) then
  try
    a1:=RSLoadTextFile(FileName); // !!! надо вначале сравнивать размер
    if (length(a)=length(a1)) and (a = a1) then
      exit;
  except
  end;
  DeleteFile(ptr(s));
  MoveFile(ptr(FileName), ptr(s));
  RSSaveTextFile(FileName, a);
end;

procedure TRSLodEdit.TreeView1Change(Sender: TObject; Node: TTreeNode);
var i,j:int; s:string; // r:TRect;
begin
  if not CanSelectListView or (Node<>TreeView1.Selected) or
                                 (Node = nil) or (Node.ImageIndex<>0) then exit;
  s:=(Node as TMyNode).FileName;
  if (ListView1.Selected<>nil) and (s=SelCaption) then
  begin
    Node.Data:=ptr(ItemIndexes[LastSel]+1);
    exit;
  end;

  i:= int(Node.Data) - 1;
  if ((i < 0) or (i >= Archive.RawFiles.Count)
     or not SameText(Archive.RawFiles.Name[i], s)) and not Archive.RawFiles.FindFile(s, i) then
    exit;

  Node.Data:= ptr(i + 1);
  i:= ArchiveIndexes[i];

  j:=ListView1.SelCount;
  if j>=1 then
    if j=1 then
      ListView1.Selected.Selected:=false
    else
      for j:=0 to ListView1.Items.Count-1 do
        ListView1.Items[j].Selected:=false;

  //ListView_EnsureVisible(ListView1.Handle, i, false);
  ListView_SetItemState(ListView1.Handle, i, LVIS_SELECTED or LVIS_FOCUSED,
                                              LVIS_SELECTED or LVIS_FOCUSED);
  Timer2.Enabled:=true;
end;

procedure TRSLodEdit.AddtoFavorites1Click(Sender: TObject);
var i:int;
begin
  CanSelectListView:=false;
  try
    with ListView1.Items do
      for i:=0 to Count-1 do
        if Item[i].Selected then
        begin
          AddTreeNode(Archive.Names[ItemIndexes[i]], 0, false);
        end;
  finally
    CanSelectListView:=true;
  end;
end;

procedure TRSLodEdit.ListView1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
  Handled:=ListView1.Selected=nil;
  {
  with MousePos do
    a:=ListView1.GetItemAt(X, Y);
  if (a=nil) or not a.Selected then
  begin
    mouse_event(MOUSEEVENTF_LEFTDOWN,0,0,0,0);
    mouse_event(MOUSEEVENTF_LEFTUP,0,0,0,0);
    Application.ProcessMessages;
    Handled:=ListView1.Selected=nil;
  end;
  }
{  with Mouse.CursorPos do
    PopupMenu1.Popup(x, y);}
end;

procedure TRSLodEdit.TreeView1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
var
  TimerOn: Boolean;
  DropItem: TTreeNode;
  i: int;
begin
  Accept:= false;
  if Source <> Sender then  exit;
  TimerOn:= false;
  DropItem:= (Sender as TTreeView).GetNodeAt(x, y);
  if DropItem = nil then
    DropItem:= TreeView1.Items[0];
  if DropItem <> DragTargetNode then
  begin
    DragTargetNode:= DropItem;
    DragTimer.Enabled:= false;
    TimerOn:= true;
  end;
  if (DropItem = nil) or (DropItem = DragNode) then
    exit;
  for i:= 0 to high(DragNodes) do
    if (DropItem = DragNodes[i]) or DropItem.HasAsParent(DragNodes[i]) then
      exit;
  Accept:= true;
  if TimerOn then
    DragTimer.Enabled:= not DragNode.HasAsParent(DropItem);
end;

procedure TRSLodEdit.TreeView1DragDrop(Sender, Source: TObject; X, Y: Integer);
var
  Node: TTreeNode;
  i, n: int;
begin
  if Source = Sender then
    with Sender as TTreeView do
    begin
      Node:= GetNodeAt(x, y);
      if Node = nil then
        Node:= Items[0]
      else
        if Node.ImageIndex = 0 then
          Node:= Node.Parent;

      //if Node = DragNode.Parent then exit;

      Items.BeginUpdate;
      try
        n:= length(TMyNode(Node).AllItems);
        for i := 0 to high(DragNodes) do
        begin
          DragNodes[i].Selected:= false;
          DragNodes[i].MoveTo(Node, naAddChild);
        end;
        MoveNodeChildren(Node, Node, n);
        Perform(TVM_SELECTITEM, TVGN_CARET or TVSI_NOSINGLEEXPAND, int(DragNode.ItemId));
        for i:= 0 to high(DragNodes) do
          if DragNodes[i] <> DragNode then
            Subselect(DragNodes[i]);
      finally
        Items.EndUpdate;
      end;
    end;
end;

procedure TRSLodEdit.TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button=mbMiddle) and (@EnterReaderModeHelper<>nil) then
    EnterReaderModeHelper(TreeView1.Handle);
end;

procedure TRSLodEdit.TreeView1StartDrag(Sender: TObject;
  var DragObject: TDragObject);
begin
  with Sender as TTreeView do
  begin
    DragNode:= Selected;
    SetLength(DragNodes, SelectionCount);
    GetSortedSelectedNodes(TreeView1, DragNodes);
  end;
  DragTargetNode:= nil;
  DragTimer.Enabled:= false;
  InvalidateRect(TreeView1.Handle, nil, false);
end;

procedure TRSLodEdit.TreeView1WndProc(Sender: TObject; var m: TMessage;
  var Handled: Boolean; const NextWndProc: TWndMethod);
begin
  case m.Msg of
    CN_NOTIFY:
      with TWMNotify(m) do
        if NMHdr^.code = TVN_BEGINDRAG then
          if PNMTreeView(NMHdr).itemNew.hItem = TreeView1.Items[0].ItemId then
          begin
            Handled:= true;
            with TreeView1 do
              if not Items[0].Selected then
                Perform(TVM_SELECTITEM, TVGN_CARET or TVSI_NOSINGLEEXPAND, int(Items[0].ItemId));
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

procedure TRSLodEdit.TrySaveTree;
begin
  if FavsChanged then
    try
      SaveTree(GetTreePath(ArchiveFileName));
    except
      on e:Exception do
        Application.ShowException(e);
    end;
end;

procedure TRSLodEdit.UpdateFavsVisibility(Node: TTreeNode);
var
  i: int;
begin
  if Node = nil then
    Node:= TreeView1.Items[0];
  with TMyNode(Node) do
    for i := 0 to high(AllItems) do
      if AllItems[i].ImageIndex = 0 then
        UpdateNodeVisibility(AllItems[i])
      else
        UpdateFavsVisibility(AllItems[i]);
end;

procedure TRSLodEdit.UpdateNodeVisibility(Node: TTreeNode);
begin
  with TMyNode(Node) do
    Hidden:= GetParent.Hidden or (ImageIndex = 0) and (FilterExt <> AnyExt) and
       not SameText(ExtractFileExt(FileName), FilterExt);
end;

procedure TRSLodEdit.UpdatePreviewBmp;
var
  r: TRect;
begin
  r:= Image1.BoundsRect;
  InvalidateRect(Panel1.Handle, @r, false);
end;

procedure TRSLodEdit.UpdateRecent;
begin
  TRSSpeedButton(Open1.Tag).DropDownDisabled:= (RecentFiles1.Count = 0);
end;

procedure TRSLodEdit.UpdateToolbarState;
var
  b: Boolean;
begin
  if not FEditing then
    exit;
  TRSSpeedButton(SaveSelectionAsArchive1.Tag).Enabled:= Archive <> nil;
  if ListView1.SelCount <= 1 then
    TRSSpeedButton(ExtractTo2.Tag).Hint:= SExtractAs
  else
    TRSSpeedButton(ExtractTo2.Tag).Hint:= SExtractTo;
  b:= ListView1.SelCount<>0;
  TRSSpeedButton(Extract2.Tag).Enabled:= b;
  TRSSpeedButton(ExtractTo2.Tag).Enabled:= b;
  TRSSpeedButton(Add1.Tag).Enabled:= b;
  TRSSpeedButton(ExtractForDefTool2.Tag).Enabled:= b and CanExtractDef;
  TRSSpeedButton(Rebuild1.Tag).Enabled:= Archive <> nil;
  TRSSpeedButton(MergeWith1.Tag).Enabled:= Archive <> nil;
  TRSSpeedButton(CompareTo1.Tag).Enabled:= Archive <> nil;
end;

procedure TRSLodEdit.Cut1Click(Sender: TObject);
var Node:TTreeNode;
begin
  Node:=TreeView1.Selected;
  if Node=nil then exit;
  Copy1Click(nil);
  if Node.Level=0 then
    TMyNode(Node).DeleteChildren
  else
    Delete1Click(nil);
end;

procedure SetClipboardBuffer(Format: Word; var Buffer; Size: Integer);
var
  Data: THandle;
  DataPtr: Pointer;
begin
  Clipboard.Open;
  try
    Data := GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE, Size);
    try
      DataPtr := GlobalLock(Data);
      try
        Move(Buffer, DataPtr^, Size);
        //Adding;
        SetClipboardData(Format, Data);
      finally
        GlobalUnlock(Data);
      end;
    except
      GlobalFree(Data);
      raise;
    end;
  finally
    Clipboard.Close;
  end;
end;

procedure SaveClipboard(Data:string; Format:DWord);
begin
  if Data = '' then exit;
  SetClipboardBuffer(Format, Data[1], length(Data));
end;

function TRSLodEdit.CancelCompare: Boolean;
begin
  Result:= SwitchCheck(CompareTo1, false);
  if Result then
    SpecFilter:= nil;
  FilterItemVisible:= nil;
end;

function TRSLodEdit.CanExtractDef: Boolean;
var
  i: int;
begin
  Result:= true;
  if Def1.Visible then
    with ListView1, Items do
      for i:=0 to Count-1 do
        if Item[i].Selected and SameText(ExtractFileExt(Archive.Names[ItemIndexes[i]]), '.def') then
          exit;
  Result:= false;
end;

procedure TRSLodEdit.CheckFileChanged;
begin
  if Archive = nil then
    exit;

  if Archive.RawFiles.CheckFileChanged then
  begin
    if ListView1.Selected<>nil then
      DefaultSel:= SelCaption;
    CreateArchive(Archive.RawFiles.FileName);
    EndLoad(true);
  end else
    with TRSLod(Archive) do
      if (Archive is TRSLod) and RSMMArchivesCheckFileChanged(BitmapsLods, Archive) then
      begin
        LoadBitmapsLods(ExtractFilePath(TRSLod(BitmapsLods[0]).RawFiles.FileName));
        if LastSel >= 0 then
          LoadFile(LastSel);
      end;
end;

function TRSLodEdit.ConfirmBox(const msg: string): Boolean;
begin
  Result:= RSMessageBox(Handle, msg, 'Confirmation', MB_OKCANCEL or MB_ICONQUESTION) = mrOk;
end;

procedure TRSLodEdit.ConvertToPalette(Sender: TRSLod; b, b1: TBitmap);
var
  pal: HPALETTE;
begin
  pal:= CreateOptimizedPaletteFromSingleBitmap(b1, 256, 8, false);
  b1.PixelFormat:= pf8bit;
  b1.Palette:= NormalizePalette(b, pal);
  b1.Canvas.Draw(0, 0, b);
end;

procedure TRSLodEdit.Copy1Click(Sender: TObject);
var Nodes:array of TTreeNode;
begin
  with TreeView1 do
  begin
    SetLength(Nodes, SelectionCount);
    GetSortedSelectedNodes(TreeView1, Nodes);
  end;
  if length(Nodes)=0 then  exit;
  ClipboardBackup:= SaveNodes(Nodes);
  SaveClipboard(ClipboardBackup, ClipboardFormat);
end;

procedure TRSLodEdit.Copy2Click(Sender: TObject);
var
  s: string;
begin
  FillDropSource(true);
  ExtractDropSource(true);
  DropFileSource1.CopyToClipboard;
  if FDragFilesList.Count = 1 then
    s:= FDragFilesList[0]
  else
    s:= TMyStringList(FDragFilesList).GetTextStr;
  FCopyStr:= s;
  AddTextClipboardFormat(s);
end;

procedure TRSLodEdit.CopyName1Click(Sender: TObject);
begin
  Clipboard.Text:= SelCaption;
end;

procedure TRSLodEdit.CreateArchive(FileName: string);
begin
  TrySaveTree;
  FreeArchive;
  Archive:= RSLoadMMArchive(FileName);
  ArchiveCreated;
end;

procedure TRSLodEdit.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WinClassName:='MMArchive Main Form';
end;

function LoadClipboard(Format:DWord): string;
var h:THandle; DataPtr:pointer; Size:DWord;
begin
  if not IsClipboardFormatAvailable(Format) then
    exit;

  DataPtr:=nil;
  h:=0; // Чтоб копиллятор не ругался
  Clipboard.Open;
  try
    h:=Clipboard.GetAsHandle(Format);
    if h=0 then RSRaiseLastOSError;
    DataPtr:=GlobalLock(h);
    if DataPtr=nil then RSRaiseLastOSError;
    Size:=GlobalSize(h);
    SetLength(Result, Size);
    CopyMemory(ptr(Result), DataPtr, Size);
  finally
    if DataPtr<>nil then
      GlobalUnlock(h);
    Clipboard.Close;
  end;
end;

procedure TRSLodEdit.Paste1Click(Sender: TObject);
var a:string; Node:TTreeNode;
begin
  with TreeView1 do
  begin
    Node:=TreeView1.Selected;
    if Node=nil then
      Node:=TreeView1.Items[0]
    else
      if Node.ImageIndex=0 then
        Node:=Node.Parent;
    a:= LoadClipboard(ClipboardFormat);
    if a = '' then
      a:= ClipboardBackup;
    DoLoadTree(a, Node as TMyTreeNode);
  end;
end;

procedure TRSLodEdit.Paste2Click(Sender: TObject);
var
  f: THandle;
  sl: TStringList;
  s: string;
  i, n: int;
begin
  if Archive = nil then
    exit;
  f:= Clipboard.GetAsHandle(CF_HDROP);
  if f = 0 then
    exit;

  sl:= TStringList.Create;
  try
    n:= DragQueryFile(f, $FFFFFFFF, nil, 0);
    for i := 0 to n - 1 do
    begin
      SetLength(s, DragQueryFile(f, i, nil, 0));
      if (s<>'') and (int(DragQueryFile(f, i, ptr(s), length(s)+1)) = length(s)) then
        sl.Add(s);
    end;
    if Archive <> nil then
      DoAdd(sl);
  finally
    sl.Free;
  end;
end;

type
  TBinkHeaderPart = record
    Signature: array[0..2] of char;
    Version: byte;
  end;

procedure TRSLodEdit.PlayVideo;
var
  hdr: TBinkHeaderPart;
  i: int;
begin
  if not ExceptionsSilenced then
    RSSetSilentExceptionsFiter;
  ExceptionsSilenced:= true;
  if VideoStream = nil then
  begin
    VideoStream:= Archive.RawFiles.GetAsIsFileStream(ItemIndexes[LastSel]);
    try
      VideoStream.ReadBuffer(hdr, 4);
      VideoStream.Seek(-4, soCurrent);
      if hdr.Signature = 'SMK' then
        i:= 0
      else
        if hdr.Version > $62 then
          i:= 1
        else
          i:= 2;

      VideoPlayer:= VideoPlayers[i];
      if VideoPlayer = nil then
      begin
        case i of
          0: VideoPlayer:= TRSSmackPlayer.Create(AppPath + 'SmackW32.DLL');
          1: VideoPlayer:= TRSBinkPlayer.Create(AppPath + 'BinkW32.dll');
          2: VideoPlayer:= TRSBinkPlayer.Create(AppPath + 'BinkW32old.dll');
        end;
        VideoPlayers[i]:= VideoPlayer;
      end;
      VideoPlayer.Open((VideoStream as TFileStream).Handle);
    except
      Archive.RawFiles.FreeAsIsFileStream(ItemIndexes[LastSel], VideoStream);
      VideoStream:= nil;
      VideoPlayer:= nil;
      raise;
    end;
    NeedPreviewBmp.Height:= 0;
    PreviewBmp.PixelFormat:= pf32bit;
    VideoPlayer.PreparePic(PreviewBmp);
    VideoPlayer.ExtractFrame(PreviewBmp);
    UpdatePreviewBmp;
    if not Timer1.Enabled then  // if inactive
      VideoPlayer.Pause:= true;
  end else
    if VideoPlayer <> nil then
      VideoPlayer.Pause:= false;
  Timer1.Interval:= 10;
end;

procedure TRSLodEdit.PleaseWait(const s: string);
begin
  PanelRebuilding.Caption:= s;
  PanelRebuilding.Visible:= s <> '';
  if s <> '' then
    PanelRebuilding.Repaint;
end;

{
var Node:TTreeNode; i:int;
begin
  if length(CutNodes)=0 then exit;
  with TreeView1 do
  begin
    Node:=TreeView1.Selected;
    if Node=nil then
      Node:=TreeView1.Items[0]
    else
      if Node.ImageIndex=0 then
        Node:=Node.Parent;
    if Node=CutNodes[0].Parent then exit;
    for i:=length(CutNodes)-1 downto 0 do
      CutNodes[i].MoveTo(Node, naAddChild);
    Node.CustomSort(nil, 0);
  end;
end;
}


procedure TRSLodEdit.TreeView1CreateNodeClass(Sender: TCustomTreeView;
  var NodeClass: TTreeNodeClass);
begin
  NodeClass:=TMyTreeNode;
end;

procedure TRSLodEdit.Button1Click(Sender: TObject);
begin
  if ListView1.Selected=nil then exit;
  RSLodResult:=SelCaption;
  ModalResult:=mrOk;
end;

procedure TRSLodEdit.ListView1DblClick(Sender: TObject);
begin
  if not FEditing then
    Button1.Click;
end;

procedure TRSLodEdit.IgnoreUnpackingErrors1Click(Sender: TObject);
begin
  if Archive <> nil then
  begin
    Archive.RawFiles.IgnoreUnzipErrors:= IgnoreUnpackingErrors1.Checked;
    if Archive.RawFiles.IgnoreUnzipErrors and (FileType = aNone) and (ListView1.SelCount <> 0) then
      LoadFile(LastSel);
  end;
end;

procedure TRSLodEdit.Image1DblClick(Sender: TObject);
begin
  if (PreviewBmp <> nil) and (PreviewBmp.Width <> 0) and (PreviewBmp.Height <> 0) then
  begin
    Panel2.Width:= max(Panel2.Width, min(PreviewBmp.Width + Image1.Left + 1, ClientWidth - 30));
    Panel1.Height:= max(Panel1.Height, min(PreviewBmp.Height + (Panel1.Height - RSSpeedButton1.Top + Image1.Left), Panel2.Height - 30));
  end;
  if ListView1.SelCount <> 0 then
    ListView_EnsureVisible(ListView1.Handle, LastSel, false);
end;

procedure TRSLodEdit.Initialize(Editing:boolean=false; UseRSMenus:boolean=true);
begin
  {
  self:=ptr(TRSLodEdit.NewInstance);
  RSLodEdit:=self;
  self.Create(Application);
  }
  Application.CreateForm(TRSLodEdit, RSLodEdit);
  self:=RSLodEdit;
  if UseRSMenus then
  begin
    RSMenu.Add(PopupTree);
    RSMenu.Add(PopupList);
    if Editing then
    begin
      RSMenu.Add(MainMenu1);
      RSMenu.OnGetShortCut:= MenuShortCut;
    end;
  end;
  with RSLanguage.AddSection('[TRSLodEdt]', self) do
  begin
    AddItem('SDeleteQuestion', SDeleteQuestion);
    AddItem('SDeleteManyQuestion', SDeleteManyQuestion);
    AddItem('SNewFolder', SNewFolder);
    AddItem('SExtractAs', SExtractAs);
    AddItem('SExtractTo', SExtractTo);
    AddItem('SEPaletteNotFound', SEPaletteNotFound);
    AddItem('SEPaletteMustExist', SEPaletteMustExist);
    AddItem('SPalette', SPalette);
    AddItem('SPaletteChanged', SPaletteChanged);
    AddItem('SFavorites', SFavorites);
    AddItem('SRenameOverwriteQuestion', SRenameOverwriteQuestion);
    AddItem('SExtractOverwriteFileQuestion', SExtractOverwriteFileQuestion);
    AddItem('SExtractOverwriteDirQuestion', SExtractOverwriteDirQuestion);
    AddItem('SPleaseWait', SPleaseWait);
    AddItem('SPleaseWaitRebuilding', SPleaseWaitRebuilding);
  end;
  FEditing:= Editing;
  if not Editing then
  begin
    Panel3.Hide;
    Panel4.Show;
    ListView1.MultiSelect:= false;
    //ProgressBar1.Top:=ProgressBar1.Top-Panel3.Height;
     // temp
    with PopupList.Items do
    begin
      Delete(IndexOf(Extract1));
      Delete(IndexOf(Extractto1));
      Delete(IndexOf(ExtractForDefTool1));
      Delete(IndexOf(Delete2));
      Delete(IndexOf(Rename2));
      Delete(IndexOf(Copy2));
      Delete(IndexOf(Paste2));
    end;
    Menu:=nil;
  end else
  begin
    Application.Title:= AppCaption;
    with PopupList.Items do
    begin
      Delete(IndexOf(Select1));
      Delete(IndexOf(CopyName1));
    end;
    RSBindToolBar:= true;
    ComboExtFilter.Left:= 1 + RSMakeToolBar(Panel3, [New1, Open1, RecentFiles1,
      SaveSelectionAsArchive1, N3,
      Add1, Extract2, ExtractTo2, ExtractForDefTool2, N6,
      Rebuild1, MergeWith1, CompareTo1, N6, Sortbyextension1], Toolbar, 1);
    UpdateToolbarState;
    TmpRecent1.Free;
    Recent:= TRSRecent.Create(RecentClick, RecentFiles1, true);
    RSHelpCreate(AppCaption + ' Help Form');
    LoadIni;
    DragAcceptFiles(Handle, true);
  end;

  //RSSaveTextFile(AppPath + 'lang.txt', RSLanguage.MakeLanguage);

  if not Editing then
    DestroyHandle;
end;

procedure TRSLodEdit.Button2Click(Sender: TObject);
begin
//  Closing:=true;
  Close;
end;

procedure TRSLodEdit.MenuShortCut(Item: TMenuItem; var Result: string);
begin
  if Item = Delete3 then
    Result:= 'Del'
  else if Item = AddtoFavorites2 then
    Result:= 'Ctrl+Enter'
  else if Item = Copy3 then
    Result:= 'Ctrl+C'
  else if Item = Paste3 then
    Result:= 'Ctrl+V'
  else if Item = Rename3 then
    Result:= 'Enter';
end;

procedure TRSLodEdit.MergeFavorites1Click(Sender: TObject);
begin
  if not OpenDialog2.Execute then exit;
  LoadTree(OpenDialog2.FileName);
end;

procedure TRSLodEdit.MergeWith1Click(Sender: TObject);
var
  arc: TRSMMArchive;
begin
  OpenDialogMerge.InitialDir:= ExtractFilePath(Archive.RawFiles.FileName);
  if not OpenDialogMerge.Execute then  exit;
  arc:= RSLoadMMArchive(OpenDialogMerge.FileName);
  try
    if arc.Count = 0 then  exit;
    FreeVideo;
    CancelCompare;
    DefaultSel:= arc.RawFiles.Name[arc.Count - 1];
    PleaseWait(SPleaseWait);
    if Archive.Count = 0 then
      Archive.RawFiles.ReserveFilesCount(arc.Count);
    arc.RawFiles.MergeTo(Archive.RawFiles);
    EndLoad(true);
  finally
    PleaseWait;
    arc.Free;
  end;
end;

procedure TRSLodEdit.MoveDown1Click(Sender: TObject);
begin
  MoveSelectedNodes(false);
end;

procedure TRSLodEdit.MoveNodeChildren(Source, Destination: TTreeNode; BaseIndex: int);
label
  next;
var
  Src: TMyNode absolute Source;
  Dest: TMyNode absolute Destination;
  i, DestHigh, k: int;
  it, NextNode: TMyNode;
begin
  // files always go after folders, folders with the same name must be joined
  // also don't allow exact copies of the same file
  NextNode:= nil;
  if Src = Dest then
  begin
    if (BaseIndex >= length(Dest.AllItems)) or (BaseIndex = 0) then  exit;
    NextNode:= Dest.AllItems[BaseIndex];
  end;
  while (NextNode <> nil) or (Src.AllItems <> nil) and (Src <> Dest) do
  begin
    if NextNode <> nil then
    begin
      it:= NextNode;
      i:= it.Index + 1;
      NextNode:= nil;
      if i < length(Dest.AllItems) then
        NextNode:= Dest.AllItems[i];
      DestHigh:= i - 2;
    end else
    begin
      it:= Src.AllItems[0];
      DestHigh:= high(Dest.AllItems);
    end;

    if it.ImageIndex = 0 then
      k:= MaxInt
    else
      k:= 0;

    for i := 0 to DestHigh do
      if Dest.AllItems[i].ImageIndex = it.ImageIndex then
      begin
        k:= i + 1;
        if SameText(it.Text, Dest.AllItems[i].Text) then
          if (it.ImageIndex = 0) and SameText(it.FileName, Dest.AllItems[i].FileName) then
          begin
            it.Delete;
            goto next;
          end else
            if it.ImageIndex = 1 then
            begin
              MoveNodeChildren(it, Dest.AllItems[i]);
              it.Delete;
              goto next;
            end;
      end;
    it.MoveToIndex(Dest, k);
next:
  end;
end;

procedure TRSLodEdit.MoveSelectedNodes(MoveUp: Boolean);
var
  Nodes: array of TMyNode;
  CurSel: TTreeNode;

  function IsSelected(Node: TMyNode): Boolean;
  var
    i: int;
  begin
    Result:= true;
    for i := 0 to high(Nodes) do
      if Node = Nodes[i] then
        exit;
    Result:= false;
  end;

var
  i, j, k: int;
begin
  with TreeView1 do
  begin
    SetLength(Nodes, SelectionCount);
    GetSortedSelectedNodes(TreeView1, Nodes, not MoveUp);
    CurSel:= Selected;
    if CurSel = nil then  exit;
      //CurSel:= Nodes[0];
    Items.BeginUpdate;
  end;

  try
    for i := 0 to high(Nodes) do
    begin
      if Nodes[i] = TreeView1.Items[0] then  continue;
      with Nodes[i] do
      begin
        k:= Index;
        if MoveUp then
        begin
          for j := k - 1 downto 0 do
            if GetParent.AllItems[j].ImageIndex = ImageIndex then
            begin
              if IsSelected(GetParent.AllItems[j]) then
                break;
              k:= j;
              if not GetParent.AllItems[j].Hidden then
                break;
            end;
        end else
        begin
          for j := k + 1 to high(GetParent.AllItems) do
            if GetParent.AllItems[j].ImageIndex = ImageIndex then
            begin
              if IsSelected(GetParent.AllItems[j]) then
                break;
              k:= j;
              if not GetParent.AllItems[j].Hidden then
                break;
            end;
        end;
        Selected:= false; // avoid expanding
        Index:= k;
      end;
    end;

  finally
    TreeView1.Items.EndUpdate;
  end;

  with TreeView1 do
  begin
    Perform(TVM_SELECTITEM, TVGN_CARET or TVSI_NOSINGLEEXPAND, int(CurSel.ItemId));
    for i:= 0 to high(Nodes) do
      if Nodes[i] <> CurSel then
        Subselect(Nodes[i]);
  end;
end;

procedure TRSLodEdit.MoveUp1Click(Sender: TObject);
begin
  MoveSelectedNodes(true);
end;

procedure TRSLodEdit.Timer2Timer(Sender: TObject);
begin
  ListView_EnsureVisible(ListView1.Handle, LastSel, false);
  Timer2.Enabled:=false;
end;

procedure TRSLodEdit.Language1Click(Sender: TObject);
var
  s: string;
  m: TMenuItem;
  i: int;
begin
  for i := Language1.Count - 1 downto 1 do
    Language1.Items[i].Free;

  English1.Checked:= SameText(FLanguage, 'English');
  with TRSFindFile.Create(AppPath + LangDir + '*.txt') do
    try
      while FindAttributes(0, FILE_ATTRIBUTE_DIRECTORY) do
      begin
        s:= ChangeFileExt(Data.cFileName, '');
        if not SameText(s, 'English') then
        begin
          m:= TMenuItem.Create(self);
          m.RadioItem:= true;
          m.Caption:= s;
          m.OnClick:= English1Click;
          m.OnDrawItem:= English1.OnDrawItem;
          m.OnAdvancedDrawItem:= English1.OnAdvancedDrawItem;
          m.OnMeasureItem:= English1.OnMeasureItem;
          Language1.Add(m);
          m.Checked:= SameText(FLanguage, s);
        end;
        FindNext;
      end;
    finally
      Free;
    end;
end;

procedure TRSLodEdit.ListView1Change(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  Timer2.Enabled:=false;
end;

procedure TRSLodEdit.RSSpeedButton3Click(Sender: TObject);
begin
  if Def=nil then exit;
  Def.RebuildPal;
  LoadBmp(LastBmp, NeedPreviewBmp);
  UpdatePreviewBmp;
end;

procedure TRSLodEdit.ListView1Data(Sender: TObject; Item: TListItem);
begin
  with Item do
  begin
    Caption:= ItemCaptions[Index];
    Data:= ptr(ItemIndexes[Index]);
  end;
end;

procedure TRSLodEdit.Open1Click(Sender: TObject);
begin
  if ListView1.Selected<>nil then
    DefaultSel:= SelCaption;
  PrepareLoad;
  if not OpenDialog1.Execute then exit;

  FilterExt:= AnyExt;
  CancelCompare;

  CreateArchive(OpenDialog1.FileName);
  EndLoad(false);
end;

procedure TRSLodEdit.Options1Click(Sender: TObject);
begin
  Associate1.Checked:= Association1.Associated;
  Associate2.Checked:= Association2.Associated;
  Associate3.Checked:= Association3.Associated;
  Associate4.Checked:= Association4.Associated;
  Associate5.Checked:= Association5.Associated;
end;

procedure TRSLodEdit.File1Click(Sender: TObject);
begin
  RecentFiles1.Visible:= RecentFiles1.Count > 0;
  SaveSelectionAsArchive1.Enabled:= Archive <> nil;
end;

procedure TRSLodEdit.FillDropSource(copy: Boolean);
var
  s: string;
  i: int;
begin
  if FMyTempPath = '' then
  begin
    SetLength(FMyTempPath, MAX_PATH);
    SetLength(FMyTempPath, GetTempPath(MAX_PATH + 1, ptr(FMyTempPath)));
    FMyTempPath:= IncludeTrailingPathDelimiter(FMyTempPath);
    FMyTempPath:= FMyTempPath + 'MMArchive' + IntToStr(GetCurrentProcessId);
    FMyTempPath:= IncludeTrailingPathDelimiter(FMyTempPath);
  end;
  s:= FMyTempPath;
  if not copy then
    s:= s + 'd\';
  DropFileSource1.Files.Clear;
  FDragFilesList.Clear;
  with ListView1 do
    for i:= 0 to Items.Count - 1 do
      if Items[i].Selected then
      begin
        DropFileSource1.Files.Add(s + Archive.GetExtractName(ItemIndexes[i]));
        FDragFilesList.Add(ItemCaptions[i]);
      end;
end;

procedure TRSLodEdit.FindSpritePal(name: string; var pal: int2; Kind: int);
var
  sl: TStringList;
const
  size6 = $38;
  size7 = $3C;
  OffName = 12;
  OffPal6 = 48;
  OffPal7 = 50;

  function DoFindPal(const name: string): Boolean;
  var
    Kinds: array[1..3] of int2;
    size, n, i, j: int;
    p, p1: PChar;
  begin
    n:= pint(FSFT.Memory)^;
    size:= (FSFT.Size - pint(PChar(FSFT.Memory) + 4)^*2) div n;

    p:= PChar(FSFT.Memory) + 8 + OffName;
    if size = size7 then
      p1:= PChar(FSFT.Memory) + 8 + OffPal7
    else
      p1:= PChar(FSFT.Memory) + 8 + OffPal6;

    Result:= true;
    for i := 1 to 3 do
      Kinds[i]:= 0;
    for i := 0 to n - 1 do
    begin
      if (pint2(p1)^ <> 0) and (StrComp(p, ptr(name)) = 0) then
      begin
        for j := 1 to 3 do
        begin
          if Kinds[j] = pint2(p1)^ then  break;
          if Kinds[j] = 0 then
          begin
            if Kind = j then
            begin
              pal:= pint2(p1)^;
              exit;
            end;
            Kinds[j]:= pint2(p1)^;
            break;
          end;
        end;
      end;
      inc(p, size);
      inc(p1, size);
    end;
    for i := Kind downto 1 do
      if Kinds[i] <> 0 then
      begin
        pal:= Kinds[i];
        exit;
      end;
    Result:= false;
  end;

  procedure FindLods(const mask: string);
  begin
    with TRSFindFile.Create(mask) do
      try
        while FindEachFile do
          sl.Add(FileName);
      finally
        Free;
      end;
  end;

var
  Lod: TRSLod;
  fs: TFileStream;
  s, name1: string;
  mm8: Boolean;
  size, i, j: int;
  p: PChar;
begin
  if FSFT = nil then
  begin
    if FSFTNotFound then  exit;
    FSFTNotFound:= true;
    name1:= ExtractFilePath(TRSLod(Archive).BitmapsLod.RawFiles.FileName);
    if not FileExists(name1 + '..\DataFiles\dsft.bin') then
    begin
      s:= 'english';
      with TRSRegistry.Create do
        try
          RootKey:= HKEY_LOCAL_MACHINE;
          if OpenKeyReadOnly('SOFTWARE\New World Computing\Might and Magic Day of the Destroyer\1.0') then
            Read('language_file', s);
        finally
          Free;
        end;
      s:= s + 'T.lod';
      mm8:= false;

      if FileExists(name1 + s) then
        mm8:= true
      else if FileExists(name1 + 'EnglishT.lod') then
      begin
        s:= 'EnglishT.lod';
        mm8:= true;
      end
      else if FileExists(name1 + 'events.lod') then
        s:= 'events.lod'
      else if FileExists(name1 + 'icons.lod') then
        s:= 'icons.lod'
      else
        exit; // !!! show dialog

      Lod:= nil;
      sl:= TStringList.Create;
      try
        FindLods(name1 + s);
        if mm8 then
          FindLods(name1 + '*.T.lod');
        FindLods(name1 + '*.' + s);
        Lod:= TRSLod.Create;
        for i:= sl.Count - 1 downto 0 do
        begin
          Lod.Load(sl[i]);
          if Lod.RawFiles.FindFile('dsft.bin', j) then
          begin
            FSFT:= TMemoryStream.Create;
            Lod.Extract(j, FSFT);
            break;
          end;
        end;
      finally
        sl.Free;
        Lod.Free;
      end;
      if FSFT = nil then  exit;
    end else
    begin
      fs:= TFileStream.Create(name1 + '..\DataFiles\dsft.bin', fmOpenRead);
      try
        FSFT:= TMemoryStream.Create;
        RSCopyStream(FSFT, fs, fs.Size);
      finally
        fs.Free;
      end;
    end;

    size:= (FSFT.Size - pint(PChar(FSFT.Memory) + 4)^*2) div pint(FSFT.Memory)^;

    p:= PChar(FSFT.Memory) + 8 + OffName;
    for i := 0 to pint(FSFT.Memory)^ - 1 do
    begin
      StrLower(p);
      inc(p, size);
    end;
  end;

  name:= LowerCase(name);
  if not DoFindPal(name) and (name[length(name)] in ['0'..'7']) then
    if not DoFindPal(copy(name, 1, length(name) - 1)) and (name[length(name)] <> '0') then
    begin
      name[length(name)]:= '0';
      DoFindPal(name);
    end;
end;

procedure TRSLodEdit.PrepareLoad;
begin
  with OpenDialog1 do
  begin
    Title:='';
    Options:=[ofHideReadOnly,ofPathMustExist,ofFileMustExist,ofEnableSizing];
    SaveDialog:=false;
    if Archive <> nil then
      FileName:= Archive.RawFiles.FileName;
  end;
end;

procedure TRSLodEdit.NeedBitmapsLod(Sender: TObject);
begin
  with TRSLod(Sender) do
  begin
    LoadBitmapsLods(ExtractFilePath(RawFiles.FileName));
    if (BitmapsLods = nil) and OpenDialogBitmapsLod.Execute then
      LoadBitmapsLods(ExtractFilePath(OpenDialogBitmapsLod.FileName));
  end;
end;

procedure TRSLodEdit.NeedPalette(Sender: TRSLod; Bitmap: TBitmap;
  var Palette: int);
var
  PalData: array[0..767] of Byte;
  pal: int;
begin
  if Bitmap.PixelFormat <> pf8bit then
    raise Exception.Create(SEPaletteMustExist);
  RSWritePalette(@PalData, Bitmap.Palette);
  if Sender.BitmapsLods = nil then
  begin
    NeedBitmapsLod(Sender);
    if Sender.BitmapsLods = nil then
      exit;
  end;

  pal:= RSMMArchivesFindSamePalette(Sender.BitmapsLods, PalData);
  if pal <> 0 then
    Palette:= pal
  else
    raise Exception.Create(SEPaletteNotFound);
end;

function TRSLodEdit.NeedPreviewBmp: TBitmap;
begin
  if PreviewBmp = nil then
    PreviewBmp:= TBitmap.Create;
    
  Result:= PreviewBmp;
end;

procedure TRSLodEdit.New1Click(Sender: TObject);
const
  vers: array[0..14] of TRSLodVersion = (RSLodHeroes, RSLodHeroes, RSLodHeroes,
    RSLodGames, RSLodHeroes, RSLodGames, RSLodBitmaps, RSLodIcons, RSLodSprites,
    RSLodMM8, RSLodGames7, RSLodGames, RSLodChapter7, RSLodChapter, RSLodHeroes
  );
var
  ver: TRSLodVersion;
  s, dir: string;
begin
  SaveDialogNew.InitialDir:= DialogToFolder(OpenDialog1);
  SaveDialogNew.FileName:= '';
  if not SaveDialogNew.Execute then exit;
  FreeArchive;
  OpenDialog1.FileName:= SaveDialogNew.FileName;
  dir:= ExtractFilePath(SaveDialogNew.FileName);
  RSCreateDir(dir);
  s:= ExtractFileExt(SaveDialogNew.FileName);
  ver:= vers[SaveDialogNew.FilterIndex - 1];
  if SameText(s, '.snd') then
  begin
    Archive:= TRSSnd.Create;
    TRSSnd(Archive).New(SaveDialogNew.FileName, ver <> RSLodHeroes);
  end else
  if SameText(s, '.vid') then
  begin
    Archive:= TRSVid.Create;
    TRSVid(Archive).New(SaveDialogNew.FileName, ver <> RSLodHeroes);
  end else
  begin
    Archive:= TRSLod.Create;
    TRSLod(Archive).New(SaveDialogNew.FileName, ver);
  end;
  ArchiveCreated;
  EndLoad(false);
end;

// determine transparent color and place it as the first index
function TRSLodEdit.NormalizePalette(b: TBitmap; HPal: HPALETTE): HPALETTE;
var
  best: int;

  function NotBest(x, y: int): Boolean;
  var
    c: TColor;
  begin
    c:= b.Canvas.Pixels[x, y];
    Result:= not ((c = $FFFF00) or (c = $FF00FF) or (c = $FC00FC) or (c = $FCFC00));
    if not Result or (x = 0) and (y = 0) then
      best:= GetNearestPaletteIndex(HPal, c);
  end;

var
  pal: array[-1..255] of int;
  w, h, i: int;
begin
  w:= b.Width - 1;
  h:= b.Height - 1;
  Result:= HPal;
  GetPaletteEntries(HPal, 0, 256, pal[0]);
  if NotBest(0, 0) and NotBest(0, h) and NotBest(w, h) and NotBest(w, 0) then
    for i:= 1 to 255 do
      if (pal[i] = $FFFF00) or
         (best = 0) and ((pal[i] = $FF00FF) or (pal[i] = $FC00FC) or (pal[i] = $FCFC00)) then
        best:= i;
  if best = 0 then  exit;
  zSwap(pal[0], pal[best]);
  pal[-1]:= $1000300;
  Result:= CreatePalette(PLogPalette(@pal)^);
  DeleteObject(HPal);
end;

function IsThere(s1, s2: string): Boolean;
var
  i: int;
begin
  RSLodCompareStr(PChar(s1), PChar(s2), i);
  Result:= i >= length(s2);
end;

procedure TRSLodEdit.ListView1DataFind(Sender: TObject; Find: TItemFind;
  const FindString: String; const FindPosition: TPoint; FindData: Pointer;
  StartIndex: Integer; Direction: TSearchDirection; Wrap: Boolean;
  var Index: Integer);
var
  i, j, m: int;
begin
  if StartIndex >= length(ItemIndexes) then
    StartIndex:= 0;
  m:= -1;
  if Archive.RawFiles.Sorted then
  begin
    if (StartIndex > 0) and IsThere(Archive.Names[ItemIndexes[StartIndex]], FindString) then
    begin
      Index:= StartIndex;
      exit;
    end;
    Archive.RawFiles.FindFile(FindString, i);
    while IsThere(Archive.RawFiles.Name[i], FindString) do
    begin
      j:= ArchiveIndexes[i];
      if j >= 0 then
      begin
        if (j < m) and ((j >= StartIndex) or (m < StartIndex)) or (j >= StartIndex) and (m < StartIndex) or (m < 0) then
          m:= j;
      end;
      inc(i);
    end;
    Index:= m;
  end else
  begin
    for i := StartIndex to length(ItemIndexes) - 1 do
      if IsThere(Archive.Names[ItemIndexes[i]], FindString) then
      begin
        Index:= i;
        exit;
      end;
    for i := 0 to StartIndex - 1 do
      if IsThere(Archive.Names[ItemIndexes[i]], FindString) then
      begin
        Index:= i;
        exit;
      end;
  end;
end;

procedure TRSLodEdit.Delete2Click(Sender: TObject);
begin
  DoDelete;
end;

procedure TRSLodEdit.DeselectTimerTimer(Sender: TObject);
const
  b = LVIS_FOCUSED or LVIS_SELECTED;
begin
  if ListView_GetItemState(ListView1.Handle, LastSel, b) <> b then
    LoadFile(-1);
  DeselectTimer.Enabled:= false;
end;

function TRSLodEdit.DialogToFolder(dlg: TOpenDialog): string;
begin
  Result:= ExtractFilePath(dlg.FileName);
  if Result = '' then
    Result:= dlg.InitialDir;
end;

procedure TRSLodEdit.DoExtract(Choose: Boolean; DefTool: Boolean);
var
  a: TStream;
  ad: TRSByteArray;
  s, s1, err, err1: string;
  i, j: int;
begin
  j:=ListView1.SelCount;
  if j=0 then
    exit;

  if Choose or (ExtractPath = '') then
  begin
    if (j=1) and not DefTool then
    begin
      s:= ExtractPath + Archive.GetExtractName(ItemIndexes[LastSel]);
      SaveDialogExport.Options:= [ofOverwritePrompt,ofHideReadOnly,ofEnableSizing];
    end else
    begin
      s:= ExtractPath + 'Extract Here';
      SaveDialogExport.Options:= [ofHideReadOnly,ofEnableSizing];
    end;

    SaveDialogExport.FileName:= s;
    if not SaveDialogExport.Execute then  exit;
    s:= SaveDialogExport.FileName;
    ExtractPath:= ExtractFilePath(s);
    RSCreateDir(ExtractPath);
    if (j<>1) or DefTool then
      s:='';
  end else
    s:='';

  // Overwrite prompt
  if s = '' then
    with ListView1, Items do
      for i:=0 to Count-1 do
        if Item[i].Selected then
        begin
          if DefTool then
            s1:= ExtractPath + ChangeFileExt(Archive.Names[ItemIndexes[i]], '')
          else
            s1:= ExtractPath + Archive.GetExtractName(ItemIndexes[i]);
          if FileExists(s1) or DirectoryExists(s1) then
            err:= err + #13#10 + s1;
        end;

  if err <> '' then
  begin
    if DefTool then
      err:= Format(SExtractOverwriteDirQuestion, [err])
    else
      err:= Format(SExtractOverwriteFileQuestion, [err]);

    if not ConfirmBox(err) then
      exit;
    // Yes-No-Cancel is better, but isn't worth the effort
    //i:= RSMessageBox(Handle, err, 'Confirmation', MB_YESNOCANCEL or MB_ICONQUESTION);
  end;

  // Extract
  s1:= '';
  err:= '';
  with ListView1, Items do
    for i:=0 to Count-1 do
      if Item[i].Selected then
      try
        s1:= Archive.Names[ItemIndexes[i]];
        if s <> '' then
        begin
          a:= TRSFileStreamProxy.Create(s, fmCreate);
          try
            Archive.Extract(ItemIndexes[i], a);
          finally
            s:='';
            a.Free;
          end;
        end else
          if DefTool and SameText(ExtractFileExt(s1), '.def') then
          begin
            Archive.ExtractArrayOrBmp(ItemIndexes[i], ad).Free;
            with TRSDefWrapper.Create(ad) do
              try
                err1:= ExtractDefToolList(
                   ExtractPath + ChangeFileExt(s1, '') + '\' + ChangeFileExt(s1, '.hdl'),
                   ExtractWithExternalShadow1.Checked, ExtractIn24Bits1.Checked);
                if err1 <> '' then
                  err:= err + s1 + ' : ' + err1;
              finally
                Free;
              end;
          end else
            Archive.Extract(ItemIndexes[i], ExtractPath);
      except
        on e: Exception do
        begin
          s:='';
          if j<>1 then
            err:= err + s1 + ' : ' + e.Message + #13#10
          else
            raise;
        end;
      end;

  if err <> '' then
    ErrorBox(err);
end;

procedure TRSLodEdit.Extract1Click(Sender: TObject);
begin
  DoExtract(false);
end;

procedure TRSLodEdit.ExtractDropSource(copy: Boolean);
var
  s: string;
  i, j: int;
begin
  s:= FMyTempPath;
  if not copy then
    s:= s + 'd\';
  RSFileOperation(ExcludeTrailingPathDelimiter(s), '', FO_DELETE);
  RSCreateDir(s);
  with FDragFilesList do
    for i := 0 to Count - 1 do
      if Archive.RawFiles.FindFile(Strings[i], j) then
        Archive.Extract(j, s);
end;

procedure TRSLodEdit.ExtractForDefTool1Click(Sender: TObject);
begin
  DoExtract(true, true);
end;

procedure TRSLodEdit.ExtractTo1Click(Sender: TObject);
begin
  DoExtract(true);
end;

procedure TRSLodEdit.ExtSort;
var
  i: int;
begin
  if length(ItemIndexes) <= 1 then  exit;
  ExtQSort(0, high(ItemIndexes));
  for i := 0 to high(ItemIndexes) do
    ArchiveIndexes[ItemIndexes[i]]:= i;
end;

procedure TRSLodEdit.ExtQSort(L, R: int);

  function FindExt(const s: string): PChar;
  var
    i: int;
  begin
    for i := length(s) downto 1 do
      if s[i] = '.' then
      begin
        Result:= @s[i];
        exit;
      end;
    Result:= '';
  end;

  function CompareExt(const s1, s2: string): int;
  begin
    Result:= RSLodCompareStr(FindExt(s1), FindExt(s2));
    if Result = 0 then
      Result:= RSLodCompareStr(PChar(s1), PChar(s2));
  end;

var
  I, J, P: Integer;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      while CompareExt(ItemCaptions[I], ItemCaptions[P]) < 0 do  Inc(I);
      while CompareExt(ItemCaptions[J], ItemCaptions[P]) > 0 do  Dec(J);
      if I <= J then
      begin
        //ExchangeItems(I, J);
        zSwap(ItemCaptions[I], ItemCaptions[J]);
        zSwap(ItemIndexes[I], ItemIndexes[J]);

        if P = I then
          P := J
        else if P = J then
          P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then  ExtQSort(L, J);
    L := I;
  until I >= R;
end;

procedure TRSLodEdit.DoAdd(Files:TStrings);
var
  WasAdded, WasPlaying: Boolean;

  procedure Added(i:int);
  begin
    WasAdded:= true;
    DefaultSel:= Archive.RawFiles.Name[i];
  end;

var
  i:int; s:string; b:TBitmap;
  err: string;
begin
  WasPlaying:= (FileType = aVideo) and (Timer1.Interval <> 0);
  FreeVideo;
  for i:= 0 to Files.Count-1 do
    try
      s:= Files[i];
      if (Archive is TRSLod) and (TRSLod(Archive).Version = RSLodHeroes) and
         (SameText(ExtractFileExt(s), '.pcx')) then
      begin
        b:= TJvPcx.Create;
        try
          b.LoadFromFile(s);
          Added(TRSLod(Archive).Add(ExtractFileName(s), b));
        finally
          b.Free;
        end;
      end else
        Added(Archive.Add(s));

{
      if SameText(s1, '.def') then
      begin
        df:=TRSDefWrapper.Create(RSLoadFile(s));
        with df do
          try
            s:= ExtractFileName(s);
            Added(Lod.Add(Data, s), s);
            if MakeMasks<>0 then
            begin
              // !! if MakeMasks=-1 then (dialog)
              SetLength(a, SizeOf(TMsk));
              RSMakeMsk(df, PMsk(a)^);
              s:= ChangeFileExt(s, '.msk');
              Added(Lod.Add(a, s), s);
              s:= ChangeFileExt(s, '.msg');
              Added(Lod.Add(a, s), s);
            end;
          finally
            Free;
          end;
        goto CaseEnd;
      end;

      }
    except
      on e:Exception do
      begin
        if Files.Count > 1 then
          err:= err + ExtractFileName(Files[i]) + ' : ' + e.Message + #13#10
        else
          raise;
      end;
    end;

  if err <> '' then
    ErrorBox(err);

  if WasAdded then
  begin
    CancelCompare;
    EndLoad(true);
  end else
    if WasPlaying then
      PlayVideo;
end;

procedure TRSLodEdit.DoDelete(Backup: Boolean);
var
  i,j,k:int; s:string;
begin
  i:=ListView1.SelCount;
  if i=0 then exit;
  if i=1 then
    s:=Format(SDeleteQuestion, [SelCaption])
  else
    s:=SDeleteManyQuestion;

  if not ConfirmBox(s) then
    exit;

  if FileType = aVideo then
    FreeVideo;

  Archive.BackupOnDelete:= Backup and Backup1.Checked;
  try
    with ListView1.Items do
      for i:=Count-1 downto 0 do
        if Item[i].Selected then
        begin
          Item[i].Selected:=false;
          k:= ItemIndexes[i];
          Archive.RawFiles.Delete(k);

          ArrayDelete(ArchiveIndexes, k, 4);
          SetLength(ArchiveIndexes, high(ArchiveIndexes));
          for j:= 0 to high(ArchiveIndexes) do
            if ArchiveIndexes[j] > i then
              dec(ArchiveIndexes[j]);

          ArrayDelete(ItemIndexes, i, 4);
          SetLength(ItemIndexes, high(ItemIndexes));
          for j:= 0 to high(ItemIndexes) do
            if ItemIndexes[j] > k then
              dec(ItemIndexes[j]);

          ArrayDelete(ItemCaptions, i, 4);
          SetLength(ItemCaptions, high(ItemCaptions));

          Count:= Count - 1;
          if i < LastSel then
            dec(LastSel);

          if FilterItemVisible <> nil then
            ArrayDelete(FilterItemVisible, k, SizeOf(FilterItemVisible[0]));
        end;
  finally
    Archive.BackupOnDelete:= Backup1.Checked;
  end;

  if LastSel > high(ItemIndexes) then
    LastSel:= high(ItemIndexes);
  ListView_SetItemState(ListView1.Handle, LastSel,
     LVIS_SELECTED or LVIS_FOCUSED, LVIS_SELECTED or LVIS_FOCUSED);
  ListView1.Invalidate;
end;

procedure TRSLodEdit.Panel1Paint(Sender: TRSCustomControl;
  State: TRSControlState; DefaultPaint: TRSProcedure);
var
  w, h: int;
  r: TRect;
begin
  with Sender, Canvas do
  begin
    Brush.Color:=clBtnFace;
    if RSMemo1.Visible and not ThemeServices.ThemesEnabled then
      Pen.Color:=clBtnShadow
    else
      Pen.Color:=clBtnFace;
    if (PreviewBmp <> nil) and (PreviewBmp.Width <> 0) and (PreviewBmp.Height <> 0) then
    begin
      Rectangle(0, 0, Image1.Left, Height);
      w:= PreviewBmp.Width;
      h:= PreviewBmp.Height;
      DoReStretch(RSSpeedButton1.Down or (FileType = aPal), Image1.Width, Image1.Height, w, h);
      r:= Bounds(Image1.Left, Image1.Top, w, h);
      StretchDraw(r, PreviewBmp);
      Rectangle(r.Right, 0, Width, r.Bottom);
      Rectangle(r.Left, r.Bottom, Width, Height);
    end else
      Rectangle(0, 0, Width, Height);
    {
    with ThemeServices do
      if ThemesEnabled then
      begin
        a.Element:=teListView;
        a.Part:=0;
        a.State:=0;
        DrawEdge(Handle, a, Rect(0,0,Width,Height), EDGE_SUNKEN, BF_SOFT or BF_FLAT or BF_TOPLEFT or BF_BOTTOMRIGHT);
      end else
    }
    //    FrameRect(Rect(0,0,Width,Height));
    //Pen.Color:=c
  end;
end;

procedure TRSLodEdit.PopupListAllowShortCut(Sender: TMenu; var Message: TWMKey;
  var Allow: Boolean);
begin
  Allow:= not ListView1.IsEditing;
end;

procedure TRSLodEdit.PopupListPopup(Sender: TObject);
begin
  if ListView1.SelCount <= 1 then
    ExtractTo1.Caption:=SExtractAs
  else
    ExtractTo1.Caption:=SExtractTo;

  ExtractForDefTool1.Enabled:= CanExtractDef;
  Paste2.Enabled:= Clipboard.HasFormat(CF_HDROP);
end;

procedure TRSLodEdit.Edit1Click(Sender: TObject);
var b:Boolean;
begin
  if ListView1.SelCount <= 1 then
    ExtractTo2.Caption:=SExtractAs
  else
    ExtractTo2.Caption:=SExtractTo;
  b:= ListView1.SelCount<>0;
  Extract2.Enabled:= b;
  ExtractTo2.Enabled:= b;
  Delete3.Enabled:= b;
  AddtoFavorites2.Enabled:= b;
  ExtractForDefTool2.Enabled:= b and CanExtractDef;
  Paste3.Enabled:= Clipboard.HasFormat(CF_HDROP);
  Copy3.Enabled:= b;
  Rename3.Enabled:= b;
end;

procedure TRSLodEdit.TrackBar1AdjustClickRect(Sender: TRSTrackBar;
  var r: TRect);
begin
  dec(r.Top, 5);
end;

procedure TRSLodEdit.ListView1WndProc(Sender: TObject; var Msg: TMessage;
  var Handled: Boolean; const NextWndProc: TWndMethod);
begin
  // OnSelectItem with is broken with OwnerData
  if Msg.Msg = CN_NOTIFY then
    with PNMListView(TWMNotify(Msg).NMHdr)^ do
      if (hdr.code = LVN_ITEMCHANGED) and (uChanged = LVIF_STATE) then
      begin
        if (uNewState and LVIS_FOCUSED) > (uOldState and LVIS_FOCUSED) then
          ListViewSelectItem(iItem, true)
        else if (uOldState and LVIS_SELECTED) <> (uNewState and LVIS_SELECTED) then
          ListViewSelectItem(iItem, false);
      end;
end;

procedure TRSLodEdit.ListViewSelectItem(i: int; Chosen: Boolean);
const
  b = LVIS_FOCUSED or LVIS_SELECTED;
begin
  UpdateToolbarState;
  if i < 0 then  DeselectTimer.Enabled:= true;
  if not Chosen and ((i <> LastSel) or (i < 0)) then  exit;
  LastSel:=i;
  if not Chosen and (ListView_GetItemState(ListView1.Handle, i, b) <> b) then
    i:= -1;

  if SelectingIndex<>nil then
  begin
    SelectingIndex^:=i;
    exit;
  end;

  SelectingIndex:=@i;
  try
    Application.ProcessMessages;
  finally
    SelectingIndex:=nil;
  end;

  // !!! LoadFile не должен вызывать Application.ProcessMessages и т.п.
  LoadFile(i);
end;

procedure TRSLodEdit.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TRSLodEdit.TreeView1EndDrag(Sender, Target: TObject; X,
  Y: Integer);
begin
  DragNode:= nil;
  DragTimer.Enabled:= false;
  InvalidateRect(TreeView1.Handle, nil, false);
end;

procedure TRSLodEdit.PopupTreePopup(Sender: TObject);
var i:int;
begin
  i:=TreeView1.SelectionCount;
  if TreeView1.Items[0].Selected then
    dec(i);
{  Cut1.Enabled:= i<>0;
  Copy1.Enabled:= i<>0;
  Paste1.Enabled:= i<>0;}
  Delete1.Enabled:= i<>0;
  Rename1.Enabled:= i<>0;
  MoveUp1.Enabled:= i<>0;
  MoveDown1.Enabled:= i<>0;
  StoreAsText1.Checked:= FavsAsText;
  //StoreAsText1.Visible:= TreeView1.Items[0].Selected;
end;

procedure TRSLodEdit.PopupTreeAfterPopup(Sender: TObject);
var i:int;
begin
  with Sender as TPopupMenu, Items do
    for i:=0 to Count-1 do
      Items[i].Enabled:=true;
end;

procedure TRSLodEdit.Default1Click(Sender: TObject);
begin
  TMenuItem(Sender).Checked:= true;
  if Sender = FirstKind1 then
    FSFTKind:= 1
  else if Sender = SecondKind1 then
    FSFTKind:= 2
  else if Sender = ThirdKind1 then
    FSFTKind:= 3
  else
    FSFTKind:= 0;

  if PreviewBmp <> nil then
    LoadFile(LastSel);
end;

procedure TRSLodEdit.DefaultPalette1Click(Sender: TObject);
begin
  if Def<>nil then
  begin
    Def.RebuildPal;
    TrackBar1Change(nil);
  end;
end;

function TRSLodEdit.DefFilterProc(Sender: TRSLodEdit; i: int;
  var Str: string): Boolean;
var
  a, c: TStream;
  b: Byte;
begin
  Result:= false;
  if (FilterItemVisible <> nil) and not FilterItemVisible[i] then
    exit;
  if not SameText(ExtractFileExt(Str), '.def') then
  begin
    Result:= (FDefFilter in [$43, $44]) and (SameText(ExtractFileExt(Str), '.msk')
                                              or SameText(ExtractFileExt(Str), '.msg'));
    exit;
  end;

  with Archive.RawFiles do
  begin
    if Size[i] = 0 then  exit;
    b:= 0;
    c:= nil;
    a:= GetAsIsFileStream(i, true);
    try
      if IsPacked[i] then
      begin
        c:= TDecompressionStream.Create(a);
        c.Read(b, 1);
      end else
        a.Read(b, 1);
    finally
      c.Free;
      FreeAsIsFileStream(i, a);
    end;
    Result:= b = FDefFilter;
  end;
end;

initialization
  RSLoadProc(@EnterReaderModeHelper, user32, 'EnterReaderModeHelper');

end.
