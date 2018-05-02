program ORMRestServer;

{$APPTYPE CONSOLE}

{$INCLUDE synopse.inc}
{$R *.res}

uses
  SysUtils,
  DateUtils,
  mORMot,
  SynCommons,
  Quick.Commons,
  Quick.Log,
  Quick.Console,
  Quick.ORM.Engine,
  Quick.ORM.RestServer,
  Quick.ORM.Security,
  Quick.ORM.DataBase,
  ORMDemo.Model,
  ORMDemo.RestMethods,
  ORMDemo.Interf,
  ORMDemo.CustomServer;

//contains interface for rest service

var
  RestServer : TORMRestServer;
  i : Integer;
  User : TAUser;
  Group : TAGroup;
  Login : TLogin;
  randomname : string;

begin
  try
    Log := TQuickLog.Create;
    Log.SetLog('.\ServerHTTPSocket.log',False,20);
    Log.ShowEventType := True;
    Log.ShowHeaderInfo := True;
    Console.LogVerbose := LOG_DEBUG;
    Console.Log := Log;
    RestServer := TORMRestServer.Create(False);
    RestServer.CustomORMServerClass := TORMServer;
    RestServer.DataBase.DBType := dtSQLite;
    RestServer.DataBase.DBFileName := '.\ORMTest.db3';
    RestServer.DataBase.IncludedClasses := [TAUser,TAGroup];
    RestServer.HTTPOptions.Binding.IP := '127.0.0.1';
    RestServer.HTTPOptions.Binding.Port := 8099;
    RestServer.HTTPOptions.Protocol := TSrvProtocol.spWebSocketBidir_Binary;
    RestServer.HTTPOptions.AuthMode := TAuthMode.amDefault;
    RestServer.ServerLog := LOG_ONLYERRORS;
    RestServer.HTTPOptions.IPRestriction.DefaultSecurityRule := TSecurityAccess.saAllowed;
    RestServer.HTTPOptions.IPRestriction.ExcludedIPFromDefaultRule.Add('127.0.0.1');
    RestServer.Service.MethodClass := TServiceMethods;
    RestServer.Service.MethodInterface := IServiceMethods;
    RestServer.Service.InstanceImplementation := sicShared;
    RestServer.Service.Enabled := True;
    RestServer.Security.DefaultAdminPassword := 'exilon';
    RestServer.Security.ServiceAuthorizationPolicy := TServiceAuthorizationPolicy.saDenyAll;
    RestServer.Security.PublicMethods := ['Test','AppActions']; //method-based public allowed
    RestServer.Security.PublicServices := True; //interface-based public allowed
    RestServer.ConfigFile.Enabled := True; //config file overwrites in-code config
    RestServer.Connect;
    coutFmt('DB service listening on port %d',[RestServer.HTTPOptions.Binding.Port],etInfo);
    RestServer.Security.Users.Add('pepe','1234').DisplayName := 'Pepelu';
    RestServer.Security.Users.Add('joan','5555').Group('Supervisor');
    RestServer.Security.Users.Add('restricted').Password('1234').Group('Guest');
    RestServer.Security.Users.Add('other').Password('1234').Group('Operator');
    RestServer.Security.Groups.Add('Admin2').CopySecurityFrom('User').GlobalSecurity.AllowServices := spAllow;
    RestServer.Security.Groups.Add('Operator').CopySecurityFrom('User');
    RestServer.Security.Users['pepe'].Group('Admin');
    RestServer.Security.Groups['Admin'].GlobalSecurity.AllowAllServices := spAllow;
    RestServer.Security.Groups['Supervisor'].AllowedServices := ['Sum','Mult'];
    RestServer.Security.Groups['Supervisor'].GlobalSecurity.AllowAllTables := spDeny;
    RestServer.Security.Groups['Supervisor'].Table('AUser').AllowAll;
    RestServer.Security.Groups['Admin'].Service('RandomNumber').Deny;
    RestServer.Security.Groups['Operator'].Service('Sum').Allow;
    RestServer.Security.Groups['Guest'].GlobalSecurity.AllowServices := spAllow;
    RestServer.Security.Groups['Guest'].Service('Sum').Allow;
    RestServer.Security.Groups['Operator'].Table('AUser').DenyAll;
    RestServer.Security.Groups['Operator'].Table('AGroup').AllowAll.CanDelete := False;
    RestServer.Security.Groups['Guest'].Table('AUser').DenyAll;
    with RestServer.Security.Groups['Guest'].Table('AGroup') do
    begin
      CanRead := True;
      CanCreate := True;
      CanUpdate := False;
      CanDelete := False;
    end;
    RestServer.Security.Groups['User'].Table('AGroup').ReadOnly;

    RestServer.Security.Groups['Admin'].AppAction('Home.Open').Allow;
    RestServer.Security.Groups['Admin'].AppAction('Users.List').Allow;

    RestServer.Security.Groups['Operator'].AppAction('Home.Open').Allow;
    RestServer.Security.Groups['Operator'].AppAction('Users.List').Deny;

    RestServer.Security.ApplySecurity;

    //access from browser
    //http://127.0.0.1:8099/root/ServiceMethods.Sum?[2,2]

    //creates 10 dummy users
    for i := 1 to 10 do
    begin
      User := TAUser.Create;
      try
        randomname := IntToStr(Random(10000));
        User.Name := 'User' + randomname;
        User.Surname := 'Surname' + randomname;
        User.Age := Random(50)+20;
        Login.Username := 'user' + randomname;
        Login.UserPass := TSQLAuthUser.ComputeHashedPassword(IntToStr(Random(9999)+1000));
        Login.LastLogin := IncDay(Now,Random(60)*-1);
        User.Login := Login;
        RestServer.ORM.AddOrUpdate(User);
      finally
        User.Free;
      end;
    end;
    for i := 1 to 10 do
    begin
      Group := TAGroup.Create;
      try
        Group.Name := 'Group' + IntToStr(Random(10000));
        Group.AllowNewUsers := Boolean(Random(1));
        RestServer.ORM.AddOrUpdate(Group);
      finally
        Group.Free;
      end;
    end;
    ConsoleWaitForEnterKey;
    RestServer.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
