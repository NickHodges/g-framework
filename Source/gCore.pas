unit gCore;

interface

Uses
  Generics.Collections,
  Generics.Defaults,
  System.RTTI,
  System.SysUtils,
  Data.DBXJSON,
  Data.DBXPlatform,
  Xml.XMLDoc,
  Xml.XMLIntf,
  Contnrs;

type
  TCustomAttributeClass = class of TCustomAttribute;
  TgBaseClass = class of TgBase;
  {$M+}
  TgBase = class;
  {$M-}

  TgList = class;
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

  TgSerializerClass = class of TgSerializer;
  TgSerializer = Class(TObject)
  Public
    constructor Create; virtual;
    procedure AddObjectProperty(const APropertyName: string; AObject: TgBase); virtual; abstract;
    procedure AddValueProperty(const AName: String; AValue: Variant); virtual; abstract;
    procedure Deserialize(AObject: TgBase; const AString: String); virtual; abstract;
    function Serialize(AObject: TgBase): String; virtual; abstract;
  End;

  TgSerializerJSON = class(TgSerializer)
  strict private
    FJSONObject: TJSONObject;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Serialize(AObject: TgBase): string; override;
    procedure AddValueProperty(const AName: string; AValue: Variant); override;
    procedure AddObjectProperty(const APropertyName: string; AObject: TgBase); override;
    procedure Deserialize(AObject: TgBase; const AString: string); override;
    property JSONObject: TJSONObject read FJSONObject write FJSONObject;
  end;

  TgSerializerXML = class(TgSerializer)
  private
    FCurrentNode: IXMLNode;
    FDocument: TXMLDocument;
    FDocumentInterface : IXMLDocument;
  public
    constructor Create; override;
    procedure AddValueProperty(const AName: String; AValue: Variant); override;
    procedure Deserialize(AObject: TgBase; const AString: String); override;
    function Serialize(AObject: TgBase): string; override;
    procedure AddObjectProperty(const APropertyName: string; AObject: TgBase); override;
    property CurrentNode: IXMLNode read FCurrentNode write FCurrentNode;
    property Document: TXMLDocument read FDocument;
  end;

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
    constructor Create(AOwner: TgBase = Nil); virtual;
    /// <summary>TgBase.Destroy frees any automatically instantiated object properties
    /// owned by the object,
    /// then destroys itself.</summary>
    destructor Destroy; override;
    procedure Assign(ASource : TgBase); virtual;
    procedure Deserialize(ASerializerClass: TgSerializerClass; const AString: String);
    class function FriendlyName: String;
    function GetFriendlyClassName: String;
    function Inspect(ARTTIProperty: TRttiProperty): TObject; overload;
    /// <summary>TgBase.Owns determines if the object passed into  the ABase parameter
    /// has Self as its owner.
    /// </summary>
    /// <returns> Boolean
    /// </returns>
    /// <param name="ABase"> (TgBase) </param>
    function Owns(ABase : TgBase): Boolean;
    function Serialize(ASerializerClass: TgSerializerClass): String; overload; virtual;
    property IsInspecting: Boolean read GetIsInspecting write SetIsInspecting;
    property Values[Const APath : String]: Variant read GetValues write SetValues; default;
  published
    [ExcludeFeature([Serializable])]
    property FriendlyClassName: String read GetFriendlyClassName;
    /// <summary>TgBase.Owner represents the object passed in the constructor. You may
    /// use the Owner object to "walk up" the model.
    /// </summary> type:TgBase
    [ExcludeFeature([AutoCreate, Serializable])]
    property Owner: TgBase read FOwner;
  end;

  TgRecordProperty = Record
  public
    Getter: TRTTIMethod;
    Setter: TRTTIMethod;
    Validator: TRTTIMethod;
  End;

  TgSerializationHelperClass = class of TgSerializationHelper;
  TgSerializationHelper = class(TObject)
  public
    class function BaseClass: TgBaseClass; virtual; abstract;
    class function SerializerClass: TgSerializerClass; virtual; abstract;
  end;

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
    FSerializationHelpers: TDictionary<TgSerializerClass, TList<TPair<TgBaseClass, TgSerializationHelperClass>>>;
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
    class procedure InitializeSerializationHelpers(ARTTIType: TRTTIType); static;
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
    class function SerializationHelpers(ASerializerClass: TgSerializerClass; AObject: TgBase): TgSerializationHelperClass; static;
  end;

  EgValue = class(Exception)
  end;

  EgAssign = class(Exception)
  end;

  TgSerializationHelperComparer = class(TComparer<TPair<TgBaseClass, TgSerializationHelperClass>>)
    function Compare(const Left, Right: TPair<TgBaseClass, TgSerializationHelperClass>): Integer; override;
  end;

  TgSerializationHelperJSONBaseClass = Class of TgSerializationHelperJSONBase;
  TgSerializationHelperJSONBase = class(TgSerializationHelper)
  public
    class function BaseClass: TgBaseClass; override;
    class procedure Deserialize(AObject: TgBase; AJSONObject: TJSONObject); virtual;
    class procedure Serialize(AObject: TgBase; ASerializer: TgSerializerJSON); virtual;
    class function SerializerClass: TgSerializerClass; override;
  end;

  TgSerializationHelperXMLBaseClass = class of TgSerializationHelperXMLBase;
  TgSerializationHelperXMLBase = class(TgSerializationHelper)
  public
    class function BaseClass: TgBaseClass; override;
    class procedure Deserialize(AObject: TgBase; AXMLNode: IXMLNode); virtual;
    class procedure Serialize(AObject: TgBase; ASerializer: TgSerializerXML); virtual;
    class function SerializerClass: TgSerializerClass; override;
  end;

  EgParse = class(Exception)
  end;

  TgListEnumerator = class(TObject)
  strict private
    FCurrentIndex: Integer;
    FList: TgList;
  strict protected
    function GetCurrent: TgBase;
  public
    constructor Create(AList: TgList);
    function MoveNext: Boolean;
    property Current: TgBase read GetCurrent;
  End;

  TgBaseProcedure = Reference to Procedure(ABase : TgBase);

  TgList = class(TgBase)
  Strict Private
    FList: TObjectList;
    FItemClass: TgBaseClass;
    FWhere: String;
    FOrderBy: String;
    function GetIsFiltered: Boolean;
    procedure SetIsFiltered(const AValue: Boolean);
  Private
    FCurrentIndex: Integer;
    function GetCurrent: TgBase;
  Strict Protected
    Function DoGetValues(Const APath : String; Out AValue : Variant) : Boolean; Override;
    Function DoSetValues(Const APath : String; AValue : Variant) : Boolean; Override;
    function GetBOL: Boolean; virtual;
    function GetCanAdd: Boolean; virtual;
    function GetCanNext: Boolean; virtual;
    function GetCanPrevious: Boolean; virtual;
    function GetCount: Integer; virtual;
    function GetCurrentIndex: Integer; virtual;
    function GetEOL: Boolean; virtual;
    function GetHasItems: Boolean; virtual;
    function GetItems(AIndex : Integer): TgBase; virtual;
    function GetItemClass: TgBaseClass;virtual;
    procedure SetCurrentIndex(const AIndex: Integer); virtual;
    procedure SetItemClass(const Value: TgBaseClass);virtual;
    procedure SetItems(AIndex : Integer; const AValue: TgBase); virtual;
    procedure SetWhere(const AValue: String); virtual;
    procedure SetOrderBy(const AValue: String); virtual;
  Public
    Constructor Create(AOwner : TgBase = Nil); Override;
    Destructor Destroy; Override;
    procedure Clear; virtual;
    function GetEnumerator: TgListEnumerator;
    procedure Execute(AgBaseProcedure: TgBaseProcedure);
    procedure Filter; virtual;
    procedure Sort;
    property IsFiltered: Boolean read GetIsFiltered write SetIsFiltered;
    property Items[AIndex : Integer]: TgBase read GetItems write SetItems; default;
    property ItemClass: TgBaseClass read GetItemClass write SetItemClass;
  Published
    Procedure Add; Overload; Virtual;
    Procedure Delete; Virtual;
    Procedure First; Virtual;
    Procedure Last; Virtual;
    Procedure Next; Virtual;
    Procedure Previous; Virtual;
    property BOL: Boolean read GetBOL;
    property CanAdd: Boolean read GetCanAdd;
    property CanNext: Boolean read GetCanNext;
    property CanPrevious: Boolean read GetCanPrevious;
    property Count: Integer read GetCount;
    [ExcludeFeature([AutoCreate, Serializable])]
    property Current: TgBase read GetCurrent;
    [ExcludeFeature([Serializable])]
    property CurrentIndex: Integer read GetCurrentIndex write SetCurrentIndex;
    property EOL: Boolean read GetEOL;
    property HasItems: Boolean read GetHasItems;
    [ExcludeFeature([Serializable])]
    property Where: String read FWhere write SetWhere;
    [ExcludeFeature([Serializable])]
    property OrderBy: String read FOrderBy write SetOrderBy;
  End;

  EgList = class(Exception)
  end;

procedure SplitPath(Const APath : String; Out AHead, ATail : String);

implementation

Uses
  TypInfo,
  Variants,
  XML.XMLDOM,
  Math
;

Const
{$IFDEF CPUX86}
  PROPSLOT_MASK    = $FF000000;
{$ENDIF CPUX86}
{$IFDEF CPUX64}
  PROPSLOT_MASK    = $FF00000000000000;
{$ENDIF CPUX64}

function IsField(P: Pointer): Boolean; inline;
begin
  Result := (IntPtr(P) and PROPSLOT_MASK) = PROPSLOT_MASK;
end;

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
  ObjectProperty : TgBase;
  ObjectPropertyClass: TgBaseClass;
  Value : TValue;
  Field : Pointer;
begin
  for RTTIProperty in G.AutoCreateProperties(Self) do
  Begin
    ObjectPropertyClass := TgBaseClass(RTTIProperty.PropertyType.AsInstance.MetaclassType);
    // See if there is a owner that can populate this property
    ObjectProperty := OwnerByClass(ObjectPropertyClass);
    if Not Assigned(ObjectProperty) then
      ObjectProperty := ObjectPropertyClass.Create(Self);
    Value := ObjectProperty;
    Field := TRTTIInstanceProperty(RTTIProperty).PropInfo^.GetProc;
    Value.Cast(RTTIProperty.PropertyType.Handle).ExtractRawData(PByte(Self) + (IntPtr(Field) and (not PROPSLOT_MASK)));
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
        If Assigned(SourceObject) And SourceObject.InheritsFrom(TgBase) Then
        Begin
          if ASource.Owns(SourceObject) then
          Begin
            DestinationObject := TgBase(RTTIProperty.GetValue(Self).AsObject);
            If Assigned(DestinationObject) And DestinationObject.InheritsFrom(TgBase) Then
              DestinationObject.Assign(SourceObject);
          End
          Else
            RTTIProperty.SetValue(Self, RTTIProperty.GetValue(ASource));
        End;
      End
      Else
        RTTIProperty.SetValue(Self, RTTIProperty.GetValue(ASource));
    End;
  End
  Else
    Raise EgAssign.CreateFmt('Assignment mismatch between source ''%s'' and destination ''%s'' classes.', [ASource.ClassName, ClassName]);
End;

procedure TgBase.Deserialize(ASerializerClass: TgSerializerClass; const AString: String);
var
  Serializer: TgSerializer;
begin
  Serializer := ASerializerClass.Create;
  try
    Serializer.Deserialize(Self, AString);
  finally
    Serializer.Free;
  end;
end;

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

class function TgBase.FriendlyName: String;
Begin
  if SameText(UnitName, TgBase.UnitName) then
    Result := Copy(ClassName, 3, MaxInt)
  Else
    Result := Copy(ClassName, 2, MaxInt);
End;

function TgBase.GetFriendlyClassName: String;
Begin
  Result := FriendlyName;
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

function TgBase.Serialize(ASerializerClass: TgSerializerClass): String;
var
  Serializer: TgSerializer;
begin
  Serializer := ASerializerClass.Create;
  try
    Result := Serializer.Serialize(Self);
  finally
    Serializer.Free;
  end;
end;

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
    End
    Else If RTTIType.IsInstance And RTTIType.AsInstance.MetaclassType.InheritsFrom(TgSerializationHelper) And Not (RTTIType.AsInstance.MetaclassType = TgSerializationHelper) Then
      InitializeSerializationHelpers(RTTIType);
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
    CanAdd := Not RTTIProperty.IsWritable And IsField(TRTTIInstanceProperty(RTTIProperty).PropInfo^.GetProc);
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
  FSerializationHelpers := TDictionary<TgSerializerClass, TList<TPair<TgBaseClass, TgSerializationHelperClass>>>.Create();
  Initialize;
end;

class destructor G.Destroy;
begin
  FreeAndNil(FSerializationHelpers);
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
  begin
    if Not (RTTIProperty.Visibility = mvPublished) Or Not RTTIProperty.IsReadable Then
      Continue;
    if RTTIProperty.PropertyType.IsInstance then
    Begin
      If Not RTTIProperty.PropertyType.AsInstance.MetaclassType.InheritsFrom(TgBase) Then
        Continue;
    End
    else if Not RTTIProperty.IsWritable Then
      Continue;
    CanAdd := True;
    for Attribute in RTTIProperty.GetAttributes do
    if Attribute.InheritsFrom(ExcludeFeature) And (Serializable in ExcludeFeature(Attribute).FeatureExclusions) then
    begin
      CanAdd := False;
      Continue;
    end;
    if CanAdd then
    begin
      FSerializableProperties.TryGetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
      SetLength(RTTIProperties, Length(RTTIProperties) + 1);
      RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
      FSerializableProperties.AddOrSetValue(TgBaseClass(ARTTIType.AsInstance.MetaclassType), RTTIProperties);
    end;
  end;
End;

class procedure G.InitializeSerializationHelpers(ARTTIType: TRTTIType);
var
  BaseClass: TgBaseClass;
  List: TList<TPair<TgBaseClass, TgSerializationHelperClass>>;
  SerializationHelperClass: TgSerializationHelperClass;
  Pair: TPair<TgBaseClass, TgSerializationHelperClass>;
  SerializerClass: TgSerializerClass;
  Comparer: TgSerializationHelperComparer;
begin
  SerializationHelperClass := TgSerializationHelperClass(ARTTIType.AsInstance.MetaclassType);
  SerializerClass := SerializationHelperClass.SerializerClass;
  BaseClass := TgSerializationHelperClass(ARTTIType.AsInstance.MetaclassType).BaseClass;
  FSerializationHelpers.TryGetValue(SerializerClass, List);
  if Not Assigned(List) then
    List := TList<TPair<TgBaseClass, TgSerializationHelperClass>>.Create;
  Pair.Create(BaseClass, SerializationHelperClass);
  List.Add(Pair);
  Comparer := TgSerializationHelperComparer.Create;
  try
    List.Sort(Comparer);
  finally
    Comparer.Free;
  end;
  FSerializationHelpers.AddOrSetValue(SerializerClass, List);
end;

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

class function G.SerializationHelpers(ASerializerClass: TgSerializerClass; AObject: TgBase): TgSerializationHelperClass;
var
  Pair: TPair<TgBaseClass, TgSerializationHelperClass>;
  List : TList<TPair<TgBaseClass, TgSerializationHelperClass>>;
begin
  Result := Nil;
  FSerializationHelpers.TryGetValue(ASerializerClass, List);
  for Pair in List do
  begin
    if AObject.InheritsFrom(Pair.Key) then
    Begin
      Result := Pair.Value;
      Break;
    End;
  end;
end;

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

constructor TgSerializer.Create;
begin
  inherited Create;
end;

constructor TgSerializerJSON.Create;
begin
  inherited Create;
  FJSONObject := TJSONObject.Create();
end;

destructor TgSerializerJSON.Destroy;
begin
  FreeAndNil(FJSONObject);
  inherited Destroy;
end;

procedure TgSerializerJSON.AddObjectProperty(const APropertyName: string; AObject: TgBase);
var
  SerializationHelperJSONBaseClass: TgSerializationHelperJSONBaseClass;
  Serializer: TgSerializerJSON;
begin
  Serializer := TgSerializerJSON.Create;
  Try
    SerializationHelperJSONBaseClass := TgSerializationHelperJSONBaseClass(G.SerializationHelpers(TgSerializerJSON, AObject));
    SerializationHelperJSONBaseClass.Serialize(AObject, Serializer);
    JSONObject.AddPair(APropertyName, Serializer.JSONObject);
  Finally
    Serializer.JSONObject := Nil;
    Serializer.Free;
  End;
end;

procedure TgSerializerJSON.AddValueProperty(const AName: string; AValue: Variant);
begin
  JSONObject.AddPair(AName, AValue);
end;

procedure TgSerializerJSON.Deserialize(AObject: TgBase; const AString: string);
var
  SerializationHelperJSONBaseClass: TgSerializationHelperJSONBaseClass;
begin
  FreeAndNil(FJSONObject);
  JSONObject := TJSONObject.ParseJSONValue(AString) As TJSONObject;
  SerializationHelperJSONBaseClass := TgSerializationHelperJSONBaseClass(G.SerializationHelpers(TgSerializerJSON, AObject));
  SerializationHelperJSONBaseClass.Deserialize(AObject, JSONObject);
end;

function TgSerializerJSON.Serialize(AObject: TgBase): string;
var
  SerializationHelperJSONBaseClass: TgSerializationHelperJSONBaseClass;
begin
  SerializationHelperJSONBaseClass := TgSerializationHelperJSONBaseClass(G.SerializationHelpers(TgSerializerJSON, AObject));
  SerializationHelperJSONBaseClass.Serialize(AObject, Self);
  Result := JSONObject.ToString;
end;

constructor TgSerializerXML.Create;
begin
  inherited Create;
  FDocument := TXMLDocument.Create(Nil);
  FDocumentInterface := FDocument;
  FDocument.DOMVendor := GetDOMVendor('MSXML');
  FDocument.Options := [doNodeAutoIndent];
end;

procedure TgSerializerXML.AddObjectProperty(const APropertyName: string; AObject: TgBase);
var
  SerializationHelperXMLBaseClass: TgSerializationHelperXMLBaseClass;
begin
  FCurrentNode := CurrentNode.AddChild(APropertyName);
  CurrentNode.Attributes['classname'] := AObject.QualifiedClassName;
  SerializationHelperXMLBaseClass := TgSerializationHelperXMLBaseClass(G.SerializationHelpers(TgSerializerXML, AObject));
  SerializationHelperXMLBaseClass.Serialize(AObject, Self);
  FCurrentNode := CurrentNode.ParentNode;
end;

procedure TgSerializerXML.AddValueProperty(const AName: String; AValue: Variant);
var
  ChildNode: IXMLNode;
begin
  ChildNode := CurrentNode.AddChild(AName);
  ChildNode.Text := AValue;
end;

procedure TgSerializerXML.Deserialize(AObject: TgBase; const AString: String);
var
  SerializationHelperXMLBaseClass: TgSerializationHelperXMLBaseClass;
begin
  Document.LoadFromXML(AString);
  FCurrentNode := Document.DocumentElement.ChildNodes[0];
  SerializationHelperXMLBaseClass := TgSerializationHelperXMLBaseClass(G.SerializationHelpers(TgSerializerXML, AObject));
  SerializationHelperXMLBaseClass.Deserialize(AObject, CurrentNode);
end;

function TgSerializerXML.Serialize(AObject: TgBase): string;
var
  SerializationHelperXMLBaseClass: TgSerializationHelperXMLBaseClass;
begin
  FDocument.Active := True;
  FCurrentNode := Document.AddChild('xml');
  FCurrentNode := CurrentNode.AddChild(AObject.FriendlyClassName);
  CurrentNode.Attributes['classname'] := AObject.QualifiedClassName;
  SerializationHelperXMLBaseClass := TgSerializationHelperXMLBaseClass(G.SerializationHelpers(TgSerializerXML, AObject));
  SerializationHelperXMLBaseClass.Serialize(AObject, Self);
  Result := Document.XML.Text;
end;

function TgSerializationHelperComparer.Compare(const Left, Right: TPair<TgBaseClass, TgSerializationHelperClass>): Integer;
begin
  if Left.Key = Right.Key then
    Result := 0
  Else if Left.Key.InheritsFrom(Right.Key) then
    Result := -1
  Else if Right.Key.InheritsFrom(Left.Key) then
    Result := 1
  Else
    Result := 0;
end;

class function TgSerializationHelperJSONBase.BaseClass: TgBaseClass;
begin
  Result := TgBase;
end;

class procedure TgSerializationHelperJSONBase.Deserialize(AObject: TgBase; AJSONObject: TJSONObject);
var
  JSONClassName: String;
  ObjectProperty: TgBase;
  Pair: TJSONPair;
  RTTIProperty: TRTTIProperty;
  SerializationHelperJSONBaseClass: TgSerializationHelperJSONBaseClass;
begin
  Pair := AJSONObject.Get('ClassName');
  JSONClassName := Pair.JsonValue.Value;
  if Not SameText(JSONClassName, AObject.QualifiedClassName) then
    Raise EgParse.CreateFmt('Expected: %s, Parsed: %s', [AObject.QualifiedClassName, JSONClassName]);
  for Pair in AJSONObject do
  begin
    if SameText(Pair.JsonString.Value, 'ClassName') then
      Continue;
    RTTIProperty := G.PropertyByName(AObject, Pair.JsonString.Value);
    if Not RTTIProperty.PropertyType.IsInstance then
      AObject[Pair.JsonString.Value] := Pair.JsonValue.Value
    Else
    Begin
      ObjectProperty := TgBase(RTTIProperty.GetValue(AObject).AsObject);
      If Assigned(ObjectProperty) And ObjectProperty.InheritsFrom(TgBase) And AObject.Owns(ObjectProperty) Then
      Begin
        SerializationHelperJSONBaseClass := TgSerializationHelperJSONBaseClass(G.SerializationHelpers(TgSerializerJSON, ObjectProperty));
        if Assigned(SerializationHelperJSONBaseClass) then
          SerializationHelperJSONBaseClass.Deserialize(ObjectProperty, TJSONObject(Pair.JsonValue));
      End;
    End;
  end;
end;

class procedure TgSerializationHelperJSONBase.Serialize(AObject: TgBase; ASerializer: TgSerializerJSON);
var
  DoubleValue: Double;
  ObjectProperty: TgBase;
  RTTIProperty: TRTTIProperty;
  Value: String;
begin
  ASerializer.JSONObject.AddPair('ClassName', AObject.QualifiedClassName);
  For RTTIProperty In G.SerializableProperties(AObject) Do
  Begin
    If Not RTTIProperty.PropertyType.IsInstance Then
    Begin
      if (RTTIProperty.PropertyType.TypeKind = tkFloat) then
      Begin
       DoubleValue := RTTIProperty.GetValue(AObject).AsVariant;
       If SameText(RTTIProperty.PropertyType.Name, 'TDate') then
         Value := FormatDateTime('m/d/yyyy', DoubleValue)
       Else if SameText(RTTIProperty.PropertyType.Name, 'TDateTime') then
         Value := FormatDateTime('m/d/yyyy hh:nn:ss', DoubleValue);
      End
      Else
        Value := AObject[RTTIProperty.Name];
      ASerializer.AddValueProperty(RTTIProperty.Name, Value);
    End
    Else
    Begin
      ObjectProperty := TgBase(AObject.Inspect(RTTIProperty));
      If Assigned(ObjectProperty) And ObjectProperty.InheritsFrom(TgBase) Then
        ASerializer.AddObjectProperty(RTTIProperty.Name, ObjectProperty);
    End;
  End;
end;

class function TgSerializationHelperJSONBase.SerializerClass: TgSerializerClass;
begin
  Result := TgSerializerJSON;
end;

class function TgSerializationHelperXMLBase.BaseClass: TgBaseClass;
begin
  Result := TgBase;
end;

class procedure TgSerializationHelperXMLBase.Deserialize(AObject: TgBase; AXMLNode: IXMLNode);
var
  ChildNode: IXMLNode;
  Counter: Integer;
  ObjectProperty: TgBase;
  RTTIProperty: TRTTIProperty;
  SerializationHelperXMLBaseClass: TgSerializationHelperXMLBaseClass;
begin
  if Not SameText(AXMLNode.Attributes['classname'], AObject.QualifiedClassName) then
    Raise EgParse.CreateFmt('Expected: %s, Parsed: %s', [AObject.QualifiedClassName, AXMLNode.Attributes['classname']]);
  for Counter := 0 to AXMLNode.ChildNodes.Count - 1 do
  begin
    ChildNode := AXMLNode.ChildNodes[Counter];
    RTTIProperty := G.PropertyByName(AObject, ChildNode.NodeName);
    if Not RTTIProperty.PropertyType.IsInstance then
      AObject[ChildNode.NodeName] := ChildNode.ChildNodes.First.Text
    Else
    Begin
      ObjectProperty := TgBase(RTTIProperty.GetValue(AObject).AsObject);
      If Assigned(ObjectProperty) And ObjectProperty.InheritsFrom(TgBase) And AObject.Owns(ObjectProperty) Then
      Begin
        SerializationHelperXMLBaseClass := TgSerializationHelperXMLBaseClass(G.SerializationHelpers(TgSerializerXML, ObjectProperty));
        SerializationHelperXMLBaseClass.Deserialize(ObjectProperty, ChildNode);
      End;
    End;
  end;
end;

class procedure TgSerializationHelperXMLBase.Serialize(AObject: TgBase; ASerializer: TgSerializerXML);
var
  DoubleValue: Double;
  ObjectProperty: TgBase;
  RTTIProperty: TRTTIProperty;
  Value: String;
begin
  For RTTIProperty In G.SerializableProperties(AObject) Do
  Begin
    if RTTIProperty.PropertyType.IsInstance then
    Begin
      ObjectProperty := TgBase(AObject.Inspect(RTTIProperty));
      If Assigned(ObjectProperty) And ObjectProperty.InheritsFrom(TgBase) Then
        ASerializer.AddObjectProperty(RTTIProperty.Name, ObjectProperty);
    End
    Else
    Begin
      if (RTTIProperty.PropertyType.TypeKind = tkFloat) then
      Begin
       DoubleValue := RTTIProperty.GetValue(AObject).AsVariant;
       If SameText(RTTIProperty.PropertyType.Name, 'TDate') then
         Value := FormatDateTime('m/d/yyyy', DoubleValue)
       Else if SameText(RTTIProperty.PropertyType.Name, 'TDateTime') then
         Value := FormatDateTime('m/d/yyyy hh:nn:ss', DoubleValue);
      End
      Else
        Value := AObject[RTTIProperty.Name];
      ASerializer.AddValueProperty(RTTIProperty.Name, Value);
    End
  End;
end;

class function TgSerializationHelperXMLBase.SerializerClass: TgSerializerClass;
begin
  Result := TgSerializerXML;
end;

Constructor TgList.Create(AOwner : TgBase = Nil);
Begin
  Inherited Create(AOwner);
  FList := TObjectList.Create;
  FCurrentIndex := -1;
End;

Destructor TgList.Destroy;
Begin
  Inherited;
  FList.Free;
End;

Procedure TgList.Add;
Begin
  FCurrentIndex := FList.Add(ItemClass.Create(Self));
End;

Procedure TgList.Delete;
Begin
  FList.Delete(CurrentIndex);
End;

Function TgList.DoGetValues(Const APath : String; Out AValue : Variant) : Boolean;
Var
  Index : Integer;
  IndexString : String;
  Position : Integer;
Begin
  Result := Inherited DoGetValues(APath, AValue);
  If Not Result Then
  Begin
    If (Length(APath) > 0) And (APath[1] = '[') Then
    Begin
      Position := Pos(']', APath);
      If Not (Position > 0) Then
        EgList.CreateFmt('Array not terminated in path ''%s''.', [APath]);
      IndexString := Trim(Copy(APath, 2, Position - 2));
      If Not TryStrToInt(IndexString, Index) Then
        EgList.CreateFmt('''%s'' is not a valid index value.', [IndexString]);
      CurrentIndex := Index;
      Result := True;
      AValue := Current.Values[Copy(APath, Position + 2, MaxInt)];
    End;
  End;
End;

Function TgList.DoSetValues(Const APath : String; AValue : Variant) : Boolean;
Var
  Index : Integer;
  IndexString : String;
  Position : Integer;
Begin
  Result := Inherited DoSetValues(APath, AValue);
  If Not Result Then
  Begin
    If (Length(APath) > 0) And (APath[1] = '[') Then
    Begin
      Position := Pos(']', APath);
      If Not (Position > 0) Then
        EgList.CreateFmt('Array not terminated in path ''%s''.', [APath]);
      IndexString := Trim(Copy(APath, 2, Position - 1));
      If Not TryStrToInt(IndexString, Index) Then
        EgList.CreateFmt('''%s'' is not a valid index value.', [IndexString]);
      CurrentIndex := Index;
      Result := True;
      Current.Values[Copy(APath, Position + 2, MaxInt)] := AValue;
    End;
  End;
End;

Procedure TgList.First;
Begin
  FCurrentIndex := -1;
End;

function TgList.GetBOL: Boolean;
Begin
  Result := Min(FCurrentIndex, FList.Count - 1) = - 1;
End;

function TgList.GetCanAdd: Boolean;
Begin
  Result := True;
End;

function TgList.GetCanNext: Boolean;
Begin
  Result := (Count > 1) And InRange(FCurrentIndex, - 1, Count - 2);
End;

function TgList.GetCanPrevious: Boolean;
Begin
  Result := (Count > 1) And (FCurrentIndex > 0);
End;

function TgList.GetCount: Integer;
Begin
  Result := FList.Count;
End;

function TgList.GetCurrent: TgBase;
Begin
  Result := TgBase(FList[CurrentIndex]);
End;

function TgList.GetCurrentIndex: Integer;
Begin
  If FList.Count > 0 Then
    Result := EnsureRange(FCurrentIndex, 0, FList.Count - 1)
  Else
    Result := - 1;
End;

function TgList.GetEOL: Boolean;
Begin
  Result := Max(FCurrentIndex, 0) = FList.Count;
End;

function TgList.GetItemClass: TgBaseClass;
begin
  Result := FItemClass;
end;

function TgList.GetItems(AIndex : Integer): TgBase;
Begin
  Result := TgBase(FList[AIndex]);
End;

Procedure TgList.Last;
Begin
  FCurrentIndex := FList.Count;
End;

Procedure TgList.Next;
Begin
  If FCurrentIndex < - 1 Then
    FCurrentIndex := CurrentIndex - 1
  Else If FCurrentIndex < FList.Count Then
    FCurrentIndex := CurrentIndex + 1
  Else
    Raise EgList.Create('Failed attempt to move past end of list.');
End;

Procedure TgList.Previous;
Begin
  If FCurrentIndex > FList.Count Then
    FCurrentIndex := CurrentIndex + 1
  Else If FCurrentIndex > - 1 Then
    FCurrentIndex := CurrentIndex - 1
  Else
    Raise EgList.Create('Failed attempt to move before beginning of list.');
End;

procedure TgList.SetCurrentIndex(const AIndex: Integer);
Begin
  If (FList.Count > 0) And InRange(AIndex, - 1, FList.Count) Then
    FCurrentIndex := AIndex
  Else
    Raise EgList.CreateFmt('Failed to set CurrentIndex to %d, because the valid range is between 0 and %d.', [AIndex, FList.Count - 1]);
End;

procedure TgList.SetItemClass(const Value: TgBaseClass);
begin
  FItemClass := Value;
end;

procedure TgList.SetItems(AIndex : Integer; const AValue: TgBase);
Begin
  FList[AIndex] := AValue;
End;

procedure TgList.Clear;
begin
  FList.Clear;
  FCurrentIndex := -1;
end;

function TgList.GetEnumerator: TgListEnumerator;
Begin
  Result := TgListEnumerator.Create(Self);
End;

procedure TgList.Execute(AgBaseProcedure: TgBaseProcedure);
var
  Item: TgBase;
begin
  for Item in Self do
    AgBaseProcedure(Item);
end;

procedure TgList.Filter;
begin
{
  If Not IsFiltered And ( Where > '' ) Then
  Begin
    Last;
    While Not BOL Do
    Begin
      If Not Eval( Where, Current ) Then
        Delete;
      Previous;
    End;
    IsFiltered := True;
  End;
}
end;

function TgList.GetHasItems: Boolean;
begin
  Result := Count > 0;
end;

function TgList.GetIsFiltered: Boolean;
begin
  Result := gosFiltered In FObjectStates;
end;

procedure TgList.SetIsFiltered(const AValue: Boolean);
begin
  If AValue Then
    Include(FObjectStates, gosFiltered)
  Else
    Exclude(FObjectStates, gosFiltered);
end;

procedure TgList.SetWhere(const AValue: String);
begin
  FWhere := AValue;
end;

procedure TgList.SetOrderBy(const AValue: String);
begin
  FOrderBy := AValue;
end;

procedure TgList.Sort;
begin
  // TODO -cMM: TgList.Sort default body inserted
end;

constructor TgListEnumerator.Create(AList: TgList);
begin
  FList := AList;
  FCurrentIndex := -1;
end;

function TgListEnumerator.GetCurrent: TgBase;
var
  SavedCurrentIndex: Integer;
begin
  SavedCurrentIndex := FList.CurrentIndex;
  FList.CurrentIndex := FCurrentIndex;
  Result := FList.Current;
  FList.CurrentIndex := SavedCurrentIndex;
end;

function TgListEnumerator.MoveNext: Boolean;
var
  SavedCurrentIndex: Integer;
begin
  If FList.Count = 0 Then
  Begin
    Result := False;
    Exit;
  End;
  Inc( FCurrentIndex );
  SavedCurrentIndex := FList.CurrentIndex;
  FList.CurrentIndex := FCurrentIndex;
  Result := Not FList.EOL;
  FList.CurrentIndex := SavedCurrentIndex;
end;

Initialization
  TgSerializationHelperXMLBase.BaseClass;
  TgSerializationHelperJSONBase.BaseClass;

end.
