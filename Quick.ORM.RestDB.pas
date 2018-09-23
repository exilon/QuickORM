{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.RestDB
  Description : Rest ORM access SQLite db only
  Author      : Kike Pérez
  Version     : 1.5
  Created     : 02/06/2017
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

unit Quick.ORM.RestDB;

interface

{$INCLUDE synopse.inc}

uses
  Classes,
  SysUtils,
  {$IFDEF NEXTGEN}
  Not compatible with firemonkey android/ios
  {$ENDIF}
  SynCommons,
  SynDBODBC,
  mORMot,
  mORMotDB,
  mORMotSQLite3,
  SynSQLite3,
  SynSQLite3Static,
  Quick.ORM.Engine,
  Quick.ORM.DataBase,
  Quick.ORM.Security,
  Quick.ORM.Server.Config;

type

  TIDDynArray = mORMot.TIDDynArray;

  //Client with direct SQLite DB access
  TORMRestDB = class
  private
    fDataBase : TORMDataBase;
    fSecurity : TORMSecurity;
    fConfigFile : TORMRestDBConfig;
    fUseConfigFile : Boolean;
  public
    ORM : TSQLRestClientDB;
    property DataBase : TORMDataBase read fDataBase write fDataBase;
    property Security : TORMSecurity read fSecurity write fSecurity;
    constructor Create;
    destructor Destroy; override;
    function Connect : Boolean; overload; override;
    function Connect(DoCustomDB : TProc) : Boolean; overload;
  end;


implementation

{TORMRestDB Class}

constructor TORMRestDB.Create;
begin
  inherited;
  fDataBase := TORMDataBase.Create;
  fSecurity := TORMSecurity.Create;
end;

destructor TORMRestDB.Destroy;
begin
  if Assigned(ORM) then ORM.Free;
  if Assigned(fDataBase) then fDataBase.Free;
  if Assigned(fSecurity) then fSecurity.Free;
  inherited;
end;

function TORMRestDB.Connect : Boolean;
begin
  Result := Connect(nil);
end;

function TORMRestDB.Connect(DoCustomDB : TProc) : Boolean;
var
  DBIndex : TDBIndex;
begin
  Result := False;

  if Assigned(fDataBase.Model) then fDataBase.Model.Free;
  fDataBase.Model := TSQLModel.Create(fDataBase.IncludedClasses, fDataBase.aRootURI);
  if fDataBase.FullMemoryMode then
  begin
    ORM := TSQLRestClientDB.Create(fDataBase.Model,nil,SQLITE_MEMORY_DATABASE_NAME,TSQLRestServerDB,fSecurity.Enabled,'');
  end
  else
  begin
    if not Assigned(DoCustomDb) then
    begin
    case fDataBase.DBType of
      dtSQLite : ORM := TSQLRestClientDB.Create(fDataBase.Model, nil, fDataBase.DBFileName, TSQLRestServerDB);
      dtMSSQL :
        begin  {SQL Server Native Client 10.0} {Microsoft OLE DB Provider for SQL Server}
          //fDataBase.Model := TSQLModel.Create(fDataBase.IncludedClasses);
          fDataBase.SQLProperties := //TOleDBMSSQL2008ConnectionProperties.Create(fDataBase.SQLConnection.ServerName,fDataBase.SQLConnection.DataBase,fDataBase.SQLConnection.Username,fDataBase.SQLConnection.UserPass);
          //TODBCConnectionProperties.Create('','Driver={SQL Server Native Client 10.0} ;Database='+fDataBase.SQLConnection.DataBase+';'+
          //  'Server='+fDataBase.SQLConnection.ServerName+';UID='+fDataBase.SQLConnection.Username+';Pwd='+fDataBase.SQLConnection.UserPass+';MARS_Connection=yes','','');
          TODBCConnectionProperties.Create('',DataBase.SQLConnection.GetConnectionString,'','');
          VirtualTableExternalRegisterAll(fDataBase.Model,fDataBase.SQLProperties);
          //fDataBase.Model.VirtualTableRegister(fDataBase.IncludedClasses[0],TSQLVirtualTableBinary);
          ORM := TSQLRestClientDB.Create(fDataBase.Model,nil,SQLITE_MEMORY_DATABASE_NAME,TSQLRestServerDB,fSecurity.Enabled,'');
        end;
    end;
    end
    else DoCustomDB;
  end;
  //exclusive mode speeds up sqlite performance, but db can't be accessible from outside processes
  if fDataBase.LockMode = TSQLiteLockMode.lmExclusive then ORM.Server.DB.LockingMode := TSQLLockingMode.lmExclusive
    else ORM.Server.DB.LockingMode := TSQLLockingMode.lmNormal;
  //creates tables if not exists
  ORM.Server.CreateMissingTables;
  //create indexes
  for DBIndex in DataBase.DBIndexes do
  begin
    if DBIndex.FieldNames.Count > 1 then ORM.Server.CreateSQLMultiIndex(DBIndex.SQLRecordClass,DBIndex.FieldNames,DBIndex.Unique)
      else ORM.Server.CreateSQLIndex(DBIndex.SQLRecordClass,DBIndex.FieldNames,DBIndex.Unique);
  end;
  //assigns ORM to security class
  fSecurity.SetORMServer(ORM);
  //checks if default security needs to apply
  fSecurity.SetDefaultSecurity;
  Result := True;
end;

end.
