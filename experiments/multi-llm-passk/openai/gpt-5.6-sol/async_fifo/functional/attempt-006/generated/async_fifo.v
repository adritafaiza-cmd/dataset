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

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] wq2_rgray;
  wire [ASIZE:0] rq2_wgray;
  wire [ASIZE:0] wq2_rbin;
  wire [ASIZE:0] rq2_wbin;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] rused_next;

  wire wfull_next;
  wire rempty_next;
  wire awfull_next;
  wire arempty_next;

  reg wfull_reg;
  reg rempty_reg;
  reg awfull_reg;
  reg arempty_reg;

  wire write_accept;
  wire read_accept;

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
  assign rempty = rempty_reg;
  assign awfull = awfull_reg;
  assign arempty = arempty_reg;

  assign write_accept = winc && !wfull_reg;
  assign read_accept  = rinc && !rempty_reg;

  assign wq2_rbin = gray_to_bin(wq2_rgray);
  assign rq2_wbin = gray_to_bin(rq2_wgray);

  assign wbin_next  = wbin + write_accept;
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

  assign rbin_next  = rbin + read_accept;
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign wfull_next =
      (wbin_next[ASIZE] != wq2_rbin[ASIZE]) &&
      (wbin_next[ASIZE-1:0] == wq2_rbin[ASIZE-1:0]);

  assign rempty_next = (rgray_next == rq2_wgray);

  assign wused_next = wbin_next - wq2_rbin;
  assign rused_next = rq2_wbin - rbin_next;

  assign awfull_next =
      (wused_next >= {1'b0, {ASIZE{1'b1}}});

  assign arempty_next =
      (rused_next <= {{ASIZE{1'b0}}, 1'b1});

  async_fifo_sync #(
    .WIDTH(ASIZE+1)
  ) sync_read_pointer_to_write_domain (
    .clk   (wclk),
    .rst_n (wrst_n),
    .d     (rgray),
    .q     (wq2_rgray)
  );

  async_fifo_sync #(
    .WIDTH(ASIZE+1)
  ) sync_write_pointer_to_read_domain (
    .clk   (rclk),
    .rst_n (rrst_n),
    .d     (wgray),
    .q     (rq2_wgray)
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

  always @(posedge wclk) begin
    if (write_accept)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  generate
    if (FALLTHROUGH == "TRUE") begin : g_fallthrough
      assign rdata = mem[rbin[ASIZE-1:0]];
    end else begin : g_registered_read
      reg [DSIZE-1:0] rdata_reg;

      always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (read_accept)
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
  input  wire [WIDTH-1:0] d,
  output reg  [WIDTH-1:0] q
);

  reg [WIDTH-1:0] sync_ff1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff1 <= {WIDTH{1'b0}};
      q        <= {WIDTH{1'b0}};
    end else begin
      sync_ff1 <= d;
      q        <= sync_ff1;
    end
  end

endmodule
