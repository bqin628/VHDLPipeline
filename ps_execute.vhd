-- ECE 3056: Architecture, Concurrency and Energy in Computation
-- Sudhakar Yalamanchili
-- Pipelined MIPS Processor VHDL Behavioral Mode--
--
--
-- execution unit. only a subset of instructions are supported in this
-- model, specifically add, sub, lw, sw, beq, and, or
--

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity execute is
port(
--
-- inputs
--
     PC4 : in std_logic_vector(31 downto 0);
     register_rs, register_rt :in std_logic_vector (31 downto 0);
     Sign_extend :in std_logic_vector(31 downto 0);
     ALUOp: in std_logic_vector(1 downto 0);
     ALUSrc, RegDst : in std_logic;
     wreg_rd, wreg_rt : in std_logic_vector(4 downto 0);

-- outputs
--
     alu_result, Branch_PC :out std_logic_vector(31 downto 0);
     wreg_address : out std_logic_vector(4 downto 0);
     zero: out std_logic;

     fwmemdata, fwalu_result, fwmemory_data: in std_logic_vector(31 downto 0);
     branchsignal, stall, fwmemwrite, fwMemToReg, fwRegWrite : in std_logic;
     instructionOne, instructionTwo, fwwbreg, fwmemreg: in std_logic_vector(4 downto 0);
     fwregrt : out std_logic_vector(31 downto 0)); --forward register rt
     end execute;


architecture behavioral of execute is
SIGNAL Ainput, Binput	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
signal ALU_Internal : std_logic_vector (31 downto 0);
Signal Function_opcode : std_logic_vector (5 downto 0);
Signal fwwrite_data : std_logic_vector(31 downto 0);
Signal forwardOne : std_logic_vector(1 downto 0);
Signal forwardTwo : std_logic_vector(1 downto 0);

SIGNAL ALU_ctl	: STD_LOGIC_VECTOR( 2 DOWNTO 0 );

BEGIN
  fwwrite_data <= fwalu_result(31 downto 0) when (fwMemToReg = '0') else fwmemory_data;

  forwardOne <= "01" when
                          ((fwRegWrite = '1') and
                          (fwwbreg /= "00000") and
                          (not((fwmemwrite = '1') and (fwmemreg /= "00000") and (fwmemreg = instructionOne))) and
                          (fwwbreg = instructionOne)) else
                "10" when
                          ((fwmemwrite = '1') and
                          (fwmemreg /= "00000") and
                          (fwmemreg = instructionOne)) else
                "00";

  --first ALU
  Ainput <= fwwrite_data when forwardOne = "01" else
            fwmemdata when forwardOne = "10" else
            register_rs;

  forwardTwo <= "00" when
                          ((fwRegWrite = '1') and
                          (fwwbreg /= "00000") and
                          (ALUSrc = '0') and
                          (not((fwmemwrite = '1') and (fwmemreg /= "00000") and (fwmemreg = instructionTwo))) and
                          (ALUSrc = '0') and
                          (fwwbreg = instructionTwo)) else
                "01" when
                          ((fwmemwrite = '1') and
                          (fwmemreg /= "00000") and
                          (fwmemreg = instructionTwo) and
                          (ALUSrc = '1')) else
                "10" when (ALUSrc = '0') else
                "11" when ALUSrc = '1';
  --second ALU
  Binput <= fwwrite_data when forwardTwo = "00" else
            fwmemdata when forwardTwo = "01" else
            register_rt when forwardTwo = "10" else
            Sign_extend(31 downto 0) when forwardTwo = "11" else
            X"BBBBBBBB";



	 fwregrt <= fwwrite_data when ((fwRegWrite = '1') and (fwwbreg /= "00000") and not ((fwmemwrite = '1') and (fwmemreg /= "00000") and (fwmemreg = instructionTwo)) and (fwwbreg = instructionTwo)) else
              fwmemdata when ((fwmemwrite = '1') and (fwmemreg /= "00000") and (fwmemreg = instructionTwo)) else
              register_rt;

	 -- Get the function field. This will be the least significant
	 -- 6 bits of  the sign extended offset

	 Function_opcode <= Sign_extend(5 downto 0);

		-- Generate ALU control bits

	ALU_ctl( 0 ) <= ( Function_opcode( 0 ) OR Function_opcode( 3 ) ) AND ALUOp(1 );
	ALU_ctl( 1 ) <= ( NOT Function_opcode( 2 ) ) OR (NOT ALUOp( 1 ) );
	ALU_ctl( 2 ) <= ( Function_opcode( 1 ) AND ALUOp( 1 )) OR ALUOp( 0 );

		-- Generate Zero Flag
	Zero <= '1' WHEN ( ALU_internal = X"00000000"  )
		         ELSE '0';

-- implement the RegDst mux in this pipeline stage
--
wreg_address <= wreg_rd when RegDst = '1' else wreg_rt;

ALU_result <= X"0000000" & B"000" & ALU_internal(31) when ALU_ctl = "111" else ALU_internal;

PROCESS ( ALU_ctl, Ainput, Binput )
	BEGIN
					-- Select ALU operation
 	CASE ALU_ctl IS
						-- ALU performs ALUresult = A_input AND B_input
		WHEN "000" 	=>	ALU_internal 	<= Ainput AND Binput;
						-- ALU performs ALUresult = A_input OR B_input
     	WHEN "001" 	=>	ALU_internal 	<= Ainput OR Binput;
						-- ALU performs ALUresult = A_input + B_input
	 	WHEN "010" 	=>	ALU_internal 	<= Ainput + Binput;
						-- ALU performs ?
 	 	WHEN "011" 	=>	ALU_internal <= X"00000000";
						-- ALU performs ?
 	 	WHEN "100" 	=>	ALU_internal 	<= X"00000000";
						-- ALU performs ?
 	 	WHEN "101" 	=>	ALU_internal 	<=  X"00000000";
						-- ALU performs ALUresult = A_input -B_input
 	 	WHEN "110" 	=>	ALU_internal 	<= (Ainput - Binput);
						-- ALU performs SLT
  	 	WHEN "111" 	=>	ALU_internal 	<= (Ainput - Binput) ;
 	 	WHEN OTHERS	=>	ALU_internal 	<= X"FFFFFFFF" ;
  	END CASE;
  END PROCESS;

end behavioral;
