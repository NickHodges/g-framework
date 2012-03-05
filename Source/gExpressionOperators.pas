unit gExpressionOperators;

{ Author: Steve Kramer, goog@goog.com }

interface

Uses
    Classes
  , Contnrs
  , gExpressionEvaluator
  , Variants
  ;

Type
  TOperator = class(TgExpressionToken)
  Public
    Function Precedence : Integer;Virtual;
    Procedure PostFix(ATokenList : TList; AStack : TStack);Override;
  End;

  TBinaryOperator = Class(TOperator)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Virtual;Abstract;
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TBinaryOperatorP1 = Class(TBinaryOperator)
  Public
    Function Precedence : Integer;Override;
  End;

  TBinaryOperatorP2 = Class(TBinaryOperator)
  Public
    Function Precedence : Integer;Override;
  End;

  TBinaryOperatorP3 = Class(TBinaryOperator)
  Public
    Function Precedence : Integer;Override;
  End;

  TAdd = class(TBinaryOperatorP2)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TLogicalAnd = class(TBinaryOperator)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  public
  End;

  TComma = Class(TOperator)
  Public
    Function Precedence : Integer;Override;
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TDash = Class(TgExpressionToken)
  Public
    class function CreateToken(AExpressionEvaluator : TgExpressionEvaluator; AInFixTokenList : TObjectList): TgExpressionToken; override;
  End;

  TDIV = Class(TBinaryOperatorP3)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TDivide = class(TBinaryOperatorP3)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TEQ = Class(TBinaryOperatorP1)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TGE = Class(TBinaryOperatorP1)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TGT = Class(TBinaryOperatorP1)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TIn = Class(TBinaryOperatorP1)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TLE = Class(TBinaryOperatorP1)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TLParen = class(TOperator)
  private
    FParameterCount: Integer;
  Public
    Function Precedence : Integer;Override;
    Procedure PostFix(ATokenList : TList; AStack : TStack);Override;
    Procedure Evaluate(AStack : TgVariantStack);Override;
    Property ParameterCount : Integer read FParameterCount;
  End;

  TLT = Class(TBinaryOperatorP1)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TMod = Class(TBinaryOperatorP3)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TMultiply = class(TBinaryOperatorP3)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TNE = Class(TBinaryOperatorP1)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TNot = Class(Toperator)
  Public
    Function Precedence : Integer;Override;
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TOr = Class(TBinaryOperator)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TPower = Class(TBinaryOperator)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  Public
    Function Precedence : Integer;Override;
  End;

  TRParen = class(TOperator)
  Public
    Procedure PostFix(ATokenList : TList; AStack : TStack);Override;
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TSubtract = class(TBinaryOperatorP2)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TLike = class(TBinaryOperatorP3)
  Protected
    Function Operate(Value1, Value2 : Variant) : Variant;Override;
  End;

  TBetween = class(TOperator)
  public
    procedure Evaluate(AStack : TgVariantStack); override;
    function Precedence: Integer; override;
  end;

  TAnd = class(TgExpressionToken)
  public
    class function CreateToken(AExpressionEvaluator : TgExpressionEvaluator; AInFixTokenList : TObjectList): TgExpressionToken; override;
  end;

  TBetweenAnd = class(TOperator)
  public
    function Precedence: Integer; override;
  end;

implementation

Uses
    gExpressionLiterals
  , gExpressionFunctions
  , Math
  , StrUtils
  , SysUtils
  ;

{ TOperator }

procedure TOperator.PostFix(ATokenList: TList; AStack: TStack);
Var
  Operator : TOperator;
begin
  If AStack.Count = 0 Then
    AStack.Push(Self)
  Else
  Begin
    Operator := TOperator(AStack.Peek);
    If Precedence > Operator.Precedence Then
      AStack.Push(Self)
    Else
    Begin
      Repeat
        Operator := TOperator(AStack.Pop);
        ATokenList.Add(Operator);
      Until (AStack.Count = 0) or (Precedence > TOperator(AStack.Peek).Precedence);
      AStack.Push(Self);
    End;
  End;
end;

function TOperator.Precedence: Integer;
begin
  Result := 0;
end;

{ TBinaryOperator }

Procedure TBinaryOperator.Evaluate(AStack : TgVariantStack);
Var
  Value1, Value2 : Variant;
Begin
  Value2 := AStack.Pop;
  Value1 := AStack.Pop;
  AStack.Push(Operate(Value1, Value2));
End;

{ TBinaryOperatorP1 }

function TBinaryOperatorP1.Precedence: Integer;
begin
  Result := 1;
end;

{ TBinaryOperatorP2 }

function TBinaryOperatorP2.Precedence: Integer;
begin
  Result := 2;
end;

{ TBinaryOperatorP3 }

function TBinaryOperatorP3.Precedence: Integer;
begin
  Result := 3;
end;

{ TAdd }

Function TAdd.Operate(Value1, Value2 : Variant) : Variant;
var
  V1: String;
  V2: String;
Begin
  If VarIsStr( Value1 ) Or VarIsStr( Value2 ) Then
  Begin
    V1 := Value1;
    V2 := Value2;
    Result := V1 + V2;
  End
  Else
    Result := Value1 + Value2;
End;

{ TLogicalAnd }

Function TLogicalAnd.Operate(Value1, Value2 : Variant) : Variant;
Var
  BooleanValue1 : Boolean;
  BooleanValue2 : Boolean;
Begin
  If VarIsEmpty(Value1) or VarIsEmpty(Value2) Then
    Result := False
  Else
  Begin
    BooleanValue1 := Value1;
    BooleanValue2 := Value2;
    Result := BooleanValue1 And BooleanValue2;
  End;
End;

{ TComma }

procedure TComma.Evaluate(AStack : TgVariantStack);
begin
end;

function TComma.Precedence: Integer;
begin
  Result := -1;
end;

{ TDash }

class function TDash.CreateToken(AExpressionEvaluator : TgExpressionEvaluator; AInFixTokenList : TObjectList): TgExpressionToken;
Var
  LastToken : TgExpressionToken;
begin
  If AInFixTokenList.Count > 0 Then
    LastToken := TgExpressionToken(AInFixTokenList.Last)
  Else
    LastToken := Nil;
  If Assigned(LastToken) And (Not LastToken.InheritsFrom(TOperator) or LastToken.InheritsFrom(TRParen)) Then
    Result := TSubtract.Create(AExpressionEvaluator)
  Else
    Result := TNumber.Create(AExpressionEvaluator);
end;

{ TDIV }

function TDIV.Operate(Value1, Value2: Variant): Variant;
Var
  Int1 : Integer;
  Int2 : Integer;
begin
  Int1 := Value1;
  Int2 := Value2;
  Result := Int1 Div Int2;
end;

{ TDivide }

Function TDivide.Operate(Value1, Value2 : Variant) : Variant;
Begin
  Result := Value1 / Value2;
End;

{ TEQ }

Function TEQ.Operate(Value1, Value2 : Variant) : Variant;
Begin
  If VarIsEmpty(Value1) or VarIsEmpty(Value2) Then
    Result := False
  Else
    Result := Value1 = Value2;
End;

{ TGE }

Function TGE.Operate(Value1, Value2 : Variant) : Variant;
Begin
  If VarIsEmpty(Value1) or VarIsEmpty(Value2) Then
    Result := False
  Else
    Result := Value1 >= Value2;
End;

{ TGT }

Function TGT.Operate(Value1, Value2 : Variant) : Variant;
Begin
  If VarIsEmpty(Value1) or VarIsEmpty(Value2) Then
    Result := False
  Else
    Result := Value1 > Value2;
End;

{ TLE }

Function TLE.Operate(Value1, Value2 : Variant) : Variant;
Begin
  If VarIsEmpty(Value1) or VarIsEmpty(Value2) Then
    Result := False
  Else
    Result := Value1 <= Value2;
End;

{ TLParen }

procedure TLParen.PostFix(ATokenList: TList; AStack: TStack);
begin
  AStack.Push(Self);
end;

Procedure TLParen.Evaluate(AStack : TgVariantStack);
Begin
End;

function TLParen.Precedence: Integer;
begin
  Result := -2;
end;

{ TLT }

Function TLT.Operate(Value1, Value2 : Variant) : Variant;
Begin
  If VarIsEmpty(Value1) or VarIsEmpty(Value2) Then
    Result := False
  Else
    Result := Value1 < Value2;
End;

{ TMod }

function TMod.Operate(Value1, Value2: Variant): Variant;
begin
  Result := Value1 Mod Value2;
end;

{ TMultiply }

Function TMultiply.Operate(Value1, Value2 : Variant) : Variant;
Begin
  Result := Value1 * Value2;
End;

{ TNE }

function TNE.Operate(Value1, Value2: Variant): Variant;
begin
  If VarIsEmpty(Value1) or VarIsEmpty(Value2) Then
    Result := True
  Else
    Result := Value1 <> Value2;
end;

{ TNot }

Procedure TNot.Evaluate(AStack : TgVariantStack);
Var
  Value : Variant;
  BooleanValue : Boolean;
Begin
  Value := AStack.Pop;
  If VarIsEmpty(Value) Then
    AStack.Push(True)
  Else
  Begin
    BooleanValue := Value;
    AStack.Push(Not BooleanValue);
  End;
End;

function TNot.Precedence: Integer;
begin
  Result := 5;
end;

{ TOr }

Function Tor.Operate(Value1, Value2 : Variant) : Variant;
Var
  BooleanValue1 : Boolean;
  BooleanValue2 : Boolean;
Begin
  If VarIsEmpty(Value1) or VarIsEmpty(Value2) Then
    Result := False
  Else
  Begin
    BooleanValue1 := Value1;
    BooleanValue2 := Value2;
    Result := BooleanValue1 Or BooleanValue2;
  End;
End;

{ TPower }

function TPower.Operate(Value1, Value2: Variant): Variant;
begin
  Result := Power(Value1, Value2);
end;

function TPower.Precedence: Integer;
begin
  Result := 4;
end;

{ TRParen }

procedure TRParen.PostFix(ATokenList: TList; AStack: TStack);
Var
  Token : TgExpressionToken;
  FunctionToken : TFunction;
  Counter : Integer;
begin
  Token := TgExpressionToken(AStack.Pop);
  While Not Token.InheritsFrom(TLParen) Do
  Begin
    ATokenList.Add(Token);
    Token := TgExpressionToken(AStack.Pop);
  End;
  If (AStack.Count > 0) And TgExpressionToken(AStack.Peek).InheritsFrom(TFunction) Then
  Begin
    FunctionToken := TFunction(AStack.Pop);
    Counter := ATokenList.Add(FunctionToken) - 1;
    Repeat
      Token := TgExpressionToken(ATokenList[Counter]);
      If Token.InheritsFrom(TComma) Then
        FunctionToken.ParameterCount := FunctionToken.ParameterCount + 1;
      Dec(Counter);
    Until (Counter = -1) Or Token.InheritsFrom(TFunction);
    FunctionToken.ParameterCount := FunctionToken.ParameterCount + 1;
  End;
end;

Procedure TRParen.Evaluate(AStack : TgVariantStack);
Begin
End;

{ TSubtract }

Function TSubtract.Operate(Value1, Value2 : Variant) : Variant;
Begin
  Result := Value1 - Value2;
End;

{ TIn }

function TIn.Operate(Value1, Value2: Variant): Variant;
begin
  Result := Pos(Value1, Value2) > 0;
end;

{ TLike }

function TLike.Operate(Value1, Value2 : Variant): Variant;
var
  SearchString: String;
Begin
  SearchString := Value2;
  If SearchString[Length( SearchString )] = '%' Then
  Begin
    SearchString := Copy( SearchString, 1, Length( SearchString ) - 1 );
    If SearchString[1] = '%' Then
    Begin
      SearchString := Copy( SearchString, 2, MaxInt );
      Result := ContainsText( Value1, SearchString )
    End
    Else
      Result := StartsText( SearchString, Value1 )
  End
  Else if SearchString[1] = '%' then
  Begin
    SearchString := Copy(SearchString, 2, MaxInt);
    Result := EndsText(SearchString, Value1);
  End
  Else
    Result := SameText(Value1, Value2);
End;

{ TBinaryOperator }

procedure TBetween.Evaluate(AStack : TgVariantStack);
var
  MaxValue: Variant;
  MinValue: Variant;
  TestValue: Variant;
  Result : Boolean;
begin
  MaxValue := AStack.Pop;
  MinValue := AStack.Pop;
  TestValue := AStack.Pop;
  Result := TestValue >= MinValue;
  If Result Then
    Result := TestValue <= MaxValue;
  AStack.Push(Result);
end;

{ TBinaryOperatorP1 }

function TBetween.Precedence: Integer;
begin
  Result := 2;
end;

class function TAnd.CreateToken(AExpressionEvaluator : TgExpressionEvaluator; AInFixTokenList : TObjectList): TgExpressionToken;
Var
  TestToken : TgExpressionToken;
begin
  If AInFixTokenList.Count > 1 Then
    TestToken := TgExpressionToken(AInFixTokenList[AInFixTokenList.Count - 2])
  Else
    TestToken := Nil;
  If Assigned(TestToken) And TestToken.InheritsFrom(TBetween) Then
    Result := TBetweenAnd.Create(AExpressionEvaluator)
  Else
    Result := TLogicalAnd.Create(AExpressionEvaluator);
end;

{ TBinaryOperatorP1 }

function TBetweenAnd.Precedence: Integer;
begin
  Result := 3;
end;


Initialization
  TAdd.Register('+');
  TAnd.Register('And');
  TComma.Register(',');
  TDash.Register('-');
  TDiv.Register('Div');
  TDivide.Register('/');
  TEQ.Register('=');
  TGE.Register('>=');
  TGT.Register('>');
  TIn.Register('In');
  TLE.Register('<=');
  TLike.Register('Like');
  TLParen.Register('(');
  TLT.Register('<');
  TMod.Register('Mod');
  TMultiply.Register('*');
  TNE.Register('<>');
  TNot.Register('Not');
  TOr.Register('Or');
  TPower.Register('^');
  TRParen.Register(')');
  TBetween.Register('Between');

end.
