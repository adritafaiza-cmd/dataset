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

    // Memory array
    reg [WIDTH-1:0] mem [0:(1 << LGFIFO)-1];

    // Write pointer and gray code
    reg [LGFIFO:0] wptr_bin;
    wire [LGFIFO:0] wptr_gray;
    assign wptr_gray = (wptr_bin >> 1) ^ wptr_bin;

    // Read pointer and gray code
    reg [LGFIFO:0] rptr_bin;
    wire [LGFIFO:0] rptr_gray;
    assign rptr_gray = (rptr_bin >> 1) ^ rptr_bin;

    // Synchronization registers in write domain for read pointer
    reg [LGFIFO:0] rptr_gray_sync1, rptr_gray_sync;

    // Convert synchronized gray to binary in write domain
    wire [LGFIFO:0] rptr_sync_bin;
    assign rptr_sync_bin[LGFIFO] = rptr_gray_sync[LGFIFO];
    generate
        genvar i;
        for (i = LGFIFO-1; i >=0; i = i -1) begin : gray2bin_rptr
            assign rptr_sync_bin[i] = rptr_sync_bin[i+1] ^ rptr_gray_sync[i];
        end
    endgenerate

    // Synchronization registers in read domain for write pointer
    reg [LGFIFO:0] wptr_gray_sync1, wptr_gray_sync;

    // Convert synchronized gray to binary in read domain
    wire [LGFIFO:0] wptr_sync_bin;
    assign wptr_sync_bin[LGFIFO] = wptr_gray_sync[LGFIFO];
    generate
        genvar j;
        for (j = LGFIFO-1; j >=0; j = j -1) begin : gray2bin_wptr
            assign wptr_sync_bin[j] = wptr_sync_bin[j+1] ^ wptr_gray_sync[j];
        end
    endgenerate

    // Full and empty conditions
    wire full;
    assign full = ( (wptr_bin[LGFIFO] != rptr_sync_bin[LGFIFO]) && (wptr_bin[LGFIFO-1:0] == rptr_sync_bin[LGFIFO-1:0]) );

    // Write pointer logic
    generate
        if (WRITE_ON_POSEDGE) begin : gen_write_posedge
            always @(posedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    wptr_bin <= 0;
                end else if (i_wr && !o_wr_full) begin
                    wptr_bin <= wptr_bin + 1;
                    mem[wptr_bin[LGFIFO-1:0]] <= i_wr_data;
                end
            end
        end else begin : gen_write_negedge
            always @(negedge i_wclk or negedge i_wr_reset_n) begin
                if (!i_wr_reset_n) begin
                    wptr_bin <= 0;
                end else if (i_wr && !o_wr_full) begin
                    wptr_bin <= wptr_bin + 1;
                    mem[wptr_bin[LGFIFO-1:0]] <= i_wr_data;
                end
            end
        end
    endgenerate

    // Read pointer logic
    generate
        if (WRITE_ON_POSEDGE) begin : gen_read_posedge
            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    rptr_bin <= 0;
                end else if (i_rd && !o_rd_empty) begin
                    rptr_bin <= rptr_bin + 1;
                end
            end
        end else begin : gen_read_negedge
            always @(negedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    rptr_bin <= 0;
                end else if (i_rd && !o_rd_empty) begin
                    rptr_bin <= rptr_bin + 1;
                end
            end
        end
    endgenerate

    // Synchronization of read pointer to write domain
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync <= rptr_gray_sync1;
        end
    end

    // Synchronization of write pointer to read domain
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync <= wptr_gray_sync1;
        end
    end

    // Full and empty assignments
    always @(*) begin
        o_wr_full = full;
    end

    always @(*) begin
        o_rd_empty = (rptr_bin == wptr_sync_bin);
    end

    // Read data logic
    generate
        if (OPT_REGISTER_READS) begin : gen_reg_reads
            // Registered read data
            always @(posedge i_rclk or negedge i_rd_reset_n) begin
                if (!i_rd_reset_n) begin
                    o_rd_data <= 0;
                end else if (i_rd && !o_rd_empty) begin
                    o_rd_data <= mem[rptr_bin[LGFIFO-1:0]];
                end
            end
        end else begin : gen_noreg_reads
            // Combinational read
            always @(*) begin
                o_rd_data = mem[rptr_bin[LGFIFO-1:0]];
            end
        end
    endgenerate

endmodule
