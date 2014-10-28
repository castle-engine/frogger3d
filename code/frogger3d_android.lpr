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

{ Library to run the game on Android. }
library frogger3d_android;
uses CastleAndroidNativeAppGlue, Game;
exports ANativeActivity_onCreate;
end.
