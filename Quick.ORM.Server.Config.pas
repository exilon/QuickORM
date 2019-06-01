{ ***************************************************************************

  Copyright (c) 2016-2019 Kike Pérez

  Unit        : Quick.ORM.RestServer.Config
  Description : Rest ORM Server allows access by http, httpapi or websockets
  Author      : Kike Pérez
  Version     : 1.5
  Created     : 09/06/2017
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

unit Quick.ORM.Server.Config;

{$i QuickORM.inc}

interface

uses
  Classes,
  SysUtils,
  {$IFNDEF FPC}
  System.IOUtils,
  {$ELSE}
  Quick.Files,
  {$ENDIF}
  SynCommons,
  mORMot,
  Quick.ORM.Engine,
  Quick.ORM.Security,
  Quick.FileMonitor;

type

  TConfigChangedEvent = procedure of object;

  //Basic Server config file
  TORMCustomConfig = class
  private
    fConfigFilename : RawUTF8;
    fOnLoadConfig : TLoadConfigEvent;
    fDebugMode : Boolean;
    fDBFilename : RawUTF8;
    fFileMonitor : TQuickFileMonitor;
    fOnConfigChanged : TConfigChangedEvent;
    fReloaded : Boolean;
    procedure FileChangedNotify(MonitorNotify : TMonitorNotify);
  published
    property DebugMode : Boolean read fDebugMode write fDebugMode;
    property DBFilename : RawUTF8 read fDBFilename write fDBFilename;
  public
    constructor Create;
    destructor Destroy; override;
    property OnLoadConfig : TLoadConfigEvent read fOnLoadConfig write fOnLoadConfig;
    property OnConfigChanged : TConfigChangedEvent read fOnConfigChanged write fOnConfigChanged;
    function Load : Boolean;
    function Save : Boolean;
  end;

  TORMCustomConfigClass = class of TORMCustomConfig;

  TORMRestDBConfig = class(TORMCustomConfig);

  TORMRestDBFullConfig = class(TORMCustomConfig);

  TORMRestServerConfig = class(TORMCustomConfig)
  private
    fHost : RawUTF8;
    fPort : Integer;
    fIPRestrictionDefaultRule : RawUTF8;
    fIPRestrictionExcludedIP : TArrayOfRawUTF8;
    fAPIKeys : TArrayOfRawUTF8;
    function GetDefaultSecurityRule : TSecurityAccess;
    procedure SetDefaultSecurityRule(cSecurityAccess : TSecurityAccess);
  published
    property ServerHost : RawUTF8 read fHost write fHost;
    property ServerPort : Integer read fPort write fPort;
    property IPRestrictionDefaultRule : RawUTF8 read fIPRestrictionDefaultRule write fIPRestrictionDefaultRule;
    property IPRestrictionExcludedIP : TArrayOfRawUTF8 read fIPRestrictionExcludedIP write fIPRestrictionExcludedIP;
    property APIKeys : TArrayOfRawUTF8 read fAPIKeys write fAPIKeys;
  public
    property DefaultSecurityRule : TSecurityAccess read GetDefaultSecurityRule write SetDefaultSecurityRule;
    constructor Create;
  end;

implementation


{TORMCustomConfig Class}

constructor TORMCustomConfig.Create;
begin
  fConfigFilename := Format('%s\%s.config',[TPath.GetDirectoryName(ParamStr(0)),TPath.GetFileNameWithoutExtension(ParamStr(0))]);
  fOnLoadConfig := nil;
  fOnConfigChanged := nil;
  fReloaded := False;
  fDebugMode := False;
  fDBFilename := '';
  fFileMonitor := TQuickFileMonitor.Create;
  fFileMonitor.FileName := fConfigFilename;
  fFileMonitor.Interval := 2000;
  fFileMonitor.Notifies := [TMonitorNotify.mnFileModified];
  fFileMonitor.OnFileChange := FileChangedNotify;
  fFileMonitor.Enabled := True;
end;

destructor TORMCustomConfig.Destroy;
begin
  if Assigned(fFileMonitor) then
  begin
    fFileMonitor.Enabled := False;
    fFileMonitor.Free;
  end;
end;

procedure TORMCustomConfig.FileChangedNotify(MonitorNotify : TMonitorNotify);
begin
  if MonitorNotify = TMonitorNotify.mnFileModified then
  begin
    fReloaded := True;
    Self.Load;
    if Assigned(fOnConfigChanged) then fOnConfigChanged;
  end;
end;

function TORMCustomConfig.Load : Boolean;
begin
  fFileMonitor.Enabled := False;
  try
    if FileExists(fConfigFilename) then
    begin
      try
        Result := JSONFileToObject(fConfigFilename,Self,nil,[j2oIgnoreUnknownProperty]);
        if (not fReloaded) and (Result) and (Assigned(fOnLoadConfig)) then fOnLoadConfig;
        //saves to update possible new fields in json file
        if Result then Result := Self.Save
          else raise Exception.Create('Error reading Config File!');
      except
        on E : Exception do raise Exception.Create(Format('Can''t load/save Server Config! [%s]',[e.Message]));
      end;
    end
    else Result := Self.Save;
  finally
    fFileMonitor.Enabled := True;
  end;
  //if (not fReloaded) and (Result) and (Assigned(fOnLoadConfig)) then fOnLoadConfig;
end;

function TORMCustomConfig.Save : Boolean;
begin
  try
    Result := ObjectToJSONFile(Self,fConfigFilename);
  except
    on E : Exception do raise Exception.Create(Format('Can''t save Server Config! [%s]',[e.Message]));
  end;
end;

{TORMRestServerConfig Class}

constructor TORMRestServerConfig.Create;
begin
  inherited;
  fHost := '127.0.0.1';
  fPort := 8090;
  fDBFilename := '';
  fIPRestrictionDefaultRule := 'Allow';
  fIPRestrictionExcludedIP := [];
end;

function TORMRestServerConfig.GetDefaultSecurityRule : TSecurityAccess;
begin
  if LowerCase(fIPRestrictionDefaultRule) = 'allow' then Result := TSecurityAccess.saAllowed
    else Result := TSecurityAccess.saDenied;
end;

procedure TORMRestServerConfig.SetDefaultSecurityRule(cSecurityAccess : TSecurityAccess);
begin
  if cSecurityAccess = TSecurityAccess.saAllowed then fIPRestrictionDefaultRule := 'allow'
    else fIPRestrictionDefaultRule := 'denied';
end;

end.
