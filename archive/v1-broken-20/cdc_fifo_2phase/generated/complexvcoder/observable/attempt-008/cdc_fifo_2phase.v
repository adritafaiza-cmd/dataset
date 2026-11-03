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
    reg [WIDTH-1:0] data_reg [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0] read_ptr, write_ptr;
    reg valid_reg, empty_reg, full_reg;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            read_ptr <= 0;
            write_ptr <= 0;
            valid_reg <= 0;
            empty_reg <= 1;
            full_reg <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !full_reg) begin
                data_reg[write_ptr] <= src_data_i;
                write_ptr <= (write_ptr + 1) % (2**LOG_DEPTH);
                valid_reg <= 1;
                empty_reg <= 0;
                if (write_ptr == read_ptr) begin
                    full_reg <= 1;
                end
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= 0;
            write_ptr <= 0;
            valid_reg <= 0;
            empty_reg <= 1;
            full_reg <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i && !empty_reg) begin
                read_ptr <= (read_ptr + 1) % (2**LOG_DEPTH);
                valid_reg <= 0;
                empty_reg <= 1;
                if (write_ptr == read_ptr) begin
                    full_reg <= 0;
                end
            end
        end
    end

    // Clock domain crossing for ready signals
    reg src_ready_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_reg <= 1;
        end else begin
            if (full_reg) begin
                src_ready_reg <= 0;
            end else begin
                src_ready_reg <= 1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ready_o <= 1;
        end else begin
            src_ready_o <= src_ready_reg;
        end
    end

    // Clock domain crossing for valid signals
    reg dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 0;
        end else begin
            if (valid_reg) begin
                dst_valid_reg <= 1;
            end else begin
                dst_valid_reg <= 0;
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_o <= 0;
        end else begin
            dst_valid_o <= dst_valid_reg;
        end
    end

    // Output data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else begin
            if (valid_reg) begin
                dst_data_o <= data_reg[read_ptr];
            end else begin
                dst_data_o <= 0;
            end
        end
    end

endmodule
