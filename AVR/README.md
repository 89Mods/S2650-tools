<h1>AtMega32 Software</h1>
<p>
The AtMega32 serves as the in-system ROM programmer and clock generator for the S2650 computer. It can also single-step the clock, and show the current state of the data bus.<br>
You don’t need to be able to compile the .c file, you simply need to flash the .hex file onto an AtMega32, and configure its fuses to accept an external clock signal from the 20MHz crystal.<br>
<br>
Plug a serial-to-UART bridge into the 6-pin header to the right of the AtMega and open a terminal to it at 115200 baud. Press the AVR’s reset button above the IC. Follow the instructions shown in the terminal to start running the 2650. You may need to reset the 2650 after starting the clock.<br>
<br>
However, you may also not connect a UART bride, in which case the AtMega is programmed to automatically start the 2650 at its maximum clock speed. Do this if you don’t need a specific clock speed, and don’t need to program the ROM.<br>
<br>
For instructions on using the in-system ROM programmer, see the "ROMProgrammer" part of the repository.
</p>
