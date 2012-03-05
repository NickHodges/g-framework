unit gExpressionLiterals;

{ Author: Steve Kramer, goog@goog.com }

interface

Uses
    Classes
  , SysUtils
  , StrUtils
  , gExpressionEvaluator
  ;

Type

  TLiteral = class(TgExpressionToken)
  Protected
    Value: Variant;
  public
    Procedure Evaluate(AStack : TgVariantStack);Override;
  End;

  THex = Class(TLiteral)
  public
    procedure Parse(ASymbolLength: Integer); override;
  End;

  TNumber = Class(TLiteral)
  public
    procedure Parse(ASymbolLength: Integer); override;
  End;

  TString = Class(TLiteral)
  public
    procedure Parse(ASymbolLength: Integer); override;
  End;

  TDateTimeLiteral = class(TLiteral)
  public
    procedure Parse(ASymbolLength: Integer); override;
  end;

implementation

uses gCore, gParse;

{ TLiteral }

procedure TLiteral.Evaluate(AStack : TgVariantStack);
begin
  AStack.Push(Value);
end;

procedure THex.Parse(ASymbolLength: Integer);
Const
  HexChars = '0123456789ABCDEFabcdef';
Var
  StartPos : Integer;
Begin
  inherited Parse(ASymbolLength);
  StartPos := SourceStringIndex - 1;
  While Pos(SourceString[SourceStringIndex], HexChars) > 0 Do
    SourceStringIndex := SourceStringIndex + 1;
  Value := StrToInt(Copy(SourceString, StartPos, SourceStringIndex - StartPos));
end;

procedure TNumber.Parse(ASymbolLength: Integer);
Const
  NumberChars = '0123456789.';
Var
  StartPos : Integer;
  TempString : String;
Begin
  StartPos := SourceStringIndex;
  If SourceString[SourceStringIndex] = '-' Then
    SourceStringIndex := SourceStringIndex + 1;
  Repeat
    SourceStringIndex := SourceStringIndex + 1;
  Until ( SourceStringIndex > SourceStringLength ) OR (Pos(SourceString[SourceStringIndex], NumberChars) = 0);
  TempString := Copy(SourceString, StartPos, SourceStringIndex - StartPos);
  If Pos('.', TempString) > 0 Then
    Value := StrToFloat(TempString)
  Else
    Value := StrToInt(TempString);
end;

{ TString }

procedure TString.Parse(ASymbolLength: Integer);
Var
  DataString: PChar;
  BeforeExtractLength: Integer;
Const
  QuoteChar = '''';
Begin
  DataString := PChar(Copy( SourceString, SourceStringIndex, MaxInt ));
  BeforeExtractLength := Length( DataString );
  Value := AnsiExtractQuotedStr( DataString, QuoteChar );
  SourceStringIndex := SourceStringIndex + ( BeforeExtractLength - Length( DataString ) );
end;

procedure TDateTimeLiteral.Parse(ASymbolLength: Integer);
Const
  DateChars = '0123456789/ :';
Var
  StartPos : Integer;
  TempString : String;
  Symbol : String;
  DateTime : TDateTime;
  ValueLength: Integer;
Begin
  Symbol := Copy(SourceString, SourceStringIndex, ASymbolLength);
  StartPos := SourceStringIndex + ASymbolLength;
  Repeat
    SourceStringIndex := SourceStringIndex + 1;
  Until ( SourceStringIndex > SourceStringLength ) OR (Pos(SourceString[SourceStringIndex], DateChars) = 0);
  ValueLength := SourceStringIndex - StartPos;
  TempString := Copy(SourceString, StartPos, ValueLength);
  If Not SameText(Copy(SourceString, StartPos + ValueLength, ASymbolLength), Symbol) Or Not TryStrToDateTime(TempString, DateTime) then
  Begin
    SourceStringIndex := StartPos - ASymbolLength;
    Owner.RaiseException('%s isn''t a valid date / time literal.', [Copy(SourceString, StartPos - ASymbolLength, ValueLength - StartPos + 2 * ASymbolLength)]);
  End;
  Value := DateTime;
  SourceStringIndex := StartPos + ValueLength + ASymbolLength;
end;

Initialization
  THex.Register('$');
  TNumber.Register('0');
  TNumber.Register('1');
  TNumber.Register('2');
  TNumber.Register('3');
  TNumber.Register('4');
  TNumber.Register('5');
  TNumber.Register('6');
  TNumber.Register('7');
  TNumber.Register('8');
  TNumber.Register('9');
  TString.Register('''');
  TDateTimeLiteral.Register('#');

end.
