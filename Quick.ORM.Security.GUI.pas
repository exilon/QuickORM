{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.Security.GUI
  Description : Rest ORM Security GUI User/Services
  Author      : Kike Pérez
  Version     : 1.2
  Created     : 23/07/2017
  Modified    : 24/07/2017

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

unit Quick.ORM.Security.GUI;

interface

uses
  Classes,
  System.SysUtils,
  System.Win.Registry,
  SynCommons,
  mORMot,
  Quick.Commons,
  Quick.ORM.Form.Login;

type
  TORMLoginGUI = class
  private
    fFrmLogin : TfrmLogin;
    fHost : RawUTF8;
    fPort : Integer;
    fUserName : RawUTF8;
    fUserPass : RawUTF8;
  public
    property Host : RawUTF8 read fHost write fHost;
    property Port : Integer read fPort write fPort;
    property UserName : RawUTF8 read fUserName write fUserName;
    property UserPass : RawUTF8 read fUserPass write fUserPass;
    function LoginPrompt(ShowHostPrompt : Boolean = True) : Boolean;
    function LoadCredentials : Boolean;
    function SaveCredentials : Boolean;
  end;

implementation

function TORMLoginGUI.LoadCredentials : Boolean;
var
  reg : TRegistry;
  appname : string;
begin
  Result := False;
  appname := ExtractFileNameWithoutExt(ParamStr(0));
  reg := TRegistry.Create;
  try
    if reg.OpenKey('\Software\' + appName + '\Auth',False) then
    begin
      fHost := reg.ReadString('Host');
      fPort := reg.ReadInteger('Port');
      fUserName := reg.ReadString('UserName');
      fUserPass := reg.ReadString('UserPass');
      Result := True;
    end;
  finally
    reg.Free;
  end;
end;

function TORMLoginGUI.SaveCredentials : Boolean;
var
  reg : TRegistry;
  appname : string;
begin
  Result := False;
  appname := ExtractFileNameWithoutExt(ParamStr(0));
  reg := TRegistry.Create;
  try
    reg.OpenKey('\Software\' + appName + '\Auth',True);
    reg.WriteString('Host',fHost);
    reg.WriteInteger('Port',fPort);
    reg.WriteString('UserName',fUserName);
    reg.WriteString('UserPass',fUserPass);
  finally
    reg.Free;
  end;
end;


function TORMLoginGUI.LoginPrompt(ShowHostPrompt : Boolean = True) : Boolean;
var
  saved : Boolean;
begin
  Result := False;
  //check if saved credentials or prompts for credentials
  saved := LoadCredentials;
  fFrmLogin := TfrmLogin.Create(nil);
  try
    fFrmLogin.lblHost.Visible := ShowHostPrompt;
    fFrmLogin.edHost.Visible := ShowHostPrompt;
    fFrmLogin.edPort.Visible := ShowHostPrompt;
    fFrmLogin.cxSaveCredentials.Checked := saved;

    fFrmLogin.edHost.Text := fHost;
    fFrmLogin.edPort.Text := fPort.ToString;
    fFrmLogin.edUsername.Text := fUserName;
    fFrmLogin.edUserPass.Text := fUserPass;
    fFrmLogin.OldPassword := fUserPass;

    if fFrmLogin.ShowModal = 1 then
    begin
      fHost := fFrmLogin.edHost.Text;
      fPort := StrToInt(fFrmLogin.edPort.Text);
      fUserName := fFrmLogin.edUsername.Text;
      if (saved) and (fFrmLogin.edUserPass.Text = fFrmLogin.OldPassword) then fUserPass := fFrmLogin.edUserPass.Text
        else fUserPass := TSQLAuthUser.ComputeHashedPassword(fFrmLogin.edUserPass.Text);
      if fFrmLogin.cxSaveCredentials.Checked then SaveCredentials;
      Result := True;
    end;
  finally
    fFrmLogin.Free;
  end;
end;

end.
