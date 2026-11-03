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

    localparam FIFO_SIZE = 2**ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem[FIFO_SIZE-1:0];
    reg [ADDR_WIDTH:0] wp, rp;
    reg wfull_reg, rempty_reg;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wp <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                wp <= wp + 1;
            end
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rp <= 0;
        end else begin
            if (rinc && !rempty_reg) begin
                rp <= rp + 1;
            end
        end
    end

    // FIFO full and empty logic
    assign wfull = (wp + 1 == rp) || (wp + 1 == FIFO_SIZE);
    assign rempty = wp == rp;

    // Debug pointer outputs
    assign waddr = wp;
    assign raddr = rp;

    // Write data logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            // Do nothing
        end else begin
            if (winc && !wfull_reg) begin
                mem[wp] <= wdata;
            end
        end
    end

    // Read data logic
    assign rdata = mem[rp];

    // Register outputs for asynchronous read
    reg [DATA_WIDTH-1:0] rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else begin
            rdata_reg <= rdata;
        end
    end

    assign rdata = rdata_reg;

endmodule
