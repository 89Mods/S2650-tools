import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.file.Files;

public class ROMProgrammer {
	
	public static void main(String[] args) {
		try {
			int capacity = 4096;
			//int capacity = 8192*4;
			//int capacity = 32*1024;
			
			//Runtime.getRuntime().exec("stty -F /dev/ttyUSB0 115200");
			FileInputStream serialIn = new FileInputStream("/dev/ttyUSB0");
			FileOutputStream serialOut = new FileOutputStream("/dev/ttyUSB0");
			
			byte[] romData;
			//romData = new byte[32768];
			//Random rng = new Random();
			//rng.nextBytes(romData);
			//for(int i = 0; i < romData.length; i++) {
				//if(romData[i] < 33) romData[i] = 0;
				//romData[i] = (byte)(0x7A + (i % 2));
			//}
			//File romfile = new File("/home/lucah/a18asm/testa18.dat");
			//File romfile = new File("/media/tholin/Data/EmbeddedProgramming/Z80/mandel/mandel.rom");
			//File romfile = new File("/home/tholin/S2650-Tools/Programs/EmissionsController/emiss.bin");
			File romfile = new File(args[0]);
			if(!romfile.exists()) {
				System.err.println("File not found");
				System.exit(1);
			}
			//File romfile = new File("/home/tholin/VACS/DivMul/test.bin");
			//File romfile = new File("/home/tholin/.wine/drive_c/lcc42/examples/blink2/a.bin");
			//File romfile = new File("./zeroes.bin");
			if(romfile.length() == 0) {
				System.err.println("Error: file is empty.");
				System.exit(1);
			}
			if(romfile.getName().endsWith(".hex")) {
				
			}
			FileInputStream romin = new FileInputStream(romfile);
			romData = new byte[Math.min((int)romfile.length(), capacity)];
			System.out.println(romData.length);
			romin.read(romData);
			romin.close();
			//Arrays.fill(romData, (byte)0b00000010);
			
			while(serialIn.available() > 0) serialIn.read();
			
			serialOut.write('2');
			Thread.sleep(1000);
			
			serialOut.write('p');
			int response = serialIn.read();
			if(response != 'a') {
				System.err.println("Invalid response from programmer. " + Character.toString((char)response));
				System.exit(1);
			}
			//serialOut.write(romData.length & 0xFF);
			//serialOut.write((romData.length >> 8) & 0xFF);
			serialOut.write('A' + (romData.length & 0x0F));
			serialOut.write('A' + ((romData.length >> 4) & 0x0F));
			serialOut.write('A' + ((romData.length >> 8) & 0x0F));
			serialOut.write('A' + ((romData.length >> 12) & 0x0F));
			Thread.sleep(100);
			
			System.out.print("Writing\r\n|");
			for(int i = 0; i < 98; i++) System.out.print("-");
			System.out.println("|");
			int currPercent = 0;
			for(int i = 0; i < romData.length; i++) {
				int percent = (int)((double)i / (double)romData.length * 100.0D);
				if(percent > currPercent) {
					while(percent > currPercent) {
						System.out.print(">");
						currPercent++;
					}
				}
				//if((i + 1) % 10 == 0 || i == 0) System.out.println("Writing " + Integer.toString(i + 1) + "/" + Integer.toString(romData.length));
				//if(i < 4) Thread.sleep(25);
				response = serialIn.read();
				if(response != 'n') {
					System.err.println("Invalid response from programmer. " + Character.toString((char)response));
					System.exit(1);
				}
				serialOut.write(romData[i]);
			}
			for(int i = currPercent; i < 100; i++) {
				System.out.print(">");
			}
			System.out.println("\r\n");
			response = serialIn.read();
			if(response != 'd') {
				System.err.println("Invalid response from programmer. " + Character.toString((char)response));
				if(response == 'n') {
					System.err.println("Trying to recover...");
					while(true) {
						serialOut.write(' ');
						if(serialIn.read() == 'd') break;
					}
				}else System.exit(1);
			}
			
			System.out.print("Verifying\r\n|");
			for(int i = 0; i < 98; i++) System.out.print("-");
			System.out.println("|");
			currPercent = 0;
			int val;
			byte[] readback = new byte[romData.length];
			for(int i = 0; i < romData.length; i++) {
				int percent = (int)((double)i / (double)romData.length * 100.0D);
				if(percent > currPercent) {
					while(percent > currPercent) {
						System.out.print(">");
						currPercent++;
					}
				}
				//if((i + 1) % 10 == 0 || i == 0) System.out.println("Verifying " + Integer.toString(i + 1) + "/" + Integer.toString(romData.length));
				serialOut.write(0x96);
				val = (serialIn.read() & 0xFF) - 48;
				val |= ((serialIn.read() & 0xFF) - 48) * 16;
				readback[i] = (byte)val;
				if((byte)val != romData[i]) {
					System.err.println("Error at address 0x" + Integer.toHexString(i) + ": expected 0x" + Integer.toHexString(romData[i] & 0xFF) + ", got 0x" + Integer.toHexString(val));
				}
			}
			for(int i = currPercent; i < 100; i++) {
				System.out.print(">");
			}
			Files.write(new File("./readback.dat").toPath(), readback);
			System.out.println("\r\nDone.");
			
			serialIn.close();
			serialOut.close();
		}catch(Exception e) {
			System.err.println("Error: ");
			e.printStackTrace();
			System.exit(1);
		}
	}
	
}
