-------------------------------------------------------------------------------------------------------
	library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL; 
	
	entity pwm_gen is
	generic(
			clk_frq 	: integer := 20_000_000						;    --clock frekans değeri
			pwm_frq 	: integer := 20_000                              --pwm frekans değeri
	);
	Port (
			clk         : in std_logic                              ;    --clock girişi
			Duty        : in integer range 0 to 100 := 0            ;    --Duty Cycle değer girişi
			pwm_o       : out std_logic
			
	);
	end pwm_gen;

architecture Behavioral of pwm_gen is
        
        constant timer_Lmt   : integer := clk_frq/pwm_frq        ;    --sayıcının sıfırlanması gereken limit değer
        signal   On_time     : integer range 0 to timer_Lmt      ;    --pwm sinyalinin high konumu
        signal   timer       : integer range 0 to timer_Lmt      ;    --sayıcı tanımlaması
       

begin
        On_time <= (timer_Lmt/100)*Duty						    ; 
    
	process (clk) 
    begin
    
    if (rising_edge(clk)) then 
        
        if (timer = timer_Lmt-1) then 
            
            timer <= 0											; 	 -- timer sıfırlanması
        
        
        elsif (timer < On_time) then
            
            pwm_o			<= '1'								; 	 --pwm çıkışı '1' konumu
            timer   <= timer + 1								;
        
        else
            
            pwm_o <= '0'										; 	 --pwm çıkışı '0' konumu
            timer   <= timer + 1								;
            
            end if;
        end if;
        
    end process;    
end Behavioral;
