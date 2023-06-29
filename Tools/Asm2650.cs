using System;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace Signetics2650 {
    enum AddressingModes {
        Implicit,
        Zero,
        Immediate,
        Relative,
        Absolute
    }
    struct Instruction {
            public Instruction(uint op, bool br, bool reg, AddressingModes addr) {
                opcode = op;
                isBranch = br;
                needsRegister = reg;
                addrMode = addr;
            }
            public uint opcode { get; }
            public bool isBranch { get; }
            public bool needsRegister { get; }
            public AddressingModes addrMode { get; }
    }
    class Asm2650 {
        private static Dictionary<string, Instruction> cpuInstrs = null;
        private static List<string> unusableOpcodes;
        private static string[] invalidLabelStarts = {"0","1","2","3","4","5","6","7","8","9"};
        private static char[] invalidLabelSymbols = {'-', '+', '*', '/', '>', '<', ',', '\\', '\'', '%'};
        static void FillInstructionTable() {
            cpuInstrs = new Dictionary<string, Instruction>();
            unusableOpcodes = new List<string>();
            cpuInstrs.Add("lodz", new Instruction(0x00, false, true, AddressingModes.Zero));
            cpuInstrs.Add("lodi", new Instruction(0x04, false, true, AddressingModes.Immediate));
            cpuInstrs.Add("lodr", new Instruction(0x08, false, true, AddressingModes.Relative));
            cpuInstrs.Add("loda", new Instruction(0x0C, false, true, AddressingModes.Absolute));
            cpuInstrs.Add("spsu", new Instruction(0x12, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("spsl", new Instruction(0x13, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("retc", new Instruction(0x14, true, false, AddressingModes.Implicit));
            cpuInstrs.Add("bctr", new Instruction(0x18, true, false, AddressingModes.Relative));
            cpuInstrs.Add("bcta", new Instruction(0x1C, true, false, AddressingModes.Absolute));
            cpuInstrs.Add("eorz", new Instruction(0x20, false, true, AddressingModes.Zero));
            cpuInstrs.Add("eori", new Instruction(0x24, false, true, AddressingModes.Immediate));
            cpuInstrs.Add("eorr", new Instruction(0x28, false, true, AddressingModes.Relative));
            cpuInstrs.Add("eora", new Instruction(0x2C, false, true, AddressingModes.Absolute));
            cpuInstrs.Add("redc", new Instruction(0x30, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("rete", new Instruction(0x34, true, false, AddressingModes.Implicit));
            cpuInstrs.Add("bstr", new Instruction(0x38, true, false, AddressingModes.Relative));
            cpuInstrs.Add("bsta", new Instruction(0x3C, true, false, AddressingModes.Absolute));
            cpuInstrs.Add("halt", new Instruction(0x40, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("andz", new Instruction(0x40, false, true, AddressingModes.Zero));
            unusableOpcodes.Add("andz,r0");
            cpuInstrs.Add("andi", new Instruction(0x44, false, true, AddressingModes.Immediate));
            cpuInstrs.Add("andr", new Instruction(0x48, false, true, AddressingModes.Relative));
            cpuInstrs.Add("anda", new Instruction(0x4C, false, true, AddressingModes.Absolute));
            cpuInstrs.Add("rrr",  new Instruction(0x50, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("rede", new Instruction(0x54, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("brnr", new Instruction(0x58, true, true, AddressingModes.Relative));
            cpuInstrs.Add("brna", new Instruction(0x5C, true, true, AddressingModes.Absolute));
            cpuInstrs.Add("iorz", new Instruction(0x60, false, true, AddressingModes.Zero));
            cpuInstrs.Add("iori", new Instruction(0x64, false, true, AddressingModes.Immediate));
            cpuInstrs.Add("iorr", new Instruction(0x68, false, true, AddressingModes.Relative));
            cpuInstrs.Add("iora", new Instruction(0x6C, false, true, AddressingModes.Absolute));
            cpuInstrs.Add("redd", new Instruction(0x70, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("cpsu", new Instruction(0x74, false, false, AddressingModes.Immediate));
            cpuInstrs.Add("cpsl", new Instruction(0x75, false, false, AddressingModes.Immediate));
            cpuInstrs.Add("ppsu", new Instruction(0x76, false, false, AddressingModes.Immediate));
            cpuInstrs.Add("ppsl", new Instruction(0x77, false, false, AddressingModes.Immediate));
            cpuInstrs.Add("bsnr", new Instruction(0x78, true, true, AddressingModes.Relative));
            cpuInstrs.Add("bsna", new Instruction(0x7C, true, true, AddressingModes.Absolute));
            cpuInstrs.Add("addz", new Instruction(0x80, false, true, AddressingModes.Zero));
            cpuInstrs.Add("addi", new Instruction(0x84, false, true, AddressingModes.Immediate));
            cpuInstrs.Add("addr", new Instruction(0x88, false, true, AddressingModes.Relative));
            cpuInstrs.Add("adda", new Instruction(0x8C, false, true, AddressingModes.Absolute));
            cpuInstrs.Add("lpsu", new Instruction(0x92, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("lpsl", new Instruction(0x93, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("dar",  new Instruction(0x94, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("bcfr", new Instruction(0x98, true, false, AddressingModes.Relative));
            cpuInstrs.Add("zbrr", new Instruction(0x9B, true, false, AddressingModes.Relative));
            unusableOpcodes.Add("bcfr,un");
            unusableOpcodes.Add("bcfr,3");
            cpuInstrs.Add("bcfa", new Instruction(0x9C, true, false, AddressingModes.Absolute));
            cpuInstrs.Add("bxa",  new Instruction(0x9F, true, false, AddressingModes.Absolute));
            unusableOpcodes.Add("bcfa,un");
            unusableOpcodes.Add("bcfa,3");
            cpuInstrs.Add("subz", new Instruction(0xA0, false, true, AddressingModes.Zero));
            cpuInstrs.Add("subi", new Instruction(0xA4, false, true, AddressingModes.Immediate));
            cpuInstrs.Add("subr", new Instruction(0xA8, false, true, AddressingModes.Relative));
            cpuInstrs.Add("suba", new Instruction(0xAC, false, true, AddressingModes.Absolute));
            cpuInstrs.Add("wrtc", new Instruction(0xB0, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("tpsu", new Instruction(0xB4, false, false, AddressingModes.Immediate));
            cpuInstrs.Add("tpsl", new Instruction(0xB5, false, false, AddressingModes.Immediate));
            cpuInstrs.Add("bsfr", new Instruction(0xB8, true, false, AddressingModes.Relative));
            unusableOpcodes.Add("bsfr,un");
            unusableOpcodes.Add("bsfr,3");
            cpuInstrs.Add("zsbr", new Instruction(0xBB, true, false, AddressingModes.Relative));
            cpuInstrs.Add("bsfa", new Instruction(0xBC, true, false, AddressingModes.Absolute));
            cpuInstrs.Add("bsxa", new Instruction(0xBF, true, false, AddressingModes.Absolute));
            unusableOpcodes.Add("bsfa,un");
            unusableOpcodes.Add("bsfa,3");
            cpuInstrs.Add("nop",  new Instruction(0xC0, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("strz", new Instruction(0xC0, false, true, AddressingModes.Zero));
            unusableOpcodes.Add("strz,r0");
            cpuInstrs.Add("strr", new Instruction(0xC8, false, true, AddressingModes.Relative));
            cpuInstrs.Add("stra", new Instruction(0xCC, false, true, AddressingModes.Absolute));
            cpuInstrs.Add("rrl",  new Instruction(0xD0, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("wrte", new Instruction(0xD4, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("birr", new Instruction(0xD8, true, true, AddressingModes.Relative));
            cpuInstrs.Add("bira", new Instruction(0xDC, true, true, AddressingModes.Absolute));
            cpuInstrs.Add("comz", new Instruction(0xE0, false, true, AddressingModes.Zero));
            cpuInstrs.Add("comi", new Instruction(0xE4, false, true, AddressingModes.Immediate));
            cpuInstrs.Add("comr", new Instruction(0xE8, false, true, AddressingModes.Relative));
            cpuInstrs.Add("coma", new Instruction(0xEC, false, true, AddressingModes.Absolute));
            cpuInstrs.Add("wrtd", new Instruction(0xF0, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("tmi",  new Instruction(0xF4, false, true, AddressingModes.Implicit));
            cpuInstrs.Add("bdrr", new Instruction(0xF8, true, true, AddressingModes.Relative));
            cpuInstrs.Add("bdra", new Instruction(0xFC, true, true, AddressingModes.Absolute));
            
            //AS2650 only!
            cpuInstrs.Add("mul", new Instruction(0x90, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("xchg", new Instruction(0x91, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("push", new Instruction(0x10, false, false, AddressingModes.Implicit));
            cpuInstrs.Add("pop", new Instruction(0x11, false, false, AddressingModes.Implicit));
        }

        private static bool ParseNum(string s, out uint res) {
            uint temp;
            if(s.StartsWith("0b")) {
                s = s.Substring(2);
                temp = 0;
                for(int i = 0; i < s.Length; i++) {
                    temp <<= 1;
                    char c = s[i];
                    if(c == '1') temp += 1;
                    else if(c != '0') {
                        res = 0;
                        return false;
                    }
                }
                res = temp;
                return true;
            }else if(s.StartsWith("0x")) {
                s = s.Substring(2);
                bool a = uint.TryParse(s, System.Globalization.NumberStyles.HexNumber, null, out temp);
                if(!a) res = 0;
                else res = temp;
                return a;
            }else if(s.StartsWith('\'')) {
                if(s.Length != 3 || s[2] != '\'') {
                    res = 0;
                    return false;
                }
                res = s[1];
                return true;
            }else {
                bool a = uint.TryParse(s, System.Globalization.NumberStyles.None, null, out temp);
                if(!a) res = 0;
                else res = temp;
                return a;
            }
        }

        private static bool ParseInstrArg(string s, Dictionary<string, uint> symbolTable, out uint res) {
            uint temp;
            Regex regex = new Regex(@"[+\-*/%]|>>|<<");
            Match m = regex.Match(s);
            if(!m.Success || s.StartsWith('\'')) {
                if(ParseNum(s, out temp)) {
                    res = temp;
                    return true;
                }
                if(symbolTable.ContainsKey(s)) {
                    res = symbolTable[s];
                    return true;
                }
                res = 0;
                return false;
            }
            MatchCollection ms = regex.Matches(s);
            m = ms[ms.Count - 1];
            string p1 = s.Substring(0, m.Index);
            string p2 = s.Substring(m.Index + m.Length);
            uint val1,val2;
            if(!ParseInstrArg(p1, symbolTable, out val1) || !ParseInstrArg(p2, symbolTable, out val2)) {
                res = 0;
                return false;
            }
            char c = s[m.Index];
            if(c == '+') res = val1 + val2;
            else if(c == '-') {
                if(val2 > val1) {
                    Console.WriteLine("Value underflow");
                    res = 0;
                    return false;
                }
                res = val1 - val2;
            }else if(c == '*') res = val1 * val2;
            else if(c == '/') res = val1 * val2;
            else if(c == '%') res = val1 % val2;
            else if(c == '>') res = val1 >> (int)val2;
            else if(c == '<') res = val1 << (int)val2;
            else {
                res = 0;
                return false;
            }
            return true;
        }

        private static bool ParseInstr(string s, out string enc, out string arg1, out string arg2, out string arg3) {
            int i;
            for(i = 0; i < s.Length; i++) {
                char c = s[i];
                if(c == ',' || c == ' ' || c == '\t') break;
            }
            if(i == s.Length) {
                enc = s;
                arg1 = arg2 = arg3 = null;
                return true;
            }
            enc = s.Substring(0, i);
            if(s[i] == ' ' || s[i] == '\t') {
                arg1 = s.Substring(i + 1);
                arg2 = arg3 = null;
                return !(arg1.Contains(' ') || arg1.Contains('\t') || arg1.Contains(','));
            }
            s = s.Substring(i + 1);
            i = 0;
            for(i = 0; i < s.Length; i++) {
                char c = s[i];
                if(c == ' ' || c == '\t') break;
            }
            if(i == s.Length) {
                arg1 = s;
                arg2 = arg3 = null;
                return true;
            }
            arg1 = s.Substring(0, i);
            s = s.Substring(i + 1);
            if(arg1.Contains(',')) {
                arg2 = arg3 = null;
                return false;
            }
            i = 0;
            for(i = 0; i < s.Length; i++) {
                char c = s[i];
                if(c == ',') break;
            }
            if(i == s.Length) {
                arg2 = s;
                arg3 = null;
                return true;
            }
            arg2 = s.Substring(0, i);
            arg3 = s.Substring(i + 1);
            if(arg2.Contains(' ') || arg2.Contains(' ')) return false;
            return true;
        }

        private static int ParseDB(string s, List<uint> ret) {
            if(s.StartsWith('"')) { //String
                if(!s.EndsWith('"')) return 3;
                for(int i = 1; i < s.Length; i++) {
                    char c = s[i];
                    if(c == '"') break;
                    ret.Add(c);
                }
            }else if(s.StartsWith('\'')) { //Character
                if(s.Length != 3 || s[2] != '\'') return 3;
                ret.Add(s[1]);
            }else if(s.Contains(',')) { //Comma-separated list of numbers
                string[] s2 = s.Split(',');
                for(int i = 0; i < s2.Length; i++) {
                    uint a;
                    if(!ParseNum(s2[i], out a)) return 1;
                    if(a > 255) return 2;
                    ret.Add(a);
                }
            }else { //Single number
                uint a;
                if(!ParseNum(s, out a)) return 1;
                if(a > 255) return 2;
                ret.Add(a);
            }
            return 0;
        }

        public static void Assemble(string source) {
            if(cpuInstrs == null) FillInstructionTable();
            string[] lines = File.ReadAllLines(source);
            uint[] outputData = new uint[8192];
            //Remove comments
            for(int i = 0; i < lines.Length; i++) {
                if(lines[i].IndexOf(';') >= 0) lines[i] = lines[i].Substring(0, lines[i].IndexOf(';'));
                lines[i] = lines[i].TrimEnd();
                lines[i] = Regex.Replace(lines[i], @"\s+", " ");
            }
            Dictionary<string, uint> symbolTable = new Dictionary<string, uint>();
            Console.WriteLine("Pass 1");
            uint ptr = 0;
            for(int i = 0; i < lines.Length; i++) {
                string line = lines[i];
                if(string.IsNullOrEmpty(line)) continue;
                if(line.ToLower().Trim().Equals("end")) break;
                if(line.StartsWith('\t') || line.StartsWith(' ')) {
                    //Instruction
                    line = line.TrimStart();
                    if(line.StartsWith("db ") || line.StartsWith("db\t")) {
                        line = line.Substring(3);
                        List<uint> a = new List<uint>();
                        int res = ParseDB(line, a);
                        if(res == 1) {
                            Console.WriteLine($"Error on line {i + 1}: Not a number.");
                            return;
                        }else if(res == 2) {
                            Console.WriteLine($"Error on line {i + 1}: Value overflow.");
                            return;
                        }else if(res == 3) {
                            Console.WriteLine($"Error on line {i + 1}: Invalid formatting.");
                            return;
                        }
                        ptr += (uint)a.Count;
                        continue;
                    }
                    line = line.ToLower();
                    foreach(string s in unusableOpcodes) {
                        if(line.StartsWith(s)) {
                            Console.WriteLine($"Error on line {i + 1}: Use of nonexistant instruction \"{s}\".");
                            return;
                        }
                    }
                    string instrEnc,arg1,arg2,arg3;
                    if(!ParseInstr(line, out instrEnc, out arg1, out arg2, out arg3)) {
                        Console.WriteLine($"Error on line {i + 1}: Invalid formatting.");
                        return;
                    }
                    Instruction instr;
                    try {
                        instr = cpuInstrs[instrEnc];
                    }catch(Exception) {
                        Console.WriteLine($"Error on line {i + 1}: Unknown instruction \"{instrEnc}\".");
                        return;
                    }
                    uint instrLen = 1;
                    if(instr.addrMode == AddressingModes.Immediate) instrLen += 1;
                    else if(instr.addrMode == AddressingModes.Relative) instrLen += 1;
                    else if(instr.addrMode == AddressingModes.Absolute) instrLen += 2;
                    ptr += instrLen;
                }else {
                    line = line.ToLower();
                    if(line.StartsWith("org")) {
                        line = line.Substring(3);
                        if(line[0] != ' ' && line[0] != '\t') {
                            Console.WriteLine($"Error on line {i + 1}: Invalid formating for org.");
                            return;
                        }
                        line = line.Trim();
                        uint val;
                        if(!ParseNum(line, out val)) {
                            Console.WriteLine($"Error on line {i + 1}: Parse error on org value: not a number.");
                            return;
                        }
                        if(val < ptr) {
                            Console.WriteLine($"Error on line {i + 1}: Can’t go backwards!");
                            return;
                        }
                        ptr = val;
                    }else {
                        //Label or equ
                        string name;
                        uint val;
                        if(line.IndexOf(' ') > 0) {
                            string[] s = line.Split(' ');
                            if(s.Length != 3 || !(s[1].Equals("equ") || s[1].Equals("org"))) {
                                Console.WriteLine($"Error on line {i + 1}: Not an instruction, label or symbol definition.");
                                return;
                            }
                            name = s[0];
                            if(!ParseInstrArg(s[2], symbolTable, out val)) {
                                Console.WriteLine($"Error on line {i + 1}: Parse error on symbol value: not a number.");
                                return;
                            }
                        }else if(line.EndsWith(':')) {
                            line = line.Substring(0, line.Length - 1);
                            if(line.Contains(' ') || line.Contains('\t') || line.Length == 0) {
                                Console.WriteLine($"Error on line {i + 1}: Label name cannot contain spaces or be empty.");
                                return;
                            }
                            name = line;
                            val = ptr;
                        }else {
                            Console.WriteLine($"Error on line {i + 1}: Not an instruction, label or symbol definition.");
                            return;
                        }
                        foreach(char c in invalidLabelSymbols) {
                            if(name.Contains(c)) {
                                Console.WriteLine($"Error on line {i + 1}: Forbidden character '{c}' in label/symbol name.");
                                return;
                            }
                        }
                        foreach(string s in invalidLabelStarts) {
                            if(name.StartsWith(s)) {
                                Console.WriteLine($"Error on line {i + 1}: Forbidden label/symbol name.");
                                return;
                            }
                        }
                        if(symbolTable.ContainsKey(name)) {
                            Console.WriteLine($"Error on line {i + 1}: Redefinition of symbol {name}");
                            return;
                        }
                        symbolTable.Add(name, val);
                    }
                }
            }
            Console.WriteLine("Pass 2");
            ptr = 0;
            for(int i = 0; i < lines.Length; i++) {
                string line = lines[i];
                if(string.IsNullOrEmpty(line)) continue;
                if(line.ToLower().Trim().Equals("end")) break;
                if(line.StartsWith("org")) {
                    line = line.Substring(3);
                    if(line[0] != ' ' && line[0] != '\t') {
                        Console.WriteLine($"Error on line {i + 1}: Invalid formating for org.");
                        return;
                    }
                    line = line.Trim();
                    uint val;
                    if(!ParseNum(line, out val)) {
                        Console.WriteLine($"Error on line {i + 1}: Parse error on org value: not a number.");
                        return;
                    }
                    if(val < ptr) {
                        Console.WriteLine($"Error on line {i + 1}: Can’t go backwards!");
                        return;
                    }
                    ptr = val;
                }else
                if(line.StartsWith('\t') || line.StartsWith(' ')) {
                    //Instruction
                    line = line.TrimStart();
                    if(line.StartsWith("db ") || line.StartsWith("db\t")) {
                        line = line.Substring(3);
                        List<uint> a = new List<uint>();
                        int res = ParseDB(line, a);
                        if(res != 0) {
                            Console.WriteLine($"Error on line {i + 1}: Unexpected error.");
                            return;
                        }
                        for(int j = 0; j < a.Count; j++) {
                            outputData[ptr] = a[j];
                            ptr++;
                        }
                        continue;
                    }
                    line = line.ToLower();
                    string instrEnc,arg1,arg2,arg3;
                    if(!ParseInstr(line, out instrEnc, out arg1, out arg2, out arg3)) {
                        Console.WriteLine($"Error on line {i + 1}: Invalid formatting.");
                        return;
                    }
                    Instruction instr = cpuInstrs[instrEnc];

                    uint finalOpcode = instr.opcode;
                    if(instr.needsRegister) {
                        string s = arg1.Substring(0, 2);
                        if(s.Equals("r0")) finalOpcode += 0;
                        else if(s.Equals("r1")) finalOpcode += 1;
                        else if(s.Equals("r2")) finalOpcode += 2;
                        else if(s.Equals("r3")) finalOpcode += 3;
                        else {
                            Console.WriteLine($"Error on line {i + 1}: Invalid register name \"{s}\".");
                            return;
                        }
                        arg1 = arg2;
                    }
                    if(instr.isBranch && !instr.needsRegister && !instrEnc.Equals("bsxa") && !instrEnc.Equals("zbsr") && !instrEnc.Equals("bxa") && !instrEnc.Equals("zbrr")) {
                        string s = arg1.Length == 1 ? arg1 : arg1.Substring(0, 2);
                        if(s[0] == '0' && s.Length == 1) finalOpcode += 0;
                        else if(s[0] == '1' && s.Length == 1) finalOpcode += 1;
                        else if(s[0] == '2' && s.Length == 1) finalOpcode += 2;
                        else if(s[0] == '3' && s.Length == 1) finalOpcode += 3;
                        else if(s.Equals("eq")) finalOpcode += 0;
                        else if(s.Equals("gt")) finalOpcode += 1;
                        else if(s.Equals("lt")) finalOpcode += 2;
                        else if(s.Equals("un")) finalOpcode += 3;
                        else {
                            Console.WriteLine($"Error on line {i + 1}: Invalid branch condition \"{s}\".");
                            return;
                        }
                        arg1 = arg2;
                    }
                    outputData[ptr] = finalOpcode;
                    ptr++;

                    if((instr.isBranch || instr.addrMode != AddressingModes.Absolute) && arg3 != null) {
                        Console.WriteLine($"Error on line {i + 1}: Too many arguments to non-indexed instruction.");
                        return;
                    }

                    if(instr.isBranch && instr.addrMode == AddressingModes.Relative) {
                        bool indirect = arg1.StartsWith('*');
                        if(indirect) arg1 = arg1.Substring(1);
                        uint argValue;
                        if(!ParseInstrArg(arg1, symbolTable, out argValue)) {
                            Console.WriteLine($"Error on line {i + 1}: Invalid expression \"{arg1}\".");
                            return;
                        }
                        int diff = (int)argValue - (int)ptr - 1;
                        if(diff < -64 || diff > 63) {
                            Console.WriteLine($"Error on line {i + 1}: Destination is too far for a relative jump.");
                            return;
                        }
                        if(diff < 0) {
                            diff = -diff;
                            diff = 64 - diff;
                            diff = 63 + diff + 1;
                        }
                        outputData[ptr] = (uint)(diff | (indirect ? 128 : 0));
                        ptr++;
                    }else if(instr.isBranch && instr.addrMode == AddressingModes.Absolute) {
                        bool indirect = arg1.StartsWith('*');
                        if(indirect) arg1 = arg1.Substring(1);
                        uint argValue;
                        if(!ParseInstrArg(arg1, symbolTable, out argValue)) {
                            Console.WriteLine($"Error on line {i + 1}: Invalid expression \"{arg1}\".");
                            return;
                        }
                        if(argValue > 32767) {
                            Console.WriteLine($"Error on line {i + 1}: Value overflow.");
                            return;
                        }
                        outputData[ptr] = (argValue >> 8) | (uint)(indirect ? 128 : 0);
                        outputData[ptr + 1] = argValue & 255;
                        ptr += 2;
                    }else if(!instr.isBranch && instr.addrMode == AddressingModes.Immediate) {
                        uint argValue;
                        if(!ParseInstrArg(arg1, symbolTable, out argValue)) {
                            Console.WriteLine($"Error on line {i + 1}: Invalid expression \"{arg1}\".");
                            return;
                        }
                        if(argValue > 255) {
                            Console.WriteLine($"Error on line {i + 1}: Value overflow.");
                            return;
                        }
                        outputData[ptr] = argValue;
                        ptr++;
                    }else if(!instr.isBranch && instr.addrMode == AddressingModes.Relative) {
                        bool indirect = arg1.StartsWith('*');
                        if(indirect) arg1 = arg1.Substring(1);
                        uint argValue;
                        if(!ParseInstrArg(arg1, symbolTable, out argValue)) {
                            Console.WriteLine($"Error on line {i + 1}: Invalid expression \"{arg1}\".");
                            return;
                        }
                        int diff = (int)argValue - (int)ptr - 1;
                        if(diff < -64 || diff > 63) {
                            Console.WriteLine($"Error on line {i + 1}: Destination is too far for relative addressing.");
                            return;
                        }
                        if(diff < 0) {
                            diff = -diff;
                            diff = 64 - diff;
                            diff = 63 + diff + 1;
                        }
                        outputData[ptr] = (uint)(diff | (indirect ? 128 : 0));
                        ptr++;
                    }else if(!instr.isBranch && instr.addrMode == AddressingModes.Absolute) {
                        bool indirect = arg1.StartsWith('*');
                        if(indirect) arg1 = arg1.Substring(1);
                        uint argValue;
                        if(!ParseInstrArg(arg1, symbolTable, out argValue)) {
                            Console.WriteLine($"Error on line {i + 1}: Invalid expression \"{arg1}\".");
                            return;
                        }
                        if(argValue > 8191) {
                            Console.WriteLine($"Error on line {i + 1}: Value overflow.");
                            return;
                        }
                        if(arg3 != null) { //Indexed
                            uint regNum;
                            if(arg3.Length != 3 && arg3.Length != 2){
                                Console.WriteLine($"Error on line {i + 1}: Invalid argument for indexed instruction.");
                                return;
                            }
                            if(arg3.StartsWith("r0")) regNum = 0;
                            else if(arg3.StartsWith("r1")) regNum = 1;
                            else if(arg3.StartsWith("r2")) regNum = 2;
                            else if(arg3.StartsWith("r3")) regNum = 3;
                            else {
                                Console.WriteLine($"Error on line {i + 1}: Invalid register name in indexed instruction.");
                                return;
                            }
                            char c = arg3.Length == 3 ? arg3[2] : '0';
                            if(c != '+' && c != '-' && c != '0') {
                                Console.WriteLine($"Error on line {i + 1}: Invalid operation '{c}' for indexed instruction.");
                                return;
                            }
                            if((finalOpcode & 0b11) != 0) {
                                Console.WriteLine($"Error on line {i + 1}: Cannot use a destination register other then r0 on indexed instructions.");
                                return;
                            }
                            outputData[ptr - 1] = (finalOpcode & 0b11111100) | regNum; //Modify opcode to hold index register instead of destination register, which implicitely becomes 0 in this case
                            argValue |= (uint)(c == '+' ? 1 : (c == '-' ? 2 : 3)) << 13;
                        }
                        outputData[ptr] = (argValue >> 8) | (uint)(indirect ? 128 : 0);
                        outputData[ptr + 1] = argValue & 255;
                        ptr += 2;
                    }
                }
            }
            string outputFilename = "";
            string[] parts = source.Split('.');
            for(int i = 0; i < parts.Length - 1; i++) {
                outputFilename = $"{outputFilename}{(i == 0 ? "" : ".")}{parts[i]}";
            }
            outputFilename = $"{outputFilename}.bin";
            byte[] outputDataBytes = new byte[ptr];
            for(int i = 0; i < ptr; i++) {
                outputDataBytes[i] = (byte)outputData[i];
            }
            File.WriteAllBytes(outputFilename, outputDataBytes);
        }
    }
}
