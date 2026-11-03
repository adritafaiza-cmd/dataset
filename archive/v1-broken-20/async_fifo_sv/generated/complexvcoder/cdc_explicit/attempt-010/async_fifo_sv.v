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

    localparam FIFO_DEPTH = 2**ADDR_WIDTH;

    // Internal signals
    logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    logic [ADDR_WIDTH-1:0] wptr, rptr;
    logic wptr_inc, rptr_inc;
    logic [ADDR_WIDTH:0] wptr_reg, rptr_reg;
    logic [DATA_WIDTH-1:0] wdata_reg, rdata_reg;
    logic wfull_reg, rempty_reg;

    // Write logic
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_reg <= 1'b0;
        end else begin
            wptr_inc = winc && !wfull_reg;
            if (wptr_inc) begin
                wptr <= (wptr + 1) % FIFO_DEPTH;
                wfull_reg <= (wptr + 1) == rptr;
            end
        end
    end

    // Read logic
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_reg <= 1'b1;
        end else begin
            rptr_inc = rinc && !rempty_reg;
            if (rptr_inc) begin
                rptr <= (rptr + 1) % FIFO_DEPTH;
                rempty_reg <= wptr == rptr;
            end
        end
    end

    // Output logic
    assign waddr = wptr_reg;
    assign raddr = rptr_reg;
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;
    assign rdata = rdata_reg;

    // Address register for write domain
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_reg <= 0;
        end else begin
            wptr_reg <= wptr;
        end
    end

    // Address register for read domain
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_reg <= 0;
        end else begin
            rptr_reg <= rptr;
        end
    end

    // Data register for write domain
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wdata_reg <= 0;
        end else if (wptr_inc) begin
            wdata_reg <= wdata;
        end
    end

    // Data register for read domain
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else if (rptr_inc) begin
            rdata_reg <= mem[rptr];
        end
    end

endmodule
