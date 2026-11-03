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

  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [ASIZE-1:0] a_ptr, a_ptr_gray, b_ptr, b_ptr_gray;
  reg [ASIZE-1:0] a_ptr_sync, b_ptr_sync;
  reg [ASIZE-1:0] a_ptr_sync_gray, b_ptr_sync_gray;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;
  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  // Synchronize pointers across clock domains
  sync_gray #(.WIDTH(ASIZE)) a_ptr_sync_u (.clk(a_clk), .rst_n(a_rst_n), .din(b_ptr_gray), .dout(a_ptr_sync));
  sync_gray #(.WIDTH(ASIZE)) b_ptr_sync_u (.clk(b_clk), .rst_n(b_rst_n), .din(a_ptr_gray), .dout(b_ptr_sync));

  // Gray code conversion
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_ptr_gray <= {ASIZE{1'b0}};
    end else begin
      a_ptr_gray <= gray_encode(a_ptr);
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_ptr_gray <= {ASIZE{1'b0}};
    end else begin
      b_ptr_gray <= gray_encode(b_ptr);
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_ptr_sync_gray <= {ASIZE{1'b0}};
    end else begin
      a_ptr_sync_gray <= gray_encode(a_ptr_sync);
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_ptr_sync_gray <= {ASIZE{1'b0}};
    end else begin
      b_ptr_sync_gray <= gray_encode(b_ptr_sync);
    end
  end

  // Write logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_ptr <= {ASIZE{1'b0}};
      a_full_reg <= 1'b0;
      a_afull_reg <= 1'b0;
    end else if (a_dir && a_winc) begin
      if (a_full_reg) begin
        // Do nothing
      end else begin
        mem[a_ptr] <= a_wdata;
        a_ptr <= a_ptr + 1;
        if (a_ptr == 2**ASIZE - 1) begin
          a_full_reg <= 1'b1;
        end else if (a_ptr == 2**ASIZE - 2) begin
          a_afull_reg <= 1'b1;
        end
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_ptr <= {ASIZE{1'b0}};
      b_full_reg <= 1'b0;
      b_afull_reg <= 1'b0;
    end else if (b_dir && b_winc) begin
      if (b_full_reg) begin
        // Do nothing
      end else begin
        mem[b_ptr] <= b_wdata;
        b_ptr <= b_ptr + 1;
        if (b_ptr == 2**ASIZE - 1) begin
          b_full_reg <= 1'b1;
        end else if (b_ptr == 2**ASIZE - 2) begin
          b_afull_reg <= 1'b1;
        end
      end
    end
  end

  // Read logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= {DSIZE{1'b0}};
      a_empty_reg <= 1'b1;
      a_aempty_reg <= 1'b1;
    end else if (!a_dir && a_rinc) begin
      if (a_empty_reg) begin
        // Do nothing
      end else begin
        a_rdata_reg <= mem[a_ptr_sync];
        a_ptr_sync <= a_ptr_sync + 1;
        if (a_ptr_sync == 2**ASIZE - 1) begin
          a_empty_reg <= 1'b1;
        end else if (a_ptr_sync == 2**ASIZE - 2) begin
          a_aempty_reg <= 1'b1;
        end
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= {DSIZE{1'b0}};
      b_empty_reg <= 1'b1;
      b_aempty_reg <= 1'b1;
    end else if (!b_dir && b_rinc) begin
      if (b_empty_reg) begin
        // Do nothing
      end else begin
        b_rdata_reg <= mem[b_ptr_sync];
        b_ptr_sync <= b_ptr_sync + 1;
        if (b_ptr_sync == 2**ASIZE - 1) begin
          b_empty_reg <= 1'b1;
        end else if (b_ptr_sync == 2**ASIZE - 2) begin
          b_aempty_reg <= 1'b1;
        end
      end
    end
  end

  assign a_rdata = a_rdata_reg;
  assign a_full = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;
  assign b_rdata = b_rdata_reg;
  assign b_full = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

endmodule

module sync_gray #(
  parameter WIDTH = 1
) (
  input  wire clk,
  input  wire rst_n,
  input  wire [WIDTH-1:0] din,
  output wire [WIDTH-1:0] dout
);

  reg [WIDTH-1:0] sync_reg [1:0];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_reg[0] <= {WIDTH{1'b0}};
      sync_reg[1] <= {WIDTH{1'b0}};
    end else begin
      sync_reg[0] <= din;
      sync_reg[1] <= sync_reg[0];
    end
  end

  assign dout = sync_reg[1];

endmodule

function [ASIZE-1:0] gray_encode;
  input [ASIZE-1:0] bin;
  reg [ASIZE-1:0] gray;
  integer i;
  begin
    gray = bin;
    for (i = ASIZE - 1; i > 0; i = i - 1) begin
      gray[i - 1] = bin[i] ^ bin[i - 1];
    end
    gray_encode = gray;
  end
endfunction
