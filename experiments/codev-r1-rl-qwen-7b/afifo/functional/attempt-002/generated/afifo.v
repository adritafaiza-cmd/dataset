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

    localparam addr_width = LGFIFO;

    // FIFO memory
    reg [WIDTH-1:0] mem [0:(1 << LGFIFO)-1];

    // Write domain signals
    reg [addr_width:0] wptr;
    wire [addr_width:0] wgray, wgraynext;
    wire [addr_width:0] wptr_next;
    reg [addr_width:0] rptr_sync1, rptr_sync;

    // Read domain signals
    reg [addr_width:0] rptr;
    wire [addr_width:0] rgray;
    wire [addr_width:0] rptr_next;
    reg [addr_width:0] wptr_sync1, wptr_sync;

    // Full and empty conditions
    wire full, empty;

    // Write pointer logic
    assign wptr_next = (i_wr && !o_wr_full) ? wptr + 1 : wptr;
    assign wgray = wptr ^ (wptr >> 1);
    assign wgraynext = wptr_next ^ (wptr_next >> 1);

    // Synchronize read pointer to write domain
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            rptr_sync1 <= 0;
            rptr_sync <= 0;
        end else begin
            rptr_sync1 <= rgray;
            rptr_sync <= rptr_sync1;
        end
    end

    // Full condition
    assign full = (wgraynext == { ~rptr_sync[addr_width], rptr_sync[addr_width-1:0] });

    // Update write pointer and flags
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wptr <= 0;
            o_wr_full <= 0;
        end else begin
            wptr <= wptr_next;
            o_wr_full <= full;
        end
    end

    // Read pointer logic
    assign rptr_next = (i_rd && !o_rd_empty) ? rptr + 1 : rptr;
    assign rgray = rptr ^ (rptr >> 1);

    // Synchronize write pointer to read domain
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            wptr_sync1 <= 0;
            wptr_sync <= 0;
        end else begin
            wptr_sync1 <= wgray;
            wptr_sync <= wptr_sync1;
        end
    end

    // Empty condition
    assign empty = (rgray == wptr_sync);

    // Update read pointer and flags
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rptr <= 0;
            o_rd_empty <= 1;
        end else begin
            rptr <= rptr_next;
            o_rd_empty <= empty;
        end
    end

    // Memory write
    always @(posedge i_wclk) begin
        if (i_wr && !o_wr_full) begin
            mem[wptr[addr_width-1:0]] <= i_wr_data;
        end
    end

    // Memory read
    generate
        if (OPT_REGISTER_READS) begin
            // Registered read data
            reg [WIDTH-1:0] o_rd_data_reg;
            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    o_rd_data_reg <= 0;
                end else if (i_rd && !o_rd_empty) begin
                    o_rd_data_reg <= mem[rptr[addr_width-1:0]];
                end
            end
            assign o_rd_data = o_rd_data_reg;
        end else begin
            // Combinational read
            always @* begin
                o_rd_data = mem[rptr[addr_width-1:0]];
            end
        end
    endgenerate

endmodule
