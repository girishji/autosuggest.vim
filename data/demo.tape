# Run this script from autosuggest.vim dir

# VHS documentation
#
# Output:
#   Output <path>.gif               Create a GIF output at the given <path>
#   Output <path>.mp4               Create an MP4 output at the given <path>
#   Output <path>.webm              Create a WebM output at the given <path>
#
# Require:
#   Require <string>                Ensure a program is on the $PATH to proceed
#
# Settings:
#   Set FontSize <number>           Set the font size of the terminal
#   Set FontFamily <string>         Set the font family of the terminal
#   Set Height <number>             Set the height of the terminal
#   Set Width <number>              Set the width of the terminal
#   Set LetterSpacing <float>       Set the font letter spacing (tracking)
#   Set LineHeight <float>          Set the font line height
#   Set LoopOffset <float>%         Set the starting frame offset for the GIF loop
#   Set Theme <json|string>         Set the theme of the terminal
#   Set Padding <number>            Set the padding of the terminal
#   Set Framerate <number>          Set the framerate of the recording
#   Set PlaybackSpeed <float>       Set the playback speed of the recording
#   Set MarginFill <file|#000000>   Set the file or color the margin will be filled with.
#   Set Margin <number>             Set the size of the margin. Has no effect if MarginFill isn't set.
#   Set BorderRadius <number>       Set terminal border radius, in pixels.
#   Set WindowBar <string>          Set window bar type. (one of: Rings, RingsRight, Colorful, ColorfulRight)
#   Set WindowBarSize <number>      Set window bar size, in pixels. Default is 40.
#   Set TypingSpeed <time>          Set the typing speed of the terminal. Default is 50ms.
#
# Sleep:
#   Sleep <time>                    Sleep for a set amount of <time> in seconds
#
# Type:
#   Type[@<time>] "<characters>"    Type <characters> into the terminal with a
#                                   <time> delay between each character
#
# Keys:
#   Escape[@<time>] [number]        Press the Escape key
#   Backspace[@<time>] [number]     Press the Backspace key
#   Delete[@<time>] [number]        Press the Delete key
#   Insert[@<time>] [number]        Press the Insert key
#   Down[@<time>] [number]          Press the Down key
#   Enter[@<time>] [number]         Press the Enter key
#   Space[@<time>] [number]         Press the Space key
#   Tab[@<time>] [number]           Press the Tab key
#   Left[@<time>] [number]          Press the Left Arrow key
#   Right[@<time>] [number]         Press the Right Arrow key
#   Up[@<time>] [number]            Press the Up Arrow key
#   Down[@<time>] [number]          Press the Down Arrow key
#   PageUp[@<time>] [number]        Press the Page Up key
#   PageDown[@<time>] [number]      Press the Page Down key
#   Ctrl+<key>                      Press the Control key + <key> (e.g. Ctrl+C)
#
# Display:
#   Hide                            Hide the subsequent commands from the output
#   Show                            Show the subsequent commands in the output

Output demo.gif

Set Margin 10
Set MarginFill "#674EFF"
Set BorderRadius 10
Set Padding 10

Set TypingSpeed 500ms
Set FontSize 18
Set Width 1000
Set Height 600
Set Shell "zsh"

Type@200ms "vi -n" Sleep 2s Enter
Type@500ms ":e **/" Sleep 2
Ctrl+p Sleep 3 Enter
Type@1ms "gg" Sleep 2
Type "/" Sleep 2
Type "sea" Sleep 2 Tab 2 Sleep 3s Enter
Type "/" Sleep 2
Type "mu" Sleep 2 Tab 1 Sleep 1s
Type "-" Sleep 2 Tab Space Sleep 2 Tab Sleep 2s Enter Sleep 3
Escape # remove highlighting

Type ":e **/a" Sleep 2 Tab 3 Sleep 1s Enter
Type ":e **/a" Sleep 2 Tab 4 Sleep 1s Enter
Type ":buf" Sleep 1 Tab 2 Sleep 2s Space Sleep 2s Tab Sleep 3s Enter

Type ":h getp" Sleep 2 Tab 2 Sleep 1s Enter Sleep 3
Type ":bd" Sleep 2s Enter
Type ":hi spel" Sleep 2s Tab 3 Enter Sleep 3 Enter

Type ":call g:A" Sleep 2 Tab 2
Type "#{search: #{pum: v:false}})" Sleep 2 Enter
Type "/" Sleep 2
Type "auto" Sleep 2 Tab 3 Sleep 3s Enter

Type@300ms ":That's all!" Sleep 1
Ctrl+u
Type@200ms ":qa" Enter
Sleep 2
