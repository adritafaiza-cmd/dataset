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
    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg wfull_sync, rempty_sync;
    reg [SYNC_STAGES-1:0] wptr_sync, rptr_sync;

    // Write process
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_sync <= 0;
        end else begin
            if (winc && !wfull_sync) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
            end
            if (wptr == 2**ADDR_WIDTH - 1)
                wfull_sync <= 1;
            else
                wfull_sync <= 0;
        end
    end

    // Read process
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_sync <= 1;
        end else begin
            if (rinc && !rempty_sync) begin
                rptr <= rptr + 1;
            end
            if (rptr == 2**ADDR_WIDTH - 1)
                rempty_sync <= 0;
            else
                rempty_sync <= 1;
        end
    end

    // Synchronize pointers across clock domains
    generate
        if (SYNC_STAGES > 0) begin
            genvar i;
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_wptr
                always @(posedge wclk or negedge wrst_n) begin
                    if (!wrst_n)
                        wptr_sync[i] <= 0;
                    else
                        wptr_sync[i] <= wptr_sync[i + 1];
                end
            end
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n)
                    rptr_sync[i] <= 0;
                else
                    rptr_sync[i] <= rptr_sync[i + 1];
            end
        end
    endgenerate

    // Output assignment
    assign waddr = wptr_sync[SYNC_STAGES];
    assign raddr = rptr_sync[SYNC_STAGES];
    assign wfull = wfull_sync;
    assign rempty = rempty_sync;
    assign rdata = mem[rptr_sync[SYNC_STAGES]];

endmodule
