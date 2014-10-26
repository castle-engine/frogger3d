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

{$apptype CONSOLE}

{ "Frog3d" standalone game binary. }
program frog3d;
uses CastleWindow, CastleConfig, CastleParameters, CastleLog, CastleUtils,
  CastleSoundEngine, CastleClassUtils,
  Game, GameWindow;

const
  Version = '1.0.0';
  Options: array [0..0] of TOption = (
    (Short: 'v'; Long: 'version'; Argument: oaNone)
  );

procedure OptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
begin
  case OptionNum of
    0: begin
         WritelnStr(Version);
         ProgramBreak;
       end;
    else raise EInternalError.Create('OptionProc');
  end;
end;

begin
  Config.Load;

  SoundEngine.ParseParameters; { after Config.Load, to be able to turn off sound }
  Window.FullScreen := true;
  Window.ParseParameters;
  Parameters.Parse(Options, @OptionProc, nil);

  {$ifdef UNIX}
  { Note: do this after handling options, to handle --version first }
  InitializeLog(Version);
  {$endif}

  Application.Initialize;
  Window.OpenAndRun;
  Config.Save;
end.
