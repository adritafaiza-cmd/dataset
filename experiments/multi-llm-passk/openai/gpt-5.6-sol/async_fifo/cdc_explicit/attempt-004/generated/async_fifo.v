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

  localparam [ASIZE:0] DEPTH_COUNT =
    {1'b1, {ASIZE{1'b0}}};
  localparam [ASIZE:0] ALMOST_FULL_COUNT =
    {1'b0, {ASIZE{1'b1}}};
  localparam [ASIZE:0] ONE_COUNT =
    {{ASIZE{1'b0}}, 1'b1};

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

  wire wrst_sync_n;
  wire rrst_sync_n;

  reg  [ASIZE:0] wbin;
  reg  [ASIZE:0] wgray;
  reg              wfull_reg;
  reg              awfull_reg;

  reg  [ASIZE:0] rbin;
  reg  [ASIZE:0] rgray;
  reg              rempty_reg;
  reg              arempty_reg;

  wire [ASIZE:0] wq2_rgray;
  wire [ASIZE:0] rq2_wgray;

  wire             waccept;
  wire             raccept;
  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] wq2_rbin;
  wire [ASIZE:0] rq2_wbin;
  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] ravail_next;

  wire             wfull_next;
  wire             awfull_next;
  wire             rempty_next;
  wire             arempty_next;

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
      for (i = ASIZE-1; i >= 0; i = i - 1)
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
    .WIDTH(ASIZE+1)
  ) u_rgray_to_wclk (
    .clk      (wclk),
    .rst_n    (wrst_sync_n),
    .gray_in  (rgray),
    .gray_out (wq2_rgray)
  );

  async_fifo_gray_sync #(
    .WIDTH(ASIZE+1)
  ) u_wgray_to_rclk (
    .clk      (rclk),
    .rst_n    (rrst_sync_n),
    .gray_in  (wgray),
    .gray_out (rq2_wgray)
  );

  assign waccept = winc && !wfull_reg;
  assign raccept = rinc && !rempty_reg;

  assign wbin_next  = wbin + (waccept ? ONE_COUNT : {ASIZE+1{1'b0}});
  assign wgray_next = bin_to_gray(wbin_next);

  assign rbin_next  = rbin + (raccept ? ONE_COUNT : {ASIZE+1{1'b0}});
  assign rgray_next = bin_to_gray(rbin_next);

  assign wq2_rbin = gray_to_bin(wq2_rgray);
  assign rq2_wbin = gray_to_bin(rq2_wgray);

  assign wused_next  = wbin_next - wq2_rbin;
  assign ravail_next = rq2_wbin - rbin_next;

  assign wfull_next  = (wused_next == DEPTH_COUNT);
  assign awfull_next = (wused_next >= ALMOST_FULL_COUNT);

  assign rempty_next  = (rgray_next == rq2_wgray);
  assign arempty_next = (ravail_next <= ONE_COUNT);

  assign wfull  = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;
  assign rdata = rdata_reg;

  always @(posedge wclk or negedge wrst_sync_n) begin
    if (!wrst_sync_n) begin
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
    if (wrst_sync_n && waccept)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  always @(posedge rclk or negedge rrst_sync_n) begin
    if (!rrst_sync_n) begin
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
      always @(posedge rclk or negedge rrst_sync_n) begin
        if (!rrst_sync_n) begin
          rdata_reg <= {DSIZE{1'b0}};
        end else if (!rempty_next && (rempty_reg || raccept)) begin
          rdata_reg <= mem[rbin_next[ASIZE-1:0]];
        end
      end
    end else begin : g_registered_read
      always @(posedge rclk or negedge rrst_sync_n) begin
        if (!rrst_sync_n) begin
          rdata_reg <= {DSIZE{1'b0}};
        end else if (raccept) begin
          rdata_reg <= mem[rbin[ASIZE-1:0]];
        end
      end
    end
  endgenerate

endmodule


module async_fifo_reset_sync (
  input  wire clk,
  input  wire arst_n,
  output wire srst_n
);

  (* async_reg = "true" *) reg [1:0] sync_ff;

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
  input  wire [WIDTH-1:0] gray_in,
  output wire [WIDTH-1:0] gray_out
);

  (* async_reg = "true" *) reg [WIDTH-1:0] sync_ff1;
  (* async_reg = "true" *) reg [WIDTH-1:0] sync_ff2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff1 <= {WIDTH{1'b0}};
      sync_ff2 <= {WIDTH{1'b0}};
    end else begin
      sync_ff1 <= gray_in;
      sync_ff2 <= sync_ff1;
    end
  end

  assign gray_out = sync_ff2;

endmodule
