module afifo #(
        parameter LGFIFO = 3,
        parameter WIDTH  = 16,
        parameter NFF    = 2,
        parameter [0:0] WRITE_ON_POSEDGE = 1'b1,
        parameter [0:0] OPT_REGISTER_READS = 1'b1
    ) (
        input wire            i_wclk, i_wr_reset_n, i_wr,
        input wire [WIDTH-1:0] i_wr_data,
        output reg            o_wr_full,
        input wire            i_rclk, i_rd_reset_n, i_rd,
        output reg [WIDTH-1:0] o_rd_data,
        output reg            o_rd_empty
    );

    // Internal signals
    reg [LGFIFO:0] wr_ptr, rd_ptr;
    reg [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
    reg [LGFIFO:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];
    reg [WIDTH-1:0] mem_reg;

    // Gray code conversion functions
    function [LGFIFO:0] bin2gray;
        input [LGFIFO:0] bin;
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    function [LGFIFO:0] gray2bin;
        input [LGFIFO:0] gray;
        integer i;
        reg [LGFIFO:0] bin;
        bin = gray;
        for (i = LGFIFO-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray2bin = bin;
    endfunction

    // Write side logic
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            o_wr_full <= 0;
        end else begin
            if (i_wr && !o_wr_full) begin
                if (WRITE_ON_POSEDGE) begin
                    mem[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
                    wr_ptr <= wr_ptr + 1;
                    wr_ptr_gray <= bin2gray(wr_ptr + 1);
                end else begin
                    mem[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
                    wr_ptr <= wr_ptr + 1;
                    wr_ptr_gray <= bin2gray(wr_ptr + 1);
                end
            end
            // Calculate full flag
            o_wr_full <= (wr_ptr_gray[LGFIFO] != rd_ptr_gray_sync[LGFIFO]) && (wr_ptr_gray[LGFIFO-1:0] == rd_ptr_gray_sync[LGFIFO-1:0]);
        end
    end

    // Read side logic
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            o_rd_empty <= 1;
            o_rd_data <= 0;
            mem_reg <= 0;
        end else begin
            if (i_rd && !o_rd_empty) begin
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= bin2gray(rd_ptr + 1);
                mem_reg <= mem[rd_ptr[LGFIFO-1:0]];
            end
            // Calculate empty flag
            o_rd_empty <= (wr_ptr_gray_sync[LGFIFO] == rd_ptr_gray[LGFIFO]) && (wr_ptr_gray_sync[LGFIFO-1:0] == rd_ptr_gray[LGFIFO-1:0]);
        end
    end

    // Synchronize write pointer gray code to read clock domain
    sync_bit #(.NFF(NFF)) sync_wr_ptr_gray (
        .clk_src(i_wclk),
        .d_src(wr_ptr_gray),
        .clk_dst(i_rclk),
        .d_dst(wr_ptr_gray_sync)
    );

    // Synchronize read pointer gray code to write clock domain
    sync_bit #(.NFF(NFF)) sync_rd_ptr_gray (
        .clk_src(i_rclk),
        .d_src(rd_ptr_gray),
        .clk_dst(i_wclk),
        .d_dst(rd_ptr_gray_sync)
    );

    // Additional register for read data if OPT_REGISTER_READS is set
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            o_rd_data <= 0;
        end else if (OPT_REGISTER_READS) begin
            o_rd_data <= mem_reg;
        end
    end

endmodule

module sync_bit #(
        parameter NFF = 2
    ) (
        input wire clk_src,
        input wire d_src,
        input wire clk_dst,
        output reg d_dst
    );

    reg [NFF-1:0] sreg;

    always @(posedge clk_src) begin
        sreg <= {sreg[NFF-2:0], d_src};
    end

    always @(posedge clk_dst) begin
        d_dst <= sreg[NFF-1];
    end

endmodule
