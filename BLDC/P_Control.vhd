library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
entity P_control is 
	port (
			clk  	  : in std_logic								;	
			rst		  : in std_logic								;
			ref       : in std_logic_vector(15 downto 0)			;
			actual    : in std_logic_vector(15 downto 0)			;
			enable	  : in std_logic								;
			kp        : in integer :=215                            ; 
			ki        : in integer := 2*188                         ;
			Cntrl     : out integer                                 ;                   
		    Cntrl_2   : out integer
		 );
end P_control;
architecture Behavioral of P_control is
  component div_gen_1
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
	signal error 		: integer range 0 to 4000   		            ;
	signal error_p      : integer range 0 to 4000                       ;
	signal error_n      : integer range 0 to 4000                       ;
	signal Kp_i		    : integer  := 4 * 188            			    ;
	constant dvs        : integer  := 32767                             ;
	signal divisor_valid    : std_logic                                      ;
    signal divisor_data     : std_logic_vector(31 downto 0):= (others=>'0')  ;
    signal dividend_valid   : std_logic                                      ;
    signal dividend_data    : std_logic_vector(31 downto 0):= (others=>'0')  ; 
    signal dout_valid       : std_logic                                      ;
    signal dout_user        : std_logic_vector(0 downto 0)                   ;
    signal Quotient         : std_logic_vector (31 downto 0):= (others=>'0') ;
    signal Fractional       : std_logic_vector (31 downto 0):= (others=>'0') ;
    signal Cntrl_q          : integer                                        ;
    signal cntrl_s_2        : integer                                        ;
    signal quotient_last    : std_logic_vector(15 downto 0)                  ;
    
begin
---------------------------------------------------------------------------
i_div_gen_1 : div_gen_1
  PORT MAP (
    aclk =>  clk,
    s_axis_divisor_tvalid  =>   divisor_valid           ,
    s_axis_divisor_tdata   =>   divisor_data            ,
    s_axis_dividend_tvalid =>   dividend_valid          ,
    s_axis_dividend_tdata  =>   dividend_data           ,
    m_axis_dout_tvalid     =>   dout_valid              ,
    m_axis_dout_tdata (63 downto 32)     =>   quotient(31 downto 0)  ,
    m_axis_dout_tdata (31 downto 0)      =>   fractional(31 downto 0)  
  );
----------------------------------------------------------------------------	
	process (clk, rst)
	begin
	
		if(rising_edge(clk)) then
			if(rst = '1') then
				Cntrl <= 0;
				error <= 0;
			end if;
			if(enable = '1') then
				error 		<= conv_integer(ref) - conv_integer(actual)   ;
			    Cntrl     <= error * Kp_i                                 ;
			    cntrl_s_2 <= error * ki                                   ;
			 else 
			    cntrl <= 0												  ;
				cntrl_2<=0												  ;
			end if;
			
			    dividend_data    <= conv_std_logic_vector(cntrl_s_2, 32)    ;
			    divisor_data     <= conv_std_logic_vector(dvs, 32)        	;
			    
			    dividend_valid   <= '1'										;
			    divisor_valid    <= '1'										;
			    cntrl_2 <= conv_integer(quotient)                           ;
	
		end if;
	end process;
end Behavioral;