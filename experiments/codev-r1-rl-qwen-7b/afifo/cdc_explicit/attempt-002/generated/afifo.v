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

    // Memory
    reg [WIDTH-1:0] mem [0:(1 << LGFIFO)-1];

    // Pointers
    reg [LGFIFO:0] wptr, rptr;

    // Gray code conversions
    wire [LGFIFO:0] wptr_gray, rptr_gray;
    assign wptr_gray = (wptr >> 1) ^ wptr;
    assign rptr_gray = (rptr >> 1) ^ rptr;

    // Synchronizers
    reg [LGFIFO:0] rptr_gray_sync [NFF-1:0];
    reg [LGFIFO:0] wptr_gray_sync [NFF-1:0];

    // Write domain logic
    integer i;

    // Synchronize read pointer's Gray code to write domain
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            for (i=0; i < NFF; i=i+1) begin
                rptr_gray_sync[i] <= 0;
            end
        end else begin
            rptr_gray_sync[0] <= rptr_gray;
            for (i=1; i < NFF; i=i+1) begin
                rptr_gray_sync[i] <= rptr_gray_sync[i-1];
            end
        end
    end

    // Full condition
    wire full;
    assign full = (wptr_gray == { ~rptr_gray_sync[NFF-1][LGFIFO], ~rptr_gray_sync[NFF-1][LGFIFO-1], rptr_gray_sync[NFF-1][LGFIFO-2:0] });

    // Update write pointer and full flag
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wptr <= 0;
            o_wr_full <= 0;
        end else begin
            if (WRITE_ON_POSEDGE && i_wr && !o_wr_full) begin
                mem[wptr[LGFIFO-1:0]] <= i_wr_data;
                wptr <= wptr + 1;
            end
            o_wr_full <= full;
        end
    end

    // Read domain logic
    // Synchronize write pointer's Gray code to read domain
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            for (i=0; i < NFF; i=i+1) begin
                wptr_gray_sync[i] <= 0;
            end
        end else begin
            wptr_gray_sync[0] <= wptr_gray;
            for (i=1; i < NFF; i=i+1) begin
                wptr_gray_sync[i] <= wptr_gray_sync[i-1];
            end
        end
    end

    // Empty condition
    wire empty;
    assign empty = (rptr_gray == wptr_gray_sync[NFF-1]);

    // Update read pointer and empty flag
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rptr <= 0;
            o_rd_empty <= 1;
        end else begin
            if (i_rd && !o_rd_empty) begin
                rptr <= rptr + 1;
            end
            o_rd_empty <= empty;
        end
    end

    // Read data logic
    generate
        if (OPT_REGISTER_READS) begin
            // Registered read data
            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    o_rd_data <= 0;
                end else if (i_rd && !o_rd_empty) begin
                    o_rd_data <= mem[rptr[LGFIFO-1:0]];
                end
            end
        end else begin
            // Combinational read data
            always @(*) begin
                o_rd_data = mem[rptr[LGFIFO-1:0]];
            end
        end
    endgenerate

endmodule
