unit gWebServerController;

interface

uses
  gCore
  , System.Classes
  , Generics.Collections
  , Contnrs
  , SysUtils
  , StrUtils
  , Windows
;
const
  sDateFormat = '"%s", dd "%s" yyyy hh:nn:ss';

type
  TgRequestContentBase = class;
  TgWebServerControllerConfigurationData = class;
  TgRequestLogItem = class;
  TgResponse = class;
  TgRequestMap = class;
  TgRequestLogItemClass = class of TgRequestLogItem;

  TMemoryStream_Helper = class helper for TMemoryStream
    procedure WriteString(const Value: String);
  end;

  TgHeaderFields = class(TgDictionary)
  strict private
    FHost: String;
    FMethod: AnsiString;
    FDocument: AnsiString;
  published
    property Document: AnsiString read FDocument write FDocument;
    property Host: String read FHost write FHost;
    property Method: AnsiString read FMethod write FMethod;
  end;

  TgRequest = class(TgBase)
  strict private
    FContent: TgRequestContentBase;
    FHeaderFields: TgHeaderFields;
    FQueryFields: TgDictionary;
    FCookieFields: TgDictionary;
    FContentFields: TgDictionary;
    FHTTPVersion: String;
    FMaxFileUploadSize: Integer;
    FMultiPart: Boolean;
    FURI: String;
    FIPAddress: String;
    FIsSecure: Boolean;
    FIsMobile: Boolean;
    FMethod: String;
    function GetFields(const AName: String): String;
    function GetHost: String;
    function GetIsMobile: Boolean;
    procedure SetHost(const AValue: String);
  Public
    Destructor Destroy;Override;
    function AsString: String;
    Property Content : TgRequestContentBase read FContent write FContent;
    property Fields[const AName: String]: String read GetFields; default;
    property MaxFileUploadSize: Integer read FMaxFileUploadSize write FMaxFileUploadSize;
    Property MultiPart : Boolean read FMultiPart write FMultiPart;
  Published
    property Method: String read FMethod write FMethod;
    property HTTPVersion: String read FHTTPVersion write FHTTPVersion;
    property URI: String read FURI write FURI;
    property ContentFields: TgDictionary read FContentFields;
    property CookieFields: TgDictionary read FCookieFields;
    property HeaderFields: TgHeaderFields read FHeaderFields;
    property Host: String read GetHost write SetHost;
    property QueryFields: TgDictionary read FQueryFields;
    property IPAddress: String read FIPAddress write FIPAddress;
    property IsSecure: Boolean read FIsSecure write FIsSecure;
    property IsMobile: Boolean read GetIsMobile write FIsMobile;
  End;

  TgRequestDistiller = class
  end;

  TgRequestContentItemBase = class(TgBase)
  private
    FContentLength: Integer;
    function FileUploadPath: String;
  Protected
    FContent: TMemoryStream;
    function GetContent: TMemoryStream;Virtual;
    function GetContentType: String;Virtual;Abstract;
    function GetRequest: TgRequest;Virtual;
  Public
    Destructor Destroy;Override;
    Procedure Parse;Virtual;Abstract;
    Property Request : TgRequest read GetRequest;
    Property ContentType : String read GetContentType;
    Property ContentLength : Integer read FContentLength write FContentLength;
    Property Content : TMemoryStream read GetContent;
  End;

  TgRequestContentBase = class(TgList)
  private
    FContent: TMemoryStream;
    function GetCurrent: TgRequestContentItemBase; ReIntroduce;
    function GetRequest: TgRequest;
    function GetContent: TMemoryStream;
  Public
    Destructor Destroy;Override;
    procedure Parse; virtual; abstract;
    Property Content : TMemoryStream read GetContent;
    Property Request : TgRequest read GetRequest;
  Published
    Property Current : TgRequestContentItemBase read GetCurrent;
  End;

  TgWebServerController = class(TgController)
  public
    type
      E = class(Exception)
      public
        function ResponseCode: Integer; virtual;
      end;
      EFileNotFound = class(E)
      public
        function ResponseCode: Integer; override;
      end;
      TgWebServerControllerConfigurationDataAnon = reference to procedure(Item: TgWebServerControllerConfigurationData);
  strict private
    FActions: TgDictionary;
    FModel: TgModel;
    FRequest: TgRequest;
    FResponse: TgResponse;
    FUIState: TgDictionary;
    FLogItem: TgRequestLogItem;
//    FRequestDistiller: TgRequestDistiller;
    FRequestMap: TgRequestMap;
    procedure PopulateModelFromRequest;
    procedure LogOutInternal(AObject: TgBase);
    procedure DoAction;
    function FindDocument(const ADocument: String): String;
    procedure SetCookies(APropertyList: TStringList);
    property Model: TgModel read FModel write FModel;
  private
  class var
    ConfigurationData: TgWebServerControllerConfigurationData;
    ConfigurationDataSynchronizer: TMultiReadExclusiveWriteSynchronizer;
  var
    FAction: String;
    procedure SetAction(const AValue: String);
  strict protected
  public
    class constructor Create;
    class destructor Destroy;
    destructor Destroy; override;
    class function ReadConfigurationData: TgWebServerControllerConfigurationData; overload;
    class procedure ReadConfigurationData(Method: TgWebServerControllerConfigurationDataAnon); overload;
    class procedure EndReadConfigurationData;
    class procedure EndWriteConfigurationData;
    class function WriteConfiguationData: TgWebServerControllerConfigurationData; overload;
    class procedure WriteConfiguationData(Method: TgWebServerControllerConfigurationDataAnon); overload;
    class function FileUploadPath: String;
    procedure Execute;
    procedure Login;
    procedure LogOut;
    function MakeCookie(const AName, AValue, ADomain, APath: String; const AExpiration: TDateTime; ASecure: Boolean): String;
  published
    property Action: String read FAction write SetAction;
    property Actions: TgDictionary read FActions;
    property Request: TgRequest read FRequest;
    property Response: TgResponse read FResponse;
    property UIState: TgDictionary read FUIState;
    property LogItem: TgRequestLogItem read FLogItem;
    [NoAutoCreate]
    property RequestMap: TgRequestMap read FRequestMap;
  end;

  TgRequestContentFormData = Class(TgRequestContentBase)
  Public
    constructor Create(AOwner: TgBase = nil); override;
    Procedure Parse;Override;
  End;

  TgRequestContentItemMultiPartFormData = Class(TgRequestContentItemBase)
  Public
    Procedure Parse;Override;
  End;

  TgRequestContentItemFile = Class(TgRequestContentItemMultiPartFormData)
  private
    FFileName: String;
    FName: String;
  Protected
    function GetContentType: String;Override;
  Public
    Procedure Parse;Override;
    Property Name : String read FName write FName;
    Property FileName : String read FFileName write FFileName;
  End;

  TgRequestContentItemFormData = Class(TgRequestContentItemBase)
  Protected
    function GetContentType: String;Override;
  Public
    Procedure Parse;Override;
  End;

  TgRequestContentMultiPartFormData = Class(TgRequestContentBase)
  Public
    Procedure Parse;Override;
    constructor Create(AOwner: TgBase = nil); override;
  End;

  TgRequestMap = class(TgIdentityObject<String>)
  private
  public
    type
      [Serializable]
      TgRequestMaps = class(TgIdentityList<TgRequestMap>)
      public
        constructor Create(Owner: TgBase = nil); override;
      end;
      TPopulateMethod = reference to procedure;
    class var _Builders: TList<TPopulateMethod>;
    class procedure RegisterBuilder(Anon: TPopulateMethod);
  strict private
    FVirtualPaths: TgRequestMaps;
    FSearchPath : String;
    FSubHosts: TgRequestMaps;
    FDefaultPage: String;
    FRedirect : String;
    FBasePath: String;
    FHosts: TgIdentityList;
    FLogClass: TgRequestLogItemClass;
    FLoginTemplate: String;
    FSecurePath: String;
    FPathQuery: Boolean;
    FMobileSearchPath: String;
    FModelClass: TgModelClass;
    function GetLoginTemplate: String;
  strict protected
    function GetSubHost(var AHost: String): TgRequestMap;
    function GetVirtualPath(var APath : String): TgRequestMap;
    Function GetPathInternal(const AHead, ATail : String) : String;
    function GetPath(ARequestString: String): String;
    function AbsolutePath(ARelativePath: String): String;
    Function IsRelativePath(APath : String) : Boolean;
    Function GetSearchPath : String;
    property Hosts: TgIdentityList read FHosts;
  Public
    class constructor Create;
    class destructor Destroy;
    class procedure SplitHostPath(const APath : String; var AHead, ATail : String);
    class Procedure SplitRequestPath(const ARequestPath : String; var AHead, ATail : String); Virtual;
    constructor Create(AOwner: TgBase = nil); override;
    destructor Destroy; override;
    Function TopRequestMap : TgRequestMap;
    property VirtualPath[var APath : String]: TgRequestMap read GetVirtualPath;
    Property Path[ARequestString : String] : String read GetPath;
    Property SubHost[var AHost : String] : TgRequestMap read GetSubHost;
  Published
    property BasePath: String read FBasePath write FBasePath;
    [DefaultValue('.')]
    Property SearchPath : String read GetSearchPath write FSearchPath;
    property MobileSearchPath: String read FMobileSearchPath write FMobileSearchPath;
    [NotAutoCreate]
    property VirtualPaths: TgRequestMaps read FVirtualPaths stored False;
    [NotAutoCreate]
    property SubHosts: TgRequestMaps read FSubHosts;
    property DefaultPage: String read FDefaultPage write FDefaultPage;
    property LogClass: TgRequestLogItemClass read FLogClass write FLogClass;
    Property Redirect : String read FRedirect write FRedirect;
    Property LoginTemplate : String read GetLoginTemplate write FLoginTemplate;
    property ModelClass: TgModelClass read FModelClass write FModelClass;
    property SecurePath: String read FSecurePath write FSecurePath;
    property PathQuery: Boolean read FPathQuery write FPathQuery;
  End;

  TgWebServerControllerConfigurationData = class(TgBase)
  public
    class var
       Packages: TStringList;
  strict private
    FDefaultHost: String;
    FFileTypes: TgDictionary;
    FHosts: TgRequestMap.TgRequestMaps;
    FTemplateFileExtensions: TgMemo;
    RequestMapBuilders: TObjectList;
    procedure AddDefaultFileTypes;
    class function GetFileName: String; static;
    procedure AddDefaultPackages;
    procedure AddDefaultPackage(const AFileName: String);
  public
    class constructor Create;
    class destructor Destroy;
    class function FileNamePackages: String;
    class procedure LoadPackages;
    class procedure UnloadPackages;
    class procedure RegisterPackage(const APackageName: String);
    constructor Create(AOwner: TgBase = Nil); override;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    procedure InitializeRequestMapBuilders;
    procedure FinalizeRequestMapBuilders;
    procedure GetRequestMap(var Host, URI: String; out RequestMap: TgRequestMap);
    class property FileName: String read GetFileName;
    function Serialize(ASerializerClass: TgSerializerClass): string; override;
  published
    property DefaultHost: String read FDefaultHost write FDefaultHost;
    property FileTypes: TgDictionary read FFileTypes;
    property Hosts: TgRequestMap.TgRequestMaps read FHosts;
    property TemplateFileExtensions: TgMemo read FTemplateFileExtensions write FTemplateFileExtensions;
  end;

  TgRequestLogItem = class(TgBase)
  strict private
    FDateTime: TDateTime;
    FDuration: Integer;
    FStatusCode: Integer;
// TODO: FMethod
//// TODO: FIPAddress
////  FIPAddress: TgIPAddressString;
//  FMethod: TgRequestMethodString;
// TODO: FUserAgent
//  FUserAgent: TgUserAgentString;
    function GetDuration: Integer;
// TODO: GetHost
//  function GetHost: TgURI;
// TODO: GetReferer
//  function GetReferer: TgURI;
    function GetWebServerController: TgWebServerController;
  strict protected
    property WebServerController: TgWebServerController read GetWebServerController;
  public
// TODO: Populate
//  procedure Populate; override;
  Published
    property DateTime: TDateTime read FDateTime write FDateTime;
    property Duration: Integer read GetDuration write FDuration;
// TODO: Host
//// TODO: IPAddress
////  property IPAddress: TgIPAddressString read FIPAddress write FIPAddress;
//  property Host: TgURI read GetHost;
// TODO: Referer
//  property Referer: TgURI read GetReferer;
// TODO: Method
//  property Method: TgRequestMethodString read FMethod write FMethod;
// TODO: UserAgent
//  property UserAgent: TgUserAgentString read FUserAgent write FUserAgent;
    property StatusCode: Integer read FStatusCode write FStatusCode;
  End;

  TgResponse = class(TgBase)
  strict private
    FContentStream: TMemoryStream;
    FHeaderFields: TgDictionary;
    FStatusCode: Integer;
    FCookies: TgDictionary;
    FExpires: TDateTime;
    FDate: TDateTime;
    function GetReasonPhrase: String;
    function GetStatusLine: String;
    procedure SetExpires(const Value: TDateTime);
    procedure SetDate(const Value: TDateTime);
    procedure SetRedirect(const AURL: String);
    procedure SetHeader(const AValue: String);
    procedure SetSetMobile(const AValue: Boolean);
    procedure SetIsMobile(const AValue: Boolean);
  private
    function GetText: AnsiString;
  Public
    constructor Create(AOwner: TgBase = Nil); override;
    Destructor Destroy;Override;
    function GetFriendlyClassName: string; override;
    property ContentStream: TMemoryStream read FContentStream;
    property Text: AnsiString read GetText;
  Published
    property HeaderFields: TgDictionary read FHeaderFields;
    property Cookies: TgDictionary read FCookies;
    Property StatusCode : Integer read FStatusCode write FStatusCode;
    Property ReasonPhrase : String read GetReasonPhrase;
    Property StatusLine : String read GetStatusLine;
    Property Date : TDateTime read FDate write SetDate;
    Property Expires : TDateTime read FExpires write SetExpires;
    property Redirect: String write SetRedirect;
    property Header: String write SetHeader;
    property SetMobile: Boolean write SetSetMobile;
    property IsMobile: Boolean write SetIsMobile;
  End;

  EgWebServerController = class(Exception)
  end;

  TgWebRequestParser = class(TObject)
  strict private
    FRequest: TgRequest;
  strict protected
    procedure ReadContentFields; virtual; abstract;
    procedure ReadCookieFields; virtual; abstract;
    procedure ReadHeaderFields; virtual; abstract;
    procedure ReadQueryFields; virtual; abstract;
    procedure ReadRequestLine; virtual; abstract;
    function RemoveContentTypeExtraData(AContentType: String): String;
    property Request: TgRequest read FRequest write FRequest;
  public
    constructor Create(ARequest: TgRequest);
    destructor Destroy; override;
    procedure GetData; virtual;
    class procedure PopulateCookieFields(const ACookieString: String; ACookieFields: TgDictionary);
    class procedure PopulateHeaderFields(AHeaderString: String; AHeaderFields: TgHeaderFields);
    class procedure PopulateQueryFields(const AQueryString: String; AQueryFields: TgDictionary);
  end;

  TgWebAdapter = class(TObject)
  strict protected
    function DiscoverExecutablePath: String; virtual; abstract;
  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

type
  TgWebResponseGenerator = class(TObject)
  strict private
    FHeaderStream: TStringStream;
    FContentStream: TStringStream;
    FController: TgWebServerController;
    FRequest: TgRequest;
    FResponse: TgResponse;
  strict protected
    procedure PopulateHeaderStream;
    procedure SendStream(AStream: TStream); virtual; abstract;
    property HeaderStream: TStringStream read FHeaderStream write FHeaderStream;
    property ContentStream: TStringStream read FContentStream write FContentStream;
    property Request: TgRequest read FRequest write FRequest;
    property Response: TgResponse read FResponse write FResponse;
  public
    constructor Create(AController: TgWebServerController);
    destructor Destroy; override;
    procedure SendData;
  end;

function ParseRFC822DateString(const ADateString: String): TDateTime;

implementation

Uses
  Types,
  RTTI,
  DateUtils
;

function ParseRFC822DateString(const ADateString: String): TDateTime;
const
  MonthsString = 'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC';
var
  DateString: String;
  Day: Integer;
  MonthPos : Integer;
  Month : Integer;
  Year: Integer;
  Time: TDateTime;
Begin
  Try
    DateString := Trim(ADateString);
    Day := StrToInt(Copy(DateString, 6, 2));
    MonthPos := Pos(UpperCase(Copy(DateString, 9, 3)), MonthsString);
    Month := ((MonthPos - 1) DIV 3) + 1;
    Year := StrToInt(Copy(DateString, 13, 4));
    Time := StrToTime(Copy(DateString, 18, 8));
    Result := EncodeDate(Year, Month, Day) + Time;
  Except
    Result := 0;
  End;
End;

class constructor TgWebServerController.Create;
begin
//  G.AfterInit(procedure
//    begin
      ConfigurationData := TgWebServerControllerConfigurationData.Create;
      ConfigurationDataSynchronizer := TMultiReadExclusiveWriteSynchronizer.Create;
//    end);
end;

class destructor TgWebServerController.Destroy;
begin
  FreeAndNil(ConfigurationData);
  FreeAndNil(ConfigurationDataSynchronizer);
end;

destructor TgWebServerController.Destroy;
begin
  FreeAndNil(FResponse);
  FreeAndNil(FRequest);
  FreeAndNil(FUIState);
  inherited Destroy;
end;

class function TgWebServerController.ReadConfigurationData: TgWebServerControllerConfigurationData;
begin
  ConfigurationDataSynchronizer.BeginRead;
  Result := ConfigurationData;
end;

class procedure TgWebServerController.EndReadConfigurationData;
begin
  ConfigurationDataSynchronizer.EndRead;
end;

class procedure TgWebServerController.EndWriteConfigurationData;
begin
  ConfigurationDataSynchronizer.EndWrite;
end;

procedure TgWebServerController.Execute;
var
  Counter: Integer;
  FileName: String;
  FileStream: TFileStream;
  PropertyList: TStringList;
  RequestLogItemClass : TgRequestLogItemClass;
  LoadList: TList;
  FileExtention: String;
  MimeType: String;
  PathArray: TStringDynArray;
  PathQuery: String;
  RedirectString: String;
  TempString: String;
  Document: String;
  FileNameExtension: String;
  Host: String;
  IsTemplate: Boolean;
  ModelNeeded: Boolean;
  ModelClass: TgModelClass;
  StringList: TStringList;
  Attribute: TCustomAttribute;
  Token: string;
  TempVariant: Variant;
  GDocument: TgDocument;
  PropertyAttribute: TgPropertyAttribute;
begin
{ TODO : Add request logging }
  Try
    Host := Request.Host;
    Document := Request.URI;
    TgWebServerController.ConfigurationData.GetRequestMap(Host,Document,FRequestMap);

    if not Assigned(RequestMap) then begin
      Response.StatusCode := 501;
      exit;
    end;
    if (RequestMap.Redirect > '') then
    Begin
      Response.StatusCode := 301;
      Response.HeaderFields['Location'] := RequestMap.Redirect;
      Exit;
    End;


    // exposites.com/pathquery/id=6/image.jpg
    ModelNeeded := False;
    If RequestMap.PathQuery Then
    Begin
      ModelNeeded := True;
      SplitOnChar(Document, '/', PathQuery, TempString);
      PathQuery := URLDecode(PathQuery);
      Document := TempString;
      StringList := TStringList.Create;
      try
        StringList.Delimiter := '&';
        StringList.DelimitedText := PathQuery;
        For Counter := 0 to StringList.Count - 1 Do
          Request.QueryFields[StringList.Names[Counter]] := StringList.ValueFromIndex[Counter];
      finally
        StringList.Free;
      end;
    End;

    // if a document doesn't end in a slash, then redirect with a slash to
    // make the client address include the root character
    If Document = '' Then
    Begin
      Response.StatusCode := 301;
      Response.HeaderFields['Location'] := Request.URI + '/';
      Exit;
    End;

    If ( Document = '/' ) And ( RequestMap.DefaultPage > '' ) Then
      Document := RequestMap.DefaultPage;
    FileName := FindDocument(Document);
    If FileName = '' Then
      Raise EFileNotFound.CreateFmt( '%s not found.', [Document] );

    FileNameExtension := ExtractFileExt( FileName );
    If FileNameExtension > '' Then
    Begin
      Delete(FileNameExtension, 1, 1);
      IsTemplate := ConfigurationData.TemplateFileExtensions.IndexOf( FileNameExtension ) > -1;
      if IsTemplate then
        ModelNeeded := True;
    End;
    if IsTemplate then
    begin
      ModelClass := RequestMap.ModelClass;
      If not Assigned(ModelClass) Then
        ModelClass := TgModel;
      If ModelNeeded Then
      Begin
{ TODO : Add IPAddressLog stuff }
        FModel := ModelClass.Create(Self);
        If Assigned(RequestMap.LogClass) Then
          FLogItem := RequestMap.LogClass.Create(Self);

        // Push authorization values
        // [Authorization]
        // property emailaddress : TgEmailAddressString
        // [Authorization]
        // property password : TgPasswordString

        // Request Content Fields
        // emailaddress: jim@computerminds.com
        // password: password

        if Request.CookieFields.DoGetValues('Token',TempVariant) and  (TempVariant <> '') then
          Token := TempVariant
        else  for Attribute in G.Attributes(FModel, Authorization) do
        Begin
          PropertyAttribute := TgPropertyAttribute(Attribute);
          FModel[PropertyAttribute.RTTIProperty.Name] := Request.ContentFields[PropertyAttribute.RTTIProperty.Name];
        End;

        if FModel.IsAuthorized(Token) Then
        Begin
          Response.Cookies['Token'] := Token;
          PopulateModelFromRequest;
        End
        Else
          FileName := FindDocument(RequestMap.LoginTemplate);
{ TODO : Check to see if we should add in X-SendFile }
        if IsTemplate then
        Begin
          GDocument := TgDocument.Create(FModel);
          try
            GDocument.SearchPath := RequestMap.SearchPath;
            //GDocument.IsSecure
            GDocument.ProcessFile(FileName,Response.ContentStream);
          finally
            GDocument.Free;
          end;
        End
        Else If Not (Response.StatusCode > 301) Then
          Response.HeaderFields['X-SendFile'] := FileName
        Else If Response.StatusCode = 200 Then
        Begin
          FileExtention := ExtractFileExt( FileName );
          If FileExtention > '' Then
          Begin
            ConfigurationData := ReadConfigurationData;
            try
              MimeType := ConfigurationData.FileTypes.Values[Copy( FileExtention, 2, MaxInt)];
            finally
              EndReadConfigurationData;
            end;
          End;
          If (MimeType > '') And (Response.HeaderFields['Content-Type'] = '') Then
            Response.HeaderFields['Content-Type'] := MimeType;
        End
      End;
    End
    else begin
      // Just send file
      Response.HeaderFields['X-SendFile'] := FileName
   //   Response.ContentStream.LoadFromFile(FileName);
    end;
    Response.Date := Now;
  Except
    On Ex: Exception Do
    Begin
      If Ex.InheritsFrom( E ) Then
      Begin
        Response.StatusCode := E(Ex).ResponseCode;
        Response.ContentStream.WriteString( Ex.message );
      End
      Else
      Begin
        Response.StatusCode := 500;
        Response.ContentStream.WriteString( Ex.message );
        Raise;
      End;
    End;
  End;
end;

procedure TgWebServerController.PopulateModelFromRequest;
var
  NameValuePair: TgBase.TPathValue;
  NewName: String;
  TempName: String;
  RequestFields: TgBase;
  RequestFieldsArray: Array[0..1] Of TgBase;
  LastTwoChars: String;
  MethodFound: Boolean;
  RTTIProperty: TRTTIProperty;
  TempObject : TgObject;
begin
  MethodFound := False;
  RequestFieldsArray[0] := Request.QueryFields;
  RequestFieldsArray[1] := Request.ContentFields;
  Try
    For RequestFields In RequestFieldsArray Do
    Begin
{ TODO :
Add TgDictionary.ToArray to represent Query and Content field lists.
Each array element represents a name / value pair (NameValuePair) }

      For NameValuePair In RequestFields Do
      Begin
        try
          NewName := NameValuePair.Path;
          If NewName = '' Then
            Continue;
{ TODO : Add image submit code }
(*
            LastTwoChars := Copy( NameValuePair.Name, Length( NameValuePair.Name ) - 1, MaxInt );
            If SameText( LastTwoChars, '.y' ) And MethodFound Then
              MethodFound := False
            Else
            Begin
              If SameText( LastTwoChars, '.x' ) Then
              Begin
                TempName := Copy( NameValuePair.Name, 1, Length( NameValuePair.Name ) - 2 );
                If FModel.MethodExistsOnPath[TempName] Then
                Begin
                  NewName := TempName;
                  MethodFound := True;
                End;
              End;

*)
            RTTIProperty := G.PropertyByName(FModel, NewName);
            If Assigned(RTTIProperty) And (RTTIProperty.PropertyType.Handle = TypeInfo(Boolean)) Then
            Begin

 { TODO : Add security }
              If ( NameValuePair.Value = '' ) Or SameText( NameValuePair.Value, 'False' )  Then
                FModel[NewName] := False
              Else
                FModel[NewName] := True;
            End
            Else
              FModel[NewName] := NameValuePair.Value;
        except
          On E: EgValidation Do
            Raise;
 { TODO : Figure out how to handle exceptions }
(*
            On E: Exception Do
            Begin
              Try
                TempObject := TgObject(FModel.LastObject(NewName, TempName));
                If Assigned(TempObject) and TempObject.InheritsFrom(TgObject) Then
                Begin
                  TempObject.ValidationErrors[TempName] := E.Message;
                  TempObject.ValidationErrors.Objects[TempName].ErrorLevel := gelTypeConversion;
                  TempObject.ValidationErrors.Objects[TempName].TypeConversionErrorValue := NameValuePair.Value;
                End;
              Except
                On E: Exception Do
                  Raise Exception.CreateFmt('%s, %s, NewName: %s, TempName: %s, StringHashValue.Value: %s', [E.ClassName, E.Message, NewName, TempName, NameValuePair.Value]);
              End;
            End;

*)        end;
      End;
    End;
    DoAction;
  Except
 { TODO : Figure out how to handle exceptions }
(*
      On E: EgValidation Do
      Begin
        ValidationError := True;
        With FModel.ValidationErrors Do
        Begin
          Message := 'Please fix items in red.';
          ErrorLevel := gelError;
        End;
      End;

*)  End;
end;

class procedure TgWebServerController.ReadConfigurationData(
  Method: TgWebServerControllerConfigurationDataAnon);
var
  Temp: TgWebServerControllerConfigurationData;
begin
  Temp := ReadConfigurationData;
  try
    Method(Temp);
  finally
    EndReadConfigurationData;
  end;

end;

class function TgWebServerController.WriteConfiguationData: TgWebServerControllerConfigurationData;
begin
  ConfigurationDataSynchronizer.BeginWrite;
  Result := ConfigurationData;
end;

procedure TgWebServerController.LogOut;
begin
{ TODO : Implement }
end;

function TgWebServerController.MakeCookie(const AName, AValue, ADomain, APath: String; const AExpiration: TDateTime; ASecure: Boolean): String;
const
  sDateFormat = '"%s", dd "%s" yyyy hh:nn:ss';
begin
  Result := AValue;
  If ADomain <> '' Then
    Result := Result + Format('; domain=%s', [ADomain]);
  If APath <> '' Then
    Result := Result + Format('; path=%s', [APath]);
  If AValue = '' Then
    Result := Result + '; max-age=0'
  Else If AExpiration > 0 Then
    Result := Result +
      Format(FormatDateTime('"; expires="' + sDateFormat + ' "GMT"', AExpiration + TimeZoneBias),
        [DayOfWeekStr(AExpiration), MonthStr(AExpiration)]);
  Result := Result + '; version=1';
  { TODO : Make sure this is set for the webserver's http status. }
  If ASecure then
    Result := Result + '; secure';
end;

procedure TgWebServerController.LogOutInternal(AObject: TgBase);
var
  Counter: Integer;
  PropertyName: String;
  FullPropertyName: String;
  AuthorizationAttributeValue: String;
begin
{ TODO : Complete }
(*

    For Counter := 0 to AObject.VisiblePropertyNames.Count - 1 Do
    Begin
      PropertyName := AObject.VisiblePropertyNames[Counter];
      FullPropertyName := AObject.ObjectPathName;
      If FullPropertyName > '' Then
        FullPropertyName := FullPropertyName + '.';
      FullPropertyName := FullPropertyName + PropertyName;
      AuthorizationAttributeValue := AObject.PropertyAttributes[PropertyName, 'Authorization'];
      If Not AnsiSameText(FullPropertyName, 'HostName') And ( AuthorizationAttributeValue > '' ) And Not SameText( AuthorizationAttributeValue, 'Insecure' ) Then
      Begin
        FModel.StringValues[FullPropertyName] := '';
        Response.Cookies.EmptyValues[FullPropertyName] := '';
      End;
      If (AObject.PropertyTypes[PropertyName] = gdtClass) And AObject.ObjectPropertyClassType(PropertyName).InheritsFrom(TgObject) And Not AObject.ObjectPropertyClassType(PropertyName).InheritsFrom(TgIdentityObject) Then
        LogoutInternal( TgObject(AObject.Objects[PropertyName]) );
    End;

*)end;

procedure TgWebServerController.DoAction;
var
  ActionsList: TStringList;
  Counter: Integer;
begin
  If Action > '' Then
  Begin
    ActionsList := TStringList.Create;
    try
      ActionsList.StrictDelimiter := True;
      ActionsList.CommaText := Actions[Action];
{ TODO : Make Secure }
      For Counter := 0 To ActionsList.Count - 1 Do
        FModel[ActionsList.Names[Counter]] := ActionsList.ValueFromIndex[Counter];
    finally
      ActionsList.Free;
    end;
  end;
end;

procedure TgWebServerController.SetAction(const AValue: String);
var
  ActionList: TStringList;
begin
  // Actions come in comma delimited if there are multiple.  Only do the last one.
  If AValue > '' Then
  Begin
    ActionList := TStringList.Create;
    try
      ActionList.StrictDelimiter := True;
      ActionList.CommaText := AValue;
      FAction := ActionList[ActionList.Count - 1];
    finally
      ActionList.Free;
    end;
  End;
end;

procedure TgWebServerController.Login;
begin
  // TODO -cMM: TgWebServerController.Login default body inserted
end;

procedure TgWebServerController.SetCookies(APropertyList: TStringList);
const
  TenYears = 365.25 * 10;
var
  PropertyName: String;
  ExpirationDate: TDateTime;
  Counter: Integer;
  AttributeValue: String;
begin
  For Counter := 0 to APropertyList.Count - 1 Do
  Begin
    AttributeValue := APropertyList.ValueFromIndex[Counter];
    ExpirationDate := 0;
    If SameText( AttributeValue, 'Insecure' ) Then
      ExpirationDate := Now + TenYears
    Else If Not SameText(AttributeValue, 'Secure') Then
      Continue;
    PropertyName := APropertyList.Names[Counter];
    Response.Cookies[PropertyName] := MakeCookie( PropertyName, FModel[PropertyName], '', '', ExpirationDate, False );
  End;
end;

class procedure TgWebServerController.WriteConfiguationData(
  Method: TgWebServerControllerConfigurationDataAnon);
var
  Temp: TgWebServerControllerConfigurationData;
begin
  Temp := WriteConfiguationData;
  try
    Method(Temp);
  finally
    EndWriteConfigurationData;
  end;

end;

{ TgRequest }

destructor TgRequest.Destroy;
begin
  FreeAndNil(FQueryFields);
  FreeAndNil(FHeaderFields);
  FreeAndNil(FCookieFields);
  FreeAndNil(FContentFields);
  FreeAndNil(FContent);
  inherited;
end;

function TgRequest.AsString: String;
var
  StringList: TStringList;
  Field: TgBase.TPathValue;
begin
  StringList := TStringList.Create;
  try
    StringList.Add('Header Fields:');
    for Field in HeaderFields do
      StringList.Add(Field.Text);
    StringList.Add('');
    StringList.Add('Query Fields:');
    for Field in QueryFields do
      StringList.Add(Field.Text);
    StringList.Add('');
    StringList.Add('Cookie Fields:');
    for Field in CookieFields do
      StringList.Add(Field.Text);
    StringList.Add('');
    StringList.Add('Content Fields:');
    for Field in ContentFields do
      StringList.Add(Field.Text);
    StringList.Add('');
    Result := StringList.Text;
  finally
    StringList.Free;
  end;
end;

function TgRequest.GetFields(const AName: String): String;
begin
  Result := ContentFields[AName];
  If Result = '' Then
    Result := CookieFields[AName];
  If Result = '' Then
    Result := HeaderFields[AName];
end;

function TgRequest.GetIsMobile: Boolean;
begin
  Result := SameText(QueryFields['Controller.Request.IsMobile'], 'True') or (SameText(QueryFields['Controller.Request.IsMobile'], '') And SameText(CookieFields['Display-Type'], 'Mobile')) or FIsMobile;
end;

{ TgRequestContentBase }

destructor TgRequestContentBase.Destroy;
begin
  FContent.Free;
  inherited;
end;

function TgRequestContentBase.GetContent: TMemoryStream;
begin
  If Not Assigned(FContent) Then
    FContent := TMemoryStream.Create;
  Result := FContent;
end;

function TgRequestContentBase.GetCurrent: TgRequestContentItemBase;
begin
  Result := TgRequestContentItemBase(Inherited GetCurrent);
end;

function TgRequestContentBase.GetRequest: TgRequest;
begin
  Result := TgRequest(Owner);
end;

constructor TgRequestContentFormData.Create(AOwner: TgBase = nil);
begin
  inherited Create( AOwner );
  ItemClass := TgRequestContentItemFormData;
end;

procedure TgRequestContentFormData.Parse;
begin
  Add;
  TgRequestContentItemBase(Current).Content.CopyFrom(Content, 0);
end;

{ TgRequestContentItemBase }

destructor TgRequestContentItemBase.Destroy;
begin
  FContent.Free;
  inherited;
end;

function TgRequestContentItemBase.FileUploadPath: String;
begin
  Result := G.RootPath + IncludeTrailingPathDelimiter('FileUploads');
end;

function TgRequestContentItemBase.GetContent: TMemoryStream;
begin
  If Not Assigned(FContent) Then
    FContent := TMemoryStream.Create;
  Result := FContent;
end;

function TgRequestContentItemBase.GetRequest: TgRequest;
begin
  Result := TgRequestContentBase(Owner).Request;
end;

{ TgRequestContentItemFile }

function TgRequestContentItemFile.GetContentType: String;
begin

end;

procedure TgRequestContentItemFile.Parse;
Type
  PArrayData = ^TArrayData;
  TArrayData = Array of Byte;
Var
  Position : Integer;
  StringList : TStringList;
  Counter : Integer;
  ContentDisposition : TStringList;
  FileStream : TFileStream;
  FilePath : String;
  FileName : String;
begin
  Position := Pos(CRLF + CRLF, PChar(Content.Memory));
  StringList := TStringList.Create;
  Try
    StringList.Text := Trim(Copy(PChar(Content.Memory), 1, Position - 1));
    For Counter := 0 to StringList.Count - 1 Do
      StringList[Counter] := StringReplace( StringList[Counter], ':', '=', [rfReplaceAll] );
    For Counter := 0 to StringList.Count - 1 Do
      StringList.Values[StringList.Names[Counter]] := Trim(StringList.Values[StringList.Names[Counter]]);
    ContentDisposition := TStringList.Create;
    Try
      ContentDisposition.Text := StringReplace( StringList.Values['Content-Disposition'], ';', CRLF, [rfReplaceAll] );
      For Counter := 0 to ContentDisposition.Count - 1 Do
      Begin
        ContentDisposition[Counter] := Trim(ContentDisposition[Counter]);
        ContentDisposition.ValueFromIndex[Counter] := Trim(ContentDisposition.ValueFromIndex[Counter]);
      End;

      FilePath := FileUploadPath + IncludeTrailingPathDelimiter(IntToStr(GetCurrentThreadId));
      try
        ForceDirectories(FilePath);
        FileName := FilePath + ExtractFileName( AnsiDequotedStr( ContentDisposition.Values['FileName'], '"' ) );
        FileStream := TFileStream.Create(FileName,fmCreate);
        Try
          FileStream.Write(PChar(PChar(Content.Memory) + Position + 3)^, Content.Size - Position - 4);
        Finally
          FileStream.Free;
        End;
      except
      end;
      Request.ContentFields[AnsiDequotedStr( ContentDisposition.Values['Name'], '"' )] := FileName;

{
      FileVariant := VarArrayCreate([0, Content.Size - Position - 5], varByte);
      FileVariantPointer := VarArrayLock(FileVariant);
      Try
        Move(PChar(PChar(Content.Memory) + Position + 3)^, FileVariantPointer^, Content.Size - Position - 4);
      Finally
        VarArrayUnlock(FileVariant);
      End;

      Request.ContentFields[StripQuotes(ContentDisposition.Values['Name']) + '.File'] := FileVariant;
      Request.ContentFields[StripQuotes(ContentDisposition.Values['Name']) + '.FileName'] := StripQuotes(ContentDisposition.Values['FileName']);
      Request.ContentFields[StripQuotes(ContentDisposition.Values['Name']) + '.ContentType'] := StripQuotes(StringList.Values['Content-Type']);

}

    Finally
      ContentDisposition.Free;
    End;
  Finally
    StringList.Free;
  End;
end;

{ TgRequestContentItemFormData }

function TgRequestContentItemFormData.GetContentType: String;
begin


end;

procedure TgRequestContentItemFormData.Parse;
Var
  ContentString : String;
  StringList : TStringList;
  Counter : Integer;
  PropertyName : String;
  PropertyValue : String;
begin
  SetString(ContentString, PChar(Content.Memory), Content.Size);
  ContentString := StringReplace(ContentString, '&', #13#10, [rfReplaceAll]);
  StringList := TStringList.Create;
  Try
    StringList.Text := ContentString;
    For Counter := 0 to StringList.Count - 1 Do
    Begin
//      StringList[Counter] := TidURI.URLDecode(StringReplace(StringList[Counter], '+', ' ', [rfReplaceAll]));
      PropertyName := URLDecode( StringList.Names[Counter] );
      PropertyValue := URLDecode( Copy( StringList[Counter], Pos( '=', StringList[Counter] ) + 1, MaxInt ) ); //StringList.Values[PropertyName];
      If Request.ContentFields[PropertyName] = '' Then
        Request.ContentFields[PropertyName] := PropertyValue
      Else
        Request.ContentFields[PropertyName] := Request.ContentFields[PropertyName] + ',' + PropertyValue;
    End;
  Finally
    StringList.Free;
  End;
end;

{ TgRequestContentItemMultiPartFormData }

procedure TgRequestContentItemMultiPartFormData.Parse;
Var
  Position : Integer;
  StringList : TStringList;
  TempString : String;
  ContentDisposition : TStringList;
  Counter : Integer;
  PropertyName: String;
  PropertyValue: String;
begin
  Position := Pos(CRLF + CRLF, PChar(Content.Memory));
  StringList := TStringList.Create;
  Try
    StringList.Text := Trim(Copy(PChar(Content.Memory), 1, Position - 1));
    If StringList.Count > 0 Then
    Begin
      StringList[0] := StringReplace( StringList[0], ':', '=', [rfReplaceAll] );
      ContentDisposition := TStringList.Create;
      Try
        ContentDisposition.Text := StringReplace( Trim( StringList.Values['Content-Disposition'] ), ';', CRLF, [rfReplaceAll] );
        For Counter := 0 to ContentDisposition.Count - 1 Do
        Begin
          ContentDisposition[Counter] := Trim(ContentDisposition[Counter]);
          TempString := Trim(ContentDisposition.Names[Counter]);
          ContentDisposition.Values[TempString] := Trim(ContentDisposition.Values[TempString]);
        End;
        { TODO -omgenereu : Skipped content encoded option.  Revisit. }
  //      Request.ContentFields.NotEncoded := True;
        PropertyName := AnsiDequotedStr( Trim( ContentDisposition.Values['Name'] ), '"' );
        PropertyValue := Copy(PChar(Content.Memory), Position + 4, Content.Size - Position - 5);
        If Request.ContentFields[PropertyName] = '' Then
          Request.ContentFields[PropertyName] := PropertyValue
        Else
          Request.ContentFields[PropertyName] := Request.ContentFields[PropertyName] + ',' + PropertyValue;
      Finally
        ContentDisposition.Free;
      End;
    End;
  Finally
    StringList.Free;
  End;
end;

constructor TgRequestContentMultiPartFormData.Create(AOwner: TgBase = nil);
begin
  inherited Create( AOwner );
  ItemClass := TgRequestContentItemMultiPartFormData;
end;

procedure TgRequestContentMultiPartFormData.Parse;
var
  Position : Integer;
  Boundary : String;
  ObjectList : TObjectList;
  Counter : Integer;
  Buffer : TBuffer;
  StringList : TStringList;
  HeaderCounter : Integer;
  TempString : String;
  ContentDisposition : TStringList;
  ContentString: string;
begin
  Position := Pos(CRLF, PChar(Content.Memory));
  Boundary := Copy(PChar(Content.Memory), 1, Position - 1);
  ObjectList := TObjectList.Create(True);
  Try
    ContentString := Copy(PChar(Content.Memory), Position + 1, Content.Size - Position);
    SplitBuffer(Boundary, PChar(PChar(Content.Memory) + Position + 1), Content.Size - Position, ObjectList);
    For Counter := 0 to ObjectList.Count - 1 Do
    Begin
      Buffer := TBuffer(ObjectList[Counter]);
      Position := Pos(CRLF + CRLF, PChar(Buffer.Address));
      StringList := TStringList.Create;
      Try
        StringList.Text := Copy(PChar(Buffer.Address), 1, Position - 1);
        For HeaderCounter := 0 to StringList.Count - 1 Do
          StringList[HeaderCounter] := StringReplace( StringList[HeaderCounter], ':', '=', [rfReplaceAll] );
        For HeaderCounter := 0 to StringList.Count - 1 Do
        Begin
          Try
            StringList.Values[StringList.Names[HeaderCounter]] := Trim(StringList.Values[StringList.Names[HeaderCounter]]);
          Except
            On E: Exception Do
              Raise Exception.CreateFmt('%s, %s'#13#10'StringList HeaderCounter: %d'#13#10'ContentString: %s'#13#10'StringList: %s', [E.ClassName, E.Message, HeaderCounter, ContentString, StringList.Text]);
          End;
        End;
        ContentDisposition := TStringList.Create;
        Try
          ContentDisposition.Text := StringReplace( StringList.Values['Content-Disposition'], ';', CRLF, [rfReplaceAll] );
          For HeaderCounter := 0 to ContentDisposition.Count - 1 Do
          Begin
            ContentDisposition[HeaderCounter] := Trim(ContentDisposition[HeaderCounter]);
            Try
              TempString := Trim(ContentDisposition.Names[HeaderCounter]);
            Except
              On E: Exception Do
              Raise Exception.CreateFmt('%s, %s'#13#10'ContentDisposition HeaderCounter: %d'#13#10'%s', [E.ClassName, E.Message, HeaderCounter, ContentDisposition.Text]);
            End;
            ContentDisposition.Values[TempString] := Trim(ContentDisposition.Values[TempString]);
          End;
          If AnsiDequotedStr( ContentDisposition.Values['FileName'], '"' ) > '' Then
            ItemClass := TgRequestContentItemFile
          Else
            ItemClass := TgRequestContentItemMultiPartFormData;
          Add;
          Current.Content.Write(Buffer.Address^, Buffer.Length);
        Finally
          ContentDisposition.Free;
        End;
      Finally
        StringList.Free;
      End;
    End;
  Finally
    ObjectList.Free;
  End;
end;

class constructor TgRequestMap.Create;
begin
  inherited;
  _Builders := TList<TPopulateMethod>.Create;
end;

class destructor TgRequestMap.Destroy;
begin
  FreeAndNil(_Builders);
  inherited;
end;

{ TgRequestMap }

function TgRequestMap.AbsolutePath(ARelativePath: String): String;
Var
  StringList : TStringList;
  Counter : Integer;
begin
  StringList := TStringList.Create;
  Try
    StringList.Delimiter := ';';
    StringList.DelimitedText := ARelativePath;
    For Counter := 0 to StringList.Count - 1 Do
    Begin
      If IsRelativePath( StringList[Counter] ) Then
        StringList[Counter] := IncludeTrailingPathDelimiter( BasePath ) + StringList[Counter];
      If IsRelativePath( BasePath ) Then
        StringList[Counter] := IncludeTrailingPathDelimiter( ExecutablePath ) + StringList[Counter];
    End;
    Result := StringList.DelimitedText;
    if Result[Length(Result)] = ';' then
      SetLength(Result, Length(Result) - 1);
  Finally
    StringList.Free;
  End;
end;

function TgRequestMap.GetLoginTemplate: String;
begin
//  If (Not IsLoading) And Assigned(TemplateRequestMap) And (FLoginTemplate = '') Then
//    Result := TemplateRequestMap.LoginTemplate
//  Else
    Result := FLoginTemplate;
//  If IsRelativePath(Result) Then
//    Result := IncludeTrailingPathDelimiter(BasePath) + Result;
end;

function TgRequestMap.GetPath(ARequestString: String): String;
Var
  Head : String;
  Tail : String;
begin
  ARequestString := Copy(ARequestString, 2, MaxInt);
  SplitRequestPath(ARequestString, Head, Tail);
  Result := GetPathInternal(Head, Tail);
end;

function TgRequestMap.GetPathInternal(const AHead, ATail : String) : String;
Var
  VirtualPathRequestMap : TgRequestMap;
  NewHead : String;
  NewTail : String;
  ResultLength : Integer;
begin
  If VirtualPaths.TryGet(AHead,VirtualPathRequestMap) Then
  Begin
    SplitRequestPath(ATail, NewHead, NewTail);
    Result := VirtualPathRequestMap.GetPathInternal(NewHead, NewTail);
  End
  Else
  Begin
    Result := AHead + '/' + ATail;
    ResultLength := Length(Result);
    If Result[ResultLength] = '/' Then
      Result := Copy(Result, 1, ResultLength - 1);
  End;
end;

function TgRequestMap.GetSearchPath: String;
begin
  If Not IsLoading Then
  Begin
    If FSearchPath > '' Then
      Result := AbsolutePath(FSearchPath)
  End
  Else If Not IsSaving Then
    Result := AbsolutePath(FSearchPath)
  Else
    Result := FSearchPath;
end;

function TgRequestMap.GetSubHost(var AHost: String): TgRequestMap;
Var
  Head : String;
  Tail : String;
begin
  SplitHostPath(AHost, Head, Tail);
  if not SubHosts.TryGet(Head,Result) then exit(Self);
  AHost := Tail;
  If AHost > '' Then
    Result := Result.SubHost[AHost];
End;

function TgRequestMap.GetVirtualPath(var APath : String): TgRequestMap;
var
  Head: String;
  Tail: String;
  VirtualPathRequestMap: TgRequestMap;
begin
  Result := Self;
  SplitRequestPath(APath, Head, Tail);
  If Head = '' Then
    APath := ''
  Else
  Begin
    If VirtualPaths.TryGet(Head,VirtualPathRequestMap) Then
    Begin
      APath := Tail;
      Result := VirtualPathRequestMap.GetVirtualPath(APath);
    End
  End
end;

function TgRequestMap.IsRelativePath(APath: String): Boolean;
Var
  PathLength : Integer;
begin
  PathLength := Length(APath);
  Result := (PathLength > 0) And Not (((PathLength > 0) And (APath[1] = '\')) or ((PathLength > 1) And (APath[2] = ':')));
end;

class procedure TgRequestMap.RegisterBuilder(
  Anon: TPopulateMethod);
begin
  _Builders.Add(Anon);
end;

class procedure TgRequestMap.SplitHostPath(const APath : String; var AHead, ATail : String);
Var
  Position: Integer;
begin
  Position := LastDelimiter('.', APath);
  If Position = 0 Then
  Begin
    AHead := APath;
    ATail := '';
  End
  Else
  Begin
    ATail := Copy(APath, 1, Position - 1);
    AHead := Copy(APath, Position + 1, MaxInt);
  End;
end;

class procedure TgRequestMap.SplitRequestPath(const ARequestPath: String; var AHead, ATail: String);
Var
  Position : Integer;
begin
  AHead := ARequestPath;
  ATail := '';
  If (Length(AHead) > 0) And (AHead[1] = '/') Then
    System.Delete(AHead,1,1);
  Position := Pos('/', AHead);
  If Position > 1 Then
  Begin
    ATail := Copy(AHead, Position + 1, MaxInt);
    AHead := Copy(AHead, 1, Position - 1);
  End;
end;

function TgRequestMap.TopRequestMap: TgRequestMap;
begin
  If Assigned(Owner.Owner) And Owner.Owner.InheritsFrom(TgRequestMap) Then
    Result := TgRequestMap(Owner.Owner).TopRequestMap
  Else
    Result := Self;
end;

// TODO: SetLogClassName
//procedure TgRequestMap.SetLogClassName(const AValue: String);
//begin
//FLogClassName := AValue;
//FLogClass := TgLogClass(G.ClassByName(AValue));
//if Not Assigned(FLogClass) then
//  raise Exception.Create('Invalid Log Class Name');
//end;

constructor TgWebServerControllerConfigurationData.Create(AOwner: TgBase = Nil);
begin
  inherited Create(AOwner);
  RequestMapBuilders := TObjectList.Create();
end;

class destructor TgWebServerControllerConfigurationData.Destroy;
begin
  FreeAndNil(Packages);
end;

destructor TgWebServerControllerConfigurationData.Destroy;
begin
  FreeAndNil(RequestMapBuilders);
  inherited Destroy;
end;

procedure TgWebServerControllerConfigurationData.AddDefaultFileTypes;
begin
  TemplateFileExtensions.Add( 'html' );
  FileTypes['htm'] := 'text/html';
  FileTypes['txt'] := 'text/ascii';
  FileTypes['gif'] := 'image/gif';
  FileTypes['jpg'] := 'image/jpg';
  FileTypes['png'] := 'image/png';
  FileTypes['htf'] := 'text/html';
  FileTypes['html'] := 'text/html';
  FileTypes['jpeg'] := 'image/jpeg';
  FileTypes['xls'] := 'application/vnd.ms-excel';
  FileTypes['htg'] := 'image/gif';
  FileTypes['swf'] := 'application/x-shockwave-flash';
  FileTypes['htt'] := 'text/html';
  FileTypes['css'] := 'text/css';
  FileTypes['pdf'] := 'application/pdf';
  FileTypes['mp3'] := 'audio/mp3';
  FileTypes['wmv'] := 'video/x-ms-wmv';
  FileTypes['mov'] := 'video/quicktime';
  FileTypes['ico'] := 'image/x-icon';
  FileTypes['csv'] := 'text/csv';
  FileTypes['zip'] := 'application/zip';
end;

class function TgWebServerControllerConfigurationData.GetFileName: String;
begin
  Result := IncludeTrailingPathDelimiter( ExecutablePath ) + 'gwscontroller.xml';
end;

class procedure TgWebServerControllerConfigurationData.LoadPackages;
var
  Counter: Integer;
begin
  If Assigned( Packages ) Then
    For Counter := 0 To Packages.Count - 1 Do
      Packages.Objects[Counter] := TObject(LoadPackage( Packages[Counter] ));
end;

class procedure TgWebServerControllerConfigurationData.UnloadPackages;
var
  Counter: Integer;
  Module: Integer;
begin
  If Assigned( Packages ) Then
    For Counter := Packages.Count - 1 DownTo 0 Do
    Begin
      Module := Cardinal(Packages.Objects[Counter]);
      If Module > 0 Then
        UnloadPackage( Module );
    End;
end;

class procedure TgWebServerControllerConfigurationData.RegisterPackage(const APackageName: String);
var
  PackageFileName: String;
  Counter: Integer;
  PackageName: String;
begin
  PackageName := ExpandFileName( APackageName );
  PackageFileName := ExtractFileName( PackageName );
  For Counter := Packages.Count - 1 DownTo 0 Do
  Begin
    If SameText( ExtractFileName( Packages[Counter] ), PackageFileName ) Then
    Begin
      Packages[Counter] := PackageName;
      Exit;
    End;
  End;
  Packages.Add( PackageName )
end;

procedure TgWebServerControllerConfigurationData.Load;
begin
  Hosts.Clear;
  If Not FileExists( FileName ) Then
  Begin
    AddDefaultFileTypes;
    AddDefaultPackages;
    Hosts.Add;
    DefaultHost := 'thebugger.com';
    Hosts.Current.BasePath := 'c:\GWeb';
    Hosts.Current.ID := 'thebugger.com';
    Hosts.Current.VirtualPaths.Add;
    Hosts.Current.VirtualPaths.Current.ID :='LoveBucket';
    Hosts.Current.VirtualPaths.Current.BasePath :='C:\LoveBucket';
    Save;
  End;
  Deserialize(TgSerializerXML, FileToString(FileName));
end;

procedure TgWebServerControllerConfigurationData.Save;
begin
  Packages.SaveToFile(FileNamePackages);

  StringToFile(Serialize(TgSerializerXML), FileName);
end;

function TgWebServerControllerConfigurationData.Serialize(
  ASerializerClass: TgSerializerClass): string;
begin
  Result := Serialize(ASerializerClass,TgWebServerControllerConfigurationData);
end;

procedure TgWebServerControllerConfigurationData.AddDefaultPackages;
begin
  AddDefaultPackage( 'pgFirebird.bpl' );
  AddDefaultPackage( 'pgIndy.bpl' );
end;

class constructor TgWebServerControllerConfigurationData.Create;
begin
  Packages := TStringList.Create;
  if FileExists(FileNamePackages) then
   Packages.LoadFromFile(FileNamePackages);

end;

procedure TgWebServerControllerConfigurationData.AddDefaultPackage(const AFileName: String);
var
  FileName: String;
begin
  FileName := IncludeTrailingPathDelimiter( ExecutablePath ) + AFileName;
  If FileExists(FileName) Then
    Packages.Add(FileName);
end;

procedure TgWebServerControllerConfigurationData.InitializeRequestMapBuilders;
var
  RequestMapBuilder : TgRequestMap.TPopulateMethod;
begin
  for RequestMapBuilder in TgRequestMap._Builders do
    RequestMapBuilder;
end;

class function TgWebServerControllerConfigurationData.FileNamePackages: String;
begin
  Result := ChangeFileExt(FileName,'.pkgs');
end;

procedure TgWebServerControllerConfigurationData.FinalizeRequestMapBuilders;
begin
  FreeAndNil(RequestMapBuilders);
end;


procedure TgWebServerControllerConfigurationData.GetRequestMap(var Host,
  URI: String; out RequestMap: TgRequestMap);
Var
  Head : String;
  Tail : String;
  TopLevelDomain : String;
//  DefaultRequestMap : TgRequestMap;
begin
  // Todo: Make sure DefaultRequestMap is assigned prior to this
//  RequestMap := DefaultRequestMap;
  TopLevelDomain := ExtractFileExt(Host);
  TgRequestMap.SplitHostPath(ChangeFileExt(Host, ''), Head, Tail);
  if Hosts.TryGet(Head + TopLevelDomain,RequestMap) then begin
    Head := Tail;
    if Head > '' then
      RequestMap := RequestMap.SubHost[Head];
  end
  else if not Hosts.TryGet(DefaultHost,RequestMap) then begin
    RequestMap := nil;
    exit;
  end;
  if URI > '' then
    RequestMap := RequestMap.VirtualPath[URI];

end;

function TgRequestLogItem.GetDuration: Integer;
begin
  If FDuration = 0 Then
    FDuration := MilliSecondOfTheDay(Now - FDateTime);
  Result := FDuration;
end;

function TgRequestLogItem.GetWebServerController: TgWebServerController;
begin
  Result := TgWebServerController(Owner);
end;

constructor TgResponse.Create(AOwner: TgBase = Nil);
begin
  inherited Create( AOwner );
  StatusCode := 200;
  FContentStream := TMemoryStream.Create();
end;

destructor TgResponse.Destroy;
begin
  FreeAndNil(FContentStream);
  FContentStream.Free;
  FHeaderFields.Free;
  FCookies.Free;
  inherited;
end;

function TgResponse.GetFriendlyClassName: string;
begin
  Result := 'gResponse';
end;

function TgResponse.GetReasonPhrase: String;
begin
  case FStatusCode of
    // 2XX: Success
    200: Result := 'OK';
    201: Result := 'Created';
    202: Result := 'Accepted';
    203: Result := 'Non-Authoritative Information';
    204: Result := 'No Content';
    205: Result := 'Reset Content';
    206: Result := 'Partial Content';
    // 3XX: Redirections
    301: Result := 'Moved Permanently';
    302: Result := 'Moved Temporarily';
    303: Result := 'See Other';
    304: Result := 'Not Modified';
    305: Result := 'Use Proxy';
    // 4XX Client Errors
    400: Result := 'Bad Request';
    401: Result := 'Unauthorized';
    403: Result := 'Forbidden';
    404: Result := 'Not Found';
    405: Result := 'Method Not Allowed';
    406: Result := 'Not Acceptable';
    407: Result := 'Proxy Authentication Required';
    408: Result := 'Request Timeout';
    409: Result := 'Conflict';
    410: Result := 'Gone';
    411: Result := 'Length Required';
    412: Result := 'Precondition Failed';
    413: Result := 'Request Entity Too Long';
    414: Result := 'Request URI Too Long';
    415: Result := 'Unsupported Media Type';
    // 5XX Server errors
    500: Result := 'Internal Server Error';
    501: Result := 'Not Implemented';
    502: Result := 'Bad Gateway';
    503: Result := 'Service Unavailable';
    504: Result := 'Gateway Timeout';
    505: Result := 'HTTP Version Not Supported';
  else
    Result := 'Unknown Response Code';
  end;
end;

function TgResponse.GetStatusLine: String;
begin
  Result := Format('HTTP/1.0 %d %s', [StatusCode, ReasonPhrase]);
end;

function TgResponse.GetText: AnsiString;
begin
  SetLength(Result, ContentStream.Size);
  Move((ContentStream as TMemoryStream).Memory^, pAnsiChar(Result)^, ContentStream.Size);
end;

procedure TgResponse.SetDate(const Value: TDateTime);
begin
  FDate := Value;
  HeaderFields['Date'] := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss "GMT"', FDate + TimeZoneBias);
end;

procedure TgResponse.SetExpires(const Value: TDateTime);
begin
  FExpires := Value;
  HeaderFields['Expires'] := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss "GMT"', FExpires + TimeZoneBias);
end;

procedure TgResponse.SetRedirect(const AURL: String);
begin
  StatusCode := 301;
  HeaderFields['Location'] := AURL;
end;

procedure TgResponse.SetHeader(const AValue: String);
var
  Name : String;
  Value : String;
begin
  SplitOnChar(AValue, '=', Name, Value);
  HeaderFields[Name] := Value;
end;

procedure TgResponse.SetSetMobile(const AValue: Boolean);
begin
  IsMobile := AValue;
  Redirect := '/';
end;

procedure TgResponse.SetIsMobile(const AValue: Boolean);
var
  Value: string;
  WebServerController: TgWebServerController;
begin
  If AValue Then
    Value := 'Mobile'
  Else
    Value := 'Desktop';
  If Owner.InheritsFrom(TgWebServerController) Then
  Begin
    WebServerController := TgWebServerController(Owner);
    Cookies['Display-Type'] := WebServerController.MakeCookie('Display-Type', Value, '', '', SysUtils.Date + 1000, WebServerController.Request.IsSecure);
  End;
end;

class function TgWebServerController.FileUploadPath: String;
begin
  Result := G.RootPath + IncludeTrailingPathDelimiter('FileUploads');
end;

function TgWebServerController.FindDocument(const ADocument: String): String;
var
  UnvirtualizedDocument: String;
begin
  Result := '';
  If (RequestMap.SearchPath > '') And (ADocument > '') Then
  Begin
    UnvirtualizedDocument := StringReplace( ADocument, '/', '\', [rfReplaceAll] );
    If UnvirtualizedDocument[1] = '\' Then
      Delete(UnvirtualizedDocument, 1, 1);
    Result := FileSearch( UnvirtualizedDocument, RequestMap.SearchPath );
  End;
end;

function TgRequest.GetHost: String;
begin
  Result := HeaderFields.Host;
end;

procedure TgRequest.SetHost(const AValue: String);
begin
  HeaderFields.Host := AValue;
end;

function TgWebServerController.EFileNotFound.ResponseCode: Integer;
begin
  Result := 404;
end;

function TgWebServerController.E.ResponseCode: Integer;
begin
  Result := 500;
end;


constructor TgRequestMap.Create(AOwner: TgBase);
begin
  inherited;
  FVirtualPaths := TgRequestMaps.Create;
  FSubHosts := TgRequestMaps.Create;
end;

destructor TgRequestMap.Destroy;
begin
  FreeAndNil(FSubHosts);
  FreeAndNil(FVirtualPaths);
  inherited;
end;

{ TMemoryStream_Helper }

procedure TMemoryStream_Helper.WriteString(const Value: String);
begin
  WriteBuffer(pChar(Value)^,ByteLength(Value));
end;

{ TgRequestMap.TgRequestMaps }

constructor TgRequestMap.TgRequestMaps.Create(Owner: TgBase);
begin
  inherited;
  Buffered := True;
  Active := True;
end;

{ TgWebRequestParser }

constructor TgWebRequestParser.Create(ARequest: TgRequest);
begin
  inherited Create;
  FRequest := ARequest;
end;

procedure TgWebRequestParser.GetData;
begin
//  DebugLog.WriteLn( 'Parsing request' );
  ReadRequestLine;
  ReadHeaderFields;
  ReadQueryFields;
  ReadCookieFields;
  ReadContentFields;
end;

class procedure TgWebRequestParser.PopulateCookieFields(const ACookieString: String; ACookieFields: TgDictionary);
var
  StringList: TStringList;
  CookieString: String;
  TempString: String;
  CookieName: String;
  CookieValue: String;
begin
  TempString := Trim(ACookieString);
  TempString := StringReplace(TempString, ';', #13#10, [rfReplaceAll]);
  StringList := TStringList.Create;
  try
    StringList.Text := TempString;
    For CookieString In StringList Do
    Begin
      SplitOnChar(CookieString, '=', CookieName, CookieValue);
      CookieName := Trim(CookieName);
      CookieValue := AnsiDequotedStr(Trim(CookieValue), '"');
      If ACookieFields[CookieName] = '' Then
        ACookieFields[CookieName] := CookieValue;
    End;
  Finally
    StringList.Free;
  End;
end;

class procedure TgWebRequestParser.PopulateHeaderFields(AHeaderString: String; AHeaderFields: TgHeaderFields);
var
  HeaderLine: String;
  HeaderStringList: TStringList;
  Name: string;
  Value: string;
begin
  HeaderStringList := TStringList.Create;
  try
    HeaderStringList.Text := AHeaderString;
    For HeaderLine In HeaderStringList Do
    Begin
      SplitOnChar(HeaderLine, ':', Name, Value);
      try
        Name := Trim(URLDecode(Name));
      except
      end;
      try
        Value := Trim(URLDecode(Value));
      except
      end;
      If Value > '' Then
        AHeaderFields[Name] := Value;
    End;
  finally
    HeaderStringList.Free;
  end;
end;

class procedure TgWebRequestParser.PopulateQueryFields(const AQueryString: String; AQueryFields: TgDictionary);
var
  StringList: TStringList;
  URLElement: String;
  PropertyName: string;
  PropertyValue: String;
begin
  If AQueryString > '' Then
  Begin
    StringList := TStringList.Create;
    Try
      StringList.CommaText := '"' + StringReplace(AQueryString, '&', '","', [rfReplaceAll]) + '"';
      For URLElement In StringList Do
      Begin
        SplitOnChar( URLElement, '=', PropertyName, PropertyValue );
        PropertyName := URLDecode( PropertyName );
        PropertyValue := URLDecode( PropertyValue );
        If AQueryFields[PropertyName] = '' Then
          AQueryFields[PropertyName] := PropertyValue
        Else
          AQueryFields[PropertyName] := AQueryFields[PropertyName] + ',' + PropertyValue;
      End;
    Finally
      StringList.Free;
    End;
  End;
end;

function TgWebRequestParser.RemoveContentTypeExtraData(AContentType: String): String;
var
  ContentTypeSemicolon: Integer;
begin
  ContentTypeSemicolon := Pos( ';', AContentType );
  If ContentTypeSemicolon > 0 Then
    Result := Copy( AContentType, 1, ContentTypeSemicolon - 1 )
  Else
    Result := AContentType;
end;

destructor TgWebRequestParser.Destroy;
Var
  FilePath : String;
  SearchRec : TSearchRec;
begin
  FilePath := TgWebServerController.FileUploadPath + IncludeTrailingPathDelimiter(IntToStr(GetCurrentThreadId));
  If Request.MultiPart And DirectoryExists( FilePath ) Then
  Begin
    Try
      If ( SysUtils.FindFirst( FilePath + '*.*', faAnyFile, SearchRec ) = 0 ) Then
      Begin
        Repeat
          If ( SearchRec.Attr And faDirectory ) = 0 Then
            SysUtils.DeleteFile( FilePath + SearchRec.Name );
        Until FindNext( SearchRec ) <> 0;
      End;
    Finally
      SysUtils.FindClose( SearchRec );
    End;
    RemoveDir( FilePath );
  End;
  inherited;
end;

{ TgWebAdapter }

constructor TgWebAdapter.Create;
begin
  Try
    TgWebServerController.ConfigurationData.Load;
    TgWebServerController.ConfigurationData.InitializeRequestMapBuilders;
  Except
  End;
end;

destructor TgWebAdapter.Destroy;
begin
  Try
    TgWebServerController.ConfigurationData.FinalizeRequestMapBuilders;
    G.Finalize;
    TgWebServerController.ConfigurationData.UnloadPackages;
    inherited Destroy;
  Except
  End;
end;

constructor TgWebResponseGenerator.Create(AController: TgWebServerController);
begin
  inherited Create;
  FHeaderStream := TStringStream.Create( '' );
  FContentStream := TStringStream.Create( '' );
  FController := AController;
  FRequest := FController.Request;
  FResponse := FController.Response;
end;

destructor TgWebResponseGenerator.Destroy;
begin
  FreeAndNil(FContentStream);
  FreeAndNil(FHeaderStream);
  inherited Destroy;
end;

procedure TgWebResponseGenerator.PopulateHeaderStream;
Var
  Header : TgHeaderFields.TPathValue;
begin
  For Header In Response.HeaderFields Do
    HeaderStream.WriteString( Header.Path + ': ' + Header.Value + CRLF );
  For Header In Response.Cookies Do
    HeaderStream.WriteString( 'Set-Cookie: ' + Header.Path + '=' + Header.Value + CRLF );
  HeaderStream.WriteString( '' + CRLF );
end;

procedure TgWebResponseGenerator.SendData;
var
  SendFileName: String;
  SendFileStream: TFileStream;
  LastModified: TDateTime;
  IfModifiedSince: TDateTime;
  LastModifiedString: String;
  SendFileDelete: Boolean;
  IfModifiedSinceString: String;
begin
//  DebugLog.WriteLn( 'Generating response' );
  SendFileName := Response.HeaderFields['X-SendFile'];
  If SendFileName > '' Then
  Begin
    SendFileDelete := SameText( Response.HeaderFields['X-SendFileDelete'], 'True' );
    Response.HeaderFields.Delete( 'X-SendFile' );
    FileAge( SendFileName, LastModified );
    IfModifiedSinceString := Request.HeaderFields['If-Modified-Since'];
    // This should be parsed in the request.
    If IfModifiedSinceString > '' Then
      IfModifiedSince := ParseRFC822DateString( IfModifiedSinceString ) - TimeZoneBias
    Else
      IfModifiedSince := 0;
    If ( IfModifiedSince = 0 ) Or ( IfModifiedSince >= LastModified ) Then
    Begin
      LastModifiedString := Format(FormatDateTime(sDateFormat + ' "GMT; "', LastModified + TimeZoneBias), [DayOfWeekStr(LastModified), MonthStr(LastModified)]);
      Response.HeaderFields['Last-Modified'] := LastModifiedString;
      SendFileStream := TFileStream.Create( SendFileName, fmOpenRead + fmShareDenyWrite );
      try
        SendStream( SendFileStream );
      finally
        SendFileStream.Free;
      end;
    End
    Else
    Begin
      Response.StatusCode := 304;
      SendStream( nil );
    End;
    If SendFileDelete Then
      SysUtils.DeleteFile( SendFileName );
  End
  Else
    SendStream( Response.ContentStream );
end;

end.

