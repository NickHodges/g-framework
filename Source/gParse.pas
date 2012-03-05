unit gParse;

interface

uses
    SysUtils
  , Classes
  ;

type
  TgTokenClass = Class of TgToken;
  EgParseClass = Class Of EgParse; 

  TgTokenRegistry = class;

  TgSymbolString = class(TObject)
  strict private
    FSourceString: String;
    FSourceStringIndex: Integer;
    FSourceStringLength: Integer;
    FSourceStringLineNumber: Integer;
    FLastNewLine: Integer;
    FSourceStringName: String;
    FSymbolStringExceptionClass: EgParseClass;
    function GetSourceStringColumnNumber: Integer;
    function GetCurrentChar: Char;
    function GetSourceStringName: String;
  strict protected
    property SymbolStringExceptionClass: EgParseClass read FSymbolStringExceptionClass write FSymbolStringExceptionClass;
  public
    constructor Create; virtual;
    function Copy(AStart, ACount: Integer): string;
    procedure Initialize(const AString: String);
    procedure NewLine;
    function Pos(const AString: String): Integer;
    procedure RaiseException(const Msg: String; const Args: Array of Const);
    property SourceString: String read FSourceString write FSourceString;
    property SourceStringColumnNumber: Integer read GetSourceStringColumnNumber;
    property SourceStringIndex: Integer read FSourceStringIndex write FSourceStringIndex;
    property SourceStringLength: Integer read FSourceStringLength write FSourceStringLength;
    property SourceStringLineNumber: Integer read FSourceStringLineNumber;
    property CurrentChar: Char read GetCurrentChar;
    property SourceStringName: String read GetSourceStringName write FSourceStringName;
  end;

  TgToken = class abstract(TObject)
  strict private
    FOwner: TgSymbolString;
    FTokenStringIndex: Integer;
    function GetSourceString: String;
    function GetSourceStringIndex: Integer;
    function GetSourceStringLength: Integer;
    function GetSourceStringLineNumber: Integer;
    procedure SetSourceStringIndex(const Value: Integer);
  strict protected
    class function TokenRegistry: TgTokenRegistry; virtual; abstract;
    property Owner: TgSymbolString read FOwner;
  public
    constructor Create(AOwner: TgSymbolString); virtual;
    procedure Parse(ASymbolLength: Integer); virtual;
    class procedure Register(const ASymbol: String); virtual;
    class function ValidSymbol(const ASymbolName: String): Boolean; virtual;
    property SourceString: String read GetSourceString;
    property SourceStringIndex: Integer read GetSourceStringIndex write SetSourceStringIndex;
    property SourceStringLength: Integer read GetSourceStringLength;
    property SourceStringLineNumber: Integer read GetSourceStringLineNumber;
  End;

  TgTokenRegistry = class(TStringList)
  strict private
    FUnknownTokenClass: TgTokenClass;
  protected
    function CompareStrings(const S1: string; const S2: string): Integer; override;
  public
    Constructor Create;
    function ClassifyNextSymbol(const AString: String; AStringIndex: Integer; out ASymbol: String): TgTokenClass;
    procedure RegisterToken(const ASymbol: String; ATokenClass: TgTokenClass);
    property UnknownTokenClass: TgTokenClass read FUnknownTokenClass write FUnknownTokenClass;
  End;

  EgParse = class(Exception)
  end;

implementation

uses
    StrUtils
  , Math
  ;

constructor TgSymbolString.Create;
begin
  inherited Create;
  SymbolStringExceptionClass := EgParse;
  FSourceStringLineNumber := 1;
end;

function TgSymbolString.Copy(AStart, ACount: Integer): string;
begin
  Result := System.Copy( SourceString, AStart, ACount );
end;

function TgSymbolString.GetSourceStringColumnNumber: Integer;
begin
  Result := SourceStringIndex - FLastNewLine;
end;

procedure TgSymbolString.Initialize(const AString: String);
begin
  SourceString := AString;
  SourceStringIndex := 1;
  SourceStringLength := Length( AString );
end;

procedure TgSymbolString.NewLine;
begin
  Inc( FSourceStringLineNumber );
  FLastNewLine := SourceStringIndex; 
end;

function TgSymbolString.Pos(const AString: String): Integer;
begin
  Result := PosEx( AString, SourceString, SourceStringIndex );
end;

procedure TgSymbolString.RaiseException(const Msg: String; const Args: Array of Const);
var
  AppendString : String;
begin
  AppendString := Format( 'On line %d at column %d of %s: ', [SourceStringLineNumber, SourceStringColumnNumber, SourceStringName] );
  Raise SymbolStringExceptionClass.CreateFmt( AppendString + Msg, Args );
end;

function TgSymbolString.GetCurrentChar: Char;
begin
  Result := FSourceString[FSourceStringIndex];
end;

function TgSymbolString.GetSourceStringName: String;
begin
  If FSourceStringName > '' Then
    Result := FSourceStringName
  Else
    Result := '{unknown}';
end;

constructor TgToken.Create(AOwner: TgSymbolString);
begin
  Inherited Create;
  FOwner := AOwner;
end;

function TgToken.GetSourceString: String;
begin
  Result := Owner.SourceString;
end;

function TgToken.GetSourceStringIndex: Integer;
begin
  Result := Owner.SourceStringIndex;
end;

function TgToken.GetSourceStringLength: Integer;
begin
  Result := Owner.SourceStringLength;
end;

function TgToken.GetSourceStringLineNumber: Integer;
begin
  Result := Owner.SourceStringLineNumber;
end;

procedure TgToken.Parse(ASymbolLength: Integer);
begin
  FTokenStringIndex := SourceStringIndex;
  SourceStringIndex := SourceStringIndex + ASymbolLength;
end;

{ TgToken }

class procedure TgToken.Register(const ASymbol: String);
begin
  TokenRegistry.RegisterToken(UpperCase(ASymbol), Self);
end;

procedure TgToken.SetSourceStringIndex(const Value: Integer);
begin
  Owner.SourceStringIndex := Value;
end;

class function TgToken.ValidSymbol(const ASymbolName: String): Boolean;
begin
  Result := False;
end;

{ TgTokenRegistry }

constructor TgTokenRegistry.Create;
begin
  Inherited;
  CaseSensitive := False;
  Sorted := True;
end;

function TgTokenRegistry.ClassifyNextSymbol(const AString: String; AStringIndex: Integer; out ASymbol: String): TgTokenClass;
Var
  InputString : String;
  TokenIndex : Integer;
  SymbolLength : Integer;
  SymbolCompare: Boolean;
  IsSystem: Boolean;
const
  SPseudoSystemObject = 'SYSTEM.';
begin
  InputString := UpperCase(Copy( AString, AStringIndex, MaxInt ));
  IsSystem := StartsStr( SPseudoSystemObject, InputString );
  If IsSystem Then
    InputString := Copy( InputString, Length( SPseudoSystemObject ) + 1, MaxInt );
  repeat
    If Not Find(InputString, TokenIndex) Then
      TokenIndex := Max(TokenIndex - 1, 0);
    ASymbol := Strings[TokenIndex];
    SymbolLength := Length( ASymbol );
    SymbolCompare := StartsText( ASymbol, InputString );
    InputString := Copy( InputString, 1, Min( SymbolLength, Length( InputString ) ) - 1 );
    If SymbolCompare Then
      Break;
  until InputString = '';
  If SymbolCompare And Not ( ( Length( InputString ) > SymbolLength ) And Assigned( UnknownTokenClass ) And UnknownTokenClass.ValidSymbol( Copy( InputString, 1, SymbolLength + 1 ) ) ) Then
    Result := TgTokenClass(Objects[TokenIndex])
  Else If Assigned(UnknownTokenClass) Then
    Result := UnknownTokenClass
  Else
    Raise EgParse.CreateFmt('Symbol ''%s'' not found.', [InputString]);
  If IsSystem Then
    ASymbol := 'System.' + ASymbol;
end;

function TgTokenRegistry.CompareStrings(const S1: string; const S2: string): Integer;
begin
  If S1 = S2 Then
    Result := 0
  Else If S1 >  S2 Then
    Result := 1
  Else
    Result := -1;
end;

procedure TgTokenRegistry.RegisterToken(const ASymbol: String; ATokenClass: TgTokenClass);
Var
  Index : Integer;
begin
  Index := IndexOf(ASymbol);
  If Index > -1 Then
    Objects[Index] := TObject(ATokenClass)
  Else
    AddObject(UpperCase(ASymbol), TObject(ATokenClass));
end;




end.
