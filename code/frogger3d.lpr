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

{$apptype GUI}

{ "Frogger 3D" standalone game binary. }
program frogger3d;

{$ifdef MSWINDOWS} {$R automatic-windows-resources.res} {$endif MSWINDOWS}

uses CastleWindow, CastleConfig, CastleParameters, CastleLog, CastleUtils,
  CastleSoundEngine, CastleClassUtils,
  Game;

const
  Version = '1.1.0';
  Options: array [0..0] of TOption = (
    (Short: 'v'; Long: 'version'; Argument: oaNone)
  );

procedure OptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
begin
  case OptionNum of
    0: begin
         WritelnStr(Version);
         Halt;
       end;
    else raise EInternalError.Create('OptionProc');
  end;
end;

begin
  UserConfig.Load;

  Window.StencilBits := 8; // needed by shadow volumes

  SoundEngine.ParseParameters; { after Config.Load, to be able to turn off sound }
  Window.FullScreen := true;
  Window.ParseParameters;
  Parameters.Parse(Options, @OptionProc, nil);

  { Note: do this after handling options, to handle --version first }
  InitializeLog;

  Window.OpenAndRun;
  UserConfig.Save;
end.
