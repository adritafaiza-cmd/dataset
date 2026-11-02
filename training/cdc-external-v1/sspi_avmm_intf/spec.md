Implement the SystemVerilog module `sspi_avmm_intf`.

Implement sspi avmm intf using the interface and behavioral contract below.

Functional contract and interface notes:

07/16/21
This module handles AVMM side read/write to AIB PHY CSR. Then read/write to buffer

Required clock and reset behavior:

- Clock ports: avmm_clk.
- Reset ports: avmm_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- spi_bitsync: spi_bitsync #(.DWIDTH(32)) bitsync2_csr0_reg ( .clk (avmm_clk), .rst_n (avmm_rst_n), .data_in (csr0_reg[31:0]), .data_out (csr0_reg_sync_aclk[31:0]) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module sspi_avmm_intf #(
      parameter AVMM_ADDR_WIDTH=16,
      parameter BUF_SIZE = 256,
      parameter BUF_ADWIDTH = $clog2(BUF_SIZE)
   ) (
   input   logic                         avmm_clk, // AVMM Slave interface
   input   logic                         avmm_rst_n,
   //AVMM interface 0
   output  logic                         o_avmm0_write,
   output  logic                         o_avmm0_read,
   output  logic  [AVMM_ADDR_WIDTH-1:0]  o_avmm0_addr,
   output  logic  [31:0]                 o_avmm0_wdata,
   output  logic  [3:0]                  o_avmm0_byte_en,
   input   logic  [31:0]                 i_avmm0_rdata,
   input   logic                         i_avmm0_rdatavalid,
   input   logic                         i_avmm0_waitrequest,
   //AVMM interface 1
   output  logic                         o_avmm1_write,
   output  logic                         o_avmm1_read,
   output  logic  [AVMM_ADDR_WIDTH-1:0]  o_avmm1_addr,
   output  logic  [31:0]                 o_avmm1_wdata,
   output  logic  [3:0]                  o_avmm1_byte_en,
   input   logic  [31:0]                 i_avmm1_rdata,
   input   logic                         i_avmm1_rdatavalid,
   input   logic                         i_avmm1_waitrequest,
   //AVMM interface 2
   output  logic                         o_avmm2_write,
   output  logic                         o_avmm2_read,
   output  logic  [AVMM_ADDR_WIDTH-1:0]  o_avmm2_addr,
   output  logic  [31:0]                 o_avmm2_wdata,
   output  logic  [3:0]                  o_avmm2_byte_en,
   input   logic  [31:0]                 i_avmm2_rdata,
   input   logic                         i_avmm2_rdatavalid,
   input   logic                         i_avmm2_waitrequest,
   input   logic [31:0]                  csr0_reg,    //SCLK domain This is treated as static by SDC delay constrain 
   input   logic [31:0]                  csr1_reg,    //SCLK domain This is static
   input   logic [31:0]                  rx_buf_rdata,
   output  logic [BUF_ADWIDTH-1:0]       rx_buf_raddr, 
   output  logic [31:0]                  tx_buf_wdata,
   output  logic [BUF_ADWIDTH-1:0]       tx_buf_waddr,
   output  logic                         tx_buf_we,
   output  logic                         trans_done
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
