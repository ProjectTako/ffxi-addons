# ffxi-addons/scanzone  
ScanZone:  
Scan Zone is an addon that will let you scan your current zone for any NPC, including mobs. This will make the server send your client an entity update packet, which it then reads for certain data and displays in the chat log, such as name, id, and position. 

Note:  
Windower users MUST edit scanzone.lua to point to their FFXI install directory (line 32).  
Ashita users do not need to do this step.
  
Commands:  
scanzone scan 0x00 - scans the zone for the entity with the hex id 0x00.  
scanzone find name - reads the dat files for the current zone to locate the target index used for scanning