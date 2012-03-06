unit gExpressionFunctions;

{ Author: Steve Kramer, goog@goog.com }

interface

Uses
    Classes
  , SysUtils
  , Contnrs
  , gExpressionEvaluator
  , gExpressionOperators
  ;

Type
  TFunction = Class(TOperator)
  Public
    ParameterCount : Integer;
    Function Precedence : Integer;Override;
    Procedure PostFix(ATokenList : TList; AStack : TStack);Override;
  End;

  TSameText = class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TCopy = Class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TIf = Class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TLength = Class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TLowerCase = Class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TPos = Class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TRandom = Class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TUpperCase = Class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TVarIsEmpty = Class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TFormatFloat = Class(TFunction)
  Public
    procedure Evaluate(AStack : TgVariantStack); override;
  End;

  TFormatDateTime = class(TFunction)
  public
    procedure Evaluate(AStack : TgVariantStack); override;
  end;

  TRight = class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TDateFunction = class(TFunction)
  Public
    procedure Evaluate(AStack : TgVariantStack); override;
  end;

  TNow = class(TFunction)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TABS = class(TFunction)
  public
    procedure Evaluate(AStack: TgVariantStack); override;
  end;

implementation

Uses
    Variants
  , StrUtils
  ;

{ TFunction }

procedure TFunction.PostFix(ATokenList: TList; AStack: TStack);
begin
  AStack.Push(Self);
end;

function TFunction.Precedence: Integer;
begin
  Result := 9;
end;

{ TSameText }

procedure TSameText.Evaluate(AStack : TgVariantStack);
Var
  String1 : String;
  String2 : String;
begin
  String1 := AStack.Pop;
  String2 := AStack.Pop;
  AStack.Push(SameText(String1, String2));
end;

{ TCopy }

Procedure TCopy.Evaluate(AStack : TgVariantStack);
Var
  S : String;
  Index : Integer;
  Count : Integer;
Begin
  Count := AStack.Pop;
  Index := AStack.Pop;
  S := AStack.Pop;
  AStack.Push(Copy(S, Index, Count));
End;

{ TIf }

Procedure TIf.Evaluate(AStack : TgVariantStack);
Var
  ElseValue : Variant;
  ThenValue : Variant;
  IfValue : Boolean;
Begin
  ElseValue := AStack.Pop;
  ThenValue := AStack.Pop;
  IfValue := AStack.Pop;
  If IfValue Then
    AStack.Push(ThenValue)
  Else
    AStack.Push(ElseValue);
End;

{ TLength }

procedure TLength.Evaluate(AStack : TgVariantStack);
begin
  AStack.Push(Length(AStack.Pop));
end;

{ TLowerCase }

procedure TLowerCase.Evaluate(AStack: TgVariantStack);
begin
  AStack.Push(LowerCase(AStack.Pop));
end;

{ TPos }

procedure TPos.Evaluate(AStack : TgVariantStack);
Var
  SearchString : String;
  TargetString : String;
begin
  TargetString := AStack.Pop;
  SearchString := AStack.Pop;
  AStack.Push(Pos(SearchString, TargetString));
end;

{ TRandom }

procedure TRandom.Evaluate(AStack : TgVariantStack);
Var
  Value : Integer;
begin
  Value := AStack.Pop;
  Value := Random(Value);
  AStack.Push(Value);
end;

{ TUpperCase }

Procedure TUpperCase.Evaluate(AStack : TgVariantStack);
Begin
  AStack.Push(UpperCase(AStack.Pop));
End;

{ TVarIsEmpty }

procedure TVarIsEmpty.Evaluate(AStack : TgVariantStack);
Var
  Value : Variant;
begin
  Value := AStack.Pop;
  AStack.Push(VarIsEmpty(Value));
end;

{ TFormatFloat }

procedure TFormatFloat.Evaluate(AStack : TgVariantStack);
Var
  FormatString : String;
  Value : Extended;
Begin
  Value := AStack.Pop;
  FormatString := AStack.Pop;
  AStack.Push(FormatFloat(FormatString, Value));
End;

{ TFormatFloat }

procedure TFormatDateTime.Evaluate(AStack : TgVariantStack);
Var
  FormatString : String;
  Value : Extended;
Begin
  Value := AStack.Pop;
  FormatString := AStack.Pop;
  AStack.Push(FormatDateTime(FormatString, Value));
End;

{ TRight }

procedure TRight.Evaluate(AStack : TgVariantStack);
Var
  SearchString : String;
  ExtractLength : Integer;
begin
  ExtractLength := AStack.Pop;
  SearchString := AStack.Pop;
  If ExtractLength < 0 Then
     ExtractLength := Length(SearchString) + ExtractLength;
  AStack.Push( RightStr( SearchString, ExtractLength ) );
end;

procedure TDateFunction.Evaluate(AStack : TgVariantStack);
begin
  AStack.Push(Date);
end;

{ TSameText }

procedure TNow.Evaluate(AStack : TgVariantStack);
begin
  AStack.Push(Now);
end;

procedure TABS.Evaluate(AStack: TgVariantStack);
var
  Value: Double;
begin
  Value := AStack.Pop;
  AStack.Push(Abs(Value));
end;

Initialization
  TSameText.Register('SameText');
  TAbs.Register('Abs');
  TCopy.Register('Copy');
  TIf.Register('If');
  TLength.Register('Length');
  TLowerCase.Register('LowerCase');
  TPos.Register('Pos');
  TRandom.Register('Random');
  TUpperCase.Register('UpperCase');
  TVarIsEmpty.Register('VarIsEmpty');
  TFormatFloat.Register( 'FormatFloat' );
  TFormatDateTime.Register( 'FormatDateTime' );
  TRight.Register( 'Right' );
  TRight.Register( 'RightStr' );
  TDateFunction.Register('Date');
  TNow.Register('Now');
end.
