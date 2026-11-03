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

  // Internal signals
  wire [DSIZE-1:0] a_fifo_rdata;
  wire a_fifo_full;
  wire a_fifo_afull;
  wire a_fifo_empty;
  wire a_fifo_aempty;
  wire [DSIZE-1:0] b_fifo_rdata;
  wire b_fifo_full;
  wire b_fifo_afull;
  wire b_fifo_empty;
  wire b_fifo_aempty;

  // FIFO cores
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) a_fifo (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_fifo_rdata),
    .full(a_fifo_full),
    .afull(a_fifo_afull),
    .empty(a_fifo_empty),
    .aempty(a_fifo_aempty)
  );

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) b_fifo (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_fifo_rdata),
    .full(b_fifo_full),
    .afull(b_fifo_afull),
    .empty(b_fifo_empty),
    .aempty(b_fifo_aempty)
  );

  // Direction muxes
  dir_mux #(.DSIZE(DSIZE)) dir_mux_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .dir(a_dir),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

  dir_mux #(.DSIZE(DSIZE)) dir_mux_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .dir(b_dir),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

endmodule

module fifo_core
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  // FIFO core implementation
  reg [ASIZE-1:0] wr_ptr, rd_ptr;
  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [DSIZE-1:0] temp_data;
  reg [1:0] state;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      state <= 0;
    end else begin
      case (state)
        0: begin // Idle
          if (winc && !full) begin
            mem[wr_ptr] <= wdata;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == (1<<ASIZE)-1) wr_ptr <= 0;
            if (wr_ptr == rd_ptr) state <= 1; // Full
          end else if (rinc && !empty) begin
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == (1<<ASIZE)-1) rd_ptr <= 0;
            if (rd_ptr == wr_ptr) state <= 2; // Empty
          end
        end
        1: begin // Full
          if (rinc) begin
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == (1<<ASIZE)-1) rd_ptr <= 0;
            if (rd_ptr == wr_ptr) state <= 2; // Empty
          end
        end
        2: begin // Empty
          if (winc) begin
            mem[wr_ptr] <= wdata;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == (1<<ASIZE)-1) wr_ptr <= 0;
            if (wr_ptr == rd_ptr) state <= 1; // Full
          end
        end
      endcase
    end
  end

  assign rdata = mem[rd_ptr];
  assign full = (wr_ptr == rd_ptr) && !empty;
  assign afull = (wr_ptr == (rd_ptr + 1) && !empty);
  assign empty = (wr_ptr == rd_ptr) && !winc;
  assign aempty = (wr_ptr == (rd_ptr + 1) && !winc);

endmodule

module dir_mux
  #(
    parameter DSIZE         = 8
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              dir,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  // Direction mux implementation
  wire [DSIZE-1:0] local_rdata;
  wire local_full, local_afull, local_empty, local_aempty;

  assign {local_rdata, local_full, local_afull, local_empty, local_aempty} = dir ? {wdata, winc, 1'b0, 1'b0, 1'b0} : {local_rdata, local_full, local_afull, local_empty, local_aempty};

  assign rdata = local_rdata;
  assign full = local_full;
  assign afull = local_afull;
  assign empty = local_empty;
  assign aempty = local_aempty;

endmodule
