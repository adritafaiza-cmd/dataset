module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    reg [WIDTH-1:0]       fifo_data [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0]   fifo_read_ptr, fifo_write_ptr;
    reg                   fifo_full, fifo_empty;
    reg [LOG_DEPTH-1:0]   src_gray_counter_gray, src_gray_counter_gray_reg;
    reg [LOG_DEPTH-1:0]   dst_gray_counter_gray, dst_gray_counter_gray_reg;

    // Gray counter for source domain
    gray_counter #(.WIDTH(LOG_DEPTH)) src_gray_counter (
        .count(fifo_read_ptr),
        .gray(src_gray_counter_gray)
    );

    // Gray counter for destination domain
    gray_counter #(.WIDTH(LOG_DEPTH)) dst_gray_counter (
        .count(fifo_write_ptr),
        .gray(dst_gray_counter_gray)
    );

    // Synchronization logic for source domain
    sync_gray_counter #(.WIDTH(LOG_DEPTH), .STAGES(SYNC_STAGES)) src_sync_gray_counter (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .gray_in(src_gray_counter_gray),
        .gray_out(src_gray_counter_gray_reg)
    );

    // Synchronization logic for destination domain
    sync_gray_counter #(.WIDTH(LOG_DEPTH), .STAGES(SYNC_STAGES)) dst_sync_gray_counter (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .gray_in(dst_gray_counter_gray),
        .gray_out(dst_gray_counter_gray_reg)
    );

    // FIFO logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_full <= 1'b0;
            fifo_empty <= 1'b1;
            fifo_read_ptr <= 0;
            fifo_write_ptr <= 0;
        end else begin
            if (!fifo_full && src_valid_i && src_ready_o) begin
                fifo_data[fifo_write_ptr] <= src_data_i;
                fifo_write_ptr <= fifo_write_ptr + 1;
                if (fifo_write_ptr == (1<<LOG_DEPTH)-1) begin
                    fifo_write_ptr <= 0;
                end
                if (fifo_write_ptr == fifo_read_ptr) begin
                    fifo_full <= 1'b1;
                end
                fifo_empty <= 1'b0;
            end else if (fifo_empty && dst_ready_i) begin
                fifo_read_ptr <= fifo_read_ptr + 1;
                if (fifo_read_ptr == (1<<LOG_DEPTH)-1) begin
                    fifo_read_ptr <= 0;
                end
                if (fifo_read_ptr == fifo_write_ptr) begin
                    fifo_empty <= 1'b1;
                end
                fifo_full <= 1'b0;
            end
        end
    end

    // Output logic
    assign dst_data_o = fifo_data[fifo_read_ptr];
    assign dst_valid_o = ~fifo_empty;
    assign src_ready_o = ~fifo_full;

endmodule

module gray_counter (
    input  [LOG_DEPTH-1:0] count,
    output [LOG_DEPTH-1:0] gray
);

    always @(*) begin
        gray = count ^ (count >> 1);
    end

endmodule

module sync_gray_counter #(
    parameter WIDTH = 3,
    parameter STAGES = 2
)(
    input                  clk,
    input                  rst_n,
    input  [WIDTH-1:0]     gray_in,
    output reg [WIDTH-1:0] gray_out
);

    reg [WIDTH-1:0] sync_reg [0:STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out <= 0;
        end else begin
            sync_reg[0] <= gray_in;
            gray_out <= sync_reg[STAGES-1];
        end
    end

endmodule
