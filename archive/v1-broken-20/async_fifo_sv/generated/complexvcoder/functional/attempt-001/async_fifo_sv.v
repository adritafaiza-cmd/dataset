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

    // Internal signals
    reg [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wptr_sync;
    reg [ADDR_WIDTH:0] rptr_sync;
    reg [ADDR_WIDTH:0] wptr_sync_reg;
    reg [ADDR_WIDTH:0] rptr_sync_reg;
    reg wfull_reg;
    reg rempty_reg;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                if (wptr == 2**ADDR_WIDTH - 1) begin
                    wptr <= 0;
                end
            end
            wfull_reg <= (wptr == rptr);
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_reg <= 1;
        end else begin
            if (rinc && !rempty_reg) begin
                rptr <= rptr + 1;
                if (rptr == 2**ADDR_WIDTH - 1) begin
                    rptr <= 0;
                end
            end
            rempty_reg <= (wptr == rptr);
        end
    end

    // Synchronization logic
    always @(posedge wclk) begin
        wptr_sync_reg <= wptr;
    end

    always @(posedge rclk) begin
        rptr_sync_reg <= rptr;
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr_sync_reg;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr_sync_reg;
    end

    // Output logic
    assign wfull = wfull_reg;
    assign waddr = {wptr_sync, wfull_reg};
    assign rdata = mem[rptr];
    assign rempty = rempty_reg;
    assign raddr = {rptr_sync, rempty_reg};

endmodule
