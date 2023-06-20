library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 

entity tb_bldc is

generic 
(
	clk_frq     : integer := 100_000_000								;
	pwm_frq     : integer := 20_000	                                    ;
	
	c_clkfreq   : integer := 100_000_000				                ;
    c_baudrate  : integer := 100_0000					                ;
    c_stopbit   : integer := 1	
);

end tb_bldc;

architecture Behavioral of tb_bldc is

component trapezoidal_control is

generic 
(
	clk_frq     : integer := 100_000_000								;
	pwm_frq     : integer := 20_000	                                    ;
	
	c_clkfreq   : integer := 100_000_000				                ;
    c_baudrate  : integer := 100_0000					                ;
    c_stopbit   : integer := 1	
);
port 
(
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------INPUTS------------------------------------------------------------------------------
	clk_x	   		: in std_logic											 ;
	
	hall_a 		: in std_logic											 ;
	hall_b 		: in std_logic											 ;
	hall_c 		: in std_logic											 ;
	
	start  		: in std_logic											 ;
	--stop   		: in std_logic											 ;
	
	forward		: in std_logic											 ;
	--reverse		: in std_logic											 ;
	closed_loop : in std_logic;    
	
	rst         : in std_logic											 ;
	
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------OUTPUTS-----------------------------------------------------------------------------
	
	U_L			: out std_logic											 ;
	U_H		    : out std_logic											 ;
	
	V_L			: out std_logic											 ;
	V_H			: out std_logic											 ;
	
	W_L			: out std_logic											 ;
	W_H			: out std_logic											 ;
	
    rx_i		: in  std_logic      	    							 ;
	tx_o		: out std_logic		
	
);


end component;

--COMPONENT div_gen_0
--  PORT (
   
--    aclk : IN STD_LOGIC;
--    s_axis_divisor_tvalid : IN STD_LOGIC;
--    s_axis_divisor_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--    s_axis_dividend_tvalid : IN STD_LOGIC;
--    s_axis_dividend_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--    m_axis_dout_tvalid : OUT STD_LOGIC;
--    --m_axis_dout_tuser : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
--    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
--  );

--end component;

--component design_1_wrapper is
--  port (
--    A_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
--    B_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
--    CLK_0 : in STD_LOGIC;
--    S_0 : out STD_LOGIC_VECTOR ( 31 downto 0 )
--  );
--end component;

signal clk     : std_logic ;
signal hall_a  : std_logic ;
signal hall_b  : std_logic ;
signal hall_c  : std_logic ;
signal start   : std_logic ;
signal stop    : std_logic ;
signal forward : std_logic ;
signal reverse : std_logic ;
signal rst     : std_logic ;
signal U_H     : std_logic ;
signal U_L     : std_logic ;
signal V_H     : std_logic ;
signal V_L     : std_logic ;
signal W_H     : std_logic ;
signal W_L     : std_logic ;
signal Duty    : integer range 0 to 100;
signal rx_i    : std_logic ;
signal tx_o    : std_logic ;
signal closed_loop: std_logic;
constant c_clock_per : time := 50 ns    ;
constant hall_s_per  : time := 50 ns   ;
constant c_hex_val_1 : std_logic_vector(0 to 10):= "10" & x"01" & "0"	;
constant c_hex_val_2 : std_logic_vector(0 to 10):= "10" & x"02" & "0"	;
constant c_baud      : time := 1.0 us      ;  

--signal divisor_valid    : std_logic                                      ;
--signal divisor_data     : std_logic_vector(31 downto 0)                  ;
--signal dividend_valid   : std_logic                                      ;
--signal dividend_data    : std_logic_vector(31 downto 0)                  ; 
--signal dout_valid       : std_logic                                      ;
--signal dout_user        : std_logic_vector(0 downto 0)                   ;
--signal quotient         : std_logic_vector(31 downto 0)                  ;
--signal Fractional       : std_logic_vector(31 downto 0)                  ;

signal A_0              : std_logic_vector(15 downto 0)                  ;
signal B_0              : std_logic_vector(15 downto 0)                  ;
signal CLK_0            : std_logic                                      ;
signal S_0              : std_logic_vector(31 downto 0)                  ;

begin

--i_div_gen_0 : div_gen_0
--  PORT MAP (
--    aclk =>  clk,
    
--    s_axis_divisor_tvalid  =>   divisor_valid           ,
--    s_axis_divisor_tdata   =>   divisor_data            ,
--    s_axis_dividend_tvalid =>   dividend_valid          ,
--    s_axis_dividend_tdata  =>   dividend_data           ,
--    m_axis_dout_tvalid     =>   dout_valid              ,
--   -- m_axis_dout_tuser      =>   dout_user               ,
--    m_axis_dout_tdata(63 downto 32)      =>   quotient,
--    m_axis_dout_tdata(31 downto 0)       =>   Fractional
  
--  );
  
  
--  i_design_1_wrapper :i_design_1_wrapper
--  port map(
--    A_0 =>A_0,
--    B_0 =>B_0,
--    CLK_0 =>CLK_0,
--    S_0 =>S_0
--  );

DUT : trapezoidal_control 

generic map 
(
	clk_frq     => clk_frq	,
	pwm_frq     => pwm_frq
)               
				
port map            
(               
				
	clk_x	   		=> clk		,
							
	hall_a 		=> hall_a   ,
	hall_b 		=> hall_b   ,
	hall_c 		=> hall_c   ,
							
	start  		=> start    ,
	
							
	forward		=> forward  ,
    closed_loop => closed_loop,
    	
							
	rst         => rst      ,
							
	U_L			=> U_L      ,
	U_H		    => U_H      ,
							
	V_L			=> V_L      ,
	V_H			=> V_H      ,
							
	W_L			=> W_L      ,
	W_H			=> W_H      ,
	
	rx_i        => rx_i     ,
	tx_o        => tx_o    
	
);


P_CLKGEN : process begin 
	
	clk 	<=	'0'			;
	wait for c_clock_per/2  ;
	clk     <=  '1' 		;
	wait for c_clock_per/2  ;
	
end process P_CLKGEN;

P_STIMULI : process begin

rst <= '1';
wait for 5* c_clock_per;
start <= '1';
forward <= '1';
rst     <= '0';
closed_loop <='1';
for i in 0 to 100000000 loop

wait for 1* c_clock_per;

hall_a <= '0';
hall_b <= '0';
hall_c <= '1';

wait for hall_s_per;

hall_a <= '0';
hall_b <= '1';
hall_c <= '1';

wait for hall_s_per;

hall_a <= '0';
hall_b <= '1';
hall_c <= '0';

wait for hall_s_per;

hall_a <= '1';
hall_b <= '1';
hall_c <= '0';

wait for hall_s_per;

hall_a <= '1';
hall_b <= '0';
hall_c <= '0';

wait for hall_s_per;

hall_a <= '1';
hall_b <= '0';
hall_c <= '1';

wait for hall_s_per;

--if( i >= 15 and i < 25) then
--for k in 0 to 10 loop  
--	rx_i <= c_hex_val_2(10-k)													;
--	wait for c_baud     														;

--end loop;
--end if;
--if( i >= 25) then
--for p in 0 to 10 loop  
--	rx_i <= c_hex_val_1(10-p)													;
--	wait for c_baud     														;
	
--end loop;

--end if;

end loop;

wait;
end process P_STIMULI;
end Behavioral;