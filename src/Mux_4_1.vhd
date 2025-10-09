library ieee;
use ieee.std_logic_1164.all;

entity Mux_4_1 is

	port(	
		DTLEN: in std_logic_vector(1 downto 0);
		DATA_WIDTH: out integer range 5 to 8
	     );

end Mux_4_1;

architecture Behavioral of Mux_4_1 is

begin

	process(DTLEN)
	begin

		case DTLEN is
			when "00" 	=> DATA_WIDTH <= 5;
			when "01" 	=> DATA_WIDTH <= 6;
			when "10"	=> DATA_WIDTH <= 7;
			when others 	=> DATA_WIDTH <= 8;
		end case;

	end process;

end Behavioral;