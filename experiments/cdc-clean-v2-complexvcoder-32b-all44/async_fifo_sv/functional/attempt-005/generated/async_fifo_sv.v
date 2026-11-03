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
    reg [ADDR_WIDTH:0] write_pointer;
    reg [ADDR_WIDTH:0] write_pointer_synced;
    reg [ADDR_WIDTH:0] read_pointer;
    reg [ADDR_WIDTH:0] read_pointer_synced;
    reg [DATA_WIDTH-1:0] fifo_memory [0:(2**ADDR_WIDTH)-1];
    reg write_enable;
    reg read_enable;
    reg fifo_full;
    reg fifo_empty;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_pointer <= 0;
            fifo_full <= 0;
        end else begin
            if (write_enable) begin
                fifo_memory[write_pointer[ADDR_WIDTH-1:0]] <= wdata;
                write_pointer <= write_pointer + 1;
            end
            fifo_full <= (write_pointer + 1) == read_pointer_synced;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer <= 0;
            fifo_empty <= 1;
        end else begin
            if (read_enable) begin
                read_pointer <= read_pointer + 1;
            end
            fifo_empty <= write_pointer_synced == read_pointer;
        end
    end

    // Write enable and read enable logic
    assign write_enable = winc && !fifo_full;
    assign read_enable = rinc && !fifo_empty;

    // FIFO full and empty signals
    assign wfull = fifo_full;
    assign rempty = fifo_empty;

    // Output read data
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (read_enable) begin
            rdata <= fifo_memory[read_pointer[ADDR_WIDTH-1:0]];
        end
    end

    // Address outputs for debug
    assign waddr = write_pointer;
    assign raddr = read_pointer;

    // Synchronization counters
    sync_counter #(.ADDR_WIDTH(ADDR_WIDTH)) write_pointer_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .data_in(write_pointer),
        .data_out(write_pointer_synced)
    );

    sync_counter #(.ADDR_WIDTH(ADDR_WIDTH)) read_pointer_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .data_in(read_pointer),
        .data_out(read_pointer_synced)
    );

endmodule

module sync_counter #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH:0]     data_in,
    output reg [ADDR_WIDTH:0]      data_out
);

    // Internal signals
    reg [ADDR_WIDTH:0] sync_stage_1;
    reg [ADDR_WIDTH:0] sync_stage_2;

    // Synchronization logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage_1 <= 0;
            sync_stage_2 <= 0;
            data_out <= 0;
        end else begin
            sync_stage_1 <= data_in;
            sync_stage_2 <= sync_stage_1;
            data_out <= sync_stage_2;
        end
    end

endmodule
