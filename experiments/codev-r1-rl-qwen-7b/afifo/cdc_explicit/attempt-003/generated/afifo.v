module afifo #(
    parameter LGFIFO = 3,
    parameter WIDTH = 16,
    parameter NFF = 2,
    parameter WRITE_ON_POSEDGE = 1'b1,
    parameter OPT_REGISTER_READS = 1'b1
) (
    input wire i_wclk, i_wr_reset_n, i_wr,
    input wire [WIDTH-1:0] i_wr_data,
    output reg o_wr_full,
    input wire i_rclk, i_rd_reset_n, i_rd,
    output reg [WIDTH-1:0] o_rd_data,
    output reg o_rd_empty
);

    localparam PTR_WIDTH = LGFIFO + 1;

    reg [PTR_WIDTH-1:0] wptr, rptr;
    reg [PTR_WIDTH-1:0] wptr_gray, rptr_gray;
    reg [WIDTH-1:0] mem [0:(1 << LGFIFO)-1];
    reg [PTR_WIDTH-1:0] rptr_sync [NFF-1:0];
    reg [PTR_WIDTH-1:0] wptr_sync [NFF-1:0];

    function [PTR_WIDTH-1:0] bin2gray(input [PTR_WIDTH-1:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Synchronize read pointer to write domain
    integer i;
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            for (i=0; i < NFF; i=i+1)
                rptr_sync[i] <= 0;
        end else begin
            rptr_sync[0] <= rptr_gray;
            for (i=1; i < NFF; i=i+1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    // Synchronize write pointer to read domain
    integer j;
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            for (j=0; j < NFF; j=j+1)
                wptr_sync[j] <= 0;
        end else begin
            wptr_sync[0] <= wptr_gray;
            for (j=1; j < NFF; j=j+1)
                wptr_sync[j] <= wptr_sync[j-1];
        end
    end

    wire [PTR_WIDTH-1:0] rptr_sync_gray = rptr_sync[NFF-1];
    wire [PTR_WIDTH-1:0] wptr_sync_gray = wptr_sync[NFF-1];
    wire [PTR_WIDTH-1:0] wgray_next = bin2gray(wptr + 1);
    wire full = (wgray_next == { ~rptr_sync_gray[PTR_WIDTH-1 : PTR_WIDTH-2], rptr_sync_gray[PTR_WIDTH-3 : 0] });
    wire empty = (rptr_gray == wptr_sync_gray);

    // Write pointer and memory update
    generate
        if (WRITE_ON_POSEDGE) begin
            always @(posedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    wptr <= 0;
                    wptr_gray <= 0;
                end else begin
                    if (i_wr && !o_wr_full) begin
                        wptr <= wptr + 1;
                        mem[wptr[PTR_WIDTH-2:0]] <= i_wr_data;
                    end
                    wptr_gray <= bin2gray(wptr);
                end
            end
        end else begin
            always @(negedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    wptr <= 0;
                    wptr_gray <= 0;
                end else begin
                    if (i_wr && !o_wr_full) begin
                        wptr <= wptr + 1;
                        mem[wptr[PTR_WIDTH-2:0]] <= i_wr_data;
                    end
                    wptr_gray <= bin2gray(wptr);
                end
            end
        end
    endgenerate

    // Read pointer update
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else begin
            if (i_rd && !o_rd_empty)
                rptr <= rptr + 1;
            rptr_gray <= bin2gray(rptr);
        end
    end

    // Full and empty flags
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n)
            o_wr_full <= 0;
        else
            o_wr_full <= full;
    end

    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n)
            o_rd_empty <= 1;
        else
            o_rd_empty <= empty;
    end

    // Read data handling
    generate
        if (OPT_REGISTER_READS) begin
            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n)
                    o_rd_data <= 0;
                else if (i_rd && !o_rd_empty)
                    o_rd_data <= mem[rptr[PTR_WIDTH-2:0]];
            end
        end else begin
            always @* o_rd_data = mem[rptr[PTR_WIDTH-2:0]];
        end
    endgenerate

endmodule
