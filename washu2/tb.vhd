library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity washu2_cpu_ddc_jon_turner_tb is end entity;
architecture behav of washu2_cpu_ddc_jon_turner_tb is
  signal clk,reset: std_logic := '0';
  signal en, rw, PC_Buff_Sel: std_logic;
  signal aBus, dBus: std_logic_vector(15 downto 0);
  type regarray is array(54 downto 0) of std_logic_vector(15 downto 0);
  signal ram_chip_storage : regarray:=(
    0 =>  x"1000", 1 =>  x"5011", 2 =>  x"1fff", 3 =>  x"5010",
    4 =>  x"1001", 5 =>  x"8010", 6 =>  x"0102", 7 =>  x"2010",
    8 =>  x"0204", 9 =>  x"8011", 10 =>  x"5011", 11 =>  x"01f7",
    12 =>  x"0000", 13 | 14 | 15 =>  x"0000",
    16 => x"1234", 17 => x"5678", others => x"0000");
begin
  CPU: entity work.washu2_cpu_ddc_jon_turner 
         port map(clk=>clk,reset=>reset,en=>en,rw=>rw,aBus=>aBus,dBus=>dBus) ;
  clk_process: process begin clk <= not clk after 10 ns; wait for 10 ns; end process clk_process;
  reset_process: process begin reset <= '1'; wait for 20 ns; reset <= '0'; wait; end process;
  Mem_process: process(clk) begin
    if rising_edge(clk) then
      if rw = '0' and en='1' then
        report "Writing value: " & integer'image(to_integer(unsigned(dBus))) &
               " to memory address: " & integer'image(to_integer(unsigned(aBus)));
        ram_chip_storage(to_integer(unsigned(aBus))) <= dBus ;
      elsif rw = '1' and en='1' then
        if aBus /= (15 downto 0 =>'Z') then dBus <= ram_chip_storage(to_integer(unsigned(aBus)));
        else dBus <= (15 downto 0 =>'Z'); end if;
      end if;
    end if;
  end process;
end architecture;