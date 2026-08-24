module async_fifo_reset_sync (
  input  wire clk,
  input  wire arst_n,
  output wire srst_n
);

  (* ASYNC_REG = "TRUE" *) reg [1:0] sync_ff;

  always @(posedge clk or negedge arst_n) begin
    if (!arst_n)
      sync_ff <= 2'b00;
    else begin
      sync_ff[0] <= 1'b1;
      sync_ff[1] <= sync_ff[0];
    end
  end

  assign srst_n = sync_ff[1];

endmodule


module async_fifo_gray_sync #(
  parameter WIDTH = 5
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

  localparam DEPTH = (1 << ASIZE);
  localparam [ASIZE:0] DEPTH_COUNT =
      {1'b1, {ASIZE{1'b0}}};
  localparam [ASIZE:0] ALMOST_FULL_COUNT =
      DEPTH_COUNT - {{ASIZE{1'b0}}, 1'b1};
  localparam [ASIZE:0] FULL_GRAY_MASK =
      {2'b11, {(ASIZE-1){1'b0}}};

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  wire wrst_sync_n;
  wire rrst_sync_n;

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] wq2_rgray;
  wire [ASIZE:0] rq2_wgray;

  wire [ASIZE:0] wq2_rbin;
  wire [ASIZE:0] rq2_wbin;

  wire [ASIZE:0] wbinnext;
  wire [ASIZE:0] wgraynext;
  wire [ASIZE:0] rbinnext;
  wire [ASIZE:0] rgraynext;

  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] rused_next;

  wire wpush;
  wire rpop;

  wire wfull_next;
  wire rempty_next;
  wire awfull_next;
  wire arempty_next;

  reg wfull_reg;
  reg rempty_reg;
  reg awfull_reg;
  reg arempty_reg;
  reg [DSIZE-1:0] rdata_reg;

  function [ASIZE:0] bin_to_gray;
    input [ASIZE:0] bin;
    begin
      bin_to_gray = (bin >> 1) ^ bin;
    end
  endfunction

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
    .clk    (wclk),
    .arst_n (wrst_n),
    .srst_n (wrst_sync_n)
  );

  async_fifo_reset_sync u_rreset_sync (
    .clk    (rclk),
    .arst_n (rrst_n),
    .srst_n (rrst_sync_n)
  );

  async_fifo_gray_sync #(
    .WIDTH (ASIZE+1)
  ) u_rgray_to_wclk (
    .clk        (wclk),
    .rst_n      (wrst_sync_n),
    .async_gray (rgray),
    .sync_gray  (wq2_rgray)
  );

  async_fifo_gray_sync #(
    .WIDTH (ASIZE+1)
  ) u_wgray_to_rclk (
    .clk        (rclk),
    .rst_n      (rrst_sync_n),
    .async_gray (wgray),
    .sync_gray  (rq2_wgray)
  );

  assign wfull  = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;
  assign rdata = rdata_reg;

  assign wpush = wrst_sync_n && winc && !wfull_reg;
  assign rpop  = rrst_sync_n && rinc && !rempty_reg;

  assign wbinnext  = wbin + {{ASIZE{1'b0}}, wpush};
  assign wgraynext = bin_to_gray(wbinnext);

  assign rbinnext  = rbin + {{ASIZE{1'b0}}, rpop};
  assign rgraynext = bin_to_gray(rbinnext);

  assign wq2_rbin = gray_to_bin(wq2_rgray);
  assign rq2_wbin = gray_to_bin(rq2_wgray);

  assign wfull_next =
      (wgraynext == (wq2_rgray ^ FULL_GRAY_MASK));

  assign rempty_next =
      (rgraynext == rq2_wgray);

  assign wused_next = wbinnext - wq2_rbin;
  assign rused_next = rq2_wbin - rbinnext;

  assign awfull_next =
      (wused_next >= ALMOST_FULL_COUNT);

  assign arempty_next =
      (rused_next <= {{ASIZE{1'b0}}, 1'b1});

  always @(posedge wclk or negedge wrst_sync_n) begin
    if (!wrst_sync_n) begin
      wbin       <= {(ASIZE+1){1'b0}};
      wgray      <= {(ASIZE+1){1'b0}};
      wfull_reg  <= 1'b0;
      awfull_reg <= 1'b0;
    end else begin
      wbin       <= wbinnext;
      wgray      <= wgraynext;
      wfull_reg  <= wfull_next;
      awfull_reg <= awfull_next;
    end
  end

  always @(posedge wclk) begin
    if (wpush)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  always @(posedge rclk or negedge rrst_sync_n) begin
    if (!rrst_sync_n) begin
      rbin        <= {(ASIZE+1){1'b0}};
      rgray       <= {(ASIZE+1){1'b0}};
      rempty_reg  <= 1'b1;
      arempty_reg <= 1'b1;
    end else begin
      rbin        <= rbinnext;
      rgray       <= rgraynext;
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
          rdata_reg <= mem[rbinnext[ASIZE-1:0]];
      end
    end else begin : g_registered_read
      always @(posedge rclk or negedge rrst_sync_n) begin
        if (!rrst_sync_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (rpop)
          rdata_reg <= mem[rbin[ASIZE-1:0]];
      end
    end
  endgenerate

endmodule
