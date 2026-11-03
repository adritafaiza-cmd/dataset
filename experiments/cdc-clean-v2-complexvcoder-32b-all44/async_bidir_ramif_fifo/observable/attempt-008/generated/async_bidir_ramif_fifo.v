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

  // Internal signals
  reg [1:0] rst_n_synced_a2b;
  reg [1:0] rst_n_synced_b2a;
  reg       winc_synced_a2b;
  reg       winc_synced_b2a;
  reg       rinc_synced_a2b;
  reg       rinc_synced_b2a;
  reg       dir_synced_a2b;
  reg       dir_synced_b2a;
  reg [ASIZE-1:0] a_addr;
  reg [ASIZE-1:0] b_addr;

  // Cross-domain synchronization for a side signals to b side
  cds cds_a2b (
    .rst_in    (a_rst_n),
    .clk_in    (a_clk),
    .data_in   ({a_dir, a_rinc, a_winc}),
    .clk_out   (b_clk),
    .rst_out   (rst_n_synced_a2b[1]),
    .data_out  ({dir_synced_a2b, rinc_synced_a2b, winc_synced_a2b})
  );

  // Cross-domain synchronization for b side signals to a side
  cds cds_b2a (
    .rst_in    (b_rst_n),
    .clk_in    (b_clk),
    .data_in   ({b_dir, b_rinc, b_winc}),
    .clk_out   (a_clk),
    .rst_out   (rst_n_synced_b2a[1]),
    .data_out  ({dir_synced_b2a, rinc_synced_b2a, winc_synced_b2a})
  );

  // Control logic for FIFO on side A
  fifo_control fifo_ctrl_a (
    .clk       (a_clk),
    .rst_n     (a_rst_n),
    .winc      (winc_synced_b2a),
    .winc_local(a_winc),
    .rinc      (rinc_synced_a2b),
    .rinc_local(a_rinc),
    .dir       (dir_synced_a2b),
    .addr      (a_addr),
    .full      (a_full),
    .afull     (a_afull),
    .empty     (a_empty),
    .aempty    (a_aempty)
  );

  // Control logic for FIFO on side B
  fifo_control fifo_ctrl_b (
    .clk       (b_clk),
    .rst_n     (b_rst_n),
    .winc      (winc_synced_a2b),
    .winc_local(b_winc),
    .rinc      (rinc_synced_b2a),
    .rinc_local(b_rinc),
    .dir       (dir_synced_b2a),
    .addr      (b_addr),
    .full      (b_full),
    .afull     (b_afull),
    .empty     (b_empty),
    .aempty    (b_aempty)
  );

  // Connections to RAM interface
  assign o_ram_a_clk     = a_clk;
  assign o_ram_a_wdata   = a_wdata;
  assign a_rdata         = i_ram_a_rdata;
  assign o_ram_a_addr    = a_addr;
  assign o_ram_a_rinc    = a_rinc;
  assign o_ram_a_winc    = a_winc;

  assign o_ram_b_clk     = b_clk;
  assign o_ram_b_wdata   = b_wdata;
  assign b_rdata         = i_ram_b_rdata;
  assign o_ram_b_addr    = b_addr;
  assign o_ram_b_rinc    = b_rinc;
  assign o_ram_b_winc    = b_winc;

endmodule

// Cross-domain synchronizer module
module cds (
    input wire clk_in,
    input wire clk_out,
    input wire rst_in,
    input wire [2:0] data_in,
    output reg rst_out,
    output reg [2:0] data_out
);

always @(posedge clk_out or negedge rst_in) begin
  if (!rst_in) begin
    rst_out <= 1'b0;
    data_out <= 3'b000;
  end else begin
    rst_out <= rst_in;
    data_out <= data_in;
  end
end

endmodule

// FIFO control logic module
module fifo_control (
    input wire clk,
    input wire rst_n,
    input wire winc,
    input wire winc_local,
    input wire rinc,
    input wire rinc_local,
    input wire dir,
    output reg [ASIZE-1:0] addr,
    output wire full,
    output wire afull,
    output wire empty,
    output wire aempty
);

  reg [ASIZE:0] wr_ptr;
  reg [ASIZE:0] rd_ptr;
  reg [ASIZE:0] wr_ptr_gray;
  reg [ASIZE:0] rd_ptr_gray;
  reg [ASIZE:0] wr_ptr_gray_sync;
  reg [ASIZE:0] rd_ptr_gray_sync;

  // Gray code conversion
  always @(*) begin
    wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);
  end

  // Synchronize gray pointers across clock domains
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_sync <= {ASIZE+1{1'b0}};
      rd_ptr_gray_sync <= {ASIZE+1{1'b0}};
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // Binary conversion
  wire [ASIZE:0] wr_ptr_sync;
  wire [ASIZE:0] rd_ptr_sync;
  assign wr_ptr_sync = wr_ptr_gray_sync ^ (wr_ptr_gray_sync >> 1);
  assign rd_ptr_sync = rd_ptr_gray_sync ^ (rd_ptr_gray_sync >> 1);

  // Address calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= {ASIZE+1{1'b0}};
      rd_ptr <= {ASIZE+1{1'b0}};
    end else begin
      if (winc && !full) begin
        wr_ptr <= wr_ptr + 1;
      end
      if (rinc && !empty) begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

  // Assign address output
  always @(*) begin
    if (dir)
      addr = wr_ptr_sync[ASIZE-1:0];
    else
      addr = rd_ptr_sync[ASIZE-1:0];
  end

  // Full and almost full flags
  assign full  = (wr_ptr_gray_sync[ASIZE-1:0] == (rd_ptr_gray + 1)[ASIZE-1:0]) && (wr_ptr_gray_sync[ASIZE] != rd_ptr_gray[ASIZE]);
  assign afull = (wr_ptr_gray_sync[ASIZE-1:0] == (rd_ptr_gray + 2)[ASIZE-1:0]) && (wr_ptr_gray_sync[ASIZE] != rd_ptr_gray[ASIZE]);

  // Empty and almost empty flags
  assign empty  = (wr_ptr_gray_sync == rd_ptr_gray_sync);
  assign aempty = (wr_ptr_gray_sync[ASIZE-1:0] == rd_ptr_gray_sync[ASIZE-1:0]) && (wr_ptr_gray_sync[ASIZE] != rd_ptr_gray_sync[ASIZE]);

endmodule
