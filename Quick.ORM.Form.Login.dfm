object frmLogin: TfrmLogin
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Login'
  ClientHeight = 158
  ClientWidth = 338
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  DesignSize = (
    338
    158)
  PixelsPerInch = 96
  TextHeight = 13
  object lblHost: TLabel
    Left = 83
    Top = 12
    Width = 54
    Height = 13
    AutoSize = False
    Caption = 'Server:'
  end
  object Label2: TLabel
    Left = 83
    Top = 39
    Width = 54
    Height = 13
    AutoSize = False
    Caption = 'User:'
  end
  object Label3: TLabel
    Left = 83
    Top = 66
    Width = 54
    Height = 13
    AutoSize = False
    Caption = 'Password:'
  end
  object imgLogo: TImage
    Left = 8
    Top = 14
    Width = 64
    Height = 64
    Center = True
    Stretch = True
  end
  object edHost: TEdit
    Left = 143
    Top = 9
    Width = 119
    Height = 21
    TabOrder = 0
    TextHint = 'Host or ip'
  end
  object edUsername: TEdit
    Left = 143
    Top = 36
    Width = 161
    Height = 21
    TabOrder = 2
    TextHint = 'User name'
  end
  object edUserPass: TEdit
    Left = 143
    Top = 63
    Width = 161
    Height = 21
    PasswordChar = '*'
    TabOrder = 3
    TextHint = 'Password'
  end
  object btnOk: TButton
    Left = 170
    Top = 125
    Width = 76
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Ok'
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 255
    Top = 125
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
  object cxSaveCredentials: TCheckBox
    Left = 143
    Top = 97
    Width = 187
    Height = 17
    Caption = 'Remember my credentials'
    TabOrder = 4
  end
  object edPort: TEdit
    Left = 265
    Top = 9
    Width = 39
    Height = 21
    NumbersOnly = True
    TabOrder = 1
    TextHint = 'Port'
  end
end
