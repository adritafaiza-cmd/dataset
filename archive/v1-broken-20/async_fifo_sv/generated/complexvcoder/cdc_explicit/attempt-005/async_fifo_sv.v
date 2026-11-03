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
    logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    logic [ADDR_WIDTH-1:0] wptr, rptr;
    logic [ADDR_WIDTH:0] waddr_sync, raddr_sync;
    logic wfull_sync, rempty_sync;

    // Write control logic
    assign waddr = waddr_sync;
    assign wfull = wfull_sync;

    // Read control logic
    assign raddr = raddr_sync;
    assign rempty = rempty_sync;

    // FIFO core logic
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_sync <= 1'b0;
        end else begin
            if (winc && !wfull_sync) begin
                mem[wptr] <= wdata;
                wptr <= (wptr + 1) % (2**ADDR_WIDTH);
                wfull_sync <= (wptr == rptr);
            end
        end
    end

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_sync <= 1'b1;
        end else begin
            if (rinc && !rempty_sync) begin
                rptr <= (rptr + 1) % (2**ADDR_WIDTH);
                rempty_sync <= (wptr == rptr);
            end
        end
    end

    // Address synchronization
    cdc_sync #(.WIDTH(ADDR_WIDTH)) waddr_sync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .data(wptr),
        .sync_data(waddr_sync)
    );

    cdc_sync #(.WIDTH(ADDR_WIDTH)) raddr_sync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .data(rptr),
        .sync_data(raddr_sync)
    );

    // Full and empty flags synchronization
    cdc_sync #(.WIDTH(1)) wfull_sync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .data(wfull_sync),
        .sync_data(wfull_sync)
    );

    cdc_sync #(.WIDTH(1)) rempty_sync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .data(rempty_sync),
        .sync_data(rempty_sync)
    );

    // Read data logic
    assign rdata = mem[rptr];

endmodule

module cdc_sync #(
    parameter WIDTH = 1
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [WIDTH-1:0]        data,
    output wire [WIDTH-1:0]        sync_data
);

    logic [WIDTH-1:0] sync_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= data;
        end
    end

    assign sync_data = sync_reg;

endmodule
