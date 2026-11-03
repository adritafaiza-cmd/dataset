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

    wire [ADDR_WIDTH:0] write_pointer;
    wire [ADDR_WIDTH:0] write_pointer_next;
    wire [ADDR_WIDTH:0] read_pointer;
    wire [ADDR_WIDTH:0] read_pointer_next;
    wire [ADDR_WIDTH:0] read_pointer_synced;
    wire [ADDR_WIDTH:0] write_pointer_synced;
    wire wfull_flag;
    wire rempty_flag;

    // Write Pointer Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_pointer <= 0;
        end else if (winc && !wfull_flag) begin
            write_pointer <= write_pointer_next;
        end
    end

    assign write_pointer_next = (write_pointer == (2**(ADDR_WIDTH+1) - 1)) ? 0 : write_pointer + 1;
    assign waddr = write_pointer;

    // Read Pointer Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer <= 0;
        end else if (rinc && !rempty_flag) begin
            read_pointer <= read_pointer_next;
        end
    end

    assign read_pointer_next = (read_pointer == (2**(ADDR_WIDTH+1) - 1)) ? 0 : read_pointer + 1;
    assign raddr = read_pointer;

    // Full and Empty Flags
    assign wfull_flag = (write_pointer_next == read_pointer_synced);
    assign rempty_flag = (write_pointer_synced == read_pointer);

    assign wfull = wfull_flag;
    assign rempty = rempty_flag;

    // Synchronization Registers
    sync_register #(
        .DATA_WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) write_pointer_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(write_pointer),
        .dout(write_pointer_synced)
    );

    sync_register #(
        .DATA_WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) read_pointer_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(read_pointer),
        .dout(read_pointer_synced)
    );

    // Dual-port RAM
    dual_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_memory (
        .clk_a(wclk),
        .rst_a_n(wrst_n),
        .we_a(winc && !wfull_flag),
        .addr_a(write_pointer[ADDR_WIDTH-1:0]),
        .din_a(wdata),
        .clk_b(rclk),
        .rst_b_n(rrst_n),
        .addr_b(read_pointer_synced[ADDR_WIDTH-1:0]),
        .dout_b(rdata)
    );

endmodule

module sync_register #(
    parameter DATA_WIDTH = 1,
    parameter SYNC_STAGES = 2
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [DATA_WIDTH-1:0]   din,
    output wire [DATA_WIDTH-1:0]   dout
);

    reg [DATA_WIDTH-1:0] sync_stages [SYNC_STAGES-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stages <= 0;
        end else begin
            sync_stages[0] <= din;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
        end
    end

    assign dout = sync_stages[SYNC_STAGES-1];

endmodule

module dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk_a,
    input  wire                    rst_a_n,
    input  wire                    we_a,
    input  wire [ADDR_WIDTH-1:0]   addr_a,
    input  wire [DATA_WIDTH-1:0]   din_a,
    input  wire                    clk_b,
    input  wire                    rst_b_n,
    input  wire [ADDR_WIDTH-1:0]   addr_b,
    output wire [DATA_WIDTH-1:0]   dout_b
);

    reg [DATA_WIDTH-1:0] memory [2**(ADDR_WIDTH)-1:0];

    always @(posedge clk_a or negedge rst_a_n) begin
        if (!rst_a_n) begin
            memory <= 0;
        end else if (we_a) begin
            memory[addr_a] <= din_a;
        end
    end

    always @(posedge clk_b or negedge rst_b_n) begin
        if (!rst_b_n) begin
            dout_b <= 0;
        end else begin
            dout_b <= memory[addr_b];
        end
    end

endmodule
