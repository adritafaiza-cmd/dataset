module async_fifo_reset_sync (
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
  localparam DEPTH = (1 << ASIZE);

  localparam [ASIZE:0] DEPTH_VALUE =
      {1'b1, {ASIZE{1'b0}}};

  localparam [ASIZE:0] ALMOST_FULL_COUNT =
      {1'b0, {ASIZE{1'b1}}};

  localparam [ASIZE:0] ONE_COUNT =
      {{ASIZE{1'b0}}, 1'b1};

  reg [DSIZE-1:0] mem [0:DEPTH-1];

  wire wrst_sync_n;
  wire rrst_sync_n;

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  wire [ASIZE:0] wgray_sync;
  wire [ASIZE:0] rgray_sync;
  wire [ASIZE:0] wbin_sync;
  wire [ASIZE:0] rbin_sync;

  wire [ASIZE:0] wbinnext;
  wire [ASIZE:0] wgraynext;
  wire [ASIZE:0] rbinnext;
  wire [ASIZE:0] rgraynext;

  wire [ASIZE:0] wused_next;
  wire [ASIZE:0] ravail_next;

  wire wtake;
  wire rtake;

  wire wfull_next;
  wire awfull_next;
  wire rempty_next;
  wire arempty_next;

  reg wfull_reg;
  reg awfull_reg;
  reg rempty_reg;
  reg arempty_reg;

  function [ASIZE:0] gray_to_binary;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray_to_binary[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i-1)
        gray_to_binary[i] = gray_to_binary[i+1] ^ gray[i];
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
    .WIDTH (PSIZE)
  ) u_rptr_to_wclk (
    .clk   (wclk),
    .rst_n (wrst_sync_n),
    .din   (rgray),
    .dout  (rgray_sync)
  );

  async_fifo_gray_sync #(
    .WIDTH (PSIZE)
  ) u_wptr_to_rclk (
    .clk   (rclk),
    .rst_n (rrst_sync_n),
    .din   (wgray),
    .dout  (wgray_sync)
  );

  assign rbin_sync = gray_to_binary(rgray_sync);
  assign wbin_sync = gray_to_binary(wgray_sync);

  assign wtake = winc && !wfull_reg;
  assign rtake = rinc && !rempty_reg;

  assign wbinnext  = wbin + wtake;
  assign wgraynext = (wbinnext >> 1) ^ wbinnext;

  assign rbinnext  = rbin + rtake;
  assign rgraynext = (rbinnext >> 1) ^ rbinnext;

  assign wused_next  = wbinnext - rbin_sync;
  assign ravail_next = wbin_sync - rbinnext;

  assign wfull_next =
      (wbinnext == (rbin_sync ^ DEPTH_VALUE));

  assign awfull_next =
      (wused_next >= ALMOST_FULL_COUNT);

  assign rempty_next =
      (rgraynext == wgray_sync);

  assign arempty_next =
      (ravail_next <= ONE_COUNT);

  always @(posedge wclk or negedge wrst_sync_n) begin
    if (!wrst_sync_n) begin
      wbin        <= {PSIZE{1'b0}};
      wgray       <= {PSIZE{1'b0}};
      wfull_reg   <= 1'b0;
      awfull_reg  <= 1'b0;
    end else begin
      wbin        <= wbinnext;
      wgray       <= wgraynext;
      wfull_reg   <= wfull_next;
      awfull_reg  <= awfull_next;
    end
  end

  always @(posedge rclk or negedge rrst_sync_n) begin
    if (!rrst_sync_n) begin
      rbin         <= {PSIZE{1'b0}};
      rgray        <= {PSIZE{1'b0}};
      rempty_reg   <= 1'b1;
      arempty_reg  <= 1'b1;
    end else begin
      rbin         <= rbinnext;
      rgray        <= rgraynext;
      rempty_reg   <= rempty_next;
      arempty_reg  <= arempty_next;
    end
  end

  always @(posedge wclk) begin
    if (wrst_sync_n && wtake)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  assign wfull  = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;

  generate
    if (FALLTHROUGH == "TRUE") begin : g_fallthrough
      assign rdata = mem[rbin[ASIZE-1:0]];
    end else begin : g_registered_read
      reg [DSIZE-1:0] rdata_reg;

      always @(posedge rclk or negedge rrst_sync_n) begin
        if (!rrst_sync_n)
          rdata_reg <= {DSIZE{1'b0}};
        else if (rtake)
          rdata_reg <= mem[rbin[ASIZE-1:0]];
      end

      assign rdata = rdata_reg;
    end
  endgenerate

endmodule
