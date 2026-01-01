Library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ExApprox is 
	port (
		clk : in STD_LOGIC;
		reset : in STD_LOGIC;
		start : in STD_LOGIC;
		x_in : in STD_LOGIC_VECTOR(31 downto 0);
		done : out STD_LOGIC;
		result: out STD_LOGIC_VECTOR(31 downto 0)
	);
end ExApprox;

architecture RTL of ExApprox is
	type state_type is (IDLE, COMPUTE, COMPLETE);
	signal state : state_type := IDLE;
	constant MAX_INTEGER : integer := 30;
	constant ONE_Q16 : signed(63 downto 0) := to_signed(65536, 64);
	
	signal x_reg : signed(63 downto 0);
	signal result_reg : signed(63 downto 0);
	signal term : signed(63 downto 0);
	signal counter : integer range 0 to MAX_INTEGER + 1;
	
	function fp_mul(a, b : signed(63 downto 0)) return signed is
		variable tmp : signed(127 downto 0);
	begin
		tmp := a * b;
		return tmp(79 downto 16);
	end function;

	function fp_div(a, b: signed(63 downto 0)) return signed is
		variable tmp : signed(127 downto 0);
	begin
		tmp := shift_left(resize(a, 128), 16);
		return resize(tmp / b, 64);
	end function;

begin 
	process(clk, reset)
	variable next_term : signed(63 downto 0);
	begin
		if reset = '1' then
			state <= IDLE;
			done <= '0';
			result <= (others => '0');
			term <= (others => '0');
			result_reg <= (others => '0');
			x_reg <= (others => '0');
			counter <= 0;

		elsif rising_edge(clk) then
			case state is
				when IDLE =>
					done <= '0';
					if start = '1' then
						x_reg <= resize(signed(x_in), 64);
						term <= ONE_Q16;
						result_reg <= (others => '0');
						counter <= 0;
						state <= COMPUTE;
					end if;
		
				when COMPUTE =>
					result_reg <= result_reg + term;
					if counter < MAX_INTEGER then
						next_term := fp_div(
							fp_mul(term, x_reg),
							to_signed((counter + 1) * 65536, 64)
						);
						term <= next_term;
						counter <= counter + 1;
					else
						state <= COMPLETE;
					end if;

				when COMPLETE =>
					result <= std_logic_vector(result_reg(31 downto 0));
					done <= '1';
					if start = '0' then
						state <= IDLE;
						done <= '0';
					end if;
			end case;
		end if;
	end process;
end RTL;


































	
		
