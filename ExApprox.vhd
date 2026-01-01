Library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ExApprox is 
	port (
		clk : in STD_LOGIC;				-- xung clock
		reset : in STD_LOGIC;				-- ret mach
		start : in STD_LOGIC;				-- CPU kich hoat bat dau tinh
		x_in : in STD_LOGIC_VECTOR(31 downto 0);	-- gia tri dau vao x (Q16.16)
		done : out STD_LOGIC;				-- bao tinh xong
		result: out STD_LOGIC_VECTOR(31 downto 0)	-- ket qua
	);
end ExApprox;

architecture RTL of ExApprox is
	type state_type is (IDLE, COMPUTE, COMPLETE);		-- FSM co 3 trang thai cho, tinh toan va xuat ket qua
	signal state : state_type := IDLE;
	constant MAX_INTEGER : integer := 30;			-- so vong lap cho chuoi taylor
	constant ONE_Q16 : signed(63 downto 0) := to_signed(65536, 64);	-- gia tri dau tien trong chuoi taylor duoi dang so thuc 1.0
	
	signal x_reg : signed(63 downto 0);			-- noi luu tru x
	signal result_reg : signed(63 downto 0);		-- tong tich luy
	signal term : signed(63 downto 0);			-- hang tu hien tai cua chuoi taylor
	signal counter : integer range 0 to MAX_INTEGER + 1;	-- dem so vong lap
	
	function fp_mul(a, b : signed(63 downto 0)) return signed is	-- ham nhan fixed-point
		variable tmp : signed(127 downto 0);
	begin
		tmp := a * b;
		return tmp(79 downto 16);
	end function;

	function fp_div(a, b: signed(63 downto 0)) return signed is	-- ham chia fixed-point
		variable tmp : signed(127 downto 0);
	begin
		tmp := shift_left(resize(a, 128), 16);
		return resize(tmp / b, 64);
	end function;

begin 
	process(clk, reset)				-- procces dieu khien FSM + Datapath
	variable next_term : signed(63 downto 0);
	begin
		if reset = '1' then			-- reset toan bo ve trang thai ban dau
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
						x_reg <= resize(signed(x_in), 64);	-- luu x_in vao x_reg
						term <= ONE_Q16;			-- term = 1
						result_reg <= (others => '0');		-- result = 0
						counter <= 0;
						state <= COMPUTE;			-- chuyen trang thai COMPUTE
					end if;
		
				when COMPUTE =>
					result_reg <= result_reg + term;		-- cong hang tu hien tai vao ket qua
					if counter < MAX_INTEGER then			-- tinh hang tu tiep theo
						next_term := fp_div(
							fp_mul(term, x_reg),
							to_signed((counter + 1) * 65536, 64)
						);
						term <= next_term;			-- cap nhat term
						counter <= counter + 1;			-- tang bo dem
					else
						state <= COMPLETE;			-- het vong lap chuyen sang trang thai COMPLETE
					end if;

				when COMPLETE =>
					result <= std_logic_vector(result_reg(31 downto 0));	-- xuat ket qua ra cong result
					done <= '1';
					if start = '0' then					-- CPU ha start de quay ve IDLE
						state <= IDLE;
					end if;
			end case;
		end if;
	end process;
end RTL;

















