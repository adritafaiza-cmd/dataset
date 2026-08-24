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

  localparam [ASIZE:0] FULL_MASK =
    {2'b11, {(ASIZE-1){1'b0}}};
  localparam [ASIZE:0] ALMOST_FULL_LEVEL =
    {1'b0, {ASIZE{1'b1}}};
  localparam [ASIZE:0] ALMOST_EMPTY_LEVEL =
    {{ASIZE{1'b0}}, 1'b1};

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg             wfull_reg;
  reg             awfull_reg;

  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;
  reg             rempty_reg;
  reg             arempty_reg;

  reg [DSIZE-1:0] rdata_reg;

  wire [ASIZE:0] rq2_wgray;
  wire [ASIZE:0] wq2_rgray;

  wire wpush;
  wire rpop;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] synced_rbin;
  wire [ASIZE:0] synced_wbin;
  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] rused_next;

  wire wfull_next;
  wire awfull_next;
  wire rempty_next;
  wire arempty_next;

  function [ASIZE:0] gray2bin;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray2bin[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i-1)
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
  endfunction

  assign wfull   = wfull_reg;
  assign awfull  = awfull_reg;
  assign rempty  = rempty_reg;
  assign arempty = arempty_reg;

  assign wpush = winc && !wfull_reg;
  assign rpop  = rinc && !rempty_reg;

  assign wbin_next  = wbin + wpush;
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

  assign rbin_next  = rbin + rpop;
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign synced_rbin = gray2bin(rq2_wgray);
  assign synced_wbin = gray2bin(wq2_rgray);

  assign wused_next = wbin_next - synced_rbin;
  assign rused_next = synced_wbin - rbin_next;

  assign wfull_next =
    (wgray_next == (rq2_wgray ^ FULL_MASK));
  assign awfull_next =
    (wused_next >= ALMOST_FULL_LEVEL);

  assign rempty_next =
    (rgray_next == wq2_rgray);
  assign arempty_next =
    (rused_next <= ALMOST_EMPTY_LEVEL);

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
    if (wpush)
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

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n)
      rdata_reg <= {DSIZE{1'b0}};
    else if (rpop)
      rdata_reg <= mem[rbin[ASIZE-1:0]];
  end

  generate
    if (FALLTHROUGH == "TRUE") begin : gen_fallthrough
      assign rdata = mem[rbin[ASIZE-1:0]];
    end else begin : gen_registered_read
      assign rdata = rdata_reg;
    end
  endgenerate

  async_fifo_sync #(
    .PSIZE(ASIZE+1)
  ) sync_rptr_to_wclk (
    .clk    (wclk),
    .rst_n  (wrst_n),
    .d_async(rgray),
    .q_sync (rq2_wgray)
  );

  async_fifo_sync #(
    .PSIZE(ASIZE+1)
  ) sync_wptr_to_rclk (
    .clk    (rclk),
    .rst_n  (rrst_n),
    .d_async(wgray),
    .q_sync (wq2_rgray)
  );

endmodule


module async_fifo_sync #(
  parameter PSIZE = 5
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [PSIZE-1:0] d_async,
  output wire [PSIZE-1:0] q_sync
);

  reg [PSIZE-1:0] sync_ff1;
  reg [PSIZE-1:0] sync_ff2;

  assign q_sync = sync_ff2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff1 <= {PSIZE{1'b0}};
      sync_ff2 <= {PSIZE{1'b0}};
    end else begin
      sync_ff1 <= d_async;
      sync_ff2 <= sync_ff1;
    end
  end

endmodule
