unit MainUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Effects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,  FMX.Utils,
  System.Math, System.DateUtils, System.Threading;

const
  NUM_OF_AGENTS = 16000;

type
  TAntObj = Record
    x,y:Single;
    direction:Single;
    Gcolor:Byte;
  End;
  TForm1 = class(TForm)
    Timer1: TTimer;
    MakeScreenshotTimer: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure MakeScreenshotTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    BaseBitmap:TBitmap;
    Ants:Array[1..NUM_OF_AGENTS] of TAntObj;
    speed:Single;
    alpha_param:byte;
    stillmove:boolean;
    mode:byte;
    respawn_mode:Boolean;
    TrailKiller:boolean;
    KillWeak:boolean;
    settings_angle:Single;
    ShowInstructions:Boolean;
    InstructionsText:string;
    Hint_StartTime:TDateTime;
    Hint_Show:boolean;
    Hint_Text:string;
    function Sense(Ant:TAntObj;AngleOffset:Single;Data: TBitmapData):Byte;
    procedure AgentMove(i:Integer;Data:TBitmapData;alpha_param:byte;w,h:Integer);
    procedure ShowHint(hint:string);
    procedure HintDraw(canvas:TCanvas);
    procedure SaveScreenshot(x_count,y_count:integer;prefix:string = 'Screenshot');
    procedure StartPosition;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}
function TForm1.Sense(Ant:TAntObj;AngleOffset:Single;Data: TBitmapData):Byte;
var
  Angle:Single;
  newPosX,newPosY:Single;
begin
if TrailKiller and (Ant.x>Ants[1].x-50) and (Ant.x<Ants[1].x+50) and (Ant.y>Ants[1].y-50) and (Ant.y<Ants[1].y+50)
    and(ant.x <> Ants[1].x)and(ant.y <> Ants[1].y) then begin
      result:=0;
      Exit;
      end;
  Angle:=Ant.direction + AngleOffset;
  newPosX:=Ant.x+sin(Angle)*(speed+2);
  newPosY:=Ant.y+cos(Angle)*(speed+2);
  if newPosX>BaseBitmap.Width-1 then newPosX:=newPosX-BaseBitmap.Width+1;
  if newPosX<0 then newPosX:=newPosX+BaseBitmap.Width-1;
  if newPosY>BaseBitmap.Height-1 then newPosY:=newPosY-BaseBitmap.Height+1;
  if newPosY<0 then newPosY:=newPosY+BaseBitmap.Height-1;
Result := TAlphaColorRec(Data.GetPixel(Round(newPosX),Round(newPosY))).R;
//if Result>100 then Result:=Result-(Result-100)*2;
if (Result<10) and (mode = 1) then Result:=50;
if (Result>100) and (mode = 1) then Result:=0;
if (Result>128) and (mode = 2) then Result:=Result-(Result-128)*2;
//if (Result<10) and (mode = 4) then Result:=TAlphaColorRec(Data.GetPixel(Round(newPosX),Round(newPosY))).B;
if (Result>220) and (mode = 3) then Result:=220-(Result-220);
end;

function ARGBtoColorChannels(A, R, G, B: Byte):TAlphaColor;
var rec:TAlphaColorRec;
begin
rec.A:=A;
rec.R:=R;
rec.G:=G;
rec.B:=B;
Result:=TAlphaColor(rec);
end;

type
  PIntArray = ^TIntArray;
  TIntArray = array [0 .. 0] of Integer;

procedure Diffuse(Data: TBitmapData;w,h:Integer);
var
  R,B:PIntArray;
begin
GetMem(R,w * h * SizeOf(Integer));
GetMem(B,w * h * SizeOf(Integer));

TParallel.&For(0,w*h-1,
  procedure(i:Integer)
  var
    offsetX,offsetY,sampleX,sampleY:Integer;
    x,y,sum, sumB:integer;
  begin
    y:=i div w;
    x:=i mod w;
    sum:=0;
    sumB:=0;
    for offsetX := -1 to 1 do begin
      for offsetY := -1 to 1 do begin
        SampleX := min(w-1,max(0,x+offsetX));
        SampleY := min(h-1,max(0,y+offsetY));
        sum:=sum+TAlphaColorRec(Data.GetPixel(SampleX,SampleY)).R;
        sumB:=sumB+TAlphaColorRec(Data.GetPixel(SampleX,SampleY)).B;
        end;
      end;
    R[i]:=sum div 9;
    B[i]:=sumB div 9;
    if R[i]>0 then R[i]:=R[i]-1;
    if B[i]>0 then B[i]:=B[i]-1;
  end);
TParallel.&For(0,w*h-1,
  procedure(i:Integer)
  begin
      Data.SetPixel(i mod w,i div w,ARGBtoColorChannels(Form1.alpha_param,R[i],B[i] div 2,B[i]))
//    if (i div w + i) mod 2 = 0 then
//      Data.SetPixel(i mod w,i div w,ARGBtoColorChannels(Form1.alpha_param,R[i],B[i] div 2,B[i]))
//    else
//      Data.SetPixel(i mod w,i div w,ARGBtoColorChannels(Form1.alpha_param,R[i],R[i] div 2,B[i]))
//    //Data.SetPixel(i mod w,i div w,ARGBtoColorChannels(255,R[i],R[i],R[i]))
  end);
FreeMem(R,w * h * SizeOf(Integer));
FreeMem(B,w * h * SizeOf(Integer));
end;


procedure TForm1.AgentMove(i:Integer;Data:TBitmapData;alpha_param:byte;w,h:Integer);
var
  weights:array[1..3] of Byte;
  r:byte;
begin
weights[1]:=Sense(ants[i],settings_angle,Data);
weights[2]:=Sense(ants[i],0,Data);
weights[3]:=Sense(ants[i],-settings_angle,Data);
r:=TAlphaColorRec(Data.GetPixel(Round(Ants[i].x),Round(Ants[i].y))).R;
if KillWeak and (r = 0)then begin
  Ants[i].x:=w div 2;
  Ants[i].y:=h div 2;
  r:=200;
  end;
if r+20>255 then r:=255 else r:=r+20;
//Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(alpha_param,r,r,r));
if r<120 then
    Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(alpha_param,r,20,255))
  else
    Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(alpha_param,r,Ants[i].Gcolor,Ants[i].Gcolor div 2 + 60));
//Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(alpha_param,r,Ants[i].Gcolor,(255-r) div 2 + 128 ));
if TrailKiller and (i = 1) then
  Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),$FFFFFFFF);

if (weights[2]>weights[1]) and (weights[2]>weights[3]) then begin
  //Ants[i].direction:=Ants[i].direction;
  //Ants[i].direction:=Ants[i].direction+random*0.264-0.132;
  //Ants[i].direction:=Ants[i].direction+random(3)*0.6-0.3;
end else if (weights[2]<weights[1]) and (weights[2]<weights[3]) then begin
  //Ants[i].direction:=Ants[i].direction+random*0.6-0.3;
  Ants[i].direction:=Ants[i].direction+random(3)*settings_angle-settings_angle;
end else if weights[3]>weights[1] then begin
  Ants[i].direction:=Ants[i].direction-settings_angle;
end else if weights[3]<weights[1] then begin
  Ants[i].direction:=Ants[i].direction+settings_angle;
end else Ants[i].direction:=Ants[i].direction+random(3)*0.1-0.1;

if Ants[i].direction>2*pi then Ants[i].direction:=Ants[i].direction-2*pi;
if Ants[i].direction<0 then Ants[i].direction:=Ants[i].direction+2*pi;

if stillmove then begin
  Ants[i].x:=Ants[i].x+sin(Ants[i].direction)*speed;
  Ants[i].y:=Ants[i].y+cos(Ants[i].direction)*speed;
  end;

if respawn_mode then begin
    if (Ants[i].x>w-1) or (Ants[i].x<0) or (Ants[i].y>h-1) or (Ants[i].y<0) then begin
      Ants[i].x:=w div 2;
      Ants[i].y:=h div 2;
    end;
  end else begin
    if Ants[i].x>w-1 then Ants[i].x:=Ants[i].x-w+1;
    if Ants[i].x<0 then Ants[i].x:=Ants[i].x+w-1;
    if Ants[i].y>h-1 then Ants[i].y:=Ants[i].y-h+1;
    if Ants[i].y<0 then Ants[i].y:=Ants[i].y+h-1;
  end;
//Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),ARGBtoColorChannels(alpha_param,r,Ants[i].Gcolor,255));
if TrailKiller and (i = 1) then
  Data.SetPixel(Round(Ants[i].x),Round(Ants[i].y),$FFFFFFFF);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  bmp:TBitmap;
  Data: TBitmapData;
begin
bmp:= BaseBitmap;
//Blur(nil,bmp,1);
//if Timer1.Tag = 1 then Blur(nil,bmp,2);
//Timer1.Tag := (Timer1.Tag+1)mod 2;
bmp.Map(TMapAccess.ReadWrite, Data);
Diffuse(Data,bmp.Width,bmp.Height);
//NUM_OF_AGENTS
TParallel.&For(1,NUM_OF_AGENTS,
  procedure(i:Integer)
  begin
    AgentMove(i,Data,alpha_param,bmp.Width,bmp.Height);
  end);
//if KillWeak then KillWeak:=false;
bmp.Unmap(Data);
Canvas.BeginScene();
Canvas.DrawBitmap(bmp,RectF(0,0,bmp.Width,bmp.Height),RectF(0,0,Canvas.Width,Canvas.Height),1);
if ShowInstructions then
  Canvas.FillText(RectF(100,0,Canvas.Width,Canvas.Height), InstructionsText, false, 100, [],TTextAlign.Leading, TTextAlign.taCenter);
HintDraw(Canvas);
Canvas.EndScene;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
BaseBitmap.Free;
end;

procedure TForm1.StartPosition;
var
  i:word;
begin
for i := 1 to NUM_OF_AGENTS do begin
//  Ants[i].x:=Random(BaseBitmap.Width);
//  Ants[i].y:=Random(BaseBitmap.Height);
  Ants[i].direction:=i*2*pi/NUM_OF_AGENTS;
  Ants[i].x:=BaseBitmap.width div 2+sin(Ants[i].direction)*20;
  Ants[i].y:=BaseBitmap.height div 2+cos(Ants[i].direction)*20;
  Ants[i].Gcolor:=Random(100)+50;
  end;
BaseBitmap.Canvas.BeginScene;
BaseBitmap.Canvas.Clear($FF000000);
BaseBitmap.Canvas.EndScene;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
speed:=1.3;
settings_angle:=0.3;
alpha_param:=180;
stillmove:=true;
mode:=0;
respawn_mode:=true;
TrailKiller:=false;
KillWeak:=false;
BaseBitmap:=TBitmap.Create(Canvas.Width ,Canvas.Height );
StartPosition;
Canvas.Fill.Color := TAlphaColors.White;
InstructionsText:='Physarum polycephalum simulation'#10#13 +
  'by Aleshkov A.F., https://github.com/AlfAleshkov/Physarum-simulation'#10#13 +
  'Shortcut keys:'#10#13 +
  '"m" or "0","1","2"... - change mode of sensor calculation'#10#13 +
  '"p" - Pause'#10#13 +
  'Space - Agents pause, trail diffusion continues'#10#13 +
  '"+","-" - change agent angle'#10#13 +
  '"z","x" - change agent transparency (alpha channel)'#10#13 +
  '"r" - respawn mode: when reaching edges - die and respawn at center'#10#13 +
  '"k" - Enable/Disable trail-killer, one of agent (white point) turns off agents sensors around him'#10#13 +
  '"e" - Kill weak lonely agents'#10#13 +
  'Left click - Clear trail map within 50px radius'#10#13+
  '"F1" - show/hide this instructions';
ShowInstructions:=False;
ShowHint('Press F1 to view shortcuts keys');
end;


procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
if Key = vkF1 then ShowInstructions:= not ShowInstructions;
if Key = vkReturn then begin
  StartPosition;
end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
if KeyChar = 'p' then Timer1.Enabled:= not Timer1.Enabled;
if KeyChar = 'x' then
  alpha_param:=alpha_param+10;
if KeyChar = 'z' then
  alpha_param:=alpha_param-10;
if KeyChar = ' ' then stillmove:=not stillmove;
if KeyChar = 'm' then begin
  mode:=(mode+1) mod 4;
  ShowHint('Mode No: '+IntToStr(mode));
  end;
if KeyChar in ['0','1','2','3','4'] then begin
  mode:=StrToInt(KeyChar);
  ShowHint('Mode No: '+IntToStr(mode));
  end;
if KeyChar = 'r' then begin
  respawn_mode:= not respawn_mode;
  if respawn_mode then
    ShowHint('Respawn at center, ON') else ShowHint('Respawn mode OFF');
  end;
if KeyChar = 'k' then begin
  TrailKiller:= not TrailKiller;
  if TrailKiller then
    ShowHint('Trail-killer start hunting') else ShowHint('Trail-killer disabled');
  end;
if KeyChar = 'e' then begin
  KillWeak:=not KillWeak;
  if KillWeak then
    ShowHint('Weak agent execution') else ShowHint('Weak execution disabled');
  end;

if KeyChar = '-' then begin
  settings_angle:=settings_angle-0.02;
  ShowHint('settings_angle: '+IntToStr(Round(settings_angle * 180/pi)));
  end;
if KeyChar = '+' then begin
  settings_angle:=settings_angle+0.02;
  ShowHint('settings_angle: '+IntToStr(Round(settings_angle * 180/pi)));
  end;
if KeyChar = 's' then SaveScreenshot(1,1);
if KeyChar = 'a' then MakeScreenshotTimer.Enabled:= not MakeScreenshotTimer.Enabled;

end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var dx,dy:Integer;
begin
if Button = TMouseButton.mbLeft then begin
  BaseBitmap.Canvas.BeginScene;
  BaseBitmap.Canvas.Fill.Color:=$FF000000;
  dx:=Round(BaseBitmap.Width*x/canvas.Width);
  dy:=Round(BaseBitmap.Height*y/canvas.Height);
  BaseBitmap.Canvas.FillEllipse(RectF(dx-50,dy-50,dx+50,dy+50),1);
  BaseBitmap.Canvas.EndScene;
  end;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
var dx,dy:Integer;
begin
if ssRight in Shift then begin
  BaseBitmap.Canvas.BeginScene;
  BaseBitmap.Canvas.Fill.Color:=$FFFF0000;
  dx:=Round(BaseBitmap.Width*x/canvas.Width);
  dy:=Round(BaseBitmap.Height*y/canvas.Height);
  BaseBitmap.Canvas.FillEllipse(RectF(dx-10,dy-10,dx+10,dy+10),1);
  BaseBitmap.Canvas.EndScene;
  end;
end;

procedure TForm1.ShowHint(hint:string);
begin
Hint_StartTime:=Now;
Hint_Show:=true;
Hint_Text:=hint;
end;

procedure TForm1.HintDraw(canvas:TCanvas);
begin
if Hint_Show then begin
  if SecondsBetween(Hint_StartTime, Now) < 2 then begin
    Canvas.FillText(RectF(100,10,Canvas.Width,Canvas.Height), Hint_Text, false, 100,[],TTextAlign.Leading, TTextAlign.Leading);
  end else  Hint_Show:=false;
end;
end;

procedure TForm1.MakeScreenshotTimerTimer(Sender: TObject);
begin
SaveScreenshot(1,1,'Animation');
end;

procedure TForm1.SaveScreenshot(x_count,y_count:integer;prefix:string = 'Screenshot');
var
  qlt:TBitmapCodecSaveParams;
  i,j,w,h:integer;
  bmp:TBitmap;
  filename:string;
begin
ShowHint('Screenshot '+ExtractFilePath(ParamStr(0)));
qlt.Quality:=92;
if (x_count = 1) and (y_count = 1) then begin
  i:=1;
  filename:='';
  while (FileExists(filename))or(i=1) do begin
    filename:=ExtractFilePath(ParamStr(0))+prefix+Format('%.*d',[3, i])+'.jpg';
    inc(i);
    end;
  BaseBitmap.SaveToFile(filename,@qlt);
  exit;
end;
bmp:=TBitmap.Create(BaseBitmap.Width*x_count,BaseBitmap.Height*y_count);
w:=BaseBitmap.Width;
h:=BaseBitmap.Height;
bmp.Canvas.BeginScene;
for i := 0 to x_count-1 do
  for j := 0 to y_count-1 do
    bmp.Canvas.DrawBitmap(BaseBitmap,RectF(0,0,w,h),RectF(i*w,j*h,(i+1)*w,(j+1)*h),1);
bmp.Canvas.EndScene;
//BaseBitmap.SaveToFile(ExtractFilePath(ParamStr(0))+'Screenshot01.jpg',@qlt);

bmp.SaveToFile(ExtractFilePath(ParamStr(0))+'Texture01.jpg',@qlt);
bmp.Free
end;

end.
