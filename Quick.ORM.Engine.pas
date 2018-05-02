{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.Engine
  Description : Rest ORM Engine
  Author      : Kike Pérez
  Version     : 1.2
  Created     : 02/06/2017
  Modified    : 25/03/2018

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

unit Quick.ORM.Engine;

interface

{$INCLUDE synopse.inc}

uses
  Classes,
  SysUtils,
  {$IFDEF ANDROID}
  SynCrossPlatformJSON,
  SynCrossPlatformREST,
  {$ELSE}
  SynCommons,
  mORMot,
  {$ENDIF}
  Quick.Commons;

const
  DEF_CONNECTION_TIMEOUT = 20000;
  DEF_ENCRYPTIONKEY = '234CC84D8A32D7477A7B1633615499AB';
  DEF_NAMEDPIPE = 'defaultpipe';
  DEF_ROOTURI = 'root';
  SQLITE_MEMORY_DATABASE_NAME = ':memory:';
  LOG_ALL : TSynLogInfos = [succ(sllNone)..high(TSynLogInfo)];
  LOG_ONLYERRORS: TSynLogInfos = [sllLastError,sllError,sllException,sllExceptionOS,sllDDDError];
  LOG_NONE: TSynLogInfos = [];

type

  {$IFNDEF MSWINDOWS}
  EORMException = class(Exception);
  {$ENDIF}
  EORMServer = class(EORMException);

  TDBType = (dtSQLite, dtMSSQL);

  TSQLiteLockMode = (lmNormal, lmExclusive);

  TSQLConnection = class
    ServerName : RawUTF8;
    DataBase : RawUTF8;
    Username : RawUTF8;
    UserPass : RawUTF8;
  end;

  //TORMServer = class(TSQLRestServer)
  //published
  //  procedure Sum(Ctxt: TSQLRestServerURIContext);
  //end;

  TORMClient = TSQLRestClientURI;

  {$IFNDEF NEXTGEN}
  TSrvProtocol = (spHTTP_Socket, spHTTPsys, spHTTPsys_SSL, spHTTPsys_AES, spHTTP_WebSocket, spWebSocketBidir_JSON, spWebSocketBidir_Binary, spWebSocketBidir_BinaryAES{$IFDEF MSWINDOWS}, spNamedPipe{$ENDIF});
  {$ELSE}
  TSrvProtocol = (spHTTP_Socket, spHTTP_SSL, spHTTP_AES, spHTTP_WebSocket, spWebSocketBidir_JSON, spWebSocketBidir_Binary, spWebSocketBidir_BinaryAES);
  {$ENDIF}
  TAuthMode = (amNoAuthentication, amSimple, amDefault, amHttpBasic {$IFDEF MSWINDOWS}, amSSPI {$ENDIF});

  TServiceAuthorizationPolicy = (saAllowAll, saDenyAll);

  TSecurityAppliedEvent = procedure of object;

  TConnectionSuccessEvent = procedure of object;

  TConnectionFailedEvent = procedure of object;

  TIPRestrictedTryEvent = procedure(const ip : string) of object;

  TApiKeyBeforeAccessEvent = procedure(const apikey : string; var allow : Boolean ) of object;

  TApiKeyAfterAccessEvent = procedure(const apikey : string; allowed : Boolean) of object;

  TLoadConfigEvent = procedure of object;

  TIPBinding = class
    IP : RawUTF8;
    Port : Integer;
  end;

  TArrayOfRawUTF8 = array of RawUTF8;

  {$IFNDEF ANDROID}
  TArrayOfRawUTF8Helper = record helper for TArrayOfRawUTF8
  public
    procedure Add(const value : RawUTF8; AllowDuplicates : Boolean = False);
    procedure Remove(const value : RawUTF8);
    function Exists(const value : RawUTF8) : Boolean;
    procedure Clear;
    function Count : Integer;
  end;
  {$ENDIF}

  TDBIndex = record
    SQLRecordClass : TSQLRecordClass;
    FieldNames : TArrayOfRawUTF8;
    Unique : Boolean;
  end;

  TDBIndexArray = TArray<TDBIndex>;

  TDBIndexArrayHelper = record helper for TDBIndexArray
  public
    procedure Add(aSQLRecordClass : TSQLRecordClass; aIndexFieldName : RawUTF8; aUnique : Boolean = False); overload;
    procedure Add(aSQLRecordClass : TSQLRecordClass; aMultiIndexFieldNames : TArrayOfRawUTF8; aUnique : Boolean = False); overload;
  end;

  TSQLRecordClassArray = array of TSQLRecordClass;

  TFilterParams = record
    Field : RawUTF8;
    Value : Variant;
  end;

  TSQLRecordTimeStamped = class(TSQLRecord)
  private
    fCreationDate: TCreateTime;
    fModifiedDate: TModTime;
  published
    property CreationDate: TCreateTime read fCreationDate write fCreationDate;
    property ModifiedDate: TModTime read fModifiedDate write fModifiedDate;
  end;

  function GetQueryParam(const aParams : string; const QueryParam : string) : string;


implementation


function GetQueryParam(const aParams : string; const QueryParam : string) : string;
var
  param : string;
  pair : string;
  value : TArray<string>;
begin
  Result := '';
  if aParams.Contains('?') then
  begin
    param := Copy(aParams,Pos('?',aParams)+1,aParams.Length);
    for pair in param.Split(['&']) do
    begin
      value := pair.Split(['=']);
      if value[0].ToLower = QueryParam.ToLower then
      begin
        Result := value[1];
        Break;
      end;
    end;
  end;
end;

{$IFNDEF ANDROID}
{ TArrayOfRawUTF8Helper }

procedure TArrayOfRawUTF8Helper.Add(const value: RawUTF8; AllowDuplicates : Boolean = False);
var
  arr : TDynArray;
begin
  arr.Init(TypeInfo(TArrayOfRawUTF8),Self);
  if AllowDuplicates then
  begin
    if arr.IndexOf(value) = -1 then arr.Add(value);
  end
  else arr.Add(value);
end;

procedure TArrayOfRawUTF8Helper.Remove(const value: RawUTF8);
var
  idx : Integer;
  arr : TDynArray;
begin
  arr.Init(TypeInfo(TArrayOfRawUTF8),Self);
  idx := arr.IndexOf(value);
  if idx <> -1 then arr.Delete(idx);
end;

function TArrayOfRawUTF8Helper.Exists(const value : RawUTF8) : Boolean;
var
  idx : Integer;
  arr : TDynArray;
begin
  arr.Init(TypeInfo(TArrayOfRawUTF8),Self);
  idx := arr.IndexOf(value);
  if idx <> -1 then Result := True
    else Result := False;
end;

procedure TArrayOfRawUTF8Helper.Clear;
begin
  Self := [];
end;

function TArrayOfRawUTF8Helper.Count : Integer;
begin
  Result := High(Self) + 1;
end;
{$ENDIF}

{ TDBIndexArrayHelper }

procedure TDBIndexArrayHelper.Add(aSQLRecordClass : TSQLRecordClass; aIndexFieldName : RawUTF8; aUnique : Boolean = False);
var
  dbindex : TDBIndex;
begin
  dbindex.SQLRecordClass := aSQLRecordClass;
  dbindex.FieldNames := [aIndexFieldName];
  Self := Self + [dbindex];
end;

procedure TDBIndexArrayHelper.Add(aSQLRecordClass : TSQLRecordClass; aMultiIndexFieldNames : TArrayOfRawUTF8; aUnique : Boolean = False);
var
  dbindex : TDBIndex;
begin
  dbindex.SQLRecordClass := aSQLRecordClass;
  dbindex.FieldNames := aMultiIndexFieldNames;
  Self := Self + [dbindex];
end;

end.
