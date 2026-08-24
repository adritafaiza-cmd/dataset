module async_fifo_reset_sync #(
  parameter STAGES = 2
)(
  input  wire clk,
  input  wire arst_n,
  output wire srst_n
);

  (* async_reg = "true" *) reg [STAGES-1:0] sync_ff;

  always @(posedge clk or negedge arst_n) begin
    if (!arst_n)
      sync_ff <= {STAGES{1'b0}};
    else
      sync_ff <= {sync_ff[STAGES-2:0], 1'b1};
  end

  assign srst_n = sync_ff[STAGES-1];

endmodule


module async_fifo_gray_sync #(
  parameter WIDTH = 5
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [WIDTH-1:0] async_gray,
  output wire [WIDTH-1:0] sync_gray
);

  (* async_reg = "true" *) reg [WIDTH-1:0] sync_ff1;
  (* async_reg = "true" *) reg [WIDTH-1:0] sync_ff2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff1 <= {WIDTH{1'b0}};
      sync_ff2 <= {WIDTH{1'b0}};
    end else begin
      sync_ff1 <= async_gray;
      sync_ff2 <= sync_ff1;
    end
  end

  assign sync_gray = sync_ff2;

endmodule


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

  localparam integer DEPTH = (1 << ASIZE);
  localparam integer PSIZE = ASIZE + 1;

  localparam [ASIZE:0] FULL_MASK =
      {2'b11, {(ASIZE-1){1'b0}}};

  localparam [ASIZE:0] ALMOST_FULL_LEVEL = DEPTH - 1;
  localparam [ASIZE:0] ALMOST_EMPTY_LEVEL = 1;

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  wire wrst_sync_n;
  wire rrst_sync_n;

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] rgray_wsync;
  wire [ASIZE:0] wgray_rsync;

  reg wfull_reg;
  reg awfull_reg;
  reg rempty_reg;
  reg arempty_reg;

  reg [DSIZE-1:0] rdata_reg;

  wire waccept;
  wire raccept;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] rbin_wsync;
  wire [ASIZE:0] wbin_rsync;

  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] ravail_next;

  wire wfull_next;
  wire awfull_next;
  wire rempty_next;
  wire arempty_next;

  function [ASIZE:0] gray_to_binary;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray_to_binary[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i - 1)
        gray_to_binary[i] = gray_to_binary[i+1] ^ gray[i];
    end
  endfunction

  async_fifo_reset_sync #(
    .STAGES(2)
  ) u_wreset_sync (
    .clk    (wclk),
    .arst_n (wrst_n),
    .srst_n (wrst_sync_n)
  );

  async_fifo_reset_sync #(
    .STAGES(2)
  ) u_rreset_sync (
    .clk    (rclk),
    .arst_n (rrst_n),
    .srst_n (rrst_sync_n)
  );

  async_fifo_gray_sync #(
    .WIDTH(PSIZE)
  ) u_rgray_to_wclk (
    .clk        (wclk),
    .rst_n      (wrst_sync_n),
    .async_gray (rgray),
    .sync_gray  (rgray_wsync)
  );

  async_fifo_gray_sync #(
    .WIDTH(PSIZE)
  ) u_wgray_to_rclk (
    .clk        (rclk),
    .rst_n      (rrst_sync_n),
    .async_gray (wgray),
    .sync_gray  (wgray_rsync)
  );

  assign waccept = winc && !wfull_reg;
  assign raccept = rinc && !rempty_reg;

  assign wbin_next  = wbin + waccept;
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

  assign rbin_next  = rbin + raccept;
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign rbin_wsync = gray_to_binary(rgray_wsync);
  assign wbin_rsync = gray_to_binary(wgray_rsync);

  assign wused_next = wbin_next - rbin_wsync;
  assign ravail_next = wbin_rsync - rbin_next;

  assign wfull_next =
      (wgray_next == (rgray_wsync ^ FULL_MASK));

  assign rempty_next =
      (rgray_next == wgray_rsync);

  assign awfull_next =
      (wused_next >= ALMOST_FULL_LEVEL);

  assign arempty_next =
      (ravail_next <= ALMOST_EMPTY_LEVEL);

  always @(posedge wclk or negedge wrst_sync_n) begin
    if (!wrst_sync_n) begin
      wbin        <= {PSIZE{1'b0}};
      wgray       <= {PSIZE{1'b0}};
      wfull_reg   <= 1'b0;
      awfull_reg  <= 1'b0;
    end else begin
      wbin        <= wbin_next;
      wgray       <= wgray_next;
      wfull_reg   <= wfull_next;
      awfull_reg  <= awfull_next;
    end
  end

  always @(posedge wclk) begin
    if (waccept)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  always @(posedge rclk or negedge rrst_sync_n) begin
    if (!rrst_sync_n) begin
      rbin        <= {PSIZE{1'b0}};
      rgray       <= {PSIZE{1'b0}};
      rempty_reg  <= 1'b1;
      arempty_reg <= 1'b1;
    end else begin
      rbin        <= rbin_next;
      rgray       <= rgray_next;
      rempty_reg  <= rempty_next;
      arempty_reg <= arempty_next;
    end
  end

  generate
    if (FALLTHROUGH == "TRUE") begin : g_fallthrough
      always @(posedge rclk or negedge rrst_sync_n) begin
        if (!rrst_sync_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (!rempty_next)
          rdata_reg <= mem[rbin_next[ASIZE-1:0]];
      end
    end else begin : g_registered_read
      always @(posedge rclk or negedge rrst_sync_n) begin
        if (!rrst_sync_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (raccept)
          rdata_reg <= mem[rbin[ASIZE-1:0]];
      end
    end
  endgenerate

  assign wfull  = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;
  assign rdata  = rdata_reg;

endmodule
