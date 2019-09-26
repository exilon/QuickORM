{ ***************************************************************************

  Copyright (c) 2016-2019 Kike Pérez

  Unit        : Quick.ORM.Security
  Description : Rest ORM Security User/Services
  Author      : Kike Pérez
  Version     : 1.6
  Created     : 20/06/2017
  Modified    : 26/09/2019

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

unit Quick.ORM.Security;

{$i QuickORM.inc}

interface

uses
  Classes,
  SysUtils,
  {$IFDEF NEXTGEN}
  SynCrossPlatformJSON,
  SynCrossPlatformRest,
  {$ELSE}
  mORMot,
  SynCommons,
  {$ENDIF}
  Generics.Collections,
  Quick.Commons,
  Quick.ORM.Engine;

type

  // SQLRights
  //           POSTSQL SELECTSQL Service AuthR AuthW TablesR TablesW
  // Admin        Yes     Yes       Yes    Yes   Yes    Yes    Yes
  // Supervisor   No      Yes       Yes    Yes   No     Yes    Yes
  // User         No      No        Yes    No    No     Yes    Yes
  // Guest        No      No        No     No    No     Yes    No
  // *Service     No      No        Yes    No    No     No     No

  TServiceNames = array of RawUTF8;

  TSecurityPermission = (spNotDefined, spAllow, spDeny);
  TSecurityAccess = (saAllowed, saDenied);

  //Interface-based security
  TORMServiceSecurity = class
  private
    fServiceName : RawUTF8;
    fPermission : TSecurityPermission;
    fNeedsAuth : Boolean;
  published
    property ServiceName : RawUTF8 read fServiceName write fServiceName;
    property Permission : TSecurityPermission read fPermission write fPermission;
    property NeedsAuth : Boolean read fNeedsAuth write fNeedsAuth;
  public
    constructor Create(const cServiceName : string);
    procedure Allow;
    procedure Deny;
  end;

  TORMServiceList = array of TORMServiceSecurity;

  //Table access security
  TORMTableSecurity = class
  private
    fTableID : Integer;
    fTableName : RawUTF8;
    fCanCreate : Boolean;
    fCanRead : Boolean;
    fCanUpdate : Boolean;
    fCanDelete : Boolean;
  public
    constructor Create(const cTableName : string);
    function DenyAll : TORMTableSecurity;
    function AllowAll : TORMTableSecurity;
    procedure ReadOnly;
  published
    property TableID : Integer read fTableID write fTableID;
    property TableName : RawUTF8 read fTableName write fTableName;
    property CanCreate : Boolean read fCanCreate write fCanCreate;
    property CanRead : Boolean read fCanRead write fCanRead;
    property CanUpdate : Boolean read fCanUpdate write fCanUpdate;
    property CanDelete : Boolean read fCanDelete write fCanDelete;
  end;

  TORMTableList = array of TORMTableSecurity;

  //App functions access security
  TORMAppSecurity = class
  private
    fAction : RawUTF8;
    fDescription : RawUTF8;
    fPermission : TSecurityPermission;
  published
    property Action : RawUTF8 read fAction write fAction;
    property Description : RawUTF8 read fDescription write fDescription;
    property Permission : TSecurityPermission read fPermission write fPermission;
  public
    constructor Create(const cAction : string);
    procedure Allow;
    procedure Deny;
    function Allowed : Boolean;
  end;

  TORMAppSecurityList = array of TORMAppSecurity;

  //ORM AuthUser
  TORMAuthUser = class(TSQLAuthUser)
  private
    fDeleted : Boolean;
    fChangedGroupName : RawUTF8;
  public
    constructor Create; override;
    property IsDeleted : Boolean read fDeleted;
    property ChangedGroupName : RawUTF8 read fChangedGroupName;
    function Password(cPass : RawUTF8) : TORMAuthUser;
    function Group(cGroupName : RawUTF8) : TORMAuthUser;
    procedure Remove;
  end;

  //Global security for Services, Methods, Tables and Apps
  TGlobalSecurity = class
  private
    fAllowServices : TSecurityPermission;
    fAllowAllServices : TSecurityPermission;
    fAllowAllTables : TSecurityPermission;
    fAllowAllAppActions : TSecurityPermission;
  published
    property AllowServices : TSecurityPermission read fAllowServices write fAllowServices;
    property AllowAllServices : TSecurityPermission read fAllowAllServices write fAllowAllServices;
    property AllowAllTables : TSecurityPermission read fAllowAllTables write fAllowAllTables;
    property AllowAllAppActions : TSecurityPermission read fAllowAllAppActions write fAllowAllAppActions;
  end;

  //ORM AuthGroup
  TORMAuthGroup = class(TSQLAuthGroup)
  private
    fDeleted : Boolean;
    fCopySecurityGroup : RawUTF8;
    fGlobalSecurity : TGlobalSecurity;
    fServiceSecurity : TORMServiceList;
    fTableSecurity : TORMTableList;
    fAppSecurity : TORMAppSecurityList;
    procedure ClearLists;
    function GetServices(index : Integer) : TServiceNames;
    procedure SetServices(index : Integer; ServiceNames : TServiceNames);
  published
    property GlobalSecurity : TGlobalSecurity read fGlobalSecurity write fGlobalSecurity;
    property ServiceSecurity : TORMServiceList read fServiceSecurity write fServiceSecurity;
    property TableSecurity : TORMTableList read fTableSecurity write fTableSecurity;
    property AppSecurity : TORMAppSecurityList read fAppSecurity write fAppSecurity;
  public
    constructor Create; override;
    destructor Destroy; override;
    function FillOne : Boolean; virtual;
    property IsDeleted : Boolean read fDeleted;
    procedure Remove;
    function CopySecurityFrom(const cGroupName : string) : TORMAuthGroup;
    property AllowedServices : TServiceNames index 0 read GetServices write SetServices;
    property DeniedServices : TServiceNames  index 1 read GetServices write SetServices;
    function Service(const ServiceName : string) : TORMServiceSecurity;
    function Table(const TableName : string) : TORMTableSecurity;
    function AppAction(const Action : string) : TORMAppSecurity;
  end;

  //ORM User security
  TORMUserSecurity = class
  private
    fORMServer : TSQLRest;
    fUserChanges : TObjectList<TORMAuthUser>;
    procedure SetORMServer(cORMServer : TSQLRest);
    function GetFromList(cUserName : string; out AUser : TORMAuthUser) : Boolean; overload;
    function GetFromList(cID : TID; out AUser : TORMAuthUser) : Boolean; overload;
    function GetUserByName(const cUserName : string) : TORMAuthUser;
    function GetUserByID(cID : TID) : TORMAuthUser;
  public
    constructor Create;
    Destructor Destroy; override;
    function Exists(cUserName : string) : Boolean;
    property GetByName[const cUserName : string] : TORMAuthUser read GetUserByName; default;
    property GetByID[cID : TID] : TORMAuthUser read GetUserByID;
    function Add(const cUserName : string; cPassword : string = ''; FailIfExists : Boolean = False) : TORMAuthUser;
    function Remove(const cUserName : string) : Boolean;
    function RemoveAll : Boolean; //revisar
  end;

  //ORM Group security
  TORMGroupSecurity = class
  private
    fORMServer : TSQLRest;
    fGroupChanges : TObjectList<TORMAuthGroup>;
    procedure SetORMServer(cORMServer : TSQLRest);
    function GetFromList(cGroupName : string; out AGroup : TORMAuthGroup) : Boolean; overload;
    function GetFromList(cID : TID; out AGroup : TORMAuthGroup) : Boolean; overload;
    function GetGroupByName(const cGroupName : string) : TORMAuthGroup;
    function GetGroupByID(cID : TID) : TORMAuthGroup;
  public
    constructor Create;
    Destructor Destroy; override;
    function Exists(cGroupName : string) : Boolean;
    property GetByName[const cGroupName : string] : TORMAuthGroup read GetGroupByName; default;
    property GetByID[cID : TID] : TORMAuthGroup read GetGroupByID;
    function Add(const cGroupName : string; FailIfExists : Boolean = False) : TORMAuthGroup;
    function Remove(const cGroupName : string) : Boolean;
    function RemoveAll : Boolean; //revisar??
  end;

  //ORM security manager
  TORMSecurity = class
  private
    fDefaultAdminPassword : RawUTF8;
    fServiceAuthorizationPolicy : TServiceAuthorizationPolicy;
    fUsers : TORMUserSecurity;
    fGroups : TORMGroupSecurity;
    fORMServer : TSQLRest;
    fServiceFactoryServer : TServiceFactoryServer;
    fEnabled : Boolean;
    fPublicMethods : TArrayOfRawUTF8;
    fPublicServices : Boolean;
    fOnSecurityApplied : TSecurityAppliedEvent;
    procedure SetServiceFactoryServer(cServiceFactoryServer : TServiceFactoryServer);
  public
    constructor Create;
    destructor Destroy; override;
    property DefaultAdminPassword : RawUTF8 read fDefaultAdminPassword write fDefaultAdminPassword;
    property ServiceAuthorizationPolicy : TServiceAuthorizationPolicy read fServiceAuthorizationPolicy write fServiceAuthorizationPolicy;
    property ServiceFactoryServer : TServiceFactoryServer read fServiceFactoryServer write SetServiceFactoryServer;
    property Enabled : Boolean read fEnabled write fEnabled;
    property Users : TORMUserSecurity read fUsers write fUsers;
    property Groups : TORMGroupSecurity read fGroups write fGroups;
    property PublicMethods : TArrayOfRawUTF8 read fPublicMethods write fPublicMethods;
    property PublicServices : Boolean read fPublicServices write fPublicServices;
    property OnSecurityApplied : TSecurityAppliedEvent read fOnSecurityApplied write fOnSecurityApplied;
    procedure SetORMServer(cORMServer: TSQLRest);
    procedure SetDefaultSecurity;
    procedure SetServiceAuthorizationPolicy;
    procedure SetMethodAuthorizationPolicy;
    function ApplySecurity : Boolean;
  end;

implementation


{ TORMServiceSecurity }

constructor TORMServiceSecurity.Create(const cServiceName : string);
begin
  fServiceName := cServiceName;
end;

procedure TORMServiceSecurity.Allow;
begin
  fPermission := TSecurityPermission.spAllow;
end;

procedure TORMServiceSecurity.Deny;
begin
  fPermission := TSecurityPermission.spDeny;
end;


{ TORMTableSecurity }

constructor TORMTableSecurity.Create(const cTableName : string);
begin
  fTableName := cTableName;
  fCanRead := True;
  fCanCreate := True;
  fCanUpdate := True;
  fCanDelete := True;
end;

function TORMTableSecurity.AllowAll : TORMTableSecurity;
begin
  Result := Self;
  fCanCreate := True;
  fCanRead := True;
  fCanUpdate := True;
  fCanDelete := True;
end;

function TORMTableSecurity.DenyAll : TORMTableSecurity;
begin
  Result := Self;
  fCanCreate := False;
  fCanRead := False;
  fCanUpdate := False;
  fCanDelete := False;
end;

procedure TORMTableSecurity.ReadOnly;
begin
  fCanCreate := False;
  fCanRead := True;
  fCanUpdate := False;
  fCanDelete := False;
end;

{TORMAppSecurity Class}

constructor TORMAppSecurity.Create(const cAction : string);
begin
  fAction := cAction;
  fDescription := cAction;
  fPermission := TSecurityPermission.spNotDefined;
end;

procedure TORMAppSecurity.Allow;
begin
  fPermission := TSecurityPermission.spAllow;
end;

procedure TORMAppSecurity.Deny;
begin
  fPermission := TSecurityPermission.spDeny;
end;

function TORMAppSecurity.Allowed : Boolean;
begin
  if fPermission = TSecurityPermission.spAllow then Result := True
    else Result := False; //?? what happens if not defined
end;


{TORMAuthUser Class}

constructor TORMAuthUser.Create;
begin
  inherited;
  fChangedGroupName := '';
  fDeleted := False;
end;

function TORMAuthUser.Password(cPass: RawUTF8) : TORMAuthUser;
begin
  Result := Self;
  Self.SetPasswordPlain(cPass);
end;

function TORMAuthUser.Group(cGroupName: RawUTF8) : TORMAuthUser;
begin
  Result := Self;
  //will applied later on apply security changes
  fChangedGroupName := cGroupName;
  //Self.GroupRights := TORMAuthGroup(fGroupSecurity.Groups[cGroupName].ID);
  //raise Exception.Create(Format('Can''t assign group, not exits "%s" group',[cGroupName]));
end;

procedure TORMAuthUser.Remove;
begin
  Self.fDeleted := True;
end;


{TORMAuthUser Class}

constructor TORMAuthGroup.Create;
begin
  inherited;
  fCopySecurityGroup := '';
  fServiceSecurity := nil;
  fTableSecurity := nil;
  fAppSecurity := nil;
  fGlobalSecurity := TGlobalSecurity.Create;
  fGlobalSecurity.AllowServices := TSecurityPermission.spNotDefined;
  fGlobalSecurity.AllowAllServices := TSecurityPermission.spNotDefined;
  fGlobalSecurity.AllowAllTables := TSecurityPermission.spNotDefined;
end;

destructor TORMAuthGroup.Destroy;
begin
  ClearLists;
  fGlobalSecurity.Free;
  inherited;
end;

function TORMAuthGroup.FillOne;
begin
  fCopySecurityGroup := '';
  ClearLists;
  Result := inherited FillOne;
end;

procedure TORMAuthGroup.ClearLists;
var
  i : Integer;
begin
  for i := low(fServiceSecurity) to high(fServiceSecurity) do if Assigned(fServiceSecurity[i]) then fServiceSecurity[i].Free;
  fServiceSecurity := [];
  for i := low(fTableSecurity) to high(fTableSecurity) do if Assigned(fTableSecurity[i]) then fTableSecurity[i].Free;
  fTableSecurity := [];
  for i := low(fAppSecurity) to high(fAppSecurity) do if Assigned(fAppSecurity[i]) then fAppSecurity[i].Free;
  fAppSecurity := [];
end;

function TORMAuthGroup.GetServices(index : Integer) : TServiceNames;
var
  ServiceSecur : TORMServiceSecurity;
  mPermission : TSecurityPermission;
  arrServices : TDynArray;
begin
  case index of
   0 : mPermission := TSecurityPermission.spAllow;
   1 : mPermission := TSecurityPermission.spDeny;
   else mPermission := TSecurityPermission.spNotDefined;
  end;
  arrServices.Init(TypeInfo(TServiceNames),Result);
  for ServiceSecur in fServiceSecurity do
  begin
    if ServiceSecur.Permission = mPermission then arrServices.Add(ServiceSecur.ServiceName);
  end;
end;

procedure TORMAuthGroup.SetServices(index : Integer; ServiceNames : TServiceNames);
var
  ServiceName : RawUTF8;
begin
  for ServiceName in ServiceNames do
  begin
    if index = 0 then Service(ServiceName).Allow
     else Service(ServiceName).Deny;
  end;
end;

procedure TORMAuthGroup.Remove;
begin
  Self.fDeleted := True;
end;

function TORMAuthGroup.CopySecurityFrom(const cGroupName: string) : TORMAuthGroup;
begin
  Result := Self;
  fCopySecurityGroup := cGroupName;
end;

function TORMAuthGroup.Service(const ServiceName : string) : TORMServiceSecurity;
var
  ServiceSecur : TORMServiceSecurity;
  arrServiceSecurity : TDynArray;
begin
  //returns ServiceSecurity if exists
  for ServiceSecur in fServiceSecurity do
  begin
    if LowerCase(ServiceSecur.ServiceName) = LowerCase(ServiceName) then
    begin
      Result := ServiceSecur;
      Exit;
    end;
  end;
  //if not exists
  Result := TORMServiceSecurity.Create(ServiceName);
  arrServiceSecurity.Init(TypeInfo(TORMServiceList),fServiceSecurity);
  arrServiceSecurity.Add(Result);
end;

function TORMAuthGroup.Table(const TableName : string) : TORMTableSecurity;
var
  TableSecur : TORMTableSecurity;
  arrTableSecurity : TDynArray;
begin
  //returns TableSecurity if exists
  for TableSecur in fTableSecurity do
  begin
    if LowerCase(TableSecur.TableName) = LowerCase(TableName) then
    begin
      Result := TableSecur;
      Exit;
    end;
  end;
  //if not exists
  Result := TORMTableSecurity.Create(TableName);
  arrTableSecurity.Init(TypeInfo(TORMTableList),fTableSecurity);
  arrTableSecurity.Add(Result);
end;

function TORMAuthGroup.AppAction(const Action : string) : TORMAppSecurity;
var
  AppSecur : TORMAppSecurity;
  arrAppSecurity : TDynArray;
begin
  //returns AppSecurity if exists
  for AppSecur in fAppSecurity do
  begin
    if LowerCase(AppSecur.Action) = LowerCase(Action) then
    begin
      Result := AppSecur;
      Exit;
    end;
  end;
  //if not exists
  Result := TORMAppSecurity.Create(Action);
  arrAppSecurity.Init(TypeInfo(TORMAppSecurityList),fAppSecurity);
  arrAppSecurity.Add(Result);
end;


{TORMUserSecurity Class}

constructor TORMUserSecurity.Create;
begin
  inherited;
  fUserChanges := TObjectList<TORMAuthUser>.Create(True);
end;

destructor TORMUserSecurity.Destroy;
begin
  fUserChanges.Free;
  inherited;
end;

procedure TORMUserSecurity.SetORMServer(cORMServer: TSQLRest);
begin
  fORMServer := cORMServer;
end;

function TORMUserSecurity.Exists(cUserName : string) : Boolean;
var
  AUser : TORMAuthUser;
begin
  Result := False;
  //Checks if already exists in the list
  if not GetFromList(cUserName,AUser) then
  begin
    //if not found in list, checks in db
    AUser := TORMAuthUser.CreateAndFillPrepare(fORMServer,'LogonName=?',[cUsername]);
    try
      if AUser.FillOne then Result := True;
    finally
      AUser.Free;
    end;
  end
  else Result := True;
end;

function TORMUserSecurity.GetFromList(cUserName : string; out AUser : TORMAuthUser) : Boolean;
var
  User : TORMAuthUser;
begin
  Result := False;
  for User in fUserChanges do
  begin
    if User.LogonName = cUserName then
    begin
      Result := True;
      AUser := User;
      Break;
    end;
  end;
end;

function TORMUserSecurity.GetFromList(cID : TID; out AUser : TORMAuthUser) : Boolean;
var
  User : TORMAuthUser;
begin
  Result := False;
  for User in fUserChanges do
  begin
    if User.ID = cID then
    begin
      Result := True;
      AUser := User;
      Break;
    end;
  end;
end;

function TORMUserSecurity.GetUserByName(const cUserName : string) : TORMAuthUser;
begin
  //Checks if already exists in the list
  if not GetFromList(cUserName,Result) then
  begin
    //if not found in list, checks in db
    Result := TORMAuthUser.CreateAndFillPrepare(fORMServer,'LogonName=?',[cUsername]);
    if Result.FillOne then fUserChanges.Add(Result)
      else raise Exception.Create('User not found!');
  end;
end;

function TORMUserSecurity.GetUserByID(cID : TID) : TORMAuthUser;
begin
  //Checks if already exists in the list
  if not GetFromList(cID,Result) then
  begin
    //if not found in list, checks in db
    Result := TORMAuthUser.CreateAndFillPrepare(fORMServer,'ID=?',[cID]);
    if Result.FillOne then fUserChanges.Add(Result)
      else raise Exception.Create('User not found!');
  end;
end;

function TORMUserSecurity.Add(const cUserName : string; cPassword : string = ''; FailIfExists : Boolean = False) : TORMAuthUser;
begin
  //checks if exists user
  if Exists(cUserName) then
  begin
    if FailIfExists then raise Exception.Create(Format('Can''t add user "%s". Already exists!',[cUserName]))
      else Result := GetUserByName(cUserName);
  end
  else
  begin
    Result := TORMAuthUser.Create;
    Result.DisplayName := Capitalize(cUserName);
    Result.LogonName := cUserName;
    Result.PasswordPlain := cPassword;
    Result.GroupRights := TORMAuthGroup(3); //default as user
    fUserChanges.Add(Result);
  end;
end;

function TORMUserSecurity.Remove(const cUserName: string) : Boolean;
var
  AuthUser : TORMAuthUser;
begin
  Result := False;
  AuthUser := GetUserByName(cUserName);
  if AuthUser.ID <> 0 then
  begin
    AuthUser.Remove;
    Result := True;
  end;
end;

function TORMUserSecurity.RemoveAll : Boolean;
begin
  //deletes all users in AuthUsers
  Result := fORMServer.Delete(TORMAuthUser,'LogonName<>?',['Admin']);
end;



{TORMGroupSecurity Class}

constructor TORMGroupSecurity.Create;
begin
  inherited;
  fGroupChanges := TObjectList<TORMAuthGroup>.Create(True);
end;

destructor TORMGroupSecurity.Destroy;
begin
  fGroupChanges.Free;
  inherited;
end;

procedure TORMGroupSecurity.SetORMServer(cORMServer: TSQLRest);
begin
  fORMServer := cORMServer;
end;

function TORMGroupSecurity.Exists(cGroupName : string) : Boolean;
var
  AGroup : TORMAuthGroup;
begin
  Result := False;
  //Checks if already exists in the list
  if not GetFromList(cGroupName,AGroup) then
  begin
    //if not found in list, checks in db
    AGroup := TORMAuthGroup.CreateAndFillPrepare(fORMServer,'Ident=?',[cGroupName]);
    try
      if AGroup.FillOne then Result := True;
    finally
      AGroup.Free;
    end;
  end
  else Result := True;
end;

function TORMGroupSecurity.GetFromList(cGroupName : string; out AGroup : TORMAuthGroup) : Boolean;
var
  Group : TORMAuthGroup;
begin
  Result := False;
  for Group in fGroupChanges do
  begin
    if Group.Ident = cGroupName then
    begin
      Result := True;
      AGroup := Group;
      Break;
    end;
  end;
end;

function TORMGroupSecurity.GetFromList(cID : TID; out AGroup : TORMAuthGroup) : Boolean;
var
  Group : TORMAuthGroup;
begin
  Result := False;
  for Group in fGroupChanges do
  begin
    if Group.ID = cID then
    begin
      Result := True;
      AGroup := Group;
      Break;
    end;
  end;
end;

function TORMGroupSecurity.GetGroupByName(const cGroupName : string) : TORMAuthGroup;
begin
  //Checks if already exists in the list
  if not GetFromList(cGroupName,Result) then
  begin
    //if not found in list, checks in db
    Result := TORMAuthGroup.CreateAndFillPrepare(fORMServer,'Ident=?',[cGroupName]);
    if Result.FillOne then fGroupChanges.Add(Result)
      else raise Exception.Create(Format('Group "%s" not found!',[cGroupName]));
  end;
end;

function TORMGroupSecurity.GetGroupByID(cID : TID) : TORMAuthGroup;
begin
  //Checks if already exists in the list
  if not GetFromList(cID,Result) then
  begin
    //if not found in list, checks in db
    Result := TORMAuthGroup.CreateAndFillPrepare(fORMServer,'ID=?',[cID]);
    if Result.FillOne then fGroupChanges.Add(Result)
      else raise Exception.Create('Group not found!');
  end;
end;

function TORMGroupSecurity.Add(const cGroupName : string; FailIfExists : Boolean = False) : TORMAuthGroup;
var
  AuthGroup : TORMAuthGroup;
begin
  if Exists(cGroupName) then
  begin
    if FailIfExists then raise Exception.Create(Format('Can''t add group "%s". Already exists!',[cGroupName]))
      else Result := GetGroupByName(cGroupname);
  end
  else
  begin
    AuthGroup := TORMAuthGroup.Create;
    AuthGroup.Ident := cGroupName;
    AuthGroup.SessionTimeout := 60;
    //AuthGroup.SQLAccessRights := //get default from???
    fGroupChanges.Add(AuthGroup);
    Result := AuthGroup;
  end;
end;

function TORMGroupSecurity.Remove(const cGroupName: string) : Boolean;
var
  AuthGroup : TORMAuthGroup;
begin
  Result := False;
  AuthGroup := GetGroupByName(cGroupName);
  if AuthGroup.ID <> 0 then
  begin
    AuthGroup.Remove;
    Result := True;
  end;
end;

function TORMGroupSecurity.RemoveAll : Boolean;
begin
  //deletes all users in AuthUsers
  Result := fORMServer.Delete(TORMAuthGroup,'Ident<>?',['Admin']);
end;


{TORMSecurity Class}

constructor TORMSecurity.Create;
begin
  inherited;
  fUsers := TORMUserSecurity.Create;
  fGroups := TORMGroupSecurity.Create;
  fPublicMethods := []; //TMethodArray.Create([]);
  fPublicServices := False;
end;

destructor TORMSecurity.Destroy;
begin
  fUsers.Free;
  fGroups.Free;
  fPublicMethods := [];
  inherited;
end;

procedure TORMSecurity.SetORMServer(cORMServer: TSQLRest);
begin
  fORMServer := cORMServer;
  fUsers.SetORMServer(cORMServer);
  fGroups.SetORMServer(cORMServer);
end;

procedure TORMSecurity.SetServiceFactoryServer(cServiceFactoryServer : TServiceFactoryServer);
begin
  if cServiceFactoryServer = nil then raise Exception.Create('ServiceFactoryServer not assigned!');

  fServiceFactoryServer := cServiceFactoryServer;
  //applies services authorization policy from db
  SetServiceAuthorizationPolicy;
end;

procedure TORMSecurity.SetDefaultSecurity;
var
  AuthUser : TORMAuthUser;
begin
  if fEnabled then
  begin
    if fORMServer = nil then raise Exception.Create('ORM not assigned!');
    //changes default admin password and deletes Supervisor and User default accounts
    AuthUser := TORMAuthUser.CreateAndFillPrepare(fORMServer,'',[]);
    try
      while AuthUser.FillOne do
      begin
        if AuthUser.PasswordHashHexa = AuthUser.ComputeHashedPassword('synopse') then
        begin
          //changes default Admin password
          if AuthUser.LogonName = 'Admin' then
          begin
            //AuthUser.LogonName := 'admin';
            if fDefaultAdminPassword = '' then raise Exception.Create('Empty Admin password not allowed!');

            AuthUser.PasswordPlain := fDefaultAdminPassword;
            fORMServer.AddOrUpdate(AuthUser,False);
          end
          else //deletes other default accounts
          begin
            fORMServer.Delete(TORMAuthUser,AuthUser.ID);
          end;
        end;
      end;
    finally
      AuthUser.Free;
    end;
  end;
end;

procedure TORMSecurity.SetServiceAuthorizationPolicy;
var
  Group : TORMAuthGroup;
  SAR : TSQLAccessRights;
begin
  if fORMServer = nil then raise Exception.Create('ORM not assigned!');

  //apply global authorization

  //if security enabled sets services security
  if fEnabled then
  begin
    if (fServiceAuthorizationPolicy = saAllowAll) or (not fEnabled) then fServiceFactoryServer.AllowAll
      else fServiceFactoryServer.DenyAll;
    if fPublicServices then fServiceFactoryServer.ByPassAuthentication := True
      else fServiceFactoryServer.ByPassAuthentication := False;
  end;

  //apply group custom authorization
  if fEnabled then
  begin
    Group := TORMAuthGroup.CreateAndFillPrepare(fORMServer,'',[]);
    try
      while Group.FillOne do
      begin
        //apply service execution permissions
        if Group.GlobalSecurity.AllowServices <> TSecurityPermission.spNotDefined then
        begin
          SAR := Group.SQLAccessRights;
          if Group.GlobalSecurity.AllowServices = TSecurityPermission.spAllow then SAR.AllowRemoteExecute := SAR.AllowRemoteExecute + [reService]
            else Exclude(SAR.AllowRemoteExecute,reService);
          Group.SQLAccessRights := SAR;
        end;

        //apply global services permissions
        if Group.GlobalSecurity.AllowAllServices <> TSecurityPermission.spNotDefined then
        begin
          if Group.GlobalSecurity.AllowAllServices = TSecurityPermission.spAllow then fServiceFactoryServer.AllowAllByName(Group.Ident)
            else fServiceFactoryServer.DenyAllByName(Group.Ident);
        end;
        //apply custom services permissions
        fServiceFactoryServer.AllowByName(Group.AllowedServices,Group.Ident);
        fServiceFactoryServer.DenyByName(Group.DeniedServices,Group.Ident);
      end;
    finally
      Group.Free;
    end;
  end;
end;

procedure TORMSecurity.SetMethodAuthorizationPolicy;
var
  MethodName : RawUTF8;
begin
  //apply public methods without auth
  for MethodName in fPublicMethods do
  begin
    if (fORMServer as TSQLRestServer).ServiceMethodByPassAuthentication(MethodName) = -1 then raise Exception.Create('Public Method not found!');
  end;
end;

function TORMSecurity.ApplySecurity : Boolean;
var
  AUser : TORMAuthUser;
  AGroup : TORMAuthGroup;
  AGroupFrom : TORMAuthGroup;
  SAR : TSQLAccessRights;
  TableSecur : TORMTableSecurity;
  TableIdx : Integer;
  TableClass : TSQLRecordClass;
begin
  Result := True;
  if fORMServer = nil then raise Exception.Create('ORM not assigned!');
  //apply method security
  SetMethodAuthorizationPolicy;
  //apply group security changes
  for AGroup in fGroups.fGroupChanges do
  begin
    if AGroup.IsDeleted then
    begin
      if not fORMServer.Delete(TORMAuthGroup,AGroup.ID) then Result := False;
    end
    else
    begin
      //if needs copy security from other group
      if AGroup.fCopySecurityGroup <> '' then
      begin
        AGroupFrom := TORMAuthGroup.CreateAndFillPrepare(fORMServer,'Ident=?',[AGroup.fCopySecurityGroup]);
        try
          if AGroupFrom.FillOne then AGroup.SQLAccessRights := AGroupFrom.SQLAccessRights
            else raise Exception.Create(Format('Can''t get security from group. Group "%s" not found!',[AGroup.fCopySecurityGroup]));
        finally
          AGroupFrom.Free;
        end;
      end;
      //apply global table permissions
      if AGroup.GlobalSecurity.AllowAllTables <> spNotDefined then
      for TableClass in fORMServer.Model.Tables do
      begin
        TableIdx := fORMServer.Model.GetTableIndex(TableClass);
        SAR := AGroup.SQLAccessRights;
        if AGroup.GlobalSecurity.AllowAllTables = TSecurityPermission.spAllow then SAR.Edit(TableIdx,True,True,True,True)
          else SAR.Edit(TableIdx,False,False,False,False);
        AGroup.SQLAccessRights := SAR;
      end;
      //apply custom table security changes
      for TableSecur in AGroup.TableSecurity do
      begin
        try
          //checks if exists table in Model
          TableIdx := fORMServer.Model.GetTableIndex(TableSecur.TableName);
          if TableIdx > -1 then
          begin
            TableSecur.TableID := TableIdx;
            SAR := AGroup.SQLAccessRights;
            //apply custom permissions
            SAR.Edit(TableSecur.TableID,TableSecur.CanCreate,TableSecur.CanRead,TableSecur.CanUpdate,TableSecur.CanDelete);
            AGroup.SQLAccessRights := SAR;
          end
          else raise Exception.Create(Format('Don''t exists table "%s". Can''t change security!',[TableSecur.TableName]));
        except
          on E : Exception do raise Exception.Create(Format('Can''t change table "%s" security!. Error "%s"',[TableSecur.TableName,e.Message]));
        end;
      end;

      if fORMServer.AddOrUpdate(AGroup,False) = 0 then Result := False;
      //apply global services execution permissions
      if AGroup.GlobalSecurity.AllowServices <> TSecurityPermission.spNotDefined then
      begin
        SAR := AGroup.SQLAccessRights;
        if AGroup.GlobalSecurity.AllowServices = TSecurityPermission.spAllow then SAR.AllowRemoteExecute := SAR.AllowRemoteExecute + [reService]
          else Exclude(SAR.AllowRemoteExecute,reService);
        AGroup.SQLAccessRights := SAR;
      end;
      //apply group services global authorization
      if AGroup.GlobalSecurity.AllowAllServices <> TSecurityPermission.spNotDefined then
      begin
        if AGroup.GlobalSecurity.AllowAllServices = TSecurityPermission.spAllow then fServiceFactoryServer.AllowAllByName(AGroup.Ident)
          else fServiceFactoryServer.DenyAllByName(AGroup.Ident);
      end;
      //apply group custom services authorization
      fServiceFactoryServer.AllowByName(AGroup.AllowedServices,AGroup.Ident);
      fServiceFactoryServer.DenyByName(AGroup.DeniedServices,AGroup.Ident);
    end;
    //fGroups.fGroupChanges.Remove(AGroup);
  end;
  fGroups.fGroupChanges.Clear;

  if not result then Exit;
  Result := True;
  //apply user security changes
  for AUser in fUsers.fUserChanges do
  begin
    if AUser.IsDeleted then
    begin
      if not fORMServer.Delete(TORMAuthUser,AUser.ID) then Result := False;
    end
    else
    begin
      //if group changed
      if AUser.ChangedGroupName <> '' then
      begin
        AGroupFrom := TORMAuthGroup.CreateAndFillPrepare(fORMServer,'Ident=?',[AUser.ChangedGroupName]);
        try
          if AGroupFrom.FillOne then AUser.GroupRights := TORMAuthGroup(AGroupFrom.ID)
            else raise Exception.Create(Format('Can''t change user group. Group "%s" not found!',[AUser.ChangedGroupName]));
        finally
          AGroupFrom.Free;
        end;
      end;
      if fORMServer.AddOrUpdate(AUser,False) = 0 then Result := False;
      //fUsers.fUserChanges.Remove(AUser);
    end;
  end;
  fUsers.fUserChanges.Clear;
  if Assigned(fOnSecurityApplied) then fOnSecurityApplied;
end;


initialization

TJSONSerializer.RegisterObjArrayForJSON([TypeInfo(TORMServiceList), TORMServiceSecurity]);
TJSONSerializer.RegisterObjArrayForJSON([TypeInfo(TORMTableList), TORMTableSecurity]);
TJSONSerializer.RegisterObjArrayForJSON([TypeInfo(TORMAppSecurityList), TORMAppSecurity]);



end.
