module afifo #(
    parameter LGFIFO = 3,
    parameter WIDTH = 16,
    parameter NFF = 2,
    parameter WRITE_ON_POSEDGE = 1'b1,
    parameter OPT_REGISTER_READS = 1'b1
) (
    input wire i_wclk,
    input wire i_wr_reset_n,
    input wire i_wr,
    input wire [WIDTH-1:0] i_wr_data,
    output reg o_wr_full,
    input wire i_rclk,
    input wire i_rd_reset_n,
    input wire i_rd,
    output reg [WIDTH-1:0] o_rd_data,
    output reg o_rd_empty
);

    // FIFO memory
    reg [WIDTH-1:0] mem [0:(1 << LGFIFO)-1];

    // Pointers
    reg [LGFIFO:0] wptr, rptr;

    // Gray code conversions
    wire [LGFIFO:0] wgray, rgray;
    assign wgray = (wptr >> 1) ^ wptr;
    assign rgray = (rptr >> 1) ^ rptr;

    // Synchronization registers
    reg [LGFIFO:0] rgray_sync1, rgray_sync2;
    reg [LGFIFO:0] wgray_sync1, wgray_sync2;

    // Full and empty conditions
    wire full, empty;

    // Write domain logic
    generate
        if (WRITE_ON_POSEDGE) begin
            // Synchronize read pointer to write clock domain
            always @(posedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    rgray_sync1 <= 0;
                    rgray_sync2 <= 0;
                end else begin
                    rgray_sync1 <= rgray;
                    rgray_sync2 <= rgray_sync1;
                end
            end

            // Full condition
            wire [LGFIFO:0] wptr_next = wptr + (i_wr && !o_wr_full);
            wire [LGFIFO:0] wgraynext = (wptr_next >> 1) ^ wptr_next;

            assign full = (wgraynext == { ~rgray_sync2[LGFIFO], rgray_sync2[LGFIFO-1:0] });

            // Update write pointer and flags
            always @(posedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    wptr <= 0;
                    o_wr_full <= 0;
                end else begin
                    if (i_wr && !o_wr_full) begin
                        mem[wptr[LGFIFO-1:0]] <= i_wr_data;
                        wptr <= wptr + 1;
                    end
                    o_wr_full <= full;
                end
            end
        end else begin
            // Synchronize read pointer to write clock domain on negedge
            always @(negedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    rgray_sync1 <= 0;
                    rgray_sync2 <= 0;
                end else begin
                    rgray_sync1 <= rgray;
                    rgray_sync2 <= rgray_sync1;
                end
            end

            // Full condition
            wire [LGFIFO:0] wptr_next = wptr + (i_wr && !o_wr_full);
            wire [LGFIFO:0] wgraynext = (wptr_next >> 1) ^ wptr_next;

            assign full = (wgraynext == { ~rgray_sync2[LGFIFO], rgray_sync2[LGFIFO-1:0] });

            // Update write pointer and flags
            always @(negedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    wptr <= 0;
                    o_wr_full <= 0;
                end else begin
                    if (i_wr && !o_wr_full) begin
                        mem[wptr[LGFIFO-1:0]] <= i_wr_data;
                        wptr <= wptr + 1;
                    end
                    o_wr_full <= full;
                end
            end
        end
    endgenerate

    // Read domain logic
    generate
        if (WRITE_ON_POSEDGE) begin
            // Synchronize write pointer to read clock domain
            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    wgray_sync1 <= 0;
                    wgray_sync2 <= 0;
                end else begin
                    wgray_sync1 <= wgray;
                    wgray_sync2 <= wgray_sync1;
                end
            end

            // Empty condition
            assign empty = (rgray == wgray_sync2);

            // Update read pointer and flags
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
        end else begin
            // Synchronize write pointer to read clock domain on negedge
            always @(negedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    wgray_sync1 <= 0;
                    wgray_sync2 <= 0;
                end else begin
                    wgray_sync1 <= wgray;
                    wgray_sync2 <= wgray_sync1;
                end
            end

            // Empty condition
            assign empty = (rgray == wgray_sync2);

            // Update read pointer and flags
            always @(negedge i_rclk or negedge i_rd_reset_n) begin
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
        end
    endgenerate

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
            always @* begin
                o_rd_data = mem[rptr[LGFIFO-1:0]];
            end
        end
    endgenerate

endmodule
