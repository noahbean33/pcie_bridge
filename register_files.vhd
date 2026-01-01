library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Register File Module
-- This module implements six 64-bit memory-mapped registers accessible via
-- the Avalon Memory-Mapped (Avalon-MM) interface from the PCIe bridge.
-- Supports synchronous read and write operations with address-based register selection.
entity register_files is
    port(
	    clock        :in std_logic;                       -- System clock (62.5MHz from PCIe)
		reset        :in std_logic;                       -- Active-low reset signal
	
	
        addr_regs      :in std_logic_vector ( 31 downto 0 ); -- Register address from Avalon-MM
		read_regs      :in std_logic;                     -- Read enable signal
		write_regs     :in std_logic;                     -- Write enable signal
		readdata_regs  :out std_logic_vector ( 63 downto 0 ); -- Data output for read operations
		writedata_regs :in std_logic_vector ( 63 downto 0 )   -- Data input for write operations
		
		
	);
end register_files;

architecture register_files_arch of register_files is

-- Internal register signals - six 64-bit general purpose registers
-- These registers can be accessed from the Host PC via PCIe memory-mapped I/O
signal reg1:std_logic_vector ( 63 downto 0 );  -- Register at offset 0x00000000
signal reg2:std_logic_vector ( 63 downto 0 );  -- Register at offset 0x00000004
signal reg3:std_logic_vector ( 63 downto 0 );  -- Register at offset 0x00000008
signal reg4:std_logic_vector ( 63 downto 0 );  -- Register at offset 0x0000000C
signal reg5:std_logic_vector ( 63 downto 0 );  -- Register at offset 0x00000010
signal reg6:std_logic_vector ( 63 downto 0 );  -- Register at offset 0x00000014
signal reg7:std_logic_vector ( 63 downto 0 );  -- Unused register (declared but not implemented)

begin



-- Read Process
-- Handles synchronous read operations from the register file
-- When read_regs is asserted, the appropriate register is output based on addr_regs
-- Invalid addresses return a constant pattern for debugging
process (clock,reset,read_regs,reg1,reg2,reg3,reg4,reg5,reg6)
begin
    if (reset = '0') then
        -- Active-low reset: clear read data output
        readdata_regs <= (others => '0');
	elsif (rising_edge (clock)) then
        if (read_regs = '1') then
		    -- Address decoder: select register based on address
		    case addr_regs is
			    when x"00000000" => readdata_regs <= reg1;  -- Read reg1
		        when x"00000004" => readdata_regs <= reg2;  -- Read reg2
		        when x"00000008" => readdata_regs <= reg3;  -- Read reg3
		        when x"0000000C" => readdata_regs <= reg4;  -- Read reg4
		        when x"00000010" => readdata_regs <= reg5;  -- Read reg5
		        when x"00000014" => readdata_regs <= reg6;  -- Read reg6
		                                             
			    -- Return constant pattern for unmapped addresses (for debugging)
			    when others      => readdata_regs <= x"9876987698769876";
			
		    end case;
		end if;
	end if;
end process;


-- Write Process
-- Handles synchronous write operations to the register file
-- When write_regs is asserted, writedata_regs is stored in the register specified by addr_regs
-- All registers are reset to zero on system reset
process (clock,reset,write_regs)
begin
    if (reset = '0') then
        -- Active-low reset: initialize all registers to zero
        reg1 <= (others => '0');
		reg2 <= (others => '0');
		reg3 <= (others => '0');
		reg4 <= (others => '0');
		reg5 <= (others => '0');
		reg6 <= (others => '0');
		
	elsif (rising_edge (clock)) then
        if (write_regs = '1') then
		    -- Address decoder: write to register based on address
		    case addr_regs is
			    when x"00000000" => reg1 <= writedata_regs;  -- Write to reg1
		        when x"00000004" => reg2 <= writedata_regs;  -- Write to reg2
		        when x"00000008" => reg3 <= writedata_regs;  -- Write to reg3
		        when x"0000000C" => reg4 <= writedata_regs;  -- Write to reg4
		        when x"00000010" => reg5 <= writedata_regs;  -- Write to reg5
		        when x"00000014" => reg6 <= writedata_regs;  -- Write to reg6
		                                             
			    -- Ignore writes to unmapped addresses
			    when others      => null;
			
		    end case;
		end if;
	end if;
end process;







end register_files_arch;