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
    logic [WIDTH-1:0]       mem [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH-1:0]   write_ptr;
    logic [LOG_DEPTH-1:0]   read_ptr;
    logic                   full_flag;
    logic                   empty_flag;

    // Synchronizers for write pointer and read pointer
    logic [LOG_DEPTH-1:0]   write_ptr_sync [2:0];
    logic [LOG_DEPTH-1:0]   read_ptr_sync [2:0];

    // Synchronizers for full and empty flags
    logic                   full_flag_sync [2:0];
    logic                   empty_flag_sync [2:0];

    // Synchronizers for data and valid signals
    logic [WIDTH-1:0]       data_sync [2:0];
    logic                   valid_sync [2:0];

    // Synchronizer for ready signal
    logic                   ready_sync [2:0];

    // Write pointer logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                write_ptr <= write_ptr + 1;
            end
        end
    end

    // Read pointer logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                read_ptr <= read_ptr + 1;
            end
        end
    end

    // Full and empty flags logic
    assign full_flag = (write_ptr == read_ptr + 2**LOG_DEPTH - 1);
    assign empty_flag = (write_ptr == read_ptr);

    // Synchronizer for write pointer
    generate
        for (genvar i = 0; i < 3; i++) begin : write_ptr_sync_gen
            always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    write_ptr_sync[i] <= 0;
                end else begin
                    write_ptr_sync[i] <= write_ptr;
                end
            end
        end
    endgenerate

    // Synchronizer for read pointer
    generate
        for (genvar i = 0; i < 3; i++) begin : read_ptr_sync_gen
            always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    read_ptr_sync[i] <= 0;
                end else begin
                    read_ptr_sync[i] <= read_ptr;
                end
            end
        end
    endgenerate

    // Synchronizer for full and empty flags
    generate
        for (genvar i = 0; i < 3; i++) begin : flags_sync_gen
            always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    full_flag_sync[i] <= 0;
                end else begin
                    full_flag_sync[i] <= full_flag;
                end
            end
            always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    empty_flag_sync[i] <= 1;
                end else begin
                    empty_flag_sync[i] <= empty_flag;
                end
            end
        end
    endgenerate

    // Synchronizer for data and valid signals
    generate
        for (genvar i = 0; i < 3; i++) begin : data_valid_sync_gen
            always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    data_sync[i] <= 0;
                end else begin
                    data_sync[i] <= src_data_i;
                end
            end
            always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    valid_sync[i] <= 0;
                end else begin
                    valid_sync[i] <= src_valid_i;
                end
            end
        end
    endgenerate

    // Synchronizer for ready signal
    generate
        for (genvar i = 0; i < 3; i++) begin : ready_sync_gen
            always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    ready_sync[i] <= 1;
                end else begin
                    ready_sync[i] <= src_ready_o;
                end
            end
        end
    endgenerate

    // Destination output logic
    assign dst_data_o = mem[read_ptr_sync[2]];
    assign dst_valid_o = ~empty_flag_sync[2];

    // Source ready logic
    assign src_ready_o = ~full_flag_sync[2];

endmodule
