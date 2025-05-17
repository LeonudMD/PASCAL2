unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, DBCtrls, DBGrids, uSolver, dbf, DB, Model, LazUTF8;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    CheckBox1: TCheckBox;
    DataSource1: TDataSource;
    Dbf1: TDbf;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    poisk: TEdit;
    ploshadbatarei: TEdit;
    kolvoball: TEdit;
    Label24: TLabel;
    Label25: TLabel;
    otnmassSPH: TEdit;
    Label23: TLabel;
    PageControl1: TPageControl;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    udmasskotsr: TEdit;
    Label22: TLabel;
    otnmassDY: TEdit;
    Label21: TLabel;
    udmassDY: TEdit;
    Label20: TLabel;
    udmassEY: TEdit;
    energKPD: TEdit;
    Label18: TLabel;
    Label19: TLabel;
    tyagKPD: TEdit;
    Label17: TLabel;
    Moshnost: TEdit;
    Label16: TLabel;
    tyaga: TEdit;
    Label15: TLabel;
    startmass: TEdit;
    exckon: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    radiuskon: TEdit;
    naklkon: TEdit;
    exc0: TEdit;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label9: TLabel;
    radius0: TEdit;
    nakl0: TEdit;
    ScorostIst: TEdit;
    MotorVr: TEdit;
    MassaPN: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure poiskChange(Sender: TObject);
    procedure Dbf1FilterRecord(DataSet: TDataSet; var Accept: Boolean);

  private

  public

  end;

var
  Form1: TForm1;
  param: TMTAParam;
  DYParam: TTaskParam;
  r0: real;
  rk: real;
  i0: real;
  ik: real;
  Tm: real;
  mpn:real;
  rate : real;
  M0: real;
  AlphaEY:real;
  GammaDY:real;
  GammaK:real;
  GammaSPX:real;
  NuT:real;
  NuEY:real;
  bal: integer;


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Dbf1.FilePath:=ExtractFilePath(Application.ExeName);
 Dbf1.FilePathFull:=ExtractFilePath(Application.ExeName);
 if not FileExists('engines.dbf') then begin

  with Dbf1.FieldDefs do begin
   Add('ID', ftAutoInc, 0, True);
   Add('NAME', ftString, 16, True);
   Add('Thrust, mN', ftString, 16, True);
   Add('Specific impulse, s', ftString, 16, True);
   Add('Power consumption, kW', ftString, 16, True);
   Add('Efficiency, %', ftString, 16, True);
   Add('Resource, h', ftString, 16, True);
   Add('Weight, kg', ftString, 16, True);
  end;

  Dbf1.CreateTable;
 end;

 Dbf1.Open;

 Dbf1.OnFilterRecord := @Dbf1FilterRecord;

end;

procedure TForm1.CheckBox1Change(Sender: TObject);
begin
 Dbf1.Filtered:=(Sender as TCheckBox).Checked;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  P, Mpn, M0, a0, c, Tm, copt, i0, e0, r0, ik, ek, rk,
  AlphaEY, GammaDY, GammaK, GammaSPX, NuT, NuEY, bal, SSB: real;
begin
  // 1) Считываем всё в локальные переменные (как было)
  if not TryStrToFloat(MassaPN.Text, Mpn) then begin
    ShowMessage('Неверное значение массы полезной нагрузки');
    Exit;
  end;
  if not TryStrToFloat(MotorVr.Text, Tm) then begin
    ShowMessage('Неверное значение времени полёта');
    Exit;
  end;
  if not TryStrToFloat(ScorostIst.Text, c) then begin
    ShowMessage('Неверное значение скорости истечения');
    Exit;
  end;
  i0 := StrToFloat(nakl0.Text) * Pi/180;
  r0 := StrToFloat(radius0.Text);
  e0 := StrToFloat(exc0.Text);
  ik := StrToFloat(naklkon.Text) * Pi/180;
  rk := StrToFloat(radiuskon.Text);
  ek := StrToFloat(exckon.Text);

  AlphaEY  := StrToFloat(udmassEY.Text);
  GammaDY  := StrToFloat(udmassDY.Text);
  GammaK   := StrToFloat(udmasskotsr.Text);
  GammaSPX := StrToFloat(otnmassSPH.Text);
  NuT      := StrToFloat(tyagKPD.Text);
  NuEY     := StrToFloat(energKPD.Text);
  bal      := StrToFloat(kolvoball.Text);

  // 2) Простые проверки, чтобы не делить на ноль
  if (NuT = 0) or (NuEY = 0) then begin
    ShowMessage('Ошибка: КПД не может быть равным 0.');
    Exit;
  end;
  if c = 0 then begin
    ShowMessage('Ошибка: скорость истечения не может быть равной 0.');
    Exit;
  end;

  // 3) Инициализируем параметры энергоустановки
  param.AlphaEY  := AlphaEY;
  param.GammaDY  := GammaDY;
  param.GammaK   := GammaK;
  param.GammaSPX := GammaSPX;
  param.NuT      := NuT;
  param.NuEY     := NuEY;

  // 4) Подготовка параметров перелёта (не трогаем)
  InitTaskParam(DYParam, r0, i0, rk, ik, Tm, c);

  // 5) Собственно расчёты
  M0   := GetStartMass(param, c, Tm*24*3600, DYParam.Vxk*1000, Mpn);
  P    := GetMTAPower(param, c, M0*DYParam.begin_accel*1000);
  copt := GetRateopt(param, Tm*24*3600);

  // 6) Отображаем результаты
  startmass.Text := FloatToStr(M0);
  Moshnost.Text  := FloatToStr(P);
  exc0.Text      := FloatToStr(copt);
end;

procedure TForm1.poiskChange(Sender: TObject);
begin
  // «Обновляем» фильтрацию
  Dbf1.Filtered := False;
  Dbf1.Filtered := CheckBox1.Checked;
end;



procedure TForm1.Dbf1FilterRecord(DataSet: TDataSet; var Accept: Boolean);
var
  needle, hay: string;
begin
  // Если фильтр выключен — пропускаем всё
  if not CheckBox1.Checked then
  begin
    Accept := True;
    Exit;
  end;

  // Иначе — фильтруем по подстроке (рус/латинница, без учёта регистра)
  needle := UTF8LowerCase(poisk.Text);
  hay    := UTF8LowerCase(DataSet.FieldByName('NAME').AsString);

  // Пустой текст — пускаем всё, иначе ищем вхождение
  Accept := (needle = '') or (Pos(needle, hay) > 0);
end;



end.

