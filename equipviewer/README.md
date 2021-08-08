# ffxi-addons/equipviewer  
EquipViewer:  
Overlays your currently equipped items onto the screen anywhere. Basically just shows your equipment screen, but smaller, anywhere you want, and you can make it translucent. 
  
Commands:  
equipviewer pos[ition] x y - Moves the equipment overlay to the desired location.  
equipviewer opacity number - sets the opacity of the font object. 0 = transparent, 1 = opaque.  
equipviewer scale number - sets the scale of the icons and background, deftault = 1.0  
equipviewer showammo - toggles it showing ammo count when the ammo amount > 1  
  
To use:  
The addon uses a dependency injection model to allow the core logic and work to be in a shared file that both the Windower and Ashita version uses. This allows any major changes that happen to be done in a single file without having to update a version for both applications.  
Since both the Windower and the Ashita version use the same core files, and the whole point is to not have to update the same file in multiple places, there is a bit of work involved to get all the files in the right place. For both Windower and Ashita, you start by creating a folder in your addons folder called equipviewer. Then, take the files located in the core folder and place them there. Finally, take the equipviewer.lua file located in EITHER the Windower or Ashita folder and place it in your equipviewer folder. You can then unzip the icons.7z folder into your equipviewer folder. From there, you should be able to load the addon.  