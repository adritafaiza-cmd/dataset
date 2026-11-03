module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
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

    reg [DATA_WIDTH-1:0] memory [0:(2**ADDR_WIDTH)-1];
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
    reg [ADDR_WIDTH:0] wptr_gray_synced, rptr_gray_synced;
    reg wfull_raw, rempty_raw;

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull_raw) begin
            memory[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wptr <= wptr + 1;
        end
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty_raw) begin
            rptr <= rptr + 1;
        end
    end

    // Gray code conversion
    always @(*) begin
        wptr_gray = (wptr >> 1) ^ wptr;
        rptr_gray = (rptr >> 1) ^ rptr;
    end

    // Synchronizer registers for cross-domain signals
    sync_reg #(.DATA_WIDTH(ADDR_WIDTH+1)) wptr_gray_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wptr_gray),
        .dout(wptr_gray_synced)
    );

    sync_reg #(.DATA_WIDTH(ADDR_WIDTH+1)) rptr_gray_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rptr_gray),
        .dout(rptr_gray_synced)
    );

    // Full and empty flags
    always @(*) begin
        wfull_raw = (wptr_gray_synced + 1) == rptr_gray;
        rempty_raw = wptr_gray == rptr_gray_synced;
    end

    // Output assignments
    assign wfull = wfull_raw;
    assign rempty = rempty_raw;
    assign waddr = wptr;
    assign raddr = rptr;
    assign rdata = memory[rptr[ADDR_WIDTH-1:0]];

endmodule

module sync_reg #(
    parameter DATA_WIDTH = 5
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [DATA_WIDTH-1:0]   din,
    output reg  [DATA_WIDTH-1:0]   dout
);

    reg [DATA_WIDTH-1:0] reg1, reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg1 <= 0;
            reg2 <= 0;
        end else begin
            reg1 <= din;
            reg2 <= reg1;
        end
    end

    assign dout = reg2;

endmodule
