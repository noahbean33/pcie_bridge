library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

Library UNISIM;
use UNISIM.vcomponents.all;

-- Top-Level PCIe Bridge Module
-- This is the main entity that integrates the PCIe IP block with the register file module.
-- It handles differential clock buffering, PCIe transceiver connections, and Avalon-MM protocol bridging.
entity full_project is
    port(
    -- Clock and Reset
        CLK_IN_P : in STD_LOGIC; -- 100MHz differential clock positive
        CLK_IN_N : in STD_LOGIC; -- 100MHz differential clock negative
        RST_IN   : in STD_LOGIC; -- External reset input (active-high)
    
	-- PCIe Physical Link (x1 lane)
		PCIE_RXN : in STD_LOGIC_VECTOR ( 0 to 0 );  -- PCIe receive lane (negative)
		PCIE_RXP : in STD_LOGIC_VECTOR ( 0 to 0 );  -- PCIe receive lane (positive)
		PCIE_TXN : out STD_LOGIC_VECTOR ( 0 to 0 ); -- PCIe transmit lane (negative)
		PCIE_TXP : out STD_LOGIC_VECTOR ( 0 to 0 )  -- PCIe transmit lane (positive)
		
		
	);
end full_project;

architecture full_project_arch of full_project is

-- Component Declarations

-- PCIe IP Block Wrapper Component
-- This component wraps the Xilinx PCIe Gen1/Gen2 x1 IP core
-- It translates PCIe TLPs to Avalon Memory-Mapped interface
component pcie_block_wrapper is
  port (
    M_AVALON_0_address            : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AVALON_0_beginbursttransfer : out STD_LOGIC;
    M_AVALON_0_burstcount         : out STD_LOGIC_VECTOR ( 8 downto 0 );
    M_AVALON_0_read               : out STD_LOGIC;
    M_AVALON_0_readdata           : in STD_LOGIC_VECTOR ( 63 downto 0 );
    M_AVALON_0_readdatavalid      : in STD_LOGIC;
    M_AVALON_0_waitrequest        : in STD_LOGIC;
    M_AVALON_0_write              : out STD_LOGIC;
    M_AVALON_0_writedata          : out STD_LOGIC_VECTOR ( 63 downto 0 );
    clock_out_62_5                : out STD_LOGIC;
	ext_reset_in_0                : in STD_LOGIC;
    pcie_7x_mgt_0_rxn             : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcie_7x_mgt_0_rxp             : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcie_7x_mgt_0_txn             : out STD_LOGIC_VECTOR ( 0 to 0 );
    pcie_7x_mgt_0_txp             : out STD_LOGIC_VECTOR ( 0 to 0 );
    reset_pcie_out                : out STD_LOGIC;
	slowest_sync_clk_0            : in STD_LOGIC
  );
end component;

-- Register File Component
-- Implements six 64-bit memory-mapped registers accessible via Avalon-MM
component register_files is
    port(
	    clock        :in std_logic;
		reset        :in std_logic;
	
	
        addr_regs      :in std_logic_vector ( 31 downto 0 );
		read_regs      :in std_logic;
		write_regs     :in std_logic;
		readdata_regs  :out std_logic_vector ( 63 downto 0 );
		writedata_regs :in std_logic_vector ( 63 downto 0 )
		
		
	);
end component;

-- Internal Signal Declarations

-- Clock signals
signal clock_out_100_sig        : std_logic; -- 100MHz buffered clock from differential input
signal clock_out_62_5           :std_logic;  -- 62.5MHz PCIe user clock

-- Reset signals						    
signal reset_pcie_out           :std_logic;  -- PCIe link reset output (active-low)
					    
-- Avalon-MM signals connecting PCIe block to register file
signal addr_regs                : std_logic_vector ( 31 downto 0 ); -- Register address
signal read_regs                : std_logic;                        -- Read strobe
signal write_regs               : std_logic;                        -- Write strobe
signal readdata_regs            : std_logic_vector ( 63 downto 0 ); -- Read data from registers
signal writedata_regs           : std_logic_vector ( 63 downto 0 ); -- Write data to registers
		
-- Avalon-MM handshake signals
signal m_avalon_0_readdatavalid : std_logic; -- Indicates read data is valid
signal m_avalon_0_waitrequest   : std_logic; -- Flow control (not currently used)

begin

-- Differential Clock Input Buffer
-- Converts the 100MHz differential clock input (CLK_IN_P/N) to a single-ended signal
-- IBUFDS: Xilinx primitive for Artix-7 FPGA differential input buffering
   IBUFDS_inst : IBUFDS
   generic map (
      DIFF_TERM => FALSE,       -- Differential termination disabled
      IBUF_LOW_PWR => TRUE,     -- Low power mode for better power efficiency
      IOSTANDARD => "DEFAULT")  -- Use default I/O standard
   port map (
      O  => clock_out_100_sig , -- Single-ended 100MHz clock output
      I  => CLK_IN_P ,          -- Differential positive input
      IB => CLK_IN_N            -- Differential negative input
   );

-- PCIe Block Wrapper Instantiation
-- Connects the PCIe IP core to the external PCIe lanes and internal Avalon-MM bus
pcie_block_wrapper_comp: pcie_block_wrapper
  port map(
    -- Avalon-MM Master Interface
    M_AVALON_0_address            => addr_regs,                  -- Address output to register file
    M_AVALON_0_beginbursttransfer => open,                       -- Burst transfer (not used)
    M_AVALON_0_burstcount         => open,                       -- Burst count (not used)
    M_AVALON_0_read               => read_regs,                  -- Read strobe output
    M_AVALON_0_readdata           => readdata_regs,              -- Read data input from register file
    M_AVALON_0_readdatavalid      => m_avalon_0_readdatavalid,  -- Read data valid input
    M_AVALON_0_waitrequest        => '0',                        -- Wait request (tied to '0' - always ready)
    M_AVALON_0_write              => write_regs,                 -- Write strobe output
    M_AVALON_0_writedata          => writedata_regs,             -- Write data output
    -- Clocking and Reset
	clock_out_62_5                => clock_out_62_5,              -- 62.5MHz user clock output
	ext_reset_in_0                => RST_IN,                       -- External reset input
    reset_pcie_out                => reset_pcie_out,             -- PCIe link reset output
	slowest_sync_clk_0            => clock_out_100_sig,          -- 100MHz reference clock input
    -- PCIe Physical Interface
    pcie_7x_mgt_0_rxn             => PCIE_RXN,                   -- PCIe RX negative
    pcie_7x_mgt_0_rxp             => PCIE_RXP,                   -- PCIe RX positive
    pcie_7x_mgt_0_txn             => PCIE_TXN,                   -- PCIe TX negative
    pcie_7x_mgt_0_txp             => PCIE_TXP                    -- PCIe TX positive
  );

-- Register File Instantiation
-- Implements the six 64-bit memory-mapped registers accessible via PCIe
register_files_comp: register_files
    port map(
	    clock           => clock_out_62_5, -- 62.5MHz PCIe user clock
		reset           => reset_pcie_out, -- Active-low reset from PCIe block

        -- Avalon-MM Slave Interface
        addr_regs       => addr_regs     , -- Address input from PCIe block
		read_regs       => read_regs     , -- Read strobe input
		write_regs      => write_regs    , -- Write strobe input
		readdata_regs   => readdata_regs , -- Read data output to PCIe block
		writedata_regs  => writedata_regs  -- Write data input from PCIe block
		
		
	);  
     
    
-- Read Data Valid Generation Process
-- This process generates the readdatavalid signal for the Avalon-MM interface
-- It asserts for one clock cycle after a read operation to indicate valid data
process (clock_out_62_5,reset_pcie_out)
begin
    if (reset_pcie_out = '0') then
        -- Active-low reset: clear readdatavalid
	    m_avalon_0_readdatavalid <= '0';
	elsif (rising_edge (clock_out_62_5)) then
	    if (read_regs = '1') then
	        -- Assert readdatavalid when read is requested
	        m_avalon_0_readdatavalid <= '1';
		else
	        -- Deassert readdatavalid after one clock cycle
		    m_avalon_0_readdatavalid <= '0';
		end if;
	end if;
end process; 











end full_project_arch;