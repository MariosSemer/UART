library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity fifo_memory is
	generic (
    		WORD_WIDTH : natural := 8;
    		FIFO_DEPTH : integer := 8);
	port (  wr_clk: in std_logic;
	        fifo_wr_en: in std_logic;
		fifo_rd_en: in std_logic;
	        fifo_rd_addr: in integer range 0 to FIFO_DEPTH-1;
		fifo_wr_addr: in integer range 0 to FIFO_DEPTH-1;
		i_fifo_data: in std_logic_vector(WORD_WIDTH-1 downto 0);
		o_fifo_data: out std_logic_vector(WORD_WIDTH-1 downto 0));
end fifo_memory;

architecture Behavioral of fifo_memory is

type fifo_mem is array (FIFO_DEPTH-1 downto 0) of std_logic_vector(WORD_WIDTH-1 downto 0);
signal fifo_registers : fifo_mem;

begin

	process(wr_clk)
	begin
		if(rising_edge(wr_clk)) then
			if(fifo_wr_en = '1') then
				fifo_registers(fifo_wr_addr) <= i_fifo_data;
			end if;
		end if;
	end process;

	o_fifo_data <= fifo_registers(fifo_rd_addr);
	
end Behavioral;
