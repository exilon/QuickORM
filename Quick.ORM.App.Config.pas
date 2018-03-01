{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.App.Config
  Description : Load/Save config from/to JSON file
  Author      : Kike Pérez
  Version     : 1.1
  Created     : 26/01/2017
  Modified    : 29/09/2017

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

unit Quick.ORM.App.Config;

interface

uses
  System.Classes, System.SysUtils, mORMot, SynCommons, SynCrypto;

type

  TORMAppConfig = class(TSQLRecord)
  private
    fConfigFile : RawUTF8;
    fConfigEncrypted : Boolean;
    fConfigPassword : RawUTF8;
  public
    property ConfigFile : RawUTF8 read fConfigFile write fConfigFile;
    property ConfigEncrypted : Boolean read fConfigEncrypted write fConfigEncrypted;
    property ConfigPassword : RawUTF8 read fConfigPassword write fConfigPassword;
    function Load(CreateIfNotExists : Boolean = False) : Boolean;
    function Save : Boolean;
  end;

  {Usage: create a descend class from TORMAppConfig and add published properties to be loaded/saved

    TMyConfig = class(TORMAppConfig)
  private
    fName : RawUTF8;
    fSurname : RawUTF8;
    fStatus : Integer;
  published
    property Name : RawUTF8 read fName write fName;
    property SurName : RawUTF8 read fSurname write fSurname;
    property Status : Integer read fStatus write fStatus;
  end;
  }

implementation


{ TORMAppConfig }

function TORMAppConfig.Load(CreateIfNotExists : Boolean = False) : Boolean;
var
  tmp : RawUTF8;
begin
  if (CreateIfNotExists) and (not FileExists(fConfigFile)) then
  begin
    Self.Save;
    Result := False;
  end;

  try
    if fConfigEncrypted then
    begin
      tmp := AnyTextFileToRawUTF8(fConfigFile,true);
      if tmp <> '' then
      begin
        tmp := AESSHA256(tmp,fConfigPassword,False);
        RemoveCommentsFromJSON(pointer(tmp));
        JSONToObject(Self,pointer(tmp),result,nil,[]);
      end;
    end
    else
    begin
      Result := JSONFileToObject(fConfigFile,Self);
    end;
  except
    on e : Exception do raise e;
  end;
end;

function TORMAppConfig.Save : Boolean;
var
  json : RawUTF8;
begin
  try
    if fConfigEncrypted then
    begin
      json := ObjectToJSON(Self);
      json := AESSHA256(json,fConfigPassword,True);
      Result := FileFromString(json,fConfigFile);
    end
    else
    begin
      Result := ObjectToJSONFile(Self,fConfigFile);
    end;
  except
    on e : Exception do raise e;
  end;
end;



end.
