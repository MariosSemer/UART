library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_rptr is

	generic (
		FIFO_DEPTH : integer := 8);
	port (  i_rst: in std_logic;
	        rd_clk: in std_logic;
		i_rd_en: in std_logic;
		empty: in std_logic;
	        fifo_rd_addr: out integer range 0 to FIFO_DEPTH-1);
		
end fifo_rptr;

architecture Behavioral of fifo_rptr is
	
	signal sig_rd_ptr: integer range 0 to FIFO_DEPTH-1;

begin
	
	fifo_rd_addr <= sig_rd_ptr;

	process(rd_clk,i_rst)

	begin
	
		if(i_rst = '1') then
			sig_rd_ptr <= 0;
		elsif(rising_edge(rd_clk)) then
			if(i_rd_en = '1' and empty = '0') then
				if(sig_rd_ptr = FIFO_DEPTH-1) then
					sig_rd_ptr <= 0;		--	ROLL OVER
				else
					sig_rd_ptr <= sig_rd_ptr + 1;
				end if;
			end if;
		end if;

	end process;

end Behavioral;

