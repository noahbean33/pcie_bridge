# PCIe-to-Register-File Bridge via Avalon-MM

This project implements a high-speed communication bridge between a Host PC (Root Port) and an FPGA (Endpoint) using the PCI Express (PCIe) protocol. It features a custom Register File module that allows for 64-bit data storage and retrieval via an Avalon Memory-Mapped (Avalon-MM) interface.

## Project Architecture

The system is designed for the Xilinx Artix-7 family and consists of three primary layers:

- **Physical/Link Layer**: Handled by the `pcie_block_wrapper`, which manages the differential transceiver signals (PCIE_RX/PCIE_TX) and link training.
- **Protocol Translation**: The PCIe IP core translates PCIe TLP (Transaction Layer Packets) into the Avalon-MM protocol, providing simplified read, write, and address signals.
- **Application Layer**: A custom `register_files` module that provides six 64-bit internal registers for data processing or hardware control.

## Technical Specifications

- **Protocol**: PCIe Gen1/Gen2 x1
- **Data Width**: 64-bit data bus for all register operations
- **Clocking**:
  - Reference Clock: 100MHz differential input (CLK_IN_P/N)
  - User Clock: 62.5MHz synchronized PCIe clock domain
- **Interface**: Avalon Memory-Mapped (Avalon-MM)

## Memory Map

The Host PC can access specific hardware registers by targeting the following memory addresses:

| Offset Address | Register | Description                        |
|----------------|----------|------------------------------------|
| 0x00000000     | reg1     | 64-bit General Purpose Register    |
| 0x00000004     | reg2     | 64-bit General Purpose Register    |
| 0x00000008     | reg3     | 64-bit General Purpose Register    |
| 0x0000000C     | reg4     | 64-bit General Purpose Register    |
| 0x00000010     | reg5     | 64-bit General Purpose Register    |
| 0x00000014     | reg6     | 64-bit General Purpose Register    |
| Others         | N/A      | Returns constant 0x9876987698769876|

## Implementation Details

### Clock and Reset Management

The project utilizes the IBUFDS (Differential Input Buffer) primitive to handle the high-speed 100MHz reference clock. The system is held in reset until the PCIe IP block signals that the link is stable (`reset_pcie_out`).

### Data Transfer Process

Data transfers are managed through a dual-process VHDL architecture:

- **Write Process**: Listens for `write_regs = '1'` and updates the internal signals (reg1 to reg6) based on the incoming `writedata_regs`.
- **Read Process**: When `read_regs = '1'`, the module multiplexes the requested register data onto `readdata_regs`.
- **Handshaking**: The `m_avalon_0_readdatavalid` signal is used to inform the PCIe controller that the requested data is ready for transmission back to the Root Port.

## File Structure

- **full_project.vhd**: Top-level entity integrating the PCIe wrapper and Register File
- **full_project_tb.vhd**: Testbench for the PCIe bridge system
- **register_files.vhd**: Implementation of the 64-bit memory-mapped registers

## Future Enhancements

- Implementation of DMA (Direct Memory Access) for higher throughput
- Expansion of the Register File to include status flags and interrupt control
- Development of a Linux Kernel Driver to interface with the FPGA from user-space

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.