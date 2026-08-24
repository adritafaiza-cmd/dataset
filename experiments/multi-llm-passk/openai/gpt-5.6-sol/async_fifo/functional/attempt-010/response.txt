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

  localparam [ASIZE:0] DEPTH_VALUE =
      {1'b1, {ASIZE{1'b0}}};
  localparam [ASIZE:0] ONE_VALUE =
      {{ASIZE{1'b0}}, 1'b1};

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] wq2_rgray;
  wire [ASIZE:0] rq2_wgray;

  wire [ASIZE:0] wsync_rbin;
  wire [ASIZE:0] rsync_wbin;

  wire waccept;
  wire raccept;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] ravail_next;

  wire wfull_next;
  wire awfull_next;
  wire rempty_next;
  wire arempty_next;

  reg wfull_reg;
  reg awfull_reg;
  reg rempty_reg;
  reg arempty_reg;

  reg [DSIZE-1:0] rdata_reg;

  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray_to_bin[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i-1)
        gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
    end
  endfunction

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
      (wused_next == DEPTH_VALUE);

  assign awfull_next =
      (wused_next >= (DEPTH_VALUE - ONE_VALUE));

  assign rempty_next =
      (rgray_next == rq2_wgray);

  assign arempty_next =
      (ravail_next <= ONE_VALUE);

  async_fifo_sync #(
    .WIDTH(ASIZE+1)
  ) sync_rptr_to_wclk (
    .clk    (wclk),
    .rst_n  (wrst_n),
    .d_async(rgray),
    .q_sync (wq2_rgray)
  );

  async_fifo_sync #(
    .WIDTH(ASIZE+1)
  ) sync_wptr_to_rclk (
    .clk    (rclk),
    .rst_n  (rrst_n),
    .d_async(wgray),
    .q_sync (rq2_wgray)
  );

  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
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

  always @(posedge wclk) begin
    if (waccept)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
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

  generate
    if (FALLTHROUGH == "TRUE") begin : g_fallthrough
      assign rdata = mem[rbin[ASIZE-1:0]];
    end else begin : g_registered_read
      always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (raccept)
          rdata_reg <= mem[rbin[ASIZE-1:0]];
      end

      assign rdata = rdata_reg;
    end
  endgenerate

endmodule


module async_fifo_sync #(
  parameter WIDTH = 5
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [WIDTH-1:0] d_async,
  output wire [WIDTH-1:0] q_sync
);

  reg [WIDTH-1:0] sync_ff1;
  reg [WIDTH-1:0] sync_ff2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff1 <= {WIDTH{1'b0}};
      sync_ff2 <= {WIDTH{1'b0}};
    end else begin
      sync_ff1 <= d_async;
      sync_ff2 <= sync_ff1;
    end
  end

  assign q_sync = sync_ff2;

endmodule
