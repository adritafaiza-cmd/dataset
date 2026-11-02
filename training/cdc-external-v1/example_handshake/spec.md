Implement the SystemVerilog module `example_handshake`.

Implement example handshake using the interface and behavioral contract below.

Functional contract and interface notes:

Example: cdc_handshake instantiation
This example shows a 4-phase handshake between a 50 MHz "processor" domain
that initiates DMA transfers and a 200 MHz "DMA engine" domain that executes
them.
The processor asserts dma_req and waits for dma_ack. The DMA engine sees the
synchronized request, starts the DMA, and asserts its ack when done.

Required clock and reset behavior:

- Clock ports: clk_cpu, clk_dma.
- Reset ports: rst_cpu_n, rst_dma_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_handshake: cdc_handshake u_dma_hs ( .clk_src (clk_cpu), .rst_src_n (rst_cpu_n), .src_req_i (cpu_req), .src_ack_o (cpu_ack), .clk_dst (clk_dma), .rst_dst_n (rst_dma_n), .dst_req_o (dma_req_dma), .dst_ack_i (dma_ack_dma) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module example_handshake (
    // Processor domain (50 MHz)
    input  logic clk_cpu,
    input  logic rst_cpu_n,
    input  logic start_dma,     // CPU requests a DMA transfer
    output logic dma_done,      // High when DMA engine has acknowledged
    // DMA engine domain (200 MHz)
    input  logic clk_dma,
    input  logic rst_dma_n,
    output logic dma_req_dma,   // Synchronized DMA request in engine domain
    input  logic dma_ack_dma    // DMA engine asserts when transfer complete
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
