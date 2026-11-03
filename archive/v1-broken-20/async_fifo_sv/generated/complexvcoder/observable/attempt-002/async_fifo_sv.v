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
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rr_ptr;
    reg wfull_int;
    reg rempty_int;

    // Synchronization registers for write domain
    reg [DATA_WIDTH-1:0] sync_wdata[0:SYNC_STAGES-1];
    reg sync_wfull;
    reg sync_waddr;

    // Synchronization registers for read domain
    reg [DATA_WIDTH-1:0] sync_rdata;
    reg sync_rempty;
    reg sync_raddr;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wfull_int <= 0;
        end else begin
            if (winc && !wfull_int) begin
                mem[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == 2**ADDR_WIDTH - 1)
                    wfull_int <= 1;
            end
        end
    end

    // Generate sync_wdata and sync_wfull
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_wdata_gen
            assign sync_wdata[i] = sync_wdata[i-1];
        end
        assign sync_wdata[0] = wdata;
        assign sync_wfull = sync_wdata[SYNC_STAGES-1];
    endgenerate

    // Generate sync_waddr
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_waddr_gen
            assign sync_waddr = sync_waddr;
        end
    endgenerate

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rr_ptr <= 0;
            rempty_int <= 1;
        end else begin
            if (rinc && !rempty_int) begin
                rr_ptr <= rr_ptr + 1;
                if (rr_ptr == 2**ADDR_WIDTH)
                    rempty_int <= 0;
            end
        end
    end

    // Generate sync_rdata
    always @(posedge rclk) begin
        sync_rdata <= mem[rr_ptr];
    end

    // Generate sync_rempty
    assign sync_rempty = rempty_int;

    // Generate sync_raddr
    always @(posedge rclk) begin
        sync_raddr <= rr_ptr;
    end

    // Output assignments
    assign wfull = sync_wfull;
    assign waddr = sync_waddr;
    assign rdata = sync_rdata;
    assign rempty = sync_rempty;
    assign raddr = sync_raddr;

endmodule
