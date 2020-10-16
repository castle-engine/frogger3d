{
  Copyright 2014-2014 Michalis Kamburelis.

  This file is part of "Frogger 3D".

  "Frogger 3D" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Frogger 3D" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Implements the game logic, independent from Android / standalone. }
unit Game;

interface

uses CastleWindowTouch, CastlePlayer, CastleLevels, CastleCreatures;

var
  Window: TCastleWindowTouch;

implementation

uses SysUtils, Math,
  CastleLog, CastleWindow, CastleProgress, CastleWindowProgress,
  CastleControls, CastleFilesUtils, CastleKeysMouse, CastleScene,
  CastleUIControls, CastleTransform, CastleVectors, CastleMessages, CastleColors;

const
  CX = 12;
  CZ = 50;
  Speeds: array [0..CX-1] of Single = (1, -0.5, 1.2, -0.75, 1, -0.5, 1.2, -0.75, 2, -0.55, 2.2, -1.75);
  SpeedsScale = 2.0;
  XSpread = 1;
  ZSpread = 4;

var
  SceneManager: TGameSceneManager; //< same as Window.SceneManager, just comfortable shortcut
  CylinderScene, PlayerScene: TCastleScene;
  Cylinders: array [0..CX-1, 0..CZ-1] of TCastleTransform;
  Player: TCastleTransform;

  HelpLabel: TCastleLabel;
  CylinderZMin, CylinderZMax: Single;
  FpsPlayer: TPlayer; // representation of FPS camera

procedure GameStart;

  { Be sure to clean resources from previous game, to not clog memory. }
  procedure GameEnd;
  var
    X, Z: Integer;
  begin
    FreeAndNil(FpsPlayer);
    for X := 0 to CX - 1 do
      for Z := 0 to CZ - 1 do
        FreeAndNil(Cylinders[X, Z]);
    FreeAndNil(Player);
    FreeAndNil(PlayerScene);
    FreeAndNil(CylinderScene);
  end;

var
  X, Z: Integer;
begin
  GameEnd;

  FpsPlayer := TPlayer.Create(SceneManager);
  SceneManager.Items.Add(FpsPlayer);
  SceneManager.Player := FpsPlayer;
  FpsPlayer.Blocked := true; // do not allow to move player in this game

  SceneManager.LoadLevel('1');

  CylinderScene := TCastleScene.Create(SceneManager);
  CylinderScene.Load('castle-data:/cylinder.x3d');

  for X := 0 to CX - 1 do
    for Z := 0 to CZ - 1 do
    begin
      Cylinders[X, Z] := TCastleTransform.Create(SceneManager);
      Cylinders[X, Z].Add(CylinderScene);
      Cylinders[X, Z].Translation := Vector3(
        X * XSpread - CX * XSpread / 2, 0, Z * ZSpread - 50);
      SceneManager.Items.Add(Cylinders[X, Z]);
    end;

  { initial cylinder min/max define the span where cylinders can be in z }
  CylinderZMin := Cylinders[0,      0].Translation[2];
  CylinderZMax := Cylinders[0, CZ - 1].Translation[2];

  PlayerScene := TCastleScene.Create(SceneManager);
  PlayerScene.Load('castle-data:/player.x3d');
  Player := TCastleTransform.Create(SceneManager);
  Player.Add(PlayerScene);
  Player.Translation := Vector3(- CX * XSpread / 2 - 1, 0.5, 0);
  Player.Rotation := Vector4(0, 1, 0, -Pi / 2);
  SceneManager.Items.Add(Player);
end;

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  SceneManager := Window.SceneManager;

  Progress.UserInterface := WindowProgressInterface;
  Levels.AddFromFile('castle-data:/level.xml');

  HelpLabel := TCastleLabel.Create(Window);
  HelpLabel.Text.Text := 'Move using AWSD keys or clicking/touching at window edges.';
  HelpLabel.Frame := false;
  HelpLabel.Color := Red;
  HelpLabel.Anchor(vpTop);
  HelpLabel.Anchor(hpMiddle);
  Window.Controls.InsertFront(HelpLabel);

  GameStart;
end;

procedure WindowUpdate(Container: TUIContainer);
var
  X, Z: Integer;
  T: TVector3;
  PlayerX, CylinderX, PlayerZ: Single;
  Some: boolean;
begin
  for X := 0 to CX - 1 do
    for Z := 0 to CZ - 1 do
    begin
      T := Cylinders[X, Z].Translation;
      T.Data[2] += SpeedsScale * Speeds[X] * Window.Fps.SecondsPassed;
      { force the cylinder to fit in CylinderZMin/Max zone.
        This makes seemingly infinite cylinders }
      while T.Data[2] > CylinderZMax do
        T.Data[2] -= (CylinderZMax - CylinderZMin);
      while T.Data[2] < CylinderZMin do
        T.Data[2] += (CylinderZMax - CylinderZMin);
      Cylinders[X, Z].Translation := T;
    end;

  PlayerX := Player.Translation[0];
  PlayerZ := Player.Translation[2];
  for X := 0 to CX - 1 do
  begin
    CylinderX := Cylinders[X, 0].Translation[0];
    if SameValue(PlayerX, CylinderX, 0.1) then
    begin
      Some := false;
      for Z := 0 to CZ - 1 do
      begin
        if (PlayerZ >= Cylinders[X, Z].Translation[2] - 1) and
           (PlayerZ <= Cylinders[X, Z].Translation[2] + 1) then
        begin
          Some := true;

          T := Player.Translation;
          T.Data[2] += SpeedsScale * Speeds[X] * Window.Fps.SecondsPassed;
          Player.Translation := T;
        end;
      end;
      if not Some then
      begin
        MessageOk(Window, 'You are dead, game over.');
        GameStart;
      end;
    end;
  end;

  if PlayerX > Cylinders[CX - 1, 0].Translation[0] + 0.1 then
  begin
    MessageOk(Window, 'Congratulations, you win!');
    GameStart;
  end;
end;

procedure PlayerShift(const X, Z: Single);
begin
  Player.Translation := Player.Translation + Vector3(X * XSpread / 2, 0, Z * 0.2);
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
const
  BorderArea = 0.25;
var
  BorderLeft, BorderRight, BorderTop, BorderBottom: boolean;
begin
  if Event.IsKey(keyF5) then
    Window.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png'));
  if Event.IsKey(keyEscape) then
    Application.Terminate;
  if Event.IsKey(keyW) then
    PlayerShift(0, -1);
  if Event.IsKey(keyS) then
    PlayerShift(0,  1);
  if Event.IsKey(keyD) then
    PlayerShift( 1, 0);
  if Event.IsKey(keyA) then
    PlayerShift(-1, 0);

  if Event.IsMouseButton(mbLeft) then
  begin
    BorderLeft   := Event.Position[0] < BorderArea * Container.Width;
    BorderRight  := Event.Position[0] > Container.Width - BorderArea * Container.Width;
    BorderBottom := Event.Position[1] < BorderArea * Container.Height;
    BorderTop    := Event.Position[1] > Container.Height - BorderArea * Container.Height;
    if BorderTop    and (not BorderLeft) and (not BorderRight) then
      PlayerShift(0, -1);
    if BorderBottom and (not BorderLeft) and (not BorderRight) then
      PlayerShift(0,  1);
    if BorderRight  and (not BorderBottom) and (not BorderTop) then
      PlayerShift( 1, 0);
    if BorderLeft   and (not BorderBottom) and (not BorderTop) then
      PlayerShift(-1, 0);
  end;
end;

function MyGetApplicationName: string;
begin
  Result := 'frogger3d';
end;

initialization
  { This should be done as early as possible to mark our log lines correctly. }
  OnGetApplicationName := @MyGetApplicationName;

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window and initialize Window callbacks }
  Window := TCastleWindowTouch.Create(Application);
  Window.OnPress := @WindowPress;
  Window.OnUpdate := @WindowUpdate;
  Window.FpsShowOnCaption := true;
  Application.MainWindow := Window;
end.
