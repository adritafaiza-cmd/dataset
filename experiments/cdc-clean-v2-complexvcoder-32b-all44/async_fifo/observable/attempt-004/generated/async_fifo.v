module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    // Internal signals
    wire [ASIZE-1:0] w_gray, r_gray;
    wire [ASIZE-1:0] w_bin, r_bin;
    wire [ASIZE-1:0] w_gray_sync, w_gray_sync2, w_gray_sync3;
    wire [ASIZE-1:0] r_gray_sync, r_gray_sync2, r_gray_sync3;
    wire [ASIZE-1:0] w_ptr_gray_sync3, r_ptr_gray_sync3;
    wire [ASIZE-1:0] w_ptr_bin, r_ptr_bin;
    wire w_full, w_a_full, r_empty, r_a_empty;

    // Gray counters for write and read pointers
    gray_counter w_gray_counter (
        .clk   (wclk),
        .rst_n (wrst_n),
        .inc   (winc),
        .gray  (w_gray)
    );

    gray_counter r_gray_counter (
        .clk   (rclk),
        .rst_n (rrst_n),
        .inc   (rinc),
        .gray  (r_gray)
    );

    // Binary counters for write and read pointers
    binary_counter w_bin_counter (
        .clk   (wclk),
        .rst_n (wrst_n),
        .inc   (winc),
        .bin   (w_bin)
    );

    binary_counter r_bin_counter (
        .clk   (rclk),
        .rst_n (rrst_n),
        .inc   (rinc),
        .bin   (r_bin)
    );

    // Memory module
    memory fifo_memory (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .waddr  (w_bin),
        .din    (wdata),
        .wen    (winc),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .raddr  (r_bin),
        .dout   (rdata)
    );

    // Synchronize write Gray pointer to read clock domain
    sync_gray_to_bin w_gray_sync_chain (
        .clk       (rclk),
        .rst_n     (rrst_n),
        .gray_in   (w_gray),
        .gray_sync (w_gray_sync3)
    );

    // Synchronize read Gray pointer to write clock domain
    sync_gray_to_bin r_gray_sync_chain (
        .clk       (wclk),
        .rst_n     (wrst_n),
        .gray_in   (r_gray),
        .gray_sync (r_gray_sync3)
    );

    // Convert synchronized Gray pointers to binary
    gray_to_bin w_gray_to_bin (
        .gray (w_gray_sync3),
        .bin  (w_ptr_bin)
    );

    gray_to_bin r_gray_to_bin (
        .gray (r_gray_sync3),
        .bin  (r_ptr_bin)
    );

    // Calculate full and almost full flags
    assign w_full = (w_ptr_bin == (r_ptr_bin + 1) % (1 << ASIZE)) || (w_ptr_bin == r_ptr_bin && winc && !rinc);
    assign w_a_full = (w_ptr_bin == (r_ptr_bin + 2) % (1 << ASIZE)) || (w_ptr_bin == r_ptr_bin && winc && !rinc);

    // Calculate empty and almost empty flags
    assign r_empty = (w_ptr_bin == r_ptr_bin) && !winc && rinc;
    assign r_a_empty = (w_ptr_bin == r_ptr_bin) && !winc && rinc;

    // Outputs
    assign wfull = w_full;
    assign awfull = w_a_full;
    assign rempty = r_empty;
    assign arempty = r_a_empty;

endmodule

module gray_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [ASIZE-1:0] gray
);

    reg [ASIZE-1:0] gray_reg;
    reg [ASIZE-1:0] gray_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg <= 0;
        end else begin
            gray_reg <= gray_next;
        end
    end

    always @(*) begin
        gray_next = gray_reg + inc;
        gray = gray_next ^ (gray_next >> 1);
    end

endmodule

module binary_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [ASIZE-1:0] bin
);

    reg [ASIZE-1:0] bin_reg;
    reg [ASIZE-1:0] bin_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_reg <= 0;
        end else begin
            bin_reg <= bin_next;
        end
    end

    always @(*) begin
        bin_next = bin_reg + inc;
        bin = bin_next;
    end

endmodule

module memory (
    input  wire wclk,
    input  wire wrst_n,
    input  wire [ASIZE-1:0] waddr,
    input  wire [DSIZE-1:0] din,
    input  wire wen,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [ASIZE-1:0] raddr,
    output wire [DSIZE-1:0] dout
);

    reg [DSIZE-1:0] mem [0:(1 << ASIZE) - 1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            // Initialize memory
            integer i;
            for (i = 0; i < (1 << ASIZE); i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (wen) begin
            mem[waddr] <= din;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            dout <= 0;
        end else begin
            dout <= mem[raddr];
        end
    end

endmodule

module sync_gray_to_bin (
    input  wire clk,
    input  wire rst_n,
    input  wire [ASIZE-1:0] gray_in,
    output wire [ASIZE-1:0] gray_sync
);

    reg [ASIZE-1:0] sync_reg1;
    reg [ASIZE-1:0] sync_reg2;
    reg [ASIZE-1:0] sync_reg3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
            sync_reg3 <= 0;
        end else begin
            sync_reg1 <= gray_in;
            sync_reg2 <= sync_reg1;
            sync_reg3 <= sync_reg2;
        end
    end

    assign gray_sync = sync_reg3;

endmodule

module gray_to_bin (
    input  wire [ASIZE-1:0] gray,
    output wire [ASIZE-1:0] bin
);

    reg [ASIZE-1:0] bin_reg;

    always @(*) begin
        bin_reg = gray;
        for (integer i = ASIZE - 1; i > 0; i = i - 1) begin
            bin_reg[i] = bin_reg[i] ^ bin_reg[i-1];
        end
        bin = bin_reg;
    end

endmodule
