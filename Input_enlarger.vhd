library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Input_Enlarger is
	Generic (
		Width : integer := 200
		);
   Port ( 
		clock : in  STD_LOGIC;
		input_signal : in  STD_LOGIC;
      output_signal : out  STD_LOGIC
	);
end Input_Enlarger;

architecture Behavioral of Input_Enlarger is
	constant NumberOfBits : integer := 9;
	signal WaitCounter : STD_LOGIC_VECTOR (NumberOfBits downto 0);
	signal Input_Reg : std_logic_vector(1 downto 0);
	signal inter_output_signal : std_logic;

begin
	process(clock)
	begin
		if rising_edge(clock) then
			Input_Reg(0) <= input_signal;
			Input_Reg(1) <= Input_Reg(0);
		end if;
	end process;

	process(clock)
	begin
		if rising_edge(clock) then
			if (Input_Reg = b"01") then --leading edge of input signal
				WaitCounter <= (others => '0');
				inter_output_signal <= '1';
			elsif (WaitCounter = CONV_STD_LOGIC_VECTOR(Width, NumberOfBits) ) then
				WaitCounter <= (others => '1');
				inter_output_signal <= '0';
			else
				WaitCounter <= WaitCounter +1;
				inter_output_signal <= inter_output_signal;
			end if;
		end if;
	end process;
	
	output_signal <= inter_output_signal;

end Behavioral;
