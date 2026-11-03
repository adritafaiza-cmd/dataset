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

    localparam DEPTH = 2**LOG_DEPTH;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [LOG_DEPTH:0] wr_ptr;
    reg [LOG_DEPTH:0] rd_ptr;
    reg [LOG_DEPTH:0] cnt;
    reg full;
    reg empty;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                mem[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == DEPTH - 1) begin
                    wr_ptr <= 0;
                end
                cnt <= cnt + 1;
                if (cnt == DEPTH) begin
                    full <= 1;
                end
                empty <= 0;
            end
        end
    end

    assign src_ready_o = !full;

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (dst_ready_i && !empty) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == DEPTH - 1) begin
                    rd_ptr <= 0;
                end
                cnt <= cnt - 1;
                if (cnt == 0) begin
                    empty <= 1;
                end
                full <= 0;
            end
        end
    end

    assign dst_data_o = mem[rd_ptr];
    assign dst_valid_o = !empty;

endmodule
