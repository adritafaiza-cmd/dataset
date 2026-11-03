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

    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH:0]   wptr_sync;
    reg [ADDR_WIDTH:0]   rptr_sync;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] rdata_reg;

    assign wfull = (wptr == rptr_sync[ADDR_WIDTH-1:0]) && (wptr_sync[ADDR_WIDTH] == 1'b1);
    assign rempty = (wptr_sync[ADDR_WIDTH-1:0] == rptr) && (rptr_sync[ADDR_WIDTH] == 1'b0);
    assign waddr = {1'b0, wptr};
    assign raddr = {1'b0, rptr};

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= '0;
        end else if (winc &&!wfull) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1'b1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= '0;
            rdata_reg <= '0;
        end else if (rinc &&!rempty) begin
            rdata_reg <= mem[rptr];
            rptr <= rptr + 1'b1;
        end
    end

    assign rdata = rdata_reg;

    // Synchronize wptr to read clock domain
    reg [SYNC_STAGES-1:0] wptr_sync_reg;
    always @(posedge rclk) begin
        wptr_sync_reg[0] <= wptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync_reg[i] <= wptr_sync_reg[i-1];
        end
        wptr_sync <= {wptr_sync_reg[SYNC_STAGES-1], wptr_sync_reg[SYNC_STAGES-2]};
    end

    // Synchronize rptr to write clock domain
    reg [SYNC_STAGES-1:0] rptr_sync_reg;
    always @(posedge wclk) begin
        rptr_sync_reg[0] <= rptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync_reg[i] <= rptr_sync_reg[i-1];
        end
        rptr_sync <= {rptr_sync_reg[SYNC_STAGES-1], rptr_sync_reg[SYNC_STAGES-2]};
    end

endmodule
