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
  CanExit: Boolean;
  Counter: Integer;
  IsSystem: Boolean;
  SymbolLength : Integer;
  TempSymbol: string;
  TempTokenIndex: Integer;
  TokenIndex : Integer;
const
  SPseudoSystemObject = 'SYSTEM.';
begin
  IsSystem := StartsText( SPseudoSystemObject, Copy(AString, AStringIndex, Length(SPseudoSystemObject)));
  If IsSystem Then
    AStringIndex := AStringIndex + Length( SPseudoSystemObject );
  Counter := 1;
  CanExit := False;
  Repeat

    Repeat

      while (AStringIndex+Counter < Length(AString)) and (AString[AStringIndex+Counter-1] in ['a'..'z','_','A'..'Z']) and  (AString[AStringIndex+Counter] in ['a'..'z','_','A'..'Z']) do
        Inc(Counter);
      //Find the closest token
      Find(UpperCase(Copy(AString, AStringIndex, Counter)), TokenIndex);

      //If Find says we're at the end, then get out
      If TokenIndex = Count Then
      Begin
        CanExit := True;
        SymbolLength := 0;
        Counter := 0;
        Break;
      End
      Else
      Begin
        //Grab its symbol
        ASymbol := Strings[TokenIndex];
        SymbolLength := Length(ASymbol);
        //Compare the next symbol in the string with the symbol in the list
        Counter := 1;
        While (Counter <= SymbolLength) And (UpperCase(AString[AStringIndex + Counter - 1]) = ASymbol[Counter]) Do
          Inc(Counter);

        //There is no match
        If (Counter <= SymbolLength) And (UpperCase(AString[AStringIndex + Counter - 1]) < ASymbol[Counter]) Then
        Begin
          CanExit := True;
          Break;
        End;
      End;

    Until CanExit Or (Counter > SymbolLength);

    //If we found a match check one more character
    If (Counter > SymbolLength) Then
    Begin
      If ((AStringIndex + Counter - 1) <= Length(AString)) Then
      Begin
        Find(Copy(AString, AStringIndex, Counter), TempTokenIndex);
        If TempTokenIndex < Count Then
          TempSymbol := Strings[TempTokenIndex];
        CanExit := (TempTokenIndex = Count) Or Not StartsText(TempSymbol, Copy(AString, AStringIndex, Length(TempSymbol)));
      End
      Else
        CanExit := True;
    End;

  Until CanExit;

  //If we matched the symbol, check one character past the symbol to see if we could be referring to a valid variable name
  If Counter > SymbolLength Then
  Begin
   If (AStringIndex + Counter > Length(AString)) Or Not Assigned(UnknownTokenClass) Or Not UnknownTokenClass.ValidSymbol(Copy(AString, AStringIndex, Counter)) Then
    Result := TgTokenClass(Objects[TokenIndex])
   Else
    Result := UnknownTokenClass;
  End
  Else
  Begin
    If Assigned(UnknownTokenClass) Then
      Result := UnknownTokenClass
    Else
      Raise EgParse.CreateFmt('Symbol ''%s'' not found.', [Copy(AString, AStringIndex, 50)]);
  End;

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
