unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, RSMemo, RSQ, Menus, IniFiles, Math, ComCtrls,
  CommCtrl;

type
  TForm2 = class(TForm)
    ListView1: TListView;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Label1: TLabel;
    procedure ListView1Changing(Sender: TObject; Item: TListItem;
      Change: TItemChange; var AllowChange: Boolean);
    procedure ListView1DrawItem(Sender: TCustomListView; Item: TListItem;
      r: TRect; State: TOwnerDrawState);
    procedure ListView1Exit(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView1Resize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  protected
    MappedKeys: array[0..255] of Byte;
    KeyLines: array[0..255] of int2;
    CurrentKey: Byte;
    AllowItemChange: Boolean;
    procedure CreateParams(var Params: TCreateParams); override;
    function SetKeyText(it: TListItem; i: int): TListItem;
    function SelectItem(it: TListItem): TListItem;
  public
    procedure UpdateKey(i:int);
    procedure CloseCurrentKey;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

const
  DllName = 'Scaler';
  SPressKey = '<press a key>';

procedure TForm2.Button1Click(Sender: TObject);
var
  i: int;
begin
  with TIniFile.Create(AppPath + DllName + '.ini') do
    try
      for i:=1 to 255 do
      begin
        if MappedKeys[i] = 0 then
          DeleteKey('Controls', 'Key'+IntToStr(i))
        else
          WriteInteger('Controls', 'Key'+IntToStr(i), MappedKeys[i]);
      end;
    finally
      Free;
    end;
  Close;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TForm2.Button3Click(Sender: TObject);
var i: int;
begin
  if CurrentKey <> 0 then
  begin
    MappedKeys[CurrentKey]:= 0;
    CloseCurrentKey;
    ListView1.SetFocus;
    exit;
  end;
  for i := 1 to 255 do
  begin
    MappedKeys[i]:= 0;
    KeyLines[i]:= -1;
  end;
  ListView1.Clear;
  SelectItem(ListView1.Items.Add).Caption:= SPressKey;
  ListView1.SetFocus;
end;

procedure TForm2.CloseCurrentKey;
var k: Byte;
begin
  k:= CurrentKey;
  CurrentKey:= 0;
  UpdateKey(k);
  SelectItem(ListView1.Items.Add).Caption:= SPressKey;
  Button3.Caption:= 'Clear All';
end;

procedure TForm2.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WinClassName:='Scaler Controls Form';
end;

procedure TForm2.FormCreate(Sender: TObject);
var
  i: int;
begin
  Constraints.MinWidth:= Constraints.MinWidth + Width - ClientWidth;
  Constraints.MinHeight:= Constraints.MinHeight + Height - ClientHeight;
  with TIniFile.Create(AppPath + DllName + '.ini') do
    try
      for i:=1 to 255 do
      begin
        MappedKeys[i]:= ReadInteger('Controls', 'Key'+IntToStr(i), 0);
        KeyLines[i]:= -1;
      end;
      for i:=1 to 255 do
        UpdateKey(i);
      SelectItem(ListView1.Items.Add).Caption:= SPressKey;
    finally
      Free;
    end;
end;

procedure TForm2.ListView1Changing(Sender: TObject; Item: TListItem;
  Change: TItemChange; var AllowChange: Boolean);
begin
  if Change = ctState then
    AllowChange:= AllowItemChange;
end;

procedure TForm2.ListView1DrawItem(Sender: TCustomListView; Item: TListItem;
  r: TRect; State: TOwnerDrawState);

  procedure DoDraw(s: string; x: int);
  var
    i: int;
    s1: string;
    c: TColor;
  begin
    i:= pos(#1, s);
    if i > 0 then
    begin
      s1:= copy(s, i + 1, length(s) - i);
      s:= copy(s, 1, i - 1);
    end;

    with Sender.Canvas do
    begin
      if not Item.Selected then
        Font.Color:= clWindowText
      else
        Font.Color:= clHighlightText;
      TextRect(r, r.Left + x, r.Top, s);
      if i > 0 then
      begin
        if not Item.Selected then
          Font.Color:= clBtnShadow;
        c:= Brush.Color;
        Brush.Style:= bsClear;
        i:= r.Right;
        dec(r.Right, 15);
        TextRect(r, s1, [tfRight]);
        r.Right:= i;
        Brush.Style:= bsSolid;
        Brush.Color:= c;
      end;
    end;
  end;

var
  w: int;
begin
  with Sender, Canvas do
  begin
    FillRect(r);
    if Item.Selected then
      Brush.Color:= clHighlight;
    w:= r.Right;
    if Item.SubItems.Count > 0 then
      r.Right:= Column[0].Width + r.Left;
    inc(r.Left, 2);
    DoDraw(Item.Caption, 4);
    if Item.SubItems.Count > 0 then
    begin
      r.Left:= r.Right;
      r.Right:= w;
      DoDraw(Item.SubItems.Strings[0], 6);
    end;
  end;
end;

procedure TForm2.ListView1Exit(Sender: TObject);
var
  key: Word;
begin
  if GetKeyState(VK_TAB) < 0 then
  begin
    ListView1.SetFocus;
    key:= VK_TAB;
    ListView1KeyDown(nil, Key, []);
  end;
end;

procedure TForm2.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  if Key = 0 then
    exit;
  with ListView1 do
    ListView_SetItemState(Handle, ListView_GetNextItem(Handle, 0, LVNI_FOCUSED), 0, LVIS_FOCUSED);
  if Key = VK_ESCAPE then
  begin
    if CurrentKey <> 0 then
      CloseCurrentKey;
    exit;
  end;

  if CurrentKey = 0 then
  begin
    with ListView1.Items do
      Delete(Count - 1);
    CurrentKey:= Key;
    Button3.Caption:= 'Clear Key';
    UpdateKey(Key);
  end else
  begin
    MappedKeys[CurrentKey]:= Key;
    CloseCurrentKey;
  end;
  Key:= 0;
end;

procedure TForm2.ListView1Resize(Sender: TObject);
var i, j: int;
begin
  with TListView(Sender) do
  begin
    i:= ClientWidth;
    j:= i div 2;
    Column[1].Width:= i - max(Column[0].Width, j) - 1;
    ShowScrollBar(Handle, SB_HORZ, false);
    Column[0].Width:= j;
    ShowScrollBar(Handle, SB_HORZ, false);
    Column[1].Width:= i - j;
    ShowScrollBar(Handle, SB_HORZ, false);
  end;
end;

function TForm2.SelectItem(it: TListItem): TListItem;
begin
  AllowItemChange:= true;
  it.Selected:= true;
  ListView_EnsureVisible(ListView1.Handle, it.Index, false);
  Result:= it;
  AllowItemChange:= false;
end;

function KeyToText(i: uint):string;
begin
  Result:= Format('%s'#1'(%d)', [ShortCutToText(i), i]);
end;

function TForm2.SetKeyText(it: TListItem; i: int): TListItem;
var
  s: string;
begin
  it.Caption:= KeyToText(i);
  if CurrentKey <> i then
    s:= KeyToText(MappedKeys[i])
  else
    s:= SPressKey;

  with it.SubItems do
    if Count = 0 then
      Add(s)
    else
      Strings[0]:= s;

  Result:= SelectItem(it);
end;

procedure TForm2.UpdateKey(i: int);
var
  b: Boolean;
  j: int;
begin
  b:= (MappedKeys[i] <> 0) or (CurrentKey = i);
  j:= KeyLines[i];
  with ListView1.Items do
    if j >= 0 then
      if not b then
      begin
        Delete(j);
        KeyLines[i]:= -1;
        for j := j to Count - 1 do
          dec(KeyLines[int(Item[j].Data)]);
      end else
        SetKeyText(Item[j], i)
    else
      if b then
        with SetKeyText(Add, i) do
        begin
          KeyLines[i]:= Index;
          Data:= ptr(i);
        end;
end;

end.
