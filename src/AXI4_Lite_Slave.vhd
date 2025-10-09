library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXI4_Lite_Slave is
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

end AXI4_Lite_Slave;

architecture Behavioral of AXI4_Lite_Slave is

	signal axi_awready    : std_logic := '0';
  	signal axi_wready     : std_logic := '0';
  	signal axi_bvalid     : std_logic := '0';
  	signal axi_arready    : std_logic := '0';
  	signal axi_rvalid     : std_logic := '0';
  	signal axi_rdata      : std_logic_vector(7 downto 0) := (others => '0');
	signal zeros	      : std_logic_vector(23 downto 0) := (others => '0');

  	signal axi_write_addr : std_logic_vector(31 downto 0);
  	signal axi_read_addr  : std_logic_vector(31 downto 0);

begin

	awready <= axi_awready;
	wready <= axi_wready;
	bvalid <= axi_bvalid;
	arready <= axi_arready;
	rvalid <= axi_rvalid;

	clk <= aclk;
	rst <= not aresetn;

	WRITE_PROCESS: process(aclk)
	begin
		if(rising_edge(aclk)) then
			if(aresetn = '0') then
				axi_awready <= '0';
				axi_wready <= '0';
				axi_bvalid <= '0';
				axi_write_addr <= (others => '0');
				axi_rdata <= (others => '0');
			else
			
				-- WRITE ADDRESS HANDSHAKE --

				if(axi_awready = '0' and awvalid = '1') then		-- SEE WHEN WRITE ADDRESS AND WRITE DATA ARE READY TO MANIPULATE THE READY SIGNALS CORRECTLY --
					axi_awready <= '1';
					axi_write_addr <= awaddr;
				else
					axi_awready <= '0';
				end if;

				-- WRITE DATA HANDSHAKE --

				if(axi_wready = '0' and wvalid = '1') then		-- SEE WHEN WRITE ADDRESS AND WRITE DATA ARE READY TO MANIPULATE THE READY SIGNALS CORRECTLY --
					axi_wready <= '1';
					tx_wr_en <= '1';
					case axi_write_addr is

						-- CONTROL REGISTER --

						when X"00000000" =>
							if(wstrb(0) = '1') then
								CTRL_REG<=wdata(7 downto 0);
							end if;
							bresp <= "00";

						-- TX FIFO DATA --

						when X"0000000C" =>
							if(STATUS_REG_1(3) = '0') then
								if(wstrb(0) = '1') then
									tx_data_out <= wdata(7 downto 0);
								end if;
								bresp <= "00";
							else
								bresp <= "10";
							end if;
						when others =>
							bresp <= "10";
					end case;
				else
					axi_wready <= '0';
				end if;

				-- WRITE RESPONSE HANDSHAKE --

				if(axi_awready = '1' and awvalid = '1' and axi_wready = '1' and wvalid = '1' and axi_bvalid = '0') then
            				axi_bvalid <= '1';
        			elsif bready = '1' and axi_bvalid = '1' then
            				axi_bvalid <= '0';
        			end if;
			end if;
		end if;
	end process;

	READ_PROCESS: process(aclk)
	begin
		if(rising_edge(aclk)) then
			if(aresetn = '0') then
				axi_arready <= '0';
				axi_rvalid <= '0';
				rdata <= (others => '0');
				axi_read_addr <= (others => '0');
			else

				-- READ ADDRESS HANDSHAKE --

				if(arvalid = '1' and axi_arready = '0') then
					axi_arready <= '1';
					axi_read_addr <= araddr;
				else
					axi_arready <= '0';
				end if;

				-- READ DATA HANDSHAKE --

				if(rready = '1' and axi_rvalid = '0' and arvalid = '1' and axi_arready = '1') then
					axi_rvalid <= '1';
					rx_rd_en <= '1';
					case axi_read_addr is

						-- STATUS REGISTER 1 --

						when X"00000004" =>
							rdata <= zeros & STATUS_REG_1;
							rresp <= "00";

						-- STATUS REGISTER 2 --

						when X"00000008" => 
							rdata <= zeros & STATUS_REG_2;
							rresp <= "00";

						-- RX FIFO DATA --

						when X"00000010" =>
							if(STATUS_REG_2(2) = '0') then
								rdata <= zeros & rx_data_in;
								rresp <= "00";
							else
								rdata <= (others => '0');
							end if;
						when others =>
							rdata <= (others => '0');
					end case;
				elsif(rready = '1' and axi_rvalid = '1') then
					axi_rvalid <= '0';
				end if;
			end if;
		end if;
	end process;

end Behavioral;