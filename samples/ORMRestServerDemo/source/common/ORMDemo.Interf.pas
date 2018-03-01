unit ORMDemo.Interf;

interface

uses
  mORMot;

type

  IServiceMethods = interface(IInvokable)
    ['{4EB49814-A4A9-40D2-B85A-137DDF43C72C}']
    function Sum(val1, val2 : Double) : Double;
    function Mult(val1, val2 : Double) : Double;
    function RandomNumber : Int64;
  end;

implementation

initialization

TInterfaceFactory.RegisterInterfaces([TypeInfo(IServiceMethods)]);

end.
