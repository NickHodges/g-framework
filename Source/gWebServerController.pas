unit gWebServerController;

interface

uses
  gCore
  , System.Classes
  , Contnrs
  , SysUtils
  , StrUtils
  ;

type
  TgRequestContentBase = class;
  TgWebServerControllerConfigurationData = class;
  TgRequestLogItem = class;
  TgResponse = class;
  TgRequest = class(TgBase)
  strict private
    FContent: TgRequestContentBase;
    FHeaderFields: TgDictionary;
    FQueryFields: TgDictionary;
    FCookieFields: TgDictionary;
    FContentFields: TgDictionary;
    FMaxFileUploadSize: Integer;
    FMultiPart: Boolean;
    FURI: String;
    FIPAddress: String;
    FIsSecure: Boolean;
    FIsMobile: Boolean;
    function GetFields(const AName: String): String;
    function GetIsMobile: Boolean;
  Public
    Destructor Destroy;Override;
    function AsString: String;
    Property Content : TgRequestContentBase read FContent write FContent;
    property Fields[const AName: String]: String read GetFields; default;
    property MaxFileUploadSize: Integer read FMaxFileUploadSize write FMaxFileUploadSize;
    Property MultiPart : Boolean read FMultiPart write FMultiPart;
  Published
    property ContentFields: TgDictionary read FContentFields;
    property CookieFields: TgDictionary read FCookieFields;
    property HeaderFields: TgDictionary read FHeaderFields;
    property QueryFields: TgDictionary read FQueryFields;
    property URI: String read FURI write FURI;
    property IPAddress: String read FIPAddress write FIPAddress;
    property IsSecure: Boolean read FIsSecure write FIsSecure;
    property IsMobile: Boolean read GetIsMobile write FIsMobile;
  End;

  TgRequestDistiller = class
  end;

  TgRequestContentItemBase = class(TgBase)
  private
    FContentLength: Integer;
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
  strict private
    FActions: TgDictionary;
    FModel: TgModel;
    FRequest: TgRequest;
    FResponse: TgResponse;
    FUIState: TgDictionary;
    FLogItem: TgRequestLogItem;
    FRequestDistiller: TgRequestDistiller;
    function GetRequest: TgRequest;
    function GetResponse: TgResponse;
    procedure PopulateModelFromRequest;
    procedure PushAuthorizationValues(AObject: TgObject; AStringList: TStringList);
    procedure LogOutInternal(AObject: TgBase);
    procedure ConvertEncryptedQueryFields(const APassword: String);
    procedure DoAction;
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
    destructor Destroy; override;
    class function ReadConfigurationData: TgWebServerControllerConfigurationData;
    class procedure EndReadConfigurationData;
    class procedure EndWriteConfigurationData;
    class function WriteConfiguationData: TgWebServerControllerConfigurationData;
    procedure Execute;
    procedure Login;
    procedure LogOut;
    function MakeCookie(const AName, AValue, ADomain, APath: String; const AExpiration: TDateTime; ASecure: Boolean): String;
  published
    property Action: String read FAction write SetAction;
    property Actions: TgDictionary read FActions;
    property Request: TgRequest read GetRequest;
    property Response: TgResponse read GetResponse;
    property UIState: TgDictionary read FUIState;
    property LogItem: TgRequestLogItem read FLogItem;
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
      TgRequestMaps = TgIdentityList<TgRequestMap>;
  strict private
    FVirtualPaths: TgRequestMaps;
    FSearchPath : String;
    FSubHosts: TgRequestMaps;
    FDefaultPage : String;
    FRedirect : String;
    FLogClassName : String;
    FModelClassName: String;
    FTemplateRequestMap: TgRequestMap;
    FBasePath: String;
    FHosts: TgIdentityList;
    FLoginTemplate: String;
    FSecurePath: String;
    FPathQuery: Boolean;
    FMobileSearchPath: String;
    function GetDefaultPage: String;
    function GetLogClassName: String;
    function GetModelClassName: String;
    function GetTemplateRequestMap: TgRequestMap;
    function GetBasePath: String;
    function GetSubHost(const AHost: String): TgRequestMap;
    function GetLoginTemplate: String;
  strict protected
    function GetVirtualPath(var APath : String): TgRequestMap;
    Function GetPathInternal(const AHead, ATail : String) : String;
    function GetPath(ARequestString: String): String;
    function AbsolutePath(ARelativePath: String): String;
    Function IsRelativePath(APath : String) : Boolean;
    Function GetSearchPath : String;
    function GetMobileSearchPath: String;
    Property TemplateRequestMap : TgRequestMap read GetTemplateRequestMap;
    property Hosts: TgIdentityList read FHosts;
  Public
    class procedure SplitHostPath(const APath : String; var AHead, ATail : String);
    class Procedure SplitRequestPath(const ARequestPath : String; var AHead, ATail : String); Virtual;
    Function TopRequestMap : TgRequestMap;
    property VirtualPath[var APath : String]: TgRequestMap read GetVirtualPath;
    Property Path[ARequestString : String] : String read GetPath;
    Property SubHost[const AHost : String] : TgRequestMap read GetSubHost;
  Published
    Property BasePath : String read GetBasePath write FBasePath;
    Property SearchPath : String read GetSearchPath write FSearchPath;
    property MobileSearchPath: String read GetMobileSearchPath write FMobileSearchPath;
    property VirtualPaths: TgRequestMaps read FVirtualPaths stored False;
    property SubHosts: TgRequestMaps read FSubHosts;
    Property DefaultPage : String read GetDefaultPage write FDefaultPage;
    Property Redirect : String read FRedirect write FRedirect;
    Property LogClassName : String read GetLogClassName write FLogClassName;
    property ModelClassName: String read GetModelClassName write FModelClassName;
    Property LoginTemplate : String read GetLoginTemplate write FLoginTemplate;
    property SecurePath: String read FSecurePath write FSecurePath;
    property PathQuery: Boolean read FPathQuery write FPathQuery;
  End;

  TgWebServerControllerConfigurationData = class(TgBase)
  strict private
    FDefaultHost: String;
    FFileTypes: TgDictionary;
    FPackages: String;
    FTemplateFileExtensions: String;
    FHosts: TgRequestMap.TgRequestMaps;
    RequestMapBuilders: TObjectList;
    procedure AddDefaultFileTypes;
    function FileName: String;
    procedure AddDefaultPackages;
    procedure AddDefaultPackage(const AFileName: String);
    function GetHost(const AHost : String): TgRequestMap;
  public
    constructor Create(AOwner: TgBase = Nil); override;
    destructor Destroy; override;
    procedure LoadPackages;
    procedure UnloadPackages;
    procedure RegisterPackage(const APackageName: String);
    procedure Load;
    procedure Save;
    procedure InitializeRequestMapBuilders;
    procedure FinalizeRequestMapBuilders;
    property Host[const AHost : String]: TgRequestMap read GetHost;
  published
    property DefaultHost: String read FDefaultHost write FDefaultHost;
    property FileTypes: TgDictionary read FFileTypes;
    property Hosts: TgRequestMap.TgRequestMaps read FHosts;
    property Packages: String read FPackages write FPackages;
    property TemplateFileExtensions: String read FTemplateFileExtensions write FTemplateFileExtensions;
  end;

  TgRequestLogItem = class(TgBase)
  strict private
    FDateTime: TDateTime;
    FDuration: Integer;
    FStatusCode: Integer;
    FIPAddress: TgIPAddressString;
    FMethod: TgRequestMethodString;
    FUserAgent: TgUserAgentString;
    function GetDuration: Integer;
    function GetHost: TgURI;
    function GetReferer: TgURI;
    function GetWebServerController: TgWebServerController;
  strict protected
    property WebServerController: TgWebServerController read GetWebServerController;
  public
    procedure Populate; override;
  Published
    property DateTime: TDateTime read FDateTime write FDateTime;
    property Duration: Integer read GetDuration write FDuration;
    property IPAddress: TgIPAddressString read FIPAddress write FIPAddress;
    property Host: TgURI read GetHost;
    property Referer: TgURI read GetReferer;
    property Method: TgRequestMethodString read FMethod write FMethod;
    property UserAgent: TgUserAgentString read FUserAgent write FUserAgent;
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
  Public
    constructor Create(AOwner: TgBase = Nil); override;
    Destructor Destroy;Override;
    class function FriendlyClassName: string; override;
    property ContentStream: TMemoryStream read FContentStream;
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

implementation

Uses
  SysUtils
  ;

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

function TgWebServerController.GetRequest: TgRequest;
begin
  ReturnObjectReference( Result, FRequest, TgRequest, ooNone );
end;

function TgWebServerController.GetResponse: TgResponse;
begin
  ReturnObjectReference( Result, FResponse, TgResponse, ooNone );
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
  SerializationFormat: TgSerializationFormatXHTML;
  FileName: String;
  FileStream: TFileStream;
  SourceDocument: TgXMLDocument;
  PropertyList: TStringList;
  RequestLogItemClass : TgRequestLogItemClass;
  LoadList: TList;
  FileExtention: String;
  MimeType: String;
  RedirectString: String;
begin
//  DebugLog.WriteLn( 'Controller processing' );
  try
    FRequestDistiller := TgRequestDistiller.Create( Self );
    try
      RequestLogItemClass := FRequestDistiller.LogClass;
      If Assigned(RequestLogItemClass) Then
        FLogItem := RequestLogItemClass.Create(Self);
      If FRequestDistiller.Encryption Then
        ConvertEncryptedQueryFields( FRequestDistiller.EncryptionPassword );
      If FRequestDistiller.Redirect > '' Then
      Begin
        Response.StatusCode := 301;
        Response.HeaderFields['Location'] := FRequestDistiller.Redirect;
      End
      Else If FRequestDistiller.IsTemplate Or FRequestDistiller.IsPathQuery Then
      Begin
        IPAddressLog.Add(Request.IPAddress);
        FModel := FRequestDistiller.ModelClass.Create;
        try
          FModel.Controller := Self;

          PropertyList := TStringList.Create;
          try
            PushAuthorizationValues(FModel, PropertyList);
            LoadList := TList.Create;
            try
//              FModel.BeforeAuthorization( PropertyList, LoadList );
              If FModel.IsAuthorized Then
              Begin
                FileName := FRequestDistiller.FileName;
                PopulateModelFromRequest;
//                FModel.AfterPopulate( PropertyList, LoadList );
                SetCookies( PropertyList );
              End
              Else
                FileName := FRequestDistiller.LoginTemplateFileName;
            finally
              LoadList.Free;
            end;
            //If PopulateModelFromRequest didn't create a file to be sent in place of the template response
            If FRequestDistiller.IsTemplate And (Response.HeaderFields['X-SendFile'] = '') Then
            Begin
              SourceDocument := TgXMLDocument.Create;
              SerializationFormat := TgSerializationFormatXHTML.Create;
              FileStream := TFileStream.Create( FileName, fmOpenRead + fmShareDenyWrite );
              try
                SourceDocument.SearchPath := FRequestDistiller.SearchPath;
                If FRequestDistiller.Encryption Then
                  SourceDocument.EncryptionPassword := FRequestDistiller.EncryptionPassword;
                SourceDocument.AliasPath := FRequestDistiller.AliasPath;
                SourceDocument.SecurePath := FRequestDistiller.SecurePath;
                SourceDocument.IsSecure := FRequest.IsSecure;
                SourceDocument.IsMobile := FRequest.IsMobile;
                SerializationFormat.ShowDeclaration := False;
                gDOM.EvaluateTemplate( FileStream, Response.ContentStream, FModel, SourceDocument, SerializationFormat );
                Response.HeaderFields['Expires'] := Format(FormatDateTime(sDateFormat + ' "GMT; "', Now + TimeZoneBias), [DayOfWeekStr(Now), MonthStr(Now)]);
              finally
                FileStream.Free;
                SerializationFormat.Free;
                SourceDocument.Free;
              end;
            End;
          finally
            PropertyList.Free;
          end;
          If Assigned(LogItem) Then
          Begin
            Try
              LogItem.Populate;
            Except
            End;
          End;
        finally
          FModel.Free;
        end;
      End;
      If Not (Response.StatusCode > 301) And Not FRequestDistiller.IsTemplate Then
        Response.HeaderFields['X-SendFile'] := FRequestDistiller.Filename;
      If Response.StatusCode = 301 Then
      Begin
        Response.ContentStream.Clear;
        if EvaluatePartials then
        Begin
          Response.StatusCode := 200;
          RedirectString := Format( '<div redirect="%s"></div>', [Response.HeaderFields['Location']] );
          Response.HeaderFields['Location'] := '';
          Response.ContentStream.Write( RedirectString[1], Length( RedirectString ) );
        End;
      End
      Else If Response.StatusCode = 200 Then
      Begin
        FileExtention := ExtractFileExt( FRequestDistiller.Filename );
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
      End;
    finally
      FreeAndNil( FRequestDistiller );
    end;
    Response.Date := Now;
  Except
    On E: Exception Do
    Begin
      If E.InheritsFrom( EgWebServerController ) Then
      Begin
        Response.StatusCode := EgWebServerController(E).ResponseCode;
        Response.ContentStream.Write( PChar(E.message)^, Length( E.Message ) );
      End
      Else
      Begin
        Response.StatusCode := 500;
        Response.ContentStream.Write( PChar(E.message)^, Length( E.Message ) );
        Raise;
      End;
    End;
  End;
  If Assigned(LogItem) Then
  Begin
    Try
      LogItem.StatusCode := Response.StatusCode;
      try
        LogItem.Save;
      except
      end;
    Finally
      LogItem.Free
    End;
  End;
end;

procedure TgWebServerController.PopulateModelFromRequest;
var
  StringHashValue: TgOrderedStringHashValue;
  NewName: String;
  TempName: String;
  RequestFields: TgOrderedStringHashTable;
  RequestFieldsArray: Array[0..1] Of TgOrderedStringHashTable;
  LastTwoChars: String;
  MethodFound: Boolean;
  TempObject : TgObject;
begin
  MethodFound := False;
  RequestFieldsArray[0] := Request.QueryFields;
  RequestFieldsArray[1] := Request.ContentFields;
  Try
    For RequestFields In RequestFieldsArray Do
    Begin
      For StringHashValue In RequestFields Do
      Begin
        try
          NewName := StringHashValue.Name;
          If NewName = '' Then
            Continue;
          LastTwoChars := Copy( StringHashValue.Name, Length( StringHashValue.Name ) - 1, MaxInt );
          If SameText( LastTwoChars, '.y' ) And MethodFound Then
            MethodFound := False
          Else
          Begin
            If SameText( LastTwoChars, '.x' ) Then
            Begin
              TempName := Copy( StringHashValue.Name, 1, Length( StringHashValue.Name ) - 2 );
              If FModel.MethodExistsOnPath[TempName] Then
              Begin
                NewName := TempName;
                MethodFound := True;
              End;
            End;
            If FModel.PropertyTypes[NewName] = gdtBoolean Then
            Begin
              If ( StringHashValue.Value = '' ) Or SameText( StringHashValue.Value, 'False' )  Then
                FModel.StringValuesSecure[NewName] := 'False'
              Else
                FModel.StringValuesSecure[NewName] := 'True';
            End
            Else
              FModel.StringValuesSecure[NewName] := StringHashValue.Value;
          End;
        except
          On E: EgValidation Do
            Raise;
          On E: Exception Do
          Begin
            Try
              TempObject := TgObject(FModel.LastObject(NewName, TempName));
              If Assigned(TempObject) and TempObject.InheritsFrom(TgObject) Then
              Begin
                TempObject.ValidationErrors[TempName] := E.Message;
                TempObject.ValidationErrors.Objects[TempName].ErrorLevel := gelTypeConversion;
                TempObject.ValidationErrors.Objects[TempName].TypeConversionErrorValue := StringHashValue.Value;
              End;
            Except
              On E: Exception Do
                Raise Exception.CreateFmt('%s, %s, NewName: %s, TempName: %s, StringHashValue.Value: %s', [E.ClassName, E.Message, NewName, TempName, StringHashValue.Value]);
            End;
          End;
        end;
      End;
    End;
    DoAction;
  Except
    On E: EgValidation Do
    Begin
      ValidationError := True;
      With FModel.ValidationErrors Do
      Begin
        Message := 'Please fix items in red.';
        ErrorLevel := gelError;
      End;
    End;
  End;
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

procedure TgWebServerController.PushAuthorizationValues(AObject: TgObject; AStringList: TStringList);
var
  PropertyName: String;
  FullPropertyName: String;
  Counter: Integer;
  AuthorizationAttributeValue : String;
  ObjectPropertyClassType: TgIdentityObjectClass;
  FullPropertyValue: String;
begin
  For Counter := 0 to AObject.VisiblePropertyNames.Count - 1 Do
  Begin
    PropertyName := AObject.VisiblePropertyNames[Counter];
    FullPropertyName := AObject.ObjectPathName;
    If FullPropertyName > '' Then
      FullPropertyName := FullPropertyName + '.';
    FullPropertyName := FullPropertyName + PropertyName;
    If AObject.PropertyIsObject(PropertyName) Then
    Begin
      ObjectPropertyClassType := TgIdentityObjectClass(AObject.ObjectPropertyClassType(PropertyName));
      If ObjectPropertyClassType.InheritsFrom(TgIdentityObject) Then
        FullPropertyName := FullPropertyName + '.' + ObjectPropertyClassType.KeyPropertyName;
    End;
    AuthorizationAttributeValue := AObject.PropertyAttributes[PropertyName, 'Authorization'];
    If Not (AuthorizationAttributeValue = '') And Not SameText( AuthorizationAttributeValue, 'False' ) Then
    Begin
      AStringList.Values[FullPropertyName] := AuthorizationAttributeValue;
      FModel.StringValues[FullPropertyName] := Request.Fields[FullPropertyName];
    End;
    If AObject.PropertyIsObject(PropertyName) And AObject.ObjectPropertyClassType(PropertyName).InheritsFrom(TgObject) And Not AObject.ObjectPropertyClassType(PropertyName).InheritsFrom(TgIdentityObject) Then
      PushAuthorizationValues(TgObject(AObject.Objects[PropertyName]), AStringList);
  End;
  // Special case for Logout
  FullPropertyName := 'Controller.Logout';
  FullPropertyValue := Request.Fields[FullPropertyName];
  If FullPropertyValue > '' Then
    FModel.StringValues[FullPropertyName] := Request.Fields[FullPropertyName];
  FullPropertyName := 'Model.Controller.Logout';
  FullPropertyValue := Request.Fields[FullPropertyName];
  If FullPropertyValue > '' Then
    FModel.StringValues[FullPropertyName] := Request.Fields[FullPropertyName];
end;

procedure TgWebServerController.LogOutInternal(AObject: TgBase);
var
  Counter: Integer;
  PropertyName: String;
  FullPropertyName: String;
  AuthorizationAttributeValue: String;
begin
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
end;

procedure TgWebServerController.ConvertEncryptedQueryFields(const APassword: String);
var
  Counter: Integer;
  FieldList : TList;
  Item: TgOrderedStringHashValue;
  GIValue: String;
begin
  FieldList := TList.Create;
  try
    Request.QueryFields.PopulateList( FieldList );
    For Counter := 0 to FieldList.Count - 1 Do
    Begin
      Item := TgOrderedStringHashValue(FieldList[Counter]);
      If SameText( 'GI', Item.Name ) Then
      Begin
        GIValue := Item.Value;
        Request.QueryFields.Delete( 'GI' );
        TgWebRequestParser.PopulateQueryFields( DeEscapeHTML( ObfuscateDecode( GIValue, APassword ) ), Request.QueryFields );
        Exit;
      End;
    End;
  finally
    FieldList.Free;
  end;
end;

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
      For Counter := 0 To ActionsList.Count - 1 Do
        FModel.StringValuesSecure[ActionsList.Names[Counter]] := ActionsList.ValueFromIndex[Counter];
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
    Response.Cookies[PropertyName] := MakeCookie( PropertyName, FModel.StringValues[PropertyName], '', '', ExpirationDate, False );
  End;
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
  Field: TgOrderedStringHashValue;
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
            NewItemClass := TgRequestContentItemFile
          Else
            NewItemClass := TgRequestContentItemMultiPartFormData;
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

{ TgRequestMap }

function TgRequestMap.AbsolutePath(ARelativePath: String): String;
Var
  StringList : TStringList;
  Counter : Integer;
begin
  StringList := TStringList.Create;
  Try
    StringList.Text := StringReplace(ARelativePath, ';', CRLF, [rfReplaceAll]);
    For Counter := 0 to StringList.Count - 1 Do
    Begin
      If IsRelativePath( StringList[Counter] ) Then
        StringList[Counter] := IncludeTrailingPathDelimiter( BasePath ) + StringList[Counter];
      If IsRelativePath( BasePath ) Then
        StringList[Counter] := IncludeTrailingPathDelimiter( ExecutablePath ) + StringList[Counter];
    End;
    Result := StringReplace(StringList.Text, CRLF, ';', [rfReplaceAll]);
    SetLength(Result, Length(Result) - 1);
  Finally
    StringList.Free;
  End;
end;

function TgRequestMap.GetModelClassName: String;
begin
  If (Not IsLoading) And Assigned(TemplateRequestMap) And (FModelClassName = '') Then
    Result := TemplateRequestMap.ModelClassName
  Else
    Result := FModelClassName;
end;

function TgRequestMap.GetBasePath: String;
begin
  If (Not IsLoading) And Assigned(TemplateRequestMap) And (FBasePath = '') Then
    Result := TemplateRequestMap.BasePath
  Else
    Result := FBasePath;
end;

function TgRequestMap.GetDefaultPage: String;
begin
  If (Not IsLoading) And Assigned(TemplateRequestMap) And (FDefaultPage = '') Then
    Result := TemplateRequestMap.DefaultPage
  Else
    Result := FDefaultPage;
end;

function TgRequestMap.GetSubHost(const AHost: String): TgRequestMap;
Var
  Head : String;
  Tail : String;
begin
  SplitHostPath(AHost, Head, Tail);
  if not SubHosts.TryGet(Head,Result) then exit(Self);
  If Tail > '' Then
    Result := Result.SubHost[Tail];
End;

function TgRequestMap.GetLogClassName: String;
begin
//  If (Not IsLoading) And Assigned(TemplateRequestMap) And (FLogClassName = '') Then
//    Result := TemplateRequestMap.LogClassName
//  Else
    Result := FLogClassName;
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
  VirtualPathRequestMap := VirtualPaths[AHead];
  If Assigned(VirtualPathRequestMap) Then
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
  If (Not IsLoading) And Assigned(TemplateRequestMap) Then
  Begin
    If FSearchPath > '' Then
      Result := AbsolutePath(FSearchPath)
    Else
      Result := TemplateRequestMap.SearchPath;
  End
  Else If Not IsSaving Then
    Result := AbsolutePath(FSearchPath)
  Else
    Result := FSearchPath;
end;

function TgRequestMap.GetTemplateRequestMap: TgRequestMap;
begin
  If Not IsInspecting And Not Assigned(FTemplateRequestMap) And Assigned(Hosts) Then
    FTemplateRequestMap := Hosts.RequestMaps[Template];
  Result := FTemplateRequestMap;
end;

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
    VirtualPathRequestMap := VirtualPaths[Head];
    If Assigned(VirtualPathRequestMap) Then
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
    Delete(AHead,1,1);
  Position := Pos('/', AHead);
  If Position > 1 Then
  Begin
    ATail := Copy(AHead, Position + 1, MaxInt);
    AHead := Copy(AHead, 1, Position - 1);
  End;
end;

function TgRequestMap.TopRequestMap: TgRequestMap;
begin
  If Assigned(OwnersOwner) And OwnersOwner.InheritsFrom(TgRequestMap) Then
    Result := TgRequestMap(OwnersOwner).TopRequestMap
  Else
    Result := Self;
end;

function TgRequestMap.GetMobileSearchPath: String;
begin
  If (Not IsLoading) And Assigned(TemplateRequestMap) Then
  Begin
    If FMobileSearchPath > '' Then
      Result := AbsolutePath(FMobileSearchPath)
    Else
      Result := TemplateRequestMap.MobileSearchPath;
  End
  Else If Not IsSaving Then
    Result := AbsolutePath(FMobileSearchPath)
  Else
    Result := FMobileSearchPath;
end;

constructor TgWebServerControllerConfigurationData.Create(AOwner: TgBase = Nil);
begin
  inherited Create(AOwner);
  RequestMapBuilders := TObjectList.Create();
end;

destructor TgWebServerControllerConfigurationData.Destroy;
begin
  FreeAndNil(RequestMapBuilders);
  inherited Destroy;
end;

procedure TgWebServerControllerConfigurationData.AddDefaultFileTypes;
begin
  TemplateFileExtensions.Add( 'html' );
  FileTypes.Text := 'htm=text/html' + CRLF +
                    'txt=text/ascii' + CRLF +
                    'gif=image/gif' + CRLF +
                    'jpg=image/jpg' + CRLF +
                    'png=image/png' + CRLF +
                    'htf=text/html' + CRLF +
                    'html=text/html' + CRLF +
                    'jpeg=image/jpeg' + CRLF +
                    'xls=application/vnd.ms-excel' + CRLF +
                    'htg=image/gif' + CRLF +
                    'swf=application/x-shockwave-flash' + CRLF +
                    'htt=text/html' + CRLF +
                    'css=text/css' + CRLF +
                    'pdf=application/pdf' + CRLF +
                    'mp3=audio/mp3' + CRLF +
                    'wmv=video/x-ms-wmv' + CRLF +
                    'mov=video/quicktime' + CRLF +
                    'ico=image/x-icon' + CRLF +
                    'csv=text/csv' + CRLF +
                    'zip=application/zip' + CRLF;
end;

function TgWebServerControllerConfigurationData.FileName: String;
begin
  Result := IncludeTrailingPathDelimiter( ExecutablePath ) + 'gwscontroller.xml';
end;

procedure TgWebServerControllerConfigurationData.LoadPackages;
var
  Counter: Integer;
begin
  If Assigned( FPackages ) Then
    For Counter := 0 To FPackages.Count - 1 Do
      FPackages.Objects[Counter] := TObject(GLoadPackage( FPackages[Counter] ));
end;

procedure TgWebServerControllerConfigurationData.UnloadPackages;
var
  Counter: Integer;
  Module: Integer;
begin
  If Assigned( FPackages ) Then
    For Counter := FPackages.Count - 1 DownTo 0 Do
    Begin
      Module := Cardinal(FPackages.Objects[Counter]);
      If Module > 0 Then
        GUnloadPackage( Module );
    End;
end;

procedure TgWebServerControllerConfigurationData.RegisterPackage(const APackageName: String);
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
    Save;
  End;
  LoadFromFile( FileName );
end;

procedure TgWebServerControllerConfigurationData.Save;
begin
  SaveToFile( FileName );
end;

procedure TgWebServerControllerConfigurationData.AddDefaultPackages;
begin
  AddDefaultPackage( 'pgFirebird.bpl' );
  AddDefaultPackage( 'pgIndy.bpl' );
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
  RequestMapBuilderPointer : Pointer;
  RequestMapBuilder : TgRequestMapBuilder;
  RequestMapBuilderClassList : TList;
begin
  RequestMapBuilderClassList := TList.Create;
  Try
    ClassRegistry.AllClassDescendents(TgRequestMapBuilder, RequestMapBuilderClassList);
    For RequestMapBuilderPointer In RequestMapBuilderClassList Do
    Begin
      RequestMapBuilder := TgRequestMapBuilderClass(RequestMapBuilderPointer).Create;
      RequestMapBuilder.Initialize;
      RequestMapBuilders.Add(RequestMapBuilder);
    End;
  Finally
    RequestMapBuilderClassList.Free;
  End;
end;

procedure TgWebServerControllerConfigurationData.FinalizeRequestMapBuilders;
begin
  FreeAndNil(RequestMapBuilders);
end;

function TgWebServerControllerConfigurationData.GetHost(const AHost : String): TgRequestMap;
Var
  Head : String;
  Tail : String;
  URI: String;
  Counter : Integer;
  TopLevelDomain : String;
  DefaultRequestMap : TgRequestMap;
begin
  DefaultRequestMap := Nil;
  TgRequestMap.SplitRequestPath(AHost,Head, URI);
  TopLevelDomain := ExtractFileExt(Head);
  TgRequestMap.SplitHostPath(ChangeFileExt(Head, ''), Head, Tail);
  if not Hosts.TryGet(Head + TopLevelDomain,Result) then
     Exit(DefaultRequestMap);
  if Tail > '' then
    Result := Result.SubHost[Tail];
  if URI > '' then
    Result := Result.VirtualPath[URI];
end;

function TgRequestLogItem.GetDuration: Integer;
begin
  If FDuration = 0 Then
    FDuration := MilliSecondOfTheDay(Now - FDateTime);
  Result := FDuration;
end;

function TgRequestLogItem.GetHost: TgURI;
begin
  ReturnObjectReference(Result, 'Host');
end;

function TgRequestLogItem.GetReferer: TgURI;
begin
  ReturnObjectReference(Result, 'Referer');
end;

procedure TgRequestLogItem.Populate;
begin
  IPAddress := WebServerController.Request.IPAddress;
  Host.URI := WebServerController.Request.HeaderFields['Host'] + WebServerController.Request.URI;
  Referer.URI := WebServerController.Request.HeaderFields['Referer'];
  UserAgent := WebServerController.Request.HeaderFields['User-Agent'];
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
  FCookies := TgOrderedStringHashTable.Create();
  FHeaderFields := TgOrderedStringHashTable.Create();
end;

destructor TgResponse.Destroy;
begin
  FreeAndNil(FHeaderFields);
  FreeAndNil(FCookies);
  FreeAndNil(FContentStream);
  FContentStream.Free;
  FHeaderFields.Free;
  FCookies.Free;
  inherited;
end;

class function TgResponse.FriendlyClassName: string;
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
var
  URL: String;
begin
  StatusCode := 301;
  If Assigned(Owner) And Owner.InheritsFrom(TgWebServerController) Then
    URL := gCore.EvaluateTemplateString(AURL, TgWebServerController(Owner).RequestModel)
  Else
    URL := AURL;
  HeaderFields['Location'] := URL;
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

end.
