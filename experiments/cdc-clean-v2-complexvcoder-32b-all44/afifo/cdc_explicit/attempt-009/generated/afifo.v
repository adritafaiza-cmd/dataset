module afifo #(
    parameter LGFIFO = 3,
    parameter WIDTH  = 16,
    parameter NFF    = 2,
    parameter [0:0] WRITE_ON_POSEDGE = 1'b1,
    parameter [0:0] OPT_REGISTER_READS = 1'b1
) (
    input wire i_wclk, i_wr_reset_n, i_wr,
    input wire [WIDTH-1:0] i_wr_data,
    output reg o_wr_full,
    input wire i_rclk, i_rd_reset_n, i_rd,
    output reg [WIDTH-1:0] o_rd_data,
    output reg o_rd_empty
);

    // Internal signals
    wire wr_en;
    wire rd_en;
    wire wr_full_sync;
    wire rd_empty_sync;

    // Synchronization stages
    sync_stage #(NFF) wr_sync (
        .i_clk(i_wclk),
        .i_reset_n(i_wr_reset_n),
        .i_data(i_wr),
        .o_data(wr_en)
    );

    sync_stage #(NFF) rd_sync (
        .i_clk(i_rclk),
        .i_reset_n(i_rd_reset_n),
        .i_data(wr_full_sync),
        .o_data(o_wr_full)
    );

    // FIFO memory
    mem #(
        .LGFIFO(LGFIFO),
        .WIDTH(WIDTH),
        .NFF(NFF)
    ) fifo_mem (
        .i_wclk(i_wclk),
        .i_wr_reset_n(i_wr_reset_n),
        .i_wr_en(wr_en),
        .i_wr_data(i_wr_data),
        .o_wr_full(wr_full_sync),
        .i_rclk(i_rclk),
        .i_rd_reset_n(i_rd_reset_n),
        .i_rd_en(i_rd),
        .o_rd_data(o_rd_data),
        .o_rd_empty(rd_empty_sync)
    );

    // Synchronize rd_empty
    sync_stage #(NFF) rd_empty_sync_stage (
        .i_clk(i_rclk),
        .i_reset_n(i_rd_reset_n),
        .i_data(rd_empty_sync),
        .o_data(o_rd_empty)
    );

    // Additional output register if OPT_REGISTER_READS is set
    reg [WIDTH-1:0] rd_data_reg;

    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_data_reg <= {WIDTH{1'b0}};
        end else if (OPT_REGISTER_READS && i_rd && !rd_empty_sync) begin
            rd_data_reg <= o_rd_data;
        end
    end

    // Assign final read data output based on OPT_REGISTER_READS
    assign o_rd_data = OPT_REGISTER_READS ? rd_data_reg : o_rd_data;

endmodule

// Synchronization stage module
module sync_stage #(
    parameter NFF = 2
) (
    input wire i_clk,
    input wire i_reset_n,
    input wire i_data,
    output reg o_data
);

    reg [NFF-1:0] sync_reg;

    always @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            sync_reg <= {NFF{1'b0}};
        end else begin
            sync_reg <= {sync_reg[NFF-2:0], i_data};
        end
    end

    assign o_data = sync_reg[NFF-1];

endmodule

// FIFO memory module
module mem #(
    parameter LGFIFO = 3,
    parameter WIDTH = 16,
    parameter NFF = 2
) (
    input wire i_wclk,
    input wire i_wr_reset_n,
    input wire i_wr_en,
    input wire [WIDTH-1:0] i_wr_data,
    output reg o_wr_full,
    input wire i_rclk,
    input wire i_rd_reset_n,
    input wire i_rd_en,
    output reg [WIDTH-1:0] o_rd_data,
    output reg o_rd_empty
);

    localparam DEPTH = 1 << LGFIFO;
    reg [WIDTH-1:0] mem_array [DEPTH-1:0];
    reg [LGFIFO-1:0] wr_ptr, rd_ptr;
    reg [LGFIFO-1:0] wr_ptr_gray, rd_ptr_gray;
    reg [LGFIFO-1:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [LGFIFO-1:0] wr_ptr_gray_sync_2, rd_ptr_gray_sync_2;
    reg wr_full, rd_empty;

    // Binary to Gray code conversion
    function [LGFIFO-1:0] bin2gray;
        input [LGFIFO-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Write side logic
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wr_ptr <= {LGFIFO{1'b0}};
            wr_ptr_gray <= {LGFIFO{1'b0}};
            o_wr_full <= 1'b0;
        end else if (i_wr_en && !wr_full) begin
            mem_array[wr_ptr] <= i_wr_data;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin2gray(wr_ptr + 1);
        end
    end

    // Read side logic
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_ptr <= {LGFIFO{1'b0}};
            rd_ptr_gray <= {LGFIFO{1'b0}};
            o_rd_empty <= 1'b1;
        end else if (i_rd_en && !rd_empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin2gray(rd_ptr + 1);
        end
    end

    // Synchronize write pointer to read clock domain
    sync_stage #(NFF) wr_ptr_sync_stage1 (
        .i_clk(i_rclk),
        .i_reset_n(i_rd_reset_n),
        .i_data(wr_ptr_gray),
        .o_data(wr_ptr_gray_sync)
    );

    sync_stage #(NFF) wr_ptr_sync_stage2 (
        .i_clk(i_rclk),
        .i_reset_n(i_rd_reset_n),
        .i_data(wr_ptr_gray_sync),
        .o_data(wr_ptr_gray_sync_2)
    );

    // Synchronize read pointer to write clock domain
    sync_stage #(NFF) rd_ptr_sync_stage1 (
        .i_clk(i_wclk),
        .i_reset_n(i_wr_reset_n),
        .i_data(rd_ptr_gray),
        .o_data(rd_ptr_gray_sync)
    );

    sync_stage #(NFF) rd_ptr_sync_stage2 (
        .i_clk(i_wclk),
        .i_reset_n(i_wr_reset_n),
        .i_data(rd_ptr_gray_sync),
        .o_data(rd_ptr_gray_sync_2)
    );

    // Calculate full and empty flags
    assign wr_full = (wr_ptr_gray_sync_2 == bin2gray(rd_ptr + DEPTH));
    assign rd_empty = (rd_ptr_gray_sync_2 == wr_ptr_gray);

    // Read data output
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            o_rd_data <= {WIDTH{1'b0}};
        end else if (i_rd_en && !rd_empty) begin
            o_rd_data <= mem_array[rd_ptr];
        end
    end

endmodule
