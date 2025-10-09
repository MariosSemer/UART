library ieee;
use ieee.std_logic_1164.all;

entity AXI4_Lite_UART_Slave is
	generic( 
		MAX_DATA_WIDTH: integer := 8
		);
	port(   
		-- CLOCK AND RESET --
		
		aclk: in std_logic;
		aresetn: in std_logic;

		-- READ ADDRESS CHANNEL --

		araddr: in std_logic_vector(31 downto 0);
		arprot: in std_logic_vector(2 downto 0);
		arvalid: in std_logic;
		arready: out std_logic;

		-- READ DATA CHANNEL --

		rdata: out std_logic_vector(31 downto 0);
		rresp: out std_logic_vector(1 downto 0);
		rvalid: out std_logic;
		rready: in std_logic;

		-- WRITE ADDRESS CHANNEL --

		awaddr: in std_logic_vector(31 downto 0);
		awprot: in std_logic_vector(2 downto 0);
		awvalid: in std_logic;
		awready: out std_logic;

		-- WRITE DATA CHANNEL --

		wdata: in std_logic_vector(31 downto 0);
		wstrb: in std_logic_vector(3 downto 0);
		wvalid: in std_logic;
		wready: out std_logic;

		-- WRITE RESPONSE CHANNEL --

		bresp: out std_logic_vector(1 downto 0);
		bvalid: out std_logic;
		bready: in std_logic;

		-- I/O FROM TX AND RX --

		tx_data_out: out std_logic;
		rx_data_in: in std_logic

	);
end AXI4_Lite_UART_Slave;

architecture Behavioral of AXI4_Lite_UART_Slave is

	component AXI4_Lite_Slave is
		port(   
			-- CLOCK AND RESET --
		
			aclk: in std_logic;
			aresetn: in std_logic;

			-- READ ADDRESS CHANNEL --

			araddr: in std_logic_vector(31 downto 0);
			arprot: in std_logic_vector(2 downto 0);
			arvalid: in std_logic;
			arready: out std_logic;

			-- READ DATA CHANNEL --

			rdata: out std_logic_vector(31 downto 0);
			rresp: out std_logic_vector(1 downto 0);
			rvalid: out std_logic;
			rready: in std_logic;

			-- WRITE ADDRESS CHANNEL --

			awaddr: in std_logic_vector(31 downto 0);
			awprot: in std_logic_vector(2 downto 0);
			awvalid: in std_logic;
			awready: out std_logic;

			-- WRITE DATA CHANNEL --

			wdata: in std_logic_vector(31 downto 0);
			wstrb: in std_logic_vector(3 downto 0);
			wvalid: in std_logic;
			wready: out std_logic;

			-- WRITE RESPONSE CHANNEL --

			bresp: out std_logic_vector(1 downto 0);
			bvalid: out std_logic;
			bready: in std_logic;

			-- CSR interface --

			CTRL_REG: out std_logic_vector(7 downto 0);
			STATUS_REG_1: in std_logic_vector(7 downto 0);
			STATUS_REG_2: in std_logic_vector(7 downto 0);

			-- I/O FROM TX_FIFO AND RX_FIFO --

			tx_data_out: out std_logic_vector(7 downto 0);
			tx_wr_en: out std_logic;
			rx_data_in: in std_logic_vector(7 downto 0);
			rx_rd_en: out std_logic;

			-- CLOCK AND RESET OF THE SLAVE --

			clk: out std_logic;
			rst: out std_logic
		);

	end component;

	component UART_Transmitter is
		generic( 
			MAX_DATA_WIDTH: integer := 8;
			SAMPLING_RATE: integer := 16						-- SAMPLING_RATE = (clock_frequency)/(BAUD_RATE_DIV*baud_rate)
			);
		port( 	tx_tick: in std_logic;							-- clk_frequency from baud rate generator
	      		tx_data_in: in std_logic_vector(MAX_DATA_WIDTH-1 downto 0);		-- input DATA_WIDTH word
	      		tx_start: in std_logic:= '1';						-- initiates the transmission
	      		tx_en: in std_logic;							-- Request data transmission					
	      		PRTEN: in std_logic;							-- Enables parity bit	      
	      		DATA_WIDTH: in integer range 5 to 8;					-- Data length selected through CTRL_REG
	      		tx_active: out std_logic;						-- '0' when inactive / '1' when transmission starts
	      		tx_parity: out std_logic;						-- '0' when even / '1' when odd
	      		tx_done: out std_logic;							-- 1 tick cycle done bit
	      		tx_data_out: out std_logic);						-- output DATA_WIDTH bit by bit word
						
	end component;

	component UART_Reciever is
		generic( 
			MAX_DATA_WIDTH: integer := 8;
			SAMPLING_RATE: integer := 16						-- SAMPLING_RATE = (clock_frequency)/(BAUD_RATE_DIV*baud_rate)
			);
		port( 	rx_tick: in std_logic;							-- clk_frequency from baud rate generator
	      		rx_data_in: in std_logic;							-- serial input word, it is '1' and the recieving starts when it goes low
	      		rx_en: in std_logic;							-- Request data reception						
	      		PRTEN: in std_logic;							-- Enables parity bit	      
	     		DATA_WIDTH: in integer range 5 to 8;
	    		rx_done: out std_logic;							-- 1 tick cycle done bit
	    		rx_parity: out std_logic;						-- '0' when even / '1' when odd
	     		rx_active: out std_logic;						-- '0' when inactive / '1' when transmission starts
	    		rx_data_out: out std_logic_vector(MAX_DATA_WIDTH-1 downto 0));		-- output DATA_WIDTH word
						
	end component;

	component baud_rate_generator is
		generic( 
		 	CLK_FREQ: integer := 100000000						-- CLK_FREQ = 100 MHz
			);			
		port( 	axi_clk: in std_logic;							-- sys_clk coming from AXI4 Lite interface
	      		axi_rst: in std_logic;							-- sys_rst coming from AXI4 Lite interface
	      		BDSEL: in std_logic_vector(1 downto 0);					-- baud rate select bits from CONTROL register
	      		tick: out std_logic);							-- clk for the Transmitter and Reciever		
						
	end component;

	component sync_fifo is
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
	end component;

	component Mux_4_1 is

		port(	
			DTLEN: in std_logic_vector(1 downto 0);
			DATA_WIDTH: out integer range 5 to 8
	     	);

	end component;

	signal axi_arready, axi_rvalid, axi_awready, axi_wready, axi_bvalid: std_logic;

	signal clkn, rstn: std_logic;

	signal tx_full, tx_empty, tx_wr_en, tx_rd_en, tx_active, tx_parity, tx_done, tx_fifo_wr_en: std_logic;

	signal rx_full, rx_empty, rx_rd_en, rx_wr_en, rx_active, rx_fifo_rd_en, rx_done, rx_parity, rx_en: std_logic;

	signal tx_fifo_data_out, tx_fifo_data_in, tx_axi_data_out: std_logic_vector(MAX_DATA_WIDTH-1 downto 0);

	signal rx_fifo_data_out, rx_fifo_data_in, rx_axi_data_in: std_logic_vector(MAX_DATA_WIDTH-1 downto 0);

	signal CTRL_REG, STATUS_REG_1, STATUS_REG_2:std_logic_vector(MAX_DATA_WIDTH-1 downto 0);

	signal tx_en, tick: std_logic;

	signal BDSEL, DTLEN: std_logic_vector(1 downto 0);

	signal STRTBT, PRTEN: std_logic;

	signal DATA_WIDTH: integer range 5 to 8;

begin

	AXI4LITESLAVE: AXI4_Lite_Slave port map(
						aclk => aclk,
						aresetn => aresetn,
						araddr => araddr,
						arprot => arprot,
						arvalid => arvalid,
						arready => arready,
						rdata => rdata,
						rresp => rresp,
						rvalid => rvalid,
						rready => rready,
						awaddr => awaddr,
						awprot => awprot,
						awvalid => awvalid,
						awready => awready,
						wdata => wdata,
						wstrb => wstrb,
						wvalid => wvalid,
						wready => wready,
						bresp => bresp,
						bvalid => bvalid,
						bready => bready,
						CTRL_REG => CTRL_REG,
						STATUS_REG_1 => STATUS_REG_1,
						STATUS_REG_2 => STATUS_REG_2,
						tx_data_out => tx_axi_data_out,
						tx_wr_en => tx_wr_en,
						rx_data_in => rx_axi_data_in,
						rx_rd_en => rx_rd_en,
						clk => clkn,
						rst => rstn
						);

	rx_wr_en <= rx_active and rx_done;
	rx_fifo_rd_en <= rx_rd_en;
	STATUS_REG_2(4) <= rx_fifo_rd_en;
	STATUS_REG_2(5) <= rx_wr_en;
	tx_rd_en <= tx_en;
	tx_fifo_wr_en <= tx_wr_en;
	STATUS_REG_1(4) <= tx_rd_en;
	STATUS_REG_1(5) <= tx_fifo_wr_en;

	RX_FIFO: sync_fifo port map(
					i_clk => clkn,
	        			i_rst => rstn,
	        			i_wr_en => rx_wr_en,
					i_rd_en => rx_fifo_rd_en,
					i_wr_data => rx_fifo_data_in,
					o_rd_data => rx_fifo_data_out,
					empty => rx_full,
					full => rx_empty
					);
	
	rx_axi_data_in <= rx_fifo_data_out;

	STATUS_REG_1(2) <= rx_empty;
	STATUS_REG_1(3) <= rx_full;

	TX_FIFO: sync_fifo port map(
					i_clk => clkn,
	        			i_rst => rstn,
	        			i_wr_en => tx_fifo_wr_en,
					i_rd_en => tx_rd_en,
					i_wr_data => tx_fifo_data_in,
					o_rd_data => tx_fifo_data_out,
					empty => tx_full,
					full => tx_empty
					);

	tx_fifo_data_in <= tx_axi_data_out;

	STATUS_REG_2(2) <= tx_empty;
	STATUS_REG_2(3) <= tx_full;

	-- tx_en <= tx_rd_en and (not(tx_active)) and (not(tx_empty));
	-- rx_en <= rx_wr_en and rx_active and (not(rx_full));

	BDSEL <= CTRL_REG(3 downto 2);

	BDRTGENERATOR: baud_rate_generator port map(
							axi_clk => clkn,
	      						axi_rst => rstn,
	      						BDSEL => BDSEL,
	      						tick => tick
							);

	DTLEN <= CTRL_REG(5 downto 4);

	MUX4to1: Mux_4_1 port map(
					DTLEN => DTLEN,
					DATA_WIDTH => DATA_WIDTH
					);

	STRTBT <= CTRL_REG(1);
	PRTEN <= CTRL_REG(0);
	rx_en <= CTRL_REG(7);
	tx_en <= CTRL_REG(6);

	UART_TX: Uart_Transmitter port map(
						tx_tick => tick,
	      					tx_data_in => tx_fifo_data_out,
	      					tx_start => STRTBT,
	     					tx_en => tx_en,
	      					PRTEN => PRTEN,
	      					DATA_WIDTH => DATA_WIDTH,
	      					tx_active => tx_active,
	      					tx_parity => tx_parity,
	      					tx_done => tx_done,
	      					tx_data_out => tx_data_out
						);

	STATUS_REG_1(0) <= tx_active;
	STATUS_REG_1(1) <= tx_parity;

	UART_RX: UART_Reciever port map(
						rx_tick => tick,
	      					rx_data_in => rx_data_in,
	      					rx_en => rx_en,
	      					PRTEN => PRTEN,
	      					DATA_WIDTH => DATA_WIDTH,
	     					rx_done => rx_done,
	     					rx_parity => rx_parity,
	     					rx_active => rx_active,
	     					rx_data_out => rx_fifo_data_in
						);

	STATUS_REG_2(0) <= rx_active;
	STATUS_REG_2(1) <= rx_parity;

end Behavioral;