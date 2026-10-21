```systemverilog
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

    localparam INT_WIDTH = ADDR_WIDTH + 1;
    localparam FIFO_DEPTH = 2**ADDR_WIDTH;
    localparam GRANT_WIDTH = INT_WIDTH;

    // Generate sync stages
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stage
            wire [INT_WIDTH-1:0] sync_in;
            wire [INT_WIDTH-1:0] sync_out;
            wire [INT_WIDTH-1:0] sync_clk;
            wire [INT_WIDTH-1:0] sync_rst;

            assign sync_clk = (i % 2 == 0) ? wclk : rclk;
            assign sync_rst = (i % 2 == 0) ? wrst_n : rrst_n;

            always @(posedge sync_clk or negedge sync_rst) begin
                if (!sync_rst)
                    sync_out <= {1'b0, {INT_WIDTH-1{1'b0}}};
                else
                    sync_out <= sync_in;
            end

            assign sync_in = (i == SYNC_STAGES - 1) ? waddr : sync_out;
            assign waddr = (i == SYNC_STAGES - 1) ? waddr : sync_out;
        end
    endgenerate

    // Write pointer generation
    reg [INT_WIDTH-1:0] wptr;
    reg [INT_WIDTH-1:0] wptr_sync;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {1'b0, {INT_WIDTH-1{1'b0}}};
        else if (winc && !wfull)
            wptr <= wptr + 1;
    end

    // Read pointer generation
    reg [INT_WIDTH-1:0] rptr;
    reg [INT_WIDTH-1:0] rptr_sync;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {1'b0, {INT_WIDTH-1{1'b0}}};
        else if (rinc && !rempty)
            rptr <= rptr + 1;
    end

    // Data storage
    reg [DATA_WIDTH-1:0] mem[FIFO_DEPTH-1:0];

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 1'b0;
            rdata <= {DATA_WIDTH{1'b0}};
        end
        else if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wfull <= (wptr == {1'b1, {ADDR_WIDTH{1'b0}}});
        end
        else begin
            wfull <= 1'b0;
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= 1'b1;
            rdata <= {DATA_WIDTH{1'b0}};
        end
        else if (rinc && !rempty) begin
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
            rempty <= (rptr == {1'b0, {ADDR_WIDTH{1'b0}}});
        end
        else begin
            rempty <= 1'b0;
        end
    end

    // Cross-domain synchronization for full/empty signals
    // wfull is generated in write domain, needs to be read in read domain
    // rempty is generated in read domain, needs to be read in write domain

    // Sync wfull to read domain
    wire [INT_WIDTH-1:0] wfull_sync;
    reg [INT_WIDTH-1:0] wfull_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            wfull_reg <= 1'b0;
        else
            wfull_reg <= wfull;
    end

    // Sync rempty to write domain
    wire [INT_WIDTH-1:0] rempty_sync;
    reg [INT_WIDTH-1:0] rempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            rempty_reg <= 1'b1;
        else
            rempty_reg <= rempty;
    end

    // Final outputs after sufficient synchronization
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

    // Debug pointers
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
```<|im_end|>
