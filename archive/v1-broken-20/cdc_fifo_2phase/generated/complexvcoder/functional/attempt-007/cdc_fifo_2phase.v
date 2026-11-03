module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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
    reg  [WIDTH-1:0]        fifo [0:(2**LOG_DEPTH)-1];
    reg  [LOG_DEPTH:0]      write_ptr;
    reg  [LOG_DEPTH:0]      read_ptr;
    reg                     full;
    reg                     empty;

    // Synchronizers for source domain
    reg  [WIDTH-1:0]        src_data_sync;
    reg                     src_valid_sync;
    reg                     src_ready_sync;
    reg                     src_ready_reg;

    // Synchronizers for destination domain
    reg  [WIDTH-1:0]        dst_data_sync;
    reg                     dst_valid_sync;
    reg                     dst_ready_sync;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                fifo[write_ptr] <= src_data_i;
                write_ptr <= write_ptr + 1;
                if (write_ptr == (2**LOG_DEPTH) - 1) begin
                    full <= 1;
                end else begin
                    empty <= 0;
                end
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (dst_ready_i && !empty) begin
                dst_data_o <= fifo[read_ptr];
                read_ptr <= read_ptr + 1;
                if (read_ptr == (2**LOG_DEPTH) - 1) begin
                    empty <= 1;
                end else begin
                    full <= 0;
                end
            end
        end
    end

    // Synchronizers for source domain
    assign src_data_sync = src_data_i;
    assign src_valid_sync = src_valid_i;
    assign src_ready_o = !full;

    // Synchronizers for destination domain
    assign dst_data_sync = fifo[read_ptr];
    assign dst_valid_o = !empty;

    // Handshake logic for source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_reg <= 1;
        end else begin
            src_ready_reg <= dst_ready_i;
        end
    end

    // Handshake logic for destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ready_sync <= 0;
        end else begin
            dst_ready_sync <= src_ready_reg;
        end
    end

endmodule
