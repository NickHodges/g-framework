unit gExpressionConstants;

interface

Uses
    gExpressionEvaluator
  ;

Type
  TConstant = class(TgExpressionToken)
  End;

  TMaxInt = Class(TConstant)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TTrue = Class(TConstant)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TFalse = Class(TConstant)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  TUnassigned = class(TConstant)
  Public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

implementation

Uses
    SysUtils
  , Variants
  ;

{ TMaxInt }

procedure TMaxInt.Evaluate(AStack : TgVariantStack);
begin
  AStack.Push(MaxInt);
end;

{ TTrue }

procedure TTrue.Evaluate(AStack : TgVariantStack);
begin
  AStack.Push(True);
end;

{ TFalse }

procedure TFalse.Evaluate(AStack : TgVariantStack);
begin
  AStack.Push(False);
end;

{ TTrue }

procedure TUnassigned.Evaluate(AStack : TgVariantStack);
begin
  AStack.Push(Unassigned);
end;


Initialization
  TMaxInt.Register('MaxInt');
  TTrue.Register('True');
  TFalse.Register('False');
  TUnassigned.Register('Unassigned');

end.

