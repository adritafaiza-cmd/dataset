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
    reg [ADDR_WIDTH-1:0] write_pointer;
    reg [ADDR_WIDTH-1:0] read_pointer;
    reg [DATA_WIDTH*2**ADDR_WIDTH-1:0] fifo_data;
    reg wfull_reg, rempty_reg;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_pointer <= 0;
        end else if (winc && !wfull_reg) begin
            write_pointer <= (write_pointer + 1) % (2**ADDR_WIDTH);
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer <= 0;
        end else if (rinc && !rempty_reg) begin
            read_pointer <= (read_pointer + 1) % (2**ADDR_WIDTH);
        end
    end

    // FIFO data storage
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            fifo_data <= 0;
        end else if (winc && !wfull_reg) begin
            fifo_data <= {fifo_data[DATA_WIDTH*2**ADDR_WIDTH-1:DATA_WIDTH*(write_pointer+1)], wdata};
        end
    end

    // Full and empty status logic
    assign wfull_reg = (write_pointer == (read_pointer - 1) % (2**ADDR_WIDTH));
    assign rempty_reg = (write_pointer == read_pointer);

    // Data path logic
    assign rdata = fifo_data[DATA_WIDTH*(read_pointer+1)-1:DATA_WIDTH*read_pointer];

    // Output ports
    assign wfull = wfull_reg;
    assign waddr = write_pointer;
    assign rempty = rempty_reg;
    assign raddr = read_pointer;

endmodule
