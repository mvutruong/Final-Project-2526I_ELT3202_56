Library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ExApprox_tb is
end ExApprox_tb;

architecture sim of ExApprox_tb is		-- khai bao tin hieu mo phong
	signal clk : std_logic := '0';
	signal reset : std_logic := '1';
	signal start : std_logic := '0';
	signal x_in : std_logic_vector(31 downto 0) := (others => '0');
	signal done : std_logic;
	signal result : std_logic_vector(31 downto 0);
	signal result_real : real;		-- ket qua duoi dang so thuc

	constant CLK_PERIOD : time := 10 ns;	-- chu ki clock

	component ExApprox
		port (
			clk : in std_logic;
			reset : in std_logic;
			start : in std_logic;
			x_in : in std_logic_vector(31 downto 0);
			done : out std_logic;
			result : out std_logic_vector(31 downto 0)
		);
	end component;

begin
	UUT: ExApprox				-- noi testbench voi mach ExAppox
		port map (
			clk => clk,
			reset => reset,
			start => start,
			x_in => x_in,
			done => done,
			result => result
		);
	result_real <= real(to_integer(signed(result))) / 65536.0;	-- chuyen ket qua sang dang so thuc

clk_process :process
begin					-- tao clock vuong lien tuc
	clk <= '0';
	wait for CLK_PERIOD/2;
	clk <= '1';
	wait for CLK_PERIOD/2;
end process;

stim_proc : process			-- dieu khien reset, start va du lieu test
procedure run_test(val : real) is
	variable q16 : integer;
begin
	start <= '0';
	wait for CLK_PERIOD;
	if done = '1' then		-- dam bao mach o trang thai IDLE trach kich hoat khi mach chua san sang
		wait until done = '0';
		wait for CLK_PERIOD;
	end if;

	q16 := integer(val * 65536.0);
	x_in <= std_logic_vector(to_signed(q16, 32));	-- chuyen x sang fixed-point
	start <= '1';					-- start len muc 1 trong 1 chu ky
	wait for CLK_PERIOD;
	start <= '0';
	wait until done = '1';				-- cho mach tinh xong FSM sang COMPLETE
	wait for CLK_PERIOD;
	wait for 0 ns;
	report "x = " & real'image(val) & " => exp(x) = " & real'image(result_real);	-- in ket qua
end procedure;
	
begin
	wait for 20 ns;			-- test
	reset <= '0';
	wait for CLK_PERIOD;

	run_test(-2.5);
	wait;
end process;
end sim;
