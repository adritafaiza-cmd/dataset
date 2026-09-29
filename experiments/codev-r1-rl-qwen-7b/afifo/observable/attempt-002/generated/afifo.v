module afifo #(
    parameter LGFIFO = 3,
    parameter WIDTH = 16,
    parameter NFF = 2,
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

    localparam ADDR_WIDTH = LGFIFO;
    reg [WIDTH-1:0] mem [0:(1 << LGFIFO)-1];

    // Write domain signals
    reg [ADDR_WIDTH:0] wptr;
    wire [ADDR_WIDTH:0] wgraynext;
    reg [ADDR_WIDTH:0] rptr_sync1, rptr_sync2;
    wire full;

    // Read domain signals
    reg [ADDR_WIDTH:0] rptr;
    wire [ADDR_WIDTH:0] rgraynext;
    reg [ADDR_WIDTH:0] wptr_sync1, wptr_sync2;
    wire empty;

    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    assign wgraynext = bin2gray(wptr + 1);
    assign full = (wgraynext == { ~rptr_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rptr_sync2[ADDR_WIDTH-2:0] });

    generate
        if (WRITE_ON_POSEDGE) begin
            always @(posedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    wptr <= 0;
                end else if (i_wr && !full) begin
                    mem[wptr[ADDR_WIDTH-1:0]] <= i_wr_data;
                    wptr <= wptr + 1;
                end
            end
        end else begin
            always @(negedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    wptr <= 0;
                end else if (i_wr && !full) begin
                    mem[wptr[ADDR_WIDTH-1:0]] <= i_wr_data;
                    wptr <= wptr + 1;
                end
            end
        end
    endgenerate

    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            rptr_sync1 <= 0;
            rptr_sync2 <= 0;
        end else begin
            rptr_sync1 <= rgray;
            rptr_sync2 <= rptr_sync1;
        end
    end

    reg [ADDR_WIDTH:0] wgray;
    always @* wgray = bin2gray(wptr);

    // Read domain logic
    assign rgraynext = bin2gray(rptr + 1);
    assign empty = (rgray == wptr_sync2);

    generate
        if (OPT_REGISTER_READS) begin
            reg [WIDTH-1:0] rd_data_reg;
            reg rd_empty_reg;

            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    rd_data_reg <= 0;
                    rd_empty_reg <= 1;
                end else begin
                    if (i_rd && !empty) begin
                        rd_data_reg <= mem[rptr[ADDR_WIDTH-1:0]];
                        rd_empty_reg <= 0;
                        rptr <= rptr + 1;
                    end else if (empty) begin
                        rd_empty_reg <= 1;
                    end
                end
            end

            assign o_rd_data = rd_data_reg;
            assign o_rd_empty = rd_empty_reg;
        end else begin
            always @* o_rd_data = mem[rptr[ADDR_WIDTH-1:0]];

            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    o_rd_empty <= 1;
                end else begin
                    o_rd_empty <= empty;
                end
            end

            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    rptr <= 0;
                end else if (i_rd && !empty) begin
                    rptr <= rptr + 1;
                end
            end
        end
    endgenerate

    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            wptr_sync1 <= 0;
            wptr_sync2 <= 0;
        end else begin
            wptr_sync1 <= wgray;
            wptr_sync2 <= wptr_sync1;
        end
    end

    reg [ADDR_WIDTH:0] rgray;
    always @* rgray = bin2gray(rptr);

    assign o_wr_full = full;

    initial begin
        o_wr_full = 0;
        o_rd_empty = 1;
    end

endmodule
