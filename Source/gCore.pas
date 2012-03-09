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
  Contnrs,
  System.Classes,
  gExpressionConstants,
  gExpressionLiterals,
  gExpressionOperators,
  gExpressionFunctions
;

type
  TCustomAttributeClass = class of TCustomAttribute;
  TgBaseClass = class of TgBase;
  {$M+}
  TgBase = class;
  {$M-}

  TgList = class;
  TgObject = class;
  TgPropertyAttribute = class(TCustomAttribute)
  strict private
    FRTTIProperty: TRTTIProperty;
  public
    property RTTIProperty: TRTTIProperty read FRTTIProperty write FRTTIProperty;
  end;

  TgFeature = (AutoCreate, Serializable, Visible, Composite);
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
  public
    type
      /// <summary>
      /// Raised when a <see cref="TgBase" /> is assigned to another <see cref="TgBase"
      /// /> and there is a failure in that process
      /// </summary>
      EgAssign = class(Exception)
      end;
      /// <summary>
      ///   Used to return a path error for <see cref="TgBase.DoGetValues" /> and <see
      ///   cref="TgBase.DoSetValues" /> used by the <see cref="TgBase.Values" />
      ///
      /// </summary>
      EgValue = class(Exception)
      end;

  strict private
    FOwner: TgBase;
  strict protected
    function DoGetValues(Const APath : String; Out AValue : Variant): Boolean; virtual;
    function DoSetValues(Const APath : String; AValue : Variant): Boolean; virtual;
    function GetIsInspecting: Boolean; virtual;
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
    procedure SetIsInspecting(const AValue: Boolean); virtual;
    procedure SetValues(Const APath : String; AValue : Variant); virtual;
  public
    /// <summary>TgBase.Create instantiates a new G object, sets its owner and
    /// automatically
    /// instantiates any object properties descending from TgBase that don't have the
    /// ExcludeFeature
    /// attribute with an AutoCreate</summary>
    /// <param name="AOwner"> (TgBase) </param>
    constructor Create(AOwner: TgBase = Nil); virtual;
    procedure Assign(ASource : TgBase); virtual;
    procedure Deserialize(ASerializerClass: TgSerializerClass; const AString: String);
    class function FeatureExclusions(ARTTIProperty: TRTTIProperty): TgFeatureExclusions; virtual;
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

    ///	<summary>
    ///	  This property is used to get and set values for any published
    ///	  property on this structure or any <see cref="TgBase" /> structure
    ///	  owned by a published class property
    ///	</summary>
    ///	<param name="APath">
    ///	  Local properties are just their name, but when using this on a
    ///	  <see cref="TgBase" /> class decendant
    ///	</param>
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

  TgList<T: TgBase> = class;

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

  Validation = class(TCustomAttribute)
  public
    procedure Execute(AObject: TgObject; ARTTIProperty: TRTTIProperty); virtual; abstract;
  end;

  TgPropertyValidationAttribute = record
  public
    RTTIProperty: TRTTIProperty;
    ValidateAttribute: Validation;
    procedure Execute(AObject: TgObject);
  End;

  G = class(TObject)
  strict private
  class var
    FAttributes: TDictionary<TPair<TgBaseClass, TCustomAttributeClass>, TArray<TCustomAttribute>>;
    FAutoCreateProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FCompositeProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FDisplayPropertyNames: TDictionary<TgBaseClass, TArray<String>>;
    FMethodByName: TDictionary<String, TRTTIMethod>;
    FObjectProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FPersistableProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
    FPropertyByName: TDictionary<String, TRTTIProperty>;
    FPropertyValidationAttributes: TDictionary<TgBaseClass, TArray<TgPropertyValidationAttribute>>;
    FRecordProperty: TDictionary<TRTTIProperty, TgRecordProperty>;
    FRTTIContext: TRTTIContext;
    FSerializableProperties: TDictionary < TgBaseClass, TArray < TRTTIProperty >>;
    FSerializationHelpers: TDictionary<TgSerializerClass, TList<TPair<TgBaseClass, TgSerializationHelperClass>>>;
    FClassValidationAttributes: TDictionary<TgBaseClass, TArray<Validation>>;
    FVisibleProperties: TDictionary<TgBaseClass, TArray<TRTTIProperty>>;
  var
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
    class procedure InitializeCompositeProperties(ARTTIType: TRTTIType); static;
    class procedure InitializeDisplayPropertyNames(ARTTIType: TRTTIType); static;
    class procedure InitializeMethodByName(ARTTIType: TRTTIType); static;
    class procedure InitializeObjectProperties(ARTTIType: TRTTIType); static;
    class procedure InitializeProperties(ARTTIType: TRTTIType); static;
    class procedure InitializePropertyByName(ARTTIType: TRTTIType); static;
    class procedure InitializeRecordProperty(ARTTIType: TRTTIType); static;
    class procedure InitializeSerializableProperties(ARTTIType : TRttiType); static;
    class procedure InitializeSerializationHelpers(ARTTIType: TRTTIType); static;
    class procedure InitializeVisibleProperties(ARTTIType: TRTTIType); static;
  public
    class constructor Create;
    class destructor Destroy;
    class function Attributes(ABaseClass: TgBaseClass; AAttributeClass: TCustomAttributeClass): TArray<TCustomAttribute>; overload; static;
    class function Attributes(ABase: TgBase; AAttributeClass: TCustomAttributeClass): Tarray<TCustomAttribute>; overload; static;
    class function AutoCreateProperties(AInstance: TgBase): TArray<TRTTIProperty>; overload; static; inline;
    class function AutoCreateProperties(AClass: TgBaseClass): TArray<TRTTIProperty>; overload; static;
    class function CompositeProperties(AClass: TgBaseClass): TArray<TRTTIProperty>; overload; static;
    class function CompositeProperties(ABase: TgBase): TArray<TRTTIProperty>; overload; static;
    class function DisplayPropertyNames(AClass: TgBaseClass): TArray<String>; static;
    class procedure InitialializePersistableProperties(ARTTIType: TRTTIType); static;
    class procedure InitializePropertyValidationAttributes(ARTTIType: TRTTIType); static;
    class function MethodByName(ABaseClass: TgBaseClass; const AName: String): TRTTIMethod; overload; static;
    class function MethodByName(ABase: TgBase; const AName: String): TRTTIMethod; overload; static;
    class function ObjectProperties(AInstance: TgBase): TArray<TRTTIProperty>; overload; static; inline;
    class function ObjectProperties(AClass: TgBaseClass): TArray<TRTTIProperty>; overload; static; inline;
    class function PersistableProperties(ABaseClass: TgBaseClass): TArray<TRTTIProperty>; overload; static;
    class function PersistableProperties(ABase: TgBase): TArray<TRTTIProperty>; overload; static;
    class function Properties(AClass: TgBaseClass): TArray<TRTTIProperty>; static;
    class function PropertyByName(AClass: TgBaseClass; const AName: String): TRTTIProperty; overload; static;
    class function PropertyByName(ABase: TgBase; const AName: String): TRTTIProperty; overload; static;
    class function PropertyValidationAttributes(ABaseClass: TgBaseClass): TArray<TgPropertyValidationAttribute>; overload; static;
    class function PropertyValidationAttributes(ABase: TgBase): TArray<TgPropertyValidationAttribute>; overload; static;
    class function RecordProperty(ARTTIProperty: TRTTIProperty): TgRecordProperty; static;
    class function SerializableProperties(ABase: TgBase): TArray<TRTTIProperty>; overload; inline;
    class function SerializableProperties(AClass : TgBaseClass): TArray<TRTTIProperty>; overload;
    class function SerializationHelpers(ASerializerClass: TgSerializerClass; AObject: TgBase): TgSerializationHelperClass; static;
    class function ClassValidationAttributes(AClass: TgBaseClass): TArray<Validation>; overload; static;
    class function ClassValidationAttributes(ABase: TgBase): TArray<Validation>; overload; static;
    class function VisibleProperties(ABaseClass: TgBaseClass): TArray<TRTTIProperty>; static;
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

  TgOrderByItem = class(TObject)
  public
    type
      EgOrderByItem = class(Exception);
  strict private
    FDescending: Boolean;
    FPropertyName: String;
  public
    constructor Create(const AItemText: String);
    property Descending: Boolean read FDescending write FDescending;
    property PropertyName: String read FPropertyName write FPropertyName;
  end;

  ///	<summary>
  ///	  This class will be used to cursor through a list of
  ///	  <see cref="gCore|TgBase" /> classes and will also be used to support
  ///	  selection lists in the user Interface
  ///	</summary>
  ///	<remarks>
  ///	  <para>
  ///	    This maintains a cursor in the list of
  ///	    <see cref="gCore|TgList.Current">Current</see> and can be moved by
  ///	    setting the <see cref="gCore|TgList.CurrentIndex">CurrentIndex</see>,
  ///	    and the Count Property will tell you how many items are in the list
  ///	  </para>
  ///	  <para>
  ///	    Filtering is achived by using the
  ///	    <see cref="gCore|TgList.Where">Where</see> property and Sorting can
  ///	    be achived by setting the
  ///	    <see cref="gCore|TgList.OrderBy">OrderBy</see> property.
  ///	  </para>
  ///	  <para>
  ///	    To Check status or Change the Current  Item use:
  ///	  </para>
  ///	  <para>
  ///	    <ul><li><see cref="gCore|TgList.First">First</see></li><li><see cref="gCore|TgList.Last">Last</see></li><li><see cref="gCore|TgList.Next">Next</see>, <see cref="gCore|TgList.CanNext">CanNext</see>, <see cref="gCore|TgList.EOL">EOL</see></li><li><see cref="gCore|TgList.Previous">Previous</see>, <see cref="gCore|TgList.CanPrevious">CanPrevious</see>,
  ///	    <see cref="gCore|TgList.BOL">BOL</see></li><li><see cref="gCore|TgList.HasItems">HasItems</see></li>
  ///     </ul>
  ///	  </para>
  ///	  <para>
  ///	    To use Add to append a new item or Delete to remove the current Item
  ///	  </para>
  ///	</remarks>
 ///  <seealso cref="gCore|TgList{T}" />
  TgList = class(TgBase)
    Type
      TState = (lsInspecting, lsOrdered, lsFiltered);
      TStates = Set of TState;

      /// <summary> Structure used by the <see cref="GetEnumerator" /> to allow For-in
      /// loops</summary>
      TgEnumerator = record
      private
        FCurrentIndex: Integer;
        FList: TgList;
        SavedCurrentIndex: Integer;
        function GetCurrent: TgBase;
      public
        procedure Init(AList: TgList);
        function MoveNext: Boolean;
        property Current: TgBase read GetCurrent;
      End;

      /// <summary> Internal structure used by the <see cref="OrderBy" />  to sort the items contained in this list
      /// </summary>
      TgComparer = class(TComparer<TgBase>)
      strict private
        FOrderByList: TObjectList<TgOrderByItem>;
      public
        constructor Create(AOrderByList: TObjectList<TgOrderByItem>);
        function Compare(const Left, Right: TgBase): Integer; override;
      end;

  strict private
    FFilteredList: TList<TgBase>;
    FItemClass: TgBaseClass;
    FList: TObjectList<TgBase>;
    FOrderBy: String;
    FOrderByList: TObjectList<TgOrderByItem>;
    FWhere: String;
    FStates: TStates;
    function GetIsFiltered: Boolean;
    function GetIsOrdered: Boolean;
    function GetList: TList<TgBase>;
    function GetOrderByList: TObjectList<TgOrderByItem>;
    procedure SetIsFiltered(const AValue: Boolean);
    procedure SetIsOrdered(const AValue: Boolean);
  private
    FCurrentIndex: Integer;
  strict protected
    function DoGetValues(Const APath : String; Out AValue : Variant): Boolean; override;
    function DoSetValues(Const APath : String; AValue : Variant): Boolean; override;
    function GetBOL: Boolean; virtual;
    function GetCanAdd: Boolean; virtual;
    function GetCanNext: Boolean; virtual;
    function GetCanPrevious: Boolean; virtual;
    function GetCount: Integer; virtual;
    function GetCurrent: TgBase;
    function GetCurrentIndex: Integer; virtual;
    function GetEOL: Boolean; virtual;
    function GetHasItems: Boolean; virtual;
    function GetIsInspecting: Boolean; override;
    function GetItemClass: TgBaseClass; virtual;
    function GetItems(AIndex : Integer): TgBase; virtual;
    procedure SetCurrentIndex(const AIndex: Integer); virtual;
    procedure SetIsInspecting(const AValue: Boolean); override;
    procedure SetItemClass(const Value: TgBaseClass); virtual;
    procedure SetItems(AIndex : Integer; const AValue: TgBase); virtual;
    procedure SetOrderBy(const AValue: String); virtual;
    procedure SetWhere(const AValue: String); virtual;
  public
    type
      /// <summary> This is the general exception for a <see cref="TgList" />
      /// </summary>
      EgList = class(Exception);
    constructor Create(AOwner: TgBase = Nil); override;
    destructor Destroy; override;
    procedure Assign(ASource: TgBase); override;
    procedure Clear; virtual;

    ///	<summary>
    ///	  In combination with the <see cref="where" /> property this will create a sub list of
    ///	  the main list to cursor through.
    ///	</summary>
    procedure Filter; virtual;
    function GetEnumerator: TgEnumerator;
    procedure Sort;
    property IsFiltered: Boolean read GetIsFiltered write SetIsFiltered;
    property IsOrdered: Boolean read GetIsOrdered write SetIsOrdered;
    property ItemClass: TgBaseClass read GetItemClass write SetItemClass;
    property Items[AIndex : Integer]: TgBase read GetItems write SetItems; default;
    property OrderByList: TObjectList<TgOrderByItem> read GetOrderByList;
  published
    procedure Add; overload; virtual;
    procedure Delete; virtual;
    procedure First; virtual;
    procedure Last; virtual;
    procedure Next; virtual;
    procedure Previous; virtual;
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
    property List: TList<TgBase> read GetList;
    [ExcludeFeature([Serializable])]
    property OrderBy: String read FOrderBy write SetOrderBy;
    ///	<summary>
    ///	  After setting this property with a proper value you'll need to use
    ///	  the <see cref="Filter" /> method to create the new filtered list
    ///	</summary>
    /// <example>
    ///	  <code lang="Delphi">
    ///  type
    ///    TgMine = class(TgCore)
    ///    private
    ///      FID: Integer;
    ///    published
    ///      property ID: Integer read FID write FID;
    ///    end;
    ///	 var List: TgList;
    ///  begin
    ///    List := TgList;
    ///    List.ItemClass := TgMine;
    ///    List.Where := 'ID = 12';
    ///    List.Filter;
    ///    List.Free;
    ///  end;
    ///	  </code>
    /// </example>
    [ExcludeFeature([Serializable])]
    property Where: String read FWhere write SetWhere;
  end;


 ///	<summary>
 ///	  Decendant class of <see cref="gCore|TgList" /> but the
 ///	  <see cref="gCore|TgList{T}.Current">Current</see>
 ///	  property as well as the for in operator will be native types
 ///	  of T as well as introducing a <see cref="gCore|TgList{T}.Items">Items</see> property
 ///	</summary>
 ///	<typeparam name="T">
 ///	  would be the decendant class of <see cref="gCore|TgBase">TgBase</see> to be Managed by this list
 ///	</typeparam>
 ///  <seealso cref="gCore|TgList">TgList</seealso>
 TgList<T: TgBase> = class(TgList)
  Public
    type
      EgList = class(Exception);
  Strict Protected
    type

      /// <summary> Structure used by the <see cref="GetEnumerator" /> to allow For-in
      /// loops.</summary>
      /// <remarks> This Enumerator is necessary because of the generic type of the <see
      /// cref="TgList{T}" />
      ///
      /// </remarks>
      TgEnumerator = record
      private
        FCurrentIndex: Integer;
        FList: TgList<T>;
        SavedCurrentIndex: Integer;
        function GetCurrent: T;
      public
        procedure Init(AList: TgList<T>);
        function MoveNext: Boolean;
        property Current: T read GetCurrent;
      End;
    function GetCurrent: T;
    function GetItems(AIndex : Integer): T; reintroduce; virtual;
    procedure SetItems(AIndex : Integer; const AValue: T); reintroduce; virtual;
    function GetItemClass: TgBaseClass; override;
  Public
    class function FeatureExclusions(ARTTIProperty: TRttiProperty): TgFeatureExclusions; override;
    function GetEnumerator: TgEnumerator;
    property Items[AIndex : Integer]: T read GetItems write SetItems; default;
  Published
    property Current: T read GetCurrent;
  End;

  TgSerializationHelperXMLList = class(TgSerializationHelperXMLBase)
  public
    class function BaseClass: TgBaseClass; override;
    class procedure Deserialize(AObject: TgBase; AXMLNode: IXMLNode); override;
    class procedure Serialize(AObject: TgBase; ASerializer: TgSerializerXML); override;
  end;

  TgSerializationHelperJSONList = class(TgSerializationHelperJSONBase)
  public
    class function BaseClass: TgBaseClass; override;
    class procedure Serialize(AObject: TgBase;ASerializer: TgSerializerJSON); override;
    class procedure Deserialize(AObject: TgBase; AJSONObject: TJSONObject); override;
  end;

  TgBaseClassComparer = class(TComparer<TRTTIType>)
    function Compare(const Left, Right: TRTTIType): Integer; override;
  end;

  TgValidationErrors = class(TgBase)
  strict private
    FDictionary: TDictionary<String, String>;
    function GetCount: Integer;
    function GetHasItems: Boolean;
  strict protected
    function DoGetValues(const APath: string; out AValue: Variant): Boolean; override;
    function DoSetValues(const APath: string; AValue: Variant): Boolean; override;
  public
    constructor Create(AOwner: TgBase = Nil); override;
    destructor Destroy; override;
    procedure Clear;
    procedure PopulateList(AStringList: TStrings);
  published
    property Count: Integer read GetCount;
    property HasItems: Boolean read GetHasItems;
  end;

  TgObjectClass = class of TgObject;
  TgObject = class(TgBase)
    type
      TState = (osInspecting, osOriginalValues, osLoaded, osLoading, osSaving, osDeleting);
      TStates = Set Of TState;
  strict private
    FOriginalValues: TgObject;
    FStates: TStates;
    FValidationErrors: TgValidationErrors;
    function GetIsOriginalValues: Boolean;
    function GetOriginalValues: TgBase;
    function GetValidationErrors: TgValidationErrors;
    procedure PopulateDefaultValues;
    procedure SetIsOriginalValues(const AValue: Boolean);
  strict protected
    /// <summary>TgObject.AutoCreate gets called by the Create constructor to instantiate
    /// object properties. You may override this method in a descendant class to alter
    /// its behavior.
    /// </summary>
    procedure AutoCreate; virtual;
    function GetDisplayName: String; virtual;
    function GetIsModified: Boolean; virtual;
    function GetIsValid: Boolean; virtual;
    procedure GetIsValidInternal; virtual;
    function GetIsInspecting: Boolean; override;
    procedure SetIsInspecting(const AValue: Boolean); override;
  public
    constructor Create(AOwner: TgBase = nil); override;
    destructor Destroy; override;
    function AllValidationErrors: String;
    class function DisplayPropertyNames: TArray<String>; inline;
    function HasValidationErrors: Boolean;
    procedure InitializeOriginalValues; virtual;
    function IsPropertyModified(ARTTIProperty: TRttiProperty): Boolean; overload;
    function IsPropertyModified(const APropertyName: string): Boolean; overload;
    property IsModified: Boolean read GetIsModified;
    property IsOriginalValues: Boolean read GetIsOriginalValues write SetIsOriginalValues;
    property IsValid: Boolean read GetIsValid;
  published
    [ExcludeFeature([Visible])]
    property DisplayName: String read GetDisplayName;
    [ExcludeFeature([AutoCreate, Composite, Serializable, Visible])]
    property OriginalValues: TgBase read GetOriginalValues;
    [ExcludeFeature([AutoCreate, Composite, Serializable, Visible])]
    property ValidationErrors: TgValidationErrors read GetValidationErrors;
  end;

  DisplayPropertyNames = class(TCustomAttribute)
  strict private
    FValue: TArray<String>;
  public
    constructor Create(AValue: TArray<String>);
    property Value: TArray<String> read FValue;
  end;

  EgValidation = class(Exception)
  end;

  Required = class(Validation)
  strict private
    FEnabled: Boolean;
  public
    constructor Create(AEnabled: Boolean = True);
    procedure Execute(AObject: TgObject; ARTTIProperty: TRTTIProperty); override;
    property Enabled: Boolean read FEnabled;
  end;

procedure SplitPath(Const APath : String; Out AHead, ATail : String);

implementation

Uses
  TypInfo,
  Variants,
  XML.XMLDOM,
  Math,
  gExpressionEvaluator
;

Const
{$IFDEF CPUX86}
  PROPSLOT_MASK    = $FF000000;
{$ENDIF CPUX86}
{$IFDEF CPUX64}
  PROPSLOT_MASK    = $FF00000000000000;
{$ENDIF CPUX64}

type
  TgBaseExpressionEvaluator = Class(TgExpressionEvaluator)
  Strict Private
    FModel : TgBase;
  Strict Protected
    Function GetValue(Const AVariableName : String) : Variant; Override;
  Public
    Constructor Create(AModel : TgBase); Reintroduce; Virtual;
  End;

Function Eval(Const AExpression : String; ABase : TgBase) : Variant;
Var
  ExpressionEvaluator : TgBaseExpressionEvaluator;
Begin
  ExpressionEvaluator := TgBaseExpressionEvaluator.Create(ABase);
  Try
    Result := ExpressionEvaluator.Evaluate(AExpression);
  Finally
    ExpressionEvaluator.Free;
  End;
End;

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

class function TgBase.FeatureExclusions(ARTTIProperty: TRTTIProperty): TgFeatureExclusions;
var
  Attribute: TCustomAttribute;
begin
  Result := [];
  for Attribute in ARTTIProperty.GetAttributes do
  Begin
    if Attribute.InheritsFrom(ExcludeFeature) Then
      Result := Result + ExcludeFeature(Attribute).FeatureExclusions;
  End;
end;

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
begin
  Result := False;
end;

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

procedure TgBase.SetIsInspecting(const AValue: Boolean);
begin

end;

procedure TgBase.SetValues(Const APath : String; AValue : Variant);
Begin
  If Not DoSetValues(APath, AValue) Then
    Raise EgValue.CreateFmt('Path ''%s'' not found.', [APath]);
End;

class procedure G.Initialize;
var
  BaseTypes: TList<TRTTIType>;
  RTTIType: TRTTIType;
  Comparer: TgBaseClassComparer;
begin
  //Make sure the types are in ancestral order
  BaseTypes := TList<TRTTIType>.Create;
  try
    for RTTIType in FRTTIContext.GetTypes do
    if RTTIType.IsInstance And RTTIType.AsInstance.MetaclassType.InheritsFrom(TgBase) then
      BaseTypes.Add(RTTIType);
    Comparer := TgBaseClassComparer.Create;
    try
      BaseTypes.Sort(Comparer);
    finally
      Comparer.Free;
    end;
    //Then initialize the structure caches
    for RTTIType in BaseTypes do
    begin
      InitializeProperties(RTTIType);
      InitializeAttributes(RTTIType);
      InitializeObjectProperties(RTTIType);
      InitializeAutoCreateProperties(RTTIType);
      InitializePropertyByName(RTTIType);
      InitializeMethodByName(RTTIType);
      InitializeRecordProperty(RTTIType);
      InitializeSerializableProperties(RTTIType);
      InitializeCompositeProperties(RTTIType);
      InitializeVisibleProperties(RTTIType);
      InitializeDisplayPropertyNames(RTTIType);
      InitializePropertyValidationAttributes(RTTIType);
    end;
  finally
    BaseTypes.Free;
  end;
  for RTTIType in FRTTIContext.GetTypes do
  begin
    If RTTIType.IsInstance And RTTIType.AsInstance.MetaclassType.InheritsFrom(TgSerializationHelper) And Not (RTTIType.AsInstance.MetaclassType = TgSerializationHelper) Then
      InitializeSerializationHelpers(RTTIType);
  end;
end;

class procedure G.InitializeAttributes(ARTTIType: TRTTIType);
var
  Attribute: TCustomAttribute;
  Pair : TPair<TgBaseClass, TCustomAttributeClass>;
  Attributes : TArray<TCustomAttribute>;
  RTTIProperty: TRTTIProperty;
  ClassValidationAttributes : TArray<Validation>;

  procedure AddAttribute;
  begin
    Pair.Key := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
    Pair.Value := TCustomAttributeClass(Attribute.ClassType);
    FAttributes.TryGetValue(Pair, Attributes);
    SetLength(Attributes, Length(Attributes) + 1);
    Attributes[Length(Attributes) - 1] := Attribute;
    FAttributes.AddOrSetValue(Pair, Attributes);

    if Not Assigned (RTTIProperty) And Attribute.InheritsFrom(Validation) then
    Begin
      FClassValidationAttributes.TryGetValue(Pair.Key, ClassValidationAttributes);
      SetLength(ClassValidationAttributes, Length(Attributes) + 1);
      ClassValidationAttributes[Length(Attributes) - 1] := Validation(Attribute);
      FClassValidationAttributes.AddOrSetValue(Pair.Key, ClassValidationAttributes);
    End;

  end;

begin
  // Add Class Attributes
  RTTIProperty := Nil;
  for Attribute in ARTTIType.GetAttributes do
    AddAttribute;
  // Add Property Attributes
  for RTTIProperty in Properties(TgBaseClass(ARTTIType.AsInstance.MetaclassType)) do
  if RTTIProperty.Visibility = mvPublished then
  begin
    for Attribute in RTTIProperty.GetAttributes do
    begin
      if Attribute.InheritsFrom(TgPropertyAttribute) then
        TgPropertyAttribute(Attribute).RTTIProperty := RTTIProperty;
      AddAttribute;
    end;
  end;
end;

class procedure G.InitializeAutoCreateProperties(ARTTIType: TRTTIType);
Var
  RTTIProperty : TRTTIProperty;
  BaseClass: TgBaseClass;
  RTTIProperties: TArray<TRTTIProperty>;
Begin
  BaseClass := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
  for RTTIProperty in G.ObjectProperties(BaseClass) do
  begin
    If Not RTTIProperty.IsWritable And IsField(TRTTIInstanceProperty(RTTIProperty).PropInfo^.GetProc) And Not (AutoCreate In BaseClass.FeatureExclusions(RTTIProperty)) Then
    Begin
      FAutoCreateProperties.TryGetValue(BaseClass, RTTIProperties);
      SetLength(RTTIProperties, Length(RTTIProperties) + 1);
      RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
      FAutoCreateProperties.AddOrSetValue(BaseClass, RTTIProperties);
    End;
  end;
end;

class procedure G.InitializeObjectProperties(ARTTIType: TRTTIType);
Var
  RTTIProperty : TRTTIProperty;
  RTTIProperties: TArray<TRTTIProperty>;
Begin
  for RTTIProperty in G.Properties(TgBaseClass(ARTTIType.AsInstance.MetaclassType)) do
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
  FProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FAttributes := TDictionary<TPair<TgBaseClass, TCustomAttributeClass>, TArray<TCustomAttribute>>.Create();
  FObjectProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FAutoCreateProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FPropertyByName := TDictionary<String, TRTTIProperty>.Create();
  FMethodByName := TDictionary<String, TRTTIMethod>.Create();
  FSerializableProperties := TDictionary < TgBaseClass, TArray < TRTTIProperty >>.Create();
  FRecordProperty := TDictionary<TRTTIProperty, TgRecordProperty>.Create();
  FSerializationHelpers := TDictionary<TgSerializerClass, TList<TPair<TgBaseClass, TgSerializationHelperClass>>>.Create();
  FClassValidationAttributes := TDictionary<TgBaseClass, TArray<Validation>>.Create();
  FCompositeProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FVisibleProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FDisplayPropertyNames := TDictionary<TgBaseClass, TArray<String>>.Create();
  FPersistableProperties := TDictionary<TgBaseClass, TArray<TRTTIProperty>>.Create();
  FPropertyValidationAttributes := TDictionary<TgBaseClass, TArray<TgPropertyValidationAttribute>>.Create();
  Initialize;
end;

class destructor G.Destroy;
begin
  FreeAndNil(FPropertyValidationAttributes);
  FreeAndNil(FPersistableProperties);
  FreeAndNil(FDisplayPropertyNames);
  FreeAndNil(FVisibleProperties);
  FreeAndNil(FCompositeProperties);
  FreeAndNil(FClassValidationAttributes);
  FreeAndNil(FSerializationHelpers);
  FreeAndNil(FRecordProperty);
  FreeAndNil(FMethodByName);
  FreeAndNil(FSerializableProperties);
  FreeAndNil(FPropertyByName);
  FreeAndNil(FAutoCreateProperties);
  FreeAndNil(FObjectProperties);
  FreeAndNil(FAttributes);
  FreeAndNil(FProperties);
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

class function G.CompositeProperties(AClass: TgBaseClass): TArray<TRTTIProperty>;
begin
  FCompositeProperties.TryGetValue(AClass, Result);
end;

class function G.CompositeProperties(ABase: TgBase): TArray<TRTTIProperty>;
begin
  Result := CompositeProperties(TgBaseClass(ABase.ClassType));
end;

class function G.DisplayPropertyNames(AClass: TgBaseClass): TArray<String>;
begin
  FDisplayPropertyNames.TryGetValue(AClass, Result);
end;

class procedure G.InitialializePersistableProperties(ARTTIType: TRTTIType);
var
  BaseClass: TgBaseClass;
  RTTIProperties: TArray<TRTTIProperty>;
  RTTIProperty: TRTTIProperty;
begin
  BaseClass := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
  for RTTIProperty in SerializableProperties(BaseClass) do
  begin
    FPersistableProperties.TryGetValue(BaseClass, RTTIProperties);
    SetLength(RTTIProperties, Length(RTTIProperties) + 1);
    RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
    FPersistableProperties.AddOrSetValue(BaseClass, RTTIProperties);
  end;
end;

class procedure G.InitializeCompositeProperties(ARTTIType: TRTTIType);
var
  BaseClass: TgBaseClass;
  RTTIProperties: TArray<TRTTIProperty>;
  RTTIProperty: TRTTIProperty;
begin
  BaseClass := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
  for RTTIProperty in ObjectProperties(BaseClass) do
  if Not RTTIProperty.IsWritable then
  begin
    FCompositeProperties.TryGetValue(BaseClass, RTTIProperties);
    SetLength(RTTIProperties, Length(RTTIProperties) + 1);
    RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
    FCompositeProperties.AddOrSetValue(BaseClass, RTTIProperties);
  end;
end;

class procedure G.InitializeDisplayPropertyNames(ARTTIType: TRTTIType);
var
  BaseClass: TgBaseClass;
  CustomAttributes: TArray<TCustomAttribute>;
  DisplayPropertyNames: TArray<String>;
  RTTIProperty: TRTTIProperty;
begin
  BaseClass := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
  CustomAttributes := Attributes(BaseClass, gCore.DisplayPropertyNames);
  if Length(CustomAttributes) > 0 then
  begin
    DisplayPropertyNames := gCore.DisplayPropertyNames(CustomAttributes[0]).Value;
    FDisplayPropertyNames.AddOrSetValue(BaseClass, DisplayPropertyNames);
  end
  Else
  for RTTIProperty in G.VisibleProperties(BaseClass) do
  begin
    if Not RTTIProperty.PropertyType.IsInstance then
    Begin
      SetLength(DisplayPropertyNames, 1);
      DisplayPropertyNames[0] := RTTIProperty.Name;
      FDisplayPropertyNames.AddOrSetValue(BaseClass, DisplayPropertyNames);
    End;
  end;
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

class procedure G.InitializeProperties(ARTTIType: TRTTIType);
var
  RTTIProperties: TArray<TRTTIProperty>;
  TempClass: TgBaseClass;
  RTTIProperty: TRTTIProperty;
  Counter: Integer;
  Replaced: Boolean;
begin
  TempClass := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
  //Include all the ancestor properties
  If TempClass <> TgBase Then
    FProperties.TryGetValue(TgBaseClass(TempClass.ClassParent), RTTIProperties);
  //For each new property
  for RTTIProperty in ARTTIType.GetDeclaredProperties do
  if RTTIProperty.Visibility = mvPublished then
  begin
    Replaced := False;
    for Counter := 0 to Length(RTTIProperties) - 1 do
    Begin
      //If the property is re-introduced
      if SameText(RTTIProperty.Name, RTTIProperties[Counter].Name) then
      Begin
        //Substitute the ancestor property with the declared one
        RTTIProperties[Counter] := RTTIProperty;
        Replaced := True;
        Break;
      End;
    End;
    if Not Replaced then
    Begin
      SetLength(RTTIProperties, Length(RTTIProperties) + 1);
      RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
    End;
  end;
  FProperties.AddOrSetValue(TempClass, RTTIProperties);
end;

class procedure G.InitializePropertyByName(ARTTIType: TRTTIType);
var
  RTTIProperty: TRTTIProperty;
  Key : String;
begin
  for RTTIProperty in G.Properties(TgBaseClass(ARTTIType.AsInstance.MetaclassType)) do
  if RTTIProperty.Visibility = mvPublished then
  begin
    Key := ARTTIType.AsInstance.MetaclassType.ClassName + '.' + UpperCase(RTTIProperty.Name);
    FPropertyByName.Add(Key, RTTIProperty);
  end;
end;

class procedure G.InitializePropertyValidationAttributes(ARTTIType: TRTTIType);
var
  RTTIProperty: TRTTIProperty;
  Attribute: TCustomAttribute;
  BaseClass: TgBaseClass;
  PropertyValidationAttribute: TgPropertyValidationAttribute;
  PropertyValidationAttributes: TArray<TgPropertyValidationAttribute>;

  procedure AddAttribute;
  begin
    FPropertyValidationAttributes.TryGetValue(BaseClass, PropertyValidationAttributes);
    SetLength(PropertyValidationAttributes, Length(PropertyValidationAttributes) + 1);
    PropertyValidationAttribute.RTTIProperty := RTTIProperty;
    PropertyValidationAttribute.ValidateAttribute := Validation(Attribute);
    PropertyValidationAttributes[Length(PropertyValidationAttributes) - 1] := PropertyValidationAttribute;
    FPropertyValidationAttributes.AddOrSetValue(BaseClass, PropertyValidationAttributes);
  end;

begin
  BaseClass := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
  for RTTIProperty in Properties(BaseClass) do
  begin
    for Attribute in RTTIProperty.GetAttributes do
    if Attribute.InheritsFrom(Validation) then
      AddAttribute;
    for Attribute in RTTIProperty.PropertyType.GetAttributes do
    if Attribute.InheritsFrom(Validation) then
      AddAttribute;
  end;
end;

class procedure G.InitializeRecordProperty(ARTTIType: TRTTIType);
var
  CanAdd: Boolean;
  RecordProperty: TgRecordProperty;
  RTTIProperty: TRTTIProperty;
begin
  for RTTIProperty in G.Properties(TgBaseClass(ARTTIType.AsInstance.MetaclassType)) do
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
      RecordProperty.Validator := RTTIProperty.PropertyType.AsRecord.GetMethod('Validation');
      FRecordProperty.AddOrSetValue(RTTIProperty, RecordProperty);
    End;
  end;
end;

class procedure G.InitializeSerializableProperties(ARTTIType : TRttiType);
Var
  RTTIProperties: TArray<TRTTIProperty>;
  RTTIProperty : TRTTIProperty;
Begin
  for RTTIProperty in G.Properties(TgBaseClass(ARTTIType.AsInstance.MetaclassType)) do
  begin
    if (RTTIProperty.Visibility = mvPublished) And RTTIProperty.IsReadable
      And Not (Serializable In TgBaseClass(ARTTIType.AsInstance.MetaclassType).FeatureExclusions(RTTIProperty))
      And
        (
            (RTTIProperty.PropertyType.IsInstance And RTTIProperty.PropertyType.AsInstance.MetaclassType.InheritsFrom(TgBase))
          Or
            (Not RTTIProperty.PropertyType.IsInstance And RTTIProperty.IsWritable)
        )
    then
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

class procedure G.InitializeVisibleProperties(ARTTIType: TRTTIType);
var
  BaseClass: TgBaseClass;
  RTTIProperties: TArray<TRTTIProperty>;
  RTTIProperty: TRTTIProperty;
begin
  BaseClass := TgBaseClass(ARTTIType.AsInstance.MetaclassType);
  for RTTIProperty in Properties(BaseClass) do
  if (RTTIProperty.Visibility = mvPublished) and Not (TgFeature.Visible in BaseClass.FeatureExclusions(RTTIProperty)) then
  begin
    FVisibleProperties.TryGetValue(BaseClass, RTTIProperties);
    SetLength(RTTIProperties, Length(RTTIProperties) + 1);
    RTTIProperties[Length(RTTIProperties) - 1] := RTTIProperty;
    FVisibleProperties.AddOrSetValue(BaseClass, RTTIProperties);
  end;
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

class function G.PersistableProperties(ABaseClass: TgBaseClass): TArray<TRTTIProperty>;
begin
  FPersistableProperties.TryGetValue(ABaseClass, Result);
end;

class function G.PersistableProperties(ABase: TgBase): TArray<TRTTIProperty>;
begin
  Result := PersistableProperties(TgBaseClass(ABase.ClassType));
end;

class function G.Properties(AClass: TgBaseClass): TArray<TRTTIProperty>;
begin
  FProperties.TryGetValue(AClass, Result);
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

class function G.PropertyValidationAttributes(ABaseClass: TgBaseClass): TArray<TgPropertyValidationAttribute>;
begin
  FPropertyValidationAttributes.TryGetValue(ABaseClass, Result);
end;

class function G.PropertyValidationAttributes(ABase: TgBase): TArray<TgPropertyValidationAttribute>;
begin
  Result := PropertyValidationAttributes(TgBaseClass(ABase.ClassType));
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

class function G.ClassValidationAttributes(AClass: TgBaseClass): TArray<Validation>;
begin
  FClassValidationAttributes.TryGetValue(AClass, Result);
end;

class function G.ClassValidationAttributes(ABase: TgBase): TArray<Validation>;
begin
  Result := ClassValidationAttributes(TgBase(ABase.ClassType));
end;

class function G.VisibleProperties(ABaseClass: TgBaseClass): TArray<TRTTIProperty>;
begin
  FVisibleProperties.TryGetValue(ABaseClass, Result);
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
begin
  ABase[RTTIProperty.Name] := Value;
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

{ TgList<T> }

class function TgList<T>.FeatureExclusions(ARTTIProperty: TRttiProperty): TgFeatureExclusions;
begin
  Result := inherited FeatureExclusions(ARTTIProperty);
  if SameText(ARTTIProperty.Name, 'Current') then
    Result := Result + [TgFeature.AutoCreate, TgFeature.Serializable];
end;

function TgList<T>.GetCurrent: T;
Begin
  Result := T(Inherited GetCurrent);
End;

function TgList<T>.GetItems(AIndex : Integer): T;
Begin
  Result := T(Inherited GetItems(AIndex));
End;

procedure TgList<T>.SetItems(AIndex : Integer; const AValue: T);
Begin
  Inherited SetItems(AIndex, AValue);
End;

function TgList<T>.GetEnumerator: TgEnumerator;
Begin
  Result.Init(Self);
End;

function TgList<T>.GetItemClass: TgBaseClass;
begin
  if Not Assigned(Inherited GetItemClass) then
    Inherited SetItemClass(T);
  Result := inherited GetItemClass;
end;

{ TgList }

constructor TgList.Create(AOwner: TgBase = Nil);
Begin
  Inherited Create(AOwner);
  FList := TObjectList<TgBase>.Create;
  FFilteredList := TList<TgBase>.Create();
  FCurrentIndex := -1;
End;

destructor TgList.Destroy;
Begin
  FOrderByList.Free;
  FFilteredList.Free;
  FList.Free;
  Inherited;
End;

procedure TgList.Add;
Begin
  if IsFiltered then
    raise EgList.Create('Cannot add to a filtered list.');
  FCurrentIndex := FList.Add(ItemClass.Create(Self));
End;

procedure TgList.Assign(ASource: TgBase);
var
  Item: TgBase;
begin
  inherited Assign(ASource);
  for Item in TgList(ASource) do
  begin
    ItemClass := TgBaseClass(Item.ClassType);
    Add;
    Current.Assign(Item);
  end;
end;

procedure TgList.Clear;
begin
  if IsFiltered then
    raise EgList.Create('Cannot clear a filtered list.');
  FList.Clear;
  FCurrentIndex := -1;
end;

procedure TgList.Delete;
Begin
  if IsFiltered then
    raise EgList.Create('Cannot delete from a filtered list.');
  if CurrentIndex > -1 then
    FList.Delete(CurrentIndex)
  Else
    raise EgList.Create('There is no item to delete.');
End;

function TgList.DoGetValues(Const APath : String; Out AValue : Variant): Boolean;
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
      If Position > 0 Then
      Begin
        IndexString := Trim(Copy(APath, 2, Position - 2));
        If TryStrToInt(IndexString, Index) Then
        Begin
          CurrentIndex := Index;
          Result := True;
          AValue := Current.Values[Copy(APath, Position + 2, MaxInt)];
        End;
      End;
    End;
  End;
End;

function TgList.DoSetValues(Const APath : String; AValue : Variant): Boolean;
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
      If Position > 0 Then
      Begin
        IndexString := Trim(Copy(APath, 2, Position - 2));
        If TryStrToInt(IndexString, Index) Then
        Begin
          CurrentIndex := Index;
          Result := True;
          Current.Values[Copy(APath, Position + 2, MaxInt)] := AValue;
        End;
      End;
    End;
  End;
End;

procedure TgList.Filter;
begin
  If Not IsFiltered And ( Where > '' ) Then
  Begin
    FFilteredList.Clear;
    First;
    while Not EOL do
    Begin
      if Eval(Where, Current) then
        FFilteredList.Add(Current);
      Next;
    End;
    IsFiltered := True;
  End;
end;

procedure TgList.First;
Begin
  FCurrentIndex := -1;
End;

function TgList.GetBOL: Boolean;
Begin
  Result := Min(FCurrentIndex, List.Count - 1) = - 1;
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
  Result := List.Count;
End;

function TgList.GetCurrent: TgBase;
Begin
  if CurrentIndex = -1 then
    raise EgList.CreateFmt('Attempted to get an item from an empty %s list.', [ClassName]);
  Result := List[CurrentIndex];
End;

function TgList.GetCurrentIndex: Integer;
Begin
  If List.Count > 0 Then
    Result := EnsureRange(FCurrentIndex, 0, List.Count - 1)
  Else
    Result := - 1;
End;

function TgList.GetEnumerator: TgEnumerator;
Begin
  Result.Init(Self);
End;

function TgList.GetEOL: Boolean;
Begin
  Result := Max(FCurrentIndex, 0) = List.Count;
End;

function TgList.GetHasItems: Boolean;
begin
  Result := Count > 0;
end;

function TgList.GetIsFiltered: Boolean;
begin
  Result := lsFiltered In FStates;
end;

function TgList.GetIsInspecting: Boolean;
begin
  Result := lsInspecting in FStates;
end;

function TgList.GetIsOrdered: Boolean;
begin
  Result := lsOrdered In FStates;
end;

function TgList.GetItemClass: TgBaseClass;
begin
  Result := FItemClass;
end;

function TgList.GetItems(AIndex : Integer): TgBase;
Begin
  if InRange(AIndex, 0, List.Count - 1) then
    Result := List[AIndex]
  Else
    Raise EgList.CreateFmt('Failed to get the item at index %d, because the valid range is between 0 and %d.', [AIndex, List.Count - 1]);
End;

function TgList.GetList: TList<TgBase>;
begin
  if IsFiltered then
    Result := FFilteredList
  Else
    Result := FList;
end;

function TgList.GetOrderByList: TObjectList<TgOrderByItem>;
begin
  If Not Assigned( FOrderByList ) Then
    FOrderByList := TObjectList<TgOrderByItem>.Create;
  Result := FOrderByList;
end;

procedure TgList.Last;
Begin
  FCurrentIndex := List.Count;
End;

procedure TgList.Next;
Begin
  If (List.Count > 0) And (FCurrentIndex < List.Count) Then
    FCurrentIndex := CurrentIndex + 1
  Else
    Raise EgList.Create('Failed attempt to move past end of list.');
End;

procedure TgList.Previous;
Begin
  If (List.Count > 0) And (FCurrentIndex > -1) Then
    FCurrentIndex := CurrentIndex - 1
  Else
    Raise EgList.Create('Failed attempt to move past end of list.');
End;

procedure TgList.SetCurrentIndex(const AIndex: Integer);
Begin
  If (List.Count > 0) And InRange(AIndex, 0, List.Count - 1) Then
    FCurrentIndex := AIndex
  Else
    Raise EgList.CreateFmt('Failed to set CurrentIndex to %d, because the valid range is between 0 and %d.', [AIndex, List.Count - 1]);
End;

procedure TgList.SetIsFiltered(const AValue: Boolean);
begin
  If AValue Then
    Include(FStates, lsFiltered)
  Else
  Begin
    Exclude(FStates, lsFiltered);
    FFilteredList.Clear;
  End;
  FCurrentIndex := -1;
end;

procedure TgList.SetIsInspecting(const AValue: Boolean);
begin
  if AValue then
    Include(FStates, lsInspecting)
  Else
    Exclude(FStates, lsInspecting);
end;

procedure TgList.SetIsOrdered(const AValue: Boolean);
begin
  If AValue Then
    Include(FStates, lsOrdered)
  Else
    Exclude(FStates, lsOrdered);
end;

procedure TgList.SetItemClass(const Value: TgBaseClass);
begin
  FItemClass := Value;
end;

procedure TgList.SetItems(AIndex : Integer; const AValue: TgBase);
Begin
  if InRange(AIndex, 0, List.Count - 1) then
    FList[AIndex] := AValue
  Else
    Raise EgList.CreateFmt('Failed to set the item at index %d, because the valid range is between 0 and %d.', [AIndex, List.Count - 1]);
End;

procedure TgList.SetOrderBy(const AValue: String);
var
  StringList: TStringList;
  ItemText: String;
  Item: TgOrderByItem;
begin
  FOrderBy := AValue;
  IsOrdered := False;
  OrderByList.Clear;
  StringList := TStringList.Create;
  try
    StringList.StrictDelimiter := True;
    StringList.CommaText := AValue;
    For ItemText In StringList Do
    Begin
      Item := TgOrderByItem.Create( ItemText );
      OrderByList.Add( Item );
    End;
  finally
    StringList.Free;
  end;
end;

procedure TgList.SetWhere(const AValue: String);
begin
  FWhere := AValue;
end;

procedure TgList.Sort;
var
  Comparer: TgComparer;
begin
  if (Count > 0) then
  Begin
//    EnsureOrderByDefault;
    Comparer := TgComparer.Create(FOrderByList);
    try
      List.Sort(Comparer);
    finally
      Comparer.Free;
    end;
    IsOrdered := True;
  End;
end;

{ TgList.TgEnumerator }

procedure TgList.TgEnumerator.Init(AList: TgList);
begin
  FList := AList;
  SavedCurrentIndex := FList.CurrentIndex;
  FList.First;
  FCurrentIndex := -1;
end;

function TgList.TgEnumerator.GetCurrent: TgBase;
begin
  FList.CurrentIndex := FCurrentIndex;
  Result := FList.Current;
  FList.CurrentIndex := SavedCurrentIndex;
end;

function TgList.TgEnumerator.MoveNext: Boolean;
begin
  If FList.Count = 0 Then
    Exit(False);
  if FCurrentIndex > -1 then
  Begin
    FList.CurrentIndex := FCurrentIndex;
    FList.Next;
  End;
  Inc(FCurrentIndex);
  Result := Not FList.EOL;
  FList.CurrentIndex := SavedCurrentIndex;
end;

{ TgSerializationHelperXMLList }

class function TgSerializationHelperXMLList.BaseClass: TgBaseClass;
begin
  Result := TgList;
end;

class procedure TgSerializationHelperXMLList.Deserialize(AObject: TgBase; AXMLNode: IXMLNode);
var
  Counter: Integer;
  SerializationHelperXMLBaseClass: TgSerializationHelperXMLBaseClass;
begin
  if Not SameText(AXMLNode.Attributes['classname'], AObject.QualifiedClassName) then
    Raise EgParse.CreateFmt('Expected: %s, Parsed: %s', [AObject.QualifiedClassName, AXMLNode.Attributes['classname']]);
  for Counter := 0 to AXMLNode.ChildNodes.Count - 1 do
  Begin
    TgList(AObject).Add;
    SerializationHelperXMLBaseClass := TgSerializationHelperXMLBaseClass(G.SerializationHelpers(TgSerializerXML, TgList(AObject).Current));
    SerializationHelperXMLBaseClass.Deserialize(TgList(AObject).Current, AXMLNode.ChildNodes[Counter]);
  End;
end;

class procedure TgSerializationHelperXMLList.Serialize(AObject: TgBase; ASerializer: TgSerializerXML);
var
  ItemObject: TgBase;
  ItemPointer: TObject;
  SerializationHelperXMLBaseClass: TgSerializationHelperXMLBaseClass;
begin
  for ItemPointer in TgList(AObject) do
  Begin
    ItemObject := TgBase(ItemPointer);
    ASerializer.CurrentNode := ASerializer.CurrentNode.AddChild(ItemObject.FriendlyClassName);
    ASerializer.CurrentNode.Attributes['classname'] := ItemObject.QualifiedClassName;
    SerializationHelperXMLBaseClass := TgSerializationHelperXMLBaseClass(G.SerializationHelpers(TgSerializerXML, ItemObject));
    SerializationHelperXMLBaseClass.Serialize(ItemObject, ASerializer);
    ASerializer.CurrentNode := ASerializer.CurrentNode.ParentNode;
  End;
end;

{ TgSerializationHelperJSONList }

class function TgSerializationHelperJSONList.BaseClass: TgBaseClass;
begin
  Result := TgList;
end;

class procedure TgSerializationHelperJSONList.Deserialize(AObject: TgBase; AJSONObject: TJSONObject);
var
  JSONClassName: String;
  JSONValue: TJSONValue;
  Pair: TJSONPair;
  SerializationHelperJSONBaseClass: TgSerializationHelperJSONBaseClass;
begin
  Pair := AJSONObject.Get('ClassName');
  JSONClassName := Pair.JsonValue.Value;
  if Not SameText(JSONClassName, AObject.QualifiedClassName) then
    Raise EgParse.CreateFmt('Expected: %s, Parsed: %s', [QualifiedClassName, JSONClassName]);
  Pair := AJSONObject.Get('List');
  If Not Pair.JsonValue.InheritsFrom(TJSONArray) Then
    raise EgParse.CreateFmt('Expected: TJSONArray, Parsed: %s.', [Pair.JsonValue.ClassName]);
  for JSONValue in TJSONArray(Pair.JsonValue) Do
  Begin
    if Not JSONValue.InheritsFrom(TJSONObject) then
      raise EgParse.CreateFmt('Expected: TJSONObject, Parsed: %s', [JSONValue.ClassName]);
    TgList(AObject).Add;
    SerializationHelperJSONBaseClass := TgSerializationHelperJSONBaseClass(G.SerializationHelpers(TgSerializerJSON, TgList(AObject).Current));
    SerializationHelperJSONBaseClass.Deserialize(TgList(AObject).Current, TJSONObject(JSONValue));
  End;
end;

class procedure TgSerializationHelperJSONList.Serialize(AObject: TgBase;ASerializer: TgSerializerJSON);
var
  ItemObject: TgBase;
  ItemPointer: TObject;
  JSONArray: TJSONArray;
  ItemSerializer: TgSerializerJSON;
  SerializationHelperJSONBaseClass: TgSerializationHelperJSONBaseClass;
begin
  ASerializer.JSONObject.AddPair('ClassName', AObject.QualifiedClassName);
  JSONArray := TJSONArray.Create;
  try
    for ItemPointer in TgList(AObject) do
    Begin
      ItemSerializer := TgSerializerJSON.Create;
      try
        ItemObject := TgBase(ItemPointer);
        SerializationHelperJSONBaseClass := TgSerializationHelperJSONBaseClass(G.SerializationHelpers(TgSerializerJSON, ItemObject));
        SerializationHelperJSONBaseClass.Serialize(ItemObject, ItemSerializer);
        JSONArray.AddElement(ItemSerializer.JSONObject);
        ItemSerializer.JSONObject := Nil;
      finally
        ItemSerializer.Free;
      end;
    End;
    ASerializer.JSONObject.AddPair('List', JSONArray);
    JSONArray := Nil;
  finally
    JSONArray.Free;
  end;
end;

{ TgBaseClassComparer }

function TgBaseClassComparer.Compare(const Left, Right: TRTTIType): Integer;
begin
  if Left = Right then
    Result := 0
  Else if Left.AsInstance.MetaclassType.InheritsFrom(Right.AsInstance.MetaclassType) then
    Result := 1
  Else if Right.AsInstance.MetaclassType.InheritsFrom(Left.AsInstance.MetaclassType) then
    Result := -1
  Else
    Result := 0;
end;

Constructor TgBaseExpressionEvaluator.Create(AModel : TgBase);
Begin
  Assert(Assigned(AModel), 'No model assigned');
  Inherited Create;
  FModel := AModel;
End;

Function TgBaseExpressionEvaluator.GetValue(Const AVariableName : String) : Variant;
Begin
  Result := FModel[AVariableName];
End;

{ TgOrderByItem }

constructor TgOrderByItem.Create(const AItemText: String);
var
  PosOfSpace: Integer;
  Direction: String;
  TrimmedItemText: String;
begin
  TrimmedItemText := Trim( AItemText );
  PosOfSpace := Pos( ' ', TrimmedItemText );
  If PosOfSpace > 0 Then
  Begin
    PropertyName := Trim( Copy( TrimmedItemText, 1, PosOfSpace ) );
    Direction := Trim( Copy( TrimmedItemText, PosOfSpace, MaxInt ) );
    If SameText( Direction, 'DESC' ) Then
      Descending := True
    Else If SameText( Direction, 'ASC' ) Then
      Descending := False
    Else
      Raise EgOrderByItem.CreateFmt( '''%s'' is an invalid Order By direction.', [Direction] );
  End
  Else
  Begin
    PropertyName := TrimmedItemText;
    Descending := False;
  End;
end;

constructor TgList.TgComparer.Create(AOrderByList: TObjectList<TgOrderByItem>);
begin
  inherited Create;
  FOrderByList := AOrderByList;
end;

function TgList.TgComparer.Compare(const Left, Right: TgBase): Integer;
Var
  Value1 : Variant;
  Value2 : Variant;
  PropertyName: String;
  OrderByItem: TgOrderByItem;
Begin
  Result := 0;
  If FOrderByList.Count > 0 Then
  Begin
    For OrderByItem In FOrderByList Do
    Begin
      PropertyName := OrderByItem.PropertyName;
      Value1 := Left[PropertyName];
      Value2 := Right[PropertyName];
      If VarIsType(Value1, varString) Then
      Begin
        Value1 := UpperCase(Value1);
        Value2 := UpperCase(Value2);
      End;
      If Value1 <> Value2 Then
      Begin
        If Value1 < Value2 Then
          Result := -1
        Else If Value1 > Value2 Then
          Result := 1;
        If OrderByItem.Descending Then
          Result := Result * -1;
        Exit;
      End;
    End;
  End;
end;

{ TgList<T>.TgEnumerator }

function TgList<T>.TgEnumerator.GetCurrent: T;
begin
  FList.CurrentIndex := FCurrentIndex;
  Result := FList.Current;
  FList.CurrentIndex := SavedCurrentIndex;
end;

procedure TgList<T>.TgEnumerator.Init(AList: TgList<T>);
begin
  FList := AList;
  SavedCurrentIndex := FList.CurrentIndex;
  FList.First;
  FCurrentIndex := -1;
end;

function TgList<T>.TgEnumerator.MoveNext: Boolean;
begin
  If FList.Count = 0 Then
    Exit(False);
  if FCurrentIndex > -1 then
  Begin
    FList.CurrentIndex := FCurrentIndex;
    FList.Next;
  End;
  Inc(FCurrentIndex);
  Result := Not FList.EOL;
  FList.CurrentIndex := SavedCurrentIndex;
end;

constructor TgObject.Create(AOwner: TgBase = nil);
begin
  inherited;
  AutoCreate;
  PopulateDefaultValues;
end;

destructor TgObject.Destroy;
var
  ObjectProperty: TgObject;
  RTTIProperty: TRTTIProperty;
begin
  FOriginalValues.Free;
  for RTTIProperty in G.AutoCreateProperties(Self) do
  Begin
    ObjectProperty := TgObject(RTTIProperty.GetValue(Self).AsObject);
    if Owns(ObjectProperty) then
      ObjectProperty.Free;
  End;
  Inherited Destroy;
end;

function TgObject.AllValidationErrors: String;
var
  ObjectProperty: TgObject;
  StringList: TStringList;
  RTTIProperty: TRTTIProperty;
begin
  StringList := TStringList.Create;
  try
    ValidationErrors.PopulateList(StringList);
    for RTTIProperty in G.CompositeProperties(Self) do
    begin
      ObjectProperty := TgObject(Inspect(RTTIProperty));
      if Assigned(ObjectProperty) And ObjectProperty.InheritsFrom(TgObject) then
        ObjectProperty.ValidationErrors.PopulateList(StringList);
    end;
    Result := StringList.Text;
  finally
    StringList.Free;
  end;
end;

procedure TgObject.AutoCreate;
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

class function TgObject.DisplayPropertyNames: TArray<String>;
var
  RTTIProperty: TRTTIProperty;
begin
  for RTTIProperty in G.VisibleProperties(Self) do
  begin
    if Not RTTIProperty.PropertyType.IsInstance then
    Begin
      SetLength(Result, 1);
      Result[0] := RTTIProperty.Name;
    End;
  end;
end;

function TgObject.GetDisplayName: String;
var
  PropertyName: String;
begin
  Result := '';
  for PropertyName in DisplayPropertyNames do
    Result := Result + Values[PropertyName] + ', ';
  if Result > '' then
    SetLength(Result,  Length(Result) - 2);
end;

function TgObject.GetIsInspecting: Boolean;
begin
  Result := osInspecting in FStates;
end;

function TgObject.GetIsModified: Boolean;
var
  RTTIProperty: TRTTIProperty;
begin
  Result := False;
  for RTTIProperty in G.PersistableProperties(Self) do
  Begin
    Result := IsPropertyModified(RTTIProperty);
    if Result then
      Exit;
  end;
end;

function TgObject.GetIsOriginalValues: Boolean;
begin
  Result := osOriginalValues in FStates;
end;

function TgObject.GetIsValid: Boolean;
var
  ObjectProperty: TgObject;
  RTTIProperty: TRTTIProperty;
begin
  ValidationErrors.Clear;
  GetIsValidInternal;
  Result := Not ValidationErrors.HasItems;
  for RTTIProperty in G.CompositeProperties(Self) do
  Begin
    ObjectProperty := TgObject(Inspect(RTTIProperty));
    if Assigned(ObjectProperty) And ObjectProperty.InheritsFrom(TgObject) And Owns(ObjectProperty) And Not ObjectProperty.IsValid then
      Exit(False);
  End;
end;

procedure TgObject.GetIsValidInternal;
var
  PropertyValidationAttribute: TgPropertyValidationAttribute;
begin
  for PropertyValidationAttribute in G.PropertyValidationAttributes(Self) do
    PropertyValidationAttribute.Execute(Self);
end;

function TgObject.GetOriginalValues: TgBase;
begin
  if Not IsInspecting And Not Assigned(FOriginalValues) then
  Begin
    FOriginalValues := TgObjectClass(Self.ClassType).Create(Owner);
    FOriginalValues.IsOriginalValues := True;
  End;
  Result := FOriginalValues;
end;

function TgObject.GetValidationErrors: TgValidationErrors;
begin
  if Not IsInspecting And Not IsOriginalValues And Not Assigned(FValidationErrors) then
    FValidationErrors := TgValidationErrors.Create;
  Result := FValidationErrors;
end;

function TgObject.HasValidationErrors: Boolean;
var
  RTTIProperty: TRTTIProperty;
  ObjectProperty : TgObject;
begin
  Result := ValidationErrors.Count > 0;
  if Not Result then
  Begin
    for RTTIProperty in G.CompositeProperties(Self) do
    begin
      ObjectProperty := TgObject(Inspect(RTTIProperty));
      if Assigned(ObjectProperty) And ObjectProperty.InheritsFrom(TgObject) then
      Begin
        Result := ObjectProperty.HasValidationErrors;
        if Result then
          Exit;
      End;
    end;
  End;
end;

procedure TgObject.InitializeOriginalValues;
begin
  OriginalValues.Assign(Self);
end;

function TgObject.IsPropertyModified(ARTTIProperty: TRttiProperty): Boolean;
begin
  If Not ARTTIProperty.PropertyType.IsInstance Then
    Result := Not (ARTTIProperty.GetValue(Self).AsVariant = ARTTIProperty.GetValue(OriginalValues).AsVariant)
  Else if ARTTIProperty.PropertyType.AsInstance.MetaclassType.InheritsFrom(TgObject) then
    Result := TgObject(ARTTIProperty.GetValue(Self).AsObject).IsModified
  Else
    Result := False;
end;

function TgObject.IsPropertyModified(const APropertyName: string): Boolean;
begin
  Result := IsPropertyModified(G.PropertyByName(Self, APropertyName));
end;

procedure TgObject.PopulateDefaultValues;
Var
  Attribute : TCustomAttribute;
Begin
  For Attribute In G.Attributes(Self, DefaultValue) Do
    DefaultValue(Attribute).Execute(Self);
End;

procedure TgObject.SetIsInspecting(const AValue: Boolean);
begin
  if AValue then
    Include(FStates, osInspecting)
  Else
    Exclude(FStates, osInspecting);
end;

procedure TgObject.SetIsOriginalValues(const AValue: Boolean);
begin
  If AValue Then
    Include(FStates, osOriginalValues)
  Else
    Exclude(FStates, osOriginalValues);
end;

constructor TgValidationErrors.Create(AOwner: TgBase = Nil);
begin
  inherited Create(AOwner);
  FDictionary := TDictionary<String, String>.Create();
end;

destructor TgValidationErrors.Destroy;
begin
  FreeAndNil(FDictionary);
  inherited Destroy;
end;

procedure TgValidationErrors.Clear;
begin
  FDictionary.Clear;
end;

function TgValidationErrors.DoGetValues(const APath: string; out AValue: Variant): Boolean;
var
  TempString: String;
begin
  Result := inherited DoGetValues(APath, AValue);
  if Not Result then
  Begin
    Result := FDictionary.TryGetValue(APath, TempString);
    AValue := TempString;
  End;
end;

function TgValidationErrors.DoSetValues(const APath: string; AValue: Variant): Boolean;
var
  TempString: String;
begin
  Result := inherited DoSetValues(APath, AValue);
  if Not Result then
  Begin
    TempString := AValue;
    FDictionary.AddOrSetValue(APath, TempString);
    Result := True;
  End;
end;

function TgValidationErrors.GetCount: Integer;
begin
  Result := FDictionary.Count;
end;

function TgValidationErrors.GetHasItems: Boolean;
begin
  Result := Count > 0;
end;

procedure TgValidationErrors.PopulateList(AStringList: TStrings);
var
  Pair: TPair<String, String>;
begin
  for Pair in FDictionary do
    AStringList.Add(Pair.Key + ': ' + Pair.Value);
end;

constructor DisplayPropertyNames.Create(AValue: TArray<String>);
begin
  inherited Create;
  FValue := AValue;
end;

constructor Required.Create(AEnabled: Boolean = True);
begin
  inherited Create;
  FEnabled := AEnabled;
end;

procedure Required.Execute(AObject: TgObject; ARTTIProperty: TRTTIProperty);
var
  RaiseException: Boolean;
  TempObject: TObject;
  Value: Variant;
begin
  RaiseException := False;
  if Enabled And ARTTIProperty.PropertyType.IsInstance then
  begin
    TempObject := ARTTIProperty.GetValue(AObject).AsObject;
    if Not Assigned(TempObject) then
      RaiseException := True;
  end
  Else
  Begin
    Value := AObject[ARTTIProperty.Name];
    case VarType(Value) of
      varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64, varSingle, varDouble, varCurrency, varDate :
        if Value = 0 then RaiseException := True;
      varUString :
        if Value = '' then RaiseException := True;
    end;
  End;
  if RaiseException then
    AObject.ValidationErrors[ARTTIProperty.Name] := Format('%s is required.', [ARTTIProperty.Name]);
end;

procedure TgPropertyValidationAttribute.Execute(AObject: TgObject);
begin
  ValidateAttribute.Execute(AObject, RTTIProperty);
end;

Initialization
  TgSerializationHelperXMLBase.BaseClass;
  TgSerializationHelperXMLList.BaseClass;
  TgSerializationHelperJSONBase.BaseClass;
  TgSerializationHelperJSONList.BaseClass;

end.




