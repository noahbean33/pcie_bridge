# Bugs and Issues

This document identifies potential bugs and issues found in the PCIe bridge project.

## Critical Issues

### 1. Sensitivity List Issues in register_files.vhd

**File**: `register_files.vhd` (Line 46)

**Issue**: The read process has an incorrect sensitivity list for a synchronous process.

```vhdl
process (clock,reset,read_regs,reg1,reg2,reg3,reg4,reg5,reg6)
```

**Problem**: For a synchronous process (using `rising_edge(clock)`), the sensitivity list should only contain `clock` and `reset`. Including other signals (`read_regs`, `reg1`, `reg2`, etc.) is incorrect for synthesizable code and may cause simulation/synthesis mismatches.

**Fix**: Change the sensitivity list to:
```vhdl
process (clock, reset)
```

**Impact**: May cause synthesis warnings or mismatches between simulation and hardware behavior.

---

### 2. Sensitivity List Issues in register_files.vhd (Write Process)

**File**: `register_files.vhd` (Line 75)

**Issue**: The write process has an incorrect sensitivity list.

```vhdl
process (clock,reset,write_regs)
```

**Problem**: For a synchronous process, only `clock` and `reset` should be in the sensitivity list. The `write_regs` signal is read within the process and should not be in the sensitivity list.

**Fix**: Change to:
```vhdl
process (clock, reset)
```

**Impact**: May cause synthesis warnings or simulation issues.

---

## Minor Issues

### 3. Unused Signal Declaration

**File**: `register_files.vhd` (Line 36)

**Issue**: Signal `reg7` is declared but never used.

```vhdl
signal reg7:std_logic_vector ( 63 downto 0 );  -- Unused register (declared but not implemented)
```

**Problem**: This signal is declared but has no functionality - it's not readable or writable, and occupies no address space. This creates confusion and wastes resources.

**Fix**: Remove the declaration entirely or implement it as the 7th register.

**Impact**: Code clutter and potential confusion for future maintainers.

---

### 4. Hardcoded Waitrequest Signal

**File**: `full_project.vhd` (Line 123)

**Issue**: The `M_AVALON_0_waitrequest` signal is hardcoded to '0'.

```vhdl
M_AVALON_0_waitrequest        => '0',
```

**Problem**: While this works for the current simple register file implementation, it prevents proper flow control in the Avalon-MM interface. If the register file ever needs to stall transactions (e.g., for slower operations), this cannot be supported.

**Fix**: Connect this to an actual waitrequest signal from the register file or document why it's acceptable to tie it to '0'.

**Impact**: Low - works for current implementation, but limits future extensibility.

---

### 5. Read Data Timing Issue

**File**: `full_project.vhd` (Lines 156-173)

**Issue**: The `m_avalon_0_readdatavalid` signal is generated in the top-level module, creating a one-cycle delay that might not align with Avalon-MM timing requirements.

**Problem**: The readdatavalid signal is asserted one cycle after `read_regs` is asserted. However, `readdata_regs` is also updated in that same cycle within the register_files module. This creates potential timing ambiguity.

**Fix**: Consider implementing the readdatavalid signal inside the register_files module for better encapsulation and clearer timing.

**Impact**: Low - appears to work correctly but could be more robust.

---

### 6. Incomplete Address Decoding Test Coverage

**File**: `full_project_tb.vhd`

**Issue**: The testbench doesn't comprehensively test all register addresses or verify read operations.

**Problem**: The testbench only performs write operations to some addresses (0x10, 0x14, 0x18) and doesn't verify:
- Writes to registers 1-4 (addresses 0x00, 0x04, 0x08, 0x0C)
- Read operations from any register
- The default return value (0x9876987698769876) for invalid addresses

**Fix**: Add test cases for:
- All six valid register addresses
- Read transactions to verify written data
- Reads from invalid addresses to verify the default pattern

**Impact**: Medium - incomplete verification of the design functionality.

---

### 7. Reset Polarity Inconsistency

**File**: `full_project.vhd`, `register_files.vhd`

**Issue**: Mixed reset polarity conventions.

**Problem**: 
- `RST_IN` is active-high (external input)
- `reset_pcie_out` is active-low (from PCIe block)
- This inconsistency can lead to confusion

**Fix**: Document the reset polarity clearly at each interface, or add a polarity converter if possible.

**Impact**: Low - works correctly but can be confusing for designers.

---

## Potential Issues

### 8. No Byte Enable Support

**File**: `register_files.vhd`

**Issue**: The register file doesn't support byte-level write enables.

**Problem**: All writes are 64-bit wide. The Avalon-MM interface could potentially support byte enables for partial register writes, but this isn't implemented.

**Fix**: Add byte enable support if needed for the application.

**Impact**: Low - depends on application requirements.

---

### 9. No Error Response for Invalid Addresses

**File**: `register_files.vhd`

**Issue**: Invalid write addresses are silently ignored.

```vhdl
when others => null;
```

**Problem**: There's no error signaling mechanism (e.g., Avalon-MM response signal) to indicate that a write to an invalid address failed.

**Fix**: Consider implementing error response signals if the PCIe IP supports them.

**Impact**: Low - current behavior is acceptable but could be more robust.
