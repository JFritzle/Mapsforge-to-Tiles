# Mapsforge-to-Tiles
Graphical user interface to render tiles by Mapsforge tile server directly and optionally compose them to an image without installed map application

### About
Prebuilt Mapsforge maps are provided amongst others by [mapsforge.org](http://download.mapsforge.org) and [openandromaps.org](https://www.openandromaps.org). 

To render local Mapsforge maps directly without installed map application, a local tile server can be set up to render these Mapsforge maps and to interact with this graphical user interface via TMS protocol. The corresponding tile server is available at this [mapsforgesrv](https://github.com/telemaxx/mapsforgesrv) repository.  

While old *single task* server type was capable of rendering only one single set of parameters at a time, the new *multiple tasks* server type is capable of rendering multiple sets of parameters concurrently. Thus, one single *multiple tasks* server instance can replace multiple *single task* server instances.  
**This Graphical user interface only supports the *multiple tasks* server type.**  
Latest GUI supporting *single task* server type is still available in GitHub's [*legacy*](https://github.com/JFritzle/Mapsforge-to-Tiles/tree/legacy) branch.

### Graphical user interface
This project’s intension is to easily let the user interactively and comfortably select the numerous available options of tile server. In addition, option settings as well as position and font size of graphical user interface automatically get saved and restored. Tile server gets started/restarted using these options without need to manually set up any configuration files. 

Graphical user interface is a single script written in _Tcl/Tk_ scripting language and is executable on _Microsoft Windows_ and _Linux_ operating system. Language-neutral script file _Mapsforge-to-Tiles.tcl_ requires an additional user settings file and at least one localized resource file. Additional files must follow _Tcl/Tk_ syntax rules too.

User settings file is named _Mapsforge-to-Tiles.ini_. A template file is provided.

Resource files are named _Mapsforge-to-Tiles.<locale\>_, where _<locale\>_ matches locale’s 2 lowercase letters ISO 639-1 code. English localized resource file _Mapsforge-to-Tiles.en_ and German localized resource file _Mapsforge-to-Tiles.de_ are provided. Script can be easily localized to any other system’s locale by providing a corresponding resource file using English resource file as a template. 

Rendered tiles may optionally be composed to an image.

Screenshot of graphical user interface:
![GUI_Windows](https://github.com/user-attachments/assets/efffa6a3-93ec-47eb-bbd2-c7fffa3e251d)


### Installation

1.	Java runtime environment (JRE) or Java development kit (JDK)  
JRE version 11 or higher is required. Each JDK contains JRE as subset.  
Windows: If not yet installed, download and install JRE or JDK, e.g. from [Oracle](https://www.java.com) or [Adoptium](https://adoptium.net/de/temurin/releases).  
Linux: If not yet installed, install JRE or JDK using Linux package manager. (Ubuntu: _apt install openjdk-<version\>-jre_ or _apt install openjdk-<version\>-jdk_ with required or newer _<version\>_)

2.	Mapsforge tile server  
Open [mapsforgesrv releases](https://github.com/telemaxx/mapsforgesrv/releases).  
Download most recently released jar file _mapsforgesrv-fatjar.jar_ from _<release\>\_for\_java11_tasks_ assets.  
Windows: Copy downloaded jar file into Mapsforge tile server’s installation folder, e.g. into folder _%programfiles%/MapsforgeSrv_.  
Linux: Copy downloaded jar file into Mapsforge tile server’s installation folder, e.g. into folder _~/MapsforgeSrv_.  
Note:  
New *multiple tasks* server type and server version 0.21.0.0 or higher is required.  
Old *single task* server type and previous server versions are no longer supported.  

3. Alternative Marlin rendering engine (optional, recommended)  
[Marlin](https://github.com/bourgesl/marlin-renderer) is an open source Java2D rendering engine optimized for performance, replacing the standard built into Java. Download is available at [Marlin-renderer releases](https://github.com/bourgesl/marlin-renderer/releases).  
For JRE version lower than 17, download jar file _marlin-\*.jar_  
from _Marlin-renderer \<latest version> for JDK11+_ section's assets.  
For JRE version 17 or higher, download jar file _marlin-\*.jar_  
from _Marlin-renderer \<latest version> for JDK17+_ section's assets.  
Windows: Copy downloaded jar file into Mapsforge tile server’s installation folder, e.g. into folder _%programfiles%/MapsforgeSrv_.  
Linux: Copy downloaded jar file into Mapsforge tile server’s installation folder, e.g. into folder _~/MapsforgeSrv_.  

4.	Tcl/Tk scripting language version 8.6 or higher binaries  
Windows: Download and install latest stable version of Tcl/Tk, currently 9.0.  
See https://wiki.tcl-lang.org/page/Binary+Distributions for available binary distributions. Recommended Windows binary distribution is from [teclab’s tcltk](https://gitlab.com/teclabat/tcltk/-/packages) Windows repository. Select most recent installation file _tcltk90-9.0.\<x.y>.Win10.nightly.\<date>.tgz_. Unpack zipped tar archive (file extension _.tgz_) into your Tcl/Tk installation folder, e.g. _%programfiles%/Tcl_.  
Note: [7-Zip](https://www.7-zip.org) file archiver/extractor is able to unpack _.tgz_ archives.   
Linux: Install packages _tcl, tcllib, tcl-thread, tk_ and _tklib_ using Linux package manager.  
(Ubuntu: _apt install tcl tcllib tcl-thread tk tklib_)

5. GraphicsMagick and/or ImageMagick  
At least one installation of either GraphicsMagick or ImageMagick is required!  
Usually GraphicsMagick is faster than ImageMagick, especially with a large number of tiles.  
For performance reasons, Q8 variants of both graphics tools are strongly preferable over Q16 variants. Since Q16 variants internally work with 16-bit color values per pixel, each input file with 8-bit color values per pixel must be internally converted to 16-bit color values before processing, which consumes time, twice as much memory and disk space.  
<br/>GraphicsMagick:  
Windows: If not yet installed, download and install latest GraphicsMagick version from [download section](https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick-binaries).  
After installation, program _gm.exe_ is expected to be found in one of folders _C:\Program Files*\GraphicsMagick*_. An alternative installation path for _gm.exe_ can be specified in the ini file.  
Linux: If not yet installed, install GraphicsMagick package using Linux package manager. (Ubuntu: _apt install graphicsmagick_)  
Note: GraphicsMagick resource limits are hard-coded in Tcl script file, but can be adjusted in section _Set resource limits of GraphicsMagick_ if needed.  
<br/>ImageMagick:  
ImageMagick version 7 or newer is required! Versions older than version 7 do not include program _magick_ required for scripting.  
Windows: If not yet installed, download and install latest ImageMagick version from [download section](https://imagemagick.org/script/download.php).  
After installation, program _magick.exe_ is expected to be found in one of folders _C:\Program Files*\ImageMagick*_. An alternative installation path for _magick.exe_ can be specified in the ini file.  
Linux: If not yet installed, install ImageMagick package using Linux package manager. (Ubuntu: _apt install imagemagick_)  
When Linux package managers do only install versions older than version 7 by default, then [installation from source](https://imagemagick.org/script/install-source.php) may be required. Default is to build Q16 variant. Use _./configure \-\-with-quantum-depth=8_ to build Q8 variant.  
Note: ImageMagick resource limits are hard-coded in Tcl script file, but can be adjusted in section _Set resource limits of ImageMagick_ if needed.  

6. curl  
If not yet available, installation of curl is required!  
Windows: Starting with version 10, a suitable _curl_ is part of Windows and is to be found as _C:\Windows\System32\curl.exe_. If however desired, latest curl version is available at curl's [download section](https://curl.se/download.html). An alternative installation path for _curl.exe_ can be specified in the ini file.  
Linux: If not yet installed, install curl package using Linux package manager. (Ubuntu: _apt install curl_)  

7. Mapsforge maps  
Download Mapsforge maps for example from [openandromaps.org](https://www.openandromaps.org). Each downloaded OpenAndroMaps map archive contains a map file (file extension _.map_). Tile server will render this map file.  

8. Mapsforge themes  
Mapsforge themes _Elevate_ and _Elements_ (file extension _.xml_) suitable for OpenAndroMaps are available for download at [openandromaps.org](https://www.openandromaps.org).  
Note:  
In order "Hillshading on map" to be applied to rendered map tiles, hillshading has to be enabled in theme file too. _Elevate_ and _Elements_ themes version 5 or higher do enable hillshading.

9. DEM data (optional, required for hillshading)  
Download and store DEM (Digital Elevation Model) data for the regions to be rendered.
Notes:  
Either HGT files or ZIP archives containing 1 single equally named HGT file may be supplied.  
Example: ZIP archive N49E008.zip containing 1 single HGT file N49E008.hgt.  
While 1\" (arc second) resolution DEM data have a significantly higher accuracy than 3\" resolution, hillshading assumes significantly much more time. Therefore 3\" resolution usually is better choice.  
    
   \- HGT files with 3\" resolution SRTM (Shuttle Radar Topography Mission) data are available for whole world at [viewfinderpanoramas.org](http://www.viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm). Unzip downloaded ZIP files to DEM folder.  
\- HGT files with 1\" resolution DEM data are available for selected regions at [viewfinderpanoramas.org](http://www.viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org1.htm). Unzip downloaded ZIP files to DEM folder.  
\- ZIP archives with 3\" and 1\" resolution compiled and resampled by Sonny are available for selected regions at [Sonny's Digital LiDAR Terrain Models of European Countries](https://sonny.4lima.de). LiDAR data where available are more precise than SRTM data. Store downloaded ZIP files to DEM folder.

10. Mapsforge-to-Tiles graphical user interface  
Download language-neutral script file _Mapsforge-to-Tiles.tcl_, user settings file _Mapsforge-to-Tiles.ini_  and at least one localized resource file.  
Windows: Copy downloaded files into Mapsforge tile server’s installation folder, e.g. into folder _%programfiles%/MapsforgeSrv_.  
Linux: Copy downloaded files into Mapsforge tile server’s installation folder, e.g. into folder _~/MapsforgeSrv_.  
Edit _user-defined script variables settings section_ of user settings file _Mapsforge-to-Tiles.ini_ to match files and folders of your local installation of Java and Mapsforge tile server.  
Important:  
Always use slash character “/” as directory separator in script, for Microsoft Windows too!

### Script file execution

Windows:  
Associate file extension _.tcl_ to Tcl/Tk window shell’s binary _wish.exe_. Right-click script file and open file’s properties window. Change data type _.tcl_ to get opened by _Wish application_ e.g. by executable _%programfiles%/Tcl/bin/wish.exe_. Once file extension has been associated, double-click script file to run.

Linux:  
Either run script file from command line by
```
wish <path-to-script>/Mapsforge-to-Tiles.tcl
```
or create a desktop starter file _Mapsforge-to-Tiles.desktop_
```
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=Mapsforge-to-Tiles
Exec=wish <path-to-script>/Mapsforge-to-Tiles.tcl
```
or associate file extension _.tcl_ to Tcl/Tk window shell’s binary _/usr/bin/wish_ and run script file by double-click file in file manager.

                     
### Usage

* After selecting map(s), theme file, theme style, style’s overlays etc. in graphical user interface, hit _Start_ button to start tile server, render tiles and stop tile server when done. To restart after changing any settings, hit _Start_ button again.
* Use keyboard keys Ctrl-plus to increase and keyboard keys Ctrl-minus to decrease font size of graphical user interface and/or output console.
* See output console for tile server’s output, render statistics, process steps carried out, etc. 

### Example

Screenshot showing Heidelberg (Germany) and using
* OpenAndroMaps map file _Germany_oam.osm.map_
* OpenAndroMaps rendering theme _Elevate_
* Theme file’s style _elv-hiking_ aka _Hiking_ 
* Style’s default overlays plus additional overlay _elv-waymarks_ aka _Waymarks_ 
* Tile numbers and zoom level as shown above

Upper left half of image was rendered with hillshading settings as  above but "Hillshading on map" selected, lower right half of image was rendered with hillshading settings as above with "Hillshading as map" selected.   
 
![Heidelberg](https://github.com/user-attachments/assets/21703c9b-9300-4feb-8dfc-a530c38592c3)                                                  

### Hints

* Output console  
While console output of tile server can be informative and helpful to verify what is happening as well as to analyze errors, writing to console costs some performance. Therefore the console should be hidden if not needed. 
* Built-in world map  
Since the built-in [Mapsforge world map](https://download.mapsforge.org/maps/world/world.map) only shows the coastline, it only serves as a rough overview. Due to map's low resolution, coastlines show inaccurate at high resolution.  
In order not to cover an accurate map, the built-in world map has been automatically deactivated at higher zoom levels since tile server version 0.21.0.3.    
Starting with server version 0.23.0.3, built-in world map is rendered with lower priority than user-defined accurate maps. Zoom level restriction was therefore removed. 
* Area not covered by selected maps consists of "no content" tiles. However whole world is covered, when built-in Mapsforge world map is appended to selected maps.
* Hillshading
  * When selecting "Hillshading on map", map and hillshading are rendered  into one single map.  
  * When selecting "Hillshading as map", map and hillshading are rendered as two separate maps. Post-processing hillshading, gray value of flat area gets mapped to full transparency. Thus the flatter the area, the more the original colors of the map shine through. Finally, hillshading as alpha-transparent overlay gets composed with map.  
[OpenTopoMap](https://opentopomap.org) uses same hillshading technique as hillshading algorithm "diffuselight".  
* Tiles range in x and y directions may be given as tile numbers or as coordinate values. Entered coordinate values are converted into tile numbers according to zoom level set, entered tile numbers are converted into coordinate values according to zoom level set. When changing the zoom level, the input values are retained, the converted values however are recalculated. For correlation between zoom level and corresponding tiles range and for conversion formulas used, see https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames.  