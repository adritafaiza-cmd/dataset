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
  localparam [ASIZE:0] FULL_MASK = (3 << (ASIZE-1));
  localparam [ASIZE:0] AFULL_LEVEL = DEPTH - 1;
  localparam [ASIZE:0] AEMPTY_LEVEL = 1;

  wire arst_n;
  wire wreset_n;
  wire rreset_n;

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] wgray_sync;
  wire [ASIZE:0] rgray_sync;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] synced_wbin;
  wire [ASIZE:0] synced_rbin;
  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] rused_next;

  wire wpush;
  wire rpop;
  wire wfull_next;
  wire rempty_next;
  wire awfull_next;
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

  assign arst_n = wrst_n & rrst_n;

  async_fifo_reset_sync u_wreset_sync (
    .clk     (wclk),
    .arst_n  (arst_n),
    .srst_n  (wreset_n)
  );

  async_fifo_reset_sync u_rreset_sync (
    .clk     (rclk),
    .arst_n  (arst_n),
    .srst_n  (rreset_n)
  );

  async_fifo_gray_sync #(
    .WIDTH(ASIZE+1)
  ) u_sync_rgray_to_wclk (
    .clk      (wclk),
    .reset_n  (wreset_n),
    .din      (rgray),
    .dout     (rgray_sync)
  );

  async_fifo_gray_sync #(
    .WIDTH(ASIZE+1)
  ) u_sync_wgray_to_rclk (
    .clk      (rclk),
    .reset_n  (rreset_n),
    .din      (wgray),
    .dout     (wgray_sync)
  );

  assign wpush = winc && !wfull_reg;
  assign rpop  = rinc && !rempty_reg;

  assign wbin_next  = wbin + wpush;
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

  assign rbin_next  = rbin + rpop;
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign synced_rbin = gray_to_bin(rgray_sync);
  assign synced_wbin = gray_to_bin(wgray_sync);

  assign wused_next = wbin_next - synced_rbin;
  assign rused_next = synced_wbin - rbin_next;

  assign wfull_next  = (wgray_next == (rgray_sync ^ FULL_MASK));
  assign rempty_next = (rgray_next == wgray_sync);

  assign awfull_next = (wused_next >= AFULL_LEVEL);
  assign arempty_next = (rused_next <= AEMPTY_LEVEL);

  assign wfull  = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;

  always @(posedge wclk or negedge wreset_n) begin
    if (!wreset_n) begin
      wbin       <= {ASIZE+1{1'b0}};
      wgray      <= {ASIZE+1{1'b0}};
      wfull_reg  <= 1'b0;
      awfull_reg <= 1'b0;
    end
    else begin
      wbin       <= wbin_next;
      wgray      <= wgray_next;
      wfull_reg  <= wfull_next;
      awfull_reg <= awfull_next;
    end
  end

  always @(posedge wclk) begin
    if (wreset_n && wpush)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  always @(posedge rclk or negedge rreset_n) begin
    if (!rreset_n) begin
      rbin        <= {ASIZE+1{1'b0}};
      rgray       <= {ASIZE+1{1'b0}};
      rempty_reg  <= 1'b1;
      arempty_reg <= 1'b1;
    end
    else begin
      rbin        <= rbin_next;
      rgray       <= rgray_next;
      rempty_reg  <= rempty_next;
      arempty_reg <= arempty_next;
    end
  end

  generate
    if (FALLTHROUGH == "TRUE") begin : g_fallthrough
      assign rdata = mem[rbin[ASIZE-1:0]];
    end
    else begin : g_registered_read
      always @(posedge rclk or negedge rreset_n) begin
        if (!rreset_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (rpop)
          rdata_reg <= mem[rbin[ASIZE-1:0]];
      end

      assign rdata = rdata_reg;
    end
  endgenerate

endmodule


module async_fifo_reset_sync (
  input  wire clk,
  input  wire arst_n,
  output wire srst_n
);

  (* ASYNC_REG = "TRUE" *) reg [1:0] reset_pipe;

  always @(posedge clk or negedge arst_n) begin
    if (!arst_n)
      reset_pipe <= 2'b00;
    else begin
      reset_pipe[0] <= 1'b1;
      reset_pipe[1] <= reset_pipe[0];
    end
  end

  assign srst_n = reset_pipe[1];

endmodule


module async_fifo_gray_sync #(
  parameter WIDTH = 5
)(
  input  wire             clk,
  input  wire             reset_n,
  input  wire [WIDTH-1:0] din,
  output wire [WIDTH-1:0] dout
);

  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff1;
  (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_ff2;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sync_ff1 <= {WIDTH{1'b0}};
      sync_ff2 <= {WIDTH{1'b0}};
    end
    else begin
      sync_ff1 <= din;
      sync_ff2 <= sync_ff1;
    end
  end

  assign dout = sync_ff2;

endmodule
