library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity washu2_cpu_ddc_jon_turner is
  port (
    clk, reset : in std_logic;
    en, rw     : out std_logic;
    aBus       : out std_logic_vector(15 downto 0);
    dBus       : inout std_logic_vector(15 downto 0)
  );
end entity;

architecture str of washu2_cpu_ddc_jon_turner is

  type state_type is (
    resetState, pauseState, fetch,
    halt, negate,
    branch, brZero, brPos, brNeg, brInd,
    cLoad, dLoad, iLoad,
    dStore, iStore,
    add, andd
  );

  subtype address is std_logic_vector(15 downto 0);
  subtype word    is std_logic_vector(15 downto 0);

  signal state : state_type;
  signal tick  : unsigned(3 downto 0);

  signal pc    : address := x"0000";
  signal iReg  : word;
  signal iar   : address;
  signal acc   : word;
  signal alu   : word;
  signal this  : address;
  signal opAdr : address;
  signal mdr   : word;

  signal target17 : std_logic_vector(16 downto 0);
  signal target   : word;

begin

  opAdr <= this(15 downto 12) & iReg(11 downto 0);

  target17 <= std_logic_vector(
                signed('0' & this) +
                signed((16 downto 8 => iReg(7)) & iReg(7 downto 0))
              );
  target <= target17(15 downto 0);

  alu <= std_logic_vector(unsigned(not acc) + 1) when state = negate else
         std_logic_vector(signed(acc) + signed(mdr)) when state = add else
         (acc and dbus) when state = andd else
         (others => '0');

  process(clk)

    function decode(instr : std_logic_vector(15 downto 0)) return state_type is
    begin
      case instr(15 downto 12) is
        when x"0" =>
          case instr(11 downto 8) is
            when x"0" =>
              if instr(11 downto 0) = x"000" then
                return halt;
              elsif instr(11 downto 0) = x"001" then
                return negate;
              else
                return halt;
              end if;
            when x"1" => return branch;
            when x"2" => return brZero;
            when x"3" => return brPos;
            when x"4" => return brNeg;
            when x"5" => return brInd;
            when others => return halt;
          end case;

        when x"1" => return cLoad;
        when x"2" => return dLoad;
        when x"3" => return iLoad;
        when x"5" => return dStore;
        when x"6" => return iStore;
        when x"8" => return add;
        when x"C" => return andd;
        when others => return halt;
      end case;
    end function;

    procedure wrapup is
    begin
      state <= fetch;
      tick  <= x"0";
    end procedure;

  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= resetState;
        tick  <= x"0";
        pc    <= (others => '0');
        this  <= (others => '0');
        iReg  <= (others => '0');
        acc   <= (others => '0');
        iar   <= (others => '0');
        mdr   <= (others => '0');

      else
        tick <= tick + 1;

        if state = resetState then
          state <= fetch;
          tick  <= x"0";

        elsif state = pauseState then
          state <= fetch;
          tick  <= x"0";

        ---------------------------------------------------------------------
        -- FETCH with professor's synchronous TB:
        -- tick=0 : request instruction
        -- tick=1 : memory updates dBus on edge
        -- tick=2 : CPU captures dBus into iReg
        -- tick=3 : decode and increment PC
        ---------------------------------------------------------------------
        elsif state = fetch then
          if tick = x"1" then
            iReg <= dBus;
          elsif tick = x"2" then
            state <= decode(iReg);
            tick  <= x"0";
            this  <= pc;
            pc    <= std_logic_vector(unsigned(pc) + 1);
          end if;

        else
          case state is

            when branch =>
              pc <= target;
              wrapup;

            when brZero =>
              if acc = x"0000" then
                pc <= target;
              end if;
              wrapup;

            when brPos =>
              if acc(15) = '0' and acc /= x"0000" then
                pc <= target;
              end if;
              wrapup;

            when brNeg =>
              if acc(15) = '1' then
                pc <= target;
              end if;
              wrapup;

            -----------------------------------------------------------------
            -- brInd read timing
            -----------------------------------------------------------------
            when brInd =>
              if tick = x"2" then
                mdr <= dBus;
              elsif tick = x"3" then
                pc <= mdr;
                wrapup;
              end if;

            when cLoad =>
              acc <= (15 downto 12 => iReg(11)) & iReg(11 downto 0);
              wrapup;

            -----------------------------------------------------------------
            -- dLoad read timing
            -----------------------------------------------------------------
            when dLoad =>
              if tick = x"2" then
                mdr <= dBus;
              elsif tick = x"3" then
                acc <= mdr;
                wrapup;
              end if;

            -----------------------------------------------------------------
            -- iLoad read timing
            -----------------------------------------------------------------
            when iLoad =>
              if tick = x"2" then
                mdr <= dBus;      -- pointer from opAdr
              elsif tick = x"3" then
                iar <= mdr;
              elsif tick = x"6" then
                mdr <= dBus;      -- actual data from iar
              elsif tick = x"7" then
                acc <= mdr;
                wrapup;
              end if;

            -----------------------------------------------------------------
            -- dStore with one bus-turnaround cycle
            -- tick=0 : force memory to release dBus (dummy Z read cycle)
            -- tick=1 : actual write cycle
            -- tick=2 : wrap up
            -----------------------------------------------------------------
            when dStore =>
              if tick = x"0" then
                wrapup;
              end if;

            -----------------------------------------------------------------
            -- iStore with bus-turnaround before final write
            -----------------------------------------------------------------
            when iStore =>
              if tick = x"2" then
                mdr <= dBus;      -- pointer from opAdr
              elsif tick = x"3" then
                iar <= mdr;
              elsif tick = x"6" then
                wrapup;
              end if;

            when negate =>
              acc <= alu;
              wrapup;

            -----------------------------------------------------------------
            -- add/andd read timing
            -----------------------------------------------------------------
            when add | andd =>
              if tick = x"1" then
                acc <= alu;
                wrapup;
              end if;

            when halt =>
              state <= halt;

            when others =>
              state <= halt;

          end case;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Combinational bus/memory control for original professor TB
  ---------------------------------------------------------------------------
  process(iReg, pc, iar, acc, this, opAdr, state, tick, target)
  begin
    en   <= '0';
    rw   <= '1';
    aBus <= (others => 'Z');
    dBus <= (others => 'Z');

    case state is

      -----------------------------------------------------------------------
      -- fetch request at tick 0
      -----------------------------------------------------------------------
      when fetch =>
        if tick = x"0" then
          en   <= '1';
          rw   <= '1';
          aBus <= pc;
        elsif tick = x"2" then
          en   <= '1';
          rw   <= '1';
          aBus <= (others => 'Z');
        end if;

      -----------------------------------------------------------------------
      -- brInd read request
      -----------------------------------------------------------------------
      when brInd =>
        if tick = x"0" then
          en   <= '1';
          rw   <= '1';
          aBus <= target;
        end if;

      -----------------------------------------------------------------------
      -- dLoad/add/andd read request
      -----------------------------------------------------------------------
      when dLoad | add | andd =>
        if tick = x"0" then
          en   <= '1';
          rw   <= '1';
          aBus <= opAdr;
        end if;

      -----------------------------------------------------------------------
      -- iLoad:
      -- tick=0 read pointer
      -- tick=4 read actual data from iar
      -----------------------------------------------------------------------
      when iLoad =>
        if tick = x"0" then
          en   <= '1';
          rw   <= '1';
          aBus <= opAdr;
        elsif tick = x"4" then
          en   <= '1';
          rw   <= '1';
          aBus <= iar;
        end if;

      -----------------------------------------------------------------------
      -- dStore:
      -- tick=0 -> dummy read with Z address, so memory drives Z next edge
      -- tick=1 -> actual write, CPU alone drives dBus
      -----------------------------------------------------------------------
      when dStore =>
        if tick = x"0" then
          en   <= '1';
          rw   <= '0';
          aBus <= opAdr;
          dBus <= acc;
        end if;

      -----------------------------------------------------------------------
      -- iStore:
      -- tick=0 -> read pointer
      -- tick=4 -> dummy Z read to release dBus
      -- tick=5 -> actual write to memory[iar]
      -----------------------------------------------------------------------
      when iStore =>
        if tick = x"0" then
          en   <= '1';
          rw   <= '1';
          aBus <= opAdr;
        elsif tick = x"4" then
          en   <= '1';
          rw   <= '1';
          aBus <= (others => 'Z');
        elsif tick = x"5" then
          en   <= '1';
          rw   <= '0';
          aBus <= iar;
          dBus <= acc;
        end if;

      when others =>
        null;

    end case;
  end process;

end architecture;