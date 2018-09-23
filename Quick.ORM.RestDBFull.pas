{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.RestDBFull
  Description : Rest ORM access local/remote db only
  Author      : Kike Pérez
  Version     : 1.5
  Created     : 12/06/2017
  Modified    : 23/09/2018

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

unit Quick.ORM.RestDBFull;

interface

{$INCLUDE synopse.inc}

uses
  Classes,
  SysUtils,
  SynCommons,
  SynDBODBC,
  mORMot,
  mORMotDB,
  mORMotSQLite3,
  SynSQLite3Static,
  Quick.ORM.Engine,
  Quick.ORM.Server.Base,
  Quick.ORM.DataBase,
  Quick.ORM.Security,
  Quick.ORM.Server.Config;

type

  //Server with direct DB access
  TORMRestDBFull = class(TORMBaseServer)
  private
    fConfigFile : TORMRestDBFullConfig;
    procedure ConfigFileLoaded;
  public
    ORM : TSQLRestServer;
    constructor Create(cFullMemoryMode : Boolean = False); override;
    destructor Destroy; override;
    function Connect : Boolean; overload; override;
    function Connect(DoCustomDB : TProc) : Boolean; overload;
  end;


implementation

{TORMRestDB Class}

constructor TORMRestDBFull.Create(cFullMemoryMode : Boolean = False);
begin
  inherited Create(cFullMemoryMode);
  fConfigFile := TORMRestDBFullConfig.Create;
  fConfigFile.OnLoadConfig := Self.ConfigFileLoaded;
  //fConfigFile.Load; loads on connect
end;

destructor TORMRestDBFull.Destroy;
begin
  if Assigned(ORM) then ORM.Free;
  if Assigned(fConfigFile) then fConfigFile.Free;
  inherited;
end;

function TORMRestDBFull.Connect : Boolean;
begin
  Result := Connect(nil);
end;

function TORMRestDBFull.Connect(DoCustomDB : TProc) : Boolean;
var
  DBIndex : TDBIndex;
begin
  Result := False;
  //load config file
  if UseConfigFile then fConfigFile.Load;

  if Assigned(DataBase.Model) then DataBase.Model.Free;
  DataBase.Model := TSQLModel.Create(DataBase.IncludedClasses, DataBase.aRootURI);
  if DataBase.FullMemoryMode then
  begin
    if DataBase.IncludedClasses = nil then ORM := TSQLRestServerFullMemory.CreateWithOwnModel([])
      else ORM := TSQLRestServerFullMemory.Create(DataBase.Model,False);
  end
  else
  begin
    if not Assigned(DoCustomDb) then
    begin
    case DataBase.DBType of
      dtSQLite : ORM := TSQLRestServerDB.Create(DataBase.Model,DataBase.DBFileName,Security.Enabled);
      dtMSSQL :
        begin  {SQL Server Native Client 10.0}
          //fDataBase.Model := TSQLModel.Create(fDataBase.IncludedClasses);
          DataBase.SQLProperties := //TOleDBMSSQL2008ConnectionProperties.Create(fDataBase.SQLConnection.ServerName,fDataBase.SQLConnection.DataBase,fDataBase.SQLConnection.Username,fDataBase.SQLConnection.UserPass);
          TODBCConnectionProperties.Create('','Driver={SQL Server} ;Database='+DataBase.SQLConnection.DataBase+';'+
            'Server='+DataBase.SQLConnection.ServerName+';UID='+DataBase.SQLConnection.Username+';Pwd='+DataBase.SQLConnection.UserPass,'','');
          VirtualTableExternalRegisterAll(DataBase.Model,DataBase.SQLProperties);
          ORM := TSQLRestServerDB.Create(DataBase.Model,SQLITE_MEMORY_DATABASE_NAME,Security.Enabled,'');
        end;
    end;
    end
    else DoCustomDB;
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
  //checks if default security needs to apply
  Security.SetDefaultSecurity;
  Result := True;
end;

procedure TORMRestDBFull.ConfigFileLoaded;
begin
  //read base config file fields of Base class
  ReadBaseConfigFile(fConfigFile);
end;

end.
