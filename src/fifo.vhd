library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sync_fifo is
	generic (
    		WORD_WIDTH : natural := 8;
    		FIFO_DEPTH : integer := 8);
	port (  i_clk: in std_logic;
	        i_rst: in std_logic;
	        i_wr_en: in std_logic;
		i_rd_en: in std_logic;
		i_wr_data: in std_logic_vector(WORD_WIDTH-1 downto 0);
		o_rd_data: out std_logic_vector(WORD_WIDTH-1 downto 0);
		empty: out std_logic;
		full: out std_logic);
end sync_fifo;

architecture Behavioral of sync_fifo is 

	component fifo_wptr is
		generic (
			FIFO_DEPTH : integer := 8);
		port (  i_rst: in std_logic;
	        	wr_clk: in std_logic;
			i_wr_en: in std_logic;
			full: in std_logic;
	        	fifo_wr_addr: out integer range 0 to FIFO_DEPTH-1);
	end component;

	component fifo_rptr is
		generic (
			FIFO_DEPTH : integer := 8);
		port (  i_rst: in std_logic;
		        rd_clk: in std_logic;
			i_rd_en: in std_logic;
			empty: in std_logic;
	    	    	fifo_rd_addr: out integer range 0 to FIFO_DEPTH-1);
	end component;

	component fifo_signal_generator is
		generic (
			FIFO_DEPTH : integer := 8);
		port (  i_rst: in std_logic;
	        	i_clk: in std_logic;
			i_rd_en: in std_logic;
			i_wr_en: in std_logic;
			empty: out std_logic;
		        full: out std_logic);
	end component;

	component fifo_memory is
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
	end component;

	signal fifo_full, fifo_empty: std_logic;
	signal fifo_wr_en, fifo_rd_en: std_logic;
	signal sig_rd_addr,sig_wr_addr: integer range 0 to FIFO_DEPTH-1:=0;

begin
	
	fifo_wr_en <= i_wr_en and (not(fifo_full));
	fifo_rd_en <= i_rd_en and (not(fifo_empty));

	w_ptr: fifo_wptr port map(i_rst,i_clk,i_wr_en,fifo_full,sig_wr_addr);

	r_ptr: fifo_rptr port map(i_rst,i_clk,i_rd_en,fifo_empty,sig_rd_addr);

	sig_gen: fifo_signal_generator port map(i_rst,i_clk,fifo_rd_en,fifo_wr_en,fifo_empty,fifo_full);

	mem: fifo_memory port map(i_clk,fifo_wr_en,fifo_rd_en,sig_rd_addr,sig_wr_addr,i_wr_data,o_rd_data);

	full <= fifo_full;
	empty <= fifo_empty;

end Behavioral;
