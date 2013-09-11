
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;																						
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
Library UNISIM;
use UNISIM.vcomponents.all; --  for bufg

entity trigger is
	port (
		clock50 : in STD_LOGIC;
		clock100 : in STD_LOGIC;
		clock200 : in STD_LOGIC;
		clock400 : in STD_LOGIC; 
		trig_in : in STD_LOGIC_VECTOR (191 downto 0);		
		trig_out : out STD_LOGIC_VECTOR (63 downto 0);
		nim_in   : in  STD_LOGIC;
		nim_out  : out STD_LOGIC;
		led	     : out STD_LOGIC_VECTOR(8 downto 1); -- 8 LEDs onboard
		pgxled   : out STD_LOGIC_VECTOR(8 downto 1); -- 8 LEDs on PIG board
		Global_Reset_After_Power_Up : in std_logic;
		VN2andVN1 : in std_logic_vector(7 downto 0);
--............................. vme interface ....................
		u_ad_reg :in std_logic_vector(11 downto 2);
		u_dat_in :in std_logic_vector(31 downto 0);
		u_data_o :out std_logic_vector(31 downto 0);
		oecsr, ckcsr:in std_logic
	);
end trigger;


architecture RTL of trigger is

	subtype sub_Adress is std_logic_vector(11 downto 4);
	constant BASE_TRIG_InputPatternMask_IN1 : sub_Adress 			:= x"50" ; -- r/w
	constant BASE_TRIG_InputPatternMask_IN2 : sub_Adress 			:= x"51" ; -- r/w
	constant BASE_TRIG_InputPatternMask_IN3 : sub_Adress 			:= x"52" ; -- r/w
	constant BASE_TRIG_InputPatternMask_INOUT1 : sub_Adress		:= x"53" ; -- r/w
	constant BASE_TRIG_InputPatternMask_INOUT2 : sub_Adress		:= x"54" ; -- r/w

	constant BASE_TRIG_FIXED : sub_Adress 								:= x"f0" ; -- r
	constant TRIG_FIXED_Master : std_logic_vector(31 downto 0)  := x"12112103"; -- 21.11.2012

	------------------------------------------------------------------------------
	
	signal InputPatternMask : std_logic_vector(5*32-1 downto 0) := x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
	signal Post_trig_in, Post_trig_in_short : std_logic_vector(5*32-1 downto 0);
	
	--BaF2 Vetos
	signal LED_Signals_Sector_1, LED_Signals_Sector_2 : std_logic_vector(63 downto 0);
	signal LED_SectorOR_1, LED_SectorOR_2 : std_logic;

	--PWO CFD and PWO Vetos
	signal CFD_PWO_Sector_1, CFD_PWO_Sector_2 : std_logic_vector(11 downto 0);
	
	--Signals for Coplanarity
	signal SB1, SB2 : std_logic_vector(63 downto 0); --Signals Trigger is Based on
	signal LED_Coplanar_Signals_SectorA, LED_Coplanar_Signals_SectorB, LED_Coplanar_Signals_SectorC,
		LED_Coplanar_Signals_SectorD, LED_Coplanar_Signals_SectorE, LED_Coplanar_Signals_SectorF : std_logic_vector(7 downto 0);

	signal CFD_VETO_Sector_1, CFD_VETO_Sector_2 : std_logic_vector(2 downto 0);
	signal CFD_PWO_SectorOR_1, CFD_PWO_SectorOR_2, CFD_VETO_SectorOR_1, CFD_VETO_SectorOR_2 : std_logic;
	
	
	component GateShortener
		 	generic ( 
				NCh : integer
			);  
			Port ( sig_in : in  STD_LOGIC;
				  sig_out : out  STD_LOGIC;
				  clock : in  STD_LOGIC);
	end component;

	
begin
	------------------------------------------------------------------------------------------------
	-- Enable/Disable individual channels
	Post_trig_in <= trig_in(5*32-1 downto 0) and InputPatternMask;

	------------------------------------------------------------------------------------------------
	-- Switch on corresponding LED if cable is connected
	led(1) <= '0' when (Post_trig_in(31+0*32 downto 0*32) = x"00000000") else '1';
	led(2) <= '0';
	led(3) <= '0' when (Post_trig_in(31+1*32 downto 1*32) = x"00000000") else '1';
	led(4) <= '0';
	led(5) <= '0' when (Post_trig_in(31+2*32 downto 2*32) = x"00000000") else '1';
	led(6) <= '0';
	pgxled(1) <= '0' when (Post_trig_in(31+3*32 downto 3*32) = x"00000000") else '1';
	pgxled(2) <= '0';
	pgxled(3) <= '0' when (Post_trig_in(31+4*32 downto 4*32) = x"00000000") else '1';
	pgxled(4) <= '0';
	pgxled(6 downto 5) <= (others => '1');

	led(8 downto 7) <= "00";
	pgxled(8 downto 7) <= (others => '0');

	------------------------------------------------------------------------------------------------
	
	ShortenGates: for i in 0 to 5*32-1 generate
		GateShortener_1: GateShortener 
			GENERIC MAP(NCh=>10) 
			PORT MAP(
				sig_in=>Post_trig_in(i),
				sig_out=>Post_trig_in_short(i),
				clock=>clock100);
	end generate;

	------------------------------------------------------------------------------------------------

	--BaF2 VETOs
	LED_Signals_Sector_1  <= Post_trig_in_short(2*32-1 downto 0*32);
	LED_Signals_Sector_2  <= Post_trig_in_short(4*32-1 downto 2*32);
	
	LED_SectorOR_1 <= '1' when LED_Signals_Sector_1 /= "0" else '0';
	LED_SectorOR_2 <= '1' when LED_Signals_Sector_2 /= "0" else '0';
	
	--PWO CFD
	CFD_PWO_Sector_1 <= Post_trig_in_short(4*32+11 downto 4*32);
	CFD_PWO_Sector_2 <= Post_trig_in_short(4*32+11+12 downto 4*32+12);
	CFD_VETO_Sector_1 <= Post_trig_in_short(4*32+12+12+2 downto 4*32+12+12);
	CFD_VETO_Sector_2 <= Post_trig_in_short(4*32+12+12+3+2 downto 4*32+12+12+3);
	
	CFD_PWO_SectorOR_1 <= '1' when CFD_PWO_Sector_1 /= "0" else '0';
	CFD_PWO_SectorOR_2 <= '1' when CFD_PWO_Sector_2 /= "0" else '0';
	CFD_VETO_SectorOR_1 <= '1' when CFD_VETO_Sector_1 /= "0" else '0';
	CFD_VETO_SectorOR_2 <= '1' when CFD_VETO_Sector_2 /= "0" else '0';

	nim_out <= LED_SectorOR_1 or LED_SectorOR_2 or CFD_PWO_SectorOR_1 or CFD_PWO_SectorOR_2 or CFD_VETO_SectorOR_1 or CFD_VETO_SectorOR_2;
	
	trig_out(0) <= LED_SectorOR_1;
	trig_out(0+32) <= LED_SectorOR_2;
	trig_out(1) <= CFD_PWO_SectorOR_1;
	trig_out(1+32) <= CFD_PWO_SectorOR_2;
	trig_out(2) <= CFD_VETO_SectorOR_1;
	trig_out(2+32) <= CFD_VETO_SectorOR_2;
	--trig_out(31) <= nim_in;
	--trig_out(31+32) <= nim_in;
	
	
	----------------------------------------------------------------------------------------------------------------------------------------------------------------
	--Coplanarity Trigger start
	SB1 <= LED_Signals_Sector_1;
	SB2 <= LED_Signals_Sector_2;
	
	--Sector A
	LED_Coplanar_Signals_SectorA(0) <= SB1(03) or SB1(06) or SB1(10) or SB1(15) or SB1(21) or SB1(28) or SB1(29) or SB1(36) or SB1(37) or SB1(45) or SB1(46) or SB1(55); --bin 20
	LED_Coplanar_Signals_SectorA(1) <= SB1(07) or SB1(11) or SB1(16) or SB1(22) or SB1(30) or SB1(38) or SB1(47) or SB1(56); --bin 21
	LED_Coplanar_Signals_SectorA(2) <= SB1(04) or SB1(17) or SB1(23) or SB1(31) or SB1(39) or SB1(48) or SB1(57) or SB1(58); --bin 22
	LED_Coplanar_Signals_SectorA(3) <= SB1(12) or SB1(24) or SB1(40) or SB1(49) or SB1(59); --bin 23
	LED_Coplanar_Signals_SectorA(4) <= SB1(08) or SB1(13) or SB1(18) or SB1(25) or SB1(32) or SB1(41) or SB1(50) or SB1(51) or SB1(60); --bin 24
	LED_Coplanar_Signals_SectorA(5) <= SB1(05) or SB1(19) or SB1(26) or SB1(33) or SB1(42) or SB1(52) or SB1(61) or SB1(62); --bin 25
	LED_Coplanar_Signals_SectorA(6) <= SB1(09) or SB1(14) or SB1(20) or SB1(27) or SB1(34) or SB1(43) or SB1(53) or SB1(63); --bin 26
	LED_Coplanar_Signals_SectorA(7) <= SB1(35) or SB1(44) or SB1(54); --bin 27
	
	
	--Sector B
	LED_Coplanar_Signals_SectorB(0) <= SB2(3) or SB2(6) or SB2(10) or SB2(15) or SB2(21) or SB2(28) or SB2(29) or SB2(36) or SB2(37) or SB2(45) or SB2(46) or SB2(55); --bin 28
	LED_Coplanar_Signals_SectorB(1) <= SB2(7) or SB2(11) or SB2(16) or SB2(22) or SB2(30) or SB2(38) or SB2(47) or SB2(56); --bin 29
	LED_Coplanar_Signals_SectorB(2) <= SB2(4) or SB2(17) or SB2(23) or SB2(31) or SB2(39) or SB2(48) or SB2(57) or SB2(58); --bin 30
	LED_Coplanar_Signals_SectorB(3) <= SB2(12) or SB2(24) or SB2(40) or SB2(49) or SB2(59); --bin 31
	LED_Coplanar_Signals_SectorB(4) <= SB2(8) or SB2(13) or SB2(18) or SB2(25) or SB2(32) or SB2(41) or SB2(50) or SB2(51) or SB2(60); --bin 32
	LED_Coplanar_Signals_SectorB(5) <= SB2(5) or SB2(19) or SB2(26) or SB2(33) or SB2(42) or SB2(52) or SB2(61) or SB2(62); --bin 33
	LED_Coplanar_Signals_SectorB(6) <= SB2(9) or SB2(14) or SB2(20) or SB2(27) or SB2(34) or SB2(43) or SB2(53) or SB2(63); --bin 34
	LED_Coplanar_Signals_SectorB(7) <= SB2(35) or SB2(44) or SB2(54); --bin 35

	--Sector C
	LED_Coplanar_Signals_SectorC(0) <= SB1(3) or SB1(6) or SB1(10) or SB1(15) or SB1(21) or SB1(28) or SB1(29) or SB1(36) or SB1(37) or SB1(45) or SB1(46); --bin 36
	LED_Coplanar_Signals_SectorC(1) <= SB1(7) or SB1(11) or SB1(16) or SB1(22) or SB1(30) or SB1(38) or SB1(47) or SB1(55); --bin 37
	LED_Coplanar_Signals_SectorC(2) <= SB1(4) or SB1(17) or SB1(23) or SB1(31) or SB1(39) or SB1(48) or SB1(56) or SB1(57); --bin 38
	LED_Coplanar_Signals_SectorC(3) <= SB1(8) or SB1(12) or SB1(18) or SB1(24) or SB1(32) or SB1(40) or SB1(49) or SB1(50) or SB1(58); --bin 39
	LED_Coplanar_Signals_SectorC(4) <= SB1(13) or SB1(25) or SB1(41) or SB1(51) or SB1(59); --bin 40
	LED_Coplanar_Signals_SectorC(5) <= SB1(5) or SB1(19) or SB1(26) or SB1(33) or SB1(42) or SB1(52) or SB1(60) or SB1(61); --bin 41
	LED_Coplanar_Signals_SectorC(6) <= SB1(9) or SB1(14) or SB1(20) or SB1(27) or SB1(34) or SB1(43) or SB1(53) or SB1(62); --bin 42
	LED_Coplanar_Signals_SectorC(7) <= SB1(35) or SB1(44) or SB1(54) or SB1(63); --bin 43

	--Sector D
	LED_Coplanar_Signals_SectorD(0) <= SB2(3) or SB2(6) or SB2(10) or SB2(15) or SB2(21) or SB2(28) or SB2(29) or SB2(36) or SB2(37) or SB2(45) or SB2(46) or SB2(55); --bin 44
	LED_Coplanar_Signals_SectorD(1) <= SB2(7) or SB2(11) or SB2(16) or SB2(22) or SB2(30) or SB2(38) or SB2(47) or SB2(56); --bin 45
	LED_Coplanar_Signals_SectorD(2) <= SB2(4) or SB2(17) or SB2(23) or SB2(31) or SB2(39) or SB2(48) or SB2(57) or SB2(58); --bin 46
	LED_Coplanar_Signals_SectorD(3) <= SB2(12) or SB2(24) or SB2(40) or SB2(49) or SB2(59); --bin 47
	LED_Coplanar_Signals_SectorD(4) <= SB2(8) or SB2(13) or SB2(18) or SB2(25) or SB2(32) or SB2(41) or SB2(50) or SB2(51) or SB2(60); --bin 0
	LED_Coplanar_Signals_SectorD(5) <= SB2(5) or SB2(19) or SB2(26) or SB2(33) or SB2(42) or SB2(52) or SB2(61) or SB2(62); --bin 1
	LED_Coplanar_Signals_SectorD(6) <= SB2(9) or SB2(14) or SB2(20) or SB2(27) or SB2(34) or SB2(43) or SB2(53) or SB2(63); --bin 2
	LED_Coplanar_Signals_SectorD(7) <= SB2(35) or SB2(44) or SB2(54); --bin 3

	--Sector E
	LED_Coplanar_Signals_SectorE(0) <= SB1(3) or SB1(6) or SB1(10) or SB1(15) or SB1(21) or SB1(28) or SB1(29) or SB1(36) or SB1(37) or SB1(45) or SB1(46) or SB1(55); --bin 4
	LED_Coplanar_Signals_SectorE(1) <= SB1(7) or SB1(11) or SB1(16) or SB1(22) or SB1(30) or SB1(38) or SB1(47) or SB1(56); --bin 5
	LED_Coplanar_Signals_SectorE(2) <= SB1(4) or SB1(17) or SB1(23) or SB1(31) or SB1(39) or SB1(48) or SB1(57) or SB1(58); --bin 6
	LED_Coplanar_Signals_SectorE(3) <= SB1(12) or SB1(24) or SB1(40) or SB1(49) or SB1(59); --bin 7
	LED_Coplanar_Signals_SectorE(4) <= SB1(8) or SB1(13) or SB1(18) or SB1(25) or SB1(32) or SB1(41) or SB1(50) or SB1(51) or SB1(60); --bin 8
	LED_Coplanar_Signals_SectorE(5) <= SB1(5) or SB1(19) or SB1(26) or SB1(33) or SB1(42) or SB1(52) or SB1(61) or SB1(62); --bin 9
	LED_Coplanar_Signals_SectorE(6) <= SB1(9) or SB1(14) or SB1(20) or SB1(27) or SB1(34) or SB1(43) or SB1(53) or SB1(63); --bin 10
	LED_Coplanar_Signals_SectorE(7) <= SB1(35) or SB1(44) or SB1(54); --bin 11

	--Sector F
	LED_Coplanar_Signals_SectorF(0) <= SB2(3) or SB2(6) or SB2(10) or SB2(15) or SB2(21) or SB2(28) or SB2(29) or SB2(36) or SB2(37) or SB2(45) or SB2(46); --bin 12
	LED_Coplanar_Signals_SectorF(1) <= SB2(7) or SB2(11) or SB2(16) or SB2(22) or SB2(30) or SB2(38) or SB2(47) or SB2(55); --bin 13
	LED_Coplanar_Signals_SectorF(2) <= SB2(4) or SB2(17) or SB2(23) or SB2(31) or SB2(39) or SB2(48) or SB2(56) or SB2(57); --bin 14
	LED_Coplanar_Signals_SectorF(3) <= SB2(8) or SB2(12) or SB2(18) or SB2(24) or SB2(32) or SB2(40) or SB2(49) or SB2(50) or SB2(58); --bin 15
	LED_Coplanar_Signals_SectorF(4) <= SB2(13) or SB2(25) or SB2(41) or SB2(51) or SB2(59); --bin 16
	LED_Coplanar_Signals_SectorF(5) <= SB2(5) or SB2(19) or SB2(26) or SB2(33) or SB2(42) or SB2(52) or SB2(60) or SB2(61); --bin 17
	LED_Coplanar_Signals_SectorF(6) <= SB2(9) or SB2(14) or SB2(20) or SB2(27) or SB2(34) or SB2(43) or SB2(53) or SB2(62); --bin 18
	LED_Coplanar_Signals_SectorF(7) <= SB2(35) or SB2(44) or SB2(54) or SB2(63); --bin 19
	
	--select which sector should be given out
	trig_out(31 downto 24) <= 
		LED_Coplanar_Signals_SectorA when (VN2andVN1 = x"07") else
		LED_Coplanar_Signals_SectorC when (VN2andVN1 = x"08") else
		LED_Coplanar_Signals_SectorE when (VN2andVN1 = x"09") else
		(others => '0');
	
	trig_out(31+32 downto 24+32) <= 
		LED_Coplanar_Signals_SectorB when (VN2andVN1 = x"07") else
		LED_Coplanar_Signals_SectorD when (VN2andVN1 = x"08") else
		LED_Coplanar_Signals_SectorF when (VN2andVN1 = x"09") else
		(others => '0');
	
	----------------------------------------------------------------------------------------------------------------------------------------------------------------

	
	

	---------------------------------------------------------------------------------------------------------	
	-- Code for VME handling / access
	-- handle read commands from vmebus
	---------------------------------------------------------------------------------------------------------	
	process(clock50, oecsr, u_ad_reg)
	begin
		if (clock50'event and clock50 = '1' and oecsr = '1') then
			u_data_o <= (others => '0');
				
			if (u_ad_reg(11 downto 4) =  BASE_TRIG_FIXED) then 
				u_data_o(31 downto 0) <= TRIG_FIXED_Master; end if;
			if (u_ad_reg(11 downto 4) =  BASE_TRIG_InputPatternMask_IN1) then 
				u_data_o(31 downto 0) <= InputPatternMask(32*0+31 downto 32*0+0); end if;
			if (u_ad_reg(11 downto 4) =  BASE_TRIG_InputPatternMask_IN2) then 
				u_data_o(31 downto 0) <= InputPatternMask(32*1+31 downto 32*1+0); end if;
			if (u_ad_reg(11 downto 4) =  BASE_TRIG_InputPatternMask_IN3) then 
				u_data_o(31 downto 0) <= InputPatternMask(32*2+31 downto 32*2+0); end if;
			if (u_ad_reg(11 downto 4) =  BASE_TRIG_InputPatternMask_INOUT1) then 
				u_data_o(31 downto 0) <= InputPatternMask(32*3+31 downto 32*3+0); end if;
			if (u_ad_reg(11 downto 4) =  BASE_TRIG_InputPatternMask_INOUT2) then 
				u_data_o(31 downto 0) <= InputPatternMask(32*4+31 downto 32*4+0); end if;

		end if;
	end process;

	---------------------------------------------------------------------------------------------------------	
	-- Code for VME handling / access
	-- decoder for data registers
	-- handle write commands from vmebus
	---------------------------------------------------------------------------------------------------------	
	process(clock50, ckcsr, u_ad_reg)
	begin
		if (clock50'event and clock50 ='1') then
			if (ckcsr='1' and u_ad_reg(11 downto 4)= BASE_TRIG_InputPatternMask_IN1 ) then
				InputPatternMask(32*0+31 downto 32*0+0) <= u_dat_in; end if;
			if (ckcsr='1' and u_ad_reg(11 downto 4)= BASE_TRIG_InputPatternMask_IN2 ) then
				InputPatternMask(32*1+31 downto 32*1+0) <= u_dat_in; end if;
			if (ckcsr='1' and u_ad_reg(11 downto 4)= BASE_TRIG_InputPatternMask_IN3 ) then
				InputPatternMask(32*2+31 downto 32*2+0) <= u_dat_in; end if;
			if (ckcsr='1' and u_ad_reg(11 downto 4)= BASE_TRIG_InputPatternMask_INOUT1 ) then
				InputPatternMask(32*3+31 downto 32*3+0) <= u_dat_in; end if;
			if (ckcsr='1' and u_ad_reg(11 downto 4)= BASE_TRIG_InputPatternMask_INOUT2 ) then
				InputPatternMask(32*4+31 downto 32*4+0) <= u_dat_in; end if;
			
		end if;
	end process;
	


end RTL;