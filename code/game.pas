{
  Copyright 2014-2014 Michalis Kamburelis.

  This file is part of "Frog3d".

  "Frog3d" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Frog3d" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Implements the game logic, independent from Android / standalone. }
unit Game;

interface

uses CastleWindowTouch, CastlePlayer, CastleLevels, CastleCreatures,
  GameWindow;

implementation

uses SysUtils, CastleLog, CastleWindow, CastleProgress, CastleWindowProgress,
  CastleControls, CastlePrecalculatedAnimation, CastleGLImages, CastleConfig,
  CastleImages, CastleFilesUtils, CastleKeysMouse, CastleUtils, CastleScene,
  CastleMaterialProperties, CastleResources, CastleGameNotifications, CastleNotifications,
  CastleSceneCore, Castle3D, CastleVectors, CastleMessages;

const
  CX = 12;
  CY = 50;
  Speeds: array [0..CX-1] of Single = (1, 0.5, 1.2, 0.75, 1, 0.5, 1.2, 0.75, 2, 0.55, 2.2, 1.75);
  SpeedsScale = 2.0;
  XSpread = 1;
  YSpread = 4;

var
  Cyls: array [0..CX-1, 0..CY-1] of T3DTransform;
  Player: T3DTransform;

{ One-time initialization. }
procedure ApplicationInitialize;
begin
  Progress.UserInterface := WindowProgressInterface;

  Levels.AddFromFile(ApplicationData('level.xml'));
end;

procedure WindowOpen(Container: TUIContainer);
var
  Scene: TCastleScene;
  X, Y: Integer;
begin
  Window.SceneManager.LoadLevel('1');

  for X := 0 to CX - 1 do
    for Y := 0 to CY - 1 do
    begin
      Scene := TCastleScene.Create(Window.SceneManager);
      Scene.Load(ApplicationData('cyl.x3d'), true);
      Cyls[X, Y] := T3DTransform.Create(Window.SceneManager);
      Cyls[X, Y].Add(Scene);
      Cyls[X, Y].Translation := Vector3Single(X * XSpread, 0, Y * YSpread - 50);
      Window.SceneManager.Items.Add(Cyls[X, Y]);
    end;

  Scene := TCastleScene.Create(Window.SceneManager);
  Scene.Load(ApplicationData('p.x3d'), true);
  Player := T3DTransform.Create(Window.SceneManager);
  Player.Add(Scene);
  Player.Translation := Vector3Single(-1, 0.5, 0);
//  Player.Scale := Vector3Single(0.2, 0.2, 0.2);
  Window.SceneManager.Items.Add(Player);
end;

procedure WindowResize(Container: TUIContainer);
begin
end;

procedure WindowUpdate(Container: TUIContainer);
var
  X, Y: Integer;
  T: TVector3Single;
  PX, CC, PY: Single;
  Some: boolean;
begin
  for X := 0 to CX - 1 do
    for Y := 0 to CY - 1 do
    begin
      T := Cyls[X, Y].Translation;
      T[2] += SpeedsScale * Speeds[X] * Window.Fps.UpdateSecondsPassed;
      Cyls[X, Y].Translation := T;
    end;

  PX := Player.Translation[0];
  PY := Player.Translation[2];
  for X := 0 to CX - 1 do
  begin
    CC := Cyls[X, 0].Translation[0];
    if Abs(PX - CC) < 0.1 then
    begin
      Some := false;
      for Y := 0 to CY - 1 do
      begin
        if (PY >= Cyls[X, Y].Translation[2] - 1) and (PY <= Cyls[X, Y].Translation[2] + 1) then
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
  
  // if PY > Cyls[CX - 1, 0].Translation[2] + 0.1 then
  //     begin
  //       MessageOk(Window, 'game win');
  //       Application.Quit;
  //     end;
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
var
  T: TVector3Single;
begin
  if Event.IsKey(K_F5) then
    Window.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png'));
  if Event.IsKey(K_Escape) then
    Application.Quit;
  if Event.IsKey(K_A) then
  begin
    T := Player.Translation;
    T[2] -= 0.2;
    Player.Translation := T;
  end;
  if Event.IsKey(K_D) then
  begin
    T := Player.Translation;
    T[2] += 0.2;
    Player.Translation := T;
  end;
  if Event.IsKey(K_W) then
  begin
    T := Player.Translation;
    T[0] += XSpread / 2;
    Player.Translation := T;
  end;
end;

function MyGetApplicationName: string;
begin
  Result := 'frog3d';
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
//  Window.AntiAliasing := aa4SamplesNicer; // much slower
  Application.MainWindow := Window;
end.
