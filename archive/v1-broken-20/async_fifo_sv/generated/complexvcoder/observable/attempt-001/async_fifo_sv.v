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

    reg [DATA_WIDTH-1:0] fifo_memory [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH:0] write_pointer;
    reg [ADDR_WIDTH:0] read_pointer;

    wire [ADDR_WIDTH:0] write_pointer_sync_out;
    wire [ADDR_WIDTH:0] read_pointer_sync_out;

    // Synchronize write pointer across clock domains
    sync_reg #(.WIDTH(ADDR_WIDTH+1)) write_pointer_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .data_in({winc, write_pointer}),
        .data_out(write_pointer_sync_out)
    );

    // Synchronize read pointer across clock domains
    sync_reg #(.WIDTH(ADDR_WIDTH+1)) read_pointer_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .data_in({rinc, read_pointer}),
        .data_out(read_pointer_sync_out)
    );

    // FIFO buffer
    assign waddr = write_pointer_sync_out[ADDR_WIDTH:1];
    assign raddr = read_pointer_sync_out[ADDR_WIDTH:1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_pointer <= 0;
        end else if (winc && !wfull) begin
            fifo_memory[write_pointer] <= wdata;
            write_pointer <= (write_pointer + 1) % FIFO_DEPTH;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer <= 0;
        end else if (rinc && !rempty) begin
            read_pointer <= (read_pointer + 1) % FIFO_DEPTH;
        end
    end

    assign wfull = (write_pointer == read_pointer) && winc;
    assign rempty = (write_pointer == read_pointer) && rinc;

    assign rdata = fifo_memory[read_pointer_sync_out[ADDR_WIDTH:1]];

endmodule

module sync_reg #(
    parameter WIDTH = 1
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [WIDTH-1:0]        data_in,
    output wire [WIDTH-1:0]        data_out
);

    reg [WIDTH-1:0] dff;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dff <= 0;
        end else begin
            dff <= data_in;
        end
    end

    assign data_out = dff;

endmodule
