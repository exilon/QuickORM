
**QuickORM**
----------
QuickORM is a simple RestServer and Restclient based on mORMot framework. Provides a fast implementation of client-server applications in few minutes.

*NEW: Custom external database compatibility (Thanks to @juanter)
*NEW: Easy external DB Mapping Fields
*NEW: Client with basic android compatibility.
*NEW: Delphinus support

----------
This framework uses next libraries:

  Synopse mORMot framework. Copyright (C) 2017 Arnaud Bouchez (Synopse Informatique - https://synopse.info)
	https://synopse/mORMot
	
  QuickLib. Copyright (C) 2016-2018 Kike Pérez
	https://github.com/exilon/QuickLib

## Server classes
There are 3 server flavors:

**TORMRestDB:** Rest ORM access to database. For single applications without client connection needs.
**TORMRestDBFull:** It's a client and embeded server. Client comunicates to server that provides cache benefits. For single application without client connection needs.
**TORMRestServer:** Rest ORM with http server embeded, allowing clients connections to ORM and services published.
## Client classes
**TORMRestClient:** Client to connect to ORMRestServer and acces to database or published services.
## Documentation
### TORMRestServer:
Connect to your SQLite, InMemory or External database providing ORM access and publish rest services with http server or websockets. Define security, ip and apikey restrictions with easy.
You can provide a binding port in command line to allow reverse proxies like ARR (with httpplatform module installed) or Azure Webservices integration.
- **CustomORMServerClass:** Define a inherited class to declare your http published methods.
- **ConfigFile:** Defines configfile options. If enabled, a json config file will created with binding options, ip restrictions and api keys.
	- **Enabled:** If enabled uses config file and overrides in code options defined.
	- **RestartServerIfChanged:** Restarts server applying new settings if config file is modified (like web.config in IIS).
- **ORMRestServer.DataBase:** Defines connection to database and options.
	- **DBType:** Sqlite or MSSQL (more soon)
	- **DBFileName:** Path to sqlite database.
	- **aRootURI:** First path of URL /root/ by default.
	- **DBIndexes:** Specifies indexes your database will create if not exists.
	- **FullMemoryMode:** Database creates in memory, no file needed.
	- **LockMode:** Normal or exclusive acces to speedup operations.
	- **IncludedClasses:** SQLRecord classes used in your database.
	- **SQLConnection:** Properties to connect to external database (host, user, password,...).
	- **DBMappingFiels:** Can map your internal class fields with external database fields (example: can map your SQLRecord ID with external IdCustom)
	
- **ORMRestServer.HTTPOptions:** HTTP Server configuration.
	- **Binding:** Defines listen ip and port for http server.
	- **Protocol:** Defines protocol as HTTPSocket,  Websockets or HTTP.Sys
	- **AuthMode:** HTTP Authentification mode.
	- **IPRestriction:** Defines restricted ip and exclusions.

- **ORMRestServer.Service:** Services configuration.
	- **ServiceInterface:** Interface with contract definition for your services.
	- **MethodClass:** Class with implementation of services.
	- **Enabled**: Defines if services are published through your http server. 

	
- **ORMRestServer.Security:** Security related options, user, groups and tables permissions.
	- **DefaultAdminPassword:** Defines default password when database is first created.
	- **ServiceAuthorizationPolicy:** Defines if all your services are accesible to all users or not.
	- **PublicServices:** Defines which services interface-based are public (No authentification needed).
	- **PublicMethods:** Defines which methods are public (No authentification needed).
	- **Users:** Create, modify and remove users, passwords and group membership.
	- **Groups:** Create, modify and remove groups. Manage services and tables permissions. All permissions are stored on database.

## Examples
```delphi	

//Create a new user and group and allow services access
RestServer.Security.Groups.Add('Operators').CopySecurityFrom('User').GlobalSecurity.AllowServices := spAllow;
RestServer.Security.Users.Add('mike','5555').Group('Supervisor');
//Change user "mike" password
RestServer.Security.Users['mike'].Password := '1234';
	
//Allow Guest group access to "Sum" service only
RestServer.Security.Groups['Guest'].GlobalSecurity.AllowAllServices := spDeny;
RestServer.Security.Groups['Guest'].Service('Sum').Allow;
	
//Deny Operators group access to table "Reports"
RestServer.Security.Groups['Operators'].Table('Reports').DenyAll;
	
//Gives readonly permissions to Operators group
RestServer.Security.Groups['Operators'].Table('Reports').ReadOnly
	
//Allow "Operators" group Read and Create access to table "Reports"
with RestServer.Security.Groups['Operators'].Table('Reports') do
begin
	CanRead := True;
	CanCreate := True;
	CanUpdate := False;
	CanDelete := False;
end;
	
//Create a unique index
RestServer.DBIndexes.Add(TMyClass,'FieldName',True);
	
//Create a multiindex
ORMRestServer.DBIndexes.Add(TMyClass,['FieldName1','FieldName2']);

//Define public methods
RestServer.Security.PublicMethods := ['Method1','Method2'];

//Mapping fields
RestServer.Database.DBMappingFiels.Map(TMySQLRecord,'ID','IDCustom');
```

Do you want learn delphi? [learndelphi.org](https://learndelphi.org)