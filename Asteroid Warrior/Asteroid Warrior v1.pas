uses wpfobjects, sounds, gameunit;
//Код в процессе перехода к ООП
//Код не оптимизирован
var k:=0.9;
var ShipAcceleration:= 0.8;
var gamedir:=GetCurrentDir;
var Shots := new list<GameObjT>;  //выстрелы
var Asteroids := new list<AsteroidT>;//препятствия
var Explosions := new list<ExplosionT>;//эффекты взрывов
var Scorebox, ShipHPBox,Hitbox, InfoBox: RoundRectWPF;//поле для отображения счета 
var GameoverBox,NewGameBox:RoundRectWPF;
var Score, ShotsLimit, ShotCD, NextShot, AsteroidsLimit, DebrisLimit: integer;
var ShotSpeed, TopShipSpeed, MaxAsteroidRadius, GameSpeed, shiphp: real;//скорость игры
var ku, kd, kl, kr, kf, GameOver, Cheat, playost, playshoot,playexplosive, N1L,cleanspace: boolean;//флаг проигрыша
var ost:sound;// := new sound('t:\it\pascal\r-type\src\music\soundtrack1.mp3');//
var gameovermusic:=new sound(gamedir+'\src\music\gameover2.mp3');
var blast1 := new sound(gamedir+'\src\sounds\blaster.mp3');
var Expl := new sound(gamedir+'\src\sounds\explosive.mp3');//
var Player, Background: GameObjT;
var SpeedVector :SpeedVectorT;

procedure randomost;
begin
  case random(3) of
    0:ost:=new sound(gamedir+'\src\music\soundtrack1.mp3');
    1:ost:=new sound(gamedir+'\src\music\soundtrack2.mp3');
    2:ost:=new sound(gamedir+'\src\music\soundtrack3.mp3');
  end;
end;

function CreateAsteroid(): AsteroidT;
begin
  var r := MaxAsteroidRadius + pabcsystem.Random(MaxAsteroidRadius);
  var Asteroid := new circlewpf(window.Width + random(window.Width), 40 + random(window.Height - 80), r, graycolor(round(255 - r * 2)));
  Asteroid.Dx := -GameSpeed + Asteroid.Radius / 10;
  result := Asteroid;
end;

procedure clearspace;
begin
    Asteroids.ForEach(t -> begin t.Destroy end);
    Asteroids.RemoveAll(t -> true);
end;

procedure init;
begin
  (ku,kd,kl,kr,kf) := (false,false,false,false,false);
  shots.Clear;
  asteroids.Clear;
  explosions.Clear;
  objects.DestroyAll(t -> true);
  Background:= new PictureWPF(0, 0, 'src\images\background9600.jpg');
  gameoverbox:=new RoundRectWPF(window.Width / 2-250, window.Height / 2 - 50, 500, 100, 10, colors.Orange);
  gameoverbox.TextAlignment := alignment.Center;
  gameoverbox.Text := 'GAME OVER';//пишем game over
  gameoverbox.FontSize := 72;
  gameoverbox.Visible:=false;
  newgamebox:=new RoundRectWPF(window.Width / 2-250, window.Height / 2 + 150, 500, 60,10, colors.green);
  newgamebox.TextAlignment := alignment.Center;
  newgamebox.Text := 'Нажми ENTER чтобы начать';
  newgamebox.FontSize := 36;
  newgamebox.Visible:=false;
  player := new PictureWPF(window.Width / 4, window.Height / 2, 'src\images\ship.png');//игрок
  hitbox := new RoundRectWPF(player.center.X, player.center.Y, 40, 20,5,  colors.Black);
  gameover:=false;
  player.Dx:=0;
  player.Dy:=0;
  GameSpeed:=15;
  asteroidslimit:=8;
  DebrisLimit:=5;
  background.Dx := -2;
  score := 0;    //счёт игры
  ShotsLimit := 3;//
  ShotCD := 100;   //
  NextShot := 0;   //
  ShotSpeed := 25; //
  TopShipSpeed := 11.0;
  ShipHP:=1000;
  hitbox.visible := false;
  for var i := 1 to AsteroidsLimit do //добавляем  
    Asteroids.Add(CreateAsteroid);
  scorebox := new RoundRectWPF(10, 10, 150, 30, 5,colors.Beige);//рисуем бокс для счета
  ShipHPBox := new RoundRectWPF(190, 10, 200, 30, 5,colors.Wheat);//рисуем бокс для счета
  
  Background.ToBack;
  infobox:=new RoundRectWPF(10,window.Height-160,200,150,2,ARGB(100,200,200,200));
  infobox.FontColor:=colors.White;
  infobox.FontSize:=11;
  maxasteroidradius:=10;
  cleanspace:=true;
  SpeedVector := new SpeedVectorT(0, 0);
end;

procedure fire;
begin
  if (shots.Count >= shotslimit) or (NextShot > Milliseconds) then exit;
  shots.Add(new PictureWPF(player.left + 48, player.top + 38, 'src\images\shot.png'));
  shots.Last.Dx := shotspeed;
  NextShot := Milliseconds + ShotCD;
  playshoot:=true;
end;

procedure SplitAsteroid(Asteroid: CircleWPF);
begin
  if asteroid.Radius < 6 then exit;
  var rpi := pi + random(-pi / 6, pi / 6);
    for var i := 1 to DebrisLimit do
    begin 
      Asteroids.Add(new CircleWPF(Asteroid.Center.X + Asteroid.Radius * cos(pi / 2 + rpi + 2 * pi / DebrisLimit * i), Asteroid.Center.Y + Asteroid.Radius * sin(pi / 2 - rpi + 2 * pi / DebrisLimit * i), Asteroid.Radius/DebrisLimit*3/2, graycolor(round(255 - Asteroid.Radius))));
      Asteroids.Last.Dx := asteroid.Dx * cos(pi / 2 + pi/8 + 2 * pi / DebrisLimit * i);
      if Asteroid.Dy=0 then
         Asteroids.Last.Dy := asteroid.Dx * sin(pi / 2 + pi/8 + 2 * pi / DebrisLimit * i)
       else 
         Asteroids.Last.Dy := GameSpeed * sin(pi / 2+pi/8 + 2 * pi / DebrisLimit * i);
    end
end;

procedure endgame;//процедура - конец игры
begin
  shiphpbox.Text:='';
  player.Visible := false;
  gameover := true;//устанавливаем флаг в true
  gameoverbox.visible:=true;
  newgamebox.visible:=true;
end;

procedure play;//процедура обработки игровых событий
begin
  if cleanspace then
  begin
    Asteroids.ForEach(t -> begin t.Destroy end);
    Asteroids.RemoveAll(t -> true);
    cleanspace := false;
  end;
  if maxasteroidradius<40 then maxasteroidradius+=0.01;
  for var i := 0 to Asteroids.Count - 1 do
  begin
    if (Asteroids[i].right < 0) or (Asteroids[i].bottom < 0) or (Asteroids[i].top > window.Height) or (asteroids[i].left > window.Width * 2) or (asteroids[i].Radius < 2) then Asteroids[i].Visible := false;
    if (hitbox.Intersects(Asteroids[i])) and (Asteroids[i].Visible) and player.Visible and not cheat then shiphp-=Asteroids[i].Radius;
    if (ShipHP<0) and not gameover then begin explosions.Add(new CircleWPF(player.bounds.X, player.bounds.Y, 400, colors.Red)); endgame; end;
    if (hitbox.Intersects(Asteroids[i])) and Asteroids[i].Visible and player.Visible then begin SplitAsteroid(Asteroids[i]); Asteroids[i].Visible := false; end;
    for var j := 0 to shots.Count - 1 do
    begin
      if shots[j].Intersects(Asteroids[i]) and shots[j].Visible then 
      begin
        explosions.Add(new AsteroidT(Asteroids[i].center.X, Asteroids[i].center.Y, Asteroids[i].Radius * 10, colors.OrangeRed));
        explosions.last.Dx := Asteroids[i].dx / 2;
        Asteroids[i].visible := false;
        shots[j].Visible := false;
        score += round(Asteroids[i].Radius)* (N1L?2:1)*(cheat?0:1);
        SplitAsteroid(Asteroids[i]);
        if Asteroids[i].Radius>20 then playexplosive:=true;
      end;
      if shots[j].OutOfGraphWindow and shots[j].Visible then shots[j].visible := false;
    end;
  end;
  explosions.ForEach(t -> begin if t.radius > 10 then begin t.radius *= 0.9; end else begin t.Visible := false; t.destroy end end);
  explosions.RemoveAll(t -> not t.visible);
  Asteroids.ForEach(t -> begin if t.Visible then t.Move else t.Destroy end);
  Asteroids.RemoveAll(t -> not t.visible);
  foreach var obj in shots do if obj.visible then obj.Move else obj.destroy;
  //shots.ForEach(t -> begin if t.visible then t.Move else t.destroy end);
  shots.RemoveAll(t -> not t.visible);
  if (Asteroids.Count < AsteroidsLimit) and not gameover then Asteroids.Add(CreateAsteroid);

  player.Dy *= k;//коэфициент уменьшения скорости движения по вертикали - энерция управления
  player.Dx *= k;//коэфициент уменьшения скорости движения по горизонту - энерция управления
  if player.right > window.width then (player.right, SpeedVector.X) := (window.width,0);
  if player.bottom > window.Height then (player.Bottom,SpeedVector.Y) := (window.Height,0);
  if player.top < 0 then (player.top,SpeedVector.Y) := (0,0); //ограничения
  if player.left < 0 then (player.left,SpeedVector.X) := (0,0);
  if gameover then exit;
  if background.right <= window.width then background.left := window.width-1920;//условие для зацикливаннея фона
  
  if ku then speedVector.Y -= ShipAcceleration;
  if kd then speedVector.Y += ShipAcceleration;
  if kl then speedVector.X -= ShipAcceleration;
  if kr then speedVector.X += ShipAcceleration;
  
  if SpeedVector.X > TopShipSpeed then SpeedVector.X := TopShipSpeed;
  if SpeedVector.Y > TopShipSpeed then SpeedVector.Y := TopShipSpeed;
  if SpeedVector.X < -TopShipSpeed then SpeedVector.X := -TopShipSpeed;
  if SpeedVector.Y < -TopShipSpeed then SpeedVector.Y := -TopShipSpeed;
  
  (player.Dx, player.Dy) := (SpeedVector.X, SpeedVector.Y);
  
  if not N1L then
  begin
    if not ku and not kd then SpeedVector.Y *= k;
    if not kl and not kr then SpeedVector.X *= k;
  end;
  if kf then fire;
  SpeedVector.Draw.X2 :=  SpeedVector.Draw.X1 + SpeedVector.X * 5;
  SpeedVector.Draw.Y2 :=  SpeedVector.Draw.Y1 + SpeedVector.Y * 5;
  player.Move;
  hitbox.center := player.center;
  background.Move;
  scorebox.Text := 'Счёт: ' + score;
  ShipHPBox.Text := 'Состояние корябля: ' + round(ShipHP);
  GameSpeed += 0.0001;
  infobox.Text:='N - 1й закон Ньютона: ' + (N1L?'вкл':'выкл')+#10#13+'F11 - сбросить размер астеродов: ' + round(MaxAsteroidRadius).ToString+#10#13+'F12 - бессмертие: ' + (cheat?'вкл':'выкл')+#10#13+'PgUP/PgDN - кол-во астероидов: ' + AsteroidsLimit.ToString+#10#13+'Home/End - кол-во осколков: ' + DebrisLimit.ToString+#10#13+'Del - очистка от астероидов';
end;


begin
  window.SetSize(1600, 800);
  window.IsFixedSize := true;
  window.CenterOnScreen;
  window.Caption := 'Asteroid Warrior';
  init;
  randomost;
  playost:=true;
  endgame;
  gameoverbox.Visible:=false;
  infobox.Text:=$'N - 1й закон Ньютона: {N1L?''вкл'':''выкл''}{#10#13}F11 - сбросить размер астеродов: {round(MaxAsteroidRadius).ToString}{#10#13}F12 - бессмертие: {cheat?''вкл'':''выкл''}{#10#13}PgUP/PgDN - кол-во астероидов: {AsteroidsLimit.ToString}{#10#13}Home/End - кол-во осколков: {DebrisLimit.ToString}{#10#13}Del - очистка от астероидов';
//////////////////////Обработчик событий клавиатуры/////////////////////////////
  onkeydown := k -> begin
    if gameover and (k = key.enter) then begin init(); end;
    if gameover then exit;
    case k of
      key.up: ku := true;
      key.down: kd := true;
      key.Left: kl := true;
      key.right: kr := true;
      key.Space: kf := true;
      key.N: N1L := not N1L;
      key.F12: cheat := not cheat;
      key.F11: MaxAsteroidRadius := 10;
      key.PageUp: AsteroidsLimit += 1;
      key.PageDown: AsteroidsLimit -= 1;
      key.Home: DebrisLimit += 1;
      key.End: DebrisLimit -= 1;
      key.Delete: clearspace;
    end;
  end;
  
  onkeyup := k -> begin
    if gameover then exit;
    case k of
      key.up: ku := false;
      key.down: kd := false;
      key.Left: kl := false;
      key.right: kr := false;
      key.Space: kf := false;
    end;
  end;
  
  ondrawframe := dt -> 
  begin
    play;
  end;
  
  while true do
  begin
    if gameover and playost then 
    begin
      ost.stop;
      gameovermusic.play;
      playost := false;
    end;
    
    if not gameover and not playost then
    begin
      randomost;
      ost.play;
      gameovermusic.Stop;
      playost := true
    end;
    
    if playshoot then begin
      blast1.Reset;
      blast1.play;
      playshoot := false
    end;
  
  if playexplosive then
     begin
       playexplosive:=false;
       expl.Reset;
       expl.Play;
     end;
   end;
end.