module async_reset_sync (
  input  wire clk,
  input  wire arst_n,
  output wire srst_n
);

  (* ASYNC_REG = "TRUE" *) reg [1:0] sync_ff;

  always @(posedge clk or negedge arst_n) begin
    if (!arst_n)
      sync_ff <= 2'b00;
    else
      sync_ff <= {sync_ff[0], 1'b1};
  end

  assign srst_n = sync_ff[1];

endmodule


module async_gray_sync #(
  parameter WIDTH = 2
)(
  input  wire                 clk,
  input  wire                 rst_n,
  input  wire [WIDTH-1:0]     d,
  output wire [WIDTH-1:0]     q
);

  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff1;
  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff1 <= {WIDTH{1'b0}};
      sync_ff2 <= {WIDTH{1'b0}};
    end else begin
      sync_ff1 <= d;
      sync_ff2 <= sync_ff1;
    end
  end

  assign q = sync_ff2;

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
  localparam PTR_WIDTH = ASIZE + 1;
  localparam [PTR_WIDTH-1:0] PTR_ONE =
      {{(PTR_WIDTH-1){1'b0}}, 1'b1};
  localparam [PTR_WIDTH-1:0] FULL_XOR_MASK =
      {2'b11, {(ASIZE-1){1'b0}}};

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  wire wrst_sync_n;
  wire rrst_sync_n;

  reg [PTR_WIDTH-1:0] wbin;
  reg [PTR_WIDTH-1:0] wgray;
  reg [PTR_WIDTH-1:0] rbin;
  reg [PTR_WIDTH-1:0] rgray;

  wire [PTR_WIDTH-1:0] wgray_sync_r;
  wire [PTR_WIDTH-1:0] rgray_sync_w;

  reg wfull_reg;
  reg awfull_reg;
  reg rempty_reg;
  reg arempty_reg;

  wire waccept;
  wire raccept;

  wire [PTR_WIDTH-1:0] wbin_next;
  wire [PTR_WIDTH-1:0] wgray_next;
  wire [PTR_WIDTH-1:0] wbin_ahead;
  wire [PTR_WIDTH-1:0] wgray_ahead;
  wire [PTR_WIDTH-1:0] rgray_full_target;
  wire                 wfull_next;
  wire                 awfull_next;

  wire [PTR_WIDTH-1:0] rbin_next;
  wire [PTR_WIDTH-1:0] rgray_next;
  wire [PTR_WIDTH-1:0] rbin_ahead;
  wire [PTR_WIDTH-1:0] rgray_ahead;
  wire                 rempty_next;
  wire                 arempty_next;

  reg [DSIZE-1:0] rdata_reg;

  function [PTR_WIDTH-1:0] bin_to_gray;
    input [PTR_WIDTH-1:0] bin;
    begin
      bin_to_gray = (bin >> 1) ^ bin;
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
    .WIDTH(PTR_WIDTH)
  ) u_rgray_to_wclk (
    .clk   (wclk),
    .rst_n (wrst_sync_n),
    .d     (rgray),
    .q     (rgray_sync_w)
  );

  async_gray_sync #(
    .WIDTH(PTR_WIDTH)
  ) u_wgray_to_rclk (
    .clk   (rclk),
    .rst_n (rrst_sync_n),
    .d     (wgray),
    .q     (wgray_sync_r)
  );

  assign waccept = winc && !wfull_reg;
  assign raccept = rinc && !rempty_reg;

  assign wbin_next  = wbin + (waccept ? PTR_ONE : {PTR_WIDTH{1'b0}});
  assign wgray_next = bin_to_gray(wbin_next);
  assign wbin_ahead = wbin_next + PTR_ONE;
  assign wgray_ahead = bin_to_gray(wbin_ahead);

  assign rgray_full_target = rgray_sync_w ^ FULL_XOR_MASK;

  assign wfull_next = (wgray_next == rgray_full_target);
  assign awfull_next =
      wfull_next || (wgray_ahead == rgray_full_target);

  assign rbin_next  = rbin + (raccept ? PTR_ONE : {PTR_WIDTH{1'b0}});
  assign rgray_next = bin_to_gray(rbin_next);
  assign rbin_ahead = rbin_next + PTR_ONE;
  assign rgray_ahead = bin_to_gray(rbin_ahead);

  assign rempty_next = (rgray_next == wgray_sync_r);
  assign arempty_next =
      rempty_next || (rgray_ahead == wgray_sync_r);

  always @(posedge wclk) begin
    if (waccept)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  always @(posedge wclk or negedge wrst_sync_n) begin
    if (!wrst_sync_n) begin
      wbin       <= {PTR_WIDTH{1'b0}};
      wgray      <= {PTR_WIDTH{1'b0}};
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
      rbin        <= {PTR_WIDTH{1'b0}};
      rgray       <= {PTR_WIDTH{1'b0}};
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
  assign rdata = rdata_reg;

endmodule
