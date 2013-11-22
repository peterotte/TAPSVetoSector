----------------------------------------------------------------------------------
-- Engineer: Peter-Bernd Otte
-- Create Date:    08:47:24 09/10/2013 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;																						
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
Library UNISIM;
use UNISIM.vcomponents.all; --  for bufg

entity EventIDSender is
    Port ( StatusCounter : out  STD_LOGIC_VECTOR (6 downto 0);
           UserEventID : in  STD_LOGIC_VECTOR (31 downto 0);
           ResetSenderCounter : in  STD_LOGIC;
           OutputPin : out  STD_LOGIC;
           clock50 : in  STD_LOGIC);
end EventIDSender;

architecture Behavioral of EventIDSender is

	signal CalculatedParityBit : std_logic;
	signal SenderClock : std_logic;
	signal ClockPreScaleCounter : std_logic_vector(1 downto 0);
	signal Inter_StatusCounter : STD_LOGIC_VECTOR (6 downto 0);

begin
	StatusCounter <= Inter_StatusCounter;

	process(clock50)
	begin
		if rising_edge(clock50) then
			ClockPreScaleCounter <= ClockPreScaleCounter +1;
		end if;
	end process;
	SenderClock <= ClockPreScaleCounter(1);


	CalculatedParityBit <= UserEventID(0) xor UserEventID(1) xor UserEventID(2) xor UserEventID(3) xor UserEventID(4) xor UserEventID(5) xor 
		UserEventID(6) xor UserEventID(7) xor UserEventID(8) xor UserEventID(9) xor UserEventID(10) xor UserEventID(11) xor UserEventID(12) xor 
		UserEventID(13) xor UserEventID(14) xor UserEventID(15) xor UserEventID(16) xor UserEventID(17) xor UserEventID(18) xor UserEventID(19) xor 
		UserEventID(20) xor UserEventID(21) xor UserEventID(22) xor UserEventID(23) xor UserEventID(24) xor UserEventID(25) xor UserEventID(26) xor 
		UserEventID(27) xor UserEventID(28) xor UserEventID(29) xor UserEventID(30) xor UserEventID(31);
	

	process(SenderClock)
	begin
		if (ResetSenderCounter = '1') then
			Inter_StatusCounter <= b"0000000";
		elsif rising_edge(SenderClock) then
			if (Inter_StatusCounter(6) = '0') then
				Inter_StatusCounter <= Inter_StatusCounter +1;
			else
				Inter_StatusCounter <= Inter_StatusCounter;
			end if;
		end if;
	end process;

	process (clock50)
	begin
		if rising_edge(clock50) then
		  case Inter_StatusCounter is
		    when b"000"&x"1" => OutputPin <= '1';
			 when b"000"&x"2" => OutputPin <= UserEventID(0);
			 when b"000"&x"3" => OutputPin <= UserEventID(1);
			 when b"000"&x"4" => OutputPin <= UserEventID(2);
			 when b"000"&x"5" => OutputPin <= UserEventID(3);
			 when b"000"&x"6" => OutputPin <= UserEventID(4);
			 when b"000"&x"7" => OutputPin <= UserEventID(5);
			 when b"000"&x"8" => OutputPin <= UserEventID(6);
			 when b"000"&x"9" => OutputPin <= UserEventID(7);
			 when b"000"&x"a" => OutputPin <= UserEventID(8);
			 when b"000"&x"b" => OutputPin <= UserEventID(9);
			 when b"000"&x"c" => OutputPin <= UserEventID(10);
			 when b"000"&x"d" => OutputPin <= UserEventID(11);
			 when b"000"&x"e" => OutputPin <= UserEventID(12);
			 when b"000"&x"f" => OutputPin <= UserEventID(13);
			 when b"001"&x"0" => OutputPin <= UserEventID(14);
			 when b"001"&x"1" => OutputPin <= UserEventID(15);
			 when b"001"&x"2" => OutputPin <= UserEventID(16);
			 when b"001"&x"3" => OutputPin <= UserEventID(17);
			 when b"001"&x"4" => OutputPin <= UserEventID(18);
			 when b"001"&x"5" => OutputPin <= UserEventID(19);
			 when b"001"&x"6" => OutputPin <= UserEventID(20);
			 when b"001"&x"7" => OutputPin <= UserEventID(21);
			 when b"001"&x"8" => OutputPin <= UserEventID(22);
			 when b"001"&x"9" => OutputPin <= UserEventID(23);
			 when b"001"&x"a" => OutputPin <= UserEventID(24);
			 when b"001"&x"b" => OutputPin <= UserEventID(25);
			 when b"001"&x"c" => OutputPin <= UserEventID(26);
			 when b"001"&x"d" => OutputPin <= UserEventID(27);
			 when b"001"&x"e" => OutputPin <= UserEventID(28);
			 when b"001"&x"f" => OutputPin <= UserEventID(29);
			 when b"010"&x"0" => OutputPin <= UserEventID(30);
			 when b"010"&x"1" => OutputPin <= UserEventID(31);
			 when b"010"&x"2" => OutputPin <= CalculatedParityBit;
			 when b"010"&x"3" => OutputPin <= '1';
			 when others => OutputPin <= '0';
			end case;
		end if;
	end process;

end Behavioral;

