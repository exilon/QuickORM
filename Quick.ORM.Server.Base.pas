{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.Server.Base
  Description : ORM Server Base
  Author      : Kike Pérez
  Version     : 1.4
  Created     : 02/06/2017
  Modified    : 17/09/2017

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

unit Quick.ORM.Server.Base;

interface

uses
  Classes,
  SysUtils,
  System.IOUtils,
  SynCommons,
  mORMot,
  mORMotSQLite3,
  mORMotDB,
  SynSQLite3Static,
  SynDBODBC,
  Quick.ORM.Engine,
  Quick.ORM.DataBase,
  Quick.ORM.Security,
  Quick.ORM.Server.Config;

type

  TReloadConfigEvent = procedure of object;
  TRestartServerEvent = procedure of object;

  {TServerLog = class
  private
    fLogType : TLogType; //mORMot or QuickLog
    fLogVerbose : TSynLogInfos;
  end;}

  TConfigFileOptions = class
  private
    fEnabled : Boolean;
    fRestartServerIfChanged : Boolean;
    fLockDebugMode : Boolean;
  public
    property Enabled : Boolean read fEnabled write fEnabled;
    property RestartServerIfChanged : Boolean read fRestartServerIfChanged write fRestartServerIfChanged;
    property LockDebugMode : Boolean read fLockDebugMode write fLockDebugMode;
    constructor Create;
  end;

  TORMBaseServer = class
  private
    fDataBase : TORMDataBase;
    fSecurity : TORMSecurity;
    fOnSecurityApplied : TSecurityAppliedEvent;
    fOnConnectionSuccess : TConnectionSuccessEvent;
    fOnConnectionFailed : TConnectionFailedEvent;
    fServerLog : TSynLogInfos;
    fConfigFile : TConfigFileOptions;
    fNeedsRestart : Boolean;
    fOnReloadConfig : TReloadConfigEvent;
    fOnRestart : TRestartServerEvent;
    procedure SetServerLog(Value : TSynLogInfos);
    procedure SecurityApplied;
  public
    property DataBase : TORMDataBase read fDataBase write fDataBase;
    property Security : TORMSecurity read fSecurity write fSecurity;
    property ServerLog : TSynLogInfos read fServerLog write SetServerLog;
    property ConfigFile : TConfigFileOptions read fConfigFile write fConfigFile;
    property NeedsRestart : Boolean read fNeedsRestart write fNeedsRestart;
    property OnSecurityApplied : TSecurityAppliedEvent read fOnSecurityApplied write fOnSecurityApplied;
    property OnConnectionSuccess : TConnectionSuccessEvent read fOnConnectionSuccess write fOnConnectionSuccess;
    property OnConnectionFailed : TConnectionFailedEvent read fOnConnectionFailed write fOnConnectionFailed;
    property OnReloadConfig : TReloadConfigEvent read fOnReloadConfig write fOnReloadConfig;
    property OnRestart : TRestartServerEvent read fOnRestart write fOnRestart;
    constructor Create(cFullMemoryMode : Boolean = False); virtual;
    destructor Destroy; override;
    procedure ReadBaseConfigFile(cConfig : TORMCustomConfig);
    function Connect : Boolean; virtual; abstract;
    procedure LoadConfig; virtual; abstract;
    procedure ReloadConfig; virtual; abstract;
    procedure GetDefinedServerConfig; virtual; abstract;
  end;

implementation

constructor TConfigFileOptions.Create;
begin
  inherited;
  fEnabled := True;
  fLockDebugMode := False;
  fRestartServerIfChanged := True;
end;

procedure TORMBaseServer.SetServerLog(Value : TSynLogInfos);
begin
  with TSQLLog.Family do
  begin
    CustomFileName := Format('%s_debug',[TPath.GetFileNameWithoutExtension(ParamStr(0))]);
    Level := Value;
    EchoToConsole := Value; // log all events to the console
    RotateFileCount := 2;
    RotateFileSizeKB := 20000;
  end;
end;

procedure TORMBaseServer.SecurityApplied;
begin
  if Assigned(fOnSecurityApplied) then fOnSecurityApplied;
end;

procedure TORMBaseServer.ReadBaseConfigFile(cConfig : TORMCustomConfig);
begin
  if cConfig.DBFilename <> '' then
  begin
    if DataBase.DBFileName <> cConfig.DBFilename then
    begin
      DataBase.DBFileName := cConfig.DBFilename;
      fNeedsRestart := True;
    end;
  end
  else cConfig.DBFilename := DataBase.DBFileName;
  if (cConfig.DebugMode) and (not fConfigFile.LockDebugMode) then SetServerLog(LOG_ALL)
    else SetServerLog(fServerLog);
end;

constructor TORMBaseServer.Create(cFullMemoryMode : Boolean = False);
begin
  fDataBase := TORMDataBase.Create;
  fDataBase.FullMemoryMode := cFullMemoryMode;
  fSecurity := TORMSecurity.Create;
  fSecurity.OnSecurityApplied := SecurityApplied;
  fServerLog := LOG_NONE;
  //fServerLog := LOG_ONLYERRORS;
  fConfigFile := TConfigFileOptions.Create;
  fNeedsRestart := False;
end;

destructor TORMBaseServer.Destroy;
begin
  if Assigned(fDataBase) then fDataBase.Free;
  if Assigned(fSecurity) then fSecurity.Free;
  if Assigned(fConfigFile) then fConfigFile.Free;
  inherited;
end;

end.
