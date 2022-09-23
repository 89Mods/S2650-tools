# Signetics 2650 Assembler and Emulator

This directory contains my assembler and emulator for the Signetics 2650, written in C#. You will need the dotnet framework to run this.

To use the assembler, run:
<code>dotnet run asm program.asm</code>

This will try to assemble the given program, and, if there are no errors, output a file named <code>program.bin</code>
This can then either be run on a real 2650, or in the emulator, by running:

<code>dotnet run emu program.bin</code>
