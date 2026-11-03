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

    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;
    localparam ADDR_WIDTH-sync = ADDR_WIDTH - SYNC_STAGES;

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-sync-1:0] wptr;
    reg [ADDR_WIDTH-sync-1:0] rptr;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg wfull_reg;
    reg rempty_reg;

    reg [DATA_WIDTH-1:0] wfull_sync;
    reg [ADDR_WIDTH-sync-1:0] waddr_sync;
    reg [DATA_WIDTH-1:0] rempty_sync;
    reg [ADDR_WIDTH-sync-1:0] raddr_sync;

    // FIFO core logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            rptr <= 0;
            wfull_reg <= 0;
            rempty_reg <= 1;
        end else begin
            if (!wfull_reg && winc) begin
                mem[wptr] <= wdata;
                wptr <= (wptr + 1) % FIFO_DEPTH;
                if (wptr == rptr) begin
                    wfull_reg <= 1;
                end
            end
            if (!rempty_reg && rinc) begin
                rptr <= (rptr + 1) % FIFO_DEPTH;
                if (wptr == rptr) begin
                    rempty_reg <= 1;
                end
            end
        end
    end

    // Write clock domain crossing
    cdc_sync #(
        .WIDTH(DATA_WIDTH),
        .STAGES(SYNC_STAGES)
    ) wcdc (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wfull_reg),
        .dout(wfull_sync)
    );

    cdc_sync #(
        .WIDTH(ADDR_WIDTH-sync),
        .STAGES(SYNC_STAGES)
    ) wcdc_addr (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr),
        .dout(waddr_sync)
    );

    // Read clock domain crossing
    cdc_sync #(
        .WIDTH(DATA_WIDTH),
        .STAGES(SYNC_STAGES)
    ) rcdc (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rempty_reg),
        .dout(rempty_sync)
    );

    cdc_sync #(
        .WIDTH(ADDR_WIDTH-sync),
        .STAGES(SYNC_STAGES)
    ) rcdc_addr (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr),
        .dout(raddr_sync)
    );

    // Output logic
    assign wfull = wfull_sync;
    assign waddr = {waddr_sync, 1'b0};
    assign rdata = rdata_reg;
    assign rempty = rempty_sync;
    assign raddr = {raddr_sync, 1'b0};

    // Data output register
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else begin
            if (!rempty_reg && rinc) begin
                rdata_reg <= mem[rptr];
            end
        end
    end

endmodule

module cdc_sync #(
    parameter WIDTH = 1,
    parameter STAGES = 2
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [WIDTH-1:0]        din,
    output wire [WIDTH-1:0]        dout
);

    reg [WIDTH-1:0] shift_reg [0:STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {WIDTH{1'b0}};
        end else begin
            shift_reg <= {shift_reg[STAGES-2:0], din};
        end
    end

    assign dout = shift_reg[STAGES-1];

endmodule
