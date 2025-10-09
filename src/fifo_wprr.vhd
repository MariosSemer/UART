library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_wptr is

	generic (
		FIFO_DEPTH : integer := 8);
	port (  i_rst: in std_logic;
	        wr_clk: in std_logic;
		i_wr_en: in std_logic;
		full: in std_logic;
	        fifo_wr_addr: out integer range 0 to FIFO_DEPTH-1);
		
end fifo_wptr;

architecture Behavioral of fifo_wptr is
	
	signal sig_wr_ptr: integer range 0 to FIFO_DEPTH-1;

begin
	
	fifo_wr_addr <= sig_wr_ptr;

	process(wr_clk,i_rst)

	begin
	
		if(i_rst = '1') then
			sig_wr_ptr <= 0;
		elsif(rising_edge(wr_clk)) then
			if(i_wr_en = '1' and full = '0') then
				if(sig_wr_ptr = FIFO_DEPTH-1) then
					sig_wr_ptr <= 0;		--	ROLL OVER
				else
					sig_wr_ptr <= sig_wr_ptr + 1;
				end if;
			end if;
		end if;

	end process;

end Behavioral;
