using System;

namespace Signetics2650 {
    class Tools2650 {
        static void Main(string[] args) {
            if(args.Length < 1) {
                Console.WriteLine("Error: Must specify an action (emu, asm)");
                Environment.Exit(1);
                return;
            }
            if(args[0].ToLower().Equals("emu")) {
                if(args.Length < 2) {
                    Console.WriteLine("Error: Must specify an input file");
                    Environment.Exit(1);
                    return;
                }
                Emu2650.RunEmu(args[1]);
            }else if(args[0].ToLower().Equals("asm")) {
                if(args.Length < 2) {
                    Console.WriteLine("Error: Must specify an input file");
                    Environment.Exit(1);
                    return;
                }
                Asm2650.Assemble(args[1]);
            }else {
                Console.WriteLine("Error: Action must be one of: emu, asm");
                Environment.Exit(1);
                return;
            }
        }
    }
}