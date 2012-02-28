unit gCore;

interface

Uses
  Generics.Collections,
  System.RTTI,
  SysUtils
;

type
  TCustomAttributeClass = class of TCustomAttribute;
  TgBaseClass = class of TgBase;
  {$M+}
  TgBase = class;
  {$M-}

  TgPropertyAttribute = class(TCustomAttribute)
  strict private
    FRTTIProperty: TRTTIProperty;
  public
    property RTTIProperty: TRTTIProperty read FRTTIProperty write FRTTIProperty;
  end;

  TgFeature = (AutoCreate, Serializable);
  TgFeatureExclusions = Set of TgFeature;

  ExcludeFeature = class(TgPropertyAttribute)
  strict private
    FFeatureExclusions: TgFeatureExclusions;
  public
    constructor Create(AFeatureExclusions: TgFeatureExclusions);
    property FeatureExclusions: TgFeatureExclusions read FFeatureExclusions;
  end;

  DefaultValue = class(TgPropertyAttribute)
  Strict Private
    FValue : Variant;
  Public
    Constructor Create(Const AValue : String); Overload;
    Constructor Create(AValue : Integer); Overload;
    Constructor Create(AValue : Double); Overload;
    Constructor Create(AValue : TDateTime); Overload;
    procedure Execute(ABase: TgBase);
    Property Value : Variant Read FValue;
  End;

  TgObjectState = (GosInspecting, GosOriginalValues, gosLoaded, gosLoading, gosSaving, gosDeleting, gosFiltered);
  TgObjectStates = Set Of TgObjectState;

  /// <summary>TgBase is the base ancestor of all application specific classes you
  /// create in G
  /// </summary>
  TgBase = class(TObject)
  strict private
    FOwner: TgBase;
    function GetIsInspecting: Boolean;
    procedure PopulateDefaultValues;
    procedure SetIsInspecting(Const AValue : Boolean);
  private
    FObjectStates: TgObjectStates;
  strict protected
    /// <summary>TgBase.AutoCreate gets called by the Create constructor to instantiate
    /// object properties. You may override this method in a descendant class to alter
    /// its behavior.
    /// </summary>
    procedure AutoCreate; virtual;
    function DoGetValues(Const APath : String; Out AValue : Variant): Boolean; virtual;
    function DoSetValues(Const APath : String; AValue : Variant): Boolean; virtual;
    function GetValues(Const APath : String): Variant; virtual;
    /// <summary>TgBase.OwnerByClass walks up the Owner path looking for an owner whose
    /// class type matches the AClass parameter. This method gets used by the
    /// AutoCreate method to determine if an object property should get created, or
    /// reference an existing object up the owner tree.
    /// </summary>
    /// <returns> TgBase
    /// </returns>
    /// <param name="AClass"> (TgBaseClass) </param>
    function OwnerByClass(AClass: TgBaseClass): TgBase; virtual;
    procedure SetValues(Const APath : String; AValue : Variant); virtual;
  public
    /// <summary>TgBase.Create instantiates a new G object, sets its owner and
    /// automatically
    /// instantiates any object properties descending from TgBase that don't have the
    /// ExcludeFeature
    /// attribute with an AutoCreate</summary>
    /// <param name="AOwner"> (TgBase) </param>
    constructor Create(AOwner: TgBase = Nil);
    /// <summary>TgBase.Destroy frees any automatically instantiated object properties
    /// owned by the object,
    /// then destroys itself.</summary>
    destructor Destroy; override;
    procedure Assign(ASource : TgBase); virtual;
    function Inspect(ARTTIProperty: TRttiProperty): TObject; overload;
    /// <summary>TgBase.Owns determines if the object passed into  the ABase parameter
    /// has Self as its owner.
    /// </summary>
    /// <returns> Boolean
    /// </returns>
    /// <param name="ABase"> (TgBase) </param>
    function Owns(ABase : TgBase): Boolean;
    property IsInspecting: Boolean read GetIsInspecting write SetIsInspecting;
    property Values[Const APath : String]: Variant read GetValues write SetValues; default;
  published
    /// <summary>TgBase.Owner represents the object passed in the constructor. You may
    /// use the Owner object to "walk up" the model.
    /// </summary> type:TgBase
    [ExcludeFeature([AutoCreate])]
    property Owner: TgBase read FOwner;
  end;

  TgRecordProperty = Record
  public
    Getter: TRTTIMethod;
    Setter: TRTTIMethod;
    Validator: TRTTIMethod;
  End;

  G = class(TObject)
  strict private
  class var
    FAttributes: TDictionary<TPair<TgBaseClass, TCustomAttributeClass>, TArray<TCustomAttribute>>;
    FAutoCreateProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FMethodByName: TDictionary<String, TRTTIMethod>;
    FObjectProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FPropertyByName: TDictionary<String, TRTTIProperty>;
    FRecordProperty: TDictionary<TRTTIProperty, TgRecordProperty>;
    FRTTIContext: TRTTIContext;
    FSerializableProperties: TDictionary < TgBaseClass, TArray < TRTTIProperty >>;
    class procedure Initialize; static;
    /// <summary>G.InitializeAttributes initializes the cache of attributes for the
    /// class passed in the ARTTIType parameter.  For property attributes, it assigns
    /// the attribute's RTTIProperty property.
    /// </summary>
    /// <param name="ARTTIType"> (TRTTIType) </param>
    class procedure InitializeAttributes(ARTTIType: TRTTIType); static;
    /// <summary>G.InitializeAutoCreateProperties initializes the cache of auto created
    /// properties for the ARTTIType parameter class passed in.
    /// </summary>
    /// <param name="ARTTIType"> (TRTTIType) </param>
    class procedure InitializeAutoCreateProperties(ARTTIType: TRTTIType); static;
    class procedure InitializeMethodByName(ARTTIType: TRTTIType); static;
    class procedure InitializeObjectProperties(ARTTIType: TRTTIType); static;
    class procedure InitializePropertyByName(ARTTIType: TRTTIType); static;
    class procedure InitializeRecordProperty(ARTTIType: TRTTIType); static;
    class procedure InitializeSerializableProperties(ARTTIType : TRttiType); static;
  public
    class constructor Create;
    class destructor Destroy;
    class function Attributes(ABaseClass: TgBaseClass; AAttributeClass: TCustomAttributeClass): TArray<TCustomAttribute>; overload; static;
    class function Attributes(ABase: TgBase; AAttributeClass: TCustomAttributeClass): Tarray<TCustomAttribute>; overload; static;
    class function AutoCreateProperties(AInstance: TgBase): TArray<TRTTIProperty>; overload; static; inline;
    class function AutoCreateProperties(AClass: TgBaseClass): TArray<TRTTIProperty>; overload; static;
    class function MethodByName(ABaseClass: TgBaseClass; const AName: String): TRTTIMethod; overload; static;
    class function MethodByName(ABase: TgBase; const AName: String): TRTTIMethod; overload; static;
    class function ObjectProperties(AInstance: TgBase): TArray<TRTTIProperty>; overload; static; inline;
    class function ObjectProperties(AClass: TgBaseClass): TArray<TRTTIProperty>; overload; static; inline;
    class function PropertyByName(AClass: TgBaseClass; const AName: String): TRTTIProperty; overload; static;
    class function PropertyByName(ABase: TgBase; const AName: String): TRTTIProperty; overload; static;
    class function RecordProperty(ARTTIProperty: TRTTIProperty): TgRecordProperty; static;
    class function SerializableProperties(ABase: TgBase): TArray<TRTTIProperty>; overload; inline;
    class function SerializableProperties(AClass : TgBaseClass): TArray<TRTTIProperty>; overload;
  end;

  EgValue = class(Exception)
  end;

  EgAssign = class(Exception)
  end;

procedure SplitPath(Const APath : String; Out AHead, ATail : String);

implementation

Uses
  TypInfo,
  Variants
;

procedure SplitPath(Const APath : String; Out AHead, ATail : String);
var
  Position: Integer;
Begin
  Position := Pos('.', APath);
  if Position > 0 then
  Begin
    AHead := Copy(APath, 1, Position - 1);
    ATail := Copy(APath, Position + 1, MaxInt);
  End
  Else
  Begin
    AHead := APath;
    ATail := '';
  End;
End;

procedure TgBase.AutoCreate;
var
  RTTIProperty: TRTTIProperty;
  Field : TRTTIField;
  ObjectProperty : TgBase;
  ObjectPropertyClass: TgBaseClass;
begin
  for RTTIProperty in G.AutoCreateProperties(Self) do
  Begin
    // If follow the convention the property name will have a underlying field with the same name prefixed by a 'F'
   { TODO : Find a better of initialzing the local storage of a property }
    Field := RTTIProperty.Parent.GetField('F' + RTTIProperty.Name);
    if Assigned(Field) then
    Begin
      ObjectPropertyClass := TgBaseClass(RTTIProperty.PropertyType.AsInstance.MetaclassType);
      // See if there is a owner that can populate this property
      ObjectProperty := OwnerByClass(ObjectPropertyClass);
      if Not Assigned(ObjectProperty) then
        // Then just create a empty structure to be populated later.
        // This will be owned by this structure and destroyed because it there.
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
  PopulateDefaultValues;
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

procedure TgBase.Assign(ASource : TgBase);
Var
  SourceObject : TgBase;
  DestinationObject : TgBase;
  RTTIProperty : TRTTIProperty;
Begin
  If ASource.ClassType = ClassType Then
  Begin
    For RTTIProperty In G.SerializableProperties(Self) Do
    Begin
      If RTTIProperty.PropertyType.IsInstance Then
      Begin
        SourceObject := TgBase(ASource.Inspect(RTTIProperty));
        If Assigned(SourceObject) And SourceObject.InheritsFrom(TgBase) And ASource.Owns(SourceObject) Then
        Begin
          DestinationObject := TgBase(RTTIProperty.GetValue(Self).AsObject);
          If Assigned(DestinationObject) And DestinationObject.InheritsFrom(TgBase) Then
            DestinationObject.Assign(SourceObject);
        End;
      End
      Else
        RTTIProperty.SetValue(Self, RTTIProperty.GetValue(ASource));
    End;
  End
  Else
    Raise EgAssign.CreateFmt('Assignment mismatch between source ''%s'' and destination ''%s'' classes.', [ASource.ClassName, ClassName]);
End;

function TgBase.DoGetValues(Const APath : String; Out AValue : Variant): Boolean;
Var
  Head : String;
  ObjectProperty: TgBase;
  PropertyValue: TValue;
  RecordProperty: TgRecordProperty;
  RTTIProperty : TRttiProperty;
  Tail : String;
Begin
  Result := False;
  SplitPath(APath, Head, Tail);
  RTTIProperty := G.PropertyByName(Self, Head);
  if Assigned(RTTIProperty) then
  begin
    if Not RTTIProperty.IsReadable then
      raise EgValue.CreateFmt('%s.%s is not a readable property.', [ClassName, RTTIProperty.Name]);
    if RTTIProperty.PropertyType.IsInstance then
    begin
      if Tail > '' then
      Begin
        ObjectProperty := TgBase(RTTIProperty.GetValue(Self).AsObject);
        Result := ObjectProperty.DoGetValues(Tail, AValue);
      End
      Else
        raise EgValue.CreateFmt('Can''t return %s.%s, because it''s an object property', [ClassName, RTTIProperty.Name]);
    end
    Else if RTTIProperty.PropertyType.IsRecord Then
    Begin
      RecordProperty := G.RecordProperty(RTTIProperty);
      If Not Assigned(RecordProperty.Getter) then
        Raise EgValue.CreateFmt('%s has no GetValue method for runtime assignment.', [RTTIProperty.Name]);
      PropertyValue := RTTIProperty.GetValue(Self);
      AValue := RecordProperty.Getter.Invoke(PropertyValue, []).AsVariant;
      Result := True;
    End
    Else
    Begin
      if Tail = '' then
      Begin
        If (RTTIProperty.PropertyType.TypeKind = TkEnumeration) And SameText(RTTIProperty.PropertyType.Name, 'Boolean') Then
        Begin
          AValue := RTTIProperty.GetValue(Self).AsBoolean;
          Result := True;
        End
        Else
        Begin
          AValue := RTTIProperty.GetValue(Self).AsType<Variant>;
          Result := True;
        End;
      End
      Else
        raise EgValue.CreateFmt('Can''t return %s.%s, because %s is not an object property', [RTTIProperty.Name, Tail, RTTIProperty.Name]);
    End
  end;
End;

function TgBase.DoSetValues(Const APath : String; AValue : Variant): Boolean;
Var
  Head: String;
  ObjectProperty: TgBase;
  PropertyValue: TValue;
  RecordProperty: TgRecordProperty;
  RTTIProperty : TRTTIProperty;
  RTTIMethod : TRTTIMethod;
  Tail: String;
  Value : TValue;
Begin
  Result := False;
  SplitPath(APath, Head, Tail);
  RTTIProperty := G.PropertyByName(Self, Head);
  if Assigned(RTTIProperty) then
  begin
    if RTTIProperty.PropertyType.IsInstance then
    begin
      if Tail > '' then
      Begin
        ObjectProperty := TgBase(RTTIProperty.GetValue(Self).AsObject);
        Result := ObjectProperty.DoSetValues(Tail, AValue);
      End
      Else
        raise EgValue.CreateFmt('Can''t set %s.%s, because it''s an object property', [ClassName, RTTIProperty.Name]);
    end
    Else if RTTIProperty.PropertyType.IsRecord then
    begin
      RecordProperty := G.RecordProperty(RTTIProperty);
      If Not Assigned(RecordProperty.Setter) then
        Raise EgValue.CreateFmt('%s has no SetValue method for runtime assignment.', [RTTIProperty.Name]);
      PropertyValue := RTTIProperty.GetValue(Self);
      RecordProperty.Setter.Invoke(PropertyValue, [TValue.From<Variant>(AValue)]);
      RTTIProperty.SetValue(Self, PropertyValue);
      Result := True;
    end
    Else
    Begin
      if Tail = '' then
      Begin
        if Not RTTIProperty.IsWritable then
          raise EgValue.CreateFmt('%s.%s is not settable.', [ClassName, RTTIProperty.Name]);
        Case RTTIProperty.PropertyType.TypeKind Of
          TkEnumeration :
            Value := TValue.FromVariant(VarAsType(AVAlue, VarBoolean));
          TkInteger :
            Value := TValue.FromVariant(VarAsType(AValue, VarInteger));
          TkFloat :
          Begin
            case (VarType(AValue) and varTypeMask) of
              varString, varUString:
              if SameText(RTTIProperty.PropertyType.Name, 'TDate') or SameText(RTTIProperty.PropertyType.Name, 'TDateTime') then
                Value := StrToDateTime(AValue);
            Else
              Value := TValue.FromVariant(VarAsType(AValue, VarDouble));
            end;
          End;
          TkUString :
            Value := TValue.FromVariant(VarAsType(AValue, VarUString));
        Else
          Raise EgValue.CreateFmt('%s.%s is not a value property', [ClassName, RTTIProperty.Name]);
        End;
        RTTIProperty.SetValue(Self, Value);
        Result := True;
      End
      Else
        raise EgValue.CreateFmt('Can''t set %s.%s, because %s is not an object property', [RTTIProperty.Name, Tail, RTTIProperty.Name]);
    End
  end
  Else
  Begin
    RTTIMethod := G.MethodByName(Self, Head);
    if Assigned(RTTIMethod) then
    Begin
      RTTIMethod.Invoke(Self, []);
      Result := True;
    End;
  End;
End;

function TgBase.GetIsInspecting: Boolean;
Begin
  Result := GosInspecting In FObjectStates;
End;

function TgBase.GetValues(Const APath : String): Variant;
Begin
  If Not DoGetValues(APath, Result) Then
    Raise EgValue.CreateFmt('Path ''%s'' not found.', [APath]);
End;

function TgBase.Inspect(ARTTIProperty: TRttiProperty): TObject;
begin
  IsInspecting := True;
  Result := ARTTIProperty.GetValue(Self).AsObject;
  IsInspecting := False;
end;

function TgBase.Owns(ABase : TgBase): Boolean;
Begin
  Result := Assigned(ABase) And (ABase.Owner = Self);
End;

procedure TgBase.PopulateDefaultValues;
Var
  Attribute : TCustomAttribute;
Begin
  For Attribute In G.Attributes(Self, DefaultValue) Do
    DefaultValue(Attribute).Execute(Self);
End;

procedure TgBase.SetIsInspecting(Const AValue : Boolean);
Begin
  If AValue Then
    Include(FObjectStates, GosInspecting)
  Else
    Exclude(FObjectStates, GosInspecting);
End;

procedure TgBase.SetValues(Const APath : String; AValue : Variant);
Begin
  If Not DoSetValues(APath, AValue) Then
    Raise EgValue.CreateFmt('Path ''%s'' not found.', [APath]);
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
      InitializePropertyByName(RTTIType);
      InitializeMethodByName(RTTIType);
      InitializeRecordProperty(RTTIType);
      InitializeSerializableProperties(RTTIType);
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
  // Add Class Attributes
  for Attribute in ARTTIType.GetAttributes do
    AddAttribute(Attribute);
  // Add Property Attributes
  for RTTIProperty in ARTTIType.GetProperties do
  if RTTIProperty.Visibility = mvPublished then
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
{ TODO : Don't do a auto create if the getter is a method. only when it is local storage }
    CanAdd := True;
    for Attribute in RTTIProperty.GetAttributes do
    if Attribute.InheritsFrom(ExcludeFeature) And (AutoCreate In ExcludeFeature(Attribute).FeatureExclusions) Then
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
  if (RTTIProperty.Visibility = mvPublished) And RTTIProperty.PropertyType.IsInstance then
  Begin
    FObjectProperties.TryGetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
    SetLength(RTTIProperties, Length(RTTIProperties) + 1);
    RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
    FObjectProperties.AddOrSetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
  End;
end;

class constructor G.Create;
begin
  FRTTIContext := TRTTIContext.Create();
  FAttributes := TDictionary<TPair<TgBaseClass, TCustomAttributeClass>, TArray<TCustomAttribute>>.Create();
  FObjectProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FAutoCreateProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FPropertyByName := TDictionary<String, TRTTIProperty>.Create();
  FMethodByName := TDictionary<String, TRTTIMethod>.Create();
  FSerializableProperties := TDictionary < TgBaseClass, TArray < TRTTIProperty >>.Create();
  FRecordProperty := TDictionary<TRTTIProperty, TgRecordProperty>.Create();
  Initialize;
end;

class destructor G.Destroy;
begin
  FreeAndNil(FRecordProperty);
  FreeAndNil(FMethodByName);
  FreeAndNil(FSerializableProperties);
  FreeAndNil(FPropertyByName);
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

class procedure G.InitializeMethodByName(ARTTIType: TRTTIType);
var
  Key: String;
  RTTIMethod: TRTTIMethod;
begin
  for RTTIMethod in ARTTIType.GetMethods do
  if (RTTIMethod.Visibility = mvPublished) And (Length(RTTIMethod.GetParameters) = 0) then
  begin
    Key := ARTTIType.AsInstance.MetaclassType.ClassName + '.' + UpperCase(RTTIMethod.Name);
    FMethodByName.Add(Key, RTTIMethod);
  end;
end;

class procedure G.InitializePropertyByName(ARTTIType: TRTTIType);
var
  RTTIProperty: TRTTIProperty;
  Key : String;
begin
  for RTTIProperty in ARTTIType.GetProperties do
  if RTTIProperty.Visibility = mvPublished then
  begin
    Key := ARTTIType.AsInstance.MetaclassType.ClassName + '.' + UpperCase(RTTIProperty.Name);
    FPropertyByName.Add(Key, RTTIProperty);
  end;
end;

class procedure G.InitializeRecordProperty(ARTTIType: TRTTIType);
var
  CanAdd: Boolean;
  RecordProperty: TgRecordProperty;
  RTTIProperty: TRTTIProperty;
begin
  for RTTIProperty in ARTTIType.GetProperties do
  if (RTTIProperty.Visibility = mvPublished) And (RTTIProperty.PropertyType.IsRecord) then
  begin
    CanAdd := True;
    if RTTIProperty.IsReadable Then
    begin
      RecordProperty.Getter := RTTIProperty.PropertyType.AsRecord.GetMethod('GetValue');
      CanAdd := Assigned(RecordProperty.Getter);
    end;
    if CanAdd And RTTIProperty.IsWritable then
    begin
      RecordProperty.Setter := RTTIProperty.PropertyType.AsRecord.GetMethod('SetValue');
      CanAdd := Assigned(RecordProperty.Setter);
    end;
    if CanAdd then
    Begin
      RecordProperty.Validator := RTTIProperty.PropertyType.AsRecord.GetMethod('Validate');
      FRecordProperty.Add(RTTIProperty, RecordProperty);
    End;
  end;
end;

class procedure G.InitializeSerializableProperties(ARTTIType : TRttiType);
Var
  Attribute: TCustomAttribute;
  CanAdd: Boolean;
  RTTIProperties: TArray<TRTTIProperty>;
  RTTIProperty : TRTTIProperty;
Begin
  for RTTIProperty in ARTTIType.GetProperties do
  if RTTIProperty.Visibility = mvPublished then
  begin
    CanAdd := True;
    for Attribute in RTTIProperty.GetAttributes do
    begin
      if Attribute.InheritsFrom(ExcludeFeature) And (Serializable in ExcludeFeature(Attribute).FeatureExclusions) then
        Break;
      if CanAdd And RTTIProperty.IsReadable then
      Begin
        if RTTIProperty.PropertyType.IsInstance then
          CanAdd := RTTIProperty.PropertyType.AsInstance.MetaclassType.InheritsFrom(TgBase)
        else
          CanAdd := RTTIProperty.IsWritable;
      End;
      if CanAdd then
      begin
        FSerializableProperties.TryGetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
        SetLength(RTTIProperties, Length(RTTIProperties) + 1);
        RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
        FSerializableProperties.AddOrSetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
      end;
    end;
  end;
End;

class function G.MethodByName(ABaseClass: TgBaseClass; const AName: String): TRTTIMethod;
var
  Key: String;
begin
  Key := ABaseClass.ClassName + '.' + UpperCase(AName);
  FMethodByName.TryGetValue(Key, Result);
end;

class function G.MethodByName(ABase: TgBase; const AName: String): TRTTIMethod;
begin
  Result := MethodByName(TgBaseClass(ABase.ClassType), AName);
end;

class function G.ObjectProperties(AInstance: TgBase): TArray<TRTTIProperty>;
begin
  Result := ObjectProperties(TgBaseClass(AInstance.ClassType));
end;

class function G.ObjectProperties(AClass: TgBaseClass): TArray<TRTTIProperty>;
begin
  FObjectProperties.TryGetValue(AClass, Result);
end;

class function G.PropertyByName(AClass: TgBaseClass; const AName: String): TRTTIProperty;
var
  Key : String;
begin
  Key := AClass.ClassName + '.' + UpperCase(AName);
  FPropertyByName.TryGetValue(Key, Result);
end;

class function G.PropertyByName(ABase: TgBase; const AName: String): TRTTIProperty;
begin
  Result := PropertyByName(TgBaseClass(ABase.ClassType), AName);
end;

class function G.RecordProperty(ARTTIProperty: TRTTIProperty): TgRecordProperty;
begin
  FRecordProperty.TryGetValue(ARTTIProperty, Result);
end;

class function G.SerializableProperties(ABase: TgBase): TArray<TRTTIProperty>;
Begin
  Result := SerializableProperties(TgBaseClass(ABase.ClassType));
End;

class function G.SerializableProperties(AClass : TgBaseClass): TArray<TRTTIProperty>;
Begin
  FSerializableProperties.TryGetValue(AClass, Result);
End;

constructor ExcludeFeature.Create(AFeatureExclusions: TgFeatureExclusions);
begin
  inherited Create;
  FFeatureExclusions := AFeatureExclusions;
end;

Constructor DefaultValue.Create(Const AValue : String);
Begin
  FValue := AValue;
End;

Constructor DefaultValue.Create(AValue : Integer);
Begin
  FValue := AValue;
End;

Constructor DefaultValue.Create(AValue : Double);
Begin
  FValue := AValue;
End;

Constructor DefaultValue.Create(AValue : TDateTime);
Begin
  FValue := AValue;
End;

procedure DefaultValue.Execute(ABase: TgBase);
var
  TempValue: TValue;
begin
  TempValue := TValue.FromVariant(Value);
  RTTIProperty.SetValue(ABase, TempValue);
end;

end.
