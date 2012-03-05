unit gExpressionEvaluator;

{ Author: Steve Kramer, goog@goog.com }

interface

Uses
    classes
  , contnrs
  , Variants
  , gParse
  , SysUtils
  ;

Type
  TgExpressionEvaluatorClass = Class of TgExpressionEvaluator;
  TgExpressionEvaluator = class(TgSymbolString)
  strict private
    FInFixTokenList : TObjectList;
    FPostFixTokenList : TList;
    Function EvaluateTokenList : Variant;
    procedure ParseNextToken;
    Procedure PostFixTokenList;
    procedure TokenizeExpression;
  strict protected
    function GetValue(const AVariableName: String): Variant; virtual;
    function UnknownTokenClass: TgTokenClass;
  public
    constructor Create; override;
    Destructor Destroy;Override;
    function Evaluate(const AExpression: String): Variant;
    function OverrideTokenClass(ATokenClass: TgTokenClass; const ASymbol: String): TgTokenClass; virtual;
    property Value[const AVariableName: String]: Variant read GetValue;
  End;

  TgVariantStack = class(TObject)
  strict private
    fStack : Array[0..99] of Variant;
    fStackIndex : Integer;
  public
    Constructor Create;
    Procedure Clear;
    Function Pop : Variant;
    Procedure Push(AValue : Variant);
  End;

  TgExpressionTokenClass = Class of TgExpressionToken;
  TgExpressionToken = class(TgToken)
  strict private
    function GetExpressionEvaluator: TgExpressionEvaluator;
  strict protected
    class function TokenRegistry: TgTokenRegistry; override;
    property ExpressionEvaluator: TgExpressionEvaluator read GetExpressionEvaluator;
  public
    constructor Create(AExpressionEvaluator : TgExpressionEvaluator); reintroduce; virtual;
    Class Function CreateToken(AExpressionEvaluator : TgExpressionEvaluator; AInFixTokenList : TObjectList) : TgExpressionToken;Virtual;
    procedure Evaluate(AStack : TgVariantStack); virtual;
    Procedure PostFix(ATokenList : TList; AStack : TStack);Virtual;
  End;

  TgWhitespace = class(TgExpressionToken)
  Public
    class var
    Chars: String;
    procedure Parse(ASymbolLength: Integer); override;
    class procedure Register(const ASymbol: String); override;
  End;

  TVariableClass = Class Of TgVariable;
  TgVariable = class(TgExpressionToken)
  strict private
    Name: String;
    class function IsValidFirstChar(const ASymbol: Char): Boolean;
    class function IsValidOtherChar(const ASymbol: Char): Boolean;
  public
    procedure Evaluate(AStack : TgVariantStack); override;
    procedure Parse(ASymbolLength: Integer); override;
    Class Procedure Register;ReIntroduce;
    class function ValidSymbol(const ASymbolName: String): Boolean; override;
  End;

  EgExpressionEvaluator = class(Exception)
  end;

  function Eval(const AExpression: String; AExpressionEvaluatorClass: TgExpressionEvaluatorClass = Nil): Variant;

implementation

Uses
    Math
  , Character
  ;

  function Eval(const AExpression: String; AExpressionEvaluatorClass: TgExpressionEvaluatorClass = Nil): Variant;
  var
    ExpressionEvaluator: TgExpressionEvaluator;
  begin
    if Not Assigned(AExpressionEvaluatorClass) then
      AExpressionEvaluatorClass := TgExpressionEvaluator;
    ExpressionEvaluator := AExpressionEvaluatorClass.Create;
    try
      Result := ExpressionEvaluator.Evaluate(AExpression);
    finally
      ExpressionEvaluator.Free;
    end;
  end;

Var
  ExpressionTokenRegistry : TgTokenRegistry;
  VariableClass : TVariableClass;

{ TgExpressionEvaluator }

constructor TgExpressionEvaluator.Create;
Begin
  Inherited;
  FInFixTokenList := TObjectList.Create;
  FPostFixTokenList := TList.Create;
End;

Destructor TgExpressionEvaluator.Destroy;
Begin
  FPostFixTokenList.Free;
  FInfixTokenList.Free;
  Inherited Destroy;
End;

function TgExpressionEvaluator.Evaluate(const AExpression: String): Variant;
begin
  Initialize( AExpression );
  TokenizeExpression;
  PostFixTokenList;
  Result := EvaluateTokenList;
end;

function TgExpressionEvaluator.EvaluateTokenList: Variant;
Var
  Counter : Integer;
  Stack : TgVariantStack;
begin
  Stack := TgVariantStack.Create;
  Try
    For Counter := 0 to FPostFixTokenList.Count - 1 Do
      TgExpressionToken(FPostFixTokenList[Counter]).Evaluate(Stack);
    Result := Stack.Pop;
  Finally
    Stack.Free;
  End;
end;

function TgExpressionEvaluator.GetValue(const AVariableName: String): Variant;
begin
  Result := Unassigned;
end;

function TgExpressionEvaluator.OverrideTokenClass(ATokenClass: TgTokenClass; const ASymbol: String): TgTokenClass;
begin
  Result := ATokenClass;
end;

procedure TgExpressionEvaluator.ParseNextToken;
Var
  TokenClass : TgTokenClass;
  Token : TgExpressionToken;
  Symbol: String;
Begin
  TokenClass := ExpressionTokenRegistry.ClassifyNextSymbol(SourceString, SourceStringIndex, Symbol);
  TokenClass := OverrideTokenClass( TokenClass, Symbol );
  Token := TgExpressionTokenClass(TokenClass).CreateToken(Self, FInFixTokenList);
  Token.Parse( Length( Symbol ) );
  If Token.InheritsFrom(TgWhitespace) Then
    Token.Free
  Else
    FInfixTokenList.Add(Token);
End;

procedure TgExpressionEvaluator.PostFixTokenList;
Var
  Stack : TStack;
  Counter : Integer;
begin
  FPostFixTokenList.Clear;
  Stack := TStack.Create;
  Try
    For Counter := 0 to FInFixTokenList.Count - 1 Do
      TgExpressionToken(FInFixTokenList[Counter]).PostFix(FPostFixTokenList, Stack);
    While Stack.Count > 0 Do
      FPostFixTokenList.Add(Stack.Pop);
  Finally
    Stack.Free;
  End;
end;

procedure TgExpressionEvaluator.TokenizeExpression;
Begin
  FInfixTokenList.Clear;
  While SourceStringIndex <= SourceStringLength Do
    ParseNextToken;
End;

function TgExpressionEvaluator.UnknownTokenClass: TgTokenClass;
begin
  Result := ExpressionTokenRegistry.UnknownTokenClass;
end;

constructor TgExpressionToken.Create(AExpressionEvaluator : TgExpressionEvaluator);
begin
  Inherited Create(AExpressionEvaluator);
end;

class function TgExpressionToken.CreateToken(AExpressionEvaluator : TgExpressionEvaluator; AInFixTokenList : TObjectList): TgExpressionToken;
begin
  Result := Create(AExpressionEvaluator);
end;

procedure TgExpressionToken.Evaluate(AStack : TgVariantStack);
begin

end;

function TgExpressionToken.GetExpressionEvaluator: TgExpressionEvaluator;
begin
  Result := TgExpressionEvaluator(Owner);
end;

procedure TgExpressionToken.PostFix(ATokenList : TList; AStack: TStack);
begin
  ATokenList.Add(Self);
end;

class function TgExpressionToken.TokenRegistry: TgTokenRegistry;
begin
  Result := ExpressionTokenRegistry;
end;

{ TgVariable }

procedure TgVariable.Evaluate(AStack : TgVariantStack);
Begin
  AStack.Push(ExpressionEvaluator.Value[Name]);
End;

class function TgVariable.IsValidFirstChar(const ASymbol: Char): Boolean;
begin
  Result := TCharacter.IsLetter(ASymbol);
end;

class function TgVariable.IsValidOtherChar(const ASymbol: Char): Boolean;
begin
  Result := (TCharacter.IsLetter(ASymbol) or TCharacter.IsNumber(ASymbol) or (Pos(ASymbol, '.[]') > 0));
end;

procedure TgVariable.Parse(ASymbolLength: Integer);
Var
  TokenLength : Integer;
begin
  If IsValidFirstChar(SourceString[SourceStringIndex]) Then
  Begin
    TokenLength := 1;
    While ( ( SourceStringIndex + TokenLength ) <= ( SourceStringLength + 1 ) ) And IsValidOtherChar( SourceString[SourceStringIndex + TokenLength - 1] ) Do
      Inc(TokenLength);
    Dec(TokenLength);
    Name := Copy( SourceString, SourceStringIndex, TokenLength);
    SourceStringIndex := SourceStringIndex + TokenLength;
  End
  Else
    Owner.RaiseException( 'Invalid variable first character ''%s''.', [SourceString[SourceStringIndex]] );
end;

class procedure TgVariable.Register;
begin
  VariableClass := Self;
end;

class function TgVariable.ValidSymbol(const ASymbolName: String): Boolean;
const
  StartPosition = 2;
Var
  Counter : Integer;
  VariableNameLength : Integer;
begin
  Result := False;
  VariableNameLength := Length(ASymbolName);
  If (ASymbolName > '') And IsValidFirstChar(ASymbolName[1]) Then
  Begin
    For Counter := StartPosition to VariableNameLength Do
      If Not IsValidOtherChar(ASymbolName[Counter]) Then
        Exit;
    Result := True;
  End;
end;

{ TgVariantStack }

Constructor TgVariantStack.Create;
Begin
  Inherited;
  fStackIndex := -1;
End;

Procedure TgVariantStack.Clear;
Begin
  fStackIndex := -1;
End;

Function TgVariantStack.Pop : Variant;
Begin
  Result := fStack[fStackIndex];
  Dec(fStackIndex);
End;

Procedure TgVariantStack.Push(AValue : Variant);
Begin
  Inc(fStackIndex);
  fStack[fStackIndex] := AValue;
End;

{ TgWhitespace }

procedure TgWhitespace.Parse(ASymbolLength: Integer);
begin
  While (SourceStringIndex <= SourceStringLength) And ( Pos( SourceString[SourceStringIndex], Chars ) > 0 ) Do
    SourceStringIndex := SourceStringIndex + 1;
end;

{ TgToken }

class procedure TgWhitespace.Register(const ASymbol: String);
begin
  inherited Register( ASymbol );
  Chars := Chars + ASymbol;
end;


Initialization
  ExpressionTokenRegistry := TgTokenRegistry.Create;
  TgVariable.Register;
  TgWhitespace.Register(' ');
  TgWhitespace.Register(#0009);
  TgWhitespace.Register(#0013);
  TgWhitespace.Register(#0010);
  ExpressionTokenRegistry.UnknownTokenClass := TgVariable;

Finalization
  ExpressionTokenRegistry.Free;

end.
