library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_rate_generator is
	generic( 
		 CLK_FREQ: integer := 100000000				-- CLK_FREQ = 100 MHz
		);			
	port( axi_clk: in std_logic;					-- sys_clk coming from AXI4 Lite interface
	      axi_rst: in std_logic;					-- sys_rst coming from AXI4 Lite interface
	      BDSEL: in std_logic_vector(1 downto 0);			-- baud rate select bits from CONTROL register
	      tick: out std_logic);					-- clk for the Transmitter and Reciever		
						
end baud_rate_generator;

architecture Behavioral of baud_rate_generator is

	signal r_tick: std_logic :='0';
	signal counter: integer :=0;
	signal BAUD_RATE: integer;					-- baud = bits per second
	signal DIV: integer;						-- devides the clock frequency

begin

	-- baud selection multiplexer

	with BDSEL select
    		BAUD_RATE <= 2400  when "00",
                     	     4800  when "01",
                   	     9600  when "10",
                    	     19200  when "11",
			     9600 when others;

	DIV <= CLK_FREQ/BAUD_RATE;

	-- "ticks" every DIV clock cycles

	process(axi_clk,axi_rst)
	begin

		if(axi_rst = '1') then
			r_tick <= '0';
		elsif(rising_edge(axi_clk)) then
			if(counter = DIV) then
				r_tick <= '1';
				counter <= 0;
			else
				r_tick <= '0';
				counter <= counter + 1;
			end if;
		end if;

	end process;

	tick <= r_tick;

end Behavioral;