library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debounce is

generic (

			c_clkfreq	: integer := 20_000_000;
			c_debtime	: integer := 1_000_000 ;
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

end debounce;

architecture Behavioral of debounce is

constant c_timerlim	: integer := c_clkfreq/c_debtime;

signal timer		: integer range 0 to c_timerlim := 0;
signal timer_en		: std_logic := '0';
signal timer_tick	: std_logic := '0';

type t_state is (S_INITIAL, S_ZERO, S_ZEROTOONE, S_ONE, S_ONETOZERO);

signal state_a : t_state := S_INITIAL;
signal state_b : t_state := S_INITIAL;
signal state_c : t_state := S_INITIAL;

begin

process (clk) begin

if (rising_edge(clk)) then

	case state_a is
		
		when S_INITIAL =>
			if (c_initval = '0') then
				state_a	<= S_ZERO;
			else
				state_a	<= S_ONE;
				end if;
		
		when S_ZERO =>
			signal_o_a	<= '0';
			if (signal_i_a = '1') then
				state_a	<= S_ZEROTOONE;
			end if;
		
		when S_ZEROTOONE =>
			signal_o_a	<= '0';
			timer_en	<= '1';
			if (timer_tick = '1') then
				state_a		<= S_ONE;
				timer_en	<= '0';
			end if;
			if (signal_i_a = '0') then
				state_a		<= S_ZERO;
				timer_en	<= '0';
			end if;
		
		when S_ONE =>
			signal_o_a	<= '1';
			if (signal_i_a = '0') then
				state_a	<= S_ONETOZERO;
			end if;		
		
		when S_ONETOZERO =>
			signal_o_a	<= '1';
			timer_en	<= '1';
			if (timer_tick = '1') then
				state_a		<= S_ZERO;
				timer_en	<= '0';
			end if;
			if (signal_i_a = '1') then
				state_a		<= S_ONE;
				timer_en	<= '0';
			end if;		
	end case;
	
	
	case state_b is
		when S_INITIAL =>
			if (c_initval = '0') then
				state_b	<= S_ZERO;		
			else
				state_b	<= S_ONE;
			end if;	
		when S_ZERO =>
			signal_o_b	<= '0';
			if (signal_i_b = '1') then	
				state_b	<= S_ZEROTOONE;
			end if;
		when S_ZEROTOONE =>
			signal_o_b	<= '0';
			timer_en	<= '1';
			if (timer_tick = '1') then
				state_b		<= S_ONE;
				timer_en	<= '0';
			end if;
			if (signal_i_b = '0') then
				state_b		<= S_ZERO;
				timer_en	<= '0';
			end if;
		when S_ONE =>
			signal_o_b	<= '1';
			if (signal_i_b = '0') then	
				state_b	<= S_ONETOZERO;
			end if;		
		when S_ONETOZERO =>
			signal_o_b	<= '1';
			timer_en	<= '1';	
			if (timer_tick = '1') then
				state_b		<= S_ZERO;
				timer_en	<= '0';
			end if;
			if (signal_i_b = '1') then
				state_b		<= S_ONE;
				timer_en	<= '0';
			end if;		
	end case;
	
	case state_c is
		when S_INITIAL =>
			if (c_initval = '0') then	
				state_c	<= S_ZERO;
			else
				state_c	<= S_ONE;
			end if;
		when S_ZERO =>
			signal_o_c	<= '0';
			if (signal_i_c = '1') then	
				state_c	<= S_ZEROTOONE;
			end if;
		when S_ZEROTOONE =>
			signal_o_c	<= '0';
			timer_en	<= '1';
			if (timer_tick = '1') then	
				state_c		<= S_ONE;
				timer_en	<= '0';
			end if;
			if (signal_i_c = '0') then
				state_c		<= S_ZERO;
				timer_en	<= '0';
			end if;
		when S_ONE =>
			signal_o_c	<= '1';
			if (signal_i_c = '0') then
				
				state_c	<= S_ONETOZERO;
			end if;		
		when S_ONETOZERO =>
			signal_o_c	<= '1';
			timer_en	<= '1';
			if (timer_tick = '1') then
				state_c		<= S_ZERO;
				timer_en	<= '0';
			end if;
			if (signal_i_c = '1') then
				state_c		<= S_ONE;
				timer_en	<= '0';
			end if;		
	end case;

end if;
end process;

P_TIMER : process (clk) begin

if (rising_edge(clk)) then

	if (timer_en = '1') then

		if (timer = c_timerlim-1) then

			timer_tick	<= '1';
			timer		<= 0;

		else

			timer_tick 	<= '0';
			timer 		<= timer + 1;

		end if;
	else

		timer		<= 0;
		timer_tick	<= '0';

	end if;

end if;
end process;

end Behavioral;