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
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] waddr_sync, raddr_sync;
    reg wfull_sync, rempty_sync;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wfull_sync <= 1'b0;
        end else begin
            if (!wfull_sync && winc) begin
                mem[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == DEPTH - 1)
                    wfull_sync <= 1'b1;
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rempty_sync <= 1'b1;
        end else begin
            if (!rempty_sync && rinc) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == DEPTH - 1)
                    rempty_sync <= 1'b0;
            end
        end
    end

    // Address outputs
    assign waddr = wr_ptr;
    assign raddr = rd_ptr;

    // Synchronize outputs to respective clock domains
    wire [ADDR_WIDTH:0] waddr_out, raddr_out;
    wire wfull_out, rempty_out;

    always @(posedge rclk) begin
        waddr_out <= waddr_sync;
        raddr_out <= raddr_sync;
        wfull_out <= wfull_sync;
        rempty_out <= rempty_sync;
    end

    always @(posedge wclk) begin
        waddr_sync <= waddr_out;
        raddr_sync <= raddr_out;
        wfull_sync <= wfull_out;
        rempty_sync <= rempty_out;
    end

    // Output assignment
    assign wfull = wfull_sync;
    assign rempty = rempty_sync;
    assign rdata = mem[rd_ptr];

endmodule
