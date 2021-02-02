{ ***************************************************************************

  Copyright (c) 2016-2019 Kike Pérez

  Unit        : Quick.ORM.RestServer
  Description : Rest ORM Server allows access by http, httpapi or websockets
  Author      : Kike Pérez
  Version     : 1.9
  Created     : 02/06/2017
  Modified    : 08/05/2019

  This file is part of QuickORM: https://github.com/exilon/QuickORM

  Uses Synopse mORMot framework. Copyright (C) 2017 Arnaud Bouchez
       Synopse Informatique - https://synopse.info

 ***************************************************************************

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

 *************************************************************************** }

unit Quick.ORM.RestServer;

{$i QuickORM.inc}
{$INCLUDE synopse.inc}

interface

uses
  Classes,
  SysUtils,
  SynCommons,
  mORMot,
  mORMotSQLite3,
  mORMotDB,
  mORMotHttpServer,
  SynSQLite3Static,
  SynDBODBC,
  SynCrtSock,
  SynBidirSock,
  Quick.ORM.Engine,
  Quick.ORM.Server.Base,
  Quick.ORM.DataBase,
  Quick.ORM.Security,
  Quick.ORM.Server.Config;

type

  TCustomORMServer = TSQLRestServerDB;

  TORMServerClass = class of TCustomORMServer;

  TIPRestriction = class
  private
    fDefaultSecurityRule : TSecurityAccess;
    fExcludedIPFromDefaultRule : TArrayOfRawUTF8;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property DefaultSecurityRule : TSecurityAccess read fDefaultSecurityRule write fDefaultSecurityRule;
    property ExcludedIPFromDefaultRule : TArrayOfRawUTF8 read fExcludedIPFromDefaultRule write fExcludedIPFromDefaultRule;
  end;

  TORMHTTPServer = class(TSQLHttpServer)
  private
    fIPRestriction : TIPRestriction;
    fAPIKeys : TArrayOfRawUTF8;
    fOnIPRestrictedTry : TIPRestrictedTryEvent;
    fOnApiKeyBeforeAccess : TApiKeyBeforeAccessEvent;
    fOnApiKeyAfterAccess : TApiKeyAfterAccessEvent;
  protected
    function Request(Ctxt: THttpServerRequest): cardinal; override;
    function BeforeServiceExecute(Ctxt: TSQLRestServerURIContext; const Method: TServiceMethod) : Boolean;
  public
    property IPRestriction : TIPRestriction read fIPRestriction write fIPRestriction;
    property APIKeys : TArrayOfRawUTF8 read fAPIKeys write fAPIKeys;
    property OnIPRestrictedTry : TIPRestrictedTryEvent read fOnIPRestrictedTry write fOnIPRestrictedTry;
    property OnApiKeyBeforeAccess : TApiKeyBeforeAccessEvent read fOnApiKeyBeforeAccess write fOnApiKeyBeforeAccess;
    property OnApiKeyAfterAccess : TApiKeyAfterAccessEvent read fOnApiKeyAfterAccess write fOnApiKeyAfterAccess;
  end;

  THTTPServerOptions = class
  private
    fBinding : TIPBinding;
    fAuthMode : TAuthMode;
    fProtocol : TSrvProtocol;
    fConnectionTimeout : Integer;
    fCORSAllowedDomains : RawUTF8;
    fWSEncryptionKey : RawUTF8;
    fNamedPipe : RawUTF8;
    fIPRestriction : TIPRestriction;
    fAPIKeys : TArrayOfRawUTF8;
  public
    property Binding : TIPBinding read fBinding write fBinding;
    property AuthMode : TAuthMode read fAuthMode write fAuthMode;
    property Protocol : TSrvProtocol read fProtocol write fProtocol;
    property ConnectionTimeout : Integer read fConnectionTimeout write fConnectionTimeout;
    property CORSAllowedDomains : RawUTF8 read fCORSAllowedDomains write fCORSAllowedDomains;
    property WSEncryptionKey : RawUTF8 read fWSEncryptionKey write fWSEncryptionKey;
    property NamedPipe : RawUTF8 read fNamedPipe write fNamedPipe;
    property IPRestriction : TIPRestriction read fIPRestriction write fIPRestriction;
    property APIKeys : TArrayOfRawUTF8 read fAPIKeys write fAPIKeys;
    constructor Create;
    destructor Destroy; override;
  end;
  
  TGuidArray = array of TGUID;

  TORMService = class
  public
    fMethodClass : TInterfacedClass;
    fMethodInterface : TGuidArray;
    fInstanceImplementation : TServiceInstanceImplementation;
    fResultAsXMLIfRequired : Boolean;
    fEnabled : Boolean;
  public
    property MethodClass : TInterfacedClass read fMethodClass write fMethodClass;
    property MethodInterface : TGuidArray read fMethodInterface write fMethodInterface;
    property InstanceImplementation : TServiceInstanceImplementation read fInstanceImplementation write fInstanceImplementation;
    property ResultAsXMLIfRequired : Boolean read fResultAsXMLIfRequired write fResultAsXMLIfRequired;
    property Enabled : Boolean read fEnabled write fEnabled;
    constructor Create;
  end;

  {$IFDEF FPC}
  TProc = procedure;
  {$ENDIF}

  TORMRestServer = class(TORMBaseServer)
  private
    fHTTPServer : TORMHTTPServer;
    fService : TORMService;
    fHTTPOptions : THTTPServerOptions;
    fCustomORMServerClass : TORMServerClass;
    fConfigFile : TORMRestServerConfig;
    procedure LoadConfig;
    procedure ReloadConfig;
    procedure GetDefinedServerConfig;
  public
    ORM : TSQLRestServer;
    property CustomORMServerClass : TORMServerClass read fCustomORMServerClass write fCustomORMServerClass;
    property Service : TORMService read fService write fService;
    property HTTPOptions : THTTPServerOptions read fHTTPOptions write fHTTPOptions;
    constructor Create(cFullMemoryMode : Boolean = False); override;
    destructor Destroy; override;
    function Connect : Boolean; overload; override;
    function Connect(DoCustomDB : TProc) : Boolean; overload;
  end;

implementation


{TIPRestriction Class}

constructor TIPRestriction.Create;
begin
  fDefaultSecurityRule := TSecurityAccess.saAllowed;
  fExcludedIPFromDefaultRule := [];
end;

destructor TIPRestriction.Destroy;
begin
  if Assigned(fExcludedIPFromDefaultRule) then fExcludedIPFromDefaultRule := [];
  inherited;
end;

{THTTPServer Class}

constructor THTTPServerOptions.Create;
begin
  inherited;
  fBinding := TIPBinding.Create;
  fBinding.IP := '127.0.0.1';
  fBinding.Port := 8090;
  fProtocol := spHTTP_Socket;
  fCORSAllowedDomains := '*';
  fConnectionTimeout := DEF_CONNECTION_TIMEOUT;
  fWSEncryptionKey := DEF_ENCRYPTIONKEY;
  fNamedPipe := DEF_NAMEDPIPE;
  fIPRestriction := TIPRestriction.Create;
end;

destructor THTTPServerOptions.Destroy;
begin
  if Assigned(fBinding) then fBinding.Free;
  if Assigned(fIPRestriction) then fIPRestriction.Free;
  inherited;
end;


{TORMService Class}

constructor TORMService.Create;
begin
  inherited;
  fMethodClass := nil;
  //fMethodInterface := nil;
  fInstanceImplementation := sicShared;
  fResultAsXMLIfRequired := False;
  fEnabled := False;
end;

{TORMHTTPServer Class}

function MatchArray(const aValue : string; const aAValues : TArrayOfRawUTF8) : Boolean;
var
  lValue : string;
begin
 Result := False;
 for lValue in aAValues do
  begin
    if AnsiSameStr(lValue,AValue) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TORMHTTPServer.Request(Ctxt: THttpServerRequest): cardinal;
var
  ClientIP : RawUTF8;
  ip : RawUTF8;
  CanAccess : Boolean;
  apikey : string;
begin
  try
    ClientIP := FindIniNameValue(pointer(Ctxt.InHeaders),'REMOTEIP: ');
  except
    Result := HTTP_FORBIDDEN;
    Exit;
  end;

  //check default behaviour
  if fIPRestriction.DefaultSecurityRule = TSecurityAccess.saAllowed then CanAccess := True
    else CanAccess := False;

  //check if ip included in exception list
  if MatchArray(ClientIP,fIPRestriction.fExcludedIPFromDefaultRule) then CanAccess := not CanAccess;

  if CanAccess then
  begin
    //check if apikey required
    if High(fAPIKeys) > -1 then
    begin
      apikey := GetQueryParam(Ctxt.URL,'apikey');
      CanAccess := MatchArray(apikey,fAPIKeys);
      if Assigned(fOnApiKeyBeforeAccess) then fOnApiKeyBeforeAccess(apikey,CanAccess);
      if Assigned(fOnApiKeyAfterAccess) then fOnApiKeyAfterAccess(apikey,CanAccess);
    end;
  end
  else if Assigned(fOnIPRestrictedTry) then fOnIPRestrictedTry(ClientIP);

  if CanAccess then Result := inherited Request(Ctxt)
    else Result := HTTP_FORBIDDEN;
end;

function TORMHTTPServer.BeforeServiceExecute(Ctxt: TSQLRestServerURIContext; const Method: TServiceMethod): Boolean;
var
  ClientIP : RawUTF8;
  CanAccess : Boolean;
  apikey : string;
begin
  try
    ClientIP := Ctxt.RemoteIP;
  except
    Result := False;
    Exit;
  end;

  //check default behaviour
  if fIPRestriction.DefaultSecurityRule = TSecurityAccess.saAllowed then CanAccess := True
    else CanAccess := False;

  //check if ip included in exception list
  if MatchArray(ClientIP,fIPRestriction.fExcludedIPFromDefaultRule) then CanAccess := not CanAccess;

  if CanAccess then
  begin
    //check if apikey required
    if High(fAPIKeys) > -1 then
    begin
      apikey := GetQueryParam(Ctxt.URI,'apikey');
      CanAccess := MatchArray(apikey,fAPIKeys);
      if Assigned(fOnApiKeyBeforeAccess) then fOnApiKeyBeforeAccess(apikey,CanAccess);
      if Assigned(fOnApiKeyAfterAccess) then fOnApiKeyAfterAccess(apikey,CanAccess);
    end;
  end
  else if Assigned(fOnIPRestrictedTry) then fOnIPRestrictedTry(ClientIP);

  if CanAccess then Result := True
    else Result := False;
end;


{TORMRestServer Class}

constructor TORMRestServer.Create(cFullMemoryMode : Boolean = False);
begin
  inherited Create(cFullMemoryMode);
  fHTTPOptions := THTTPServerOptions.Create;
  fService := TORMService.Create;
  fService.Enabled := False;
  fCustomORMServerClass := nil;
  fConfigFile := TORMRestServerConfig.Create;
  fConfigFile.OnLoadConfig := Self.LoadConfig;
  fConfigFile.OnConfigChanged := Self.ReloadConfig;
  //fConfigFile.Load; loads on connect
end;

destructor TORMRestServer.Destroy;
begin
  if Assigned(fHTTPServer) then fHTTPServer.Free;
  if Assigned(ORM) then ORM.Free;
  if Assigned(fHTTPOptions) then fHTTPOptions.Free;
  if Assigned(fService) then fService.Free;
  if Assigned(fConfigFile) then fConfigFile.Free;
  //deletes registration
  //if fHTTPMode = TSQLHttpServerOptions.useHttpApi then THttpApiServer.AddUrlAuthorize(faRootURI,'8080',false,'+',True);
  inherited;
end;

procedure TORMRestServer.LoadConfig;
begin
  //read base config file fields of Base class
  ReadBaseConfigFile(fConfigFile);
  //read custom config file field
  NeedsRestart := False; //after ReadBaseConfigFile to avoid restart on first Load
  fHTTPOptions.IPRestriction.DefaultSecurityRule := fConfigFile.DefaultSecurityRule;
  fHTTPOptions.IPRestriction.ExcludedIPFromDefaultRule := fConfigFile.IPRestrictionExcludedIP;
  fHTTPOptions.APIKeys := fConfigFile.APIKeys;
  fHTTPOptions.Binding.IP := fConfigFile.ServerHost;
  fHTTPOptions.Binding.Port := fConfigFile.ServerPort;
end;

procedure TORMRestServer.ReloadConfig;
var
  cNeedsRestart : Boolean;
begin
  if Assigned(OnReloadConfig) then OnReloadConfig;

  //determines if changes on configfile need restart server
  if (fConfigfile.ServerHost <> fHTTPOptions.Binding.IP) or
     (fConfigfile.ServerPort <> fHTTPOptions.Binding.Port) then cNeedsRestart := True;

  //apply new values
  LoadConfig;

  //
  NeedsRestart := cNeedsRestart;

  //restart server to apply changes
  if (NeedsRestart) and (ConfigFile.RestartServerIfChanged) then
  begin
    if Assigned(OnRestart) then OnRestart;

    Connect;
    Security.ApplySecurity;
    NeedsRestart := False;
  end;
end;

procedure TORMRestServer.GetDefinedServerConfig;
begin
  fConfigFile.ServerHost := fHTTPOptions.fBinding.IP;
  fConfigFile.ServerPort := fHTTPOptions.fBinding.Port;
  fConfigFile.DefaultSecurityRule := fHTTPOptions.IPRestriction.fDefaultSecurityRule;
  fConfigFile.IPRestrictionExcludedIP := fHTTPOptions.IPRestriction.fExcludedIPFromDefaultRule;
  fConfigFile.APIKeys := fHTTPOptions.APIKeys;
  fConfigFile.DBFilename := DataBase.DBFileName;
end;

function TORMRestServer.Connect : Boolean;
begin
  Result := Connect(nil);
end;

function TORMRestServer.Connect(DoCustomDB : TProc) : Boolean;
var
  ServiceFactoryServer: TServiceFactoryServer;
  ProxyPort : Integer;
  DBIndex : TDBIndex;
  DBMapping : TDBMappingField;
begin
  //load config file
  if ConfigFile.Enabled then
  begin
    Self.GetDefinedServerConfig;
    fConfigFile.Load;
  end;

  //clear if previosly connected
  if Assigned(fHTTPServer) then FreeAndNil(fHTTPServer);
  if Assigned(ORM) then FreeAndNil(ORM);
  if Assigned(DataBase.SQLProperties) then DataBase.SQLProperties.Free;
  if Assigned(Security.ServiceFactoryServer) then Security.ServiceFactoryServer.Free;

  //check if port config provided in params by proxy (to work as a service in Azure)
  if ParamCount > 0 then
  begin
    if (TryStrToInt(ParamStr(1),ProxyPort)) and (ProxyPort > 0) then
    begin
      fHTTPOptions.Binding.IP := '127.0.0.1';
      fHTTPOptions.Binding.Port := ProxyPort;
    end;
  end;

  //if needs Authentication
  if fHTTPOptions.AuthMode <> TAuthMode.amNoAuthentication then// in [TAuthMode.amDefault,TAuthMode.amSimple,TAuthMode.amHttpBasic] then
  begin
    Security.Enabled := True;
    DataBase.IncludedClasses := DataBase.IncludedClasses + [TORMAuthUser] + [TORMAuthGroup];
  end
  else Security.Enabled := False;

  if Assigned(DataBase.Model) then DataBase.Model.Free;
  DataBase.Model := TSQLModel.Create(DataBase.IncludedClasses, DataBase.aRootURI);
  if DataBase.FullMemoryMode then
  begin
    if fCustomORMServerClass <> nil then ORM := fCustomORMServerClass.Create(DataBase.Model,False)
    else
    begin
      if DataBase.IncludedClasses = nil then ORM := TSQLRestServerFullMemory.CreateWithOwnModel([])
        else ORM := TSQLRestServerFullMemory.Create(DataBase.Model,False);
    end;
  end
  else
  begin
    if not Assigned(DoCustomDb) then
    begin
      case DataBase.DBType of
        dtSQLite :
          begin
            if fCustomORMServerClass = nil then ORM := TSQLRestServerDB.Create(DataBase.Model,DataBase.DBFileName,Security.Enabled)
              else ORM := fCustomORMServerClass.Create(DataBase.Model,DataBase.DBFileName,Security.Enabled);
          end;
        dtMSSQL :
          begin
            DataBase.SQLProperties := //TOleDBMSSQL2008ConnectionProperties.Create(fDataBase.SQLConnection.ServerName,fDataBase.SQLConnection.DataBase,fDataBase.SQLConnection.Username,fDataBase.SQLConnection.UserPass);
            //TODBCConnectionProperties.Create('','Driver={SQL Server Native Client 10.0} ;Database='+DataBase.SQLConnection.DataBase+';'+
            //  'Server='+DataBase.SQLConnection.ServerName+';UID='+DataBase.SQLConnection.Username+';Pwd='+DataBase.SQLConnection.UserPass+';MARS_Connection=yes','','');
            TODBCConnectionProperties.Create('',DataBase.SQLConnection.GetConnectionString,'','');
            VirtualTableExternalRegisterAll(DataBase.Model,DataBase.SQLProperties);

            try
              for DBMapping in DataBase.DBMappingFields do
              begin
                DataBase.Model.Props[DBMapping.SQLRecordClass].ExternalDB.MapField(DBMapping.InternalFieldName,DBMapping.ExternalFieldName);
              end;
            except
              on E : Exception do raise Exception.CreateFmt('Error mapping fields! (%s)',[e.Message]);
            end;

            if fCustomORMServerClass = nil then ORM := TSQLRestServerDB.Create(DataBase.Model,SQLITE_MEMORY_DATABASE_NAME,Security.Enabled,'')
              else ORM := fCustomORMServerClass.Create(DataBase.Model,SQLITE_MEMORY_DATABASE_NAME,Security.Enabled,'')
          end;
      end;
    end
    else DoCustomDb;
  end;
  //create tables
  ORM.CreateMissingTables;
  //create indexes
  for DBIndex in DataBase.DBIndexes do
  begin
    if DBIndex.FieldNames.Count > 1 then ORM.CreateSQLMultiIndex(DBIndex.SQLRecordClass,DBIndex.FieldNames,DBIndex.Unique)
      else ORM.CreateSQLIndex(DBIndex.SQLRecordClass,DBIndex.FieldNames,DBIndex.Unique);
  end;
  //assigns ORM to security class
  Security.SetORMServer(ORM);

  //fHTTPServer := TSQLHttpServer.Create(IntToStr(fHTTPServerOptions.Binding.Port),[ORM],'+',fHTTPServerOptions.Protocol);
  //if fHTTPMode = TSQLHttpServerOptions.useHttpApi then THttpApiServer.AddUrlAuthorize(faRootURI,IntToStr(fBinding.Port),false,fBinding.Host{+}));
  //netsh http show urlacl

  //Authmode initialization
  case fHTTPOptions.AuthMode of
    amNoAuthentication:
      begin
        //Nothing to do
      end;
    amSimple: //TSQLRestServerAuthenticationNone (uses User/pass but not signature Authentication)
      begin
        ORM.AuthenticationRegister(TSQLRestServerAuthenticationNone);
      end;
    amDefault: //TSQLRestServerAuthenticationDefault
      begin
        ORM.AuthenticationRegister(TSQLRestServerAuthenticationDefault);
      end;
    amHttpBasic: //TSQLRestServerAuthenticationHttpBasic
      begin
        ORM.AuthenticationRegister(TSQLRestServerAuthenticationHttpBasic);
      end;
    // TSQLRestServerAuthenticationSSPI
    {$IFDEF MSWINDOWS}
    amSSPI:
      begin
        ORM.AuthenticationRegister(TSQLRestServerAuthenticationSSPI);
      end;
    {$endif}
  else
    begin
      //DeInitialize();
      raise Exception.Create('Authentication mode not available!');
    end;
  end;

  //service initialization
  if fService.Enabled then
  begin
    ServiceFactoryServer := ORM.ServiceDefine(fService.MethodClass, fService.fMethodInterface, fService.InstanceImplementation);
    ServiceFactoryServer.SetOptions([], [optErrorOnMissingParam]);
    if (not Security.Enabled) or (Security.PublicServices) then ServiceFactoryServer.ByPassAuthentication := True;
    //determines if service will return XML if client only accepts XML
    ServiceFactoryServer.ResultAsXMLObjectIfAcceptOnlyXML := fService.ResultAsXMLIfRequired;
  end;

  //protocol initialization
  if Assigned(fHTTPServer) then fHTTPServer.Free;
  case fHTTPOptions.Protocol of
    spHTTP_Socket:
      begin
        fHTTPServer := TORMHTTPServer.Create(fHTTPOptions.Binding.Port.ToString, [ORM], '+', useHttpSocket);
        THttpServer(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := fHTTPOptions.ConnectionTimeout;
      end;
    {
      // require manual URI registration, we will not use this option in this test project, because this option
      // should be used with installation program that will unregister all used URIs during sofware uninstallation.
      HTTPsys:
      begin
      HTTPServer := TSQLHttpServer.Create(AnsiString(Options.Port), [RestServer], '+', useHttpApi);
      THttpServer(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := SERVER_CONNECTION_TIMEOUT;
      end;
    }
    spHTTPsys:
      begin
        fHTTPServer := TORMHTTPServer.Create(fHTTPOptions.Binding.Port.ToString, [ORM], '+', HTTP_DEFAULT_MODE);
        THttpServer(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := fHTTPOptions.fConnectionTimeout;
      end;
    spHTTPsys_SSL:
      begin
        fHTTPServer := TORMHTTPServer.Create(fHTTPOptions.Binding.Port.ToString, [ORM], '+', HTTP_DEFAULT_MODE, 32, TSQLHttpServerSecurity.secSSL);
        THttpServer(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := fHTTPOptions.fConnectionTimeout;
      end;
    spHTTPsys_AES:
      begin
        fHTTPServer := TORMHTTPServer.Create(fHTTPOptions.Binding.Port.ToString, [ORM], '+', HTTP_DEFAULT_MODE, 32, TSQLHttpServerSecurity.secSynShaAes);
        THttpServer(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := fHTTPOptions.fConnectionTimeout;
      end;
    spHTTP_WebSocket:
      begin
        fHTTPServer := TORMHTTPServer.Create(fHTTPOptions.Binding.Port.ToString, [ORM], '+', useBidirSocket);
        TWebSocketServerRest(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := fHTTPOptions.fConnectionTimeout;
      end;
    spWebSocketBidir_JSON:
      begin
        fHTTPServer := TORMHTTPServer.Create(fHTTPOptions.Binding.Port.ToString, [ORM], '+', useBidirSocket);
        TWebSocketServerRest(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := fHTTPOptions.fConnectionTimeout;
        { WebSocketServerRest := } fHTTPServer.WebSocketsEnable(ORM, '', True);
      end;
    spWebSocketBidir_Binary:
      begin
        fHTTPServer := TORMHTTPServer.Create(fHTTPOptions.Binding.Port.ToString, [ORM], '+', useBidirSocket);
        TWebSocketServerRest(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := fHTTPOptions.fConnectionTimeout;
        { WebSocketServerRest := } fHTTPServer.WebSocketsEnable(ORM, '', false);
      end;
    spWebSocketBidir_BinaryAES:
      begin
        fHTTPServer := TORMHTTPServer.Create(fHTTPOptions.Binding.Port.ToString, [ORM], '+', useBidirSocket);
        TWebSocketServerRest(fHTTPServer.HttpServer).ServerKeepAliveTimeOut := fHTTPOptions.fConnectionTimeout;
        { WebSocketServerRest := } fHTTPServer.WebSocketsEnable(ORM, fHTTPOptions.WSEncryptionKey, false);
      end;
    spNamedPipe:
      begin
        if not ORM.ExportServerNamedPipe('\\.\pipe\' + fHTTPOptions.NamedPipe) then Exception.Create('Unable to register server with named pipe channel.');
      end;
  else
    begin
      raise Exception.Create('Protocol not available!');
    end;
  end;

  if fHTTPOptions.Protocol <> spNamedPipe then fHTTPServer.AccessControlAllowOrigin := fHTTPOptions.CORSAllowedDomains;

  //ip restriction
  if Assigned(fHTTPOptions.IPRestriction) then fHTTPServer.IPRestriction := fHTTPOptions.IPRestriction;
  //apikey access
  fHTTPServer.APIKeys := fHTTPOptions.APIKeys;

  //checks if default security needs to apply
  Security.SetDefaultSecurity;

  //assigns ServiceFactory to Security class
  if fService.Enabled then
  begin
    Security.ServiceFactoryServer := ServiceFactoryServer;
    //check every service authorization before execute
    ServiceFactoryServer.OnMethodExecute := fHTTPServer.BeforeServiceExecute;
  end;

  //apply security settings
  Security.ApplySecurity;

  Result := True;

  if Assigned(OnConnectionSuccess) then OnConnectionSuccess;
end;


end.
