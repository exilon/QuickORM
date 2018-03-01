unit ClientMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  mORMot,
  SynCommons,
  Quick.ORM.Engine,
  Quick.ORM.RestClient,
  ORMDemo.Model, //unit contains Models for Demo
  Vcl.StdCtrls,
  System.Generics.Collections,
  ORMDemo.Interf; //unit contains interface for rest methods

type
  TMainForm = class(TForm)
    btnConnect: TButton;
    meInfo: TMemo;
    btnGetUsers: TButton;
    btnGetGroups: TButton;
    btnFuncSum: TButton;
    btnFuncRandom: TButton;
    btnFuncMult: TButton;
    edVal1: TEdit;
    edVal2: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnConnectClick(Sender: TObject);
    procedure btnGetUsersClick(Sender: TObject);
    procedure GetUsers;
    procedure GetGroups;
    procedure btnGetGroupsClick(Sender: TObject);
    procedure btnFuncSumClick(Sender: TObject);
    procedure btnFuncMultClick(Sender: TObject);
    procedure btnFuncRandomClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  RestClient : TORMRestClient;
  RestFunc : IServiceMethods;

implementation

{$R *.dfm}

procedure TMainForm.btnConnectClick(Sender: TObject);
var
  done : Boolean;
begin
  if RestClient.HTTPOptions.AuthMode = amNoAuthentication then done := RestClient.Connect
    else done := RestClient.LoginPrompt(True);
  //done := RestClient.Connect(edHost.Text,StrToInt(edPort.Text));
  if done then meInfo.Lines.Add('Connected to RestServer!')
  else
  begin
    meInfo.Lines.Add('Can''t connect to Restserver!');
    Exit;
  end;
  btnGetUsers.Enabled := done;
  btnGetGroups.Enabled := done;
  btnFuncSum.Enabled := done;
  btnFuncMult.Enabled := done;
  btnFuncRandom.Enabled := done;

  //gets Interface-Method service
  if RestClient.Service.Enabled then RestClient.Service.SetRestMethod(RestFunc);

  //show apps actions access security
  if RestClient.ActionAllowed('Home.Open') then meInfo.Lines.Add('Allowed "Home.Open"')
    else meInfo.Lines.Add('Denied "Home.Open"');

  if RestClient.ActionAllowed('Users.List') then meInfo.Lines.Add('Allowed "Users.List"')
    else meInfo.Lines.Add('Denied "Users.List"');
end;

procedure TMainForm.btnFuncMultClick(Sender: TObject);
begin
  meInfo.Lines.Add(FloatToStr(RestFunc.Mult(StrToFloat(edVal1.Text),StrToFloat(edVal2.Text))));
end;

procedure TMainForm.btnFuncRandomClick(Sender: TObject);
begin
  meInfo.Lines.Add(IntToStr(RestFunc.RandomNumber));
end;

procedure TMainForm.btnFuncSumClick(Sender: TObject);
begin
  meInfo.Lines.Add(FloatToStr(RestFunc.Sum(StrToFloat(edVal1.Text),StrToFloat(edVal2.Text))));
end;

procedure TMainForm.btnGetGroupsClick(Sender: TObject);
begin
  GetGroups;
end;

procedure TMainForm.btnGetUsersClick(Sender: TObject);
begin
  if RestClient.ActionAllowed('Users.List') then GetUsers
    else ShowMessage('Action not allowed!');
end;

procedure TMainForm.GetUsers;
var
  User : TAUser;
begin
  User := TAUser.CreateAndFillPrepare(RestClient.ORM,'',[]);
  try
    if User = nil then
    begin
      meInfo.Lines.Add('No results found!');
      Exit;
    end;
    while User.FillOne do
    begin
      meInfo.Lines.Add(Format('%s / %d year(s) / LastLogin: %s',[User.Name,User.Age,DateTimeToStr(User.Login.LastLogin)]));
    end;
  finally
    User.Free;
  end;
end;

procedure TMainForm.GetGroups;
var
  Group : TAGroup;
  Groups : TObjectList<TAGroup>;
begin
  Groups := RestClient.ORM.RetrieveList<TAGroup>;
  if (Groups <> nil) and (Groups.Count > 0) then
  begin
    try
      for Group in Groups do
      begin
        meInfo.Lines.Add(Format('%s / Allowed: %s',[Group.Name,Group.AllowNewUsers.ToString]));
      end;
    finally
      Groups.Free;
    end
  end
  else
  begin
    meInfo.Lines.Add('No results found!');
    Exit;
  end;
end;


procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  RestFunc := nil;
  RestClient.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  listbox : TListBox;
begin
  RestClient := TORMRestClient.Create;
  RestClient.Host := '127.0.0.1';
  RestClient.Port := 8099;
  RestClient.DataBase.IncludedClasses := [TAUser,TAGroup];
  RestClient.Login.UserName := 'Admin';
  RestClient.Login.UserPass := 'exilon';
  RestClient.HTTPOptions.Protocol := TSrvProtocol.spWebSocketBidir_Binary;
  RestClient.HTTPOptions.AuthMode := TAuthMode.amDefault;
  RestClient.Service.MethodInterface := IServiceMethods;
  RestClient.Service.InstanceImplementation := sicShared;
  RestClient.Service.Enabled := True;
end;

end.
