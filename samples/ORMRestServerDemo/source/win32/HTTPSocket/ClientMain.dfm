object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'ORMRestClient HTTP Socket'
  ClientHeight = 380
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object btnConnect: TButton
    Left = 552
    Top = 347
    Width = 75
    Height = 25
    Caption = 'Connect'
    TabOrder = 0
    OnClick = btnConnectClick
  end
  object meInfo: TMemo
    Left = 8
    Top = 8
    Width = 619
    Height = 273
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object btnGetUsers: TButton
    Left = 463
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Get Users'
    Enabled = False
    TabOrder = 2
    OnClick = btnGetUsersClick
  end
  object btnGetGroups: TButton
    Left = 382
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Get Groups'
    Enabled = False
    TabOrder = 3
    OnClick = btnGetGroupsClick
  end
  object btnFuncSum: TButton
    Left = 95
    Top = 324
    Width = 75
    Height = 25
    Caption = 'Sum'
    Enabled = False
    TabOrder = 4
    OnClick = btnFuncSumClick
  end
  object btnFuncRandom: TButton
    Left = 301
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Random'
    Enabled = False
    TabOrder = 5
    OnClick = btnFuncRandomClick
  end
  object btnFuncMult: TButton
    Left = 95
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Mult'
    Enabled = False
    TabOrder = 6
    OnClick = btnFuncMultClick
  end
  object edVal1: TEdit
    Left = 12
    Top = 298
    Width = 77
    Height = 21
    TabOrder = 7
    Text = '4'
  end
  object edVal2: TEdit
    Left = 12
    Top = 325
    Width = 77
    Height = 21
    TabOrder = 8
    Text = '2'
  end
end
