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

  localparam PTR_WIDTH = ASIZE + 1;
  localparam DEPTH     = (1 << ASIZE);

  localparam [ASIZE:0] FIFO_DEPTH =
      {1'b1, {ASIZE{1'b0}}};

  localparam [ASIZE:0] ALMOST_FULL_LEVEL =
      FIFO_DEPTH - {{ASIZE{1'b0}}, 1'b1};

  localparam [ASIZE:0] ALMOST_EMPTY_LEVEL =
      {{ASIZE{1'b0}}, 1'b1};

  localparam [ASIZE:0] FULL_COMPARE_MASK =
      {2'b11, {(ASIZE-1){1'b0}}};

  wire wrst_local_n;
  wire rrst_local_n;

  reset_sync u_wreset_sync (
    .clk     (wclk),
    .arst_n  (wrst_n),
    .srst_n  (wrst_local_n)
  );

  reset_sync u_rreset_sync (
    .clk     (rclk),
    .arst_n  (rrst_n),
    .srst_n  (rrst_local_n)
  );

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] rgray_wclk;
  wire [ASIZE:0] wgray_rclk;

  cdc_sync_bus #(
    .WIDTH(PTR_WIDTH)
  ) u_sync_rgray_to_wclk (
    .clk    (wclk),
    .rst_n  (wrst_local_n),
    .din    (rgray),
    .dout   (rgray_wclk)
  );

  cdc_sync_bus #(
    .WIDTH(PTR_WIDTH)
  ) u_sync_wgray_to_rclk (
    .clk    (rclk),
    .rst_n  (rrst_local_n),
    .din    (wgray),
    .dout   (wgray_rclk)
  );

  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray_to_bin[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i-1)
        gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
    end
  endfunction

  wire waccept;
  wire raccept;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire [ASIZE:0] rbin_wclk;
  wire [ASIZE:0] wbin_rclk;

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

  assign wfull   = wfull_reg;
  assign rempty  = rempty_reg;
  assign awfull  = awfull_reg;
  assign arempty = arempty_reg;

  assign waccept = winc && !wfull_reg;
  assign raccept = rinc && !rempty_reg;

  assign wbin_next  = wbin + waccept;
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;

  assign rbin_next  = rbin + raccept;
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  assign rbin_wclk = gray_to_bin(rgray_wclk);
  assign wbin_rclk = gray_to_bin(wgray_rclk);

  assign wused_next = wbin_next - rbin_wclk;
  assign rused_next = wbin_rclk - rbin_next;

  assign wfull_next =
      (wgray_next == (rgray_wclk ^ FULL_COMPARE_MASK));

  assign rempty_next =
      (rgray_next == wgray_rclk);

  assign awfull_next =
      (wused_next >= ALMOST_FULL_LEVEL);

  assign arempty_next =
      (rused_next <= ALMOST_EMPTY_LEVEL);

  always @(posedge wclk or negedge wrst_local_n) begin
    if (!wrst_local_n) begin
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

  always @(posedge wclk) begin
    if (wrst_local_n && waccept)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  always @(posedge rclk or negedge rrst_local_n) begin
    if (!rrst_local_n) begin
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
      reg [DSIZE-1:0] rdata_reg;

      always @(posedge rclk or negedge rrst_local_n) begin
        if (!rrst_local_n) begin
          rdata_reg <= {DSIZE{1'b0}};
        end else begin
          if (rempty_reg && !rempty_next)
            rdata_reg <= mem[rbin[ASIZE-1:0]];
          else if (raccept && !rempty_next)
            rdata_reg <= mem[rbin_next[ASIZE-1:0]];
        end
      end

      assign rdata = rdata_reg;
    end else begin : g_registered_read
      reg [DSIZE-1:0] rdata_reg;

      always @(posedge rclk or negedge rrst_local_n) begin
        if (!rrst_local_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (raccept)
          rdata_reg <= mem[rbin[ASIZE-1:0]];
      end

      assign rdata = rdata_reg;
    end
  endgenerate

endmodule


module reset_sync (
  input  wire clk,
  input  wire arst_n,
  output wire srst_n
);

  (* async_reg = "true" *) reg sync_ff1;
  (* async_reg = "true" *) reg sync_ff2;

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


module cdc_sync_bus #(
  parameter WIDTH = 2
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [WIDTH-1:0] din,
  output wire [WIDTH-1:0] dout
);

  (* async_reg = "true" *) reg [WIDTH-1:0] sync_ff1;
  (* async_reg = "true" *) reg [WIDTH-1:0] sync_ff2;

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
