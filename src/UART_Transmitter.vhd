library ieee;
use ieee.std_logic_1164.all;

entity UART_Transmitter is
	generic( 
		MAX_DATA_WIDTH: integer := 8;
		SAMPLING_RATE: integer := 16						-- SAMPLING_RATE = (clock_frequency)/(BAUD_RATE_DIV*baud_rate)
		);
	port( tx_tick: in std_logic;							-- clk_frequency from baud rate generator
	      tx_data_in: in std_logic_vector(MAX_DATA_WIDTH-1 downto 0);		-- input DATA_WIDTH word
	      tx_start: in std_logic:= '1';						-- initiates the transmission
	      tx_en: in std_logic;							-- Request data transmission					
	      PRTEN: in std_logic;							-- Enables parity bit	      
	      DATA_WIDTH: in integer range 5 to 8;					-- Data length selected through CTRL_REG
	      tx_active: out std_logic;							-- '0' when inactive / '1' when transmission starts
	      tx_parity: out std_logic;							-- '0' when even / '1' when odd
	      tx_done: out std_logic;							-- 1 tick cycle done bit
	      tx_data_out: out std_logic);						-- output DATA_WIDTH bit by bit word
						
end UART_Transmitter;

architecture Behavioral of UART_Transmitter is

	type Transmitter_STATES is (TX_IDLE, TX_START_BIT, TX_DATA, TX_SAMPLE, TX_PARITY_CHECK, TX_STOP_BIT);
	signal TX_STATES: Transmitter_STATES := TX_IDLE;

	signal TX_data_INDEX: integer range 0 to MAX_DATA_WIDTH := 0;
	signal TX_CNTR: integer range 0 to SAMPLING_RATE := 0;

	signal TX_parity_bit: std_logic := '0';
	signal TX_active_bit: std_logic := '0';
	signal TX_data_word: std_logic_vector(MAX_DATA_WIDTH-1 downto 0);

begin

	process(tx_tick)

		variable parity: std_logic;

	begin

		if(rising_edge(tx_tick)) then
			case TX_STATES is
				when TX_IDLE =>						-- IDLE STATE => waits the start bit to go from high to low to begin transmitting
			
					TX_data_INDEX <= 0;
					tx_done <= '0';
					tx_data_out <= '1';
					TX_CNTR <= 0;
					TX_active_bit <= '0';
					TX_parity_bit <= '0';

					if(tx_start = '0' and tx_en = '1') then
						
						TX_active_bit <= '1';
						TX_data_word <= tx_data_in;
						TX_STATES <= TX_START_BIT;

					else
						
						TX_STATES <= TX_IDLE;

					end if;

				when TX_START_BIT =>					-- START_BIT STATE => when the start bit goes low it waits some "ticks" to start sampling data

					tx_data_out <= '0';

					if(TX_CNTR < SAMPLING_RATE/2 - 1) then

						TX_CNTR <= TX_CNTR + 1;
						TX_STATES <= TX_START_BIT;

					else

						TX_CNTR <= 0;
						TX_STATES <= TX_DATA;

					end if;
					
				when TX_DATA =>						-- DATA STATE => if all the word is read it sends it to STOP_BIT STATE, else it samples the input data
						
					if(TX_data_INDEX < DATA_WIDTH) then

						tx_data_out <= TX_data_word(TX_data_INDEX);
						TX_STATES <= TX_SAMPLE;

					else

						TX_STATES <= TX_PARITY_CHECK;

					end if;

				when TX_SAMPLE =>					-- SAMPLE STAE => samples the data 

					if(TX_CNTR < SAMPLING_RATE - 1) then

						TX_CNTR <= TX_CNTR + 1;
						TX_STATES <= TX_SAMPLE;

					else

						TX_data_INDEX <= TX_data_INDEX + 1;
						TX_CNTR <= 0;
						TX_STATES <= TX_DATA;

					end if;

				when TX_PARITY_CHECK =>					-- PARITY STATE => checks if parity is odd or even
	
					if(PRTEN = '1') then
						parity := '0';
						PARITY_LOOP: 
						for i in 0 to DATA_WIDTH-1 loop
							parity := parity xor TX_data_word(i);
						end loop;
						TX_parity_bit <= parity;
						tx_data_out <= parity;
						TX_STATES <= TX_STOP_BIT;
					else
						TX_parity_bit <= '0';
						TX_STATES <= TX_STOP_BIT;
					end if;
							
				when TX_STOP_BIT =>					-- STOP_BIT STATE => samples the stop bit and then goes to IDLE STATE again

					tx_data_out <= '1';
					if(TX_CNTR < SAMPLING_RATE - 1) then

						TX_CNTR <= TX_CNTR + 1;
						TX_STATES <= TX_STOP_BIT;

					else
						
						tx_done <= '1';
						TX_STATES <= TX_IDLE;

					end if;

				when others =>

					TX_STATES <= TX_IDLE;

			end case;
		end if;
	end process;

	tx_parity <= TX_parity_bit;
	tx_active <= TX_active_bit;
			
end Behavioral;