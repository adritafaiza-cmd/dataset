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
  reg [ASIZE-1:0] wcnt_sync, rcnt_sync;
  reg wfull_reg, rempty_reg;
  reg awfull_reg, arempty_reg;

  assign wfull = wfull_reg;
  assign awfull = awfull_reg;
  assign rempty = rempty_reg;
  assign arempty = arempty_reg;

  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wptr <= 0;
      wcnt <= 0;
      wfull_reg <= 0;
      awfull_reg <= 0;
    end else if (winc && !wfull_reg) begin
      fifo[wptr] <= wdata;
      wptr <= wptr + 1;
      wcnt <= wcnt + 1;
      if (wcnt == 2**ASIZE - 2) begin
        awfull_reg <= 1;
      end else if (wcnt == 2**ASIZE - 1) begin
        wfull_reg <= 1;
      end else begin
        awfull_reg <= 0;
      end
    end else if (winc && wfull_reg) begin
      // do nothing
    end
  end

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rptr <= 0;
      rcnt <= 0;
      rempty_reg <= 1;
      arempty_reg <= 1;
      if (FALLTHROUGH == "TRUE") begin
        rdata <= 0;
      end
    end else if (rinc && !rempty_reg) begin
      if (FALLTHROUGH == "TRUE") begin
        // do nothing
      end else begin
        rdata <= fifo[rptr];
      end
      rptr <= rptr + 1;
      rcnt <= rcnt + 1;
      if (rcnt == 2) begin
        arempty_reg <= 1;
      end else if (rcnt == 1) begin
        rempty_reg <= 0;
      end else begin
        arempty_reg <= 0;
      end
    end else if (rinc && rempty_reg) begin
      // do nothing
    end
  end

  // gray counter
  always @(posedge wclk) begin
    wptr_gray <= {wptr[ASIZE-2:0], wptr[ASIZE-1]};
  end

  always @(posedge rclk) begin
    rptr_gray <= {rptr[ASIZE-2:0], rptr[ASIZE-1]};
  end

  // synchronizer
  reg [1:0] wptr_sync_reg;
  reg [1:0] rptr_sync_reg;
  reg [1:0] wcnt_sync_reg;
  reg [1:0] rcnt_sync_reg;

  always @(posedge rclk) begin
    wptr_sync_reg[0] <= wptr_gray[ASIZE-1];
    wptr_sync_reg[1] <= wptr_sync_reg[0];
    wptr_sync <= {wptr_sync_reg[1], wptr_sync_reg[0], wptr_gray[ASIZE-2:0]};
  end

  always @(posedge wclk) begin
    rptr_sync_reg[0] <= rptr_gray[ASIZE-1];
    rptr_sync_reg[1] <= rptr_sync_reg[0];
    rptr_sync <= {rptr_sync_reg[1], rptr_sync_reg[0], rptr_gray[ASIZE-2:0]};
  end

  always @(posedge rclk) begin
    wcnt_sync_reg[0] <= wcnt[ASIZE-1];
    wcnt_sync_reg[1] <= wcnt_sync_reg[0];
    wcnt_sync <= {wcnt_sync_reg[1], wcnt_sync_reg[0], wcnt[ASIZE-2:0]};
  end

  always @(posedge wclk) begin
    rcnt_sync_reg[0] <= rcnt[ASIZE-1];
    rcnt_sync_reg[1] <= rcnt_sync_reg[0];
    rcnt_sync <= {rcnt_sync_reg[1], rcnt_sync_reg[0], rcnt[ASIZE-2:0]};
  end

  // fallthrough
  always @(posedge rclk) begin
    if (FALLTHROUGH == "TRUE") begin
      if (!rempty_reg) begin
        rdata <= fifo[rptr_sync];
      end
    end
  end

endmodule
