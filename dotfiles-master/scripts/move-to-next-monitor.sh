#!/bin/sh
#
# Move the current window to the next monitor.
#
# Also works only on one X screen (which is the most common case).
#
# Source https://github.com/jc00ke/move-to-next-monitor
#
# Props to
# http://icyrock.com/blog/2012/05/xubuntu-moving-windows-between-monitors/
#
# Unfortunately, both "xdotool getwindowgeometry --shell $window_id" and
# checking "-geometry" of "xwininfo -id $window_id" are not sufficient, as
# the first command does not respect panel/decoration offsets and the second
# will sometimes give a "-0-0" geometry. This is why we resort to "xwininfo".

screen_width=`xdpyinfo | awk '/dimensions:/ { print $2; exit }' | cut -d"x" -f1`
screen_height=`xdpyinfo | awk '/dimensions:/ { print $2; exit }' | cut -d"x" -f2`
display_width=`xdotool getdisplaygeometry | cut -d" " -f1`
display_height=`xdotool getdisplaygeometry | cut -d" " -f2`
window_id=`xdotool getactivewindow`

# Remember if it was maximized.
window_horz_maxed=`xprop -id $window_id _NET_WM_STATE | grep '_NET_WM_STATE_MAXIMIZED_HORZ'`
window_vert_maxed=`xprop -id $window_id _NET_WM_STATE | grep '_NET_WM_STATE_MAXIMIZED_VERT'`

# Un-maximize current window so that we can move it
wmctrl -ir $window_id -b remove,maximized_vert,maximized_horz

# Read window position
x=`xwininfo -id $window_id | awk '/Absolute upper-left X:/ { print $4 }'`
y=`xwininfo -id $window_id | awk '/Absolute upper-left Y:/ { print $4 }'`

# Subtract any offsets caused by panels or window decorations
x_offset=`xwininfo -id $window_id | awk '/Relative upper-left X:/ { print $4 }'`
y_offset=`xwininfo -id $window_id | awk '/Relative upper-left Y:/ { print $4 }'`
x=`expr $x - $x_offset`
y=`expr $y - $y_offset`

# Compute new X position
new_x=`expr $x + $display_width`
# Compute new Y position
new_y=`expr $y + $display_height`

# If we would move off the right-most monitor, we set it to the left one.
# We also respect the window's width here: moving a window off more than half its width won't happen.
width=`xdotool getwindowgeometry $window_id | awk '/Geometry:/ { print $2 }'|cut -d"x" -f1`
if [ `expr $new_x + $width / 2` -gt $screen_width ]; then
  new_x=`expr $new_x - $screen_width`
fi

height=`xdotool getwindowgeometry $window_id | awk '/Geometry:/ { print $2 }'|cut -d"x" -f2`
if [ `expr $new_y + $height / 2` -gt $screen_height ]; then
  new_y=`expr $new_y - $screen_height`
fi

# Don't move off the left side.
if [ $new_x -lt 0 ]; then
  new_x=0
fi

# Don't move off the bottom
if [ $new_y -lt 0 ]; then
  new_y=0
fi

# Move the window
xdotool windowmove $window_id $new_x $new_y

# Maximize window again, if it was before
if [ -n "${window_horz_maxed}" -a -n "${window_vert_maxed}" ]; then
  wmctrl -ir $window_id -b add,maximized_vert,maximized_horz
elif [ -n  "${window_horz_maxed}" ]; then
  wmctrl -ir $window_id -b add,maximized_horz
elif [ -n  "${window_vert_maxed}" ]; then
  wmctrl -ir $window_id -b add,maximized_vert
fi
