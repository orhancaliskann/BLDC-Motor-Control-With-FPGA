library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity trapezoidal_control is

generic 
(
	clk_frq     : integer := 20_000_000    								;
	pwm_frq     : integer := 20_000	                                    ;
	
	c_clkfreq   : integer := 20_000_000				               		;
    c_baudrate  : integer := 115200						                ;
    c_stopbit   : integer := 1									 
);
port 
(
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
	clk_x	    : in  std_logic											 ;
	rst         : in  std_logic											 ;
	pulse       : out std_logic											 ;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
	hall_a 		: in std_logic											 ;
	hall_b 		: in std_logic											 ;
	hall_c 		: in std_logic											 ;
	
	start  		: in std_logic											 ;
	
	forward		: in std_logic											 ;
	forward_led : out std_logic                                          ;
	
	closed_loop : in std_logic                                           ;
	closed_l_led: out std_logic                                          ; 
	locked_led  : out std_logic                                          ;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
	U_L			: out std_logic											 ;
	U_H		    : out std_logic											 ;
	
	V_L			: out std_logic											 ;
	V_H			: out std_logic											 ;
	
	W_L			: out std_logic											 ;
	W_H			: out std_logic											 ;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------	
	rx_i		: in  std_logic  :='1'   	    						 ;
	tx_o		: out std_logic											 
);
end trapezoidal_control;

architecture Behavioral of trapezoidal_control is
-------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------Component Declaration----------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
component pwm_gen is

generic(
        clk_frq 	: integer := 20_000_000						;    
        pwm_frq 	: integer := 20_000                              
);
Port (
        clk         : in std_logic                              ;    
        Duty        : in integer range 0 to 100 := 0            ;    
        pwm_o       : out std_logic                             
        
 );
end component;
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
component UART_Module is

generic (
			c_clkfreq      : integer := 20_000_000									;	      --Internal clock freq
			c_baudrate     : integer := 115200										;		  --Communication speed
			c_stopbit      : integer := 1													  --number of stop bit 
		);		
		
port 	(	
			clk            : in  std_logic											;		  --clock input
            rst            : in  std_logic:='0'                                     ;         --state reset button
-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------UART TX port-----------------------------------------------------------			
			
			tx_start_i     : in std_logic                                  			;	      --start command
			tx_done_tick_o : out std_logic							       	        ;		  --data out information tick
			data_i 		   : in std_logic_vector (7 downto 0 )  					;		  --Data input value 
            tx_busy        : out std_logic                                          ;         --tx busy or not
            busy_led       : out std_logic                                          ;         --Tx bus busy information led
-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------UART RX port-----------------------------------------------------------
            
			data_o 		   : out std_logic_vector (7 downto 0 ) 					;		  --Data output value 
			rx_done_tick_o : out std_logic					    					;	      --Data out information tick
		    frame_err      : out std_logic 									        ;		  --Frame error flag
		    parity_err 	   : out std_logic                                          ;	      --Data isn't true	
		
-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------Physical signal--------------------------------------------------------
			rx_i           : in  std_logic											;		  --UART rx input
			tx_o           : out std_logic													  --UART tx output			
		);

end component;
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

component debounce is

generic (

			c_clkfreq	: integer := 20_000_000;
			c_debtime	: integer := 1_000_000;
			c_initval	: std_logic	:= '0'

		);

port    (
			clk			: in std_logic;
			rst		    : in std_logic;
		
			signal_i_a	: in std_logic;
			signal_i_b	: in std_logic;
			signal_i_c	: in std_logic;
		
			signal_o_a	: out std_logic;
			signal_o_b	: out std_logic;
			signal_o_c	: out std_logic

	    );

end component;

-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
component div_gen_0
  
  PORT (
    
    aclk                  :    IN STD_LOGIC                             ;
    
    s_axis_divisor_tvalid :    IN STD_LOGIC                             ;
    s_axis_divisor_tdata  :    IN STD_LOGIC_VECTOR(31 DOWNTO 0)         ;
    s_axis_dividend_tvalid:    IN STD_LOGIC                             ;
    s_axis_dividend_tdata :    IN STD_LOGIC_VECTOR(31 DOWNTO 0)         ;
    
    m_axis_dout_tvalid    :    OUT STD_LOGIC                            ;
    m_axis_dout_tdata     :    OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
    
  );

end component;
-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
component P_control is 
	
	port (
			clk  	  : in std_logic								;	
			rst		  : in std_logic								;
			
			ref       : in std_logic_vector(15 downto 0)			;
			actual    : in std_logic_vector(15 downto 0)			;
			kp        : integer :=215                               ;
			ki        : integer :=2*188                             ;
			
			enable	  : in std_logic								;
			
			Cntrl     : out integer                                 ;
			Cntrl_2   : out integer                 
		 );

end component;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
component clk_wiz_0 is

port(   
        clk_in1 : in std_logic;
        reset   : in std_logic;
        
        locked  : out std_logic;
        clk_out1: out std_logic
       
     );
     
end component;
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
signal Hall_s			: std_logic_vector (2 downto 0)					 ;
signal Hall_p			: std_logic_vector (2 downto 0)					 ;
signal Hall_n			: std_logic_vector (2 downto 0)					 ;

signal pwm				: std_logic										 ;
signal dead_time		: integer range 0 to 50				    		 ;

signal start_s			: std_logic := '0'								 ;
signal forward_s		: std_logic	:= '1'     							 ;
signal reverse_s		: std_logic := '0'								 ;
signal Duty				: integer range 0 to 100 := 0					 ;
signal Duty_reg         : integer range 0 to 100 := 0                    ;

signal tx_start_i       : std_logic := '0'								 ;   
signal tx_done_tick_o   : std_logic	:= '0'								 ;
signal tx_busy       	: std_logic	:= '0'  							 ;
signal busy_led         : std_logic := '0'								 ;
signal data_i 		    : std_logic_vector (7 downto 0)					 ;
signal tx_step          : integer range 0 to 2 := 0                      ;

signal rx_done_tick_o   : std_logic := '0'								 ;
signal frame_err        : std_logic := '0'								 ;
signal parity_err 	    : std_logic	:= '0'								 ;
signal data_o 		    : std_logic_vector (7 downto 0) 				 ;

signal led_status		: std_logic := '0'								 ;
signal led_cntr			: integer range 0 to 20_000_000 := 0			 ;

signal soft_s			: integer range 0 to 20 		 := 0			 ;
signal soft_s_cntr		: integer range 0 to 20_000_000 := 0			 ;

signal sector_cntr      : integer range 0 to 25          := 0            ;
signal rpm_cntr         : integer range 0 to 25000       := 0            ;
signal rpm              : integer range 0 to 25000       := 0            ;
signal rpm_sec          : integer range 0 to 200_000_100 := 0            ;
signal rpm_reg          : std_logic_vector (15 downto 0)                 ;
signal rpm_reg_n        : std_logic_vector (15 downto 0)                 ;
signal rpm_reg_2c       : std_logic_vector (15 downto 0)                 ;
signal rpm_cntr_2       : integer range 0 to 25          :=0             ;
signal rpm_cntr_3       : integer range 0 to 25          :=0             ;
signal rpm_act          : std_logic_vector (15 downto 0)                 ;
signal hall_cntr        : integer range 0 to 500                         ;
signal loop_cntr        : integer range 0 to 65536                       ;
signal loop_cntr_2      : integer range 0 to 65536                       ;
signal loop_cntr_valid  : std_logic                                      ;
signal loop_cntr_reg    : std_logic_vector (15 downto 0)                 ;
signal send_en          : std_logic                                      ;
signal send_en_p        : std_logic                                      ;
signal send_en_n        : std_logic                                      ;
signal rpm_reg_p        : std_logic_vector(15 downto 0)                  ;
signal loop_cntr_reg_n  : std_logic_vector(15 downto 0)                  ;
signal loop_cntr_reg_2c : std_logic_vector(15 downto 0)                  ; 

signal hall_a_p         : std_logic                                      ;
signal hall_a_n         : std_logic                                      ;
signal hall_a_loop      : integer range 0 to 4000                        ;
signal rpm_us           : integer range 0 to 400_000                     ;

signal hall_c_fall      : std_logic                                      ;
signal hall_c_p         : std_logic                                      ;
signal hall_c_n         : std_logic                                      ;         

signal En               : std_logic                                      ;
signal data_reg         : std_logic_vector (7 downto 0)                  ;

signal hall_a_deb       : std_logic                                      ;
signal hall_b_deb       : std_logic                                      ;
signal hall_c_deb       : std_logic                                      ;
signal start_deb        : std_logic                                      ;
signal forward_deb      : std_logic                                      ;
signal rst_deb          : std_logic                                      ;
signal closed_loop_deb  : std_logic                                      ;

signal divisor_valid    : std_logic                                      ;
signal divisor_data     : std_logic_vector(31 downto 0)                  ;
signal dividend_valid   : std_logic                                      ;
signal dividend_data    : std_logic_vector(31 downto 0)                  ; 
signal dout_valid       : std_logic                                      ;
signal dout_user        : std_logic_vector(0 downto 0)                   ;
signal Quotient         : std_logic_vector (31 downto 0)                 ;
signal Fractional       : std_logic_vector (31 downto 0)                 ;
constant dvs            : integer  := 32767                              ;

signal ref              : std_logic_vector (15 downto 0)                 ;
signal actual           : std_logic_vector (15 downto 0)                 ;
signal enable           : std_logic                                      ;
signal cntrl            : integer                                        ;
signal kp               : integer := 215                                 ;
signal ki               : integer :=2* 188                               ;
signal kp_cntr          : std_logic                                      ;
signal cntrl_d          : integer                                        ;
signal cntrl_d_p        : integer                                        ;
signal cntrl_2          : integer                                        ;

signal locked           : std_logic                                      ;
signal clk              : std_logic                                      ;

constant c_debtime      : integer   := 500_000                           ;
constant c_initval      : std_logic := '0'                               ;

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------


begin 

-------------------------------------------------------------------------------------------------------------------------
------------------------------------------------Component Instantiation--------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

i_pwm_gen : pwm_gen 

generic map

(
        clk_frq => clk_frq 												 ,
        pwm_frq => pwm_frq
)

Port map 
(
        clk    => clk													 ,
        Duty   => Duty                                                   ,
        pwm_o  => pwm
        
 );
 
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

i_uart_module : UART_Module 

generic map(
			c_clkfreq      => c_clkfreq								     ,		 --Clock frequency
			c_baudrate     => c_baudrate							     ,		 --Communication speed
			c_stopbit      => c_stopbit 			                             --UART stop bit number
		   )					                                                              
																	     
port map   (				                                                                  
			clk            => clk									     ,		 --Board clock frequency (100MHz)
            rst            => rst									     ,		 --Reset command
-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------UART TX port-----------------------------------------------------------			
			
			tx_start_i     => tx_start_i								 ,		 --Transmitter start command
			tx_done_tick_o => tx_done_tick_o                        	 ,		 --All data transmitted tick
			data_i 		   => data_i                                	 ,		 --Data input
            tx_busy        => tx_busy                               	 ,		 --Tx bus is busy or not
            busy_led       => busy_led                                   ,       --Tx busy information led

-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------UART RX port-----------------------------------------------------------

			data_o 		   => data_o									 ,		 --Data output	
			rx_done_tick_o => rx_done_tick_o                             ,		 --All data recieved tick
		    frame_err      => frame_err                                  ,		 --Frame error (stop bit error)
		    parity_err 	   => parity_err                                 ,		 --Parity error (wrong data)
		
-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------Physical signal--------------------------------------------------------
			rx_i           => rx_i 										 ,		 --Rx bus
			tx_o           => tx_o										 		 --Tx bus
		   );
		   
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

i_debounce : debounce

generic map(

			c_clkfreq	=> c_clkfreq,
			c_debtime	=> c_debtime,
			c_initval	=> c_initval

		   )

port map  (
			
			clk			=> clk,
			rst		    => rst,
		
			signal_i_a	=> hall_a,
			signal_i_b	=> hall_b,
			signal_i_c	=> hall_c,
	
			signal_o_a	=> hall_a_deb,
			signal_o_b	=> hall_b_deb,
			signal_o_c	=> hall_c_deb

	       );
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
i_div_gen_0 : div_gen_0
  PORT MAP (
    aclk =>  clk,
    
    s_axis_divisor_tvalid  =>   divisor_valid           ,
    s_axis_divisor_tdata   =>   divisor_data            ,
    s_axis_dividend_tvalid =>   dividend_valid          ,
    s_axis_dividend_tdata  =>   dividend_data           ,
    m_axis_dout_tvalid     =>   dout_valid              ,
    --m_axis_dout_tuser      =>   dout_user               ,
    m_axis_dout_tdata (63 downto 32)      =>   quotient(31 downto 0)  ,
    m_axis_dout_tdata (31 downto 0)      =>   fractional(31 downto 0)  
  
  );
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------ 
i_P_control : P_control 
	
	port map (
			clk => clk, 	  
			rst => rst,
			
			ref       => ref,
			actual    => actual,
			
			enable	  => enable,
			
			kp        => kp,
			ki        => ki, 
			Cntrl     => cntrl, 
			Cntrl_2   => Cntrl_2               
		 );
		 
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
i_clock20 : clk_wiz_0

 port map(   
       
        clk_in1 => clk_x,
        reset   => rst,
        
        locked  => locked,
        clk_out1=> clk
     
     );
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
	      
process(clk, rst)
begin
if(rising_edge(clk)) then

Hall_s   <= hall_a_deb & hall_b_deb & hall_c_deb							 ;
Hall_p   <= Hall_s														     ;
Hall_n   <= Hall_p													         ;
rpm_sec  <= rpm_sec + 1                                                      ;
rpm_us   <= rpm_us + 1                                                       ; 

hall_a_p <= hall_a_deb                                                       ;
hall_a_n <= hall_a_p                                                         ;

hall_c_p <= hall_c_deb                                                       ;
hall_c_n <= hall_c_p                                                         ;

if(rst = '1') then 

    duty <= 0;
    tx_step <= 0;
    send_en <= '0';
    send_en_p <= '0';
    send_en_n<='0';
    Hall_s			<= (others =>'0')				   ;
    Hall_p			<= (others =>'0')				   ;
    Hall_n			<= (others =>'0')				   ;
    dead_time		<=  0				    		   ;
    led_status		<= '0'							   ;
    led_cntr		<=  0			 				   ;
    rpm_cntr       <=  0            				   ;
    rpm            <=  0            				   ;
    rpm_sec        <=  0            				   ;
    rpm_reg        <= (others =>'0')                   ;
	En             <= '0'                              ;			 
    hall_cntr      <=  0                               ;
    start_s	 	   <= '0'				  			   ;
    forward_s	   <= '1'     						   ;
    forward_led    <= '0'                              ;
    reverse_s      <= '0'                              ; 
    kp             <= 215                              ; 
    ki             <= 2*215                            ;
    
else
if (led_cntr = 20_000_000) then																		 							 
		led_cntr 		   <= 0											 ;
		led_status 		   <= not led_status							 ;
	else                                                            	                         																 
		led_cntr   		   <= led_cntr + 1								 ;
		led_status 		   <= led_status								 ;	
end if;
end if;


if(hall_a_deb = '1' and hall_c_p ='0' and hall_c_n = '1')then

   forward_led <= '1';
   
end if;

if(hall_c_deb = '1' and hall_a_p ='0' and hall_a_n = '1')then

   forward_led <= '0';
   
end if;


if(Hall_s /= Hall_p) then

	En <= '0'														 ;
    
end if;

if(Duty > 90) then

    Duty <= 90;

end if;
 
if(Duty < 30) then

    Duty <= 30;

end if;

if(hall_a_p = '1' and hall_a_n = '0') then
    
    hall_cntr <= hall_cntr + 1                                     ;
    hall_a_loop <= hall_a_loop + 1                                 ;

end if;

    if(hall_a_loop >= 5) then
    
    loop_cntr <= loop_cntr + 1                                  ;
        
    end if; 

    if(rpm_us >= 400_000) then 
    loop_cntr_2 <= loop_cntr * 300;
    loop_cntr_valid<= '1';
    rpm_us    <= 0;
    loop_cntr <= 0;
 
    end if;
    if(loop_cntr_valid = '1')then
    
        loop_cntr_reg <= conv_std_logic_vector(loop_cntr_2,16);
        loop_cntr_valid <= '0';
    
    end if;
    
    loop_cntr_reg_n <= not loop_cntr_reg  ;
    loop_cntr_reg_2c<= loop_cntr_reg_n + 1;

    if(rpm_sec > 20_000_000) then
    
    rpm <= hall_cntr * 15                                       ;
    rpm_sec <= 0                                                ;
    rpm_cntr <= rpm_cntr + 1                                    ;
    rpm_reg_p<= rpm_reg                                         ;
    
    end if;
    
    if(rpm_cntr /= 0) then
    hall_cntr <= 0;
    rpm_cntr <= 0                                               ;
    rpm_reg <= conv_std_logic_vector(rpm, 16)                   ;
    rpm_cntr_2 <= rpm_cntr_2 + 1; 
    
    end if;
    
    if(rpm_cntr_2 /= 0) then
    
        rpm_reg_n <= not rpm_reg;
        rpm_cntr_2 <= 0;
        rpm_cntr_3 <= rpm_cntr_3 + 1;
               
    end if;
    
    if(rpm_cntr_3 /= 0) then
    
    rpm_cntr_3 <= 0;
    rpm_reg_2c <= rpm_reg_n + 1;
    send_en   <= '1';
    
    end if;
    
    
    
if(reverse_s = '1') then
    actual <= loop_cntr_reg_2c                                   ;

if(send_en = '1' and tx_step = 0) then
    
    send_en_p <=send_en;
    send_en_n <= send_en_p; 
    data_i(7 downto 0) <=   rpm_reg_2c(15 downto 8)              ;

    if(send_en_p ='1' and send_en_n ='0')then

    tx_start_i <= '1'                                            ;

    else

    tx_start_i <= '0';
    end if;

    if(tx_done_tick_o ='1' and tx_step = 0) then

    tx_step <= 1                                                      ;
    send_en_p <= '0';
    send_en_n <= '0';

    end if;  
end if;
    if(tx_step = 1 and send_en ='1') then

    data_i (7 downto 0) <= rpm_reg_2c(7 downto 0)                ;
    send_en_p <=send_en                                          ;
    send_en_n <= send_en_p                                       ; 
    
   if(send_en_p ='1' and send_en_n ='0')then
   
    tx_start_i <= '1'                                            ;
    
    else

    tx_start_i <= '0';
    
    end if;
    
    if(tx_done_tick_o ='1' and tx_step = 1) then
  
    tx_start_i <= '0'                                                 ;
    tx_step <= 0                                                      ;
    send_en <= '0';
    send_en_p <= '0';
    send_en_n<='0';
    rpm <= 0;
    
    end if;
end if;
end if;



if(forward_s = '1') then
    actual <= loop_cntr_reg                                      ;
if(send_en = '1' and tx_step = 0) then
    
    send_en_p <=send_en;
    send_en_n <= send_en_p; 
    data_i(7 downto 0) <=   rpm_reg(15 downto 8)                 ;
    
    if(send_en_p ='1' and send_en_n ='0')then
   
    tx_start_i <= '1'                                            ;
    
    else

    tx_start_i <= '0';
    
    end if;
    
    if(tx_done_tick_o ='1' and tx_step = 0) then
  
    tx_step <= 1                                                      ;
    send_en_p <= '0';
    send_en_n <= '0';
    
    end if;
    
end if;
    
    if(tx_step = 1 and send_en ='1') then
  
    data_i (7 downto 0) <= rpm_reg(7 downto 0)                ;
    send_en_p <=send_en                                          ;
    send_en_n <= send_en_p                                       ; 
    
   if(send_en_p ='1' and send_en_n ='0')then
   
    tx_start_i <= '1'                                            ;
    else
    tx_start_i <= '0';   
    end if;
 
    if(tx_done_tick_o ='1' and tx_step = 1) then
  
    tx_start_i <= '0'                                                 ;
    tx_step <= 0                                                      ;
    send_en <= '0';
    send_en_p <= '0';
    send_en_n<='0';
    rpm <= 0;
    end if;
end if;
end if;
 

if(start = '1') then

	start_s <= '1'													     ;

else

    start_s <= '0'                                                       ;
    Duty    <=  0                                                        ;

end if;

if(locked = '1') then

locked_led <= '1';

else

locked_led <= '0';

end if;

if(forward = '1') then
    
    

	forward_s <= '1'													 ;
	reverse_s <= '0'													 ;
   
else
    
	reverse_s <= '1'													 ;
	forward_s <= '0'													 ;
    
end if;


if(dead_time > 49) then

    En <= '1'                                                            ;

end if;

if(closed_loop = '1') then

    enable <= '1'                                                        ;
        
else

    enable <= '0'                                                        ;

end if;

-----------------------------------------------------------------------------------------------------------
-------------------------------------------OPEN LOOP-------------------------------------------------------
if(enable = '0') then

closed_l_led    <= '0';

if(rx_done_tick_o = '1') then

    data_reg <= data_o                                                    ;
    
end if; 

if(data_reg = x"0A" and Duty > 24 and Duty < 90) then

    Duty <= 30;
    data_reg <= (others=> '0');         

end if;

if(data_reg = x"1A" and Duty > 24) then

    Duty <= 35;
    data_reg <= (others=> '0');         

end if;

if(data_reg = x"2A" and Duty > 24) then

    Duty <= 40;
    data_reg <= (others=> '0');         

end if;

if(data_reg = x"3A" and Duty > 24) then

    Duty <= 45;
    data_reg <= (others=> '0');         

end if;


if(data_reg = x"0B" and Duty > 24) then

    Duty <= 50;
    data_reg <= (others=> '0');          

end if;

if(data_reg = x"1B" and Duty > 24) then

    Duty <= 55;
    data_reg <= (others=> '0');          

end if;

if(data_reg = x"0C" and Duty > 24) then

    Duty <= 60;
    data_reg <= (others=> '0');           

end if;

if(data_reg = x"1C" and Duty > 24) then

    Duty <= 65;
    data_reg <= (others=> '0');           

end if;

if(data_reg = x"0D" and Duty > 24) then

     Duty <= 70;
     data_reg <= (others=> '0');           
     
end if;

if(data_reg = x"1D" and Duty > 24) then

     Duty <= 75;
     data_reg <= (others=> '0');           
     
end if;

if(data_reg = x"0E" and Duty > 24) then

     Duty <= 80;
     data_reg <= (others=> '0');                    

end if;

if(data_reg = x"1E" and Duty > 24) then

     Duty <= 85;
     data_reg <= (others=> '0');                    

end if;

if(data_reg = x"0F" and Duty > 24) then

     Duty <= 90;             
     data_reg <= (others=> '0');
     
end if;

end if;

-----------------------------------------------------------------------------------------------------------
----------------------------------------------CLOSED LOOP--------------------------------------------------

if(enable = '1') then

closed_l_led    <= '1';

if(rx_done_tick_o = '1') then

    data_reg <= data_o                                                    ;
    kp_cntr  <= '1';   

end if; 

	    dividend_data    <= conv_std_logic_vector(cntrl, 32)    ;
	    divisor_data     <= conv_std_logic_vector(dvs, 32)        ;
	       
    	dividend_valid   <= '1';
	    divisor_valid    <= '1';
        
     
        Duty <= conv_integer(quotient) + cntrl_2                 ;

if(data_reg = x"01") then

    ref <= "0000010011100010";     

end if;

if(data_reg = x"02") then

    ref <= "0000010111011100";
    
end if;

if(data_reg = x"03") then

    ref <= "0000011111010000";
   
end if;


if(data_reg = x"04" and Duty > 24) then

    ref <= "0000100111000100";           
    
end if;
end if;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------




case Hall_s is 
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
when "001" =>
				
	if(start_s = '1' and rst = '0') then
	
		if( forward_s = '1') then
			
			if(En = '1') then

                U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '1'											 		 ;
				W_H <= pwm											 		 ;
				W_L <= '0'											 		 ;


			    
			    dead_time <= 0                                               ;
			    
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ;
			
			end if;
			
		end if;		 
				
		if( reverse_s = '1') then		 
			
			if(En = '1') then

                U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= pwm											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '1'											 		 ;
			    
			    dead_time <= 0                                               ;
			     
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;		 
	
	end if;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------			 
when "011" =>		 
		
	if(start_s = '1'and rst = '0') then
	
		if( forward_s = '1') then		 
		
			if(En = '1') then
                
                U_H <= '0'											 		 ;
				U_L <= '1'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= pwm											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= 0                                               ;
			
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ;   
			
			end if;
			
		end if;		 
				
		if( reverse_s = '1') then		 
			
			if(En = '1') then

                U_H <= pwm											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '1'											 		 ;
			     
			    dead_time <= 0                                               ;
			
			else 
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;		 
	
	end if;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
			 
when "010" =>		 
	
	if(start_s = '1' and rst = '0') then
	
		if( forward_s = '1') then		 
			
			if(En = '1') then

                U_H <= '0'											 		 ;
				U_L <= '1'											 		 ;
				V_H <= pwm											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
			    
			    dead_time <= 0                                               ;
			
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;		 
				
		if( reverse_s = '1') then		 
			
			if( En = '1') then
                
                U_H <= pwm											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '1'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
			    
			    dead_time <= 0                                               ;
			
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;		 
	
	end if;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
			 
when "110" =>		 
	
	if(start_s = '1' and rst = '0') then
	
		if( forward_s = '1') then		 
		
			if(En = '1') then
                
                U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= pwm											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '1'											 		 ;

			    
			    dead_time <= 0                                               ;
			     
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;		 
				
		if( reverse_s = '1') then		 
			
			if(En = '1') then

                U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '1'											 		 ;
				W_H <= pwm											 		 ;
				W_L <= '0'											 		 ;
			     
			    dead_time <= 0                                               ;
			
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;		 
	
	end if;
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
			 
when "100" =>		 
		
	if(start_s = '1' and rst = '0') then
	
		if( forward_s = '1') then		 
			
			if(En = '1') then

                U_H <= pwm											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '1'											 		 ;
			
			    dead_time <= 0                                               ;
			
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;		 
				
		if( reverse_s = '1') then		 
			
			if(En = '1') then

                U_H <= '0'											 		 ;
				U_L <= '1'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= pwm											 		 ;
				W_L <= '0'											 		 ;
			 
			    dead_time <= 0                                               ;
			   
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;	

	end if;
			 
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
			 
when "101" =>		 
		
	if(start_s = '1' and rst = '0') then
	
		if( forward_s = '1') then		 
			
			if(En = '1') then

                U_H <= pwm											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '1'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;

			
			    dead_time <= 0                                               ;
			
			else
				
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;	 
				
		if( reverse_s = '1') then		 
			
			if(En = '1') then

                U_H <= '0'											 		 ;
				U_L <= '1'											 		 ;
				V_H <= pwm											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
			    
			    dead_time <= 0                                               ;
			    
			else
			
				U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;
				
				dead_time <= dead_time + 1									 ; 
			
			end if;
			
		end if;
	
	end if;

------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------

 when others => 
   
                U_H <= '0'											 		 ;
				U_L <= '0'											 		 ;
				V_H <= '0'											 		 ;
				V_L <= '0'											 		 ;
				W_H <= '0'											 		 ;
				W_L <= '0'											 		 ;             	
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------	
end case;
end if;
end process;
				
				pulse <= led_status											 ;

end Behavioral;