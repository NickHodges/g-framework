unit gCore;

interface

type
  TgBase = class(TObject)
  strict private
    FOwner: TgBase;
  public
    constructor Create(AOwner: TgBase = Nil);
  published
    /// <summary>TgBase.Owner represents the object passed in the constructor. You may
    /// use the Owner object to "walk up" the model.
    /// </summary> type:TgBase
    property Owner: TgBase read FOwner;
  end;

implementation

constructor TgBase.Create(AOwner: TgBase = Nil);
begin
  inherited Create;
  FOwner := AOwner;
end;

end.
