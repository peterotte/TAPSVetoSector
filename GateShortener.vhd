--------------------------------------------------------
-- author: Peter Otte
-- 6.10.2011
--
-- Gate Shortener
-- Basic idea: shortens a long signal
-- maximum length: NCh * Clock+0..1*Clock (jitter)
--
-- note: the VUPROM output NIM_OUT adds an additional 
--       20ns because of the design of the hardware 
--------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GateShortener is
	generic ( 
			NCh : integer
			);  
    Port ( sig_in : in  STD_LOGIC;
           sig_out : out  STD_LOGIC;
           clock : in  STD_LOGIC);
end GateShortener;

architecture Behavioral of GateShortener is
	signal sr : std_logic_vector(NCh downto 0);
begin
	sig_out <= '1' when ((sig_in = '1') and (sr(NCh) = '0')) else '0';
	
	process (clock, sig_in)
	begin
		if rising_edge(clock) then
			for i in 0 to NCh-1 loop
				sr(i+1) <= sr(i);
			end loop;
			sr(0)<=sig_in;
		end if;
	end process;

end Behavioral;

