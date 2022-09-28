<h1>ROM Programmer</h1>
<p>
This is the software for the in-system ROM programmer of the S2650 computer. However, I strongly recommend you instead install a ZIF socket to hold the ROM, and use a universial ROM programmer instead.<br>

<h3>Usage</h3>
The ROM Programmer needs to be compiled. This only needs to be done once. <code>javac ROMProgrammer.java</code>
Make sure the serial port to the AVR is configured to 115200 baud, then switch the board into "PGM" mode using the on-board switch. Remove the SRAM IC from the board.<br>
Now, you can run that ROM programmer: <code>java ROMProgrammer "path/to/your_binary.bin"</code><br>
The programmer will automatically verify the ROM contents. If no errors pop up, the ROM is now programmed. You can put the SRAM IC back in, and switch the board back into "RUN" mode. It is recommended to power cycle the board now.
</p>
