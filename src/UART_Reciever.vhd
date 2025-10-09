library ieee;
use ieee.std_logic_1164.all;

entity UART_Reciever is
	generic(
		MAX_DATA_WIDTH: integer := 8; 
		SAMPLING_RATE: integer := 16						-- SAMPLING_RATE = (clock_frequency)/(BAUD_RATE_DIV*baud_rate)
		);
	port( rx_tick: in std_logic;							-- clk_frequency from baud rate generator
	      rx_data_in: in std_logic;							-- serial input word, it is '1' and the recieving starts when it goes low
	      rx_en: in std_logic;							-- Request data reception						
	      PRTEN: in std_logic;							-- Enables parity bit	      
	      DATA_WIDTH: in integer range 5 to 8;
	      rx_done: out std_logic;							-- 1 tick cycle done bit
	      rx_parity: out std_logic;							-- '0' when even / '1' when odd
	      rx_active: out std_logic;							-- '0' when inactive / '1' when transmission starts
	      rx_data_out: out std_logic_vector(MAX_DATA_WIDTH-1 downto 0));		-- output DATA_WIDTH word
						
end UART_Reciever;

architecture Behavioral of UART_Reciever is

	type Reciever_STATES is (RX_IDLE, RX_START_BIT, RX_DATA, RX_SAMPLE, RX_PARITY_CHECK, RX_STOP_BIT);
	signal RX_STATES: Reciever_STATES := RX_IDLE;

	signal RX_data_INDEX: integer range 0 to MAX_DATA_WIDTH := 0;
	signal RX_CNTR: integer range 0 to SAMPLING_RATE := 0;

	signal RX_active_bit: std_logic := '0';
	signal RX_parity_bit: std_logic := '0';

	signal RX_data_word: std_logic_vector(MAX_DATA_WIDTH-1 downto 0);

begin
                    	     	
	process(rx_tick)

		variable parity: std_logic;

	begin

		if(rising_edge(rx_tick)) then
			case RX_STATES is
				when RX_IDLE =>						-- IDLE STATE => waits the start bit to go from high to low to begin transmitting
			
					RX_data_INDEX <= 0;
					rx_done <= '0';
					RX_CNTR <= 0;
					RX_active_bit <= '0';
					RX_parity_bit <= '0';

					if(rx_data_in = '0' and rx_en = '1') then
						
						RX_active_bit <= '1';
						RX_STATES <= RX_START_BIT;

					else
						
						RX_STATES <= RX_IDLE;

					end if;

				when RX_START_BIT =>					-- START_BIT STATE => when the start bit goes low it waits some "ticks" to start sampling data

					if(RX_CNTR < SAMPLING_RATE/2 - 1) then

						RX_CNTR <= RX_CNTR + 1;
						RX_STATES <= RX_START_BIT;

					else

						RX_CNTR <= 0;
						RX_STATES <= RX_DATA;

					end if;
					
				when RX_DATA =>						-- DATA STATE => if all the word is read it sends it to STOP_BIT STATE, else it samples the input data
						
					if(RX_data_INDEX < DATA_WIDTH) then

						RX_STATES <= RX_SAMPLE;

					else	
						if(MAX_DATA_WIDTH /= DATA_WIDTH) then
							RX_data_word(MAX_DATA_WIDTH-1 downto DATA_WIDTH) <= (others => '0');
						end if;
						RX_STATES <= RX_PARITY_CHECK;

					end if;

				when RX_SAMPLE =>					-- SAMPLE STAE => samples the data at the midpoint

					if(RX_CNTR < SAMPLING_RATE - 1) then

						RX_CNTR <= RX_CNTR + 1;
						RX_STATES <= RX_SAMPLE;

					else

						RX_data_word(RX_data_INDEX) <= rx_data_in;
						RX_data_INDEX <= RX_data_INDEX + 1;
						RX_CNTR <= 0;
						RX_STATES <= RX_DATA;

					end if;
							
				when RX_PARITY_CHECK =>					-- PARITY STATE => checks if parity is odd or even
					
					if(PRTEN = '1') then
						parity := '0';
						PARITY_LOOP: 
						for i in 0 to DATA_WIDTH-1 loop
							parity := parity xor RX_data_word(i);
						end loop;
						RX_parity_bit <= parity;
						RX_STATES <= RX_STOP_BIT;
					else
						RX_parity_bit <= '0';
						RX_STATES <= RX_STOP_BIT;
					end if;				

				when RX_STOP_BIT =>					-- STOP_BIT STATE => samples the stop bit and then goes to IDLE STATE again

					rx_done <= '1';
					if(RX_CNTR < SAMPLING_RATE - 1) then

						RX_CNTR <= RX_CNTR + 1;
						RX_STATES <= RX_STOP_BIT;

					else

						RX_STATES <= RX_IDLE;

					end if;

				when others =>

					RX_STATES <= RX_IDLE;

			end case;
		end if;
	end process;

	rx_data_out <= RX_data_word;
	rx_active <= RX_active_bit;
	rx_parity <= RX_parity_bit;

end Behavioral;