unit gWebUI;

interface
uses
  TypInfo,
  System.RTTI,
  Classes,
  System.StrUtils,
  SysUtils,
  Generics.Collections,
  Generics.Defaults,
  Xml.XMLIntf,
  gCore;
type
  TgElementgForm = class(TgElement)
  public
    procedure ProcessNode(Source: IXMLNode; TargetChildNodes: IXMLNodeList); override;
  end;
  TgElementForm = class(TgElement)
  public
    procedure ProcessChildNodes(SourceChildNodes: IXMLNodeList;
      TargetChildNodes: IXMLNodeList); override;
  end;

  TgElementInput = class(TgElement)
  public
    type
      TType = (it,ittext,itcheckbox,itradio,itsubmit,ithidden,itunknown,itimage,itfile);
  private
    FName: String;
    FID: String;
    FType: String;
    FValue: String;
    FTypeEnum: TType;
    FEvaluate: String;
    procedure SetType(const Value: String);
    procedure SetTypeEnum(const Value: TType);
    property TypeEnum: TType read FTypeEnum write SetTypeEnum;
  public
    procedure ProcessNode(Source: IXMLNode; TargetChildNodes: IXMLNodeList); override;
  published
    property Evaluate: String read FEvaluate write FEvaluate;
    property Value: String read FValue write FValue;
    property Type_: String read FType write SetType;
    property Name: String read FName write FName;
    property ID: String read FID write FID;
  end;
  TgElementOption = class(TgElement)
  public
    procedure ProcessNode(Source: IXMLNode; TargetChildNodes: IXMLNodeList); override;
  end;

  TgElementTextArea = class(TgElementInput)
  public
    procedure ProcessNode(Source: IXMLNode; TargetChildNodes: IXMLNodeList); override;
  end;

  TgWebUIBase = class(TgBase)
  private
    FRttiNamedObject: TRttiNamedObject;
    FCondition: String;
    FCaption: String;
    FHelp: String;
    function GetName: String;
    function GetCaption: String;
  public
    type
      TItems = TDictionary<TRttiNamedObject, TgWebUIBase>;
      TEnum = type Integer;
    const _BooleanHTML = '<input type="checkbox" id="%1:s" name="%1:s" value="true" %3:s/>';
    const _DisplayHTML = '<span id="%1:s">{%2:s}</span>';
    class var _: TItems;
    class constructor Create;
    class destructor Destroy;
    class procedure Register(Value: TgWebUIBase);
    class procedure Unregister(Value: TgWebUIBase);
    class function GetUI(ARttiNamedObject: TRttiNamedObject; out WebUI: TgWebUIBase): Boolean;
    class function ToString(const Name: String; Base: TgBaseClass): String;
    class procedure Build(var Builder: TStringBuilder; const Name: String; AgBaseClass: TgBaseClass); overload;
    class procedure Build(var Builder: TStringBuilder; ARttiMember: TRttiMember); overload;
    class function ReadableText(const Value: String): String;
  public
    constructor Create(ARttiNamedObject: TRttiNamedObject); virtual;
    class procedure CreateUITemplate(var Builder: TStringBuilder; gBaseClass: TgBaseClass; ARTTIProperty: TRTTIProperty = nil; GenerateSupportFiles: Boolean = False); overload;
    class procedure CreateUITemplate(var Builder: TStringBuilder; gModelClass: TgModelClass; GenerateSupportFiles: Boolean = False); overload;
    class function CreateUITemplate(ModelClass: TgModelClass; const PropertyName: String = ''; GenerateSupportFiles: Boolean = False): string; overload;
    procedure BuildLink(var Builder: TStringBuilder; RttiMemeber: TRttiMember); virtual;
    procedure BuildLabel(var Builder: TStringBuilder); virtual;
    procedure BuildValue(var Builder: TStringBuilder); virtual;
    procedure Build(var Builder: TStringBuilder); overload; virtual;
    property RttiNamedObject: TRttiNamedObject read FRttiNamedObject;
    property Name: String read GetName;
    property Caption: String read GetCaption write FCaption;
    property Help: String read FHelp write FHelp;
  end;

  TgWebUIHTML = class(TgWebUIBase)
  // 0: Field Label
  // 1: Id
  // 2: Value
  // 3: Additional Attributes
  private
    FHTML: string;
    FAttributes: String;
    FExtra: String;
    Fmaxlength: Integer;
    Fsize: Integer;
    function GetExtra: String;
    procedure Setmaxlength(const Value: Integer);
    function GetHTML: string;
//    const _TextHTML = '<input type="text" id="%1:s" name="%1:s" value="{%2:s}"%3:s />';
    const _TextHTML = '<input type="text" id="inp%1:s" name="%1:s"%3:s />';
    const _InputHTML = '<input id="inp%1:s" name="%1:s"%3:s />';
    const _TextareaHTML = '<textarea id="txt%1:s" name="%1:s"%3:s></textarea>';
  public
    constructor Create(ARttiNamedObject: TRttiNamedObject); overload;override;
    constructor Create(ARttiNamedObject: TRttiNamedObject; const AHTML: String; Size: Integer = -1; MaxLen: Integer = -1); overload;
    constructor Create(ARttiNamedObject: TRttiNamedObject; AHTMLControlAttribute: HTMLControlAttribute; AMaxTextLength: MaxTextLength = nil); overload;
    procedure BuildValue(var Builder: TStringBuilder); overload; override;
    property HTML: string read GetHTML write FHTML;
    property Extra: String read GetExtra write FExtra;
  published
    property size: Integer read Fsize write Fsize default -1;
    property maxlength: Integer read Fmaxlength write Setmaxlength default -1;
  end;

  TgWebUIEnum = class(TgWebUIBase)
  public
    type
      E = class(Exception);
  private
    FKind:TTypeKind;
    FRttiEnum: TRttiEnumerationType;
    FValues: TStringList;
    FValueLabels: TStringList;
//    const _RadioHTML = '<input type="radio" name="%0:s" id="%0:s" value="%1:s" title="%2:s"%3:s>%2:s</input>';
    const _RadioHTML = '<input type="radio" name="%0:s" id="%0:s_%1:s" value="%1:s" title="%2:s"%3:s/><label id="lbl%0:s_%1:s" for="%0:s_%1:s">%2:s</label>';
///      <input type="radio" name="Enum1" id="Enum1_Bag" value="eBag" title="Bag" checked="False""/><label for="Enum1_Bag">Bag</label>
//    const _SelectHTML = '<option%3:s value="%1:s" title="%2:s">%2:s</option>';
    const _SelectHTML = '<option%3:s value="%1:s" title="%2:s">%2:s</option>';
//    const _CheckHTML = '<tr><td><input type="checkbox" name="%0:s" id="%0:s" value="%1:s" title="%2:s"%3:s>%2:s</input></td></tr>';
//    const _CheckHTML = '<span title="%2:s"><input type="checkbox" name="%0:s" id="%0:s_%1:s" value="%1:s" %3:s/><label id="lbl%0:s_%1:s" for="%0:s_%1:s">%2:s</label></span>';
    const _CheckHTML = '<input type="checkbox" name="%0:s" id="%0:s_%1:s" value="%1:s" %3:s/><label id="lbl%0:s_%1:s" for="%0:s_%1:s">%2:s</label>';
  public
    constructor Create(ARttiNamedObject: TRttiNamedObject); override;
    destructor Destroy; override;
    procedure BuildValue(var Builder: TStringBuilder); override;
    property Kind: TTypeKind read FKind;
    property RttiEnum: TRttiEnumerationType read FRttiEnum;
  end;

  TgWebUIClass = class(TgWebUIBase)
    procedure Build(var Builder: TStringBuilder); override;
  end;
  TgWebUIIdentityObject = class(TgWebUIBase)
  protected
    FItemClass: TgBaseClass;
    FFields: TArray<TgWebUIBase>;
    FMethods: TArray<TgWebUIBase>;
  public
    constructor Create(ARttiNamedObject: TRttiNamedObject); override;
    procedure Build(var Builder: TStringBuilder); override;
    procedure BuildLink(var Builder: TStringBuilder; ARttiMember: TRttiMember); override;
  end;

  TgWebUIList = class(TgWebUIBase)
  protected
    FItemClass: TgBaseClass;
    FColumns: TArray<TgWebUIBase>;
  public
    procedure AddColumn(WebUI: TgWebUIBase);
    constructor Create(ARttiNamedObject: TRttiNamedObject); override;
    procedure BuildLink(var Builder: TStringBuilder; ARttiMember: TRttiMember); override;
    procedure Build(var Builder: TStringBuilder); override;
    property ItemClass: TgBaseClass read FItemClass;
  end;

  TgWebUIMethod = class(TgWebUIBase)
  private
    FRttiMethod: TRttiMethod;
    FName: String;
    FValue: String;
    FExtra: String;
    FCan: TRTTIProperty;
    function GetExtra: String;
  public
//    const _ButtonHTML = '<input type="submit" name="%0:s" id="%0:s" value="%1:s" title="%2:s"%3:s>%2:s</input>';
    const _ButtonHTML = '<input%3:s type="submit" id="inp%1:s" value="%1:s" />';

  public
    constructor Create(ARttiNamedObject: TRttiNamedObject); override;
    procedure Build(var Builder: TStringBuilder); override;
  public
    property Extra: String read GetExtra write FExtra;
    property RttiMethod: TRttiMethod read FRttiMethod;
  end;





implementation
uses
  Math;

{ TgWebUIBase }

class procedure TgWebUIBase.Build(var Builder: TStringBuilder; const Name: String; AgBaseClass: TgBaseClass);
var
  WebUI: TgWebUIBase;
  ARTTIMember: TRTTIMember;
begin
  if not AgBaseClass.DoGetMembers(Name,ARTTIMember) then
    ARTTIMember:= nil;

  if not GetUI(ARTTIMember,WebUI) then
    WebUI := nil;
  if Assigned(WebUI) then
    WebUI.Build(Builder);
end;

class constructor TgWebUIBase.Create;
begin
  TgElementForm.Register('form',TgElementForm);
  TgElement.Register('gform',TgElementgForm);
  TgElementInput.Register('input',TgElementInput);
  TgElementTextArea.Register('textarea',TgElementTextArea);
  TgElementOption.Register('option',TgElementOption);
  _ := TItems.Create;
  Register(TgWebUIHTML.Create(nil));
end;

procedure TgWebUIBase.Build(var Builder: TStringBuilder);
var
  ACaption: String;
begin
//  Builder.Append('<td>');
  Builder.AppendFormat('<div name="grp%s">',[Name]);
  ACaption := Caption;
  if ACaption = '' then
    ACaption := ReadableText(Name);
  Builder.AppendFormat('<label id="lbl%0:s" for="%0:s">%1:s</label>',[Name,ACaption]);
  //     <label id="BoolField" for="BoolField">Bool Field</label>
//  BuildLabel(Builder,Name);
//  Builder.Append('</td>');
//  Builder.Append('<td>');
  BuildValue(Builder);
  Builder.Append('</div>');
//  Builder.Append('</td>');
end;

class procedure TgWebUIBase.Build(var Builder: TStringBuilder;
  ARttiMember: TRttiMember);
var
  WebUI: TgWebUIBase;
begin
  if TgWebUIBase.GetUI(ARttiMember,WebUI) then
    WebUI.Build(Builder);
end;

procedure TgWebUIBase.BuildLabel(var Builder: TStringBuilder);
begin
  if Caption = '' then
    Builder.Append(ReadableText(Name))
  else
    Builder.Append(Caption);
end;

procedure TgWebUIBase.BuildLink(var Builder: TStringBuilder;
  RttiMemeber: TRttiMember);
begin
end;

procedure TgWebUIBase.BuildValue(var Builder: TStringBuilder);
begin

end;

constructor TgWebUIBase.Create(ARttiNamedObject: TRttiNamedObject);
begin
  inherited Create;
  if not Assigned(ARttiNamedObject) then exit;

  FRttiNamedObject := ARttiNamedObject;
end;

class procedure TgWebUIBase.CreateUITemplate(var Builder: TStringBuilder;
  gBaseClass: TgBaseClass; ARTTIProperty: TRTTIProperty;
  GenerateSupportFiles: Boolean);
var
  WebUI: TgWebUIBase;
begin
   if GetUI(ARTTIProperty,WebUI) then
     WebUI.Build(Builder);
end;

class procedure TgWebUIBase.CreateUITemplate(var Builder: TStringBuilder;
  gModelClass: TgModelClass; GenerateSupportFiles: Boolean);
var
  Index: Integer;
  WebUI: TgWebUIBase;
  RTTIProperty: TRttiProperty;
begin
  Builder.Append('<ul id="mnuModel">');
//  Builder.Append('<ul id="mnu');
//  Builder.Append(gModelClass.FriendlyName);
//  Builder.Append('">');

  for RTTIProperty in gModelClass.RTTIValueProperties do // ToDo: Is this rthe righ properties
    if RTTIProperty.Visibility = mvPublished then
      if GetUI(RTTIProperty,WebUI) then
        WebUI.BuildLink(Builder,RTTIProperty);
  Builder.Append('</ul>');
end;

class function TgWebUIBase.CreateUITemplate(ModelClass: TgModelClass; const PropertyName: String = ''; GenerateSupportFiles: Boolean = False): string;
var
  Builder: TStringBuilder;
  RTTIProperty: TRttiProperty;
begin
  Builder := TStringBuilder.Create;
  try
    if PropertyName = '' then
      CreateUITemplate(Builder,ModelClass,GenerateSupportFiles)
    else
      CreateUITemplate(Builder,ModelClass,G.PropertyByName(ModelClass,PropertyName),GenerateSupportFiles);;
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;

end;

class destructor TgWebUIBase.Destroy;
begin
  FreeAndNil(_);
end;


function TgWebUIBase.GetCaption: String;
begin
  if FCaption = '' then
    FCaption := ReadableText(FRttiNamedObject.Name);
  Result := FCaption;
end;

function TgWebUIBase.GetName: String;
begin
  Result := FRttiNamedObject.Name;
end;

class function TgWebUIBase.GetUI(ARttiNamedObject: TRttiNamedObject; out WebUI:
    TgWebUIBase): Boolean;
var
  RttiProperty: TRttiProperty;
  RttiType: TRttiType;
  RttiStringType: TRttiStringType;
  AHTMLControlAttribute: HTMLControlAttribute;
  AMaxTextLength: MaxTextLength;
  ADisplayOnly: DisplayOnly;
  ANotVisible: NotVisible;
  ACaption: gCore.Caption;
  AHelp: gCore.Help;
begin
  Result := False;
  WebUI := nil;
  if _.TryGetValue(ARttiNamedObject,WebUI) then exit(Assigned(WebUI));
  // Default
  if not Assigned(ARttiNamedObject) then
    Result := _.TryGetValue(nil,WebUI)
  else if ARttiNamedObject is TRttiProperty then begin
    RttiProperty := ARttiNamedObject as TRttiProperty;
    RttiType := RttiProperty.PropertyType;
    if _.TryGetValue(RttiType,WebUI) then exit(true);
    if (RttiType.TypeKind in [tkClassRef]) then
      exit(False);
    AHTMLControlAttribute := GetAttribute<HTMLControlAttribute>(ARttiNamedObject);
    AMaxTextLength := GetAttribute<MaxTextLength>(ARttiNamedObject);
    ADisplayOnly := GetAttribute<DisplayOnly>(ARttiNamedObject);
    ANotVisible := GetAttribute<NotVisible>(ARttiNamedObject);
    ACaption := GetAttribute<gCore.Caption>(ARttiNamedObject);
    AHelp := GetAttribute<gCore.Help>(ARttiNamedObject);
    if Assigned(ANotVisible) then begin
      _.Add(ARttiNamedObject,WebUI);
      exit(False);
    end
    else if Assigned(ADisplayOnly) or not RttiProperty.IsWritable then begin
      case RttiType.TypeKind of
        tkClass
        : if RttiType.AsInstance.MetaclassType.InheritsFrom(TgList) then
            WebUI := TgWebUIList.Create(ARttiNamedObject)
          else if RttiType.AsInstance.MetaclassType.InheritsFrom(TgIdentityObject) then
            WebUI := TgWebUIIdentityObject.Create(ARttiNamedObject)
          else
            WebUI := TgWebUIClass.Create(ARttiNamedObject);
        else
          WebUI := TgWebUIHTML.Create(ARttiNamedObject,_DisplayHTML);
      end;
    end;

    if not Assigned(WebUI) then
     case RttiType.TypeKind of
      tkClass
      : WebUI := TgWebUIClass.Create(ARttiNamedObject);
      tkEnumeration,tkSet
      : begin
          if RttiType = TRttiContext.Create.GetType(TypeInfo(boolean)) then// 'Boolean') = 0  then
            WebUI := TgWebUIHTML.Create(ARttiNamedObject,_BooleanHTML)
          else
            WebUI := TgWebUIEnum.Create(ARttiNamedObject);
        end;
      tkInteger,tkInt64
      : begin
          WebUI := TgWebUIHTML.Create(ARttiNamedObject,AHTMLControlAttribute,AMaxTextLength);
          (WebUI as TgWebUIHTML).maxlength := Max(Length(IntToStr((RttiType as TRttiOrdinalType).MinValue)),Length(IntToStr((RttiType as TRttiOrdinalType).MaxValue)));
        end;
      tkChar,tkWChar
      : begin
          WebUI := TgWebUIHTML.Create(ARttiNamedObject,AHTMLControlAttribute,AMaxTextLength);
          (WebUI as TgWebUIHTML).maxlength := 1;
        end;
      tkFloat
      : begin
          WebUI := TgWebUIHTML.Create(ARttiNamedObject,AHTMLControlAttribute,AMaxTextLength);
          case (RttiType as TRttiFloatType).FloatType of
            ftSingle
            : (WebUI as TgWebUIHTML).maxlength := 12+6;
            ftDouble
            : (WebUI as TgWebUIHTML).maxlength := 16+6;
            ftExtended
            : (WebUI as TgWebUIHTML).maxlength := 20+6;
            ftComp
            : (WebUI as TgWebUIHTML).maxlength := 20+6;
            ftCurr
            : (WebUI as TgWebUIHTML).maxlength := 20+6;
          end;
        end;
      tkString
      : begin
          RttiStringType := RttiType as TRttiStringType;
          WebUI := TgWebUIHTML.Create(ARttiNamedObject,AHTMLControlAttribute,AMaxTextLength);
          case RttiStringType.StringKind of
            skShortString
            : (WebUI as TgWebUIHTML).maxlength := RttiStringType.TypeSize-1;
          end;
        end
      else begin
        WebUI := TgWebUIHTML.Create(ARttiNamedObject,AHTMLControlAttribute,AMaxTextLength);
      end;
    end;
    if Assigned(WebUI) then begin
      if Assigned(aCaption) then
        WebUI.Caption := aCaption.Value;
      if Assigned(aHelp) then
        WebUI.Help := aHelp.Value;
      _.Add(ARttiNamedObject,WebUI);
    end;
  end
  else if ARttiNamedObject is TRttiMethod then begin
    ANotVisible := GetAttribute<NotVisible>(ARttiNamedObject);
    ACaption := GetAttribute<gCore.Caption>(ARttiNamedObject);
    AHelp := GetAttribute<gCore.Help>(ARttiNamedObject);
    if Assigned(ANotVisible) then begin
      _.Add(ARttiNamedObject,WebUI);
      exit(False);
    end;
    WebUI := TgWebUIMethod.Create(ARttiNamedObject);
    if Assigned(aCaption) then
      WebUI.Caption := aCaption.Value;
    if Assigned(aHelp) then
      WebUI.Help := aHelp.Value;
    _.Add(ARttiNamedObject,WebUI);
  end;
  Result := Assigned(WebUI);
end;

class function TgWebUIBase.ReadableText(const Value: String): String;
var
  Index: Integer;
  Len: Integer;
begin
  Result := Value;
  // Remove lower case prefix
  while (Length(Result) > 0) and (Result[1] in ['a'..'z']) do
    Delete(Result,1,1);
  Len := Length(Result);
  for Index := Len-1 downto 1 do
    // replace _ with space
    if Result[Index] = '_' then
      Result[Index] := ' '
    // put space before capital letters that come after a lowercase letter
    else if (Result[Index] in ['a'..'z']) and (Result[Index+1] in ['A'..'Z']) then
      Insert(' ',Result,Index+1)
    else if (Result[Index] in ['a'..'z']) and (Result[Index+1] in ['0'..'9']) then
      Insert(' ',Result,Index+1)
    else if (Index < Len-2) and (Result[Index] in ['A'..'Z']) and (Result[Index+1] in ['A'..'Z']) and (Result[Index+2] in ['a'..'z']) then
      Insert(' ',Result,Index+1)



end;

class procedure TgWebUIBase.Register(Value: TgWebUIBase);
begin
  _.Add(Value.RttiNamedObject ,Value);
end;

class function TgWebUIBase.ToString(const Name: String; Base: TgBaseClass): String;
var
  Builder: TStringBuilder;
begin
  if not Assigned(Base) then Exit('');
  Builder := TStringBuilder.Create;
  try
    Build(Builder,Name,Base);
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;

end;

class procedure TgWebUIBase.Unregister(Value: TgWebUIBase);
begin
  _.Remove(Value.RttiNamedObject);
end;

{ TgWebUIHTML }

procedure TgWebUIHTML.BuildValue(var Builder: TStringBuilder);
var
//  Value: String;
  AExtra: String;
  AHTMLAttribute: HTMLAttribute;
begin
//  Register(TgWebUIHTML.Create(nil,'<td>%0:s</td><td><input type="text" id="%1:s" AName="%1:s" value="{%2:s}"%3:s/></td>'));
  // 0: Field Label
  // 1: Id
  // 2: Value
  // 3: Additional
//  Value := ABase[AName];
  AExtra := Extra;
  if Help <> '' then
    AExtra := AExtra + ' title="'+Help+'"';
  AExtra := AExtra + FAttributes;
  Builder.AppendFormat(HTML,[
     Caption{0}
    ,Name{1}
    ,Name{2}
    ,AExtra{3}
    ]);
end;

constructor TgWebUIHTML.Create(ARttiNamedObject: TRttiNamedObject;
  const AHTML: String; Size, MaxLen: Integer);
begin
  inherited Create(ARttiNamedObject);
  Fsize := Size;
  Fmaxlength := MaxLen;
  FHTML := AHTML;

end;

constructor TgWebUIHTML.Create(ARttiNamedObject: TRttiNamedObject;
  AHTMLControlAttribute: HTMLControlAttribute; AMaxTextLength: MaxTextLength);
begin
  Create(ARttiNamedObject);
  if Assigned(AMaxTextLength) then begin
    size := AMaxTextLength.Size;
    maxlength := AMaxTextLength.MaxLength;
  end;
  if Assigned(AHTMLControlAttribute) then
    HTML := AHTMLControlAttribute.HTML
end;

constructor TgWebUIHTML.Create(ARttiNamedObject: TRttiNamedObject);
var
  Attributes: THTMLAttributes;
  Attribute: HTMLAttribute;
begin
  inherited;
  if not GetAttributes<HTMLAttribute>(ARttiNamedObject,Attributes) then
    FAttributes := ''
  else for Attribute in Attributes do
    FAttributes := FAttributes + ' '+Attribute.AsText;

  size := -1;
  maxlength := -1;
end;

function TgWebUIHTML.GetExtra: String;
var
  Builder: TStringBuilder;
  Index: Integer;
  PathValue: TPathValue;
  RttiProperty: TRttiProperty;
begin
  if FExtra = '' then begin
    Builder := TStringBuilder.Create;
    try
      for Index := 0 to PathCount-1 do begin
        PathValue := PathValues[Index];
        if not PathValue.Empty and (not DoGetProperties(PathValue.Path,RttiProperty) or not PathValue.IsDefault(RttiProperty as TRttiInstanceProperty)) then begin
          Builder.Append(' ');
          Builder.Append(PathValue.Path);
          Builder.Append('="');
          Builder.Append(String(PathValue.Value));
          Builder.Append('"');
        end;
      end;
      if FCondition <> '' then
        Builder.AppendFormat(' condition="%s"',[FCondition]);
      FExtra := Builder.ToString
    finally
      Builder.Free;
    end;
  end;
  Result := FExtra;
end;

function TgWebUIHTML.GetHTML: string;
begin
  if FHTML = '' then begin
    if Pos('type=',FAttributes) > 0 then
      HTML := _InputHTML
    else if maxlength > 0 then
      HTML := _TextHTML
    else
      HTML := _TextAreaHTML;
  end;
  Result := FHTML;
end;

procedure TgWebUIHTML.Setmaxlength(const Value: Integer);
begin
  if Fmaxlength = Value then exit;
  if (Value > 0) and ((Size = -1) or (Value < Size)) then
     Size := Value;
  Fmaxlength := Value;
end;

{ TgElementgForm }

procedure TgElementgForm.ProcessNode(Source: IXMLNode;
  TargetChildNodes: IXMLNodeList);
var
  Index: Integer;
  Builder: TStringBuilder;
  RTTIMethod: TRttiMethod;
  RTTIInstanceType: TRttiInstanceType;
  AgBase: TgBase;
  AgBaseClass: TgBaseClass;
begin
  AgBase := gBase;
  if not Assigned(AgBase) then exit;
  AgBaseClass := TgBaseClass(AgBase.ClassType);
  Builder := TStringBuilder.Create;
  try
//    Builder.Append('<form><table>');
    Builder.Append('<form>');
    for Index := 0 to AgBase.PathCount-1 do begin
//      Builder.Append('<tr>');
      TgWebUIBase.Build(Builder,AgBase.Paths[Index],AgBaseClass);
//      Builder.Append('</tr>');
    end;
//    Builder.Append('<tr><td>');
    RTTIInstanceType := TRttiContext.Create.GetType(AgBase.ClassInfo) as TRttiInstanceType;
    for RTTIMethod in RTTIInstanceType.GetDeclaredMethods do
      TgWebUIBase.Build(Builder,RTTIMethod);
//    TgWebUIBase.Build(Builder,gBase.
//    Builder.Append('</td></tr>');
//    Builder.Append('</table></form>');
    Builder.Append('</form>');
{$IFDEF DEBUG}
    with TStringList.Create do try Text := Builder.ToString; SaveToFile('xxx.html'); finally free end;
{$ENDIF}
    gDocument.ProcessText(Builder.ToString,TargetChildNodes,AgBase);

  finally
     FreeAndNil(Builder);
  end;
end;

{ TgWebUIEnum }

procedure TgWebUIEnum.BuildValue(var Builder: TStringBuilder);
var
  Index: Integer;
  Checked: String;
begin
  case FKind of
    tkEnumeration
    : begin
        if FValues.Count <= 4 then begin
          for Index := RttiEnum.MinValue to RttiEnum.MaxValue do begin
//            Checked := Format(' checked="{%s = ''%s''}"',[AName,FValues[Index]]);
            Builder.AppendFormat(_RadioHTML,[
               Name
              ,FValues[Index]
              ,FValueLabels[Index]
              ,Checked
              ])
          end
        end
        else begin
          Builder.AppendFormat('<select id="%0:s" Name="%0:s">',[Name]);
          for Index := RttiEnum.MinValue to RttiEnum.MaxValue do begin
//            Checked := Format(' selected="{%s = ''%s''}"',[AName,FValues[Index]]);
            Builder.AppendFormat(_SelectHTML,[
               Name
              ,FValues[Index]
              ,FValueLabels[Index]
              ,''//FExtra
              ]);
          end;
          Builder.Append('</select>');
        end;
      end;
   tkSet
   : begin
//       Builder.Append('<table>');
        for Index := RttiEnum.MinValue to RttiEnum.MaxValue do begin
//          Checked := Format(' checked="{If(InSet(''%s'',%s),''checked'','''')}"',[FValues[Index],AName]);
          Builder.AppendFormat(_CheckHTML,[
             Name
            ,FValues[Index]
            ,FValueLabels[Index]
            ,Checked
            ]);
        end;
//       Builder.Append('</table>');
     end;
  end


end;

constructor TgWebUIEnum.Create(ARttiNamedObject: TRttiNamedObject);
var
  Index: NativeInt;
  ATypeData: PTypeData;
  ARTTIType: TRttiType;
  Name: String;
begin
  if ARttiNamedObject is TRTTIProperty then
    ARTTIType := (ARttiNamedObject as TRTTIProperty).PropertyType
  else
    ARTTIType := (ARttiNamedObject as TRttiType);
  FKind := ARTTIType.TypeKind;
  if not (FKind in [tkEnumeration,tkSet]) then
    raise E.CreateFmt('%s is not a Enumeration',[ARttiNamedObject.Name]);
  inherited Create(ARttiNamedObject);
  FValues := TStringList.Create;
  FValueLabels := TStringList.Create;
  if ARTTIType is TRttiEnumerationType then
     FRttiEnum := (ARTTIType as TRttiEnumerationType)
  else if FKind = tkSet then
    FRttiEnum := (ARTTIType  as TRttiSetType).ElementType as TRttiEnumerationType
  else
    raise E.CreateFmt('%s is not a Enumeration',[ARttiNamedObject.Name]);

  for Index := RttiEnum .MinValue to RttiEnum .MaxValue do begin
    Name := GetEnumName(RttiEnum.Handle,Index);
    FValues.Add(Name);
    Name := ReadableText(Name);
    if Name = '' then
      Name := '(none)';
    FValueLabels.Add(Name);
  end;
end;

destructor TgWebUIEnum.Destroy;
begin
  FreeAndNil(FValues);
  FreeAndNil(FValueLabels);
  inherited;
end;

{ TgWebUIMethod }

procedure TgWebUIMethod.Build(var Builder: TStringBuilder);
var
  AExtra: String;
begin
  Builder.AppendFormat(_ButtonHTML,[
     FName {0}
    ,FName {1}
    ,FValue {2}
    ,Extra{3}
    ])
end;

constructor TgWebUIMethod.Create(ARttiNamedObject: TRttiNamedObject);
begin
  inherited;
  FRttiMethod := ARttiNamedObject as TRttiMethod;
  if FRttiMethod.Parent.IsInstance then
    FCan := FRttiMethod.Parent.AsInstance.GetProperty(Format('Can%s',[FRttiMethod.Name]));
  FName := FRttiMethod.Name;
  FValue :=ReadableText(FName);
end;

function TgWebUIMethod.GetExtra: String;
begin
  if FExtra <> '' then Exit(FExtra);
  if Assigned(FCan) then
    FExtra := FExtra+' condition="'+FCan.Name+'"';
  if Help <> '' then
    FExtra := FExtra+' title="'+Help+'"';
  Result := FExtra;
end;

procedure TgElementInput.ProcessNode(Source: IXMLNode;
  TargetChildNodes: IXMLNodeList);
var
  Index: Integer;
  ANode: IXMLNode;
  AgBase: TgBase;
  AObject: TgObject;
  AOriginalValue: IXMLNode;
  FullPath: String;
  OriginalValueName: String;
  Attribute: IXMLNode;
  AValue: Variant;
  AName: String;
  RTTIProperty: TRttiProperty;
begin
  AgBase := gBase;
//  if Assigned(Object_) then
//    gBase := Object_;
//  if not Assigned(gBase) then exit;

// Name attribute needs to be expand out to the fully qualified model level path name
  FullPath := ExpandPath(Name);
  AObject := nil;
  if AgBase is TgObject then
    AObject := AgBase as TgObject;
  if Assigned(AObject) then
    OriginalValueName := ExpandPath(Name,'OriginalValues')
  else
    OriginalValueName := '';
  NodeAttributes.Values['name'] := FullPath;

  if TypeEnum = itCheckbox then begin
    ANode := gDocument.Target.CreateNode('input');
    ANode.Attributes['type'] := 'hidden';
    ANode.Attributes['name'] := FullPath;
    ANode.Attributes['value'] := '';
    TargetChildNodes.Add(ANode);
  end;

// Current Object Path Name customers.current.firstname, customers.currentkey = 5 needs to be set before hand, or customers.add
// object Path Name customers[5].Firstname
// Form elemetn manages check box blank entry
// .OriginalValues.
// .ValidationErrors.
// evaluate attribute stops all processing of the input value and delete's itself
// text type=hidden, text, password, email, number
// checkbox type = checkbox, radio ,
// image file
// original value not on checkbox radio hidden submit image and file
// originalvalues appear after the input
// Look up the owner form to contain the hidden values
// object context is implied already
  // SetValue
  case TypeEnum of
    itCheckbox
    : begin
        if not AgBase.DoGetProperties(Name,RTTIProperty) then
          RTTIProperty := nil;

        if not Assigned(RTTIProperty) or (RTTIProperty.PropertyType.Handle = TypeInfo(Boolean)) then begin
          NodeAttributes.Values['value'] := 'true';
          AValue := AgBase.DoGetValues(Name,AValue) and AValue;
        end
        else if ((RTTIProperty.PropertyType is TRTTIEnumerationType) or (RTTIProperty.PropertyType is TRttiSetType)) then
          AValue := AgBase.DoGetInValues(Name,Value)
        else
          AValue := AgBase.DoGetValues(Name,AValue) and AValue;
        if AValue then
          NodeAttributes.Values['checked'] := 'checked';
      end;
    itRadio
    : begin
        if AgBase.DoGetValues(Name,AValue) and (AValue = value) then
          NodeAttributes.Values['checked'] := 'checked';
      end;
    itSubmit
    :
    else begin
      // if value exists as a attribute don't override it.
      if NodeAttributes.Values['value'] = '' then
        NodeAttributes.Values['value'] := AgBase[Name];
    end;
  end;
  ANode := gDocument.Target.CreateNode('input');
  if not AgBase.DoGetProperties(Name,RTTIProperty,AgBase) then
    RTTIProperty := nil;
  Index := NodeAttributes.Count-1;
  for Index := 0 to Index do begin
    AName := NodeAttributes.Names[Index];
    ANode.Attributes[AName] := NodeAttributes.Values[AName];
  end;
  TargetChildNodes.Add(ANode);
  if Assigned(AObject) then
    case TypeEnum of
      itHidden
      :;
      else begin
        AOriginalValue := gDocument.Target.CreateNode('input');
        AOriginalValue.Attributes['type'] := 'hidden';
        AOriginalValue.Attributes['name'] := OriginalValueName;
        AOriginalValue.Attributes['value'] := AObject.OriginalValues[Name];
        TargetChildNodes.Add(AOriginalValue);
      end;
    end;
end;

procedure TgElementInput.SetType(const Value: String);
var
  Index: Integer;
begin
  if FType = Value then exit;
  FType := Value;
  if Value = '' then
    FTypeEnum := it
  else begin
    Index := GetEnumValue(TypeInfo(TType),'it'+Type_);
    if Index < 0 then
      FTypeEnum := itUnknown
    else
      FTypeEnum := TType(Index);
  end;


end;

procedure TgElementInput.SetTypeEnum(const Value: TType);
begin
  if FTypeEnum = Value then exit;
  FTypeEnum := Value;
  FType := GetEnumName(TypeInfo(TType),Ord(Value));
  FType := Copy(FType,3,Length(FType)-2);
end;

{ TgElementTextArea }

procedure TgElementTextArea.ProcessNode(Source: IXMLNode;
  TargetChildNodes: IXMLNodeList);
var
  Index: Integer;
  ANode: IXMLNode;
begin
//  if Assigned(Object_) then
//    gBase := Object_;
//  if not Assigned(gBase) then exit;
(*
  if SameText(Type_,'Checkbox') then begin
    ANode := gDocument.Target.CreateNode('input');
    ANode.Attributes['type'] := 'hidden';
    ANode.Attributes['name'] := Name;
    ANode.Attributes['value'] := '';
    TargetChildNodes.Add(ANode);
  end;
*)
  ANode := gDocument.Target.CreateNode('textarea');
  for Index := 0 to Source.AttributeNodes.Count-1 do
    ANode.Attributes[Source.AttributeNodes[Index].NodeName] := Source.AttributeNodes[Index].NodeValue;
  ANode.NodeValue := gBase[Name];
  TargetChildNodes.Add(ANode);
end;

{ TgElementOption }

procedure TgElementOption.ProcessNode(Source: IXMLNode;
  TargetChildNodes: IXMLNodeList);
var
  ANode: IXMLNode;
  AName: String;
  AValue1: Variant;
  AValue2: Variant;
begin
//  inherited;
  ANode := CopyNode(Source);
  ANode.NodeValue := Source.NodeValue;
  TargetChildNodes.Add(ANode);
  if not Assigned(ANode) or not (Owner is TgElementSelect) then exit;
  AName := (Owner as TgElementSelect).Name;
  if not gBase.DoGetValues(AName,AValue1) then exit;
  AValue2 := ANode.Attributes['value'];
  if AValue1 = AValue2 then
    ANode.Attributes['selected'] := true;
end;

{ TgWebUIClass }

procedure TgWebUIClass.Build(var Builder: TStringBuilder);
begin
  Builder.Append('<lu>');
  Builder.Append(Name);
  Builder.Append('</lu>');
  //inherited;

end;

{ TgWebUIIdentityObject }

procedure TgWebUIIdentityObject.Build(var Builder: TStringBuilder);
var
  WebUI: TgWebUIBase;
begin
  Builder.AppendFormat('<form object="%0:s">',[Name]);
  for WebUI in FFields do
    WebUI.Build(Builder);
  for WebUI in FMethods do
    WebUI.Build(Builder);
  Builder.Append('</form>');
end;

procedure TgWebUIIdentityObject.BuildLink(var Builder: TStringBuilder;
  ARttiMember: TRttiMember);
begin
  Builder.AppendFormat('<li id="%0:s"><a href="%0:sForm.html">%1:s</a></li>',[ARttiMember.Name,ARttiMember.Name])
end;

constructor TgWebUIIdentityObject.Create(ARttiNamedObject: TRttiNamedObject);
var
  Index: Integer;
  RTTIProperty: TRttiProperty;
  RTTIMethod: TRttiMethod;
  RTTIInstanceType: TRttiInstanceType;
  WebUI: TgWebUIBase;
  aColumns: Columns;
  Name: String;
begin
  inherited;
  if not ((ARTTINamedObject as TRttiInstanceProperty).PropertyType.AsInstance.MetaclassType.InheritsFrom(TgIdentityObject)) then exit;
  FItemClass := TgBaseClass((ARTTINamedObject as TRttiProperty).PropertyType.AsInstance.MetaclassType);
  if not Assigned(FItemClass) then exit;
  if GetAttribute<Columns>(ARttiNamedObject,aColumns) then begin
    for Name in aColumns.Names do
      if FItemClass.DoGetProperties(Name,RTTIProperty) then begin
        SetLength(FFields,Length(FFields)+1);
        FFields[High(FFields)] := WebUI;
      end
  end
  else
    for RTTIProperty in FItemClass.RTTIValueProperties do
      if (RTTIProperty.Name <> 'ID') and TgWebUIBase.GetUI(RTTIProperty,WebUI) then begin
        SetLength(FFields,Length(FFields)+1);
        FFields[High(FFields)] := WebUI;
      end;
  RTTIInstanceType := TRttiContext.Create.GetType(FItemClass.ClassInfo) as TRttiInstanceType;
//  RTTIInstanceType := TRttiContext.Create.GetType(TgIdentityObject.ClassInfo) as TRttiInstanceType;
  for RTTIMethod in RTTIInstanceType.GetMethods do
    if RTTIMethod.Visibility = mvPublished then
      if TgWebUIBase.GetUI(RTTIMethod,WebUI) then begin
        SetLength(FMethods,Length(FMethods)+1);
        FMethods[High(FMethods)] := WebUI;
      end;
end;

{ TgWebUIList }

procedure TgWebUIList.AddColumn(WebUI: TgWebUIBase);
begin
  SetLength(FColumns,Length(FColumns)+1);
  FColumns[High(FColumns)] := WebUI;

end;

procedure TgWebUIList.Build(var Builder: TStringBuilder);
var
  WebUI: TgWebUIBase;
begin
  Builder.AppendFormat('<table id="lst%0:s">',[Name]);
  Builder.Append('<tr>');
  for WebUI in FColumns do
    Builder.AppendFormat('<th>%0:s</th>',[WebUI.Caption]);
  Builder.Append('</tr>');
  Builder.AppendFormat('<tr foreach="%0:s">',[Name]);
  for WebUI in FColumns do
    Builder.AppendFormat('<td><a href="%0:s-%1:sform.html?%0:s.currentkey={ID}">{%2:s}</a></td>',[Name,ItemClass.FriendlyName,WebUI.Name]);
  Builder.Append('</tr>');
  Builder.Append('</table>');
end;

procedure TgWebUIList.BuildLink(var Builder: TStringBuilder;
  ARttiMember: TRttiMember);
begin
  Builder.AppendFormat('<li id="%0:s"><a href="%0:sList.html">%1:s</a></li>',[ARttiMember.Name,ARttiMember.Name])
end;

constructor TgWebUIList.Create(ARttiNamedObject: TRttiNamedObject);
var
  RttiProperty: TRttiProperty;
  WebUI: TgWebUIBase;
  aColumns: Columns;
  Name: String;
begin
  inherited;
  if ((ARTTINamedObject as TRttiProperty).PropertyType.AsInstance.MetaclassType.InheritsFrom(TgList)) then
    FItemClass := TgList.TClassOf((ARTTINamedObject as TRttiProperty).PropertyType.AsInstance.MetaclassType)._ItemClass;
  if GetAttribute<Columns>(ARttiNamedObject,aColumns) then
    for Name in aColumns.Names do begin
      RttiProperty := G.PropertyByName(ItemClass,Name);
      if Assigned(RttiProperty) then
        if TgWebUIBase.GetUI(RttiProperty,WebUI) then
          AddColumn(WebUI);
    end
  else // Default Columns
    for RTTIProperty in FItemClass.RTTIValueProperties do
      if RTTIProperty.Visibility = mvPublished then
        if TgWebUIBase.GetUI(RttiProperty,WebUI) and (WebUI.Name <> 'ID') then
          AddColumn(WebUI);


end;

{ TgWebUIModel }


{ TgElementForm }


{ TgElementForm }

procedure TgElementForm.ProcessChildNodes(SourceChildNodes,
  TargetChildNodes: IXMLNodeList);
var
  ANode: IXMLNode;
  ABase: TgBase;
  AIdentityList: TgIdentityList;
  AList: TgList;
  ACurrent: Boolean;
  Head: String;
  Tail: String;
begin
  ABase := gBase;
  if Assigned(ABase) and Assigned(ABase.Owner) then begin
    SplitPathLast(ExpandPath(''),Head,Tail);

    AIdentityList := nil;
    if ABase.Owner is TgIdentityList then
      AIdentityList := ABase.Owner as TgIdentityList;
    AList := nil;
    if ABase.Owner is TgList then
      AList := ABase.Owner as TgList;

    // Current?
    ANode := nil;
    if SameText(Head,'Current') then begin
      ANode := gDocument.Target.CreateNode('input');
      ANode.Attributes['type'] := 'hidden';
      if not ABase.IsLoaded then begin
        ANode.Attributes['value'] := '';
        ANode.Attributes['name'] := Tail+'.Add';
      end
      else if Assigned(AIdentityList) then begin
        ANode.Attributes['value'] := AIdentityList.CurrentKey;
        ANode.Attributes['name'] := Tail+'.CurrentKey';
      end
      else if Assigned(AList) then begin
        ANode.Attributes['value'] := AList.CurrentIndex;
        ANode.Attributes['name'] := Tail+'.CurrentIndex';
      end;
    end;
    if Assigned(ANode) then
      TargetChildNodes.Add(ANode);
  end;
inherited;

end;

end.

//when you have a edit box

<input type="text" id="{propertyName}" name="Name" size="50" maxlength="50" Value="{ModelValu}" />
<input type="checkbox">
<input type="text"> email Link<mailto link>
<input type="password"
<textarea is a String without a length = class"htmleditor" cols"80" rows="15">
end
[can we attach attributes?
attributes on properites to control cols and rows of control
attribute display only {Radonly}
visible attribute

tGhtmlString = type string

class procedure TgWebUIBase.Build(var Builder: TStringBuilder;
  ARttiMember: TRttiMember; Base: TgBase);
var
  WebUI: TgWebUIBase;
begin
  if TgWebUIBase.GetUI(ARttiMember,WebUI) then
    WebUI.Build(Builder,ARttiMember,ARttiMember.Name,Base);
end;



