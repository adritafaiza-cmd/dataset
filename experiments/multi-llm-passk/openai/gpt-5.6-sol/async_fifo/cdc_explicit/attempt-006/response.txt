module async_fifo #(
  parameter DSIZE = 8,
  parameter ASIZE = 4,
  parameter FALLTHROUGH = "TRUE"
)(
  input  wire             wclk,
  input  wire             wrst_n,
  input  wire             winc,
  input  wire [DSIZE-1:0] wdata,
  output wire             wfull,
  output wire             awfull,

  input  wire             rclk,
  input  wire             rrst_n,
  input  wire             rinc,
  output wire [DSIZE-1:0] rdata,
  output wire             rempty,
  output wire             arempty
);

  localparam [ASIZE:0] FIFO_DEPTH =
      {1'b1, {ASIZE{1'b0}}};
  localparam [ASIZE:0] ALMOST_FULL_LEVEL =
      FIFO_DEPTH - 1'b1;
  localparam [ASIZE:0] ONE =
      {{ASIZE{1'b0}}, 1'b1};
  localparam [ASIZE:0] FULL_MASK =
      FIFO_DEPTH | (FIFO_DEPTH >> 1);

  wire wreset_n;
  wire rreset_n;

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  (* async_reg = "true" *) reg [ASIZE:0] wq1_rgray;
  (* async_reg = "true" *) reg [ASIZE:0] wq2_rgray;
  (* async_reg = "true" *) reg [ASIZE:0] rq1_wgray;
  (* async_reg = "true" *) reg [ASIZE:0] rq2_wgray;

  reg wfull_reg;
  reg awfull_reg;
  reg rempty_reg;
  reg arempty_reg;

  wire waccept;
  wire raccept;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] wsync_rbin;
  wire [ASIZE:0] rsync_wbin;
  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] ravail_next;

  wire wfull_next;
  wire awfull_next;
  wire rempty_next;
  wire arempty_next;

  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray_to_bin[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i-1)
        gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
    end
  endfunction

  async_fifo_reset_sync u_wreset_sync (
    .clk     (wclk),
    .arst_n  (wrst_n),
    .srst_n  (wreset_n)
  );

  async_fifo_reset_sync u_rreset_sync (
    .clk     (rclk),
    .arst_n  (rrst_n),
    .srst_n  (rreset_n)
  );

  assign wfull  = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;

  assign waccept = winc && !wfull_reg;
  assign raccept = rinc && !rempty_reg;

  assign wbin_next  = wbin + waccept;
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

  assign rbin_next  = rbin + raccept;
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign wsync_rbin = gray_to_bin(wq2_rgray);
  assign rsync_wbin = gray_to_bin(rq2_wgray);

  assign wused_next  = wbin_next - wsync_rbin;
  assign ravail_next = rsync_wbin - rbin_next;

  assign wfull_next =
      (wgray_next == (wq2_rgray ^ FULL_MASK));
  assign awfull_next =
      (wused_next >= ALMOST_FULL_LEVEL);

  assign rempty_next =
      (rgray_next == rq2_wgray);
  assign arempty_next =
      (ravail_next <= ONE);

  always @(posedge wclk or negedge wreset_n) begin
    if (!wreset_n) begin
      wbin       <= {ASIZE+1{1'b0}};
      wgray      <= {ASIZE+1{1'b0}};
      wfull_reg  <= 1'b0;
      awfull_reg <= 1'b0;
    end else begin
      wbin       <= wbin_next;
      wgray      <= wgray_next;
      wfull_reg  <= wfull_next;
      awfull_reg <= awfull_next;
    end
  end

  always @(posedge rclk or negedge rreset_n) begin
    if (!rreset_n) begin
      rbin        <= {ASIZE+1{1'b0}};
      rgray       <= {ASIZE+1{1'b0}};
      rempty_reg  <= 1'b1;
      arempty_reg <= 1'b1;
    end else begin
      rbin        <= rbin_next;
      rgray       <= rgray_next;
      rempty_reg  <= rempty_next;
      arempty_reg <= arempty_next;
    end
  end

  always @(posedge wclk or negedge wreset_n) begin
    if (!wreset_n) begin
      wq1_rgray <= {ASIZE+1{1'b0}};
      wq2_rgray <= {ASIZE+1{1'b0}};
    end else begin
      wq1_rgray <= rgray;
      wq2_rgray <= wq1_rgray;
    end
  end

  always @(posedge rclk or negedge rreset_n) begin
    if (!rreset_n) begin
      rq1_wgray <= {ASIZE+1{1'b0}};
      rq2_wgray <= {ASIZE+1{1'b0}};
    end else begin
      rq1_wgray <= wgray;
      rq2_wgray <= rq1_wgray;
    end
  end

  async_fifo_memory #(
    .DSIZE       (DSIZE),
    .ASIZE       (ASIZE),
    .FALLTHROUGH (FALLTHROUGH)
  ) u_memory (
    .wclk     (wclk),
    .wreset_n (wreset_n),
    .w_en     (waccept),
    .waddr    (wbin[ASIZE-1:0]),
    .wdata    (wdata),
    .rclk     (rclk),
    .rreset_n (rreset_n),
    .r_en     (raccept),
    .raddr    (rbin[ASIZE-1:0]),
    .rdata    (rdata)
  );

endmodule


module async_fifo_reset_sync (
  input  wire clk,
  input  wire arst_n,
  output wire srst_n
);

  (* async_reg = "true" *) reg sync_ff1;
  (* async_reg = "true" *) reg sync_ff2;

  always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      sync_ff1 <= 1'b0;
      sync_ff2 <= 1'b0;
    end else begin
      sync_ff1 <= 1'b1;
      sync_ff2 <= sync_ff1;
    end
  end

  assign srst_n = sync_ff2;

endmodule


module async_fifo_memory #(
  parameter DSIZE = 8,
  parameter ASIZE = 4,
  parameter FALLTHROUGH = "TRUE"
)(
  input  wire             wclk,
  input  wire             wreset_n,
  input  wire             w_en,
  input  wire [ASIZE-1:0] waddr,
  input  wire [DSIZE-1:0] wdata,

  input  wire             rclk,
  input  wire             rreset_n,
  input  wire             r_en,
  input  wire [ASIZE-1:0] raddr,
  output wire [DSIZE-1:0] rdata
);

  localparam DEPTH = (1 << ASIZE);

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  always @(posedge wclk) begin
    if (wreset_n && w_en)
      mem[waddr] <= wdata;
  end

  generate
    if (FALLTHROUGH == "TRUE") begin : g_fallthrough
      assign rdata = mem[raddr];
    end else begin : g_registered_read
      reg [DSIZE-1:0] rdata_reg;

      always @(posedge rclk or negedge rreset_n) begin
        if (!rreset_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (r_en)
          rdata_reg <= mem[raddr];
      end

      assign rdata = rdata_reg;
    end
  endgenerate

endmodule
