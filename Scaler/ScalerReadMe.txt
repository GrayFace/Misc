Scaler for MMF Games
(c) Sergey 'GrayFace' Rozhenko
https://grayface.github.io/

Can be applied to any game made with ClickTeam Multimedia Fusion 2 or its predecessors that doesn't use hardware accelerated graphics. Newer versions of Fusion are probably also supported if they have a non-HWA version.

Options you select are stored in Scaler.ini in the Scaler program folder. You can copy it to game folder to override options selected in the Scaler window. You can further override options by targeting individual executable by creating ExeName.Scaler.ini file. It's a good idea to then edit the override ini file and remove all options which need not be overriden.

Here's a rundown of the options:
'Black Border' paints the area around the game view in black. Useful for games that have a different background color.
'Non-integer Scaling' stretches the game to the max, but doesn't look as clean and produces scaling artifacts in places with animation due to how the effect is achieved.
'Windowed' enables resizing and maximization of the game window and stretches it by largest possible integer factor, but doesn't go full screen.
'Maximized' maximizes the game window when combined with 'Windowed'.
'Only modify controls' is primarily for games that can either stretch on their own or use hardware accelerated graphics.

When configuring controls you may want to keep the old key and also assign a new one. For example, let's say you need Num 5 to act like Down:
1. Press Num 5, then press Down. This will make Num 5 key act as Down, but Down key would stop acting as Down.
2. Press Down, then press Down again. This will make Down key work again.
