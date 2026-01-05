# VHDL to SystemVerilog Translation Guide

## Table of Contents
1. [Overview](#overview)
2. [General Syntax Mapping](#general-syntax-mapping)
3. [Module Structure Translation](#module-structure-translation)
4. [Data Types](#data-types)
5. [Operators and Expressions](#operators-and-expressions)
6. [Sequential Logic](#sequential-logic)
7. [Combinational Logic](#combinational-logic)
8. [Component Instantiation](#component-instantiation)
9. [Project-Specific Translation Examples](#project-specific-translation-examples)
10. [Common Pitfalls](#common-pitfalls)
11. [Complete Module Examples](#complete-module-examples)

---

## Overview

This guide provides a comprehensive reference for translating the PCIe Bridge project from VHDL to SystemVerilog. The project consists of three main files:
- `full_project.vhd` - Top-level module
- `register_files.vhd` - Register file implementation
- `full_project_tb.vhd` - Testbench

---

## General Syntax Mapping

### Basic Syntax Differences

| VHDL | SystemVerilog | Notes |
|------|---------------|-------|
| `entity`/`architecture` | `module`/`endmodule` | SV combines entity and architecture |
| `port()` | `module name (ports);` | Ports declared in module header |
| `signal` | `logic` or `wire` | Use `logic` for general signals |
| `:=` (assignment) | `=` (blocking) or `<=` (non-blocking) | Context dependent |
| `<=` (signal assignment) | `<=` (non-blocking) | Same syntax, different semantics |
| `--` (comment) | `//` or `/* */` | Single or multi-line |
| `std_logic` | `logic` | Single bit |
| `std_logic_vector` | `logic [N:0]` | Multi-bit vector |
| `(others => '0')` | `'0` or `{N{1'b0}}` | Zero initialization |
| `x"DEADBEEF"` | `32'hDEADBEEF` | Hexadecimal literals |

### Case Sensitivity
- **VHDL**: Case-insensitive
- **SystemVerilog**: Case-sensitive (use consistent naming)

### File Extensions
- **VHDL**: `.vhd`, `.vhdl`
- **SystemVerilog**: `.sv`, `.v` (Verilog)

---

## Module Structure Translation

### VHDL Entity/Architecture
```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity module_name is
    port(
        clk : in std_logic;
        rst : in std_logic;
        data_in : in std_logic_vector(31 downto 0);
        data_out : out std_logic_vector(31 downto 0)
    );
end module_name;

architecture rtl of module_name is
    signal internal_sig : std_logic_vector(31 downto 0);
begin
    -- Architecture body
end rtl;
```

### SystemVerilog Module
```systemverilog
module module_name (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] data_in,
    output logic [31:0] data_out
);

    logic [31:0] internal_sig;
    
    // Module body
    
endmodule
```

---

## Data Types

### Signal/Variable Declarations

**VHDL:**
```vhdl
signal my_signal : std_logic;
signal my_vector : std_logic_vector(7 downto 0);
signal my_int : integer range 0 to 255;
variable my_var : std_logic_vector(15 downto 0);
```

**SystemVerilog:**
```systemverilog
logic        my_signal;
logic [7:0]  my_vector;
int          my_int;        // 32-bit signed
logic [15:0] my_var;
```

### Bit Ordering

**VHDL (downto - MSB first):**
```vhdl
signal data : std_logic_vector(31 downto 0);  -- data(31) is MSB
```

**SystemVerilog (little-endian - LSB first):**
```systemverilog
logic [31:0] data;  // data[31] is MSB, data[0] is LSB
```

### Constants

**VHDL:**
```vhdl
constant REG_WIDTH : integer := 64;
constant RESET_VAL : std_logic_vector(7 downto 0) := x"00";
```

**SystemVerilog:**
```systemverilog
parameter int REG_WIDTH = 64;
localparam logic [7:0] RESET_VAL = 8'h00;
```

---

## Operators and Expressions

### Logical Operators

| VHDL | SystemVerilog | Operation |
|------|---------------|-----------|
| `and` | `&` | Bitwise AND |
| `or` | `\|` | Bitwise OR |
| `not` | `~` | Bitwise NOT |
| `xor` | `^` | Bitwise XOR |
| `nand` | `~&` | Bitwise NAND |

### Comparison Operators

| VHDL | SystemVerilog | Operation |
|------|---------------|-----------|
| `=` | `==` | Equality |
| `/=` | `!=` | Inequality |
| `<`, `>`, `<=`, `>=` | `<`, `>`, `<=`, `>=` | Relational |

### Concatenation

**VHDL:**
```vhdl
result <= data1 & data2;  -- Concatenate
```

**SystemVerilog:**
```systemverilog
result = {data1, data2};  // Concatenate
```

### Bit Selection and Slicing

**VHDL:**
```vhdl
bit_val <= data(5);              -- Single bit
slice <= data(15 downto 8);      -- Slice
```

**SystemVerilog:**
```systemverilog
bit_val = data[5];               // Single bit
slice = data[15:8];              // Slice
```

---

## Sequential Logic

### Clocked Process / Always Block

**VHDL:**
```vhdl
process(clk, rst)
begin
    if (rst = '0') then
        -- Asynchronous reset (active-low)
        counter <= (others => '0');
    elsif (rising_edge(clk)) then
        -- Synchronous logic
        counter <= counter + 1;
    end if;
end process;
```

**SystemVerilog:**
```systemverilog
always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        // Asynchronous reset (active-low)
        counter <= '0;
    end else begin
        // Synchronous logic
        counter <= counter + 1;
    end
end
```

### Synchronous Reset Only

**VHDL:**
```vhdl
process(clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            counter <= (others => '0');
        else
            counter <= counter + 1;
        end if;
    end if;
end process;
```

**SystemVerilog:**
```systemverilog
always_ff @(posedge clk) begin
    if (rst) begin
        counter <= '0;
    end else begin
        counter <= counter + 1;
    end
end
```

---

## Combinational Logic

### Case Statement

**VHDL:**
```vhdl
process(addr, reg1, reg2, reg3)
begin
    case addr is
        when x"00000000" => data_out <= reg1;
        when x"00000004" => data_out <= reg2;
        when x"00000008" => data_out <= reg3;
        when others       => data_out <= x"0000000000000000";
    end case;
end process;
```

**SystemVerilog:**
```systemverilog
always_comb begin
    case (addr)
        32'h00000000: data_out = reg1;
        32'h00000004: data_out = reg2;
        32'h00000008: data_out = reg3;
        default:      data_out = 64'h0000000000000000;
    endcase
end
```

### Conditional Assignment

**VHDL:**
```vhdl
output <= input1 when (sel = '1') else input2;
```

**SystemVerilog:**
```systemverilog
assign output = sel ? input1 : input2;
```

---

## Component Instantiation

### VHDL Component Declaration and Instantiation

**VHDL:**
```vhdl
-- Component declaration
component register_files is
    port(
        clock        : in  std_logic;
        reset        : in  std_logic;
        addr_regs    : in  std_logic_vector(31 downto 0);
        read_regs    : in  std_logic;
        readdata_regs: out std_logic_vector(63 downto 0)
    );
end component;

-- Instantiation
register_files_comp: register_files
    port map(
        clock         => clock_out_62_5,
        reset         => reset_pcie_out,
        addr_regs     => addr_regs,
        read_regs     => read_regs,
        readdata_regs => readdata_regs
    );
```

### SystemVerilog Module Instantiation

**SystemVerilog:**
```systemverilog
// No separate declaration needed

// Instantiation with named port connections
register_files register_files_inst (
    .clock         (clock_out_62_5),
    .reset         (reset_pcie_out),
    .addr_regs     (addr_regs),
    .read_regs     (read_regs),
    .readdata_regs (readdata_regs)
);
```

### Unconnected Ports

**VHDL:**
```vhdl
port map(
    output_port => open,  -- Unconnected output
    input_port  => '0'    -- Tied to constant
);
```

**SystemVerilog:**
```systemverilog
module_inst (
    .output_port (),      // Unconnected output
    .input_port  (1'b0)   // Tied to constant
);
```

---

## Project-Specific Translation Examples

### Example 1: Register File Read Process

**VHDL (`register_files.vhd`):**
```vhdl
process (clock, reset)
begin
    if (reset = '0') then
        readdata_regs <= (others => '0');
    elsif (rising_edge(clock)) then
        if (read_regs = '1') then
            case addr_regs is
                when x"00000000" => readdata_regs <= reg1;
                when x"00000004" => readdata_regs <= reg2;
                when x"00000008" => readdata_regs <= reg3;
                when x"0000000C" => readdata_regs <= reg4;
                when x"00000010" => readdata_regs <= reg5;
                when x"00000014" => readdata_regs <= reg6;
                when others      => readdata_regs <= x"9876987698769876";
            end case;
        end if;
    end if;
end process;
```

**SystemVerilog:**
```systemverilog
always_ff @(posedge clock or negedge reset) begin
    if (!reset) begin
        readdata_regs <= 64'h0;
    end else begin
        if (read_regs) begin
            case (addr_regs)
                32'h00000000: readdata_regs <= reg1;
                32'h00000004: readdata_regs <= reg2;
                32'h00000008: readdata_regs <= reg3;
                32'h0000000C: readdata_regs <= reg4;
                32'h00000010: readdata_regs <= reg5;
                32'h00000014: readdata_regs <= reg6;
                default:      readdata_regs <= 64'h9876987698769876;
            endcase
        end
    end
end
```

### Example 2: Register File Write Process

**VHDL (`register_files.vhd`):**
```vhdl
process (clock, reset)
begin
    if (reset = '0') then
        reg1 <= (others => '0');
        reg2 <= (others => '0');
        reg3 <= (others => '0');
        reg4 <= (others => '0');
        reg5 <= (others => '0');
        reg6 <= (others => '0');
    elsif (rising_edge(clock)) then
        if (write_regs = '1') then
            case addr_regs is
                when x"00000000" => reg1 <= writedata_regs;
                when x"00000004" => reg2 <= writedata_regs;
                when x"00000008" => reg3 <= writedata_regs;
                when x"0000000C" => reg4 <= writedata_regs;
                when x"00000010" => reg5 <= writedata_regs;
                when x"00000014" => reg6 <= writedata_regs;
                when others      => null;
            endcase
        end if;
    end if;
end process;
```

**SystemVerilog:**
```systemverilog
always_ff @(posedge clock or negedge reset) begin
    if (!reset) begin
        reg1 <= 64'h0;
        reg2 <= 64'h0;
        reg3 <= 64'h0;
        reg4 <= 64'h0;
        reg5 <= 64'h0;
        reg6 <= 64'h0;
    end else begin
        if (write_regs) begin
            case (addr_regs)
                32'h00000000: reg1 <= writedata_regs;
                32'h00000004: reg2 <= writedata_regs;
                32'h00000008: reg3 <= writedata_regs;
                32'h0000000C: reg4 <= writedata_regs;
                32'h00000010: reg5 <= writedata_regs;
                32'h00000014: reg6 <= writedata_regs;
                default:      ; // Do nothing
            endcase
        end
    end
end
```

### Example 3: Xilinx Primitive Instantiation

**VHDL (`full_project.vhd`):**
```vhdl
Library UNISIM;
use UNISIM.vcomponents.all;

IBUFDS_inst : IBUFDS
generic map (
    DIFF_TERM    => FALSE,
    IBUF_LOW_PWR => TRUE,
    IOSTANDARD   => "DEFAULT"
)
port map (
    O  => clock_out_100_sig,
    I  => CLK_IN_P,
    IB => CLK_IN_N
);
```

**SystemVerilog:**
```systemverilog
// Xilinx primitives can be instantiated directly in SystemVerilog
IBUFDS #(
    .DIFF_TERM    ("FALSE"),
    .IBUF_LOW_PWR ("TRUE"),
    .IOSTANDARD   ("DEFAULT")
) IBUFDS_inst (
    .O  (clock_out_100_sig),
    .I  (CLK_IN_P),
    .IB (CLK_IN_N)
);
```

### Example 4: Testbench Clock Generation

**VHDL (`full_project_tb.vhd`):**
```vhdl
signal CLK_IN_P_sig : STD_LOGIC := '1';
signal CLK_IN_N_sig : STD_LOGIC := '0';

CLK_IN_P_sig <= not CLK_IN_P_sig after 5 ns;
CLK_IN_N_sig <= not CLK_IN_P_sig;
```

**SystemVerilog:**
```systemverilog
logic CLK_IN_P_sig = 1'b1;
logic CLK_IN_N_sig = 1'b0;

always #5ns CLK_IN_P_sig = ~CLK_IN_P_sig;
assign CLK_IN_N_sig = ~CLK_IN_P_sig;
```

### Example 5: Testbench Reset Stimulus

**VHDL:**
```vhdl
RST_IN_sig <= '0', '1' after 4 us;
```

**SystemVerilog:**
```systemverilog
initial begin
    RST_IN_sig = 1'b0;
    #4us;
    RST_IN_sig = 1'b1;
end
```

---

## Common Pitfalls

### 1. Assignment Operators

**VHDL** uses `:=` for variables and `<=` for signals.

**SystemVerilog** uses:
- `=` for blocking assignments (combinational, within `initial`, or immediate)
- `<=` for non-blocking assignments (sequential, in `always_ff` or `always`)

**Rule of Thumb:**
- Use `<=` in `always_ff` (sequential logic)
- Use `=` in `always_comb` (combinational logic)
- Use `=` in `initial` blocks (testbench initialization)

### 2. Bit Literals

**VHDL:**
```vhdl
'0'              -- Single bit 0
'1'              -- Single bit 1
"0000"           -- 4-bit binary
x"FF"            -- 8-bit hex (needs vector context)
(others => '0')  -- All zeros
```

**SystemVerilog:**
```systemverilog
1'b0             // Single bit 0
1'b1             // Single bit 1
4'b0000          // 4-bit binary
8'hFF            // 8-bit hex
'0               // All zeros (sized to LHS)
{4{1'b0}}        // Replicate: 4 bits of 0
```

### 3. Sensitivity Lists

**VHDL:**
```vhdl
process(clk, rst)  -- Only clock and reset for sequential
process(a, b, c)   -- All inputs for combinational
```

**SystemVerilog:**
```systemverilog
always_ff @(posedge clk or negedge rst)  // Sequential
always_comb                               // Automatic sensitivity
```

**Note:** `always_comb` automatically includes all read signals in the sensitivity list.

### 4. Null Statement

**VHDL:**
```vhdl
when others => null;
```

**SystemVerilog:**
```systemverilog
default: ;  // Empty statement or just omit
```

### 5. Libraries

**VHDL** requires explicit library declarations:
```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
```

**SystemVerilog** has built-in types:
```systemverilog
// No library needed for basic logic types
// For math: `include "math.svh" or similar
```

### 6. Open Ports vs. Unconnected

**VHDL:**
```vhdl
port map(unused_output => open);
```

**SystemVerilog:**
```systemverilog
module_inst (.unused_output());  // Leave empty
// Or simply don't connect it
```

---

## Complete Module Examples

### Full Translation: register_files

**Original VHDL (`register_files.vhd`):**
```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity register_files is
    port(
        clock          : in  std_logic;
        reset          : in  std_logic;
        addr_regs      : in  std_logic_vector(31 downto 0);
        read_regs      : in  std_logic;
        write_regs     : in  std_logic;
        readdata_regs  : out std_logic_vector(63 downto 0);
        writedata_regs : in  std_logic_vector(63 downto 0)
    );
end register_files;

architecture register_files_arch of register_files is
    signal reg1 : std_logic_vector(63 downto 0);
    signal reg2 : std_logic_vector(63 downto 0);
    signal reg3 : std_logic_vector(63 downto 0);
    signal reg4 : std_logic_vector(63 downto 0);
    signal reg5 : std_logic_vector(63 downto 0);
    signal reg6 : std_logic_vector(63 downto 0);
begin

    -- Read process
    process (clock, reset)
    begin
        if (reset = '0') then
            readdata_regs <= (others => '0');
        elsif (rising_edge(clock)) then
            if (read_regs = '1') then
                case addr_regs is
                    when x"00000000" => readdata_regs <= reg1;
                    when x"00000004" => readdata_regs <= reg2;
                    when x"00000008" => readdata_regs <= reg3;
                    when x"0000000C" => readdata_regs <= reg4;
                    when x"00000010" => readdata_regs <= reg5;
                    when x"00000014" => readdata_regs <= reg6;
                    when others      => readdata_regs <= x"9876987698769876";
                end case;
            end if;
        end if;
    end process;

    -- Write process
    process (clock, reset)
    begin
        if (reset = '0') then
            reg1 <= (others => '0');
            reg2 <= (others => '0');
            reg3 <= (others => '0');
            reg4 <= (others => '0');
            reg5 <= (others => '0');
            reg6 <= (others => '0');
        elsif (rising_edge(clock)) then
            if (write_regs = '1') then
                case addr_regs is
                    when x"00000000" => reg1 <= writedata_regs;
                    when x"00000004" => reg2 <= writedata_regs;
                    when x"00000008" => reg3 <= writedata_regs;
                    when x"0000000C" => reg4 <= writedata_regs;
                    when x"00000010" => reg5 <= writedata_regs;
                    when x"00000014" => reg6 <= writedata_regs;
                    when others      => null;
                end case;
            end if;
        end if;
    end process;

end register_files_arch;
```

**SystemVerilog Translation (`register_files.sv`):**
```systemverilog
// Register File Module
// This module implements six 64-bit memory-mapped registers accessible via
// the Avalon Memory-Mapped (Avalon-MM) interface from the PCIe bridge.
// Supports synchronous read and write operations with address-based register selection.

module register_files (
    input  logic        clock,          // System clock (62.5MHz from PCIe)
    input  logic        reset,          // Active-low reset signal
    input  logic [31:0] addr_regs,      // Register address from Avalon-MM
    input  logic        read_regs,      // Read enable signal
    input  logic        write_regs,     // Write enable signal
    output logic [63:0] readdata_regs,  // Data output for read operations
    input  logic [63:0] writedata_regs  // Data input for write operations
);

    // Internal register signals - six 64-bit general purpose registers
    // These registers can be accessed from the Host PC via PCIe memory-mapped I/O
    logic [63:0] reg1;  // Register at offset 0x00000000
    logic [63:0] reg2;  // Register at offset 0x00000004
    logic [63:0] reg3;  // Register at offset 0x00000008
    logic [63:0] reg4;  // Register at offset 0x0000000C
    logic [63:0] reg5;  // Register at offset 0x00000010
    logic [63:0] reg6;  // Register at offset 0x00000014

    // Read Process
    // Handles synchronous read operations from the register file
    // When read_regs is asserted, the appropriate register is output based on addr_regs
    // Invalid addresses return a constant pattern for debugging
    always_ff @(posedge clock or negedge reset) begin
        if (!reset) begin
            // Active-low reset: clear read data output
            readdata_regs <= 64'h0;
        end else begin
            if (read_regs) begin
                // Address decoder: select register based on address
                case (addr_regs)
                    32'h00000000: readdata_regs <= reg1;  // Read reg1
                    32'h00000004: readdata_regs <= reg2;  // Read reg2
                    32'h00000008: readdata_regs <= reg3;  // Read reg3
                    32'h0000000C: readdata_regs <= reg4;  // Read reg4
                    32'h00000010: readdata_regs <= reg5;  // Read reg5
                    32'h00000014: readdata_regs <= reg6;  // Read reg6
                    // Return constant pattern for unmapped addresses (for debugging)
                    default:      readdata_regs <= 64'h9876987698769876;
                endcase
            end
        end
    end

    // Write Process
    // Handles synchronous write operations to the register file
    // When write_regs is asserted, writedata_regs is stored in the register specified by addr_regs
    // All registers are reset to zero on system reset
    always_ff @(posedge clock or negedge reset) begin
        if (!reset) begin
            // Active-low reset: initialize all registers to zero
            reg1 <= 64'h0;
            reg2 <= 64'h0;
            reg3 <= 64'h0;
            reg4 <= 64'h0;
            reg5 <= 64'h0;
            reg6 <= 64'h0;
        end else begin
            if (write_regs) begin
                // Address decoder: write to register based on address
                case (addr_regs)
                    32'h00000000: reg1 <= writedata_regs;  // Write to reg1
                    32'h00000004: reg2 <= writedata_regs;  // Write to reg2
                    32'h00000008: reg3 <= writedata_regs;  // Write to reg3
                    32'h0000000C: reg4 <= writedata_regs;  // Write to reg4
                    32'h00000010: reg5 <= writedata_regs;  // Write to reg5
                    32'h00000014: reg6 <= writedata_regs;  // Write to reg6
                    // Ignore writes to unmapped addresses
                    default:      ;
                endcase
            end
        end
    end

endmodule
```

---

## Translation Checklist

When translating each module, follow this checklist:

- [ ] Convert entity/architecture to module/endmodule
- [ ] Translate port declarations (watch bit ordering!)
- [ ] Convert signal declarations to logic
- [ ] Replace library uses with SystemVerilog equivalents
- [ ] Convert all processes to always_ff or always_comb
- [ ] Update sensitivity lists (or use always_comb)
- [ ] Change assignment operators (`:=` → `=`, keep `<=` for non-blocking)
- [ ] Convert case statements (when → case, others → default)
- [ ] Update literals (x"FF" → 8'hFF)
- [ ] Convert component declarations to module instantiations
- [ ] Update generic maps to parameter assignments
- [ ] Test with SystemVerilog simulator (ModelSim, VCS, Xcelium, Verilator)

---

## Recommended Translation Order

1. **Start with `register_files.vhd`** - Simplest module, no dependencies
2. **Translate `full_project.vhd`** - References register_files
3. **Translate `full_project_tb.vhd`** - Testbench to verify

---

## Simulation and Verification

After translation, verify using:

### ModelSim/QuestaSim
```bash
vlog -sv register_files.sv
vlog -sv full_project.sv
vlog -sv full_project_tb.sv
vsim -voptargs=+acc work.full_project_tb
run -all
```

### Verilator (Linting)
```bash
verilator --lint-only -sv register_files.sv
```

### VCS
```bash
vcs -sverilog register_files.sv full_project.sv full_project_tb.sv
./simv
```

---

## Additional Resources

- [SystemVerilog for VHDL Users](https://www.doulos.com/knowhow/sysverilog/)
- [IEEE 1800-2017 SystemVerilog Standard](https://ieeexplore.ieee.org/document/8299595)
- [Xilinx UltraFast Design Methodology](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug949-vivado-design-methodology.pdf)
- [Sutherland HDL - SystemVerilog Training](http://www.sutherland-hdl.com/)

---

## Summary

Key differences to remember:
1. **Module structure**: Entity+Architecture → Module
2. **Data types**: std_logic_vector → logic [N:0]
3. **Processes**: process → always_ff/always_comb
4. **Literals**: x"FF" → 8'hFF, '0'/'1' → 1'b0/1'b1
5. **Operators**: Same for most, but watch concatenation {a,b}
6. **Sensitivity**: Use always_comb for automatic sensitivity
7. **Case sensitivity**: VHDL is case-insensitive, SV is case-sensitive

This guide should provide all the information needed to successfully translate the PCIe bridge project from VHDL to SystemVerilog while maintaining functionality and readability.
