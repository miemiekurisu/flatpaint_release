#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Assembling fpcolor
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target arm64-apple-macosx11.0.0 -o /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpcolor.o  -x assembler /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpcolor.s
if [ $? != 0 ]; then DoExitAsm fpcolor; fi
rm /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpcolor.s
echo Assembling fpselection
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target arm64-apple-macosx11.0.0 -o /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpselection.o  -x assembler /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpselection.s
if [ $? != 0 ]; then DoExitAsm fpselection; fi
rm /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpselection.s
echo Assembling fpsurface
/Library/Developer/CommandLineTools/usr/bin/clang -x assembler -c -target arm64-apple-macosx11.0.0 -o /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpsurface.o  -x assembler /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpsurface.s
if [ $? != 0 ]; then DoExitAsm fpsurface; fi
rm /Users/kurisu/Documents/workspace.nosync/project/flatpaint/src/core/fpsurface.s
