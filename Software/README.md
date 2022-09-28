<h1>Software</h1>
<p>
This is a collection of programs for my Signetics 2650 microcomputer. Most of these are simple demos or test programs. This library will expand as I keep playing around with the computer.
</p>

<table>
	<tr>
		<th>Name</th>
		<th>Description</th>
	</tr>
	<tr>
		<td>BoardTest</td>
		<td>Simple test program for the 3rd board revision. Implements a simple cat program.</td>
	</tr>
	<tr>
		<td>DivMul</td>
		<td>Various division and multiplication subroutines, plus tests for them.</td>
	</tr>
	<tr>
		<td>EmissionsController</td>
		<td>Smoothsteps between random numbers and sends results out over serial. Meant to control emission strength on my VRChat avatar using an OSC application on my desktop.</td>
	</tr>
	<tr>
		<td>IndirectTest</td>
		<td>Testing indirect addressing mode. Note: not yet updated to work on latest board revision.</td>
	</tr>
	<tr>
		<td>Mandel</td>
		<td>Uses fixed-point numbers to render the mandelbrot fractal. Zoom strength and image coordinates can be changed. Renders a zoomed-in region by default.</td>
	</tr>
	<tr>
		<td>Mul32</td>
		<td>Implementation of 32-bit, 8.24 fixed-point multiplication.</td>
	</tr>
	<tr>
		<td>PrintTest</td>
		<td>Prints a constant string. First program I wrote for the 2650.</td>
	</tr>
	<tr>
		<td>R110</td>
		<td>Implementation of the Rule 110 automata. Also contains a version that runs entirely within the CPU’s registers, requiring no RAM whatsoever.</td>
	</tr>
	<tr>
		<td>MemoryMon</td>
		<td>Lets you inspect, write into, and execute arbitrarily from memory. Enter programs manually through the terminal! Includes a "Hellorld!" program you can try assembling and then typing in.</td>
	</tr>
	<tr>
		<td>Bot</td>
		<td>Discord bot driven by the S2650. Similar command set as MemoryMon.</td>
	</tr>
</table>
