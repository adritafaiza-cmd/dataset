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

  localparam [PSIZE-1:0] DEPTH_VALUE =
      {1'b1, {ASIZE{1'b0}}};

  localparam [PSIZE-1:0] ALMOST_FULL_LEVEL =
      {1'b0, {ASIZE{1'b1}}};

  wire wrst_sync_n;
  wire rrst_sync_n;

  reg  [PSIZE-1:0] wbin;
  reg  [PSIZE-1:0] wgray;
  reg  [PSIZE-1:0] rbin;
  reg  [PSIZE-1:0] rgray;

  wire [PSIZE-1:0] wgray_sync;
  wire [PSIZE-1:0] rgray_sync;

  wire [PSIZE-1:0] wbin_sync;
  wire [PSIZE-1:0] rbin_sync;

  wire [PSIZE-1:0] wbin_next;
  wire [PSIZE-1:0] wgray_next;
  wire [PSIZE-1:0] rbin_next;
  wire [PSIZE-1:0] rgray_next;

  wire [PSIZE-1:0] wused_next;
  wire [PSIZE-1:0] rused_next;

  reg wfull_reg;
  reg awfull_reg;
  reg rempty_reg;
  reg arempty_reg;

  wire wpush;
  wire rpop;

  wire wfull_next;
  wire awfull_next;
  wire rempty_next;
  wire arempty_next;

  function [PSIZE-1:0] gray_to_bin;
    input [PSIZE-1:0] gray;
    integer i;
    begin
      gray_to_bin[PSIZE-1] = gray[PSIZE-1];
      for (i = PSIZE-2; i >= 0; i = i - 1)
        gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
    end
  endfunction

  async_fifo_reset_sync u_wreset_sync (
    .clk     (wclk),
    .arst_n  (wrst_n),
    .srst_n  (wrst_sync_n)
  );

  async_fifo_reset_sync u_rreset_sync (
    .clk     (rclk),
    .arst_n  (rrst_n),
    .srst_n  (rrst_sync_n)
  );

  async_fifo_gray_sync #(
    .WIDTH(PSIZE)
  ) u_sync_rgray_to_wclk (
    .clk    (wclk),
    .rst_n  (wrst_sync_n),
    .din    (rgray),
    .dout   (rgray_sync)
  );

  async_fifo_gray_sync #(
    .WIDTH(PSIZE)
  ) u_sync_wgray_to_rclk (
    .clk    (rclk),
    .rst_n  (rrst_sync_n),
    .din    (wgray),
    .dout   (wgray_sync)
  );

  assign rbin_sync = gray_to_bin(rgray_sync);
  assign wbin_sync = gray_to_bin(wgray_sync);

  assign wpush = winc && !wfull_reg && wrst_sync_n;
  assign rpop  = rinc && !rempty_reg && rrst_sync_n;

  assign wbin_next  = wbin + {{(PSIZE-1){1'b0}}, wpush};
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

  assign rbin_next  = rbin + {{(PSIZE-1){1'b0}}, rpop};
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign wused_next = wbin_next - rbin_sync;
  assign rused_next = wbin_sync - rbin_next;

  assign wfull_next =
      (wbin_next == (rbin_sync ^ DEPTH_VALUE));

  assign awfull_next =
      (wused_next >= ALMOST_FULL_LEVEL);

  assign rempty_next =
      (rgray_next == wgray_sync);

  assign arempty_next =
      (rused_next <= {{(PSIZE-1){1'b0}}, 1'b1});

  always @(posedge wclk or negedge wrst_sync_n) begin
    if (!wrst_sync_n) begin
      wbin       <= {PSIZE{1'b0}};
      wgray      <= {PSIZE{1'b0}};
      wfull_reg  <= 1'b0;
      awfull_reg <= 1'b0;
    end else begin
      wbin       <= wbin_next;
      wgray      <= wgray_next;
      wfull_reg  <= wfull_next;
      awfull_reg <= awfull_next;
    end
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

  async_fifo_memory #(
    .DSIZE       (DSIZE),
    .ASIZE       (ASIZE),
    .FALLTHROUGH (FALLTHROUGH)
  ) u_memory (
    .wclk     (wclk),
    .wen      (wpush),
    .waddr    (wbin[ASIZE-1:0]),
    .wdata    (wdata),
    .rclk     (rclk),
    .rrst_n   (rrst_sync_n),
    .ren      (rpop),
    .raddr    (rbin[ASIZE-1:0]),
    .rdata    (rdata)
  );

  assign wfull  = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;

endmodule


module async_fifo_reset_sync (
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


module async_fifo_gray_sync #(
  parameter WIDTH = 5
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [WIDTH-1:0] din,
  output wire [WIDTH-1:0] dout
);

  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff1;
  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff1 <= {WIDTH{1'b0}};
      sync_ff2 <= {WIDTH{1'b0}};
    end else begin
      sync_ff1 <= din;
      sync_ff2 <= sync_ff1;
    end
  end

  assign dout = sync_ff2;

endmodule


module async_fifo_memory #(
  parameter DSIZE = 8,
  parameter ASIZE = 4,
  parameter FALLTHROUGH = "TRUE"
)(
  input  wire             wclk,
  input  wire             wen,
  input  wire [ASIZE-1:0] waddr,
  input  wire [DSIZE-1:0] wdata,

  input  wire             rclk,
  input  wire             rrst_n,
  input  wire             ren,
  input  wire [ASIZE-1:0] raddr,
  output wire [DSIZE-1:0] rdata
);

  localparam DEPTH = (1 << ASIZE);

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  always @(posedge wclk) begin
    if (wen)
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
        else if (ren)
          rdata_reg <= mem[raddr];
      end

      assign rdata = rdata_reg;
    end
  endgenerate

endmodule
