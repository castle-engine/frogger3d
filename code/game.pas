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

uses SysUtils, CastleLog, CastleWindow, CastleProgress, CastleWindowProgress,
  CastleControls, CastlePrecalculatedAnimation, CastleGLImages, CastleConfig,
  CastleImages, CastleFilesUtils, CastleKeysMouse, CastleUtils, CastleScene,
  CastleMaterialProperties, CastleResources, CastleGameNotifications, CastleNotifications,
  CastleSceneCore, Castle3D, CastleVectors, CastleMessages;

const
  CX = 12;
  CZ = 50;
  Speeds: array [0..CX-1] of Single = (1, -0.5, 1.2, -0.75, 1, -0.5, 1.2, -0.75, 2, -0.55, 2.2, -1.75);
  SpeedsScale = 2.0;
  XSpread = 1;
  ZSpread = 4;

var
  Cyls: array [0..CX-1, 0..CZ-1] of T3DTransform;
  Player: T3DTransform;

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  Progress.UserInterface := WindowProgressInterface;

  Levels.AddFromFile(ApplicationData('level.xml'));
end;

procedure WindowOpen(Container: TUIContainer);
var
  CylinderScene, PlayerScene: TCastleScene;
  X, Z: Integer;
begin
  Window.SceneManager.LoadLevel('1');

  CylinderScene := TCastleScene.Create(Window.SceneManager);
  CylinderScene.Load(ApplicationData('cyl.x3d'), true);

  for X := 0 to CX - 1 do
    for Z := 0 to CZ - 1 do
    begin
      Cyls[X, Z] := T3DTransform.Create(Window.SceneManager);
      Cyls[X, Z].Add(CylinderScene);
      Cyls[X, Z].Translation := Vector3Single(X * XSpread, 0, Z * ZSpread - 50);
      Window.SceneManager.Items.Add(Cyls[X, Z]);
    end;

  PlayerScene := TCastleScene.Create(Window.SceneManager);
  PlayerScene.Load(ApplicationData('p.x3d'), true);
  Player := T3DTransform.Create(Window.SceneManager);
  Player.Add(PlayerScene);
  Player.Translation := Vector3Single(-1, 0.5, 0);
  Window.SceneManager.Items.Add(Player);
end;

procedure WindowResize(Container: TUIContainer);
begin
end;

procedure WindowUpdate(Container: TUIContainer);
var
  X, Z: Integer;
  T: TVector3Single;
  PlayerX, CylinderX, PlayerZ: Single;
  Some: boolean;
begin
  for X := 0 to CX - 1 do
    for Z := 0 to CZ - 1 do
    begin
      T := Cyls[X, Z].Translation;
      T[2] += SpeedsScale * Speeds[X] * Window.Fps.UpdateSecondsPassed;
      Cyls[X, Z].Translation := T;
    end;

  PlayerX := Player.Translation[0];
  PlayerZ := Player.Translation[2];
  for X := 0 to CX - 1 do
  begin
    CylinderX := Cyls[X, 0].Translation[0];
    if FloatsEqual(PlayerX, CylinderX, 0.1) then
    begin
      Some := false;
      for Z := 0 to CZ - 1 do
      begin
        if (PlayerZ >= Cyls[X, Z].Translation[2] - 1) and
           (PlayerZ <= Cyls[X, Z].Translation[2] + 1) then
        begin
          Some := true;

          T := Player.Translation;
          T[2] += SpeedsScale * Speeds[X] * Window.Fps.UpdateSecondsPassed;
          Player.Translation := T;
        end;
      end;
      if not Some then
      begin
        MessageOk(Window, 'Dead, game over');
        Application.Quit;
      end;
    end;
  end;

  if PlayerX > Cyls[CX - 1, 0].Translation[0] + 0.1 then
  begin
    MessageOk(Window, 'Game win');
    Application.Quit;
  end;
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);

  procedure PlayerShift(const X, Z: Single);
  begin
    Player.Translation := Player.Translation + Vector3Single(X, 0, Z);
  end;

begin
  if Event.IsKey(K_F5) then
    Window.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png'));
  if Event.IsKey(K_Escape) then
    Application.Quit;
  if Event.IsKey(K_A) then
    PlayerShift(0, -0.2);
  if Event.IsKey(K_D) then
    PlayerShift(0,  0.2);
  if Event.IsKey(K_W) then
    PlayerShift( XSpread / 2, 0);
  if Event.IsKey(K_S) then
    PlayerShift(-XSpread / 2, 0);
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
  Window.OnOpen := @WindowOpen;
  Window.OnPress := @WindowPress;
  Window.OnUpdate := @WindowUpdate;
  Window.OnResize := @WindowResize;
  Window.FpsShowOnCaption := true;
  Application.MainWindow := Window;
end.
