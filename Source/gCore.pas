unit gCore;

interface

type
  TgBase = class(TObject)
  strict private
    FOwner: TgBase;
  public
    constructor Create(AOwner: TgBase = Nil);
  published
    {$Region 'Documentation'}
    /// <summary>TgBase.Owner represents the object passed in the constructor.
    /// </summary>
    /// type:TgBase
    {$EndRegion}
    property Owner: TgBase read FOwner;
  end;

implementation

constructor TgBase.Create(AOwner: TgBase = Nil);
begin
  inherited Create;
  FOwner := AOwner;
end;

end.
