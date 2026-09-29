module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
) (
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr
);

localparam PTR_WIDTH = ADDR_WIDTH + 1;

// Write domain signals
reg [PTR_WIDTH-1:0] wptr;
wire [PTR_WIDTH-1:0] wgray_next;
wire [PTR_WIDTH-1:0] wptr_next;
reg [PTR_WIDTH-1:0] rgray_sync1, rgray_sync;

// Read domain signals
reg [PTR_WIDTH-1:0] rptr;
wire [PTR_WIDTH-1:0] rgray_next;
wire [PTR_WIDTH-1:0] rptr_next;
reg [PTR_WIDTH-1:0] wgray_sync1, wgray_sync;

// Memory
reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

// Write pointer logic
assign wptr_next = wptr + 1;
assign wgray_next = wptr_next ^ (wptr_next >> 1);

// Synchronize read pointer's gray to write domain
always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
        rgray_sync1 <= 0;
        rgray_sync <= 0;
    end else begin
        rgray_sync1 <= rgray;
        rgray_sync <= rgray_sync1;
    end
end

// Full condition
wire wfull_val;
assign wfull_val = (wgray_next == { ~rgray_sync[PTR_WIDTH-1 : PTR_WIDTH-2], rgray_sync[PTR_WIDTH-3 : 0] });

// Update write pointer
always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
        wptr <= 0;
    end else if (winc && !wfull_val) begin
        wptr <= wptr_next;
    end
end

assign wfull = wfull_val;

// Read pointer logic
assign rptr_next = rptr + 1;
assign rgray_next = rptr_next ^ (rptr_next >> 1);

// Synchronize write pointer's gray to read domain
always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        wgray_sync1 <= 0;
        wgray_sync <= 0;
    end else begin
        wgray_sync1 <= wgray;
        wgray_sync <= wgray_sync1;
    end
end

// Empty condition
wire rempty_val;
assign rempty_val = (rgray == wgray_sync);

// Update read pointer
always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        rptr <= 0;
    end else if (rinc && !rempty_val) begin
        rptr <= rptr_next;
    end
end

assign rempty = rempty_val;

// Memory write
always @(posedge wclk) begin
    if (winc && !wfull)
        mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
end

// Memory read
reg [DATA_WIDTH-1:0] rdata_reg;
always @(posedge rclk) begin
    if (rinc && !rempty)
        rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
end

assign rdata = rdata_reg;

// Assign addresses
assign waddr = wptr;
assign raddr = rptr;

// Convert pointers to gray
wire [PTR_WIDTH-1:0] wgray = wptr ^ (wptr >> 1);
wire [PTR_WIDTH-1:0] rgray = rptr ^ (rptr >> 1);

endmodule
