-- check, whether all PLLs are locked: ./vmeext 0xXX004000 0x0 r
-- should be 0x3
-- To Reset the PLLs: ./vmeext 0xXX004000 0x3 w

-- Engineer: S.Minami, Peter-Bernd Otte
-- 2.4.2012
 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clock_boost is
    Port ( CLKIN_N_IN : in  STD_LOGIC;
           CLKIN_P_IN : in  STD_LOGIC;
			  CLK_RST_IN : in  STD_LOGIC_VECTOR (3 downto 0);
           CLK_LOCKED_OUT : out  STD_LOGIC_VECTOR (3 downto 0);
			  CLK50MHz_OUT : out  STD_LOGIC;
           CLK100MHz_OUT : out  STD_LOGIC;
           CLK200MHz_OUT : out  STD_LOGIC;
           CLK400MHz_OUT : out  STD_LOGIC;
			  clock1MHz_OUT : out  STD_LOGIC;
			  clock0_5Hz_OUT : out  STD_LOGIC
		  );
 
end clock_boost;

architecture Behavioral of clock_boost is

	COMPONENT clkbst100to200
	PORT(
		CLKIN_N_IN : IN std_logic;
		CLKIN_P_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLKDV_OUT : OUT std_logic;
		CLKIN_IBUFGDS_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		CLK2X_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic
		);
	END COMPONENT;

	COMPONENT clkbst200to400
	PORT(
		CLKIN_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLK0_OUT : OUT std_logic;
		CLK2X_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic
		);
	END COMPONENT;
		
	signal clk50,clk100,clk200,clk400: std_logic;
	signal locked, reset : std_logic_vector ( 3 downto 0);
	signal locked4 : std_logic;
	signal clk100_2, clk200_2: std_logic;
	signal clock1MHz, clock0_5Hz : std_logic;
begin

	CLK50MHz_OUT <= clk50;
	CLK100MHz_OUT <= clk100;
	CLK200MHz_OUT <= clk200;
	CLK400MHz_OUT <= clk400;
	CLK_LOCKED_OUT <= locked;
	reset <= CLK_RST_IN;

	Inst_clkbst100to200: clkbst100to200 PORT MAP(
		CLKIN_N_IN => CLKIN_N_IN,
		CLKIN_P_IN => CLKIN_P_IN,
		RST_IN => reset(0),
		CLKDV_OUT => clk50,
		CLKIN_IBUFGDS_OUT => clk100_2,
		CLK0_OUT => clk100,
		CLK2X_OUT => clk200,
		LOCKED_OUT => locked(0)
	);

	Inst_clkbst200to400: clkbst200to400 PORT MAP(
		CLKIN_IN => clk200,
		RST_IN => reset(1),
		CLK0_OUT => clk200_2,
		CLK2X_OUT => clk400,
		LOCKED_OUT => locked(1) 
	);
	
	process (clk50)
	variable Counter : integer; 
	begin
		if rising_edge(clk50) then
			Counter := Counter +1;
			if Counter > 24 then --24 gives (24+1) * 20ns long pulses
				Counter := 0;
				clock1MHz <= not clock1MHz;
			else
				clock1MHz <= clock1MHz;
			end if;
		end if;
	end process;
	clock1MHz_OUT <= clock1MHz;
	
	process (clock1MHz)
	variable Counter : integer; 
	begin
		if rising_edge(clock1MHz) then
			Counter := Counter +1;
			if Counter > 1000000-1 then --1000000-1 gives (1000000) * 1µs long pulses
				Counter := 0;
				clock0_5Hz <= not clock0_5Hz;
			else
				clock0_5Hz <= clock0_5Hz;
			end if;
		end if;
	end process;
	clock0_5Hz_OUT <= clock0_5Hz;

	
		
end Behavioral;