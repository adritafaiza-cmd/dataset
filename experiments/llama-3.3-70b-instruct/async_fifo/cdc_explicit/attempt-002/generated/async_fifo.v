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

  reg [ASIZE-1:0] wptr, rptr;
  reg [ASIZE-1:0] wptr_gray, rptr_gray;
  reg [ASIZE-1:0] wptr_sync, rptr_sync;
  reg [ASIZE:0]  wcnt, rcnt;
  reg [DSIZE-1:0] mem [2**ASIZE-1:0];

  assign wfull = (wcnt == (1 << ASIZE));
  assign awfull = (wcnt >= (1 << ASIZE) - 2);
  assign rempty = (rcnt == 0);
  assign arempty = (rcnt <= 2);

  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wptr <= 0;
      wcnt <= 0;
    end else if (winc && !wfull) begin
      mem[wptr] <= wdata;
      wptr <= wptr + 1;
      wcnt <= wcnt + 1;
    end
  end

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rptr <= 0;
      rcnt <= 0;
    end else if (rinc && !rempty) begin
      if (FALLTHROUGH == "TRUE") begin
        rdata <= mem[rptr];
      end
      rptr <= rptr + 1;
      rcnt <= rcnt - 1;
    end
  end

  always @(posedge wclk) begin
    wptr_gray <= wptr;
  end

  always @(posedge rclk) begin
    rptr_gray <= rptr;
  end

  // Synchronize wptr_gray to read clock domain
  reg [2:0] wptr_sync_reg;
  always @(posedge rclk) begin
    wptr_sync_reg[0] <= wptr_gray;
    wptr_sync_reg[1] <= wptr_sync_reg[0];
    wptr_sync_reg[2] <= wptr_sync_reg[1];
    wptr_sync <= wptr_sync_reg[2];
  end

  // Synchronize rptr_gray to write clock domain
  reg [2:0] rptr_sync_reg;
  always @(posedge wclk) begin
    rptr_sync_reg[0] <= rptr_gray;
    rptr_sync_reg[1] <= rptr_sync_reg[0];
    rptr_sync_reg[2] <= rptr_sync_reg[1];
    rptr_sync <= rptr_sync_reg[2];
  end

  always @(posedge rclk) begin
    if (FALLTHROUGH != "TRUE") begin
      if (!rempty) begin
        rdata <= mem[rptr];
      end
    end
  end

  always @(posedge wclk) begin
    if (winc && !wfull) begin
      wcnt <= wcnt + 1;
    end
  end

  always @(posedge rclk) begin
    if (rinc && !rempty) begin
      rcnt <= rcnt - 1;
    end
  end

  always @(posedge wclk) begin
    if (wcnt == (1 << ASIZE)) begin
      wcnt <= (1 << ASIZE);
    end
  end

  always @(posedge rclk) begin
    if (rcnt == 0) begin
      rcnt <= 0;
    end
  end

endmodule
