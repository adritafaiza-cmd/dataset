```verilog
`timescale 1ns/1ps

module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
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
       input wire              b_dir
       );

  // Internal pointers and counters
  reg [ASIZE-1:0] a_write_ptr;
  reg [ASIZE-1:0] a_read_ptr;
  reg [ASIZE-1:0] b_write_ptr;
  reg [ASIZE-1:0] b_read_ptr;

  // Gray code pointers for cross-domain signaling
  reg [ASIZE-1:0] a_write_gray;
  reg [ASIZE-1:0] a_read_gray;
  reg [ASIZE-1:0] b_write_gray;
  reg [ASIZE-1:0] b_read_gray;

  // Status flags
  reg a_full_int;
  reg a_empty_int;
  reg b_full_int;
  reg b_empty_int;

  // Acknowledged status (sampled across domains)
  reg a_afull;
  reg a_aempty;
  reg b_afull;
  reg b_aempty;

  // Write data registers
  reg [DSIZE-1:0] a_write_data_reg;
  reg [DSIZE-1:0] b_write_data_reg;

  // Read data registers
  reg [DSIZE-1:0] a_read_data_reg;
  reg [DSIZE-1:0] b_read_data_reg;

  // Direction control
  reg a_dir_reg;
  reg b_dir_reg;

  // Write enable signals (internal)
  reg a_write_en;
  reg b_write_en;

  // Read enable signals (internal)
  reg a_read_en;
  reg b_read_en;

  // Helper function to generate Gray code from binary
  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    begin
      bin2gray = {bin[ASIZE-2:0], bin[ASIZE-1] ^ bin[ASIZE-2:0]};
    end
  endfunction

  // Helper function to convert Gray code back to binary
  function [ASIZE-1:0] gray2bin;
    input [ASIZE-1:0] gray;
    begin
      gray2bin = gray;
      for (integer i = ASIZE-2; i >= 0; i = i - 1) begin
        gray2bin[i] = gray[i] ^ gray[i+1];
      end
    end
  endfunction

  // Write logic for Domain A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_write_ptr <= 0;
      a_write_data_reg <= 0;
      a_dir_reg <= 0;
      a_write_en <= 0;
    end else begin
      if (a_winc) begin
        a_write_ptr <= a_write_ptr + 1'b1;
        a_write_data_reg <= a_wdata;
        a_dir_reg <= a_dir;
        a_write_en <= 1;
      end else begin
        a_write_en <= 0;
      end
    end
  end

  // Write logic for Domain B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_write_ptr <= 0;
      b_write_data_reg <= 0;
      b_dir_reg <= 0;
      b_write_en <= 0;
    end else begin
      if (b_winc) begin
        b_write_ptr <= b_write_ptr + 1'b1;
        b_write_data_reg <= b_wdata;
        b_dir_reg <= b_dir;
        b_write_en <= 1;
      end else begin
        b_write_en <= 0;
      end
    end
  end

  // Read logic for Domain A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_read_ptr <= 0;
      a_read_data_reg <= 0;
      a_read_en <= 0;
    end else begin
      if (a_rinc) begin
        a_read_ptr <= a_read_ptr + 1'b1;
        a_read_en <= 1;
      end else begin
        a_read_en <= 0;
      end
    end
  end

  // Read logic for Domain B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_read_ptr <= 0;
      b_read_data_reg <= 0;
      b_read_en <= 0;
    end else begin
      if (b_rinc) begin
        b_read_ptr <= b_read_ptr + 1'b1;
        b_read_en <= 1;
      end else begin
        b_read_en <= 0;
      end
    end
  end

  // Cross-domain pointer updates (Gray code)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_write_gray <= 0;
      a_read_gray <= 0;
    end else begin
      a_write_gray <= bin2gray(a_write_ptr);
      a_read_gray <= bin2gray(a_read_ptr);
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_write_gray <= 0;
      b_read_gray <= 0;
    end else begin
      b_write_gray <= bin2gray(b_write_ptr);
      b_read_gray <= bin2gray(b_read_ptr);
    end
  end

  // Full/Empty logic for Domain A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_int <= 0;
      a_empty_int <= 1;
    end else begin
      if (a_write_ptr == a_read_ptr) begin
        a_empty_int <= 1;
        a_full_int <= 0;
      end else if (a_write_ptr == (a_read_ptr + 1'b1) - 1) begin
        a_empty_int <= 0;
        a_full_int <= 1;
      end else begin
        a_empty_int <= 0;
        a_full_int <= 0;
      end
    end
  end

  // Full/Empty logic for Domain B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_int <= 0;
      b_empty_int <= 1;
    end else begin
      if (b_write_ptr == b_read_ptr) begin
        b_empty_int <= 1;
        b_full_int <= 0;
      end else if (b_write_ptr == (b_read_ptr + 1'b1) - 1) begin
        b_empty_int <= 0;
        b_full_int <= 1;
      end else begin
        b_empty_int <= 0;
        b_full_int <= 0;
      end
    end
  end

  // Read data output logic for Domain A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata <= 0;
    end else begin
      if (a_rinc) begin
        // Sample the data from the write side of the other domain
        if (a_dir) begin
          // Reading from B's write side
          a_rdata <= b_write_data_reg;
        end else begin
          // Reading from A's own write side
          a_rdata <= a_write_data_reg;
        end
      end else begin
        a_rdata <= a_rdata;
      end
    end
  end

  // Read data output logic for Domain B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata <= 0;
    end else begin
      if (b_rinc) begin
        // Sample the data from the write side of the other domain
        if (b_dir) begin
          // Reading from A's write side
          b_rdata <= a_write_data_reg;
        end else begin
          // Reading from B's own write side
          b_rdata <= b_write_data_reg;
        end
      end else begin
        b_rdata <= b_rdata;
      end
    end
  end

  // Acknowledged status logic for Domain A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_afull <= 0;
      a_aempty <= 1;
    end else begin
      if (FALLTHROUGH == "TRUE") begin
        if (a_rinc) begin
          if (a_dir) begin
            // Reading from B's write side
            if (b_write_gray == a_read_gray) begin
              a_aempty <= 1;
              a_afull <= 0;
            end else if (b_write_gray == (a_read_gray + 1'b1) - 1) begin
              a_aempty <= 0;
              a_afull <= 1;
            end else begin
              a_aempty <= 0;
              a_afull <= 0;
            end
          end else begin
            // Reading from A's own write side
            if (a_write_gray == a_read_gray) begin
              a_aempty <= 1;
              a_afull <= 0;
            end else if (a_write_gray == (a_read_gray + 1'b1) - 1) begin
              a_aempty <= 0;
              a_afull <= 1;
            end else begin
              a_aempty <= 0;
              a_afull <= 0;
            end
          end
        end else begin
          a_afull <= a_afull;
          a_aempty <= a_aempty;
        end
      end else begin
        // Combinational read not selected
        a_afull <= a_full_int;
        a_aempty <= a_empty_int;
      end
    end
  end

  // Acknowledged status logic for Domain B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_afull <= 0;
      b_aempty <= 1;
    end else begin
      if (FALLTHROUGH == "TRUE") begin
        if (b_rinc) begin
          if (b_dir) begin
            // Reading from A's write side
            if (a_write_gray == b_read_gray) begin
              b_aempty <= 1;
              b_afull <= 0;
            end else if (a_write_gray == (b_read_gray + 1'b1) - 1) begin
              b_aempty <= 0;
              b_afull <= 1;
            end else begin
              b_aempty <= 0;
              b_afull <= 0;
            end
          end else begin
            // Reading from B's own write side
            if (b_write_gray == b_read_gray) begin
              b_aempty <= 1;
              b_afull <= 0;
            end else if (b_write_gray == (b_read_gray + 1'b1) - 1) begin
              b_aempty <= 0;
              b_afull <= 1;
            end else begin
              b_aempty <= 0;
              b_afull <= 0;
            end
          end
        end else begin
          b_afull <= b_afull;
          b_aempty <= b_aempty;
        end
      end else begin
        // Combinational read not selected
        b_afull <= b_full_int;
        b_aempty <= b_empty_int;
      end
    end
  end

  // Output full/empty signals (non-acknowledged)
  assign a_full = a_full_int;
  assign a_empty = a_empty_int;
  assign b_full = b_full_int;
  assign b_empty = b_empty_int;

endmodule
```<|im_end|>
