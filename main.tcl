#!/bin/sh
# the next line restarts using wish\
exec wish "$0" "$@" 

if {![info exists vTcl(sourcing)]} {

    # Provoke name search
    catch {package require bogus-package-name}
    set packageNames [package names]

    package require BWidget
    switch $tcl_platform(platform) {
	windows {
	}
	default {
	    option add *ScrolledWindow.size 14
	}
    }
    
    package require Tk
    switch $tcl_platform(platform) {
	windows {
            option add *Button.padY 0
	}
	default {
            option add *Scrollbar.width 10
            option add *Scrollbar.highlightThickness 0
            option add *Scrollbar.elementBorderWidth 2
            option add *Scrollbar.borderWidth 2
	}
    }
    
}

#############################################################################
# Visual Tcl v1.60 Project
#


#################################
# VTCL LIBRARY PROCEDURES
#

if {![info exists vTcl(sourcing)]} {
#############################################################################
## Library Procedure:  Window

proc ::Window {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global vTcl
    foreach {cmd name newname} [lrange $args 0 2] {}
    set rest    [lrange $args 3 end]
    if {$name == "" || $cmd == ""} { return }
    if {$newname == ""} { set newname $name }
    if {$name == "."} { wm withdraw $name; return }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists} {
                wm deiconify $newname
            } elseif {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[winfo exists $newname] && [wm state $newname] == "normal"} {
                vTcl:FireEvent $newname <<Show>>
            }
        }
        hide    {
            if {$exists} {
                wm withdraw $newname
                vTcl:FireEvent $newname <<Hide>>
                return}
        }
        iconify { if $exists {wm iconify $newname; return} }
        destroy { if $exists {destroy $newname; return} }
    }
}
#############################################################################
## Library Procedure:  vTcl:DefineAlias

proc ::vTcl:DefineAlias {target alias widgetProc top_or_alias cmdalias} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global widget
    set widget($alias) $target
    set widget(rev,$target) $alias
    if {$cmdalias} {
        interp alias {} $alias {} $widgetProc $target
    }
    if {$top_or_alias != ""} {
        set widget($top_or_alias,$alias) $target
        if {$cmdalias} {
            interp alias {} $top_or_alias.$alias {} $widgetProc $target
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:DoCmdOption

proc ::vTcl:DoCmdOption {target cmd} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## menus are considered toplevel windows
    set parent $target
    while {[winfo class $parent] == "Menu"} {
        set parent [winfo parent $parent]
    }

    regsub -all {\%widget} $cmd $target cmd
    regsub -all {\%top} $cmd [winfo toplevel $parent] cmd

    uplevel #0 [list eval $cmd]
}
#############################################################################
## Library Procedure:  vTcl:FireEvent

proc ::vTcl:FireEvent {target event {params {}}} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## The window may have disappeared
    if {![winfo exists $target]} return
    ## Process each binding tag, looking for the event
    foreach bindtag [bindtags $target] {
        set tag_events [bind $bindtag]
        set stop_processing 0
        foreach tag_event $tag_events {
            if {$tag_event == $event} {
                set bind_code [bind $bindtag $tag_event]
                foreach rep "\{%W $target\} $params" {
                    regsub -all [lindex $rep 0] $bind_code [lindex $rep 1] bind_code
                }
                set result [catch {uplevel #0 $bind_code} errortext]
                if {$result == 3} {
                    ## break exception, stop processing
                    set stop_processing 1
                } elseif {$result != 0} {
                    bgerror $errortext
                }
                break
            }
        }
        if {$stop_processing} {break}
    }
}
#############################################################################
## Library Procedure:  vTcl:Toplevel:WidgetProc

proc ::vTcl:Toplevel:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }
    set command [lindex $args 0]
    set args [lrange $args 1 end]
    switch -- [string tolower $command] {
        "setvar" {
            foreach {varname value} $args {}
            if {$value == ""} {
                return [set ::${w}::${varname}]
            } else {
                return [set ::${w}::${varname} $value]
            }
        }
        "hide" - "show" {
            Window [string tolower $command] $w
        }
        "showmodal" {
            ## modal dialog ends when window is destroyed
            Window show $w; raise $w
            grab $w; tkwait window $w; grab release $w
        }
        "startmodal" {
            ## ends when endmodal called
            Window show $w; raise $w
            set ::${w}::_modal 1
            grab $w; tkwait variable ::${w}::_modal; grab release $w
        }
        "endmodal" {
            ## ends modal dialog started with startmodal, argument is var name
            set ::${w}::_modal 0
            Window hide $w
        }
        default {
            uplevel $w $command $args
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:WidgetProc

proc ::vTcl:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }

    set command [lindex $args 0]
    set args [lrange $args 1 end]
    uplevel $w $command $args
}
#############################################################################
## Library Procedure:  vTcl:toplevel

proc ::vTcl:toplevel {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    uplevel #0 eval toplevel $args
    set target [lindex $args 0]
    namespace eval ::$target {set _modal 0}
}
}


if {[info exists vTcl(sourcing)]} {

proc vTcl:project:info {} {
    set base .top47
    namespace eval ::widgets::$base {
        set set,origin 1
        set set,size 1
        set runvisible 1
    }
    namespace eval ::widgets::$base.can68 {
        array set save {-borderwidth 1 -closeenough 1 -height 1 -insertbackground 1 -relief 1 -selectbackground 1 -selectforeground 1 -width 1}
    }
    namespace eval ::widgets::$base.but61 {
        array set save {-command 1 -relief 1 -text 1}
    }
    namespace eval ::widgets::$base.but62 {
        array set save {-command 1 -relief 1 -text 1}
    }
    namespace eval ::widgets::$base.but63 {
        array set save {-command 1 -relief 1 -text 1}
    }
    namespace eval ::widgets_bindings {
        set tagslist _TopLevel
    }
    namespace eval ::vTcl::modules::main {
        set procs {
            init
            main
            Display
            Test
            ChooseCol
            SaveState
            SaveFile
            GuiType
        }
        set compounds {
        }
        set projectType single
    }
}
}

#################################
# USER DEFINED PROCEDURES
#
#############################################################################
## Procedure:  main

proc ::main {argc argv} {
global color
global env
set ::progDir "$env(PWD)"
set color "NONE"
set ImgDir "$::progDir/Images"
set ComBox0 ".top47.can68.com83"
set ComBox1 ".top47.can68.com84"
set ComBox2 ".top47.can68.com66"
set Can0 ".top47.can68.can60"
set ::guifg "NONE"
set ::guibg "NONE"

file delete $::progDir/TestCopy.tcl
file copy $::progDir/main.tcl $::progDir/TestCopy.tcl
set pic [image create photo ph0 -file $ImgDir/Start.ppm]
$Can0 create image 69 47 -image $pic

$ComBox0 configure -text "Comment"
$ComBox1 configure -text "NONE"
$ComBox2 configure -text "guifg"
}
#############################################################################
## Procedure:  Display

proc ::Display {} {
global widget
set ImgDir "$::progDir/Images/"
set ComBox ".top47.can68.com83"
set Can ".top47.can68.can60"
set CurText [$ComBox cget -text]

if [file exist $ImgDir/$CurText.ppm] {
    set img [image create photo $CurText -file $ImgDir/$CurText.ppm]
    $Can create image 69 47 -image $img
} else {
    set dum [image create photo Dummy -file $ImgDir/Dummy.ppm]
    $Can create image 69 47 -image $dum
} 
}
#############################################################################
## Procedure:  Test

proc ::Test {Aspect GuiType GuiFB GuiBG} {
global widget
global color
global env

while {![string match [exec gvim --serverlist] "HIVIM"]} {
    exec gvim --servername HiVim --remote-silent $::progDir/TestCopy.tcl &
    after 1000
}
exec gvim --servername HiVim --remote-send ":hi $Aspect guifg=$GuiFB guibg=$GuiBG gui=$GuiType<CR>"
return "hi $Aspect guifg=$GuiFB guibg=$GuiBG gui=$GuiType"
}
#############################################################################
## Procedure:  ChooseCol

proc ::ChooseCol {} {
global widget
global color

set color [tk_chooseColor]
}
#############################################################################
## Procedure:  SaveState

proc ::SaveState {} {
set ComBox0 ".top47.can68.com83"
set ComBox1 ".top47.can68.com84"
set ComBox2 ".top47.can68.com66"
GuiType

set ::arr([$ComBox0 cget -text]) [Test [$ComBox0 cget -text] [$ComBox1 cget -text] $::guifg $::guibg]
}
#############################################################################
## Procedure:  SaveFile

proc ::SaveFile {} {
global widget
global env

set User $env(USER)
set Date [clock format [clock sec] -format "%B %d, %Y"]

##Vim color scheme file header...
set header "\" Vim syntax file
\" Language: C
\" Maintainer: $User
\" Last Change: $Date
\" Remark:
if exists(\"b:current_syntax\")
     finish
endif"

set saveinfo [tk_getSaveFile -initialdir $env(HOME) -title "Save..." -initialfile "*.vim"] 
set filepointer [open $saveinfo w]
puts $filepointer $header
foreach index [array names ::arr] {
    puts $filepointer $::arr($index)
} 
close $filepointer
}
#############################################################################
## Procedure:  GuiType

proc ::GuiType {} {
global widget
global color
set ComBox2 ".top47.can68.com66"

if {[string match [$ComBox2 cget -text] "guifg"]} {
    set ::guifg $color
} else {
    set ::guibg $color
}
 
}

#############################################################################
## Initialization Procedure:  init

proc ::init {argc argv} {

}

init $argc $argv

#################################
# VTCL GENERATED GUI PROCEDURES
#

proc vTclWindow. {base} {
    if {$base == ""} {
        set base .
    }
    ###################
    # CREATING WIDGETS
    ###################
    wm focusmodel $top passive
    wm geometry $top 1x1+0+0; update
    wm maxsize $top 2033 738
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm withdraw $top
    wm title $top "vtcl.tcl"
    bindtags $top "$top Vtcl.tcl all"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    ###################
    # SETTING GEOMETRY
    ###################

    vTcl:FireEvent $base <<Ready>>
}

proc vTclWindow.top47 {base} {
    if {$base == ""} {
        set base .top47
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel \
        -highlightcolor black 
    wm focusmodel $top passive
    wm geometry $top 358x166+259+344; update
    wm maxsize $top 1351 738
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm deiconify $top
    wm title $top "HiVim"
    vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    canvas $top.can68 \
        -borderwidth 2 -closeenough 1.0 -height 265 -insertbackground black \
        -relief groove -selectbackground #c4c4c4 -selectforeground black \
        -width 387 
    vTcl:DefineAlias "$top.can68" "Canvas1" vTcl:WidgetProc "Toplevel1" 1
    canvas $top.can68.can60 \
        -borderwidth 2 -closeenough 1.0 -height 271 -highlightcolor black \
        -insertbackground black -relief groove -selectbackground #c4c4c4 \
        -selectforeground black -width 387 
    vTcl:DefineAlias "$top.can68.can60" "Canvas2" vTcl:WidgetProc "Toplevel1" 1
    button $top.can68.but66 \
        -activebackground #f9f9f9 -activeforeground black -command ChooseCol \
        -foreground black -highlightcolor black -relief groove \
        -text {Color  } 
    vTcl:DefineAlias "$top.can68.but66" "Button4" vTcl:WidgetProc "Toplevel1" 1
    ComboBox $top.can68.com83 \
        -exportselection 0 -font {Helvetica -12 bold} -foreground black \
        -highlightcolor black -insertbackground black -justify center \
        -modifycmd Display -relief groove -selectbackground #d9d9d9 \
        -selectforeground black -takefocus 1 -text Comment \
        -values {Comment Constant Cursor CursorIM CursorColumn CursorLine Directory DiffAdd DiffChange DiffDelete DiffText ErrorMsg VertSplit Folded FoldedColumn SignColumn Identifier IncSearch  LineNr MatchParen ModeMsg MoreMsg NonText Normal Pmenu PmenuSel PmenuSbar PmenuThumb Question Search SpecialKey SpellBad SpellCap SpellLocal SpellRare Statement StatusLine StatusLineNC TabLine TabLineFill TabLineSel Title Visual VisualNOS WarningMsg WildMenu} 
    vTcl:DefineAlias "$top.can68.com83" "ComboBox1" vTcl:WidgetProc "Toplevel1" 1
    bindtags $top.can68.com83 "$top.can68.com83 BwComboBox $top all"
    ComboBox $top.can68.com84 \
        -cursor left_ptr -disabledforeground #d9d9d9 -editable 0 \
        -exportselection 0 -font {Helvetic -12 bold} -foreground black \
        -highlightcolor black -insertbackground black -justify center \
        -relief groove -selectbackground #d9d9d9 -selectforeground black \
        -takefocus 1 -text NONE \
        -values {bold underline undercurl reverse italic standout NONE} 
    vTcl:DefineAlias "$top.can68.com84" "ComboBox2" vTcl:WidgetProc "Toplevel1" 1
    bindtags $top.can68.com84 "$top.can68.com84 BwComboBox $top all"
    ComboBox $top.can68.com66 \
        -cursor left_ptr -disabledforeground #d9d9d9 -editable 0 \
        -exportselection 0 -font {Helvetica -12 bold} -foreground black \
        -highlightcolor black -insertbackground black -justify center \
        -modifycmd GuiType -relief groove -selectbackground #d9d9d9 \
        -selectforeground black -takefocus 1 -text guifg \
        -values {guifg guibg} 
    vTcl:DefineAlias "$top.can68.com66" "ComboBox3" vTcl:WidgetProc "Toplevel1" 1
    bindtags $top.can68.com66 "$top.can68.com66 BwComboBox $top all"
    button $top.but61 \
        -command SaveState -relief groove -text Test 
    vTcl:DefineAlias "$top.but61" "Button1" vTcl:WidgetProc "Toplevel1" 1
    button $top.but62 \
        -command SaveFile -relief groove -text Save 
    vTcl:DefineAlias "$top.but62" "Button2" vTcl:WidgetProc "Toplevel1" 1
    button $top.but63 \
        -command exit -relief groove -text Close 
    vTcl:DefineAlias "$top.but63" "Button3" vTcl:WidgetProc "Toplevel1" 1
    ###################
    # SETTING GEOMETRY
    ###################
    pack $top.can68 \
        -in $top -anchor center -expand 0 -fill none -side top 
    place $top.can68.can60 \
        -in $top.can68 -x 15 -y 15 -width 130 -height 92 -anchor nw \
        -bordermode ignore 
    place $top.can68.but66 \
        -in $top.can68 -x 160 -y 90 -width 181 -height 20 -anchor nw \
        -bordermode ignore 
    place $top.can68.com83 \
        -in $top.can68 -x 160 -y 15 -width 181 -height 20 -anchor nw \
        -bordermode ignore 
    place $top.can68.com84 \
        -in $top.can68 -x 160 -y 40 -width 181 -height 20 -anchor nw \
        -bordermode ignore 
    place $top.can68.com66 \
        -in $top.can68 -x 160 -y 65 -width 181 -height 20 -anchor nw \
        -bordermode ignore 
    place $top.but61 \
        -in $top -x 20 -y 125 -width 95 -height 28 -anchor nw \
        -bordermode ignore 
    place $top.but62 \
        -in $top -x 135 -y 125 -width 95 -height 28 -anchor nw \
        -bordermode ignore 
    place $top.but63 \
        -in $top -x 245 -y 125 -width 95 -height 28 -anchor nw \
        -bordermode ignore 

    vTcl:FireEvent $base <<Ready>>
}

#############################################################################
## Binding tag:  _TopLevel

bind "_TopLevel" <<Create>> {
    if {![info exists _topcount]} {set _topcount 0}; incr _topcount
}
bind "_TopLevel" <<DeleteWindow>> {
    if {[set ::%W::_modal]} {
                vTcl:Toplevel:WidgetProc %W endmodal
            } else {
                destroy %W; if {$_topcount == 0} {exit}
            }
}
bind "_TopLevel" <Destroy> {
    if {[winfo toplevel %W] == "%W"} {incr _topcount -1}
}

Window show .
Window show .top47

main $argc $argv
