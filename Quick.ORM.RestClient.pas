{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.RestClient
  Description : Rest ORM Client access by http, httpapi or websockets
  Author      : Kike Pérez
  Version     : 1.4
  Created     : 02/06/2017
  Modified    : 07/09/2017

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
unit Quick.ORM.RestClient;

interface

{$INCLUDE synopse.inc}

uses
  Classes,
  SysUtils,
  SynCommons,
  SynCrtSock,
  mORMot,
  mORMotSQLite3,
  mORMotHttpClient,
  Quick.ORM.Engine,
  Quick.ORM.Security,
  Quick.ORM.Security.GUI;

type

  TAuthLogin = class
  private
    fUserName : RawUTF8;
    fHashedPassword : RawUTF8;
    procedure HashPassword(value : RawUTF8);
  public
    property UserName : RawUTF8 read fUserName write fUserName;
    property UserPass : RawUTF8 write HashPassword;
    property HashedPassword : RawUTF8 read fHashedPassword write fHashedPassword;
  end;

  THTTPClientOptions = class
  private
    fAuthMode : TAuthMode;
    fProtocol : TSrvProtocol;
    fConnectionTimeout : Integer;
    fSendTimeout : Integer;
    fReceiveTimeout : Integer;
    fConnectTimeout : Integer;
    fWSEncryptionKey : RawUTF8;
    fNamedPipe : RawUTF8;
  public
    property AuthMode : TAuthMode read fAuthMode write fAuthMode;
    property Protocol : TSrvProtocol read fProtocol write fProtocol;
    property ConnectionTimeout : Integer read fConnectionTimeout write fConnectionTimeout;
    property SendTimeout : Integer read fSendTimeout write fSendTimeout;
    property ReceiveTimeout : Integer read fReceiveTimeout write fReceiveTimeout;
    property ConnectTimeout : Integer read fConnectTimeout write fConnectTimeout;
    property WSEncryptionKey : RawUTF8 read fWSEncryptionKey write fWSEncryptionKey;
    property NamedPipe : RawUTF8 read fNamedPipe write fNamedPipe;
    constructor Create;
  end;

  //Client with DB access througth an http server
  TORMDataBaseConnection = class
  private
    fModel : TSQLModel;
    fIncludedClasses : TSQLRecordClassArray;
    faRootURI : RawUTF8;
  public
    property Model : TSQLModel read fModel write fModel;
    property IncludedClasses : TSQLRecordClassArray read fIncludedClasses write fIncludedClasses;
    property aRootURI : RawUTF8 read faRootURI write faRootURI;
    constructor Create;
    destructor Destroy; override;
  end;

  TORMServiceClient = class
  private
    fORMClient : TORMClient;
    fMethodInterface : TGUID;
    fInstanceImplementation : TServiceInstanceImplementation;
    fEnabled : Boolean;
  public
    constructor Create;
    property MethodInterface : TGUID read fMethodInterface write fMethodInterface;
    property InstanceImplementation : TServiceInstanceImplementation read fInstanceImplementation write fInstanceImplementation;
    property Enabled : Boolean read fEnabled write fEnabled;
    procedure SetORM(fORM : TORMClient);
    function SetRestMethod(out Obj) : Boolean;
  end;

  TConnectEvent = procedure of object;
  TConnectErrorEvent = procedure of object;

  TORMRestClient = class
  private
    fDataBase : TORMDataBaseConnection;
    fHost : RawUTF8;
    fPort : Integer;
    fHTTPOptions : THTTPClientOptions;
    fService : TORMServiceClient;
    fLogin : TAuthLogin;
    fMyAuthGroup : TORMAuthGroup;
    fOnConnect : TConnectEvent;
    fOnConnectError : TConnectErrorEvent;
  public
    ORM : TORMClient;
    property Login : TAuthLogin read fLogin write fLogin;
    property Host : RawUTF8 read fHost write fHost;
    property Port : Integer read fPort write fPort;
    property DataBase : TORMDataBaseConnection read fDataBase write fDataBase;
    property HTTPOptions : THTTPClientOptions read fHTTPOptions write fHTTPOptions;
    property Service : TORMServiceClient read fService write fService;
    property OnConnect : TConnectEvent read fOnConnect write fOnConnect;
    property OnConnectError : TConnectErrorEvent read fOnConnectError write fOnConnectError;
    constructor Create;
    destructor Destroy; override;
    function Connect(const aServer : string; aPort : Integer) : Boolean; overload;
    function Connect : Boolean; overload;
    function LoginPrompt(ShowHostPrompt : Boolean = True) : Boolean;
    function ActionAllowed(const Action : string) : Boolean;
  end;

implementation


{TAuthLogin}

procedure TAuthLogin.HashPassword(value : RawUTF8);
begin
  fHashedPassword := TSQLAuthUser.ComputeHashedPassword(value);
end;

{TORMDataBaseConnection Class}

constructor TORMDataBaseConnection.Create;
begin
  inherited;
  faRootURI := DEF_ROOTURI;
end;

destructor TORMDataBaseConnection.Destroy;
begin
  if Assigned(fModel) then fModel.Free;
  inherited;
end;


{THTTPClientOptions Class}

constructor THTTPClientOptions.Create;
begin
  inherited;
  fProtocol := spHTTP_Socket;
  fConnectionTimeout := DEF_CONNECTION_TIMEOUT;
  fAuthMode := amNoAuthentication;
  fSendTimeout := HTTP_DEFAULT_SENDTIMEOUT;
  fReceiveTimeout := HTTP_DEFAULT_RECEIVETIMEOUT;
  fConnectTimeout := HTTP_DEFAULT_CONNECTTIMEOUT;
  fWSEncryptionKey := DEF_ENCRYPTIONKEY;
  fNamedPipe := DEF_NAMEDPIPE;
end;


{TORMServiceClient Class}

constructor TORMServiceClient.Create;
begin
  inherited;
  fEnabled := False;
end;

procedure TORMServiceClient.SetORM(fORM : TORMClient);
begin
  fORMClient := fORM;
end;

function TORMServiceClient.SetRestMethod(out Obj) : Boolean;
begin
  Result := fORMClient.Services.Resolve(fMethodInterface, obj);
end;


{TORMRestClient Class}


constructor TORMRestClient.Create;
begin
  inherited;
  fDataBase := TORMDataBaseConnection.Create;
  fLogin := TAuthLogin.Create;
  fLogin.UserName := 'User';
  fLogin.UserPass := '';
  fHTTPOptions := THTTPClientOptions.Create;
  fService := TORMServiceClient.Create;
end;

destructor TORMRestClient.Destroy;
begin
  if Assigned(ORM) then ORM.Free;
  if Assigned(fLogin) then fLogin.Free;
  if Assigned(fHTTPOptions) then fHTTPOptions.Free;
  if Assigned(fDataBase) then fDataBase.Free;
  if Assigned(fService) then fService.Free;
  inherited;
end;

function TORMRestClient.Connect(const aServer : string; aPort : Integer) : Boolean;
begin
  fHost := aServer;
  fPort := aPort;
  Result := Connect;
end;

function TORMRestClient.Connect : Boolean;
begin
  Result := False;
  try
    if fHTTPOptions.AuthMode in [TAuthMode.amDefault,TAuthMode.amSimple] then fDataBase.IncludedClasses := fDataBase.IncludedClasses + [TORMAuthUser] + [TORMAuthGroup];
    fDataBase.Model := TSQLModel.Create(fDataBase.IncludedClasses,fDataBase.aRootURI);

    //Protocol initialization
    case fHTTPOptions.Protocol of
      spHTTP_Socket:
        begin
          ORM := TSQLHttpClientWinSock.Create(fHost, IntToStr(fPort), fDataBase.Model, fHTTPOptions.SendTimeout, fHTTPOptions.ReceiveTimeout, fHTTPOptions.ConnectTimeout);
          TSQLHttpClientWinSock(ORM).KeepAliveMS := fHTTPOptions.ConnectionTimeout;
        end;
      spHTTPsys:
        begin
          ORM := TSQLHttpClientWinHTTP.Create(fHost,IntToStr(fPort), fDataBase.Model, fHTTPOptions.SendTimeout, fHTTPOptions.ReceiveTimeout,fHTTPOptions.ConnectTimeout);
          TSQLHttpClientWinHTTP(ORM).KeepAliveMS := fHTTPOptions.ConnectionTimeout;
          TSQLHttpClientWinHTTP(ORM).Compression := [hcSynShaAes];
        end;
     {$ifdef MSWINDOWS}
      spHTTPsys_SSL:
        begin
          ORM := TSQLHttpClientWinHTTP.Create(fHost,IntToStr(fPort), fDataBase.Model, True, '', '', fHTTPOptions.SendTimeout, fHTTPOptions.ReceiveTimeout, fHTTPOptions.ConnectTimeout);
          TSQLHttpClientWinHTTP(ORM).KeepAliveMS := fHTTPOptions.ConnectionTimeout;
          TSQLHttpClientWinHTTP(ORM).Compression := [hcSynShaAes];
        end;
     {$endif}
      spHTTPsys_AES:
        begin
          ORM := TSQLHttpClientWinHTTP.Create(fHost,IntToStr(fPort), fDataBase.Model, fHTTPOptions.SendTimeout, fHTTPOptions.ReceiveTimeout, fHTTPOptions.ConnectTimeout);
          TSQLHttpClientWinHTTP(ORM).KeepAliveMS := fHTTPOptions.ConnectionTimeout;
          TSQLHttpClientWinHTTP(ORM).Compression := [hcSynShaAes];
        end;
      spHTTP_WebSocket:
        begin
          ORM := TSQLHttpClientWebsockets.Create(fHost,IntToStr(fPort), fDataBase.Model, fHTTPOptions.SendTimeout, fHTTPOptions.ReceiveTimeout, fHTTPOptions.ConnectTimeout);
          TSQLHttpClientWebsockets(ORM).KeepAliveMS := fHTTPOptions.ConnectionTimeout;
        end;
      spWebSocketBidir_JSON:
        begin
          ORM := TSQLHttpClientWebsockets.Create(fHost,IntToStr(fPort), fDataBase.Model, fHTTPOptions.SendTimeout, fHTTPOptions.ReceiveTimeout, fHTTPOptions.ConnectTimeout);
          TSQLHttpClientWebsockets(ORM).KeepAliveMS := fHTTPOptions.ConnectionTimeout;
          (ORM as TSQLHttpClientWebsockets).WebSocketsUpgrade('', True);
        end;
      spWebSocketBidir_Binary:
        begin
          ORM := TSQLHttpClientWebsockets.Create(fHost,IntToStr(fPort), fDataBase.Model, fHTTPOptions.SendTimeout, fHTTPOptions.ReceiveTimeout, fHTTPOptions.ConnectTimeout);
          TSQLHttpClientWebsockets(ORM).KeepAliveMS := fHTTPOptions.ConnectionTimeout;
          (ORM as TSQLHttpClientWebsockets).WebSocketsUpgrade('', False);
        end;
      spWebSocketBidir_BinaryAES:
        begin
          ORM := TSQLHttpClientWebsockets.Create(fHost,IntToStr(fPort), fDataBase.Model, fHTTPOptions.SendTimeout, fHTTPOptions.ReceiveTimeout, fHTTPOptions.ConnectTimeout);
          TSQLHttpClientWebsockets(ORM).KeepAliveMS := fHTTPOptions.ConnectionTimeout;
          (ORM as TSQLHttpClientWebsockets).WebSocketsUpgrade(fHTTPOptions.WSEncryptionKey, False);
        end;
      spNamedPipe:
        begin
          ORM := TSQLRestClientURINamedPipe.Create(fDataBase.Model,'\\.\pipe\' + fHTTPOptions.NamedPipe);
        end
    else
      begin
        raise Exception.Create('Protocol not available!');
      end;
    end;

    //Authmode initialization
    case fHTTPOptions.AuthMode of
      amNoAuthentication: //No user Authentication
        begin
          //nothing to do here
          Result := True; //shows as connected ever ???
        end;
      amSimple:
        begin //TSQLRestServerAuthenticationNone (uses user/pass but not signature on client side)
          Result := TSQLRestServerAuthenticationNone.ClientSetUser(ORM,fLogin.UserName,fLogin.HashedPassword,passHashed);
        end;
      amDefault: //TSQLRestServerAuthenticationDefault (uses user/pass with signature on client side)
        begin
          Result := ORM.SetUser(fLogin.UserName,fLogin.HashedPassword,True);
        end;
      amHttpBasic: //TSQLRestServerAuthenticationHttpBasic
        begin
          Result := TSQLRestServerAuthenticationHttpBasic.ClientSetUser(ORM,fLogin.UserName,fLogin.HashedPassword,passHashed);
        end;
      {$IFDEF MSWINDOWS}
      amSSPI: //TSQLRestServerAuthenticationSSPI
        begin
          Result := TSQLRestServerAuthenticationSSPI.ClientSetUser(ORM,fLogin.UserName,fLogin.HashedPassword,passHashed);
        end;
      {$ENDIF}
    else
      begin
        raise Exception.Create('Authentication mode not available');
      end;
    end;

    if Result then
    begin
      //Check TimeSync with Server
      if not ORM.ServerTimeStampSynchronize() then
      begin
        Result := False;
        raise Exception.Create(ORM.LastErrorMessage);
      end;

      //Service initialization
      if fService.Enabled then
      begin
        fService.SetORM(ORM);
        ORM.ServiceDefine([fService.fMethodInterface],fService.fInstanceImplementation);
      end;

      //get Auth Group
      fMyAuthGroup := TORMAuthGroup.CreateAndFillPrepare(ORM,'ID=?',[ORM.SessionUser.GroupRights.ID]);
      if not fMyAuthGroup.FillOne then
      begin
        //raise Exception.Create('No group assigned or error on get group info!');
      end;
    end;
  finally
    if Result then
    begin
      if Assigned(fOnConnect) then fOnConnect;
    end
    else
    begin
      if Assigned(fOnConnectError) then fOnConnectError;
    end
  end;
end;

function TORMRestClient.LoginPrompt(ShowHostPrompt : Boolean = True) : Boolean;
var
  LoginGUI : TORMLoginGUI;
begin
  Result := False;
  LoginGUI := TORMLoginGUI.Create;
  try
    LoginGUI.Host := fHost;
    LoginGUI.Port := fPort;
    if LoginGUI.LoginPrompt(True) then
    begin
      fHost := LoginGUI.Host;
      fPort := LoginGUI.Port;
      fLogin.UserName := LoginGUI.UserName;
      fLogin.HashedPassword := LoginGUI.UserPass;
      Result := Connect;
    end;
  finally
    LoginGUI.Free;
  end;
end;

function TORMRestClient.ActionAllowed(const Action : string) : Boolean;
begin
  Result := Self.fMyAuthGroup.AppAction(Action).Allowed;
end;

end.
