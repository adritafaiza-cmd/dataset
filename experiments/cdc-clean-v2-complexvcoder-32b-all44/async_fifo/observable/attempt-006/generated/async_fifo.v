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

    wire [ASIZE:0] wr_ptr_gray;
    wire [ASIZE:0] rd_ptr_gray;
    wire [ASIZE:0] wr_ptr_bin;
    wire [ASIZE:0] rd_ptr_bin;
    wire [ASIZE+1:0] diff;
    wire [ASIZE+1:0] almost_full_threshold;
    wire [ASIZE+1:0] almost_empty_threshold;

    assign almost_full_threshold = {1'b0, {(ASIZE){1'b1}}} - (ASIZE + 2);
    assign almost_empty_threshold = ASIZE + 2;

    gray_counter wr_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray(wr_ptr_gray)
    );

    gray_counter rd_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray(rd_ptr_gray)
    );

    binary_snapshot wr_bin_snap (
        .clk(wclk),
        .rst_n(wrst_n),
        .gray_in(wr_ptr_gray),
        .binary(wr_ptr_bin)
    );

    binary_snapshot rd_bin_snap (
        .clk(rclk),
        .rst_n(rrst_n),
        .gray_in(rd_ptr_gray),
        .binary(rd_ptr_bin)
    );

    dual_port_ram fifo_ram (
        .wclk(wclk),
        .wr_addr(wr_ptr_bin),
        .wr_data(wdata),
        .rclk(rclk),
        .rd_addr(rd_ptr_bin),
        .rd_data(rdata)
    );

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 1'b0;
            awfull <= 1'b0;
        end else begin
            diff = wr_ptr_bin - rd_ptr_bin;
            wfull <= (diff == {1'b0, {(ASIZE){1'b1}}});
            awfull <= (diff >= almost_full_threshold);
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= 1'b1;
            arempty <= 1'b1;
        end else begin
            diff = wr_ptr_bin - rd_ptr_bin;
            rempty <= (diff == 0);
            arempty <= (diff <= almost_empty_threshold);
        end
    end

endmodule

module gray_counter (
    input wire clk,
    input wire rst_n,
    input wire inc,
    output reg [ASIZE:0] gray
);

    reg [ASIZE:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            gray <= 0;
        end else if (inc) begin
            count <= count + 1;
            gray <= (count >> 1) ^ count;
        end
    end

endmodule

module binary_snapshot (
    input wire clk,
    input wire rst_n,
    input wire [ASIZE:0] gray_in,
    output reg [ASIZE:0] binary
);

    reg [ASIZE:0] gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg <= 0;
            binary <= 0;
        end else begin
            gray_reg <= gray_in;
            binary <= gray_to_bin(gray_reg);
        end
    end

    function [ASIZE:0] gray_to_bin;
        input [ASIZE:0] gray;
        integer i;
        reg [ASIZE:0] bin;
        begin
            bin = gray[ASIZE];
            for (i = ASIZE - 1; i >= 0; i = i - 1) begin
                bin[i] = bin[i + 1] ^ gray[i];
            end
            gray_to_bin = bin;
        end
    endfunction

endmodule

module dual_port_ram (
    input wire wclk,
    input wire [ASIZE:0] wr_addr,
    input wire [DSIZE-1:0] wr_data,
    input wire rclk,
    input wire [ASIZE:0] rd_addr,
    output reg [DSIZE-1:0] rd_data
);

    reg [DSIZE-1:0] ram [0:(2**(ASIZE+1))-1];

    always @(posedge wclk) begin
        ram[wr_addr] <= wr_data;
    end

    always @(posedge rclk) begin
        rd_data <= ram[rd_addr];
    end

endmodule
