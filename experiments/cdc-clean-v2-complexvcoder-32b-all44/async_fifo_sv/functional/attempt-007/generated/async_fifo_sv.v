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
    wire [ADDR_WIDTH:0] w_gray_addr;
    wire [ADDR_WIDTH:0] r_gray_addr;
    wire [ADDR_WIDTH:0] w_bin_addr;
    wire [ADDR_WIDTH:0] r_bin_addr;
    wire [ADDR_WIDTH:0] w_gray_addr_synced;
    wire [ADDR_WIDTH:0] r_gray_addr_synced;
    wire [ADDR_WIDTH:0] w_bin_addr_synced;
    wire [ADDR_WIDTH:0] r_bin_addr_synced;

    // Write domain
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) w_gray_counter (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .en       (winc),
        .gray_out (w_gray_addr)
    );

    gray_to_binary #(.WIDTH(ADDR_WIDTH+1)) w_gray_to_bin (
        .gray_in  (w_gray_addr),
        .binary_out(w_bin_addr)
    );

    binary_to_gray #(.WIDTH(ADDR_WIDTH+1)) w_bin_to_gray (
        .binary_in(w_bin_addr),
        .gray_out (w_gray_addr)
    );

    // Read domain
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) r_gray_counter (
        .clk      (rclk),
        .rst_n    (rrst_n),
        .en       (rinc),
        .gray_out (r_gray_addr)
    );

    gray_to_binary #(.WIDTH(ADDR_WIDTH+1)) r_gray_to_bin (
        .gray_in  (r_gray_addr),
        .binary_out(r_bin_addr)
    );

    binary_to_gray #(.WIDTH(ADDR_WIDTH+1)) r_bin_to_gray (
        .binary_in(r_bin_addr),
        .gray_out (r_gray_addr)
    );

    // Synchronization
    sync_register #(.WIDTH(ADDR_WIDTH+1), .SYNC_STAGES(SYNC_STAGES)) w_gray_addr_sync (
        .clk      (rclk),
        .rst_n    (rrst_n),
        .data_in  (w_gray_addr),
        .data_out (w_gray_addr_synced)
    );

    sync_register #(.WIDTH(ADDR_WIDTH+1), .SYNC_STAGES(SYNC_STAGES)) r_gray_addr_sync (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .data_in  (r_gray_addr),
        .data_out (r_gray_addr_synced)
    );

    gray_to_binary #(.WIDTH(ADDR_WIDTH+1)) w_gray_sync_to_bin (
        .gray_in  (w_gray_addr_synced),
        .binary_out(w_bin_addr_synced)
    );

    gray_to_binary #(.WIDTH(ADDR_WIDTH+1)) r_gray_sync_to_bin (
        .gray_in  (r_gray_addr_synced),
        .binary_out(r_bin_addr_synced)
    );

    // Memory
    memory #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH+1)) fifo_memory (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .we       (winc),
        .addr     (w_bin_addr),
        .din      (wdata),
        .dout     (rdata)
    );

    // Full and Empty flags
    assign wfull = (w_bin_addr == {~r_bin_addr_synced[ADDR_WIDTH], r_bin_addr_synced[ADDR_WIDTH-1:0]});
    assign rempty = (r_bin_addr == {~w_bin_addr_synced[ADDR_WIDTH], w_bin_addr_synced[ADDR_WIDTH-1:0]});

    // Debug address outputs
    assign waddr = w_bin_addr;
    assign raddr = r_bin_addr;

endmodule

module gray_counter #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    output wire [WIDTH-1:0] gray_out
);

    reg [WIDTH-1:0] gray_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_count <= 0;
        end else if (en) begin
            gray_count <= gray_count + 1;
        end
    end

    assign gray_out = (gray_count >> 1) ^ gray_count;

endmodule

module binary_to_gray #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] binary_in,
    output wire [WIDTH-1:0] gray_out
);

    assign gray_out = (binary_in >> 1) ^ binary_in;

endmodule

module gray_to_binary #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] gray_in,
    output wire [WIDTH-1:0] binary_out
);

    reg [WIDTH-1:0] binary;

    always @(*) begin
        binary = gray_in;
        for (int i = WIDTH-2; i >= 0; i = i - 1) begin
            binary[i] = binary[i+1] ^ gray_in[i];
        end
    end

    assign binary_out = binary;

endmodule

module sync_register #(
    parameter WIDTH = 5,
    parameter SYNC_STAGES = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= 0;
            end
        end else begin
            sync_reg[0] <= data_in;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign data_out = sync_reg[SYNC_STAGES-1];

endmodule

module memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (we) begin
            mem[addr] <= din;
        end
    end

    assign dout = mem[addr];

endmodule
