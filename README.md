# SPI Master Controller

A high-performance, configurable SPI (Serial Peripheral Interface) Master implementation for FPGA and embedded systems. This module provides a reliable and flexible solution for interfacing with SPI slave devices.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Usage](#usage)
- [SPI Modes](#spi-modes)
- [Timing Diagrams](#timing-diagrams)
- [Examples](#examples)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Features

- ✅ Full SPI Master protocol implementation
- ✅ Support for all four SPI modes (Mode 0, 1, 2, 3)
- ✅ Configurable clock divider for flexible baud rates
- ✅ Variable data width (8, 16, 32 bits)
- ✅ Multi-slave support with individual chip select
- ✅ MSB-first and LSB-first data transmission
- ✅ Status flags (busy, ready, error)
- ✅ Simple and intuitive interface
- ✅ Synthesizable for major FPGA platforms (Xilinx, Intel, Lattice)
- ✅ Thoroughly tested and documented

## Architecture

### Block Diagram

```
┌─────────────────────────────────────┐
│         SPI Master Core             │
│                                     │
│  ┌──────────┐      ┌────────────┐  │
│  │  Control │      │   Clock    │  │
│  │  Logic   │◄────►│  Generator │  │
│  └──────────┘      └────────────┘  │
│       │                             │
│       ▼                             │
│  ┌──────────┐      ┌────────────┐  │
│  │   Shift  │◄────►│    CS      │  │
│  │ Register │      │   Control  │  │
│  └──────────┘      └────────────┘  │
└─────────────────────────────────────┘
        │      │      │      │
        ▼      ▼      ▼      ▼
      MOSI   MISO   SCLK    CS
```

### Pin Description

| Signal | Direction | Description |
|--------|-----------|-------------|
| `clk` | Input | System clock |
| `rst` | Input | Asynchronous reset (active high) |
| `start` | Input | Start transmission |
| `data_in` | Input | Data to transmit |
| `data_out` | Output | Received data |
| `busy` | Output | Transaction in progress |
| `done` | Output | Transaction complete |
| `sclk` | Output | SPI clock |
| `mosi` | Output | Master Out Slave In |
| `miso` | Input | Master In Slave Out |
| `cs_n` | Output | Chip Select (active low) |

## Getting Started

### Prerequisites

- FPGA development tools (Vivado, Quartus, or similar)
- Verilog/VHDL simulator (ModelSim, Vivado Simulator, etc.)
- Basic understanding of SPI protocol

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/spi_master.git
cd spi_master
```

2. Add the source files to your project:
```
src/
├── spi_master.v          # Main SPI master module
├── spi_clock_gen.v       # Clock generator
└── spi_controller.v      # Control FSM
```

3. Include in your design:
```verilog
`include "spi_master.v"
```

## Configuration

### Parameters

Configure the SPI Master by setting these parameters:

```verilog
module spi_master #(
    parameter CLOCK_DIV = 8,      // Clock divider (system_clk / SPI_clk)
    parameter DATA_WIDTH = 8,     // Data frame size (8, 16, 32)
    parameter CPOL = 0,           // Clock polarity (0 or 1)
    parameter CPHA = 0,           // Clock phase (0 or 1)
    parameter MSB_FIRST = 1       // 1 for MSB first, 0 for LSB first
) (
    // ports...
);
```

### Configuration Examples

**Fast SPI (10 MHz from 100 MHz system clock):**
```verilog
spi_master #(
    .CLOCK_DIV(10),
    .DATA_WIDTH(8),
    .CPOL(0),
    .CPHA(0)
) spi_inst (
    // connections...
);
```

**16-bit SPI Mode 3:**
```verilog
spi_master #(
    .CLOCK_DIV(16),
    .DATA_WIDTH(16),
    .CPOL(1),
    .CPHA(1)
) spi_inst (
    // connections...
);
```

## Usage

### Basic Transaction

```verilog
// 1. Wait for ready state
wait(!busy);

// 2. Load data
data_in <= 8'hA5;

// 3. Assert start signal
start <= 1'b1;

// 4. Wait one clock cycle
@(posedge clk);
start <= 1'b0;

// 5. Wait for completion
wait(done);

// 6. Read received data
rx_data <= data_out;
```

### Example Instantiation

```verilog
module top_module (
    input wire clk,
    input wire rst,
    // SPI signals
    output wire spi_sclk,
    output wire spi_mosi,
    input wire spi_miso,
    output wire spi_cs_n
);

    reg [7:0] tx_data;
    wire [7:0] rx_data;
    reg start_tx;
    wire busy, done;
    
    spi_master #(
        .CLOCK_DIV(8),
        .DATA_WIDTH(8),
        .CPOL(0),
        .CPHA(0)
    ) spi_inst (
        .clk(clk),
        .rst(rst),
        .start(start_tx),
        .data_in(tx_data),
        .data_out(rx_data),
        .busy(busy),
        .done(done),
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs_n(spi_cs_n)
    );
    
    // Your application logic here
    
endmodule
```

## SPI Modes

| Mode | CPOL | CPHA | Clock Polarity | Clock Phase |
|------|------|------|----------------|-------------|
| 0 | 0 | 0 | Idle Low | Sample on leading edge |
| 1 | 0 | 1 | Idle Low | Sample on trailing edge |
| 2 | 1 | 0 | Idle High | Sample on leading edge |
| 3 | 1 | 1 | Idle High | Sample on trailing edge |

## Timing Diagrams

### Mode 0 (CPOL=0, CPHA=0)
```
CS_N  ‾‾‾\_____________________________________/‾‾‾
SCLK  ___/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_____
MOSI  ---<D7><D6><D5><D4><D3><D2><D1><D0>---
MISO  ---<D7><D6><D5><D4><D3><D2><D1><D0>---
```

### Mode 3 (CPOL=1, CPHA=1)
```
CS_N  ‾‾‾\_____________________________________/‾‾‾
SCLK  ‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾‾‾
MOSI  ---<D7><D6><D5><D4><D3><D2><D1><D0>---
MISO  ---<D7><D6><D5><D4><D3><D2><D1><D0>---
```

## Examples

### Reading from an ADC (MCP3008)

```verilog
// Send start bit + single-ended channel 0 command
tx_data <= 8'b11000000;
start_tx <= 1'b1;
@(posedge clk);
start_tx <= 1'b0;
wait(done);

// Read 10-bit result (2 more bytes)
// ... additional transactions
```

### Writing to Flash Memory

```verilog
// Write enable command
tx_data <= 8'h06;
start_tx <= 1'b1;
// ... continue with address and data bytes
```

## Testing

### Running Simulations

```bash
# Using Vivado
vivado -mode batch -source sim/run_sim.tcl

# Using ModelSim
vsim -do sim/testbench.do

# Using Icarus Verilog
iverilog -o sim.vvp testbench/tb_spi_master.v src/spi_master.v
vvp sim.vvp
```

### Testbench

A comprehensive testbench is provided in `testbench/tb_spi_master.v` that tests:
- All four SPI modes
- Different data widths
- Back-to-back transactions
- Error conditions

## Project Structure

```
spi_master/
├── src/
│   ├── spi_master.v          # Top-level module
│   ├── spi_clock_gen.v       # Clock divider
│   └── spi_controller.v      # FSM controller
├── testbench/
│   ├── tb_spi_master.v       # Main testbench
│   └── spi_slave_model.v     # SPI slave for testing
├── sim/
│   └── run_sim.tcl           # Simulation scripts
├── doc/
│   ├── timing.pdf            # Detailed timing diagrams
│   └── integration_guide.pdf # Integration guide
├── examples/
│   ├── adc_interface.v       # ADC example
│   └── flash_controller.v    # Flash memory example
├── LICENSE
└── README.md
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please ensure your code:
- Follows the existing coding style
- Includes appropriate test cases
- Updates documentation as needed

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- SPI protocol specification from various semiconductor datasheets
- Community feedback and contributions

## Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Check existing documentation in the `doc/` folder
- Review example implementations in `examples/`

## Roadmap

- [ ] Add DMA support for high-speed transfers
- [ ] Implement multi-master arbitration
- [ ] Add support for Quad-SPI mode
- [ ] Create Python test framework
- [ ] Add support for more FPGA platforms

---

**⭐ If you find this project useful, please consider giving it a star!**