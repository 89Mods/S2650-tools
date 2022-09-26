using System;
using System.IO;
using System.Diagnostics;

namespace Signetics2650 {
    class P8251 {
        public const uint S_TXRDY = 1;
        public const uint S_RXRDY = 2;
        public const uint S_TXEMPTY = 4;
        public const uint S_PE = 8;
        public const uint S_OE = 16;
        public const uint S_FE = 32;
        public const uint S_SYNDET = 64;
        public const uint S_DSR = 128;

        public uint mode,status;
        public uint txbuff,rxbuff;
        public bool waitingForMode;

        private bool txOn,rxOn;

        public P8251() {
            Reset();
        }

        public void Update() {
            if((status & S_TXEMPTY) == 0) {
                Console.Write(Char.ToString((char)txbuff));
                status |= S_TXEMPTY | S_TXRDY;
            }
            if(Console.KeyAvailable) {
                rxbuff = Console.ReadKey(true).KeyChar;
                if((status & S_RXRDY) == 0) {
                    status |= S_OE;
                }
                status |= S_RXRDY;
            }
        }

        public void Reset() {
            waitingForMode = true;
            status = S_TXEMPTY;
            txOn = false;
            rxOn = false;
        }

        public void SendByte(uint data, bool cd) {
            if(waitingForMode) {
                if(!cd) return;
                mode = data;
                status |= S_TXRDY;
                waitingForMode = false;
                return;
            }
            if(cd) {
                txOn = (data & 1) != 0;
                rxOn = (data & 4) != 0;
                if((data & 16) != 0) {
                    status &= ~(S_PE | S_OE | S_FE);
                }
                if((data & 64) != 0) {
                    Reset();
                    return;
                }
            }else {
                if(!txOn) return;
                txbuff = data;
                status &= ~(S_TXEMPTY | S_TXRDY);
            }
        }

        public uint ReadByte(bool cd) {
            if(waitingForMode) return 0;
            if(cd) {
                return status;
            }else {
                status &= ~(S_RXRDY);
                return rxbuff;
            }
        }
    }

    class OutputPort {
        public uint state;

        public OutputPort() {
            Reset();
        }

        public void Reset() {
            state = 0;
        }

        public void SendByte(uint data) {
            this.state = data;
        }
    }

    class Emu2650 {
        const int ROM_SIZE = 4096;
        const int RAM_SIZE = 2048;

        public uint[] ROM = new uint[ROM_SIZE];
        public uint[] RAM = new uint[RAM_SIZE];
        public uint PSU,PSL,R0;
        public uint[,] regs = new uint[2,3];
        public uint PC;
        public uint PR;
        public uint[] stack = new uint[8];

        public OutputPort port;
        public P8251 serial;

        public Emu2650(uint[] romImage) {
            port = new OutputPort();
            serial = new P8251();
            Reset();
            Array.Copy(romImage, ROM, Math.Min(romImage.Length, ROM_SIZE));
        }

        public void Reset() {
            Array.Fill<uint>(RAM, 0);
            PSU = PSL = R0 = PC = PR = 0;
            regs[0,0] = regs[0,1] = regs[0,2] = regs[1,0] = regs[1,1] = regs[1,2] = 0;
            port.Reset();
            serial.Reset();
        }

        private uint ReadMem(uint addr) {
            addr &= 8191;
            addr |= (PR & 3) << 13;

            if(addr < ROM_SIZE) return ROM[addr];
            if(addr - ROM_SIZE < RAM_SIZE) return RAM[addr - ROM_SIZE];
            if(addr - ROM_SIZE - RAM_SIZE < RAM_SIZE) return RAM[addr - ROM_SIZE - RAM_SIZE];
            return 0;
        }

        private void WriteMem(uint addr, uint val) {
            addr &= 8191;
            addr |= (PR & 3) << 13;
            val &= 255;

            if(addr < ROM_SIZE) return;
            if(addr - ROM_SIZE < RAM_SIZE) {
                RAM[addr - ROM_SIZE] = val;
                return;
            }
            if(addr - ROM_SIZE - RAM_SIZE < RAM_SIZE) RAM[addr - ROM_SIZE - RAM_SIZE] = val;
        }

        private uint ReadInstrArg() {
            uint res = ReadMem(PC);
            PC = (PC + 1) & 8191;
            return res;
        }

        private uint ComputeDisplacement() {
            uint arg = ReadInstrArg();
            int a = (int)(arg & 127);
            if(a >= 64) a = -(64 - (a - 64));
            int res = (int)PC + a;
            if(res < 0) res = 8191 + res;
            res &= 8191;
            return (uint)res;
        }

        private uint GetReg(uint reg) {
            if(reg > 3) return 0;
            if(reg == 0) return R0;
            reg--;
            uint bank = (PSL >> 4) & 1;
            return regs[bank,reg];
        }

        private void SetReg(uint reg, uint val) {
            if(reg > 3) return;
            if(reg == 0) {
                R0 = val & 0xFF;
                return;
            }
            reg--;
            uint bank = (PSL >> 4) & 1;
            regs[bank,reg] = val & 0xFF;
        }

        private void IncReg(uint reg) {
            SetReg(reg, GetReg(reg) + 1);
        }

        private void DecReg(uint reg) {
            SetReg(reg, GetReg(reg) == 0 ? 255 : GetReg(reg) - 1);
        }

        private uint GetAbsoluteAddress(uint reg, out uint regNew) {
            uint arg = ReadInstrArg();
            uint effectiveAddress = (arg & 0b11111) << 8;
            effectiveAddress |= ReadInstrArg();
            arg >>= 5;
            if((arg & 4) != 0) {
                uint newAddr = ReadMem(effectiveAddress) << 8;
                newAddr |= ReadMem((effectiveAddress + 1) & 8191);
                newAddr &= 8191;
                effectiveAddress = newAddr;
            }
            arg &= 3;
            if(arg != 0) {
                regNew = 0;
                if(arg == 1) IncReg(reg);
                if(arg == 2) DecReg(reg);
                effectiveAddress += GetReg(reg);
                effectiveAddress &= 8191;
            }else regNew = reg;
            return effectiveAddress;
        }

        private void SetCCFor(uint val) {
            val &= 0xFF;
            uint newCC = 0;
            if(val > 127) newCC = 0b10;
            else if(val != 0) newCC = 0b01;
            newCC <<= 6;
            PSL &= 0b00111111;
            PSL |= newCC;
        }

        private void SetCompareCC(uint val, uint val2) {
            val &= 0xFF;
            val2 &= 0xFF;

            uint newCC = 0;
            if(val2 > val) newCC = 0b10;
            else if(val2 < val) newCC = 0b01;
            newCC <<= 6;
            PSL &= 0b00111111;
            PSL |= newCC;
        }

        private void StackPush() {
            uint sp = PSU & 7;
            stack[sp] = PC | (PR << 13);
            sp++;
            sp &= 7;
            PSU &= 0b11111000;
            PSU |= sp;
        }

        private void StackPop() {
            uint sp = PSU & 7;
            PC = stack[(sp - 1) & 7];
            PR = (PC >> 13) & 3;
            PC &= 8191;
            sp--;
            sp &= 7;
            PSU &= 0b11111000;
            PSU |= sp;
        }

        private void BranchRelative(bool subroutine) {
            uint newPC = ComputeDisplacement();
            if(subroutine) StackPush();
            PC = newPC;
        }

        private void BranchAbsolute(bool subroutine) {
            uint newAddr = ReadInstrArg() & 0b01111111;
            uint page = newAddr >> 5;
            newAddr &= 0b00011111;
            newAddr <<= 8;
            newAddr |= ReadInstrArg();
            if(subroutine) StackPush();
            PR = page;
            PC = newAddr;
        }

        private uint ParseLoad(uint mode, uint reg, out uint newReg) {
            newReg = reg;
            if(mode == 0) {
                uint ret = GetReg(reg);
                newReg = 0;
                return ret;
            }else if(mode == 1) return ReadInstrArg();
            else if(mode == 2) return ReadMem(ComputeDisplacement());
            else if(mode == 3) {
                uint newReg2;
                uint val = ReadMem(GetAbsoluteAddress(reg, out newReg2));
                newReg = newReg2;
                return val;
            }
            return 0;
        }

        private uint GetCarry() {
            return PSL & 1;
        }

        private void SetCarry(uint carry) {
            PSL &= 254;
            PSL |= carry & 1;
        }

        private uint GetInterdigitCarry() {
            return (PSL >> 5) & 1;
        }

        private void SetInterdigitCarry(uint carry) {
            PSL &= 0b11011111;
            PSL |= (carry & 1) << 5;
        }

        private void SetOverflow(uint ovf) {
            PSL &= 0b11111011;
            PSL |= (ovf & 1) << 2;
        }

        private void EmuStep() {
            serial.Update();
            uint instr = ReadMem(PC);
            PC = (PC + 1) & 8191;

            if(instr >= 0x04 && instr <= 0x07) {
                SetReg(instr - 0x04, ReadInstrArg());
                return;
            }
            if(instr >= 0 && instr <= 0x0F) { //Load instruction
                uint mode = (instr & 15) / 4;
                uint reg = instr & 3;
                uint newReg;
                uint val = ParseLoad(mode, reg, out newReg);
                reg = newReg;
                SetReg(reg, val);
                SetCCFor(GetReg(reg));
                return;
            }
            if(instr >= 0xC1 && instr <= 0xCF) { //Store instruction
                uint mode = (instr - 0xC0) / 4;
                uint reg = instr & 3;
                if(mode == 0) {
                    SetReg(reg, R0);
                }else if(mode == 1) {
                    ReadInstrArg(); //nopi
                }else if(mode == 2) {
                    WriteMem(ComputeDisplacement(), GetReg(reg));
                }else if(mode == 3) {
                    uint newReg;
                    uint addr = GetAbsoluteAddress(reg, out newReg);
                    reg = newReg;
                    WriteMem(addr, GetReg(reg));
                }
                //CC update
                if(mode == 0) SetCCFor(R0);
                return;
            }

            if(instr >= 0x98 && instr <= 0x9A) {
                uint condition = instr - 0x98;
                if(((PSL & 0b11000000) >> 6) != condition) BranchRelative(false);
                else ReadInstrArg();
                return;
            }

            if(instr >= 0x9C && instr <= 0x9E) {
                uint condition = instr - 0x9C;
                if(((PSL & 0b11000000) >> 6) != condition) BranchAbsolute(false);
                else {
                    ReadInstrArg();
                    ReadInstrArg();
                }
                return;
            }

            if(instr >= 0x18 && instr <= 0x1B) {
                uint condition = instr - 0x18;
                if(condition == 3 || ((PSL & 0b11000000) >> 6) == condition) BranchRelative(false);
                else ReadInstrArg();
                return;
            }

            if(instr >= 0x1C && instr <= 0x1F) {
                uint condition = instr - 0x1C;
                if(condition == 3 || ((PSL & 0b11000000) >> 6) == condition) BranchAbsolute(false);
                else {
                    ReadInstrArg();
                    ReadInstrArg();
                }
                return;
            }

            if(instr >= 0x38 && instr <= 0x3B) {
                uint condition = instr - 0x38;
                if(condition == 3 || ((PSL & 0b11000000) >> 6) == condition) BranchRelative(true);
                else ReadInstrArg();
                return;
            }

            if(instr >= 0x3C && instr <= 0x3F) {
                uint condition = instr - 0x3C;
                if(condition == 3 || ((PSL & 0b11000000) >> 6) == condition) BranchAbsolute(true);
                else {
                    ReadInstrArg();
                    ReadInstrArg();
                }
                return;
            }

            if(instr >= 0xF8 && instr <= 0xFF) {
                uint reg = instr & 3;
                uint val = GetReg(reg);
                val = val == 0 ? 255 : val - 1;
                SetReg(reg, val);
                if(val != 0) {
                    if(instr < 0xFC) BranchRelative(false);
                    else BranchAbsolute(false);
                }else {
                    ReadInstrArg();
                    if(instr >= 0xFC) ReadInstrArg();
                }
                return;
            }

            if(instr >= 0x14 && instr <= 0x17) {
                uint condition = instr - 0x14;
                if(condition == 3 || ((PSL & 0b11000000) >> 6) == condition) StackPop();
                return;
            }

            if(instr >= 0xF0 && instr <= 0xF3) { //wrtd
                uint reg = instr - 0xF0;
                uint val = GetReg(reg);
                if((port.state & 128) != 0) return;
                if((port.state & 64) != 0) serial.SendByte(val, true);
                else serial.SendByte(val, false);
                return;
            }

            if(instr >= 0x70 && instr <= 0x73) { //redd
                uint reg = instr - 0x70;
                uint val;
                if((port.state & 128) != 0) val = 0;
                else {
                    if((port.state & 64) != 0) val = serial.ReadByte(true);
                    else val = serial.ReadByte(false);
                }
                SetReg(reg, val);
                SetCCFor(val);
                return;
            }

            if(instr >= 0xB0 && instr <= 0xB3) { //wrtc
                uint reg = instr - 0xB0;
                uint val = GetReg(reg);
                port.SendByte(val);
                if((port.state & 128) != 0) {
                    serial.Reset();
                }
                return;
            }

            if((instr >= 0x20 && instr <= 0x2F) || (instr >= 0x60 && instr <= 0x6F) || (instr >= 0x41 && instr <= 0x4F)) {
                uint mode = (instr & 15) / 4;
                uint reg = instr & 3;
                uint newReg;
                uint val = ParseLoad(mode, reg, out newReg);
                reg = newReg;
                uint val2 = GetReg(reg);
                SetReg(reg, instr < 0x40 ? val ^ val2 : (instr < 0x60 ? val & val2 : val | val2));
                //CC update
                SetCCFor(GetReg(reg));
                return;
            }

            if(instr >= 0xE0 && instr <= 0xEF) {
                uint mode = (instr & 15) / 4;
                uint reg = instr & 3;
                uint newReg;
                uint val = ParseLoad(mode, reg, out newReg);
                reg = newReg;
                uint val2 = GetReg(reg);
                
                SetCompareCC(val2, val);
                return;
            }

            if(instr >= 0x50 && instr <= 0x53) {
                uint reg = instr & 3;
                uint val = GetReg(reg);

                uint prevMSB = val & 128;
                if((PSL & 8) != 0) {
                    SetInterdigitCarry((val >> 6) & 1);
                    uint newCarry = val & 1;
                    val >>= 1;
                    val |= GetCarry() << 7;
                    SetCarry(newCarry);
                }else {
                    uint a = val & 1;
                    val >>= 1;
                    val |= a << 7;
                }
                if((val & 128) != prevMSB) SetOverflow(1);
                else SetOverflow(0);
                SetReg(reg, val);
                //CC update
                SetCCFor(val);
                return;
            }

            if(instr >= 0xD0 && instr <= 0xD3) {
                uint reg = instr & 3;
                uint val = GetReg(reg);

                if((PSL & 8) != 0) {
                    SetInterdigitCarry((val >> 4) & 1);
                    uint newCarry = (val & 128) >> 7;
                    val <<= 1;
                    val |= GetCarry();
                    SetCarry(newCarry);
                }else {
                    uint a = (val & 128) >> 7;
                    val <<= 1;
                    val |= a;
                }
                SetReg(reg, val);
                //CC update
                SetCCFor(val);
                return;
            }

            if(instr >= 0x80 && instr <= 0x8F) {
                uint mode = (instr & 15) / 4;
                uint reg = instr & 3;
                uint newReg;
                uint val = ParseLoad(mode, reg, out newReg);
                reg = newReg;
                uint val2 = GetReg(reg);

                uint res = val + val2;
                if((PSL & 0b1000) != 0) res += PSL & 1;
                if(res > 255) SetCarry(1);
                else SetCarry(0);
                SetInterdigitCarry((res & 0b10000) >> 4);
                res &= 0xFF;
                if((val & 128) == (val2 & 128) && (res & 128) != (val & 128)) SetOverflow(1);
                else SetOverflow(0);
                SetReg(reg, res);

                //CC update
                SetCCFor(res);
                return;
            }

            if(instr >= 0xA0 && instr <= 0xAF) {
                uint mode = (instr & 15) / 4;
                uint reg = instr & 3;
                uint newReg;
                uint val = ParseLoad(mode, reg, out newReg);
                reg = newReg;
                uint val2 = GetReg(reg);

                int res = (int)val2 - (int)val;
                if((PSL & 1) == 0) res--;
                if(res < 0) SetCarry(0);
                else SetCarry(1);
                SetInterdigitCarry((uint)(res & 0b10000) >> 4);
                if(res < 0) res = 256 + res;
                res &= 0xFF;
                if((val & 128) == (val2 & 128) && (res & 128) != (val & 128)) SetOverflow(1);
                else SetOverflow(0);
                SetReg(reg, (uint)res);

                //CC update
                SetCCFor((uint)res);
                return;
            }

            uint arg,b;
            switch(instr) {
                case 0x92: //lpsu
                    PSU = R0;
                    return;
                case 0x93: //lpsl
                    PSL = R0;
                    return;
                case 0x12: //spsu
                    R0 = PSU;
                    return;
                case 0x13: //spsl
                    R0 = PSL;
                    return;
                case 0x74: //cpsu
                    arg = ReadInstrArg();
                    PSU &= ~arg;
                    return;
                case 0x75: //cpsl
                    arg = ReadInstrArg();
                    PSL &= ~arg;
                    return;
                case 0x76: //ppsu
                    arg = ReadInstrArg();
                    PSU |= arg;
                    return;
                case 0x77: //ppsl
                    arg = ReadInstrArg();
                    PSL |= arg;
                    return;
                case 0xB4: //tpsu
                case 0xB6:
                    arg = ReadInstrArg();
                    b = PSU & arg;
                    PSL &= 0b00111111;
                    if(b != arg) PSL |= 128;
                    return;
                case 0xB5: //tpsl
                case 0xB7:
                    arg = ReadInstrArg();
                    b = PSL & arg;
                    PSL &= 0b00111111;
                    if(b != arg) PSL |= 128;
                    return;
                case 0xC0: //nop
                case 0x90:
                case 0x91:
                    return;   
            }
            Console.WriteLine(String.Format("Invalid or unsupported opcode {0:X}", instr));
            Environment.Exit(2);
        }

        public static void RunEmu(string file) {
            byte[] romImage = File.ReadAllBytes(file);
            if(romImage.Length > 4096) {
                Console.WriteLine("Error: binary image too large. Must be 4096 bytes at most.");
                Environment.Exit(1);
            }
            uint[] convertedRomImage = new uint[romImage.Length];
            for(int i = 0; i < romImage.Length; i++) convertedRomImage[i] = (uint)(romImage[i] & 0xFF);
            Emu2650 emu = new Emu2650(convertedRomImage);
            Stopwatch timer = new Stopwatch();
            timer.Start();
            int ips = 350000;
            long targetDelay = (long)((double)10000000 / (double)ips);
            //FileStream stream = File.Open("r0.raw", FileMode.Create);
            //Stopwatch exitTimer = new Stopwatch();
            //exitTimer.Start();
            while(true) {
                if(timer.ElapsedTicks / (Stopwatch.Frequency / (1000L * 1000L)) >= targetDelay) {
                    timer.Restart();
                    emu.EmuStep();
                    //if((float)exitTimer.ElapsedTicks / (float)Stopwatch.Frequency >= 30) break;
                    //stream.WriteByte((Byte)emu.R0);
                }
            }
            //stream.Close();
        }
    }
}