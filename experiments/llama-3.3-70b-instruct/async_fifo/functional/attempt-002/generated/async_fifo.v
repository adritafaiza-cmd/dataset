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

  reg [DSIZE-1:0] fifo [2**ASIZE-1:0];
  reg [ASIZE-1:0] wptr, rptr;
  reg [ASIZE-1:0] wptr_gray, rptr_gray;
  reg [ASIZE-1:0] wptr_sync, rptr_sync;
  reg [ASIZE-1:0] wcnt, rcnt;
  reg wfull_reg, rempty_reg;
  reg awfull_reg, arempty_reg;

  assign wfull = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;

  always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
      wptr <= 0;
      wcnt <= 0;
      wfull_reg <= 1'b0;
      awfull_reg <= 1'b0;
    end else if (winc && ~wfull_reg) begin
      fifo[wptr] <= wdata;
      wptr <= wptr + 1;
      wcnt <= wcnt + 1;
      if (wcnt == (2**ASIZE - 2)) begin
        awfull_reg <= 1'b1;
      end else begin
        awfull_reg <= 1'b0;
      end
      if (wcnt == (2**ASIZE - 1)) begin
        wfull_reg <= 1'b1;
      end else begin
        wfull_reg <= 1'b0;
      end
    end
  end

  always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
      rptr <= 0;
      rcnt <= 0;
      rempty_reg <= 1'b1;
      arempty_reg <= 1'b1;
      if (FALLTHROUGH == "TRUE") begin
        rdata <= {DSIZE{1'b0}};
      end
    end else if (rinc && ~rempty_reg) begin
      if (FALLTHROUGH == "TRUE") begin
        rdata <= fifo[rptr];
      end
      rptr <= rptr + 1;
      rcnt <= rcnt - 1;
      if (rcnt == 2) begin
        arempty_reg <= 1'b1;
      end else begin
        arempty_reg <= 1'b0;
      end
      if (rcnt == 1) begin
        rempty_reg <= 1'b1;
      end else begin
        rempty_reg <= 1'b0;
      end
    end
  end

  gray_counter #(.ASIZE(ASIZE)) u_wptr_gray(
    .clk(wclk),
    .rst_n(wrst_n),
    .cnt(wptr),
    .gray(wptr_gray)
  );

  sync_module #(.ASIZE(ASIZE)) u_wptr_sync(
    .clk(rclk),
    .rst_n(rrst_n),
    .async(wptr_gray),
    .sync(wptr_sync)
  );

  gray_counter #(.ASIZE(ASIZE)) u_rptr_gray(
    .clk(rclk),
    .rst_n(rrst_n),
    .cnt(rptr),
    .gray(rptr_gray)
  );

  sync_module #(.ASIZE(ASIZE)) u_rptr_sync(
    .clk(wclk),
    .rst_n(wrst_n),
    .async(rptr_gray),
    .sync(rptr_sync)
  );

  always @(posedge wclk or negedge wrst_n) begin
    if (~wrst_n) begin
      wcnt <= 0;
    end else if (winc && ~wfull_reg) begin
      wcnt <= wcnt + 1;
    end else if (~winc && wfull_reg) begin
      wcnt <= wcnt;
    end
  end

  always @(posedge rclk or negedge rrst_n) begin
    if (~rrst_n) begin
      rcnt <= 0;
    end else if (rinc && ~rempty_reg) begin
      rcnt <= rcnt - 1;
    end else if (~rinc && rempty_reg) begin
      rcnt <= rcnt;
    end
  end

endmodule

module gray_counter #(
  parameter ASIZE = 4
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [ASIZE-1:0] cnt,
  output wire [ASIZE-1:0] gray
);

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      gray <= 0;
    end else begin
      gray <= cnt ^ (cnt >> 1);
    end
  end

endmodule

module sync_module #(
  parameter ASIZE = 4
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire [ASIZE-1:0] async,
  output wire [ASIZE-1:0] sync
);

  reg [ASIZE-1:0] sync_reg1, sync_reg2;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      sync_reg1 <= 0;
      sync_reg2 <= 0;
    end else begin
      sync_reg1 <= async;
      sync_reg2 <= sync_reg1;
    end
  end

  assign sync = sync_reg2;

endmodule
