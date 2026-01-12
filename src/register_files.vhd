--------------------------------------------------------------------------------
-- File: register_files.vhd
-- Project: PCIe Bridge Register File
-- Author: Design Team
-- Date Created: 2024
-- Last Modified: 2026-01-11
-- Version: 2.0
--------------------------------------------------------------------------------
-- Description:
--   This module implements six 64-bit memory-mapped registers accessible via
--   the Avalon Memory-Mapped (Avalon-MM) interface from the PCIe bridge.
--   
--   Features:
--   - Six 64-bit general-purpose registers (addresses 0x00-0x14)
--   - Synchronous read/write operations with address-based selection
--   - Byte-level write enable support for partial register updates
--   - Read data valid signal generation for Avalon-MM compliance
--   - Error response signaling for invalid address access
--   - Waitrequest flow control (always ready for single-cycle operations)
--
-- Register Map:
--   Address     Register    Access
--   0x00000000  reg1        Read/Write
--   0x00000004  reg2        Read/Write
--   0x00000008  reg3        Read/Write
--   0x0000000C  reg4        Read/Write
--   0x00000010  reg5        Read/Write
--   0x00000014  reg6        Read/Write
--   others      N/A         Returns 0x9876987698769876 (read) / Ignored (write)
--
-- Interface:
--   Clock: 62.5MHz PCIe user clock
--   Reset: Active-low asynchronous reset
--   Protocol: Avalon Memory-Mapped (Avalon-MM)
--
-- Change Log:
--   v1.0 (2024): Initial implementation with basic read/write
--   v2.0 (2026-01-11): Added byte enables, readdatavalid, waitrequest, error response
--                      Fixed sensitivity lists, removed unused reg7 signal
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
entity register_files is
    port(
	    clock          :in std_logic;                       -- System clock (62.5MHz from PCIe)
		reset          :in std_logic;                       -- Active-low reset signal
	
	
        addr_regs      :in std_logic_vector ( 31 downto 0 ); -- Register address from Avalon-MM
		read_regs      :in std_logic;                     -- Read enable signal
		write_regs     :in std_logic;                     -- Write enable signal
		readdata_regs  :out std_logic_vector ( 63 downto 0 ); -- Data output for read operations
		writedata_regs :in std_logic_vector ( 63 downto 0 );  -- Data input for write operations
		
		-- Flow control and status signals
		waitrequest    :out std_logic;                    -- Indicates module is busy (Avalon-MM)
		readdatavalid  :out std_logic;                    -- Indicates read data is valid (Avalon-MM)
		
		-- Byte enable for partial writes
		byteenable     :in std_logic_vector ( 7 downto 0 ); -- Byte enable (one bit per byte)
		
		-- Error response
		response       :out std_logic_vector ( 1 downto 0 )  -- 00=OK, 01=ERROR, others=reserved
		
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

begin

-- Waitrequest Signal
-- For this simple register file, operations complete in one cycle
-- so waitrequest is always '0' (never busy)
waitrequest <= '0';

-- Read Process
-- Handles synchronous read operations from the register file
-- When read_regs is asserted, the appropriate register is output based on addr_regs
-- Invalid addresses return a constant pattern for debugging
-- Generates readdatavalid signal one cycle after read request
process (clock, reset)
begin
    if (reset = '0') then
        -- Active-low reset: clear read data output and control signals
        readdata_regs <= (others => '0');
        readdatavalid <= '0';
        response <= "00";  -- OK response
	elsif (rising_edge (clock)) then
        if (read_regs = '1') then
		    -- Address decoder: select register based on address
		    case addr_regs is
			    when x"00000000" => 
			        readdata_regs <= reg1;  -- Read reg1
			        response <= "00";       -- OK
		        when x"00000004" => 
			        readdata_regs <= reg2;  -- Read reg2
			        response <= "00";       -- OK
		        when x"00000008" => 
			        readdata_regs <= reg3;  -- Read reg3
			        response <= "00";       -- OK
		        when x"0000000C" => 
			        readdata_regs <= reg4;  -- Read reg4
			        response <= "00";       -- OK
		        when x"00000010" => 
			        readdata_regs <= reg5;  -- Read reg5
			        response <= "00";       -- OK
		        when x"00000014" => 
			        readdata_regs <= reg6;  -- Read reg6
			        response <= "00";       -- OK
		                                             
			    -- Return constant pattern for unmapped addresses (for debugging)
			    when others      => 
			        readdata_regs <= x"9876987698769876";
			        response <= "01";       -- ERROR for invalid address
		    end case;
			
			-- Assert readdatavalid when read is requested
		    readdatavalid <= '1';
		else
		    -- Deassert readdatavalid after one clock cycle
		    readdatavalid <= '0';
		    response <= "00";  -- Default OK response
		end if;
	end if;
end process;


-- Write Process
-- Handles synchronous write operations to the register file
-- When write_regs is asserted, writedata_regs is stored in the register specified by addr_regs
-- Supports byte-level write enables for partial register updates
-- All registers are reset to zero on system reset
process (clock, reset)
variable temp_data : std_logic_vector(63 downto 0);
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
			    when x"00000000" =>   -- Write to reg1
			        temp_data := reg1;
			        for i in 0 to 7 loop
			            if byteenable(i) = '1' then
			                temp_data(i*8+7 downto i*8) := writedata_regs(i*8+7 downto i*8);
			            end if;
			        end loop;
			        reg1 <= temp_data;
			        
		        when x"00000004" =>   -- Write to reg2
			        temp_data := reg2;
			        for i in 0 to 7 loop
			            if byteenable(i) = '1' then
			                temp_data(i*8+7 downto i*8) := writedata_regs(i*8+7 downto i*8);
			            end if;
			        end loop;
			        reg2 <= temp_data;
			        
		        when x"00000008" =>   -- Write to reg3
			        temp_data := reg3;
			        for i in 0 to 7 loop
			            if byteenable(i) = '1' then
			                temp_data(i*8+7 downto i*8) := writedata_regs(i*8+7 downto i*8);
			            end if;
			        end loop;
			        reg3 <= temp_data;
			        
		        when x"0000000C" =>   -- Write to reg4
			        temp_data := reg4;
			        for i in 0 to 7 loop
			            if byteenable(i) = '1' then
			                temp_data(i*8+7 downto i*8) := writedata_regs(i*8+7 downto i*8);
			            end if;
			        end loop;
			        reg4 <= temp_data;
			        
		        when x"00000010" =>   -- Write to reg5
			        temp_data := reg5;
			        for i in 0 to 7 loop
			            if byteenable(i) = '1' then
			                temp_data(i*8+7 downto i*8) := writedata_regs(i*8+7 downto i*8);
			            end if;
			        end loop;
			        reg5 <= temp_data;
			        
		        when x"00000014" =>   -- Write to reg6
			        temp_data := reg6;
			        for i in 0 to 7 loop
			            if byteenable(i) = '1' then
			                temp_data(i*8+7 downto i*8) := writedata_regs(i*8+7 downto i*8);
			            end if;
			        end loop;
			        reg6 <= temp_data;
		                                             
			    -- Ignore writes to unmapped addresses
			    when others      => null;
			
		    end case;
		end if;
	end if;
end process;







end register_files_arch;