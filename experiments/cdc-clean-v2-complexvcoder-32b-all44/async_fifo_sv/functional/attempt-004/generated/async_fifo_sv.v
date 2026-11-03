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

    wire [ADDR_WIDTH:0] w_gray_ptr;
    wire [ADDR_WIDTH:0] r_gray_ptr;
    wire [ADDR_WIDTH:0] w_bin_ptr;
    wire [ADDR_WIDTH:0] r_bin_ptr;
    wire rd;
    wire [DATA_WIDTH-1:0] fifo_dout;
    wire fifo_empty;

    // Gray code counters
    gray_counter #(.ADDR_WIDTH(ADDR_WIDTH)) gray_wptr (
        .clk       (wclk),
        .rst_n     (wrst_n),
        .inc       (winc),
        .gray_code (w_gray_ptr)
    );

    gray_counter #(.ADDR_WIDTH(ADDR_WIDTH)) gray_rptr (
        .clk       (rclk),
        .rst_n     (rrst_n),
        .inc       (rinc),
        .gray_code (r_gray_ptr)
    );

    // Gray to binary converters
    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH)) bin_wptr (
        .gray_code (w_gray_ptr),
        .bin_code  (w_bin_ptr)
    );

    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH)) bin_rptr (
        .gray_code (r_gray_ptr),
        .bin_code  (r_bin_ptr)
    );

    // Synchronous FIFO core
    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) fifo_core (
        .clk     (wclk),
        .rst_n   (wrst_n),
        .din     (wdata),
        .wr      (winc),
        .rd      (rd),
        .dout    (fifo_dout),
        .full    (wfull),
        .empty   (fifo_empty)
    );

    // Synchronize read signal to write domain
    sync_signal #(.SYNC_STAGES(SYNC_STAGES)) sync_rd (
        .clk_in      (rclk),
        .clk_out     (wclk),
        .rst_n       (wrst_n),
        .async_signal(rinc),
        .sync_signal (rd)
    );

    // Synchronize empty signal to read domain
    sync_signal #(.SYNC_STAGES(SYNC_STAGES)) sync_empty (
        .clk_in      (wclk),
        .clk_out     (rclk),
        .rst_n       (rrst_n),
        .async_signal(fifo_empty),
        .sync_signal (rempty)
    );

    // Assign outputs
    assign waddr = w_bin_ptr;
    assign raddr = r_bin_ptr;
    assign rdata = fifo_dout;

endmodule

module gray_counter #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    inc,
    output wire [ADDR_WIDTH:0]     gray_code
);

    reg [ADDR_WIDTH:0] gray_reg;
    wire [ADDR_WIDTH:0] next_gray;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gray_reg <= 0;
        else if (inc)
            gray_reg <= next_gray;
    end

    assign next_gray = (gray_reg << 1) ^ (gray_reg >> (ADDR_WIDTH - 1));

    assign gray_code = gray_reg;

endmodule

module gray_to_bin #(
    parameter ADDR_WIDTH = 4
)(
    input  wire [ADDR_WIDTH:0]     gray_code,
    output wire [ADDR_WIDTH:0]     bin_code
);

    wire [ADDR_WIDTH:0] gray_code_rev;
    genvar i;

    // Reverse the gray_code for easier conversion
    generate
        for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : gen_reverse
            assign gray_code_rev[i] = gray_code[ADDR_WIDTH - i];
        end
    endgenerate

    wire [ADDR_WIDTH:0] bin_code_int;
    assign bin_code_int[0] = gray_code_rev[0];

    genvar j;
    generate
        for (j = 1; j <= ADDR_WIDTH; j = j + 1) begin : gen_bin_convert
            assign bin_code_int[j] = bin_code_int[j - 1] ^ gray_code_rev[j];
        end
    endgenerate

    // Reverse the bin_code_int to get the final binary code
    generate
        for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : gen_reverse_bin
            assign bin_code[i] = bin_code_int[ADDR_WIDTH - i];
        end
    endgenerate

endmodule

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [DATA_WIDTH-1:0]   din,
    input  wire                    wr,
    input  wire                    rd,
    output wire [DATA_WIDTH-1:0]   dout,
    output wire                    full,
    output wire                    empty
);

    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg full_reg;
    reg empty_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full_reg <= 0;
            empty_reg <= 1;
        end else begin
            if (wr && !full_reg) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr[ADDR_WIDTH:0] == {~rd_ptr[ADDR_WIDTH], rd_ptr[ADDR_WIDTH-1:0]})
                    full_reg <= 1;
                if (empty_reg)
                    empty_reg <= 0;
            end
            if (rd && !empty_reg) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr[ADDR_WIDTH:0] == wr_ptr[ADDR_WIDTH:0])
                    empty_reg <= 1;
                if (full_reg)
                    full_reg <= 0;
            end
        end
    end

    assign dout = mem[rd_ptr[ADDR_WIDTH-1:0]];
    assign full = full_reg;
    assign empty = empty_reg;

endmodule

module sync_signal #(
    parameter SYNC_STAGES = 2
)(
    input  wire clk_in,
    input  wire clk_out,
    input  wire rst_n,
    input  wire async_signal,
    output wire sync_signal
);

    reg [SYNC_STAGES-1:0] sync_chain;

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            sync_chain[0] <= 0;
        else
            sync_chain[0] <= async_signal;
    end

    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n)
            sync_chain[SYNC_STAGES-1:1] <= 0;
        else
            sync_chain[SYNC_STAGES-1:1] <= sync_chain[SYNC_STAGES-2:0];
    end

    assign sync_signal = sync_chain[SYNC_STAGES-1];

endmodule
