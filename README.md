# Mapsforge-to-Tiles
Graphical user interface to render tiles by Mapsforge tile server directly and optionally compose them to an image without installed map application

### Preliminary
Prebuilt Mapsforge maps are provided amongst others by [mapsforge.org](http://download.mapsforge.org) and [openandromaps.org](https://www.openandromaps.org). 

To render local Mapsforge maps directly without installed map application, a local tile server can be set up to render these Mapsforge maps and to interact with this graphical user interface via TMS protocol. The corresponding tile server is available at this [mapsforgesrv](https://github.com/telemaxx/mapsforgesrv) repository.  


### Graphical user interface
This project’s intension is to easily let the user interactively and comfortably select the numerous available options of tile server. In addition, option settings as well as position and font size of graphical user interface automatically get saved and restored. Tile server gets started/restarted using these options without need to manually set up any configuration files. 

Graphical user interface is a single script written in _Tcl/Tk_ scripting language and is executable on _Microsoft Windows_ and _Linux_ operating system. Language-neutral script file _Mapsforge-to-Tiles.tcl_ requires an additional user settings file and at least one localized resource file. Additional files must follow _Tcl/Tk_ syntax rules too.

User settings file is named _Mapsforge-to-Tiles.ini_. A template file is provided.

Resource files are named _Mapsforge-to-Tiles.<locale\>_, where _<locale\>_ matches locale’s 2 lowercase letters ISO 639-1 code. English localized resource file _Mapsforge-to-Tiles.en_ and German localized resource file _Mapsforge-to-Tiles.de_ are provided. Script can be easily localized to any other system’s locale by providing a corresponding resource file using English resource file as a template. 

Rendered tiles may optionally be composed to an image. Composition requires package _ImageMagick_ with package’s command line utility _convert_ to be installed. 

Screenshot of graphical user interface:
![GUI_Windows](https://user-images.githubusercontent.com/62614244/178749371-c37f6b0f-4665-45aa-a629-dccbc6eea658.png)

### Installation

1.	Java runtime environment version 8 or higher   
Windows: If not yet installed, download and install Java, e.g. from [Oracle](https://www.java.com).  
Linux: If not yet installed, install Java runtime package using Linux package manager. (Ubuntu: _apt install openjdk-<version\>-jre_ where _<version\>_ is 8 or higher)

2.	Mapsforge tile server  
Open [mapsforgesrv](https://github.com/telemaxx/mapsforgesrv) repository.  
For Java version 11 or higher, switch branch to _master_, navigate to folder _mapsforgesrv/bin/jars_ready2use_ and download jar file [_mapsforgesrv-fatjar.jar_](https://github.com/telemaxx/mapsforgesrv/raw/master/mapsforgesrv/bin/jars_ready2use/mapsforgesrv-fatjar.jar).  
For Java version 8 (or higher), switch branch to _Java8_, navigate to folder _mapsforgesrv/bin/jars_ready2use_ and download jar file [_mapsforgesrv4java8.jar_](https://github.com/telemaxx/mapsforgesrv/raw/Java8/mapsforgesrv/bin/jars_ready2use/mapsforgesrv4java8.jar).  
Windows: Copy downloaded jar file into Mapsforge tile server’s installation folder, e.g. into folder _%programfiles%/MapsforgeSrv_.  
Linux: Copy downloaded jar file into Mapsforge tile server’s installation folder, e.g. into folder _~/MapsforgeSrv_.  
Note:  
Currently Mapsforge tile server version 0.17.4 or higher is required. Previous server versions are no longer supported.  

3.	Alternative Marlin rendering engine (optional)  
[Marlin](https://github.com/bourgesl/marlin-renderer) is an open source Java2D rendering engine optimized for performance.  
For Java version 11 or higher, open [mapsforgesrv](https://github.com/telemaxx/mapsforgesrv) repository, switch branch to _master_, navigate to folder _mapsforgesrv/libs_ and download jar file(s) _marlin-*.jar_.  
For Java version 8, open [mapsforgesrv](https://github.com/telemaxx/mapsforgesrv) repository, switch branch to _Java8_, navigate to folder _mapsforgesrv/libs_ and download jar file(s) _marlin-*.jar_.  
Windows: Copy downloaded jar file(s) into Mapsforge tile server’s installation folder, e.g. into folder _%programfiles%/MapsforgeSrv_.  
Linux: Copy downloaded jar file(s) into Mapsforge tile server’s installation folder, e.g. into folder _~/MapsforgeSrv_.  

4.	Tcl/Tk scripting language version 8.6 or higher binaries  
Windows: Download and install latest stable version of Tcl/Tk. See https://wiki.tcl-lang.org/page/Binary+Distributions for available binary distributions. Recommended distribution is [teclab’s tcltk](https://github.com/teclab-at/tcltk/releases) repository. First select most recent installation file _tcltk86-8.6.x.y.tcl86.Win10.x86_64.tgz_, then press _Download_ button. Unpack zipped tar archive (file extension _.tgz_) into your Tcl/Tk installation folder, e.g. _%programfiles%/Tcl_.  
Note 1: [7-Zip](https://www.7-zip.org) file archiver/extractor is able to unpack _.tgz_ archives.   
Note 2: Archives of latest releases for Windows at teclab’s tcltk repository may have file extension _.zip_ while they should have extension _.tgz_. Rename extension to _.tgz_ before unpacking archive.  
Linux: Install packages _tcl, tcllib, tk_ and _tklib_ using Linux package manager. (Ubuntu: _apt install tcl tcllib tk tklib_)

5. ImageMagick  
Windows: If not yet installed, download and install latest ImageMagick version from [download section](https://imagemagick.org/script/download.php). Enable option "Install legacy utilities" during installation.  
After installation, legacy utility _convert.exe_ is expected to be found in one of folders _C:\Program Files*\ImageMagick*_. An alternative installation path for _convert.exe_ can be specified in the ini file.  
Linux: If not yet installed, install ImageMagick package using Linux package manager. (Ubuntu: _apt install imagemagick_)

6. Mapsforge maps  
Download Mapsforge maps for example from [openandromaps.org](https://www.openandromaps.org). Each downloaded OpenAndroMaps map archive contains a map file (file extension _.map_). Tile server will render this map file.  

7. Mapsforge themes  
Mapsforge themes _Elevate_ and _Elements_ (file extension _.xml_) suitable for OpenAndroMaps are available for download at [openandromaps.org](https://www.openandromaps.org).  
Note:  
In order "Hillshading on map" to be applied to rendered map tiles, hillshading has to be enabled in theme file too. _Elevate_ and _Elements_ themes version 5 or higher do enable hillshading.

8. DEM data (optional, required for hillshading)  
Download and store HGT files with DEM (Digital Elevation Model) data for the regions to be rendered. HGT files with 3 arc seconds resolution are available for example at [viewfinderpanoramas.org](http://www.viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm).

9. Mapsforge-to-Tiles graphical user interface  
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
 
![Heidelberg](https://user-images.githubusercontent.com/62614244/164913502-0a7bcb4b-318a-4789-93fa-f27ca754cad3.jpg)                                                  

### Hints

* Built-in world map  
Since the built-in [Mapsforge world map](https://download.mapsforge.org/maps/world/world.map) only shows the coastline, it only serves as a rough overview. Due to map's low resolution, coastlines show inaccurate at high resolution. Because the Mapsforge renderer prefers land on the world map to sea on the selected detailed local map, it may be advisable to disable the built-in world map when rendering coastal regions at high resolution.
* Area not covered by selected maps consists of "no content" tiles. However whole world is covered, when built-in Mapsforge world map is appended to selected maps.
* Hillshading
  * When selecting "Hillshading on map", map and hillshading are rendered  into one single map. Flat area gets a medium shade of gray, while slopes get a darker or a brighter shade of gray depending on the angle of incidence of light. Thus map has a shade of gray everywhere.  
  * When selecting "Hillshading as map", map and hillshading are rendered as two separate maps. Post-processing hillshading, gray value of flat area gets mapped to full transparency, darker gray values get mapped to transparency levels of black, brighter gray values get mapped to transparency levels of white. Thus the flatter the area, the more the original colors of the map shine through. Finally, hillshading as alpha-transparent overlay gets composed with map.  
[OpenTopoMap](https://opentopomap.org) uses this same hillshading technique.  
* Tiles range in x and y directions may be given as tile numbers or as coordinate values. Entered coordinate values are converted into tile numbers according to zoom level set, entered tile numbers are converted into coordinate values according to zoom level set. When changing the zoom level, the input values are retained, the converted values however are recalculated. For correlation between zoom level and corresponding tiles range and for conversion formulas used, see https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames.  



                      













