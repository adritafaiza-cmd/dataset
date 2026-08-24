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

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] wgray_sync;
  wire [ASIZE:0] rgray_sync;
  wire [ASIZE:0] wbin_sync;
  wire [ASIZE:0] rbin_sync;

  wire           wadvance;
  wire           radvance;
  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rgray_next;
  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] rused_next;

  reg wfull_reg;
  reg awfull_reg;
  reg rempty_reg;
  reg arempty_reg;

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

  assign wfull   = wfull_reg;
  assign awfull  = awfull_reg;
  assign rempty  = rempty_reg;
  assign arempty = arempty_reg;

  async_fifo_sync #(
    .WIDTH(ASIZE+1)
  ) sync_wgray_to_rclk (
    .clk   (rclk),
    .rst_n (rrst_n),
    .din   (wgray),
    .dout  (wgray_sync)
  );

  async_fifo_sync #(
    .WIDTH(ASIZE+1)
  ) sync_rgray_to_wclk (
    .clk   (wclk),
    .rst_n (wrst_n),
    .din   (rgray),
    .dout  (rgray_sync)
  );

  assign wbin_sync = gray_to_bin(wgray_sync);
  assign rbin_sync = gray_to_bin(rgray_sync);

  assign wadvance = winc && !wfull_reg;
  assign radvance = rinc && !rempty_reg;

  assign wbin_next  = wbin + wadvance;
  assign rbin_next  = rbin + radvance;
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign wused_next = wbin_next - rbin_sync;
  assign rused_next = wbin_sync - rbin_next;

  assign wfull_next =
      (wbin_next[ASIZE] != rbin_sync[ASIZE]) &&
      (wbin_next[ASIZE-1:0] == rbin_sync[ASIZE-1:0]);

  assign awfull_next =
      (wused_next >= (DEPTH - 1));

  assign rempty_next = (rgray_next == wgray_sync);
  assign arempty_next = (rused_next <= 1);

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
    if (wadvance)
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
    if (FALLTHROUGH == "TRUE") begin : gen_fallthrough
      assign rdata = mem[rbin[ASIZE-1:0]];
    end else begin : gen_registered_read
      reg [DSIZE-1:0] rdata_reg;

      always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (radvance)
          rdata_reg <= mem[rbin[ASIZE-1:0]];
      end

      assign rdata = rdata_reg;
    end
  endgenerate

endmodule


module async_fifo_sync #(
  parameter WIDTH = 2
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [WIDTH-1:0] din,
  output reg  [WIDTH-1:0] dout
);

  reg [WIDTH-1:0] sync_ff1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff1 <= {WIDTH{1'b0}};
      dout     <= {WIDTH{1'b0}};
    end else begin
      sync_ff1 <= din;
      dout     <= sync_ff1;
    end
  end

endmodule
