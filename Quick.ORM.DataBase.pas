{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.DataBase
  Description : Rest ORM Database config & connection
  Author      : Kike Pérez
  Version     : 1.2
  Created     : 20/06/2017
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

unit Quick.ORM.DataBase;

{$i QuickLogger.inc}

interface

uses
  Classes,
  SysUtils,
  SynCommons,
  mORMot,
  mORMotDB,
  SynDB,
  System.IOUtils,
  Quick.Commons,
  Quick.ORM.Engine;

type

  TORMDataBase = class
    private
      fSQLProperties : TSQLDBConnectionProperties;
      fDBFileName : RawUTF8;
      fDBType : TDBType;
      fDBIndexes : TDBIndexArray;
      fDBMappingFields : TDBMappingArray;
      fFullMemoryMode : Boolean;
      fModel : TSQLModel;
      faRootURI : RawUTF8;
      fIncludedClasses : TSQLRecordClassArray;
      fSQLConnection : TSQLConnection;
      fLockMode : TSQLiteLockMode;
      procedure SetDBFileName(const dbfname : RawUTF8);
    public
      property DBType : TDBType read fDBType write fDBType;
      property DBFileName : RawUTF8 read fDBFileName write SetDBFileName;
      property DBIndexes : TDBIndexArray read fDBIndexes write fDBIndexes;
      property DBMappingFields : TDBMappingArray read fDBMappingFields write fDBMappingFields;
      property Model : TSQLModel read fModel write fModel;
      property FullMemoryMode : Boolean read fFullMemoryMode write fFullMemoryMode;
      property LockMode : TSQLiteLockMode read fLockMode write fLockMode;
      property aRootURI : RawUTF8 read faRootURI write faRootURI;
      property IncludedClasses : TSQLRecordClassArray read fIncludedClasses write fIncludedClasses;
      property SQLProperties : TSQLDBConnectionProperties read fSQLProperties write fSQLProperties;
      property SQLConnection : TSQLConnection read fSQLConnection write fSQLConnection;
      constructor Create;
      destructor Destroy; override;
    end;

implementation


{TORMDataBase Class}

constructor TORMDataBase.Create;
begin
  fDBType := dtSQLite;
  fModel := nil;
  faRootURI := 'root';
  fDBFileName := '.\default.db3';
  fSQLConnection := TSQLConnection.Create;
  fSQLConnection.Provider := TDBProvider.dbMSSQL;
  fLockMode := TSQLiteLockMode.lmNormal;
end;

destructor TORMDataBase.Destroy;
begin
  if Assigned(fModel) then fModel.Free;
  if Assigned(fSQLConnection) then fSQLConnection.Free;
  inherited;
end;

procedure TORMDataBase.SetDBFileName(const dbfname : RawUTF8);
begin
  //if dbfile not found, sets as current app dir
  if (CompareText(dbfname,'SQLITE_MEMORY_DATABASE_NAME') = 0) or TFile.Exists(dbfname) then fDBFileName := dbfname
    else fDBFileName := Format('%s\%s',[path.EXEPATH,TPath.GetFileName(dbfname)]);
end;

end.
