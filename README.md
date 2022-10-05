# LEGv8-Simulator
A SwiftUI application for writing, executing, and debugging LEGv8 assembly code with a series of visual tools.

![](screenshot.png)

:warning: This software is community made and may have errors. Use at your own risk.

# Download
Here you can download the [latest release](https://github.com/AdinAck/LEGv8-Simulator/releases/).

# Usage
## Editing text
The top left panel is the Monaco Text Editor from VSCode, it supports all the standard shortcuts and QoL features (even the command pallette).

## Execution
There are three buttons in the top right:
- Assemble - Assemble the code for execution (cmd + b)
- Step - Execute the next instruction (cmd + k)
- Run/Continue - Execute the rest of the instructions (cmd + l)
- Stop - Reset everything, go back to beginning of program (cmd + j)

Below the text editor, there is a "console" displaying a history of instructions executed, the current line of execution, the program counter and line number values for each instruction, and errors if the occur.

# TODO
- support loading data
- Optimize lexer and improve verbosity
- Line by line execution in monaco editor (hard)

## Unimplemented instructions
- LDURSW
- STURW
- LDURH
- STURH
- LDURB
- STURB
- LDXR
- STXR
- BR
- BL

# Known issues 🐞
## iOS
- Monaco Javascript error on start for no reason, has to do with `detectTheme` somehow.
- Plus button in file explorer errors, but "Create document" button works fine...
- 2 back buttons? Only one of them does anything.
- Keyboard does not present itself.

## macOS
- None

## Shared
- It is possible the lexer may mistakenly accept incorrectly formatted instruction arguments as comma separators are treated the same as whitespace.
- InvalidMemoryAddress error may incorrectly display the invalid address. This is a bug with printf so it is impractical for me to resolve it.

# Contributions
If you would like to contribute to the project, please contact me (see my [profile README](https://github.com/AdinAck)).