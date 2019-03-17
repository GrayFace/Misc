unit RSStringer;

interface

uses
  SysUtils, Classes;

type
  TRSStringer = class(TComponent)
  private
    FIt:TStrings;
    procedure SetItems(v: TStrings);
  protected
    { Protected declarations }
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items:TStrings read FIt write SetItems;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('RSPak', [TRSStringer]);
end;

constructor TRSStringer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIt := TStringList.Create;
end;

destructor TRSStringer.Destroy;
begin
  FIt.Free;
  inherited Destroy;
end;

procedure TRSStringer.SetItems(v: TStrings);
begin
  FIt.Assign(v);
end;

end.
