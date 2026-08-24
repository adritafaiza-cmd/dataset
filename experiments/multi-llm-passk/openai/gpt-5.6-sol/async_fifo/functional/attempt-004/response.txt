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

  localparam [ASIZE:0] PTR_ONE =
      {{ASIZE{1'b0}}, 1'b1};
  localparam [ASIZE:0] FIFO_DEPTH =
      (PTR_ONE << ASIZE);
  localparam [ASIZE:0] FULL_MASK =
      (PTR_ONE << ASIZE) | (PTR_ONE << (ASIZE-1));

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

  reg [ASIZE:0] wbin;
  reg [ASIZE:0] wgray;
  reg [ASIZE:0] rbin;
  reg [ASIZE:0] rgray;

  reg [ASIZE:0] rq1_rgray;
  reg [ASIZE:0] rq2_rgray;
  reg [ASIZE:0] wq1_wgray;
  reg [ASIZE:0] wq2_wgray;

  reg wfull_reg;
  reg rempty_reg;

  wire write_accept;
  wire read_accept;

  wire [ASIZE:0] wbin_next;
  wire [ASIZE:0] wgray_next;
  wire [ASIZE:0] rbin_next;
  wire [ASIZE:0] rgray_next;

  wire wfull_next;
  wire rempty_next;

  wire [ASIZE:0] synced_rbin;
  wire [ASIZE:0] synced_wbin;
  wire [ASIZE:0] w_used;
  wire [ASIZE:0] r_available;

  function [ASIZE:0] gray_to_binary;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray_to_binary[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i-1)
        gray_to_binary[i] = gray_to_binary[i+1] ^ gray[i];
    end
  endfunction

  assign wfull  = wfull_reg;
  assign rempty = rempty_reg;

  assign write_accept = winc && !wfull_reg;
  assign read_accept  = rinc && !rempty_reg;

  assign wbin_next =
      wbin + {{ASIZE{1'b0}}, write_accept};
  assign wgray_next =
      (wbin_next >> 1) ^ wbin_next;

  assign rbin_next =
      rbin + {{ASIZE{1'b0}}, read_accept};
  assign rgray_next =
      (rbin_next >> 1) ^ rbin_next;

  assign wfull_next =
      (wgray_next == (rq2_rgray ^ FULL_MASK));
  assign rempty_next =
      (rgray_next == wq2_wgray);

  assign synced_rbin = gray_to_binary(rq2_rgray);
  assign synced_wbin = gray_to_binary(wq2_wgray);

  assign w_used      = wbin - synced_rbin;
  assign r_available = synced_wbin - rbin;

  assign awfull  = (w_used >= (FIFO_DEPTH - PTR_ONE));
  assign arempty = (r_available <= PTR_ONE);

  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wbin      <= {ASIZE+1{1'b0}};
      wgray     <= {ASIZE+1{1'b0}};
      wfull_reg <= 1'b0;
    end
    else begin
      wbin      <= wbin_next;
      wgray     <= wgray_next;
      wfull_reg <= wfull_next;
    end
  end

  always @(posedge wclk) begin
    if (write_accept)
      mem[wbin[ASIZE-1:0]] <= wdata;
  end

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rbin       <= {ASIZE+1{1'b0}};
      rgray      <= {ASIZE+1{1'b0}};
      rempty_reg <= 1'b1;
    end
    else begin
      rbin       <= rbin_next;
      rgray      <= rgray_next;
      rempty_reg <= rempty_next;
    end
  end

  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      rq1_rgray <= {ASIZE+1{1'b0}};
      rq2_rgray <= {ASIZE+1{1'b0}};
    end
    else begin
      rq1_rgray <= rgray;
      rq2_rgray <= rq1_rgray;
    end
  end

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      wq1_wgray <= {ASIZE+1{1'b0}};
      wq2_wgray <= {ASIZE+1{1'b0}};
    end
    else begin
      wq1_wgray <= wgray;
      wq2_wgray <= wq1_wgray;
    end
  end

  generate
    if (FALLTHROUGH == "TRUE") begin : g_fallthrough
      assign rdata = mem[rbin[ASIZE-1:0]];
    end
    else begin : g_registered_read
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
