{ ***************************************************************************

  Copyright (c) 2016-2018 Kike Pérez

  Unit        : Quick.ORM.Form.Login
  Description : ORMRestClient Login Form
  Author      : Kike Pérez
  Version     : 1.1
  Created     : 02/06/2017
  Modified    : 09/09/2017

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
unit Quick.ORM.Form.Login;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Winapi.ShellAPI,
  Vcl.ExtCtrls;

type
  TfrmLogin = class(TForm)
    edHost: TEdit;
    edUsername: TEdit;
    edUserPass: TEdit;
    btnOk: TButton;
    btnCancel: TButton;
    lblHost: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    cxSaveCredentials: TCheckBox;
    edPort: TEdit;
    imgLogo: TImage;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    OldPassword : string;
    procedure GetMainExeIcon(IconIndex : Word);
  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.dfm}

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  GetMainExeIcon(1);
end;

procedure TfrmLogin.GetMainExeIcon(IconIndex : Word);
var
   Icon : TIcon;
   Filename : string;
begin
  Filename := ExtractFileName(ParamStr(0));
  Icon := TIcon.Create;
  try
    Icon.Handle := ExtractAssociatedIcon(hInstance,PChar(FileName),IconIndex);
    Icon.Transparent := True;
    imgLogo.Picture.Bitmap.Assign(Icon);
  finally
    Icon.Free;
  end;
end;

end.
