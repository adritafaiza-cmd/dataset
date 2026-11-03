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
    wire [ASIZE:0] w_gray_count;
    wire [ASIZE:0] r_gray_count;
    wire [ASIZE-1:0] w_bin_count;
    wire [ASIZE-1:0] r_bin_count;
    reg [ASIZE:0] w_gray_sync;
    reg [ASIZE:0] r_gray_sync;
    reg [ASIZE-1:0] w_gray_sync_bin;
    reg [ASIZE-1:0] r_gray_sync_bin;
    reg w_full_flag;
    reg r_empty_flag;

    // Helper modules
    gray_counter w_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .count(w_gray_count)
    );

    gray_counter r_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .count(r_gray_count)
    );

    binary_counter w_bin_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .count(w_bin_count)
    );

    binary_counter r_bin_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .count(r_bin_count)
    );

    dual_port_ram fifo_memory (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .waddr(w_bin_count),
        .wdata(wdata),
        .wen(winc),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(r_bin_count),
        .rdata(rdata)
    );

    // Synchronize read gray count to write clock domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            w_gray_sync <= 0;
        end else begin
            w_gray_sync <= r_gray_count;
        end
    end

    // Synchronize write gray count to read clock domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            r_gray_sync <= 0;
        end else begin
            r_gray_sync <= w_gray_count;
        end
    end

    // Convert synchronized gray counts to binary
    always @(*) begin
        w_gray_sync_bin = gray_to_bin(w_gray_sync);
        r_gray_sync_bin = gray_to_bin(r_gray_sync);
    end

    // Full and empty flags logic
    always @(*) begin
        w_full_flag = (w_gray_sync_bin + 1) % (2**ASIZE) == w_bin_count;
        r_empty_flag = w_gray_sync_bin == r_bin_count;
        awfull = (w_gray_sync_bin + 2) % (2**ASIZE) == w_bin_count;
        arempty = (w_gray_sync_bin + 1) % (2**ASIZE) == r_bin_count;
    end

    // Gray to binary conversion function
    function [ASIZE-1:0] gray_to_bin;
        input [ASIZE:0] gray;
        reg [ASIZE-1:0] bin;
        integer i;
        begin
            bin = gray[ASIZE];
            for (i = ASIZE - 1; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            gray_to_bin = bin;
        end
    endfunction

    // Assign full and empty flags
    assign wfull = w_full_flag;
    assign rempty = r_empty_flag;

endmodule

module gray_counter (
    input wire clk,
    input wire rst_n,
    input wire inc,
    output reg [ASIZE:0] count
);

    reg [ASIZE:0] count_reg;
    reg [ASIZE:0] count_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= 0;
        end else begin
            count_reg <= count_next;
        end
    end

    always @(*) begin
        if (inc) begin
            count_next = gray_next(count_reg);
        end else begin
            count_next = count_reg;
        end
    end

    // Gray code increment function
    function [ASIZE:0] gray_next;
        input [ASIZE:0] gray;
        reg [ASIZE:0] next_gray;
        begin
            next_gray = gray + 1;
            next_gray = (next_gray & ~gray) | (~next_gray & gray);
            gray_next = next_gray;
        end
    endfunction

    assign count = count_reg;

endmodule

module binary_counter (
    input wire clk,
    input wire rst_n,
    input wire inc,
    output reg [ASIZE-1:0] count
);

    reg [ASIZE-1:0] count_reg;
    reg [ASIZE-1:0] count_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= 0;
        end else begin
            count_reg <= count_next;
        end
    end

    always @(*) begin
        if (inc) begin
            count_next = count_reg + 1;
        end else begin
            count_next = count_reg;
        end
    end

    assign count = count_reg;

endmodule

module dual_port_ram (
    input wire wclk,
    input wire wrst_n,
    input wire [ASIZE-1:0] waddr,
    input wire [DSIZE-1:0] wdata,
    input wire wen,
    input wire rclk,
    input wire rrst_n,
    input wire [ASIZE-1:0] raddr,
    output reg [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] mem [0:(2**ASIZE)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (integer i = 0; i < 2**ASIZE; i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (wen) begin
            mem[waddr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            rdata <= mem[raddr];
        end
    end

endmodule
