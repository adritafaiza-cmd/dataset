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

    wire [ASIZE:0] gray_wptr_gray;
    wire [ASIZE:0] gray_rptr_gray;
    wire [ASIZE:0] sync_gray_wptr_data_out;
    wire [ASIZE:0] sync_gray_rptr_data_out;
    wire [ASIZE-1:0] bin_wptr_binary;
    wire [ASIZE-1:0] bin_rptr_binary;

    // Gray code counters
    gray_counter #(.ASIZE(ASIZE)) gray_wptr (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc & ~wfull),
        .gray(gray_wptr_gray)
    );

    gray_counter #(.ASIZE(ASIZE)) gray_rptr (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc & ~rempty),
        .gray(gray_rptr_gray)
    );

    // Synchronizers
    synchronizer #(.ASIZE(ASIZE)) sync_gray_wptr (
        .clk(rclk),
        .rst_n(rrst_n),
        .data_in(gray_wptr_gray),
        .data_out(sync_gray_wptr_data_out)
    );

    synchronizer #(.ASIZE(ASIZE)) sync_gray_rptr (
        .clk(wclk),
        .rst_n(wrst_n),
        .data_in(gray_rptr_gray),
        .data_out(sync_gray_rptr_data_out)
    );

    // Binary counters
    binary_counter #(.ASIZE(ASIZE)) bin_wptr (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc & ~wfull),
        .gray(sync_gray_rptr_data_out),
        .binary(bin_wptr_binary)
    );

    binary_counter #(.ASIZE(ASIZE)) bin_rptr (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc & ~rempty),
        .gray(sync_gray_wptr_data_out),
        .binary(bin_rptr_binary)
    );

    // Memory
    memory #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_memory (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .wr_addr(bin_wptr_binary),
        .wr_data(wdata),
        .wr_en(winc & ~wfull),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rd_addr(bin_rptr_binary),
        .rd_en(rinc & ~rempty),
        .rd_data(rdata),
        .full(wfull),
        .empty(rempty)
    );

    // Almost full detector
    almost_full_detector #(.ASIZE(ASIZE)) almost_full_det (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .gray_wptr(gray_wptr_gray),
        .bin_rptr(bin_rptr_binary),
        .almost_full(awfull)
    );

    // Almost empty detector
    almost_empty_detector #(.ASIZE(ASIZE)) almost_empty_det (
        .rclk(rclk),
        .rrst_n(rrst_n),
        .gray_rptr(gray_rptr_gray),
        .bin_wptr(bin_wptr_binary),
        .almost_empty(arempty)
    );

endmodule

module gray_counter #(
    parameter ASIZE = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [ASIZE:0] gray
);

    reg [ASIZE:0] gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gray_reg <= 0;
        else if (inc)
            gray_reg <= gray_reg + 1;
    end

    assign gray = (gray_reg >> 1) ^ gray_reg;

endmodule

module binary_counter #(
    parameter ASIZE = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    input  wire [ASIZE:0] gray,
    output wire [ASIZE-1:0] binary
);

    reg [ASIZE-1:0] binary_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_reg <= 0;
        else if (inc)
            binary_reg <= gray_to_binary(gray);
    end

    assign binary = binary_reg;

    function [ASIZE-1:0] gray_to_binary;
        input [ASIZE:0] gray;
        integer i;
        begin
            gray_to_binary = gray[ASIZE];
            for (i = ASIZE - 1; i >= 0; i = i - 1)
                gray_to_binary[i] = gray_to_binary[i+1] ^ gray[i];
        end
    endfunction

endmodule

module synchronizer #(
    parameter ASIZE = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [ASIZE:0] data_in,
    output wire [ASIZE:0] data_out
);

    reg [ASIZE:0] stage1, stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= 0;
            stage2 <= 0;
        end else begin
            stage1 <= data_in;
            stage2 <= stage1;
        end
    end

    assign data_out = stage2;

endmodule

module memory #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire [ASIZE-1:0] wr_addr,
    input  wire [DSIZE-1:0] wr_data,
    input  wire wr_en,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [ASIZE-1:0] rd_addr,
    input  wire rd_en,
    output wire [DSIZE-1:0] rd_data,
    output wire full,
    output wire empty
);

    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg [ASIZE:0] wr_ptr;
    reg [ASIZE:0] rd_ptr;
    reg [ASIZE:0] wr_ptr_gray;
    reg [ASIZE:0] rd_ptr_gray;
    reg [ASIZE:0] sync_wr_ptr_gray;
    reg [ASIZE:0] sync_rd_ptr_gray;
    reg [ASIZE:0] wr_ptr_next;
    reg [ASIZE:0] rd_ptr_next;
    reg [DSIZE-1:0] rd_data_reg;

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en & ~full) begin
            mem[wr_addr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_data_reg <= 0;
        end else if (rd_en & ~empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
            rd_data_reg <= mem[rd_addr];
        end
    end

    // Synchronizers
    synchronizer #(.ASIZE(ASIZE)) sync_wr_ptr (
        .clk(rclk),
        .rst_n(rrst_n),
        .data_in(wr_ptr_gray),
        .data_out(sync_wr_ptr_gray)
    );

    synchronizer #(.ASIZE(ASIZE)) sync_rd_ptr (
        .clk(wclk),
        .rst_n(wrst_n),
        .data_in(rd_ptr_gray),
        .data_out(sync_rd_ptr_gray)
    );

    // Full and empty detection
    assign wr_ptr_next = wr_ptr + 1;
    assign rd_ptr_next = rd_ptr + 1;

    assign full = (wr_ptr_next == sync_rd_ptr_gray);
    assign empty = (wr_ptr_gray == sync_rd_ptr_gray);

    assign rd_data = rd_data_reg;

endmodule

module almost_full_detector #(
    parameter ASIZE = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [ASIZE:0] gray_wptr,
    input  wire [ASIZE-1:0] bin_rptr,
    output wire almost_full
);

    reg [ASIZE:0] bin_rptr_gray;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_rptr_gray <= 0;
        else
            bin_rptr_gray <= (bin_rptr >> 1) ^ bin_rptr;
    end

    assign almost_full = (gray_wptr == (bin_rptr_gray + 1));

endmodule

module almost_empty_detector #(
    parameter ASIZE = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [ASIZE:0] gray_rptr,
    input  wire [ASIZE-1:0] bin_wptr,
    output wire almost_empty
);

    reg [ASIZE:0] bin_wptr_gray;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_wptr_gray <= 0;
        else
            bin_wptr_gray <= (bin_wptr >> 1) ^ bin_wptr;
    end

    assign almost_empty = (gray_rptr == (bin_wptr_gray - 1));

endmodule
