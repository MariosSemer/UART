library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_signal_generator is

	generic (
		FIFO_DEPTH : integer := 8);
	port (  i_rst: in std_logic;
	        i_clk: in std_logic;
		i_rd_en: in std_logic;
		i_wr_en: in std_logic;
		empty: out std_logic;
	        full: out std_logic);
		
end fifo_signal_generator;

architecture Behavioral of fifo_signal_generator is

	signal sig_COUNT: integer range 0 to FIFO_DEPTH:=0;
	signal fifo_full, fifo_empty: std_logic;

begin

	process(i_rst,i_clk)

	begin

		if(i_rst = '1') then
			sig_COUNT <= 0;
		elsif(rising_edge(i_clk)) then
 			if(i_wr_en = '1' and i_rd_en = '0') then
				sig_COUNT <= sig_COUNT + 1;
			elsif(i_wr_en = '0' and i_rd_en = '1') then
				sig_COUNT <= sig_COUNT - 1;
			end if;
		end if;

	end process;

	fifo_full <= '1' when sig_COUNT = FIFO_DEPTH else '0'; 
	fifo_empty <= '1' when sig_COUNT = 0 else '0'; 

	full <= fifo_full;
	empty <= fifo_empty;

end Behavioral;
