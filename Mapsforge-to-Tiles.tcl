# Render Mapsforge maps to tiles
# ==============================

# Notes:
# - Additional user settings file is mandatory!
#   Name of file = this script's full path
#   where file extension "tcl" is replaced by "ini"
# - At least one additional localized resource file is mandatory!
#   Name of file = this script's full path
#   where file extension "tcl" is replaced by
#   2 lowercase letters ISO 639-1 code, e.g. "en"

# Potentially switch from "tclsh" to "wish" shell

set shell [info nameofexecutable]
if {[string first tclsh $shell] != -1} {
  regsub -- {tclsh} $shell {wish} shell
  regsub -all -- {\\} $argv0 {/} argv0
  if {[catch "exec {$shell} {$argv0} $argv &" result]} {puts "Error: $result"}
  exit 0
}

set script [file normalize [info script]]
set cwd [pwd]
encoding system utf-8

wm withdraw .

# Required packages and procedure aliases

package require msgcat
package require tooltip
package require http

interp alias {} ::mc {} ::msgcat::mc
interp alias {} ::messagebox {} ::tk::MessageBox
interp alias {} ::combobox {} ::ttk::combobox
interp alias {} ::tooltip {} ::tooltip::tooltip

# Try using system locale for script
# If corresponding localized file does not exist, try locale "en" (English)
# Localized filename = script's filename where file extension "tcl"
# is replaced by 2 lowercase letters ISO 639-1 code

set locale [regsub {(.*)[-_]+(.*)} [::msgcat::mclocale] {\1}]
if {$locale == "c"} {set locale "en"}

set prefix [file rootname $script]

set list {}
lappend list $locale en
foreach item [glob -nocomplain -tails -path $prefix. -type f ??] {
  lappend list [lindex [split $item .] end]
}

unset locale
foreach suffix $list {
  set file $prefix.$suffix
  if {[file exists $file]} {
    if {[catch {source $file} result]} {
      messagebox -title [file tail $script] -icon error \
	-message "Error reading locale file '[file tail $file]':\n$result"
      exit
    }
    set locale $suffix
    ::msgcat::mclocale $locale
    break
  }
}
if {![info exists locale]} {
  messagebox -title [file tail $script] -icon error \
	-message "No locale file '[file tail $file]' found"
  exit
}

# Read user settings from file
# Filename = script's filename where file extension "tcl" is replaced by "ini"

set file [file rootname $script].ini

if {[file exist $file]} {
  if {[catch {source $file} result]} {
    messagebox -title [file tail $script] -icon error \
	-message "[mc i00 [file tail $file]]:\n$result"
    exit
  }
} else {
  messagebox -title [file tail $script] -icon error \
	-message "[mc i01 [file tail $file]]"
  exit
}

# Process user settings:
# replace commands resolved by current search path
# replace relative paths by absolute paths#

# - commands
set cmds {java_cmd curl_cmd gm_cmd magick_cmd}
# - commands + folders + files
set list [concat $cmds ini_folder maps_folder themes_folder server_jar]

set drive [regsub {((^.:)|(^//[^/]*)||(?:))(?:.*$)} $cwd {\1}]
if {$tcl_platform(os) == "Windows NT"}	{cd $env(SystemDrive)/}
if {$tcl_platform(os) == "Linux"}	{cd /}

foreach item $list {
  if {![info exists $item]} {continue}
  set value [set $item]
  if {$value == ""} {continue}
  if {[lsearch -exact $cmds $item] != -1} {
    set exec [auto_execok $value]
    if {$exec != ""} {set value [lindex $exec 0]}
  }
  switch [file pathtype $value] {
    absolute		{set $item [file normalize $value]}
    relative		{set $item [file normalize $cwd/$value]}
    volumerelative	{set $item [file normalize $drive/$value]}
  }
}

cd $cwd

# Restore saved settings from folder ini_folder

if {![info exists ini_folder]} {set ini_folder [file normalize ~/.Mapsforge]}
file mkdir $ini_folder

set maps.selection {}
set maps.world 0
set maps.contrast 0
set maps.gamma 1.00
set user.scale 1.00
set text.scale 1.00
set symbol.scale 1.00
set font.size [font configure TkDefaultFont -size]
set console.geometry ""
set console.font.size 8

set shading.onoff 0
set shading.layer "onmap"
set shading.algorithm "simple"
set shading.simple.linearity 0.1
set shading.simple.scale 0.666
set shading.diffuselight.angle 50.
set shading.magnitude 1.
set dem.folder ""

set tcp.port $tcp_port
set tcp.interface $interface
set tcp.maxconn 256
set threads.min 0
set threads.max 8

set use.curl 0
set use.magick "gm"
set tiles.folder $cwd
set tiles.abort 0
# For compatibility only:
set tiles.write 1
set http.keep 0
set http.wait 0

set tms_name_srv "Mapsforge Map"
set tms_name_ovl "Mapsforge Hillshading"

foreach item {global hillshading tiles} {
  set fd [open "$ini_folder/$item.ini" a+]
  seek $fd 0
  while {[gets $fd line] != -1} {
    regexp {^(.*?)=(.*)$} $line "" name value
    set $name $value
  }
  close $fd
}

# Restore saved font sizes

foreach item {TkDefaultFont TkTextFont TkFixedFont} {
  font configure $item -size ${font.size}
}
option add *Scale.Width [expr 6+${font.size}]

# Configure main window

set title [mc l01]
wm title . $title
wm protocol . WM_DELETE_WINDOW "set action 0"
wm resizable . 0 0
. configure -bd 5

bind . <Control-plus>  {incr_font_size +1}
bind . <Control-minus> {incr_font_size -1}
bind . <Control-KP_Add>      {incr_font_size +1}
bind . <Control-KP_Subtract> {incr_font_size -1}

bind Button <Return> {%W invoke}
bind Checkbutton <Return> {%W invoke}

set dialog.wrapLength [expr [winfo screenwidth .]/2]
foreach {name value} {
*Button.borderWidth 2
*Button.highlightThickness 1
*Button.padX 0
*Button.padY 0
*Button.takeFocus 1
*Checkbutton.anchor w
*Checkbutton.borderWidth 0
*Checkbutton.padX 0
*Checkbutton.padY 0
*Checkbutton.takeFocus 1
*Dialog.msg.wrapLength ${dialog.wrapLength}
*Dialog.dtl.wrapLength ${dialog.wrapLength}
*Dialog.msg.font TkDefaultFont
*Dialog.dtl.font TkDefaultFont
*Label.borderWidth 1
*Label.padX 0
*Label.padY 0
*Labelframe.borderWidth 0
*Radiobutton.borderWidth 0
*Radiobutton.padX 0
*Radiobutton.padY 0
*Scale.highlightThickness 1
*Scale.showValue 0
*Scale.takeFocus 1
*Scrollbar.takeFocus 0
*TCombobox.takeFocus 1
} {eval option add $name $value}

ttk::style configure TCombobox -padding 1

# Bitmap arrow down

set arrow_down [image create bitmap -data {
  #define down_arrow_width 12
  #define down_arrow_height 12
  static char down_arrow_bits[] = {
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0xfc,0xf1,0xf8,0xf0,0x70,0xf0,0x20,0xf0,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00;
  }
}]

# Output console window

set console 0;			# Valid values: 0=hide, 1=show, -1=disabled

toplevel .console
wm withdraw .console
wm title .console "$title - [mc l99]"
set family [lsearch -nocase -exact -inline [font families] Consolas]
if {$family == ""} {set family [font configure TkFixedFont -family]}
font create console_font -family $family -size ${console.font.size}
text .console.txt -font console_font -wrap none -setgrid 1 -state disabled \
	-width 120 -xscrollcommand {.console.sbx set} \
	-height 24 -yscrollcommand {.console.sby set}
scrollbar .console.sbx -orient horizontal -command {.console.txt xview}
scrollbar .console.sby -orient vertical   -command {.console.txt yview}
grid .console.txt -row 1 -column 1 -sticky nswe
grid .console.sby -row 1 -column 2 -sticky ns
grid .console.sbx -row 2 -column 1 -sticky we
grid columnconfigure .console 1 -weight 1
grid rowconfigure    .console 1 -weight 1

bind .console.txt <Control-a> {%W tag add sel 1.0 end;break}
bind .console.txt <Control-c> {tk_textCopy %W;break}
bind .console <Control-plus>  {incr_console_font_size +1}
bind .console <Control-minus> {incr_console_font_size -1}
bind .console <Control-KP_Add>      {incr_console_font_size +1}
bind .console <Control-KP_Subtract> {incr_console_font_size -1}

bind .console <Configure> {
  if {"%W" != [winfo toplevel "%W"]} {continue}
  scan [wm geometry %W] "%%dx%%d+%%d+%%d" cols rows x y
  set console.geometry "$x $y $cols $rows"
}

proc incr_console_font_size {incr} {
  set size [font configure console_font -size]
  incr size $incr
  if {$size < 5 || $size > 20} {return}
  font configure console_font -size $size
}

proc puts_console args {
  set len [llength $args]
  foreach {arg1 arg2 arg3} $args {break}
  if {$len == 1} {
    set txt "$arg1\n"
  } elseif {$len == 2} {
    if {$arg1 == "-nonewline"} {
      set txt $arg2
    } elseif {$arg1 == "stdout"||$arg1 == "stderr"} {
      set txt "$arg2\n"
    }
  } elseif {$len == 3} {
    if {$arg1 == "-nonewline" && ($arg2 == "stdout"||$arg2 == "stderr")} {
      set txt $arg3
    } elseif {($arg1 == "stdout"||$arg1 == "stderr") && $arg3 == "nonewline"} {
      set txt $arg2
    }
  }
  if {[info exists txt]} {
    .console.txt configure -state normal
    if {[string index $txt 0] == "\r"} {
      set txt [string range $txt 1 end]
      .console.txt delete end-2l end-1l
    }
    .console.txt insert end $txt
    .console.txt configure -state disabled
    if {[winfo ismapped .console]} {
      .console.txt see end
      update idletasks
    }
  } else {
    global errorCode errorInfo
    if {[catch "puts_tcl $args" msg]} {
      regsub puts_tcl $msg puts msg
      regsub -all puts_tcl $errorInfo puts errorInfo
      return -code error $msg
    }
    return $msg
  }
}

if {$console != -1} {
  rename ::puts ::puts_tcl
  interp alias {} ::puts {} ::puts_console
  interp alias {} ::tcl::chan::puts {} ::puts_console
}

if {$console == 1} {
  set console.show 1
  wm deiconify .console
}

# Mark output message

proc puti {text} {puts "\[---\] $text"}
proc putw {text} {puts "\[+++\] $text"}

# Show error message

proc error_message {message exit_return} {
  messagebox -title $::title -icon error -message $message
  eval $exit_return
}

# Get shell command from exec command

proc get_shell_command {command} {
  return [join [lmap item $command {regsub {^(.* +.*|())$} $item {"\1"}}]]
}

# Check operating system

if {$tcl_platform(os) == "Windows NT"} {
  if {$language == ""} {
    package require registry
    set language [registry get \
	{HKEY_CURRENT_USER\Control Panel\International} {LocaleName}]
    set language [regsub {(.*)-(.*)} $language {\1}]
  }
} elseif {$tcl_platform(os) == "Linux"} {
  if {$language == ""} {
    set language [regsub {(.*)_(.*)} $env(LANG) {\1}]
    if {$env(LANG) == "C"} {set language "en"}
  }
} else {
  error_message [mc e03 $tcl_platform(os)] exit
}

# Check commands & folders

foreach item {java_cmd} {
  set value [set $item]
  if {$value == ""} {error_message [mc e04 $value $item] exit}
}
foreach item {server_jar} {
  set value [set $item]
  if {![file isfile $value]} {error_message [mc e05 $value $item] exit}
}
foreach item {maps_folder themes_folder} {
  set value [set $item]
  if {![file isdirectory $value]} {error_message [mc e05 $value $item] exit}
}

# Get major Java version

set java_version 0
set java_string "unknown"
set command [list $java_cmd -version]
set rc [catch "exec $command 2>@1" result]
if {!$rc} {
  set line [lindex [split $result "\n"] 0]
  regsub -nocase {^.* version "(.*)".*$} $line {\1} data
  set java_string $data
  if {[regsub {1\.([1-9][0-9]*)\.[0-9]?.*} $data {\1} data] > 0} {
    set java_version $data; # Oracle Java version <= 8
  } elseif {[regsub {([1-9][0-9]*)\.[0-9]?\.[0-9]?.*} $data {\1} data] > 0} {
    set java_version $data; # Other Java versions
  }
}

if {$rc || $java_version == 0} \
  {error_message [mc e08 Java [get_shell_command $command] $result] exit}

# Evaluate numeric tile server version
# from output line containing version string " version: x.y.z"

set server_version 0
set server_string "unknown"
set command [list $java_cmd -jar $server_jar -h]
set rc [catch "exec $command 2>@1" result]
foreach line [split $result "\n"] {
  if {![regsub -nocase {^.* version: ((?:[0-9]+\.){2}(?:[0-9]+){1}).*$} $line \
	{\1} data]} {continue}
  set server_string $data
  foreach item [split $data .] \
	{set server_version [expr 100*$server_version+$item]}
  break
}

if {$rc || $server_version == 0} \
  {error_message [mc e08 Server [get_shell_command $command] $result] exit}

if {$server_version < 1704 } \
  {error_message [mc e07 $server_string 0.17.4] exit}

# Looking for installed URL tool "curl"

set curl ""
if {[info exists curl_cmd] && $curl_cmd != ""} {set curl $curl_cmd}
if {$curl == ""} {set curl [lindex [auto_execok curl] 0]}

if {$curl != ""} {
  catch "exec {$curl} -V" data
  set string [lindex [split $data] 1]
  set curl_version [split $string .]
  set curl_version [expr 1000*[lindex $curl_version 0]+[lindex $curl_version 1]]
}

# Looking for installed GraphicsMagick's tool "gm"

set gm ""
if {[info exists gm_cmd] && $gm_cmd != ""} {set gm $gm_cmd}

if {$gm == "" && $::tcl_platform(os) == "Windows NT"} {
  foreach dir {"GraphicsMagick*Q8*" "GraphicsMagick*"} {
    foreach var {"ProgramFiles" "ProgramFiles(x86)"} {
      if {![info exists env($var)]} {continue}
      set val $env($var)
      set gm [lindex [glob -nocomplain -type f \
	"[file normalize $val]/$dir/gm.exe"] end]
      if {$gm != ""} {break}
    }
    if {$gm != ""} {break}
  }
}
if {$gm == ""} {set gm [lindex [auto_execok gm] 0]}

# Set resource limits of GraphicsMagick
# - GraphicsMagick uses defaults for unset resource values
# - Resource value "-1" is equivalent to "unlimited"
# See http://www.graphicsmagick.org/GraphicsMagick.html

if {$gm != ""} {
# set env(MAGICK_LIMIT_DISK)	"-1"
  set env(MAGICK_LIMIT_FILES)	"16384"
# set env(MAGICK_LIMIT_MAP)	"4GiB"
# set env(MAGICK_LIMIT_MEMORY)	"2GiB"
# set env(MAGICK_LIMIT_WIDTH)	"10MiP"
# set env(MAGICK_LIMIT_HEIGHT)	"10MiP"
# set env(MAGICK_LIMIT_PIXELS)	"1GiB"

# catch "exec {$gm} convert -list Resource" result
# puts "[file tail $gm] - $result\n"
}

# Looking for installed ImageMagick's tool "magick"

set magick ""
if {[info exists magick_cmd] && $magick_cmd != ""} {set magick $magick_cmd}

if {$magick == "" && $::tcl_platform(os) == "Windows NT"} {
  foreach dir {"ImageMagick*Q8*" "ImageMagick*"} {
    foreach var {"ProgramFiles" "ProgramFiles(x86)"} {
      if {![info exists env($var)]} {continue}
      set val $env($var)
      set magick [lindex [glob -nocomplain -type f \
	"[file normalize $val]/$dir/magick.exe"] end]
      if {$magick != ""} {break}
    }
    if {$magick != ""} {break}
  }
}
if {$magick == ""} {set magick [lindex [auto_execok magick] 0]}

# Set resource limits of ImageMagick
# - ImageMagick uses defaults for unset resource values
# - Resource value "" is equivalent to "unlimited"
# See https://imagemagick.org/script/security-policy.php#policy
# and https://imagemagick.org/script/resources.php

if {$magick != ""} {
  set fd [open "$ini_folder/policy.xml" w]
  puts $fd {?xml version="1.0" encoding="UTF-8"?>}
  puts $fd {<!DOCTYPE policymap [}
  puts $fd {  <!ELEMENT policymap (policy)*>}
  puts $fd {  <!ATTLIST policymap xmlns CDATA #FIXED ''>}
  puts $fd {  <!ELEMENT policy EMPTY>}
  puts $fd {  <!ATTLIST policy xmlns CDATA #FIXED '' domain NMTOKEN #REQUIRED}
  puts $fd {    name NMTOKEN #IMPLIED pattern CDATA #IMPLIED}
  puts $fd {    rights NMTOKEN #IMPLIED}
  puts $fd {    stealth NMTOKEN #IMPLIED value CDATA #IMPLIED>}
  puts $fd {]>}
  puts $fd {<policymap>}
# puts $fd {  <policy domain="resource" name="disk" value=""/>}
# puts $fd {  <policy domain="resource" name="file" value="1536"/>}
# puts $fd {  <policy domain="resource" name="map" value="4GB"/>}
# puts $fd {  <policy domain="resource" name="memory" value="10GB"/>}
# puts $fd {  <policy domain="resource" name="area" value="10GB"/>}
# puts $fd {  <policy domain="resource" name="width" value="10MiP"/>}
# puts $fd {  <policy domain="resource" name="height" value="10MiP"/>}
  puts $fd {</policymap>}
  close $fd
  set env(MAGICK_CONFIGURE_PATH) $ini_folder

# catch "exec {$magick} -list Resource" result
# puts "[file tail $magick] - $result\n"
}

if {$gm == "" && $magick == ""} {error_message [mc e09] exit}

# Recursively find files

proc find_files {folder pattern} {
  set list [glob -nocomplain -directory $folder -type f $pattern]
  foreach subfolder [glob -nocomplain -directory $folder -type d *] {
    lappend list {*}[find_files $subfolder $pattern]
  }
  return $list
}

# Get list of available Mapsforge maps

cd $maps_folder
set maps [find_files "" "*.map"]
cd $cwd
set maps [lsort -dictionary $maps]

if {[llength $maps] == 0} {error_message [mc e11] exit}

# Get list of available Mapsforge themes
# and add Mapsforge built-in default theme

cd $themes_folder
set themes [find_files "" "*.xml"]
cd $cwd
lappend themes "(default)"
set themes [lsort -dictionary $themes]

# --- Begin of main window left column

# Title

font create title_font {*}[font configure TkDefaultFont] \
	-underline 1 -weight bold
label .title -text $title -font title_font -fg blue
pack .title -expand 1 -fill x

set github "https://github.com/JFritzle/Mapsforge-to-Tiles"
tooltip .title "$github"
if {$tcl_platform(platform) == "windows"} {
  set script "exec cmd.exe /C START {} $github"
} elseif {$tcl_platform(os) == "Linux"} {
  set script "exec nohup xdg-open $github >/dev/null"
}
bind .title <ButtonRelease-1> "catch {$script}"

# Left menu column

frame .l
pack .l -side left -anchor n

# Preferred maps language (2 lowercase letters ISO_639-1 code)

if {![info exists maps.language]} {set maps.language $language}
labelframe .lang -labelanchor w -text [mc l11]
pack .lang -in .l -expand 1 -fill x -pady 1
entry .lang_value -textvariable maps.language -width 4 -justify center
pack .lang_value -in .lang -side right
tooltip .lang_value [mc l11t]

.lang_value configure -validate key -vcmd {
  if {%d < 1} {return 1}
  if {[string length %P] > 2} {return 0}
  if {![string is lower %S]}  {return 0}
  return 1
}

# Mapsforge renderer

labelframe .renderer -labelanchor w -text [mc l12]:
pack .renderer -in .l -expand 1 -fill x -pady 1
combobox .renderer_values -width 10 \
	-validate key -validatecommand {return 0} \
	-textvariable renderer.name -values {"database" "direct"}
if {[.renderer_values current] < 0} {.renderer_values current 0}
pack .renderer_values -in .renderer -side right -anchor e -expand 1

# Mapsforge map selection

labelframe .maps_folder -labelanchor nw -text [mc l13]:
pack .maps_folder -in .l -expand 1 -fill x -pady 1
entry .maps_folder_value -textvariable maps_folder \
	-relief sunken -bd 1 -takefocus 0 -state readonly
pack .maps_folder_value -in .maps_folder -expand 1 -fill x

labelframe .maps -labelanchor nw -text [mc l14]:
pack .maps -in .l -expand 1 -fill x -pady 1
scrollbar .maps_scroll -command ".maps_values yview"
listbox .maps_values -selectmode extended -activestyle none \
	-takefocus 1 -exportselection 0 \
	-width 0 -height [expr min([llength $maps],8)] \
	-yscrollcommand ".maps_scroll set"
pack .maps_scroll -in .maps -side right -fill y
pack .maps_values -in .maps -side left -expand 1 -fill both

foreach map $maps {
  .maps_values insert end $map
  if {[lsearch -exact ${maps.selection} $map] != -1} {
    .maps_values selection set end
  }
}
set selection [.maps_values curselection]
if {[llength $selection] > 0} {.maps_values see [lindex $selection 0]}

# Append Mapsforge world map

checkbutton .maps_world -text [mc l15] -variable maps.world
pack .maps_world -in .l -expand 1 -fill x

# Mapsforge theme selection

labelframe .themes_folder -labelanchor nw -text [mc l16]:
pack .themes_folder -in .l -expand 1 -fill x -pady 1
entry .themes_folder_value -textvariable themes_folder \
	-relief sunken -bd 1 -takefocus 0 -state readonly
pack .themes_folder_value -in .themes_folder -expand 1 -fill x

set width 0
foreach item $themes \
  {set width [expr max([font measure TkTextFont $item],$width)]}
set width [expr $width/[font measure TkTextFont "0"]+1]

labelframe .themes -labelanchor nw -text [mc l17]:
pack .themes -in .l -expand 1 -fill x -pady 1
combobox .themes_values -width $width \
	-validate key -validatecommand {return 0} \
	-textvariable theme.selection -values $themes
if {[.themes_values current] < 0} {.themes_values current 0}
pack .themes_values -in .themes -expand 1 -fill x

# Mapsforge theme style selection

labelframe .styles -labelanchor nw -text [mc l18]:
combobox .styles_values -validate key -validatecommand {return 0}
pack .styles_values -in .styles -expand 1 -fill x
bind .styles_values <<ComboboxSelected>> switch_overlays_selection

# Mapsforge theme overlays selection

checkbutton .overlays_show_hide -text [mc c01] \
	-command "show_hide_toplevel_window .overlays"
pack .overlays_show_hide -in .styles -expand 1 -fill x -pady {2 0}

# Show hillshading options

checkbutton .shading_show_hide -text [mc c02] \
	-command "show_hide_toplevel_window .shading"
pack .shading_show_hide -in .l -expand 1 -fill x

# Show visual rendering effects options

checkbutton .effects_show_hide -text [mc c03] \
	-command "show_hide_toplevel_window .effects"
pack .effects_show_hide -in .l -expand 1 -fill x

# Show server settings

checkbutton .server_show_hide -text [mc c04] \
	-command "show_hide_toplevel_window .server"
pack .server_show_hide -in .l -expand 1 -fill x

# Filler down to bottom left

frame .fill_l
pack .fill_l -in .l -fill y

# --- End of main window left column

# Create toplevel windows for
# - overlays selection
# - hillshading settings
# - visual rendering effects
# - server settings

foreach toplevel {.overlays .shading .effects .server} {
  set parent ${toplevel}_show_hide
  toplevel $toplevel -bd 5
  wm withdraw $toplevel
  wm title $toplevel [$parent cget -text]
  wm protocol $toplevel WM_DELETE_WINDOW "$parent invoke"
  wm resizable $toplevel 0 0
  wm positionfrom $toplevel program
  if {[tk windowingsystem] == "x11"} {wm attributes $toplevel -type dialog}

  bind $toplevel <Double-ButtonRelease-3> "$parent invoke"
  bind $toplevel <Control-plus>  {incr_font_size +1}
  bind $toplevel <Control-minus> {incr_font_size -1}
  bind $toplevel <Control-KP_Add>      {incr_font_size +1}
  bind $toplevel <Control-KP_Subtract> {incr_font_size -1}
}

# Show/hide toplevel window

proc show_hide_toplevel_window {toplevel} {
  set onoff [set ::[${toplevel}_show_hide cget -variable]]
  if {$onoff} {
    position_toplevel_window $toplevel
    scan [wm geometry $toplevel] "%*dx%*d+%d+%d" x y
    wm transient $toplevel .
    wm deiconify $toplevel
    if {[tk windowingsystem] == "x11"} {wm geometry $toplevel +$x+$y}
  } else {
    scan [wm geometry $toplevel] "%*dx%*d+%d+%d" x y
    set ::{$toplevel.dx} [expr $x - [set ::{$toplevel.x}]]
    set ::{$toplevel.dy} [expr $y - [set ::{$toplevel.y}]]
    wm withdraw $toplevel
  }
}

# Position toplevel window right/left besides main window

proc position_toplevel_window {toplevel} {
  if {![winfo ismapped .]} {return}
  update idletasks
  scan [wm geometry .] "%dx%d+%d+%d" width height x y
  if {[tk windowingsystem] == "win32"} {
    set bdwidth [expr [winfo rootx .]-$x]
  } elseif {[tk windowingsystem] == "x11"} {
    set bdwidth 2
    if {[auto_execok xwininfo] == ""} {
      putw "Please install program 'xwininfo' by Linux package manager"
      putw "to evaluate exact window border width."
    } elseif {![catch "exec bash -c \"export LANG=C;xwininfo -id [wm frame .] \
	| grep Width | cut -d: -f2\"" wmwidth]} {
      set bdwidth [expr ($wmwidth-$width)/2]
      set width $wmwidth
    }
  }
  set reqwidth [winfo reqwidth $toplevel]
  set right [expr $x+$bdwidth+$width]
  set left  [expr $x-$bdwidth-$reqwidth]
  if {[expr $right+$reqwidth > [winfo vrootx .]+[winfo vrootwidth .]]} {
    set x [expr $left < [winfo vrootx .] ? 0 : $left]
  } else {
    set x $right
  }
  set ::{$toplevel.x} $x
  set ::{$toplevel.y} $y
  if {[info exists ::{$toplevel.dx}]} {
    incr x [set ::{$toplevel.dx}]
    incr y [set ::{$toplevel.dy}]
  }
  wm geometry $toplevel +$x+$y
}

# --- Begin of hillshading

# Enable/disable hillshading

checkbutton .shading.onoff -text [mc c80] -variable shading.onoff -width 30
pack .shading.onoff -expand 1 -fill x

# Hillshading on map or as separate transparent overlay map

radiobutton .shading.onmap -text [mc c81] -state disabled \
	-variable shading.layer -value onmap
tooltip .shading.onmap [mc c81t]
radiobutton .shading.asmap -text [mc c82] \
	-variable shading.layer -value asmap
pack .shading.onmap .shading.asmap -anchor w

# Choose DEM folder with HGT files

if {![file isdirectory ${dem.folder}]} {set dem.folder ""}

labelframe .shading.dem_folder -labelanchor nw -text [mc l81]:
tooltip .shading.dem_folder [mc l81t]
pack .shading.dem_folder -fill x -expand 1 -pady 1
entry .shading.dem_folder_value -textvariable dem.folder \
	-relief sunken -bd 1 -takefocus 0 -state readonly
tooltip .shading.dem_folder_value [mc l81t]
button .shading.dem_folder_button -image $arrow_down -command choose_dem_folder
pack .shading.dem_folder_button -in .shading.dem_folder \
	-side right -fill y -padx {3 0}
pack .shading.dem_folder_value -in .shading.dem_folder \
	-side left -fill x -expand 1

proc choose_dem_folder {} {
  set folder [tk_chooseDirectory -parent . -initialdir ${::dem.folder} \
	-mustexist 1 -title "$::title - [mc l82]"]
  if {$folder != "" && [file isdirectory $folder]} {set ::dem.folder $folder}
}

# Hillshading algorithm

labelframe .shading.algorithm -labelanchor w -text [mc l83]:
pack .shading.algorithm -expand 1 -fill x -pady 2
combobox .shading.algorithm_values -width 12 \
	-validate key -validatecommand {return 0} \
	-textvariable shading.algorithm -values {"simple" "diffuselight"}
if {[.shading.algorithm_values current] < 0} \
	{.shading.algorithm_values current 0}
pack .shading.algorithm_values -in .shading.algorithm \
	-side right -anchor e -expand 1

# Hillshading algorithm parameters

labelframe .shading.simple -labelanchor w -text [mc l84]:
entry .shading.simple_value1 -textvariable shading.simple.linearity \
	-width 8 -justify right
set .shading.simple_value1.minmax {0 1 0.1}
tooltip .shading.simple_value1 "0 \u2264 [mc l84] \u2264 1"
label .shading.simple_label2 -text [mc l85]:
entry .shading.simple_value2 -textvariable shading.simple.scale \
	-width 8 -justify right
set .shading.simple_value2.minmax {0 10 0.666}
tooltip .shading.simple_value2 "0 \u2264 [mc l85] \u2264 10"
pack .shading.simple_value1 .shading.simple_label2 .shading.simple_value2 \
	-in .shading.simple -side left -anchor w -expand 1 -fill x -padx {5 0}

labelframe .shading.diffuselight -labelanchor w -text [mc l86]:
entry .shading.diffuselight_value -textvariable shading.diffuselight.angle \
	-width 8 -justify right
set .shading.diffuselight_value.minmax {0 90 50.}
tooltip .shading.diffuselight_value "0 \u2264 [mc l85] \u2264 90"
pack .shading.diffuselight_value -in .shading.diffuselight \
	-side right -anchor e -expand 1

proc switch_shading_algorithm {} {
  catch "pack forget .shading.simple .shading.diffuselight"
  pack .shading.${::shading.algorithm} -after .shading.algorithm \
	-expand 1 -fill x -pady 1
}

bind .shading.algorithm_values <<ComboboxSelected>> switch_shading_algorithm
switch_shading_algorithm

# Hillshading magnitude

labelframe .shading.magnitude -labelanchor w -text [mc l87]:
pack .shading.magnitude -expand 1 -fill x
entry .shading.magnitude_value -textvariable shading.magnitude \
	-width 8 -justify right
set .shading.magnitude_value.minmax {0 4 1.}
tooltip .shading.magnitude_value "0 \u2264 [mc l87] \u2264 4"
pack .shading.magnitude_value -in .shading.magnitude -anchor e -expand 1

# Reset hillshading algorithm parameters

button .shading.reset -text [mc b92] -width 8 -takefocus 0 \
	-highlightthickness 0 -command "reset_shading_values"
tooltip .shading.reset [mc b92t]
pack .shading.reset -pady {2 0}

proc reset_shading_values {} {
  foreach widget {.shading.simple_value1 .shading.simple_value2 \
	          .shading.diffuselight_value .shading.magnitude_value} {
    $widget delete 0 end
    $widget insert 0 [lindex [set ::$widget.minmax] 2]
  }
}

# Validate hillshading algorithm parameters

proc validate_float_minmax {widget} {
  set value [$widget get]
  if {[regexp {^(\d+\.?\d*|\d*\.?\d+)$} $value]} {
    set valid 1
    lassign [set ::$widget.minmax] min max
    set test [regsub {([+-]?)0*([0-9]+.*)} $value {\1\2}]
    if {$min != "" && [expr $test < $min]} {set valid 0}
    if {$max != "" && [expr $test > $max]} {set valid 0}
  } else {
    set valid 0
  }
  if {!$valid} {set value [set ::$widget.previous]}
  $widget delete 0 end
  $widget insert 0 $value
}

proc validate_float_unsigned {value} {
  if {$value == "" || $value == "."} {return 1}
  return [regexp {^(\d+\.?\d*|\d*\.?\d+)$} $value]
}

foreach widget {.shading.simple_value1 .shading.simple_value2 \
	        .shading.diffuselight_value .shading.magnitude_value} {
  $widget configure -validate key -vcmd "validate_float_unsigned %P"
  bind $widget <Enter> {set ::%W.previous [%W get]}
  bind $widget <Leave> {after idle "validate_float_minmax %W"}
  bind $widget <FocusIn>  {set ::%W.previous [%W get]}
  bind $widget <FocusOut> {after idle "validate_float_minmax %W"}
  bind $widget <Shift-ButtonRelease-1> \
	{%W delete 0 end;%W insert 0 [lindex ${::%W.minmax} 2]}
}

# Save hillshading settings to folder ini_folder

proc save_shading_settings {} {uplevel #0 {
  set fd [open "$ini_folder/hillshading.ini" w]
  fconfigure $fd -buffering full
  foreach name {shading.onoff shading.algorithm \
	shading.simple.linearity shading.simple.scale \
	shading.diffuselight.angle shading.magnitude dem.folder} {
    puts $fd "$name=[set $name]"
  }
  close $fd
}}

# --- End of hillshading
# --- Begin of visual rendering effects

# Scaling

label .effects.scaling -text [mc s01]

label .effects.user_label -text [mc s02]: -anchor w
scale .effects.user_scale -from 0.05 -to 2.50 -resolution 0.05 \
	-orient horizontal -variable user.scale
bind .effects.user_scale <Shift-ButtonRelease-1> "set user.scale 1.00"
label .effects.user_value -textvariable user.scale -width 4 \
	-relief sunken -anchor center

label .effects.text_label -text [mc s03]: -anchor w
scale .effects.text_scale -from 0.05 -to 2.50 -resolution 0.05 \
	-orient horizontal -variable text.scale
bind .effects.text_scale <Shift-ButtonRelease-1> "set text.scale 1.00"
label .effects.text_value -textvariable text.scale -width 4 \
	-relief sunken -anchor center

label .effects.symbol_label -text [mc s04]: -anchor w
scale .effects.symbol_scale -from 0.05 -to 2.50 -resolution 0.05 \
	-orient horizontal -variable symbol.scale
bind .effects.symbol_scale <Shift-ButtonRelease-1> "set symbol.scale 1.00"
label .effects.symbol_value -textvariable symbol.scale -width 4 \
	-relief sunken -anchor center

set row 0
grid .effects.scaling -row $row -column 1 -columnspan 3 -sticky we
foreach item {user text symbol} {
  incr row
  grid .effects.${item}_label -row $row -column 1 -sticky w -padx {0 2}
  grid .effects.${item}_scale -row $row -column 2 -sticky we
  grid .effects.${item}_value -row $row -column 3 -sticky e
}

# Gamma correction & Contrast-stretching

label .effects.color -text [mc s06]

label .effects.gamma_label -text [mc s07]: -anchor w
scale .effects.gamma_scale -from 0.01 -to 4.99 -resolution 0.01 \
	-orient horizontal -variable maps.gamma
bind .effects.gamma_scale <Shift-ButtonRelease-1> "set maps.gamma 1.00"
label .effects.gamma_value -textvariable maps.gamma -width 4 \
	-relief sunken -anchor center

label .effects.contrast_label -text [mc s08]: -anchor w
scale .effects.contrast_scale -from 0 -to 254 -resolution 1 \
	-orient horizontal -variable maps.contrast
bind .effects.contrast_scale <Shift-ButtonRelease-1> "set maps.contrast 0"
label .effects.contrast_value -textvariable maps.contrast -width 4 \
	-relief sunken -anchor center

set row 10
grid .effects.color -row $row -column 1 -columnspan 3 -sticky we
foreach item {gamma contrast} {
  incr row
  grid .effects.${item}_label -row $row -column 1 -sticky w -padx {0 2}
  grid .effects.${item}_scale -row $row -column 2 -sticky we
  grid .effects.${item}_value -row $row -column 3 -sticky e
}

grid columnconfigure .effects {1 2} -uniform 1

# Reset visual rendering effects

button .effects.reset -text [mc b92] -width 8 -takefocus 0 \
	-highlightthickness 0 -command "reset_effects_values"
tooltip .effects.reset [mc b92t]
grid .effects.reset -row 99 -column 1 -columnspan 3 -pady {2 0}

proc reset_effects_values {} {
  foreach item {user.scale text.scale symbol.scale maps.gamma} \
	{set ::$item 1.00}
  set ::maps.contrast 0
}

# --- End of visual rendering effects
# --- Begin of server settings

# Server information

label .server.info -text [mc x01]
pack .server.info

# Java runtime version

labelframe .server.jre_version -labelanchor w -text [mc x02]:
pack .server.jre_version -expand 1 -fill x -pady 1
label .server.jre_version_value -anchor e -textvariable java_string
pack .server.jre_version_value -in .server.jre_version \
	-side right -anchor e -expand 1

# Mapsforge server version

labelframe .server.version -labelanchor w -text [mc x03]:
pack .server.version -expand 1 -fill x -pady 1
label .server.version_value -anchor e -textvariable server_string
pack .server.version_value -in .server.version \
	-side right -anchor e -expand 1

# Mapsforge server version jar archive

labelframe .server.jar -labelanchor nw -text [mc x04]:
pack .server.jar -expand 1 -fill x -pady 1
entry .server.jar_value -textvariable server_jar \
	-relief sunken -bd 1 -takefocus 0 -state readonly
pack .server.jar_value -in .server.jar -expand 1 -fill x

# Server configuration

label .server.config -text [mc x11]
pack .server.config -pady {10 5}

# Rendering engine

if {$java_version <= 8} {
  set pattern marlin-*-Unsafe
} elseif {$java_version <= 10} {
  set pattern marlin-*-Unsafe-OpenJDK9
} else {
  set pattern marlin-*-Unsafe-OpenJDK11
}
set engines [glob -nocomplain -tails -type f \
  -directory [file dirname $server_jar] $pattern.jar]
lappend engines "(default)"
set engines [lsort -dictionary $engines]

set width 0
foreach item $engines \
  {set width [expr max([font measure TkTextFont $item],$width)]}
set width [expr $width/[font measure TkTextFont "0"]+1]

labelframe .server.engine -labelanchor nw -text [mc x12]:
combobox .server.engine_values -width $width \
	-validate key -validatecommand {return 0} \
	-textvariable rendering.engine -values $engines
if {[.server.engine_values current] < 0} \
	{.server.engine_values current 0}
if {[llength $engines] > 1} {
  pack .server.engine -expand 1 -fill x -pady 1
  pack .server.engine_values -in .server.engine \
	-anchor e -expand 1 -fill x
}

# Server interface

labelframe .server.interface -labelanchor w -text [mc x13]:
combobox .server.interface_values -width 10 \
	-textvariable tcp.interface -values {"localhost" "all"}
if {[.server.interface_values current] < 0} \
	{.server.interface_values current 0}
pack .server.interface -expand 1 -fill x -pady {6 1}
pack .server.interface_values -in .server.interface \
	-side right -anchor e -expand 1 -padx {3 0}

# Server TCP port number

labelframe .server.port -labelanchor w -text [mc x15]:
entry .server.port_value -textvariable tcp.port \
	-width 6 -justify center
set .server.port_value.minmax "1024 65535 $tcp_port"
tooltip .server.port_value "1024 \u2264 [mc x15] \u2264 65535"
pack .server.port -expand 1 -fill x -pady 1
pack .server.port_value -in .server.port \
	-side right -anchor e -expand 1 -padx {3 0}

# Maximum size of TCP listening queue

labelframe .server.maxconn -labelanchor w -text [mc x16]:
entry .server.maxconn_value -textvariable tcp.maxconn \
	-width 6 -justify center
set .server.maxconn_value.minmax {0 {} 256}
tooltip .server.maxconn_value "[mc x16] \u2265 0"
pack .server.maxconn -expand 1 -fill x -pady 1
pack .server.maxconn_value -in .server.maxconn \
	-side right -anchor e -expand 1 -padx {3 0}

# Minimum number of concurrent threads

labelframe .server.threadsmin -labelanchor w -text [mc x17]:
entry .server.threadsmin_value -textvariable threads.min \
	-width 6 -justify center
set .server.threadsmin_value.minmax {0 {} 0}
tooltip .server.threadsmin_value "[mc x17] \u2265 0"
pack .server.threadsmin -expand 1 -fill x -pady {6 1}
pack .server.threadsmin_value -in .server.threadsmin \
	-side right -anchor e -expand 1 -padx {3 0}

# Maximum number of concurrent threads

labelframe .server.threadsmax -labelanchor w -text [mc x18]:
entry .server.threadsmax_value -textvariable threads.max \
	-width 6 -justify center
set .server.threadsmax_value.minmax {4 {} 8}
tooltip .server.threadsmax_value "[mc x18] \u2265 4"
pack .server.threadsmax -expand 1 -fill x -pady 1
pack .server.threadsmax_value -in .server.threadsmax \
	-side right -anchor e -expand 1 -padx {3 0}

# Reset server configuration

button .server.reset -text [mc b92] -width 8 -takefocus 0 \
	-highlightthickness 0 -command "reset_server_values"
tooltip .server.reset [mc b92t]
pack .server.reset -pady {2 0}

proc reset_server_values {} {
  foreach widget {.server.port_value .server.maxconn_value \
	        .server.threadsmin_value .server.threadsmax_value} {
    $widget delete 0 end
    $widget insert 0 [lindex [set ::$widget.minmax] 2]
  }
  .server.engine_values current 0
  .server.interface_values set $::interface
}

# Validate server settings

proc validate_number_minmax {widget} {
  set value [$widget get]
  if {[regexp {^(\d+)$} $value]} {
    set valid 1
    lassign [set ::$widget.minmax] min max
    set test [regsub {([+-]?)0*([0-9]+.*)} $value {\1\2}]
    if {$min != "" && [expr $test < $min]} {set valid 0}
    if {$max != "" && [expr $test > $max]} {set valid 0}
  } else {
    set valid 0
  }
  if {!$valid} {set value [set ::$widget.previous]}
  $widget delete 0 end
  $widget insert 0 $value
}

proc validate_number_unsigned {value} {
  if {$value == ""} {return 1}
  return [regexp {^(\d+)$} $value]
}

foreach widget {.server.port_value .server.maxconn_value \
	        .server.threadsmin_value .server.threadsmax_value} {
  $widget configure -validate key -vcmd "validate_number_unsigned %P"
  bind $widget <Enter> {set ::%W.previous [%W get]}
  bind $widget <Leave> {after idle "validate_number_minmax %W"}
  bind $widget <FocusIn>  {set ::%W.previous [%W get]}
  bind $widget <FocusOut> {after idle "validate_number_minmax %W"}
  bind $widget <Shift-ButtonRelease-1> \
	{%W delete 0 end;%W insert 0 [lindex ${::%W.minmax} 2]}
}

# --- End of server settings
# --- Begin of theme file processing

# Get list of attributes from given xml element

proc get_element_attributes {name string} {
  lappend attributes name $name
  regsub ".*<$name\\s+(.*?)\\s*/?>.*" $string {\1} string
  set items [regsub -all {(\S+?)\s*=\s*(".*?"|'.*?')} $string {{\1=\2}}]
  foreach item $items {
    lappend attributes {*}[lrange [regexp -inline {(\S+)=.(.*).} $item] 1 2]
  }
  return $attributes
}

# Recursively find all overlays in layers list for given layer id

proc find_overlays_for_layer {layer_id layers} {
  set overlays {}
  set layer_index [lsearch -exact -index 0 $layers $layer_id]
  array set layer [lindex $layers [list $layer_index 1]]
  if {[info exists layer(parent)]} {
    lappend overlays {*}[find_overlays_for_layer $layer(parent) $layers]
  }
  lappend overlays {*}$layer(overlays)
  foreach overlay_id $overlays {
    lappend overlays {*}[find_overlays_for_layer $overlay_id $layers]
  }
  return $overlays
}

# Switch overlay selection to selected style

proc switch_overlays_selection {} {
  foreach child [winfo children .overlays] {pack forget $child}
  set style_index [.styles_values current]
  set style [lindex ${::style.table} $style_index]
  set style_id [lindex $style 0]
  pack .overlays.$style_id -expand 1 -fill x
  position_toplevel_window .overlays
}

# Read theme file and create styles & overlays lookup table
# Update lookup table by presets from ini file, if any
# Initialize style & overlays selection dialogs

proc setup_styles_overlays_structure {} {
  # Hide style & overlays selection
  if {[winfo manager .styles] != ""} {
    save_theme_settings
    pack forget .styles
    foreach child [winfo children .overlays] {destroy $child}
  }

  # Default theme has no style: nothing to do
  # Default theme has hillshading: enable hillshading configuration
  set theme ${::theme.selection}
  if {$theme == "(default)"} {
    unset -nocomplain ::style.table ::style.theme
    if {[winfo ismapped .overlays]} {.overlays_show_hide invoke}
    .shading.onmap configure -state normal
    update idletasks
    return
  }

  # Read theme file
  set ::style.theme $theme
  set theme_file "$::themes_folder/$theme"
  set fd [open $theme_file r]
  fconfigure $fd -encoding utf-8
  set data [read $fd]
  close $fd

  # Split into list of elements between "<" and ">"
  set elements {}
  set string ""
  foreach char [split $data ""] {
    if {$char == "<"} {
      set string $char
    } elseif {$char == ">"} {
      append string $char
      lappend elements $string
      set string ""
    } else {
      append string $char
    }
  }

  # Search for hillshading element
  if {[lsearch -regexp $elements {<hillshading\s+.*?>}] == -1} {
    # Hillshading element not found: disable hillshading configuration
    .shading.onmap configure -state disabled
  } else {
    # Hillshading element found: enable hillshading configuration
    .shading.onmap configure -state normal
  }

  # Search for stylemenu element
  set menu_first [lsearch -regexp $elements {<stylemenu\s+.*?>}]

  # No style menu found: nothing to do
  if {$menu_first == -1} {
    unset -nocomplain ::style.table ::style.theme
    if {[winfo ismapped .overlays]} {.overlays_show_hide invoke}
    update idletasks
    return
  }

  # Stylemenu found
  set menu_last [lsearch -start $menu_first -regexp $elements {</stylemenu>}]
  set menu_data [lrange $elements $menu_first $menu_last]

  # Analyze stylemenu element for attribute defaultvalue
  array set stylemenu [get_element_attributes "stylemenu" [lindex $menu_data 0]]
  set defaultstyle $stylemenu(defaultvalue)
  set defaultlang  $stylemenu(defaultlang)
  unset stylemenu

  # Search for layer elements within stylemenu
  set layers {}
  set layer_indices [lsearch -all -regexp $menu_data {<layer\s+.*?>}]
  foreach layer_first $layer_indices {
    set layer_last [lsearch -start $layer_first -regexp $menu_data {</layer>}]
    set layer_data [lrange $menu_data $layer_first $layer_last]
    array unset layer
    array set layer [get_element_attributes "layer" [lindex $layer_data 0]]

    # Find layer's localized layer name
    set indices [lsearch -all -regexp $layer_data {<name\s+.*?>}]
    foreach index $indices {
      array unset name
      array set name [get_element_attributes "name" [lindex $layer_data $index]]
      if {![info exists name(lang)]} {continue}
      if {$name(lang) == $::language} {
	set layer(name) $name(value)
	break
      } elseif {$name(lang) == $defaultlang} {
	set layer(name) $name(value)
      }
    }

    # Replace quoted characters within layer's name
    if {[info exists layer(name)]} {
      regsub -all {&quot;} $layer(name) {\0x22} layer(name)
      regsub -all {&amp;}  $layer(name) {\&}    layer(name)
      regsub -all {&apos;} $layer(name) {'}     layer(name)
      regsub -all {&lt;}   $layer(name) {<}     layer(name)
      regsub -all {&gt;}   $layer(name) {>}     layer(name)
    }

    # Find layer's direct overlays
    set layer(overlays) {}
    set indices [lsearch -all -regexp $layer_data {<overlay\s+.*?>}]
    foreach index $indices {
      array unset overlay
      array set overlay \
	[get_element_attributes "overlay" [lindex $layer_data $index]]
      lappend layer(overlays) $overlay(id)
    }

    lappend layers [list $layer(id) [array get layer]]
  }
  unset -nocomplain layer name overlay

  # Append overlay elements to each style and fill global lookup table
  set ::style.table {}
  foreach item $layers {
    array unset layer
    array set layer [lindex $item 1]
    if {![info exists layer(visible)]} {continue}
    set overlays {}
    foreach overlay_id [find_overlays_for_layer $layer(id) $layers] {
      set overlay_index [lsearch -exact -index 0 $layers $overlay_id]
      array unset overlay_layer
      array set overlay_layer [lindex $layers [list $overlay_index 1]]
      if {![info exists overlay_layer(enabled)]} {
	set overlay_layer(enabled) "false"
      }
      lappend overlays [list $overlay_layer(id) $overlay_layer(name) \
	 $overlay_layer(enabled) $overlay_layer(enabled)]
    }
    lappend ::style.table [list $layer(id) $layer(name) $overlays]
  }
  unset -nocomplain layer overlay_layer

  # Restore style & overlays from folder ini_folder
  set ini_file "$::ini_folder/theme.[regsub -all {/} $theme {.}].ini"
  array set preset {}
  set fd [open "$ini_file" a+]
  seek $fd 0
  while {[gets $fd line] != -1} {
    regexp {^(.*?)=(.*)$} $line "" name value
    set preset($name) $value
  }
  close $fd

  # Restore selected style
  if {[info exists preset(defaultstyle)] &&
      [lsearch -exact -index 0 ${::style.table} $preset(defaultstyle)] >= 0} {
    set defaultstyle $preset(defaultstyle)
  }

  # Restore selected overlays
  set style_index 0
  foreach style ${::style.table} {
    set style_id [lindex $style 0]
    set overlays [lindex $style 2]
    set overlay_index 0
    foreach overlay $overlays {
      set overlay_id [lindex $overlay 0]
      set name "$style_id.$overlay_id"
      if {[info exists preset($name)]} {
	lset overlay 2 $preset($name)
	lset overlays $overlay_index $overlay
      }
      incr overlay_index
    }
    lset style 2 $overlays
    lset ::style.table $style_index $style
    incr style_index
  }

  # Fill overlay selections
  if {$::tcl_platform(os) == "Linux"} {set pady 1} else {set pady 0}
  foreach style ${::style.table} {
    set style_id [lindex $style 0]
    set parent .overlays.$style_id
    frame $parent
    label $parent.label -text [lindex $style 1]
    frame $parent.separator1 -bd 2 -height 2 -relief sunken
    pack $parent.label $parent.separator1 -expand 1 -fill x -pady {0 2}
    set overlays [lindex $style 2]
    foreach overlay $overlays {
      set overlay_id [lindex $overlay 0]
      set child $parent.$overlay_id
      set variable [string range $child 1 end]
      set ::$variable [lindex $overlay 2]
      checkbutton $child -text [lindex $overlay 1] \
	   -pady $pady -highlightthickness 0 -takefocus 0 \
	   -variable $variable -onvalue "true" -offvalue "false" \
	   -command "update_style_overlay $child"
      pack $child -expand 1 -fill x
    }
    frame $parent.separator2 -bd 2 -height 2 -relief sunken
    pack $parent.separator2 -expand 1 -fill x -pady 2
    frame $parent.frame
    pack $parent.frame -expand 1
    button $parent.frame.all -text [mc b91] -width 8 -takefocus 0 \
	-highlightthickness 0 -command "select_style_overlays $parent all"
    tooltip $parent.frame.all [mc b91t]
    button $parent.frame.reset -text [mc b92] -width 8 -takefocus 0 \
	-highlightthickness 0 -command "select_style_overlays $parent default"
    tooltip $parent.frame.reset [mc b92t]
    button $parent.frame.none -text [mc b93] -width 8 -takefocus 0 \
	-highlightthickness 0 -command "select_style_overlays $parent none"
    tooltip $parent.frame.none [mc b93t]
    pack $parent.frame.all $parent.frame.reset $parent.frame.none -side left
  }

  # Fill style selection, select default style
  .styles_values configure -values [lmap i ${::style.table} {lindex $i 1}]
  set style_index [lsearch -exact -index 0 ${::style.table} $defaultstyle]
  .styles_values current $style_index

  # Show style selection
  pack configure .styles -in .l -after .themes -expand 1 -fill x -pady 1

  # Set default overlay selection
  pack .overlays.$defaultstyle -expand 1 -fill x
  position_toplevel_window .overlays
}

# Update style's lookup table entry to current overlay selection

proc update_style_overlay {child} {
  set enabled [set ::[$child cget -variable]]
  regexp {^\.overlays\.(.*?)\.(.*)$} $child "" style_id overlay_id
  set style_index [lsearch -exact -index 0 ${::style.table} $style_id]
  set style [lindex ${::style.table} $style_index]
  set overlays [lindex $style 2]
  set overlay_index [lsearch -exact -index 0 $overlays $overlay_id]
  set overlay [lindex $overlays $overlay_index]
  lset overlay 2 $enabled
  lset overlays $overlay_index $overlay
  lset style 2 $overlays
  lset ::style.table $style_index $style
}

# Select style's overlays from theme file:
# - select all overlays
# - deselect all overlays
# - select default overlays only

proc select_style_overlays {parent select} {
  switch $select {
    all		{set check {$enabled != "true"}}
    none	{set check {$enabled == "true"}}
    default	{set check {$enabled != $default}}
  }
  regexp {^\.overlays\.(.*?)$} $parent "" style_id
  set style_index [lsearch -exact -index 0 ${::style.table} $style_id]
  set style [lindex ${::style.table} $style_index]
  set overlays [lindex $style 2]
  foreach overlay $overlays {
    set enabled [lindex $overlay 2]
    set default [lindex $overlay 3]
    if {[expr $check]} {
      set overlay_id [lindex $overlay 0]
      set child $parent.$overlay_id
      $child invoke
    }
  }
}

# Get currently selected style & overlays

proc get_selected_style_overlays {} {
  set style_index [.styles_values current]
  set style [lindex ${::style.table} $style_index]
  set style_id [lindex $style 0]
  set overlays [lindex $style 2]
  set overlay_ids {}
  foreach overlay $overlays {
    if {[lindex $overlay 2] == "true"} {
      lappend overlay_ids [lindex $overlay 0]
    }
  }
  set overlay_ids [join $overlay_ids ","]
  return [list $style_id $overlay_ids]
}

# Save theme settings to folder ini_folder

proc save_theme_settings {} {
  set theme ${::style.theme}
  set style_index [.styles_values current]
  set style [lindex ${::style.table} $style_index]
  set style_id [lindex $style 0]
  set ini_file "$::ini_folder/theme.[regsub -all {/} $theme {.}].ini"
  set fd [open "$ini_file" w]
  fconfigure $fd -buffering full
  puts $fd "defaultstyle=$style_id"
  foreach style ${::style.table} {
    set style_id [lindex $style 0]
    set overlays [lindex $style 2]
    foreach overlay $overlays {
      set overlay_id [lindex $overlay 0]
      puts $fd "$style_id.$overlay_id=[lindex $overlay 2]"
    }
  }
  close $fd
}

# Enable styles & overlays selection

bind .themes_values <<ComboboxSelected>> setup_styles_overlays_structure
event generate .themes_values <<ComboboxSelected>>

# --- End of theme file processing

# Save global settings to folder ini_folder

proc save_global_settings {} {uplevel #0 {
  set maps.selection [lmap index [.maps_values curselection] \
	{.maps_values get $index}]
  scan [wm geometry .] "%dx%d+%d+%d" width height x y
  set window.geometry "$x $y $width $height"
  set font.size [font configure TkDefaultFont -size]
  set console.font.size [font configure console_font -size]
  set fd [open "$ini_folder/global.ini" w]
  fconfigure $fd -buffering full
  foreach name {renderer.name rendering.engine maps.language \
	maps.selection maps.world maps.contrast maps.gamma \
	theme.selection user.scale text.scale symbol.scale \
	tcp.maxconn threads.min threads.max \
	window.geometry font.size \
	console.show console.geometry console.font.size} {
    puts $fd "$name=[set $name]"
  }
  close $fd
}}

# Save application dependent settings to folder ini_folder

proc save_tiles_settings {} {uplevel #0 {
  set fd [open "$ini_folder/tiles.ini" w]
  fconfigure $fd -buffering full
  set xyrange.mode [.xyrange_values current]
  foreach name {tiles.folder tiles.prefix xyrange.mode zoom.level \
	tiles.xmin tiles.xmax tiles.ymin tiles.ymax \
	coord.xmin coord.xmax coord.ymin coord.ymax \
	tiles.write tiles.abort tiles.compose tiles.keep composed.show \
	tcp.interface tcp.port shading.layer \
	use.curl use.magick http.wait http.keep} {
    puts $fd "$name=[set $name]"
  }
  close $fd
}}

# Menu columns separator

frame .m -width 2 -bd 2 -relief sunken
pack .m -side left -expand 1 -fill y -padx 5

# --- Begin of main window right column

# Right menu column

frame .r
pack .r -anchor n

# X and Y range

labelframe .xyrange -labelanchor w -text [mc l21]:
pack .xyrange -in .r -expand 1 -fill x -pady 1
combobox .xyrange_values -width 18 -values [list [mc v22] [mc v23]] \
	-validate key -validatecommand {return 0}
if {[info exists xyrange.mode]} {.xyrange_values current ${::xyrange.mode}}
if {[.xyrange_values current] < 0} {.xyrange_values current 0}
pack .xyrange_values -in .xyrange -side right -anchor e -expand 1

proc switch_xyrange {} {
  set range [.xyrange_values current]
  if {$range == 0} {
    set w tiles
    set r coord
  } else {
    set r tiles
    set w coord
  }
  foreach item {xmine xmaxe ymine ymaxe} {
    .${w}.$item configure -takefocus 1 -state normal
    .${r}.$item configure -takefocus 0 -state readonly
  }
}

# Tiles

labelframe .tiles -labelanchor nw -text [mc l22]:
pack .tiles -in .r -fill x

# Coordinates

labelframe .coord -labelanchor nw -text [mc l23]:
pack .coord -in .r -fill x

# Common widgets for tiles/coordinates

foreach item {tiles coord} {
  set widget .${item}
  label $widget.xminl -text "X min"
  entry $widget.xmine -textvariable ${item}.xmin -justify right -width 12
  label $widget.xmaxl -text "X max"
  entry $widget.xmaxe -textvariable ${item}.xmax -justify right -width 12
  grid $widget.xminl -in $widget -row 1 -column 1 -sticky w
  grid $widget.xmine -in $widget -row 1 -column 2 -sticky w
  grid $widget.xmaxl -in $widget -row 1 -column 3 -sticky e
  grid $widget.xmaxe -in $widget -row 1 -column 4 -sticky e
  label $widget.yminl -text "Y min"
  entry $widget.ymine -textvariable ${item}.ymin -justify right -width 12
  label $widget.ymaxl -text "Y max"
  entry $widget.ymaxe -textvariable ${item}.ymax -justify right -width 12
  grid $widget.yminl -in $widget -row 2 -column 1 -sticky w
  grid $widget.ymine -in $widget -row 2 -column 2 -sticky w
  grid $widget.ymaxl -in $widget -row 2 -column 3 -sticky e
  grid $widget.ymaxe -in $widget -row 2 -column 4 -sticky e
  grid columnconfigure $widget {1 3} -weight 1
  grid columnconfigure $widget {2 4} -weight 1
}

# Zoom level

labelframe .zoom -labelanchor w -text [mc l24]:
pack .zoom -in .r -fill x -expand 1 -pady 1
scale .zoom_scale -from $min_zoom_level -to $max_zoom_level -resolution 1 \
	-orient horizontal -variable zoom.level -command scale_zoom
label .zoom_value -anchor center -textvariable zoom.level -width 4 \
	-relief sunken
pack .zoom_value -in .zoom -side right
pack .zoom_scale -in .zoom -side left -fill x -expand 1

proc scale_zoom {zoom} {
  set tmax [expr (1<<$zoom)-1]
  set xmax 180
  set ymax 85.0511
  set tiles_xmin "X min \u2265 0 ([mc t21 0 $xmax°])"
  set tiles_xmax "X max \u2264 $tmax ([mc t22 $tmax $xmax°])"
  set tiles_ymin "Y min \u2265 0 ([mc t23 0 $ymax°])"
  set tiles_ymax "Y max \u2264 $tmax ([mc t24 $tmax $ymax°])"
  set coord_xmin "X min \u2265 -$xmax ([mc t21 0 $xmax°])"
  set coord_xmax "X max \u2264 +$xmax ([mc t22 $tmax $xmax°])"
  set coord_ymin "Y min \u2265 -$ymax ([mc t24 $tmax $ymax°])"
  set coord_ymax "Y max \u2264 +$ymax ([mc t23 0 $ymax°])"
  foreach item {tiles coord} {
    set widget .${item}
    eval tooltip $widget.xmine "\$${item}_xmin"
    eval tooltip $widget.xmaxe "\$${item}_xmax"
    eval tooltip $widget.ymine "\$${item}_ymin"
    eval tooltip $widget.ymaxe "\$${item}_ymax"
  }
  set count [expr $tmax+1]
  tooltip .zoom_scale "[mc t25 $tmax $count $count]"

  # Shrink tiles range to valid range
  while {1} {
    set valid 1
    foreach item {xmin xmax ymin ymax} {
      if {[set ::tiles.$item] > $tmax} {set valid 0}
    }
    if {$valid} {break}
    foreach item {xmin xmax ymin ymax} {
      set ::tiles.$item [expr [set ::tiles.$item]>>1]
    }
  }

  # Recalculate tile numbers or coordinate values
  if {[.xyrange_values current] == 0} {
    set type "tiles"
  } else {
    set type "coord"
  }
  foreach item {xmine xmaxe ymine ymaxe} {
    set widget .$type.$item
    set value [$widget get]
    validate_$type $widget $value
  }
}

bind .xyrange_values <<ComboboxSelected>> switch_xyrange
switch_xyrange

# Validate tile numbers

foreach item {xmine xmaxe ymine ymaxe} {
  .tiles.$item configure -validate key -vcmd "validate_tiles %W %P"
}

proc validate_tiles {widget tile} {
  if {[$widget cget -state] == "readonly"} {return 1}
  set tile [string trim $tile]
  set suffix [lindex [split $widget "."] end]
  set xy [string range $suffix 0 0]
  set minmax [string range $suffix 1 3]
  regsub -- {tiles} $widget {coord} coord_widget
  set variable [$coord_widget cget -textvariable]
  if {$xy == "y"} {
    if {$minmax == "min"} {
      regsub -- {min} $variable {max} variable
    } else {
      regsub -- {max} $variable {min} variable
    }
  }
  if {$tile == ""} {
    set ::$variable ""
    return 1
  }
  if {![string is integer $tile]} {return 0}
  set max [expr 1<<${::zoom.level}]
  if {$tile < 0} {return 0}
  if {$tile >= $max} {return 0}
  if {$minmax == "max"} {incr tile]}
  set max [expr double($max)]
  if {$xy == "x"} {
    set value [expr $tile/$max*360.-180.]
  } else {
    set pi 3.1415926535897931
    set value [expr atan(sinh($pi*(1.-2.*$tile/$max)))]
    set value [expr $value*180./$pi]
  }
  set ::$variable [format "%+.7f" $value]
  return 1
}

# Validate coordinates

foreach item {xmine xmaxe ymine ymaxe} {
  .coord.$item configure -validate key -vcmd "validate_coord %W %P"
}

proc validate_coord {widget coord} {
  if {[$widget cget -state] == "readonly"} {return 1}
  set coord [string trim $coord]
  set suffix [lindex [split $widget "."] end]
  set xy [string range $suffix 0 0]
  set minmax [string range $suffix 1 3]
  regsub -- {coord} $widget {tiles} tiles_widget
  set variable [$tiles_widget cget -textvariable]
  if {$xy == "y"} {
    if {$minmax == "min"} {
      regsub -- {min} $variable {max} variable
    } else {
      regsub -- {max} $variable {min} variable
    }
  }
  if {$coord == "" || $coord == "+" || $coord == "-"} {
    set ::$variable ""
    return 1
  }
  if {![string is double $coord]} {return 0}
  if {$xy == "x"} {
    set limit 180.
  } else {
    set limit 85.0511288
  }
  if {$coord < -$limit} {return 0}
  if {$coord > +$limit} {return 0}
  set max [expr double(1<<${::zoom.level})]
  if {$xy == "x"} {
    set value [expr ($coord+180.)/360.*$max]
  } else {
    set pi 3.1415926535897931
    set coord [expr $coord*$pi/180.]
    set value [expr (1.-(log(tan($coord)+1./cos($coord))/$pi))/2.*$max]
  }
  set ::$variable [expr int(min($value,$max-1))]
  return 1
}

# Recalculate tile numbers or coordinate values

scale_zoom ${zoom.level}

# Choose folder for tiles and composed image

if {![file isdirectory ${tiles.folder}]} {set tiles.folder $cwd}
labelframe .tiles_folder -labelanchor nw -text [mc l31]:
pack .tiles_folder -in .r -fill x -expand 1 -pady 1
entry .tiles_folder_value -textvariable tiles.folder \
	-relief sunken -bd 1 -takefocus 0 -state readonly
button .tiles_folder_button -image $arrow_down -command choose_tiles_folder
pack .tiles_folder_button -in .tiles_folder -side right -fill y -padx {3 0}
pack .tiles_folder_value -in .tiles_folder -side left -fill x -expand 1

proc choose_tiles_folder {} {
  set folder [tk_chooseDirectory -parent . -initialdir ${::tiles.folder} \
	-title "$::title - [mc l32]"]
  if {$folder != ""} {
    if {![file isdirectory $folder]} {catch "file mkdir $folder"}
    if { [file isdirectory $folder]} {set ::tiles.folder $folder}
  }
}

# Filename prefix

labelframe .tiles_prefix -labelanchor w -text [mc l33]:
pack .tiles_prefix -in .r -expand 1 -fill x -pady {2 1}
entry .tiles_prefix_value -textvariable tiles.prefix -width 25 -justify left
pack .tiles_prefix_value -in .tiles_prefix -side right

.tiles_prefix_value configure -validate key -vcmd {
  if {%d < 1} {return 1}
  return [regexp {^(\w+[-.]?)*$} %P]
}

# Use "curl" for download

checkbutton .use_curl -text [mc c30] -variable use.curl
pack .use_curl -in .r -expand 1 -fill x
if {$curl == ""} {
  set use.curl 0
  .use_curl configure -state disabled
  tooltip .use_curl [mc c30t]
}

# Use GraphicsMagick or ImageMagick for composition

radiobutton .use_gmagick -text [mc c32 GraphicsMagick] -anchor w \
	-variable use.magick -value "gm"
radiobutton .use_imagick -text [mc c32 ImageMagick] -anchor w \
	-variable use.magick -value "magick"
pack .use_gmagick .use_imagick -in .r -expand 1 -fill x

if {$gm == ""} {
  set use.magick "magick"
  .use_gmagick configure -state disabled
  tooltip .use_gmagick [mc c32t GraphicsMagick]
}
if {$magick == ""} {
  set use.magick "gm"
  .use_imagick configure -state disabled
  tooltip .use_imagick [mc c32t ImageMagick]
}

# Compose tiles

checkbutton .tiles_compose -text [mc c33] \
	-variable tiles.compose -command tiles_compose_onoff
pack .tiles_compose -in .r -expand 1 -fill x

# Container for "Compose tiles" dependent widgets

frame .tiles_compose_onoff
proc tiles_compose_onoff {} {
  if {${::tiles.compose}} {
    pack .tiles_compose_onoff -in .r -after .tiles_compose \
	-expand 1 -fill x
  } else {
    pack forget .tiles_compose_onoff
  }
}
tiles_compose_onoff

# Keep tiles after composing to image

checkbutton .tiles_keep -text [mc c34] -variable tiles.keep
pack .tiles_keep -in .tiles_compose_onoff -expand 1 -fill x

# Show composed image

checkbutton .show_composed -text [mc c35] -variable composed.show
pack .show_composed -in .tiles_compose_onoff -expand 1 -fill x

# Action buttons

frame .buttons
button .buttons.continue -text [mc b01] -width 12 -command {set action 1}
button .buttons.cancel -text [mc b02] -width 12 -command {set action 0}
pack .buttons.continue .buttons.cancel -side left
pack .buttons -after .r -anchor n -ipady 5

proc busy_state {state} {
  set busy {.l .r .buttons.continue .overlays .shading .effects .server}
  if {$state} {
    foreach item $busy {tk busy hold $item}
    .buttons.continue configure -relief sunken
    .buttons.cancel configure -text [mc b03] -command cancel_render_job
  } else {
    .buttons.continue configure -relief raised
    .buttons.cancel configure -text [mc b02] -command {set action 0}
    foreach item $busy {tk busy forget $item}
  }
  update idletasks
}

# Show/hide output console window (show with saved geometry)

checkbutton .output -text [mc c99] \
	-variable console.show -command show_hide_console

proc show_hide_console {} {
  if {${::console.show}} {
    .console.txt see end
    if {${::console.geometry} == ""} {
      wm deiconify .console
    } else {
      lassign ${::console.geometry} x y cols rows
      wm positionfrom .console program
      wm geometry .console ${cols}x${rows}+$x+$y
      wm deiconify .console
      wm geometry .console +$x+$y
    }
    if {[winfo ismapped .]} {raise . .console}
  } else {
    wm withdraw .console
  }
}

if {$console != -1} {
  pack .output -after .buttons -anchor n -expand 1 -fill x
  show_hide_console

  wm protocol .console WM_DELETE_WINDOW ".output invoke"
  # Map/Unmap events are generated by Windows only!
  bind .console <Unmap> {if {"%W" == [winfo toplevel "%W"]} {.output deselect}}
  bind .console <Map>   {if {"%W" == [winfo toplevel "%W"]} {.output   select}}
}

# Filler down to bottom right

proc filler_width_right {} {
  set width 0
  foreach item {.use_curl .use_gmagick .use_imagick \
	.tiles_compose .tiles_keep .show_composed} {
    set width [expr max($width,[winfo reqwidth $item])]
  }
  return $width
}

frame .fill_r -width [filler_width_right]
pack .fill_r -in .r -fill y

# --- End of main window right column

# Increase/decrease font size

proc incr_font_size {incr} {
  set size [font configure TkDefaultFont -size]
  if {$size < 0} {set size [expr round(-$size/[tk scaling])]}
  incr size $incr
  if {$size < 5 || $size > 20} {return}
  foreach item {TkDefaultFont TkTextFont TkFixedFont title_font} {
    font configure $item -size $size
  }
  foreach item {.renderer_values .themes_values .styles_values \
	.xyrange_values .shading.algorithm_values \
	.server.engine_values .server.interface_values} {
    catch "$item current [$item current]"
  }
  set width [expr 6+$size]
  foreach item {.effects.user_scale .effects.text_scale .effects.symbol_scale \
	.effects.gamma_scale .effects.contrast_scale .zoom_scale} {
    catch "$item configure -width $width"
  }
  update idletasks
  .fill_r configure -width [filler_width_right]
}

# Show main window (at saved position)

update
wm positionfrom . program
if {[info exists window.geometry]} {
  lassign ${window.geometry} x y width height
  # Adjust horizontal position if necessary
  set x [expr max($x,[winfo vrootx .])]
  set x [expr min($x,[winfo vrootx .]+[winfo vrootwidth .]-$width)]
  wm geometry . +$x+$y
}
wm deiconify .

# Check selection for completeness

proc selection_ok {} {
  if {[llength [.maps_values curselection]] == 0} {
    error_message [mc e41] return
    return 0
  }
  set count 0	
  foreach item {xmin xmax ymin ymax} {
    if {[set ::tiles.$item] == ""} {incr count}
  }
  if {$count} {
    error_message [mc e42 $count] return
    return 0
  }
  if {(${::tiles.xmin} > ${::tiles.xmax}) || \
      (${::tiles.ymin} > ${::tiles.ymax})} {
    error_message [mc e43] return
    return 0
  }
  if {![file writable ${::tiles.folder}]} {
    error_message [mc e44 ${::tiles.folder}] return
    return 0
  }
  if {${::shading.onoff} && ![file isdirectory ${::dem.folder}]} {
    error_message [mc e45] return
    return 0
  }
  return 1
}

# Process start

proc process_start {command process} {

  set rc [catch {open "| $command 2>@1" r} result]
  if {$rc} {
    error_message "$result" return
    return
  }

  namespace eval $process {}
  namespace upvar $process fd fd pid pid exe exe
  set ${process}::command $command
  set ${process}::cr ""

  set fd $result
  fconfigure $fd -blocking 0 -buffering line

  set pid [pid $fd]
  set exe [file tail [lindex $command 0]]
  puti "[mc m51 $pid $exe]"

  append mark \$${process}::cr {\[} [string toupper $process] {\]}

  fileevent $fd readable "
	while {\[gets $fd line\] >= 0} {puts \"$mark \$line\"};
	if {\[eof $fd\]} {
	  close $fd; namespace delete $process;
	  puti \[mc m52 $pid $exe\];
	  set $process.eof 1;
	}"

}

# Process kill

proc process_kill {process} {

  if {![namespace exists $process]} {return}
  namespace upvar $process fd fd pid pid

  fileevent $fd readable [regsub {m52} [fileevent $fd readable] {m53}]

  if {$::tcl_platform(os) == "Windows NT"} {
    catch {exec TASKKILL /F /PID $pid}
  } elseif {$::tcl_platform(os) == "Linux"} {
    catch {exec kill -SIGTERM $pid}
  }

}

# Check if process is running

proc process_running {process} {
  return [namespace exists $process]
}

# Mapsforge tile server start

proc srv_start {srv} {

  set shading ${::shading.onoff}
  set name [set ::tms_name_$srv]
  set port [set ::tcp.port]

  if {$srv == "srv"} {
    if {${::shading.layer} == "asmap"} {set shading 0}
    append name " Tile Server \[SRV\]"
  } elseif {$srv == "ovl"} {
    if {!${::shading.onoff}} {return}
    if {${::shading.layer} == "onmap"} {return}
    append name " Overlay Server \[OVL\]"
  }

  # Server's TCP port already or still (after kill) in use?
  set count 0
  while {$count < 5} {
    set rc [catch {socket -server {} -myaddr 127.0.0.1 $port} fd]
    if {!$rc} {break}
    incr count
    after 200
  }
  if {$rc} {
    error_message [mc m59 $name $port $fd] return
    return
  }
  close $fd
  update

  lappend command $::java_cmd -Xmx1G -Xms256M -Xmn256M
  if {[info exists ::java_args]} {lappend command {*}$::java_args}

  set engine ${::rendering.engine}
  if {$engine != "(default)"} {
    set engine [file dirname $::server_jar]/$engine
    if {$::java_version <= 8} {
      lappend command -Xbootclasspath/p:$engine
      set engine [regsub {.jar} $engine {-sun-java2d.jar}]
      lappend command -Xbootclasspath/p:$engine
      lappend command -Dsun.java2d.renderer=sun.java2d.marlin.DMarlinRenderingEngine
    } else {
      lappend command --patch-module java.desktop=$engine
    }
  }

# set now [clock format [clock seconds] -format "%Y-%m-%d_%H-%M-%S"]
# lappend command -Xloggc:$::cwd/gc.$now.log -XX:+PrintGCDetails
# lappend command -Dlog4j.debug
# lappend command -Dlog4j.configuration=file:<folder>/log4j.properties

  lappend command -Dsun.java2d.opengl=true
# lappend command -Dsun.java2d.renderer.log=true
  lappend command -Dsun.java2d.renderer.log=false
  lappend command -Dsun.java2d.renderer.useLogger=true
# lappend command -Dsun.java2d.renderer.doStats=true
# lappend command -Dsun.java2d.renderer.doChecks=true
# lappend command -Dsun.java2d.renderer.useThreadLocal=true
  lappend command -Dsun.java2d.renderer.profile=speed
  lappend command -Dsun.java2d.renderer.useRef=hard
  lappend command -Dsun.java2d.renderer.pixelWidth=2048
  lappend command -Dsun.java2d.renderer.pixelHeight=2048
  lappend command -Dsun.java2d.renderer.tileSize_log2=8
  lappend command -Dsun.java2d.renderer.tileWidth_log2=8
  lappend command -Dsun.java2d.renderer.subPixel_log2_X=2
  lappend command -Dsun.java2d.renderer.subPixel_log2_Y=2
  lappend command -Dsun.java2d.renderer.useFastMath=true
  lappend command -Dsun.java2d.render.bufferSize=524288

  lappend command -jar $::server_jar
  lappend command -if ${::tcp.interface} -p ${port}

  if {$srv == "srv"} {
    set map_list [lmap index [.maps_values curselection] \
	{set map $::maps_folder/[.maps_values get $index]}]
    lappend command -m [join $map_list ","]
    if {${::maps.world} == 1} {lappend command -wm}
    set theme [.themes_values get]
    if {$theme != "(default)"} {
      set theme_file "$::themes_folder/$theme"
      lappend command -t $theme_file
      if {[winfo manager .styles] != ""} {
	lassign [get_selected_style_overlays] style_id overlay_ids
	lappend command -s $style_id
	lappend command -o $overlay_ids
      }
    }
    set language [.lang_value get]
    if {$language != ""} {lappend command -l $language}
    set renderer [.renderer_values get]
    lappend command -r $renderer

    lappend command -gc ${::maps.gamma}
    lappend command -cs ${::maps.contrast}

    lappend command -sft ${::text.scale}
    lappend command -sfs ${::symbol.scale}
    lappend command -sfu ${::user.scale}
  } elseif {$srv == "ovl"} {
    lappend command -m ""
  }

  if {$shading} {
    set algorithm ${::shading.algorithm}
    if {$algorithm == "simple"} {
      set linearity ${::shading.simple.linearity}
      set scale ${::shading.simple.scale}
      if {$linearity == ""} {set linearity 0.1}
      if {$scale == ""} {set scale 0.666}
      lappend command -hs "$algorithm\($linearity,$scale\)"
    } else {
      set angle ${::shading.diffuselight.angle}
      if {$angle == ""} {set angle 50.}
      lappend command -hs "$algorithm\($angle\)"
    }
    set magnitude ${::shading.magnitude}
    if {$magnitude == ""} {set magnitude 1.}
    lappend command -hm "$magnitude"
    lappend command -d ${::dem.folder}
  }

  lappend command -mxq ${::tcp.maxconn}
  lappend command -mxt ${::threads.max}
  lappend command -mit ${::threads.min}

  if {$::server_version >= 1900} {lappend command -term}

  puti "[mc m54 $name] ..."
  puts "[get_shell_command $command]"

  process_start $command $srv

  # Wait until port becomes ready to accept connections or server aborts
  # Send dummy render request and wait for rendering initialization

  set url "http://127.0.0.1:${port}/0/0/0.png"
  while {[process_running $srv]} {
    if {[catch {::http::geturl $url} token]} {after 10; continue}
    set size [::http::size $token]
    ::http::cleanup $token
    if {$size} {break}
  }
  after 20
  update

  if {![process_running $srv]} {error_message [mc m55 $name] return; return}
  set ${srv}::port $port
  set ${srv}::cr "\r"

}

# Mapsforge tile server stop

proc srv_stop {srv} {

  if {![namespace exists $srv]} {return}

  if {$::server_version < 1900} {
    process_kill $srv
  } else {
    namespace upvar $srv port port
    set url "http://127.0.0.1:${port}/terminate"
    if {![catch {::http::geturl $url} token]} {
      if {[::http::status $token] == "eof"} {set code 200} \
      else {set code [::http::ncode $token]}
      if {$code != 200} {process_kill $srv}
      ::http::cleanup $token
    }
  }
  if {![info exists ::$srv.eof]} {vwait $srv.eof}
  unset ::$srv.eof

}

# Cancel render job

proc cancel_render_job {} {

  set ::cancel 1
  if {![info exists batch::pid]} {return}
  set pid $batch::pid
  if {$::tcl_platform(os) == "Windows NT"} {
    catch {exec TASKKILL /F /PID $pid}
  } elseif {$::tcl_platform(os) == "Linux"} {
    catch {exec kill -SIGTERM $pid}
  }

}

# Run render job

proc geturl_handler {file socket token} {

  upvar #0 $token state
  set size 0
  if {[string first "image/" [set state(type)]] == 0} {
    set fd [open $file w+]
    fconfigure $fd -translation binary -buffering none
    while {![eof $socket]} {incr size [chan copy $socket $fd]}
    close $fd
  } else {
    while {![eof $socket]} {incr size [string length [read -nonewline $socket]]}
  }
  return $size

}

# Download tiles with "curl"

proc download_with_curl {} {uplevel 1 {

  set url $url_pattern
  regsub "\\$?{x}" $url "\[$xmin-$xmax\]" url
  regsub "\\$?{y}" $url "\[$ymin-$ymax\]" url
  regsub "\\$?{z}" $url "$zoom" url

  # Download tiles from server

  set curl_args {}
  lappend curl_args -qsvk --http1.1
  lappend curl_args --retry 0
  lappend curl_args --fail-early
  if {$::curl_version >= 7066} \
	{lappend curl_args --parallel --parallel-max 4}
  lappend curl_args -o ${prefix}$zoom.#1.#2.$suffix

  set cmd [list $::curl {*}$curl_args $url]

  set count 0
  set valid 0

  set rc [catch {open "| $cmd 2>@1" r} result]
  if {$rc} {
    error_message "Download $url:\n$result" return
    puts $fdlog [format $logfmt "URL" $url]
    puts $fdlog [format $logfmt "curl error" $result]
    puts $fdlog $logsep
    return 1
  }

  set fd $result
  fconfigure $fd -blocking 0 -buffering line -translation binary
  namespace eval batch {}
  set batch::pid [pid $fd]
  fileevent $fd readable "
	while {\[gets $fd line\] >= 0} {
	  puts $fdlog \[string trimright \$line \\r\];
	  if {\$cancel} {break};
	};
	if {\[eof $fd\] || \$cancel} {
	  set batch::rc \[catch {close $fd} batch::result];
	}"
  vwait batch::rc
  lassign [list $batch::rc $batch::result] rc result
  namespace delete batch
  if {$rc || $::cancel} {return 1}

  # Count successfully downloded files

  set ytile $ymin
  while {$ytile <= $ymax} {
    set xtile $xmin
    while {$xtile <= $xmax} {
      incr count
      set tile ${prefix}$zoom.$xtile.$ytile.$suffix
      if {[file exists $tile]} {incr valid}
      incr xtile
    }
    incr ytile
  }
  return 0

}}

# Download tiles with "http"

proc download_with_http {} {uplevel 1 {

  set count 0
  set valid 0
  set error 0
  set ytile $ymin
  while {$ytile <= $ymax} {
    if {$error} {break}
    set xtile $xmin
    while {$xtile <= $xmax} {
      if {$::cancel} {return 1}
      if {$error} {break}
      set url $url_pattern
      regsub "\\$?{x}" $url $xtile url
      regsub "\\$?{y}" $url $ytile url
      regsub "\\$?{z}" $url $zoom url
      set file $prefix$zoom.$xtile.$ytile.$suffix
      set rc [catch "::http::geturl $url -keepalive 1 \
	-binary 1 -handler {geturl_handler $file}" result]
      if {$rc} {
	error_message "Download $url:\n$result" return
	puts $fdlog [format $logfmt "URL" $url]
	puts $fdlog [format $logfmt "HTTP error" $result]
	puts $fdlog $logsep
	return 1
      }
      set token $result
      incr count

      puts $fdlog [format $logfmt "URL" $url]
      puts $fdlog [format $logfmt "HTTP transaction" [::http::status $token]]
      puts $fdlog [format $logfmt "HTTP error" [::http::error $token]]
      puts $fdlog [format $logfmt "HTTP status" [::http::code $token]]
      array set meta [set ${token}(meta)]
      foreach item [lsort [array names meta]] {
	puts $fdlog [format $logfmt $item $meta($item)]
      }
      unset meta
      puts $fdlog $logsep
      flush $fdlog

      set code [::http::ncode $token]
      set size [::http::size $token]
      ::http::cleanup $token
      unset token
      if {($code == 200 || $code == 404) && $size > 0} {
	incr valid
      } else {
	incr error
      }
      incr xtile
    }
    incr ytile
  }
  return 0

}}

proc run_render_job {} {

  set ::cancel 0

  foreach item {xmin xmax ymin ymax} {
    upvar ::tiles.$item $item
  }
  upvar ::zoom.level zoom

  set text "\n[mc m61] ...\n"
  append text "[mc l24]: $zoom\n"
  append text "[mc m63]:\n"
  append text "$xmin \u2264 xtile \u2264 $xmax\n"
  append text "$ymin \u2264 ytile \u2264 $ymax\n"
  append text "[mc m64]:\n"
  append text "${::coord.xmin}° \u2264 [mc m65] \u2264 ${::coord.xmax}°\n"
  append text "${::coord.ymin}° \u2264 [mc m66] \u2264 ${::coord.ymax}°"
  puts "$text"

  set xcount [expr $xmax-$xmin+1]
  set ycount [expr $ymax-$ymin+1]
  set total [expr $xcount*$ycount]

  set text ""
  append text "[mc m67 $xcount "x"],\n"
  append text "[mc m67 $ycount "y"],\n"
  append text "\u2192 [mc m68] = $xcount * $ycount = $total.\n"
  puts "$text"

  # Confirm if more than threshold tiles

  set threshold 100
  if {$total > $threshold} {
    if {[messagebox -parent . -title $::title -icon question -type yesno \
	-default no -message "$text\n[mc m69 $threshold]"] != "yes"} {return}
  }

  # Working in tiles folder

  catch {cd ${::tiles.folder}}
  set folder [pwd]
  puts "[mc m71 $folder]"
  update

  set prefix ${::tiles.prefix}
  if {$prefix != "" && ![regexp {[-.]+$} $prefix]} {append prefix "."}

  set composed $prefix$zoom.$xmin-$xmax.$ymin-$ymax
  file delete -force $composed.png

  # First remove existing tiles

  set tiles {}
  set ytile $ymin
  while {$ytile <= $ymax} {
    set xtile $xmin
    while {$xtile <= $xmax} {
      lappend tiles $prefix$zoom.$xtile.$ytile
      incr xtile
    }
    incr ytile
  }
  file delete -force {*}[lmap tile $tiles {list $tile.png}]

  # Url

  set url_pattern "http://127.0.0.1:${::tcp.port}/{z}/{x}/{y}.png"
  if {$::tile_size != 256} \
    {append url_pattern "?tileRenderSize=${::tile_size}"}

  # Open log file

  set logfile $composed.log
  set logsep [string repeat - 100]
  set logfmt "%-17s : %s"
  set fdlog [open $logfile w]
  fconfigure $fdlog -buffering line

  set rc 0
  set ovlmap [expr ${::shading.onoff} && {${::shading.layer} == "asmap"}]
  foreach srv {"srv" "ovl"} {

    if {$srv == "ovl" && !$ovlmap} {continue}

    if {$srv == "srv"} {set suffix "png"}
    if {$srv == "ovl"} {set suffix "ovl"}

    puts "\n[mc m70 $url_pattern] ...\n"

    puts $fdlog $logsep
    puts $fdlog "Download tiles from URL '$url_pattern' ..."
    puts $fdlog $logsep

    # Start server

    srv_start $srv
    if {![process_running $srv]} {
      set rc 1
      break
    }

    # Download with "curl" or "http"

    set start [clock milliseconds]
    if {${::use.curl}} {
      set rc [download_with_curl]
    } else {
      set rc [download_with_http]
    }
    set stop [clock milliseconds]

    # Stop server

    srv_stop $srv

    if {$::cancel} {break}

    # Report result

    puts "\n[mc m72 $total $valid]"

    # Measure time(s)

    set time [expr $stop-$start]
    puts ""
    puts "[mc m75 $time $valid]"
    if {$valid} {puts "[mc m76 [format "%.1f" [expr $time/(1.*$valid)]]]"}
    puts "... [mc m77]"

    if {$valid == 0} {set rc 1}
    if {$rc} {break}

  }
  close $fdlog

  # Download cancelled or ended abnormally

  if {$rc || $::cancel} {
    file delete -force {*}[lmap tile $tiles {list $tile.png}]
    if {$ovlmap} {file delete -force {*}[lmap tile $tiles {list $tile.ovl}]}
  }

  if {$::cancel} {
    puts "\n[mc m73a]"
    file delete -force $logfile
    return
  } elseif {$rc || $valid != $total} {
    puts "\n[mc m73b $folder/$logfile]"
    cd $::cwd
    return
  } else {
    file delete -force $logfile
  }

  # Start tiles processing

  upvar ::use.magick use_magick
  set exe [set ::$use_magick]

  if {$use_magick == "gm"} {
    set ::env(MAGICK_TMPDIR) $folder
  } elseif {$use_magick == "magick"} {
    set ::env(MAGICK_TEMPORARY_PATH) $folder
  }

  # Batch processing

  proc batch_proc {exe args} {
    lappend cmd $exe {*}$args
    set exe [file tail $exe]
    set rc [catch {open "| $cmd" r} result]
    if {$rc} {return [list $rc $result]}
    set fd $result
    fconfigure $fd -blocking 0 -buffering line
    namespace eval batch {}
    set batch::pid [pid $fd]
    fileevent $fd readable "
	while {\[gets $fd line\] >= 0} {
	  puts \"\\r> $exe \$line\";
	  if {\$cancel} {break};
	};
	if {\[eof $fd\] || \$cancel} {
	  set batch::rc \[catch {close $fd} batch::result];
	}"
    vwait batch::rc
    set return [list $batch::rc $batch::result]
    namespace delete batch
    return $return
  }

  # Fill missing tiles by white tile

  set void [pid].void.png
  if {$use_magick == "gm"} {
    exec $exe convert -size 256x256 xc:white $void
  } elseif {$use_magick == "magick"} {
    exec $exe -size 256x256 canvas:white $void
  }

  while {1} {

  # Compose map tiles and alpha transparent hillshading overlay tiles

  if {$ovlmap} {

  puts "\n[mc m84] ...\n"
  set start [clock milliseconds]

  set fd [file tempfile batch_file]
  if {$use_magick == "magick"} \
	{puts $fd "-format \"%f null: %t.ovl -layers composite %f\\n\""}
  set clean {}
  set ytile $ymin
  while {$ytile <= $ymax} {
    set xtile $xmin
    while {$xtile <= $xmax} {
      set tile $prefix$zoom.$xtile.$ytile
      incr xtile
      set map $tile.png
      set ovl $tile.ovl
      if {![file exists $ovl]} {continue}
      lappend clean $ovl
      if {![file exists $tile.png]} {set map $void}
      if {$use_magick == "gm"} {
	puts $fd "composite $ovl $map $tile.png"
      } elseif {$use_magick == "magick"} {
 	puts $fd "$map null: $ovl -layers composite -identify -write $tile.png -delete 0--1"
      }
    }
    incr ytile
  }
  seek $fd 0
  set mtime [file mtime $batch_file]

  set fderr [file tempfile]
  if {$use_magick == "gm"} {
    lassign [batch_proc $exe batch -stop-on-error on -echo on - \
	<@ $fd 2>@ $fderr] rc result
  } elseif {$use_magick == "magick"} {
    lassign [batch_proc $exe -script - \
	<@ $fd 2>@ $fderr] rc result
  }
  close $fd
  seek $fderr 0
  set data [split [read -nonewline $fderr] \n]
  close $fderr
  file delete -force $batch_file {*}$clean
  set stop [clock milliseconds]

  if {[llength $data]} {
    if {$rc || ([file exists $tile.png] && [file mtime $tile.png] >= $mtime)} {
      puts "> [join $data "\n> "]\n"
    } else {
      set rc 1
      set result "\n [join $data "\n "]\n"
    }
  }

  if {$rc || $::cancel} {
    file delete -force {*}[lmap tile $tiles {list $tile.png}]
  }

  if {$::cancel} {
    puts "[mc m74a $exe]"
    break
  } elseif {$rc} {
    puts "[mc m74b $exe $result]"
    break
  } else {
    set time [expr $stop-$start]
    puts "[mc m85 $time]"
  }

  }

  if {!${::tiles.compose}} {break}

  # Compose tiles to image

  puts "\n[mc m78 $composed.png] ..."

  set start [clock milliseconds]

  set batch_file [pid].tiles.lst
  set fd [open $batch_file w]
  set tiles {}
  set ytile $ymin
  while {$ytile <= $ymax} {
    set xtile $xmin
    while {$xtile <= $xmax} {
      set tile $prefix$zoom.$xtile.$ytile.png
      if {[file exists $tile]} {
	lappend tiles $tile
	puts $fd $tile
      } else {
	puts $fd $void
      }
      incr xtile
    }
    incr ytile
  }
  close $fd

  set args "montage -mode concatenate -tile ${xcount}x${ycount} @$batch_file $composed.png"
  puts "> [file tail $exe] $args"
  set fderr [file tempfile]
  lassign [batch_proc $exe {*}$args 2>@ $fderr] rc result
  seek $fderr 0
  set data [split [read -nonewline $fderr] \n]
  close $fderr
  file delete -force $batch_file
  set stop [clock milliseconds]

  if {[llength $data]} {
    if {$rc || [file exists $composed.png]} {
      puts "> [join $data "\n> "]\n"
    } else {
      set rc 1
      set result "\n [join $data "\n "]\n"
    }
  }


  if {$rc || $::cancel} {
    file delete -force {*}$tiles $composed.png
  }

  if {$::cancel} {
    puts "[mc m74a $exe]"
    break
  } elseif {$rc} {
    puts "[mc m74b $exe $result]"
    break
  } else {
    set time [expr $stop-$start]
    puts "[mc m85 $time]"
    puts "[mc m81 $composed.png]"
  }

  # Delete tiles

  if {!${::tiles.keep}} {
    file delete -force {*}$tiles
    puts "\n[mc m83]"
  }

  break
  }

  # End tiles processing

  file delete -force $void
  cd $::cwd

  if {$rc || $::cancel} {return}
  if {!${::composed.show}} {return}

  # Show composed image by background job

  set file $folder/$composed.png
  if {![file exists $file]} {return}
  if {$::tcl_platform(platform) == "windows"} {
    set script "exec cmd.exe /C START {} \"$file\""
  } elseif {$::tcl_platform(os) == "Linux"} {
    set script "exec nohup xdg-open \"$file\" >/dev/null"
  }
  after 0 "catch {$script}"
  return

}

# Wait for valid selection or finish

while {1} {
  vwait action
  if {$action == 0} {
    if {[winfo manager .styles] != ""} {save_theme_settings}
    foreach item {global shading tiles} {save_${item}_settings}
    exit
  }
  unset action
  if {[selection_ok]} {break}
}

# Run render job

busy_state 1
run_render_job
busy_state 0

# Wait for new selection or finish

update idletasks
if {![info exists action]} {vwait action}

# After changing settings: run render job

while {$action == 1} {
  unset action
  if {[selection_ok]} {
    busy_state 1
    run_render_job
    busy_state 0
  }
  if {![info exists action]} {vwait action}
}
unset action

# Unmap main toplevel window

wm withdraw .

# Save settings to folder ini_folder

foreach item {global shading tiles} {save_${item}_settings}
if {[winfo manager .styles] != ""} {save_theme_settings}

# Wait until output console window was closed

if {[winfo ismapped .console]} {
  puti "[mc m99]"
  wm protocol .console WM_DELETE_WINDOW ""
  bind .console <ButtonRelease-3> "destroy .console"
  tkwait window .console
}

# Done

destroy .
exit
