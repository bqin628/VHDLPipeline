--
-- control unit. simply implements the truth table for a small set of
-- instructions
--
--

Library IEEE;
use IEEE.std_logic_1164.all;

entity control is
port(opcode: in std_logic_vector(5 downto 0);
     RegDst, MemRead, MemToReg, MemWrite :out  std_logic;
     ALUSrc, RegWrite, Branch: out std_logic;
     ALUOp: out std_logic_vector(1 downto 0);

     wr_address, instructionOne, instructionTwo: in std_logic_vector(4 downto 0);
     branchsignal, ex_MemRead: in std_logic;
     stall : out std_logic);
end control;

architecture behavioral of control is

signal rformat, lw, sw, beq, stallCheck  :std_logic; -- define local signals
				    -- corresponding to instruction
				    -- type
 begin
--
-- recognize opcode for each instruction type
-- these variable should be inferred as wires

	rformat 	<=  '1'  WHEN  Opcode = "000000"  ELSE '0';
	Lw          <=  '1'  WHEN  Opcode = "100011"  ELSE '0';
 	Sw          <=  '1'  WHEN  Opcode = "101011"  ELSE '0';

--
-- implement each output signal as the column of the truth
-- table  which defines the control
--

stall <= '1' when ((ex_MemRead = '1') and (instructionOne = wr_address or instructionTwo = wr_address)) else '0';
stallCheck <= '1'when ((ex_MemRead = '1') and (instructionOne = wr_address or instructionTwo = wr_address)) else '0';

RegDst <= rformat when stallCheck = '0' and branchsignal = '0' else '0';
ALUSrc <= (lw or sw) when stallCheck = '0' and branchsignal = '0' else '0';

MemToReg <= lw when stallCheck = '0' and branchsignal = '0' else '0';
RegWrite <= (rformat or lw) when stallCheck = '0' and branchsignal = '0' else '0';
MemRead <= lw when stallCheck = '0' and branchsignal = '0' else '0';
MemWrite <= sw when stallCheck = '0' and branchsignal = '0' else '0';


ALUOp(1 downto 0) <=  rformat & '0' when stallCheck = '0' else "00"; -- note the use of the concatenation operator
				     -- to form  2 bit signal

end behavioral;
