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

    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg wfull_reg, rempty_reg;

    // Write side
    wire wclk_synced;
    wire wrst_n_synced;

    sync_reset write_reset_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .synced_rst_n(wrst_n_synced)
    );

    always @(posedge wclk or negedge wrst_n_synced) begin
        if (!wrst_n_synced) begin
            wptr <= 0;
            wfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                wfull_reg <= (wptr == rptr);
            end
        end
    end

    // Read side
    wire rclk_synced;
    wire rrst_n_synced;

    sync_reset read_reset_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .synced_rst_n(rrst_n_synced)
    );

    always @(posedge rclk or negedge rrst_n_synced) begin
        if (!rrst_n_synced) begin
            rptr <= 0;
            rempty_reg <= 1;
        end else begin
            if (rinc && !rempty_reg) begin
                rptr <= rptr + 1;
                rempty_reg <= (rptr == wptr);
            end
        end
    end

    // Output logic
    assign waddr = wptr;
    assign raddr = rptr;
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;
    assign rdata = rempty_reg ? 0 : mem[rptr];

endmodule

module sync_reset (
    input  wire                    clk,
    input  wire                    rst_n,
    output wire                    synced_rst_n
);

    reg [SYNC_STAGES-1:0] synced_rst_n_reg;

    always @(posedge clk) begin
        synced_rst_n_reg <= {rst_n, synced_rst_n_reg[SYNC_STAGES-2:0]};
    end

    assign synced_rst_n = synced_rst_n_reg[SYNC_STAGES-1];

endmodule
