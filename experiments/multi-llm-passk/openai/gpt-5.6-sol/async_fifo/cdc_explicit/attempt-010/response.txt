module async_reset_sync (
  input  wire clk,
  input  wire arst_n,
  output wire srst_n
);

  (* ASYNC_REG = "TRUE" *) reg sync_ff1;
  (* ASYNC_REG = "TRUE" *) reg sync_ff2;

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


module async_gray_sync #(
  parameter WIDTH = 2
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [WIDTH-1:0] async_gray,
  output wire [WIDTH-1:0] sync_gray
);

  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff1;
  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff2;

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


module async_fifo_mem #(
  parameter DSIZE       = 8,
  parameter ASIZE       = 4,
  parameter FALLTHROUGH = "TRUE"
)(
  input  wire                 wclk,
  input  wire                 wren,
  input  wire [ASIZE-1:0]     waddr,
  input  wire [DSIZE-1:0]     wdata,

  input  wire                 rclk,
  input  wire                 rrst_n,
  input  wire                 rden,
  input  wire [ASIZE-1:0]     raddr,
  output wire [DSIZE-1:0]     rdata
);

  localparam DEPTH = (1 << ASIZE);

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  always @(posedge wclk) begin
    if (wren)
      mem[waddr] <= wdata;
  end

  generate
    if (FALLTHROUGH == "TRUE") begin : g_fallthrough
      assign rdata = mem[raddr];
    end else begin : g_registered_read
      reg [DSIZE-1:0] rdata_reg;

      always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (rden)
          rdata_reg <= mem[raddr];
      end

      assign rdata = rdata_reg;
    end
  endgenerate

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

  localparam PSIZE = ASIZE + 1;

  localparam [ASIZE:0] FULL_XOR_MASK =
    {2'b11, {(ASIZE-1){1'b0}}};

  localparam [ASIZE:0] ALMOST_FULL_LEVEL =
    {1'b0, {ASIZE{1'b1}}};

  localparam [ASIZE:0] ALMOST_EMPTY_LEVEL =
    {{ASIZE{1'b0}}, 1'b1};

  wire wrst_sync_n;
  wire rrst_sync_n;

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] rgray_wsync;
  wire [ASIZE:0] wgray_rsync;

  wire [ASIZE:0] rbin_wsync;
  wire [ASIZE:0] wbin_rsync;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] rused_next;

  wire waccept;
  wire raccept;

  wire wfull_next;
  wire rempty_next;
  wire awfull_next;
  wire arempty_next;

  reg wfull_reg;
  reg rempty_reg;
  reg awfull_reg;
  reg arempty_reg;

  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray_to_bin[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i-1)
        gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
    end
  endfunction

  async_reset_sync u_wreset_sync (
    .clk    (wclk),
    .arst_n (wrst_n),
    .srst_n (wrst_sync_n)
  );

  async_reset_sync u_rreset_sync (
    .clk    (rclk),
    .arst_n (rrst_n),
    .srst_n (rrst_sync_n)
  );

  async_gray_sync #(
    .WIDTH (PSIZE)
  ) u_rgray_to_wclk (
    .clk        (wclk),
    .rst_n      (wrst_sync_n),
    .async_gray (rgray),
    .sync_gray  (rgray_wsync)
  );

  async_gray_sync #(
    .WIDTH (PSIZE)
  ) u_wgray_to_rclk (
    .clk        (rclk),
    .rst_n      (rrst_sync_n),
    .async_gray (wgray),
    .sync_gray  (wgray_rsync)
  );

  assign waccept = winc && !wfull_reg;
  assign raccept = rinc && !rempty_reg;

  assign wbin_next  = wbin + {{ASIZE{1'b0}}, waccept};
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

  assign rbin_next  = rbin + {{ASIZE{1'b0}}, raccept};
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign wfull_next =
    (wgray_next == (rgray_wsync ^ FULL_XOR_MASK));

  assign rempty_next =
    (rgray_next == wgray_rsync);

  assign rbin_wsync = gray_to_bin(rgray_wsync);
  assign wbin_rsync = gray_to_bin(wgray_rsync);

  assign wused_next = wbin_next - rbin_wsync;
  assign rused_next = wbin_rsync - rbin_next;

  assign awfull_next =
    (wused_next >= ALMOST_FULL_LEVEL);

  assign arempty_next =
    (rused_next <= ALMOST_EMPTY_LEVEL);

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

  always @(posedge rclk or negedge rrst_sync_n) begin
    if (!rrst_sync_n) begin
      rbin         <= {PSIZE{1'b0}};
      rgray        <= {PSIZE{1'b0}};
      rempty_reg   <= 1'b1;
      arempty_reg  <= 1'b1;
    end else begin
      rbin         <= rbin_next;
      rgray        <= rgray_next;
      rempty_reg   <= rempty_next;
      arempty_reg  <= arempty_next;
    end
  end

  async_fifo_mem #(
    .DSIZE       (DSIZE),
    .ASIZE       (ASIZE),
    .FALLTHROUGH (FALLTHROUGH)
  ) u_fifo_mem (
    .wclk   (wclk),
    .wren   (waccept),
    .waddr  (wbin[ASIZE-1:0]),
    .wdata  (wdata),
    .rclk   (rclk),
    .rrst_n (rrst_sync_n),
    .rden   (raccept),
    .raddr  (rbin[ASIZE-1:0]),
    .rdata  (rdata)
  );

  assign wfull   = wfull_reg;
  assign awfull  = awfull_reg;
  assign rempty  = rempty_reg;
  assign arempty = arempty_reg;

endmodule
