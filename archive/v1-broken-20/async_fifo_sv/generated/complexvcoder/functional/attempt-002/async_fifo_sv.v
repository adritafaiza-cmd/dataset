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

    localparam ADDR_WIDTH_1 = ADDR_WIDTH + 1;

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH_1:0] wptr, rptr;
    reg [ADDR_WIDTH_1:0] wptr_sync[0:SYNC_STAGES-1], rptr_sync[0:SYNC_STAGES-1];
    reg wfull_sync, rempty_sync;

    // Write process
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_sync <= 0;
        end else begin
            if (!wfull_sync && winc) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                if (wptr == (1<<ADDR_WIDTH)) begin
                    wptr <= 0;
                end
            end
            wfull_sync <= (wptr == rptr);
        end
    end

    // Read process
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_sync <= 1;
        end else begin
            if (!rempty_sync && rinc) begin
                rptr <= rptr + 1;
                if (rptr == (1<<ADDR_WIDTH)) begin
                    rptr <= 0;
                end
            end
            rempty_sync <= (rptr == wptr);
        end
    end

    // Synchronization registers
    generate
        generate
            genvar i;
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stages
                always @(posedge wclk or negedge wrst_n) begin
                    if (!wrst_n) begin
                        wptr_sync[i] <= 0;
                    end else begin
                        wptr_sync[i] <= wptr;
                    end
                end

                always @(posedge rclk or negedge rrst_n) begin
                    if (!rrst_n) begin
                        rptr_sync[i] <= 0;
                    end else begin
                        rptr_sync[i] <= rptr;
                    end
                end
            end
        endgenerate
    endgenerate

    // Output logic
    always @(posedge wclk or posedge rclk) begin
        wfull <= wfull_sync;
        rempty <= rempty_sync;
        waddr <= wptr_sync[SYNC_STAGES-1];
        raddr <= rptr_sync[SYNC_STAGES-1];
    end

    always @(posedge wclk) begin
        rdata <= mem[rptr_sync[SYNC_STAGES-1]];
    end

endmodule
