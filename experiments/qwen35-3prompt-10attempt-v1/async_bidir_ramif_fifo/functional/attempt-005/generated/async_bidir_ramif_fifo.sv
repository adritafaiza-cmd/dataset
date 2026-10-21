```verilog
`timescale 1ns/1ps

module async_bidir_ramif_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir,
       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,
       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

  // Internal pointers and counters
  reg [ASIZE-1:0] a_write_ptr;
  reg [ASIZE-1:0] a_read_ptr;
  reg [ASIZE-1:0] b_write_ptr;
  reg [ASIZE-1:0] b_read_ptr;

  // Cross-domain pointers (snapshots)
  reg [ASIZE-1:0] a_cross_ptr;
  reg [ASIZE-1:0] b_cross_ptr;

  // Flags for cross-domain logic
  reg a_cross_valid;
  reg b_cross_valid;

  // Full/Empty flags (internal logic)
  reg a_full_int;
  reg a_empty_int;
  reg b_full_int;
  reg b_empty_int;

  // Asynchronous Full/Empty flags (cross-domain)
  reg a_afull;
  reg a_aempty;
  reg b_afull;
  reg b_aempty;

  // RAM Interface Signals
  wire [ASIZE-1:0] ram_addr_a;
  wire [ASIZE-1:0] ram_addr_b;
  wire [DSIZE-1:0] ram_wdata_a;
  wire [DSIZE-1:0] ram_wdata_b;
  wire ram_winc_a;
  wire ram_winc_b;
  wire ram_rinc_a;
  wire ram_rinc_b;

  // Clock generation for external RAM
  // We drive the RAM clocks based on the activity of the respective side
  // to ensure the external RAM sees a valid clock when accessed.
  // In a real system, these might be derived from a global clock or the local clock
  // if the RAM is synchronous to the local clock. Here we assume the RAM is
  // synchronous to the clock we drive.
  assign o_ram_a_clk = a_clk;
  assign o_ram_b_clk = b_clk;

  // Address generation logic
  // Address is simply the pointer value.
  assign o_ram_a_addr = a_write_ptr;
  assign o_ram_b_addr = b_write_ptr;

  // Write Data generation
  // When writing, we take the local write data.
  assign o_ram_a_wdata = a_winc ? a_wdata : 16'd0; // Assuming DSIZE <= 16 for safety, else use a_wdata
  assign o_ram_b_wdata = b_winc ? b_wdata : 16'd0;

  // Write Enable generation
  // Write occurs when the local write pointer is incremented.
  assign o_ram_a_winc = a_winc;
  assign o_ram_b_winc = b_winc;

  // Read Enable generation
  // Read occurs when the local read pointer is incremented.
  assign o_ram_a_rinc = a_rinc;
  assign o_ram_b_rinc = b_rinc;

  // Read Data generation
  // Read data comes from the external RAM inputs.
  assign a_rdata = i_ram_a_rdata;
  assign b_rdata = i_ram_b_rdata;

  // ------------------------------------------------------------------
  // Side A Logic (Clock: a_clk)
  // ------------------------------------------------------------------

  // Update cross-domain pointer from Side B
  // This happens asynchronously on a_clk edge when b_cross_valid is high
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_cross_ptr <= 4'd0;
      a_cross_valid <= 1'b0;
    end else if (b_cross_valid) begin
      a_cross_ptr <= b_cross_ptr;
      a_cross_valid <= 1'b1;
    end
  end

  // Update cross-domain pointer from Side A to Side B
  // This happens asynchronously on b_clk edge when a_cross_valid is high
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_cross_ptr <= 4'd0;
      b_cross_valid <= 1'b0;
    end else if (a_cross_valid) begin
      b_cross_ptr <= a_cross_ptr;
      b_cross_valid <= 1'b1;
    end
  end

  // Side A Write Logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_write_ptr <= 4'd0;
    end else if (a_winc) begin
      a_write_ptr <= a_write_ptr + 1;
    end
  end

  // Side A Read Logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_read_ptr <= 4'd0;
    end else if (a_rinc) begin
      a_read_ptr <= a_read_ptr + 1;
    end
  end

  // Side A Full/Empty Internal Logic
  // Full: Write Ptr == Read Ptr + 1 (or 0 if FALLTHROUGH)
  // Empty: Write Ptr == Read Ptr
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_int <= 1'b0;
      a_empty_int <= 1'b1;
    end else begin
      // Calculate expected full condition
      // If FALLTHROUGH, full is when (wr_ptr + 1) == rd_ptr
      // Else, full is when wr_ptr == rd_ptr
      if (FALLTHROUGH) begin
        a_full_int <= (a_write_ptr + 1) == a_read_ptr;
      end else begin
        a_full_int <= a_write_ptr == a_read_ptr;
      end
      a_empty_int <= a_write_ptr == a_read_ptr;
    end
  end

  // Side A Asynchronous Full/Empty (Cross-domain)
  // These flags are updated on b_clk based on the snapshot of pointers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_afull <= 1'b0;
      a_aempty <= 1'b1;
    end else begin
      if (FALLTHROUGH) begin
        a_afull <= (b_cross_ptr + 1) == a_cross_ptr;
      end else begin
        a_afull <= b_cross_ptr == a_cross_ptr;
      end
      a_aempty <= b_cross_ptr == a_cross_ptr;
    end
  end

  // ------------------------------------------------------------------
  // Side B Logic (Clock: b_clk)
  // ------------------------------------------------------------------

  // Update cross-domain pointer from Side A (already handled above)
  // Update cross-domain pointer from Side B to Side A
  // This happens asynchronously on a_clk edge when b_cross_valid is high
  // (Note: The logic for updating a_cross_ptr was already done above)
  // We need to ensure b_cross_ptr is updated correctly on a_clk
  // Re-checking the logic: 
  // a_cross_ptr is updated on a_clk using b_cross_valid.
  // b_cross_ptr is updated on b_clk using a_cross_valid.
  // This is correct.

  // Side B Write Logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_write_ptr <= 4'd0;
    end else if (b_winc) begin
      b_write_ptr <= b_write_ptr + 1;
    end
  end

  // Side B Read Logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_read_ptr <= 4'd0;
    end else if (b_rinc) begin
      b_read_ptr <= b_read_ptr + 1;
    end
  end

  // Side B Full/Empty Internal Logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_int <= 1'b0;
      b_empty_int <= 1'b1;
    end else begin
      if (FALLTHROUGH) begin
        b_full_int <= (b_write_ptr + 1) == b_read_ptr;
      end else begin
        b_full_int <= b_write_ptr == b_read_ptr;
      end
      b_empty_int <= b_write_ptr == b_read_ptr;
    end
  end

  // Side B Asynchronous Full/Empty (Cross-domain)
  // Updated on a_clk based on snapshot
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_afull <= 1'b0;
      b_aempty <= 1'b1;
    end else begin
      if (FALLTHROUGH) begin
        b_afull <= (a_cross_ptr + 1) == b_cross_ptr;
      end else begin
        b_afull <= a_cross_ptr == b_cross_ptr;
      end
      b_aempty <= a_cross_ptr == b_cross_ptr;
    end
  end

  // ------------------------------------------------------------------
  // Output Assignments
  // ------------------------------------------------------------------

  // Side A Outputs
  assign a_full = a_full_int;
  assign a_afull = a_afull;
  assign a_empty = a_empty_int;
  assign a_aempty = a_aempty;

  // Side B Outputs
  assign b_full = b_full_int;
  assign b_afull = b_afull;
  assign b_empty = b_empty_int;
  assign b_aempty = b_aempty;

endmodule
```<|im_end|>
