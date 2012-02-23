unit gCore;

interface

Uses
  Generics.Collections,
  RTTI
  ;

type
  TCustomAttributeClass = class of TCustomAttribute;
  TgBaseClass = class of TgBase;

  TgPropertyAttribute = class(TCustomAttribute)
  strict private
    FRTTIProperty: TRTTIProperty;
  public
    property RTTIProperty: TRTTIProperty read FRTTIProperty write FRTTIProperty;
  end;

  AttributeExclusion = (AutoCreate);
  AttributeExclusions = Set of AttributeExclusion;

  Exclude = class(TgPropertyAttribute)
  strict private
    FExclusions: AttributeExclusions;
  public
    constructor Create(AExclusions: AttributeExclusions);
    property Exclusions: AttributeExclusions read FExclusions;
  end;

  /// <summary>TgBase is the base ancestor of all application specific classes you
  /// create in G
  /// </summary>
  {$M+}
  TgBase = class(TObject)
  strict private
    FOwner: TgBase;
  strict protected
    /// <summary>TgBase.AutoCreate gets called by the Create constructor to instantiate
    /// object properties. You may override this method in a descendant class to alter
    /// its behavior.
    /// </summary>
    procedure AutoCreate; virtual;
    /// <summary>TgBase.OwnerByClass walks up the Owner path looking for an owner whose
    /// class type matches the AClass parameter. This method gets used by the
    /// AutoCreate method to determine if an object property should get created, or
    /// reference an existing object up the owner tree.
    /// </summary>
    /// <returns> TgBase
    /// </returns>
    /// <param name="AClass"> (TgBaseClass) </param>
    function OwnerByClass(AClass: TgBaseClass): TgBase; virtual;
  public
    /// <summary>TgBase.Create instantiates a new G object, sets its owner and
    /// automatically
    /// instantiates any object properties descending from TgBase that don't have the
    /// Exclude
    /// attribute with an AutoCreate</summary>
    /// <param name="AOwner"> (TgBase) </param>
    constructor Create(AOwner: TgBase = Nil);
    /// <summary>TgBase.Destroy frees any automatically instantiated object properties
    /// owned by the object,
    /// then destroys itself.</summary>
    destructor Destroy; override;
    /// <summary>TgBase.Owns determines if the object passed into  the ABase parameter
    /// has Self as its owner.
    /// </summary>
    /// <returns> Boolean
    /// </returns>
    /// <param name="ABase"> (TgBase) </param>
    function Owns(ABase : TgBase): Boolean;
  published
    /// <summary>TgBase.Owner represents the object passed in the constructor. You may
    /// use the Owner object to "walk up" the model.
    /// </summary> type:TgBase
    [Exclude([AutoCreate])]
    property Owner: TgBase read FOwner;
  end;
  {$M-}

  G = class(TObject)
  strict private
  class var
    FAttributes: TDictionary<TPair<TgBaseClass, TCustomAttributeClass>, TArray<TCustomAttribute>>;
    FAutoCreateProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FObjectProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FRTTIContext: TRTTIContext;
    class procedure Initialize; static;
    class procedure InitializeAttributes(ARTTIType: TRTTIType); static;
    class procedure InitializeAutoCreateProperties(ARTTIType: TRTTIType); static;
    class procedure InitializeObjectProperties(ARTTIType: TRTTIType); static;
  public
    class constructor Create;
    class destructor Destroy;
    class function Attributes(ABaseClass: TgBaseClass; AAttributeClass: TCustomAttributeClass): TArray<TCustomAttribute>; overload; static;
    class function Attributes(ABase: TgBase; AAttributeClass: TCustomAttributeClass): Tarray<TCustomAttribute>; overload; static;
    class function AutoCreateProperties(AInstance: TgBase): TArray<TRTTIProperty>; overload; static; inline;
    class function AutoCreateProperties(AClass: TgBaseClass): TArray<TRTTIProperty>; overload; static;
    class function ObjectProperties(AInstance: TgBase): TArray<TRTTIProperty>; overload; static; inline;
    class function ObjectProperties(AClass: TgBaseClass): TArray<TRTTIProperty>; overload; static; inline;
  end;

implementation

Uses
  SysUtils,
  TypInfo
  ;

procedure TgBase.AutoCreate;
var
  RTTIProperty: TRTTIProperty;
  Field : TRTTIField;
  ObjectProperty : TgBase;
  ObjectPropertyClass: TgBaseClass;
begin
  for RTTIProperty in G.AutoCreateProperties(Self) do
  Begin
    Field := RTTIProperty.Parent.GetField('F' + RTTIProperty.Name);
    if Assigned(Field) then
    Begin
      ObjectPropertyClass := TgBaseClass(RTTIProperty.PropertyType.AsInstance.MetaclassType);
      ObjectProperty := OwnerByClass(ObjectPropertyClass);
      if Not Assigned(ObjectProperty) then
        ObjectProperty := ObjectPropertyClass.Create(Self);
      Field.SetValue(Self, ObjectProperty)
    End;
  End;
end;

function TgBase.OwnerByClass(AClass: TgBaseClass): TgBase;
begin
  if Assigned(Owner) then
  Begin
    if Owner.ClassType = AClass then
      Result := Owner
    Else
      Result := Owner.OwnerByClass(AClass);
  End
  Else
    Result := Nil;
end;

constructor TgBase.Create(AOwner: TgBase = Nil);
begin
  inherited Create;
  FOwner := AOwner;
  AutoCreate;
end;

destructor TgBase.Destroy;
var
  ObjectProperty: TgBase;
  RTTIProperty: TRTTIProperty;
begin
  for RTTIProperty in G.AutoCreateProperties(Self) do
  Begin
    ObjectProperty := TgBase(RTTIProperty.GetValue(Self).AsObject);
    if Owns(ObjectProperty) then
      ObjectProperty.Free;
  End;
  inherited Destroy;
end;

function TgBase.Owns(ABase : TgBase): Boolean;
Begin
  Result := Assigned(ABase) And (ABase.Owner = Self);
End;

class procedure G.Initialize;
var
  RTTIType: TRTTIType;
begin
  for RTTIType in FRTTIContext.GetTypes do
  begin
    if RTTIType.IsInstance And RTTIType.AsInstance.MetaclassType.InheritsFrom(TgBase) then
    Begin
      InitializeAttributes(RTTIType);
      InitializeObjectProperties(RTTIType);
      InitializeAutoCreateProperties(RTTIType);
    End;
  end;
end;

class procedure G.InitializeAttributes(ARTTIType: TRTTIType);
var
  Attribute: TCustomAttribute;
  Pair : TPair<TgBaseClass, TCustomAttributeClass>;
  Attributes : TArray<TCustomAttribute>;
  RTTIProperty: TRTTIProperty;

  procedure AddAttribute(AAttribute: TCustomAttribute);
  begin
    Pair.Key := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
    Pair.Value := TCustomAttributeClass(Attribute.ClassType);
    FAttributes.TryGetValue(Pair, Attributes);
    SetLength(Attributes, Length(Attributes) + 1);
    Attributes[Length(Attributes) - 1] := Attribute;
    FAttributes.AddOrSetValue(Pair, Attributes);
  end;

begin
  for Attribute in ARTTIType.GetAttributes do
    AddAttribute(Attribute);
  for RTTIProperty in ARTTIType.GetProperties do
  begin
    for Attribute in RTTIProperty.GetAttributes do
    begin
      if Attribute.InheritsFrom(TgPropertyAttribute) then
        TgPropertyAttribute(Attribute).RTTIProperty := RTTIProperty;
      AddAttribute(Attribute);
    end;
  end;
end;

class procedure G.InitializeAutoCreateProperties(ARTTIType: TRTTIType);
Var
  RTTIProperty : TRTTIProperty;
  Attribute: TCustomAttribute;
  CanAdd : Boolean;
  RTTIProperties: TArray<TRTTIProperty>;
Begin
  for RTTIProperty in G.ObjectProperties(TgBaseClass(ARTTIType.AsInstance.MetaclassType)) do
  begin
    CanAdd := True;
    for Attribute in RTTIProperty.GetAttributes do
    if Attribute.InheritsFrom(Exclude) And (AutoCreate In Exclude(Attribute).Exclusions) Then
    Begin
      CanAdd := False;
      Break;
    End;
    if CanAdd then
    Begin
      FAutoCreateProperties.TryGetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
      SetLength(RTTIProperties, Length(RTTIProperties) + 1);
      RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
      FAutoCreateProperties.AddOrSetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
    End;
  end;
end;

class procedure G.InitializeObjectProperties(ARTTIType: TRTTIType);
Var
  RTTIProperty : TRTTIProperty;
  RTTIProperties: TArray<TRTTIProperty>;
Begin
  for RTTIProperty in ARTTIType.GetProperties do
  begin
    if RTTIProperty.PropertyType.IsInstance then
    Begin
      FObjectProperties.TryGetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
      SetLength(RTTIProperties, Length(RTTIProperties) + 1);
      RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
      FObjectProperties.AddOrSetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
    End;
  end;
end;

class constructor G.Create;
begin
  FRTTIContext := TRTTIContext.Create();
  FAttributes := TDictionary<TPair<TgBaseClass, TCustomAttributeClass>, TArray<TCustomAttribute>>.Create();
  FObjectProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FAutoCreateProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  Initialize;
end;

class destructor G.Destroy;
begin
  FreeAndNil(FAutoCreateProperties);
  FreeAndNil(FObjectProperties);
  FreeAndNil(FAttributes);
  FRTTIContext.Free;
end;

class function G.Attributes(ABaseClass: TgBaseClass; AAttributeClass: TCustomAttributeClass): TArray<TCustomAttribute>;
var
  Pair : TPair<TgBaseClass, TCustomAttributeClass>;
begin
  Pair.Key := ABaseClass;
  Pair.Value := AAttributeClass;
  FAttributes.TryGetValue(Pair, Result);
end;

class function G.Attributes(ABase: TgBase; AAttributeClass: TCustomAttributeClass): Tarray<TCustomAttribute>;
begin
  Result := Attributes(TgBaseClass(ABase.ClassType), AAttributeClass);
end;

class function G.AutoCreateProperties(AInstance: TgBase): TArray<TRTTIProperty>;
begin
  Result := AutoCreateProperties(TgBaseClass(AInstance.ClassType));
end;

class function G.AutoCreateProperties(AClass: TgBaseClass): TArray<TRTTIProperty>;
begin
  FAutoCreateProperties.TryGetValue(AClass, Result);
end;

class function G.ObjectProperties(AInstance: TgBase): TArray<TRTTIProperty>;
begin
  Result := ObjectProperties(TgBaseClass(AInstance.ClassType));
end;

class function G.ObjectProperties(AClass: TgBaseClass): TArray<TRTTIProperty>;
begin
  FObjectProperties.TryGetValue(AClass, Result);
end;

constructor Exclude.Create(AExclusions: AttributeExclusions);
begin
  inherited Create;
  FExclusions := AExclusions;
end;

end.
